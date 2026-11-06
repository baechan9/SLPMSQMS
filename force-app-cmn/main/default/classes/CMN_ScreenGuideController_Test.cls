/**
 * @description 화면별 사용 가이드(CMN-00-UX-002): 레코드 페이지 화면 키·사용자 언어(AC-1), 언어 대체 en_US → ko(AC-2),
 * 미게시 제외·없음, 화면 키 형식·외부 키·중복, 권한(조회 PS 읽기, 관리 PS 편집).
 * 화면 키를 정하는 페이지 종류(레코드·목록·앱 페이지·홈)는 Jest에서 확인한다.
 * @group CMN-00-UX-002
 */
@IsTest
private class CMN_ScreenGuideController_Test {
  private static final String KEY = 'CMN_TestRecord__c.RECORD';

  @TestSetup
  static void setup() {
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User ko = CMN_TestDataFactory.newUser('sgko', 'Guide KO', profileId);
    ko.LanguageLocaleKey = 'ko';
    User zh = CMN_TestDataFactory.newUser('sgzh', 'Guide ZH', profileId);
    zh.LanguageLocaleKey = 'zh_CN';
    User adm = CMN_TestDataFactory.newUser('sgadm', 'Guide Admin', profileId);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ ko, zh, adm };
      Map<String, Id> ps = new Map<String, Id>();
      for (PermissionSet p : [
        SELECT Id, Name
        FROM PermissionSet
        WHERE Name IN ('CMN_PS_ScreenGuide_Read', 'CMN_PS_ScreenGuide_Admin')
      ]) {
        ps.put(p.Name, p.Id);
      }
      insert new List<PermissionSetAssignment>{
        new PermissionSetAssignment(
          AssigneeId = ko.Id,
          PermissionSetId = ps.get('CMN_PS_ScreenGuide_Read')
        ),
        new PermissionSetAssignment(
          AssigneeId = zh.Id,
          PermissionSetId = ps.get('CMN_PS_ScreenGuide_Read')
        ),
        new PermissionSetAssignment(
          AssigneeId = adm.Id,
          PermissionSetId = ps.get('CMN_PS_ScreenGuide_Read')
        ),
        new PermissionSetAssignment(
          AssigneeId = adm.Id,
          PermissionSetId = ps.get('CMN_PS_ScreenGuide_Admin')
        )
      };
    }
    insert new List<CMN_ScreenGuide__c>{
      guide(KEY, 'ko', true, '<p>KO body</p>'),
      guide(KEY, 'en_US', true, '<p>EN body</p>'),
      guide(KEY, 'zh_CN', false, '<p>ZH draft</p>'),
      guide('CMN_UnifiedSearch', 'ko', true, '<p>Search KO</p>')
    };
  }

  @IsTest
  static void test_AC01_recordPageGuideInUserLanguage() {
    // Given: 한국어 사용자, 레코드 페이지(주소에 객체 이름 없음 → 레코드 Id로 화면 키)
    Id recordId = CMN_TestRecord__c.SObjectType.getDescribe()
      .getKeyPrefix()
      .rightPad(15, '0');
    CMN_ScreenGuideController.Guide g;
    System.runAs(user('sgko')) {
      // When
      g = CMN_ScreenGuideController.getGuide(null, recordId);
    }
    // Then: 그 화면의 한국어 가이드, 대체 아님
    Assert.areEqual(KEY, g.pageKey);
    Assert.isTrue(g.found);
    Assert.areEqual('ko', g.language);
    Assert.isFalse(g.isFallback);
    Assert.areEqual('Guide ' + KEY + ' ko', g.title);
    Assert.areEqual('<p>KO body</p>', g.content);
    Assert.isNotNull(g.updatedAt);
    Assert.areEqual('https://video.example.com/' + KEY, g.videoUrl);
  }

  @IsTest
  static void test_AC02_fallsBackToEnglishThenKorean() {
    System.runAs(user('sgzh')) {
      // Given: 중국어 가이드는 미게시 → en_US
      CMN_ScreenGuideController.Guide g = CMN_ScreenGuideController.getGuide(
        KEY,
        null
      );
      Assert.areEqual('en_US', g.language);
      Assert.isTrue(g.isFallback);
      // 영어도 없으면 한국어
      CMN_ScreenGuideController.Guide search = CMN_ScreenGuideController.getGuide(
        'CMN_UnifiedSearch',
        null
      );
      Assert.areEqual('ko', search.language);
      Assert.isTrue(search.isFallback);
      // 가이드가 없는 화면
      CMN_ScreenGuideController.Guide none = CMN_ScreenGuideController.getGuide(
        'CMN_Item__c.LIST',
        null
      );
      Assert.isFalse(none.found);
      Assert.areEqual('CMN_Item__c.LIST', none.pageKey);
    }
  }

  @IsTest
  static void test_pageKeyFormatExternalKeyAndPermissions() {
    // 화면 키 형식 오류는 화면·저장 모두 거부
    String message;
    try {
      CMN_ScreenGuideController.getGuide('bad key!', null);
    } catch (AuraHandledException e) {
      message = e.getMessage();
    }
    Assert.areEqual(Label.CMN_Guide_InvalidPageKey, message);
    Database.SaveResult bad = Database.insert(
      guide('X.DETAIL', 'ko', true, 'x'),
      false
    );
    Assert.isFalse(bad.isSuccess());
    // 외부 키 = {PageKey}-{Language}, 같은 화면·언어 중복 거부
    Assert.areEqual(
      KEY + '-ko',
      [
        SELECT ExternalKey__c
        FROM CMN_ScreenGuide__c
        WHERE PageKey__c = :KEY AND Language__c = 'ko'
      ]
      .ExternalKey__c
    );
    Database.SaveResult dup = Database.insert(
      guide(' ' + KEY + ' ', 'ko', false, 'dup'),
      false
    );
    Assert.isFalse(dup.isSuccess());
    Assert.areEqual(
      StatusCode.DUPLICATE_VALUE,
      dup.getErrors()[0].getStatusCode()
    );
    // 조회 PS는 고칠 수 없고, 관리 PS는 고친다(개발 없이 관리자가 수정)
    CMN_ScreenGuide__c target = [
      SELECT Id
      FROM CMN_ScreenGuide__c
      WHERE PageKey__c = 'CMN_UnifiedSearch'
    ];
    target.Content__c = '<p>changed</p>';
    System.runAs(user('sgko')) {
      Assert.isFalse(
        Database.update(target, false, AccessLevel.USER_MODE).isSuccess()
      );
    }
    System.runAs(user('sgadm')) {
      Assert.isTrue(
        Database.update(target, false, AccessLevel.USER_MODE).isSuccess()
      );
    }
  }

  private static CMN_ScreenGuide__c guide(
    String pageKey,
    String lang,
    Boolean published,
    String body
  ) {
    return new CMN_ScreenGuide__c(
      Name = 'Guide ' + pageKey + ' ' + lang,
      PageKey__c = pageKey,
      Language__c = lang,
      IsPublished__c = published,
      Content__c = body,
      VideoUrl__c = 'https://video.example.com/' + pageKey
    );
  }

  private static User user(String alias) {
    return [SELECT Id FROM User WHERE Alias = :alias LIMIT 1];
  }
}
