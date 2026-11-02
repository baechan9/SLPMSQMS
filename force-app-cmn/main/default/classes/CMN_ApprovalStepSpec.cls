/**
 * @description 상신할 결재선 한 줄(CMN-00-APV-001). 같은 stepNo는 병렬(모두 승인 필요), CC는 통보만.
 * @group CMN-00-APV-001
 */
public with sharing class CMN_ApprovalStepSpec {
  @AuraEnabled
  public Integer stepNo;
  @AuraEnabled
  public String stepType;
  @AuraEnabled
  public Id approverId;
  @AuraEnabled
  public String roleCode;

  /**
   * @description 빈 결재선 줄(화면에서 역직렬화).
   */
  public CMN_ApprovalStepSpec() {
    this.stepNo = null;
  }

  /**
   * @description 결재선 줄.
   * @param stepNo 순서
   * @param stepType REVIEW·AGREE·APPROVE·CC
   * @param approverId 결재자
   * @param roleCode Role로 해석한 경우 원본 Role(없으면 null)
   */
  public CMN_ApprovalStepSpec(
    Integer stepNo,
    String stepType,
    Id approverId,
    String roleCode
  ) {
    this.stepNo = stepNo;
    this.stepType = stepType;
    this.approverId = approverId;
    this.roleCode = roleCode;
  }
}
