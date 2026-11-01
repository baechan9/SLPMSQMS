/**
 * @description 로그 보존 정리(BR-5): INFO·DEBUG 30일, WARN 90일, ERROR 365일 초과분 삭제. 매일 02:00(KST) 실행.
 *              scheduleDaily()는 실행 사용자의 시간대로 예약되므로 KST 사용자로 예약한다.
 *              CMN-00-DWH-002가 Snowflake 적재 확인 후 삭제 규칙(DWH-002 BR-4)을 붙이면 그때 조건을 바꾼다.
 * @group CMN-00-ARC-002
 */
public with sharing class CMN_LogPurgeBatch implements Database.Batchable<SObject>, Schedulable {
  public static final String JOB_NAME = 'CMN_LogPurgeBatch';
  public static final String CRON_DAILY_0200 = '0 0 2 * * ?';

  /**
   * @description 삭제 대상 로그.
   * @param bc 배치 컨텍스트
   * @return 대상 쿼리
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    Datetime now = System.now();
    Datetime d30 = now.addDays(-30);
    Datetime d90 = now.addDays(-90);
    Datetime d365 = now.addDays(-365);
    return Database.getQueryLocator(
      [
        SELECT Id
        FROM CMN_Log__c
        WHERE
          (Level__c IN ('INFO', 'DEBUG')
          AND CreatedDate < :d30)
          OR (Level__c = 'WARN'
          AND CreatedDate < :d90)
          OR (Level__c = 'ERROR'
          AND CreatedDate < :d365)
        WITH SYSTEM_MODE
      ]
    );
  }

  /**
   * @description 삭제.
   * @param bc 배치 컨텍스트
   * @param scope 삭제할 로그
   */
  public void execute(Database.BatchableContext bc, List<CMN_Log__c> scope) {
    Database.delete(scope, false, AccessLevel.SYSTEM_MODE);
  }

  /**
   * @description 후처리 없음.
   * @param bc 배치 컨텍스트
   */
  public void finish(Database.BatchableContext bc) {
    return;
  }

  /**
   * @description 예약 실행.
   * @param sc 예약 컨텍스트
   */
  public void execute(SchedulableContext sc) {
    Database.executeBatch(new CMN_LogPurgeBatch(), 2000);
  }

  /**
   * @description 매일 02:00 예약(실행 사용자 시간대 기준).
   * @return 예약 작업 Id
   */
  public static Id scheduleDaily() {
    return System.schedule(JOB_NAME, CRON_DAILY_0200, new CMN_LogPurgeBatch());
  }
}
