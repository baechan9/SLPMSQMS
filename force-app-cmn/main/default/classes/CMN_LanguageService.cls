/**
 * @description 사용자 표시 언어 규칙(CMN-00-I18N-001).
 * - 지원 언어: ko(기본), en_US·zh_CN(완전 번역), pl·es·pt_BR(확장 — 번역이 없으면 영문 대체).
 * - 포털(SSO) 언어는 로그인 때 적용하되 사용자가 직접 고르면(LanguageOverride__c) 유지한다(BR-2·BR-4).
 * @group CMN-00-I18N-001
 */
public with sharing class CMN_LanguageService {
  /** 화면에 내놓는 언어(순서 유지). */
  public static final List<String> SUPPORTED = new List<String>{
    'ko',
    'en_US',
    'zh_CN',
    'pl',
    'es',
    'pt_BR'
  };
  /** 포털 어설션 lang 값(앞 두 글자) → LanguageLocaleKey. */
  private static final Map<String, String> BY_PREFIX = new Map<String, String>{
    'ko' => 'ko',
    'en' => 'en_US',
    'zh' => 'zh_CN',
    'pl' => 'pl',
    'es' => 'es',
    'pt' => 'pt_BR'
  };

  /**
   * @description 포털 언어 값(ko, en, zh, en-US, zh_CN …)을 LanguageLocaleKey로 바꾼다.
   * @param portalLang 어설션 lang 값
   * @return LanguageLocaleKey, 모르는 값이면 null
   */
  public static String toLocaleKey(String portalLang) {
    if (String.isBlank(portalLang)) {
      return null;
    }
    String v = portalLang.trim().replace('-', '_');
    for (String s : SUPPORTED) {
      if (s.equalsIgnoreCase(v)) {
        return s;
      }
    }
    return BY_PREFIX.get(v.left(2).toLowerCase());
  }

  /**
   * @description SSO 로그인 때 포털 언어를 적용한다. 사용자가 직접 고른 경우(LanguageOverride__c)는 그대로 둔다(AC-1·AC-2).
   * @param userId 사용자
   * @param portalLang 포털 언어 값
   * @return 언어를 바꿨으면 true
   */
  public static Boolean applyPortalLanguage(Id userId, String portalLang) {
    String key = toLocaleKey(portalLang);
    if (key == null) {
      return false;
    }
    User u = [
      SELECT Id, LanguageLocaleKey, LanguageOverride__c
      FROM User
      WHERE Id = :userId
      WITH SYSTEM_MODE
    ];
    if (u.LanguageOverride__c || u.LanguageLocaleKey == key) {
      return false;
    }
    update as system new User(Id = u.Id, LanguageLocaleKey = key);
    return true;
  }

  /**
   * @description 사용자가 스위처로 언어를 고른다(직접 지정 표시).
   * @param localeKey 지원 언어
   * @throws CMN_ValidationException 지원하지 않는 언어
   */
  public static void chooseLanguage(String localeKey) {
    if (!SUPPORTED.contains(localeKey)) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    // 자기 사용자 레코드의 개인 설정만 바꾼다. 직접 지정 필드는 사용자 FLS가 읽기라 시스템 모드
    update as system new User(
      Id = UserInfo.getUserId(),
      LanguageLocaleKey = localeKey,
      LanguageOverride__c = true
    );
  }

  /**
   * @description 포털 언어 따르기로 돌린다(다음 로그인부터 포털 언어).
   */
  public static void followPortal() {
    update as system new User(
      Id = UserInfo.getUserId(),
      LanguageOverride__c = false
    );
  }
}
