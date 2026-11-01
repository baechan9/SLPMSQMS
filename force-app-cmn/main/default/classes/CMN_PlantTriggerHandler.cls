/**
 * @description 공장 트리거: 삭제 금지(BR-2). 공장 그룹 생성(SEC-002)은 그 WI가 이 핸들러에 더한다.
 * @group CMN-00-MDM-002
 */
public with sharing class CMN_PlantTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeDelete() {
    CMN_MasterDataGuard.preventDelete(oldRecords);
  }
}
