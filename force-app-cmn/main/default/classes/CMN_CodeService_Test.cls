/**
 * @description 계층형 공통 코드·코드 피커 검증(CMN-00-MDM-007).
 * @group CMN-00-MDM-007
 */
@IsTest
private class CMN_CodeService_Test {
  @TestSetup
  static void setup() {
    CMN_CodeGroup__c g = new CMN_CodeGroup__c(
      Name = 'Defect type',
      GroupCode__c = 'DEFECT_TYPE',
      MaxLevel__c = 3
    );
    insert g;
    CMN_Code__c appearance = code(
      g.Id,
      'APPEARANCE',
      '외관',
      'Appearance',
      null
    );
    insert appearance;
    CMN_Code__c foreign = code(
      g.Id,
      'FOREIGN',
      '이물',
      'Foreign',
      appearance.Id
    );
    CMN_Code__c haze = code(g.Id, 'HAZE', '흐림', 'Haze', appearance.Id);
    haze.IsActive__c = false;
    insert new List<CMN_Code__c>{ foreign, haze };
    insert new List<CMN_Code__c>{
      code(g.Id, 'INNER', '렌즈 내부', null, foreign.Id),
      code(g.Id, 'LENS_HAZE', '렌즈 흐림', 'Lens haze', haze.Id)
    };
  }

  @IsTest
  static void test_levelKeyAndPathCalculated() {
    // Given / When: 외관 > 이물 > 렌즈 내부
    CMN_Code__c leaf = byKey('DEFECT_TYPE/APPEARANCE/FOREIGN/INNER');

    // Then: 3단계, 경로 전체 키, 이름 경로
    Assert.areEqual(3, leaf.Level__c);
    Assert.areEqual('외관 > 이물 > 렌즈 내부', leaf.Path__c);
  }

  @IsTest
  static void test_AC01_englishUserSeesNameEnWithFallback() {
    // Given: 영어 사용자(코드 조회 PS)
    User en = pickerUser('en_US');

    // When
    CMN_CodePickerController.PickerData data;
    System.runAs(en) {
      data = CMN_CodePickerController.getCodes('DEFECT_TYPE');
    }

    // Then: NameEn으로 표시, NameEn이 빈 코드는 Name
    Map<String, CMN_CodePickerController.CodeOption> byKey = options(data);
    Assert.areEqual('Appearance', byKey.get('DEFECT_TYPE/APPEARANCE').label);
    Assert.areEqual(
      '렌즈 내부',
      byKey.get('DEFECT_TYPE/APPEARANCE/FOREIGN/INNER').label
    );
    Assert.areEqual(
      'Appearance > Foreign > 렌즈 내부',
      byKey.get('DEFECT_TYPE/APPEARANCE/FOREIGN/INNER').path
    );
    Assert.areEqual(3, data.maxLevel);
  }

  @IsTest
  static void test_AC02_referencedCodeCannotBeDeleted() {
    // Given: 업무 레코드(테스트 대상 객체)가 리프 코드를 참조, 참조 없는 리프, 하위가 있는 코드
    CMN_Code__c referenced = byKey('DEFECT_TYPE/APPEARANCE/FOREIGN/INNER');
    insert new CMN_TestRecord__c(
      Name = 'NCR stand-in',
      Code__c = referenced.Id
    );
    CMN_Code__c free = byKey('DEFECT_TYPE/APPEARANCE/HAZE/LENS_HAZE');
    CMN_Code__c parent = byKey('DEFECT_TYPE/APPEARANCE');

    // When
    Database.DeleteResult r1 = Database.delete(referenced.Id, false);
    Database.DeleteResult r2 = Database.delete(parent.Id, false);
    Database.DeleteResult r3 = Database.delete(free.Id, false);

    // Then: 참조 중·하위 있는 코드는 차단(라벨 문구), 참조 없는 리프는 삭제
    Assert.isFalse(r1.isSuccess());
    Assert.areEqual(Label.CMN_Code_InUse, r1.getErrors()[0].getMessage());
    Assert.isFalse(r2.isSuccess());
    Assert.isTrue(r3.isSuccess());
  }

  @IsTest
  static void test_AC03_inactiveMiddleHidesItsChildren() {
    // Given: 비활성 중분류 흐림과 그 하위 렌즈 흐림, 코드 조회 권한 사용자
    User ko = pickerUser('ko');

    // When
    Map<String, CMN_CodePickerController.CodeOption> byKey;
    System.runAs(ko) {
      byKey = options(CMN_CodePickerController.getCodes('DEFECT_TYPE'));
    }

    // Then: 둘 다 없음, 활성 경로는 있음
    Assert.isFalse(byKey.containsKey('DEFECT_TYPE/APPEARANCE/HAZE'));
    Assert.isFalse(byKey.containsKey('DEFECT_TYPE/APPEARANCE/HAZE/LENS_HAZE'));
    Assert.isTrue(byKey.containsKey('DEFECT_TYPE/APPEARANCE/FOREIGN/INNER'));
  }

  @IsTest
  static void test_BR2_levelCannotExceedMax() {
    // Given: 3단계 리프
    CMN_Code__c leaf = byKey('DEFECT_TYPE/APPEARANCE/FOREIGN/INNER');

    // When: 4단계
    Database.SaveResult r = Database.insert(
      code(leaf.CodeGroup__c, 'DEEP', '깊음', null, leaf.Id),
      false
    );

    // Then
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      String.format(Label.CMN_Code_LevelExceeded, new List<Object>{ 3 }),
      r.getErrors()[0].getMessage()
    );
  }

  @IsTest
  static void test_negative_parentFromOtherGroupAndDuplicate() {
    // Given: 다른 그룹
    CMN_CodeGroup__c other = new CMN_CodeGroup__c(
      Name = 'Cause',
      GroupCode__c = 'CAUSE',
      MaxLevel__c = 2
    );
    insert other;
    Id appearance = byKey('DEFECT_TYPE/APPEARANCE').Id;
    Id groupId = byKey('DEFECT_TYPE/APPEARANCE').CodeGroup__c;

    // When: 다른 그룹 코드를 상위로, 같은 상위 아래 같은 코드
    Database.SaveResult wrongGroup = Database.insert(
      code(other.Id, 'MAN', '사람', 'Man', appearance),
      false
    );
    Database.SaveResult dup = Database.insert(
      code(groupId, 'FOREIGN', '이물2', null, appearance),
      false
    );

    // Then
    Assert.areEqual(
      Label.CMN_Code_ParentOtherGroup,
      wrongGroup.getErrors()[0].getMessage()
    );
    Assert.isFalse(dup.isSuccess());
  }

  @IsTest
  static void test_negative_codeGroupDeleteBlocked() {
    // Given / When: 코드 그룹 삭제(주종 하위 코드가 연쇄 삭제되므로 막는다)
    Database.DeleteResult r = Database.delete(
      [SELECT Id FROM CMN_CodeGroup__c WHERE GroupCode__c = 'DEFECT_TYPE'].Id,
      false
    );

    // Then
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      Label.CMN_Master_DeleteNotAllowed,
      r.getErrors()[0].getMessage()
    );
  }

  @IsTest
  static void test_renameRefreshesDescendantPaths() {
    // Given / When: 대분류 이름 변경
    update new CMN_Code__c(
      Id = byKey('DEFECT_TYPE/APPEARANCE').Id,
      Name = '외관 불량'
    );

    // Then: 손자 경로까지 바뀐다
    Assert.areEqual(
      '외관 불량 > 이물 > 렌즈 내부',
      byKey('DEFECT_TYPE/APPEARANCE/FOREIGN/INNER').Path__c
    );
  }

  @IsTest
  static void test_negative_pickerInputValidation() {
    // Given / When / Then: 잘못된 그룹 코드는 거부, 없는 그룹은 빈 응답
    System.runAs(pickerUser('ko')) {
      try {
        CMN_CodePickerController.getCodes('DROP TABLE;');
        Assert.fail('거부돼야 한다');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
      }
      Assert.areEqual(
        0,
        CMN_CodePickerController.getCodes('NO_SUCH_GROUP').codes.size()
      );
    }
    Assert.areEqual(
      '이물',
      CMN_CodePickerController.localized(
        new CMN_Code__c(Name = '이물'),
        'zh_CN'
      )
    );
  }

  @IsTest
  static void test_bulk200Codes() {
    // Given: 대분류 200개
    Id groupId = byKey('DEFECT_TYPE/APPEARANCE').CodeGroup__c;
    List<CMN_Code__c> codes = new List<CMN_Code__c>();
    for (Integer i = 0; i < 200; i++) {
      codes.add(code(groupId, 'B' + i, 'B' + i, null, null));
    }

    // When
    Integer before = Limits.getQueries();
    insert codes;
    Integer used = Limits.getQueries() - before;

    // Then: 트리거 SOQL 3회 이하(그룹·상위·중복)
    Assert.isTrue(used <= 3, 'SOQL ' + used);
  }

  @IsTest
  static void test_demoFixturesLoadCodeTree() {
    // Given / When: 데모 픽스처 코드(그룹 → 1·2·3단계)
    CMN_TestDataFactory.loadFixtures(
      new Set<String>{ 'CMN_CodeGroup__c', 'CMN_Code__c' }
    );

    // Then: 경로 전체 키가 데모와 같다
    Id leaf = CMN_TestDataFactory.idOf(
      'CMN_Code__c',
      'DEFECT_TYPE/APPEARANCE/SCRATCH/LENS_SCRATCH'
    );
    Assert.isNotNull(leaf);
    Assert.areEqual(
      3,
      [SELECT Level__c FROM CMN_Code__c WHERE Id = :leaf].Level__c
    );
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_Code__c code(
    Id groupId,
    String code,
    String name,
    String nameEn,
    Id parent
  ) {
    return new CMN_Code__c(
      CodeGroup__c = groupId,
      Code__c = code,
      Name = name,
      NameEn__c = nameEn,
      Parent__c = parent
    );
  }

  private static CMN_Code__c byKey(String key) {
    return [
      SELECT Id, CodeGroup__c, Level__c, Path__c
      FROM CMN_Code__c
      WHERE ExternalKey__c = :key
    ];
  }

  private static Map<String, CMN_CodePickerController.CodeOption> options(
    CMN_CodePickerController.PickerData data
  ) {
    Map<String, CMN_CodePickerController.CodeOption> out = new Map<String, CMN_CodePickerController.CodeOption>();
    for (CMN_CodePickerController.CodeOption o : data.codes) {
      out.put(o.externalKey, o);
    }
    return out;
  }

  private static User pickerUser(String language) {
    User u = CMN_TestDataFactory.newUser(
      'code1',
      'Picker',
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    u.LanguageLocaleKey = language;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert u;
      insert new PermissionSetAssignment(
        AssigneeId = u.Id,
        PermissionSetId = [
          SELECT Id
          FROM PermissionSet
          WHERE Name = 'CMN_PS_Code_Read'
        ]
        .Id
      );
    }
    return u;
  }
}
