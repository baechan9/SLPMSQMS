trigger CMN_ItemVehicleTrigger on CMN_ItemVehicle__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_ItemVehicleTriggerHandler().run();
}
