/**
 * @description 결재형 문서 공개 결재 콜백(CMN-00-DOC-001 BR-3). 결재 대상 = 문서(리비전은 주종 하위라 공유 객체가 없다).
 * 상신: DRAFT → IN_APPROVAL, 승인: IN_APPROVAL → RELEASED(이전 RELEASED는 SUPERSEDED), 반려: → REJECTED, 회수: → DRAFT.
 * @group CMN-00-DOC-001
 */
public with sharing class CMN_DocumentApprovalCallback implements CMN_ApprovalCallback {
  private static final Set<String> DRAFT_ONLY = new Set<String>{
    CMN_DocumentService.DRAFT
  };
  private static final Set<String> IN_APPROVAL_ONLY = new Set<String>{
    CMN_DocumentService.IN_APPROVAL
  };

  /**
   * @description 상신 가능 여부: 결재형 문서이고 작성 중 리비전이 있어야 한다.
   * @param targetId 문서
   * @return 거절 사유(가능하면 null)
   */
  public String canSubmit(Id targetId) {
    CMN_Document__c doc = CMN_DocumentSelector.documentWithRevisions(targetId);
    if (doc == null || doc.DeliverableType__c != 'APPROVAL') {
      return Label.CMN_Doc_NotApprovalType;
    }
    for (CMN_DocumentRevision__c r : doc.Revisions__r) {
      if (r.Status__c == CMN_DocumentService.DRAFT) {
        return null;
      }
    }
    return Label.CMN_Doc_NoDraftRevision;
  }

  /**
   * @description 상신: 작성 중 리비전을 결재 중으로.
   * @param request 결재 요청
   */
  public void onSubmitted(CMN_ApprovalRequest__c request) {
    CMN_DocumentService.moveRevisions(
      request.TargetRecordId__c,
      DRAFT_ONLY,
      CMN_DocumentService.IN_APPROVAL
    );
  }

  /**
   * @description 승인: 결재 중 리비전을 공개.
   * @param request 결재 요청
   */
  public void onApproved(CMN_ApprovalRequest__c request) {
    Set<Id> revisions = new Set<Id>();
    for (
      CMN_DocumentRevision__c r : CMN_DocumentSelector.documentWithRevisions(
          request.TargetRecordId__c
        )
        .Revisions__r
    ) {
      if (r.Status__c == CMN_DocumentService.IN_APPROVAL) {
        revisions.add(r.Id);
      }
    }
    CMN_DocumentService.release(revisions);
  }

  /**
   * @description 반려: 결재 중 리비전을 반려로.
   * @param request 결재 요청
   */
  public void onRejected(CMN_ApprovalRequest__c request) {
    CMN_DocumentService.moveRevisions(
      request.TargetRecordId__c,
      IN_APPROVAL_ONLY,
      CMN_DocumentService.REJECTED
    );
  }

  /**
   * @description 회수: 결재 중 리비전을 작성 중으로.
   * @param request 결재 요청
   */
  public void onRecalled(CMN_ApprovalRequest__c request) {
    CMN_DocumentService.moveRevisions(
      request.TargetRecordId__c,
      IN_APPROVAL_ONLY,
      CMN_DocumentService.DRAFT
    );
  }
}
