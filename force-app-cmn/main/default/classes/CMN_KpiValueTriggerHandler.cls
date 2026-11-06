/**
 * @description CMN_KpiValue__c 트리거(CMN-00-DWH-003). 규칙은 CMN_KpiValueService.
 * @group CMN-00-DWH-003
 */
public with sharing class CMN_KpiValueTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_KpiValueService.prepare((List<CMN_KpiValue__c>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_KpiValueService.prepare((List<CMN_KpiValue__c>) newRecords);
  }
}
