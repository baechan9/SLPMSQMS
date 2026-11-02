/**
 * @description 임직원 동기화 조회(CMN-00-INT-002).
 * @group CMN-00-INT-002
 */
// SHARING-EXCEPTION: CMN-00-INT-002 BR-2 퇴직자 업무 이관 알림에 필요한 남의 To-Do(Owner = 처리자, Private)·결재 단계(요청 Private)
// 건수를 HR 연계 통합 사용자 문맥에서 세야 한다. 건수만 읽고 레코드 내용은 돌려주지 않는다.
public without sharing class CMN_EmployeeSelector {
  /**
   * @description 사번으로 사용자.
   * @param employeeNos 사번
   * @return 사용자
   */
  public static List<User> usersByEmployeeNo(Set<String> employeeNos) {
    return [
      SELECT Id, EmployeeNo__c
      FROM User
      WHERE EmployeeNo__c IN :employeeNos
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 동기화할 임직원과 부서 코드.
   * @param employeeIds 임직원
   * @return 임직원
   */
  public static List<CMN_Employee__c> forUserSync(Set<Id> employeeIds) {
    return [
      SELECT
        Id,
        User__c,
        Email__c,
        JobGradeCode__c,
        HrStatus__c,
        Department__r.DeptCode__c
      FROM CMN_Employee__c
      WHERE Id IN :employeeIds AND User__c != NULL
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 사용자별 진행 중 To-Do 건수.
   * @param userIds 사용자
   * @return 사용자 Id → 건수
   */
  public static Map<Id, Integer> openTodoCounts(Set<Id> userIds) {
    Map<Id, Integer> out = new Map<Id, Integer>();
    for (AggregateResult r : [
      SELECT Assignee__c a, COUNT(Id) n
      FROM CMN_Todo__c
      WHERE Assignee__c IN :userIds AND Status__c = 'OPEN'
      WITH SYSTEM_MODE
      GROUP BY Assignee__c
    ]) {
      out.put((Id) r.get('a'), (Integer) r.get('n'));
    }
    return out;
  }

  /**
   * @description 사용자별 결재 대기(PENDING) 단계 건수.
   * @param userIds 사용자
   * @return 사용자 Id → 건수
   */
  public static Map<Id, Integer> pendingApprovalCounts(Set<Id> userIds) {
    Map<Id, Integer> out = new Map<Id, Integer>();
    for (AggregateResult r : [
      SELECT Approver__c a, COUNT(Id) n
      FROM CMN_ApprovalStep__c
      WHERE Approver__c IN :userIds AND Status__c = 'PENDING'
      WITH SYSTEM_MODE
      GROUP BY Approver__c
    ]) {
      out.put((Id) r.get('a'), (Integer) r.get('n'));
    }
    return out;
  }

  /**
   * @description 부서(부서장).
   * @param departmentIds 부서
   * @return 부서 맵
   */
  public static Map<Id, CMN_Department__c> departments(Set<Id> departmentIds) {
    return new Map<Id, CMN_Department__c>(
      [
        SELECT Id, Manager__c
        FROM CMN_Department__c
        WHERE Id IN :departmentIds
        WITH SYSTEM_MODE
      ]
    );
  }
}
