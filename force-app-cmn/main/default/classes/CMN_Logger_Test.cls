@IsTest
private class CMN_Logger_Test {
  @IsTest
  static void test_AC02_logSurvivesRollback() {
    // Given: 롤백될 트랜잭션 안에서 오류 로그
    Test.startTest();
    Savepoint sp = Database.setSavepoint();
    // 업무 레코드 예시(Account는 레코드타입·검증 규칙이 붙어 공통 테스트에 쓰지 않는다)
    insert new CMN_Department__c(Name = 'rolled back', DeptCode__c = 'RB1');
    CMN_Logger.error(
      'CMN_Logger_Test.rollback',
      'boom',
      null,
      new CMN_Exception('inner cause')
    );
    // When: 롤백
    Database.rollback(sp);
    Test.getEventBus().deliver();
    Test.stopTest();
    // Then: 업무 레코드는 사라지고 로그 1건은 남는다
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM CMN_Department__c WHERE Name = 'rolled back']
    );
    List<CMN_Log__c> logs = [
      SELECT Level__c, Source__c, Message__c, Payload__c, TransactionId__c
      FROM CMN_Log__c
    ];
    Assert.areEqual(1, logs.size(), '로그 1건');
    Assert.areEqual('ERROR', logs[0].Level__c);
    Assert.areEqual('CMN_Logger_Test.rollback', logs[0].Source__c);
    Assert.areEqual('boom', logs[0].Message__c);
    Assert.isTrue(
      logs[0].Payload__c.contains('inner cause'),
      '예외 원문은 Payload에'
    );
    Assert.isNotNull(logs[0].TransactionId__c);
  }

  @IsTest
  static void test_BR4_belowMinLevelNotPublished() {
    // Given: 최소 수준 WARN
    CMN_Logger.minLevelOverride = 'WARN';
    Test.startTest();
    // When
    CMN_Logger.info('S', 'info');
    CMN_Logger.debug('S', 'debug');
    CMN_Logger.warn('S', 'warn', null);
    CMN_Logger.error('S', 'error', null);
    Test.getEventBus().deliver();
    Test.stopTest();
    // Then: WARN·ERROR만
    Assert.areEqual(2, [SELECT COUNT() FROM CMN_Log__c]);
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM CMN_Log__c WHERE Level__c IN ('INFO', 'DEBUG')]
    );
  }

  @IsTest
  static void test_defaultMinLevelIsInfo() {
    // Given: 설정 없음
    Assert.isTrue(CMN_Logger.isEnabled('INFO'));
    Assert.isFalse(CMN_Logger.isEnabled('DEBUG'));
    // 사용자 설정이 있으면 그 값
    insert new CMN_LogSetting__c(
      SetupOwnerId = UserInfo.getUserId(),
      MinLevel__c = 'debug'
    );
    Assert.isTrue(CMN_Logger.isEnabled('DEBUG'), '대소문자 무관');
  }

  @IsTest
  static void test_negative_unknownLevelIgnored() {
    Assert.isFalse(CMN_Logger.isEnabled('FATAL'));
    Assert.isFalse(CMN_Logger.isEnabled(null));
    Test.startTest();
    CMN_Logger.log('FATAL', 'S', 'x', null, null);
    Test.getEventBus().deliver();
    Test.stopTest();
    Assert.areEqual(0, [SELECT COUNT() FROM CMN_Log__c]);
  }

  @IsTest
  static void test_longMessageAndPayloadTruncated() {
    // Given: 필드 길이를 넘는 내용
    String longText = 'x'.repeat(40000);
    Test.startTest();
    CMN_Logger.log(
      'ERROR',
      '',
      longText,
      UserInfo.getUserId(),
      'p'.repeat(140000)
    );
    Test.getEventBus().deliver();
    Test.stopTest();
    // Then
    CMN_Log__c log = [
      SELECT Source__c, Message__c, Payload__c, RecordId__c
      FROM CMN_Log__c
    ];
    Assert.areEqual('unknown', log.Source__c, '빈 위치는 unknown');
    Assert.areEqual(32768, log.Message__c.length());
    Assert.areEqual(131072, log.Payload__c.length());
    Assert.areEqual(String.valueOf(UserInfo.getUserId()), log.RecordId__c);
  }
}
