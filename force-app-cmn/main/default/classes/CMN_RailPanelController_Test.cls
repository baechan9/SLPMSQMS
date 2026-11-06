/**
 * @description 결정 지원 레일 검증(CMN-00-UX-004): 패널 병합·순서·기본 펼침(AC-2), 권한 패널 숨김(AC-3),
 * 문맥 분석 바인딩(AC-6), TODO 패널, 입력 검증, 배포된 패널 설정 무결성.
 * @group CMN-00-UX-004
 */
@IsTest
private class CMN_RailPanelController_Test {
  private static final String OBJ = 'CMN_TestRecord__c';

  @TestSetup
  static void setup() {
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    // 테스트 객체·To-Do를 읽을 수 있는 사용자와 아무 권한 없는 사용자
    User reader = CMN_TestDataFactory.newUser(
      'railrd',
      'Rail Reader',
      profileId
    );
    User bare = CMN_TestDataFactory.newUser('railbr', 'Rail Bare', profileId);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ reader, bare };
      List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
      for (PermissionSet ps : [
        SELECT Id
        FROM PermissionSet
        WHERE
          Name IN (
            'CMN_PS_DataMigration',
            'CMN_PS_Todo_User',
            'CMN_PS_UiFramework_User'
          )
      ]) {
        psas.add(
          new PermissionSetAssignment(
            AssigneeId = reader.Id,
            PermissionSetId = ps.Id
          )
        );
      }
      insert psas;
    }
  }

  @IsTest
  static void test_AC02_objectRowsOverrideDefaultsAndOrder() {
    // Given: 기본 AI(10, 펼침)·APPROVAL(20, 펼침)·COMMENT(40)와 객체 COMMENT(0, 설정 있음)
    CMN_RailPanelSelector.panelsOverride = new List<CMN_RailPanel__mdt>{
      row('D_AI', '*', 'AI', 'c/cmnAiRecommendationList', 10, true, true),
      row('D_APPROVAL', '*', 'APPROVAL', 'c/cmnApprovalLine', 20, true, true),
      row('D_COMMENT', '*', 'COMMENT', 'c/cmnCommentTimeline', 40, false, true),
      row(
        'O_COMMENT',
        OBJ,
        'COMMENT',
        'c/cmnCommentTimeline',
        0,
        false,
        true,
        new Map<String, Object>{ 'Config__c' => '{"limit":5}' }
      )
    };
    // When
    List<CMN_RailPanelController.PanelView> panels = CMN_RailPanelController.getPanels(
      OBJ
    );
    // Then: COMMENT(객체 행)가 맨 위, AI·APPROVAL은 기본 펼침
    Assert.areEqual(3, panels.size());
    Assert.areEqual('COMMENT', panels[0].key);
    Assert.areEqual('{"limit":5}', panels[0].config);
    Assert.areEqual('AI', panels[1].key);
    Assert.isTrue(panels[1].defaultOpen);
    Assert.areEqual('APPROVAL', panels[2].key);
    Assert.isTrue(panels[2].defaultOpen);
    Assert.isFalse(panels[0].defaultOpen);
  }

  @IsTest
  static void test_AC02_inactiveAndInvalidComponentsAreDropped() {
    // Given: 비활성 패널, 컴포넌트 이름 형식 오류(네임스페이스 밖), 다른 객체 패널
    CMN_RailPanelSelector.panelsOverride = new List<CMN_RailPanel__mdt>{
      row('D_AI', '*', 'AI', 'c/cmnAiRecommendationList', 10, true, false),
      row('D_BAD', '*', 'BAD', 'lightning/button', 20, false, true),
      row('D_TODO', '*', 'TODO', 'c/cmnRailTodoList', 30, false, true),
      row('X_OTHER', 'CMN_Plant__c', 'TODO', 'c/cmnOther', 1, false, true)
    };
    // When
    List<CMN_RailPanelController.PanelView> panels = CMN_RailPanelController.getPanels(
      OBJ
    );
    // Then: 활성·형식 맞는 기본 TODO만
    Assert.areEqual(1, panels.size());
    Assert.areEqual('c/cmnRailTodoList', panels[0].componentName);
    Assert.areEqual(30, panels[0].phoneOrder, '휴대폰 순서가 비면 Order');
  }

  @IsTest
  static void test_AC03_panelWithMissingPermissionIsHidden() {
    // Given: 배포되지 않은 Custom Permission이 필요한 패널
    CMN_RailPanel__mdt locked = row(
      'D_LOCKED',
      '*',
      'LOCKED',
      'c/cmnLocked',
      10,
      true,
      true,
      new Map<String, Object>{
        'RequiredPermission__c' => 'CMN_NotDeployedPermission'
      }
    );
    CMN_RailPanelSelector.panelsOverride = new List<CMN_RailPanel__mdt>{
      locked,
      row('D_TODO', '*', 'TODO', 'c/cmnRailTodoList', 30, false, true)
    };
    System.runAs(user('railrd')) {
      // When
      List<CMN_RailPanelController.PanelView> panels = CMN_RailPanelController.getPanels(
        OBJ
      );
      // Then: 응답에 권한 패널이 없다
      Assert.areEqual(1, panels.size());
      Assert.areEqual('TODO', panels[0].key);
    }
  }

  @IsTest
  static void test_AC06_bindingsReadOnlyAccessibleFields() {
    // Given: 공장이 있는 테스트 레코드(읽는 사용자 소유)
    Id plant = plantId();
    CMN_TestRecord__c rec = new CMN_TestRecord__c(
      Name = 'Bind',
      Plant__c = plant
    );
    System.runAs(user('railrd')) {
      insert rec;
      // When: 공장, 없는 필드, 빈 이름
      Map<String, Object> values = CMN_RailPanelController.resolveBindings(
        rec.Id,
        new List<String>{ 'Plant__c', 'NoSuch__c', '' }
      );
      // Then: 읽을 수 있는 공장 값만
      Assert.areEqual(1, values.size());
      Assert.areEqual(plant, values.get('Plant__c'));
    }
    System.runAs(user('railbr')) {
      // When / Then: 객체 권한이 없으면 빈 값(위젯은 값 없이 표시)
      Assert.isTrue(
        CMN_RailPanelController.resolveBindings(
            rec.Id,
            new List<String>{ 'Plant__c' }
          )
          .isEmpty()
      );
    }
  }

  @IsTest
  static void test_BR6_todoPanelListsOpenTodosOfRecord() {
    // Given: 레코드에 걸린 열린 To-Do 2건(1건 기한 경과)과 다른 레코드 To-Do 1건
    User reader = user('railrd');
    Id plant = plantId();
    CMN_TestRecord__c rec = new CMN_TestRecord__c(
      Name = 'Todo',
      Plant__c = plant
    );
    CMN_TestRecord__c other = new CMN_TestRecord__c(
      Name = 'Other',
      Plant__c = plant
    );
    System.runAs(reader) {
      insert new List<CMN_TestRecord__c>{ rec, other };
    }
    List<CMN_TodoSpec> specs = new List<CMN_TodoSpec>();
    for (Integer n = 0; n < 3; n++) {
      Id source = n < 2 ? rec.Id : other.Id;
      CMN_TodoSpec s = new CMN_TodoSpec(
        reader.Id,
        'CMN_TEST_' + n,
        source,
        source,
        'CMN_Widget_TodoSummary_Title'
      );
      s.category = 'TASK';
      s.systemCode = 'QMS';
      s.dueDate = n == 0 ? Date.today().addDays(-2) : Date.today().addDays(3);
      specs.add(s);
    }
    CMN_TodoService.open(specs);
    System.runAs(reader) {
      // When
      List<CMN_RailPanelController.TodoView> todos = CMN_RailPanelController.getOpenTodos(
        rec.Id
      );
      // Then: 이 레코드 것만, 기한 순, 제목·담당·기한 경과
      Assert.areEqual(2, todos.size());
      Assert.isTrue(todos[0].isOverdue);
      Assert.isFalse(todos[1].isOverdue);
      Assert.isNotNull(todos[0].title);
      Assert.areEqual('Rail Reader', todos[0].assigneeName);
    }
  }

  @IsTest
  static void test_negative_invalidInputsReturnEmpty() {
    // 형식이 틀린 객체 이름, 빈 Id, 바인딩 필드 수 초과
    Assert.isTrue(CMN_RailPanelController.getPanels('../x').isEmpty());
    Assert.isTrue(CMN_RailPanelController.getPanels(null).isEmpty());
    Assert.isTrue(CMN_RailPanelController.getOpenTodos(null).isEmpty());
    List<String> many = new List<String>();
    for (Integer i = 0; i <= CMN_RailPanelController.MAX_BINDINGS; i++) {
      many.add('Name');
    }
    Assert.isTrue(
      CMN_RailPanelController.resolveBindings(UserInfo.getUserId(), many)
        .isEmpty()
    );
    Assert.isTrue(
      CMN_RailPanelController.resolveBindings(null, new List<String>{ 'Name' })
        .isEmpty()
    );
  }

  @IsTest
  static void test_deployedPanelSettingsAreConsistent() {
    // 배포된 설정: 기본 패널(결재·할 일·코멘트·문서)이 있고, 모든 컴포넌트 이름이 형식에 맞는다
    Set<String> defaults = new Set<String>();
    for (CMN_RailPanel__mdt r : [
      SELECT ObjectApiName__c, PanelKey__c, ComponentName__c, TitleLabel__c
      FROM CMN_RailPanel__mdt
    ]) {
      Assert.isTrue(
        Pattern.matches('^c/[a-z][A-Za-z0-9]{1,79}$', r.ComponentName__c),
        r.ComponentName__c
      );
      Assert.isTrue(String.isNotBlank(r.TitleLabel__c), r.PanelKey__c);
      if (r.ObjectApiName__c == CMN_RailPanelController.ALL_OBJECTS) {
        defaults.add(r.PanelKey__c);
      }
    }
    Assert.isTrue(
      defaults.containsAll(
        new Set<String>{ 'AI', 'APPROVAL', 'TODO', 'COMMENT', 'DOCUMENT' }
      ),
      String.valueOf(defaults)
    );
    // 샘플 객체(테스트 레코드)는 기본 패널 + 결재 유형 + 문맥 분석
    List<CMN_RailPanelController.PanelView> panels = CMN_RailPanelController.getPanels(
      OBJ
    );
    Set<String> keys = new Set<String>();
    for (CMN_RailPanelController.PanelView p : panels) {
      keys.add(p.key);
    }
    Assert.isTrue(keys.contains('CONTEXT_TODO'), String.valueOf(keys));
    // AI-004 배포로 AI 패널이 켜졌다(Vol.0 UX-004 "AI-004 배포 전 비활성"). 순서 10 = 첫 패널
    Assert.isTrue(keys.contains('AI'), String.valueOf(keys));
    Assert.areEqual('AI', panels[0].key);
  }

  @IsTest
  static void test_BR5_panelOrderTiesTitlesAndPermissions() {
    // Given: 같은 순서 두 패널(키 순), 제목 라벨 없음·없는 라벨, 배포됐지만 사용자가 안 가진 Custom Permission
    CMN_RailPanelSelector.panelsOverride = new List<CMN_RailPanel__mdt>{
      row(
        'D_B',
        '*',
        'B_KEY',
        'c/cmnB',
        10,
        false,
        true,
        new Map<String, Object>{ 'TitleLabel__c' => null }
      ),
      row(
        'D_A',
        '*',
        'A_KEY',
        'c/cmnA',
        10,
        false,
        true,
        new Map<String, Object>{ 'TitleLabel__c' => 'CMN_NoSuchLabel_X' }
      ),
      row(
        'D_PERM',
        '*',
        'PERM',
        'c/cmnP',
        5,
        false,
        true,
        new Map<String, Object>{ 'RequiredPermission__c' => 'QMS_ViewCost' }
      ),
      row('D_NULL', '*', 'Z_LAST', 'c/cmnZ', null, false, true)
    };
    System.runAs(user('railrd')) {
      // When
      List<CMN_RailPanelController.PanelView> panels = CMN_RailPanelController.getPanels(
        OBJ
      );
      // Then: 권한 패널 숨김, 같은 순서는 키 순, 순서 없는 패널은 맨 뒤, 제목이 없으면 키
      Assert.areEqual(3, panels.size());
      Assert.areEqual('A_KEY', panels[0].key);
      Assert.areEqual('A_KEY', panels[0].title);
      Assert.areEqual('B_KEY', panels[1].key);
      Assert.areEqual('B_KEY', panels[1].title);
      Assert.areEqual('Z_LAST', panels[2].key);
    }
  }

  @IsTest
  static void test_BR7_bindingsAndTodosWithoutAccess() {
    // Given: 관리자가 만든(읽는 사용자에게 공유되지 않은) 테스트 레코드
    CMN_TestRecord__c rec = new CMN_TestRecord__c(
      Name = 'Private',
      Plant__c = plantId()
    );
    insert rec;
    System.runAs(user('railrd')) {
      // When / Then: 없는 필드만 → 빈 값, 공유 밖 레코드 → 빈 값
      Assert.isTrue(
        CMN_RailPanelController.resolveBindings(
            rec.Id,
            new List<String>{ 'NoSuch__c' }
          )
          .isEmpty()
      );
      Assert.isTrue(
        CMN_RailPanelController.resolveBindings(
            rec.Id,
            new List<String>{ 'Plant__c' }
          )
          .isEmpty()
      );
    }
    System.runAs(user('railbr')) {
      // When / Then: To-Do 읽기 권한이 없으면 빈 목록(오류 아님)
      Assert.isTrue(CMN_RailPanelController.getOpenTodos(rec.Id).isEmpty());
    }
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_RailPanel__mdt row(
    String name,
    String objectApiName,
    String key,
    String component,
    Integer order,
    Boolean defaultOpen,
    Boolean active
  ) {
    return row(
      name,
      objectApiName,
      key,
      component,
      order,
      defaultOpen,
      active,
      new Map<String, Object>()
    );
  }

  /** 메타데이터 레코드는 필드를 대입할 수 없어 JSON으로 만든다. */
  private static CMN_RailPanel__mdt row(
    String name,
    String objectApiName,
    String key,
    String component,
    Integer order,
    Boolean defaultOpen,
    Boolean active,
    Map<String, Object> extra
  ) {
    Map<String, Object> values = new Map<String, Object>{
      'DeveloperName' => name,
      'ObjectApiName__c' => objectApiName,
      'PanelKey__c' => key,
      'ComponentName__c' => component,
      'TitleLabel__c' => 'CMN_DecisionRail_Todo',
      'Order__c' => order,
      'DefaultOpen__c' => defaultOpen,
      'IsActive__c' => active
    };
    values.putAll(extra);
    return (CMN_RailPanel__mdt) JSON.deserialize(
      JSON.serialize(values),
      CMN_RailPanel__mdt.class
    );
  }

  /** 채번 규칙이 공장 범위라 테스트 레코드를 만들려면 공장이 필요하다. */
  private static Id plantId() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    CMN_Plant__c p = new CMN_Plant__c(
      Name = 'KR01',
      PlantCode__c = 'KR01',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
    insert p;
    return p.Id;
  }

  private static User user(String alias) {
    return [
      SELECT Id
      FROM User
      WHERE Alias = :alias AND Username LIKE '%@test.slqms.example.com'
      LIMIT 1
    ];
  }
}
