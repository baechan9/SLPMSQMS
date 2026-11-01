trigger CMN_LineTrigger on CMN_Line__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_LineTriggerHandler().run();
}
