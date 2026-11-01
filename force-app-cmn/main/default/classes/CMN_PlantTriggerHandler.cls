/**
 * @description 공장 트리거: 삭제 금지(MDM-002 BR-2), 공장 그룹(읽기·편집) 자동 생성(SEC-002, 비동기).
 * @group CMN-00-MDM-002
 */
public with sharing class CMN_PlantTriggerHandler extends CMN_TriggerHandler {
  protected override void afterInsert() {
    CMN_PlantGroupService.enqueue(
      new Map<Id, SObject>(newRecords).keySet(),
      new Set<Id>()
    );
  }

  protected override void beforeDelete() {
    CMN_MasterDataGuard.preventDelete(oldRecords);
  }
}
