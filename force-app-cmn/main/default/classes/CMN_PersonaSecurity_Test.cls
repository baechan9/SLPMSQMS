/**
 * @description 페르소나·권한 셋 구조 검증(CMN-00-SEC-001). 앱 런처는 runAs 사용자 기준 AppMenuItem으로,
 * Setup·객체·탭 권한은 사용자의 권한 셋(프로필 소유 PS, 직접 할당 PS, PSG 구성 PS) 합으로 확인한다.
 * 프로필 이름은 이 WI가 만드는 검증 대상이라 테스트에서만 이름으로 찾는다.
 * @group CMN-00-SEC-001
 */
@IsTest
private class CMN_PersonaSecurity_Test {
  private static final String INTERNAL = 'SL Internal User';
  private static final String INTERNAL_PLATFORM = 'SL Internal Platform User';
  private static final String PORTAL = 'SL Supplier Portal User';
  private static final String SYSTEM_ADMIN_PSG = 'CMN_PSG_SystemAdmin';
  // Salesforce 라이선스 프로필에 붙는 시스템 앱. Metadata API로는 끌 수 없어 배포 후 단계
  // (profile-lockdown.py --hide-system-apps)가 지운다. 그 단계 전의 Org(CI 첫 검증)에서도 판정이 흔들리지 않게 제외한다.
  private static final Set<String> POST_DEPLOY_HIDDEN_APPS = new Set<String>{
    'CommandCenterApp',
    'DataGovernanceConsole',
    'SecurityHub',
    'Work'
  };
  private static final Set<String> PERSONA_GROUPS = new Set<String>{
    'CMN_PSG_Executive',
    'CMN_PSG_SystemAdmin',
    'QMS_PSG_Auditor',
    'QMS_PSG_DevEngineer',
    'QMS_PSG_Inspector',
    'QMS_PSG_LabTester',
    'QMS_PSG_Metrology',
    'QMS_PSG_ProcessEngineer',
    'QMS_PSG_QualityAdmin',
    'QMS_PSG_QualityEngineer',
    'QMS_PSG_QualityManager',
    'QMS_PSG_SupplierPortal',
    'QMS_PSG_SupplierQuality',
    'QMS_PSG_TrainingCoordinator',
    'QMS_PSG_Viewer'
  };

  @IsTest
  static void test_AC01_inspectorSeesFieldAppWithoutSetup() {
    for (String profileName : new List<String>{ INTERNAL, INTERNAL_PLATFORM }) {
      // Given: QMS_PSG_Inspector만 가진 사내 사용자
      User u = userWith(profileName, new Set<String>{ 'QMS_PSG_Inspector' });

      // When: 그 사용자의 앱 런처와 Setup 권한
      Set<String> apps = launcherApps(u);
      Boolean setup = hasUserPermission(u, 'PermissionsViewSetup');

      // Then: 현장 앱과 사내 기본 앱(SL QMS, 프로필 기본 앱이라 모든 사내 사용자에게 보임)만 보이고 Setup에 들어갈 수 없다(UX-007 BR-1)
      if (profileName == INTERNAL) {
        apps.removeAll(POST_DEPLOY_HIDDEN_APPS);
      }
      Assert.areEqual(
        new Set<String>{ 'SL_QMS', 'SL_QMS_Field' },
        apps,
        profileName
      );
      Assert.isFalse(setup, profileName + ': View Setup');
    }
  }

  @IsTest
  static void test_AC02_noPsgShowsNoBusinessTabs() {
    for (String profileName : new List<String>{ INTERNAL, INTERNAL_PLATFORM }) {
      // Given: PSG가 없는 신규 사내 사용자
      User u = userWith(profileName, new Set<String>());

      // When: 객체 권한과 탭 설정, 화면에 보이는 탭을 계산
      Set<Id> psIds = permissionSetIds(u);
      Integer objectGrants = [
        SELECT COUNT()
        FROM ObjectPermissions
        WHERE ParentId IN :psIds AND PermissionsRead = TRUE
      ];
      List<String> customTabs = new List<String>();
      for (PermissionSetTabSetting t : [
        SELECT Name
        FROM PermissionSetTabSetting
        WHERE ParentId IN :psIds
      ]) {
        if (t.Name.endsWith('__c')) {
          customTabs.add(t.Name);
        }
      }

      // Then: 업무 객체 권한·탭이 하나도 없다
      Assert.areEqual(0, objectGrants, profileName + ': 객체 권한');
      Assert.areEqual(new List<String>(), customTabs, profileName);
      System.runAs(u) {
        Assert.areEqual(
          new List<String>(),
          visibleCustomTabs(),
          profileName + ': describeTabs'
        );
      }
    }
  }

  @IsTest
  static void test_BR1_profilesCarryNoObjectPermissions() {
    // Given: 이 WI가 만든 프로필 3개
    Map<String, String> licenseByProfile = new Map<String, String>();
    for (Profile p : [
      SELECT Name, UserLicense.Name
      FROM Profile
      WHERE Name IN :new Set<String>{ INTERNAL, INTERNAL_PLATFORM, PORTAL }
    ]) {
      licenseByProfile.put(p.Name, p.UserLicense.Name);
    }

    // When: 프로필의 객체 권한과 금지 시스템 권한을 센다
    Integer objectGrants = [
      SELECT COUNT()
      FROM ObjectPermissions
      WHERE Parent.Profile.Name IN :licenseByProfile.keySet()
    ];
    Integer allData = [
      SELECT COUNT()
      FROM PermissionSet
      WHERE
        Profile.Name IN :licenseByProfile.keySet()
        AND (PermissionsViewAllData = TRUE
        OR PermissionsModifyAllData = TRUE
        OR PermissionsViewSetup = TRUE)
    ];

    // Then: 라이선스가 맞고, 객체 권한·전체 데이터·Setup 권한이 없다
    Assert.areEqual('Salesforce', licenseByProfile.get(INTERNAL));
    Assert.areEqual(
      'Salesforce Platform',
      licenseByProfile.get(INTERNAL_PLATFORM)
    );
    Assert.areEqual('Customer Community Plus', licenseByProfile.get(PORTAL));
    Assert.areEqual(0, objectGrants);
    Assert.areEqual(0, allData);
  }

  @IsTest
  static void test_BR2_personaGroupsDeployed() {
    // Given: 데모 사용자·기능 WI가 이름으로 참조하는 페르소나 PSG
    // When: Org의 PSG를 조회
    Set<String> found = new Set<String>();
    for (PermissionSetGroup g : [
      SELECT DeveloperName
      FROM PermissionSetGroup
      WHERE DeveloperName IN :PERSONA_GROUPS
    ]) {
      found.add(g.DeveloperName);
    }

    // Then: 15개가 모두 있다(이름 변경 금지)
    Assert.areEqual(PERSONA_GROUPS, found);
  }

  @IsTest
  static void test_BR3_userCanHoldSeveralPersonaGroups() {
    // Given: 품질 엔지니어이면서 내부심사원
    User u = userWith(
      INTERNAL_PLATFORM,
      new Set<String>{ 'QMS_PSG_QualityEngineer', 'QMS_PSG_Auditor' }
    );

    // When: 할당된 PSG를 조회
    Set<String> groups = new Set<String>();
    for (PermissionSetAssignment a : [
      SELECT PermissionSetGroup.DeveloperName
      FROM PermissionSetAssignment
      WHERE AssigneeId = :u.Id AND PermissionSetGroupId != NULL
    ]) {
      groups.add(a.PermissionSetGroup.DeveloperName);
    }

    // Then: 두 PSG를 함께 가진다
    Assert.areEqual(
      new Set<String>{ 'QMS_PSG_QualityEngineer', 'QMS_PSG_Auditor' },
      groups
    );
  }

  @IsTest
  static void test_BR4_appsFollowPersonaGroups() {
    // Given: 경영진, IT 운영, 품질경영팀
    User exec = userWith(
      INTERNAL_PLATFORM,
      new Set<String>{ 'CMN_PSG_Executive' }
    );
    User admin = userWith(
      INTERNAL_PLATFORM,
      new Set<String>{ SYSTEM_ADMIN_PSG }
    );
    User qualityAdmin = userWith(
      INTERNAL_PLATFORM,
      new Set<String>{ 'QMS_PSG_QualityAdmin' }
    );

    // When / Then: 앱은 PSG가 정한다. IT 운영만 Setup 조회
    Assert.areEqual(new Set<String>{ 'SL_QMS', 'SL_PMS' }, launcherApps(exec));
    Assert.areEqual(
      new Set<String>{
        'SL_QMS',
        'SL_PMS',
        'SL_Admin',
        'SL_QMS_Quality',
        'SL_QMS_Field'
      },
      launcherApps(admin)
    );
    Assert.areEqual(
      new Set<String>{ 'SL_QMS', 'SL_Admin', 'SL_QMS_Quality' },
      launcherApps(qualityAdmin)
    );
    Assert.isTrue(hasUserPermission(admin, 'PermissionsViewSetup'));
    Assert.isFalse(hasUserPermission(qualityAdmin, 'PermissionsViewSetup'));
  }

  @IsTest
  static void test_BR4_customPermissionsFollowPersonaGroups() {
    // Given: 경영진과 검사원
    User exec = userWith(
      INTERNAL_PLATFORM,
      new Set<String>{ 'CMN_PSG_Executive' }
    );
    User inspector = userWith(
      INTERNAL_PLATFORM,
      new Set<String>{ 'QMS_PSG_Inspector' }
    );

    // When / Then: 전 공장 대시보드는 경영진(검토 반영 Custom Permission). 비용·심사 지적 권한은 정의만 하고
    // 소유 WI의 PS(QMS_PS_NcrCost_*, QMS_PS_Audit_Admin)가 담으므로 아직 아무 PSG에도 없다.
    // FeatureManagement는 배포 직후 PSG 재계산(비동기) 중에 흔들려서, 사용자 권한 셋 구성으로 판정한다
    Assert.isTrue(hasCustomPermission(exec, 'QMS_DashboardAllPlants'));
    Assert.isFalse(hasCustomPermission(exec, 'QMS_ViewCost'));
    Assert.isFalse(hasCustomPermission(inspector, 'QMS_DashboardAllPlants'));
    Assert.isFalse(hasCustomPermission(inspector, 'QMS_AuditFindingAnyEdit'));
  }

  @IsTest
  static void test_negative_allDataOnlyInSystemAdminGroup() {
    // Given: SystemAdmin을 뺀 페르소나 PSG의 구성 PS
    Set<String> others = new Set<String>(PERSONA_GROUPS);
    others.remove(SYSTEM_ADMIN_PSG);
    Set<Id> psIds = new Set<Id>();
    for (PermissionSetGroupComponent c : [
      SELECT PermissionSetId
      FROM PermissionSetGroupComponent
      WHERE PermissionSetGroup.DeveloperName IN :others
    ]) {
      psIds.add(c.PermissionSetId);
    }

    // When: View All Data·Modify All Data를 가진 PS를 센다
    Integer violations = [
      SELECT COUNT()
      FROM PermissionSet
      WHERE
        Id IN :psIds
        AND (PermissionsViewAllData = TRUE
        OR PermissionsModifyAllData = TRUE)
    ];

    // Then: 없다(에이전트 주의)
    Assert.areEqual(0, violations);
  }

  // ------------------------------------------------------------------ 도우미
  private static User userWith(String profileName, Set<String> groupNames) {
    Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
    User u = CMN_TestDataFactory.newUser('sec001', profileName, p.Id);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert u;
      List<PermissionSetGroup> groups = [
        SELECT Id
        FROM PermissionSetGroup
        WHERE DeveloperName IN :groupNames
      ];
      Assert.areEqual(groupNames.size(), groups.size(), 'PSG 미배포');
      List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
      for (PermissionSetGroup g : groups) {
        Test.calculatePermissionSetGroup(g.Id);
        psas.add(
          new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetGroupId = g.Id
          )
        );
      }
      insert psas;
    }
    return u;
  }

  /** 프로필 소유 PS + 직접 할당 PS + 할당된 PSG의 구성 PS. */
  private static Set<Id> permissionSetIds(User u) {
    Set<Id> ids = new Set<Id>();
    Set<Id> groupIds = new Set<Id>();
    for (PermissionSet ps : [
      SELECT Id
      FROM PermissionSet
      WHERE ProfileId = :u.ProfileId
    ]) {
      ids.add(ps.Id);
    }
    for (PermissionSetAssignment a : [
      SELECT PermissionSetId, PermissionSetGroupId
      FROM PermissionSetAssignment
      WHERE AssigneeId = :u.Id
    ]) {
      if (a.PermissionSetGroupId != null) {
        groupIds.add(a.PermissionSetGroupId);
      } else {
        ids.add(a.PermissionSetId);
      }
    }
    for (PermissionSetGroupComponent c : [
      SELECT PermissionSetId
      FROM PermissionSetGroupComponent
      WHERE PermissionSetGroupId IN :groupIds
    ]) {
      ids.add(c.PermissionSetId);
    }
    return ids;
  }

  /** 앱 런처에 나오는 앱의 DeveloperName. AppMenuItem은 실행 사용자 기준으로 돌려준다. */
  private static Set<String> launcherApps(User u) {
    Set<String> names = new Set<String>();
    System.runAs(u) {
      for (AppMenuItem m : [
        SELECT Name
        FROM AppMenuItem
        WHERE Type = 'TabSet' AND IsAccessible = TRUE
      ]) {
        names.add(m.Name);
      }
    }
    return names;
  }

  private static Boolean hasUserPermission(User u, String field) {
    for (
      SObject ps : Database.queryWithBinds(
        'SELECT ' +
          String.escapeSingleQuotes(field) +
          ' FROM PermissionSet WHERE Id IN :ids',
        new Map<String, Object>{ 'ids' => permissionSetIds(u) },
        AccessLevel.SYSTEM_MODE
      )
    ) {
      if (ps.get(field) == true) {
        return true;
      }
    }
    return false;
  }

  private static Boolean hasCustomPermission(User u, String developerName) {
    return [
        SELECT COUNT()
        FROM SetupEntityAccess
        WHERE
          ParentId IN :permissionSetIds(u)
          AND SetupEntityId IN (
            SELECT Id
            FROM CustomPermission
            WHERE DeveloperName = :developerName
          )
      ] > 0;
  }

  private static List<String> visibleCustomTabs() {
    List<String> tabs = new List<String>();
    for (Schema.DescribeTabSetResult app : Schema.describeTabs()) {
      for (Schema.DescribeTabResult t : app.getTabs()) {
        if (t.isCustom()) {
          tabs.add(t.getSobjectName());
        }
      }
    }
    return tabs;
  }
}
