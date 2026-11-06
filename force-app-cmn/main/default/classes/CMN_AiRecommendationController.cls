/**
 * @description AI 추천 목록 화면 진입점(CMN-00-AI-004 BR-3, cmnAiRecommendationList).
 * 대상 레코드의 만료되지 않은 추천을 사용자 권한으로 읽어 카드 DTO로 돌려주고, 결정은 서비스에 맡긴다.
 * ContentJson은 기본 키(title, text, items)만 풀어 주고, UseCase 전용 표시는 화면의 렌더러가 원문으로 한다.
 * @group CMN-00-AI-004
 */
public with sharing class CMN_AiRecommendationController {
  private static final Integer MAX_ROWS = 50;
  private static final Integer MAX_DETAILS = 10;
  private static final Integer MAX_REFS = 10;
  private static final String BASE_QUERY =
    'SELECT Id, Name, UseCase__c, Rank__c, ContentJson__c, Rationale__c, SourceRefs__c, Score__c, Status__c, ' +
    'FinalizedAt__c, IsHit__c, DecidedAt__c, DecidedBy__r.Name, ExcludeReason__r.Name, ' +
    'ExcludeReason__r.NameEn__c, ExcludeReason__r.NameZh__c ' +
    'FROM CMN_AiRecommendation__c WHERE Status__c != :expired';

  /**
   * @description 카드의 이름-값 한 줄.
   */
  public class Detail {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;
  }

  /**
   * @description 근거 출처 링크.
   */
  public class Ref {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String label;
  }

  /**
   * @description 추천 카드.
   */
  public class Item {
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String useCase;
    @AuraEnabled
    public String useCaseLabel;
    @AuraEnabled
    public Integer rank;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String text;
    @AuraEnabled
    public List<Detail> details = new List<Detail>();
    @AuraEnabled
    public String rationale;
    @AuraEnabled
    public List<Ref> refs = new List<Ref>();
    @AuraEnabled
    public Integer scorePercent;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String statusLabel;
    @AuraEnabled
    public String excludeReason;
    @AuraEnabled
    public String decidedBy;
    @AuraEnabled
    public Datetime decidedAt;
    @AuraEnabled
    public Boolean isHit;
    @AuraEnabled
    public Boolean isFinalized;
    @AuraEnabled
    public Boolean canDecide;
    /** 원문(UseCase 렌더러·채택 후 입력란 복사용) */
    @AuraEnabled
    public String contentJson;
  }

  /**
   * @description 목록 응답.
   */
  public class View {
    @AuraEnabled
    public List<Item> items = new List<Item>();
    /** 아직 결정하지 않은 제안 수(레일 배지) */
    @AuraEnabled
    public Integer proposedCount = 0;
  }

  /**
   * @description 대상 레코드의 추천(만료 제외, 순위순, 최대 50건).
   * @param recordId 추천 대상 업무 레코드
   * @param useCase 추천 유형(비우면 전체)
   * @return 목록
   * @throws AuraHandledException 입력 오류(라벨 문구)
   */
  @AuraEnabled
  public static View getRecommendations(Id recordId, String useCase) {
    try {
      if (
        recordId == null ||
        (String.isNotBlank(useCase) &&
        !CMN_AiRecommendationService.validUseCases().contains(useCase))
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      Map<String, Object> binds = new Map<String, Object>{
        'expired' => CMN_AiRecommendationService.EXPIRED,
        'sourceText' => String.valueOf(recordId),
        'maxRows' => MAX_ROWS
      };
      String query = BASE_QUERY + ' AND SourceRecordId__c = :sourceText';
      if (String.isNotBlank(useCase)) {
        binds.put('useCase', useCase);
        query += ' AND UseCase__c = :useCase';
      }
      query += ' ORDER BY UseCase__c, Rank__c, CreatedDate DESC LIMIT :maxRows';
      List<CMN_AiRecommendation__c> rows = Database.queryWithBinds(
        query,
        binds,
        AccessLevel.USER_MODE
      );
      View v = new View();
      Set<Id> ids = new Map<Id, CMN_AiRecommendation__c>(rows).keySet();
      Set<Id> editable = CMN_AiRecommendationService.editableIds(ids);
      for (CMN_AiRecommendation__c r : rows) {
        Item i = toItem(r, editable.contains(r.Id));
        v.items.add(i);
        if (i.status == CMN_AiRecommendationService.PROPOSED) {
          v.proposedCount++;
        }
      }
      return v;
    } catch (Exception e) {
      throw toAura(e, 'getRecommendations', recordId);
    }
  }

  /**
   * @description 채택·수정 채택·제외(제외는 사유 필수).
   * @param recommendationId 추천 Id
   * @param status ADOPTED, MODIFIED, EXCLUDED
   * @param reasonCode 제외 사유 코드 Id(AI_EXCLUDE_REASON)
   * @return 갱신된 카드
   * @throws AuraHandledException 권한 없음·닫힌 추천·사유 누락(라벨 문구)
   */
  @AuraEnabled
  public static Item decide(
    Id recommendationId,
    String status,
    String reasonCode
  ) {
    try {
      CMN_AiRecommendationService.decide(recommendationId, status, reasonCode);
      List<CMN_AiRecommendation__c> rows = Database.queryWithBinds(
        BASE_QUERY + ' AND Id = :recId',
        new Map<String, Object>{
          'expired' => CMN_AiRecommendationService.EXPIRED,
          'recId' => recommendationId
        },
        AccessLevel.USER_MODE
      );
      return toItem(
        rows[0],
        CMN_AiRecommendationService.canEdit(recommendationId)
      );
    } catch (Exception e) {
      throw toAura(e, 'decide', recommendationId);
    }
  }

  private static Item toItem(CMN_AiRecommendation__c r, Boolean editable) {
    Item i = new Item();
    i.id = r.Id;
    i.useCase = r.UseCase__c;
    i.useCaseLabel = picklistLabel(
      CMN_AiRecommendation__c.UseCase__c,
      r.UseCase__c
    );
    i.rank = r.Rank__c?.intValue();
    i.title = r.Name;
    i.rationale = r.Rationale__c;
    i.scorePercent = r.Score__c == null
      ? null
      : (r.Score__c * 100).setScale(0, System.RoundingMode.HALF_UP).intValue();
    i.status = r.Status__c;
    i.statusLabel = picklistLabel(
      CMN_AiRecommendation__c.Status__c,
      r.Status__c
    );
    i.excludeReason = r.ExcludeReason__r == null
      ? null
      : localized(r.ExcludeReason__r);
    i.decidedBy = r.DecidedBy__r?.Name;
    i.decidedAt = r.DecidedAt__c;
    i.isFinalized = r.FinalizedAt__c != null;
    i.isHit = i.isFinalized ? r.IsHit__c : null;
    i.canDecide = editable && !i.isFinalized;
    i.contentJson = r.ContentJson__c;
    readContent(i, r.ContentJson__c);
    i.refs = readRefs(r.SourceRefs__c);
    return i;
  }

  /** 기본 키만 푼다: text(없으면 summary), items[{label, value}] 최대 10줄. 형식이 다르면 비운다 */
  private static void readContent(Item i, String contentJson) {
    Object parsed = parse(contentJson);
    if (!(parsed instanceof Map<String, Object>)) {
      return;
    }
    Map<String, Object> m = (Map<String, Object>) parsed;
    Object text = m.containsKey('text') ? m.get('text') : m.get('summary');
    i.text = text == null ? null : String.valueOf(text);
    Object items = m.get('items');
    if (!(items instanceof List<Object>)) {
      return;
    }
    for (Object o : (List<Object>) items) {
      if (i.details.size() >= MAX_DETAILS) {
        break;
      }
      if (o instanceof Map<String, Object>) {
        Map<String, Object> row = (Map<String, Object>) o;
        Detail d = new Detail();
        d.label = row.get('label') == null
          ? null
          : String.valueOf(row.get('label'));
        d.value = row.get('value') == null
          ? null
          : String.valueOf(row.get('value'));
        i.details.add(d);
      }
    }
  }

  /** 근거 출처: [{id, label}] 또는 [id]. 올바른 레코드 Id만 링크로 만든다 */
  private static List<Ref> readRefs(String refsJson) {
    List<Ref> out = new List<Ref>();
    Object parsed = parse(refsJson);
    if (!(parsed instanceof List<Object>)) {
      return out;
    }
    for (Object o : (List<Object>) parsed) {
      if (out.size() >= MAX_REFS) {
        break;
      }
      Object rawId = o instanceof Map<String, Object>
        ? ((Map<String, Object>) o).get('id')
        : o;
      Object rawLabel = o instanceof Map<String, Object>
        ? ((Map<String, Object>) o).get('label')
        : null;
      String idText = rawId == null ? null : String.valueOf(rawId);
      if (!(idText instanceof Id)) {
        continue;
      }
      Ref ref = new Ref();
      ref.id = idText;
      ref.label = rawLabel == null ? idText : String.valueOf(rawLabel);
      out.add(ref);
    }
    return out;
  }

  private static Object parse(String value) {
    if (String.isBlank(value)) {
      return null;
    }
    try {
      return JSON.deserializeUntyped(value);
    } catch (JSONException e) {
      return null;
    }
  }

  private static String picklistLabel(Schema.SObjectField f, String value) {
    for (Schema.PicklistEntry e : f.getDescribe().getPicklistValues()) {
      if (e.getValue() == value) {
        return e.getLabel();
      }
    }
    return value;
  }

  /** 공통 코드 표시 이름(I18N-001 BR-3, MDM-007 코드 선택과 같은 규칙) */
  private static String localized(CMN_Code__c c) {
    String prefix = UserInfo.getLanguage()?.left(2);
    if (prefix == 'ko') {
      return c.Name;
    }
    if (prefix == 'zh' && String.isNotBlank(c.NameZh__c)) {
      return c.NameZh__c;
    }
    return String.isBlank(c.NameEn__c) ? c.Name : c.NameEn__c;
  }

  private static AuraHandledException toAura(
    Exception e,
    String method,
    Id recordId
  ) {
    String message = e.getMessage();
    if (!(e instanceof CMN_ValidationException)) {
      CMN_Logger.error(
        'CMN_AiRecommendationController.' + method,
        message,
        recordId,
        e
      );
      message = Label.CMN_Common_UnexpectedError;
    }
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
