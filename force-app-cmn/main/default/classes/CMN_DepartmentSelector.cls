/**
 * @description 부서 조회(CMN-00-MDM-001). 순환 검사와 전체 경로 계산은 부서 트리 전체가 필요해서 한 번에 읽는다
 * (부서는 수천 건 규모). 기준정보는 사내 전체 공개라 시스템 모드로 읽는다.
 * @group CMN-00-MDM-001
 */
public with sharing class CMN_DepartmentSelector {
  /**
   * @description 부서 트리 전체(Id·이름·상위·경로).
   * @return 부서 Id → 부서
   */
  public static Map<Id, CMN_Department__c> tree() {
    return new Map<Id, CMN_Department__c>(
      [
        SELECT Id, Name, Parent__c, FullPath__c
        FROM CMN_Department__c
        WITH SYSTEM_MODE
        LIMIT 50000
      ]
    );
  }

  /**
   * @description 부서 코드로 부서를 찾는다.
   * @param codes 부서 코드(대소문자 무관)
   * @return 부서 목록
   */
  public static List<CMN_Department__c> byCodes(Set<String> codes) {
    return [
      SELECT
        Id,
        Name,
        DeptCode__c,
        Parent__c,
        Manager__c,
        Plant__c,
        FullPath__c,
        IsActive__c
      FROM CMN_Department__c
      WHERE DeptCode__c IN :codes
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 사용자의 부서·기본 공장 코드.
   * @param userIds 사용자 Id
   * @return 사용자 목록
   */
  public static List<User> userCodes(Set<Id> userIds) {
    return [
      SELECT Id, DepartmentCode__c, PrimaryPlantCode__c
      FROM User
      WHERE Id IN :userIds
      WITH SYSTEM_MODE
    ];
  }
}
