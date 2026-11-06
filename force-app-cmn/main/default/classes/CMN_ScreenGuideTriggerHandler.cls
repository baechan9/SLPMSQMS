/**
 * @description CMN_ScreenGuide__c 트리거(CMN-00-UX-002). 규칙은 CMN_ScreenGuideService.
 * @group CMN-00-UX-002
 */
public with sharing class CMN_ScreenGuideTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_ScreenGuideService.prepare((List<CMN_ScreenGuide__c>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_ScreenGuideService.prepare((List<CMN_ScreenGuide__c>) newRecords);
  }
}
