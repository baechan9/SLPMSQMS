/**
 * @description 결재선 해석 조회(CMN-00-APV-002). Role 배정은 사내 공개 읽기, 시스템 템플릿은 전사 설정이라 공유와 무관하게 읽는다.
 * @group CMN-00-APV-002
 */
public with sharing class CMN_ApprovalLineSelector {
  /**
   * @description 오늘 유효한 Role 배정(활성 사용자).
   * @param roleCodes Role 코드
   * @return 배정 목록
   */
  public static List<CMN_RoleAssignment__c> activeAssignments(
    Set<String> roleCodes
  ) {
    Date today = Date.today();
    return [
      SELECT Id, Role__r.Code__c, Plant__c, Department__c, User__c
      FROM CMN_RoleAssignment__c
      WHERE
        Role__r.Code__c IN :roleCodes
        AND Role__r.CodeGroup__r.GroupCode__c = :CMN_RoleResolver.ROLE_GROUP
        AND ValidFrom__c <= :today
        AND (ValidTo__c = NULL
        OR ValidTo__c >= :today)
        AND User__r.IsActive = TRUE
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description Role 코드 → 표시명(사용자 언어, 오류 문구용).
   * @param roleCodes Role 코드
   * @return 코드 → 표시명
   */
  public static Map<String, String> roleNames(Set<String> roleCodes) {
    Map<String, String> out = new Map<String, String>();
    for (CMN_Code__c c : [
      SELECT Code__c, DisplayName__c
      FROM CMN_Code__c
      WHERE
        Code__c IN :roleCodes
        AND CodeGroup__r.GroupCode__c = :CMN_RoleResolver.ROLE_GROUP
      WITH SYSTEM_MODE
    ]) {
      out.put(c.Code__c, c.DisplayName__c);
    }
    return out;
  }

  /**
   * @description 유형의 활성 시스템 기본 템플릿(단계 포함).
   * @param typeCode 결재 유형
   * @return 템플릿 목록(공장 지정·전사 기본)
   */
  public static List<CMN_ApprovalTemplate__c> systemTemplates(String typeCode) {
    return new TemplateReader().systemTemplates(typeCode);
  }

  /**
   * @description 개인 템플릿(본인 것만 — OWD Private).
   * @param templateId 템플릿
   * @return 템플릿(없거나 볼 수 없으면 null)
   */
  public static CMN_ApprovalTemplate__c personalTemplate(Id templateId) {
    List<CMN_ApprovalTemplate__c> found = [
      SELECT
        Id,
        TypeCode__c,
        (
          SELECT StepNo__c, StepType__c, User__c
          FROM Steps__r
          ORDER BY StepNo__c
        )
      FROM CMN_ApprovalTemplate__c
      WHERE Id = :templateId AND Scope__c = 'PERSONAL'
      WITH USER_MODE
    ];
    return found.isEmpty() ? null : found[0];
  }

  // SHARING-EXCEPTION: CMN-00-APV-002 시스템 결재선 템플릿은 전사 설정이다. 조건 공유 규칙(사내 전체 읽기)이 계산되기 전에도
  // 결재선 해석이 같아야 해서 SYSTEM 범위만 공유와 무관하게 읽는다. 읽기 전용, 개인 템플릿은 읽지 않는다.
  private without sharing class TemplateReader {
    List<CMN_ApprovalTemplate__c> systemTemplates(String typeCode) {
      return [
        SELECT
          Id,
          Plant__c,
          AllowUserEdit__c,
          (
            SELECT
              StepNo__c,
              StepType__c,
              ResolverType__c,
              RoleCode__c,
              User__c,
              FieldPath__c,
              IsMandatory__c
            FROM Steps__r
            ORDER BY StepNo__c, Name
          )
        FROM CMN_ApprovalTemplate__c
        WHERE
          TypeCode__c = :typeCode
          AND Scope__c = 'SYSTEM'
          AND IsDefault__c = TRUE
          AND IsActive__c = TRUE
        WITH SYSTEM_MODE
      ];
    }
  }
}
