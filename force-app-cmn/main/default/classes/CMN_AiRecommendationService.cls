/**
 * @description AI 추천 기록·결정·확정(CMN-00-AI-004 BR-1·BR-2). 추천은 참고이고 확정은 사람이 한다.
 * - record: 추천 묶음을 남긴다. 같은 대상·같은 UseCase의 이전 PROPOSED는 EXPIRED(BR-2). 공장은 원천 레코드에서 가져온다(공장 공유).
 * - decide: 사용자가 채택(ADOPTED)·수정 채택(MODIFIED)·제외(EXCLUDED, 사유 필수 AC-2)한다. 추천 레코드 편집 접근이 있어야 한다.
 * - finalize: 업무 확정 결과와 비교해 적중(IsHit)을 남긴다. 일치 규칙은 업무 WI의 CMN_AiHitRule이 준다.
 * 상태·결정 필드는 서비스 전용이라 FLS를 건너뛰는 시스템 모드로 저장하고, 레코드 공유는 이 클래스의 with sharing을 따른다.
 * 정확도 KPI(Top-1·Top-3 적중률, 채택률)는 Snowflake가 계산해 CMN_KpiValue__c로 보낸다(BR-4, DWH-003).
 * @group CMN-00-AI-004
 */
public with sharing class CMN_AiRecommendationService {
  public static final String PROPOSED = 'PROPOSED';
  public static final String ADOPTED = 'ADOPTED';
  public static final String MODIFIED = 'MODIFIED';
  public static final String EXCLUDED = 'EXCLUDED';
  public static final String EXPIRED = 'EXPIRED';
  public static final String EXCLUDE_GROUP = 'AI_EXCLUDE_REASON';
  public static final Integer MAX_RECS = 50;
  private static final Integer NAME_MAX = 80;
  private static final Integer LONG_MAX = 32768;
  private static final Integer PROMPT_MAX = 40;
  private static final Integer MODEL_MAX = 80;
  private static final Integer RANK_MAX = 999;
  private static final Set<String> DECISIONS = new Set<String>{
    ADOPTED,
    MODIFIED,
    EXCLUDED
  };
  private static Set<String> useCaseValues;

  /**
   * @description 추천 1건 입력(record).
   */
  public class Rec {
    /** 순위(1부터, 묶음 안에서 유일) */
    public Integer rank;
    /** 목록 제목(없으면 ContentJson의 title, 그것도 없으면 "{UseCase} #{순위}") */
    public String title;
    /** 구조화 내용 JSON(필수). 기본 표시 키: title, text, items[{label, value}] */
    public String contentJson;
    /** 근거 설명 */
    public String rationale;
    /** 근거 출처 JSON [{id, label}] */
    public String sourceRefsJson;
    /** 신뢰 점수 0~1 */
    public Decimal score;
    /** 프롬프트 버전(재현성, 필수) */
    public String promptVersion;
    /** 모델 정보(재현성, 필수) */
    public String modelInfo;
  }

  /**
   * @description 추천 묶음을 기록한다. 같은 대상·UseCase의 이전 제안(PROPOSED)은 만료한다(BR-2).
   * @param useCase 추천 유형(UseCase__c 값)
   * @param sourceId 추천 대상 업무 레코드
   * @param recs 추천(1~50건, 순위 유일)
   * @return 만든 추천 Id(입력 순서)
   * @throws CMN_ValidationException 입력이 형식에 맞지 않을 때
   */
  public static List<Id> record(String useCase, Id sourceId, List<Rec> recs) {
    if (
      !validUseCases().contains(useCase) ||
      sourceId == null ||
      recs == null ||
      recs.isEmpty() ||
      recs.size() > MAX_RECS
    ) {
      throw invalid();
    }
    Set<Integer> ranks = new Set<Integer>();
    for (Rec r : recs) {
      checkRec(r);
      if (!ranks.add(r.rank)) {
        throw invalid();
      }
    }
    String sourceText = String.valueOf(sourceId);
    String objectName = String.valueOf(sourceId.getSObjectType());
    Id plantId = plantOf(sourceId);

    List<CMN_AiRecommendation__c> toExpire = new List<CMN_AiRecommendation__c>();
    for (CMN_AiRecommendation__c old : [
      SELECT Id
      FROM CMN_AiRecommendation__c
      WHERE
        SourceRecordId__c = :sourceText
        AND UseCase__c = :useCase
        AND Status__c = :PROPOSED
      WITH SYSTEM_MODE
    ]) {
      toExpire.add(
        new CMN_AiRecommendation__c(Id = old.Id, Status__c = EXPIRED)
      );
    }
    List<CMN_AiRecommendation__c> rows = new List<CMN_AiRecommendation__c>();
    for (Rec r : recs) {
      rows.add(
        new CMN_AiRecommendation__c(
          Name = titleOf(useCase, r),
          UseCase__c = useCase,
          SourceRecordId__c = sourceText,
          SourceObject__c = objectName,
          Plant__c = plantId,
          Rank__c = r.rank,
          ContentJson__c = r.contentJson,
          Rationale__c = r.rationale,
          SourceRefs__c = r.sourceRefsJson,
          Score__c = r.score,
          PromptVersion__c = r.promptVersion.trim(),
          ModelInfo__c = r.modelInfo.trim(),
          Status__c = PROPOSED
        )
      );
    }
    Database.update(toExpire, AccessLevel.SYSTEM_MODE);
    Database.insert(rows, AccessLevel.SYSTEM_MODE);
    List<Id> ids = new List<Id>();
    for (CMN_AiRecommendation__c row : rows) {
      ids.add(row.Id);
    }
    return ids;
  }

  /**
   * @description 사용자 결정(채택·수정 채택·제외). 만료되었거나 확정 평가된 추천은 바꿀 수 없다.
   * @param recId 추천 Id
   * @param status ADOPTED, MODIFIED, EXCLUDED
   * @param reasonCode 제외 사유(AI_EXCLUDE_REASON 코드 Id 또는 코드 값). 제외면 필수
   * @return 저장한 추천
   * @throws CMN_ValidationException 입력 오류, 권한 없음, 닫힌 추천, 제외 사유 누락
   */
  public static CMN_AiRecommendation__c decide(
    Id recId,
    String status,
    String reasonCode
  ) {
    if (recId == null || !DECISIONS.contains(status)) {
      throw invalid();
    }
    List<CMN_AiRecommendation__c> found = [
      SELECT Id, Status__c, FinalizedAt__c
      FROM CMN_AiRecommendation__c
      WHERE Id = :recId
      WITH SYSTEM_MODE
    ];
    if (found.isEmpty() || !canEdit(recId)) {
      throw new CMN_ValidationException(Label.CMN_AiRec_NoAccess);
    }
    CMN_AiRecommendation__c rec = found[0];
    if (rec.Status__c == EXPIRED || rec.FinalizedAt__c != null) {
      throw new CMN_ValidationException(Label.CMN_AiRec_Closed);
    }
    Id reasonId = null;
    if (status == EXCLUDED) {
      reasonId = excludeReasonId(reasonCode);
      if (reasonId == null) {
        throw new CMN_ValidationException(Label.CMN_AiRec_ReasonRequired);
      }
    }
    rec.Status__c = status;
    rec.ExcludeReason__c = reasonId;
    rec.DecidedBy__c = UserInfo.getUserId();
    rec.DecidedAt__c = Datetime.now();
    Database.update(rec, AccessLevel.SYSTEM_MODE);
    return rec;
  }

  /**
   * @description 업무 확정 결과로 적중을 평가한다(만료되지 않은 추천 전부, 다시 부르면 덮어쓴다).
   * @param sourceId 추천 대상 업무 레코드
   * @param useCase 추천 유형
   * @param outcomeJson 업무 확정 결과 JSON
   * @param rule 적중 규칙(업무 WI 구현)
   * @return 평가한 추천 수
   * @throws CMN_ValidationException 입력이 형식에 맞지 않을 때
   */
  public static Integer finalize(
    Id sourceId,
    String useCase,
    String outcomeJson,
    CMN_AiHitRule rule
  ) {
    if (
      sourceId == null ||
      rule == null ||
      !validUseCases().contains(useCase) ||
      !isJson(outcomeJson) ||
      outcomeJson.length() > LONG_MAX
    ) {
      throw invalid();
    }
    String sourceText = String.valueOf(sourceId);
    List<CMN_AiRecommendation__c> recs = [
      SELECT
        Id,
        Name,
        UseCase__c,
        Rank__c,
        ContentJson__c,
        Status__c,
        Score__c,
        SourceRecordId__c
      FROM CMN_AiRecommendation__c
      WHERE
        SourceRecordId__c = :sourceText
        AND UseCase__c = :useCase
        AND Status__c != :EXPIRED
      WITH SYSTEM_MODE
      ORDER BY Rank__c
    ];
    Datetime now = Datetime.now();
    for (CMN_AiRecommendation__c rec : recs) {
      rec.IsHit__c = rule.isHit(rec, outcomeJson) == true;
      rec.FinalOutcomeJson__c = outcomeJson;
      rec.FinalizedAt__c = now;
    }
    Database.update(recs, AccessLevel.SYSTEM_MODE);
    return recs.size();
  }

  /**
   * @description 저장 전 정리(트리거): 서비스를 거치지 않은 적재(데모·이관)도 제목이 비지 않게 한다.
   * @param recs 새 추천
   */
  public static void prepare(List<CMN_AiRecommendation__c> recs) {
    for (CMN_AiRecommendation__c r : recs) {
      if (String.isBlank(r.Name)) {
        r.Name = (r.UseCase__c + ' #' + r.Rank__c).left(NAME_MAX);
      }
    }
  }

  /**
   * @description 사용할 수 있는 UseCase 값(선택 목록 활성 값).
   * @return 값 집합
   */
  public static Set<String> validUseCases() {
    if (useCaseValues == null) {
      useCaseValues = new Set<String>();
      for (
        Schema.PicklistEntry e : CMN_AiRecommendation__c.UseCase__c.getDescribe()
          .getPicklistValues()
      ) {
        if (e.isActive()) {
          useCaseValues.add(e.getValue());
        }
      }
    }
    return useCaseValues;
  }

  /**
   * @description 현재 사용자가 추천을 결정할 수 있는가(레코드 편집 접근).
   * @param recId 추천 Id
   * @return 편집 접근이 있으면 true
   */
  public static Boolean canEdit(Id recId) {
    return !editableIds(new Set<Id>{ recId }).isEmpty();
  }

  /**
   * @description 현재 사용자가 편집할 수 있는 추천 Id(UserRecordAccess, 200건 이하).
   * @param recIds 추천 Id
   * @return 편집 가능한 Id
   */
  public static Set<Id> editableIds(Set<Id> recIds) {
    Set<Id> out = new Set<Id>();
    if (recIds == null || recIds.isEmpty()) {
      return out;
    }
    for (UserRecordAccess a : [
      SELECT RecordId, HasEditAccess
      FROM UserRecordAccess
      WHERE UserId = :UserInfo.getUserId() AND RecordId IN :recIds
      WITH USER_MODE
    ]) {
      if (a.HasEditAccess) {
        out.add(a.RecordId);
      }
    }
    return out;
  }

  private static void checkRec(Rec r) {
    if (
      r == null ||
      r.rank == null ||
      r.rank < 1 ||
      r.rank > RANK_MAX ||
      !isJson(r.contentJson) ||
      r.contentJson.length() > LONG_MAX ||
      (r.rationale != null &&
      r.rationale.length() > LONG_MAX) ||
      (String.isNotBlank(r.sourceRefsJson) &&
      (!isJson(r.sourceRefsJson) || r.sourceRefsJson.length() > LONG_MAX)) ||
      (r.score != null && (r.score < 0 || r.score > 1)) ||
      String.isBlank(r.promptVersion) ||
      r.promptVersion.trim().length() > PROMPT_MAX ||
      String.isBlank(r.modelInfo) ||
      r.modelInfo.trim().length() > MODEL_MAX
    ) {
      throw invalid();
    }
  }

  private static String titleOf(String useCase, Rec r) {
    String title = r.title;
    if (String.isBlank(title)) {
      Object parsed = JSON.deserializeUntyped(r.contentJson);
      if (parsed instanceof Map<String, Object>) {
        Object t = ((Map<String, Object>) parsed).get('title');
        title = t == null ? null : String.valueOf(t);
      }
    }
    if (String.isBlank(title)) {
      title = useCase + ' #' + r.rank;
    }
    return title.trim().left(NAME_MAX);
  }

  /** 원천 레코드에 공장 Lookup(Plant__c → CMN_Plant__c)이 있으면 그 값 */
  private static Id plantOf(Id sourceId) {
    Schema.DescribeSObjectResult d = sourceId.getSObjectType().getDescribe();
    Schema.SObjectField f = d.fields.getMap().get('plant__c');
    if (f == null) {
      return null;
    }
    Schema.DescribeFieldResult fd = f.getDescribe();
    if (
      fd.getType() != Schema.DisplayType.REFERENCE ||
      !fd.getReferenceTo().contains(CMN_Plant__c.SObjectType)
    ) {
      return null;
    }
    // 객체 이름은 Id의 describe에서 오므로 사용자 입력이 아니다. 값은 바인드한다
    List<SObject> rows = Database.queryWithBinds(
      'SELECT Plant__c FROM ' + d.getName() + ' WHERE Id = :sourceId',
      new Map<String, Object>{ 'sourceId' => sourceId },
      AccessLevel.SYSTEM_MODE
    );
    return rows.isEmpty() ? null : (Id) rows[0].get('Plant__c');
  }

  private static Id excludeReasonId(String reasonCode) {
    if (String.isBlank(reasonCode)) {
      return null;
    }
    Id idValue = null;
    if (reasonCode instanceof Id) {
      idValue = (Id) reasonCode;
    }
    String codeValue = reasonCode.trim();
    List<CMN_Code__c> codes = [
      SELECT Id
      FROM CMN_Code__c
      WHERE
        CodeGroup__r.GroupCode__c = :EXCLUDE_GROUP
        AND IsActive__c = TRUE
        AND (Id = :idValue
        OR Code__c = :codeValue)
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return codes.isEmpty() ? null : codes[0].Id;
  }

  private static Boolean isJson(String value) {
    if (String.isBlank(value)) {
      return false;
    }
    try {
      JSON.deserializeUntyped(value);
      return true;
    } catch (JSONException e) {
      return false;
    }
  }

  private static CMN_ValidationException invalid() {
    return new CMN_ValidationException(Label.CMN_Common_InvalidInput);
  }
}
