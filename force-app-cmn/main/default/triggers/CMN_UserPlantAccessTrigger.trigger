trigger CMN_UserPlantAccessTrigger on CMN_UserPlantAccess__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_UserPlantAccessTriggerHandler().run();
}
