/**
 * @description 법인 트리거: 삭제 금지(BR-2, 주종 관계라 법인 삭제는 공장·라인·공정까지 지운다).
 * @group CMN-00-MDM-002
 */
public with sharing class CMN_CompanyTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeDelete() {
    CMN_PlantService.preventDelete(oldRecords);
  }
}
