trigger CMN_CommentTrigger on CMN_Comment__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_CommentTriggerHandler().run();
}
