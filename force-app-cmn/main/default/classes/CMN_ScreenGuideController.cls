/**
 * @description 화면 가이드 조회(CMN-00-UX-002, cmnScreenGuide). 현재 화면 키의 게시된 가이드를
 * 사용자 언어 → en_US → ko 순으로 찾는다(BR-2). 레코드 페이지에서 객체를 모르면 레코드 Id로 정한다.
 * @group CMN-00-UX-002
 */
public with sharing class CMN_ScreenGuideController {
  public static final String SUFFIX_RECORD = '.RECORD';
  private static final String FALLBACK_EN = 'en_US';
  private static final String FALLBACK_KO = 'ko';

  /**
   * @description 화면에 보일 가이드.
   */
  public class Guide {
    @AuraEnabled
    public String pageKey;
    @AuraEnabled
    public Boolean found = false;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String content;
    @AuraEnabled
    public String language;
    @AuraEnabled
    public Boolean isFallback = false;
    @AuraEnabled
    public String videoUrl;
    @AuraEnabled
    public String standardDocUrl;
    @AuraEnabled
    public Datetime updatedAt;
  }

  /**
   * @description 현재 화면의 가이드. 화면 키가 없고 레코드 Id만 있으면 {객체API}.RECORD로 찾는다.
   * @param pageKey 화면 키(예: QMS_NCR__c.RECORD)
   * @param recordId 레코드 페이지의 레코드 Id(선택)
   * @return 가이드(found = false면 이 화면 가이드 없음)
   * @throws AuraHandledException 화면 키 형식 오류(라벨 문구)
   */
  @AuraEnabled(cacheable=true)
  public static Guide getGuide(String pageKey, Id recordId) {
    try {
      String key = String.isNotBlank(pageKey)
        ? pageKey.trim()
        : (recordId == null
            ? null
            : String.valueOf(recordId.getSObjectType()) + SUFFIX_RECORD);
      if (!CMN_ScreenGuideService.isPageKey(key)) {
        throw new CMN_ValidationException(Label.CMN_Guide_InvalidPageKey);
      }
      Guide g = new Guide();
      g.pageKey = key;
      String userLang = UserInfo.getLanguage();
      List<String> languages = new List<String>{ userLang };
      for (String fallback : new List<String>{ FALLBACK_EN, FALLBACK_KO }) {
        if (!languages.contains(fallback)) {
          languages.add(fallback);
        }
      }
      Map<String, CMN_ScreenGuide__c> byLang = new Map<String, CMN_ScreenGuide__c>();
      for (CMN_ScreenGuide__c r : [
        SELECT
          Name,
          Language__c,
          Content__c,
          VideoUrl__c,
          StandardDocUrl__c,
          LastModifiedDate
        FROM CMN_ScreenGuide__c
        WHERE
          PageKey__c = :key
          AND IsPublished__c = TRUE
          AND Language__c IN :languages
        WITH USER_MODE
      ]) {
        byLang.put(r.Language__c, r);
      }
      for (String lang : languages) {
        CMN_ScreenGuide__c r = byLang.get(lang);
        if (r == null) {
          continue;
        }
        g.found = true;
        g.title = r.Name;
        g.content = r.Content__c;
        g.language = lang;
        g.isFallback = lang != userLang;
        g.videoUrl = r.VideoUrl__c;
        g.standardDocUrl = r.StandardDocUrl__c;
        g.updatedAt = r.LastModifiedDate;
        break;
      }
      return g;
    } catch (Exception e) {
      String message = e.getMessage();
      if (!(e instanceof CMN_ValidationException)) {
        CMN_Logger.error(
          'CMN_ScreenGuideController.getGuide',
          message,
          recordId,
          e
        );
        message = Label.CMN_Common_UnexpectedError;
      }
      AuraHandledException aura = new AuraHandledException(message);
      aura.setMessage(message);
      throw aura;
    }
  }
}
