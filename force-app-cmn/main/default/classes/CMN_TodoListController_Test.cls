/**
 * @description 메인 홈 To-Do 목록 검증(CMN-00-TDO-004): 시스템 필터, 업무·결재 탭 건수, 20건씩 더 보기, 이동 대상, 입력 검증, 권한.
 * @group CMN-00-TDO-004
 */
@IsTest
private class CMN_TodoListController_Test {
  @TestSetup
  static void setup() {
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
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User me = CMN_TestDataFactory.newUser('tdlme', 'Todo Me', profileId);
    User none = CMN_TestDataFactory.newUser('tdlnone', 'Todo None', profileId);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ me, none };
      List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
      for (PermissionSet ps : [
        SELECT Id, Name
        FROM PermissionSet
        WHERE
          Name IN (
            'CMN_PS_Todo_User',
            'CMN_PS_Approval_User',
            'CMN_PS_Site_Read'
          )
      ]) {
        psas.add(
          new PermissionSetAssignment(
            AssigneeId = me.Id,
            PermissionSetId = ps.Id
          )
        );
        if (ps.Name == 'CMN_PS_Site_Read') {
          psas.add(
            new PermissionSetAssignment(
              AssigneeId = none.Id,
              PermissionSetId = ps.Id
            )
          );
        }
      }
      insert psas;
    }
  }

  @IsTest
  static void test_AC01_qmsFilterThenAll() {
    // Given: QMS 업무 3, PMS 업무 2
    User me = user('tdlme');
    List<CMN_TodoSpec> specs = new List<CMN_TodoSpec>();
    for (Integer i = 1; i <= 5; i++) {
      specs.add(spec(me.Id, i, 'TASK', i <= 3 ? 'QMS' : 'PMS', null));
    }
    CMN_TodoService.open(specs);
    System.runAs(me) {
      // When: SL QMS 홈 기본 필터
      CMN_TodoListController.TodoPage qms = CMN_TodoListController.getTodos(
        'TASK',
        'QMS',
        0
      );
      // Then: 3건, 필터 전체면 5건
      Assert.areEqual(3, qms.items.size());
      Assert.areEqual(3, qms.taskCount);
      Assert.areEqual(
        5,
        CMN_TodoListController.getTodos('TASK', 'ALL', 0).items.size()
      );
      Assert.areEqual(
        2,
        CMN_TodoListController.getTodos('TASK', 'PMS', null).taskCount
      );
    }
  }

  @IsTest
  static void test_BR1_tabsCountAndCommonTodosInBothSystems() {
    // Given: QMS 업무 1, 공통 업무 1, 공통 결재 1(기한 경과), 다른 사람 To-Do 1
    User me = user('tdlme');
    CMN_TodoSpec overdue = spec(me.Id, 3, 'APPROVAL', 'CMN', null);
    overdue.dueDate = Date.today().addDays(-1);
    overdue.plantId = [SELECT Id FROM CMN_Plant__c LIMIT 1].Id;
    CMN_TodoService.open(
      new List<CMN_TodoSpec>{
        spec(me.Id, 1, 'TASK', 'QMS', null),
        spec(me.Id, 2, 'TASK', 'CMN', null),
        overdue,
        spec(user('tdlnone').Id, 4, 'TASK', 'QMS', null)
      }
    );
    System.runAs(me) {
      // When
      CMN_TodoListController.TodoPage qms = CMN_TodoListController.getTodos(
        'TASK',
        'QMS',
        0
      );
      CMN_TodoListController.TodoPage pms = CMN_TodoListController.getTodos(
        'APPROVAL',
        'PMS',
        0
      );
      // Then: 탭 건수는 필터 기준, 공통 To-Do는 QMS·PMS 어느 홈에나 보임
      Assert.areEqual(2, qms.taskCount);
      Assert.areEqual(1, qms.approvalCount);
      Assert.areEqual(2, qms.items.size());
      Assert.areEqual(1, pms.taskCount);
      Assert.areEqual(1, pms.items.size());
      CMN_TodoListController.TodoItem a = pms.items[0];
      Assert.isTrue(a.isOverdue);
      Assert.areEqual('KR01', a.plantName);
      Assert.areEqual('CMN', a.systemCode);
      Assert.isNotNull(a.title);
    }
  }

  @IsTest
  static void test_BR2_pagesOf20OrderedByDueDate() {
    // Given: QMS 업무 25건(기한이 서로 다름, 1건은 기한 없음)
    User me = user('tdlme');
    List<CMN_TodoSpec> specs = new List<CMN_TodoSpec>();
    for (Integer i = 1; i <= 25; i++) {
      CMN_TodoSpec s = spec(me.Id, i, 'TASK', 'QMS', null);
      s.dueDate = i == 1 ? null : Date.today().addDays(30 - i);
      specs.add(s);
    }
    CMN_TodoService.open(specs);
    System.runAs(me) {
      // When
      CMN_TodoListController.TodoPage first = CMN_TodoListController.getTodos(
        'TASK',
        'QMS',
        0
      );
      CMN_TodoListController.TodoPage second = CMN_TodoListController.getTodos(
        'TASK',
        'QMS',
        CMN_TodoListController.PAGE_SIZE
      );
      // Then: 한 화면 20건 + 더 보기, 기한 빠른 순, 기한 없음은 맨 뒤, 업무 레코드로 이동
      Assert.areEqual(20, first.items.size());
      Assert.isTrue(first.hasMore);
      Assert.areEqual(5, second.items.size());
      Assert.isFalse(second.hasMore);
      Assert.areEqual(Date.today().addDays(5), first.items[0].dueDate);
      Assert.isNull(second.items[4].dueDate);
      Assert.areEqual(fakeId(25), first.items[0].navigationId);
      Assert.areEqual(25, first.taskCount);
    }
  }

  @IsTest
  static void test_BR2_approvalOpensApprovalRequest() {
    // Given: 내가 결재자인 결재 요청과 그 단계의 결재 To-Do
    User me = user('tdlme');
    CMN_TestRecord__c target = new CMN_TestRecord__c(
      Name = 'target',
      Plant__c = [SELECT Id FROM CMN_Plant__c LIMIT 1]
      .Id,
      Status__c = 'DRAFT'
    );
    insert target;
    Id req = CMN_ApprovalService.submit(
      target.Id,
      'CMN_TEST_APPROVE',
      new List<CMN_ApprovalStepSpec>{
        new CMN_ApprovalStepSpec(1, 'APPROVE', me.Id, null)
      },
      null
    );
    Id stepId = [SELECT Id FROM CMN_ApprovalStep__c WHERE Request__c = :req].Id;
    CMN_TodoSpec s = new CMN_TodoSpec(
      me.Id,
      CMN_TodoService.SOURCE_APPROVAL,
      stepId,
      target.Id,
      'CMN_Todo_' + CMN_TodoService.SOURCE_APPROVAL
    );
    s.category = 'APPROVAL';
    s.systemCode = 'CMN';
    s.titleParams = new List<Object>{ 'target' };
    CMN_TodoService.open(new List<CMN_TodoSpec>{ s });
    System.runAs(me) {
      // When
      CMN_TodoListController.TodoItem item = CMN_TodoListController.getTodos(
          'APPROVAL',
          'QMS',
          0
        )
        .items[0];
      // Then: 결재 요청 레코드로 이동
      Assert.areEqual(req, item.navigationId);
    }
  }

  @IsTest
  static void test_negative_invalidInputAndNoAccess() {
    User me = user('tdlme');
    System.runAs(me) {
      for (
        List<Object> bad : new List<List<Object>>{
          new List<Object>{ 'OTHER', 'QMS', 0 },
          new List<Object>{ 'TASK', 'XXX', 0 },
          new List<Object>{ 'TASK', null, 0 },
          new List<Object>{ 'TASK', 'QMS', -1 },
          new List<Object>{ 'TASK', 'QMS', 2001 }
        }
      ) {
        try {
          CMN_TodoListController.getTodos(
            (String) bad[0],
            (String) bad[1],
            (Integer) bad[2]
          );
          Assert.fail('입력 검증: ' + bad);
        } catch (AuraHandledException e) {
          Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
        }
      }
    }
    // To-Do 권한 셋이 없는 사용자는 조회 실패(사용자 모드), 원문 대신 공통 문구
    System.runAs(user('tdlnone')) {
      try {
        CMN_TodoListController.getTodos('TASK', 'QMS', 0);
        Assert.fail('권한 없음');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_UnexpectedError, e.getMessage());
      }
    }
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_TodoSpec spec(
    Id assignee,
    Integer n,
    String category,
    String sys,
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

  private static User user(String alias) {
    return [
      SELECT Id
      FROM User
      WHERE Alias = :alias AND Username LIKE '%@test.slqms.example.com'
      LIMIT 1
    ];
  }
}
