trigger CMN_ItemPlantTrigger on CMN_ItemPlant__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_ItemPlantTriggerHandler().run();
}
