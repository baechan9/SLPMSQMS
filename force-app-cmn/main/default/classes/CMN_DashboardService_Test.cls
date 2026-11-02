/**
 * @description 위젯 대시보드 엔진 검증(CMN-00-DSH-001). 위젯·템플릿 메타데이터는 테스트 값으로 바꿔(override) 콘텐츠 WI가
 * 레코드를 더해도 결과가 흔들리지 않게 한다. 페르소나는 실제 PSG(QMS_PSG_QualityManager)로 확인한다.
 * @group CMN-00-DSH-001
 */
@IsTest
private class CMN_DashboardService_Test {
  /** 템플릿 해석기·설정 검증기(확장 등록 대체). */
  private class Extension implements CMN_DashboardTemplateResolver, CMN_WidgetConfigValidator {
    public String templateFor(
      String systemCode,
      Id userId,
      Set<String> permissionSetGroups
    ) {
      return 'T_DEF';
    }
    public String resolveConfig(String configJson, Id userId) {
      return configJson?.replace('{me}', userId);
    }
    public String validate(String widgetKey, Map<String, Object> config) {
      return config.get('bad') == true ? 'bad config' : null;
    }
  }

  @TestSetup
  static void setup() {
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    List<User> users = new List<User>{
      CMN_TestDataFactory.newUser('dshqm', 'Board QM', profileId),
      CMN_TestDataFactory.newUser('dshvw', 'Board Viewer', profileId)
    };
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert users;
      Id dashPs = [
        SELECT Id
        FROM PermissionSet
        WHERE Name = 'CMN_PS_Dashboard_User'
      ]
      .Id;
      PermissionSetGroup qm = [
        SELECT Id
        FROM PermissionSetGroup
        WHERE DeveloperName = 'QMS_PSG_QualityManager'
      ];
      Test.calculatePermissionSetGroup(qm.Id);
      insert new List<PermissionSetAssignment>{
        new PermissionSetAssignment(
          AssigneeId = users[0].Id,
          PermissionSetGroupId = qm.Id
        ),
        new PermissionSetAssignment(
          AssigneeId = users[1].Id,
          PermissionSetId = dashPs
        )
      };
    }
  }

  @IsTest
  static void test_AC01_qualityManagerGetsTemplateOnFirstOpen() {
    // Given: 품질팀장 PSG 사용자, 템플릿 T_QM(QualityManager)·T_DEF(기본)
    useTestMetadata();
    // When: QMS 보드 첫 진입
    System.runAs(user('dshqm')) {
      CMN_DashboardController.BoardView v = CMN_DashboardController.getBoard(
        'QMS'
      );
      // Then: T_QM 구성(비활성·PMS 전용·권한 없는 위젯은 건너뜀), 저장됨, 다시 열어도 1건
      Assert.areEqual('T_QM', v.sourceTemplate);
      Assert.areEqual(1, v.items.size());
      Assert.areEqual('T_W_A', v.items[0].widgetKey);
      Assert.areEqual('L', v.items[0].size);
      Assert.areEqual('{"rows":3}', v.items[0].configJson);
      Assert.areEqual('cmnWidgetTodoSummary', v.items[0].componentName);
      Assert.areEqual('OK', v.items[0].state);
      CMN_DashboardController.getBoard('QMS');
      Assert.areEqual(
        1,
        [
          SELECT COUNT()
          FROM CMN_UserDashboard__c
          WHERE User__c = :UserInfo.getUserId()
        ]
      );
    }
    // 맞는 PSG가 없으면 시스템 기본
    System.runAs(user('dshvw')) {
      Assert.areEqual(
        'T_DEF',
        CMN_DashboardController.getBoard('QMS').sourceTemplate
      );
    }
  }

  @IsTest
  static void test_AC02_savedLayoutReloadsSame() {
    // Given: 기본 보드
    useTestMetadata();
    System.runAs(user('dshvw')) {
      CMN_DashboardController.getBoard('QMS');
      // When: 위젯 추가·순서·크기·설정 변경 후 저장
      String layout = JSON.serialize(
        new List<Object>{
          new Map<String, Object>{
            'widgetKey' => 'T_W_B',
            'size' => 'M',
            'order' => 9,
            'config' => new Map<String, Object>{ 'k' => 2 }
          },
          new Map<String, Object>{
            'widgetKey' => 'T_W_A',
            'size' => 'S',
            'order' => 1
          }
        }
      );
      CMN_DashboardController.saveBoard('QMS', layout);
      // Then: 다시 열면 같은 배치(순서는 목록 순서로 다시 매김)
      CMN_DashboardController.BoardView v = CMN_DashboardController.getBoard(
        'QMS'
      );
      Assert.areEqual(2, v.items.size());
      Assert.areEqual('T_W_B', v.items[0].widgetKey);
      Assert.areEqual('M', v.items[0].size);
      Assert.areEqual(1, v.items[0].position);
      Assert.areEqual('{"k":2}', v.items[0].configJson);
      Assert.areEqual('T_W_A', v.items[1].widgetKey);
      Assert.areEqual('T_DEF', v.sourceTemplate);
    }
  }

  @IsTest
  static void test_BR2_lostAccessStaysAsPlaceholderButCannotBeAdded() {
    // Given: 이전에 저장된 배치에 지금은 권한 없는 위젯(T_W_PS)이 있다
    useTestMetadata();
    User viewer = user('dshvw');
    System.runAs(viewer) {
      CMN_DashboardController.getBoard('QMS');
    }
    update new CMN_UserDashboard__c(
      Id = [SELECT Id FROM CMN_UserDashboard__c WHERE User__c = :viewer.Id]
      .Id,
      LayoutJson__c = '[{"widgetKey":"T_W_PS","size":"S","order":1,"config":{}},{"widgetKey":"T_W_GONE","size":"S","order":2,"config":{}}]'
    );
    System.runAs(viewer) {
      // When / Then: 보드는 권한 없음·사용 불가 자리표시로 남는다(컴포넌트 이름은 내려가지 않음)
      CMN_DashboardController.BoardView v = CMN_DashboardController.getBoard(
        'QMS'
      );
      Assert.areEqual('NO_ACCESS', v.items[0].state);
      Assert.isNull(v.items[0].componentName);
      Assert.areEqual('UNAVAILABLE', v.items[1].state);
      // 이미 있던 권한 없는 위젯은 유지 저장 가능
      CMN_DashboardController.saveBoard(
        'QMS',
        '[{"widgetKey":"T_W_PS","size":"S","order":1}]'
      );
      // 새로 넣는 권한 없음·비활성·없는 위젯, 잘못된 크기·형식은 거부
      for (
        String bad : new List<String>{
          '[{"widgetKey":"T_W_PS2","size":"S"}]',
          '[{"widgetKey":"T_W_OFF","size":"S"}]',
          '[{"widgetKey":"NOPE","size":"S"}]',
          '[{"widgetKey":"T_W_A","size":"XL"}]',
          '{"widgetKey":"T_W_A"}',
          '[{"widgetKey":"T_W_A","size":"S","config":[1]}]'
        }
      ) {
        expectError(bad, Label.CMN_WidgetBoard_InvalidLayout);
      }
      List<Object> many = new List<Object>();
      for (Integer i = 0; i <= CMN_DashboardService.MAX_WIDGETS; i++) {
        many.add(
          new Map<String, Object>{ 'widgetKey' => 'T_W_A', 'size' => 'S' }
        );
      }
      expectError(
        JSON.serialize(many),
        String.format(
          Label.CMN_WidgetBoard_TooManyWidgets,
          new List<Object>{ CMN_DashboardService.MAX_WIDGETS }
        )
      );
    }
  }

  @IsTest
  static void test_BR3_resetAndGallery() {
    // Given: 품질팀장이 배치를 바꿔 저장
    useTestMetadata();
    System.runAs(user('dshqm')) {
      CMN_DashboardController.getBoard('QMS');
      CMN_DashboardController.saveBoard(
        'QMS',
        '[{"widgetKey":"T_W_B","size":"S"}]'
      );
      // When: 템플릿으로 초기화
      CMN_DashboardController.BoardView v = CMN_DashboardController.resetBoard(
        'QMS'
      );
      // Then: 템플릿 구성으로 돌아감
      Assert.areEqual('T_QM', v.sourceTemplate);
      Assert.areEqual('T_W_A', v.items[0].widgetKey);
      // 갤러리: 이 시스템에서 쓸 수 있고 권한 있는 활성 위젯만(BR-2)
      Set<String> keys = new Set<String>();
      for (
        CMN_DashboardController.GalleryItem g : CMN_DashboardController.getGallery(
          'QMS'
        )
      ) {
        keys.add(g.widgetKey);
        if (g.widgetKey == 'T_W_A') {
          Assert.isTrue(g.hasSchema);
          Assert.areEqual('{"x":1}', g.defaultConfigJson);
          Assert.areEqual('Widget A', g.title, '라벨이 없으면 메타데이터 라벨');
        }
      }
      Assert.areEqual(new Set<String>{ 'T_W_A', 'T_W_B', 'T_W_QMS' }, keys);
      Assert.areEqual(
        new Set<String>{ 'T_W_A', 'T_W_B', 'T_W_PMS' },
        galleryKeys('PMS')
      );
    }
  }

  @IsTest
  static void test_extensionsResolverAndValidator() {
    // Given: 등록된 해석기(T_DEF 선택, {me} 치환)와 검증기(bad 거부)
    useTestMetadata();
    CMN_DashboardService.templateItemsOverride.get('T_DEF')[0]
      .Config__c = '{"owner":"{me}"}';
    CMN_DashboardService.extensionsOverride = new List<Object>{
      new Extension()
    };
    System.runAs(user('dshqm')) {
      // When / Then: 품질팀장이어도 해석기가 고른 템플릿, 토큰 치환
      CMN_DashboardController.BoardView v = CMN_DashboardController.getBoard(
        'QMS'
      );
      Assert.areEqual('T_DEF', v.sourceTemplate);
      Assert.areEqual(
        '{"owner":"' + UserInfo.getUserId() + '"}',
        v.items[0].configJson
      );
      // 검증기가 거부하면 위젯 제목과 사유
      try {
        CMN_DashboardController.saveBoard(
          'QMS',
          '[{"widgetKey":"T_W_A","size":"S","config":{"bad":true}}]'
        );
        Assert.fail('검증기가 막아야 한다');
      } catch (AuraHandledException e) {
        Assert.isTrue(e.getMessage().contains('bad config'), e.getMessage());
        Assert.isTrue(e.getMessage().contains('Widget A'), e.getMessage());
      }
    }
  }

  @IsTest
  static void test_negative_invalidSystemAndRealMetadata() {
    // 잘못된 시스템 코드
    for (String sys : new List<String>{ null, 'CMN', 'qms' }) {
      try {
        CMN_DashboardController.getBoard(sys);
        Assert.fail('시스템 코드 검증');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
      }
    }
    // 배포된 메타데이터(기본 위젯 2종·기본 템플릿)로도 보드가 열린다
    System.runAs(user('dshvw')) {
      Assert.isNotNull(CMN_DashboardController.getBoard('PMS').sourceTemplate);
      Assert.isNotNull(CMN_DashboardController.getGallery('QMS'));
    }
    Assert.isTrue(
      CMN_DashboardService.widgets().containsKey('CMN_W_TODO_SUMMARY')
    );
  }

  // ------------------------------------------------------------------ 도우미
  private static void useTestMetadata() {
    Map<String, CMN_Widget__mdt> widgets = new Map<String, CMN_Widget__mdt>();
    for (
      CMN_Widget__mdt w : new List<CMN_Widget__mdt>{
        widget(
          'T_W_A',
          'Widget A',
          'CMN',
          null,
          null,
          true,
          '{"x":1}',
          '{"fields":[]}'
        ),
        widget('T_W_B', 'Widget B', 'CMN', null, null, true, null, null),
        widget('T_W_QMS', 'QMS only', 'CMN', 'QMS', null, true, null, null),
        widget('T_W_PMS', 'PMS only', 'PMS', null, null, true, null, null),
        widget('T_W_OFF', 'Off', 'CMN', null, null, false, null, null),
        widget(
          'T_W_PS',
          'Needs PS',
          'CMN',
          null,
          'CMN_PS_Delegation_Admin',
          true,
          null,
          null
        ),
        widget(
          'T_W_PS2',
          'Needs PS 2',
          'CMN',
          null,
          'CMN_PS_Delegation_Admin',
          true,
          null,
          null
        )
      }
    ) {
      widgets.put(w.DeveloperName, w);
    }
    CMN_DashboardService.widgetsOverride = widgets;
    CMN_DashboardService.templatesOverride = new List<CMN_DashboardTemplate__mdt>{
      (CMN_DashboardTemplate__mdt) JSON.deserialize(
        '{"DeveloperName":"T_QM","PermissionSetGroups__c":"QMS_PSG_Inspector, QMS_PSG_QualityManager","Priority__c":10,"IsDefault__c":false}',
        CMN_DashboardTemplate__mdt.class
      ),
      (CMN_DashboardTemplate__mdt) JSON.deserialize(
        '{"DeveloperName":"T_DEF","Priority__c":999,"IsDefault__c":true}',
        CMN_DashboardTemplate__mdt.class
      )
    };
    CMN_DashboardService.templateItemsOverride = new Map<String, List<CMN_DashboardTemplateItem__mdt>>{
      'T_QM' => new List<CMN_DashboardTemplateItem__mdt>{
        item('T_W_A', 'L', '{"rows":3}'),
        item('T_W_OFF', 'S', null),
        item('T_W_PMS', 'S', null),
        item('T_W_PS', 'S', null),
        item('T_W_MISSING', 'S', null)
      },
      'T_DEF' => new List<CMN_DashboardTemplateItem__mdt>{
        item('T_W_A', null, null)
      }
    };
  }

  private static CMN_Widget__mdt widget(
    String key,
    String masterLabel,
    String sys,
    String available,
    String requiredPs,
    Boolean active,
    String config,
    String configSchema
  ) {
    return (CMN_Widget__mdt) JSON.deserialize(
      JSON.serialize(
        new Map<String, Object>{
          'DeveloperName' => key,
          'MasterLabel' => masterLabel,
          'ComponentName__c' => 'cmnWidgetTodoSummary',
          'System__c' => sys,
          'AvailableSystems__c' => available,
          'TitleLabel__c' => 'CMN_Widget_NoSuchLabel',
          'DefaultSize__c' => 'M',
          'RequiredPermissionSet__c' => requiredPs,
          'DefaultConfig__c' => config,
          'ConfigSchema__c' => configSchema,
          'MobileSupported__c' => true,
          'IsActive__c' => active
        }
      ),
      CMN_Widget__mdt.class
    );
  }

  private static CMN_DashboardTemplateItem__mdt item(
    String widgetKey,
    String size,
    String config
  ) {
    return (CMN_DashboardTemplateItem__mdt) JSON.deserialize(
      JSON.serialize(
        new Map<String, Object>{
          'Widget__r' => new Map<String, Object>{
            'DeveloperName' => widgetKey
          },
          'Size__c' => size,
          'Config__c' => config
        }
      ),
      CMN_DashboardTemplateItem__mdt.class
    );
  }

  private static Set<String> galleryKeys(String sys) {
    Set<String> keys = new Set<String>();
    for (
      CMN_DashboardController.GalleryItem g : CMN_DashboardController.getGallery(
        sys
      )
    ) {
      keys.add(g.widgetKey);
    }
    return keys;
  }

  private static void expectError(String layoutJson, String expected) {
    try {
      CMN_DashboardController.saveBoard('QMS', layoutJson);
      Assert.fail('거부해야 한다: ' + layoutJson);
    } catch (AuraHandledException e) {
      Assert.areEqual(expected, e.getMessage(), layoutJson);
    }
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
