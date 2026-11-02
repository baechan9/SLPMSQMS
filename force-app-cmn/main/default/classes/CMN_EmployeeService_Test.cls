/**
 * @description HR 임직원 동기화 Salesforce 수신 계약 검증(CMN-00-INT-002). Mule upsert는 레코드 저장으로 흉내 낸다(개발 플랜 7.3).
 * @group CMN-00-INT-002
 */
@IsTest
private class CMN_EmployeeService_Test {
  @TestSetup
  static void setup() {
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User mgr = CMN_TestDataFactory.newUser('hrmgr', 'hrmgr', profileId);
    User emp = CMN_TestDataFactory.newUser('hremp', 'hremp', profileId);
    emp.EmployeeNo__c = 'E7001';
    User admin = CMN_TestDataFactory.newUser('hradm', 'hradm', profileId);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ mgr, emp, admin };
      insert new PermissionSetAssignment(
        AssigneeId = admin.Id,
        PermissionSetGroupId = [
          SELECT Id
          FROM PermissionSetGroup
          WHERE DeveloperName = 'CMN_PSG_SystemAdmin'
        ]
        .Id
      );
    }
    CMN_Department__c root = new CMN_Department__c(
      Name = 'Quality',
      DeptCode__c = 'D7000',
      Manager__c = mgr.Id
    );
    insert root;
    insert new List<CMN_Department__c>{
      new CMN_Department__c(
        Name = 'IQC',
        DeptCode__c = 'D7100',
        Parent__c = root.Id,
        Manager__c = mgr.Id
      ),
      new CMN_Department__c(
        Name = 'No manager',
        DeptCode__c = 'D7200',
        Parent__c = root.Id
      )
    };
  }

  @IsTest
  static void test_AC01_retiredEmployeeDeactivatesUserAndNotifiesManager() {
    // Given: 연결 사용자(E7001)에게 진행 중 To-Do 1건
    User emp = user('hremp');
    CMN_Employee__c e = employee('E7001', 'D7100');
    insert e;
    CMN_TodoService.open(
      new List<CMN_TodoSpec>{
        new CMN_TodoSpec(
          emp.Id,
          'CMN_TEST_TASK',
          e.Id,
          e.Id,
          'CMN_Todo_CMN_APPROVAL'
        )
      }
    );

    // When: HR이 퇴직으로 보냄
    Test.startTest();
    update new CMN_Employee__c(Id = e.Id, HrStatus__c = 'RETIRED');
    Test.stopTest();

    // Then: 사용자 비활성, 부서장에게 알림 1건(남은 To-Do 1건)
    User saved = [
      SELECT IsActive, HrStatus__c
      FROM User
      WHERE Id = :emp.Id
    ];
    Assert.isFalse(saved.IsActive);
    Assert.areEqual('RETIRED', saved.HrStatus__c);
    List<CMN_NotificationService.Message> alerts = retiredAlerts();
    Assert.areEqual(1, alerts.size());
    Assert.areEqual(new List<Id>{ user('hrmgr').Id }, alerts[0].recipientIds);
    Assert.areEqual('1', alerts[0].params.get('OpenTodos'));
    Assert.areEqual('0', alerts[0].params.get('PendingApprovals'));
    Assert.areEqual('E7001', alerts[0].params.get('EmployeeNo'));
  }

  @IsTest
  static void test_AC02_departmentMoveUpdatesEmployeeAndUser() {
    // Given: D7100 소속
    CMN_Employee__c e = employee('E7001', 'D7100');
    insert e;
    Assert.areEqual(
      user('hremp').Id,
      [SELECT User__c FROM CMN_Employee__c WHERE Id = :e.Id].User__c,
      '같은 사번 사용자 자동 연결'
    );

    // When: 부서 이동(D7100 → D7200), 직급·메일 변경
    Test.startTest();
    update new CMN_Employee__c(
      Id = e.Id,
      Department__c = dept('D7200'),
      JobGradeCode__c = 'G4',
      Email__c = 'e7001.new@slqms.example.com'
    );
    Test.stopTest();

    // Then: 임직원과 사용자 부서가 함께 바뀐다(FederationIdentifier = 사번)
    User u = [
      SELECT
        DepartmentCode__c,
        JobGradeCode__c,
        Email,
        FederationIdentifier,
        IsActive
      FROM User
      WHERE Id = :user('hremp').Id
    ];
    Assert.areEqual('D7200', u.DepartmentCode__c);
    Assert.areEqual('G4', u.JobGradeCode__c);
    Assert.areEqual('E7001', u.FederationIdentifier);
    Assert.isTrue(u.IsActive);
    Assert.areEqual(0, retiredAlerts().size());
  }

  @IsTest
  static void test_BR2_noManagerFallsBackToAdmins() {
    // Given: 부서장 없는 부서의 연결 임직원
    CMN_Employee__c e = employee('E7001', 'D7200');
    insert e;

    // When: 퇴직(같은 레코드는 트랜잭션당 한 번 처리되므로 갱신 1회)
    update new CMN_Employee__c(Id = e.Id, HrStatus__c = 'RETIRED');

    // Then: 시스템 관리자에게
    List<CMN_NotificationService.Message> alerts = retiredAlerts();
    Assert.areEqual(1, alerts.size());
    Assert.isTrue(alerts[0].recipientIds.contains(user('hradm').Id));
  }

  @IsTest
  static void test_BR2_migrationModeSkipsUserSyncAndAlerts() {
    // Given: 이관 모드(데모·이관 적재)
    CMN_TriggerHandler.permissionsOverride = new Set<String>{
      CMN_TriggerHandler.MIGRATION_PERMISSION
    };

    // When: 퇴직 상태로 적재
    Test.startTest();
    CMN_Employee__c e = employee('E7001', 'D7100');
    e.HrStatus__c = 'RETIRED';
    insert e;
    Test.stopTest();
    CMN_TriggerHandler.permissionsOverride = null;

    // Then: 연결은 하지만 사용자 갱신·알림은 없다
    Assert.areEqual(
      user('hremp').Id,
      [SELECT User__c FROM CMN_Employee__c WHERE Id = :e.Id].User__c
    );
    Assert.isTrue(
      [SELECT IsActive FROM User WHERE Id = :user('hremp').Id].IsActive
    );
    Assert.areEqual(0, retiredAlerts().size());
  }

  @IsTest
  static void test_syncFailureIsLoggedNotThrown() {
    // Given: 실행 사용자 자신에게 연결된 퇴직 임직원(자기 자신은 비활성화할 수 없음)
    CMN_TriggerHandler.permissionsOverride = new Set<String>{
      CMN_TriggerHandler.MIGRATION_PERMISSION
    };
    CMN_Employee__c e = employee('E7999', 'D7100');
    e.User__c = UserInfo.getUserId();
    e.HrStatus__c = 'RETIRED';
    insert e;
    CMN_TriggerHandler.permissionsOverride = null;

    // When
    new CMN_EmployeeUserSyncJob(new Set<Id>{ e.Id }).execute(null);
    Test.getEventBus().deliver();

    // Then: 예외 없이 ERROR 로그
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM CMN_Log__c
        WHERE Level__c = 'ERROR' AND Source__c = 'CMN_EmployeeUserSyncJob'
      ]
    );
  }

  @IsTest
  static void test_bulk200EmployeesWithoutUsers() {
    // Given: 라이선스 없는 임직원 200명
    Id d = dept('D7100');
    List<CMN_Employee__c> rows = new List<CMN_Employee__c>();
    for (Integer i = 0; i < 200; i++) {
      CMN_Employee__c e = employee(
        'E8' + String.valueOf(i).leftPad(3, '0'),
        null
      );
      e.Department__c = d;
      rows.add(e);
    }

    // When
    Integer q0 = Limits.getQueries();
    insert rows;

    // Then: SOQL은 건수와 무관, 연결 사용자 없음 → 사용자 갱신 작업 없음
    Assert.isTrue(
      Limits.getQueries() - q0 <= 2,
      'SOQL ' + (Limits.getQueries() - q0)
    );
    Assert.areEqual(0, Limits.getQueueableJobs());
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM CMN_Employee__c WHERE User__c != NULL]
    );
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_Employee__c employee(String no, String deptCode) {
    return new CMN_Employee__c(
      Name = 'Emp ' + no,
      EmployeeNo__c = no,
      Email__c = no.toLowerCase() + '@slqms.example.com',
      Department__c = deptCode == null ? null : dept(deptCode),
      JobGradeCode__c = 'G3',
      HrStatus__c = 'ACTIVE'
    );
  }

  private static Id dept(String code) {
    return [SELECT Id FROM CMN_Department__c WHERE DeptCode__c = :code].Id;
  }

  private static User user(String alias) {
    return [SELECT Id FROM User WHERE Alias = :alias LIMIT 1];
  }

  private static List<CMN_NotificationService.Message> retiredAlerts() {
    List<CMN_NotificationService.Message> out = new List<CMN_NotificationService.Message>();
    for (CMN_NotificationService.Message m : CMN_NotificationService.queued) {
      if (m.eventCode == CMN_EmployeeService.RETIRED_EVENT) {
        out.add(m);
      }
    }
    return out;
  }
}
