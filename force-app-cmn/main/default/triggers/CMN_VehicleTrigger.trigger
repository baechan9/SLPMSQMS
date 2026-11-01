trigger CMN_VehicleTrigger on CMN_Vehicle__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_VehicleTriggerHandler().run();
}
