/**
 * @description To-Do 조회(CMN-00-TDO-001).
 * @group CMN-00-TDO-001
 */
// SHARING-EXCEPTION: CMN-00-TDO-001 To-Do는 OWD Private이고 Owner = Assignee다(BR-1). To-Do를 여닫는 쪽은 처리자가 아닌
// 다른 사용자(업무 담당자, 결재 이벤트 구독의 자동 프로세스 사용자)라 남의 To-Do를 볼 수 없다. 중복 판정·종료 대상 찾기에 필요한
// 키·상태·처리자 사번만 읽고, 결과를 화면에 돌려주지 않는다.
public without sharing class CMN_TodoSelector {
  /**
   * @description 처리자와, 처리자의 같은 키 To-Do(중복 판정). 하위 조회로 SOQL 1회.
   * @param userIds 처리자
   * @param keys ExternalKey
   * @return 처리자 Id → 사용자(Todos__r 포함)
   */
  public static Map<Id, User> assigneesWithTodos(
    Set<Id> userIds,
    Set<String> keys
  ) {
    return new Map<Id, User>(
      [
        SELECT
          Id,
          IsActive,
          UserType,
          EmployeeNo__c,
          (
            SELECT Id, ExternalKey__c, Status__c
            FROM Todos__r
            WHERE ExternalKey__c IN :keys
          )
        FROM User
        WHERE Id IN :userIds
        WITH SYSTEM_MODE
      ]
    );
  }

  /**
   * @description 원천 레코드의 OPEN To-Do.
   * @param sourceType 원천 유형
   * @param sourceIds 원천 레코드 Id(18자)
   * @param assigneeOrNull 처리자(null이면 전체)
   * @return To-Do
   */
  public static List<CMN_Todo__c> openBySource(
    String sourceType,
    Set<String> sourceIds,
    Id assigneeOrNull
  ) {
    return Database.queryWithBinds(
      'SELECT Id, Assignee__c, Assignee__r.EmployeeNo__c FROM CMN_Todo__c' +
        ' WHERE SourceType__c = :sourceType AND SourceRecordId__c IN :sourceIds' +
        ' AND Status__c = \'OPEN\'' +
        (assigneeOrNull == null ? '' : ' AND Assignee__c = :assignee'),
      new Map<String, Object>{
        'sourceType' => sourceType,
        'sourceIds' => sourceIds,
        'assignee' => assigneeOrNull
      },
      AccessLevel.SYSTEM_MODE
    );
  }

  /**
   * @description 결재 이벤트 구독용 단계(요청 정보·기안자 포함, To-Do·알림 공용). 단계 Id 또는 요청 Id로 찾는다.
   * @param stepIds 단계
   * @param requestIds 요청(요청의 모든 단계)
   * @return 단계
   */
  public static List<CMN_ApprovalStep__c> approvalSteps(
    Set<Id> stepIds,
    Set<Id> requestIds
  ) {
    return [
      SELECT
        Id,
        Status__c,
        Approver__c,
        Approver__r.IsActive,
        Request__c,
        Request__r.CreatedById,
        Request__r.Title__c,
        Request__r.RecordNo__c,
        Request__r.TargetRecordId__c,
        Request__r.TargetObject__c,
        Request__r.TargetRecordNo__c,
        Request__r.Plant__c
      FROM CMN_ApprovalStep__c
      WHERE Id IN :stepIds OR Request__c IN :requestIds
      WITH SYSTEM_MODE
    ];
  }
}
