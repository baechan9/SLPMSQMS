/**
 * @description 결재 지연 독촉·에스컬레이션 검증(CMN-00-APV-005). 결재 대상은 테스트 대상 객체(KR01, Asia/Seoul).
 * @group CMN-00-APV-005
 */
@IsTest
private class CMN_ApprovalReminderJob_Test {
  /** KR01 현지 09:00 = 00:00 GMT */
  private static final Datetime NINE_KST = Datetime.newInstanceGmt(
    2026,
    12,
    10,
    0,
    0,
    0
  );

  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    CMN_Plant__c p = new CMN_Plant__c(
      Name = 'KR01',
      PlantCode__c = 'KR01',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
    insert p;
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User mgr = CMN_TestDataFactory.newUser('remmgr', 'remmgr', profileId);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert mgr;
    }
    insert new CMN_Department__c(
      Name = 'Quality',
      DeptCode__c = 'D9200',
      Manager__c = mgr.Id
    );
    User approver = CMN_TestDataFactory.newUser('remapv', 'remapv', profileId);
    approver.DepartmentCode__c = 'D9200';
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert approver;
    }
    insert new CMN_TestRecord__c(
      Name = 'target',
      Plant__c = p.Id,
      Status__c = 'DRAFT'
    );
  }

  @IsTest
  static void test_AC01_reminderOncePerDay() {
    // Given: ReminderDays 기본 2, PENDING 2일째(KR01 현지 날짜 기준)
    Id step = pendingSince(NINE_KST.addDays(-2));

    // When: 공장 09:00 잡 실행
    CMN_ApprovalReminderJob.nowOverride = NINE_KST;
    Integer sent = CMN_ApprovalReminderJob.run();

    // Then: 독촉 1건(결재자), 같은 날 재실행 시 추가 없음
    Assert.areEqual(1, sent);
    List<CMN_NotificationService.Message> reminders = messages(
      CMN_ApprovalReminderJob.REMINDER_EVENT
    );
    Assert.areEqual(1, reminders.size());
    Assert.areEqual(
      new List<Id>{ user('remapv').Id },
      reminders[0].recipientIds
    );
    Assert.areEqual('2', reminders[0].params.get('Days'));
    Assert.areEqual(
      Date.newInstance(2026, 12, 10),
      [SELECT LastReminderOn__c FROM CMN_ApprovalStep__c WHERE Id = :step]
      .LastReminderOn__c
    );
    CMN_ApprovalReminderJob.nowOverride = NINE_KST.addMinutes(30);
    Assert.areEqual(0, CMN_ApprovalReminderJob.run());
  }

  @IsTest
  static void test_BR2_escalationToManagerAndNotBeforeDays() {
    // Given: PENDING 5일째
    pendingSince(NINE_KST.addDays(-5));

    // When
    CMN_ApprovalReminderJob.nowOverride = NINE_KST;
    CMN_ApprovalReminderJob.run();

    // Then: 결재자 독촉 + 부서장 에스컬레이션
    List<CMN_NotificationService.Message> esc = messages(
      CMN_ApprovalReminderJob.ESCALATION_EVENT
    );
    Assert.areEqual(1, esc.size());
    Assert.areEqual(new List<Id>{ user('remmgr').Id }, esc[0].recipientIds);
    Assert.areEqual(1, messages(CMN_ApprovalReminderJob.REMINDER_EVENT).size());
  }

  @IsTest
  static void test_BR1_onlyAtLocalReminderHourAndAfterDays() {
    // Given: PENDING 1일째(독촉 전), 2일째 단계를 현지 10시에 실행
    Id step = pendingSince(NINE_KST.addDays(-1));
    CMN_ApprovalReminderJob.nowOverride = NINE_KST;
    Assert.areEqual(0, CMN_ApprovalReminderJob.run(), '아직 1일째');

    update new CMN_ApprovalStep__c(
      Id = step,
      PendingAt__c = NINE_KST.addDays(-3)
    );
    CMN_ApprovalReminderJob.nowOverride = NINE_KST.addHours(1);
    Assert.areEqual(0, CMN_ApprovalReminderJob.run(), '현지 10시는 처리 안 함');

    // 스케줄 진입점
    CMN_ApprovalReminderJob.nowOverride = NINE_KST;
    new CMN_ApprovalReminderJob().execute(null);
    Assert.areEqual(1, messages(CMN_ApprovalReminderJob.REMINDER_EVENT).size());
  }

  // ------------------------------------------------------------------ 도우미
  /** 결재 상신 후 대기 시작 시각을 바꾼 단계 Id. */
  private static Id pendingSince(Datetime since) {
    Id req = CMN_ApprovalService.submit(
      [SELECT Id FROM CMN_TestRecord__c].Id,
      'CMN_TEST_APPROVE',
      new List<CMN_ApprovalStepSpec>{
        new CMN_ApprovalStepSpec(1, 'APPROVE', user('remapv').Id, null)
      },
      null
    );
    CMN_ApprovalStep__c s = [
      SELECT Id, PendingAt__c
      FROM CMN_ApprovalStep__c
      WHERE Request__c = :req
    ];
    Assert.isNotNull(s.PendingAt__c, '엔진이 대기 시작 시각을 기록');
    update new CMN_ApprovalStep__c(Id = s.Id, PendingAt__c = since);
    return s.Id;
  }

  private static User user(String alias) {
    return [SELECT Id FROM User WHERE Alias = :alias LIMIT 1];
  }

  private static List<CMN_NotificationService.Message> messages(
    String eventCode
  ) {
    List<CMN_NotificationService.Message> out = new List<CMN_NotificationService.Message>();
    for (CMN_NotificationService.Message m : CMN_NotificationService.queued) {
      if (m.eventCode == eventCode) {
        out.add(m);
      }
    }
    return out;
  }
}
