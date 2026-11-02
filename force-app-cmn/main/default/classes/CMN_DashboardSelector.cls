/**
 * @description 대시보드 조회(CMN-00-DSH-001). 위젯·템플릿·확장 등록은 메타데이터(설정)라 시스템 모드, 사용자 배치는 사용자 모드.
 * 메타데이터의 긴 텍스트(DefaultConfig·ConfigSchema·Config)는 getAll()이 255자로 자르므로 SOQL로 읽는다.
 * @group CMN-00-DSH-001
 */
public with sharing class CMN_DashboardSelector {
  /**
   * @description 모든 위젯 등록.
   * @return DeveloperName → 위젯
   */
  public static Map<String, CMN_Widget__mdt> widgets() {
    Map<String, CMN_Widget__mdt> out = new Map<String, CMN_Widget__mdt>();
    for (CMN_Widget__mdt w : [
      SELECT
        DeveloperName,
        MasterLabel,
        ComponentName__c,
        System__c,
        AvailableSystems__c,
        Category__c,
        TitleLabel__c,
        DescLabel__c,
        DefaultSize__c,
        RequiredPermissionSet__c,
        DefaultConfig__c,
        ConfigSchema__c,
        MobileSupported__c,
        IsActive__c
      FROM CMN_Widget__mdt
      WITH SYSTEM_MODE
      ORDER BY Category__c, DeveloperName
    ]) {
      out.put(w.DeveloperName, w);
    }
    return out;
  }

  /**
   * @description 시스템의 템플릿(우선순위 순).
   * @param systemCode QMS 또는 PMS
   * @return 템플릿
   */
  public static List<CMN_DashboardTemplate__mdt> templates(String systemCode) {
    return [
      SELECT
        DeveloperName,
        Persona__c,
        TitleLabel__c,
        PermissionSetGroups__c,
        Priority__c,
        IsDefault__c
      FROM CMN_DashboardTemplate__mdt
      WHERE System__c = :systemCode
      WITH SYSTEM_MODE
      ORDER BY Priority__c NULLS LAST, DeveloperName
    ];
  }

  /**
   * @description 템플릿 항목(순서대로).
   * @param templateKey 템플릿 DeveloperName
   * @return 항목
   */
  public static List<CMN_DashboardTemplateItem__mdt> templateItems(
    String templateKey
  ) {
    return [
      SELECT Widget__r.DeveloperName, Order__c, Size__c, Config__c
      FROM CMN_DashboardTemplateItem__mdt
      WHERE Template__r.DeveloperName = :templateKey
      WITH SYSTEM_MODE
      ORDER BY Order__c NULLS LAST, DeveloperName
    ];
  }

  /**
   * @description 활성 확장 등록(순서대로).
   * @param kind TEMPLATE_RESOLVER 또는 CONFIG_VALIDATOR
   * @param systemCode QMS 또는 PMS(CMN 등록은 둘 다)
   * @return 클래스 이름
   */
  public static List<String> extensionClasses(String kind, String systemCode) {
    List<String> out = new List<String>();
    for (CMN_DashboardResolver__mdt r : [
      SELECT ClassName__c
      FROM CMN_DashboardResolver__mdt
      WHERE
        Kind__c = :kind
        AND IsActive__c = TRUE
        AND System__c IN ('CMN', :systemCode)
      WITH SYSTEM_MODE
      ORDER BY Order__c NULLS LAST, DeveloperName
    ]) {
      out.add(r.ClassName__c);
    }
    return out;
  }

  /**
   * @description 사용자 대시보드(본인 것).
   * @param uniqueKey {UserId}:{System}
   * @return 대시보드(없으면 null)
   */
  public static CMN_UserDashboard__c board(String uniqueKey) {
    List<CMN_UserDashboard__c> rows = [
      SELECT Id, LayoutJson__c, SourceTemplate__c
      FROM CMN_UserDashboard__c
      WHERE UniqueKey__c = :uniqueKey
      WITH USER_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * @description 사용자가 가진 권한 셋 이름(직접 + PSG 구성)과 PSG 이름. 설정 조회라 시스템 모드.
   * @param userId 사용자
   * @return [0] 권한 셋 이름, [1] PSG DeveloperName
   */
  public static List<Set<String>> permissionNames(Id userId) {
    Set<String> sets = new Set<String>();
    Set<String> groups = new Set<String>();
    Set<Id> groupIds = new Set<Id>();
    for (PermissionSetAssignment a : [
      SELECT
        PermissionSet.Name,
        PermissionSetGroupId,
        PermissionSetGroup.DeveloperName
      FROM PermissionSetAssignment
      WHERE AssigneeId = :userId
      WITH SYSTEM_MODE
    ]) {
      if (a.PermissionSetGroupId != null) {
        groupIds.add(a.PermissionSetGroupId);
        groups.add(a.PermissionSetGroup.DeveloperName);
      } else {
        sets.add(a.PermissionSet.Name);
      }
    }
    if (!groupIds.isEmpty()) {
      for (PermissionSetGroupComponent c : [
        SELECT PermissionSet.Name
        FROM PermissionSetGroupComponent
        WHERE PermissionSetGroupId IN :groupIds
        WITH SYSTEM_MODE
      ]) {
        sets.add(c.PermissionSet.Name);
      }
    }
    return new List<Set<String>>{ sets, groups };
  }
}
