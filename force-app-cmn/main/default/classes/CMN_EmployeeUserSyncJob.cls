/**
 * @description 임직원 → 연결 사용자 필드 갱신(CMN-00-INT-002 BR-1·BR-2). 사용자는 설정 객체라 임직원 저장과 다른 트랜잭션에서 저장한다.
 * 부서 코드·직급·재직 상태·메일을 맞추고, 퇴직이면 비활성화한다. 실패한 사용자는 로그로 남기고 나머지는 저장한다.
 * @group CMN-00-INT-002
 */
public with sharing class CMN_EmployeeUserSyncJob implements Queueable {
  private Set<Id> employeeIds;

  /**
   * @description 동기화할 임직원.
   * @param employeeIds 임직원 Id
   */
  public CMN_EmployeeUserSyncJob(Set<Id> employeeIds) {
    this.employeeIds = employeeIds;
  }

  /**
   * @description 사용자 갱신.
   * @param context Queueable 문맥
   */
  public void execute(QueueableContext context) {
    List<User> users = new List<User>();
    for (CMN_Employee__c e : CMN_EmployeeSelector.forUserSync(employeeIds)) {
      User u = new User(
        Id = e.User__c,
        DepartmentCode__c = e.Department__r?.DeptCode__c,
        JobGradeCode__c = e.JobGradeCode__c,
        HrStatus__c = e.HrStatus__c
      );
      if (String.isNotBlank(e.Email__c)) {
        u.Email = e.Email__c;
      }
      if (e.HrStatus__c == CMN_EmployeeService.RETIRED) {
        u.IsActive = false;
      }
      users.add(u);
    }
    List<Database.SaveResult> results = Database.update(
      users,
      false,
      AccessLevel.SYSTEM_MODE
    );
    for (Integer i = 0; i < results.size(); i++) {
      if (!results[i].isSuccess()) {
        CMN_Logger.error(
          'CMN_EmployeeUserSyncJob',
          results[i].getErrors()[0].getMessage(),
          users[i].Id
        );
      }
    }
  }
}
