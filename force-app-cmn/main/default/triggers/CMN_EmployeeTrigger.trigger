trigger CMN_EmployeeTrigger on CMN_Employee__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_EmployeeTriggerHandler().run();
}
