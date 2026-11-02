/**
 * @description 상태 흐름 설정 조회(CMN-00-UX-003).
 * @group CMN-00-UX-003
 */
public with sharing class CMN_StatusFlowSelector {
  /**
   * @description 객체의 상태 흐름.
   * @param objectApiName 객체 API명
   * @return 흐름(없으면 null)
   */
  public static CMN_StatusFlow__mdt flowFor(String objectApiName) {
    for (CMN_StatusFlow__mdt f : CMN_StatusFlow__mdt.getAll().values()) {
      if (f.ObjectApiName__c == objectApiName) {
        return f;
      }
    }
    return null;
  }

  /**
   * @description 흐름의 단계(순서대로).
   * @param flowName 흐름 DeveloperName
   * @return 단계
   */
  public static List<CMN_StatusStep__mdt> stepsOf(String flowName) {
    return [
      SELECT Value__c, Sequence__c, LabelKey__c, IsTerminal__c
      FROM CMN_StatusStep__mdt
      WHERE StatusFlow__r.DeveloperName = :flowName
      WITH SYSTEM_MODE
      ORDER BY Sequence__c, Value__c
    ];
  }
}
