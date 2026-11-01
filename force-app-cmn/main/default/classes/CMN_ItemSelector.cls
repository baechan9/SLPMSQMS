/**
 * @description 제품군·품번 조회(CMN-00-MDM-004). 기준정보는 사내 전체 공개라 시스템 모드로 읽는다.
 * @group CMN-00-MDM-004
 */
public with sharing class CMN_ItemSelector {
  /**
   * @description 품번 Id → 품번.
   * @param ids 품번 Id
   * @return 품번 맵
   */
  public static Map<Id, CMN_Item__c> itemsById(Set<Id> ids) {
    return new Map<Id, CMN_Item__c>(
      [
        SELECT Id, ItemNo__c, ItemType__c, ProductGroup__c, Customer__c
        FROM CMN_Item__c
        WHERE Id IN :ids
        WITH SYSTEM_MODE
      ]
    );
  }

  /**
   * @description 차종 Id → 차종(외부 키).
   * @param ids 차종 Id
   * @return 차종 맵
   */
  public static Map<Id, CMN_Vehicle__c> vehiclesById(Set<Id> ids) {
    return new Map<Id, CMN_Vehicle__c>(
      [
        SELECT Id, ExternalKey__c
        FROM CMN_Vehicle__c
        WHERE Id IN :ids
        WITH SYSTEM_MODE
      ]
    );
  }

  /**
   * @description 하위 제품군이 있는 제품군 Id.
   * @param ids 제품군 Id
   * @return 하위가 있는 Id
   */
  public static Set<Id> groupsWithChildren(Set<Id> ids) {
    Set<Id> out = new Set<Id>();
    for (CMN_ProductGroup__c g : [
      SELECT Parent__c
      FROM CMN_ProductGroup__c
      WHERE Parent__c IN :ids
      WITH SYSTEM_MODE
    ]) {
      out.add(g.Parent__c);
    }
    return out;
  }
}
