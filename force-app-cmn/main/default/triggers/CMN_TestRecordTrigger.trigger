trigger CMN_TestRecordTrigger on CMN_TestRecord__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_TestRecordTriggerHandler().run();
}
