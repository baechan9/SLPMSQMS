/**
 * @description 라인 트리거: 외부 키 설정·중복 검사(BR-1), 키가 바뀌면 공정 키 재계산, 삭제 금지(BR-2).
 * @group CMN-00-MDM-002
 */
public with sharing class CMN_LineTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_PlantService.assignLineKeys((List<CMN_Line__c>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_PlantService.assignLineKeys((List<CMN_Line__c>) newRecords);
  }

  protected override void afterUpdate() {
    CMN_PlantService.refreshOperationKeys(
      (List<CMN_Line__c>) newRecords,
      oldMap
    );
  }

  protected override void beforeDelete() {
    CMN_MasterDataGuard.preventDelete(oldRecords);
  }
}
