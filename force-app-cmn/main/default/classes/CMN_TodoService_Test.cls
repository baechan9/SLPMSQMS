/**
 * @description 통합 To-Do 서비스·결재 이벤트 구독 검증(CMN-00-TDO-001).
 * @group CMN-00-TDO-001
 */
@IsTest
private class CMN_TodoService_Test {
  private static final String TYPE_CODE = 'CMN_TEST_APPROVE';
  private static final String TITLE_LABEL = 'CMN_Todo_CMN_APPROVAL';
  private static final String SOURCE = 'CMN_TEST_TASK';

  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    insert new CMN_Plant__c(
      Name = 'KR01',
      PlantCode__c = 'KR01',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    List<User> users = new List<User>();
    for (String a : new List<String>{ 'tdo1', 'tdo2', 'tdo3', 'tdoadm' }) {
      User u = CMN_TestDataFactory.newUser(a, a, profileId);
      u.EmployeeNo__c = 'T' + a.toUpperCase();
      users.add(u);
    }
    users[1].LanguageLocaleKey = 'zh_CN';
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert users;
      Map<String, Id> ps = new Map<String, Id>();
      for (PermissionSet p : [
        SELECT Id, Name
        FROM PermissionSet
        WHERE Name IN ('CMN_PS_Todo_User', 'CMN_PS_Todo_Admin')
      ]) {
        ps.put(p.Name, p.Id);
      }
      List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
      for (User u : users) {
        psa.add(
          new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.get('CMN_PS_Todo_User')
          )
        );
      }
      psa.add(
        new PermissionSetAssignment(
          AssigneeId = users[3].Id,
          PermissionSetId = ps.get('CMN_PS_Todo_Admin')
        )
      );
      insert psa;
    }
    insert new CMN_TestRecord__c(
      Name = 'target',
      Plant__c = [SELECT Id FROM CMN_Plant__c LIMIT 1]
      .Id,
      Status__c = 'DRAFT'
    );
  }

  @IsTest
  static void test_AC01_openTwiceKeepsOneTodo() {
    // Given: 같은 명세
    User u = user('tdo1');
    CMN_TodoSpec spec = spec(u.Id, fakeId(1));
    spec.titleParams = new List<Object>{ 'NCR-KR01-2026-000001' };
    spec.dueDate = Date.newInstance(2026, 12, 9);

    // When: open 2회
    CMN_TodoService.open(new List<CMN_TodoSpec>{ spec });
    CMN_TodoService.open(new List<CMN_TodoSpec>{ spec });

    // Then: To-Do 1건, Owner = Assignee, 기본 제목은 기본 언어(ko) 렌더링, 이벤트는 처음 1건만
    List<CMN_Todo__c> rows = [
      SELECT
        Id,
        OwnerId,
        Status__c,
        ExternalKey__c,
        TitleFallback__c,
        Name,
        SourceObject__c,
        Category__c
      FROM CMN_Todo__c
    ];
    Assert.areEqual(1, rows.size());
    Assert.areEqual(u.Id, rows[0].OwnerId);
    Assert.areEqual('OPEN', rows[0].Status__c);
    Assert.areEqual(
      SOURCE + '/' + fakeId(1) + '/' + u.Id,
      rows[0].ExternalKey__c
    );
    Assert.areEqual('[결재] NCR-KR01-2026-000001', rows[0].TitleFallback__c);
    Assert.areEqual(rows[0].TitleFallback__c, rows[0].Name);
    Assert.areEqual('CMN_TestRecord__c', rows[0].SourceObject__c);
    Assert.areEqual(1, CMN_TodoService.published.size());
    Assert.areEqual(
      'TTDO1',
      CMN_TodoService.published[0].AssigneeEmployeeNo__c
    );
    Assert.areEqual('OPEN', CMN_TodoService.published[0].ChangeType__c);

    // When: 완료 후 다시 open → 같은 레코드가 다시 열린다
    CMN_TodoService.close(SOURCE, new Set<Id>{ fakeId(1) }, u.Id);
    Assert.areEqual('DONE', [SELECT Status__c FROM CMN_Todo__c].Status__c);
    CMN_TodoService.open(new List<CMN_TodoSpec>{ spec });
    CMN_Todo__c reopened = [
      SELECT Id, Status__c, CompletedAt__c
      FROM CMN_Todo__c
    ];
    Assert.areEqual(rows[0].Id, reopened.Id);
    Assert.areEqual('OPEN', reopened.Status__c);
    Assert.isNull(reopened.CompletedAt__c);
  }

  @IsTest
  static void test_AC02_approvalPendingOpensAndApprovalClosesTodo() {
    // Given: 검토(tdo1) → 승인(tdo2) 결재 상신
    User a1 = user('tdo1');
    User a2 = user('tdo2');
    Id target = [SELECT Id FROM CMN_TestRecord__c].Id;
    Id req = CMN_ApprovalService.submit(
      target,
      TYPE_CODE,
      new List<CMN_ApprovalStepSpec>{
        new CMN_ApprovalStepSpec(1, 'REVIEW', a1.Id, null),
        new CMN_ApprovalStepSpec(2, 'APPROVE', a2.Id, null)
      },
      'go'
    );

    // When: PENDING 이벤트 처리
    Test.getEventBus().deliver();

    // Then: tdo1에게 APPROVAL To-Do(원천 = 결재 단계, 클릭 대상 = 결재 대상)
    CMN_Todo__c t = todoOf(a1.Id);
    Assert.areEqual('OPEN', t.Status__c);
    Assert.areEqual('APPROVAL', t.Category__c);
    Assert.areEqual('CMN', t.System__c);
    Assert.areEqual('CMN_APPROVAL', t.SourceType__c);
    Assert.areEqual('CMN_ApprovalStep__c', t.SourceObject__c);
    Assert.areEqual(String.valueOf(target), t.TargetRecordId__c);
    Assert.areEqual(TITLE_LABEL, t.TitleLabel__c);
    Assert.isNotNull(t.Plant__c);
    Assert.isNull(todoOf(a2.Id));

    // When: tdo1 승인 → 이벤트 처리
    approve(a1, t.SourceRecordId__c);
    Test.getEventBus().deliver();

    // Then: tdo1 DONE, tdo2 OPEN. 마지막 승인 후 모두 DONE
    Assert.areEqual('DONE', todoOf(a1.Id).Status__c);
    Assert.isNotNull(todoOf(a1.Id).CompletedAt__c);
    CMN_Todo__c t2 = todoOf(a2.Id);
    Assert.areEqual('OPEN', t2.Status__c);
    approve(a2, t2.SourceRecordId__c);
    Test.getEventBus().deliver();
    Assert.areEqual('DONE', todoOf(a2.Id).Status__c);
    Assert.areEqual(
      'APPROVED',
      [SELECT Status__c FROM CMN_ApprovalRequest__c WHERE Id = :req].Status__c
    );
  }

  @IsTest
  static void test_BR2_rejectCancelsParallelAndRecallCancels() {
    // Given: 합의 2명 병렬(tdo1, tdo2) → 승인(tdo3)
    User a1 = user('tdo1');
    User a2 = user('tdo2');
    User a3 = user('tdo3');
    Id target = [SELECT Id FROM CMN_TestRecord__c].Id;
    CMN_ApprovalService.submit(target, TYPE_CODE, line(a1, a2, a3), null);
    Test.getEventBus().deliver();
    Assert.areEqual('OPEN', todoOf(a2.Id).Status__c);

    // When: tdo1 반려
    System.runAs(a1) {
      CMN_ApprovalService.reject((Id) todoOf(a1.Id).SourceRecordId__c, 'no');
    }
    Test.getEventBus().deliver();

    // Then: 반려한 단계는 DONE, 병렬 단계는 CANCELLED, 다음 단계 To-Do는 없다
    Assert.areEqual('DONE', todoOf(a1.Id).Status__c);
    Assert.areEqual('CANCELLED', todoOf(a2.Id).Status__c);
    Assert.isNull(todoOf(a3.Id));

    // When: 재상신 후 처리 전에 회수
    Id req2 = CMN_ApprovalService.submit(
      target,
      TYPE_CODE,
      line(a1, a2, a3),
      null
    );
    Test.getEventBus().deliver();
    Assert.areEqual(
      2,
      [SELECT COUNT() FROM CMN_Todo__c WHERE Status__c = 'OPEN']
    );
    CMN_ApprovalService.recall(req2, 'recall');
    Test.getEventBus().deliver();

    // Then: 남은 To-Do가 모두 CANCELLED
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM CMN_Todo__c WHERE Status__c = 'OPEN']
    );
  }

  @IsTest
  static void test_AC03_chineseAssigneeGetsChineseTitle() {
    // Given: 중국어 사용자에게 번호 치환값이 있는 To-Do
    User zh = user('tdo2');
    CMN_Todo__c t = new CMN_Todo__c(
      TitleLabel__c = TITLE_LABEL,
      TitleParams__c = '["PPA-KR01-2026-00006"]',
      TitleFallback__c = 'fallback'
    );

    // When / Then: 중국어 제목, 번역 없는 언어는 en_US, 객체 치환값 {key}
    Assert.areEqual(
      '[审批] PPA-KR01-2026-00006',
      CMN_TodoService.renderTitle(t, zh.LanguageLocaleKey)
    );
    Assert.areEqual(
      '[Approval] PPA-KR01-2026-00006',
      CMN_TodoService.renderTitle(t, 'ja')
    );
    t.TitleParams__c = '{"0":"8D-KR01-2026-00029"}';
    Assert.areEqual(
      '[결재] 8D-KR01-2026-00029',
      CMN_TodoService.renderTitle(t, null)
    );

    // 라벨이 없으면(다른 메뉴가 아직 만들지 않음) 기본 제목, 치환값이 깨져도 라벨 그대로
    t.TitleLabel__c = 'QMS_Todo_NOT_DEPLOYED_YET';
    Assert.areEqual('fallback', CMN_TodoService.renderTitle(t, 'zh_CN'));
    t.TitleLabel__c = TITLE_LABEL;
    t.TitleParams__c = 'not json';
    Assert.areEqual('[审批] {0}', CMN_TodoService.renderTitle(t, 'zh_CN'));
  }

  @IsTest
  static void test_AC04_bulk200SpecsUseTwoQueriesOneDml() {
    // Given: 200건 명세(처리자 2명)
    User a1 = user('tdo1');
    User a2 = user('tdo2');
    List<CMN_TodoSpec> specs = new List<CMN_TodoSpec>();
    for (Integer i = 0; i < 200; i++) {
      CMN_TodoSpec s = spec(Math.mod(i, 2) == 0 ? a1.Id : a2.Id, fakeId(i));
      s.titleParams = new List<Object>{ 'NO-' + i };
      specs.add(s);
    }

    // When
    Test.startTest();
    Integer q0 = Limits.getQueries();
    Integer d0 = Limits.getDmlStatements();
    CMN_TodoService.open(specs);
    Integer queries = Limits.getQueries() - q0;
    Integer dml = Limits.getDmlStatements() - d0;
    Test.stopTest();

    // Then: SOQL 2회 이하, 레코드 DML 1회 + 이벤트 발행 1회(PublishAfterCommit 발행은 DML 한도에 1회로 잡힌다), 200건 생성
    Assert.isTrue(queries <= 2, 'SOQL ' + queries);
    Assert.isTrue(dml <= 2, 'DML ' + dml);
    Assert.areEqual(200, [SELECT COUNT() FROM CMN_Todo__c]);
    Assert.areEqual(200, CMN_TodoService.published.size());

    // 취소 200건도 SOQL 1회, 레코드 DML 1회 + 발행 1회
    Set<Id> ids = new Set<Id>();
    for (Integer i = 0; i < 200; i++) {
      ids.add(fakeId(i));
    }
    q0 = Limits.getQueries();
    d0 = Limits.getDmlStatements();
    CMN_TodoService.cancel(SOURCE, ids);
    Assert.isTrue(Limits.getQueries() - q0 <= 1);
    Assert.isTrue(Limits.getDmlStatements() - d0 <= 2);
    Assert.areEqual(
      200,
      [SELECT COUNT() FROM CMN_Todo__c WHERE Status__c = 'CANCELLED']
    );
  }

  @IsTest
  static void test_BR1_assigneeSeesOnlyOwnAndAdminSeesAll() {
    // Given: tdo1·tdo2 To-Do
    User a1 = user('tdo1');
    User a2 = user('tdo2');
    CMN_TodoService.open(
      new List<CMN_TodoSpec>{ spec(a1.Id, fakeId(1)), spec(a2.Id, fakeId(2)) }
    );

    // When / Then: 본인 것만 보이고 상태는 바꿀 수 없다. 관리자 PS는 전체
    System.runAs(a1) {
      List<CMN_Todo__c> mine = [SELECT Id, Assignee__c FROM CMN_Todo__c];
      Assert.areEqual(1, mine.size());
      Assert.areEqual(a1.Id, mine[0].Assignee__c);
      Assert.isFalse(
        Schema.SObjectType.CMN_Todo__c.fields.Status__c.isUpdateable()
      );
      Assert.isFalse(Schema.SObjectType.CMN_Todo__c.isCreateable());
    }
    System.runAs(user('tdoadm')) {
      Assert.areEqual(2, [SELECT COUNT() FROM CMN_Todo__c]);
    }
    // 처리자가 아닌 사용자가 닫아도(업무 담당자) 닫힌다
    System.runAs(a1) {
      CMN_TodoService.close(SOURCE, new Set<Id>{ fakeId(2) }, null);
    }
    Assert.areEqual(
      'DONE',
      [SELECT Status__c FROM CMN_Todo__c WHERE Assignee__c = :a2.Id].Status__c
    );
  }

  @IsTest
  static void test_negative_invalidSpecs() {
    // Given / When / Then: 처리자 없음, 비활성 처리자, 라벨 없음, 치환값 1000자 초과
    expectError(spec(null, fakeId(1)), Label.CMN_Todo_AssigneeRequired);
    User inactive = user('tdo3');
    System.runAs(new User(Id = UserInfo.getUserId())) {
      update new User(Id = inactive.Id, IsActive = false);
    }
    expectError(spec(inactive.Id, fakeId(1)), Label.CMN_Todo_AssigneeRequired);
    CMN_TodoSpec noLabel = spec(user('tdo1').Id, fakeId(1));
    noLabel.titleLabel = '';
    expectError(noLabel, Label.CMN_Common_InvalidInput);
    CMN_TodoSpec longParams = spec(user('tdo1').Id, fakeId(1));
    longParams.titleParams = 'x'.repeat(1000);
    expectError(longParams, Label.CMN_Common_InvalidInput);
    // 빈 목록·빈 원천은 아무것도 하지 않는다
    CMN_TodoService.open(new List<CMN_TodoSpec>());
    CMN_TodoService.close(SOURCE, new Set<Id>(), null);
    Assert.areEqual(0, [SELECT COUNT() FROM CMN_Todo__c]);
  }

  // ------------------------------------------------------------------ 도우미
  private static User user(String alias) {
    return [
      SELECT Id, LanguageLocaleKey
      FROM User
      WHERE Alias = :alias
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
  }

  private static CMN_TodoSpec spec(Id assigneeId, Id sourceId) {
    return new CMN_TodoSpec(
      assigneeId,
      SOURCE,
      sourceId,
      sourceId,
      TITLE_LABEL
    );
  }

  /** 원천 레코드 Id(SourceRecordId는 텍스트라 실제 레코드가 없어도 된다). */
  private static Id fakeId(Integer n) {
    String prefix = CMN_TestRecord__c.SObjectType.getDescribe(
        SObjectDescribeOptions.DEFERRED
      )
      .getKeyPrefix();
    return Id.valueOf(prefix + String.valueOf(n + 1).leftPad(12, '0'));
  }

  private static CMN_Todo__c todoOf(Id assigneeId) {
    List<CMN_Todo__c> rows = [
      SELECT
        Id,
        Status__c,
        Category__c,
        System__c,
        SourceType__c,
        SourceRecordId__c,
        SourceObject__c,
        TargetRecordId__c,
        TitleLabel__c,
        Plant__c,
        CompletedAt__c
      FROM CMN_Todo__c
      WHERE Assignee__c = :assigneeId
      ORDER BY CreatedDate DESC, Id DESC
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  private static List<CMN_ApprovalStepSpec> line(User a1, User a2, User a3) {
    return new List<CMN_ApprovalStepSpec>{
      new CMN_ApprovalStepSpec(1, 'AGREE', a1.Id, null),
      new CMN_ApprovalStepSpec(1, 'AGREE', a2.Id, null),
      new CMN_ApprovalStepSpec(2, 'APPROVE', a3.Id, null)
    };
  }

  private static void approve(User approver, String stepId) {
    System.runAs(approver) {
      CMN_ApprovalService.approve((Id) stepId, 'ok');
    }
  }

  private static void expectError(CMN_TodoSpec s, String expected) {
    try {
      CMN_TodoService.open(new List<CMN_TodoSpec>{ s });
      Assert.fail('예외가 나야 한다: ' + expected);
    } catch (CMN_ValidationException e) {
      Assert.areEqual(expected, e.getMessage());
    }
  }
}
