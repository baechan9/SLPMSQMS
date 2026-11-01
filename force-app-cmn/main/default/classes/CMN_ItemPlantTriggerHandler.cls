/**
 * @description 공장별 품번 트리거: 외부 키·중복, 삭제 금지(단종은 Status PHASE_OUT).
 * @group CMN-00-MDM-004
 */
public with sharing class CMN_ItemPlantTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_ItemService.assignItemPlantKeys((List<CMN_ItemPlant__c>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_ItemService.assignItemPlantKeys((List<CMN_ItemPlant__c>) newRecords);
  }

  protected override void beforeDelete() {
    CMN_MasterDataGuard.preventDelete(oldRecords);
  }
}
