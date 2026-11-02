/**
 * @description 공통 기본 위젯 데이터 검증(CMN-00-DSH-001 BR-5·BR-6): 내 To-Do 요약, 내 결재 대기.
 * @group CMN-00-DSH-001
 */
@IsTest
private class CMN_CoreWidgetController_Test {
  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    insert new List<CMN_Plant__c>{ plant(c.Id, 'KR01'), plant(c.Id, 'CN01') };
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    List<User> users = new List<User>{
      CMN_TestDataFactory.newUser('wgtme', 'Widget Me', profileId),
      CMN_TestDataFactory.newUser('wgtapv', 'Widget Approver', profileId)
    };
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert users;
      List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
      for (PermissionSet ps : [
        SELECT Id
        FROM PermissionSet
        WHERE
          Name IN (
            'CMN_PS_Todo_User',
            'CMN_PS_Approval_User',
            'CMN_PS_Site_Read',
            'CMN_PS_Dashboard_User'
          )
      ]) {
        for (User u : users) {
          psas.add(
            new PermissionSetAssignment(
              AssigneeId = u.Id,
              PermissionSetId = ps.Id
            )
          );
        }
      }
      insert psas;
    }
  }

  @IsTest
  static void test_BR5_todoSummaryBySystemPlantAndOverdue() {
    // Given: 내 To-Do — QMS 할 일 2(1건 기한 경과, KR01), PMS 할 일 1, 공통 결재 1(CN01), 다른 사람 1
    User me = user('wgtme');
    Id kr = plantId('KR01');
    Id cn = plantId('CN01');
    CMN_TodoService.open(
      new List<CMN_TodoSpec>{
        spec(me.Id, 1, 'TASK', 'QMS', kr, Date.today().addDays(-1)),
        spec(me.Id, 2, 'TASK', 'QMS', kr, Date.today().addDays(3)),
        spec(me.Id, 3, 'TASK', 'PMS', kr, null),
        spec(me.Id, 4, 'APPROVAL', 'CMN', cn, null),
        spec(user('wgtapv').Id, 5, 'TASK', 'QMS', kr, null)
      }
    );
    System.runAs(me) {
      // When / Then: QMS 보드 = QMS + CMN
      CMN_CoreWidgetController.TodoSummary s = CMN_CoreWidgetController.todoSummary(
        '{"system":"QMS"}'
      );
      Assert.areEqual(2, s.task);
      Assert.areEqual(1, s.approval);
      Assert.areEqual(1, s.overdue);
      // 공장 필터(BR-6)
      s = CMN_CoreWidgetController.todoSummary(
        '{"system":"QMS","plantId":"' + kr + '"}'
      );
      Assert.areEqual(2, s.task);
      Assert.areEqual(0, s.approval);
      // 시스템 없음 = 전체
      Assert.areEqual(3, CMN_CoreWidgetController.todoSummary(null).task);
    }
  }

  @IsTest
  static void test_BR5_approvalSummaryOldestFirst() {
    // Given: 결재자 wgtapv에게 결재 2건(하나는 3일 대기)
    User approver = user('wgtapv');
    Id target = insertTarget();
    Id req = CMN_ApprovalService.submit(
      target,
      'CMN_TEST_APPROVE',
      new List<CMN_ApprovalStepSpec>{
        new CMN_ApprovalStepSpec(1, 'APPROVE', approver.Id, null)
      },
      null
    );
    CMN_ApprovalStep__c step = [
      SELECT Id
      FROM CMN_ApprovalStep__c
      WHERE Request__c = :req
    ];
    update new CMN_ApprovalStep__c(
      Id = step.Id,
      PendingAt__c = Datetime.now().addDays(-3)
    );
    System.runAs(approver) {
      // When
      CMN_CoreWidgetController.ApprovalSummary s = CMN_CoreWidgetController.approvalSummary(
        '{"maxRows":"50"}'
      );
      // Then
      Assert.areEqual(1, s.total);
      Assert.areEqual(req, s.rows[0].requestId);
      Assert.areEqual(3, s.rows[0].pendingDays);
      // 다른 공장 필터면 0건
      Assert.areEqual(
        0,
        CMN_CoreWidgetController.approvalSummary(
            '{"plantId":"' + plantId('CN01') + '"}'
          )
          .total
      );
    }
  }

  @IsTest
  static void test_negative_invalidConfig() {
    for (
      String bad : new List<String>{
        '{not json',
        '{"plantId":"abc"}',
        '{"maxRows":"x"}',
        '{"plantId":"' +
        UserInfo.getUserId() +
        '"}'
      }
    ) {
      try {
        CMN_CoreWidgetController.todoSummary(bad);
        Assert.fail('설정 검증: ' + bad);
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage(), bad);
      }
      try {
        CMN_CoreWidgetController.approvalSummary(bad);
        Assert.fail('설정 검증: ' + bad);
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage(), bad);
      }
    }
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_TodoSpec spec(
    Id assignee,
    Integer n,
    String category,
    String sys,
    Id plant,
    Date due
  ) {
    Id source = fakeId(n);
    CMN_TodoSpec s = new CMN_TodoSpec(
      assignee,
      'CMN_TEST',
      source,
      source,
      'CMN_Widget_TodoSummary_Title'
    );
    s.category = category;
    s.systemCode = sys;
    s.plantId = plant;
    s.dueDate = due;
    return s;
  }

  private static Id fakeId(Integer n) {
    String prefix = CMN_TestRecord__c.SObjectType.getDescribe(
        SObjectDescribeOptions.DEFERRED
      )
      .getKeyPrefix();
    return Id.valueOf(prefix + String.valueOf(n).leftPad(12, '0'));
  }

  private static Id insertTarget() {
    CMN_TestRecord__c r = new CMN_TestRecord__c(
      Name = 'target',
      Plant__c = plantId('KR01'),
      Status__c = 'DRAFT'
    );
    insert r;
    return r.Id;
  }

  private static CMN_Plant__c plant(Id companyId, String code) {
    return new CMN_Plant__c(
      Name = code,
      PlantCode__c = code,
      Company__c = companyId,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
  }

  private static Id plantId(String code) {
    return [SELECT Id FROM CMN_Plant__c WHERE PlantCode__c = :code].Id;
  }

  private static User user(String alias) {
    return [
      SELECT Id
      FROM User
      WHERE Alias = :alias AND Username LIKE '%@test.slqms.example.com'
      LIMIT 1
    ];
  }
}
