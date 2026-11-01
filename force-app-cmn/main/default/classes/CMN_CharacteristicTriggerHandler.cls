/**
 * @description 품질 특성 트리거: 목표 Cpk 기본값·외부 키(BR-2), 초안만 삭제.
 * @group CMN-00-MDM-006
 */
public with sharing class CMN_CharacteristicTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_CharacteristicService.prepare((List<CMN_Characteristic__c>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_CharacteristicService.prepare((List<CMN_Characteristic__c>) newRecords);
  }

  protected override void beforeDelete() {
    CMN_CharacteristicService.preventDeleteUnlessDraft(
      (List<CMN_Characteristic__c>) oldRecords
    );
  }
}
