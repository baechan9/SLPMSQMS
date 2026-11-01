/**
 * @description 협력사 품번 규칙(CMN-00-MDM-005). 외부 키 {VendorNo}-{ItemNo}-{PlantCode}로 협력사·품번·공장 조합을 하나로 유지한다(AC-1).
 * PPAP 상태·수입검사 수준은 QMS-03 서비스만 바꾼다(사용자 FLS 읽기, 필드 이력).
 * @group CMN-00-MDM-005
 */
public with sharing class CMN_SupplierService {
  /**
   * @description 협력사 품번 외부 키 설정·중복 차단(before insert·update).
   * @param links 저장할 협력사 품번
   */
  public static void assignSupplierItemKeys(List<CMN_SupplierItem__c> links) {
    Set<Id> supplierIds = new Set<Id>();
    Set<Id> itemIds = new Set<Id>();
    Set<Id> plantIds = new Set<Id>();
    for (CMN_SupplierItem__c l : links) {
      supplierIds.add(l.Supplier__c);
      itemIds.add(l.Item__c);
      plantIds.add(l.Plant__c);
    }
    Map<Id, Account> suppliers = new Map<Id, Account>(
      CMN_SupplierSelector.suppliers(supplierIds)
    );
    Map<Id, CMN_Item__c> items = CMN_ItemSelector.itemsById(itemIds);
    Map<Id, CMN_Plant__c> plants = new Map<Id, CMN_Plant__c>(
      CMN_PlantSelector.plants(new Set<String>(), plantIds)
    );
    for (CMN_SupplierItem__c l : links) {
      Account s = suppliers.get(l.Supplier__c);
      CMN_Item__c i = items.get(l.Item__c);
      CMN_Plant__c p = plants.get(l.Plant__c);
      if (
        s == null ||
        i == null ||
        p == null ||
        String.isBlank(s.SapVendorNo__c)
      ) {
        continue;
      }
      l.ExternalKey__c =
        s.SapVendorNo__c +
        '-' +
        i.ItemNo__c +
        '-' +
        p.PlantCode__c;
    }
    CMN_KeyGuard.rejectDuplicates(
      links,
      CMN_SupplierItem__c.ExternalKey__c,
      CMN_SupplierItem__c.Item__c,
      CMN_SupplierItem__c.ExternalKey__c,
      Label.CMN_Supplier_DuplicateSupplierItem
    );
  }
}
