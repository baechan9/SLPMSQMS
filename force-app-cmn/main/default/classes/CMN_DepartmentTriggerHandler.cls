/**
 * @description 부서 트리거: 순환 참조 차단·경로 계산(BR-2), 하위 경로 비동기 재계산(AC-2), 삭제 금지(BR-1).
 * @group CMN-00-MDM-001
 */
public with sharing class CMN_DepartmentTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_DepartmentService.validateAndAssignPaths(
      (List<CMN_Department__c>) newRecords
    );
  }

  protected override void beforeUpdate() {
    CMN_DepartmentService.validateAndAssignPaths(
      (List<CMN_Department__c>) newRecords
    );
  }

  protected override void afterUpdate() {
    CMN_DepartmentService.refreshDescendantsAsync(
      (List<CMN_Department__c>) newRecords,
      oldMap
    );
  }

  protected override void beforeDelete() {
    CMN_MasterDataGuard.preventDelete(oldRecords);
  }
}
