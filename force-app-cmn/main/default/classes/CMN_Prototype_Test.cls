/**
 * @description A0 프로토 공용 장치: 자리 구현 안내, 프로토 모드 세 조건(스위치·검토용 PS·Scratch Org), 목 응답 선택.
 * @group A0-PROTOTYPE
 */
@IsTest
private class CMN_Prototype_Test {
  private static final String BUNDLE = '{"version":1,"dwh":{"QMS_X":{"ok":{"rows":[1,2]},"empty":{"rows":[]}},"QMS_Y":{"ok":"text"}}}';

  @IsTest
  static void test_notYetAvailableThrowsLabel() {
    try {
      CMN_Prototype.notYetAvailable();
      Assert.fail('예외');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Prototype_NotYetAvailable, e.getMessage());
    }
  }

  @IsTest
  static void test_mockOnlyWhenSwitchPermissionAndScratch() {
    CMN_Prototype.bundleOverride = BUNDLE;
    // 스위치 켜짐 + 필요 PS 없음 → 꺼짐(실행 사용자의 PS를 비워 둔다)
    CMN_FeatureSwitch.userPermissionSets = new Set<String>();
    useSwitch(true, 'QMS_PS_Prototype_Review');
    CMN_Prototype.scratchOverride = true;
    Assert.isFalse(CMN_Prototype.isActive());
    Assert.isNull(CMN_Prototype.mockResponse('QMS_X', null));
    // 검토용 PS가 있으면 켜짐
    CMN_FeatureSwitch.userPermissionSets.add('QMS_PS_Prototype_Review');
    Assert.isTrue(CMN_Prototype.isActive());
    // 스위치 꺼짐 → 꺼짐
    useSwitch(false, null);
    Assert.isFalse(CMN_Prototype.isActive());
    // 스위치 켜짐 + Scratch 아님(SIT·운영) → 꺼짐
    useSwitch(true, null);
    CMN_Prototype.scratchOverride = false;
    Assert.isFalse(CMN_Prototype.isActive());
    // 세 조건 → 응답
    CMN_Prototype.scratchOverride = true;
    Assert.isTrue(CMN_Prototype.isActive());
    Map<String, Object> ok = (Map<String, Object>) CMN_Prototype.mockResponse(
      'QMS_X',
      null
    );
    Assert.areEqual(2, ((List<Object>) ok.get('rows')).size());
    Assert.isTrue((Boolean) ok.get(CMN_Prototype.MOCK_FLAG));
    Map<String, Object> empty = (Map<String, Object>) CMN_Prototype.mockResponse(
      'QMS_X',
      new Map<String, Object>{ 'case' => 'empty' }
    );
    Assert.areEqual(0, ((List<Object>) empty.get('rows')).size());
    // 모르는 case → ok, 모르는 키 → null, 맵이 아닌 응답은 그대로
    Map<String, Object> fallback = (Map<String, Object>) CMN_Prototype.mockResponse(
      'QMS_X',
      new Map<String, Object>{ 'case' => 'nope' }
    );
    Assert.areEqual(2, ((List<Object>) fallback.get('rows')).size());
    Assert.isNull(CMN_Prototype.mockResponse('QMS_NONE', null));
    Assert.isNull(CMN_Prototype.mockResponse(' ', null));
    Assert.areEqual('text', CMN_Prototype.mockResponse('QMS_Y', null));
  }

  @IsTest
  static void test_deployedBundleAndOrgCheck() {
    // 배포된 정적 리소스와 실제 Org 판정(개발 Org는 Scratch)
    useSwitch(true, null);
    Boolean active = CMN_Prototype.isActive();
    Object pareto = CMN_Prototype.mockResponse('QMS_B2B_PARETO', null);
    Organization o = [
      SELECT IsSandbox, TrialExpirationDate
      FROM Organization
      LIMIT 1
    ];
    Boolean scratch = o.IsSandbox && o.TrialExpirationDate != null;
    Assert.areEqual(scratch, active);
    Assert.areEqual(scratch, pareto != null);
  }

  private static void useSwitch(Boolean isOn, String permissionSet) {
    CMN_FeatureSwitch.overrides.put(
      CMN_Prototype.SWITCH_KEY,
      (CMN_FeatureSwitch__mdt) JSON.deserialize(
        JSON.serialize(
          new Map<String, Object>{
            'DeveloperName' => CMN_Prototype.SWITCH_KEY,
            'IsOn__c' => isOn,
            'RequiredPermissionSet__c' => permissionSet
          }
        ),
        CMN_FeatureSwitch__mdt.class
      )
    );
  }
}
