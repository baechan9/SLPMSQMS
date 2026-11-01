/**
 * @description 기능 스위치(BR-6). 키 = CMN_FeatureSwitch__mdt DeveloperName(예: QMS_AI_RCA).
 *              IsOn__c가 true이고 RequiredPermissionSet__c가 비었거나 사용자가 그 Permission Set을 가질 때만 켜짐.
 *              미등록 키는 예외 없이 false(AC-4).
 * @group CMN-00-ARC-002
 */
public with sharing class CMN_FeatureSwitch {
  @TestVisible
  private static Map<String, CMN_FeatureSwitch__mdt> overrides = new Map<String, CMN_FeatureSwitch__mdt>();
  @TestVisible
  private static Set<String> userPermissionSets;

  /**
   * @description 기능이 켜져 있는지.
   * @param key 스위치 키(DeveloperName)
   * @return 켜져 있으면 true, 미등록·꺼짐·권한 없음이면 false
   */
  public static Boolean isOn(String key) {
    if (String.isBlank(key)) {
      return false;
    }
    CMN_FeatureSwitch__mdt s;
    if (overrides.containsKey(key)) {
      s = overrides.get(key);
    } else {
      try {
        s = CMN_FeatureSwitch__mdt.getInstance(key);
      } catch (Exception e) {
        // DeveloperName으로 쓸 수 없는 문자가 든 키도 미등록과 같게 본다
        return false;
      }
    }
    if (s == null || !s.IsOn__c) {
      return false;
    }
    return String.isBlank(s.RequiredPermissionSet__c) ||
      permissionSets().contains(s.RequiredPermissionSet__c);
  }

  /**
   * 사용자가 직접 또는 Permission Set Group으로 가진 Permission Set 이름. 트랜잭션당 한 번 조회한다.
   */
  private static Set<String> permissionSets() {
    if (userPermissionSets != null) {
      return userPermissionSets;
    }
    userPermissionSets = new Set<String>();
    Set<Id> groupIds = new Set<Id>();
    for (PermissionSetAssignment a : [
      SELECT PermissionSet.Name, PermissionSetGroupId
      FROM PermissionSetAssignment
      WHERE AssigneeId = :UserInfo.getUserId()
      WITH SYSTEM_MODE
    ]) {
      userPermissionSets.add(a.PermissionSet.Name);
      if (a.PermissionSetGroupId != null) {
        groupIds.add(a.PermissionSetGroupId);
      }
    }
    if (!groupIds.isEmpty()) {
      for (PermissionSetGroupComponent c : [
        SELECT PermissionSet.Name
        FROM PermissionSetGroupComponent
        WHERE PermissionSetGroupId IN :groupIds
        WITH SYSTEM_MODE
      ]) {
        userPermissionSets.add(c.PermissionSet.Name);
      }
    }
    return userPermissionSets;
  }
}
