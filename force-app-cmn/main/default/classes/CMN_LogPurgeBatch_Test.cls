@IsTest
private class CMN_LogPurgeBatch_Test {
  private static CMN_Log__c log(String level, Integer daysAgo) {
    CMN_Log__c l = new CMN_Log__c(
      Level__c = level,
      Source__c = 'T',
      Message__c = level + daysAgo,
      TransactionId__c = 't'
    );
    insert l;
    Test.setCreatedDate(l.Id, System.now().addDays(-daysAgo));
    return l;
  }

  @IsTest
  static void test_BR5_deletesByLevelRetention() {
    // Given: 수준별 보존 기간 안·밖 로그
    log('INFO', 31);
    CMN_Log__c infoKeep = log('INFO', 10);
    log('DEBUG', 40);
    log('WARN', 91);
    CMN_Log__c warnKeep = log('WARN', 60);
    log('ERROR', 366);
    CMN_Log__c errorKeep = log('ERROR', 100);
    // When
    Test.startTest();
    Database.executeBatch(new CMN_LogPurgeBatch(), 200);
    Test.stopTest();
    // Then: 보존 기간 안 로그만 남는다
    Set<Id> left = new Map<Id, CMN_Log__c>([SELECT Id FROM CMN_Log__c])
      .keySet();
    Assert.areEqual(
      new Set<Id>{ infoKeep.Id, warnKeep.Id, errorKeep.Id },
      left
    );
  }

  @IsTest
  static void test_scheduleDailyAt0200() {
    Test.startTest();
    Id jobId = CMN_LogPurgeBatch.scheduleDaily();
    Test.stopTest();
    CronTrigger ct = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
    Assert.areEqual(CMN_LogPurgeBatch.CRON_DAILY_0200, ct.CronExpression);
  }

  @IsTest
  static void test_schedulableRunsBatch() {
    log('INFO', 31);
    Test.startTest();
    new CMN_LogPurgeBatch().execute((SchedulableContext) null);
    Test.stopTest();
    Assert.areEqual(0, [SELECT COUNT() FROM CMN_Log__c]);
  }
}
