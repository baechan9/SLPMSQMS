trigger CMN_PlantTrigger on CMN_Plant__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_PlantTriggerHandler().run();
}
