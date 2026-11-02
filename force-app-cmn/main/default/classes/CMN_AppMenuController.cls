/**
 * @description 앱 메뉴 허브 화면(화면 우선 플랜 A0 앱 내비게이션 골격). 메뉴 1개의 기능 타일을 사용자 언어로 만들고,
 * 읽을 수 없는 객체 타일은 빼며, 화면이 아직 없는 기능은 '준비 중'(1차 화면 묶음)으로 보낸다.
 * @group A0-PROTO-KIT
 */
public with sharing class CMN_AppMenuController {
  public static final String TARGET_OBJECT = 'OBJECT';
  public static final String TARGET_PAGE = 'PAGE';
  private static final Pattern KEY_PATTERN = Pattern.compile(
    '^[A-Za-z][A-Za-z0-9_]{1,39}$'
  );

  /** @description 메뉴 머리글과 타일. */
  public class MenuView {
    @AuraEnabled
    public String menuKey;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public String iconName;
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
  }

  /**
   * @description 메뉴 허브 내용.
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
      MenuView view = new MenuView();
      view.menuKey = menu.DeveloperName;
      view.title = labelText(menu.TitleLabel__c) ?? menu.DeveloperName;
      view.description = labelText(menu.DescLabel__c);
      view.iconName = menu.IconName__c;
      for (CMN_AppMenuItem__mdt i : CMN_AppMenuSelector.items(menuKey)) {
        ItemView item = toView(i);
        if (item != null) {
          view.items.add(item);
          view.readyCount += item.ready ? 1 : 0;
        }
      }
      return view;
    } catch (Exception e) {
      throw toAura(e);
    }
  }

  // ------------------------------------------------------------------ 내부
  /** 읽을 수 없거나 배포되지 않은 객체 타일은 null(숨김). */
  private static ItemView toView(CMN_AppMenuItem__mdt i) {
    ItemView v = new ItemView();
    v.key = i.DeveloperName;
    v.featureCode = i.FeatureCode__c;
    v.iconName = i.IconName__c;
    v.description = labelText(i.DescLabel__c);
    v.title = labelText(i.TitleLabel__c);
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

  /** 객체 API명 → 설명(없는 객체면 null). */
  private static Schema.DescribeSObjectResult describe(String objectName) {
    Type t = Type.forName(objectName);
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

  private static AuraHandledException toAura(Exception e) {
    String message;
    if (e instanceof CMN_ValidationException) {
      message = e.getMessage();
    } else {
      CMN_Logger.error(
        'CMN_AppMenuController.getMenu',
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
