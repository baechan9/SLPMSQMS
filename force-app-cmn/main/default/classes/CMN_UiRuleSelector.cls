/**
 * @description 상태·권한 화면 제어 규칙 조회(CMN-00-UX-005 BR-6). 규칙·섹션은 모든 사용자에게 같은 메타데이터라 시스템 모드로 읽고,
 * 트랜잭션 안에서 객체별로 한 번만 읽는다. 긴 텍스트 필드가 없어 SOQL 한도에 세어지지 않는다.
 * @group CMN-00-UX-005
 */
public with sharing class CMN_UiRuleSelector {
  /** 테스트에서 메타데이터 레코드 대신 쓰는 값 */
  @TestVisible
  private static List<CMN_UiRule__mdt> rulesOverride;
  @TestVisible
  private static List<CMN_UiSection__mdt> sectionsOverride;
  private static Map<String, List<CMN_UiRule__mdt>> ruleCache = new Map<String, List<CMN_UiRule__mdt>>();
  private static Map<String, List<CMN_UiSection__mdt>> sectionCache = new Map<String, List<CMN_UiSection__mdt>>();

  /**
   * @description 객체의 활성 규칙.
   * @param objectApiName 업무 객체 API명
   * @return 규칙
   */
  public static List<CMN_UiRule__mdt> rules(String objectApiName) {
    if (rulesOverride != null) {
      List<CMN_UiRule__mdt> out = new List<CMN_UiRule__mdt>();
      for (CMN_UiRule__mdt r : rulesOverride) {
        if (r.ObjectApiName__c == objectApiName && r.IsActive__c) {
          out.add(r);
        }
      }
      return out;
    }
    if (!ruleCache.containsKey(objectApiName)) {
      ruleCache.put(
        objectApiName,
        [
          SELECT
            DeveloperName,
            ObjectApiName__c,
            TargetType__c,
            TargetKey__c,
            Mode__c,
            StatusField__c,
            StatusValues__c,
            CustomPermission__c,
            RecordTypes__c,
            ExtraCondition__c,
            IsActive__c
          FROM CMN_UiRule__mdt
          WHERE ObjectApiName__c = :objectApiName AND IsActive__c = TRUE
          WITH SYSTEM_MODE
          ORDER BY DeveloperName
        ]
      );
    }
    return ruleCache.get(objectApiName);
  }

  /**
   * @description 객체의 화면 섹션(섹션 키 → 필드).
   * @param objectApiName 업무 객체 API명
   * @return 섹션
   */
  public static List<CMN_UiSection__mdt> sections(String objectApiName) {
    if (sectionsOverride != null) {
      List<CMN_UiSection__mdt> out = new List<CMN_UiSection__mdt>();
      for (CMN_UiSection__mdt s : sectionsOverride) {
        if (s.ObjectApiName__c == objectApiName) {
          out.add(s);
        }
      }
      return out;
    }
    if (!sectionCache.containsKey(objectApiName)) {
      sectionCache.put(
        objectApiName,
        [
          SELECT DeveloperName, ObjectApiName__c, SectionKey__c, Fields__c
          FROM CMN_UiSection__mdt
          WHERE ObjectApiName__c = :objectApiName
          WITH SYSTEM_MODE
          ORDER BY DeveloperName
        ]
      );
    }
    return sectionCache.get(objectApiName);
  }
}
