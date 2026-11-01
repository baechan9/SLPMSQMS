trigger CMN_ProductGroupTrigger on CMN_ProductGroup__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_ProductGroupTriggerHandler().run();
}
