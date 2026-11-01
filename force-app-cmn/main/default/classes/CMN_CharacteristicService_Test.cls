/**
 * @description 품질 특성 검증(CMN-00-MDM-006).
 * @group CMN-00-MDM-006
 */
@IsTest
private class CMN_CharacteristicService_Test {
  @TestSetup
  static void setup() {
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
    CMN_Characteristic__c active = spec('C10', 'SC', 3.0, 2.9, 3.1);
    active.EffectiveFrom__c = Date.newInstance(2025, 3, 1);
    insert active;
    CMN_CharacteristicService.activate(new Set<Id>{ active.Id });
  }

  @IsTest
  static void test_AC01_specOrderViolationRejected() {
    // Given: USL 3.1, LSL 2.9, 기준값 3.2
    CMN_Characteristic__c c = spec('C20', 'NONE', 3.2, 2.9, 3.1);

    // When
    Database.SaveResult r = Database.insert(c, false);

    // Then: 차단
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
      r.getErrors()[0].getStatusCode()
    );
  }

  @IsTest
  static void test_AC02_activeSpecChangeRejectedWithNewVersionHint() {
    // Given: ACTIVE 특성 C10
    CMN_Characteristic__c active = byNo('C10', 'ACTIVE');

    // When: USL 수정
    Database.SaveResult r = Database.update(
      new CMN_Characteristic__c(Id = active.Id, USL__c = 3.2),
      false
    );

    // Then: 차단(USL 필드, 새 버전 안내 검증 규칙)
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(new List<String>{ 'USL__c' }, r.getErrors()[0].getFields());
  }

  @IsTest
  static void test_AC03_targetCpkDefaults() {
    // Given: CC·SC 신규, 목표 Cpk 공란
    CMN_Characteristic__c cc = spec('C30', 'CC', 0, -0.2, 0.2);
    CMN_Characteristic__c sc = spec('C40', 'SC', 4.0, 3.5, 4.5);

    // When
    insert new List<CMN_Characteristic__c>{ cc, sc };

    // Then: CC 1.67, SC 1.33
    Assert.areEqual(
      1.67,
      [SELECT TargetCpk__c FROM CMN_Characteristic__c WHERE Id = :cc.Id]
      .TargetCpk__c
    );
    Assert.areEqual(
      1.33,
      [SELECT TargetCpk__c FROM CMN_Characteristic__c WHERE Id = :sc.Id]
      .TargetCpk__c
    );
  }

  @IsTest
  static void test_BR3_newVersionActivationClosesOldVersion() {
    // Given: 2025-03-01부터 ACTIVE인 C10
    CMN_Characteristic__c old = byNo('C10', 'ACTIVE');

    // When: 특성 편집 권한자가 2026-01-01 새 버전을 만들고 규격을 고친 뒤 활성화
    User editor = editor();
    Id draftId;
    System.runAs(editor) {
      draftId = CMN_CharacteristicController.createNewVersion(
        old.Id,
        Date.newInstance(2026, 1, 1)
      );
    }
    update new CMN_Characteristic__c(Id = draftId, USL__c = 3.15);
    System.runAs(editor) {
      CMN_CharacteristicController.activate(draftId);
    }

    // Then: 이전 버전은 2025-12-31로 닫혀 OBSOLETE, 새 버전 ACTIVE·새 키, 품번 특별특성 수는 1
    CMN_Characteristic__c closed = [
      SELECT Status__c, EffectiveTo__c
      FROM CMN_Characteristic__c
      WHERE Id = :old.Id
    ];
    Assert.areEqual('OBSOLETE', closed.Status__c);
    Assert.areEqual(Date.newInstance(2025, 12, 31), closed.EffectiveTo__c);
    CMN_Characteristic__c current = [
      SELECT Status__c, USL__c, ExternalKey__c
      FROM CMN_Characteristic__c
      WHERE Id = :draftId
    ];
    Assert.areEqual('ACTIVE', current.Status__c);
    Assert.areEqual(3.15, current.USL__c);
    Assert.areEqual('P-LENS-C10-20260101', current.ExternalKey__c);
    Assert.areEqual(
      1,
      [SELECT SpecialCharCount__c FROM CMN_Item__c].SpecialCharCount__c
    );
  }

  @IsTest
  static void test_negative_versionRules() {
    // Given: ACTIVE C10, 시작일 없는 초안 C50
    CMN_Characteristic__c active = byNo('C10', 'ACTIVE');
    CMN_Characteristic__c draft = spec('C50', 'NONE', 5.0, 4.9, 5.1);
    insert draft;

    // When / Then: 초안의 새 버전, 이른 시작일, 시작일 없는 활성화는 라벨 문구로 거부
    assertAura(Label.CMN_Char_NotActive, 'version', draft.Id, Date.today());
    assertAura(
      Label.CMN_Char_NewVersionMustBeLater,
      'version',
      active.Id,
      Date.newInstance(2025, 1, 1)
    );
    assertAura(Label.CMN_Char_FromRequired, 'version', active.Id, null);
    assertAura(Label.CMN_Char_FromRequired, 'activate', draft.Id, null);
    assertAura(Label.CMN_Char_NotDraft, 'activate', active.Id, null);
    assertAura(
      Label.CMN_Common_InvalidInput,
      'activate',
      [SELECT Id FROM CMN_Item__c].Id,
      null
    );
  }

  @IsTest
  static void test_negative_controllerNeedsEditPermission() {
    // Given: 특성 편집 PS가 없는 사용자
    User viewer = CMN_TestDataFactory.newUser(
      'char1',
      'Viewer',
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert viewer;
    }
    Id activeId = byNo('C10', 'ACTIVE').Id;

    // When / Then: 권한 없음
    System.runAs(viewer) {
      try {
        CMN_CharacteristicController.createNewVersion(activeId, Date.today());
        Assert.fail('권한 없음이어야 한다');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_NoPermission, e.getMessage());
      }
    }
  }

  @IsTest
  static void test_negative_unexpectedErrorMaskedAndLogged() {
    // Given: C10의 2026-02-01 초안이 이미 있다(같은 날짜 새 버전은 키 중복으로 저장 실패)
    CMN_Characteristic__c active = byNo('C10', 'ACTIVE');
    CMN_Characteristic__c existing = spec('C10', 'SC', 3.0, 2.9, 3.1);
    existing.EffectiveFrom__c = Date.newInstance(2026, 2, 1);
    insert existing;
    User editor = editor();

    // When: 같은 날짜로 새 버전
    String message;
    Test.startTest();
    System.runAs(editor) {
      try {
        CMN_CharacteristicController.createNewVersion(
          active.Id,
          Date.newInstance(2026, 2, 1)
        );
      } catch (AuraHandledException e) {
        message = e.getMessage();
      }
    }
    Test.getEventBus().deliver();
    Test.stopTest();

    // Then: 화면에는 공통 문구, 원문은 오류 로그
    Assert.areEqual(Label.CMN_Common_UnexpectedError, message);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM CMN_Log__c
        WHERE Source__c = 'CMN_CharacteristicController.createNewVersion'
      ]
    );
  }

  @IsTest
  static void test_deleteOnlyDraftAndDuplicateKey() {
    // Given: 초안 C60
    CMN_Characteristic__c draft = spec('C60', 'NONE', null, null, 40);
    insert draft;

    // When: 같은 키(품번·번호·시작일 없음) 초안 하나 더, 초안 삭제, 활성 삭제
    Database.SaveResult dup = Database.insert(
      spec('C60', 'NONE', null, null, 40),
      false
    );
    Database.DeleteResult delDraft = Database.delete(draft.Id, false);
    Database.DeleteResult delActive = Database.delete(
      byNo('C10', 'ACTIVE').Id,
      false
    );

    // Then
    Assert.isFalse(dup.isSuccess());
    Assert.isTrue(delDraft.isSuccess());
    Assert.isFalse(delActive.isSuccess());
    Assert.areEqual(
      Label.CMN_Char_DeleteOnlyDraft,
      delActive.getErrors()[0].getMessage()
    );
  }

  @IsTest
  static void test_negative_variableNeedsLimitAndUnit() {
    // Given / When: 규격·단위 없는 계량형, 규격 없는 관능
    CMN_Characteristic__c variable = spec('C70', 'NONE', null, null, null);
    CMN_Characteristic__c visual = spec('C80', 'NONE', null, null, null);
    visual.CharType__c = 'VISUAL';
    visual.Unit__c = null;
    List<Database.SaveResult> rs = Database.insert(
      new List<CMN_Characteristic__c>{ variable, visual },
      false
    );

    // Then: 계량형만 거부
    Assert.isFalse(rs[0].isSuccess());
    Assert.isTrue(rs[1].isSuccess());
  }

  @IsTest
  static void test_bulk200Characteristics() {
    // Given: 초안 200개
    List<CMN_Characteristic__c> cs = new List<CMN_Characteristic__c>();
    Id itemId = [SELECT Id FROM CMN_Item__c].Id;
    for (Integer i = 0; i < 200; i++) {
      CMN_Characteristic__c c = spec('B' + i, 'NONE', null, null, 1);
      c.Item__c = itemId;
      cs.add(c);
    }

    // When
    Integer before = Limits.getQueries();
    insert cs;
    Integer used = Limits.getQueries() - before;

    // Then: 트리거 SOQL 2회 이하(품번·중복)
    Assert.isTrue(used <= 2, 'SOQL ' + used);
  }

  @IsTest
  static void test_demoFixturesLoadCharacteristics() {
    // Given / When: 데모 픽스처 품번·특성(이관 모드로 ACTIVE 그대로)
    CMN_TestDataFactory.loadFixtures(
      new Set<String>{
        'Account',
        'CMN_ProductGroup__c',
        'CMN_Item__c',
        'CMN_Characteristic__c'
      }
    );

    // Then: 데모 키로 ACTIVE 특성이 생긴다
    Id c = CMN_TestDataFactory.idOf(
      'CMN_Characteristic__c',
      'P-LENS-HE1-C10-20240101'
    );
    Assert.isNotNull(c);
    Assert.areEqual(
      'ACTIVE',
      [SELECT Status__c FROM CMN_Characteristic__c WHERE Id = :c].Status__c
    );
  }

  // ------------------------------------------------------------------ 도우미
  private static Id itemIdCache;

  private static CMN_Characteristic__c spec(
    String no,
    String specialClass,
    Decimal nominal,
    Decimal lsl,
    Decimal usl
  ) {
    if (itemIdCache == null) {
      itemIdCache = [SELECT Id FROM CMN_Item__c WHERE ItemNo__c = 'P-LENS'].Id;
    }
    return new CMN_Characteristic__c(
      Name = no,
      Item__c = itemIdCache,
      CharNo__c = no,
      CharType__c = 'VARIABLE',
      Nominal__c = nominal,
      LSL__c = lsl,
      USL__c = usl,
      Unit__c = 'mm',
      SpecialClass__c = specialClass
    );
  }

  private static User editor() {
    User u = CMN_TestDataFactory.newUser(
      'chared',
      'Editor',
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert u;
      insert new PermissionSetAssignment(
        AssigneeId = u.Id,
        PermissionSetId = [
          SELECT Id
          FROM PermissionSet
          WHERE Name = 'CMN_PS_Characteristic_Edit'
        ]
        .Id
      );
    }
    return u;
  }

  private static CMN_Characteristic__c byNo(String no, String status) {
    return [
      SELECT Id, Status__c, EffectiveFrom__c
      FROM CMN_Characteristic__c
      WHERE CharNo__c = :no AND Status__c = :status
      LIMIT 1
    ];
  }

  private static void assertAura(
    String expected,
    String action,
    Id recordId,
    Date fromDate
  ) {
    try {
      if (action == 'version') {
        CMN_CharacteristicController.createNewVersion(recordId, fromDate);
      } else {
        CMN_CharacteristicController.activate(recordId);
      }
      Assert.fail('오류가 나야 한다: ' + expected);
    } catch (AuraHandledException e) {
      Assert.areEqual(expected, e.getMessage());
    }
  }
}
