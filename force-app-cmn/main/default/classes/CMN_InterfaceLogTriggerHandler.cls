/**
 * @description CMN_InterfaceLog__c 트리거(CMN-00-INT-001). 규칙은 CMN_InterfaceLogService.
 * @group CMN-00-INT-001
 */
public with sharing class CMN_InterfaceLogTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_InterfaceLogService.prepare((List<CMN_InterfaceLog__c>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_InterfaceLogService.prepare((List<CMN_InterfaceLog__c>) newRecords);
  }

  protected override void afterInsert() {
    if (!isMigrationMode()) {
      CMN_InterfaceLogService.alertFailures(
        (List<CMN_InterfaceLog__c>) newRecords,
        null
      );
    }
  }

  protected override void afterUpdate() {
    if (!isMigrationMode()) {
      CMN_InterfaceLogService.alertFailures(
        (List<CMN_InterfaceLog__c>) newRecords,
        oldMap
      );
    }
  }
}
