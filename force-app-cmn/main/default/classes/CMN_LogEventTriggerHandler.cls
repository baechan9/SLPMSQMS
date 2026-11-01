/**
 * @description CMN_LogEvent__e 구독: 이벤트를 CMN_Log__c로 저장한다(BR-4). 이벤트 수와 관계없이 DML 1회.
 * @group CMN-00-ARC-002
 */
public with sharing class CMN_LogEventTriggerHandler extends CMN_TriggerHandler {
  protected override void afterInsert() {
    List<CMN_Log__c> logs = new List<CMN_Log__c>();
    for (CMN_LogEvent__e e : (List<CMN_LogEvent__e>) newRecords) {
      logs.add(
        new CMN_Log__c(
          Level__c = e.Level__c,
          Source__c = e.Source__c,
          Message__c = e.Message__c,
          RecordId__c = e.RecordId__c,
          Payload__c = e.Payload__c,
          TransactionId__c = e.TransactionId__c ?? 'unknown'
        )
      );
    }
    // 이벤트 구독은 자동 프로세스 사용자로 실행된다. 일부 실패가 나머지 로그 저장을 막지 않게 한다.
    Database.insert(logs, false, AccessLevel.SYSTEM_MODE);
  }
}
