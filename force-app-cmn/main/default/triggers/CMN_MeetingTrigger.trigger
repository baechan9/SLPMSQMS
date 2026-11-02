trigger CMN_MeetingTrigger on CMN_Meeting__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_MeetingTriggerHandler().run();
}
