/**
 * @description 결재 콜백(CMN-00-APV-001 BR-8). 업무 객체의 상태 변경은 이 콜백 안에서만 한다(엔진은 업무 필드를 직접 바꾸지 않는다).
 * CMN_ApprovalType__mdt.CallbackClass__c에 구현 클래스 이름을 둔다.
 * @group CMN-00-APV-001
 */
public interface CMN_ApprovalCallback {
  /**
   * @description 상신 가능 여부.
   * @param targetId 대상 레코드
   * @return 막을 사유(Custom Label 문구), 가능하면 null
   */
  String canSubmit(Id targetId);

  /**
   * @description 상신됨.
   * @param request 결재 요청
   */
  void onSubmitted(CMN_ApprovalRequest__c request);

  /**
   * @description 최종 승인됨.
   * @param request 결재 요청
   */
  void onApproved(CMN_ApprovalRequest__c request);

  /**
   * @description 반려됨.
   * @param request 결재 요청
   */
  void onRejected(CMN_ApprovalRequest__c request);

  /**
   * @description 회수됨.
   * @param request 결재 요청
   */
  void onRecalled(CMN_ApprovalRequest__c request);
}
