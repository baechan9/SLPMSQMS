/**
 * @description 공정 트리거: 외부 키 설정·중복 검사, 삭제 금지(BR-2).
 * @group CMN-00-MDM-002
 */
public with sharing class CMN_OperationTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_PlantService.assignOperationKeys((List<CMN_Operation__c>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_PlantService.assignOperationKeys((List<CMN_Operation__c>) newRecords);
  }

  protected override void beforeDelete() {
    CMN_PlantService.preventDelete(oldRecords);
  }
}
