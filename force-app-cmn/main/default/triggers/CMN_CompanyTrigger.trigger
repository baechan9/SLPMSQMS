trigger CMN_CompanyTrigger on CMN_Company__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_CompanyTriggerHandler().run();
}
