/**
 * @description 결재 요청 트리거: 채번 APV-{YYYY}-{SEQ:7}(ARC-003). 공장 공유·삭제 통제는 프레임워크가 설정으로 처리한다.
 * @group CMN-00-APV-001
 */
public with sharing class CMN_ApprovalRequestTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_NumberingService.assign(newRecords);
  }
}
