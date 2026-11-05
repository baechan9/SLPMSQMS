/**
 * @description 테스트 객체 체크리스트 샘플 Provider(CMN-00-UX-009, 개발 플랜 DEV-3). 업무 Provider(심사·자체 평가·Gate)의 본보기다.
 * 질문지는 SL 자체 예시 문구 6개(답 유형 6종)이고 라이선스 문구를 쓰지 않는다(BR-8).
 * - 답은 레코드 ChecklistJson__c에 JSON 묶음으로 저장
 * - 제출 규칙: 4점 이하·부적합이면 관찰 메모 필수, 그때 후속 조치를 만들지 않으면 사유 필수(IAU-003 BR-2와 같은 모양)
 * - 점수(예시 계산): 질문별 달성 비율 평균, 90% 이상 A·80% 이상 B·그 밖 C, 별표 질문 4점 이하면 한 단계 강등
 * - 편집 가능 = UX-005 COMPONENT 규칙 TestChecklistEdit, 후속 조치 = 기본 구현(조치 항목) + 레코드 공장
 * @group CMN-00-UX-009
 */
public with sharing class CMN_TestChecklistProvider extends CMN_ChecklistDefaultProvider {
  private static final String EDIT_RULE = 'TestChecklistEdit';
  private static final Decimal NOTE_LIMIT = 4;
  private static final List<String> GRADES = new List<String>{ 'A', 'B', 'C' };

  /**
   * @description 수행 시트.
   * @param recordId 테스트 레코드 Id
   * @return 시트
   */
  public override CMN_Checklist.Sheet load(Id recordId) {
    CMN_TestRecord__c r = record(recordId);
    CMN_Checklist.Sheet s = new CMN_Checklist.Sheet();
    s.title = r.Name;
    s.recordNo = r.RecordNo__c;
    s.subtitle = r.Plant__r?.Name;
    s.sections.add(section('S1', Label.CMN_Checklist_SampleSec1));
    s.sections.add(section('S2', Label.CMN_Checklist_SampleSec2));
    s.questions = questions(r.OwnerId);
    s.answers = stored(r.ChecklistJson__c);
    s.editable = CMN_UiRuleService.canExecute(recordId, EDIT_RULE);
    s.scoreVisible = true;
    s.photoDocClass = 'AUDIT_EVIDENCE';
    return s;
  }

  /**
   * @description 답을 합쳐 저장한다. 제출이면 관찰 메모·후속 조치 규칙을 확인한다(오류가 있으면 저장하지 않는다).
   * @param recordId 테스트 레코드 Id
   * @param answers 답
   * @param isFinal 제출 여부
   * @return 저장 결과
   */
  public override CMN_Checklist.SaveResult saveAnswers(
    Id recordId,
    List<CMN_Checklist.Answer> answers,
    Boolean isFinal
  ) {
    CMN_Checklist.SaveResult result = new CMN_Checklist.SaveResult();
    if (!CMN_UiRuleService.canExecute(recordId, EDIT_RULE)) {
      result.errors.add(
        CMN_Checklist.issue(null, Label.CMN_Checklist_NotEditable)
      );
      return result;
    }
    CMN_TestRecord__c r = record(recordId);
    Map<String, CMN_Checklist.Answer> merged = new Map<String, CMN_Checklist.Answer>();
    for (CMN_Checklist.Answer a : stored(r.ChecklistJson__c)) {
      merged.put(a.questionKey, a);
    }
    for (CMN_Checklist.Answer a : answers) {
      merged.put(a.questionKey, a);
    }
    if (isFinal) {
      for (CMN_Checklist.Question q : questions(r.OwnerId)) {
        CMN_Checklist.Answer a = merged.get(q.key);
        if (a == null || a.isNa == true || !needsNote(q, a)) {
          continue;
        }
        if (String.isBlank(a.notes)) {
          result.errors.add(
            CMN_Checklist.issue(q.key, Label.CMN_Checklist_SampleNoteRequired)
          );
        } else if (a.followUpId == null && String.isBlank(a.noFollowUpReason)) {
          result.errors.add(
            CMN_Checklist.issue(
              q.key,
              Label.CMN_Checklist_SampleFollowUpRequired
            )
          );
        }
      }
      if (!result.errors.isEmpty()) {
        return result;
      }
    }
    Database.update(
      new CMN_TestRecord__c(
        Id = recordId,
        ChecklistJson__c = JSON.serialize(merged.values())
      ),
      AccessLevel.USER_MODE
    );
    result.success = true;
    return result;
  }

  /**
   * @description 예시 점수 계산(질문별 달성 비율 평균, 별표 강등).
   * @param recordId 테스트 레코드 Id
   * @return 미리보기
   */
  public override CMN_Checklist.ScorePreview preview(Id recordId) {
    CMN_TestRecord__c r = record(recordId);
    Map<String, CMN_Checklist.Answer> byKey = new Map<String, CMN_Checklist.Answer>();
    for (CMN_Checklist.Answer a : stored(r.ChecklistJson__c)) {
      byKey.put(a.questionKey, a);
    }
    CMN_Checklist.ScorePreview p = new CMN_Checklist.ScorePreview();
    Map<String, List<Decimal>> bySection = new Map<String, List<Decimal>>();
    List<Decimal> all = new List<Decimal>();
    Boolean starLow = false;
    for (CMN_Checklist.Question q : questions(r.OwnerId)) {
      CMN_Checklist.Answer a = byKey.get(q.key);
      if (a == null || (a.isNa != true && !answered(q, a))) {
        p.unansweredCount++;
        continue;
      }
      Decimal ratio = a.isNa == true ? null : ratio(q, a);
      if (ratio == null) {
        continue;
      }
      all.add(ratio);
      if (!bySection.containsKey(q.sectionKey)) {
        bySection.put(q.sectionKey, new List<Decimal>());
      }
      bySection.get(q.sectionKey).add(ratio);
      starLow =
        starLow || (q.isStar && a.points != null && a.points <= NOTE_LIMIT);
    }
    p.percent = percent(all);
    p.gradeBeforeDowngrade = grade(p.percent);
    p.grade = p.gradeBeforeDowngrade;
    if (starLow && p.grade != null) {
      p.grade = GRADES[
        Math.min(GRADES.indexOf(p.grade) + 1, GRADES.size() - 1)
      ];
      p.downgradeReasons.add(Label.CMN_Checklist_SampleDowngrade);
    }
    for (CMN_Checklist.Section s : load(recordId).sections) {
      CMN_Checklist.SectionScore score = new CMN_Checklist.SectionScore();
      score.key = s.key;
      score.label = s.label;
      score.percent = percent(bySection.get(s.key));
      p.sectionPercents.add(score);
    }
    return p;
  }

  protected override Id plantOf(Id recordId) {
    return record(recordId).Plant__c;
  }

  // ------------------------------------------------------------------ 내부
  private static Boolean needsNote(
    CMN_Checklist.Question q,
    CMN_Checklist.Answer a
  ) {
    return (q.noteRequiredAtOrBelow != null &&
      a.points != null &&
      a.points <= q.noteRequiredAtOrBelow) ||
      a.compliance == CMN_Checklist.NONCOMPLIANT;
  }

  private static Boolean answered(
    CMN_Checklist.Question q,
    CMN_Checklist.Answer a
  ) {
    switch on q.answerType {
      when 'SCORE_STEPS', 'POINTS' {
        return a.points != null;
      }
      when 'COMPLIANCE' {
        return a.compliance != null;
      }
      when 'YES_NO' {
        return a.yesNo != null;
      }
      when 'DEFECT_CLASS' {
        return a.sampleQty != null;
      }
      when else {
        return String.isNotBlank(a.text);
      }
    }
  }

  /** 질문별 달성 비율(0~1). 서술형은 점수에 넣지 않는다. */
  private static Decimal ratio(
    CMN_Checklist.Question q,
    CMN_Checklist.Answer a
  ) {
    switch on q.answerType {
      when 'SCORE_STEPS' {
        return a.points / 10;
      }
      when 'POINTS' {
        return q.maxPoints > 0 ? a.points / q.maxPoints : null;
      }
      when 'COMPLIANCE' {
        return a.compliance == CMN_Checklist.COMPLIANT ? 1 : 0;
      }
      when 'YES_NO' {
        return a.yesNo == CMN_Checklist.VALUE_YES ? 1 : 0;
      }
      when 'DEFECT_CLASS' {
        if (a.sampleQty == null || a.sampleQty <= 0) {
          return null;
        }
        Decimal weighted =
          (a.defectA ?? 0) +
          (a.defectB ?? 0) * 0.5 +
          (a.defectC ?? 0) * 0.25;
        return Math.max(0, 1 - weighted / a.sampleQty);
      }
      when else {
        return null;
      }
    }
  }

  private static Decimal percent(List<Decimal> ratios) {
    if (ratios == null || ratios.isEmpty()) {
      return null;
    }
    Decimal sum = 0;
    for (Decimal d : ratios) {
      sum += d;
    }
    return (sum / ratios.size() * 100).setScale(1, System.RoundingMode.HALF_UP);
  }

  private static String grade(Decimal pct) {
    if (pct == null) {
      return null;
    }
    return pct >= 90 ? 'A' : (pct >= 80 ? 'B' : 'C');
  }

  private static CMN_TestRecord__c record(Id recordId) {
    return [
      SELECT
        Id,
        Name,
        RecordNo__c,
        OwnerId,
        Plant__c,
        Plant__r.Name,
        ChecklistJson__c
      FROM CMN_TestRecord__c
      WHERE Id = :recordId
      WITH USER_MODE
      LIMIT 1
    ];
  }

  private static List<CMN_Checklist.Answer> stored(String raw) {
    return String.isBlank(raw)
      ? new List<CMN_Checklist.Answer>()
      : (List<CMN_Checklist.Answer>) JSON.deserialize(
          raw,
          List<CMN_Checklist.Answer>.class
        );
  }

  private static CMN_Checklist.Section section(String key, String text) {
    CMN_Checklist.Section s = new CMN_Checklist.Section();
    s.key = key;
    s.label = text;
    return s;
  }

  private static List<CMN_Checklist.Question> questions(Id ownerId) {
    List<CMN_Checklist.Question> out = new List<CMN_Checklist.Question>();
    CMN_Checklist.Question q1 = question(
      'Q1',
      'S1',
      '1.1',
      Label.CMN_Checklist_SampleQ1,
      CMN_Checklist.TYPE_SCORE_STEPS
    );
    q1.allowedScores = new List<Decimal>{ 0, 4, 6, 8, 10 };
    q1.isStar = true;
    q1.noteRequiredAtOrBelow = NOTE_LIMIT;
    q1.guidance = Label.CMN_Checklist_SampleQ1Guide;
    out.add(q1);
    CMN_Checklist.Question q2 = question(
      'Q2',
      'S1',
      '1.2',
      Label.CMN_Checklist_SampleQ2,
      CMN_Checklist.TYPE_POINTS
    );
    q2.maxPoints = 5;
    q2.allowNa = true;
    out.add(q2);
    out.add(
      question(
        'Q3',
        'S1',
        '1.3',
        Label.CMN_Checklist_SampleQ3,
        CMN_Checklist.TYPE_COMPLIANCE
      )
    );
    CMN_Checklist.Question q4 = question(
      'Q4',
      'S2',
      '2.1',
      Label.CMN_Checklist_SampleQ4,
      CMN_Checklist.TYPE_YES_NO
    );
    q4.assignedToId = ownerId;
    out.add(q4);
    out.add(
      question(
        'Q5',
        'S2',
        '2.2',
        Label.CMN_Checklist_SampleQ5,
        CMN_Checklist.TYPE_DEFECT_CLASS
      )
    );
    CMN_Checklist.Question q6 = question(
      'Q6',
      'S2',
      '2.3',
      Label.CMN_Checklist_SampleQ6,
      CMN_Checklist.TYPE_TEXT
    );
    q6.allowNa = true;
    out.add(q6);
    return out;
  }

  private static CMN_Checklist.Question question(
    String key,
    String sectionKey,
    String no,
    String text,
    String answerType
  ) {
    CMN_Checklist.Question q = new CMN_Checklist.Question();
    q.key = key;
    q.sectionKey = sectionKey;
    q.no = no;
    q.text = text;
    q.answerType = answerType;
    return q;
  }
}
