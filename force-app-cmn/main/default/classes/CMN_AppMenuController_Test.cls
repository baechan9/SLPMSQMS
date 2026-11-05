/**
 * @description 앱 메뉴 허브 검증(CMN-00-UX-007, A0 골격에서 시작): 메뉴별 모드(타일 상태·순서·제목, 객체 권한 숨김, 메뉴 키 검증),
 * 전체 메뉴 모드(현재 앱 그룹, 빈 그룹 숨김, 미결 배지, 페이지 권한, 휴대폰 타일), 업무 번호 바로가기, 배포된 설정 무결성.
 * @group CMN-00-UX-007
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
    // 업무 번호 바로가기 검증용: 테스트 객체와 번호 필드를 읽을 수 있는 사용자
    User finder = CMN_TestDataFactory.newUser(
      'mnufind',
      'Menu Find',
      profileId
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ site, bare, finder };
      List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
      for (PermissionSet ps : [
        SELECT Id
        FROM PermissionSet
        WHERE Name IN ('CMN_PS_Site_Read', 'CMN_PS_Todo_User')
      ]) {
        psas.add(
          new PermissionSetAssignment(
            AssigneeId = site.Id,
            PermissionSetId = ps.Id
          )
        );
      }
      psas.add(
        new PermissionSetAssignment(
          AssigneeId = finder.Id,
          PermissionSetId = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'CMN_PS_DataMigration'
          ]
          .Id
        )
      );
      insert psas;
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

  @IsTest
  static void test_AC02_hubShowsGroupsOfCurrentAppOnly() {
    // Given: 품질 업무 앱 그룹과 Admin 앱 그룹
    useHub();
    System.runAs(user('mnusite')) {
      // When: 현재 앱 = 품질 업무
      CMN_AppMenuSelector.appOverride = 'SL_QMS_Quality';
      CMN_AppMenuController.HubView quality = CMN_AppMenuController.getHub(
        null,
        'Large'
      );
      // When: 페이지가 앱을 지정
      CMN_AppMenuController.HubView admin = CMN_AppMenuController.getHub(
        'SL_Admin',
        'Large'
      );
      // Then: 현재 앱이 Apps__c에 있는 그룹만, 그룹 머리글 정보 포함
      Assert.areEqual('SL_QMS_Quality', quality.appName);
      Assert.areEqual(1, quality.groups.size());
      Assert.areEqual('QMS_TEST', quality.groups[0].menuKey);
      Assert.areEqual('QMS_Menu03', quality.groups[0].pageTab);
      Assert.areEqual(Label.CMN_AppMenu_HubTitle, quality.title);
      Assert.areEqual(new List<String>{ 'TST-' }, quality.numberPrefixes);
      Assert.areEqual(1, admin.groups.size());
      Assert.areEqual('ADM_TEST', admin.groups[0].menuKey);
    }
  }

  @IsTest
  static void test_AC02_unknownAppFallsBackToDefaultApp() {
    // Given: 앱을 판별할 수 없음(앱을 바꾼 적 없음) → 사내 기본 앱 SL_QMS
    useHub();
    CMN_AppMenuSelector.appOverride = null;
    // When: 형식이 틀린 앱 이름과 화면 크기
    CMN_AppMenuController.HubView hub = CMN_AppMenuController.getHub(
      '../bad',
      'Huge'
    );
    // Then: 테스트 사용자에게 UserAppInfo가 없으면 SL_QMS. 있으면 그 앱 이름
    Assert.isNotNull(hub.appName);
    if (hub.appName == CMN_AppMenuController.DEFAULT_APP) {
      Assert.areEqual(1, hub.groups.size());
      Assert.areEqual('QMS_TEST', hub.groups[0].menuKey);
    }
  }

  @IsTest
  static void test_AC03_badgesCountOpenAndOverdueTodos() {
    // Given: 내 열린 To-Do — 부적합 3건(1건 기한 경과), 기타 1건
    User site = user('mnusite');
    List<CMN_TodoSpec> specs = new List<CMN_TodoSpec>();
    for (Integer n = 1; n <= 4; n++) {
      CMN_TodoSpec s = new CMN_TodoSpec(
        site.Id,
        n <= 3 ? 'QMS_NCR_TEST' : 'QMS_OTHER_TEST',
        fakeId(n),
        fakeId(n),
        'CMN_Widget_TodoSummary_Title'
      );
      s.category = 'TASK';
      s.systemCode = 'QMS';
      s.dueDate = n == 1 ? Date.today().addDays(-1) : Date.today().addDays(5);
      specs.add(s);
    }
    CMN_TodoService.open(specs);
    useHub();
    System.runAs(site) {
      // When
      CMN_AppMenuSelector.appOverride = 'SL_QMS_Quality';
      List<CMN_AppMenuController.ItemView> items = CMN_AppMenuController.getHub(
          null,
          'Large'
        )
        .groups[0]
        .items;
      // Then: 부적합 타일 3건·기한 경과 1건, 전체(*) 타일 4건, 배지 없는 타일 0
      Map<String, CMN_AppMenuController.ItemView> byKey = new Map<String, CMN_AppMenuController.ItemView>();
      for (CMN_AppMenuController.ItemView i : items) {
        byKey.put(i.key, i);
      }
      Assert.areEqual(3, byKey.get('T_NCR').pendingCount);
      Assert.areEqual(1, byKey.get('T_NCR').overdueCount);
      Assert.areEqual(4, byKey.get('T_ALL').pendingCount);
      Assert.areEqual(0, byKey.get('T_PLANNED').pendingCount);
    }
  }

  @IsTest
  static void test_AC04_findRecordByNumber() {
    // Given: 채번 규칙 TST-{PLANT}-…과 번호가 있는 레코드
    useHub();
    Id plant = plantId();
    CMN_TestRecord__c rec = new CMN_TestRecord__c(
      Name = 'Find me',
      Plant__c = plant,
      RecordNo__c = 'TST-KR01-2026-000777'
    );
    // 찾는 사용자가 소유자여야 공유 모델(Private)에서 보인다
    System.runAs(user('mnufind')) {
      insert rec;
    }
    String no = [SELECT RecordNo__c FROM CMN_TestRecord__c WHERE Id = :rec.Id]
    .RecordNo__c;
    System.runAs(user('mnufind')) {
      // When: 소문자·공백이 섞인 번호로 찾기
      CMN_AppMenuController.FindResult hit = CMN_AppMenuController.findRecord(
        '  ' + no.toLowerCase() + ' '
      );
      // Then: 레코드로 간다
      Assert.isTrue(hit.found, no);
      Assert.areEqual(rec.Id, hit.recordId);
      Assert.areEqual('CMN_TestRecord__c', hit.objectApiName);

      // When / Then: 없는 번호, 접두어 없는 번호, 형식 오류는 같은 '찾을 수 없음'
      for (
        String bad : new List<String>{
          'TST-KR01-2026-999999',
          'ZZZ-1',
          '../x',
          null
        }
      ) {
        CMN_AppMenuController.FindResult miss = CMN_AppMenuController.findRecord(
          bad
        );
        Assert.isFalse(miss.found, 'no=' + bad);
        Assert.areEqual(Label.CMN_AppMenu_RecordNotFound, miss.message);
      }
    }
  }

  @IsTest
  static void test_AC04_noAccessLooksLikeNotFound() {
    // Given: 테스트 객체 읽기 권한이 없는 사용자
    useHub();
    CMN_TestRecord__c rec = new CMN_TestRecord__c(
      Name = 'Hidden',
      Plant__c = plantId(),
      RecordNo__c = 'TST-KR01-2026-000888'
    );
    insert rec;
    String no = [SELECT RecordNo__c FROM CMN_TestRecord__c WHERE Id = :rec.Id]
    .RecordNo__c;
    System.runAs(user('mnubare')) {
      // When
      CMN_AppMenuController.FindResult r = CMN_AppMenuController.findRecord(no);
      // Then: 있는 레코드지만 없는 번호와 같은 답
      Assert.isFalse(r.found);
      Assert.isNull(r.recordId);
      Assert.areEqual(Label.CMN_AppMenu_RecordNotFound, r.message);
    }
  }

  @IsTest
  static void test_AC05_groupWithoutVisibleTilesIsHidden() {
    // Given: 공장 객체 타일만 있는 그룹과 준비 중 타일이 있는 그룹, 공장 읽기 권한 없는 사용자
    CMN_AppMenuSelector.menusOverride = new List<CMN_AppMenu__mdt>{
      menu('QMS_TEST', 'SL_QMS'),
      menu('OBJ_ONLY', 'SL_QMS')
    };
    CMN_AppMenuSelector.itemsOverride = new List<CMN_AppMenuItem__mdt>{
      row(item('T_OBJECT', 10, 'OBJECT', 'CMN_Plant__c', null), 'OBJ_ONLY'),
      row(item('T_NONE', 20, 'NONE', null, 'A1'), 'QMS_TEST')
    };
    CMN_AppMenuSelector.rulesOverride = new List<CMN_NumberingRule__mdt>();
    System.runAs(user('mnubare')) {
      // When
      CMN_AppMenuController.HubView hub = CMN_AppMenuController.getHub(
        'SL_QMS',
        'Large'
      );
      // Then: 빈 그룹은 숨긴다
      Assert.areEqual(1, hub.groups.size());
      Assert.areEqual('QMS_TEST', hub.groups[0].menuKey);
    }
  }

  @IsTest
  static void test_AC06_hubUsesAtMostTwoQueriesForBadges() {
    // Given: 설정은 모두 대체값(메타데이터 조회 없음), 배지 타일 있음
    useHub();
    CMN_AppMenuSelector.appOverride = 'SL_QMS_Quality';
    System.runAs(user('mnusite')) {
      // When
      Integer before = Limits.getQueries();
      CMN_AppMenuController.getHub(null, 'Large');
      // Then: To-Do 집계 2회(전체, 기한 경과)뿐
      Assert.isTrue(Limits.getQueries() - before <= 2);
    }
  }

  @IsTest
  static void test_BR4_pageTileNeedsCustomPermission() {
    // Given: 없는 Custom Permission이 필요한 페이지 타일과 조건 없는 페이지 타일
    Map<String, Object> locked = item(
      'T_LOCKED',
      10,
      'PAGE',
      'CMN_ApprovalMonitor',
      null
    );
    locked.put('RequiredPermission__c', 'CMN_NotDeployedPermission');
    useMenu(
      new List<Map<String, Object>>{
        locked,
        item('T_OPEN', 20, 'PAGE', 'CMN_ApprovalMonitor', null)
      }
    );
    System.runAs(user('mnusite')) {
      // When
      CMN_AppMenuController.MenuView v = CMN_AppMenuController.getMenu(
        'QMS_TEST'
      );
      // Then
      Assert.areEqual(1, v.items.size());
      Assert.areEqual('T_OPEN', v.items[0].key);
    }
  }

  @IsTest
  static void test_BR8_phoneShowsOnlyPhoneTiles() {
    // Given: 휴대폰 표시 타일 1개(부적합)
    useHub();
    CMN_AppMenuSelector.appOverride = 'SL_QMS_Quality';
    System.runAs(user('mnusite')) {
      // When
      CMN_AppMenuController.HubView hub = CMN_AppMenuController.getHub(
        null,
        'Small'
      );
      // Then
      Assert.areEqual(1, hub.groups[0].items.size());
      Assert.areEqual('T_NCR', hub.groups[0].items[0].key);
    }
  }

  @IsTest
  static void test_BR6_prefixOfPattern() {
    Assert.areEqual(
      'NCR-',
      CMN_AppMenuController.prefixOf('NCR-{PLANT}-{YYYY}-{SEQ:6}')
    );
    Assert.areEqual('APV-', CMN_AppMenuController.prefixOf('apv-{YYYY}'));
    Assert.isNull(CMN_AppMenuController.prefixOf('{PLANT}-{SEQ:4}'));
    Assert.isNull(CMN_AppMenuController.prefixOf(null));
  }

  @IsTest
  static void test_deployedHubSettingsAreConsistent() {
    // 배포된 설정: 모든 메뉴에 앱·허브 탭이 있고, 앱마다 전체 메뉴 허브가 열린다
    Set<String> apps = new Set<String>();
    for (CMN_AppMenu__mdt m : [
      SELECT DeveloperName, Apps__c, PageTab__c
      FROM CMN_AppMenu__mdt
      WHERE IsActive__c = TRUE
    ]) {
      Assert.isTrue(String.isNotBlank(m.Apps__c), m.DeveloperName);
      Assert.isTrue(String.isNotBlank(m.PageTab__c), m.DeveloperName);
      for (String a : m.Apps__c.split(',')) {
        apps.add(a.trim());
      }
    }
    Assert.isTrue(
      apps.containsAll(
        new Set<String>{ 'SL_QMS_Quality', 'SL_QMS', 'SL_Admin', 'SL_PMS' }
      ),
      String.valueOf(apps)
    );
    for (String a : apps) {
      CMN_AppMenuController.HubView hub = CMN_AppMenuController.getHub(
        a,
        'Large'
      );
      Assert.isFalse(hub.groups.isEmpty(), a);
    }
  }

  // ------------------------------------------------------------------ 도우미
  /** 전체 메뉴 모드 설정: 품질 업무·SL QMS 그룹(타일 4개)과 Admin 그룹(타일 1개), 채번 규칙 1개. */
  private static void useHub() {
    CMN_AppMenuSelector.menusOverride = new List<CMN_AppMenu__mdt>{
      menu('QMS_TEST', 'SL_QMS_Quality,SL_QMS'),
      menu('ADM_TEST', 'SL_Admin')
    };
    Map<String, Object> ncr = item('T_NCR', 10, 'NONE', null, 'A4');
    ncr.put('TodoSourceTypes__c', 'QMS_NCR_TEST');
    ncr.put('ShowOnPhone__c', true);
    Map<String, Object> all = item(
      'T_ALL',
      20,
      'PAGE',
      'CMN_ApprovalMonitor',
      null
    );
    all.put('TodoSourceTypes__c', '*');
    CMN_AppMenuSelector.itemsOverride = new List<CMN_AppMenuItem__mdt>{
      row(ncr, 'QMS_TEST'),
      row(all, 'QMS_TEST'),
      row(item('T_PLANNED', 30, 'NONE', null, 'A1'), 'QMS_TEST'),
      row(item('T_ADMIN', 10, 'PAGE', 'CMN_ApprovalMonitor', null), 'ADM_TEST')
    };
    CMN_AppMenuSelector.rulesOverride = new List<CMN_NumberingRule__mdt>{
      (CMN_NumberingRule__mdt) JSON.deserialize(
        '{"DeveloperName":"T","ObjectApiName__c":"CMN_TestRecord__c",' +
        '"Pattern__c":"TST-{PLANT}-{YYYY}-{SEQ:6}"}',
        CMN_NumberingRule__mdt.class
      )
    };
  }

  private static CMN_AppMenu__mdt menu(String key, String apps) {
    return (CMN_AppMenu__mdt) JSON.deserialize(
      JSON.serialize(
        new Map<String, Object>{
          'DeveloperName' => key,
          'IsActive__c' => true,
          'TitleLabel__c' => 'CMN_AppMenu_WORK_Title',
          'IconName__c' => 'standard:task',
          'Apps__c' => apps,
          'PageTab__c' => 'QMS_Menu03'
        }
      ),
      CMN_AppMenu__mdt.class
    );
  }

  private static CMN_AppMenuItem__mdt row(
    Map<String, Object> values,
    String menuKey
  ) {
    values.put(
      'Menu__r',
      new Map<String, Object>{ 'DeveloperName' => menuKey }
    );
    return (CMN_AppMenuItem__mdt) JSON.deserialize(
      JSON.serialize(values),
      CMN_AppMenuItem__mdt.class
    );
  }

  /** 채번 규칙이 공장 범위라 번호를 받으려면 공장이 필요하다. */
  private static Id plantId() {
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
    return p.Id;
  }

  private static Id fakeId(Integer n) {
    String prefix = CMN_TestRecord__c.SObjectType.getDescribe(
        SObjectDescribeOptions.DEFERRED
      )
      .getKeyPrefix();
    return Id.valueOf(prefix + String.valueOf(n).leftPad(12, '0'));
  }

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
