/**
 * @description 결재선 템플릿·Role 해석 검증(CMN-00-APV-002). 4M 대신 테스트 대상 객체(유형 CMN_TEST_APPROVE)로 검증한다(CR-11·DEV-3).
 * @group CMN-00-APV-002
 */
@IsTest
private class CMN_ApprovalLineResolver_Test {
  private static final String TYPE_CODE = 'CMN_TEST_APPROVE';

  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    insert new List<CMN_Plant__c>{ plant(c.Id, 'KR01'), plant(c.Id, 'CN01') };
    CMN_CodeGroup__c g = new CMN_CodeGroup__c(
      Name = 'Approval role',
      GroupCode__c = 'APPROVAL_ROLE',
      MaxLevel__c = 1
    );
    insert g;
    insert new List<CMN_Code__c>{
      new CMN_Code__c(
        CodeGroup__c = g.Id,
        Code__c = 'QUALITY_MANAGER',
        Name = '품질팀장'
      ),
      new CMN_Code__c(
        CodeGroup__c = g.Id,
        Code__c = 'PRODUCTION_MANAGER',
        Name = '생산팀장'
      ),
      new CMN_Code__c(
        CodeGroup__c = g.Id,
        Code__c = 'PLANT_MANAGER',
        Name = '공장장'
      )
    };
    List<User> users = new List<User>();
    for (String a : new List<String>{ 'kim', 'wang', 'prod', 'pm', 'dept' }) {
      users.add(
        CMN_TestDataFactory.newUser(
          a,
          a,
          CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
        )
      );
    }
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert users;
    }
    Map<String, User> u = users();
    insert new List<CMN_RoleAssignment__c>{
      role('QUALITY_MANAGER', 'KR01', u.get('kim')),
      role('QUALITY_MANAGER', 'CN01', u.get('wang')),
      role('PRODUCTION_MANAGER', null, u.get('prod')),
      role('PLANT_MANAGER', 'KR01', u.get('pm'))
    };
    CMN_ApprovalTemplate__c t = new CMN_ApprovalTemplate__c(
      Name = 'Test line',
      TypeCode__c = TYPE_CODE,
      Scope__c = 'SYSTEM',
      IsDefault__c = true,
      AllowUserEdit__c = true
    );
    insert t;
    insert new List<CMN_ApprovalTemplateStep__c>{
      tstep(t.Id, 1, 'REVIEW', 'QUALITY_MANAGER', true),
      tstep(t.Id, 2, 'AGREE', 'PRODUCTION_MANAGER', false),
      tstep(t.Id, 3, 'APPROVE', 'PLANT_MANAGER', true)
    };
    insert new List<CMN_TestRecord__c>{
      new CMN_TestRecord__c(Name = 'kr', Plant__c = plantId('KR01')),
      new CMN_TestRecord__c(Name = 'cn', Plant__c = plantId('CN01'))
    };
  }

  @IsTest
  static void test_AC01_qualityManagerResolvedPerPlant() {
    // Given: KR01 품질팀장 kim, CN01 품질팀장 wang
    Map<String, User> u = users();

    // When: CN01 레코드 결재선의 품질팀장 해석(공장장은 Role 공개 메서드로 따로)
    Id cnQm = CMN_RoleResolver.resolveUser(
      'QUALITY_MANAGER',
      plantId('CN01'),
      null
    );
    List<CMN_ApprovalStepSpec> kr = CMN_ApprovalLineResolver.resolve(
      target('kr'),
      TYPE_CODE
    );

    // Then: CN01은 wang, KR01 결재선은 kim → 전사 생산팀장 prod → KR01 공장장 pm(필수 표시 유지)
    Assert.areEqual(u.get('wang').Id, cnQm);
    Assert.areEqual(u.get('kim').Id, kr[0].approverId);
    Assert.areEqual('QUALITY_MANAGER', kr[0].roleCode);
    Assert.isTrue(kr[0].isMandatory);
    Assert.areEqual(u.get('prod').Id, kr[1].approverId);
    Assert.areEqual(u.get('pm').Id, kr[2].approverId);
  }

  @IsTest
  static void test_AC02_missingPlantManagerBlocksSubmit() {
    // Given: CN01에 공장장 배정 없음
    Map<String, User> u = users();
    List<CMN_ApprovalStepSpec> line = new List<CMN_ApprovalStepSpec>{
      new CMN_ApprovalStepSpec(1, 'REVIEW', u.get('wang').Id, null),
      new CMN_ApprovalStepSpec(2, 'APPROVE', u.get('pm').Id, null)
    };

    // When / Then: 상신 차단, "공장장(CN01) 결재자 미지정"
    try {
      CMN_ApprovalService.submit(target('cn'), TYPE_CODE, line, null);
      Assert.fail('차단돼야 한다');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(
        String.format(
          Label.CMN_Approval_RoleNotAssigned,
          new List<Object>{ '공장장', 'CN01' }
        ),
        e.getMessage()
      );
    }
  }

  @IsTest
  static void test_AC03_mandatoryStepCannotBeRemovedOrReassigned() {
    // Given: KR01 결재선(품질팀장 단계 필수)
    Map<String, User> u = users();
    List<CMN_ApprovalStepSpec> resolved = CMN_ApprovalLineResolver.resolve(
      target('kr'),
      TYPE_CODE
    );
    List<CMN_ApprovalStepSpec> removed = new List<CMN_ApprovalStepSpec>{
      resolved[1],
      resolved[2]
    };
    List<CMN_ApprovalStepSpec> reassigned = new List<CMN_ApprovalStepSpec>{
      new CMN_ApprovalStepSpec(1, 'REVIEW', u.get('wang').Id, null),
      resolved[1],
      resolved[2]
    };

    // When / Then: 삭제·결재자 변경 모두 서버에서 차단, 비필수 단계 삭제는 허용
    for (
      List<CMN_ApprovalStepSpec> line : new List<List<CMN_ApprovalStepSpec>>{
        removed,
        reassigned
      }
    ) {
      try {
        CMN_ApprovalService.submit(target('kr'), TYPE_CODE, line, null);
        Assert.fail('필수 단계');
      } catch (CMN_ValidationException e) {
        Assert.areEqual(Label.CMN_Approval_MandatoryStep, e.getMessage());
      }
    }
    Id req = CMN_ApprovalService.submit(
      target('kr'),
      TYPE_CODE,
      new List<CMN_ApprovalStepSpec>{ resolved[0], resolved[2] },
      null
    );
    Assert.isNotNull(req);
  }

  @IsTest
  static void test_AC04_overlappingAssignmentsAreConfigError() {
    // Given: KR01 품질팀장 유효 기간이 겹치는 두 번째 배정
    Map<String, User> u = users();
    insert role('QUALITY_MANAGER', 'KR01', u.get('dept'));

    // When / Then
    try {
      CMN_RoleResolver.resolveUser('QUALITY_MANAGER', plantId('KR01'), null);
      Assert.fail('설정 오류');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(
        String.format(
          Label.CMN_Approval_RoleAmbiguous,
          new List<Object>{ '품질팀장', 'KR01' }
        ),
        e.getMessage()
      );
    }
  }

  @IsTest
  static void test_BR2_departmentAssignmentWinsAndExpiredIgnored() {
    // Given: 기안자 부서 DQ의 KR01 품질팀장 dept, 만료된 배정
    Map<String, User> u = users();
    CMN_Department__c dq = new CMN_Department__c(
      Name = 'QM',
      DeptCode__c = 'DQ'
    );
    insert dq;
    CMN_RoleAssignment__c deptRole = role(
      'QUALITY_MANAGER',
      'KR01',
      u.get('dept')
    );
    deptRole.Department__c = dq.Id;
    CMN_RoleAssignment__c expired = role(
      'PLANT_MANAGER',
      'CN01',
      u.get('dept')
    );
    expired.ValidFrom__c = Date.today().addYears(-2);
    expired.ValidTo__c = Date.today().addYears(-1);
    insert new List<CMN_RoleAssignment__c>{ deptRole, expired };

    // When / Then: 부서 배정 우선, 만료 배정은 무시(미지정)
    Assert.areEqual(
      u.get('dept').Id,
      CMN_RoleResolver.resolveUser('QUALITY_MANAGER', plantId('KR01'), dq.Id)
    );
    Assert.areEqual(
      u.get('kim').Id,
      CMN_RoleResolver.resolveUser('QUALITY_MANAGER', plantId('KR01'), null)
    );
    try {
      CMN_RoleResolver.resolveUser('PLANT_MANAGER', plantId('CN01'), null);
      Assert.fail('만료');
    } catch (CMN_ValidationException e) {
      Assert.isTrue(e.getMessage().contains('CN01'));
    }
    Assert.isTrue(
      [SELECT ExternalKey__c FROM CMN_RoleAssignment__c WHERE Id = :deptRole.Id]
        .ExternalKey__c.endsWith('-DQ')
    );
  }

  @IsTest
  static void test_BR1_plantTemplateBeatsCompanyDefaultAndResolverTypes() {
    // Given: CN01 전용 템플릿(사용자 지정·기안자 부서장·레코드 필드)
    Map<String, User> u = users();
    CMN_Department__c dq = new CMN_Department__c(
      Name = 'QM',
      DeptCode__c = 'DQ',
      Manager__c = u.get('prod').Id
    );
    insert dq;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      update new User(Id = UserInfo.getUserId(), DepartmentCode__c = 'DQ');
    }
    CMN_ApprovalTemplate__c cn = new CMN_ApprovalTemplate__c(
      Name = 'CN line',
      TypeCode__c = TYPE_CODE,
      Plant__c = plantId('CN01'),
      Scope__c = 'SYSTEM',
      IsDefault__c = true,
      AllowUserEdit__c = false
    );
    insert cn;
    CMN_ApprovalTemplateStep__c s1 = tstep(cn.Id, 1, 'REVIEW', null, false);
    s1.ResolverType__c = 'USER';
    s1.User__c = u.get('wang').Id;
    CMN_ApprovalTemplateStep__c s2 = tstep(cn.Id, 2, 'AGREE', null, false);
    s2.ResolverType__c = 'DRAFTER_MANAGER';
    CMN_ApprovalTemplateStep__c s3 = tstep(cn.Id, 3, 'APPROVE', null, false);
    s3.ResolverType__c = 'RECORD_FIELD';
    s3.FieldPath__c = 'OwnerId';
    insert new List<CMN_ApprovalTemplateStep__c>{ s1, s2, s3 };

    // When
    List<CMN_ApprovalStepSpec> line = CMN_ApprovalLineResolver.resolve(
      target('cn'),
      TYPE_CODE
    );

    // Then: CN01 템플릿 사용(사용자 지정 wang → 부서장 prod → 레코드 소유자), 편집 불가라 바꾸면 차단, 키 TPL-…-CN01
    Assert.areEqual(u.get('wang').Id, line[0].approverId);
    Assert.areEqual(u.get('prod').Id, line[1].approverId);
    Assert.areEqual(UserInfo.getUserId(), line[2].approverId);
    try {
      CMN_ApprovalLineResolver.enforceTemplate(
        target('cn'),
        TYPE_CODE,
        new List<CMN_ApprovalStepSpec>{ line[0], line[2] }
      );
      Assert.fail('편집 불가');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Approval_EditNotAllowed, e.getMessage());
    }
    Assert.areEqual(
      'TPL-' + TYPE_CODE + '-CN01',
      [SELECT ExternalKey__c FROM CMN_ApprovalTemplate__c WHERE Id = :cn.Id]
      .ExternalKey__c
    );
    Assert.areEqual(
      'TPL-' + TYPE_CODE + '-CN01-2',
      [SELECT ExternalKey__c FROM CMN_ApprovalTemplateStep__c WHERE Id = :s2.Id]
      .ExternalKey__c
    );
  }

  @IsTest
  static void test_BR4_personalTemplateOnlyForOwner() {
    // Given: kim이 개인 결재선 저장
    Map<String, User> u = users();
    grantApprovalUser(new List<User>{ u.get('kim'), u.get('wang') });
    Id personal;
    System.runAs(u.get('kim')) {
      personal = CMN_ApprovalLineResolver.savePersonal(
        TYPE_CODE,
        'My line',
        new List<CMN_ApprovalStepSpec>{
          new CMN_ApprovalStepSpec(1, 'APPROVE', u.get('pm').Id, null)
        }
      );
    }

    // When / Then: kim은 불러오고 wang은 못 본다
    System.runAs(u.get('kim')) {
      Assert.areEqual(
        u.get('pm').Id,
        CMN_ApprovalLineResolver.loadPersonal(personal)[0].approverId
      );
    }
    System.runAs(u.get('wang')) {
      Assert.areEqual(
        0,
        CMN_ApprovalLineResolver.loadPersonal(personal).size()
      );
    }
  }

  @IsTest
  static void test_contributorAndNoTemplate() {
    // Given: 결재선 기여(단계 하나 덧붙임)
    Map<String, User> u = users();
    CMN_ApprovalLineResolver.contributorOverride = new AddCc(u.get('dept').Id);

    // When
    List<CMN_ApprovalStepSpec> line = CMN_ApprovalLineResolver.resolve(
      target('kr'),
      TYPE_CODE
    );

    // Then: 템플릿 3단계 + 참조 1, 템플릿 없는 유형은 빈 결재선
    Assert.areEqual(4, line.size());
    Assert.areEqual('CC', line[3].stepType);
    Assert.areEqual(
      0,
      CMN_ApprovalLineResolver.resolve(target('kr'), 'NO_TEMPLATE').size()
    );
  }

  @IsTest
  static void test_negative_roleAssignmentRules() {
    // Given: APPROVAL_ROLE이 아닌 코드, 사용자 없는 배정, 같은 배정 중복, 지원하지 않는 해석 유형
    CMN_CodeGroup__c other = new CMN_CodeGroup__c(
      Name = 'Other',
      GroupCode__c = 'OTHER',
      MaxLevel__c = 1
    );
    insert other;
    CMN_Code__c notRole = new CMN_Code__c(
      CodeGroup__c = other.Id,
      Code__c = 'X',
      Name = 'X'
    );
    insert notRole;
    Map<String, User> u = users();

    // When
    List<Database.SaveResult> rs = Database.insert(
      new List<CMN_RoleAssignment__c>{
        new CMN_RoleAssignment__c(
          Role__c = notRole.Id,
          User__c = u.get('kim').Id,
          ValidFrom__c = Date.today()
        ),
        new CMN_RoleAssignment__c(
          Role__c = codeId('QUALITY_MANAGER'),
          ValidFrom__c = Date.today()
        ),
        role('QUALITY_MANAGER', 'KR01', u.get('kim'))
      },
      false
    );

    // Then
    Assert.areEqual(
      Label.CMN_Approval_NotApprovalRole,
      rs[0].getErrors()[0].getMessage()
    );
    Assert.areEqual(
      Label.CMN_Sharing_UserRequired,
      rs[1].getErrors()[0].getMessage()
    );
    Assert.isFalse(rs[2].isSuccess());
    CMN_ApprovalTemplateStep__c pr = [
      SELECT Id
      FROM CMN_ApprovalTemplateStep__c
      WHERE StepNo__c = 2
      LIMIT 1
    ];
    update new CMN_ApprovalTemplateStep__c(
      Id = pr.Id,
      ResolverType__c = 'PROJECT_ROLE'
    );
    try {
      CMN_ApprovalLineResolver.resolve(target('kr'), TYPE_CODE);
      Assert.fail('PMS 예약');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(
        String.format(
          Label.CMN_Approval_ResolverNotSupported,
          new List<Object>{ 'PROJECT_ROLE' }
        ),
        e.getMessage()
      );
    }
  }

  @IsTest
  static void test_updatesKeepKeys() {
    // Given: Role 배정과 시스템 기본 템플릿
    CMN_RoleAssignment__c ra = [
      SELECT Id, ExternalKey__c
      FROM CMN_RoleAssignment__c
      WHERE ExternalKey__c LIKE 'RA-PLANT_MANAGER-KR01-%'
    ];
    CMN_ApprovalTemplate__c t = [
      SELECT Id, ExternalKey__c
      FROM CMN_ApprovalTemplate__c
      WHERE Scope__c = 'SYSTEM'
      LIMIT 1
    ];

    // When: 유효 종료일·이름 변경
    update new CMN_RoleAssignment__c(
      Id = ra.Id,
      ValidTo__c = Date.today().addYears(1)
    );
    update new CMN_ApprovalTemplate__c(Id = t.Id, Name = 'Renamed');

    // Then: 외부 키 유지
    Assert.areEqual(
      ra.ExternalKey__c,
      [SELECT ExternalKey__c FROM CMN_RoleAssignment__c WHERE Id = :ra.Id]
      .ExternalKey__c
    );
    Assert.areEqual(
      'TPL-' + TYPE_CODE,
      [SELECT ExternalKey__c FROM CMN_ApprovalTemplate__c WHERE Id = :t.Id]
      .ExternalKey__c
    );
  }

  // ------------------------------------------------------------------ 도우미
  private class AddCc implements CMN_ApprovalLineContributor {
    private Id userId;
    AddCc(Id userId) {
      this.userId = userId;
    }
    public List<CMN_ApprovalStepSpec> contribute(
      Id targetId,
      String typeCode,
      List<CMN_ApprovalStepSpec> line
    ) {
      line.add(new CMN_ApprovalStepSpec(1, 'CC', userId, null));
      return line;
    }
  }

  private static final Map<String, Id> PLANTS = new Map<String, Id>();

  private static CMN_Plant__c plant(Id companyId, String code) {
    return new CMN_Plant__c(
      Name = code,
      PlantCode__c = code,
      Company__c = companyId,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
  }

  private static Id plantId(String code) {
    if (!PLANTS.containsKey(code)) {
      PLANTS.put(
        code,
        [SELECT Id FROM CMN_Plant__c WHERE PlantCode__c = :code].Id
      );
    }
    return PLANTS.get(code);
  }

  private static Id codeId(String code) {
    return [SELECT Id FROM CMN_Code__c WHERE Code__c = :code].Id;
  }

  private static Map<String, User> users() {
    Map<String, User> out = new Map<String, User>();
    for (User u : [
      SELECT Id, Alias
      FROM User
      WHERE Alias IN ('kim', 'wang', 'prod', 'pm', 'dept')
    ]) {
      out.put(u.Alias, u);
    }
    return out;
  }

  private static CMN_RoleAssignment__c role(
    String code,
    String plantCode,
    User u
  ) {
    return new CMN_RoleAssignment__c(
      Role__c = codeId(code),
      Plant__c = plantCode == null ? null : plantId(plantCode),
      User__c = u.Id,
      ValidFrom__c = Date.today().addDays(-30)
    );
  }

  private static CMN_ApprovalTemplateStep__c tstep(
    Id templateId,
    Integer no,
    String type,
    String roleCode,
    Boolean mandatory
  ) {
    return new CMN_ApprovalTemplateStep__c(
      Template__c = templateId,
      StepNo__c = no,
      StepType__c = type,
      ResolverType__c = 'ROLE',
      RoleCode__c = roleCode,
      IsMandatory__c = mandatory
    );
  }

  private static Id target(String name) {
    return [SELECT Id FROM CMN_TestRecord__c WHERE Name = :name].Id;
  }

  private static void grantApprovalUser(List<User> users) {
    Id ps = [SELECT Id FROM PermissionSet WHERE Name = 'CMN_PS_Approval_User']
    .Id;
    List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
    for (User u : users) {
      psas.add(
        new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps)
      );
    }
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert psas;
    }
  }
}
