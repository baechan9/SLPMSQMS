/**
 * @description CMN_ActionItem__c 트리거(CMN-00-MTG-001). 규칙은 CMN_ActionItemService. 공장 공유는 프레임워크(SEC-002).
 * @group CMN-00-MTG-001
 */
public with sharing class CMN_ActionItemTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_ActionItemService.prepare((List<CMN_ActionItem__c>) newRecords, null);
  }

  protected override void beforeUpdate() {
    CMN_ActionItemService.prepare((List<CMN_ActionItem__c>) newRecords, oldMap);
  }

  protected override void afterInsert() {
    if (!isMigrationMode()) {
      CMN_ActionItemService.afterSave(
        (List<CMN_ActionItem__c>) newRecords,
        null
      );
    }
  }

  protected override void afterUpdate() {
    if (!isMigrationMode()) {
      CMN_ActionItemService.afterSave(
        (List<CMN_ActionItem__c>) newRecords,
        oldMap
      );
    }
  }
}
