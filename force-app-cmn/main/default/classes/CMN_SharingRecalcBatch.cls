/**
 * @description 공유 전체 재계산(CMN-00-SEC-002 BR-6·AC-4). 공장 그룹·구성원을 다시 맞추고(start) 대상 객체 전체의 공유를
 * 200건씩 다시 계산한다. 데이터 이관 후, 공유 설정 변경 후 실행한다: `CMN_SharingRecalcBatch.run('QMS_Ncr__c')`.
 * @group CMN-00-SEC-002
 */
public with sharing class CMN_SharingRecalcBatch implements Database.Batchable<SObject> {
  public static final Integer BATCH_SIZE = 200;
  private final String objectApiName;

  /**
   * @description 대상 객체.
   * @param objectApiName CMN_SharingConfig__mdt에 등록된 객체
   * @throws CMN_ValidationException 등록되지 않은 객체
   */
  public CMN_SharingRecalcBatch(String objectApiName) {
    if (CMN_SharingService.configOf(objectApiName) == null) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    this.objectApiName = objectApiName;
  }

  /**
   * @description 배치 크기 200으로 실행한다.
   * @param objectApiName 대상 객체
   * @return 작업 Id
   */
  public static Id run(String objectApiName) {
    return Database.executeBatch(
      new CMN_SharingRecalcBatch(objectApiName),
      BATCH_SIZE
    );
  }

  /**
   * @description 공장 그룹·구성원을 맞추고 대상 레코드를 읽는다.
   * @param bc 배치 문맥
   * @return 레코드 로케이터
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    Set<Id> plantIds = new Map<Id, CMN_Plant__c>(
        [SELECT Id FROM CMN_Plant__c WITH SYSTEM_MODE]
      )
      .keySet();
    CMN_PlantGroupService.ensureGroups(plantIds);
    Set<Id> userIds = new Set<Id>();
    for (CMN_UserPlantAccess__c a : [
      SELECT User__c
      FROM CMN_UserPlantAccess__c
      WITH SYSTEM_MODE
    ]) {
      userIds.add(a.User__c);
    }
    CMN_PlantGroupService.syncMembers(userIds);
    CMN_SharingConfig__mdt cfg = CMN_SharingService.configOf(objectApiName);
    String fields = 'Id, ' + String.escapeSingleQuotes(cfg.PlantField__c);
    if (String.isNotBlank(cfg.SupplierField__c)) {
      fields += ', ' + String.escapeSingleQuotes(cfg.SupplierField__c);
    }
    return Database.getQueryLocatorWithBinds(
      'SELECT ' + fields + ' FROM ' + String.escapeSingleQuotes(objectApiName),
      new Map<String, Object>(),
      AccessLevel.SYSTEM_MODE
    );
  }

  /**
   * @description 묶음의 공유를 다시 계산한다.
   * @param bc 배치 문맥
   * @param scope 레코드
   */
  public void execute(Database.BatchableContext bc, List<SObject> scope) {
    CMN_SharingService.recalculate(scope);
  }

  /**
   * @description 끝 기록.
   * @param bc 배치 문맥
   */
  public void finish(Database.BatchableContext bc) {
    CMN_Logger.info(
      'CMN_SharingRecalcBatch.finish',
      'Sharing recalculated: ' + objectApiName
    );
  }
}
