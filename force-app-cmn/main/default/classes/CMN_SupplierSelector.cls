/**
 * @description 협력사 조회(CMN-00-MDM-005). 기준정보는 사내 전체 공개라 시스템 모드로 읽는다.
 * @group CMN-00-MDM-005
 */
public with sharing class CMN_SupplierSelector {
  /**
   * @description 협력사 필드.
   * @param ids Account Id
   * @return 협력사 목록
   */
  public static List<Account> suppliers(Set<Id> ids) {
    return [
      SELECT
        Id,
        SapVendorNo__c,
        SupplierGrade__c,
        IatfCertified__c,
        IatfExpiry__c,
        PortalEnabled__c
      FROM Account
      WHERE Id IN :ids
      WITH SYSTEM_MODE
    ];
  }
}
