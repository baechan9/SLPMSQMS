/**
 * @description 제품군·품번·연결 검증(CMN-00-MDM-004).
 * @group CMN-00-MDM-004
 */
@IsTest
private class CMN_ItemService_Test {
  @TestSetup
  static void setup() {
    CMN_ProductGroup__c lamp = new CMN_ProductGroup__c(
      Name = 'Lamp',
      GroupCode__c = 'LAMP'
    );
    insert lamp;
    insert new CMN_ProductGroup__c(
      Name = 'Headlamp',
      GroupCode__c = 'LAMP_HL',
      Parent__c = lamp.Id
    );
    Account hmc = new Account(
      Name = 'Hyundai',
      OemCode__c = 'HMC',
      CustomerGroup__c = 'HKMC',
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('CMN_Customer')
        .getRecordTypeId()
    );
    insert hmc;
    insert new CMN_Vehicle__c(
      Name = 'SUV',
      VehicleCode__c = 'HE1',
      Customer__c = hmc.Id
    );
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
    insert item('92101-HE1L', 'FG', hmc.Id);
  }

  @IsTest
  static void test_AC01_resyncSameItemNoKeepsOneRecord() {
    // Given: 품번 92101-HE1L이 있다
    CMN_Item__c resent = new CMN_Item__c(
      ItemNo__c = '92101-HE1L',
      Name = 'HE1 HL LH',
      ItemType__c = 'FG',
      ProductGroup__c = groupId('LAMP_HL'),
      Customer__c = [SELECT Id FROM Account WHERE OemCode__c = 'HMC']
      .Id,
      DrawingRev__c = 'D'
    );

    // When: SAP 동기화로 같은 품번을 upsert
    Database.UpsertResult r = Database.upsert(resent, CMN_Item__c.ItemNo__c);

    // Then: 1건 유지, 바뀐 필드만 갱신(고객 품번은 그대로)
    Assert.isFalse(r.isCreated());
    List<CMN_Item__c> items = [
      SELECT Name, DrawingRev__c, CustomerPartNo__c
      FROM CMN_Item__c
      WHERE ItemNo__c = '92101-HE1L'
    ];
    Assert.areEqual(1, items.size());
    Assert.areEqual('D', items[0].DrawingRev__c);
    Assert.areEqual('HE1 HL LH', items[0].Name);
    Assert.areEqual('CP-1', items[0].CustomerPartNo__c);
  }

  @IsTest
  static void test_BR1_finishedGoodNeedsCustomer() {
    // Given / When: 고객 없는 FG, 고객 없는 PART
    List<Database.SaveResult> rs = Database.insert(
      new List<CMN_Item__c>{
        item('FG-NOCUST', 'FG', null),
        item('PART-1', 'PART', null)
      },
      false
    );

    // Then: FG만 거부
    Assert.isFalse(rs[0].isSuccess());
    Assert.isTrue(rs[1].isSuccess());
  }

  @IsTest
  static void test_itemPlantAndVehicleKeys() {
    // Given: 품번·공장·차종
    Id itemId = itemId('92101-HE1L');
    Id plantId = [SELECT Id FROM CMN_Plant__c].Id;
    Id vehicleId = [SELECT Id FROM CMN_Vehicle__c].Id;

    // When: 연결 저장, 같은 공장 연결 한 번 더
    insert new CMN_ItemPlant__c(Item__c = itemId, Plant__c = plantId);
    CMN_ItemVehicle__c iv = new CMN_ItemVehicle__c(
      Item__c = itemId,
      Vehicle__c = vehicleId
    );
    insert iv;
    Database.SaveResult dup = Database.insert(
      new CMN_ItemPlant__c(Item__c = itemId, Plant__c = plantId),
      false
    );

    // Then: 키 {ItemNo}-{PlantCode}, {ItemNo}-{차종 키}, 사용 수량 기본 1, 상태 기본 ACTIVE, 중복 거부
    CMN_ItemPlant__c ip = [
      SELECT ExternalKey__c, Status__c
      FROM CMN_ItemPlant__c
    ];
    Assert.areEqual('92101-HE1L-KR01', ip.ExternalKey__c);
    Assert.areEqual('ACTIVE', ip.Status__c);
    CMN_ItemVehicle__c saved = [
      SELECT ExternalKey__c, UsagePerVehicle__c
      FROM CMN_ItemVehicle__c
      WHERE Id = :iv.Id
    ];
    Assert.areEqual('92101-HE1L-HMC-HE1', saved.ExternalKey__c);
    Assert.areEqual(1, saved.UsagePerVehicle__c);
    Assert.isFalse(dup.isSuccess());
    Assert.areEqual(
      String.format(
        Label.CMN_Item_DuplicateItemPlant,
        new List<Object>{ '92101-HE1L-KR01' }
      ),
      dup.getErrors()[0].getMessage()
    );
  }

  @IsTest
  static void test_productGroupTwoLevels() {
    // Given: LAMP > LAMP_HL, 별도 EV
    CMN_ProductGroup__c ev = new CMN_ProductGroup__c(
      Name = 'EV',
      GroupCode__c = 'EV'
    );
    insert ev;

    // When: LAMP_HL 아래에 새 제품군(3단계), 하위가 있는 LAMP를 EV 아래로
    Database.SaveResult third = Database.insert(
      new CMN_ProductGroup__c(
        Name = 'Deep',
        GroupCode__c = 'DEEP',
        Parent__c = groupId('LAMP_HL')
      ),
      false
    );
    Database.SaveResult moveParent = Database.update(
      new CMN_ProductGroup__c(Id = groupId('LAMP'), Parent__c = ev.Id),
      false
    );

    // Then: 둘 다 거부
    Assert.isFalse(third.isSuccess());
    Assert.isFalse(moveParent.isSuccess());
    Assert.areEqual(
      Label.CMN_Item_GroupHasChildren,
      moveParent.getErrors()[0].getMessage()
    );
  }

  @IsTest
  static void test_negative_deleteBlockedExceptItemVehicle() {
    // Given: 품번·공장별 품번·적용 차종
    Id itemId = itemId('92101-HE1L');
    CMN_ItemPlant__c ip = new CMN_ItemPlant__c(
      Item__c = itemId,
      Plant__c = [SELECT Id FROM CMN_Plant__c]
      .Id
    );
    insert ip;
    CMN_ItemVehicle__c iv = new CMN_ItemVehicle__c(
      Item__c = itemId,
      Vehicle__c = [SELECT Id FROM CMN_Vehicle__c]
      .Id
    );
    insert iv;

    // When / Then: 품번·공장별 품번·제품군 삭제는 거부, 적용 차종은 삭제된다
    Assert.isFalse(Database.delete(itemId, false).isSuccess());
    Assert.isFalse(Database.delete(ip.Id, false).isSuccess());
    Assert.isFalse(Database.delete(groupId('LAMP_HL'), false).isSuccess());
    Assert.isTrue(Database.delete(iv.Id, false).isSuccess());
  }

  @IsTest
  static void test_bulk200ItemsAndPlantLinks() {
    // Given: PART 200개
    List<CMN_Item__c> items = new List<CMN_Item__c>();
    for (Integer i = 0; i < 200; i++) {
      items.add(item('P-' + i, 'PART', null));
    }
    insert items;
    Id plantId = [SELECT Id FROM CMN_Plant__c].Id;
    List<CMN_ItemPlant__c> links = new List<CMN_ItemPlant__c>();
    for (CMN_Item__c i : items) {
      links.add(new CMN_ItemPlant__c(Item__c = i.Id, Plant__c = plantId));
    }

    // When
    Integer before = Limits.getQueries();
    insert links;
    Integer used = Limits.getQueries() - before;

    // Then: 트리거 SOQL 3회 이하(품번·공장·중복)
    Assert.isTrue(used <= 3, 'SOQL ' + used);
    Assert.areEqual(
      200,
      [
        SELECT COUNT()
        FROM CMN_ItemPlant__c
        WHERE ExternalKey__c LIKE 'P-%-KR01'
      ]
    );
  }

  @IsTest
  static void test_demoFixturesLoadItems() {
    // Given / When: 데모 픽스처(기준정보 계층 → 품번·연결)
    CMN_TestDataFactory.loadFixtures(
      new Set<String>{
        'CMN_Company__c',
        'CMN_Plant__c',
        'Account',
        'CMN_Vehicle__c',
        'CMN_ProductGroup__c',
        'CMN_Item__c',
        'CMN_ItemPlant__c',
        'CMN_ItemVehicle__c'
      }
    );

    // Then: 데모 품번이 데모 고객(BMW)·제품군에 연결된다(픽스처에는 공장·차종 연결 단계가 없다)
    Id itemId = CMN_TestDataFactory.idOf('CMN_Item__c', '63117-BE1L');
    Assert.isNotNull(itemId);
    CMN_Item__c saved = [
      SELECT Customer__r.OemCode__c, ProductGroup__r.GroupCode__c
      FROM CMN_Item__c
      WHERE Id = :itemId
    ];
    Assert.areEqual('BMW', saved.Customer__r.OemCode__c);
    Assert.areEqual('LAMP_HL', saved.ProductGroup__r.GroupCode__c);
  }

  @IsTest
  static void test_linkUpdatesKeepKeys() {
    // Given: 공장별 품번·적용 차종
    Id itemId = itemId('92101-HE1L');
    CMN_ItemPlant__c ip = new CMN_ItemPlant__c(
      Item__c = itemId,
      Plant__c = [SELECT Id FROM CMN_Plant__c]
      .Id
    );
    CMN_ItemVehicle__c iv = new CMN_ItemVehicle__c(
      Item__c = itemId,
      Vehicle__c = [SELECT Id FROM CMN_Vehicle__c]
      .Id
    );
    insert ip;
    insert iv;

    // When: 단종 처리, 사용 수량 변경
    update new CMN_ItemPlant__c(Id = ip.Id, Status__c = 'PHASE_OUT');
    update new CMN_ItemVehicle__c(Id = iv.Id, UsagePerVehicle__c = 2);

    // Then: 키는 그대로
    Assert.areEqual(
      '92101-HE1L-KR01',
      [SELECT ExternalKey__c FROM CMN_ItemPlant__c WHERE Id = :ip.Id]
      .ExternalKey__c
    );
    Assert.areEqual(
      2,
      [SELECT UsagePerVehicle__c FROM CMN_ItemVehicle__c WHERE Id = :iv.Id]
      .UsagePerVehicle__c
    );
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_Item__c item(String no, String type, Id customerId) {
    return new CMN_Item__c(
      ItemNo__c = no,
      Name = no,
      ItemType__c = type,
      ProductGroup__c = groupId('LAMP_HL'),
      Customer__c = customerId,
      CustomerPartNo__c = 'CP-1'
    );
  }

  private static final Map<String, Id> GROUP_IDS = new Map<String, Id>();

  private static Id groupId(String code) {
    if (!GROUP_IDS.containsKey(code)) {
      GROUP_IDS.put(
        code,
        [SELECT Id FROM CMN_ProductGroup__c WHERE GroupCode__c = :code].Id
      );
    }
    return GROUP_IDS.get(code);
  }

  private static Id itemId(String no) {
    return [SELECT Id FROM CMN_Item__c WHERE ItemNo__c = :no].Id;
  }
}
