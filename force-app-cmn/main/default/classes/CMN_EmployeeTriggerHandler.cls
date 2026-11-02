/**
 * @description CMN_Employee__c 트리거(CMN-00-INT-002). 규칙은 CMN_EmployeeService.
 * @group CMN-00-INT-002
 */
public with sharing class CMN_EmployeeTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_EmployeeService.linkUsers((List<CMN_Employee__c>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_EmployeeService.linkUsers((List<CMN_Employee__c>) newRecords);
  }

  protected override void afterInsert() {
    if (!isMigrationMode()) {
      CMN_EmployeeService.afterSave((List<CMN_Employee__c>) newRecords, null);
    }
  }

  protected override void afterUpdate() {
    if (!isMigrationMode()) {
      CMN_EmployeeService.afterSave((List<CMN_Employee__c>) newRecords, oldMap);
    }
  }
}
