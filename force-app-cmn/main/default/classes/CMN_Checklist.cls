/**
 * @description 체크리스트 수행 화면 계약 DTO(CMN-00-UX-009). Provider·컨트롤러·LWC가 같은 모양을 쓴다.
 * 점수 계산 로직은 두지 않는다(Provider 소유).
 * @group CMN-00-UX-009
 */
public with sharing class CMN_Checklist {
  public static final String TYPE_SCORE_STEPS = 'SCORE_STEPS';
  public static final String TYPE_POINTS = 'POINTS';
  public static final String TYPE_COMPLIANCE = 'COMPLIANCE';
  public static final String TYPE_YES_NO = 'YES_NO';
  public static final String TYPE_DEFECT_CLASS = 'DEFECT_CLASS';
  public static final String TYPE_TEXT = 'TEXT';
  public static final String COMPLIANT = 'COMPLIANT';
  public static final String NONCOMPLIANT = 'NONCOMPLIANT';
  public static final String VALUE_YES = 'YES';
  public static final String VALUE_NO = 'NO';

  /** @description 수행 시트. */
  public class Sheet {
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String recordNo;
    /** 대상 정보(협력사·공정 등) 한 줄 */
    @AuraEnabled
    public String subtitle;
    @AuraEnabled
    public List<Section> sections = new List<Section>();
    @AuraEnabled
    public List<Question> questions = new List<Question>();
    @AuraEnabled
    public List<Answer> answers = new List<Answer>();
    @AuraEnabled
    public Boolean editable = false;
    /** 피심사 측 등 점수를 보이지 않을 때 false */
    @AuraEnabled
    public Boolean scoreVisible = true;
    /** 사진 문서 분류 코드(DOC_CLASS) */
    @AuraEnabled
    public String photoDocClass;
  }

  /** @description 요소(질문 묶음). */
  public class Section {
    @AuraEnabled
    public String key;
    @AuraEnabled
    public String label;
  }

  /** @description 질문. */
  public class Question {
    @AuraEnabled
    public String key;
    @AuraEnabled
    public String sectionKey;
    @AuraEnabled
    public String no;
    /** 사용자 언어 문구(라이선스 문구는 라이선스 확인 시에만, BR-8) */
    @AuraEnabled
    public String text;
    @AuraEnabled
    public String guidance;
    @AuraEnabled
    public Boolean isStar = false;
    /** SCORE_STEPS, POINTS, COMPLIANCE, YES_NO, DEFECT_CLASS, TEXT */
    @AuraEnabled
    public String answerType;
    @AuraEnabled
    public List<Decimal> allowedScores = new List<Decimal>();
    @AuraEnabled
    public Decimal maxPoints;
    @AuraEnabled
    public Boolean allowNa = false;
    /** 이 점수 이하(또는 부적합)면 관찰 메모 필수 — 화면 안내용, 판단은 Provider */
    @AuraEnabled
    public Decimal noteRequiredAtOrBelow;
    @AuraEnabled
    public Id assignedToId;
  }

  /** @description 답. */
  public class Answer {
    @AuraEnabled
    public String questionKey;
    @AuraEnabled
    public Decimal points;
    /** COMPLIANT, NONCOMPLIANT */
    @AuraEnabled
    public String compliance;
    /** YES, NO */
    @AuraEnabled
    public String yesNo;
    @AuraEnabled
    public Integer sampleQty;
    @AuraEnabled
    public Integer defectA;
    @AuraEnabled
    public Integer defectB;
    @AuraEnabled
    public Integer defectC;
    @AuraEnabled
    public String text;
    @AuraEnabled
    public Boolean isNa = false;
    @AuraEnabled
    public String naReason;
    @AuraEnabled
    public String notes;
    @AuraEnabled
    public List<Id> photoIds = new List<Id>();
    @AuraEnabled
    public Id followUpId;
    /** 후속 조치를 만들지 않는 사유(IAU-003 BR-2와 같은 규칙) */
    @AuraEnabled
    public String noFollowUpReason;
  }

  /** @description 점수 미리보기. */
  public class ScorePreview {
    @AuraEnabled
    public Decimal percent;
    @AuraEnabled
    public String grade;
    @AuraEnabled
    public String gradeBeforeDowngrade;
    @AuraEnabled
    public List<String> downgradeReasons = new List<String>();
    @AuraEnabled
    public List<SectionScore> sectionPercents = new List<SectionScore>();
    @AuraEnabled
    public Integer unansweredCount = 0;
  }

  /** @description 요소별 달성률. */
  public class SectionScore {
    @AuraEnabled
    public String key;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Decimal percent;
  }

  /** @description 저장 결과. */
  public class SaveResult {
    @AuraEnabled
    public Boolean success = false;
    @AuraEnabled
    public List<Issue> errors = new List<Issue>();
  }

  /** @description 질문별 오류(questionKey가 비면 전체). */
  public class Issue {
    @AuraEnabled
    public String questionKey;
    @AuraEnabled
    public String message;
  }

  /** @description 후속 조치 입력. */
  public class FollowUpInput {
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public Id ownerId;
    @AuraEnabled
    public Date dueDate;
    /** HIGH, MEDIUM, LOW */
    @AuraEnabled
    public String severity;
  }

  /**
   * @description 오류 하나.
   * @param questionKey 질문 키(없으면 전체)
   * @param message 화면 문구
   * @return 오류
   */
  public static Issue issue(String questionKey, String message) {
    Issue i = new Issue();
    i.questionKey = questionKey;
    i.message = message;
    return i;
  }
}
