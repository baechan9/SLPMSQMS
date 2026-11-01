/**
 * @description 고객·차종 조회(CMN-00-MDM-003). 기준정보는 사내 전체 공개라 시스템 모드로 읽는다.
 * @group CMN-00-MDM-003
 */
public with sharing class CMN_CustomerSelector {
  /**
   * @description 고객 CSR 필드.
   * @param ids Account Id
   * @return 고객 목록
   */
  public static List<Account> customers(Set<Id> ids) {
    return [
      SELECT
        Id,
        OemCode__c,
        CustomerGroup__c,
        ContainmentDueDays__c,
        EightDDueDays__c,
        RootCauseDueDays__c,
        PpapDefaultLevel__c,
        AuditStandard__c,
        ClaimFormTemplate__c,
        ChangeNoticeLeadDays__c,
        ConcessionCustomerApproval__c
      FROM Account
      WHERE Id IN :ids
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 외부 키로 차종을 찾는다(중복 검사).
   * @param keys 외부 키(대소문자 무관)
   * @return 차종 목록
   */
  public static List<CMN_Vehicle__c> vehiclesByExternalKey(Set<String> keys) {
    return [
      SELECT Id, ExternalKey__c
      FROM CMN_Vehicle__c
      WHERE ExternalKey__c IN :keys
      WITH SYSTEM_MODE
    ];
  }
}
