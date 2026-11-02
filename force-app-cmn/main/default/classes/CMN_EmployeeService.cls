/**
 * @description HR 임직원 동기화 규칙(CMN-00-INT-002). Mule이 부서(상위 → 하위) → 임직원 순으로 upsert하면(BR-1)
 * 이 서비스가 라이선스 사용자를 연결하고 사용자 필드를 맞춘다.
 * - 연결: User__c가 비면 같은 사번의 사용자를 연결한다.
 * - 사용자 갱신(BR-1): 부서 코드·직급·재직 상태·메일. 퇴직이면 비활성화(BR-2). 사용자(설정 객체)와 임직원을 한 트랜잭션에서
 *   함께 저장할 수 없어(Mixed DML) CMN_EmployeeUserSyncJob(Queueable)이 한다. FederationIdentifier = 사번은 사용자 트리거(TDO-002)가 맞춘다.
 * - 퇴직 알림(BR-2): 연결 사용자의 진행 중 To-Do·결재 대기 건수를 부서장(없으면 시스템 관리자)에게 알린다.
 * - 이관 모드(데모·이관 적재)에서는 사용자 갱신·알림을 하지 않는다.
 * @group CMN-00-INT-002
 */
public with sharing class CMN_EmployeeService {
  public static final String RETIRED = 'RETIRED';
  public static final String RETIRED_EVENT = 'CMN_EMPLOYEE_RETIRED';

  /**
   * @description 사용자 연결(같은 사번).
   * @param employees 저장할 임직원
   */
  public static void linkUsers(List<CMN_Employee__c> employees) {
    Set<String> numbers = new Set<String>();
    for (CMN_Employee__c e : employees) {
      if (e.User__c == null && String.isNotBlank(e.EmployeeNo__c)) {
        numbers.add(e.EmployeeNo__c);
      }
    }
    if (numbers.isEmpty()) {
      return;
    }
    Map<String, Id> byNo = new Map<String, Id>();
    for (User u : CMN_EmployeeSelector.usersByEmployeeNo(numbers)) {
      byNo.put(u.EmployeeNo__c, u.Id);
    }
    for (CMN_Employee__c e : employees) {
      if (e.User__c == null) {
        e.User__c = byNo.get(e.EmployeeNo__c);
      }
    }
  }

  /**
   * @description 저장 후: 사용자 갱신 작업 등록, 새 퇴직자 알림.
   * @param employees 저장된 임직원
   * @param oldMap 이전 값(삽입이면 null)
   */
  public static void afterSave(
    List<CMN_Employee__c> employees,
    Map<Id, SObject> oldMap
  ) {
    Set<Id> sync = new Set<Id>();
    List<CMN_Employee__c> newlyRetired = new List<CMN_Employee__c>();
    for (CMN_Employee__c e : employees) {
      if (e.User__c == null) {
        continue;
      }
      CMN_Employee__c old = (CMN_Employee__c) oldMap?.get(e.Id);
      if (
        old == null ||
        old.Department__c != e.Department__c ||
        old.JobGradeCode__c != e.JobGradeCode__c ||
        old.HrStatus__c != e.HrStatus__c ||
        old.Email__c != e.Email__c ||
        old.User__c != e.User__c
      ) {
        sync.add(e.Id);
      }
      if (e.HrStatus__c == RETIRED && old?.HrStatus__c != RETIRED) {
        newlyRetired.add(e);
      }
    }
    if (!newlyRetired.isEmpty()) {
      notifyRetired(newlyRetired);
    }
    if (!sync.isEmpty()) {
      System.enqueueJob(new CMN_EmployeeUserSyncJob(sync));
    }
  }

  /** BR-2: 연결 사용자의 남은 업무 건수를 부서장에게 알린다(부서장이 없으면 시스템 관리자). */
  private static void notifyRetired(List<CMN_Employee__c> employees) {
    Set<Id> users = new Set<Id>();
    Set<Id> departments = new Set<Id>();
    for (CMN_Employee__c e : employees) {
      users.add(e.User__c);
      departments.add(e.Department__c);
    }
    Map<Id, Integer> todos = CMN_EmployeeSelector.openTodoCounts(users);
    Map<Id, Integer> approvals = CMN_EmployeeSelector.pendingApprovalCounts(
      users
    );
    Map<Id, CMN_Department__c> depts = CMN_EmployeeSelector.departments(
      departments
    );
    Set<Id> admins;
    List<CMN_NotificationService.Message> messages = new List<CMN_NotificationService.Message>();
    for (CMN_Employee__c e : employees) {
      Id manager = depts.get(e.Department__c)?.Manager__c;
      Set<Id> recipients = new Set<Id>();
      if (manager != null && manager != e.User__c) {
        recipients.add(manager);
      } else {
        admins = admins ?? CMN_InterfaceLogService.adminUsers();
        recipients.addAll(admins);
      }
      messages.add(
        new CMN_NotificationService.Message(
          RETIRED_EVENT,
          recipients,
          e.Id,
          new Map<String, String>{
            'EmployeeName' => e.Name,
            'EmployeeNo' => e.EmployeeNo__c,
            'OpenTodos' => String.valueOf(todos.get(e.User__c) ?? 0),
            'PendingApprovals' => String.valueOf(approvals.get(e.User__c) ?? 0)
          }
        )
      );
    }
    CMN_NotificationService.send(messages);
  }
}
