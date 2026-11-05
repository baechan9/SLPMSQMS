/**
 * @description 체크리스트 수행 화면(CMN-00-UX-009): 허용 점수(AC-1), Provider 관찰 메모 필수(AC-2), 기본 후속 조치(AC-3),
 * 점수 미리보기·미답(AC-4), NA 허용·사유(AC-6), 편집 불가, 입력 형식·등록 오류. 샘플 Provider(CMN_TestChecklistProvider)를 쓴다.
 * 화면 동작(서버 호출 없는 이동·내 분담·임시 저장·전송 대기)은 Jest에서 확인한다.
 * @group CMN-00-UX-009
 */
@IsTest
private class CMN_ChecklistController_Test {
  @TestSetup
  static void setup() {
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User owner = CMN_TestDataFactory.newUser(
      'chkown',
      'Check Owner',
      profileId
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert owner;
      insert new PermissionSetAssignment(
        AssigneeId = owner.Id,
        PermissionSetId = [
          SELECT Id
          FROM PermissionSet
          WHERE Name = 'CMN_PS_DataMigration'
        ]
        .Id
      );
    }
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    insert new CMN_Plant__c(
      Name = 'KR01',
      PlantCode__c = 'KR01',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
  }

  @IsTest
  static void test_AC01_onlyAllowedScoresAreAccepted() {
    Id rec = record('IN_PROGRESS');
    System.runAs(user()) {
      // Given: 점수 단계 0·4·6·8·10
      CMN_Checklist.Sheet s = CMN_ChecklistController.load(rec);
      Assert.areEqual(6, s.questions.size());
      Assert.areEqual(5, s.questions[0].allowedScores.size());
      Assert.areEqual(2, s.sections.size());
      // When: 5점 → Then 거부, 6점 → 저장
      CMN_Checklist.SaveResult bad = save(
        rec,
        new List<Object>{ points('Q1', 5) },
        false
      );
      Assert.isFalse(bad.success);
      Assert.areEqual(
        Label.CMN_Checklist_ScoreNotAllowed,
        bad.errors[0].message
      );
      Assert.areEqual('Q1', bad.errors[0].questionKey);
      Assert.isTrue(
        save(rec, new List<Object>{ points('Q1', 6) }, false).success
      );
      // 배점형 범위
      CMN_Checklist.SaveResult range = save(
        rec,
        new List<Object>{ points('Q2', 6) },
        false
      );
      Assert.areEqual(
        String.format(Label.CMN_Checklist_PointsRange, new List<Object>{ 5 }),
        range.errors[0].message
      );
    }
  }

  @IsTest
  static void test_AC02_providerRequiresNoteOnFinalSave() {
    Id rec = record('IN_PROGRESS');
    System.runAs(user()) {
      // Given: 4점·관찰 없음(중간 저장은 허용)
      Assert.isTrue(
        save(rec, new List<Object>{ points('Q1', 4) }, false).success
      );
      // When: 제출
      CMN_Checklist.SaveResult r = save(
        rec,
        new List<Object>{ points('Q1', 4) },
        true
      );
      // Then: Q1 오류, 저장 안 됨(중간 저장분 그대로)
      Assert.isFalse(r.success);
      Assert.areEqual('Q1', r.errors[0].questionKey);
      Assert.areEqual(
        Label.CMN_Checklist_SampleNoteRequired,
        r.errors[0].message
      );
      // 관찰만 있고 후속 조치·사유 없음 → 다음 규칙
      Map<String, Object> withNote = points('Q1', 4);
      withNote.put('notes', 'Revision missing');
      CMN_Checklist.SaveResult r2 = save(
        rec,
        new List<Object>{ withNote },
        true
      );
      Assert.areEqual(
        Label.CMN_Checklist_SampleFollowUpRequired,
        r2.errors[0].message
      );
      // 사유를 적으면 제출된다
      withNote.put('noFollowUpReason', 'Fixed on the spot');
      Assert.isTrue(save(rec, new List<Object>{ withNote }, true).success);
    }
    String stored = [
      SELECT ChecklistJson__c
      FROM CMN_TestRecord__c
      WHERE Id = :rec
    ]
    .ChecklistJson__c;
    Assert.isTrue(stored.contains('Fixed on the spot'));
  }

  @IsTest
  static void test_AC03_defaultFollowUpCreatesActionItem() {
    Id rec = record('IN_PROGRESS');
    Id followUp;
    System.runAs(user()) {
      // When
      followUp = CMN_ChecklistController.raiseFollowUp(
        rec,
        'Q1',
        JSON.serialize(
          new Map<String, Object>{
            'title' => 'Post the latest work standard',
            'description' => 'Rev 3 missing on line 2',
            'dueDate' => String.valueOf(Date.today().addDays(7)),
            'severity' => 'HIGH'
          }
        )
      );
      // 제목·기한 없으면 거부, 없는 질문 키도 거부
      expectFollowUpError(
        rec,
        'Q1',
        '{}',
        Label.CMN_Checklist_FollowUpTitleRequired
      );
      expectFollowUpError(rec, 'NOPE', '{}', Label.CMN_Common_InvalidInput);
      expectFollowUpError(rec, 'Q1', '{broken', Label.CMN_Common_InvalidInput);
    }
    // Then: 조치 항목 1건(원천 레코드·질문 키·공장·담당 = 현재 사용자)
    CMN_ActionItem__c a = [
      SELECT
        Name,
        SourceRecordId__c,
        SourceKey__c,
        Plant__c,
        Owner__c,
        Status__c
      FROM CMN_ActionItem__c
      WHERE Id = :followUp
    ];
    Assert.areEqual(String.valueOf(rec), a.SourceRecordId__c);
    Assert.areEqual('Q1', a.SourceKey__c);
    Assert.areEqual(user().Id, a.Owner__c);
    Assert.areEqual('OPEN', a.Status__c);
    Assert.areEqual(
      [SELECT Plant__c FROM CMN_TestRecord__c WHERE Id = :rec].Plant__c,
      a.Plant__c
    );
  }

  @IsTest
  static void test_AC04_previewShowsProviderScoreAndUnanswered() {
    Id rec = record('IN_PROGRESS');
    System.runAs(user()) {
      // Given: 6문항 중 3문항 답(별표 Q1 = 4점), 1문항 NA
      Map<String, Object> q2na = new Map<String, Object>{
        'questionKey' => 'Q2',
        'isNa' => true,
        'naReason' => 'No equipment'
      };
      save(
        rec,
        new List<Object>{
          points('Q1', 4),
          q2na,
          new Map<String, Object>{
            'questionKey' => 'Q3',
            'compliance' => 'COMPLIANT'
          },
          new Map<String, Object>{
            'questionKey' => 'Q5',
            'sampleQty' => 4,
            'defectA' => 0,
            'defectB' => 1,
            'defectC' => 2
          }
        },
        false
      );
      // When
      CMN_Checklist.ScorePreview p = CMN_ChecklistController.preview(rec);
      // Then: 미답 2(Q4·Q6), 평균 (0.4 + 1 + 0.75) / 3 = 71.7%, C 등급(강등 사유는 별표 4점)
      Assert.areEqual(2, p.unansweredCount);
      Assert.areEqual(71.7, p.percent);
      Assert.areEqual('C', p.gradeBeforeDowngrade);
      Assert.areEqual('C', p.grade);
      Assert.areEqual(
        Label.CMN_Checklist_SampleDowngrade,
        p.downgradeReasons[0]
      );
      Assert.areEqual(2, p.sectionPercents.size());
      Assert.areEqual(70.0, p.sectionPercents[0].percent);
      // 별표 10점이면 강등 없이 B
      save(
        rec,
        new List<Object>{
          points('Q1', 10),
          new Map<String, Object>{ 'questionKey' => 'Q4', 'yesNo' => 'NO' }
        },
        false
      );
      CMN_Checklist.ScorePreview p2 = CMN_ChecklistController.preview(rec);
      Assert.isTrue(p2.downgradeReasons.isEmpty());
      Assert.areEqual(p2.gradeBeforeDowngrade, p2.grade);
    }
  }

  @IsTest
  static void test_AC06_naNeedsPermissionAndReason() {
    Id rec = record('IN_PROGRESS');
    System.runAs(user()) {
      CMN_Checklist.SaveResult notAllowed = save(
        rec,
        new List<Object>{
          new Map<String, Object>{
            'questionKey' => 'Q1',
            'isNa' => true,
            'naReason' => 'x'
          }
        },
        false
      );
      Assert.areEqual(
        Label.CMN_Checklist_NaNotAllowed,
        notAllowed.errors[0].message
      );
      CMN_Checklist.SaveResult noReason = save(
        rec,
        new List<Object>{
          new Map<String, Object>{ 'questionKey' => 'Q6', 'isNa' => true }
        },
        false
      );
      Assert.areEqual(
        Label.CMN_Checklist_NaReasonRequired,
        noReason.errors[0].message
      );
      Assert.isTrue(
        save(
            rec,
            new List<Object>{
              new Map<String, Object>{
                'questionKey' => 'Q6',
                'isNa' => true,
                'naReason' => 'Not in scope'
              }
            },
            false
          )
          .success
      );
    }
  }

  @IsTest
  static void test_readOnlyAndInvalidInputs() {
    Id done = record('DONE');
    Id rec = record('IN_PROGRESS');
    Id plant = [SELECT Id FROM CMN_Plant__c LIMIT 1].Id;
    System.runAs(user()) {
      // 편집 불가: 읽기 전용, 저장·후속 조치 거부
      Assert.isFalse(CMN_ChecklistController.load(done).editable);
      Assert.areEqual(
        Label.CMN_Checklist_NotEditable,
        save(done, new List<Object>{ points('Q1', 6) }, false).errors[0].message
      );
      expectFollowUpError(done, 'Q1', '{}', Label.CMN_Checklist_NotEditable);
      // 형식 오류: 잘못된 선택값·음수 결함·없는 질문·깨진 JSON
      Assert.areEqual(
        Label.CMN_Checklist_InvalidAnswer,
        save(
            rec,
            new List<Object>{
              new Map<String, Object>{
                'questionKey' => 'Q3',
                'compliance' => 'MAYBE'
              }
            },
            false
          )
          .errors[0]
          .message
      );
      Assert.areEqual(
        Label.CMN_Checklist_InvalidAnswer,
        save(
            rec,
            new List<Object>{
              new Map<String, Object>{
                'questionKey' => 'Q5',
                'sampleQty' => 3,
                'defectA' => -1
              }
            },
            false
          )
          .errors[0]
          .message
      );
      for (
        String bad : new List<String>{ '[{"questionKey":"NOPE"}]', '{broken' }
      ) {
        try {
          CMN_ChecklistController.saveAnswers(rec, bad, false);
          Assert.fail('거부: ' + bad);
        } catch (AuraHandledException e) {
          Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
        }
      }
      // 등록 없는 객체·레코드 없음
      expectLoadError(plant, Label.CMN_Checklist_NoProvider);
      expectLoadError(null, Label.CMN_Common_InvalidInput);
    }
    // 설정 오류
    for (
      String cls : new List<String>{ 'CMN_Checklist', 'No_Such_Class', '../x' }
    ) {
      CMN_ChecklistController.registryOverride = new Map<String, String>{
        'CMN_TestRecord__c' => cls
      };
      System.runAs(user()) {
        expectLoadError(rec, Label.CMN_Checklist_NoProvider);
      }
    }
    // 레코드를 읽을 수 없으면 예상하지 못한 오류(원문 숨김)
    CMN_ChecklistController.registryOverride = null;
    Id ownerId = user().Id;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      delete [
        SELECT Id
        FROM PermissionSetAssignment
        WHERE
          AssigneeId = :ownerId
          AND PermissionSet.Name = 'CMN_PS_DataMigration'
      ];
    }
    System.runAs(user()) {
      expectLoadError(rec, Label.CMN_Common_UnexpectedError);
      try {
        CMN_ChecklistController.preview(rec);
        Assert.fail('예외');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_UnexpectedError, e.getMessage());
      }
    }
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_Checklist.SaveResult save(
    Id rec,
    List<Object> answers,
    Boolean isFinal
  ) {
    return CMN_ChecklistController.saveAnswers(
      rec,
      JSON.serialize(answers),
      isFinal
    );
  }

  private static Map<String, Object> points(String key, Decimal value) {
    return new Map<String, Object>{ 'questionKey' => key, 'points' => value };
  }

  private static void expectFollowUpError(
    Id rec,
    String key,
    String body,
    String message
  ) {
    try {
      CMN_ChecklistController.raiseFollowUp(rec, key, body);
      Assert.fail('거부');
    } catch (AuraHandledException e) {
      Assert.areEqual(message, e.getMessage());
    }
  }

  private static void expectLoadError(Id rec, String message) {
    try {
      CMN_ChecklistController.load(rec);
      Assert.fail('거부');
    } catch (AuraHandledException e) {
      Assert.areEqual(message, e.getMessage());
    }
  }

  private static Id record(String status) {
    CMN_TestRecord__c r = new CMN_TestRecord__c(
      Name = 'Checklist ' + status,
      Plant__c = [SELECT Id FROM CMN_Plant__c LIMIT 1]
      .Id,
      Status__c = status,
      OwnerId = user().Id
    );
    insert r;
    return r.Id;
  }

  private static User user() {
    return [
      SELECT Id
      FROM User
      WHERE Alias = 'chkown' AND Username LIKE '%@test.slqms.example.com'
      LIMIT 1
    ];
  }
}
