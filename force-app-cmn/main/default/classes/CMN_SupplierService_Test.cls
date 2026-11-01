/**
 * @description 협력사·협력사 품번 검증(CMN-00-MDM-005).
 * @group CMN-00-MDM-005
 */
@IsTest
private class CMN_SupplierService_Test {
  @TestSetup
  static void setup() {
    Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
    insert new List<Account>{
      new Account(
        Name = 'Alpha',
        SapVendorNo__c = 'V10001',
        RecordTypeId = rts.get('CMN_Supplier').getRecordTypeId()
      ),
      new Account(
        Name = 'Hyundai',
        OemCode__c = 'HMC',
        CustomerGroup__c = 'HKMC',
        RecordTypeId = rts.get('CMN_Customer').getRecordTypeId()
      )
    };
    CMN_ProductGroup__c g = new CMN_ProductGroup__c(
      Name = 'Lamp',
      GroupCode__c = 'LAMP'
    );
    insert g;
    insert new CMN_Item__c(
      ItemNo__c = 'P-LENS',
      Name = 'Lens',
      ItemType__c = 'PART',
      ProductGroup__c = g.Id
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
  }

  @IsTest
  static void test_AC01_sameSupplierItemPlantRejected() {
    // Given: 협력사 V10001 · P-LENS · KR01 조합이 있다
    insert link();

    // When: 같은 조합 한 번 더
    Database.SaveResult r = Database.insert(link(), false);

    // Then: 중복 오류(라벨 문구)
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      String.format(
        Label.CMN_Supplier_DuplicateSupplierItem,
        new List<Object>{ 'V10001-P-LENS-KR01' }
      ),
      r.getErrors()[0].getMessage()
    );
  }

  @IsTest
  static void test_defaultsAndKey() {
    // Given / When: 상태 없이 저장
    CMN_SupplierItem__c l = link();
    insert l;

    // Then: 키, PPAP 미제출, 검사 수준 정상
    CMN_SupplierItem__c saved = [
      SELECT ExternalKey__c, PpapStatus__c, InspectionLevel__c
      FROM CMN_SupplierItem__c
      WHERE Id = :l.Id
    ];
    Assert.areEqual('V10001-P-LENS-KR01', saved.ExternalKey__c);
    Assert.areEqual('NOT_SUBMITTED', saved.PpapStatus__c);
    Assert.areEqual('NORMAL', saved.InspectionLevel__c);
  }

  @IsTest
  static void test_BR1_statusFieldsServiceOnlyForUsers() {
    // Given / When: 협력사 관리 PS의 상태 필드 권한
    Map<String, FieldPermissions> perms = new Map<String, FieldPermissions>();
    for (FieldPermissions f : [
      SELECT Field, PermissionsRead, PermissionsEdit
      FROM FieldPermissions
      WHERE Parent.Name = 'CMN_PS_Supplier_Admin'
    ]) {
      perms.put(f.Field, f);
    }

    // Then: 읽기만(QMS-03 서비스가 시스템 모드로 바꾼다)
    for (
      String f : new List<String>{
        'CMN_SupplierItem__c.PpapStatus__c',
        'CMN_SupplierItem__c.InspectionLevel__c',
        'Account.SupplierGrade__c'
      }
    ) {
      Assert.isTrue(perms.get(f).PermissionsRead, f);
      Assert.isFalse(perms.get(f).PermissionsEdit, f);
    }
  }

  @IsTest
  static void test_negative_customerCannotBeSupplierAndKeyRequired() {
    // Given: 고객 계정, 번호 없는 협력사
    Id customer = [SELECT Id FROM Account WHERE OemCode__c = 'HMC'].Id;
    CMN_SupplierItem__c l = link();
    l.Supplier__c = customer;

    // When
    Database.SaveResult wrongParent = Database.insert(l, false);
    Database.SaveResult noVendor = Database.insert(
      new Account(
        Name = 'No vendor',
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
          .get('CMN_Supplier')
          .getRecordTypeId()
      ),
      false
    );

    // Then: 고객은 조회 필터로, 번호 없는 협력사는 검증 규칙으로 거부
    Assert.areEqual(
      StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION,
      wrongParent.getErrors()[0].getStatusCode()
    );
    Assert.isFalse(noVendor.isSuccess());
  }

  @IsTest
  static void test_updateAndDeleteRules() {
    // Given: 협력사 품번
    CMN_SupplierItem__c l = link();
    insert l;

    // When: 서비스처럼 시스템 문맥에서 검사 수준 변경, 삭제 시도
    update new CMN_SupplierItem__c(Id = l.Id, InspectionLevel__c = 'TIGHTENED');
    Database.DeleteResult d = Database.delete(l.Id, false);

    // Then: 키 유지, 협력사 품번·협력사 계정 삭제 거부
    Assert.isFalse(
      Database.delete(
          [SELECT Id FROM Account WHERE SapVendorNo__c = 'V10001'].Id,
          false
        )
        .isSuccess()
    );
    Assert.areEqual(
      'V10001-P-LENS-KR01',
      [SELECT ExternalKey__c FROM CMN_SupplierItem__c WHERE Id = :l.Id]
      .ExternalKey__c
    );
    Assert.isFalse(d.isSuccess());
  }

  @IsTest
  static void test_bulk200SupplierItems() {
    // Given: 품번 200개
    Id groupId = [SELECT Id FROM CMN_ProductGroup__c].Id;
    List<CMN_Item__c> items = new List<CMN_Item__c>();
    for (Integer i = 0; i < 200; i++) {
      items.add(
        new CMN_Item__c(
          ItemNo__c = 'B-' + i,
          Name = 'B' + i,
          ItemType__c = 'PART',
          ProductGroup__c = groupId
        )
      );
    }
    insert items;
    Id supplier = [SELECT Id FROM Account WHERE SapVendorNo__c = 'V10001'].Id;
    Id plant = [SELECT Id FROM CMN_Plant__c].Id;
    List<CMN_SupplierItem__c> links = new List<CMN_SupplierItem__c>();
    for (CMN_Item__c i : items) {
      links.add(
        new CMN_SupplierItem__c(
          Supplier__c = supplier,
          Item__c = i.Id,
          Plant__c = plant
        )
      );
    }

    // When
    Integer before = Limits.getQueries();
    insert links;
    Integer used = Limits.getQueries() - before;

    // Then: 트리거 SOQL 4회 이하(협력사·품번·공장·중복)
    // 협력사·품번·공장·중복 + 품번 협력사 공유의 포털 역할 조회(SEC-002)
    Assert.isTrue(used <= 6, 'SOQL ' + used);
    Assert.areEqual(200, [SELECT COUNT() FROM CMN_SupplierItem__c]);
  }

  @IsTest
  static void test_demoFixturesLoadSuppliers() {
    // Given / When: 데모 픽스처 협력사(협력사 필드 배포 후 적재)
    CMN_TestDataFactory.loadFixtures(new Set<String>{ 'Account' });

    // Then: 데모 협력사가 협력사 레코드타입으로 생긴다
    Id s = CMN_TestDataFactory.idOf('Account', 'V10003');
    Assert.isNotNull(s);
    Assert.areEqual(
      'CMN_Supplier',
      [SELECT RecordType.DeveloperName FROM Account WHERE Id = :s]
      .RecordType.DeveloperName
    );
  }

  private static CMN_SupplierItem__c link() {
    return new CMN_SupplierItem__c(
      Supplier__c = [SELECT Id FROM Account WHERE SapVendorNo__c = 'V10001']
      .Id,
      Item__c = [SELECT Id FROM CMN_Item__c WHERE ItemNo__c = 'P-LENS']
      .Id,
      Plant__c = [SELECT Id FROM CMN_Plant__c]
      .Id
    );
  }
}
