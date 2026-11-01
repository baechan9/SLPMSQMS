/**
 * @description 삭제 통제(CMN-00-SEC-003). CMN_DeleteGuard__mdt에 등록된 객체는
 * - 상태가 삭제 가능 값(예: DRAFT)이 아니면 삭제를 막고(BR-1, 관리자 예외 없음),
 * - 삭제되면 삭제 직전 레코드 전체를 JSON으로 CMN_DeleteLog__c에 남긴다(BR-2).
 * CMN_TriggerHandler가 모든 업무 객체의 before/after delete에서 부르므로, 업무 객체 WI는 규칙 레코드만 더하면 된다.
 * @group CMN-00-SEC-003
 */
public with sharing class CMN_DeleteGuardService {
  private static final Integer SNAPSHOT_MAX = 131072;
  @TestVisible
  private static Map<String, CMN_DeleteGuard__mdt> guardsOverride;
  private static Map<String, CMN_DeleteGuard__mdt> guards;
  private static String reason;
  /** 삭제 기록은 이 서비스만 만든다(CMN_DeleteLogTriggerHandler가 확인). */
  @TestVisible
  private static Boolean writing = false;

  /**
   * @description 다음 삭제의 사유(UI에서 입력한 경우). 기록 후 비운다.
   * @param text 삭제 사유
   */
  public static void setReason(String text) {
    reason = text?.left(255);
  }

  /**
   * @description 삭제 기록을 쓰는 중인지(삭제 기록 트리거가 직접 생성을 막을 때 확인).
   * @return 서비스가 쓰는 중이면 true
   */
  public static Boolean isWriting() {
    return writing;
  }

  /**
   * @description BR-1: 삭제 가능 상태가 아니면 막는다(before delete).
   * @param records Trigger.old
   */
  public static void guard(List<SObject> records) {
    CMN_DeleteGuard__mdt g = guardOf(records);
    if (g == null || String.isBlank(g.StatusField__c)) {
      return;
    }
    Set<String> deletable = new Set<String>();
    for (String v : (g.DeletableValues__c ?? '').split(',')) {
      if (String.isNotBlank(v)) {
        deletable.add(v.trim());
      }
    }
    for (SObject r : records) {
      String status = String.valueOf(r.get(g.StatusField__c));
      if (!deletable.contains(status)) {
        r.addError(
          String.format(
            Label.CMN_Delete_NotAllowedStatus,
            new List<Object>{ status }
          )
        );
      }
    }
  }

  /**
   * @description BR-2: 삭제된 레코드의 스냅숏을 남긴다(after delete).
   * @param records Trigger.old
   */
  public static void log(List<SObject> records) {
    CMN_DeleteGuard__mdt g = guardOf(records);
    if (g == null) {
      return;
    }
    String objectName = String.valueOf(records[0].getSObjectType());
    Datetime now = Datetime.now();
    List<CMN_DeleteLog__c> logs = new List<CMN_DeleteLog__c>();
    for (SObject r : records) {
      Map<String, Object> fields = r.getPopulatedFieldsAsMap();
      logs.add(
        new CMN_DeleteLog__c(
          ObjectApiName__c = objectName,
          RecordIdText__c = r.Id,
          RecordNo__c = (String) fields.get('RecordNo__c'),
          Snapshot__c = JSON.serialize(fields).left(SNAPSHOT_MAX),
          DeletedBy__c = UserInfo.getUserId(),
          DeletedAt__c = now,
          Reason__c = reason
        )
      );
    }
    reason = null;
    writing = true;
    try {
      // 삭제 기록은 사용자에게 생성 권한이 없다. 서비스가 시스템 모드로 쓴다
      Database.insert(logs, AccessLevel.SYSTEM_MODE);
    } finally {
      writing = false;
    }
  }

  private static CMN_DeleteGuard__mdt guardOf(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return null;
    }
    if (guards == null) {
      guards = new Map<String, CMN_DeleteGuard__mdt>();
      for (CMN_DeleteGuard__mdt g : CMN_DeleteGuard__mdt.getAll().values()) {
        guards.put(g.ObjectApiName__c, g);
      }
    }
    String objectName = String.valueOf(records[0].getSObjectType());
    return guardsOverride?.get(objectName) ?? guards.get(objectName);
  }
}
