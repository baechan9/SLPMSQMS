trigger CMN_DocumentTrigger on CMN_Document__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_DocumentTriggerHandler().run();
}
