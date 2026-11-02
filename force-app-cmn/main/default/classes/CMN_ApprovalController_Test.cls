/**
 * @description 결재 화면 진입점 검증(CMN-00-APV-003). 업무 객체 대신 테스트 대상 객체(유형 CMN_TEST_APPROVE)로 검증한다(CR-11·DEV-3).
 * 템플릿: 1 REVIEW 품질팀장(필수) / 3 APPROVE 공장장(필수).
 * @group CMN-00-APV-003
 */
@IsTest
private class CMN_ApprovalController_Test {
  private static final String TYPE_CODE = 'CMN_TEST_APPROVE';
  private static final String DOMAIN = '@test.slqms.example.com';

  /** 상신 거절 콜백(BR-2). */
  private class RefusingCallback implements CMN_ApprovalCallback {
    public String canSubmit(Id targetId) {
      return 'not ready';
    }
    public void onSubmitted(CMN_ApprovalRequest__c r) {
      return;
    }
    public void onApproved(CMN_ApprovalRequest__c r) {
      return;
    }
    public void onRejected(CMN_ApprovalRequest__c r) {
      return;
    }
    public void onRecalled(CMN_ApprovalRequest__c r) {
      return;
    }
  }

  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    CMN_Plant__c kr = new CMN_Plant__c(
      Name = 'KR01',
      PlantCode__c = 'KR01',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
    insert kr;
    insert new CMN_Department__c(
      Name = 'Zeta Quality Team',
      DeptCode__c = 'ZT100'
    );
    CMN_CodeGroup__c g = new CMN_CodeGroup__c(
      Name = 'Approval role',
      GroupCode__c = 'APPROVAL_ROLE',
      MaxLevel__c = 1
    );
    insert g;
    CMN_Code__c qm = new CMN_Code__c(
      CodeGroup__c = g.Id,
      Code__c = 'QUALITY_MANAGER',
      Name = 'QM'
    );
    CMN_Code__c pm = new CMN_Code__c(
      CodeGroup__c = g.Id,
      Code__c = 'PLANT_MANAGER',
      Name = 'PM'
    );
    insert new List<CMN_Code__c>{ qm, pm };

    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    List<User> users = new List<User>();
    for (
      String a : new List<String>{
        'actkim',
        'actpm',
        'actdlg',
        'actemp',
        'actgone'
      }
    ) {
      users.add(CMN_TestDataFactory.newUser(a, 'Approver ' + a, profileId));
    }
    users[3].EmployeeNo__c = 'ZE9001';
    users[3].DepartmentCode__c = 'ZT100';
    users[4].EmployeeNo__c = 'ZE9002';
    users[4].DepartmentCode__c = 'ZT100';
    users[4].IsActive = false;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert users;
      // 사내 사용자 페르소나: 결재 사용 + 공장(사이트) 조회
      List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
      for (PermissionSet ps : [
        SELECT Id
        FROM PermissionSet
        WHERE Name IN ('CMN_PS_Approval_User', 'CMN_PS_Site_Read')
      ]) {
        for (Integer i = 0; i < 4; i++) {
          psas.add(
            new PermissionSetAssignment(
              AssigneeId = users[i].Id,
              PermissionSetId = ps.Id
            )
          );
        }
      }
      insert psas;
    }
    insert new List<CMN_RoleAssignment__c>{
      new CMN_RoleAssignment__c(
        Role__c = qm.Id,
        Plant__c = kr.Id,
        User__c = users[0].Id,
        ValidFrom__c = Date.today().addDays(-30)
      ),
      new CMN_RoleAssignment__c(
        Role__c = pm.Id,
        Plant__c = kr.Id,
        User__c = users[1].Id,
        ValidFrom__c = Date.today().addDays(-30)
      )
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
      new CMN_ApprovalTemplateStep__c(
        Template__c = t.Id,
        StepNo__c = 1,
        StepType__c = 'REVIEW',
        ResolverType__c = 'ROLE',
        RoleCode__c = 'QUALITY_MANAGER',
        IsMandatory__c = true
      ),
      new CMN_ApprovalTemplateStep__c(
        Template__c = t.Id,
        StepNo__c = 3,
        StepType__c = 'APPROVE',
        ResolverType__c = 'ROLE',
        RoleCode__c = 'PLANT_MANAGER',
        IsMandatory__c = true
      )
    };
    insert new CMN_TestRecord__c(
      Name = 'target',
      Plant__c = kr.Id,
      Status__c = 'DRAFT'
    );
  }

  @IsTest
  static void test_AC01_rejectWithoutCommentBlockedOnServer() {
    // Given: 품질팀장이 처리 차례인 결재
    Map<String, User> u = users();
    Id req = CMN_ApprovalController.submit(
      targetId(),
      TYPE_CODE,
      standardLine(u),
      'please'
    );

    // 기안자(관리자)는 상신 시점 스냅숏을 본다, 처리 차례는 아니다
    CMN_ApprovalController.ActionView mine = CMN_ApprovalController.getAction(
      req
    );
    Assert.isFalse(mine.summary.isEmpty(), '상신 시점 스냅숏');
    Assert.isNull(mine.myStepId);

    System.runAs(u.get('actkim')) {
      CMN_ApprovalController.ActionView v = CMN_ApprovalController.getAction(
        req
      );
      Assert.isNotNull(v.myStepId);
      Assert.isFalse(v.isDelegate);
      Assert.areEqual(targetId(), v.targetId);
      Assert.areEqual('please', v.submitComment);
      // 스냅숏은 보는 사람의 필드 권한만큼만(테스트 대상 객체 FLS가 없는 결재자에게는 비어 있다)
      Assert.isTrue(v.summary.isEmpty());

      // When: 의견 없이(공백만) 반려
      try {
        CMN_ApprovalController.reject(v.myStepId, '   ');
        Assert.fail('의견 없는 반려는 막아야 한다');
      } catch (AuraHandledException e) {
        // Then: 서버가 차단(라벨 문구)
        Assert.areEqual(Label.CMN_Approval_CommentRequired, e.getMessage());
      }
      Assert.areEqual(
        'PENDING',
        [SELECT Status__c FROM CMN_ApprovalStep__c WHERE Id = :v.myStepId]
        .Status__c
      );

      // 의견이 있으면 반려된다
      CMN_ApprovalController.reject(v.myStepId, 'fix spec');
    }
    Assert.areEqual(
      'REJECTED',
      [SELECT Status__c FROM CMN_ApprovalRequest__c WHERE Id = :req].Status__c
    );
  }

  @IsTest
  static void test_AC02_historyShowsVersionsInOrder() {
    // Given: Version 1 반려, Version 2 승인
    Map<String, User> u = users();
    Id v1 = CMN_ApprovalController.submit(
      targetId(),
      TYPE_CODE,
      standardLine(u),
      null
    );
    System.runAs(u.get('actkim')) {
      CMN_ApprovalController.reject(stepOf(v1, u.get('actkim')), 'no');
    }
    Id v2 = CMN_ApprovalController.submit(
      targetId(),
      TYPE_CODE,
      standardLine(u),
      null
    );
    System.runAs(u.get('actkim')) {
      CMN_ApprovalController.approve(stepOf(v2, u.get('actkim')), 'ok');
    }
    System.runAs(u.get('actpm')) {
      CMN_ApprovalController.approve(stepOf(v2, u.get('actpm')), null);
    }

    // When
    List<CMN_ApprovalController.HistoryVersion> h = CMN_ApprovalController.getHistory(
      targetId()
    );

    // Then: 두 버전이 구분되어 버전 순, 단계별 처리자·의견
    Assert.areEqual(2, h.size());
    Assert.areEqual(1, h[0].version);
    Assert.areEqual('REJECTED', h[0].status);
    Assert.areEqual('REJECTED', h[0].steps[0].status);
    Assert.areEqual('no', h[0].steps[0].comment);
    Assert.areEqual('Approver actkim', h[0].steps[0].actorLabel);
    Assert.areEqual('SKIPPED', h[0].steps[1].status);
    Assert.isNull(h[0].steps[1].actorLabel);
    Assert.areEqual(2, h[1].version);
    Assert.areEqual('APPROVED', h[1].status);
    Assert.isNotNull(h[1].steps[1].actedAt);
    // 결재 요청 레코드 페이지에서도 대상의 전체 이력
    Assert.areEqual(2, CMN_ApprovalController.getHistory(v2).size());
  }

  @IsTest
  static void test_AC03_personalLineKeepsMandatorySteps() {
    // Given: 개인 결재선(합의 actdlg → 승인 actpm) 저장
    Map<String, User> u = users();
    Id personal = CMN_ApprovalController.savePersonal(
      TYPE_CODE,
      ' My line ',
      lineJson(
        new List<Object>{
          1,
          'AGREE',
          u.get('actdlg'),
          2,
          'APPROVE',
          u.get('actpm')
        }
      )
    );
    CMN_ApprovalController.LineView view = CMN_ApprovalController.getLine(
      targetId(),
      TYPE_CODE
    );
    Assert.areEqual(1, view.personalTemplates.size());
    Assert.areEqual('My line', view.personalTemplates[0].label);

    // When: 다른 건에서 불러오기
    List<CMN_ApprovalController.LineStep> line = CMN_ApprovalController.loadPersonal(
      targetId(),
      TYPE_CODE,
      personal
    );

    // Then: 개인 결재자 구성 + 템플릿 필수 단계(품질팀장 검토·공장장 승인) 유지, 단계 순(같은 순서는 필수 단계 먼저)
    Assert.areEqual(3, line.size());
    Assert.areEqual(u.get('actkim').Id, line[0].approverId, '필수 검토(1)');
    Assert.isTrue(line[0].isMandatory);
    Assert.areEqual('Approver actkim', line[0].approverName);
    Assert.areEqual(u.get('actdlg').Id, line[1].approverId, '개인 합의(1)');
    Assert.isFalse(line[1].isMandatory);
    Assert.areEqual(
      u.get('actpm').Id,
      line[2].approverId,
      '필수 승인(3) — 개인의 같은 승인은 중복 제거'
    );
    Assert.isTrue(line[2].isMandatory);

    // 불러온 결재선 그대로 상신된다(필수 단계 서버 확인 통과)
    List<CMN_ApprovalStepSpec> specs = new List<CMN_ApprovalStepSpec>();
    Integer no = 1;
    for (CMN_ApprovalController.LineStep s : line) {
      specs.add(
        new CMN_ApprovalStepSpec(no++, s.stepType, s.approverId, s.roleCode)
      );
    }
    Assert.isNotNull(
      CMN_ApprovalController.submit(
        targetId(),
        TYPE_CODE,
        JSON.serialize(specs),
        null
      )
    );
  }

  @IsTest
  static void test_BR1_searchByNameEmployeeNoDepartmentActiveOnly() {
    // Given: 활성 actemp(ZE9001), 비활성 actgone(ZE9002), 둘 다 부서 Zeta Quality Team
    // When / Then: 사번
    List<CMN_ApprovalController.UserHit> byNo = CMN_ApprovalController.searchApprovers(
      'ZE900'
    );
    Assert.areEqual(1, byNo.size(), '비활성 제외');
    Assert.areEqual('ZE9001', byNo[0].employeeNo);
    Assert.areEqual('Zeta Quality Team', byNo[0].departmentName);
    // 부서명
    List<CMN_ApprovalController.UserHit> byDept = CMN_ApprovalController.searchApprovers(
      'Zeta Quality'
    );
    Assert.areEqual(1, byDept.size());
    // 이름
    Assert.areEqual(
      1,
      CMN_ApprovalController.searchApprovers('Approver actkim').size()
    );
    // 짧은 검색어
    expectInvalid(new Call('search', null, 'Z', null));
  }

  @IsTest
  static void test_BR2_submitButtonStateAndRecall() {
    // Given: 상신 전
    Map<String, User> u = users();
    CMN_ApprovalController.LineView before = CMN_ApprovalController.getLine(
      targetId(),
      TYPE_CODE
    );
    Assert.isTrue(before.canSubmit);
    Assert.isNull(before.current);
    Assert.areEqual(2, before.steps.size(), '템플릿 필수 단계 해석');
    Assert.isFalse(before.stepTypes.isEmpty());

    // When: 상신 → 진행 중이면 상신 불가, 기안자는 회수 가능
    Id req = CMN_ApprovalController.submit(
      targetId(),
      TYPE_CODE,
      standardLine(u),
      null
    );
    CMN_ApprovalController.LineView during = CMN_ApprovalController.getLine(
      targetId(),
      TYPE_CODE
    );
    Assert.isFalse(during.canSubmit);
    Assert.areEqual(Label.CMN_Approval_AlreadyInProgress, during.refusal);
    Assert.isTrue(during.canRecall);
    CMN_ApprovalController.recall(req, 'oops');
    Assert.areEqual(
      'RECALLED',
      [SELECT Status__c FROM CMN_ApprovalRequest__c WHERE Id = :req].Status__c
    );

    // Then: 콜백 canSubmit 거절이면 버튼 비활성(사유 표시)
    CMN_ApprovalService.callbackOverride = new RefusingCallback();
    CMN_ApprovalController.LineView refused = CMN_ApprovalController.getLine(
      targetId(),
      TYPE_CODE
    );
    Assert.isFalse(refused.canSubmit);
    Assert.areEqual('not ready', refused.refusal);
  }

  @IsTest
  static void test_BR3_monitorViewsFiltersAndPendingDays() {
    // Given: 상신(관리자) 후 품질팀장 승인, 공장장 단계 3일 전부터 대기
    Map<String, User> u = users();
    Id req = CMN_ApprovalController.submit(
      targetId(),
      TYPE_CODE,
      standardLine(u),
      null
    );
    System.runAs(u.get('actkim')) {
      CMN_ApprovalController.approve(stepOf(req, u.get('actkim')), null);
    }
    update new CMN_ApprovalStep__c(
      Id = stepOf(req, u.get('actpm')),
      PendingAt__c = Datetime.now().addDays(-3)
    );
    Id plantId = [SELECT Id FROM CMN_Plant__c WHERE PlantCode__c = 'KR01'].Id;

    // When / Then: 내가 상신
    List<CMN_ApprovalController.MonitorRow> mine = CMN_ApprovalController.getMonitor(
      'SUBMITTED',
      TYPE_CODE,
      plantId,
      Date.today(),
      Date.today()
    );
    Assert.areEqual(1, mine.size());
    Assert.areEqual(
      3,
      mine[0].pendingDays,
      '체류일수 = 현재 PENDING 시작 이후 달력일'
    );
    Assert.areEqual('Approver actpm', mine[0].pendingApprovers);
    Assert.areEqual('KR01', mine[0].plantCode);
    // 진행 중
    Assert.areEqual(
      1,
      CMN_ApprovalController.getMonitor('IN_PROGRESS', null, null, null, null)
        .size()
    );
    // 필터: 다른 유형, 내일 이후
    Assert.areEqual(
      0,
      CMN_ApprovalController.getMonitor(
          'SUBMITTED',
          'CMN_DOC_RELEASE',
          null,
          null,
          null
        )
        .size()
    );
    Assert.areEqual(
      0,
      CMN_ApprovalController.getMonitor(
          'SUBMITTED',
          null,
          null,
          Date.today().addDays(1),
          null
        )
        .size()
    );
    // 내가 처리(품질팀장)
    System.runAs(u.get('actkim')) {
      Assert.areEqual(
        1,
        CMN_ApprovalController.getMonitor('ACTED', null, null, null, null)
          .size()
      );
      Assert.areEqual(
        0,
        CMN_ApprovalController.getMonitor('SUBMITTED', null, null, null, null)
          .size()
      );
    }
    // 잘못된 보기
    expectInvalid(new Call('monitor', null, 'ALL', null));
    // 유형 선택지
    Boolean found = false;
    for (CMN_ApprovalController.Option o : CMN_ApprovalController.getTypes()) {
      found = found || o.value == TYPE_CODE;
    }
    Assert.isTrue(found);
  }

  @IsTest
  static void test_delegateSeesTurnAndHistoryShowsOnBehalf() {
    // Given: 품질팀장 차례에서 품질팀장이 actdlg에게 위임
    Map<String, User> u = users();
    Id req = CMN_ApprovalController.submit(
      targetId(),
      TYPE_CODE,
      standardLine(u),
      null
    );
    System.runAs(u.get('actkim')) {
      insert new CMN_Delegation__c(
        Delegator__c = u.get('actkim').Id,
        Delegate__c = u.get('actdlg').Id,
        StartAt__c = Datetime.now().addHours(-1),
        EndAt__c = Datetime.now().addDays(1),
        Reason__c = 'trip'
      );
    }

    // When: 대리인이 처리 화면을 열고 승인
    System.runAs(u.get('actdlg')) {
      CMN_ApprovalController.ActionView v = CMN_ApprovalController.getAction(
        req
      );
      Assert.isTrue(v.isDelegate);
      Assert.areEqual('Approver actkim', v.delegatorName);
      CMN_ApprovalController.approve(v.myStepId, 'on behalf');
    }

    // Then: 이력에 "처리자(대결: 위임자)", 공장장은 차례가 아닌 사람에게는 처리 단계 없음
    CMN_ApprovalController.HistoryStep s = CMN_ApprovalController.getHistory(
        targetId()
      )[0]
      .steps[0];
    Assert.areEqual(
      String.format(
        Label.CMN_Approval_DelegatedActor,
        new List<Object>{ 'Approver actdlg', 'Approver actkim' }
      ),
      s.actorLabel
    );
    System.runAs(u.get('actdlg')) {
      Assert.isNull(CMN_ApprovalController.getAction(req)?.myStepId);
    }
  }

  @IsTest
  static void test_negative_invalidInputs() {
    Map<String, User> u = users();
    Id stepLike =
      CMN_ApprovalStep__c.SObjectType.getDescribe(
          SObjectDescribeOptions.DEFERRED
        )
        .getKeyPrefix() + '000000000001';
    Id requestLike =
      CMN_ApprovalRequest__c.SObjectType.getDescribe(
          SObjectDescribeOptions.DEFERRED
        )
        .getKeyPrefix() + '000000000001';
    Id target = targetId();
    List<Runner> cases = new List<Runner>{
      new Call('getLine', target, 'bad type!', null),
      new Call('submit', target, TYPE_CODE, '{not json'),
      new Call('submit', target, TYPE_CODE, '[]'),
      new Call('loadPersonal', target, TYPE_CODE, null),
      new Call('approveWrongType', requestLike, null, null),
      new Call('rejectWrongType', target, null, null),
      new Call('recallWrongType', stepLike, null, null),
      new Call('getAction', stepLike, null, null),
      new Call('getHistory', null, null, null),
      new Call('savePersonal', null, TYPE_CODE, '[]')
    };
    for (Runner r : cases) {
      expectInvalid(r);
    }
    // 처리 차례가 아닌 사람의 승인은 서비스가 막는다(일반 오류가 아닌 라벨 문구)
    Id req = CMN_ApprovalController.submit(
      target,
      TYPE_CODE,
      standardLine(u),
      null
    );
    System.runAs(u.get('actpm')) {
      try {
        CMN_ApprovalController.approve(stepOf(req, u.get('actpm')), null);
        Assert.fail('대기 단계가 아니면 승인할 수 없다');
      } catch (AuraHandledException e) {
        Assert.areNotEqual(Label.CMN_Common_UnexpectedError, e.getMessage());
      }
    }
    // 없는 요청은 null
    Assert.isNull(CMN_ApprovalController.getAction(requestLike));
  }

  // ------------------------------------------------------------------ 도우미
  private interface Runner {
    void run();
  }

  /** 잘못된 입력 호출 모음(익명 클래스가 없어 이름으로 나눈다). */
  private class Call implements Runner {
    private String name;
    private Id recordId;
    private String a;
    private String b;
    Call(String name, Id recordId, String a, String b) {
      this.name = name;
      this.recordId = recordId;
      this.a = a;
      this.b = b;
    }
    public void run() {
      switch on name {
        when 'getLine' {
          CMN_ApprovalController.getLine(recordId, a);
        }
        when 'submit' {
          CMN_ApprovalController.submit(recordId, a, b, null);
        }
        when 'loadPersonal' {
          CMN_ApprovalController.loadPersonal(recordId, a, recordId);
        }
        when 'approveWrongType' {
          CMN_ApprovalController.approve(recordId, null);
        }
        when 'rejectWrongType' {
          CMN_ApprovalController.reject(recordId, 'x');
        }
        when 'recallWrongType' {
          CMN_ApprovalController.recall(recordId, null);
        }
        when 'getAction' {
          CMN_ApprovalController.getAction(recordId);
        }
        when 'getHistory' {
          CMN_ApprovalController.getHistory(recordId);
        }
        when 'search' {
          CMN_ApprovalController.searchApprovers(a);
        }
        when 'monitor' {
          CMN_ApprovalController.getMonitor(a, null, null, null, null);
        }
        when 'savePersonal' {
          CMN_ApprovalController.savePersonal(a, ' ', b);
        }
      }
    }
  }

  private static void expectInvalid(Runner r) {
    try {
      r.run();
      Assert.fail('입력 오류가 나야 한다: ' + r);
    } catch (AuraHandledException e) {
      Assert.areEqual(
        Label.CMN_Common_InvalidInput,
        e.getMessage(),
        String.valueOf(r)
      );
    }
  }

  private static Map<String, User> users() {
    Map<String, User> out = new Map<String, User>();
    for (User u : [
      SELECT Id, Alias
      FROM User
      WHERE Alias LIKE 'act%' AND Username LIKE :('%' + DOMAIN)
    ]) {
      out.put(u.Alias, u);
    }
    return out;
  }

  private static Id targetId() {
    return [SELECT Id FROM CMN_TestRecord__c LIMIT 1].Id;
  }

  /** 템플릿 필수 단계를 담은 기본 결재선: 1 검토 품질팀장 → 2 승인 공장장. */
  private static String standardLine(Map<String, User> u) {
    return lineJson(
      new List<Object>{
        1,
        'REVIEW',
        u.get('actkim'),
        2,
        'APPROVE',
        u.get('actpm')
      }
    );
  }

  /** [stepNo, type, user, ...] → 화면과 같은 결재선 JSON */
  private static String lineJson(List<Object> spec) {
    List<Map<String, Object>> out = new List<Map<String, Object>>();
    for (Integer i = 0; i < spec.size(); i += 3) {
      out.add(
        new Map<String, Object>{
          'stepNo' => spec[i],
          'stepType' => spec[i + 1],
          'approverId' => ((User) spec[i + 2]).Id,
          'roleCode' => null
        }
      );
    }
    return JSON.serialize(out);
  }

  private static Id stepOf(Id requestId, User approver) {
    return [
      SELECT Id
      FROM CMN_ApprovalStep__c
      WHERE Request__c = :requestId AND Approver__c = :approver.Id
    ]
    .Id;
  }
}
