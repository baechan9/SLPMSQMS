/**
 * @description 제품군·품번·연결 규칙(CMN-00-MDM-004). 공장별 품번·적용 차종의 외부 키를 만들고 중복을 막으며,
 * 제품군을 2단계로 유지한다. BOM은 Salesforce에 두지 않는다(BR-2, Snowflake CORE.SAP_BOM).
 * @group CMN-00-MDM-004
 */
public with sharing class CMN_ItemService {
  /**
   * @description 공장별 품번 외부 키 = {ItemNo}-{PlantCode}, 중복 차단.
   * @param links 저장할 공장별 품번(before insert·update)
   */
  public static void assignItemPlantKeys(List<CMN_ItemPlant__c> links) {
    Set<Id> itemIds = new Set<Id>();
    Set<Id> plantIds = new Set<Id>();
    for (CMN_ItemPlant__c l : links) {
      itemIds.add(l.Item__c);
      plantIds.add(l.Plant__c);
    }
    Map<Id, CMN_Item__c> items = CMN_ItemSelector.itemsById(itemIds);
    Map<Id, CMN_Plant__c> plants = new Map<Id, CMN_Plant__c>(
      CMN_PlantSelector.plants(new Set<String>(), plantIds)
    );
    for (CMN_ItemPlant__c l : links) {
      CMN_Item__c i = items.get(l.Item__c);
      CMN_Plant__c p = plants.get(l.Plant__c);
      if (i != null && p != null) {
        l.ExternalKey__c = i.ItemNo__c + '-' + p.PlantCode__c;
      }
    }
    CMN_KeyGuard.rejectDuplicates(
      links,
      CMN_ItemPlant__c.ExternalKey__c,
      CMN_ItemPlant__c.Plant__c,
      CMN_ItemPlant__c.ExternalKey__c,
      Label.CMN_Item_DuplicateItemPlant
    );
  }

  /**
   * @description 적용 차종 외부 키 = {ItemNo}-{차종 외부 키}, 중복 차단.
   * @param links 저장할 적용 차종(before insert·update)
   */
  public static void assignItemVehicleKeys(List<CMN_ItemVehicle__c> links) {
    Set<Id> itemIds = new Set<Id>();
    Set<Id> vehicleIds = new Set<Id>();
    for (CMN_ItemVehicle__c l : links) {
      itemIds.add(l.Item__c);
      vehicleIds.add(l.Vehicle__c);
    }
    Map<Id, CMN_Item__c> items = CMN_ItemSelector.itemsById(itemIds);
    Map<Id, CMN_Vehicle__c> vehicles = CMN_ItemSelector.vehiclesById(
      vehicleIds
    );
    for (CMN_ItemVehicle__c l : links) {
      CMN_Item__c i = items.get(l.Item__c);
      CMN_Vehicle__c v = vehicles.get(l.Vehicle__c);
      if (i != null && v != null) {
        l.ExternalKey__c = i.ItemNo__c + '-' + v.ExternalKey__c;
      }
    }
    CMN_KeyGuard.rejectDuplicates(
      links,
      CMN_ItemVehicle__c.ExternalKey__c,
      CMN_ItemVehicle__c.Vehicle__c,
      CMN_ItemVehicle__c.ExternalKey__c,
      Label.CMN_Item_DuplicateItemVehicle
    );
  }

  /**
   * @description 제품군 2단계: 하위가 있는 제품군은 상위를 가질 수 없다(상위의 상위·자기 자신은 검증 규칙이 막는다).
   * @param groups 갱신할 제품군(before update)
   * @param oldMap 갱신 전
   */
  public static void keepTwoLevels(
    List<CMN_ProductGroup__c> groups,
    Map<Id, SObject> oldMap
  ) {
    Set<Id> gainedParent = new Set<Id>();
    for (CMN_ProductGroup__c g : groups) {
      Id oldParent = ((CMN_ProductGroup__c) oldMap.get(g.Id))?.Parent__c;
      if (g.Parent__c != null && g.Parent__c != oldParent) {
        gainedParent.add(g.Id);
      }
    }
    if (gainedParent.isEmpty()) {
      return;
    }
    Set<Id> withChildren = CMN_ItemSelector.groupsWithChildren(gainedParent);
    for (CMN_ProductGroup__c g : groups) {
      if (withChildren.contains(g.Id)) {
        g.addError(
          CMN_ProductGroup__c.Parent__c,
          Label.CMN_Item_GroupHasChildren
        );
      }
    }
  }
}
