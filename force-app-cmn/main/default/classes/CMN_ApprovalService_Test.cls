/**
 * @description 공통 결재 엔진 검증(CMN-00-APV-001). 업무 객체 대신 테스트 대상 객체와 기록 콜백으로 검증한다(CR-11·DEV-3).
 * @group CMN-00-APV-001
 */
@IsTest
private class CMN_ApprovalService_Test {
  private static final String TYPE_CODE = 'CMN_TEST_APPROVE';

  /** 콜백 호출 기록. */
  private class RecordingCallback implements CMN_ApprovalCallback {
    public Map<String, Integer> calls = new Map<String, Integer>();
    public String refusal;
    private void hit(String name) {
      calls.put(name, (calls.get(name) ?? 0) + 1);
    }
    public String canSubmit(Id targetId) {
      return refusal;
    }
    public void onSubmitted(CMN_ApprovalRequest__c r) {
      hit('submitted');
    }
    public void onApproved(CMN_ApprovalRequest__c r) {
      hit('approved');
    }
    public void onRejected(CMN_ApprovalRequest__c r) {
      hit('rejected');
    }
    public void onRecalled(CMN_ApprovalRequest__c r) {
      hit('recalled');
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
    insert new List<CMN_Plant__c>{ plant(c.Id, 'KR01'), plant(c.Id, 'CN01') };
    List<User> users = new List<User>();
    for (
      String a : new List<String>{ 'apv1', 'apv2', 'apv3', 'apv4', 'apv5' }
    ) {
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
    insert new CMN_TestRecord__c(
      Name = 'target',
      Plant__c = [SELECT Id FROM CMN_Plant__c WHERE PlantCode__c = 'KR01']
      .Id,
      Status__c = 'DRAFT'
    );
  }

  @IsTest
  static void test_AC01_parallelAgreeWaitsForAll() {
    // Given: 검토(1) - 합의 2명 병렬(2) - 승인(3)
    RecordingCallback cb = callback();
    Map<String, User> u = users();
    Id req = CMN_ApprovalService.submit(
      targetId(),
      TYPE_CODE,
      line(
        new List<Object>{
          1,
          'REVIEW',
          u.get('apv1'),
          2,
          'AGREE',
          u.get('apv2'),
          2,
          'AGREE',
          u.get('apv3'),
          3,
          'APPROVE',
          u.get('apv4')
        }
      ),
      'go'
    );

    // When: 1 승인, 2의 1명만 승인
    act(u.get('apv1'), stepOf(req, u.get('apv1')), true);
    act(u.get('apv2'), stepOf(req, u.get('apv2')), true);

    // Then: 3은 WAITING, 요청은 2단계 진행 중. 나머지 합의 후 3이 PENDING
    Assert.areEqual('WAITING', statusOf(req, u.get('apv4')));
    Assert.areEqual(
      2,
      [SELECT CurrentStepNo__c FROM CMN_ApprovalRequest__c WHERE Id = :req]
      .CurrentStepNo__c
    );
    act(u.get('apv3'), stepOf(req, u.get('apv3')), true);
    Assert.areEqual('PENDING', statusOf(req, u.get('apv4')));
    act(u.get('apv4'), stepOf(req, u.get('apv4')), true);
    CMN_ApprovalRequest__c done = [
      SELECT Status__c, CompletedAt__c, RecordNo__c
      FROM CMN_ApprovalRequest__c
      WHERE Id = :req
    ];
    Assert.areEqual('APPROVED', done.Status__c);
    Assert.isTrue(done.RecordNo__c.startsWith('APV-'));
    Assert.isFalse(Approval.isLocked(targetId()));
    Assert.areEqual(1, cb.calls.get('approved'));
  }

  @IsTest
  static void test_AC02_rejectSkipsRestAndUnlocks() {
    // Given: 3단계 결재선, 1단계 승인
    RecordingCallback cb = callback();
    Map<String, User> u = users();
    Id req = CMN_ApprovalService.submit(
      targetId(),
      TYPE_CODE,
      line(
        new List<Object>{
          1,
          'REVIEW',
          u.get('apv1'),
          2,
          'AGREE',
          u.get('apv2'),
          3,
          'APPROVE',
          u.get('apv3')
        }
      ),
      null
    );
    Assert.isTrue(Approval.isLocked(targetId()));
    act(u.get('apv1'), stepOf(req, u.get('apv1')), true);

    // When: 2단계 반려
    System.runAs(u.get('apv2')) {
      CMN_ApprovalService.reject(stepOf(req, u.get('apv2')), '규격 근거 부족');
    }

    // Then: 요청 REJECTED, 3단계 SKIPPED, 잠금 해제, onRejected 1회
    Assert.areEqual(
      'REJECTED',
      [SELECT Status__c FROM CMN_ApprovalRequest__c WHERE Id = :req].Status__c
    );
    Assert.areEqual('SKIPPED', statusOf(req, u.get('apv3')));
    Assert.isFalse(Approval.isLocked(targetId()));
    Assert.areEqual(1, cb.calls.get('rejected'));
  }

  @IsTest
  static void test_AC03_lastStepMustBeApprove() {
    // Given / When / Then: 마지막이 검토
    Map<String, User> u = users();
    expectError(
      Label.CMN_Approval_LastMustApprove,
      line(
        new List<Object>{
          1,
          'APPROVE',
          u.get('apv1'),
          2,
          'REVIEW',
          u.get('apv2')
        }
      )
    );
  }

  @IsTest
  static void test_AC04_otherPlantApproverCanReadTarget() {
    // Given: 공장 접근이 없는 결재자(다른 공장 사용자)
    Map<String, User> u = users();
    Integer before;
    System.runAs(u.get('apv5')) {
      before = [SELECT COUNT() FROM CMN_TestRecord__c];
    }

    // When: 상신
    CMN_ApprovalService.submit(
      targetId(),
      TYPE_CODE,
      line(new List<Object>{ 1, 'APPROVE', u.get('apv5') }),
      null
    );

    // Then: 대상과 결재 요청을 읽을 수 있다
    System.runAs(u.get('apv5')) {
      Assert.areEqual(0, before);
      Assert.areEqual(1, [SELECT COUNT() FROM CMN_TestRecord__c]);
      Assert.areEqual(1, [SELECT COUNT() FROM CMN_ApprovalRequest__c]);
    }
  }

  @IsTest
  static void test_AC05_recallBlockedAfterFirstStep() {
    // Given: 1단계 처리 완료
    callback();
    Map<String, User> u = users();
    Id req = CMN_ApprovalService.submit(
      targetId(),
      TYPE_CODE,
      line(
        new List<Object>{
          1,
          'REVIEW',
          u.get('apv1'),
          2,
          'APPROVE',
          u.get('apv2')
        }
      ),
      null
    );
    act(u.get('apv1'), stepOf(req, u.get('apv1')), true);

    // When / Then: 기안자 회수 차단
    try {
      CMN_ApprovalService.recall(req, 'x');
      Assert.fail('회수가 막혀야 한다');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Approval_RecallNotAllowed, e.getMessage());
    }
  }

  @IsTest
  static void test_BR4_recallBeforeAnyActionAndOnlyDrafter() {
    // Given: 상신 직후
    RecordingCallback cb = callback();
    Map<String, User> u = users();
    Id req = CMN_ApprovalService.submit(
      targetId(),
      TYPE_CODE,
      line(new List<Object>{ 1, 'APPROVE', u.get('apv1') }),
      null
    );

    // When: 결재자가 회수 시도(기안자 아님) → 차단, 기안자 회수 → 성공
    System.runAs(u.get('apv1')) {
      try {
        CMN_ApprovalService.recall(req, 'x');
        Assert.fail('기안자만');
      } catch (CMN_ValidationException e) {
        Assert.areEqual(Label.CMN_Approval_RecallNotAllowed, e.getMessage());
      }
    }
    CMN_ApprovalService.recall(req, '수정 후 재상신');

    // Then
    Assert.areEqual(
      'RECALLED',
      [SELECT Status__c FROM CMN_ApprovalRequest__c WHERE Id = :req].Status__c
    );
    Assert.areEqual('SKIPPED', statusOf(req, u.get('apv1')));
    Assert.isFalse(Approval.isLocked(targetId()));
    Assert.areEqual(1, cb.calls.get('recalled'));
  }

  @IsTest
  static void test_AC06_resubmitCreatesVersion2() {
    // Given: 승인 완료
    callback();
    Map<String, User> u = users();
    Id v1 = CMN_ApprovalService.submit(
      targetId(),
      TYPE_CODE,
      line(new List<Object>{ 1, 'APPROVE', u.get('apv1') }),
      null
    );
    act(u.get('apv1'), stepOf(v1, u.get('apv1')), true);

    // When: 같은 대상 재상신
    Id v2 = CMN_ApprovalService.submit(
      targetId(),
      TYPE_CODE,
      line(new List<Object>{ 1, 'APPROVE', u.get('apv2') }),
      null
    );

    // Then: Version 2, Version 1 이력 유지, 상태 조회는 최신
    Assert.areEqual(
      2,
      [SELECT Version__c FROM CMN_ApprovalRequest__c WHERE Id = :v2].Version__c
    );
    Assert.areEqual(
      'APPROVED',
      [SELECT Status__c FROM CMN_ApprovalRequest__c WHERE Id = :v1].Status__c
    );
    CMN_ApprovalStatusDTO s = CMN_ApprovalService.getStatus(targetId());
    Assert.areEqual(v2, s.requestId);
    Assert.areEqual(2, s.version);
    Assert.areEqual('PENDING', s.steps[0].status);
  }

  @IsTest
  static void test_BR2_ccIsNotifiedWithoutWaitingAndEvents() {
    // Given: 참조(1) - 승인(2)
    callback();
    Map<String, User> u = users();
    CMN_ApprovalService.published.clear();

    // When
    Id req = CMN_ApprovalService.submit(
      targetId(),
      TYPE_CODE,
      line(
        new List<Object>{ 1, 'CC', u.get('apv1'), 2, 'APPROVE', u.get('apv2') }
      ),
      null
    );

    // Then: 참조는 NOTIFIED, 승인이 바로 PENDING, 이벤트 SUBMITTED·STEP_PENDING
    Assert.areEqual('NOTIFIED', statusOf(req, u.get('apv1')));
    Assert.areEqual('PENDING', statusOf(req, u.get('apv2')));
    Set<String> types = new Set<String>();
    for (CMN_ApprovalEvent__e e : CMN_ApprovalService.published) {
      types.add(e.EventType__c);
      if (e.EventType__c == 'STEP_PENDING') {
        Assert.areEqual(stepOf(req, u.get('apv2')), e.StepId__c);
      }
    }
    Assert.areEqual(new Set<String>{ 'SUBMITTED', 'STEP_PENDING' }, types);
  }

  @IsTest
  static void test_BR1_validationsAndInProgressGuard() {
    // Given
    RecordingCallback cb = callback();
    Map<String, User> u = users();
    User inactive = u.get('apv5');
    System.runAs(new User(Id = UserInfo.getUserId())) {
      inactive.IsActive = false;
      update inactive;
    }

    // When / Then: 빈 결재선, 기안자 본인, 비활성, 없는 유형, 콜백 거부, 진행 중 재상신, 반려 사유 없음, 결재자 아님
    expectError(Label.CMN_Approval_NoSteps, new List<CMN_ApprovalStepSpec>());
    expectError(
      Label.CMN_Approval_SelfApproval,
      line(
        new List<Object>{ 1, 'APPROVE', new User(Id = UserInfo.getUserId()) }
      )
    );
    expectError(
      Label.CMN_Approval_ApproverInactive,
      line(new List<Object>{ 1, 'APPROVE', inactive })
    );
    try {
      CMN_ApprovalService.submit(
        targetId(),
        'NO_SUCH_TYPE',
        line(new List<Object>{ 1, 'APPROVE', u.get('apv1') }),
        null
      );
      Assert.fail('유형 없음');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(
        String.format(
          Label.CMN_Approval_NoType,
          new List<Object>{ 'NO_SUCH_TYPE' }
        ),
        e.getMessage()
      );
    }
    cb.refusal = 'BLOCKED';
    expectError(
      String.format(
        Label.CMN_Approval_CannotSubmit,
        new List<Object>{ 'BLOCKED' }
      ),
      line(new List<Object>{ 1, 'APPROVE', u.get('apv1') })
    );
    cb.refusal = null;
    // apv2는 뒤 단계 결재자라 요청을 볼 수 있지만 1단계 결재자는 아니다
    Id req = CMN_ApprovalService.submit(
      targetId(),
      TYPE_CODE,
      line(
        new List<Object>{
          1,
          'REVIEW',
          u.get('apv1'),
          2,
          'APPROVE',
          u.get('apv2')
        }
      ),
      null
    );
    expectError(
      Label.CMN_Approval_AlreadyInProgress,
      line(new List<Object>{ 1, 'APPROVE', u.get('apv2') })
    );
    Id stepId = stepOf(req, u.get('apv1'));
    try {
      CMN_ApprovalService.reject(stepId, ' ');
      Assert.fail('사유 필수');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Approval_CommentRequired, e.getMessage());
    }
    System.runAs(u.get('apv2')) {
      try {
        CMN_ApprovalService.approve(stepId, null);
        Assert.fail('결재자 아님');
      } catch (CMN_ValidationException e) {
        Assert.areEqual(Label.CMN_Approval_NotApprover, e.getMessage());
      }
    }
  }

  @IsTest
  static void test_BR1_requireDrafterManager() {
    // Given: 부서장 필수 유형, 기안자 부서의 부서장 apv3
    Map<String, User> u = users();
    CMN_Department__c dept = new CMN_Department__c(
      Name = 'QM',
      DeptCode__c = 'DQ',
      Manager__c = u.get('apv3').Id
    );
    insert dept;
    User me = new User(Id = UserInfo.getUserId(), DepartmentCode__c = 'DQ');
    System.runAs(new User(Id = UserInfo.getUserId())) {
      update me;
    }
    CMN_ApprovalService.typesOverride = new Map<String, CMN_ApprovalType__mdt>{
      'PMS_DELIVERABLE' => new CMN_ApprovalType__mdt(
        DeveloperName = 'PMS_DELIVERABLE',
        TargetObject__c = 'CMN_TestRecord__c',
        RequireDrafterManager__c = true
      )
    };

    // When / Then: 부서장 없으면 차단, 있으면 상신
    try {
      CMN_ApprovalService.submit(
        targetId(),
        'PMS_DELIVERABLE',
        line(new List<Object>{ 1, 'APPROVE', u.get('apv1') }),
        null
      );
      Assert.fail('부서장 필수');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Approval_ManagerRequired, e.getMessage());
    }
    Id req = CMN_ApprovalService.submit(
      targetId(),
      'PMS_DELIVERABLE',
      line(
        new List<Object>{
          1,
          'REVIEW',
          u.get('apv3'),
          2,
          'APPROVE',
          u.get('apv1')
        }
      ),
      null
    );
    Assert.isNotNull(req);
    Assert.isFalse(Approval.isLocked(targetId()));
  }

  @IsTest
  static void test_stepSpecDeserializesFromScreen() {
    // Given / When: 화면(LWC)이 보낸 결재선 JSON
    List<CMN_ApprovalStepSpec> specs = (List<CMN_ApprovalStepSpec>) JSON.deserialize(
      '[{"stepNo":1,"stepType":"APPROVE","approverId":"' +
        users().get('apv1').Id +
        '","roleCode":"QUALITY_MANAGER"}]',
      List<CMN_ApprovalStepSpec>.class
    );

    // Then
    Assert.areEqual(1, specs[0].stepNo);
    Assert.areEqual('QUALITY_MANAGER', specs[0].roleCode);
    Assert.isNull(new CMN_ApprovalStepSpec().stepNo);
    Assert.isNull(CMN_ApprovalService.getStatus(targetId()));
  }

  // ------------------------------------------------------------------ 도우미
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

  private static RecordingCallback callback() {
    RecordingCallback cb = new RecordingCallback();
    CMN_ApprovalService.callbackOverride = cb;
    return cb;
  }

  private static Map<String, User> users() {
    Map<String, User> out = new Map<String, User>();
    for (User u : [SELECT Id, Alias FROM User WHERE Alias LIKE 'apv%']) {
      out.put(u.Alias, u);
    }
    return out;
  }

  private static Id targetId() {
    return [SELECT Id FROM CMN_TestRecord__c LIMIT 1].Id;
  }

  /** [stepNo, type, user, ...] → 결재선 */
  private static List<CMN_ApprovalStepSpec> line(List<Object> spec) {
    List<CMN_ApprovalStepSpec> out = new List<CMN_ApprovalStepSpec>();
    for (Integer i = 0; i < spec.size(); i += 3) {
      out.add(
        new CMN_ApprovalStepSpec(
          (Integer) spec[i],
          (String) spec[i + 1],
          ((User) spec[i + 2]).Id,
          null
        )
      );
    }
    return out;
  }

  private static Id stepOf(Id requestId, User approver) {
    return [
      SELECT Id
      FROM CMN_ApprovalStep__c
      WHERE Request__c = :requestId AND Approver__c = :approver.Id
    ]
    .Id;
  }

  private static String statusOf(Id requestId, User approver) {
    return [
      SELECT Status__c
      FROM CMN_ApprovalStep__c
      WHERE Request__c = :requestId AND Approver__c = :approver.Id
    ]
    .Status__c;
  }

  private static void act(User approver, Id stepId, Boolean approve) {
    System.runAs(approver) {
      if (approve) {
        CMN_ApprovalService.approve(stepId, 'ok');
      } else {
        CMN_ApprovalService.reject(stepId, 'no');
      }
    }
  }

  private static void expectError(
    String expected,
    List<CMN_ApprovalStepSpec> steps
  ) {
    try {
      CMN_ApprovalService.submit(targetId(), TYPE_CODE, steps, null);
      Assert.fail('예외가 나야 한다: ' + expected);
    } catch (CMN_ValidationException e) {
      Assert.areEqual(expected, e.getMessage());
    }
  }
}
