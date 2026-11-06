/**
 * @description AI 추천 적중 규칙(CMN-00-AI-004 BR-1). 업무 WI가 UseCase별로 구현한다
 * (예: RCA는 원인 코드 리프 일치 = 적중). CMN_AiRecommendationService.finalize가 추천마다 부른다.
 * @group CMN-00-AI-004
 */
public interface CMN_AiHitRule {
  /**
   * @description 추천이 업무 확정 결과와 일치하는가.
   * @param recommendation 추천(ContentJson__c·Rank__c·Status__c 포함)
   * @param outcomeJson 업무 확정 결과(JSON)
   * @return 적중이면 true
   */
  Boolean isHit(CMN_AiRecommendation__c recommendation, String outcomeJson);
}
