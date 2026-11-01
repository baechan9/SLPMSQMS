/**
 * @description 삭제 기록 보호(CMN-00-SEC-003 BR-2): 누구도 수정·삭제할 수 없고, 삭제 통제 서비스만 만든다.
 * 핸들러 우회·비활성 설정으로 풀리지 않게 공통 트리거 프레임워크(CMN_TriggerHandler)를 쓰지 않는다.
 * @group CMN-00-SEC-003
 */
public with sharing class CMN_DeleteLogTriggerHandler {
  /**
   * @description 트리거 진입점.
   */
  public void run() {
    if (
      Trigger.isBefore &&
      Trigger.isInsert &&
      CMN_DeleteGuardService.isWriting()
    ) {
      return;
    }
    for (SObject r : Trigger.isDelete ? Trigger.old : Trigger.new) {
      r.addError(Label.CMN_Delete_LogReadOnly);
    }
  }
}
