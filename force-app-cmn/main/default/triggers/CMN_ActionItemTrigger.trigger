trigger CMN_ActionItemTrigger on CMN_ActionItem__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_ActionItemTriggerHandler().run();
}
