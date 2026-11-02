/**
 * @description 결재 요청·단계 조회(CMN-00-APV-001). 결재자는 다른 공장 사용자일 수 있고 엔진이 상태를 관리하므로 시스템 모드로 읽는다.
 * @group CMN-00-APV-001
 */
public with sharing class CMN_ApprovalSelector {
  /**
   * @description 요청과 단계(잠금: 같은 요청을 동시에 처리하지 않게).
   * @param requestId 요청
   * @return 요청(단계 포함)
   */
  public static CMN_ApprovalRequest__c requestForUpdate(Id requestId) {
    List<CMN_ApprovalRequest__c> found = [
      SELECT
        Id,
        RecordNo__c,
        TypeCode__c,
        TargetRecordId__c,
        TargetObject__c,
        Status__c,
        CurrentStepNo__c,
        Version__c,
        CreatedById,
        Title__c
      FROM CMN_ApprovalRequest__c
      WHERE Id = :requestId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    return found.isEmpty() ? null : found[0];
  }

  /**
   * @description 요청의 단계(순서대로).
   * @param requestId 요청
   * @return 단계 목록
   */
  public static List<CMN_ApprovalStep__c> steps(Id requestId) {
    return [
      SELECT
        Id,
        Request__c,
        StepNo__c,
        StepType__c,
        Approver__c,
        Approver__r.Name,
        Status__c,
        ActedBy__c,
        ActedAt__c,
        Comment__c
      FROM CMN_ApprovalStep__c
      WHERE Request__c = :requestId
      WITH SYSTEM_MODE
      ORDER BY StepNo__c, Name
    ];
  }

  /**
   * @description 단계 하나.
   * @param stepId 단계
   * @return 단계(없으면 null)
   */
  public static CMN_ApprovalStep__c step(Id stepId) {
    List<CMN_ApprovalStep__c> found = [
      SELECT Id, Request__c, Status__c, Approver__c
      FROM CMN_ApprovalStep__c
      WHERE Id = :stepId
      WITH SYSTEM_MODE
    ];
    return found.isEmpty() ? null : found[0];
  }

  /**
   * @description 대상의 요청(최신 차수 먼저).
   * @param targetId 대상 레코드
   * @return 요청 목록
   */
  public static List<CMN_ApprovalRequest__c> requestsOf(Id targetId) {
    return [
      SELECT
        Id,
        RecordNo__c,
        Status__c,
        Version__c,
        CurrentStepNo__c,
        CreatedById
      FROM CMN_ApprovalRequest__c
      WHERE TargetRecordId__c = :String.valueOf(targetId)
      WITH SYSTEM_MODE
      ORDER BY Version__c DESC
    ];
  }

  /**
   * @description 활성 사용자 Id.
   * @param userIds 사용자
   * @return 그중 활성 사용자
   */
  public static Set<Id> activeUsers(Set<Id> userIds) {
    return new Map<Id, User>(
        [
          SELECT Id
          FROM User
          WHERE Id IN :userIds AND IsActive = TRUE
          WITH SYSTEM_MODE
        ]
      )
      .keySet();
  }
}
