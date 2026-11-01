/**
 * @description 테스트 대상 객체 트리거(DEV-3): 업무 객체처럼 beforeInsert에서 채번한다(ARC-003 AC 검증).
 * @group CMN-00-ARC-003
 */
public with sharing class CMN_TestRecordTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_NumberingService.assign(newRecords);
  }
}
