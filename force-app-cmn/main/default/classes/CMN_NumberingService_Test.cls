/**
 * @description 채번 서비스 검증(CMN-00-ARC-003). 업무 객체(NCR) 대신 테스트 대상 객체 CMN_TestRecord__c로 검증한다(CR-11·DEV-3).
 * @group CMN-00-ARC-003
 */
@IsTest
private class CMN_NumberingService_Test {
  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    insert new List<CMN_Plant__c>{
      plant(c.Id, 'KR01', 'Asia/Seoul'),
      plant(c.Id, 'US01', 'America/Chicago')
    };
  }

  @IsTest
  static void test_AC01_bulk200InOrderWithoutGaps() {
    // Given: KR01 공장 200건(공장 시간 2027-06-01)
    CMN_NumberingService.nowOverride = Datetime.newInstanceGmt(
      2027,
      6,
      1,
      3,
      0,
      0
    );
    List<CMN_TestRecord__c> recs = records('KR01', 200);

    // When: 한 번에 저장
    Integer before = Limits.getQueries();
    insert recs;
    Integer used = Limits.getQueries() - before;

    // Then: 000001~000200이 저장 순서대로, 중복 없이
    Set<String> seen = new Set<String>();
    List<CMN_TestRecord__c> saved = [
      SELECT RecordNo__c
      FROM CMN_TestRecord__c
      WHERE Id IN :recs
    ];
    Map<Id, String> byId = new Map<Id, String>();
    for (CMN_TestRecord__c r : saved) {
      byId.put(r.Id, r.RecordNo__c);
      seen.add(r.RecordNo__c);
    }
    Assert.areEqual(200, seen.size());
    Assert.areEqual('TST-KR01-2027-000001', byId.get(recs[0].Id));
    Assert.areEqual('TST-KR01-2027-000200', byId.get(recs[199].Id));
    Assert.isTrue(used <= 4, 'SOQL ' + used);
    Assert.areEqual(200, counter('CMN_TestRecord__c/KR01/2027'));
  }

  @IsTest
  static void test_AC02_yearResetsAtPlantMidnight() {
    // Given: KR01 2027년 마지막 번호 000350
    insert new CMN_NumberCounter__c(
      Key__c = 'CMN_TestRecord__c/KR01/2027',
      LastValue__c = 350
    );

    // When: 공장 시간 2027-12-31 23:59, 2028-01-01 00:01에 하나씩
    CMN_NumberingService.nowOverride = Datetime.newInstanceGmt(
      2027,
      12,
      31,
      14,
      59,
      0
    );
    CMN_TestRecord__c last = records('KR01', 1)[0];
    insert last;
    CMN_NumberingService.nowOverride = Datetime.newInstanceGmt(
      2027,
      12,
      31,
      15,
      1,
      0
    );
    CMN_TestRecord__c first = records('KR01', 1)[0];
    insert first;

    // Then: 연도 경계는 공장 자정
    Assert.areEqual('TST-KR01-2027-000351', numberOf(last.Id));
    Assert.areEqual('TST-KR01-2028-000001', numberOf(first.Id));
  }

  @IsTest
  static void test_AC02_usPlantUsesChicagoTime() {
    // Given: 2028-01-01 03:00 UTC(시카고 2027-12-31 21:00)
    CMN_NumberingService.nowOverride = Datetime.newInstanceGmt(
      2028,
      1,
      1,
      3,
      0,
      0
    );

    // When: US01, KR01 각 1건
    CMN_TestRecord__c us = records('US01', 1)[0];
    CMN_TestRecord__c kr = records('KR01', 1)[0];
    insert new List<CMN_TestRecord__c>{ us, kr };

    // Then: 공장마다 자기 시간대 연도
    Assert.areEqual('TST-US01-2027-000001', numberOf(us.Id));
    Assert.areEqual('TST-KR01-2028-000001', numberOf(kr.Id));
  }

  @IsTest
  static void test_AC03_issuedNumberCannotChange() {
    // Given: 발행된 레코드
    CMN_TestRecord__c r = records('KR01', 1)[0];
    insert r;

    // When: 번호 수정
    Database.SaveResult res = Database.update(
      new CMN_TestRecord__c(Id = r.Id, RecordNo__c = 'TST-KR01-2027-999999'),
      false
    );

    // Then: 검증 규칙(번역된 문구)으로 차단
    Assert.isFalse(res.isSuccess());
    Assert.areEqual(
      StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,
      res.getErrors()[0].getStatusCode()
    );
  }

  @IsTest
  static void test_CR_companyWideSequenceWithoutPlant() {
    // Given: 공장 토큰 없는 전사 연번 규칙(LL-, 초기화 없음)
    CMN_NumberingService.rulesOverride = new Map<String, CMN_NumberingRule__mdt>{
      'CMN_TestRecord__c' => new CMN_NumberingRule__mdt(
        ObjectApiName__c = 'CMN_TestRecord__c',
        Pattern__c = 'LL-{SEQ:5}',
        ResetPolicy__c = 'NEVER'
      )
    };

    // When: 공장 없이 2건
    List<CMN_TestRecord__c> recs = new List<CMN_TestRecord__c>{
      new CMN_TestRecord__c(Name = 'a'),
      new CMN_TestRecord__c(Name = 'b')
    };
    insert recs;

    // Then
    Assert.areEqual('LL-00001', numberOf(recs[0].Id));
    Assert.areEqual('LL-00002', numberOf(recs[1].Id));
    Assert.areEqual(2, counter('CMN_TestRecord__c/*/*'));
  }

  @IsTest
  static void test_monthlyResetAndShortYear() {
    // Given: 월 초기화 규칙
    CMN_NumberingService.rulesOverride = new Map<String, CMN_NumberingRule__mdt>{
      'CMN_TestRecord__c' => new CMN_NumberingRule__mdt(
        ObjectApiName__c = 'CMN_TestRecord__c',
        Pattern__c = 'M-{PLANT}-{YY}{MM}-{SEQ:3}',
        ScopeField__c = 'Plant__c',
        ResetPolicy__c = 'MONTHLY'
      )
    };
    CMN_NumberingService.nowOverride = Datetime.newInstanceGmt(
      2027,
      3,
      10,
      0,
      0,
      0
    );

    // When
    CMN_TestRecord__c r = records('KR01', 1)[0];
    insert r;

    // Then
    Assert.areEqual('M-KR01-2703-001', numberOf(r.Id));
    Assert.areEqual(1, counter('CMN_TestRecord__c/KR01/202703'));
  }

  @IsTest
  static void test_BR4_deployedPatternsAreValidAndBadTokensFail() {
    // Given / When / Then: 배포된 규칙은 모두 통과(미지원 토큰이 있으면 배포 검증에서 이 테스트가 실패한다)
    for (CMN_NumberingRule__mdt r : CMN_NumberingRule__mdt.getAll().values()) {
      CMN_NumberingService.validatePattern(r.Pattern__c);
    }
    for (
      String bad : new List<String>{
        'X-{FOO}-{SEQ:4}',
        'X-{YYYY}',
        'X-{SEQ:2}-{SEQ:3}',
        'X-{SEQ:0}',
        ''
      }
    ) {
      try {
        CMN_NumberingService.validatePattern(bad);
        Assert.fail('거부돼야 한다: ' + bad);
      } catch (CMN_Exception e) {
        Assert.isTrue(e.getMessage().length() > 0);
      }
    }
  }

  @IsTest
  static void test_migrationKeepsNumberAndAdvancesCounter() {
    // Given: 이관 모드 사용자가 기존 번호 000500을 가진 레코드를 적재
    CMN_NumberingService.nowOverride = Datetime.newInstanceGmt(
      2027,
      6,
      1,
      3,
      0,
      0
    );
    User migrator = migrationUser();
    CMN_TestRecord__c old = records('KR01', 1)[0];
    old.RecordNo__c = 'TST-KR01-2027-000500';
    System.runAs(migrator) {
      insert old;
    }

    // When: 평소처럼 새 레코드
    CMN_TestRecord__c next = records('KR01', 1)[0];
    insert next;

    // Then: 기존 번호 유지, 다음 번호는 000501
    Assert.areEqual('TST-KR01-2027-000500', numberOf(old.Id));
    Assert.areEqual('TST-KR01-2027-000501', numberOf(next.Id));
  }

  @IsTest
  static void test_negative_missingPlantOrRule() {
    // Given / When: 공장 없는 레코드
    Database.SaveResult r = Database.insert(
      new CMN_TestRecord__c(Name = 'x'),
      false
    );

    // Then: 공장 필요 문구
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(Label.CMN_Numbering_NoScope, r.getErrors()[0].getMessage());

    // 규칙 없는 객체는 설정 오류
    try {
      CMN_NumberingService.assign(new List<SObject>{ new CMN_Department__c() });
      Assert.fail('규칙 없음이어야 한다');
    } catch (CMN_Exception e) {
      Assert.areEqual(
        String.format(
          Label.CMN_Numbering_NoRule,
          new List<Object>{ 'CMN_Department__c' }
        ),
        e.getMessage()
      );
    }
  }

  // ------------------------------------------------------------------ 도우미
  private static final Map<String, Id> PLANT_IDS = new Map<String, Id>();

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

  private static List<CMN_TestRecord__c> records(String plantCode, Integer n) {
    if (!PLANT_IDS.containsKey(plantCode)) {
      PLANT_IDS.put(
        plantCode,
        [SELECT Id FROM CMN_Plant__c WHERE PlantCode__c = :plantCode].Id
      );
    }
    List<CMN_TestRecord__c> out = new List<CMN_TestRecord__c>();
    for (Integer i = 0; i < n; i++) {
      out.add(
        new CMN_TestRecord__c(
          Name = 'R' + i,
          Plant__c = PLANT_IDS.get(plantCode)
        )
      );
    }
    return out;
  }

  private static String numberOf(Id id) {
    return [SELECT RecordNo__c FROM CMN_TestRecord__c WHERE Id = :id]
    .RecordNo__c;
  }

  private static Decimal counter(String key) {
    return [SELECT LastValue__c FROM CMN_NumberCounter__c WHERE Key__c = :key]
    .LastValue__c;
  }

  private static User migrationUser() {
    User u = CMN_TestDataFactory.newUser(
      'numg',
      'Migrator',
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert u;
      insert new PermissionSetAssignment(
        AssigneeId = u.Id,
        PermissionSetId = [
          SELECT Id
          FROM PermissionSet
          WHERE Name = 'CMN_PS_DataMigration'
        ]
        .Id
      );
    }
    return u;
  }
}
