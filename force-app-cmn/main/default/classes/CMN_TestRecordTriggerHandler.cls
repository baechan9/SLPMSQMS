/**
 * @description 테스트 대상 객체 트리거(DEV-3): 업무 객체처럼 beforeInsert에서 채번한다(ARC-003 AC 검증).
 * @group CMN-00-ARC-003
 */
public with sharing class CMN_TestRecordTriggerHandler extends CMN_TriggerHandler {
  /**
   * 상태·권한 필드 잠금(UX-005 BR-5) 검증용 스위치. 테스트 객체는 여러 공통 WI 테스트가 상태 없이 필드를 고치므로
   * 잠금은 UX-005 테스트에서만 켠다. 업무 객체 핸들러는 스위치 없이 항상 CMN_UiRuleService.addLockErrors를 부른다.
   */
  @TestVisible
  private static Boolean enforceUiRules = false;

  protected override void beforeInsert() {
    CMN_NumberingService.assign(newRecords);
  }

  protected override void beforeUpdate() {
    if (enforceUiRules) {
      CMN_UiRuleService.addLockErrors(newRecords, oldMap);
    }
  }
}
