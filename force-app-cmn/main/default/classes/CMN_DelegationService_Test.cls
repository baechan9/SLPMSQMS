/**
 * @description 대리결재 위임 검증(CMN-00-APV-004). 결재 대상은 테스트 대상 객체(CR-11·DEV-3).
 * @group CMN-00-APV-004
 */
@IsTest
private class CMN_DelegationService_Test {
  private static final String TYPE_CODE = 'CMN_TEST_APPROVE';

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
    Map<String, User> users = new Map<String, User>();
    for (String a : new List<String>{ 'dlgmgr', 'dlgb', 'dlgc', 'dlgx' }) {
      users.put(a, CMN_TestDataFactory.newUser(a, a, profileId));
    }
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert users.values();
    }
    insert new CMN_Department__c(
      Name = 'Quality',
      DeptCode__c = 'D9100',
      Manager__c = users.get('dlgmgr').Id
    );
    User a = CMN_TestDataFactory.newUser('dlga', 'dlga', profileId);
    a.DepartmentCode__c = 'D9100';
    a.EmployeeNo__c = 'E9101';
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert a;
      Id ps = [
        SELECT Id
        FROM PermissionSet
        WHERE Name = 'CMN_PS_Delegation_User'
      ]
      .Id;
      List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
      for (User u : [SELECT Id FROM User WHERE Alias LIKE 'dlg%']) {
        psa.add(
          new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps)
        );
      }
      insert psa;
    }
    insert new CMN_TestRecord__c(
      Name = 'target',
      Plant__c = p.Id,
      Status__c = 'DRAFT'
    );
  }

  @IsTest
  static void test_AC01_delegateGetsTodoAndClosesBoth() {
    // Given: A → B 위임(전체 유형, 지금 유효)
    User a = user('dlga');
    User b = user('dlgb');
    delegate(
      a,
      b,
      Datetime.now().addHours(-1),
      Datetime.now().addDays(1),
      null
    );

    // When: A 차례 결재 도래
    Id req = submit(a);
    Test.getEventBus().deliver();

    // Then: A·B 모두 To-Do(B는 대결 표시)
    CMN_Todo__c ta = todoOf(a.Id);
    CMN_Todo__c tb = todoOf(b.Id);
    Assert.areEqual('OPEN', ta.Status__c);
    Assert.areEqual('OPEN', tb.Status__c);
    Assert.isTrue(tb.IsDelegated__c);
    Assert.areEqual(a.Id, tb.DelegatedFrom__c);

    // When: B가 처리 → 대결 기록, A To-Do도 자동 종료
    System.runAs(b) {
      CMN_ApprovalService.approve((Id) tb.SourceRecordId__c, 'ok');
    }
    Test.getEventBus().deliver();
    CMN_ApprovalStep__c step = [
      SELECT ActedBy__c, IsDelegated__c, Status__c
      FROM CMN_ApprovalStep__c
      WHERE Request__c = :req
    ];
    Assert.areEqual(b.Id, step.ActedBy__c);
    Assert.isTrue(step.IsDelegated__c);
    Assert.areEqual('DONE', todoOf(a.Id).Status__c);
    Assert.areEqual('DONE', todoOf(b.Id).Status__c);
  }

  @IsTest
  static void test_AC02_expiredDelegationGivesNoTodo() {
    // Given: 이미 끝난 위임
    User a = user('dlga');
    User b = user('dlgb');
    delegate(
      a,
      b,
      Datetime.now().addDays(-5),
      Datetime.now().addDays(-1),
      null
    );

    // When
    submit(a);
    Test.getEventBus().deliver();

    // Then: B To-Do 없음
    Assert.isNotNull(todoOf(a.Id));
    Assert.isNull(todoOf(b.Id));
  }

  @IsTest
  static void test_AC03_typeScopedDelegationIgnoresOtherTypes() {
    // Given: 4M 승인만 위임
    User a = user('dlga');
    User b = user('dlgb');
    delegate(
      a,
      b,
      Datetime.now().addHours(-1),
      Datetime.now().addDays(1),
      'QMS_4M_APPROVE'
    );

    // When: 다른 유형(테스트 유형) 결재 도래
    Id req = submit(a);
    Test.getEventBus().deliver();

    // Then: B To-Do 없음, B는 처리할 수 없음
    Assert.isNull(todoOf(b.Id));
    System.runAs(b) {
      try {
        CMN_ApprovalService.approve(
          [SELECT Id FROM CMN_ApprovalStep__c WHERE Request__c = :req].Id,
          'x'
        );
        Assert.fail('대리인이 아니다');
      } catch (Exception e) {
        Assert.isNotNull(e.getMessage());
      }
    }
  }

  @IsTest
  static void test_BR2_delegationIsOneLevelOnly() {
    // Given: A → B, B → C
    User a = user('dlga');
    User b = user('dlgb');
    User c = user('dlgc');
    delegate(
      a,
      b,
      Datetime.now().addHours(-1),
      Datetime.now().addDays(1),
      null
    );
    delegate(
      b,
      c,
      Datetime.now().addHours(-1),
      Datetime.now().addDays(1),
      null
    );

    // When: A 결재 도래
    submit(a);
    Test.getEventBus().deliver();

    // Then: B만, C에게는 가지 않는다
    Assert.isNotNull(todoOf(b.Id));
    Assert.isNull(todoOf(c.Id));
  }

  @IsTest
  static void test_BR5_delegationOpensTodoForAlreadyPendingStep() {
    // Given: A 결재가 이미 PENDING
    User a = user('dlga');
    User b = user('dlgb');
    submit(a);
    Test.getEventBus().deliver();
    Assert.isNull(todoOf(b.Id));

    // When: 위임 등록
    delegate(
      a,
      b,
      Datetime.now().addHours(-1),
      Datetime.now().addDays(1),
      null
    );

    // Then: 즉시 B To-Do(대결)
    CMN_Todo__c tb = todoOf(b.Id);
    Assert.areEqual('OPEN', tb.Status__c);
    Assert.isTrue(tb.IsDelegated__c);
  }

  @IsTest
  static void test_BR5_extendingDelegationOpensTodo() {
    // Given: 끝난 위임과 A의 PENDING 결재
    User a = user('dlga');
    User b = user('dlgb');
    delegate(
      a,
      b,
      Datetime.now().addDays(-5),
      Datetime.now().addDays(-1),
      null
    );
    submit(a);
    Test.getEventBus().deliver();
    Assert.isNull(todoOf(b.Id));

    // When: 위임 기간 연장(수정)
    System.runAs(a) {
      CMN_Delegation__c d = [SELECT Id FROM CMN_Delegation__c LIMIT 1];
      update new CMN_Delegation__c(
        Id = d.Id,
        EndAt__c = Datetime.now().addDays(2)
      );
    }

    // Then: 대리인 To-Do
    Assert.isNotNull(todoOf(b.Id));
  }

  @IsTest
  static void test_BR1_registrationRules() {
    User a = user('dlga');
    User b = user('dlgb');
    Datetime s = Datetime.now();
    // 남(dlgx)은 A 위임을 등록할 수 없다
    System.runAs(user('dlgx')) {
      expectError(
        new CMN_Delegation__c(
          Delegator__c = a.Id,
          Delegate__c = b.Id,
          StartAt__c = s,
          EndAt__c = s.addDays(1),
          Reason__c = 'x'
        ),
        Label.CMN_Delegation_NotAllowed
      );
    }
    // 부서장은 등록할 수 있다, 외부 키 = DLG-{사번}-{시작일}
    System.runAs(user('dlgmgr')) {
      CMN_Delegation__c d = new CMN_Delegation__c(
        Delegator__c = a.Id,
        Delegate__c = b.Id,
        StartAt__c = s,
        EndAt__c = s.addDays(1),
        Reason__c = 'trip'
      );
      insert d;
      Assert.isTrue(
        [SELECT ExternalKey__c FROM CMN_Delegation__c WHERE Id = :d.Id]
          .ExternalKey__c.startsWith('DLG-E9101-')
      );
    }
    // 본인에게 위임, 기간 역전
    System.runAs(a) {
      expectError(
        new CMN_Delegation__c(
          Delegate__c = a.Id,
          StartAt__c = s,
          EndAt__c = s.addDays(1),
          Reason__c = 'x'
        ),
        Label.CMN_Delegation_InvalidDelegate
      );
      expectError(
        new CMN_Delegation__c(
          Delegate__c = b.Id,
          StartAt__c = s,
          EndAt__c = s.addDays(-1),
          Reason__c = 'x'
        ),
        Label.CMN_Delegation_InvalidPeriod
      );
    }
  }

  @IsTest
  static void test_BR6_leaveWithPendingApprovalNotifiesManager() {
    // Given: A 결재 대기 1건
    User a = user('dlga');
    submit(a);

    // When: HR 상태 LEAVE
    System.runAs(new User(Id = UserInfo.getUserId())) {
      update new User(Id = a.Id, HrStatus__c = 'LEAVE');
    }

    // Then: 부서장에게 대리인 지정 필요 알림
    CMN_NotificationService.Message found;
    for (CMN_NotificationService.Message m : CMN_NotificationService.queued) {
      if (m.eventCode == CMN_DelegationService.NEEDED_EVENT) {
        found = m;
      }
    }
    Assert.isNotNull(found);
    Assert.areEqual(new List<Id>{ user('dlgmgr').Id }, found.recipientIds);
    Assert.areEqual('1', found.params.get('PendingApprovals'));
  }

  // ------------------------------------------------------------------ 도우미
  private static User user(String alias) {
    return [SELECT Id FROM User WHERE Alias = :alias LIMIT 1];
  }

  private static void delegate(
    User delegator,
    User delegateUser,
    Datetime startAt,
    Datetime endAt,
    String types
  ) {
    System.runAs(delegator) {
      insert new CMN_Delegation__c(
        Delegate__c = delegateUser.Id,
        StartAt__c = startAt,
        EndAt__c = endAt,
        TypeCodes__c = types,
        Reason__c = 'trip'
      );
    }
  }

  private static Id submit(User approver) {
    return CMN_ApprovalService.submit(
      [SELECT Id FROM CMN_TestRecord__c].Id,
      TYPE_CODE,
      new List<CMN_ApprovalStepSpec>{
        new CMN_ApprovalStepSpec(1, 'APPROVE', approver.Id, null)
      },
      null
    );
  }

  private static CMN_Todo__c todoOf(Id assigneeId) {
    List<CMN_Todo__c> rows = [
      SELECT Id, Status__c, IsDelegated__c, DelegatedFrom__c, SourceRecordId__c
      FROM CMN_Todo__c
      WHERE Assignee__c = :assigneeId
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  private static void expectError(CMN_Delegation__c d, String expected) {
    Database.SaveResult r = Database.insert(d, false);
    Assert.isFalse(r.isSuccess(), expected);
    Assert.areEqual(expected, r.getErrors()[0].getMessage());
  }
}
