/**
 * @description 통합 검색·요약 화면 진입점(CMN-00-AI-002 BR-3, cmnUnifiedSearch). 입력 하나로 두 검색을 한다.
 * (a) 레코드 검색: CMN_SearchScope__mdt에 등록된 객체를 SOSL로 사용자 권한(USER_MODE)으로 찾는다(번호·제목·보조 필드).
 * (b) 문서 의미 검색·AI 요약: 색인 엔진(Data Cloud 또는 Cortex Search, 결정 D-4·D8-1)은 상세 기능 단계(P12)에서 붙인다.
 *     A단계에서는 프로토 목 응답(CMN_DOC_SEARCH)만 보이고, 프로토 모드가 아니면 "준비 중" 상태를 돌려준다.
 * 문서 결과의 상위 레코드 접근 확인(BR-2)은 엔진을 붙일 때 이 클래스에서 한다(목 응답은 실제 레코드가 아니다).
 * @group CMN-00-AI-002
 */
public with sharing class CMN_UnifiedSearchController {
  public static final String DOC_QUERY_KEY = 'CMN_DOC_SEARCH';
  public static final String STATE_OK = 'OK';
  public static final String STATE_EMPTY = 'EMPTY';
  public static final String STATE_NOT_AVAILABLE = 'NOT_AVAILABLE';
  private static final Integer TERM_MIN = 2;
  private static final Integer TERM_MAX = 100;
  private static final Integer DEFAULT_ROWS = 5;
  private static final Integer MAX_ROWS_PER_OBJECT = 20;
  private static final Integer MAX_SCOPES = 10;
  // SOSL 예약 문자(검색어 안에서는 글자로 찾도록 백슬래시로 막는다)
  private static final String RESERVED = '?&|!{}[]()^~*:\\"\'+-';
  @TestVisible
  private static List<CMN_SearchScope__mdt> scopesOverride;

  /**
   * @description 레코드 검색 결과 한 건.
   */
  public class Hit {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String numberText;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String subtitle;
  }

  /**
   * @description 객체별 레코드 결과.
   */
  public class RecordGroup {
    @AuraEnabled
    public String objectApiName;
    @AuraEnabled
    public String objectLabel;
    @AuraEnabled
    public List<Hit> hits = new List<Hit>();
  }

  /**
   * @description AI 요약의 출처.
   */
  public class Source {
    @AuraEnabled
    public String text;
    @AuraEnabled
    public String recordId;
  }

  /**
   * @description 문서 의미 검색 결과 한 건.
   */
  public class DocHit {
    @AuraEnabled
    public String key;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String docNo;
    @AuraEnabled
    public String revisionLabel;
    @AuraEnabled
    public String docClass;
    @AuraEnabled
    public String snippet;
    @AuraEnabled
    public Integer scorePercent;
    @AuraEnabled
    public Boolean superseded;
    @AuraEnabled
    public String recordId;
  }

  /**
   * @description 문서 검색·요약.
   */
  public class DocResult {
    /** OK, EMPTY, NOT_AVAILABLE(색인 엔진 미연결) */
    @AuraEnabled
    public String state;
    @AuraEnabled
    public Boolean isMock = false;
    @AuraEnabled
    public String summary;
    @AuraEnabled
    public List<Source> sources = new List<Source>();
    @AuraEnabled
    public List<DocHit> items = new List<DocHit>();
    @AuraEnabled
    public String message;
  }

  /**
   * @description 검색 응답.
   */
  public class Result {
    @AuraEnabled
    public String term;
    @AuraEnabled
    public List<RecordGroup> records = new List<RecordGroup>();
    @AuraEnabled
    public Integer recordCount = 0;
    @AuraEnabled
    public DocResult documents;
  }

  /**
   * @description 레코드·문서를 함께 찾는다.
   * @param term 검색어(2~100자)
   * @param includeSuperseded 이전(SUPERSEDED) 리비전 포함
   * @return 결과
   * @throws AuraHandledException 검색어 길이 오류(라벨 문구)
   */
  @AuraEnabled
  public static Result search(String term, Boolean includeSuperseded) {
    try {
      String trimmed = term?.trim();
      if (
        String.isBlank(trimmed) ||
        trimmed.length() < TERM_MIN ||
        trimmed.length() > TERM_MAX
      ) {
        throw new CMN_ValidationException(Label.CMN_Search_TermLength);
      }
      Result r = new Result();
      r.term = trimmed;
      r.records = searchRecords(trimmed);
      for (RecordGroup g : r.records) {
        r.recordCount += g.hits.size();
      }
      r.documents = searchDocuments(trimmed, includeSuperseded == true);
      return r;
    } catch (Exception e) {
      throw toAura(e);
    }
  }

  // ------------------------------------------------------------ 레코드 검색(a)
  private class Scope {
    Schema.DescribeSObjectResult d;
    String numberField;
    String titleField;
    String subtitleField;
    Integer maxRows;
  }

  private static List<RecordGroup> searchRecords(String term) {
    List<Scope> scopes = usableScopes();
    List<RecordGroup> out = new List<RecordGroup>();
    if (scopes.isEmpty()) {
      return out;
    }
    List<String> returning = new List<String>();
    for (Scope s : scopes) {
      Set<String> fields = new Set<String>{ 'Id' };
      for (
        String f : new List<String>{
          s.numberField,
          s.titleField,
          s.subtitleField
        }
      ) {
        if (f != null) {
          fields.add(f);
        }
      }
      returning.add(
        s.d.getName() +
          '(' +
          String.join(new List<String>(fields), ', ') +
          ' ORDER BY LastModifiedDate DESC LIMIT ' +
          s.maxRows +
          ')'
      );
    }
    // 객체·필드 이름은 등록 메타데이터를 describe로 확인한 값이고, 검색어는 지역 변수 바인드로 넘긴다(예약 문자는 글자로)
    String searchTerm = escape(term);
    List<List<SObject>> found = Search.query(
      'FIND :searchTerm IN ALL FIELDS RETURNING ' +
      String.join(returning, ', '),
      AccessLevel.USER_MODE
    );
    for (Integer i = 0; i < scopes.size(); i++) {
      Scope s = scopes[i];
      RecordGroup g = new RecordGroup();
      g.objectApiName = s.d.getName();
      g.objectLabel = s.d.getLabelPlural();
      for (SObject row : found[i]) {
        Hit h = new Hit();
        h.id = row.Id;
        h.numberText = textOf(row, s.numberField);
        h.title = textOf(row, s.titleField);
        h.subtitle = textOf(row, s.subtitleField);
        g.hits.add(h);
      }
      if (!g.hits.isEmpty()) {
        out.add(g);
      }
    }
    return out;
  }

  private static List<Scope> usableScopes() {
    List<CMN_SearchScope__mdt> rows = scopesOverride != null
      ? scopesOverride
      : CMN_SearchScope__mdt.getAll().values();
    List<CMN_SearchScope__mdt> sorted = new List<CMN_SearchScope__mdt>();
    for (CMN_SearchScope__mdt r : rows) {
      if (r.IsActive__c) {
        sorted.add(r);
      }
    }
    sorted.sort(new ByOrder());
    Map<String, Schema.SObjectType> describeMap = Schema.getGlobalDescribe();
    List<Scope> out = new List<Scope>();
    for (CMN_SearchScope__mdt r : sorted) {
      if (out.size() >= MAX_SCOPES) {
        break;
      }
      Schema.SObjectType t = describeMap.get(r.ObjectApiName__c?.toLowerCase());
      if (t == null) {
        continue; // 아직 배포되지 않은 메뉴 객체
      }
      Schema.DescribeSObjectResult d = t.getDescribe();
      if (!d.isAccessible() || !d.isSearchable()) {
        continue;
      }
      Map<String, Schema.SObjectField> fields = d.fields.getMap();
      Scope s = new Scope();
      s.d = d;
      s.titleField = readable(fields, r.TitleField__c) ?? 'Id';
      s.numberField = readable(fields, r.NumberField__c);
      s.subtitleField = readable(fields, r.SubtitleField__c);
      Integer n = r.MaxRows__c?.intValue();
      s.maxRows = n == null ||
        n < 1
        ? DEFAULT_ROWS
        : Math.min(n, MAX_ROWS_PER_OBJECT);
      out.add(s);
    }
    return out;
  }

  private class ByOrder implements System.Comparator<CMN_SearchScope__mdt> {
    public Integer compare(CMN_SearchScope__mdt a, CMN_SearchScope__mdt b) {
      Decimal x = a.Order__c ?? 9999;
      Decimal y = b.Order__c ?? 9999;
      return x == y ? 0 : (x < y ? -1 : 1);
    }
  }

  /** 필드가 있고 사용자가 읽을 수 있으면 실제 API 이름, 아니면 null */
  private static String readable(
    Map<String, Schema.SObjectField> fields,
    String name
  ) {
    if (String.isBlank(name)) {
      return null;
    }
    Schema.SObjectField f = fields.get(name.trim().toLowerCase());
    if (f == null) {
      return null;
    }
    Schema.DescribeFieldResult fd = f.getDescribe();
    return fd.isAccessible() ? fd.getName() : null;
  }

  private static String textOf(SObject row, String field) {
    if (field == null) {
      return null;
    }
    Object v = row.get(field);
    return v == null ? null : String.valueOf(v);
  }

  @TestVisible
  private static String escape(String term) {
    String out = '';
    for (Integer i = 0; i < term.length(); i++) {
      String c = term.substring(i, i + 1);
      out += RESERVED.contains(c) ? '\\' + c : c;
    }
    return out;
  }

  // ------------------------------------------------------------ 문서 검색(b)
  private static DocResult searchDocuments(
    String term,
    Boolean includeSuperseded
  ) {
    DocResult r = new DocResult();
    Object mock = CMN_Prototype.mockResponse(
      DOC_QUERY_KEY,
      new Map<String, Object>{ 'term' => term }
    );
    if (!(mock instanceof Map<String, Object>)) {
      // 색인 엔진(P12)이 붙기 전: 레코드 검색만 쓸 수 있다
      r.state = STATE_NOT_AVAILABLE;
      r.message = Label.CMN_Prototype_NotYetAvailable;
      return r;
    }
    Map<String, Object> m = (Map<String, Object>) mock;
    r.isMock = m.get(CMN_Prototype.MOCK_FLAG) == true;
    Object summary = m.get('summary');
    if (summary instanceof Map<String, Object>) {
      Map<String, Object> s = (Map<String, Object>) summary;
      r.summary = s.get('text') == null ? null : String.valueOf(s.get('text'));
      for (Object o : asList(s.get('sources'))) {
        if (o instanceof Map<String, Object>) {
          Source src = new Source();
          src.text = String.valueOf(((Map<String, Object>) o).get('label'));
          r.sources.add(src);
        }
      }
    }
    Integer index = 0;
    for (Object o : asList(m.get('documents'))) {
      if (!(o instanceof Map<String, Object>)) {
        continue;
      }
      Map<String, Object> d = (Map<String, Object>) o;
      Boolean superseded = d.get('superseded') == true;
      if (superseded && !includeSuperseded) {
        continue;
      }
      DocHit h = new DocHit();
      h.key = 'd' + index++;
      h.title = str(d.get('title'));
      h.docNo = str(d.get('docNo'));
      h.revisionLabel = str(d.get('revisionLabel'));
      h.docClass = str(d.get('docClass'));
      h.snippet = str(d.get('snippet'));
      Object score = d.get('score');
      h.scorePercent = score instanceof Decimal
        ? ((Decimal) score * 100)
            .setScale(0, System.RoundingMode.HALF_UP)
            .intValue()
        : null;
      h.superseded = superseded;
      r.items.add(h);
    }
    r.state = r.items.isEmpty() ? STATE_EMPTY : STATE_OK;
    return r;
  }

  private static List<Object> asList(Object o) {
    return o instanceof List<Object> ? (List<Object>) o : new List<Object>();
  }

  private static String str(Object o) {
    return o == null ? null : String.valueOf(o);
  }

  private static AuraHandledException toAura(Exception e) {
    String message = e.getMessage();
    if (!(e instanceof CMN_ValidationException)) {
      CMN_Logger.error('CMN_UnifiedSearchController.search', message, null, e);
      message = Label.CMN_Common_UnexpectedError;
    }
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
