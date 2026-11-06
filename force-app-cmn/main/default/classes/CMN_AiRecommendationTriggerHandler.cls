/**
 * @description CMN_AiRecommendation__c 트리거(CMN-00-AI-004). 공장 공유(SEC-002)는 기반 클래스가 저장 후에 맞춘다.
 * 기록·결정·확정 규칙은 CMN_AiRecommendationService에만 있다(트리거에서 상태를 바꾸지 않는다).
 * @group CMN-00-AI-004
 */
public with sharing class CMN_AiRecommendationTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_AiRecommendationService.prepare(
      (List<CMN_AiRecommendation__c>) newRecords
    );
  }
}
