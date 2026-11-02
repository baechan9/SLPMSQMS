/**
 * @description 포털 SSO 서버 규칙 검증(CMN-00-TDO-002). SAML 흐름 자체(AC-1·AC-2)는 IdP 연결 후 화면으로 확인한다.
 * @group CMN-00-TDO-002
 */
@IsTest
private class CMN_SsoService_Test {
  @IsTest
  static void test_BR1_federationIdFollowsEmployeeNo() {
    // Given: 사번 있는 사용자, 사번 없는 사용자(비상용 관리자 등, 별도 매칭 키)
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User hr = CMN_TestDataFactory.newUser('ssohr', 'ssohr', profileId);
    hr.EmployeeNo__c = 'T9001';
    User breakGlass = CMN_TestDataFactory.newUser('ssobg', 'ssobg', profileId);
    breakGlass.FederationIdentifier = 'admin-local';

    // When
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ hr, breakGlass };
      update new User(Id = hr.Id, EmployeeNo__c = 'T9002');
    }

    // Then: 사번 사용자는 사번 = FederationIdentifier(변경도 따라감), 사번 없는 사용자는 그대로
    Map<Id, User> saved = new Map<Id, User>(
      [
        SELECT FederationIdentifier
        FROM User
        WHERE Id IN :new Set<Id>{ hr.Id, breakGlass.Id }
      ]
    );
    Assert.areEqual('T9002', saved.get(hr.Id).FederationIdentifier);
    Assert.areEqual(
      'admin-local',
      saved.get(breakGlass.Id).FederationIdentifier
    );
  }

  @IsTest
  static void test_AC03_unknownFederationIdIsNotProvisioned() {
    // Given: 어설션 NameID에 맞는 사용자가 없음(퇴사·미등록) → 플랫폼이 JIT createUser 호출
    // When / Then: 사용자를 만들지 않고 실패 → SAML 사용자 지정 오류 URL(CMN_SsoNoAccess)로 이동
    try {
      new CMN_SamlJitHandler()
        .createUser(
          null,
          null,
          null,
          'E0000',
          new Map<String, String>{ 'lang' => 'ko' },
          null
        );
      Assert.fail('사용자를 만들면 안 된다');
    } catch (CMN_Exception e) {
      Assert.areEqual(Label.CMN_I18n_JitNoUserCreation, e.getMessage());
    }
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM User WHERE FederationIdentifier = 'E0000']
    );
  }
}
