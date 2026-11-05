/**
 * @description 상태·권한 화면 제어 서버 검증(CMN-00-UX-005): 상태별 버튼·컴포넌트 허용(AC-1), 액션 거부(AC-2),
 * 필드 잠금과 서비스 우회(AC-3), 권한·레코드 타입·추가 조건(AC-5), 200건 일괄 추가 SOQL 0회(AC-6), 기본 거부.
 * 배포된 테스트 객체 규칙(meta-src/cmn/ui-rules/CMN_TestRecord__c.json)과 대체 규칙을 함께 쓴다.
 * @group CMN-00-UX-005
 */
@IsTest
private class CMN_UiRuleService_Test {
  private static final String OBJ = 'CMN_TestRecord__c';

  @TestSetup
  static void setup() {
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User owner = CMN_TestDataFactory.newUser('uirown', 'Ui Owner', profileId);
    User bare = CMN_TestDataFactory.newUser('uirbar', 'Ui Bare', profileId);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ owner, bare };
      insert new PermissionSetAssignment(
        AssigneeId = owner.Id,
        PermissionSetId = [
          SELECT Id
          FROM PermissionSet
          WHERE Name = 'CMN_PS_DataMigration'
        ]
        .Id
      );
    }
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
  }

  @IsTest
  static void test_AC01_actionsAndComponentsFollowStatus() {
    System.runAs(user('uirown')) {
      // Given: 배포된 규칙 — 수정 DRAFT·IN_PROGRESS, 삭제 DRAFT, 기한 표시 DRAFT·IN_PROGRESS
      Map<String, CMN_TestRecord__c> recs = records(
        new List<String>{ 'DRAFT', 'IN_PROGRESS', 'DONE' }
      );
      // When / Then
      Assert.isTrue(CMN_UiRuleService.canExecute(recs.get('DRAFT').Id, 'Edit'));
      Assert.isTrue(
        CMN_UiRuleService.canExecute(recs.get('DRAFT').Id, 'Delete')
      );
      Assert.isTrue(
        CMN_UiRuleService.canExecute(recs.get('IN_PROGRESS').Id, 'Edit')
      );
      Assert.isFalse(
        CMN_UiRuleService.canExecute(recs.get('IN_PROGRESS').Id, 'Delete')
      );
      Assert.isFalse(CMN_UiRuleService.canExecute(recs.get('DONE').Id, 'Edit'));
      Assert.isTrue(
        CMN_UiRuleService.canExecute(
          recs.get('IN_PROGRESS').Id,
          'cmnDueIndicator'
        )
      );
      Assert.isFalse(
        CMN_UiRuleService.canExecute(recs.get('DONE').Id, 'cmnDueIndicator')
      );
    }
  }

  @IsTest
  static void test_AC02_assertStopsDisallowedAction() {
    System.runAs(user('uirown')) {
      // Given: 완료(DONE) 레코드
      Id doneId = records(new List<String>{ 'DONE' }).get('DONE').Id;
      // When / Then: 업무 액션 첫 줄의 검증이 막는다
      try {
        CMN_UiRuleService.assertCanExecute(doneId, 'Edit');
        Assert.fail('완료 레코드 수정은 거부');
      } catch (CMN_ValidationException e) {
        Assert.areEqual(Label.CMN_UiRule_ActionNotAllowed, e.getMessage());
      }
    }
  }

  @IsTest
  static void test_AC03_lockedFieldsAndServiceBypass() {
    System.runAs(user('uirown')) {
      // Given: 진행 중 레코드(기본 정보는 DRAFT에서만, 일정은 DRAFT·IN_PROGRESS에서 편집)
      CMN_TestRecord__c rec = records(new List<String>{ 'IN_PROGRESS' })
        .get('IN_PROGRESS');
      CMN_TestRecordTriggerHandler.enforceUiRules = true;

      // When: 기본 정보(제목) 수정
      rec.Name = 'Changed';
      Database.SaveResult locked = Database.update(rec, false);
      // Then: 행 오류(잠긴 필드 라벨 포함)
      Assert.isFalse(locked.isSuccess());
      String nameLabel = CMN_TestRecord__c.Name.getDescribe().getLabel();
      Assert.isTrue(
        locked.getErrors()[0].getMessage().contains(nameLabel),
        locked.getErrors()[0].getMessage()
      );

      // When: 일정(기한) 수정 → 허용
      CMN_TestRecord__c fresh = new CMN_TestRecord__c(
        Id = rec.Id,
        DueDate__c = Date.today().addDays(10)
      );
      Assert.isTrue(Database.update(fresh, false).isSuccess());

      // When: 서비스 우회 안에서 기본 정보 수정 → 허용
      CMN_UiRuleService.runAsService(
        new RenameAction(new CMN_TestRecord__c(Id = rec.Id, Name = 'ByService'))
      );
      Assert.areEqual(
        'ByService',
        [SELECT Name FROM CMN_TestRecord__c WHERE Id = :rec.Id].Name
      );
    }
  }

  @IsTest
  static void test_AC05_permissionRecordTypeAndExtraCondition() {
    // Given: 대체 규칙 — 권한 필요 액션, 추가 조건(= / !=) 액션, 레코드 타입 액션
    CMN_UiRuleSelector.rulesOverride = new List<CMN_UiRule__mdt>{
      rule('ACTION', 'Approve', '*', 'QMS_ViewCost', null, null),
      rule('ACTION', 'NamedOnly', '*', null, null, 'Name=Allowed'),
      rule('ACTION', 'NotNamed', '*', null, null, 'Name!=Allowed'),
      rule('ACTION', 'TypedOnly', '*', null, 'NO_SUCH_TYPE', null)
    };
    System.runAs(user('uirown')) {
      Id allowed = insertNamed('Allowed');
      Id other = insertNamed('Other');
      // When / Then
      Assert.isFalse(
        CMN_UiRuleService.canExecute(allowed, 'Approve'),
        '권한 없는 사용자'
      );
      Assert.isTrue(CMN_UiRuleService.canExecute(allowed, 'NamedOnly'));
      Assert.isFalse(CMN_UiRuleService.canExecute(other, 'NamedOnly'));
      Assert.isFalse(CMN_UiRuleService.canExecute(allowed, 'NotNamed'));
      Assert.isTrue(CMN_UiRuleService.canExecute(other, 'NotNamed'));
      Assert.isFalse(
        CMN_UiRuleService.canExecute(allowed, 'TypedOnly'),
        '레코드 타입이 맞지 않음'
      );
    }
  }

  @IsTest
  static void test_AC06_bulk200NoExtraQueries() {
    System.runAs(user('uirown')) {
      // Given: 진행 중 레코드 200건과 제목을 바꾼 새 값
      Id plant = [SELECT Id FROM CMN_Plant__c LIMIT 1].Id;
      List<CMN_TestRecord__c> olds = new List<CMN_TestRecord__c>();
      for (Integer i = 0; i < 200; i++) {
        olds.add(
          new CMN_TestRecord__c(
            Name = 'Bulk ' + i,
            Plant__c = plant,
            Status__c = 'IN_PROGRESS'
          )
        );
      }
      insert olds;
      Map<Id, SObject> oldMap = new Map<Id, SObject>();
      List<SObject> news = new List<SObject>();
      for (CMN_TestRecord__c o : olds) {
        oldMap.put(o.Id, o);
        CMN_TestRecord__c n = o.clone(true, true, true, true);
        n.Name = o.Name + ' x';
        news.add(n);
      }
      // When
      Integer before = Limits.getQueries();
      Map<Id, Set<String>> violations = CMN_UiRuleService.lockedFieldViolations(
        news,
        oldMap
      );
      // Then: 200건 모두 잠김, 추가 SOQL 0회(규칙·섹션 메타데이터는 한도에 세지 않음)
      Assert.areEqual(0, Limits.getQueries() - before);
      Assert.areEqual(200, violations.size());
      Assert.isTrue(violations.values()[0].contains('Name'));
    }
  }

  @IsTest
  static void test_BR1_noRuleDeniesAndStarAllows() {
    // Given: 규칙 없는 섹션 S0(잠김), 모든 상태(*) 섹션 S1(편집)
    CMN_UiRuleSelector.sectionsOverride = new List<CMN_UiSection__mdt>{
      section('S0', 'Name'),
      section('S1', 'DueDate__c')
    };
    CMN_UiRuleSelector.rulesOverride = new List<CMN_UiRule__mdt>{
      rule('SECTION', 'S1', '*', null, null, null)
    };
    CMN_TestRecord__c o = new CMN_TestRecord__c(
      Id = fakeId(),
      Name = 'A',
      Status__c = 'DONE'
    );
    CMN_TestRecord__c n = new CMN_TestRecord__c(
      Id = o.Id,
      Name = 'B',
      Status__c = 'DONE',
      DueDate__c = Date.today()
    );
    // When
    Map<Id, Set<String>> v = CMN_UiRuleService.lockedFieldViolations(
      new List<SObject>{ n },
      new Map<Id, SObject>{ o.Id => o }
    );
    // Then: 규칙 없는 섹션의 제목만 잠김
    Assert.areEqual(new Set<String>{ 'Name' }, v.get(o.Id));
    // 규칙 없는 액션은 거부
    Assert.isFalse(CMN_UiRuleService.canExecute(o.Id, 'NoRuleAction'));
  }

  @IsTest
  static void test_negative_invalidInputsAndNoAccess() {
    // 빈 입력, 섹션 없는 객체, 읽을 수 없는 레코드
    Assert.isFalse(CMN_UiRuleService.canExecute(null, 'Edit'));
    Assert.isFalse(CMN_UiRuleService.canExecute(fakeId(), ''));
    Assert.isTrue(
      CMN_UiRuleService.lockedFieldViolations(
          new List<SObject>{ new CMN_Plant__c() },
          new Map<Id, SObject>()
        )
        .isEmpty()
    );
    Assert.isTrue(
      CMN_UiRuleService.lockedFieldViolations(null, null).isEmpty()
    );
    Id draftId;
    System.runAs(user('uirown')) {
      draftId = records(new List<String>{ 'DRAFT' }).get('DRAFT').Id;
    }
    System.runAs(user('uirbar')) {
      Assert.isFalse(CMN_UiRuleService.canExecute(draftId, 'Edit'));
    }
  }

  // ------------------------------------------------------------------ 도우미
  /** 서비스 우회 안에서 실행할 작업. */
  private class RenameAction implements Callable {
    private final CMN_TestRecord__c rec;
    RenameAction(CMN_TestRecord__c rec) {
      this.rec = rec;
    }
    public Object call(String action, Map<String, Object> args) {
      update rec;
      return null;
    }
  }

  private static Map<String, CMN_TestRecord__c> records(List<String> statuses) {
    Id plant = [SELECT Id FROM CMN_Plant__c LIMIT 1].Id;
    Map<String, CMN_TestRecord__c> out = new Map<String, CMN_TestRecord__c>();
    for (String s : statuses) {
      out.put(
        s,
        new CMN_TestRecord__c(Name = 'R ' + s, Plant__c = plant, Status__c = s)
      );
    }
    insert out.values();
    return out;
  }

  private static Id insertNamed(String name) {
    CMN_TestRecord__c r = new CMN_TestRecord__c(
      Name = name,
      Plant__c = [SELECT Id FROM CMN_Plant__c LIMIT 1]
      .Id,
      Status__c = 'DRAFT'
    );
    insert r;
    return r.Id;
  }

  private static CMN_UiRule__mdt rule(
    String target,
    String key,
    String statuses,
    String permission,
    String recordTypes,
    String extra
  ) {
    return (CMN_UiRule__mdt) JSON.deserialize(
      JSON.serialize(
        new Map<String, Object>{
          'DeveloperName' => key,
          'ObjectApiName__c' => OBJ,
          'TargetType__c' => target,
          'TargetKey__c' => key,
          'Mode__c' => target == 'SECTION' ? 'EDIT' : 'SHOW',
          'StatusField__c' => 'Status__c',
          'StatusValues__c' => statuses,
          'CustomPermission__c' => permission,
          'RecordTypes__c' => recordTypes,
          'ExtraCondition__c' => extra,
          'IsActive__c' => true
        }
      ),
      CMN_UiRule__mdt.class
    );
  }

  private static CMN_UiSection__mdt section(String key, String fields) {
    return (CMN_UiSection__mdt) JSON.deserialize(
      JSON.serialize(
        new Map<String, Object>{
          'DeveloperName' => key,
          'ObjectApiName__c' => OBJ,
          'SectionKey__c' => key,
          'Fields__c' => fields
        }
      ),
      CMN_UiSection__mdt.class
    );
  }

  private static Id fakeId() {
    return Id.valueOf(
      CMN_TestRecord__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED)
        .getKeyPrefix() + '000000000001'
    );
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
