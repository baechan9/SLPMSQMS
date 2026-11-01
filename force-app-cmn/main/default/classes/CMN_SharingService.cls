/**
 * @description 공장·협력사 공유(CMN-00-SEC-002 BR-3·BR-4). CMN_SharingConfig__mdt에 등록된 객체만 대상이다(객체별 코드 없음).
 * - 공장 필드의 공장 그룹: 편집 그룹 Edit, 읽기 그룹 Read(사유 CMN_Plant).
 * - 협력사 필드가 있으면 협력사 Account 포털 Manager 역할·하위 그룹에 Read(사유 CMN_Supplier, 검토 반영 Vol.3).
 * - 공장·협력사가 바뀌면 이전 공유를 지운다. CMN_TriggerHandler가 모든 업무 객체의 after insert/update에서 부른다.
 * 본사·경영진의 전 공장 조회는 PSG의 View All로 준다(BR-5, 공유 행 대상 아님).
 * @group CMN-00-SEC-002
 */
public with sharing class CMN_SharingService {
  public static final String CAUSE_PLANT = 'CMN_Plant__c';
  public static final String CAUSE_SUPPLIER = 'CMN_Supplier__c';
  @TestVisible
  private static Map<String, CMN_SharingConfig__mdt> configsOverride;
  private static Map<String, CMN_SharingConfig__mdt> configs;

  /**
   * @description 객체의 공유 설정(비활성·미등록이면 null).
   * @param objectApiName 객체
   * @return 설정
   */
  public static CMN_SharingConfig__mdt configOf(String objectApiName) {
    if (configsOverride != null) {
      return configsOverride.get(objectApiName);
    }
    if (configs == null) {
      configs = new Map<String, CMN_SharingConfig__mdt>();
      for (
        CMN_SharingConfig__mdt c : CMN_SharingConfig__mdt.getAll().values()
      ) {
        if (c.IsActive__c) {
          configs.put(c.ObjectApiName__c, c);
        }
      }
    }
    return configs.get(objectApiName);
  }

  /**
   * @description 저장 후 공유 맞춤(트리거 프레임워크). 삽입은 전부, 갱신은 공장·협력사가 바뀐 것만.
   * @param records Trigger.new
   * @param oldMap Trigger.oldMap(삽입이면 null)
   */
  public static void onAfterSave(
    List<SObject> records,
    Map<Id, SObject> oldMap
  ) {
    if (records == null || records.isEmpty()) {
      return;
    }
    CMN_SharingConfig__mdt cfg = configOf(
      String.valueOf(records[0].getSObjectType())
    );
    if (cfg == null) {
      return;
    }
    List<SObject> changed = new List<SObject>();
    for (SObject r : records) {
      SObject old = oldMap?.get(r.Id);
      if (
        old == null ||
        r.get(cfg.PlantField__c) != old.get(cfg.PlantField__c) ||
        (String.isNotBlank(cfg.SupplierField__c) &&
        r.get(cfg.SupplierField__c) != old.get(cfg.SupplierField__c))
      ) {
        changed.add(r);
      }
    }
    if (!changed.isEmpty()) {
      recalculate(changed);
    }
  }

  /**
   * @description 레코드의 공장·협력사 공유를 다시 맞춘다(BR-3, 재계산 배치도 사용).
   * @param records 같은 객체의 레코드(공장·협력사 필드 포함)
   */
  public static void recalculate(List<SObject> records) {
    String objectName = String.valueOf(records[0].getSObjectType());
    CMN_SharingConfig__mdt cfg = configOf(objectName);
    if (cfg == null) {
      return;
    }
    Set<Id> plantIds = new Set<Id>();
    Set<Id> supplierIds = new Set<Id>();
    for (SObject r : records) {
      Id plant = (Id) r.get(cfg.PlantField__c);
      if (plant != null) {
        plantIds.add(plant);
      }
      if (
        String.isNotBlank(cfg.SupplierField__c) &&
        r.get(cfg.SupplierField__c) != null
      ) {
        supplierIds.add((Id) r.get(cfg.SupplierField__c));
      }
    }
    Map<Id, Map<String, Id>> plantGroups = CMN_PlantGroupService.groupIds(
      plantIds
    );
    Map<Id, Id> supplierGroups = supplierGroups(supplierIds);

    Map<String, ShareRow> wanted = new Map<String, ShareRow>();
    for (SObject r : records) {
      Map<String, Id> groups = plantGroups.get((Id) r.get(cfg.PlantField__c));
      if (groups != null) {
        want(
          wanted,
          r.Id,
          groups.get(CMN_PlantGroupService.EDIT),
          'Edit',
          CAUSE_PLANT
        );
        want(
          wanted,
          r.Id,
          groups.get(CMN_PlantGroupService.READ),
          'Read',
          CAUSE_PLANT
        );
      }
      if (String.isNotBlank(cfg.SupplierField__c)) {
        want(
          wanted,
          r.Id,
          supplierGroups.get((Id) r.get(cfg.SupplierField__c)),
          'Read',
          CAUSE_SUPPLIER
        );
      }
    }
    apply(
      objectName,
      new Map<Id, SObject>(records).keySet(),
      wanted,
      new Set<String>{ CAUSE_PLANT, CAUSE_SUPPLIER }
    );
  }

  /**
   * @description 협력사 품번 기준으로 품번을 협력사 포털 그룹에 읽기 공유한다(검토 반영 Vol.3 SPP-001 BR-5).
   * @param links 협력사 품번
   */
  public static void shareItemsWithSuppliers(List<CMN_SupplierItem__c> links) {
    Set<Id> supplierIds = new Set<Id>();
    Set<Id> itemIds = new Set<Id>();
    for (CMN_SupplierItem__c l : links) {
      supplierIds.add(l.Supplier__c);
      itemIds.add(l.Item__c);
    }
    Map<Id, Id> groups = supplierGroups(supplierIds);
    if (groups.isEmpty()) {
      return;
    }
    Map<String, ShareRow> wanted = new Map<String, ShareRow>();
    for (CMN_SupplierItem__c l : links) {
      want(
        wanted,
        l.Item__c,
        groups.get(l.Supplier__c),
        'Read',
        CAUSE_SUPPLIER
      );
    }
    // 품번은 여러 협력사가 공급하므로 지우지 않고 더하기만 한다(협력사 품번은 삭제 금지)
    apply('CMN_Item__c', itemIds, wanted, new Set<String>());
  }

  // ------------------------------------------------------------------ 내부
  private class ShareRow {
    Id parentId;
    Id groupId;
    String access;
    String cause;
  }

  private static void want(
    Map<String, ShareRow> wanted,
    Id parentId,
    Id groupId,
    String access,
    String cause
  ) {
    if (groupId == null) {
      return;
    }
    ShareRow s = new ShareRow();
    s.parentId = parentId;
    s.groupId = groupId;
    s.access = access;
    s.cause = cause;
    wanted.put(parentId + '|' + groupId + '|' + cause, s);
  }

  /** 원하는 공유만 남긴다: 관리 사유(removeCauses)의 기존 행 중 원하지 않는 것은 지우고 없는 것은 만든다. */
  private static void apply(
    String objectName,
    Set<Id> parentIds,
    Map<String, ShareRow> wanted,
    Set<String> removeCauses
  ) {
    String shareObject = objectName.removeEnd('__c') + '__Share';
    Set<String> causes = new Set<String>(removeCauses);
    for (ShareRow s : wanted.values()) {
      causes.add(s.cause);
    }
    List<SObject> remove = new List<SObject>();
    Set<String> have = new Set<String>();
    if (!causes.isEmpty()) {
      for (
        SObject e : Database.queryWithBinds(
          'SELECT Id, ParentId, UserOrGroupId, RowCause FROM ' +
            String.escapeSingleQuotes(shareObject) +
            ' WHERE ParentId IN :ids AND RowCause IN :causes',
          new Map<String, Object>{ 'ids' => parentIds, 'causes' => causes },
          AccessLevel.SYSTEM_MODE
        )
      ) {
        String key =
          e.get('ParentId') +
          '|' +
          e.get('UserOrGroupId') +
          '|' +
          e.get('RowCause');
        if (wanted.containsKey(key)) {
          have.add(key);
        } else if (removeCauses.contains((String) e.get('RowCause'))) {
          remove.add(e);
        }
      }
    }
    List<SObject> add = new List<SObject>();
    Schema.SObjectType shareType = ((SObject) Type.forName(
          'Schema.' + shareObject
        )
        .newInstance())
      .getSObjectType();
    for (String key : wanted.keySet()) {
      if (have.contains(key)) {
        continue;
      }
      ShareRow s = wanted.get(key);
      SObject row = shareType.newSObject();
      row.put('ParentId', s.parentId);
      row.put('UserOrGroupId', s.groupId);
      row.put('AccessLevel', s.access);
      row.put('RowCause', s.cause);
      add.add(row);
    }
    // 공유 행은 시스템이 관리한다(사용자에게 공유 권한이 없어도 레코드 저장이 막히면 안 된다)
    CMN_ShareWriter.write(remove, add);
  }

  /** 협력사 Account → 포털 Manager 역할·하위 그룹(포털 사용자가 생겨 역할이 있을 때만). */
  private static Map<Id, Id> supplierGroups(Set<Id> accountIds) {
    Map<Id, Id> out = new Map<Id, Id>();
    if (accountIds.isEmpty()) {
      return out;
    }
    Map<Id, Id> accountByRole = new Map<Id, Id>();
    for (UserRole r : [
      SELECT Id, PortalAccountId
      FROM UserRole
      WHERE PortalAccountId IN :accountIds AND PortalRole = 'Manager'
      WITH SYSTEM_MODE
    ]) {
      accountByRole.put(r.Id, r.PortalAccountId);
    }
    if (accountByRole.isEmpty()) {
      return out;
    }
    for (Group g : [
      SELECT Id, RelatedId
      FROM Group
      WHERE
        RelatedId IN :accountByRole.keySet()
        AND Type = 'RoleAndSubordinates'
      WITH SYSTEM_MODE
    ]) {
      out.put(accountByRole.get(g.RelatedId), g.Id);
    }
    return out;
  }
}
