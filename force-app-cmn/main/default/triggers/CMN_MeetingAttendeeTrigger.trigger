trigger CMN_MeetingAttendeeTrigger on CMN_MeetingAttendee__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_MeetingAttendeeTriggerHandler().run();
}
