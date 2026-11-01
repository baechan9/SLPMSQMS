/**
 * @description 사용자 ↔ 부서·기본 공장 해석(CMN-00-MDM-001). User는 사용자 정의 객체를 Lookup할 수 없어
 * 부서·기본 공장을 코드(DepartmentCode__c, PrimaryPlantCode__c)로 두고, 레코드가 필요한 곳(결재선·대시보드 범위·심사 독립성)은
 * 이 서비스로 푼다.
 * @group CMN-00-MDM-001
 */
public with sharing class CMN_UserOrgService {
  /**
   * @description 사용자별 소속 부서.
   * @param userIds 사용자 Id
   * @return 사용자 Id → 부서(코드가 없거나 부서가 없으면 빠진다)
   */
  public static Map<Id, CMN_Department__c> departmentsOf(Set<Id> userIds) {
    List<User> users = CMN_DepartmentSelector.userCodes(userIds);
    Set<String> codes = new Set<String>();
    for (User u : users) {
      if (String.isNotBlank(u.DepartmentCode__c)) {
        codes.add(u.DepartmentCode__c.toUpperCase());
      }
    }
    Map<String, CMN_Department__c> byCode = new Map<String, CMN_Department__c>();
    for (CMN_Department__c d : CMN_DepartmentSelector.byCodes(codes)) {
      byCode.put(d.DeptCode__c.toUpperCase(), d);
    }
    Map<Id, CMN_Department__c> result = new Map<Id, CMN_Department__c>();
    for (User u : users) {
      CMN_Department__c d = byCode.get(u.DepartmentCode__c?.toUpperCase());
      if (d != null) {
        result.put(u.Id, d);
      }
    }
    return result;
  }

  /**
   * @description 사용자별 기본 공장.
   * @param userIds 사용자 Id
   * @return 사용자 Id → 공장(코드가 없거나 공장이 없으면 빠진다)
   */
  public static Map<Id, CMN_Plant__c> primaryPlantsOf(Set<Id> userIds) {
    List<User> users = CMN_DepartmentSelector.userCodes(userIds);
    Set<String> codes = new Set<String>();
    for (User u : users) {
      if (String.isNotBlank(u.PrimaryPlantCode__c)) {
        codes.add(u.PrimaryPlantCode__c.toUpperCase());
      }
    }
    Map<String, CMN_Plant__c> byCode = new Map<String, CMN_Plant__c>();
    for (CMN_Plant__c p : CMN_PlantSelector.plants(codes, new Set<Id>())) {
      byCode.put(p.PlantCode__c.toUpperCase(), p);
    }
    Map<Id, CMN_Plant__c> result = new Map<Id, CMN_Plant__c>();
    for (User u : users) {
      CMN_Plant__c p = byCode.get(u.PrimaryPlantCode__c?.toUpperCase());
      if (p != null) {
        result.put(u.Id, p);
      }
    }
    return result;
  }

  /**
   * @description 저장 전 코드 검사: 없는 부서·공장 코드는 오류(Lookup의 참조 무결성을 대신한다). 공백은 지운다.
   * @param users 저장할 사용자(before insert·update)
   * @param oldMap 갱신 전(삽입이면 null)
   */
  public static void validateCodes(List<User> users, Map<Id, SObject> oldMap) {
    Set<String> deptCodes = new Set<String>();
    Set<String> plantCodes = new Set<String>();
    List<User> targets = new List<User>();
    for (User u : users) {
      User old = (User) oldMap?.get(u.Id);
      u.DepartmentCode__c = u.DepartmentCode__c?.trim();
      u.PrimaryPlantCode__c = u.PrimaryPlantCode__c?.trim();
      Boolean changed =
        old == null ||
        u.DepartmentCode__c != old.DepartmentCode__c ||
        u.PrimaryPlantCode__c != old.PrimaryPlantCode__c;
      if (!changed) {
        continue;
      }
      targets.add(u);
      if (String.isNotBlank(u.DepartmentCode__c)) {
        deptCodes.add(u.DepartmentCode__c.toUpperCase());
      }
      if (String.isNotBlank(u.PrimaryPlantCode__c)) {
        plantCodes.add(u.PrimaryPlantCode__c.toUpperCase());
      }
    }
    if (targets.isEmpty()) {
      return;
    }
    Set<String> knownDepts = new Set<String>();
    if (!deptCodes.isEmpty()) {
      for (CMN_Department__c d : CMN_DepartmentSelector.byCodes(deptCodes)) {
        knownDepts.add(d.DeptCode__c.toUpperCase());
      }
    }
    Set<String> knownPlants = new Set<String>();
    if (!plantCodes.isEmpty()) {
      for (
        CMN_Plant__c p : CMN_PlantSelector.plants(plantCodes, new Set<Id>())
      ) {
        knownPlants.add(p.PlantCode__c.toUpperCase());
      }
    }
    for (User u : targets) {
      if (
        String.isNotBlank(u.DepartmentCode__c) &&
        !knownDepts.contains(u.DepartmentCode__c.toUpperCase())
      ) {
        u.addError(
          User.DepartmentCode__c,
          String.format(
            Label.CMN_Org_UnknownDepartmentCode,
            new List<Object>{ u.DepartmentCode__c }
          )
        );
      }
      if (
        String.isNotBlank(u.PrimaryPlantCode__c) &&
        !knownPlants.contains(u.PrimaryPlantCode__c.toUpperCase())
      ) {
        u.addError(
          User.PrimaryPlantCode__c,
          String.format(
            Label.CMN_Site_UnknownPlant,
            new List<Object>{ u.PrimaryPlantCode__c }
          )
        );
      }
    }
  }
}
