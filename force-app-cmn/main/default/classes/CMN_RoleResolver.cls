/**
 * @description 결재 Role 해석(CMN-00-APV-002 BR-2, 검토 반영 Vol.4 — 공개 메서드). 해석 순서:
 * Role + 대상 공장 + 기안자 부서 → Role + 대상 공장(부서 공란) → Role + 공장 공란. 오늘 유효한 1명.
 * 같은 단계에 2명 이상이면 설정 오류, 끝까지 0명이면 Role명·공장으로 "결재자 미지정"(상신 차단).
 * @group CMN-00-APV-002
 */
public with sharing class CMN_RoleResolver {
  public static final String ROLE_GROUP = 'APPROVAL_ROLE';

  /**
   * @description Role의 결재자.
   * @param roleCode APPROVAL_ROLE 코드(예: QUALITY_MANAGER)
   * @param plantId 대상 공장(null이면 전사 배정만)
   * @param deptId 기안자 부서(null이면 부서 배정 건너뜀)
   * @return 사용자 Id
   * @throws CMN_ValidationException 미지정(AC-2) 또는 여러 명(AC-4)
   */
  public static Id resolveUser(String roleCode, Id plantId, Id deptId) {
    List<CMN_RoleAssignment__c> all = CMN_ApprovalLineSelector.activeAssignments(
      new Set<String>{ roleCode }
    );
    for (Integer level = 0; level < 3; level++) {
      Set<Id> users = new Set<Id>();
      for (CMN_RoleAssignment__c a : all) {
        if (matches(a, level, plantId, deptId)) {
          users.add(a.User__c);
        }
      }
      if (users.size() == 1) {
        return new List<Id>(users)[0];
      }
      if (users.size() > 1) {
        throw new CMN_ValidationException(
          message(Label.CMN_Approval_RoleAmbiguous, roleCode, plantId)
        );
      }
    }
    throw new CMN_ValidationException(
      message(Label.CMN_Approval_RoleNotAssigned, roleCode, plantId)
    );
  }

  private static Boolean matches(
    CMN_RoleAssignment__c a,
    Integer level,
    Id plantId,
    Id deptId
  ) {
    if (level == 0) {
      return plantId != null &&
        deptId != null &&
        a.Plant__c == plantId &&
        a.Department__c == deptId;
    }
    if (level == 1) {
      return plantId != null &&
        a.Plant__c == plantId &&
        a.Department__c == null;
    }
    return a.Plant__c == null && a.Department__c == null;
  }

  private static String message(String label, String roleCode, Id plantId) {
    String roleName = CMN_ApprovalLineSelector.roleNames(
        new Set<String>{ roleCode }
      )
      .get(roleCode) ?? roleCode;
    String plant = plantId == null
      ? '*'
      : CMN_PlantService.plantCodes(new Set<Id>{ plantId }).get(plantId);
    return String.format(label, new List<Object>{ roleName, plant });
  }
}
