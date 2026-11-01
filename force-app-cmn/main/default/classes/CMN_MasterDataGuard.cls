/**
 * @description 기준정보 공통 규칙. 기준정보는 과거 업무 레코드가 참조하므로 삭제하지 않고 IsActive__c로 비활성화한다
 * (MDM-001 BR-1, MDM-002 BR-2). 주종 관계 상위를 지우면 하위가 트리거 없이 연쇄 삭제되므로 상위도 막는다.
 * @group CMN-00-MDM-002
 */
public with sharing class CMN_MasterDataGuard {
  /**
   * @description 삭제를 막는다(before delete).
   * @param records Trigger.old
   */
  public static void preventDelete(List<SObject> records) {
    for (SObject r : records) {
      r.addError(Label.CMN_Master_DeleteNotAllowed);
    }
  }
}
