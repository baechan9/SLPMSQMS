/**
 * @description SAML JIT 핸들러(CMN-00-I18N-001 BR-2). 포털 어설션 속성 lang으로 표시 언어만 갱신한다.
 * 사용자는 만들지 않는다 — 사용자 생성은 HR 연계(CMN-00-INT-002)만 한다.
 * @group CMN-00-I18N-001
 */
public with sharing class CMN_SamlJitHandler implements Auth.SamlJitHandler {
  @TestVisible
  private static final String LANG_ATTRIBUTE = 'lang';

  /**
   * @description 새 사용자 생성 요청은 거부한다.
   * @throws CMN_Exception 항상
   */
  public User createUser(
    Id samlSsoProviderId,
    Id communityId,
    Id portalId,
    String federationIdentifier,
    Map<String, String> attributes,
    String assertion
  ) {
    throw new CMN_Exception(Label.CMN_I18n_JitNoUserCreation);
  }

  /**
   * @description 로그인 사용자 언어를 포털 언어로 맞춘다(직접 지정한 사용자는 제외).
   */
  public void updateUser(
    Id userId,
    Id samlSsoProviderId,
    Id communityId,
    Id portalId,
    String federationIdentifier,
    Map<String, String> attributes,
    String assertion
  ) {
    CMN_LanguageService.applyPortalLanguage(
      userId,
      attributes?.get(LANG_ATTRIBUTE)
    );
  }
}
