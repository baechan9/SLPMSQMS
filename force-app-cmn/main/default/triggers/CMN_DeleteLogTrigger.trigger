trigger CMN_DeleteLogTrigger on CMN_DeleteLog__c(
  before insert,
  before update,
  before delete
) {
  new CMN_DeleteLogTriggerHandler().run();
}
