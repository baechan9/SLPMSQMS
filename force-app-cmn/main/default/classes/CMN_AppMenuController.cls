/**
 * @description 앱 메뉴 허브 화면(CMN-00-UX-007, A0 골격에서 시작).
 * - 메뉴별 모드(getMenu): 메뉴 1개의 기능 타일.
 * - 전체 메뉴 모드(getHub): 현재 앱에 속한 메뉴 그룹 전부(BR-3), 권한 필터(BR-4), 미결 배지(BR-5), 휴대폰 타일(BR-8).
 * - 업무 번호 바로가기(findRecord): 채번 규칙 접두어로 객체를 찾아 사용자 권한으로 조회(BR-6).
 * 읽을 수 없는 객체 타일은 빼고, 화면이 아직 없는 기능은 '준비 중'(1차 화면 묶음)으로 보낸다.
 * @group CMN-00-UX-007
 */
public with sharing class CMN_AppMenuController {
  public static final String TARGET_OBJECT = 'OBJECT';
  public static final String TARGET_PAGE = 'PAGE';
  /** 앱을 판별할 수 없을 때(앱을 바꾼 적 없음) = 사내 프로필 기본 앱 */
  public static final String DEFAULT_APP = 'SL_QMS';
  /** TodoSourceTypes__c 값: 내 열린 To-Do 전체 */
  public static final String ALL_SOURCES = '*';
  public static final String FORM_FACTOR_SMALL = 'Small';
  private static final Set<String> FORM_FACTORS = new Set<String>{
    'Large',
    'Medium',
    FORM_FACTOR_SMALL
  };
  private static final Pattern KEY_PATTERN = Pattern.compile(
    '^[A-Za-z][A-Za-z0-9_]{1,39}$'
  );
  private static final Pattern APP_PATTERN = Pattern.compile(
    '^[A-Za-z][A-Za-z0-9_]{1,79}$'
  );
  private static final Pattern RECORD_NO_PATTERN = Pattern.compile(
    '^[A-Z0-9][A-Z0-9_-]{1,79}$'
  );
  private static final String DEFAULT_NUMBER_FIELD = 'RecordNo__c';

  /** @description 전체 메뉴 허브. */
  public class HubView {
    @AuraEnabled
    public String appName;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public List<MenuView> groups = new List<MenuView>();
    /** 업무 번호 접두어(예: NCR-). 화면이 Enter 때 번호 조회를 할지 고른다 */
    @AuraEnabled
    public List<String> numberPrefixes = new List<String>();
  }

  /** @description 메뉴(그룹) 머리글과 타일. */
  public class MenuView {
    @AuraEnabled
    public String menuKey;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public String iconName;
    /** 그룹 전용 허브 탭(메뉴 열기 대상) */
    @AuraEnabled
    public String pageTab;
    @AuraEnabled
    public Integer readyCount = 0;
    @AuraEnabled
    public List<ItemView> items = new List<ItemView>();
  }

  /** @description 기능 타일 하나. */
  public class ItemView {
    @AuraEnabled
    public String key;
    @AuraEnabled
    public String featureCode;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public String iconName;
    /** OBJECT·PAGE면 열 수 있고, 아니면 준비 중 */
    @AuraEnabled
    public String targetType;
    @AuraEnabled
    public String target;
    @AuraEnabled
    public Boolean ready = false;
    @AuraEnabled
    public String bundle;
    /** 검색 동의어(쉼표, 사용자 언어) */
    @AuraEnabled
    public String keywords;
    @AuraEnabled
    public Integer pendingCount = 0;
    @AuraEnabled
    public Integer overdueCount = 0;
  }

  /** @description 업무 번호 바로가기 결과. 없음과 권한 없음을 구분하지 않는다. */
  public class FindResult {
    @AuraEnabled
    public Boolean found = false;
    @AuraEnabled
    public Id recordId;
    @AuraEnabled
    public String objectApiName;
    @AuraEnabled
    public String message;
  }

  /**
   * @description 메뉴별 허브 내용(메뉴별 모드).
   * @param menuKey 메뉴 키(CMN_AppMenu__mdt DeveloperName, 예: QMS_03)
   * @return 메뉴
   * @throws AuraHandledException 메뉴 키 형식 오류, 없거나 비활성 메뉴
   */
  @AuraEnabled
  public static MenuView getMenu(String menuKey) {
    try {
      if (String.isBlank(menuKey) || !KEY_PATTERN.matcher(menuKey).matches()) {
        throw new CMN_ValidationException(Label.CMN_AppMenu_NotFound);
      }
      CMN_AppMenu__mdt menu = CMN_AppMenuSelector.menu(menuKey);
      if (menu == null || !menu.IsActive__c) {
        throw new CMN_ValidationException(Label.CMN_AppMenu_NotFound);
      }
      List<CMN_AppMenuItem__mdt> rows = CMN_AppMenuSelector.items(menuKey);
      return toMenuView(menu, rows, new Badges(rows), false);
    } catch (Exception e) {
      throw toAura(e, 'getMenu');
    }
  }

  /**
   * @description 전체 메뉴 허브(UX-007 BR-3). 현재 앱이 Apps__c에 들어 있는 그룹을 순서대로 돌려준다.
   * @param appName 페이지가 지정한 앱(비우면 사용자의 현재 앱, 그것도 없으면 SL_QMS)
   * @param formFactor 화면 크기(Large, Medium, Small). Small이면 휴대폰 표시 타일만
   * @return 허브
   * @throws AuraHandledException 예상하지 못한 오류
   */
  @AuraEnabled
  public static HubView getHub(String appName, String formFactor) {
    try {
      String ff = FORM_FACTORS.contains(formFactor) ? formFactor : 'Large';
      String app = String.isNotBlank(appName) &&
        APP_PATTERN.matcher(appName).matches()
        ? appName
        : (CMN_AppMenuSelector.currentAppName(ff) ?? DEFAULT_APP);
      HubView hub = new HubView();
      hub.appName = app;
      hub.title = Label.CMN_AppMenu_HubTitle;
      hub.description = Label.CMN_AppMenu_HubDesc;
      List<CMN_AppMenu__mdt> menus = new List<CMN_AppMenu__mdt>();
      for (CMN_AppMenu__mdt m : CMN_AppMenuSelector.activeMenus()) {
        if (splitSet(m.Apps__c).contains(app)) {
          menus.add(m);
        }
      }
      Map<String, List<CMN_AppMenuItem__mdt>> byMenu = new Map<String, List<CMN_AppMenuItem__mdt>>();
      List<CMN_AppMenuItem__mdt> rows = new List<CMN_AppMenuItem__mdt>();
      if (!menus.isEmpty()) {
        Set<String> keys = new Set<String>();
        for (CMN_AppMenu__mdt m : menus) {
          keys.add(m.DeveloperName);
          byMenu.put(m.DeveloperName, new List<CMN_AppMenuItem__mdt>());
        }
        rows = CMN_AppMenuSelector.items(keys);
        for (CMN_AppMenuItem__mdt i : rows) {
          byMenu.get(i.Menu__r.DeveloperName).add(i);
        }
      }
      Badges badges = new Badges(rows);
      Boolean phone = ff == FORM_FACTOR_SMALL;
      for (CMN_AppMenu__mdt m : menus) {
        MenuView section = toMenuView(
          m,
          byMenu.get(m.DeveloperName),
          badges,
          phone
        );
        // BR-4: 보이는 타일이 없는 그룹은 숨긴다
        if (!section.items.isEmpty()) {
          hub.groups.add(section);
        }
      }
      for (CMN_NumberingRule__mdt r : CMN_AppMenuSelector.numberingRules()) {
        String prefix = prefixOf(r.Pattern__c);
        if (prefix != null && !hub.numberPrefixes.contains(prefix)) {
          hub.numberPrefixes.add(prefix);
        }
      }
      return hub;
    } catch (Exception e) {
      throw toAura(e, 'getHub');
    }
  }

  /**
   * @description 업무 번호로 레코드 찾기(UX-007 BR-6). 접두어가 가장 길게 맞는 채번 규칙의 객체·번호 필드를 사용자 권한으로 조회한다.
   * 없거나 권한이 없으면 같은 '찾을 수 없음'을 돌려준다(존재 여부를 알려주지 않는다).
   * @param recordNo 업무 번호(예: NCR-KR01-2027-000123)
   * @return 결과
   * @throws AuraHandledException 예상하지 못한 오류
   */
  @AuraEnabled
  public static FindResult findRecord(String recordNo) {
    FindResult result = new FindResult();
    result.message = Label.CMN_AppMenu_RecordNotFound;
    try {
      String no = recordNo?.trim()?.toUpperCase();
      if (String.isBlank(no) || !RECORD_NO_PATTERN.matcher(no).matches()) {
        return result;
      }
      CMN_NumberingRule__mdt rule = ruleFor(no);
      Schema.DescribeSObjectResult d = rule == null
        ? null
        : describe(rule.ObjectApiName__c);
      if (d == null || !d.isAccessible()) {
        return result;
      }
      Schema.SObjectField field = d.fields.getMap()
        .get(rule.NumberField__c ?? DEFAULT_NUMBER_FIELD);
      Schema.DescribeFieldResult fd = field?.getDescribe();
      if (fd == null || !fd.isAccessible() || !fd.isFilterable()) {
        return result;
      }
      List<SObject> rows = Database.queryWithBinds(
        'SELECT Id FROM ' +
          String.escapeSingleQuotes(d.getName()) +
          ' WHERE ' +
          String.escapeSingleQuotes(fd.getName()) +
          ' = :no LIMIT 2',
        new Map<String, Object>{ 'no' => no },
        AccessLevel.USER_MODE
      );
      if (rows.size() == 1) {
        result.found = true;
        result.recordId = rows[0].Id;
        result.objectApiName = d.getName();
        result.message = null;
      }
      return result;
    } catch (QueryException e) {
      // 객체·필드 권한 없음: 찾을 수 없음과 같게 답한다
      return result;
    } catch (Exception e) {
      throw toAura(e, 'findRecord');
    }
  }

  // ------------------------------------------------------------------ 내부
  /** 타일이 셀 To-Do 수. 배지가 필요한 타일이 있을 때만 2회(전체, 기한 경과) 조회한다(BR-5). */
  private class Badges {
    Map<String, Integer> open = new Map<String, Integer>();
    Map<String, Integer> overdue = new Map<String, Integer>();

    Badges(List<CMN_AppMenuItem__mdt> rows) {
      Boolean needed = false;
      for (CMN_AppMenuItem__mdt i : rows) {
        needed = needed || String.isNotBlank(i.TodoSourceTypes__c);
      }
      if (!needed) {
        return;
      }
      try {
        open = CMN_AppMenuSelector.openTodoCounts(false);
        overdue = CMN_AppMenuSelector.openTodoCounts(true);
      } catch (QueryException e) {
        // To-Do 읽기 권한이 없으면 배지 없이 보인다
        open = new Map<String, Integer>();
        overdue = new Map<String, Integer>();
      }
    }

    Integer count(Map<String, Integer> counts, String sources) {
      Set<String> wanted = splitSet(sources);
      Integer n = 0;
      for (String source : counts.keySet()) {
        if (wanted.contains(ALL_SOURCES) || wanted.contains(source)) {
          n += counts.get(source);
        }
      }
      return n;
    }
  }

  private static MenuView toMenuView(
    CMN_AppMenu__mdt menu,
    List<CMN_AppMenuItem__mdt> rows,
    Badges badges,
    Boolean phoneOnly
  ) {
    MenuView view = new MenuView();
    view.menuKey = menu.DeveloperName;
    view.title = labelText(menu.TitleLabel__c) ?? menu.DeveloperName;
    view.description = labelText(menu.DescLabel__c);
    view.iconName = menu.IconName__c;
    view.pageTab = menu.PageTab__c;
    for (CMN_AppMenuItem__mdt i : rows) {
      if (phoneOnly && i.ShowOnPhone__c != true) {
        continue;
      }
      ItemView item = toView(i);
      if (item == null) {
        continue;
      }
      if (String.isNotBlank(i.TodoSourceTypes__c)) {
        item.pendingCount = badges.count(badges.open, i.TodoSourceTypes__c);
        item.overdueCount = badges.count(badges.overdue, i.TodoSourceTypes__c);
      }
      view.items.add(item);
      view.readyCount += item.ready ? 1 : 0;
    }
    return view;
  }

  /** 읽을 수 없거나 배포되지 않은 객체 타일, 권한 없는 페이지 타일은 null(숨김). */
  private static ItemView toView(CMN_AppMenuItem__mdt i) {
    if (
      i.TargetType__c != TARGET_OBJECT &&
      String.isNotBlank(i.RequiredPermission__c) &&
      !hasPermission(i.RequiredPermission__c)
    ) {
      return null;
    }
    ItemView v = new ItemView();
    v.key = i.DeveloperName;
    v.featureCode = i.FeatureCode__c;
    v.iconName = i.IconName__c;
    v.description = labelText(i.DescLabel__c);
    v.title = labelText(i.TitleLabel__c);
    v.keywords = labelText(i.KeywordsLabel__c);
    v.bundle = i.Bundle__c;
    if (i.TargetType__c == TARGET_OBJECT && String.isNotBlank(i.Target__c)) {
      Schema.DescribeSObjectResult d = describe(i.Target__c);
      if (d == null || !d.isAccessible()) {
        return null;
      }
      v.title = v.title ?? d.getLabelPlural();
      v.target = d.getName();
      v.targetType = TARGET_OBJECT;
      v.ready = true;
    } else if (
      i.TargetType__c == TARGET_PAGE && String.isNotBlank(i.Target__c)
    ) {
      // 앱 페이지 탭 표시 권한은 Salesforce가 탭을 열 때 확인한다
      v.target = i.Target__c;
      v.targetType = TARGET_PAGE;
      v.ready = true;
    }
    v.title = v.title ?? i.DeveloperName;
    return v;
  }

  /** 채번 규칙 중 번호가 그 접두어로 시작하는 가장 긴 것. */
  private static CMN_NumberingRule__mdt ruleFor(String no) {
    CMN_NumberingRule__mdt best;
    Integer bestLength = 0;
    for (CMN_NumberingRule__mdt r : CMN_AppMenuSelector.numberingRules()) {
      String prefix = prefixOf(r.Pattern__c);
      if (
        prefix != null &&
        no.startsWith(prefix) &&
        prefix.length() > bestLength
      ) {
        best = r;
        bestLength = prefix.length();
      }
    }
    return best;
  }

  /** 채번 패턴의 고정 접두어(첫 '{' 앞). 없으면 null. 예: NCR-{PLANT}-… → NCR- */
  @TestVisible
  private static String prefixOf(String pattern) {
    if (String.isBlank(pattern)) {
      return null;
    }
    Integer brace = pattern.indexOf('{');
    String prefix = (brace < 0 ? pattern : pattern.left(brace)).toUpperCase();
    return String.isBlank(prefix) ? null : prefix;
  }

  private static Boolean hasPermission(String customPermission) {
    try {
      return FeatureManagement.checkPermission(customPermission);
    } catch (Exception e) {
      // 아직 배포되지 않은 Custom Permission이면 보이지 않는다
      return false;
    }
  }

  private static Set<String> splitSet(String csv) {
    Set<String> out = new Set<String>();
    for (String s : (csv ?? '').split(',')) {
      if (String.isNotBlank(s)) {
        out.add(s.trim());
      }
    }
    return out;
  }

  /** 객체 API명 → 설명(없는 객체면 null). */
  private static Schema.DescribeSObjectResult describe(String objectName) {
    Type t = String.isBlank(objectName) ? null : Type.forName(objectName);
    Object instance = t == null ? null : t.newInstance();
    if (!(instance instanceof SObject)) {
      return null;
    }
    return ((SObject) instance)
      .getSObjectType()
      .getDescribe(SObjectDescribeOptions.DEFERRED);
  }

  private static String labelText(String name) {
    if (String.isBlank(name)) {
      return null;
    }
    try {
      return System.Label.get('', name);
    } catch (Exception e) {
      // 다음 묶음이 라벨을 아직 배포하지 않았으면 다른 값으로 대신한다
      return null;
    }
  }

  private static AuraHandledException toAura(Exception e, String method) {
    String message;
    if (e instanceof CMN_ValidationException) {
      message = e.getMessage();
    } else {
      CMN_Logger.error(
        'CMN_AppMenuController.' + method,
        e.getMessage(),
        null,
        e
      );
      message = Label.CMN_Common_UnexpectedError;
    }
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
