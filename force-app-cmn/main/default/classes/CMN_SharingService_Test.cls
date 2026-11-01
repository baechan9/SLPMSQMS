/**
 * @description 공장·협력사 데이터 격리 검증(CMN-00-SEC-002). NCR 대신 테스트 대상 객체(공유 설정: Plant__c, Supplier__c)로 검증한다(CR-11·DEV-3).
 * 협력사 포털 격리(AC-3)는 포털 사용자가 생기는 P4(QMS-03-SPP)에서 확인한다.
 * @group CMN-00-SEC-002
 */
@IsTest
private class CMN_SharingService_Test {
  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    List<CMN_Plant__c> plants = new List<CMN_Plant__c>{
      plant(c.Id, 'KR01', 'Asia/Seoul'),
      plant(c.Id, 'CN01', 'Asia/Shanghai')
    };
    insert plants;
    // 공장 그룹은 설정 객체라 runAs로 업무 DML과 분리해 만든다(운영에서는 CMN_PlantGroupJob)
    System.runAs(new User(Id = UserInfo.getUserId())) {
      CMN_PlantGroupService.ensureGroups(
        new Map<Id, CMN_Plant__c>(plants).keySet()
      );
    }
  }

  @IsTest
  static void test_AC01_kr01ReaderCannotSeeCn01Records() {
    // Given: KR01 읽기만 가진 사용자, KR01·CN01 레코드(관리자 소유)
    User reader = userWithAccess('sh1', 'KR01', 'Read');
    CMN_TestRecord__c kr = record('KR01');
    CMN_TestRecord__c cn = record('CN01');
    insert new List<CMN_TestRecord__c>{ kr, cn };

    // When: 그 사용자로 조회(목록·검색 모두 같은 공유가 적용된다)
    List<CMN_TestRecord__c> visible;
    System.runAs(reader) {
      visible = [SELECT Id FROM CMN_TestRecord__c];
    }

    // Then: KR01만 보인다
    Assert.areEqual(1, visible.size());
    Assert.areEqual(kr.Id, visible[0].Id);
  }

  @IsTest
  static void test_AC02_plantChangeMovesShares() {
    // Given: KR01 레코드
    CMN_TestRecord__c r = record('KR01');
    insert r;
    Map<String, Id> groups = groupIdsByName();

    // When: 공장을 CN01로
    r.Plant__c = plantId('CN01');
    update r;

    // Then: KR01 그룹 공유는 지워지고 CN01 읽기·편집 공유가 생긴다
    Map<Id, String> shares = sharesOf(r.Id);
    Assert.isFalse(shares.containsKey(groups.get('CMN_GRP_PLANT_KR01_R')));
    Assert.isFalse(shares.containsKey(groups.get('CMN_GRP_PLANT_KR01_E')));
    Assert.areEqual('Read', shares.get(groups.get('CMN_GRP_PLANT_CN01_R')));
    Assert.areEqual('Edit', shares.get(groups.get('CMN_GRP_PLANT_CN01_E')));
  }

  @IsTest
  static void test_BR2_accessChangesUpdateGroupMembership() {
    // Given: 사용자와 KR01 읽기 접근
    User u = plainUser('sh2');
    CMN_UserPlantAccess__c a = new CMN_UserPlantAccess__c(
      User__c = u.Id,
      Plant__c = plantId('KR01'),
      AccessLevel__c = 'Read'
    );

    // When: 생성 → 편집으로 변경 → 삭제(각각 비동기 구성원 맞춤)
    Test.startTest();
    insert a;
    Test.stopTest();
    Set<String> afterInsert = groupsOf(u.Id);
    a.AccessLevel__c = 'Edit';
    update a;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      CMN_PlantGroupService.syncMembers(new Set<Id>{ u.Id });
    }
    Set<String> afterEdit = groupsOf(u.Id);
    delete a;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      CMN_PlantGroupService.syncMembers(new Set<Id>{ u.Id });
    }

    // Then: 읽기 그룹 → 편집 그룹만 → 없음. 외부 키는 {사번 또는 Id}-{공장}
    Assert.areEqual(new Set<String>{ 'CMN_GRP_PLANT_KR01_R' }, afterInsert);
    Assert.areEqual(new Set<String>{ 'CMN_GRP_PLANT_KR01_E' }, afterEdit);
    Assert.areEqual(new Set<String>(), groupsOf(u.Id));
  }

  @IsTest
  static void test_BR6_recalcBatchRestoresShares() {
    // Given: 200건의 공유를 지워 둔다
    List<CMN_TestRecord__c> recs = new List<CMN_TestRecord__c>();
    for (Integer i = 0; i < 200; i++) {
      recs.add(record(Math.mod(i, 2) == 0 ? 'KR01' : 'CN01'));
    }
    insert recs;
    delete [
      SELECT Id
      FROM CMN_TestRecord__Share
      WHERE RowCause = :CMN_SharingService.CAUSE_PLANT
    ];

    // When: 재계산 배치(배치 크기 200)
    Test.startTest();
    CMN_SharingRecalcBatch.run('CMN_TestRecord__c');
    Test.stopTest();

    // Then: 레코드마다 읽기·편집 공유 2건
    Assert.areEqual(
      400,
      [
        SELECT COUNT()
        FROM CMN_TestRecord__Share
        WHERE RowCause = :CMN_SharingService.CAUSE_PLANT
      ]
    );
  }

  @IsTest
  static void test_newPlantGetsGroupsAsync() {
    // Given / When: 새 공장(트리거가 그룹 생성 작업을 넣는다)
    Test.startTest();
    insert plant([SELECT Id FROM CMN_Company__c].Id, 'US01', 'America/Chicago');
    Test.stopTest();

    // Then
    Assert.isTrue(groupIdsByName().containsKey('CMN_GRP_PLANT_US01_R'));
    Assert.isTrue(groupIdsByName().containsKey('CMN_GRP_PLANT_US01_E'));
  }

  @IsTest
  static void test_bulk200AndInactiveConfig() {
    // Given: 200건
    List<CMN_TestRecord__c> recs = new List<CMN_TestRecord__c>();
    for (Integer i = 0; i < 200; i++) {
      recs.add(record('KR01'));
    }

    // When: 한 번에 저장
    Integer before = Limits.getQueries();
    insert recs;
    Integer used = Limits.getQueries() - before;

    // Then: 공유 400건, 트리거 SOQL 상한(채번 4 + 공유 4)
    Assert.areEqual(
      400,
      [
        SELECT COUNT()
        FROM CMN_TestRecord__Share
        WHERE RowCause = :CMN_SharingService.CAUSE_PLANT
      ]
    );
    Assert.isTrue(used <= 10, 'SOQL ' + used);

    // 설정을 끄면 공유하지 않는다
    CMN_SharingService.configsOverride = new Map<String, CMN_SharingConfig__mdt>();
    CMN_TestRecord__c off = record('KR01');
    insert off;
    Assert.areEqual(0, sharesOf(off.Id).size());
  }

  @IsTest
  static void test_negative_accessNeedsUserAndNoDuplicates() {
    // Given: 사용자와 KR01 접근
    User u = plainUser('sh3');
    insert new CMN_UserPlantAccess__c(
      User__c = u.Id,
      Plant__c = plantId('KR01')
    );

    // When: 같은 사용자·공장, 사용자 없는 접근
    List<Database.SaveResult> rs = Database.insert(
      new List<CMN_UserPlantAccess__c>{
        new CMN_UserPlantAccess__c(User__c = u.Id, Plant__c = plantId('KR01')),
        new CMN_UserPlantAccess__c(Plant__c = plantId('CN01'))
      },
      false
    );

    // Then
    Assert.isFalse(rs[0].isSuccess());
    Assert.areEqual(
      Label.CMN_Sharing_UserRequired,
      rs[1].getErrors()[0].getMessage()
    );
    Assert.isTrue(
      [SELECT ExternalKey__c FROM CMN_UserPlantAccess__c LIMIT 1]
        .ExternalKey__c.endsWith('-KR01')
    );
    try {
      new CMN_SharingRecalcBatch('Account');
      Assert.fail('등록되지 않은 객체');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
    }
  }

  @IsTest
  static void test_BR4_supplierWithoutPortalRoleGetsNoShare() {
    // Given: 포털 사용자가 아직 없는 협력사(포털 역할 없음)
    Account supplier = new Account(
      Name = 'Alpha',
      SapVendorNo__c = 'V1',
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('CMN_Supplier')
        .getRecordTypeId()
    );
    insert supplier;
    CMN_TestRecord__c r = record('KR01');
    r.Supplier__c = supplier.Id;

    // When
    insert r;

    // Then: 공장 공유만(협력사 공유 대상 그룹 없음 — 포털이 생기는 P4에서 AC-3 확인)
    Assert.areEqual(
      0,
      [
        SELECT COUNT()
        FROM CMN_TestRecord__Share
        WHERE ParentId = :r.Id AND RowCause = :CMN_SharingService.CAUSE_SUPPLIER
      ]
    );
    Assert.areEqual(2, sharesOf(r.Id).size());
  }

  // ------------------------------------------------------------------ 도우미
  private static final Map<String, Id> PLANT_IDS = new Map<String, Id>();
  private static final String GROUP_PATTERN = 'CMN_GRP_PLANT_%';

  private static CMN_Plant__c plant(Id companyId, String code, String tz) {
    return new CMN_Plant__c(
      Name = code,
      PlantCode__c = code,
      Company__c = companyId,
      Region__c = 'KR',
      TimeZone__c = tz,
      DefaultLanguage__c = 'ko'
    );
  }

  private static Id plantId(String code) {
    if (!PLANT_IDS.containsKey(code)) {
      PLANT_IDS.put(
        code,
        [SELECT Id FROM CMN_Plant__c WHERE PlantCode__c = :code].Id
      );
    }
    return PLANT_IDS.get(code);
  }

  private static CMN_TestRecord__c record(String plantCode) {
    return new CMN_TestRecord__c(
      Name = plantCode,
      Plant__c = plantId(plantCode),
      Status__c = 'DRAFT'
    );
  }

  private static User plainUser(String alias) {
    User u = CMN_TestDataFactory.newUser(
      alias,
      alias,
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert u;
    }
    return u;
  }

  private static User userWithAccess(
    String alias,
    String plantCode,
    String level
  ) {
    User u = plainUser(alias);
    insert new CMN_UserPlantAccess__c(
      User__c = u.Id,
      Plant__c = plantId(plantCode),
      AccessLevel__c = level
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      CMN_PlantGroupService.syncMembers(new Set<Id>{ u.Id });
    }
    return u;
  }

  private static Map<String, Id> groupIdsByName() {
    Map<String, Id> out = new Map<String, Id>();
    for (Group g : [
      SELECT Id, DeveloperName
      FROM Group
      WHERE DeveloperName LIKE :GROUP_PATTERN
    ]) {
      out.put(g.DeveloperName, g.Id);
    }
    return out;
  }

  private static Map<Id, String> sharesOf(Id recordId) {
    Map<Id, String> out = new Map<Id, String>();
    for (CMN_TestRecord__Share s : [
      SELECT UserOrGroupId, AccessLevel
      FROM CMN_TestRecord__Share
      WHERE ParentId = :recordId AND RowCause = :CMN_SharingService.CAUSE_PLANT
    ]) {
      out.put(s.UserOrGroupId, s.AccessLevel);
    }
    return out;
  }

  private static Set<String> groupsOf(Id userId) {
    Set<String> out = new Set<String>();
    for (GroupMember m : [
      SELECT Group.DeveloperName
      FROM GroupMember
      WHERE UserOrGroupId = :userId AND Group.DeveloperName LIKE :GROUP_PATTERN
    ]) {
      out.add(m.Group.DeveloperName);
    }
    return out;
  }
}
