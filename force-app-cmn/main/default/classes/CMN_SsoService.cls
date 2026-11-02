/**
 * @description 포털 SSO 사용자 매칭 규칙(CMN-00-TDO-002 BR-1). SAML 어설션 NameID = User.FederationIdentifier = 사번.
 * 사번(EmployeeNo__c)이 있는 사용자는 FederationIdentifier를 사번과 같게 맞춘다(HR 연계·수동 생성·데모 어디서 만들어도 같다).
 * 사번이 없는 사용자(비상용 관리자·통합 사용자·포털 사용자)는 건드리지 않는다.
 * @group CMN-00-TDO-002
 */
public with sharing class CMN_SsoService {
  /**
   * @description 저장 전 FederationIdentifier를 사번으로 맞춘다.
   * @param users 저장할 사용자
   */
  public static void alignFederationId(List<User> users) {
    for (User u : users) {
      if (
        String.isNotBlank(u.EmployeeNo__c) &&
        u.FederationIdentifier != u.EmployeeNo__c
      ) {
        u.FederationIdentifier = u.EmployeeNo__c;
      }
    }
  }
}
