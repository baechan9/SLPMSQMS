/**
 * @description CMN_RoleAssignment__c 트리거: 저장 전 규칙·외부 키(CMN-00-APV-002).
 * @group CMN-00-APV-002
 */
public with sharing class CMN_RoleAssignmentTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_ApprovalLineService.prepareAssignments(
      (List<CMN_RoleAssignment__c>) newRecords
    );
  }

  protected override void beforeUpdate() {
    CMN_ApprovalLineService.prepareAssignments(
      (List<CMN_RoleAssignment__c>) newRecords
    );
  }
}
