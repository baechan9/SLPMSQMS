trigger CMN_ApprovalTemplateStepTrigger on CMN_ApprovalTemplateStep__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_ApprovalTemplateStepTriggerHandler().run();
}
