/**
 * @description 결재선 해석(CMN-00-APV-002 BR-1·BR-5). 결재 화면(APV-003)과 서비스 상신이 모두 이 결과를 쓴다.
 * - 템플릿: (유형, 대상 공장, SYSTEM, 기본) → (유형, 공장 공란, SYSTEM, 기본). 없으면 빈 결재선(사용자가 직접 만든다).
 * - 단계 해석: ROLE(CMN_RoleResolver), USER, DRAFTER_MANAGER(기안자 부서장), RECORD_FIELD(대상 필드 경로), PROJECT_ROLE(PMS 예약).
 * - 유형별 보정: CMN_ApprovalLineContributor(검토 반영 Vol.2).
 * - 편집 검증(BR-3): 필수 단계는 삭제·결재자 변경 불가, 편집 불가 템플릿은 그대로만. 상신(CMN_ApprovalService.submit)에서 서버 검증한다.
 * @group CMN-00-APV-002
 */
public with sharing class CMN_ApprovalLineResolver {
  @TestVisible
  private static CMN_ApprovalLineContributor contributorOverride;

  /**
   * @description 대상·유형의 기본 결재선.
   * @param targetId 대상 레코드
   * @param typeCode 결재 유형
   * @return 결재선(템플릿이 없으면 빈 목록)
   * @throws CMN_ValidationException Role 미지정·중복, 기안자 부서장·필드 결재자 없음
   */
  public static List<CMN_ApprovalStepSpec> resolve(
    Id targetId,
    String typeCode
  ) {
    CMN_ApprovalTemplate__c template = templateFor(targetId, typeCode);
    if (template == null) {
      return new List<CMN_ApprovalStepSpec>();
    }
    return contribute(targetId, typeCode, expand(targetId, template));
  }

  /**
   * @description 상신 결재선이 템플릿 규칙을 지키는지(BR-3, AC-3). 템플릿이 없으면 통과.
   * @param targetId 대상 레코드
   * @param typeCode 결재 유형
   * @param line 상신할 결재선
   * @throws CMN_ValidationException 필수 단계 삭제·결재자 변경, 편집 불가 템플릿 변경
   */
  public static void enforceTemplate(
    Id targetId,
    String typeCode,
    List<CMN_ApprovalStepSpec> line
  ) {
    CMN_ApprovalTemplate__c template = templateFor(targetId, typeCode);
    if (template == null) {
      return;
    }
    List<CMN_ApprovalStepSpec> expected = contribute(
      targetId,
      typeCode,
      expand(targetId, template)
    );
    if (!template.AllowUserEdit__c && signature(expected) != signature(line)) {
      throw new CMN_ValidationException(Label.CMN_Approval_EditNotAllowed);
    }
    Set<String> given = new Set<String>();
    for (CMN_ApprovalStepSpec s : line) {
      given.add(s.stepType + '|' + s.approverId);
    }
    for (CMN_ApprovalStepSpec s : expected) {
      if (s.isMandatory && !given.contains(s.stepType + '|' + s.approverId)) {
        throw new CMN_ValidationException(Label.CMN_Approval_MandatoryStep);
      }
    }
  }

  /**
   * @description 편집한 결재선을 개인 템플릿으로 저장한다(BR-4, 본인만 조회).
   * @param typeCode 결재 유형
   * @param name 템플릿 이름
   * @param line 결재선
   * @return 템플릿 Id
   */
  public static Id savePersonal(
    String typeCode,
    String name,
    List<CMN_ApprovalStepSpec> line
  ) {
    CMN_ApprovalTemplate__c t = new CMN_ApprovalTemplate__c(
      Name = name.left(80),
      TypeCode__c = typeCode,
      Scope__c = 'PERSONAL',
      AllowUserEdit__c = true,
      IsDefault__c = false,
      IsActive__c = true
    );
    Database.insert(t, AccessLevel.USER_MODE);
    List<CMN_ApprovalTemplateStep__c> steps = new List<CMN_ApprovalTemplateStep__c>();
    for (CMN_ApprovalStepSpec s : line) {
      steps.add(
        new CMN_ApprovalTemplateStep__c(
          Template__c = t.Id,
          StepNo__c = s.stepNo,
          StepType__c = s.stepType,
          ResolverType__c = 'USER',
          User__c = s.approverId
        )
      );
    }
    Database.insert(steps, AccessLevel.USER_MODE);
    return t.Id;
  }

  /**
   * @description 개인 템플릿을 결재선으로 불러온다.
   * @param templateId 개인 템플릿
   * @return 결재선(볼 수 없으면 빈 목록)
   */
  public static List<CMN_ApprovalStepSpec> loadPersonal(Id templateId) {
    List<CMN_ApprovalStepSpec> out = new List<CMN_ApprovalStepSpec>();
    CMN_ApprovalTemplate__c t = CMN_ApprovalLineSelector.personalTemplate(
      templateId
    );
    for (
      CMN_ApprovalTemplateStep__c s : t?.Steps__r ??
        new List<CMN_ApprovalTemplateStep__c>()
    ) {
      out.add(
        new CMN_ApprovalStepSpec(
          s.StepNo__c.intValue(),
          s.StepType__c,
          s.User__c,
          null
        )
      );
    }
    return out;
  }

  // ------------------------------------------------------------------ 내부
  private static CMN_ApprovalTemplate__c templateFor(
    Id targetId,
    String typeCode
  ) {
    Id plantId = (Id) targetValue(targetId, 'Plant__c');
    CMN_ApprovalTemplate__c companyDefault;
    for (
      CMN_ApprovalTemplate__c t : CMN_ApprovalLineSelector.systemTemplates(
        typeCode
      )
    ) {
      if (t.Plant__c != null && t.Plant__c == plantId) {
        return t;
      }
      if (t.Plant__c == null) {
        companyDefault = t;
      }
    }
    return companyDefault;
  }

  private static List<CMN_ApprovalStepSpec> expand(
    Id targetId,
    CMN_ApprovalTemplate__c template
  ) {
    Id drafter = UserInfo.getUserId();
    CMN_Department__c dept = CMN_UserOrgService.departmentsOf(
        new Set<Id>{ drafter }
      )
      .get(drafter);
    Id plantId = (Id) targetValue(targetId, 'Plant__c');
    List<CMN_ApprovalStepSpec> out = new List<CMN_ApprovalStepSpec>();
    for (CMN_ApprovalTemplateStep__c s : template.Steps__r) {
      Id approver;
      switch on s.ResolverType__c {
        when 'ROLE' {
          approver = CMN_RoleResolver.resolveUser(
            s.RoleCode__c,
            plantId,
            dept?.Id
          );
        }
        when 'USER' {
          approver = s.User__c;
        }
        when 'DRAFTER_MANAGER' {
          approver = dept?.Manager__c;
          if (approver == null) {
            throw new CMN_ValidationException(
              Label.CMN_Approval_ManagerRequired
            );
          }
        }
        when 'RECORD_FIELD' {
          approver = (Id) targetValue(targetId, s.FieldPath__c);
          if (approver == null) {
            throw new CMN_ValidationException(
              String.format(
                Label.CMN_Approval_FieldApproverMissing,
                new List<Object>{ s.FieldPath__c }
              )
            );
          }
        }
        when else {
          throw new CMN_ValidationException(
            String.format(
              Label.CMN_Approval_ResolverNotSupported,
              new List<Object>{ s.ResolverType__c }
            )
          );
        }
      }
      CMN_ApprovalStepSpec spec = new CMN_ApprovalStepSpec(
        s.StepNo__c.intValue(),
        s.StepType__c,
        approver,
        s.ResolverType__c == 'ROLE' ? s.RoleCode__c : null
      );
      spec.isMandatory = s.IsMandatory__c;
      out.add(spec);
    }
    return out;
  }

  private static List<CMN_ApprovalStepSpec> contribute(
    Id targetId,
    String typeCode,
    List<CMN_ApprovalStepSpec> line
  ) {
    CMN_ApprovalLineContributor c = contributorOverride;
    if (c == null) {
      CMN_ApprovalType__mdt t = CMN_ApprovalType__mdt.getInstance(typeCode);
      if (String.isNotBlank(t?.LineContributorClass__c)) {
        c = (CMN_ApprovalLineContributor) System.Type.forName(
            t.LineContributorClass__c
          )
          .newInstance();
      }
    }
    return c == null ? line : c.contribute(targetId, typeCode, line);
  }

  private static String signature(List<CMN_ApprovalStepSpec> line) {
    List<String> parts = new List<String>();
    for (CMN_ApprovalStepSpec s : line) {
      parts.add(
        String.valueOf(s.stepNo).leftPad(3, '0') +
          '|' +
          s.stepType +
          '|' +
          s.approverId
      );
    }
    parts.sort();
    return String.join(parts, ';');
  }

  /** 대상 레코드의 필드(관계 경로 허용, 예: ResponsibleDept__r.Manager__c). 필드가 없으면 null. */
  private static final Map<String, Object> TARGET_CACHE = new Map<String, Object>();

  private static Object targetValue(Id targetId, String path) {
    String key = targetId + '|' + path;
    if (TARGET_CACHE.containsKey(key)) {
      return TARGET_CACHE.get(key);
    }
    Object value;
    Schema.SObjectType t = targetId.getSObjectType();
    String first = path.substringBefore('.');
    Map<String, Schema.SObjectField> fields = t.getDescribe(
        SObjectDescribeOptions.DEFERRED
      )
      .fields.getMap();
    String fieldName = first.endsWith('__r')
      ? first.removeEnd('__r') + '__c'
      : first;
    if (!fields.containsKey(fieldName.toLowerCase())) {
      fieldName = first + 'Id'; // 표준 관계(Owner.Manager → OwnerId)
    }
    if (fields.containsKey(fieldName.toLowerCase())) {
      SObject rec = Database.queryWithBinds(
        'SELECT ' +
          String.escapeSingleQuotes(path) +
          ' FROM ' +
          String.escapeSingleQuotes(String.valueOf(t)) +
          ' WHERE Id = :id',
        new Map<String, Object>{ 'id' => targetId },
        AccessLevel.SYSTEM_MODE
      )[0];
      List<String> parts = path.split('\\.');
      for (Integer i = 0; i < parts.size() - 1 && rec != null; i++) {
        rec = rec.getSObject(parts[i]);
      }
      value = rec?.get(parts[parts.size() - 1]);
    }
    TARGET_CACHE.put(key, value);
    return value;
  }
}
