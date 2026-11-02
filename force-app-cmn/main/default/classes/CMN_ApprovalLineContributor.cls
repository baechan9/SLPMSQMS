/**
 * @description 결재 유형별 결재선 보정(CMN-00-APV-002, 검토 반영 Vol.2 DVQ-005 BR-4·DVQ-008 BR-5).
 * 템플릿으로 해석한 결재선에 업무 규칙상 필요한 단계를 더하거나 바꾼다. CMN_ApprovalType__mdt.LineContributorClass__c에 등록한다.
 * @group CMN-00-APV-002
 */
public interface CMN_ApprovalLineContributor {
  /**
   * @description 결재선 보정.
   * @param targetId 대상 레코드
   * @param typeCode 결재 유형
   * @param line 템플릿 해석 결과
   * @return 보정한 결재선
   */
  List<CMN_ApprovalStepSpec> contribute(
    Id targetId,
    String typeCode,
    List<CMN_ApprovalStepSpec> line
  );
}
