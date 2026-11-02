trigger CMN_DocumentRevisionTrigger on CMN_DocumentRevision__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_TriggerHandler().run();
}
