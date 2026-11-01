/**
 * @description 협력사 품번 트리거: 외부 키·중복(AC-1), 삭제 금지(검사·PPAP 이력의 단위),
 * 품번을 협력사 포털 그룹에 읽기 공유(SEC-002, 검토 반영 Vol.3).
 * @group CMN-00-MDM-005
 */
public with sharing class CMN_SupplierItemTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_SupplierService.assignSupplierItemKeys(
      (List<CMN_SupplierItem__c>) newRecords
    );
  }

  protected override void beforeUpdate() {
    CMN_SupplierService.assignSupplierItemKeys(
      (List<CMN_SupplierItem__c>) newRecords
    );
  }

  protected override void afterInsert() {
    CMN_SharingService.shareItemsWithSuppliers(
      (List<CMN_SupplierItem__c>) newRecords
    );
  }

  protected override void afterUpdate() {
    CMN_SharingService.shareItemsWithSuppliers(
      (List<CMN_SupplierItem__c>) newRecords
    );
  }

  protected override void beforeDelete() {
    CMN_MasterDataGuard.preventDelete(oldRecords);
  }
}
