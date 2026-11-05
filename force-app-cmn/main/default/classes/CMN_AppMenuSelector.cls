/**
 * @description 앱 메뉴 허브 조회(CMN-00-UX-007, A0 골격에서 시작). 메뉴 설정은 모든 사용자에게 같은 메타데이터라 시스템 모드로 읽고,
 * To-Do 배지는 사용자 권한(USER_MODE)으로 센다.
 * @group CMN-00-UX-007
 */
public with sharing class CMN_AppMenuSelector {
  /** 테스트에서 메타데이터 레코드 대신 쓰는 값 */
  @TestVisible
  private static List<CMN_AppMenu__mdt> menusOverride;
  @TestVisible
  private static List<CMN_AppMenuItem__mdt> itemsOverride;
  @TestVisible
  private static List<CMN_NumberingRule__mdt> rulesOverride;
  /** 테스트에서 현재 앱 판별 결과 대신 쓰는 값 */
  @TestVisible
  private static String appOverride;

  /**
   * @description 메뉴 1건.
   * @param menuKey 메뉴 키(DeveloperName)
   * @return 메뉴(없으면 null)
   */
  public static CMN_AppMenu__mdt menu(String menuKey) {
    for (CMN_AppMenu__mdt m : menusOverride ?? queryMenus(menuKey)) {
      if (m.DeveloperName == menuKey) {
        return m;
      }
    }
    return null;
  }

  /**
   * @description 활성 메뉴 전체(순서대로). 전체 메뉴 모드가 앱으로 거른다.
   * @return 메뉴
   */
  public static List<CMN_AppMenu__mdt> activeMenus() {
    List<CMN_AppMenu__mdt> out = new List<CMN_AppMenu__mdt>();
    for (CMN_AppMenu__mdt m : menusOverride ?? queryMenus(null)) {
      if (m.IsActive__c) {
        out.add(m);
      }
    }
    return out;
  }

  /**
   * @description 메뉴의 활성 기능 타일(순서대로).
   * @param menuKey 메뉴 키
   * @return 타일
   */
  public static List<CMN_AppMenuItem__mdt> items(String menuKey) {
    return items(new Set<String>{ menuKey });
  }

  /**
   * @description 여러 메뉴의 활성 기능 타일(메뉴 구분 없이 순서대로, 한 번에 조회).
   * @param menuKeys 메뉴 키
   * @return 타일
   */
  public static List<CMN_AppMenuItem__mdt> items(Set<String> menuKeys) {
    if (itemsOverride != null) {
      List<CMN_AppMenuItem__mdt> out = new List<CMN_AppMenuItem__mdt>();
      for (CMN_AppMenuItem__mdt i : itemsOverride) {
        if (menuKeys.contains(i.Menu__r?.DeveloperName) && i.IsActive__c) {
          out.add(i);
        }
      }
      return out;
    }
    return [
      SELECT
        DeveloperName,
        Menu__r.DeveloperName,
        Order__c,
        FeatureCode__c,
        TitleLabel__c,
        DescLabel__c,
        IconName__c,
        TargetType__c,
        Target__c,
        Bundle__c,
        IsActive__c,
        RequiredPermission__c,
        TodoSourceTypes__c,
        KeywordsLabel__c,
        ShowOnPhone__c
      FROM CMN_AppMenuItem__mdt
      WHERE Menu__r.DeveloperName IN :menuKeys AND IsActive__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Order__c ASC NULLS LAST, DeveloperName ASC
    ];
  }

  /**
   * @description 현재 사용자가 마지막으로 연 Lightning 앱(폼 팩터별). 앱을 바꾼 적이 없으면 null(프로필 기본 앱에 있음).
   * @param formFactor Large, Medium, Small
   * @return 앱 DeveloperName 또는 null
   */
  public static String currentAppName(String formFactor) {
    if (appOverride != null) {
      return appOverride;
    }
    // UserAppInfo·AppDefinition은 WITH SYSTEM_MODE 절을 지원하지 않는다. 자기 사용자 행과 앱 정의만 사용자 권한으로 읽는다
    List<UserAppInfo> info = [
      SELECT AppDefinitionId
      FROM UserAppInfo
      WHERE UserId = :UserInfo.getUserId() AND FormFactor = :formFactor
      WITH USER_MODE
      ORDER BY LastModifiedDate DESC
      LIMIT 1
    ];
    if (info.isEmpty()) {
      return null;
    }
    List<AppDefinition> apps = [
      SELECT DeveloperName
      FROM AppDefinition
      WHERE DurableId = :info[0].AppDefinitionId
      WITH USER_MODE
      LIMIT 1
    ];
    return apps.isEmpty() ? null : apps[0].DeveloperName;
  }

  /**
   * @description 내 열린 To-Do 수(SourceType별). 사용자 권한으로 센다.
   * @param overdueOnly true면 기한 경과(오늘 이전)만
   * @return SourceType → 건수
   */
  public static Map<String, Integer> openTodoCounts(Boolean overdueOnly) {
    Id me = UserInfo.getUserId();
    String open = CMN_TodoService.OPEN;
    List<AggregateResult> rows = overdueOnly
      ? [
          SELECT SourceType__c source, COUNT(Id) n
          FROM CMN_Todo__c
          WHERE Assignee__c = :me AND Status__c = :open AND DueDate__c < TODAY
          WITH USER_MODE
          GROUP BY SourceType__c
        ]
      : [
          SELECT SourceType__c source, COUNT(Id) n
          FROM CMN_Todo__c
          WHERE Assignee__c = :me AND Status__c = :open
          WITH USER_MODE
          GROUP BY SourceType__c
        ];
    Map<String, Integer> out = new Map<String, Integer>();
    for (AggregateResult r : rows) {
      out.put((String) r.get('source'), (Integer) r.get('n'));
    }
    return out;
  }

  /**
   * @description 채번 규칙(번호 접두어 → 객체·번호 필드).
   * @return 규칙
   */
  public static List<CMN_NumberingRule__mdt> numberingRules() {
    return rulesOverride ??
      [
        SELECT DeveloperName, ObjectApiName__c, Pattern__c, NumberField__c
        FROM CMN_NumberingRule__mdt
        WITH SYSTEM_MODE
      ];
  }

  /** menuKey가 있으면 그 메뉴만, 없으면 활성 메뉴 전체. */
  private static List<CMN_AppMenu__mdt> queryMenus(String menuKey) {
    if (menuKey != null) {
      return [
        SELECT
          DeveloperName,
          System__c,
          Order__c,
          TitleLabel__c,
          DescLabel__c,
          IconName__c,
          IsActive__c,
          Apps__c,
          PageTab__c
        FROM CMN_AppMenu__mdt
        WHERE DeveloperName = :menuKey
        WITH SYSTEM_MODE
        LIMIT 1
      ];
    }
    return [
      SELECT
        DeveloperName,
        System__c,
        Order__c,
        TitleLabel__c,
        DescLabel__c,
        IconName__c,
        IsActive__c,
        Apps__c,
        PageTab__c
      FROM CMN_AppMenu__mdt
      WHERE IsActive__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Order__c ASC NULLS LAST, DeveloperName ASC
    ];
  }
}
