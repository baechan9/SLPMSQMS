trigger CMN_KpiValueTrigger on CMN_KpiValue__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_KpiValueTriggerHandler().run();
}
