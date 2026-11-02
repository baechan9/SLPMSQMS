/**
 * @description 결재 독촉 대상 조회(CMN-00-APV-005).
 * @group CMN-00-APV-005
 */
// SHARING-EXCEPTION: CMN-00-APV-005 매시 스케줄 잡이 모든 공장의 PENDING 결재 단계(요청 Private)를 찾아야 한다.
// 잡을 예약한 사용자의 공유와 무관하게 같은 결과여야 하므로 조회만 시스템 기준으로 한다.
public without sharing class CMN_ApprovalReminderSelector {
  /**
   * @description PENDING 결재 단계와 요청·결재자 정보.
   * @return 단계
   */
  public static List<CMN_ApprovalStep__c> pendingSteps() {
    return [
      SELECT
        Id,
        Approver__c,
        Approver__r.Name,
        PendingAt__c,
        LastReminderOn__c,
        LastEscalationOn__c,
        Request__c,
        Request__r.TypeCode__c,
        Request__r.Title__c,
        Request__r.TargetRecordId__c,
        Request__r.TargetRecordNo__c,
        Request__r.RecordNo__c,
        Request__r.Plant__c,
        Request__r.SubmittedAt__c
      FROM CMN_ApprovalStep__c
      WHERE Status__c = 'PENDING' AND Request__r.Status__c = 'IN_PROGRESS'
      WITH SYSTEM_MODE
      LIMIT 10000
    ];
  }
}
