trigger CMN_DelegationTrigger on CMN_Delegation__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_DelegationTriggerHandler().run();
}
