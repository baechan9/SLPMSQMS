trigger CMN_AiRecommendationTrigger on CMN_AiRecommendation__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  new CMN_AiRecommendationTriggerHandler().run();
}
