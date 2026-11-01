/**
 * @description Account 트리거(CMN-00-MDM-005): 고객·협력사 계정은 차종·품번·협력사 품번(주종 하위)이 참조하므로 삭제를 막는다.
 * 그 밖의 계정은 표준 동작을 따른다.
 * @group CMN-00-MDM-005
 */
public with sharing class CMN_AccountTriggerHandler extends CMN_TriggerHandler {
  private static final Set<String> MASTER_TYPES = new Set<String>{
    'CMN_Customer',
    'CMN_Supplier'
  };

  protected override void beforeDelete() {
    Map<Id, Schema.RecordTypeInfo> rts = Schema.SObjectType.Account.getRecordTypeInfosById();
    List<SObject> masters = new List<SObject>();
    for (Account a : (List<Account>) oldRecords) {
      Schema.RecordTypeInfo rt = rts.get(a.RecordTypeId);
      if (rt != null && MASTER_TYPES.contains(rt.getDeveloperName())) {
        masters.add(a);
      }
    }
    CMN_MasterDataGuard.preventDelete(masters);
  }
}
