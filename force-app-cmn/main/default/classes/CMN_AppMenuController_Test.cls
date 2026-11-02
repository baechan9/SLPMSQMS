/**
 * @description 앱 메뉴 허브 검증(A0 앱 내비게이션 골격): 타일 상태·순서·제목, 객체 권한에 따른 숨김, 메뉴 키 검증, 배포된 메뉴 설정 무결성.
 * @group A0-PROTO-KIT
 */
@IsTest
private class CMN_AppMenuController_Test {
  @TestSetup
  static void setup() {
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User site = CMN_TestDataFactory.newUser('mnusite', 'Menu Site', profileId);
    User bare = CMN_TestDataFactory.newUser('mnubare', 'Menu Bare', profileId);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ site, bare };
      insert new PermissionSetAssignment(
        AssigneeId = site.Id,
        PermissionSetId = [
          SELECT Id
          FROM PermissionSet
          WHERE Name = 'CMN_PS_Site_Read'
        ]
        .Id
      );
    }
  }

  @IsTest
  static void test_tilesReadyPlannedAndHidden() {
    // Given: 객체 타일(제목 없음 → 객체 라벨), 앱 페이지 타일, 준비 중 타일, 없는 객체 타일
    useMenu(
      new List<Map<String, Object>>{
        item('T_OBJECT', 10, 'OBJECT', 'CMN_Plant__c', null),
        item('T_PAGE', 20, 'PAGE', 'CMN_ApprovalMonitor', null),
        item('T_NONE', 30, 'NONE', null, 'A1'),
        item('T_MISSING', 40, 'OBJECT', 'QMS_NotDeployed__c', null)
      }
    );
    System.runAs(user('mnusite')) {
      // When
      CMN_AppMenuController.MenuView v = CMN_AppMenuController.getMenu(
        'QMS_TEST'
      );
      // Then
      Assert.areEqual('QMS_TEST', v.menuKey);
      Assert.areEqual(3, v.items.size(), '배포되지 않은 객체 타일은 숨김');
      Assert.areEqual(2, v.readyCount);
      Assert.areEqual('T_OBJECT', v.items[0].key);
      Assert.areEqual(
        CMN_Plant__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED)
          .getLabelPlural(),
        v.items[0].title
      );
      Assert.areEqual('OBJECT', v.items[0].targetType);
      Assert.isTrue(v.items[1].ready);
      Assert.areEqual('CMN_ApprovalMonitor', v.items[1].target);
      Assert.isFalse(v.items[2].ready);
      Assert.areEqual('A1', v.items[2].bundle);
      Assert.isNull(v.items[2].targetType);
    }
  }

  @IsTest
  static void test_objectWithoutReadAccessIsHidden() {
    // Given: 공장 읽기 권한이 없는 사용자
    useMenu(
      new List<Map<String, Object>>{
        item('T_OBJECT', 10, 'OBJECT', 'CMN_Plant__c', null),
        item('T_NONE', 20, 'NONE', null, 'A2')
      }
    );
    System.runAs(user('mnubare')) {
      // When
      CMN_AppMenuController.MenuView v = CMN_AppMenuController.getMenu(
        'QMS_TEST'
      );
      // Then: 객체 타일은 빠지고 준비 중 타일만
      Assert.areEqual(1, v.items.size());
      Assert.areEqual('T_NONE', v.items[0].key);
      Assert.areEqual(0, v.readyCount);
    }
  }

  @IsTest
  static void test_negative_invalidOrInactiveMenu() {
    CMN_AppMenuSelector.menusOverride = new List<CMN_AppMenu__mdt>{
      (CMN_AppMenu__mdt) JSON.deserialize(
        '{"DeveloperName":"QMS_OFF","IsActive__c":false}',
        CMN_AppMenu__mdt.class
      )
    };
    for (
      String bad : new List<String>{ null, '', '../x', 'QMS_NONE', 'QMS_OFF' }
    ) {
      try {
        CMN_AppMenuController.getMenu(bad);
        Assert.fail('메뉴 키 검증: ' + bad);
      } catch (AuraHandledException e) {
        Assert.areEqual(
          Label.CMN_AppMenu_NotFound,
          e.getMessage(),
          'key=' + bad
        );
      }
    }
  }

  @IsTest
  static void test_deployedMenusAreConsistent() {
    // 배포된 메뉴 설정: 모든 메뉴가 열리고, 준비 중 타일에는 1차 화면 묶음이, 화면 타일에는 대상이 있다
    Integer menus = 0;
    for (CMN_AppMenu__mdt m : [
      SELECT DeveloperName
      FROM CMN_AppMenu__mdt
      WHERE IsActive__c = TRUE
    ]) {
      CMN_AppMenuController.MenuView v = CMN_AppMenuController.getMenu(
        m.DeveloperName
      );
      Assert.isNotNull(v.title, m.DeveloperName);
      menus++;
    }
    Assert.isTrue(menus >= 10, '메뉴 10개(QMS-02~09·공통 업무·기준정보)');
    for (CMN_AppMenuItem__mdt i : [
      SELECT DeveloperName, TargetType__c, Target__c, Bundle__c
      FROM CMN_AppMenuItem__mdt
      WHERE IsActive__c = TRUE
    ]) {
      if (i.TargetType__c == 'NONE') {
        Assert.isTrue(String.isNotBlank(i.Bundle__c), i.DeveloperName);
      } else {
        Assert.isTrue(String.isNotBlank(i.Target__c), i.DeveloperName);
      }
    }
  }

  // ------------------------------------------------------------------ 도우미
  private static void useMenu(List<Map<String, Object>> items) {
    CMN_AppMenuSelector.menusOverride = new List<CMN_AppMenu__mdt>{
      (CMN_AppMenu__mdt) JSON.deserialize(
        '{"DeveloperName":"QMS_TEST","IsActive__c":true,' +
        '"TitleLabel__c":"CMN_AppMenu_WORK_Title","IconName__c":"standard:task"}',
        CMN_AppMenu__mdt.class
      )
    };
    List<CMN_AppMenuItem__mdt> rows = new List<CMN_AppMenuItem__mdt>();
    for (Map<String, Object> i : items) {
      rows.add(
        (CMN_AppMenuItem__mdt) JSON.deserialize(
          JSON.serialize(i),
          CMN_AppMenuItem__mdt.class
        )
      );
    }
    CMN_AppMenuSelector.itemsOverride = rows;
  }

  private static Map<String, Object> item(
    String key,
    Integer order,
    String targetType,
    String target,
    String bundle
  ) {
    return new Map<String, Object>{
      'DeveloperName' => key,
      'Menu__r' => new Map<String, Object>{ 'DeveloperName' => 'QMS_TEST' },
      'Order__c' => order,
      'FeatureCode__c' => 'TST',
      'TargetType__c' => targetType,
      'Target__c' => target,
      'Bundle__c' => bundle,
      'IsActive__c' => true
    };
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
