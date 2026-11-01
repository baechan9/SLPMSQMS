/**
 * @description 품번 트리거: 삭제 금지(부적합·인정시험·PPAP·SPC 특성이 참조). SAP 동기화는 ItemNo__c upsert(AC-1).
 * @group CMN-00-MDM-004
 */
public with sharing class CMN_ItemTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeDelete() {
    CMN_MasterDataGuard.preventDelete(oldRecords);
  }
}
