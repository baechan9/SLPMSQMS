/**
 * @description SAP 기준정보 연계 Salesforce 수신 계약 검증(CMN-00-INT-003). Mule upsert를 통합 사용자 권한의 외부 키 upsert로 흉내 낸다
 * (개발 플랜 7.3). 매핑 대상 객체·외부 키·기본값은 MDM-002~005가 만들었고, 이 테스트는 연계 경로(통합 PS·외부 키 참조·멱등)를 확인한다.
 * @group CMN-00-INT-003
 */
@IsTest
private class CMN_SapMasterInbound_Test {
  @TestSetup
  static void setup() {
    Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
    insert new Account(
      Name = 'Alpha',
      SapVendorNo__c = 'V10001',
      RecordTypeId = rts.get('CMN_Supplier').getRecordTypeId()
    );
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
    User sap = CMN_TestDataFactory.newUser(
      'sapint',
      'sapint',
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert sap;
      List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
      for (PermissionSet ps : [
        SELECT Id
        FROM PermissionSet
        WHERE Name IN ('CMN_PS_Integration', 'CMN_PS_Integration_Sap')
      ]) {
        psa.add(
          new PermissionSetAssignment(
            AssigneeId = sap.Id,
            PermissionSetId = ps.Id
          )
        );
      }
      insert psa;
    }
  }

  @IsTest
  static void test_AC01_newInfoRecordCreatesSupplierItemWithDefaults() {
    // Given: 신규 공급업체-자재 정보레코드(검사 수준·PPAP 상태는 SAP에 없음)
    CMN_SupplierItem__c info = new CMN_SupplierItem__c(
      ExternalKey__c = 'V10001-P-LENS-KR01',
      Supplier__r = new Account(SapVendorNo__c = 'V10001'),
      Item__r = new CMN_Item__c(ItemNo__c = 'P-LENS'),
      Plant__r = new CMN_Plant__c(PlantCode__c = 'KR01')
    );

    // When: 통합 사용자가 같은 레코드를 두 번 upsert(재실행)
    System.runAs(sapUser()) {
      for (Integer i = 0; i < 2; i++) {
        Database.upsert(
          new List<CMN_SupplierItem__c>{ info.clone() },
          CMN_SupplierItem__c.ExternalKey__c,
          true,
          AccessLevel.USER_MODE
        );
      }
    }

    // Then: 1건, NORMAL·NOT_SUBMITTED
    CMN_SupplierItem__c saved = [
      SELECT InspectionLevel__c, PpapStatus__c
      FROM CMN_SupplierItem__c
    ];
    Assert.areEqual('NORMAL', saved.InspectionLevel__c);
    Assert.areEqual('NOT_SUBMITTED', saved.PpapStatus__c);
  }

  @IsTest
  static void test_AC02_deletionFlagPhasesOutItemPlantAndKeepsItem() {
    // Given: SAP 통합 사용자가 적재한 회사·플랜트·자재(운영에서 소유자 = 통합 사용자. 플랜트는 회사의, 자재-플랜트는 자재·플랜트의 주종 하위)와 자재-플랜트 확장(활성)
    System.runAs(sapUser()) {
      Database.upsert(
        new List<CMN_Item__c>{
          new CMN_Item__c(
            ItemNo__c = 'P-HOUSING',
            Name = 'Housing',
            ItemType__c = 'PART',
            ProductGroup__r = new CMN_ProductGroup__c(GroupCode__c = 'LAMP')
          )
        },
        CMN_Item__c.ItemNo__c,
        true,
        AccessLevel.USER_MODE
      );
      Database.upsert(
        new List<CMN_Company__c>{
          new CMN_Company__c(
            Name = 'SL Mexico',
            CompanyCode__c = '2000',
            Country__c = 'MX'
          )
        },
        CMN_Company__c.CompanyCode__c,
        true,
        AccessLevel.USER_MODE
      );
      Database.upsert(
        new List<CMN_Plant__c>{
          new CMN_Plant__c(
            Name = 'KR02',
            PlantCode__c = 'KR02',
            Company__r = new CMN_Company__c(CompanyCode__c = '2000'),
            Region__c = 'KR',
            TimeZone__c = 'Asia/Seoul',
            DefaultLanguage__c = 'ko'
          )
        },
        CMN_Plant__c.PlantCode__c,
        true,
        AccessLevel.USER_MODE
      );
    }
    CMN_ItemPlant__c ext = new CMN_ItemPlant__c(
      ExternalKey__c = 'P-HOUSING-KR02',
      Item__r = new CMN_Item__c(ItemNo__c = 'P-HOUSING'),
      Plant__r = new CMN_Plant__c(PlantCode__c = 'KR02'),
      Status__c = 'ACTIVE'
    );
    System.runAs(sapUser()) {
      Database.upsert(
        new List<CMN_ItemPlant__c>{ ext },
        CMN_ItemPlant__c.ExternalKey__c,
        true,
        AccessLevel.USER_MODE
      );

      // When: SAP 삭제 표시 → Mule이 PHASE_OUT으로 보냄
      Database.upsert(
        new List<CMN_ItemPlant__c>{
          new CMN_ItemPlant__c(
            ExternalKey__c = 'P-HOUSING-KR02',
            Status__c = 'PHASE_OUT'
          )
        },
        CMN_ItemPlant__c.ExternalKey__c,
        true,
        AccessLevel.USER_MODE
      );

      // 통합 사용자는 품번을 지울 수 없다(BR-5: 삭제 대신 PHASE_OUT)
      try {
        Database.delete(
          [SELECT Id FROM CMN_Item__c WHERE ItemNo__c = 'P-HOUSING'],
          AccessLevel.USER_MODE
        );
        Assert.fail('삭제 권한이 없어야 한다');
      } catch (Exception e) {
        Assert.isNotNull(e.getMessage());
      }
    }

    // Then: PHASE_OUT, 품번 유지
    Assert.areEqual(
      'PHASE_OUT',
      [
        SELECT Status__c
        FROM CMN_ItemPlant__c
        WHERE ExternalKey__c = 'P-HOUSING-KR02'
      ]
      .Status__c
    );
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM CMN_Item__c WHERE ItemNo__c = 'P-HOUSING']
    );
  }

  @IsTest
  static void test_BR1_masterUpsertIsIdempotent() {
    // Given / When: 자재·공급업체를 같은 외부 키로 두 번 upsert
    System.runAs(sapUser()) {
      for (Integer i = 0; i < 2; i++) {
        Database.upsert(
          new List<CMN_Item__c>{
            new CMN_Item__c(
              ItemNo__c = 'P-BEZEL',
              Name = 'Bezel',
              ItemType__c = 'PART',
              ProductGroup__r = new CMN_ProductGroup__c(GroupCode__c = 'LAMP')
            )
          },
          CMN_Item__c.ItemNo__c,
          true,
          AccessLevel.USER_MODE
        );
        Database.upsert(
          new List<Account>{
            new Account(
              Name = 'Beta',
              SapVendorNo__c = 'V10002',
              RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('CMN_Supplier')
                .getRecordTypeId()
            )
          },
          Account.SapVendorNo__c,
          true,
          AccessLevel.USER_MODE
        );
      }
    }

    // Then: 건수 불변
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM CMN_Item__c WHERE ItemNo__c = 'P-BEZEL']
    );
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Account WHERE SapVendorNo__c = 'V10002']
    );
  }

  private static User sapUser() {
    return [SELECT Id FROM User WHERE Alias = 'sapint' LIMIT 1];
  }
}
