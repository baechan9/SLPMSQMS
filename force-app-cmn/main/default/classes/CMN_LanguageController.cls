/**
 * @description cmnLanguageSwitcher 진입점(CMN-00-I18N-001 BR-4).
 * @group CMN-00-I18N-001
 */
public with sharing class CMN_LanguageController {
  /**
   * @description 스위처 상태.
   */
  public class State {
    @AuraEnabled
    public String current;
    @AuraEnabled
    public Boolean overridden;
    @AuraEnabled
    public List<String> languages;
  }

  /**
   * @description 현재 언어·직접 지정 여부·선택 가능한 언어.
   * @return 상태
   */
  @AuraEnabled
  public static State getState() {
    User u = [
      SELECT LanguageLocaleKey, LanguageOverride__c
      FROM User
      WHERE Id = :UserInfo.getUserId()
      WITH SYSTEM_MODE
    ];
    State s = new State();
    s.current = u.LanguageLocaleKey;
    s.overridden = u.LanguageOverride__c;
    s.languages = CMN_LanguageService.SUPPORTED;
    return s;
  }

  /**
   * @description 언어를 직접 고른다.
   * @param localeKey 지원 언어
   * @throws AuraHandledException 지원하지 않는 언어·저장 실패
   */
  @AuraEnabled
  public static void setLanguage(String localeKey) {
    try {
      CMN_LanguageService.chooseLanguage(localeKey);
    } catch (Exception e) {
      throw toAura(e, 'CMN_LanguageController.setLanguage');
    }
  }

  /**
   * @description 포털 언어 따르기로 돌린다.
   * @throws AuraHandledException 저장 실패
   */
  @AuraEnabled
  public static void followPortal() {
    try {
      CMN_LanguageService.followPortal();
    } catch (Exception e) {
      throw toAura(e, 'CMN_LanguageController.followPortal');
    }
  }

  /** 검증 오류는 라벨 그대로, 그 밖의 오류는 기록하고 공통 문구로(원문을 화면에 보내지 않는다). */
  @TestVisible
  private static AuraHandledException toAura(Exception e, String source) {
    if (e instanceof CMN_ValidationException) {
      return aura(e.getMessage());
    }
    CMN_Logger.error(source, e.getMessage(), UserInfo.getUserId(), e);
    return aura(Label.CMN_LanguageSwitcher_Error);
  }

  private static AuraHandledException aura(String message) {
    AuraHandledException e = new AuraHandledException(message);
    e.setMessage(message);
    return e;
  }
}
