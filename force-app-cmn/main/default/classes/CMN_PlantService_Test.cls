/**
 * @description 법인·공장·라인·공정 계층 검증(CMN-00-MDM-002).
 * @group CMN-00-MDM-002
 */
@IsTest
private class CMN_PlantService_Test {
  @TestSetup
  static void setup() {
    CMN_Company__c kr = new CMN_Company__c(
      Name = 'SL KR',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    CMN_Company__c us = new CMN_Company__c(
      Name = 'SL US',
      CompanyCode__c = '3000',
      Country__c = 'US'
    );
    insert new List<CMN_Company__c>{ kr, us };
    insert new List<CMN_Plant__c>{
      plant(kr.Id, 'KR01', 'KR', 'Asia/Seoul', 'ko'),
      plant(us.Id, 'US01', 'NA', 'America/Chicago', 'en_US')
    };
    insert new CMN_Line__c(
      Name = 'HL 3',
      LineCode__c = 'L03',
      Plant__c = plantId('KR01')
    );
  }

  @IsTest
  static void test_AC01_duplicateLineCodeInPlantRejected() {
    // Given: KR01에 라인 L03이 있다
    CMN_Line__c dup = new CMN_Line__c(
      Name = 'HL 3 again',
      LineCode__c = 'l03',
      Plant__c = plantId('KR01')
    );

    // When: 같은 공장에 L03(대소문자만 다름)을 추가
    Database.SaveResult r = Database.insert(dup, false);

    // Then: 중복 오류(라인 코드 필드, 라벨 문구)
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      String.format(
        Label.CMN_Site_DuplicateLineCode,
        new List<Object>{ 'l03' }
      ),
      r.getErrors()[0].getMessage()
    );
    Assert.areEqual(
      new List<String>{ 'LineCode__c' },
      r.getErrors()[0].getFields()
    );
  }

  @IsTest
  static void test_AC01_duplicateWithinOneSaveRejected() {
    // Given: 같은 저장 묶음에 KR01-L07 두 건
    List<CMN_Line__c> lines = new List<CMN_Line__c>{
      new CMN_Line__c(
        Name = 'a',
        LineCode__c = 'L07',
        Plant__c = plantId('KR01')
      ),
      new CMN_Line__c(
        Name = 'b',
        LineCode__c = 'L07',
        Plant__c = plantId('KR01')
      )
    };

    // When
    List<Database.SaveResult> rs = Database.insert(lines, false);

    // Then: 첫 건만 저장
    Assert.isTrue(rs[0].isSuccess());
    Assert.isFalse(rs[1].isSuccess());
  }

  @IsTest
  static void test_BR1_externalKeysAssignedFromCodes() {
    // Given: 사용자가 외부 키를 임의로 넣은 라인과 공정
    CMN_Line__c line = new CMN_Line__c(
      Name = 'Lens',
      LineCode__c = ' L05 ',
      Plant__c = plantId('KR01'),
      ExternalKey__c = 'WRONG'
    );

    // When: 저장
    insert line;
    CMN_Operation__c op = new CMN_Operation__c(
      Name = 'Leak',
      OpCode__c = 'OP40',
      Line__c = line.Id,
      Sequence__c = 40,
      OperationType__c = 'LEAK_TEST'
    );
    insert op;

    // Then: 코드로 다시 만든 키(공백 제거)
    Assert.areEqual(
      'KR01-L05',
      [SELECT ExternalKey__c FROM CMN_Line__c WHERE Id = :line.Id]
      .ExternalKey__c
    );
    Assert.areEqual(
      'KR01-L05-OP40',
      [SELECT ExternalKey__c FROM CMN_Operation__c WHERE Id = :op.Id]
      .ExternalKey__c
    );
  }

  @IsTest
  static void test_BR1_sameLineCodeInOtherPlantAllowed() {
    // Given / When: US01에 L03
    CMN_Line__c l = new CMN_Line__c(
      Name = 'US 3',
      LineCode__c = 'L03',
      Plant__c = plantId('US01')
    );
    insert l;

    // Then
    Assert.areEqual(
      'US01-L03',
      [SELECT ExternalKey__c FROM CMN_Line__c WHERE Id = :l.Id].ExternalKey__c
    );
  }

  @IsTest
  static void test_AC02_plantTimeZoneDecidesLocalYear() {
    // Given: 2027-01-01 03:00 UTC(시카고는 아직 2026-12-31 21:00)
    Datetime instant = Datetime.newInstanceGmt(2027, 1, 1, 3, 0, 0);

    // When: 공장 현지 날짜
    Date us = CMN_PlantService.localDate('US01', instant);
    Date kr = CMN_PlantService.localDate(plantId('KR01'), instant);

    // Then: 미국 공장은 2026년, 한국 공장은 2027년
    Assert.areEqual(Date.newInstance(2026, 12, 31), us);
    Assert.areEqual(2027, kr.year());
    Assert.areEqual(
      'America/Chicago',
      CMN_PlantService.timeZoneOf('us01').getID()
    );
  }

  @IsTest
  static void test_BR2_deleteBlockedDeactivateAllowed() {
    // Given: 법인·공장·라인·공정
    CMN_Line__c line = [SELECT Id FROM CMN_Line__c LIMIT 1];
    CMN_Operation__c op = new CMN_Operation__c(
      Name = 'Assy',
      OpCode__c = 'OP10',
      Line__c = line.Id,
      Sequence__c = 10,
      OperationType__c = 'ASSEMBLY'
    );
    insert op;
    List<SObject> targets = new List<SObject>{
      [SELECT Id FROM CMN_Company__c WHERE CompanyCode__c = '1000'],
      new CMN_Plant__c(Id = plantId('KR01')),
      line,
      op
    };

    // When: 삭제 시도
    for (SObject target : targets) {
      Database.DeleteResult r = Database.delete(target, false);
      // Then: 모두 차단(라벨 문구)
      Assert.isFalse(r.isSuccess(), String.valueOf(target.getSObjectType()));
      Assert.areEqual(
        Label.CMN_Master_DeleteNotAllowed,
        r.getErrors()[0].getMessage()
      );
    }

    // When / Then: 비활성화는 된다
    update new CMN_Line__c(Id = line.Id, IsActive__c = false);
    Assert.isFalse(
      [SELECT IsActive__c FROM CMN_Line__c WHERE Id = :line.Id].IsActive__c
    );
  }

  @IsTest
  static void test_negative_codeCannotChangeAfterCreate() {
    // Given: 공장 KR01
    CMN_Plant__c p = new CMN_Plant__c(
      Id = plantId('KR01'),
      PlantCode__c = 'KR09'
    );

    // When: 코드 변경
    Database.SaveResult r = Database.update(p, false);

    // Then: 검증 규칙으로 차단
    Assert.isFalse(r.isSuccess());
  }

  @IsTest
  static void test_BR1_migrationLineCodeFixRefreshesOperationKeys() {
    // Given: 이관 모드 사용자, 라인 L03의 공정 OP10
    CMN_Line__c line = [SELECT Id FROM CMN_Line__c WHERE LineCode__c = 'L03'];
    insert new CMN_Operation__c(
      Name = 'Assy',
      OpCode__c = 'OP10',
      Line__c = line.Id,
      Sequence__c = 10,
      OperationType__c = 'ASSEMBLY'
    );
    User migrator = migrationUser();

    // When: 이관 모드에서 라인 코드를 L33으로 정정
    System.runAs(migrator) {
      update new CMN_Line__c(Id = line.Id, LineCode__c = 'L33');
    }

    // Then: 라인·공정 외부 키가 함께 바뀐다
    Assert.areEqual(
      'KR01-L33-OP10',
      [SELECT ExternalKey__c FROM CMN_Operation__c WHERE Line__c = :line.Id]
      .ExternalKey__c
    );
  }

  @IsTest
  static void test_bulk200LinesAndOperations() {
    // Given: 공장 2곳에 라인 200개
    Id kr01 = plantId('KR01');
    Id us01 = plantId('US01');
    List<CMN_Line__c> lines = new List<CMN_Line__c>();
    for (Integer i = 0; i < 200; i++) {
      lines.add(
        new CMN_Line__c(
          Name = 'B' + i,
          LineCode__c = 'B' + i,
          Plant__c = Math.mod(i, 2) == 0 ? kr01 : us01
        )
      );
    }

    // When: 한 번에 저장하고 라인마다 공정 1개
    Integer before = Limits.getQueries();
    insert lines;
    Integer lineQueries = Limits.getQueries() - before;
    List<CMN_Operation__c> ops = new List<CMN_Operation__c>();
    for (CMN_Line__c l : lines) {
      ops.add(
        new CMN_Operation__c(
          Name = 'Op',
          OpCode__c = 'OP10',
          Line__c = l.Id,
          Sequence__c = 10,
          OperationType__c = 'EOL'
        )
      );
    }
    before = Limits.getQueries();
    insert ops;
    Integer opQueries = Limits.getQueries() - before;

    // Then: 트리거 조회 2회 이하, 키 200개
    Assert.isTrue(lineQueries <= 2, 'line SOQL ' + lineQueries);
    Assert.isTrue(opQueries <= 2, 'operation SOQL ' + opQueries);
    Assert.areEqual(
      200,
      [
        SELECT COUNT()
        FROM CMN_Operation__c
        WHERE ExternalKey__c LIKE '%-B%-OP10'
      ]
    );
  }

  @IsTest
  static void test_negative_unknownPlantThrows() {
    // Given / When / Then: 없는 공장 코드
    try {
      CMN_PlantService.localDate('XX99', Datetime.now());
      Assert.fail('예외가 나야 한다');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(
        String.format(Label.CMN_Site_UnknownPlant, new List<Object>{ 'XX99' }),
        e.getMessage()
      );
    }
  }

  @IsTest
  static void test_demoFixturesLoadIntoHierarchy() {
    // Given: 데모 픽스처(데모 CSV와 같은 키)
    // When: 계층 4개 객체 적재(이관 모드)
    CMN_TestDataFactory.loadFixtures(
      new Set<String>{
        'CMN_Company__c',
        'CMN_Plant__c',
        'CMN_Line__c',
        'CMN_Operation__c'
      }
    );

    // Then: 픽스처 라인이 데모와 같은 외부 키로 생기고, @TestSetup의 KR01은 갱신된다(중복 없음)
    Id lineId = CMN_TestDataFactory.idOf('CMN_Line__c', 'KR01-L01');
    Assert.isNotNull(lineId);
    Assert.areEqual(
      'KR01-L01',
      [SELECT ExternalKey__c FROM CMN_Line__c WHERE Id = :lineId].ExternalKey__c
    );
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM CMN_Plant__c WHERE PlantCode__c = 'KR01']
    );
    Assert.areEqual('Asia/Seoul', CMN_PlantService.timeZoneOf('KR01').getID());
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_Plant__c plant(
    Id companyId,
    String code,
    String region,
    String tz,
    String lang
  ) {
    return new CMN_Plant__c(
      Name = code,
      PlantCode__c = code,
      Company__c = companyId,
      Region__c = region,
      TimeZone__c = tz,
      DefaultLanguage__c = lang
    );
  }

  private static Id plantId(String code) {
    return [SELECT Id FROM CMN_Plant__c WHERE PlantCode__c = :code].Id;
  }

  private static User migrationUser() {
    User u = CMN_TestDataFactory.newUser(
      'migr',
      'Migrator',
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert u;
      List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
      for (PermissionSet ps : [
        SELECT Id
        FROM PermissionSet
        WHERE Name IN ('CMN_PS_DataMigration', 'CMN_PS_Site_Admin')
      ]) {
        psas.add(
          new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
          )
        );
      }
      insert psas;
    }
    return u;
  }
}
