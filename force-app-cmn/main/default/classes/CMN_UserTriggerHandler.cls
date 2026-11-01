/**
 * @description 사용자 트리거: 부서·기본 공장 코드 검사(CMN-00-MDM-001). HR 동기화(INT-002)·SSO 언어 갱신(I18N-001)도
 * 이 핸들러를 거친다.
 * @group CMN-00-MDM-001
 */
public with sharing class CMN_UserTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_UserOrgService.validateCodes((List<User>) newRecords, null);
  }

  protected override void beforeUpdate() {
    CMN_UserOrgService.validateCodes((List<User>) newRecords, oldMap);
  }
}
