/**
 * @description 연계 로그 규칙(CMN-00-INT-001 BR-3·BR-4). Mule이 실행 1회마다 CMN_InterfaceLog__c 1건을 남긴다.
 * - 외부 키 `{InterfaceId}:{CorrelationId}`: 같은 실행을 다시 보내면 갱신(멱등). 비우면 채운다.
 * - 카탈로그(CMN_Interface__mdt)에 없는 인터페이스는 저장하되 WARN 로그(로그 유실 방지).
 * - FAILED가 되면 CMN_PSG_SystemAdmin 사용자에게 알림(NTF `CMN_INTERFACE_FAILED`).
 * @group CMN-00-INT-001
 */
public with sharing class CMN_InterfaceLogService {
  public static final String FAILED = 'FAILED';
  public static final String ALERT_EVENT = 'CMN_INTERFACE_FAILED';
  public static final String ADMIN_GROUP = 'CMN_PSG_SystemAdmin';
  private static final Integer SUMMARY_MAX = 32768;
  private static final Integer NAME_MAX = 80;

  /**
   * @description 저장 전 정리: 이름·외부 키·요약 길이, 시작·종료 순서 확인.
   * @param logs 저장할 로그
   */
  public static void prepare(List<CMN_InterfaceLog__c> logs) {
    Set<String> known = knownInterfaces();
    Set<String> unknown = new Set<String>();
    for (CMN_InterfaceLog__c l : logs) {
      if (
        l.StartedAt__c != null &&
        l.EndedAt__c != null &&
        l.EndedAt__c < l.StartedAt__c
      ) {
        l.addError(Label.CMN_Common_InvalidInput);
        continue;
      }
      if (String.isBlank(l.ExternalKey__c)) {
        l.ExternalKey__c = (l.InterfaceId__c +
          ':' +
          l.CorrelationId__c)
          .left(90);
      }
      l.Name = (l.InterfaceId__c +
        ' ' +
        l.StartedAt__c?.formatGmt('yyyy-MM-dd HH:mm') +
        'Z')
        .left(NAME_MAX);
      l.ErrorSummary__c = l.ErrorSummary__c?.abbreviate(SUMMARY_MAX);
      if (!known.contains(l.InterfaceId__c)) {
        unknown.add(l.InterfaceId__c);
      }
    }
    if (!unknown.isEmpty()) {
      // 묶음당 한 번만 남긴다(행마다 로그 이벤트를 발행하지 않는다)
      CMN_Logger.warn(
        'CMN_InterfaceLogService',
        'Interface not in catalog: ' +
        String.join(new List<String>(unknown), ', '),
        null
      );
    }
  }

  /**
   * @description 새로 FAILED가 된 로그를 시스템 관리자에게 알린다(Queueable 1개).
   * @param logs 저장된 로그
   * @param oldMap 이전 값(삽입이면 null)
   */
  public static void alertFailures(
    List<CMN_InterfaceLog__c> logs,
    Map<Id, SObject> oldMap
  ) {
    List<CMN_InterfaceLog__c> newlyFailed = new List<CMN_InterfaceLog__c>();
    for (CMN_InterfaceLog__c l : logs) {
      String before = (String) oldMap?.get(l.Id)?.get('Status__c');
      if (l.Status__c == FAILED && before != FAILED) {
        newlyFailed.add(l);
      }
    }
    if (newlyFailed.isEmpty()) {
      return;
    }
    Set<Id> admins = adminUsers();
    if (admins.isEmpty()) {
      CMN_Logger.warn(
        'CMN_InterfaceLogService',
        'No system administrator to alert for failed interface runs',
        newlyFailed[0].Id
      );
      return;
    }
    List<CMN_NotificationService.Message> messages = new List<CMN_NotificationService.Message>();
    for (CMN_InterfaceLog__c l : newlyFailed) {
      messages.add(
        new CMN_NotificationService.Message(
          ALERT_EVENT,
          admins,
          l.Id,
          new Map<String, String>{
            'InterfaceId' => l.InterfaceId__c,
            'CorrelationId' => l.CorrelationId__c,
            'RecordCount' => String.valueOf(l.RecordCount__c ?? 0),
            'ErrorCount' => String.valueOf(l.ErrorCount__c ?? 0)
          }
        )
      );
    }
    CMN_NotificationService.send(messages);
  }

  /**
   * @description 시스템 관리자 페르소나(PSG) 활성 사용자.
   * @return 사용자 Id
   */
  public static Set<Id> adminUsers() {
    Set<Id> out = new Set<Id>();
    for (PermissionSetAssignment a : [
      SELECT AssigneeId
      FROM PermissionSetAssignment
      WHERE
        PermissionSetGroup.DeveloperName = :ADMIN_GROUP
        AND Assignee.IsActive = TRUE
      WITH SYSTEM_MODE
    ]) {
      out.add(a.AssigneeId);
    }
    return out;
  }

  private static Set<String> knownInterfaces() {
    Set<String> out = new Set<String>();
    for (CMN_Interface__mdt i : CMN_Interface__mdt.getAll().values()) {
      out.add(i.InterfaceId__c);
    }
    return out;
  }
}
