/**
 * @description 코드 그룹 트리거: 삭제 금지(주종 하위 코드가 연쇄 삭제되므로).
 * @group CMN-00-MDM-007
 */
public with sharing class CMN_CodeGroupTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeDelete() {
    CMN_MasterDataGuard.preventDelete(oldRecords);
  }
}
