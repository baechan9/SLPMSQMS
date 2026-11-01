trigger CMN_OperationTrigger on CMN_Operation__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_OperationTriggerHandler().run();
}
