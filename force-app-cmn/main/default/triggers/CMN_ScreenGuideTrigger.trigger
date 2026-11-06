trigger CMN_ScreenGuideTrigger on CMN_ScreenGuide__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_ScreenGuideTriggerHandler().run();
}
