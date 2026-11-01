/**
 * @description 코드 그룹·공통 코드 조회(CMN-00-MDM-007). 트리거 규칙은 시스템 모드, 피커는 사용자 모드로 읽는다.
 * @group CMN-00-MDM-007
 */
public with sharing class CMN_CodeSelector {
  /**
   * @description 코드 그룹(최대 단계·그룹 코드).
   * @param ids 그룹 Id
   * @return 그룹 맵
   */
  public static Map<Id, CMN_CodeGroup__c> groupsById(Set<Id> ids) {
    return new Map<Id, CMN_CodeGroup__c>(
      [
        SELECT Id, GroupCode__c, MaxLevel__c
        FROM CMN_CodeGroup__c
        WHERE Id IN :ids
        WITH SYSTEM_MODE
      ]
    );
  }

  /**
   * @description 코드(단계·키·경로).
   * @param ids 코드 Id
   * @return 코드 맵
   */
  public static Map<Id, CMN_Code__c> codesById(Set<Id> ids) {
    return new Map<Id, CMN_Code__c>(
      [
        SELECT
          Id,
          Name,
          CodeGroup__c,
          Parent__c,
          Level__c,
          ExternalKey__c,
          Path__c
        FROM CMN_Code__c
        WHERE Id IN :ids
        WITH SYSTEM_MODE
      ]
    );
  }

  /**
   * @description 그룹의 코드 전체(하위 경로 재계산).
   * @param groupIds 그룹 Id
   * @return 코드 목록
   */
  public static List<CMN_Code__c> codesOfGroups(Set<Id> groupIds) {
    return [
      SELECT Id, Parent__c, ExternalKey__c
      FROM CMN_Code__c
      WHERE CodeGroup__c IN :groupIds
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 하위 코드가 있는 코드 Id.
   * @param ids 코드 Id
   * @return 하위가 있는 Id
   */
  public static Set<Id> withChildren(Set<Id> ids) {
    Set<Id> out = new Set<Id>();
    for (CMN_Code__c c : [
      SELECT Parent__c
      FROM CMN_Code__c
      WHERE Parent__c IN :ids
      WITH SYSTEM_MODE
    ]) {
      out.add(c.Parent__c);
    }
    return out;
  }

  /**
   * @description 피커용: 그룹과 코드 전체(사용자 모드 — 코드 조회 권한·FLS를 따른다).
   * @param groupCode 그룹 코드
   * @return 그룹(하위 코드 포함), 없으면 null
   */
  public static CMN_CodeGroup__c groupWithCodes(String groupCode) {
    List<CMN_CodeGroup__c> found = [
      SELECT
        Id,
        GroupCode__c,
        MaxLevel__c,
        (
          SELECT
            Id,
            Name,
            NameEn__c,
            NameZh__c,
            Code__c,
            Parent__c,
            Level__c,
            SortOrder__c,
            IsActive__c,
            ExternalKey__c
          FROM Codes__r
          ORDER BY Level__c, SortOrder__c NULLS LAST, Name
        )
      FROM CMN_CodeGroup__c
      WHERE GroupCode__c = :groupCode
      WITH USER_MODE
      LIMIT 1
    ];
    return found.isEmpty() ? null : found[0];
  }
}
