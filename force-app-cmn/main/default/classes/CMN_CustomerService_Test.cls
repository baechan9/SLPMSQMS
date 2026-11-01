/**
 * @description 고객·차종 검증(CMN-00-MDM-003).
 * @group CMN-00-MDM-003
 */
@IsTest
private class CMN_CustomerService_Test {
  // 레코드타입이 있는 Account는 마스터 레코드타입으로 만들 수 없어, 고객 아닌 계정은 협력사 레코드타입으로 만든다
  private static final Id SUPPLIER_RT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('CMN_Supplier')
    .getRecordTypeId();

  @TestSetup
  static void setup() {
    insert new List<Account>{
      customer('HMC', 'Hyundai', 'HKMC'),
      new Account(Name = 'Not a customer', RecordTypeId = SUPPLIER_RT)
    };
    insert new CMN_Vehicle__c(
      Name = 'SUV',
      VehicleCode__c = 'HE1',
      Customer__c = accountId('Hyundai')
    );
  }

  @IsTest
  static void test_AC01_nonCustomerAccountNotSelectable() {
    // Given: 고객 RecordType이 아닌 Account
    CMN_Vehicle__c v = new CMN_Vehicle__c(
      Name = 'X',
      VehicleCode__c = 'X1',
      Customer__c = accountId('Not a customer')
    );

    // When: 차종의 고객으로 저장
    Database.SaveResult r = Database.insert(v, false);

    // Then: 조회 필터로 거부
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION,
      r.getErrors()[0].getStatusCode()
    );
  }

  @IsTest
  static void test_BR1_customerNeedsCodeAndGroup() {
    // Given / When: 고객 코드 없는 고객
    Account a = customer(null, 'No code', 'BMW');
    Database.SaveResult r = Database.insert(a, false);

    // Then
    Assert.isFalse(r.isSuccess());
  }

  @IsTest
  static void test_BR2_blankDueDaysUseSettingDefaults() {
    // Given: 기한이 빈 고객과 값이 있는 고객, 8D 전사 기본값 21일로 조정
    Account bmw = customer('BMW', 'BMW', 'BMW');
    bmw.EightDDueDays__c = 20;
    bmw.AuditStandard__c = 'VDA63;IATF16949';
    insert bmw;
    CMN_Settings.overrides.put(CMN_CustomerService.KEY_8D_DAYS, '21');
    Id hmc = accountId('Hyundai');

    // When
    Map<Id, CMN_CustomerService.Requirements> reqs = CMN_CustomerService.requirements(
      new Set<Id>{ hmc, bmw.Id }
    );

    // Then: 빈 값은 설정(D3 1일, 8D 21일, 원인 10일), 값이 있으면 고객 값. PPAP 기본 레벨 3(레코드타입 기본값)
    Assert.areEqual(1, reqs.get(hmc).containmentDueDays);
    Assert.areEqual(21, reqs.get(hmc).eightDDueDays);
    Assert.areEqual(10, reqs.get(hmc).rootCauseDueDays);
    Assert.areEqual('3', reqs.get(hmc).ppapDefaultLevel);
    Assert.areEqual(20, reqs.get(bmw.Id).eightDDueDays);
    Assert.areEqual(
      new List<String>{ 'VDA63', 'IATF16949' },
      reqs.get(bmw.Id).auditStandards
    );
  }

  @IsTest
  static void test_vehicleKeyAndDuplicate() {
    // Given: HMC-HE1이 있다
    Id hmc = accountId('Hyundai');

    // When: 같은 고객에 he1, 새 코드 HE2
    List<Database.SaveResult> rs = Database.insert(
      new List<CMN_Vehicle__c>{
        new CMN_Vehicle__c(
          Name = 'dup',
          VehicleCode__c = 'he1',
          Customer__c = hmc
        ),
        new CMN_Vehicle__c(
          Name = 'new',
          VehicleCode__c = ' HE2 ',
          Customer__c = hmc
        )
      },
      false
    );

    // Then: 중복은 차종 코드 오류, 새 차종 키는 HMC-HE2
    Assert.isFalse(rs[0].isSuccess());
    Assert.areEqual(
      String.format(
        Label.CMN_Customer_DuplicateVehicleCode,
        new List<Object>{ 'he1' }
      ),
      rs[0].getErrors()[0].getMessage()
    );
    Assert.areEqual(
      'HMC-HE2',
      [SELECT ExternalKey__c FROM CMN_Vehicle__c WHERE Id = :rs[1].getId()]
      .ExternalKey__c
    );
  }

  @IsTest
  static void test_negative_eopBeforeSopAndDeleteBlocked() {
    // Given: 차종 HE1
    CMN_Vehicle__c v = [SELECT Id FROM CMN_Vehicle__c LIMIT 1];

    // When: EOP < SOP, 삭제
    Database.SaveResult u = Database.update(
      new CMN_Vehicle__c(
        Id = v.Id,
        SopDate__c = Date.newInstance(2027, 1, 1),
        EopDate__c = Date.newInstance(2026, 1, 1)
      ),
      false
    );
    Database.DeleteResult d = Database.delete(v, false);

    // Then: 둘 다 거부
    Assert.isFalse(u.isSuccess());
    Assert.isFalse(d.isSuccess());
    Assert.areEqual(
      Label.CMN_Master_DeleteNotAllowed,
      d.getErrors()[0].getMessage()
    );
  }

  @IsTest
  static void test_bulk200Vehicles() {
    // Given: 차종 200개
    Id hmc = accountId('Hyundai');
    List<CMN_Vehicle__c> vs = new List<CMN_Vehicle__c>();
    for (Integer i = 0; i < 200; i++) {
      vs.add(
        new CMN_Vehicle__c(
          Name = 'V' + i,
          VehicleCode__c = 'V' + i,
          Customer__c = hmc
        )
      );
    }

    // When
    Integer before = Limits.getQueries();
    insert vs;
    Integer used = Limits.getQueries() - before;

    // Then: 트리거 SOQL 2회 이하
    Assert.isTrue(used <= 2, 'SOQL ' + used);
    Assert.areEqual(201, [SELECT COUNT() FROM CMN_Vehicle__c]);
  }

  @IsTest
  static void test_demoFixturesLoadCustomersAndVehicles() {
    // Given / When: 데모 픽스처 고객·차종(@TestSetup의 HMC와 같은 키는 갱신)
    CMN_TestDataFactory.loadFixtures(
      new Set<String>{ 'Account', 'CMN_Vehicle__c' }
    );

    // Then: 데모와 같은 외부 키
    Id v = CMN_TestDataFactory.idOf('CMN_Vehicle__c', 'HMC-HE1');
    Assert.isNotNull(v);
    Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE OemCode__c = 'HMC']);
  }

  // ------------------------------------------------------------------ 도우미
  private static Account customer(String oem, String name, String grp) {
    return new Account(
      Name = name,
      OemCode__c = oem,
      CustomerGroup__c = grp,
      RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('CMN_Customer')
        .getRecordTypeId()
    );
  }

  private static Id accountId(String name) {
    return [SELECT Id FROM Account WHERE Name = :name].Id;
  }
}
