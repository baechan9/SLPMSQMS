@IsTest
private class CMN_FeatureSwitch_Test {
  @IsTest
  static void test_AC04_unknownKeyIsOff() {
    // Given/When/Then: 미등록·빈·형식 오류 키는 예외 없이 false
    Assert.isFalse(CMN_FeatureSwitch.isOn('NO_SUCH_SWITCH_KEY'));
    Assert.isFalse(CMN_FeatureSwitch.isOn(''));
    Assert.isFalse(CMN_FeatureSwitch.isOn(null));
    Assert.isFalse(CMN_FeatureSwitch.isOn('has space-and dash'));
  }

  @IsTest
  static void test_BR6_onWithoutRequiredPermissionSet() {
    // Given: 켜짐, 필요 PS 없음
    CMN_FeatureSwitch.overrides.put(
      'X_ON',
      new CMN_FeatureSwitch__mdt(IsOn__c = true)
    );
    CMN_FeatureSwitch.overrides.put(
      'X_OFF',
      new CMN_FeatureSwitch__mdt(IsOn__c = false)
    );
    // Then
    Assert.isTrue(CMN_FeatureSwitch.isOn('X_ON'));
    Assert.isFalse(CMN_FeatureSwitch.isOn('X_OFF'));
  }

  @IsTest
  static void test_BR6_requiredPermissionSet() {
    // Given: 켜져 있지만 PS 보유자만
    CMN_FeatureSwitch.overrides.put(
      'X_PS',
      new CMN_FeatureSwitch__mdt(
        IsOn__c = true,
        RequiredPermissionSet__c = 'X_Allowed'
      )
    );
    // When: 보유하지 않음
    CMN_FeatureSwitch.userPermissionSets = new Set<String>();
    Assert.isFalse(CMN_FeatureSwitch.isOn('X_PS'));
    // When: 보유
    CMN_FeatureSwitch.userPermissionSets = new Set<String>{ 'X_Allowed' };
    Assert.isTrue(CMN_FeatureSwitch.isOn('X_PS'));
  }

  @IsTest
  static void test_BR6_permissionSetThroughGroup() {
    // Given: 필요 PS를 Permission Set Group으로만 가진 사용자
    PermissionSet ps = new PermissionSet(
      Name = 'X_Switch_PS',
      Label = 'X Switch PS'
    );
    insert ps;
    PermissionSetGroup psg = new PermissionSetGroup(
      DeveloperName = 'X_Switch_PSG',
      MasterLabel = 'X Switch PSG'
    );
    insert psg;
    insert new PermissionSetGroupComponent(
      PermissionSetGroupId = psg.Id,
      PermissionSetId = ps.Id
    );
    Test.calculatePermissionSetGroup(psg.Id);
    User u = CMN_TestDataFactory.newUser(
      'XSWITCH',
      'Switch',
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    insert u;
    insert new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetGroupId = psg.Id
    );
    CMN_FeatureSwitch.overrides.put(
      'X_GROUP',
      new CMN_FeatureSwitch__mdt(
        IsOn__c = true,
        RequiredPermissionSet__c = 'X_Switch_PS'
      )
    );
    Boolean switchedOn;
    // When
    System.runAs(u) {
      switchedOn = CMN_FeatureSwitch.isOn('X_GROUP');
    }
    // Then
    Assert.isTrue(switchedOn, 'PSG 구성 PS도 보유로 본다');
  }

  @IsTest
  static void test_permissionSetsQueriedOncePerTransaction() {
    // Given: 실제 조회 경로(사용자 PS·PSG 구성 PS)
    CMN_FeatureSwitch.overrides.put(
      'X_REAL',
      new CMN_FeatureSwitch__mdt(
        IsOn__c = true,
        RequiredPermissionSet__c = 'CMN_PS_Admin_Ops'
      )
    );
    Test.startTest();
    Boolean first = CMN_FeatureSwitch.isOn('X_REAL');
    Integer used = Limits.getQueries();
    Boolean second = CMN_FeatureSwitch.isOn('X_REAL');
    Integer usedAgain = Limits.getQueries();
    Test.stopTest();
    // Then: 두 번째 호출은 추가 조회 없음
    Assert.areEqual(first, second);
    Assert.areEqual(used, usedAgain, '조회 결과를 재사용');
  }
}
