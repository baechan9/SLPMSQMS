trigger CMN_SupplierItemTrigger on CMN_SupplierItem__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_SupplierItemTriggerHandler().run();
}
