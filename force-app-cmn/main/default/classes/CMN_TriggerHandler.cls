/**
 * @description 모든 트리거 핸들러의 기반 클래스. 트리거 본문은 `new XxxTriggerHandler().run();` 한 줄만 둔다(BR-1).
 *              핸들러를 건너뛰는 조건(BR-2): 객체 설정 IsActive__c = false, 실행 사용자가 BypassPermission__c 보유,
 *              코드에서 bypass(objectApiName) 호출. 같은 트랜잭션·같은 레코드·같은 컨텍스트 재진입은 한 번만 처리한다(BR-3).
 * @group CMN-00-ARC-002
 */
public virtual with sharing class CMN_TriggerHandler {
  /** 이관 모드 Custom Permission(개발 플랜 CR-12). 보유자의 적재는 기존 번호·상태를 유지하고 부수 효과를 생략한다. */
  public static final String MIGRATION_PERMISSION = 'CMN_DataMigration';

  private static final Set<String> BYPASSED = new Set<String>();
  private static final Map<String, Set<Id>> PROCESSED = new Map<String, Set<Id>>();
  private static Map<String, CMN_TriggerSetting__mdt> settingsByObject;

  @TestVisible
  private static Map<String, CMN_TriggerSetting__mdt> settingsOverride;
  @TestVisible
  private static Set<String> permissionsOverride;

  @TestVisible
  protected System.TriggerOperation operation;
  @TestVisible
  protected List<SObject> newRecords;
  @TestVisible
  protected List<SObject> oldRecords;
  @TestVisible
  protected Map<Id, SObject> oldMap;

  /**
   * @description 트리거 안에서 만들면 트리거 컨텍스트를 가져온다.
   */
  public CMN_TriggerHandler() {
    if (Trigger.isExecuting) {
      operation = Trigger.operationType;
      newRecords = Trigger.new;
      oldRecords = Trigger.old;
      oldMap = Trigger.oldMap;
    }
  }

  /**
   * @description 컨텍스트에 맞는 메서드를 실행한다. 건너뛰기·재진입 조건이면 아무것도 하지 않는다.
   * @throws CMN_Exception 트리거 밖에서 컨텍스트 없이 호출한 경우
   */
  public void run() {
    if (operation == null) {
      throw new CMN_Exception(
        'CMN_TriggerHandler.run() must be called from a trigger'
      );
    }
    List<SObject> records = newRecords != null ? newRecords : oldRecords;
    if (records == null || records.isEmpty()) {
      return;
    }
    String objectName = String.valueOf(records[0].getSObjectType());
    if (!isEnabled(objectName) || isReentry()) {
      return;
    }
    switch on operation {
      when BEFORE_INSERT {
        beforeInsert();
      }
      when BEFORE_UPDATE {
        beforeUpdate();
      }
      when BEFORE_DELETE {
        beforeDelete();
      }
      when AFTER_INSERT {
        afterInsert();
      }
      when AFTER_UPDATE {
        afterUpdate();
      }
      when AFTER_DELETE {
        afterDelete();
      }
      when AFTER_UNDELETE {
        afterUndelete();
      }
    }
  }

  protected virtual void beforeInsert() {
  }
  protected virtual void beforeUpdate() {
  }
  protected virtual void beforeDelete() {
  }
  protected virtual void afterInsert() {
  }
  protected virtual void afterUpdate() {
  }
  protected virtual void afterDelete() {
  }
  protected virtual void afterUndelete() {
  }

  /**
   * @description 이 트랜잭션에서 해당 객체 핸들러를 건너뛴다(예: 대량 정정 서비스가 자기 트리거를 잠시 끔).
   * @param objectApiName 객체 API 이름
   */
  public static void bypass(String objectApiName) {
    BYPASSED.add(objectApiName);
  }

  /**
   * @description bypass를 해제한다.
   * @param objectApiName 객체 API 이름
   */
  public static void clearBypass(String objectApiName) {
    BYPASSED.remove(objectApiName);
  }

  /**
   * @description 코드에서 건너뛰도록 지정됐는지.
   * @param objectApiName 객체 API 이름
   * @return 지정됐으면 true
   */
  public static Boolean isBypassed(String objectApiName) {
    return BYPASSED.contains(objectApiName);
  }

  /**
   * @description 실행 사용자가 데이터 이관 모드인지. 업무 핸들러는 이 값이 true면 채번(기존 RecordNo 유지)·상태 규칙·
   *              To-Do·알림·이벤트 같은 부수 효과를 생략한다.
   * @return 이관 모드면 true
   */
  public static Boolean isMigrationMode() {
    return hasPermission(MIGRATION_PERMISSION);
  }

  private Boolean isEnabled(String objectName) {
    if (BYPASSED.contains(objectName)) {
      return false;
    }
    CMN_TriggerSetting__mdt setting = settings().get(objectName);
    if (setting == null) {
      return true;
    }
    if (!setting.IsActive__c) {
      return false;
    }
    return String.isBlank(setting.BypassPermission__c) ||
      !hasPermission(setting.BypassPermission__c);
  }

  /**
   * 같은 핸들러·같은 컨텍스트에서 이미 처리한 레코드만으로 다시 불리면 재진입으로 본다.
   * before insert는 Id가 없어 판단하지 않는다. Platform Event에는 Id 필드가 없어 r.Id를 읽으면 예외가 나므로
   * 채워진 필드 맵으로 확인한다.
   */
  private Boolean isReentry() {
    Set<Id> ids = new Set<Id>();
    for (SObject r : (newRecords != null ? newRecords : oldRecords)) {
      Object id = r.getPopulatedFieldsAsMap().get('Id');
      if (id != null) {
        ids.add((Id) id);
      }
    }
    if (ids.isEmpty()) {
      return false;
    }
    String key = String.valueOf(this).substringBefore(':') + '/' + operation;
    Set<Id> done = PROCESSED.get(key);
    if (done == null) {
      done = new Set<Id>();
      PROCESSED.put(key, done);
    }
    if (done.containsAll(ids)) {
      return true;
    }
    done.addAll(ids);
    return false;
  }

  private static Map<String, CMN_TriggerSetting__mdt> settings() {
    if (settingsOverride != null) {
      return settingsOverride;
    }
    if (settingsByObject == null) {
      settingsByObject = new Map<String, CMN_TriggerSetting__mdt>();
      for (
        CMN_TriggerSetting__mdt s : CMN_TriggerSetting__mdt.getAll().values()
      ) {
        if (String.isNotBlank(s.ObjectApiName__c)) {
          settingsByObject.put(s.ObjectApiName__c, s);
        }
      }
    }
    return settingsByObject;
  }

  private static Boolean hasPermission(String customPermission) {
    if (permissionsOverride != null) {
      return permissionsOverride.contains(customPermission);
    }
    return FeatureManagement.checkPermission(customPermission);
  }
}
