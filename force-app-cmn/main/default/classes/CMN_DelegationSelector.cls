/**
 * @description 결재 위임 조회(CMN-00-APV-004).
 * @group CMN-00-APV-004
 */
// SHARING-EXCEPTION: CMN-00-APV-004 BR-5 위임을 등록하는 사람(위임자·부서장)은 위임자가 받은 결재 요청(Private)을 다 볼 수 없다.
// 위임 즉시 대리인 To-Do를 만들려면 위임자의 PENDING 단계를 공유와 무관하게 찾아야 한다. 단계·요청 키만 읽고 화면에 돌려주지 않는다.
public without sharing class CMN_DelegationSelector {
  /**
   * @description 사용자(활성·사번·시간대).
   * @param userIds 사용자
   * @return 사용자 맵
   */
  public static Map<Id, User> users(Set<Id> userIds) {
    return new Map<Id, User>(
      [
        SELECT Id, IsActive, EmployeeNo__c, TimeZoneSidKey
        FROM User
        WHERE Id IN :userIds
        WITH SYSTEM_MODE
      ]
    );
  }

  /**
   * @description 위임자들의 해당 시각 유효 위임.
   * @param delegatorIds 위임자
   * @param at 시각
   * @return 위임
   */
  public static List<CMN_Delegation__c> activeAt(
    Set<Id> delegatorIds,
    Datetime at
  ) {
    return [
      SELECT Id, Delegator__c, Delegate__c, TypeCodes__c
      FROM CMN_Delegation__c
      WHERE
        Delegator__c IN :delegatorIds
        AND StartAt__c <= :at
        AND EndAt__c > :at
        AND Delegate__r.IsActive = TRUE
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 위임자들의 PENDING 결재 단계(요청 정보 포함).
   * @param approverIds 결재자(위임자)
   * @return 단계
   */
  public static List<CMN_ApprovalStep__c> pendingStepsOf(Set<Id> approverIds) {
    return [
      SELECT
        Id,
        Approver__c,
        Request__c,
        Request__r.TypeCode__c,
        Request__r.Title__c,
        Request__r.RecordNo__c,
        Request__r.TargetRecordId__c,
        Request__r.TargetObject__c,
        Request__r.TargetRecordNo__c,
        Request__r.Plant__c
      FROM CMN_ApprovalStep__c
      WHERE Approver__c IN :approverIds AND Status__c = 'PENDING'
      WITH SYSTEM_MODE
    ];
  }
}
