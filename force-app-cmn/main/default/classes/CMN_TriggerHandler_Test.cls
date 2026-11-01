@IsTest
private class CMN_TriggerHandler_Test {
  private class CountingHandler extends CMN_TriggerHandler {
    public List<String> calls = new List<String>();
    protected override void beforeInsert() {
      calls.add('beforeInsert');
    }
    protected override void beforeUpdate() {
      calls.add('beforeUpdate');
    }
    protected override void beforeDelete() {
      calls.add('beforeDelete');
    }
    protected override void afterInsert() {
      calls.add('afterInsert');
    }
    protected override void afterUpdate() {
      calls.add('afterUpdate');
    }
    protected override void afterDelete() {
      calls.add('afterDelete');
    }
    protected override void afterUndelete() {
      calls.add('afterUndelete');
    }
  }

  private static Id fakeId(Integer n) {
    return Id.valueOf(
      Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED)
        .getKeyPrefix() + String.valueOf(n).leftPad(12, '0')
    );
  }

  private static CountingHandler handler(
    System.TriggerOperation op,
    List<SObject> records
  ) {
    CountingHandler h = new CountingHandler();
    h.operation = op;
    h.newRecords = records;
    return h;
  }

  @IsTest
  static void test_AC01_bulk200EventsSingleDml() {
    // Given: 로그 이벤트 200건(구독 트리거가 CMN_TriggerHandler로 CMN_Log__c를 만든다)
    List<CMN_LogEvent__e> events = new List<CMN_LogEvent__e>();
    for (Integer i = 0; i < 200; i++) {
      events.add(
        new CMN_LogEvent__e(
          Level__c = 'ERROR',
          Source__c = 'Test.bulk',
          Message__c = 'm' + i,
          TransactionId__c = 't'
        )
      );
    }
    Test.startTest();
    EventBus.publish(events);
    Integer dmlBefore = Limits.getDmlStatements();
    Integer soqlBefore = Limits.getQueries();
    // When: 구독 트리거 실행
    Test.getEventBus().deliver();
    Integer dmlUsed = Limits.getDmlStatements() - dmlBefore;
    Integer soqlUsed = Limits.getQueries() - soqlBefore;
    Test.stopTest();
    // Then: 로그 200건, 핸들러는 DML 1회·SOQL 1회 이하
    Assert.areEqual(200, [SELECT COUNT() FROM CMN_Log__c], '200건 모두 저장');
    Assert.isTrue(dmlUsed <= 1, '핸들러 DML 수: ' + dmlUsed);
    Assert.isTrue(soqlUsed <= 1, '핸들러 SOQL 수: ' + soqlUsed);
  }

  @IsTest
  static void test_AC03_inactiveSettingSkipsHandler() {
    // Given: Account 핸들러 설정 IsActive__c = false
    CMN_TriggerHandler.settingsOverride = new Map<String, CMN_TriggerSetting__mdt>{
      'Account' => new CMN_TriggerSetting__mdt(
        ObjectApiName__c = 'Account',
        IsActive__c = false
      )
    };
    CountingHandler h = handler(
      System.TriggerOperation.BEFORE_INSERT,
      new List<Account>{ new Account(Name = 'A') }
    );
    // When
    h.run();
    // Then: 핸들러 로직이 실행되지 않음
    Assert.isTrue(h.calls.isEmpty(), '비활성 객체는 건너뜀');
  }

  @IsTest
  static void test_BR2_bypassPermissionSkipsHandler() {
    // Given: 우회 Custom Permission을 가진 사용자
    CMN_TriggerHandler.settingsOverride = new Map<String, CMN_TriggerSetting__mdt>{
      'Account' => new CMN_TriggerSetting__mdt(
        ObjectApiName__c = 'Account',
        IsActive__c = true,
        BypassPermission__c = 'X_Bypass'
      )
    };
    CMN_TriggerHandler.permissionsOverride = new Set<String>{ 'X_Bypass' };
    CountingHandler h = handler(
      System.TriggerOperation.BEFORE_INSERT,
      new List<Account>{ new Account(Name = 'A') }
    );
    // When
    h.run();
    // Then
    Assert.isTrue(h.calls.isEmpty(), '우회 권한 보유자는 건너뜀');

    // Given: 권한이 없으면 실행
    CMN_TriggerHandler.permissionsOverride = new Set<String>();
    CountingHandler h2 = handler(
      System.TriggerOperation.BEFORE_INSERT,
      new List<Account>{ new Account(Name = 'A') }
    );
    h2.run();
    Assert.areEqual(new List<String>{ 'beforeInsert' }, h2.calls);
  }

  @IsTest
  static void test_BR2_codeBypassAndClear() {
    // Given: 코드에서 Account 우회
    CMN_TriggerHandler.bypass('Account');
    Assert.isTrue(CMN_TriggerHandler.isBypassed('Account'));
    CountingHandler h = handler(
      System.TriggerOperation.BEFORE_INSERT,
      new List<Account>{ new Account(Name = 'A') }
    );
    h.run();
    Assert.isTrue(h.calls.isEmpty(), '우회 중');
    // When: 해제
    CMN_TriggerHandler.clearBypass('Account');
    CountingHandler h2 = handler(
      System.TriggerOperation.BEFORE_INSERT,
      new List<Account>{ new Account(Name = 'A') }
    );
    h2.run();
    // Then
    Assert.areEqual(1, h2.calls.size(), '해제 후 실행');
  }

  @IsTest
  static void test_BR3_reentrySameContextRunsOnce() {
    // Given: 같은 레코드·같은 컨텍스트
    List<Account> recs = new List<Account>{
      new Account(Id = fakeId(1), Name = 'A'),
      new Account(Id = fakeId(2), Name = 'B')
    };
    CountingHandler first = handler(System.TriggerOperation.AFTER_UPDATE, recs);
    first.run();
    // When: 재진입
    CountingHandler again = handler(System.TriggerOperation.AFTER_UPDATE, recs);
    again.run();
    // Then: 두 번째는 건너뜀, 새 레코드가 섞이면 다시 실행
    Assert.areEqual(1, first.calls.size());
    Assert.isTrue(again.calls.isEmpty(), '재진입은 한 번만 처리');
    CountingHandler withNew = handler(
      System.TriggerOperation.AFTER_UPDATE,
      new List<Account>{ new Account(Id = fakeId(3), Name = 'C') }
    );
    withNew.run();
    Assert.areEqual(1, withNew.calls.size(), '처리하지 않은 레코드는 실행');
  }

  @IsTest
  static void test_dispatchesEveryContext() {
    Map<System.TriggerOperation, String> expected = new Map<System.TriggerOperation, String>{
      System.TriggerOperation.BEFORE_INSERT => 'beforeInsert',
      System.TriggerOperation.BEFORE_UPDATE => 'beforeUpdate',
      System.TriggerOperation.BEFORE_DELETE => 'beforeDelete',
      System.TriggerOperation.AFTER_INSERT => 'afterInsert',
      System.TriggerOperation.AFTER_UPDATE => 'afterUpdate',
      System.TriggerOperation.AFTER_DELETE => 'afterDelete',
      System.TriggerOperation.AFTER_UNDELETE => 'afterUndelete'
    };
    Integer n = 10;
    for (System.TriggerOperation op : expected.keySet()) {
      CountingHandler h = handler(
        op,
        new List<Account>{ new Account(Id = fakeId(n++), Name = 'X') }
      );
      h.run();
      Assert.areEqual(
        new List<String>{ expected.get(op) },
        h.calls,
        String.valueOf(op)
      );
    }
  }

  @IsTest
  static void test_negative_runOutsideTriggerThrows() {
    // Given: 트리거 컨텍스트 없음
    CountingHandler h = new CountingHandler();
    try {
      // When
      h.run();
      Assert.fail('트리거 밖 호출은 예외');
    } catch (CMN_Exception e) {
      // Then
      Assert.isTrue(e.getMessage().contains('trigger'));
    }
  }

  @IsTest
  static void test_emptyRecordsNoop() {
    CountingHandler h = handler(
      System.TriggerOperation.BEFORE_INSERT,
      new List<Account>()
    );
    h.run();
    Assert.isTrue(h.calls.isEmpty());
  }

  @IsTest
  static void test_migrationModeFollowsPermission() {
    CMN_TriggerHandler.permissionsOverride = new Set<String>();
    Assert.isFalse(CMN_TriggerHandler.isMigrationMode());
    CMN_TriggerHandler.permissionsOverride = new Set<String>{
      CMN_TriggerHandler.MIGRATION_PERMISSION
    };
    Assert.isTrue(CMN_TriggerHandler.isMigrationMode());
    CMN_TriggerHandler.permissionsOverride = null;
    Assert.isFalse(
      CMN_TriggerHandler.isMigrationMode(),
      '테스트 실행 사용자에게는 이관 권한이 없음'
    );
  }
}
