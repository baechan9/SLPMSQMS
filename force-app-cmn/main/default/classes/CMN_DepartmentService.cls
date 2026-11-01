/**
 * @description 부서 규칙(CMN-00-MDM-001): 순환 참조 차단, 전체 경로(FullPath__c) 계산, 하위 경로 비동기 재계산.
 * @group CMN-00-MDM-001
 */
public with sharing class CMN_DepartmentService {
  /** 경로에 담는 최대 단계(BR-2). 더 깊으면 앞을 생략 표시로 줄인다. */
  public static final Integer MAX_LEVELS = 8;
  @TestVisible
  private static final String SEPARATOR = ' > ';
  @TestVisible
  private static final String ELLIPSIS = '…';

  /**
   * @description 저장 전: 순환 참조를 막고 자기 경로를 계산한다(before insert·update).
   * @param records 저장할 부서
   */
  public static void validateAndAssignPaths(List<CMN_Department__c> records) {
    Map<Id, CMN_Department__c> tree = CMN_DepartmentSelector.tree();
    // 저장 중인 값(이름·상위)을 트리에 겹쳐 본다
    Map<Id, Id> parentOf = new Map<Id, Id>();
    Map<Id, String> nameOf = new Map<Id, String>();
    for (CMN_Department__c d : tree.values()) {
      parentOf.put(d.Id, d.Parent__c);
      nameOf.put(d.Id, d.Name);
    }
    for (CMN_Department__c d : records) {
      if (d.Id != null) {
        parentOf.put(d.Id, d.Parent__c);
        nameOf.put(d.Id, d.Name);
      }
    }
    for (CMN_Department__c d : records) {
      if (d.Id != null && hasCycle(d.Id, parentOf)) {
        d.addError(CMN_Department__c.Parent__c, Label.CMN_Org_DepartmentCycle);
        continue;
      }
      d.FullPath__c = path(d.Name, d.Parent__c, parentOf, nameOf);
    }
  }

  /**
   * @description 저장 후: 이름이나 상위가 바뀐 부서의 하위 경로를 비동기로 다시 계산한다(AC-2).
   * @param records 갱신 후 부서
   * @param oldMap 갱신 전 부서
   */
  public static void refreshDescendantsAsync(
    List<CMN_Department__c> records,
    Map<Id, SObject> oldMap
  ) {
    Set<Id> moved = new Set<Id>();
    for (CMN_Department__c d : records) {
      CMN_Department__c old = (CMN_Department__c) oldMap.get(d.Id);
      if (d.Parent__c != old.Parent__c || d.Name != old.Name) {
        moved.add(d.Id);
      }
    }
    if (!moved.isEmpty()) {
      System.enqueueJob(new CMN_DepartmentPathJob(moved));
    }
  }

  /**
   * @description 주어진 부서들의 하위 전체 경로를 다시 계산해 바뀐 것만 돌려준다(CMN_DepartmentPathJob).
   * @param roots 이동·이름 변경된 부서
   * @return 경로가 바뀐 하위 부서(Id·FullPath__c만)
   */
  public static List<CMN_Department__c> recalculateDescendants(Set<Id> roots) {
    Map<Id, CMN_Department__c> tree = CMN_DepartmentSelector.tree();
    Map<Id, Id> parentOf = new Map<Id, Id>();
    Map<Id, String> nameOf = new Map<Id, String>();
    Map<Id, List<Id>> childrenOf = new Map<Id, List<Id>>();
    for (CMN_Department__c d : tree.values()) {
      parentOf.put(d.Id, d.Parent__c);
      nameOf.put(d.Id, d.Name);
      if (d.Parent__c != null) {
        if (!childrenOf.containsKey(d.Parent__c)) {
          childrenOf.put(d.Parent__c, new List<Id>());
        }
        childrenOf.get(d.Parent__c).add(d.Id);
      }
    }
    List<CMN_Department__c> changed = new List<CMN_Department__c>();
    Set<Id> seen = new Set<Id>();
    List<Id> queue = new List<Id>();
    for (Id r : roots) {
      queue.addAll(childrenOf.get(r) ?? new List<Id>());
    }
    while (!queue.isEmpty()) {
      Id id = queue.remove(queue.size() - 1);
      if (!seen.add(id)) {
        continue;
      }
      String p = path(nameOf.get(id), parentOf.get(id), parentOf, nameOf);
      if (p != tree.get(id).FullPath__c) {
        changed.add(new CMN_Department__c(Id = id, FullPath__c = p));
      }
      queue.addAll(childrenOf.get(id) ?? new List<Id>());
    }
    return changed;
  }

  // ------------------------------------------------------------------ 내부
  private static Boolean hasCycle(Id self, Map<Id, Id> parentOf) {
    Set<Id> visited = new Set<Id>();
    Id cur = parentOf.get(self);
    while (cur != null) {
      if (cur == self || !visited.add(cur)) {
        return true;
      }
      cur = parentOf.get(cur);
    }
    return false;
  }

  /** 뿌리 → 자신 순서 이름을 잇는다. MAX_LEVELS보다 깊으면 가까운 단계만 남기고 앞을 …로 표시. */
  private static String path(
    String name,
    Id parentId,
    Map<Id, Id> parentOf,
    Map<Id, String> nameOf
  ) {
    List<String> names = new List<String>{ name };
    Set<Id> visited = new Set<Id>();
    Id cur = parentId;
    Boolean truncated = false;
    while (cur != null && visited.add(cur)) {
      if (names.size() == MAX_LEVELS) {
        truncated = true;
        break;
      }
      names.add(nameOf.get(cur));
      cur = parentOf.get(cur);
    }
    List<String> ordered = new List<String>();
    if (truncated) {
      ordered.add(ELLIPSIS);
    }
    for (Integer i = names.size() - 1; i >= 0; i--) {
      ordered.add(names[i]);
    }
    return String.join(ordered, SEPARATOR).left(255);
  }
}
