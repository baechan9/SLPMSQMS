/**
 * @description 계층형 공통 코드 규칙(CMN-00-MDM-007).
 * - 단계 = 상위 단계 + 1, 그룹 최대 단계 이하(BR-2), 상위는 같은 그룹.
 * - 외부 키 = 그룹/상위 코드…/코드(경로 전체), 경로 = 이름 경로. 상위 이름·코드가 바뀌면 하위 전체를 다시 계산한다.
 * - 업무 레코드·하위 코드가 참조하는 코드는 삭제 금지(BR-1). 참조 객체는 Org의 하위 관계에서 찾는다(업무 객체가 늘어도 고칠 필요 없음).
 * @group CMN-00-MDM-007
 */
public with sharing class CMN_CodeService {
  @TestVisible
  private static final String KEY_SEPARATOR = '/';
  @TestVisible
  private static final String PATH_SEPARATOR = ' > ';
  private static Boolean cascading = false;

  /**
   * @description 저장 전: 단계·외부 키·경로 계산과 검증(before insert·update). 같은 저장 묶음의 상위도 반영한다.
   * @param codes 저장할 코드
   */
  public static void prepare(List<CMN_Code__c> codes) {
    Set<Id> groupIds = new Set<Id>();
    Set<Id> parentIds = new Set<Id>();
    Map<Id, CMN_Code__c> inBatch = new Map<Id, CMN_Code__c>();
    for (CMN_Code__c c : codes) {
      groupIds.add(c.CodeGroup__c);
      if (c.Parent__c != null) {
        parentIds.add(c.Parent__c);
      }
      if (c.Id != null) {
        inBatch.put(c.Id, c);
      }
    }
    Map<Id, CMN_CodeGroup__c> groups = CMN_CodeSelector.groupsById(groupIds);
    Map<Id, CMN_Code__c> parents = CMN_CodeSelector.codesById(parentIds);
    Set<Id> done = new Set<Id>();
    for (CMN_Code__c c : codes) {
      compute(c, groups, parents, inBatch, done);
    }
    CMN_KeyGuard.rejectDuplicates(
      codes,
      CMN_Code__c.ExternalKey__c,
      CMN_Code__c.Code__c,
      CMN_Code__c.ExternalKey__c,
      Label.CMN_Code_Duplicate
    );
  }

  /**
   * @description 저장 후: 외부 키나 경로가 바뀐 코드의 하위 전체를 다시 계산한다(하위의 before update가 prepare로 계산).
   * @param codes 갱신 후 코드
   * @param oldMap 갱신 전
   */
  public static void refreshDescendants(
    List<CMN_Code__c> codes,
    Map<Id, SObject> oldMap
  ) {
    if (cascading) {
      return; // 하위 갱신이 다시 하위를 갱신하지 않게(한 번에 전체를 넣는다)
    }
    Set<Id> changed = new Set<Id>();
    Set<Id> groupIds = new Set<Id>();
    for (CMN_Code__c c : codes) {
      CMN_Code__c old = (CMN_Code__c) oldMap.get(c.Id);
      if (c.ExternalKey__c != old.ExternalKey__c || c.Path__c != old.Path__c) {
        changed.add(c.Id);
        groupIds.add(c.CodeGroup__c);
      }
    }
    if (changed.isEmpty()) {
      return;
    }
    Map<Id, List<Id>> childrenOf = new Map<Id, List<Id>>();
    for (CMN_Code__c c : CMN_CodeSelector.codesOfGroups(groupIds)) {
      if (c.Parent__c != null) {
        if (!childrenOf.containsKey(c.Parent__c)) {
          childrenOf.put(c.Parent__c, new List<Id>());
        }
        childrenOf.get(c.Parent__c).add(c.Id);
      }
    }
    List<CMN_Code__c> descendants = new List<CMN_Code__c>();
    List<Id> queue = new List<Id>(changed);
    while (!queue.isEmpty()) {
      Id id = queue.remove(0);
      for (Id child : childrenOf.get(id) ?? new List<Id>()) {
        descendants.add(new CMN_Code__c(Id = child));
        queue.add(child);
      }
    }
    if (descendants.isEmpty()) {
      return;
    }
    cascading = true;
    try {
      Database.update(descendants, AccessLevel.SYSTEM_MODE);
    } finally {
      cascading = false;
    }
  }

  /**
   * @description BR-1: 하위 코드나 업무 레코드(사용자 정의 객체의 코드 Lookup)가 참조하면 삭제를 막는다.
   * @param codes Trigger.old
   */
  public static void preventDeleteIfReferenced(List<CMN_Code__c> codes) {
    Set<Id> ids = new Map<Id, CMN_Code__c>(codes).keySet();
    Set<Id> used = CMN_CodeSelector.withChildren(ids);
    for (
      Schema.ChildRelationship rel : CMN_Code__c.SObjectType.getDescribe(
          SObjectDescribeOptions.DEFERRED
        )
        .getChildRelationships()
    ) {
      String child = String.valueOf(rel.getChildSObject());
      if (
        rel.getChildSObject() == CMN_Code__c.SObjectType ||
        !child.endsWith('__c')
      ) {
        continue; // 자기 참조는 위에서, 표준·시스템 하위(이력·피드 등)는 업무 참조가 아니다
      }
      String field = String.escapeSingleQuotes(
        rel.getField().getDescribe().getName()
      );
      for (
        SObject r : Database.queryWithBinds(
          'SELECT ' +
            field +
            ' FROM ' +
            String.escapeSingleQuotes(child) +
            ' WHERE ' +
            field +
            ' IN :ids',
          new Map<String, Object>{ 'ids' => ids },
          AccessLevel.SYSTEM_MODE
        )
      ) {
        used.add((Id) r.get(field));
      }
    }
    for (CMN_Code__c c : codes) {
      if (used.contains(c.Id)) {
        c.addError(Label.CMN_Code_InUse);
      }
    }
  }

  // ------------------------------------------------------------------ 내부
  private static void compute(
    CMN_Code__c c,
    Map<Id, CMN_CodeGroup__c> groups,
    Map<Id, CMN_Code__c> parents,
    Map<Id, CMN_Code__c> inBatch,
    Set<Id> done
  ) {
    if (c.Id != null && done.contains(c.Id)) {
      return;
    }
    CMN_CodeGroup__c g = groups.get(c.CodeGroup__c);
    if (g == null || String.isBlank(c.Code__c)) {
      return;
    }
    c.Code__c = c.Code__c.trim();
    CMN_Code__c parent = inBatch.get(c.Parent__c) ?? parents.get(c.Parent__c);
    if (parent != null && inBatch.containsKey(parent.Id)) {
      compute(parent, groups, parents, inBatch, done); // 같은 묶음의 상위를 먼저
    }
    if (c.Parent__c != null && parent == null) {
      return;
    }
    if (parent != null && parent.CodeGroup__c != c.CodeGroup__c) {
      c.addError(CMN_Code__c.Parent__c, Label.CMN_Code_ParentOtherGroup);
      return;
    }
    c.Level__c = parent == null ? 1 : parent.Level__c + 1;
    if (c.Level__c > g.MaxLevel__c) {
      c.addError(
        CMN_Code__c.Parent__c,
        String.format(
          Label.CMN_Code_LevelExceeded,
          new List<Object>{ g.MaxLevel__c.intValue() }
        )
      );
      return;
    }
    c.ExternalKey__c =
      (parent == null ? g.GroupCode__c : parent.ExternalKey__c) +
      KEY_SEPARATOR +
      c.Code__c;
    c.Path__c = (parent == null
        ? c.Name
        : parent.Path__c + PATH_SEPARATOR + c.Name)
      .left(255);
    if (c.Id != null) {
      done.add(c.Id);
    }
  }
}
