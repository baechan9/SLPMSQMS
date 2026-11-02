/**
 * @description 연계 표준 Salesforce 수신 계약 검증(CMN-00-INT-001). Mule 동작은 연계 시뮬(외부 키 upsert)로 흉내 낸다(개발 플랜 7.3).
 * @group CMN-00-INT-001
 */
@IsTest
private class CMN_InterfaceLogService_Test {
  @TestSetup
  static void setup() {
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User admin = CMN_TestDataFactory.newUser('ifadm', 'ifadm', profileId);
    User mule = CMN_TestDataFactory.newUser('ifmule', 'ifmule', profileId);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ admin, mule };
      insert new List<PermissionSetAssignment>{
        new PermissionSetAssignment(
          AssigneeId = admin.Id,
          PermissionSetGroupId = [
            SELECT Id
            FROM PermissionSetGroup
            WHERE DeveloperName = 'CMN_PSG_SystemAdmin'
          ]
          .Id
        ),
        new PermissionSetAssignment(
          AssigneeId = mule.Id,
          PermissionSetId = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'CMN_PS_Integration'
          ]
          .Id
        )
      };
    }
  }

  @IsTest
  static void test_AC01_sameRunUpsertedTwiceKeepsOneLog() {
    // Given: Mule이 같은 실행 결과를 두 번 보냄(재전송)
    User mule = user('ifmule');
    System.runAs(mule) {
      // When: 외부 키 upsert 2회(통합 사용자 권한)
      for (Integer i = 0; i < 2; i++) {
        Database.upsert(
          new List<CMN_InterfaceLog__c>{
            log('IF-HR-001', 'corr-1', 'SUCCESS', 0)
          },
          CMN_InterfaceLog__c.ExternalKey__c,
          true,
          AccessLevel.USER_MODE
        );
      }
    }

    // Then: 1건, 외부 키·이름 채움
    CMN_InterfaceLog__c saved = [
      SELECT Name, ExternalKey__c, RecordCount__c
      FROM CMN_InterfaceLog__c
    ];
    Assert.areEqual('IF-HR-001:corr-1', saved.ExternalKey__c);
    Assert.isTrue(saved.Name.startsWith('IF-HR-001 '));
    Assert.areEqual(120, saved.RecordCount__c);
  }

  @IsTest
  static void test_AC02_failedThenRecoveredLeavesTwoLogsAndAlertsAdmins() {
    // Given: 점검 시간 실패(FAILED), 복구 후 재처리 성공(SUCCESS)
    User admin = user('ifadm');

    // When
    insert log('IF-SAP-001', 'corr-a', 'FAILED', 3);
    insert log('IF-SAP-001', 'corr-b', 'SUCCESS', 0);

    // Then: 로그 2건, 실패 1건만 시스템 관리자에게 알림
    Assert.areEqual(
      2,
      [
        SELECT COUNT()
        FROM CMN_InterfaceLog__c
        WHERE InterfaceId__c = 'IF-SAP-001'
      ]
    );
    List<CMN_NotificationService.Message> alerts = alerts();
    Assert.areEqual(1, alerts.size());
    Assert.isTrue(alerts[0].recipientIds.contains(admin.Id));
    Assert.areEqual('IF-SAP-001', alerts[0].params.get('InterfaceId'));
    Assert.areEqual('3', alerts[0].params.get('ErrorCount'));

    // 같은 실행을 다시 FAILED로 보내도 알림을 반복하지 않고, SUCCESS → FAILED 전환은 알린다
    CMN_InterfaceLog__c a = [
      SELECT Id
      FROM CMN_InterfaceLog__c
      WHERE CorrelationId__c = 'corr-a'
    ];
    update new CMN_InterfaceLog__c(Id = a.Id, ErrorCount__c = 4);
    Assert.areEqual(1, alerts().size());
    CMN_InterfaceLog__c b = [
      SELECT Id
      FROM CMN_InterfaceLog__c
      WHERE CorrelationId__c = 'corr-b'
    ];
    update new CMN_InterfaceLog__c(Id = b.Id, Status__c = 'FAILED');
    Assert.areEqual(2, alerts().size());
  }

  @IsTest
  static void test_AC03_monitoringListViewShowsRecentFailures() {
    // Given: 최근 실패, 25시간 전 실패, 최근 성공
    Id plant = plant();
    CMN_InterfaceLog__c recent = log('IF-MES-001', 'r1', 'FAILED', 1);
    recent.Plant__c = plant;
    CMN_InterfaceLog__c old = log('IF-MES-001', 'r2', 'FAILED', 1);
    old.StartedAt__c = Datetime.now().addHours(-25);
    old.EndedAt__c = Datetime.now().addHours(-25).addMinutes(1);
    insert new List<CMN_InterfaceLog__c>{
      recent,
      old,
      log('IF-MES-001', 'r3', 'SUCCESS', 0)
    };

    // When: 리스트뷰 조건(FAILED + 최근 24시간)으로 조회
    List<CMN_InterfaceLog__c> rows = [
      SELECT CorrelationId__c, Plant__c
      FROM CMN_InterfaceLog__c
      WHERE Status__c = 'FAILED' AND IsRecent__c = TRUE
    ];

    // Then: 최근 실패 1건(공장 포함), 리스트뷰가 배포돼 있다
    Assert.areEqual(1, rows.size());
    Assert.areEqual('r1', rows[0].CorrelationId__c);
    Assert.areEqual(plant, rows[0].Plant__c);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM ListView
        WHERE
          SobjectType = 'CMN_InterfaceLog__c'
          AND DeveloperName = 'CMN_FailedLast24h'
      ]
    );
  }

  @IsTest
  static void test_BR4_catalogAndValidation() {
    // 카탈로그: 기본·Vol.9·Vol.7 인터페이스(34건 이상), 형식
    Map<String, CMN_Interface__mdt> all = CMN_Interface__mdt.getAll();
    Assert.isTrue(all.size() >= 34, 'catalog ' + all.size());
    for (CMN_Interface__mdt i : all.values()) {
      Assert.isTrue(i.InterfaceId__c.startsWith('IF-'), i.InterfaceId__c);
      Assert.isTrue(
        new Set<String>{ 'BATCH', 'REALTIME', 'EVENT' }.contains(i.Pattern__c),
        i.InterfaceId__c
      );
    }
    // 종료가 시작보다 앞서면 거절, 미등록 인터페이스는 저장 + WARN
    CMN_InterfaceLog__c bad = log('IF-HR-001', 'x', 'SUCCESS', 0);
    bad.EndedAt__c = bad.StartedAt__c.addMinutes(-1);
    Database.SaveResult sr = Database.insert(bad, false);
    Assert.isFalse(sr.isSuccess());
    Assert.areEqual(
      Label.CMN_Common_InvalidInput,
      sr.getErrors()[0].getMessage()
    );
    insert log('IF-NEW-999', 'y', 'SUCCESS', 0);
    Test.getEventBus().deliver();
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM CMN_Log__c
        WHERE Level__c = 'WARN' AND Source__c = 'CMN_InterfaceLogService'
      ]
    );
  }

  @IsTest
  static void test_bulk200LogsAndNoAdmin() {
    // Given: 실패 200건, 관리자 없음
    System.runAs(new User(Id = UserInfo.getUserId())) {
      delete [
        SELECT Id
        FROM PermissionSetAssignment
        WHERE PermissionSetGroup.DeveloperName = 'CMN_PSG_SystemAdmin'
      ];
    }
    List<CMN_InterfaceLog__c> rows = new List<CMN_InterfaceLog__c>();
    for (Integer i = 0; i < 200; i++) {
      rows.add(log('IF-SAP-002', 'bulk-' + i, 'FAILED', 1));
    }

    // When
    Integer q0 = Limits.getQueries();
    insert rows;

    // Then: SOQL은 건수와 무관, 알림 대상이 없으면 보내지 않고 경고
    Assert.isTrue(
      Limits.getQueries() - q0 <= 2,
      'SOQL ' + (Limits.getQueries() - q0)
    );
    Assert.areEqual(0, alerts().size());
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_InterfaceLog__c log(
    String interfaceId,
    String correlationId,
    String status,
    Integer errors
  ) {
    Datetime started = Datetime.now().addMinutes(-5);
    return new CMN_InterfaceLog__c(
      InterfaceId__c = interfaceId,
      CorrelationId__c = correlationId,
      Status__c = status,
      RecordCount__c = 120,
      ErrorCount__c = errors,
      StartedAt__c = started,
      EndedAt__c = started.addMinutes(2),
      ErrorSummary__c = errors > 0 ? 'E1101: invalid department' : null,
      ExternalKey__c = interfaceId + ':' + correlationId
    );
  }

  private static User user(String alias) {
    return [SELECT Id FROM User WHERE Alias = :alias LIMIT 1];
  }

  private static Id plant() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    CMN_Plant__c p = new CMN_Plant__c(
      Name = 'KR01',
      PlantCode__c = 'KR01',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
    insert p;
    return p.Id;
  }

  private static List<CMN_NotificationService.Message> alerts() {
    List<CMN_NotificationService.Message> out = new List<CMN_NotificationService.Message>();
    for (CMN_NotificationService.Message m : CMN_NotificationService.queued) {
      if (m.eventCode == CMN_InterfaceLogService.ALERT_EVENT) {
        out.add(m);
      }
    }
    return out;
  }
}
