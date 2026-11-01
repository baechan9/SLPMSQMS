trigger CMN_CodeTrigger on CMN_Code__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_CodeTriggerHandler().run();
}
