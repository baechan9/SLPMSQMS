/**
 * @description 문서 버전 비교·변경 요약 화면 진입점(CMN-00-AI-003, cmnDocumentCompare).
 * 같은 문서의 두 리비전을 사용자 권한으로 확인하고 비교 결과(변경 목록·표 셀 비교·AI 요약)를 돌려준다.
 * - 추출 텍스트가 없는 형식(스캔 이미지·CAD)은 AI를 부르지 않고 "비교 불가"(BR-4, AC-2).
 * - 텍스트 추출·섹션 정렬·LLM 요약은 색인 엔진(AI-002, P12)과 함께 붙인다. A단계는 프로토 목 응답(CMN_DOC_COMPARE)만 보인다.
 * - 요약 확정(AiChangeSummary·ChangeNote 반영, BR-2)은 상세 기능 단계에서 동작한다(A단계 자리 구현).
 * @group CMN-00-AI-003
 */
public with sharing class CMN_DocumentCompareController {
  public static final String QUERY_KEY = 'CMN_DOC_COMPARE';
  public static final String STATE_OK = 'OK';
  public static final String STATE_NOT_COMPARABLE = 'NOT_COMPARABLE';
  public static final String STATE_NOT_AVAILABLE = 'NOT_AVAILABLE';
  public static final String TYPE_ADDED = 'ADDED';
  public static final String TYPE_REMOVED = 'REMOVED';
  public static final String TYPE_CHANGED = 'CHANGED';
  // 텍스트를 뽑을 수 없는 파일 확장자(스캔 이미지·CAD). 스캔 PDF 판별은 색인 단계의 추출 결과로 한다(P12)
  private static final Set<String> NO_TEXT_EXTENSIONS = new Set<String>{
    'dwg',
    'dxf',
    'step',
    'stp',
    'igs',
    'iges',
    'catpart',
    'jpg',
    'jpeg',
    'png',
    'tif',
    'tiff',
    'bmp',
    'gif'
  };
  @TestVisible
  private static Integer aiCalls = 0;

  /**
   * @description 섹션 변경 한 줄.
   */
  public class Change {
    @AuraEnabled
    public String key;
    @AuraEnabled
    public String changeType;
    @AuraEnabled
    public String typeLabel;
    @AuraEnabled
    public String section;
    @AuraEnabled
    public String beforeText;
    @AuraEnabled
    public String afterText;
  }

  /**
   * @description 표 셀 변경 한 줄(행 키 = 특성 번호, BR-3).
   */
  public class CellChange {
    @AuraEnabled
    public String key;
    @AuraEnabled
    public String rowKey;
    @AuraEnabled
    public String columnName;
    @AuraEnabled
    public String beforeText;
    @AuraEnabled
    public String afterText;
  }

  /**
   * @description 비교 결과.
   */
  public class Comparison {
    /** OK, NOT_COMPARABLE(텍스트 없음), NOT_AVAILABLE(엔진 미연결) */
    @AuraEnabled
    public String state;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public Boolean isMock = false;
    @AuraEnabled
    public String fromLabel;
    @AuraEnabled
    public String toLabel;
    @AuraEnabled
    public String summary;
    @AuraEnabled
    public List<Change> changes = new List<Change>();
    @AuraEnabled
    public String rowKeyLabel;
    @AuraEnabled
    public List<CellChange> cells = new List<CellChange>();
  }

  /**
   * @description 같은 문서의 두 리비전을 비교한다(이전 → 이후).
   * @param fromRevisionId 이전 리비전
   * @param toRevisionId 이후 리비전
   * @return 비교 결과
   * @throws AuraHandledException 같은 리비전·다른 문서·볼 수 없는 리비전(라벨 문구)
   */
  @AuraEnabled
  public static Comparison compare(Id fromRevisionId, Id toRevisionId) {
    try {
      if (
        fromRevisionId == null ||
        toRevisionId == null ||
        fromRevisionId == toRevisionId
      ) {
        throw new CMN_ValidationException(Label.CMN_DocCompare_PickTwo);
      }
      Map<Id, CMN_DocumentRevision__c> revs = new Map<Id, CMN_DocumentRevision__c>(
        [
          SELECT Id, Document__c, RevisionNo__c, FileName__c, StorageType__c
          FROM CMN_DocumentRevision__c
          WHERE Id IN :new Set<Id>{ fromRevisionId, toRevisionId }
          WITH USER_MODE
        ]
      );
      CMN_DocumentRevision__c a = revs.get(fromRevisionId);
      CMN_DocumentRevision__c b = revs.get(toRevisionId);
      if (a == null || b == null || a.Document__c != b.Document__c) {
        throw new CMN_ValidationException(Label.CMN_DocCompare_PickTwo);
      }
      Comparison c = new Comparison();
      c.fromLabel = revLabel(a);
      c.toLabel = revLabel(b);
      if (!hasText(a) || !hasText(b)) {
        // BR-4·AC-2: 비교 불가 표시, AI 호출 없음
        c.state = STATE_NOT_COMPARABLE;
        c.message = Label.CMN_DocCompare_NotComparable;
        return c;
      }
      aiCalls++;
      Object mock = CMN_Prototype.mockResponse(
        QUERY_KEY,
        new Map<String, Object>{ 'from' => a.Id, 'to' => b.Id }
      );
      if (!(mock instanceof Map<String, Object>)) {
        c.state = STATE_NOT_AVAILABLE;
        c.message = Label.CMN_Prototype_NotYetAvailable;
        return c;
      }
      read(c, (Map<String, Object>) mock);
      return c;
    } catch (Exception e) {
      throw toAura(e, fromRevisionId);
    }
  }

  /**
   * @description AI 요약을 이후 리비전의 변경 내용으로 반영한다(BR-2). A단계 자리 구현.
   * @param revisionId 이후 리비전
   * @param summary 사용자가 다듬은 요약
   * @throws AuraHandledException 항상(상세 기능 단계에서 동작)
   */
  @AuraEnabled
  public static void applySummary(Id revisionId, String summary) {
    try {
      CMN_Prototype.notYetAvailable();
    } catch (Exception e) {
      throw toAura(e, revisionId);
    }
  }

  private static void read(Comparison c, Map<String, Object> m) {
    c.isMock = m.get(CMN_Prototype.MOCK_FLAG) == true;
    if (m.get('comparable') == false) {
      c.state = STATE_NOT_COMPARABLE;
      c.message = Label.CMN_DocCompare_NotComparable;
      return;
    }
    c.state = STATE_OK;
    c.summary = str(m.get('summary'));
    Map<String, String> typeLabels = new Map<String, String>{
      TYPE_ADDED => Label.CMN_DocCompare_Added,
      TYPE_REMOVED => Label.CMN_DocCompare_Removed,
      TYPE_CHANGED => Label.CMN_DocCompare_Changed
    };
    Integer i = 0;
    for (Object o : asList(m.get('changes'))) {
      if (!(o instanceof Map<String, Object>)) {
        continue;
      }
      Map<String, Object> row = (Map<String, Object>) o;
      Change ch = new Change();
      ch.key = 'c' + i++;
      ch.changeType = str(row.get('type'));
      ch.typeLabel = typeLabels.get(ch.changeType) ?? ch.changeType;
      ch.section = str(row.get('section'));
      ch.beforeText = str(row.get('before'));
      ch.afterText = str(row.get('after'));
      c.changes.add(ch);
    }
    Object table = m.get('table');
    if (table instanceof Map<String, Object>) {
      Map<String, Object> t = (Map<String, Object>) table;
      c.rowKeyLabel = str(t.get('keyLabel'));
      Integer j = 0;
      for (Object o : asList(t.get('rows'))) {
        if (!(o instanceof Map<String, Object>)) {
          continue;
        }
        Map<String, Object> row = (Map<String, Object>) o;
        CellChange cell = new CellChange();
        cell.key = 't' + j++;
        cell.rowKey = str(row.get('key'));
        cell.columnName = str(row.get('column'));
        cell.beforeText = str(row.get('before'));
        cell.afterText = str(row.get('after'));
        c.cells.add(cell);
      }
    }
  }

  private static Boolean hasText(CMN_DocumentRevision__c r) {
    String name = r.FileName__c;
    if (String.isBlank(name) || !name.contains('.')) {
      return true; // 링크·이름 없는 파일은 색인 단계 추출 결과로 판단(P12)
    }
    return !NO_TEXT_EXTENSIONS.contains(
      name.substringAfterLast('.').toLowerCase()
    );
  }

  private static String revLabel(CMN_DocumentRevision__c r) {
    return 'Rev.' + r.RevisionNo__c?.intValue();
  }

  private static List<Object> asList(Object o) {
    return o instanceof List<Object> ? (List<Object>) o : new List<Object>();
  }

  private static String str(Object o) {
    return o == null ? null : String.valueOf(o);
  }

  private static AuraHandledException toAura(Exception e, Id recordId) {
    String message = e.getMessage();
    if (!(e instanceof CMN_ValidationException)) {
      CMN_Logger.error('CMN_DocumentCompareController', message, recordId, e);
      message = Label.CMN_Common_UnexpectedError;
    }
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
