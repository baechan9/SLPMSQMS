/**
 * @description 결재 Role 배정·템플릿 저장 규칙(CMN-00-APV-002): APPROVAL_ROLE 코드만, 사용자 필수, 외부 키(데모 보강 CR-6)·중복 차단.
 * @group CMN-00-APV-002
 */
public with sharing class CMN_ApprovalLineService {
  /**
   * @description Role 배정 저장 전(before insert·update). 외부 키 RA-{Role}-{Plant 또는 ALL}-{사번}[-{부서 코드}].
   * @param rows Role 배정
   */
  public static void prepareAssignments(List<CMN_RoleAssignment__c> rows) {
    Set<Id> codeIds = new Set<Id>();
    Set<Id> userIds = new Set<Id>();
    Set<Id> plantIds = new Set<Id>();
    Set<Id> deptIds = new Set<Id>();
    for (CMN_RoleAssignment__c r : rows) {
      codeIds.add(r.Role__c);
      userIds.add(r.User__c);
      plantIds.add(r.Plant__c);
      deptIds.add(r.Department__c);
    }
    Map<Id, CMN_Code__c> codes = new Map<Id, CMN_Code__c>(
      [
        SELECT Id, Code__c, CodeGroup__r.GroupCode__c
        FROM CMN_Code__c
        WHERE Id IN :codeIds
        WITH SYSTEM_MODE
      ]
    );
    Map<Id, User> users = new Map<Id, User>(
      [SELECT Id, EmployeeNo__c FROM User WHERE Id IN :userIds WITH SYSTEM_MODE]
    );
    Map<Id, CMN_Department__c> depts = new Map<Id, CMN_Department__c>(
      [
        SELECT Id, DeptCode__c
        FROM CMN_Department__c
        WHERE Id IN :deptIds
        WITH SYSTEM_MODE
      ]
    );
    plantIds.remove(null);
    Map<Id, String> plants = CMN_PlantService.plantCodes(plantIds);
    for (CMN_RoleAssignment__c r : rows) {
      CMN_Code__c code = codes.get(r.Role__c);
      if (
        code == null ||
        code.CodeGroup__r.GroupCode__c != CMN_RoleResolver.ROLE_GROUP
      ) {
        r.addError(
          CMN_RoleAssignment__c.Role__c,
          Label.CMN_Approval_NotApprovalRole
        );
        continue;
      }
      User u = users.get(r.User__c);
      if (u == null) {
        r.addError(
          CMN_RoleAssignment__c.User__c,
          Label.CMN_Sharing_UserRequired
        );
        continue;
      }
      r.ExternalKey__c =
        'RA-' +
        code.Code__c +
        '-' +
        (r.Plant__c == null ? 'ALL' : plants.get(r.Plant__c)) +
        '-' +
        (u.EmployeeNo__c ?? String.valueOf(u.Id)) +
        (r.Department__c == null
          ? ''
          : '-' + depts.get(r.Department__c)?.DeptCode__c);
    }
    CMN_KeyGuard.rejectDuplicates(
      rows,
      CMN_RoleAssignment__c.ExternalKey__c,
      CMN_RoleAssignment__c.User__c,
      CMN_RoleAssignment__c.ExternalKey__c,
      Label.CMN_Approval_DuplicateRole
    );
  }

  /**
   * @description 템플릿 저장 전: 시스템 기본 템플릿 외부 키 TPL-{TypeCode}[-{PlantCode}](같은 유형·공장 기본은 하나).
   * @param rows 템플릿
   */
  public static void prepareTemplates(List<CMN_ApprovalTemplate__c> rows) {
    Set<Id> plantIds = new Set<Id>();
    for (CMN_ApprovalTemplate__c t : rows) {
      if (t.Plant__c != null) {
        plantIds.add(t.Plant__c);
      }
    }
    Map<Id, String> plants = CMN_PlantService.plantCodes(plantIds);
    for (CMN_ApprovalTemplate__c t : rows) {
      if (t.Scope__c == 'SYSTEM' && t.IsDefault__c) {
        t.ExternalKey__c =
          'TPL-' +
          t.TypeCode__c +
          (t.Plant__c == null ? '' : '-' + plants.get(t.Plant__c));
      } else if (t.Scope__c == 'PERSONAL') {
        t.ExternalKey__c = null;
      }
    }
    CMN_KeyGuard.rejectDuplicates(
      rows,
      CMN_ApprovalTemplate__c.ExternalKey__c,
      CMN_ApprovalTemplate__c.TypeCode__c,
      CMN_ApprovalTemplate__c.ExternalKey__c,
      Label.CMN_Approval_DuplicateTemplate
    );
  }

  /**
   * @description 템플릿 단계 외부 키 {템플릿 키}-{StepNo}(병렬 둘째부터 -{순번}). 개인 템플릿 단계는 키 없음.
   * @param rows 템플릿 단계(before insert)
   */
  public static void prepareTemplateSteps(
    List<CMN_ApprovalTemplateStep__c> rows
  ) {
    Set<Id> templateIds = new Set<Id>();
    for (CMN_ApprovalTemplateStep__c s : rows) {
      templateIds.add(s.Template__c);
    }
    Map<Id, CMN_ApprovalTemplate__c> templates = new Map<Id, CMN_ApprovalTemplate__c>(
      [
        SELECT Id, ExternalKey__c, (SELECT ExternalKey__c FROM Steps__r)
        FROM CMN_ApprovalTemplate__c
        WHERE Id IN :templateIds
        WITH SYSTEM_MODE
      ]
    );
    Set<String> used = new Set<String>();
    for (CMN_ApprovalTemplate__c t : templates.values()) {
      for (CMN_ApprovalTemplateStep__c s : t.Steps__r) {
        used.add(s.ExternalKey__c);
      }
    }
    for (CMN_ApprovalTemplateStep__c s : rows) {
      String base = templates.get(s.Template__c)?.ExternalKey__c;
      if (String.isBlank(base) || String.isNotBlank(s.ExternalKey__c)) {
        continue;
      }
      String key = base + '-' + s.StepNo__c.intValue();
      Integer n = 1;
      while (used.contains(key)) {
        n++;
        key = base + '-' + s.StepNo__c.intValue() + '-' + n;
      }
      used.add(key);
      s.ExternalKey__c = key;
    }
  }
}
