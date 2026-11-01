/**
 * @description CMN 설정 읽기 검증(CMN-00-MDM-003 BR-2의 기본값 저장소).
 * @group CMN-00-MDM-003
 */
@IsTest
private class CMN_Settings_Test {
  @IsTest
  static void test_BR2_deployedDefaultsReadable() {
    // Given / When: 배포된 CSR 기본값
    Integer d3 = CMN_Settings.getInteger(
      CMN_CustomerService.KEY_CONTAINMENT_DAYS,
      -1
    );

    // Then: 1일
    Assert.areEqual(1, d3);
  }

  @IsTest
  static void test_typesAndFallbacks() {
    // Given: 덮어쓴 값
    CMN_Settings.overrides.put('T_LIST', ' KR01, ,CN01 ');
    CMN_Settings.overrides.put('T_BOOL', 'TRUE');
    CMN_Settings.overrides.put('T_BAD_NUM', 'abc');
    CMN_Settings.overrides.put('T_DEC', '1.33');

    // When / Then
    Assert.areEqual(
      new List<String>{ 'KR01', 'CN01' },
      CMN_Settings.getList('T_LIST')
    );
    Assert.isTrue(CMN_Settings.getBoolean('T_BOOL', false));
    Assert.isFalse(CMN_Settings.getBoolean('NOT_THERE', false));
    Assert.areEqual(7, CMN_Settings.getInteger('T_BAD_NUM', 7));
    Assert.areEqual(1.33, CMN_Settings.getDecimal('T_DEC', 0));
    Assert.areEqual('x', CMN_Settings.getString(null, 'x'));
    Assert.areEqual(new List<String>(), CMN_Settings.getList('NOT_THERE'));
  }
}
