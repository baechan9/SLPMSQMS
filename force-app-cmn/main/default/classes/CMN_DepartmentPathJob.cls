/**
 * @description 하위 부서 전체 경로 재계산(CMN-00-MDM-001 AC-2). 부서 이동·이름 변경 후 비동기로 실행한다.
 * 경로만 바꾸므로 부서 트리거가 다시 이 작업을 넣지 않는다(이름·상위 변경 없음).
 * @group CMN-00-MDM-001
 */
public with sharing class CMN_DepartmentPathJob implements Queueable {
  private final Set<Id> roots;

  /**
   * @description 재계산 대상.
   * @param roots 이동·이름 변경된 부서
   */
  public CMN_DepartmentPathJob(Set<Id> roots) {
    this.roots = roots;
  }

  /**
   * @description 하위 경로를 다시 계산해 바뀐 것만 저장한다.
   * @param context Queueable 문맥
   */
  public void execute(QueueableContext context) {
    List<CMN_Department__c> changed = CMN_DepartmentService.recalculateDescendants(
      roots
    );
    if (!changed.isEmpty()) {
      Database.update(changed, AccessLevel.SYSTEM_MODE);
    }
  }
}
