/**
 * @description 다국어 기반 검증(CMN-00-I18N-001): SSO 언어 적용·직접 지정 유지, 스위처, 마스터 표시명 대체 규칙.
 * @group CMN-00-I18N-001
 */
@IsTest
private class CMN_LanguageService_Test {
  @IsTest
  static void test_AC01_ssoPortalLanguageApplied() {
    // Given: 직접 지정하지 않은 한국어 사용자
    User u = user('i18n1', 'ko');

    // When: 포털 언어 en으로 SSO 로그인(JIT 갱신)
    new CMN_SamlJitHandler()
      .updateUser(
        u.Id,
        null,
        null,
        null,
        'E9001',
        new Map<String, String>{ 'lang' => 'en' },
        null
      );

    // Then: 영어 UI
    Assert.areEqual('en_US', localeOf(u.Id));
  }

  @IsTest
  static void test_AC02_switcherChoiceSurvivesPortalLogin() {
    // Given: 사용자가 스위처로 zh_CN을 고름
    User u = user('i18n2', 'ko');
    System.runAs(u) {
      CMN_LanguageController.setLanguage('zh_CN');
    }

    // When: 포털 언어 en으로 다시 로그인
    new CMN_SamlJitHandler()
      .updateUser(
        u.Id,
        null,
        null,
        null,
        'E9002',
        new Map<String, String>{ 'lang' => 'en' },
        null
      );

    // Then: zh_CN 유지(직접 지정)
    Assert.areEqual('zh_CN', localeOf(u.Id));
    Assert.isTrue(
      [SELECT LanguageOverride__c FROM User WHERE Id = :u.Id]
      .LanguageOverride__c
    );
  }

  @IsTest
  static void test_BR4_followPortalReleasesOverride() {
    // Given: 직접 지정한 사용자
    User u = user('i18n3', 'ko');
    CMN_LanguageController.State state;
    System.runAs(u) {
      CMN_LanguageController.setLanguage('pl');
      // When: 포털 언어 따르기
      CMN_LanguageController.followPortal();
      state = CMN_LanguageController.getState();
    }
    new CMN_SamlJitHandler()
      .updateUser(
        u.Id,
        null,
        null,
        null,
        'E9003',
        new Map<String, String>{ 'lang' => 'zh' },
        null
      );

    // Then: 직접 지정이 풀리고 다음 로그인에 포털 언어
    Assert.isFalse(state.overridden);
    Assert.areEqual(6, state.languages.size());
    Assert.areEqual('zh_CN', localeOf(u.Id));
  }

  @IsTest
  static void test_AC03_polishUserSeesEnglishMasterName() {
    // Given: 영문명만 있는 불량 코드, 폴란드어·중국어·한국어 사용자
    CMN_CodeGroup__c g = new CMN_CodeGroup__c(
      Name = 'Defect',
      GroupCode__c = 'DEFECT_TYPE',
      MaxLevel__c = 1
    );
    insert g;
    CMN_Code__c code = new CMN_Code__c(
      CodeGroup__c = g.Id,
      Code__c = 'HAZE',
      Name = '흐림',
      NameEn__c = 'Haze'
    );
    insert code;
    Map<String, User> users = new Map<String, User>{
      'pl' => user('i18n4', 'pl'),
      'zh_CN' => user('i18n5', 'zh_CN'),
      'ko' => user('i18n6', 'ko')
    };
    grantCodeRead(users.values());

    // When: 각 사용자로 표시명(수식)과 코드 피커 이름을 읽음
    Map<String, String> display = new Map<String, String>();
    Map<String, String> picker = new Map<String, String>();
    for (String lang : users.keySet()) {
      System.runAs(users.get(lang)) {
        display.put(
          lang,
          [SELECT DisplayName__c FROM CMN_Code__c WHERE Id = :code.Id]
          .DisplayName__c
        );
        picker.put(
          lang,
          CMN_CodePickerController.getCodes('DEFECT_TYPE').codes[0].label
        );
      }
    }

    // Then: 폴란드어 → 영문, 중국어(중문 없음) → 영문, 한국어 → 이름. 수식과 피커가 같은 규칙
    Assert.areEqual('Haze', display.get('pl'));
    Assert.areEqual('Haze', display.get('zh_CN'));
    Assert.areEqual('흐림', display.get('ko'));
    Assert.areEqual(display, picker);
  }

  @IsTest
  static void test_negative_jitDoesNotCreateUsersAndBadInput() {
    // Given / When / Then: JIT 사용자 생성은 거부
    try {
      new CMN_SamlJitHandler()
        .createUser(null, null, null, 'NEW', new Map<String, String>(), null);
      Assert.fail('사용자를 만들면 안 된다');
    } catch (CMN_Exception e) {
      Assert.areEqual(Label.CMN_I18n_JitNoUserCreation, e.getMessage());
    }
    // 지원하지 않는 언어
    try {
      CMN_LanguageController.setLanguage('fr');
      Assert.fail('거부돼야 한다');
    } catch (AuraHandledException e) {
      Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
    }
    // 포털 언어 값 변환
    Assert.areEqual('en_US', CMN_LanguageService.toLocaleKey('en-US'));
    Assert.areEqual('pt_BR', CMN_LanguageService.toLocaleKey('pt'));
    Assert.areEqual('zh_CN', CMN_LanguageService.toLocaleKey('ZH'));
    Assert.isNull(CMN_LanguageService.toLocaleKey('xx'));
    Assert.isNull(CMN_LanguageService.toLocaleKey(' '));
    // 모르는 값·같은 언어는 바꾸지 않음
    User u = user('i18n7', 'ko');
    Assert.isFalse(CMN_LanguageService.applyPortalLanguage(u.Id, 'xx'));
    Assert.isFalse(CMN_LanguageService.applyPortalLanguage(u.Id, 'ko'));
  }

  @IsTest
  static void test_negative_unexpectedErrorMaskedAndLogged() {
    // Given / When: 검증 오류가 아닌 예외
    Test.startTest();
    AuraHandledException e = CMN_LanguageController.toAura(
      new DmlException('internal detail'),
      'CMN_LanguageController.setLanguage'
    );
    Test.getEventBus().deliver();
    Test.stopTest();

    // Then: 화면에는 공통 문구, 원문은 로그
    Assert.areEqual(Label.CMN_LanguageSwitcher_Error, e.getMessage());
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM CMN_Log__c
        WHERE Source__c = 'CMN_LanguageController.setLanguage'
      ]
    );
  }

  // ------------------------------------------------------------------ 도우미
  private static User user(String alias, String language) {
    User u = CMN_TestDataFactory.newUser(
      alias,
      alias,
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    u.LanguageLocaleKey = language;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert u;
    }
    return u;
  }

  private static void grantCodeRead(List<User> users) {
    Id ps = [SELECT Id FROM PermissionSet WHERE Name = 'CMN_PS_Code_Read'].Id;
    List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
    for (User u : users) {
      psas.add(
        new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps)
      );
    }
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert psas;
    }
  }

  private static String localeOf(Id userId) {
    return [SELECT LanguageLocaleKey FROM User WHERE Id = :userId]
    .LanguageLocaleKey;
  }
}
