/**
 * @description CMN_Delegation__c 트리거(CMN-00-APV-004). 규칙은 CMN_DelegationService.
 * @group CMN-00-APV-004
 */
public with sharing class CMN_DelegationTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_DelegationService.prepare((List<CMN_Delegation__c>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_DelegationService.prepare((List<CMN_Delegation__c>) newRecords);
  }

  protected override void afterInsert() {
    if (!isMigrationMode()) {
      CMN_DelegationService.openForPendingSteps(
        (List<CMN_Delegation__c>) newRecords
      );
    }
  }

  protected override void afterUpdate() {
    if (!isMigrationMode()) {
      CMN_DelegationService.openForPendingSteps(
        (List<CMN_Delegation__c>) newRecords
      );
    }
  }
}
