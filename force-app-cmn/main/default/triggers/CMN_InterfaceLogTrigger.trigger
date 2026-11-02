trigger CMN_InterfaceLogTrigger on CMN_InterfaceLog__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_InterfaceLogTriggerHandler().run();
}
