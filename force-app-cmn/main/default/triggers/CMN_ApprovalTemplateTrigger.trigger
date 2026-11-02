trigger CMN_ApprovalTemplateTrigger on CMN_ApprovalTemplate__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_ApprovalTemplateTriggerHandler().run();
}
