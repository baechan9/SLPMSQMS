/**
 * @description 사용자 트리거: 부서·기본 공장 코드 검사(CMN-00-MDM-001), SSO 매칭 키 = 사번(CMN-00-TDO-002 BR-1).
 * 휴직 전환 대리인 지정 알림(CMN-00-APV-004 BR-6). HR 동기화(INT-002)·SSO 언어 갱신(I18N-001)도 이 핸들러를 거친다.
 * @group CMN-00-MDM-001
 */
public with sharing class CMN_UserTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_UserOrgService.validateCodes((List<User>) newRecords, null);
    CMN_SsoService.alignFederationId((List<User>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_UserOrgService.validateCodes((List<User>) newRecords, oldMap);
    CMN_SsoService.alignFederationId((List<User>) newRecords);
  }

  protected override void afterUpdate() {
    if (!isMigrationMode()) {
      // 휴직 전환 시 결재 대기가 있으면 부서장에게 대리인 지정 요청(CMN-00-APV-004 BR-6)
      CMN_DelegationService.notifyLeave((List<User>) newRecords, oldMap);
    }
  }
}
