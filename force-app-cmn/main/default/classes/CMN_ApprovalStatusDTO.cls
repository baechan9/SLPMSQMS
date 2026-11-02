/**
 * @description 대상 레코드의 최신 결재 상태(CMN-00-APV-001 getStatus).
 * @group CMN-00-APV-001
 */
public with sharing class CMN_ApprovalStatusDTO {
  @AuraEnabled
  public Id requestId;
  @AuraEnabled
  public String recordNo;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public Integer version;
  @AuraEnabled
  public Integer currentStepNo;
  @AuraEnabled
  public Id drafterId;
  @AuraEnabled
  public List<Step> steps = new List<Step>();

  /**
   * @description 단계.
   */
  public class Step {
    @AuraEnabled
    public Id stepId;
    @AuraEnabled
    public Integer stepNo;
    @AuraEnabled
    public String stepType;
    @AuraEnabled
    public Id approverId;
    @AuraEnabled
    public String approverName;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Id actedById;
    @AuraEnabled
    public Datetime actedAt;
    @AuraEnabled
    public String comment;
  }
}
