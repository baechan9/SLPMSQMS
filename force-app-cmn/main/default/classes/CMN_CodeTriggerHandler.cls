/**
 * @description 공통 코드 트리거: 단계·키·경로(BR-2), 하위 재계산, 참조 중 삭제 금지(BR-1).
 * @group CMN-00-MDM-007
 */
public with sharing class CMN_CodeTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_CodeService.prepare((List<CMN_Code__c>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_CodeService.prepare((List<CMN_Code__c>) newRecords);
  }

  protected override void afterUpdate() {
    CMN_CodeService.refreshDescendants((List<CMN_Code__c>) newRecords, oldMap);
  }

  protected override void beforeDelete() {
    CMN_CodeService.preventDeleteIfReferenced((List<CMN_Code__c>) oldRecords);
  }
}
