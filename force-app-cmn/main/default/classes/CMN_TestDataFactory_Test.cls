@IsTest
private class CMN_TestDataFactory_Test {
  @IsTest
  static void test_loadFixturesSkipsUndeployedObjects() {
    // Given/When: 배포된 객체만 적재(없는 객체 단계는 건너뜀)
    Test.startTest();
    CMN_TestDataFactory.loadFixtures();
    Test.stopTest();
    // Then: 오류 없이 끝나고, 적재 중에만 이관 모드였다
    Assert.isFalse(CMN_TriggerHandler.isMigrationMode());
  }

  @IsTest
  static void test_profileByLicenseAndUser() {
    // Given: 라이선스로 프로필 선택(ko Org는 표준 프로필 이름이 한국어)
    Id platform = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    Assert.isNotNull(platform, 'Platform 프로필');
    // When
    Map<String, User> users = CMN_TestDataFactory.createUsers(
      new Set<String>{ 'E1101' }
    );
    // Then
    Assert.areEqual(1, users.size());
    Assert.isNotNull(users.get('E1101').Id);
  }
}
