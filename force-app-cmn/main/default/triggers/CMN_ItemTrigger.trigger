trigger CMN_ItemTrigger on CMN_Item__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_ItemTriggerHandler().run();
}
