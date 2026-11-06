/**
 * @description 화면 가이드 규칙(CMN-00-UX-002). 관리자가 화면 키·언어별로 가이드를 쓰고 게시한다.
 * - 화면 키 형식: {객체API}.RECORD, {객체API}.LIST, 앱 페이지(탭) API명, home. 영문·숫자·밑줄·점만 쓴다.
 * - 외부 키 `{PageKey}-{Language}`를 저장할 때마다 다시 만든다(같은 화면·언어 중복은 유일 키가 막는다).
 * @group CMN-00-UX-002
 */
public with sharing class CMN_ScreenGuideService {
  public static final Pattern PAGE_KEY = Pattern.compile(
    '^[A-Za-z][A-Za-z0-9_]{0,79}(\\.(RECORD|LIST))?$'
  );

  /**
   * @description 저장 전 정리: 화면 키 형식 확인, 외부 키 채움.
   * @param guides 저장할 가이드
   */
  public static void prepare(List<CMN_ScreenGuide__c> guides) {
    for (CMN_ScreenGuide__c g : guides) {
      String key = g.PageKey__c?.trim();
      if (String.isBlank(key) || !isPageKey(key)) {
        g.PageKey__c.addError(Label.CMN_Guide_InvalidPageKey);
        continue;
      }
      g.PageKey__c = key;
      g.ExternalKey__c = (key + '-' + g.Language__c).left(100);
    }
  }

  /**
   * @description 화면 키 형식인가.
   * @param key 화면 키
   * @return 형식에 맞으면 true
   */
  public static Boolean isPageKey(String key) {
    return key != null && key.length() <= 80 && PAGE_KEY.matcher(key).matches();
  }
}
