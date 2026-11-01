/**
 * @description 제품군 트리거: 2단계 유지, 삭제 금지.
 * @group CMN-00-MDM-004
 */
public with sharing class CMN_ProductGroupTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeUpdate() {
    CMN_ItemService.keepTwoLevels(
      (List<CMN_ProductGroup__c>) newRecords,
      oldMap
    );
  }

  protected override void beforeDelete() {
    CMN_MasterDataGuard.preventDelete(oldRecords);
  }
}
