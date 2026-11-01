trigger CMN_CharacteristicTrigger on CMN_Characteristic__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_CharacteristicTriggerHandler().run();
}
