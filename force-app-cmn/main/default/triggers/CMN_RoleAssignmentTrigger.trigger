trigger CMN_RoleAssignmentTrigger on CMN_RoleAssignment__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_RoleAssignmentTriggerHandler().run();
}
