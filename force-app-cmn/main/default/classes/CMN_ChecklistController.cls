/**
 * @description 체크리스트 수행 화면 컨트롤러(CMN-00-UX-009, LWC cmnChecklistRunner). 레코드 객체의 Provider를
 * CMN_ChecklistProvider__mdt에서 찾아 시트·저장·점수 미리보기·후속 조치를 맡긴다.
 * 셸 공통 규칙만 여기서 다시 확인한다: 편집 가능, 질문 키, 답 유형별 형식(허용 점수·배점 범위·NA 허용·NA 사유, AC-1·6).
 * 필수 입력(관찰 메모 등)과 점수 계산은 Provider가 한다.
 * @group CMN-00-UX-009
 */
public with sharing class CMN_ChecklistController {
  private static final Integer MAX_ANSWERS = 2000;
  private static final Pattern CLASS_PATTERN = Pattern.compile(
    '^[A-Za-z][A-Za-z0-9_]{0,79}$'
  );
  /** 테스트에서 등록 메타데이터 대신 쓰는 값(객체 → Provider 클래스) */
  @TestVisible
  private static Map<String, String> registryOverride;

  /**
   * @description 수행 시트.
   * @param recordId 업무 레코드 Id
   * @return 시트
   * @throws AuraHandledException Provider 미등록·권한 없음(라벨 문구)
   */
  @AuraEnabled
  public static CMN_Checklist.Sheet load(Id recordId) {
    try {
      return provider(recordId).load(recordId);
    } catch (Exception e) {
      throw toAura(e, 'load', recordId);
    }
  }

  /**
   * @description 답 저장(중간·제출).
   * @param recordId 업무 레코드 Id
   * @param answersJson CMN_Checklist.Answer 목록 JSON
   * @param isFinal 제출 여부
   * @return 저장 결과(질문 키별 오류)
   * @throws AuraHandledException 요청 형식·설정 오류(라벨 문구)
   */
  @AuraEnabled
  public static CMN_Checklist.SaveResult saveAnswers(
    Id recordId,
    String answersJson,
    Boolean isFinal
  ) {
    try {
      CMN_ChecklistProvider p = provider(recordId);
      List<CMN_Checklist.Answer> answers = parse(answersJson);
      CMN_Checklist.Sheet sheet = p.load(recordId);
      CMN_Checklist.SaveResult result = new CMN_Checklist.SaveResult();
      if (sheet?.editable != true) {
        result.errors.add(
          CMN_Checklist.issue(null, Label.CMN_Checklist_NotEditable)
        );
        return result;
      }
      result.errors.addAll(formatIssues(sheet, answers));
      if (!result.errors.isEmpty()) {
        return result;
      }
      return p.saveAnswers(recordId, answers, isFinal == true);
    } catch (Exception e) {
      throw toAura(e, 'saveAnswers', recordId);
    }
  }

  /**
   * @description 점수 미리보기(Provider 계산). 점수 비공개 시트면 null.
   * @param recordId 업무 레코드 Id
   * @return 미리보기 또는 null
   * @throws AuraHandledException 설정 오류(라벨 문구)
   */
  @AuraEnabled
  public static CMN_Checklist.ScorePreview preview(Id recordId) {
    try {
      CMN_ChecklistProvider p = provider(recordId);
      return p.load(recordId)?.scoreVisible == true
        ? p.preview(recordId)
        : null;
    } catch (Exception e) {
      throw toAura(e, 'preview', recordId);
    }
  }

  /**
   * @description 질문의 후속 조치를 만든다(BR-5).
   * @param recordId 업무 레코드 Id
   * @param questionKey 질문 키
   * @param inputJson CMN_Checklist.FollowUpInput JSON
   * @return 만든 레코드 Id
   * @throws AuraHandledException 편집 불가·형식 오류·필수 누락(라벨 문구)
   */
  @AuraEnabled
  public static Id raiseFollowUp(
    Id recordId,
    String questionKey,
    String inputJson
  ) {
    try {
      CMN_ChecklistProvider p = provider(recordId);
      CMN_Checklist.Sheet sheet = p.load(recordId);
      if (sheet?.editable != true) {
        throw new CMN_ValidationException(Label.CMN_Checklist_NotEditable);
      }
      if (!questions(sheet).containsKey(questionKey)) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      CMN_Checklist.FollowUpInput input;
      try {
        input = (CMN_Checklist.FollowUpInput) JSON.deserialize(
          inputJson,
          CMN_Checklist.FollowUpInput.class
        );
      } catch (Exception e) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      return p.raiseFollowUp(recordId, questionKey, input);
    } catch (Exception e) {
      throw toAura(e, 'raiseFollowUp', recordId);
    }
  }

  // ------------------------------------------------------------------ 내부
  private static CMN_ChecklistProvider provider(Id recordId) {
    if (recordId == null) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    String objectName = recordId.getSObjectType()
      .getDescribe(SObjectDescribeOptions.DEFERRED)
      .getName();
    String className;
    if (registryOverride != null) {
      className = registryOverride.get(objectName);
    } else {
      for (CMN_ChecklistProvider__mdt r : [
        SELECT ProviderClass__c
        FROM CMN_ChecklistProvider__mdt
        WHERE ObjectApiName__c = :objectName AND IsActive__c = TRUE
        WITH SYSTEM_MODE
        LIMIT 1
      ]) {
        className = r.ProviderClass__c;
      }
    }
    if (String.isBlank(className)) {
      throw new CMN_ValidationException(Label.CMN_Checklist_NoProvider);
    }
    Object instance;
    try {
      instance = CLASS_PATTERN.matcher(className).matches()
        ? Type.forName(className)?.newInstance()
        : null;
    } catch (Exception e) {
      instance = null;
    }
    if (!(instance instanceof CMN_ChecklistProvider)) {
      CMN_Logger.error(
        'CMN_ChecklistController',
        'provider ' + objectName + ': ' + className,
        recordId
      );
      throw new CMN_ValidationException(Label.CMN_Checklist_NoProvider);
    }
    return (CMN_ChecklistProvider) instance;
  }

  private static List<CMN_Checklist.Answer> parse(String answersJson) {
    List<CMN_Checklist.Answer> answers;
    try {
      answers = String.isBlank(answersJson)
        ? new List<CMN_Checklist.Answer>()
        : (List<CMN_Checklist.Answer>) JSON.deserialize(
            answersJson,
            List<CMN_Checklist.Answer>.class
          );
    } catch (Exception e) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    if (answers == null || answers.size() > MAX_ANSWERS) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    return answers;
  }

  private static Map<String, CMN_Checklist.Question> questions(
    CMN_Checklist.Sheet sheet
  ) {
    Map<String, CMN_Checklist.Question> out = new Map<String, CMN_Checklist.Question>();
    for (
      CMN_Checklist.Question q : sheet?.questions ??
        new List<CMN_Checklist.Question>()
    ) {
      out.put(q.key, q);
    }
    return out;
  }

  /** 답 유형별 형식(AC-1 허용 점수, AC-6 NA 허용·사유). 없는 질문 키는 요청 오류. */
  private static List<CMN_Checklist.Issue> formatIssues(
    CMN_Checklist.Sheet sheet,
    List<CMN_Checklist.Answer> answers
  ) {
    Map<String, CMN_Checklist.Question> byKey = questions(sheet);
    List<CMN_Checklist.Issue> out = new List<CMN_Checklist.Issue>();
    for (CMN_Checklist.Answer a : answers) {
      CMN_Checklist.Question q = a == null ? null : byKey.get(a.questionKey);
      if (q == null) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      String message = formatIssue(q, a);
      if (message != null) {
        out.add(CMN_Checklist.issue(q.key, message));
      }
    }
    return out;
  }

  private static String formatIssue(
    CMN_Checklist.Question q,
    CMN_Checklist.Answer a
  ) {
    if (a.isNa == true) {
      if (q.allowNa != true) {
        return Label.CMN_Checklist_NaNotAllowed;
      }
      return String.isBlank(a.naReason)
        ? Label.CMN_Checklist_NaReasonRequired
        : null;
    }
    if (q.answerType == CMN_Checklist.TYPE_SCORE_STEPS && a.points != null) {
      return containsScore(q.allowedScores, a.points)
        ? null
        : Label.CMN_Checklist_ScoreNotAllowed;
    }
    if (q.answerType == CMN_Checklist.TYPE_POINTS && a.points != null) {
      Boolean inRange =
        a.points >= 0 && (q.maxPoints == null || a.points <= q.maxPoints);
      return inRange
        ? null
        : String.format(
            Label.CMN_Checklist_PointsRange,
            new List<Object>{ q.maxPoints }
          );
    }
    Boolean badChoice =
      (a.compliance != null &&
      a.compliance != CMN_Checklist.COMPLIANT &&
      a.compliance != CMN_Checklist.NONCOMPLIANT) ||
      (a.yesNo != null &&
      a.yesNo != CMN_Checklist.VALUE_YES &&
      a.yesNo != CMN_Checklist.VALUE_NO);
    Boolean negative =
      (a.sampleQty ?? 0) < 0 ||
      (a.defectA ?? 0) < 0 ||
      (a.defectB ?? 0) < 0 ||
      (a.defectC ?? 0) < 0;
    return badChoice || negative ? Label.CMN_Checklist_InvalidAnswer : null;
  }

  private static Boolean containsScore(List<Decimal> allowed, Decimal points) {
    for (Decimal s : allowed ?? new List<Decimal>()) {
      if (s != null && s - points == 0) {
        return true;
      }
    }
    return false;
  }

  /** 검증 예외는 라벨 문구 그대로, 그 밖의 예외는 원문을 로그에 남기고 일반 문구로 바꾼다. */
  private static AuraHandledException toAura(
    Exception e,
    String method,
    Id recordId
  ) {
    String message = e.getMessage();
    if (!(e instanceof CMN_ValidationException)) {
      CMN_Logger.error(
        'CMN_ChecklistController.' + method,
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
