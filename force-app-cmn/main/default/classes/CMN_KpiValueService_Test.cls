/**
 * @description KPI 값·수신 영수 데이터 모델 검증(CMN-00-DWH-003, 화면 우선 플랜 A0 범위).
 * Mule 적재는 통합 사용자 권한의 외부 키 upsert로 흉내 낸다. 이벤트 구독·핸들러 라우팅(AC-1·AC-2)은 상세 기능 단계(B)에서 더한다.
 * @group CMN-00-DWH-003
 */
@IsTest
private class CMN_KpiValueService_Test {
  private static final String PLANT = 'KR01';

  @TestSetup
  static void setup() {
    CMN_TestDataFactory.loadFixtures(
      new Set<String>{ 'CMN_Company__c', 'CMN_Plant__c' }
    );
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User mule = CMN_TestDataFactory.newUser('kpimule', 'kpimule', profileId);
    User viewer = CMN_TestDataFactory.newUser('kpiview', 'kpiview', profileId);
    User admin = CMN_TestDataFactory.newUser('kpiadm', 'kpiadm', profileId);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ mule, viewer, admin };
      List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
      for (PermissionSet ps : [
        SELECT Id
        FROM PermissionSet
        WHERE Name IN ('CMN_PS_Integration', 'CMN_PS_Integration_Dwh')
      ]) {
        psas.add(
          new PermissionSetAssignment(
            AssigneeId = mule.Id,
            PermissionSetId = ps.Id
          )
        );
      }
      psas.add(
        new PermissionSetAssignment(
          AssigneeId = viewer.Id,
          PermissionSetGroupId = groupId('QMS_PSG_Viewer')
        )
      );
      psas.add(
        new PermissionSetAssignment(
          AssigneeId = admin.Id,
          PermissionSetGroupId = groupId('CMN_PSG_SystemAdmin')
        )
      );
      insert psas;
    }
  }

  @IsTest
  static void test_BR01_integrationUpsertIsIdempotentAndBulk() {
    // Given: Mule이 KPI 뷰 200행을 같은 외부 키로 두 번 보냄(재적재)
    User mule = user('kpimule');
    Integer queries;
    System.runAs(mule) {
      Test.startTest();
      // When: 통합 사용자 권한으로 외부 키 upsert 2회(공장은 공장 코드 참조)
      for (Integer round = 0; round < 2; round++) {
        Database.upsert(
          rows(200, round),
          CMN_KpiValue__c.ExternalKey__c,
          true,
          AccessLevel.USER_MODE
        );
      }
      queries = Limits.getQueries();
      Test.stopTest();
    }

    // Then: 200건(멱등), 두 번째 값으로 갱신, 이름·공장 채움, 트리거가 행마다 SOQL을 쓰지 않음
    Assert.areEqual(200, [SELECT COUNT() FROM CMN_KpiValue__c]);
    CMN_KpiValue__c first = [
      SELECT Name, Value__c, Plant__r.PlantCode__c
      FROM CMN_KpiValue__c
      WHERE ExternalKey__c = 'k-0'
    ];
    Assert.areEqual('QMS_SPC_CPK MONTH 2026-10-01', first.Name);
    Assert.areEqual(1.5, first.Value__c);
    Assert.areEqual(PLANT, first.Plant__r.PlantCode__c);
    Assert.isTrue(queries < 20, 'SOQL used by trigger: ' + queries);
  }

  @IsTest
  static void test_BR01_nameFollowsKeyAndPeriod() {
    // Given: 분기 KPI 1건
    CMN_KpiValue__c v = new CMN_KpiValue__c(
      KpiKey__c = ' QMS_AUDIT_REPEAT_RATE ',
      PeriodType__c = 'QUARTER',
      PeriodStart__c = Date.newInstance(2026, 7, 1),
      Value__c = 0.12,
      ExternalKey__c = 'q-1'
    );
    insert v;
    Assert.areEqual(
      'QMS_AUDIT_REPEAT_RATE QUARTER 2026-07-01',
      [SELECT Name FROM CMN_KpiValue__c WHERE Id = :v.Id].Name
    );

    // When: 기간이 바뀌어 다시 적재
    v.PeriodStart__c = Date.newInstance(2026, 10, 1);
    v.Name = 'manual';
    update v;

    // Then: 이름은 다시 만들어진다(손으로 고친 이름은 남지 않음)
    Assert.areEqual(
      'QMS_AUDIT_REPEAT_RATE QUARTER 2026-10-01',
      [SELECT Name FROM CMN_KpiValue__c WHERE Id = :v.Id].Name
    );
    Assert.areEqual(
      'QMS_X',
      CMN_KpiValueService.titleOf(new CMN_KpiValue__c(KpiKey__c = 'QMS_X'))
    );
  }

  @IsTest
  static void test_permissions_viewerReadsKpiButNotReceipts() {
    // Given: KPI 1건과 수신 영수 1건(통합 사용자가 기록)
    User mule = user('kpimule');
    System.runAs(mule) {
      Database.insert(rows(1, 0), AccessLevel.USER_MODE);
      Database.insert(
        new CMN_InboundReceipt__c(
          Name = 'CMN_TEST evt-1',
          ExternalEventId__c = 'evt-1',
          EventType__c = 'CMN_TEST',
          Status__c = 'PROCESSED',
          AttemptCount__c = 1,
          ProcessedAt__c = Datetime.now(),
          PayloadJson__c = '{"schemaVersion":1}'
        ),
        AccessLevel.USER_MODE
      );
    }

    // When/Then: 조회 전용 페르소나는 KPI를 읽지만(사내 공개 읽기) 고칠 수 없고 수신 영수는 볼 수 없다
    System.runAs(user('kpiview')) {
      List<CMN_KpiValue__c> visible = [
        SELECT Id, Value__c
        FROM CMN_KpiValue__c
        WITH USER_MODE
      ];
      Assert.areEqual(1, visible.size());
      visible[0].Value__c = 9;
      Database.SaveResult sr = Database.update(
        visible[0],
        false,
        AccessLevel.USER_MODE
      );
      Assert.isFalse(sr.isSuccess());
      Boolean denied = false;
      try {
        Integer n = [SELECT COUNT() FROM CMN_InboundReceipt__c WITH USER_MODE];
        Assert.fail('Viewer should not read receipts: ' + n);
      } catch (System.SecurityException e) {
        denied = true;
      }
      Assert.isTrue(denied);
    }

    // Then: 시스템 관리 페르소나는 다른 사람이 기록한 영수를 모두 본다
    System.runAs(user('kpiadm')) {
      Assert.areEqual(
        1,
        [SELECT COUNT() FROM CMN_InboundReceipt__c WITH USER_MODE]
      );
    }
  }

  @IsTest
  static void test_receiptExternalEventIdIsUnique() {
    // Given: 같은 외부 이벤트 Id의 영수가 이미 있음
    insert receipt('evt-dup');

    // When: 같은 Id로 한 번 더 기록
    Database.SaveResult sr = Database.insert(receipt('evt-dup'), false);

    // Then: 중복 기록이 거부된다(멱등 처리의 기반, AC-1)
    Assert.isFalse(sr.isSuccess());
    Assert.areEqual(
      StatusCode.DUPLICATE_VALUE,
      sr.getErrors()[0].getStatusCode()
    );
    Assert.areEqual(
      'RECEIVED',
      [SELECT Status__c FROM CMN_InboundReceipt__c LIMIT 1].Status__c
    );
  }

  private static List<CMN_KpiValue__c> rows(Integer count, Integer round) {
    List<CMN_KpiValue__c> out = new List<CMN_KpiValue__c>();
    for (Integer i = 0; i < count; i++) {
      out.add(
        new CMN_KpiValue__c(
          ExternalKey__c = 'k-' + i,
          KpiKey__c = 'QMS_SPC_CPK',
          PeriodType__c = 'MONTH',
          PeriodStart__c = Date.newInstance(2026, 10, 1),
          Plant__r = new CMN_Plant__c(PlantCode__c = PLANT),
          Value__c = 1.4 + round * 0.1,
          Target__c = 1.33,
          Unit__c = 'RATIO',
          Rag__c = 'GREEN'
        )
      );
    }
    return out;
  }

  private static CMN_InboundReceipt__c receipt(String eventId) {
    return new CMN_InboundReceipt__c(
      Name = 'CMN_TEST ' + eventId,
      ExternalEventId__c = eventId,
      EventType__c = 'CMN_TEST'
    );
  }

  private static Id groupId(String developerName) {
    return [
      SELECT Id
      FROM PermissionSetGroup
      WHERE DeveloperName = :developerName
    ]
    .Id;
  }

  private static User user(String alias) {
    return [SELECT Id FROM User WHERE Alias = :alias];
  }
}
