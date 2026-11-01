/**
 * @description 법인·공장·라인·공정 조회(CMN-00-MDM-002). 기준정보는 사내 전체 공개(Public Read Only)이고
 * 채번·트리거처럼 시스템 문맥에서 쓰이므로 시스템 모드로 읽는다(노출 범위가 사용자 모드와 같다).
 * @group CMN-00-MDM-002
 */
public with sharing class CMN_PlantSelector {
  /**
   * @description 공장 코드 또는 Id로 공장을 읽는다.
   * @param codes 공장 코드(대소문자 무관)
   * @param ids 공장 Id
   * @return 공장 목록
   */
  public static List<CMN_Plant__c> plants(Set<String> codes, Set<Id> ids) {
    return [
      SELECT
        Id,
        Name,
        PlantCode__c,
        TimeZone__c,
        Region__c,
        DefaultLanguage__c,
        IsActive__c
      FROM CMN_Plant__c
      WHERE PlantCode__c IN :codes OR Id IN :ids
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 라인 Id → 라인(외부 키 포함).
   * @param ids 라인 Id
   * @return 라인 맵
   */
  public static Map<Id, CMN_Line__c> linesById(Set<Id> ids) {
    return new Map<Id, CMN_Line__c>(
      [
        SELECT Id, LineCode__c, ExternalKey__c, Plant__c
        FROM CMN_Line__c
        WHERE Id IN :ids
        WITH SYSTEM_MODE
      ]
    );
  }

  /**
   * @description 라인의 공정(외부 키 재계산).
   * @param lineIds 라인 Id
   * @return 공정 목록
   */
  public static List<CMN_Operation__c> operationsByLine(Set<Id> lineIds) {
    return [
      SELECT Id, OpCode__c, Line__c, ExternalKey__c
      FROM CMN_Operation__c
      WHERE Line__c IN :lineIds
      WITH SYSTEM_MODE
    ];
  }
}
