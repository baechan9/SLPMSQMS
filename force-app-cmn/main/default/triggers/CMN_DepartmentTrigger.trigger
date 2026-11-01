trigger CMN_DepartmentTrigger on CMN_Department__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_DepartmentTriggerHandler().run();
}
