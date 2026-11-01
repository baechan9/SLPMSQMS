trigger CMN_CodeGroupTrigger on CMN_CodeGroup__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_CodeGroupTriggerHandler().run();
}
