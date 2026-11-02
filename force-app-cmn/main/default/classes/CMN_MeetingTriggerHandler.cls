/**
 * @description CMN_Meeting__c 트리거(CMN-00-MTG-001). 규칙은 CMN_MeetingService. 공장 공유는 프레임워크(SEC-002).
 * @group CMN-00-MTG-001
 */
public with sharing class CMN_MeetingTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_MeetingService.prepare((List<CMN_Meeting__c>) newRecords, null);
  }

  protected override void beforeUpdate() {
    CMN_MeetingService.prepare((List<CMN_Meeting__c>) newRecords, oldMap);
  }

  protected override void afterInsert() {
    if (!isMigrationMode()) {
      CMN_MeetingService.afterSave((List<CMN_Meeting__c>) newRecords, null);
    }
  }

  protected override void afterUpdate() {
    if (!isMigrationMode()) {
      CMN_MeetingService.afterSave((List<CMN_Meeting__c>) newRecords, oldMap);
    }
  }
}
