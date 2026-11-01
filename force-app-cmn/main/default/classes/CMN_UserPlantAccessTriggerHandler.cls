/**
 * @description 사용자별 공장 접근 트리거(CMN-00-SEC-002): 사용자 필수·외부 키·중복, 변경 후 공장 그룹 구성원 비동기 맞춤(BR-2).
 * @group CMN-00-SEC-002
 */
public with sharing class CMN_UserPlantAccessTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    prepare((List<CMN_UserPlantAccess__c>) newRecords);
  }

  protected override void beforeUpdate() {
    prepare((List<CMN_UserPlantAccess__c>) newRecords);
  }

  protected override void afterInsert() {
    sync(newRecords);
  }

  protected override void afterUpdate() {
    List<SObject> both = new List<SObject>(newRecords);
    both.addAll(oldRecords);
    sync(both);
  }

  protected override void afterDelete() {
    sync(oldRecords);
  }

  protected override void afterUndelete() {
    sync(newRecords);
  }

  private static void prepare(List<CMN_UserPlantAccess__c> accesses) {
    Set<Id> userIds = new Set<Id>();
    Set<Id> plantIds = new Set<Id>();
    for (CMN_UserPlantAccess__c a : accesses) {
      if (a.User__c == null) {
        a.addError(
          CMN_UserPlantAccess__c.User__c,
          Label.CMN_Sharing_UserRequired
        );
        continue;
      }
      userIds.add(a.User__c);
      plantIds.add(a.Plant__c);
    }
    Map<Id, User> users = new Map<Id, User>(
      [SELECT Id, EmployeeNo__c FROM User WHERE Id IN :userIds WITH SYSTEM_MODE]
    );
    Map<Id, CMN_Plant__c> plants = new Map<Id, CMN_Plant__c>(
      CMN_PlantSelector.plants(new Set<String>(), plantIds)
    );
    for (CMN_UserPlantAccess__c a : accesses) {
      User u = users.get(a.User__c);
      CMN_Plant__c p = plants.get(a.Plant__c);
      if (u != null && p != null) {
        a.ExternalKey__c =
          (u.EmployeeNo__c ?? String.valueOf(u.Id)) +
          '-' +
          p.PlantCode__c;
      }
    }
    CMN_KeyGuard.rejectDuplicates(
      accesses,
      CMN_UserPlantAccess__c.ExternalKey__c,
      CMN_UserPlantAccess__c.Plant__c,
      CMN_UserPlantAccess__c.ExternalKey__c,
      Label.CMN_Sharing_DuplicateAccess
    );
  }

  private static void sync(List<SObject> records) {
    Set<Id> userIds = new Set<Id>();
    Set<Id> plantIds = new Set<Id>();
    for (SObject r : records) {
      CMN_UserPlantAccess__c a = (CMN_UserPlantAccess__c) r;
      if (a.User__c != null) {
        userIds.add(a.User__c);
      }
      plantIds.add(a.Plant__c);
    }
    CMN_PlantGroupService.enqueue(plantIds, userIds);
  }
}
