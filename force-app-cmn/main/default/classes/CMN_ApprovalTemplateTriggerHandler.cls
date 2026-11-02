/**
 * @description CMN_ApprovalTemplate__c 트리거: 저장 전 규칙·외부 키(CMN-00-APV-002).
 * @group CMN-00-APV-002
 */
public with sharing class CMN_ApprovalTemplateTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_ApprovalLineService.prepareTemplates(
      (List<CMN_ApprovalTemplate__c>) newRecords
    );
  }

  protected override void beforeUpdate() {
    CMN_ApprovalLineService.prepareTemplates(
      (List<CMN_ApprovalTemplate__c>) newRecords
    );
  }
}
