/**
 * @description 공장 공개 그룹과 구성원(CMN-00-SEC-002). 공장마다 읽기·편집 그룹 2개(CMN_GRP_PLANT_{코드}_R/_E)를 두고
 * 사용자별 공장 접근(CMN_UserPlantAccess__c)에 맞춰 구성원을 맞춘다. 그룹·구성원은 설정 객체라 업무 DML과 같은 트랜잭션에
 * 섞을 수 없어(Mixed DML) CMN_PlantGroupJob·CMN_SharingRecalcBatch에서 부른다.
 * @group CMN-00-SEC-002
 */
public with sharing class CMN_PlantGroupService {
  public static final String READ = 'Read';
  public static final String EDIT = 'Edit';
  private static final String PREFIX = 'CMN_GRP_PLANT_';
  /** LIKE 패턴(밑줄 이스케이프는 SOQL에서 일치하지 않아 쓰지 않는다 — 밑줄 와일드카드도 자기 자신과 맞는다) */
  @TestVisible
  private static final String GROUP_PATTERN = PREFIX + '%';

  /**
   * @description 공장 그룹 DeveloperName.
   * @param plantCode 공장 코드
   * @param level Read 또는 Edit
   * @return 예: CMN_GRP_PLANT_KR01_R
   */
  public static String groupName(String plantCode, String level) {
    return PREFIX +
      plantCode.toUpperCase().replaceAll('[^A-Z0-9]', '_') +
      (level == EDIT ? '_E' : '_R');
  }

  /**
   * @description 공장별 그룹 Id(없는 그룹은 빠진다).
   * @param plantIds 공장 Id
   * @return 공장 Id → (Read·Edit → 그룹 Id)
   */
  public static Map<Id, Map<String, Id>> groupIds(Set<Id> plantIds) {
    Map<Id, Map<String, Id>> out = new Map<Id, Map<String, Id>>();
    if (plantIds.isEmpty()) {
      return out;
    }
    Map<String, Id> plantByGroup = new Map<String, Id>();
    Map<String, String> levelByGroup = new Map<String, String>();
    Map<Id, String> codes = CMN_PlantService.plantCodes(plantIds);
    for (Id plantId : codes.keySet()) {
      for (String level : new List<String>{ READ, EDIT }) {
        String name = groupName(codes.get(plantId), level);
        plantByGroup.put(name, plantId);
        levelByGroup.put(name, level);
      }
    }
    for (Group g : [
      SELECT Id, DeveloperName
      FROM Group
      WHERE DeveloperName IN :plantByGroup.keySet()
      WITH SYSTEM_MODE
    ]) {
      Id plantId = plantByGroup.get(g.DeveloperName);
      if (!out.containsKey(plantId)) {
        out.put(plantId, new Map<String, Id>());
      }
      out.get(plantId).put(levelByGroup.get(g.DeveloperName), g.Id);
    }
    return out;
  }

  /**
   * @description 없는 공장 그룹을 만든다(설정 DML).
   * @param plantIds 공장 Id
   */
  public static void ensureGroups(Set<Id> plantIds) {
    Map<Id, Map<String, Id>> existing = groupIds(plantIds);
    List<Group> missing = new List<Group>();
    for (
      CMN_Plant__c p : CMN_PlantSelector.plants(new Set<String>(), plantIds)
    ) {
      for (String level : new List<String>{ READ, EDIT }) {
        if (existing.get(p.Id)?.get(level) == null) {
          missing.add(
            new Group(
              Name = ('CMN Plant ' + p.PlantCode__c + ' ' + level).left(40),
              DeveloperName = groupName(p.PlantCode__c, level),
              Type = 'Regular',
              DoesIncludeBosses = false
            )
          );
        }
      }
    }
    if (!missing.isEmpty()) {
      Database.insert(missing, AccessLevel.SYSTEM_MODE);
    }
  }

  /**
   * @description 사용자들의 공장 그룹 구성원을 공장 접근과 같게 맞춘다(BR-2). 편집 수준은 편집 그룹만.
   * @param userIds 사용자
   */
  public static void syncMembers(Set<Id> userIds) {
    if (userIds.isEmpty()) {
      return;
    }
    List<CMN_UserPlantAccess__c> accesses = [
      SELECT User__c, Plant__c, AccessLevel__c
      FROM CMN_UserPlantAccess__c
      WHERE User__c IN :userIds
      WITH SYSTEM_MODE
    ];
    Set<Id> plantIds = new Set<Id>();
    for (CMN_UserPlantAccess__c a : accesses) {
      plantIds.add(a.Plant__c);
    }
    ensureGroups(plantIds);
    Map<Id, Map<String, Id>> groups = groupIds(plantIds);
    Set<String> wanted = new Set<String>();
    for (CMN_UserPlantAccess__c a : accesses) {
      Id g = groups.get(a.Plant__c)
        ?.get(a.AccessLevel__c == EDIT ? EDIT : READ);
      if (g != null) {
        wanted.add(a.User__c + '|' + g);
      }
    }
    List<GroupMember> remove = new List<GroupMember>();
    Set<String> have = new Set<String>();
    for (GroupMember m : [
      SELECT Id, UserOrGroupId, GroupId
      FROM GroupMember
      WHERE
        UserOrGroupId IN :userIds
        AND Group.DeveloperName LIKE :GROUP_PATTERN
      WITH SYSTEM_MODE
    ]) {
      String key = m.UserOrGroupId + '|' + m.GroupId;
      if (wanted.contains(key)) {
        have.add(key);
      } else {
        remove.add(m);
      }
    }
    List<GroupMember> add = new List<GroupMember>();
    for (String key : wanted) {
      if (!have.contains(key)) {
        add.add(
          new GroupMember(
            UserOrGroupId = (Id) key.substringBefore('|'),
            GroupId = (Id) key.substringAfter('|')
          )
        );
      }
    }
    if (!remove.isEmpty()) {
      Database.delete(remove, AccessLevel.SYSTEM_MODE);
    }
    if (!add.isEmpty()) {
      Database.insert(add, AccessLevel.SYSTEM_MODE);
    }
  }

  /**
   * @description 그룹·구성원 맞춤 작업을 넣는다(업무 트랜잭션에서는 설정 DML을 할 수 없다). 한도가 차면 기록만 남긴다.
   * @param plantIds 그룹을 보장할 공장
   * @param userIds 구성원을 맞출 사용자
   */
  public static void enqueue(Set<Id> plantIds, Set<Id> userIds) {
    if (plantIds.isEmpty() && userIds.isEmpty()) {
      return;
    }
    if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
      System.enqueueJob(new CMN_PlantGroupJob(plantIds, userIds));
    } else {
      CMN_Logger.warn(
        'CMN_PlantGroupService.enqueue',
        'Queueable limit reached; run CMN_SharingRecalcBatch to rebuild plant groups',
        null
      );
    }
  }
}
