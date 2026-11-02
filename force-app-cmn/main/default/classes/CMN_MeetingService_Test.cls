/**
 * @description 회의 관리 검증(CMN-00-MTG-001).
 * @group CMN-00-MTG-001
 */
@IsTest
private class CMN_MeetingService_Test {
  @TestSetup
  static void setup() {
    CMN_CodeGroup__c g = new CMN_CodeGroup__c(
      Name = 'MEETING_TYPE',
      GroupCode__c = 'MEETING_TYPE',
      MaxLevel__c = 1
    );
    insert g;
    insert new CMN_Code__c(
      CodeGroup__c = g.Id,
      Code__c = 'QUALITY_MEETING',
      Name = 'Quality',
      IsActive__c = true
    );
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    List<User> users = new List<User>();
    for (String a : new List<String>{ 'mtg1', 'mtg2', 'mtg3' }) {
      users.add(CMN_TestDataFactory.newUser(a, a, profileId));
    }
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert users;
      Id ps = [SELECT Id FROM PermissionSet WHERE Name = 'CMN_PS_Meeting_User']
      .Id;
      List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
      for (User u : users) {
        psa.add(
          new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps)
        );
      }
      insert psa;
    }
  }

  @IsTest
  static void test_AC01_confirmOpensTodoPerActionOwner() {
    // Given: 개최된 회의, 참석자·조치 항목 3건(담당 3명)
    CMN_Meeting__c m = meeting('HELD', false);
    insert m;
    attend(m.Id);
    List<CMN_ActionItem__c> actions = new List<CMN_ActionItem__c>();
    for (User u : users()) {
      actions.add(
        new CMN_ActionItem__c(
          Name = 'fix ' + u.Id,
          Meeting__c = m.Id,
          Owner__c = u.Id,
          DueDate__c = Date.today().addDays(7)
        )
      );
    }
    insert actions;
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM CMN_Todo__c],
      '확정 전에는 To-Do 없음'
    );

    // When: 회의록 확정
    Integer opened = CMN_MeetingController.confirmMinutes(m.Id);

    // Then: 3명에게 To-Do 각 1건, 참석자 회의록 알림
    Assert.areEqual(3, opened);
    for (User u : users()) {
      Assert.areEqual(
        1,
        [
          SELECT COUNT()
          FROM CMN_Todo__c
          WHERE Assignee__c = :u.Id AND SourceType__c = 'CMN_ACTION_ITEM'
        ]
      );
    }
    Assert.areEqual(1, messages(CMN_MeetingService.MINUTES_EVENT).size());
    Assert.areEqual(
      'MINUTES_CONFIRMED',
      [SELECT Status__c FROM CMN_Meeting__c WHERE Id = :m.Id].Status__c
    );
  }

  @IsTest
  static void test_AC02_confirmedMinutesCannotChange() {
    // Given: 확정된 회의(이관 적재)
    CMN_TriggerHandler.permissionsOverride = new Set<String>{
      CMN_TriggerHandler.MIGRATION_PERMISSION
    };
    CMN_Meeting__c m = meeting('MINUTES_CONFIRMED', false);
    m.Minutes__c = '<p>final</p>';
    insert m;
    CMN_TriggerHandler.permissionsOverride = null;

    // When / Then: 회의록 수정 차단
    Database.SaveResult r = Database.update(
      new CMN_Meeting__c(Id = m.Id, Minutes__c = '<p>changed</p>'),
      false
    );
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      Label.CMN_Meeting_MinutesLocked,
      r.getErrors()[0].getMessage()
    );
  }

  @IsTest
  static void test_BR2_confirmOnlyByServiceAndOnlyFromHeld() {
    // 직접 확정 상태로 저장 불가, 예정 회의는 확정 불가
    Database.SaveResult r = Database.insert(
      meeting('MINUTES_CONFIRMED', false),
      false
    );
    Assert.areEqual(
      Label.CMN_Meeting_ConfirmOnlyByService,
      r.getErrors()[0].getMessage()
    );
    CMN_Meeting__c m = meeting('SCHEDULED', false);
    insert m;
    try {
      CMN_MeetingController.confirmMinutes(m.Id);
      Assert.fail('예정 회의');
    } catch (AuraHandledException e) {
      Assert.areEqual(Label.CMN_Meeting_CannotConfirm, e.getMessage());
    }
    // 시간·유형 오류
    CMN_Meeting__c bad = meeting('SCHEDULED', false);
    bad.EndAt__c = bad.StartAt__c.addMinutes(-1);
    Assert.areEqual(
      Label.CMN_Meeting_InvalidPeriod,
      Database.insert(bad, false).getErrors()[0].getMessage()
    );
  }

  @IsTest
  static void test_BR1_scheduledMeetingInvitesAttendees() {
    // Given: 예정 회의와 참석자 3명 + 외부 1명
    CMN_Meeting__c m = meeting('SCHEDULED', false);
    insert m;
    Test.startTest();
    attend(m.Id);
    insert new CMN_MeetingAttendee__c(
      Meeting__c = m.Id,
      ExternalEmail__c = 'guest@example.com',
      Role__c = 'OPTIONAL'
    );
    Test.stopTest();

    // Then: 벨 알림, 초대 메일(.ics) 4건, 참석자 읽기 공유
    Assert.isFalse(messages(CMN_MeetingService.SCHEDULED_EVENT).isEmpty());
    Assert.areEqual(4, CMN_MeetingInviteJob.prepared);
    Assert.areEqual(
      3,
      [
        SELECT COUNT()
        FROM CMN_Meeting__Share
        WHERE ParentId = :m.Id AND RowCause = 'CMN_Attendee__c'
      ]
    );
    CMN_MeetingAttendee__c a = CMN_MeetingSelector.attendeesById(
      new Set<Id>{ [SELECT Id FROM CMN_MeetingAttendee__c LIMIT 1].Id }
    )[0];
    String ics = CMN_MeetingInviteJob.ics(a);
    Assert.isTrue(ics.contains('UID:' + m.Id + '@slqms'));
    Assert.isTrue(ics.contains('DTSTART:'));
  }

  @IsTest
  static void test_BR4_regularMeetingCreatesNextOnce() {
    // Given: 매주 정기 회의(참석자 3명)
    CMN_Meeting__c m = meeting('SCHEDULED', true);
    insert m;
    attend(m.Id);

    // When: 개최
    update new CMN_Meeting__c(Id = m.Id, Status__c = 'HELD');

    // Then: 다음 회차 1건(+7일, 참석자 복사), 연결
    CMN_Meeting__c cur = [
      SELECT NextMeeting__c, StartAt__c
      FROM CMN_Meeting__c
      WHERE Id = :m.Id
    ];
    Assert.isNotNull(cur.NextMeeting__c);
    CMN_Meeting__c next = [
      SELECT StartAt__c, Status__c, (SELECT Id FROM Attendees__r)
      FROM CMN_Meeting__c
      WHERE Id = :cur.NextMeeting__c
    ];
    Assert.areEqual(cur.StartAt__c.addDays(7), next.StartAt__c);
    Assert.areEqual('SCHEDULED', next.Status__c);
    Assert.areEqual(3, next.Attendees__r.size());
    Assert.areEqual(2, [SELECT COUNT() FROM CMN_Meeting__c]);
  }

  @IsTest
  static void test_BR3_actionItemTodoLifecycleAndDueAlerts() {
    // Given: 회의 밖 조치(저장 즉시 To-Do), 기한 내일
    User u1 = users()[0];
    User u2 = users()[1];
    CMN_ActionItem__c a = new CMN_ActionItem__c(
      Name = 'standalone',
      Owner__c = u1.Id,
      DueDate__c = Date.today().addDays(1)
    );
    insert a;
    Assert.areEqual(
      'OPEN',
      [SELECT Status__c FROM CMN_Todo__c WHERE Assignee__c = :u1.Id].Status__c
    );
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM CMN_ActionItem__Share
        WHERE ParentId = :a.Id AND RowCause = 'CMN_Attendee__c'
      ]
    );

    // 담당자 변경 → 이전 담당 취소, 새 담당 To-Do(같은 레코드 갱신은 트랜잭션당 한 번 처리되므로 알림 잡보다 먼저)
    update new CMN_ActionItem__c(Id = a.Id, Owner__c = u2.Id);
    Assert.areEqual(
      'CANCELLED',
      [SELECT Status__c FROM CMN_Todo__c WHERE Assignee__c = :u1.Id].Status__c
    );
    Assert.areEqual(
      'OPEN',
      [SELECT Status__c FROM CMN_Todo__c WHERE Assignee__c = :u2.Id].Status__c
    );
    // 기한 알림: 내일 → DUE, 같은 날 재실행 없음
    CMN_ActionItemReminderJob.todayOverride = Date.today();
    Assert.areEqual(1, CMN_ActionItemReminderJob.run());
    Assert.areEqual(0, CMN_ActionItemReminderJob.run());
    Assert.areEqual(1, messages(CMN_ActionItemReminderJob.DUE_EVENT).size());

    // 다음날 이후 → OVERDUE
    CMN_ActionItemReminderJob.todayOverride = Date.today().addDays(3);
    new CMN_ActionItemReminderJob().execute(null);
    Assert.areEqual(
      1,
      messages(CMN_ActionItemReminderJob.OVERDUE_EVENT).size()
    );

    // 담당자 없음 거절
    Assert.areEqual(
      Label.CMN_Action_OwnerRequired,
      Database.insert(
            new CMN_ActionItem__c(Name = 'x', DueDate__c = Date.today()),
            false
          )
          .getErrors()[0]
        .getMessage()
    );
  }

  @IsTest
  static void test_controller_panelAddAndComplete() {
    // Given: 개최된 회의(실행 사용자 소유)
    CMN_Meeting__c m = meeting('HELD', false);
    insert m;
    User u1 = users()[0];

    // When: 패널에서 조치 추가(확정 전이라 To-Do 없음) → 완료
    Id actionId = CMN_MeetingController.addAction(
      m.Id,
      'check jig',
      u1.Id,
      Date.today().addDays(3)
    );
    CMN_MeetingController.Panel p = CMN_MeetingController.getPanel(m.Id);
    Assert.isTrue(p.canEdit);
    Assert.isTrue(p.canConfirm);
    Assert.areEqual(1, p.actions.size());
    CMN_MeetingController.completeAction(actionId);
    Assert.areEqual(
      'DONE',
      [SELECT Status__c FROM CMN_ActionItem__c WHERE Id = :actionId].Status__c
    );

    // 입력 오류
    try {
      CMN_MeetingController.addAction(m.Id, ' ', u1.Id, Date.today());
      Assert.fail('입력 오류');
    } catch (AuraHandledException e) {
      Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
    }
    // 읽을 수 없는 사용자에게는 빈 패널
    System.runAs(u1) {
      Assert.isFalse(CMN_MeetingController.getPanel(m.Id).canRead);
    }
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_Meeting__c meeting(String status, Boolean weekly) {
    Datetime start = Datetime.now().addDays(1);
    return new CMN_Meeting__c(
      Name = 'Weekly quality',
      Category__c = [
        SELECT Id
        FROM CMN_Code__c
        WHERE Code__c = 'QUALITY_MEETING'
      ]
      .Id,
      IsRegular__c = weekly,
      Recurrence__c = weekly ? 'WEEKLY' : 'NONE',
      StartAt__c = start,
      EndAt__c = start.addHours(1),
      Location__c = 'Room 1',
      Status__c = status
    );
  }

  private static List<User> users() {
    return [SELECT Id FROM User WHERE Alias LIKE 'mtg%' ORDER BY Alias];
  }

  private static void attend(Id meetingId) {
    List<CMN_MeetingAttendee__c> rows = new List<CMN_MeetingAttendee__c>();
    for (User u : users()) {
      rows.add(
        new CMN_MeetingAttendee__c(
          Meeting__c = meetingId,
          User__c = u.Id,
          Role__c = 'REQUIRED'
        )
      );
    }
    insert rows;
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
