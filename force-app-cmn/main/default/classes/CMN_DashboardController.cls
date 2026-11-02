/**
 * @description 위젯 보드 화면 진입점(CMN-00-DSH-001): cmnWidgetBoard. 규칙은 CMN_DashboardService가 확인한다.
 * @group CMN-00-DSH-001
 */
public with sharing class CMN_DashboardController {
  /** @description 보드 화면. */
  public class BoardView {
    @AuraEnabled
    public String systemCode;
    @AuraEnabled
    public String sourceTemplate;
    @AuraEnabled
    public List<WidgetView> items = new List<WidgetView>();
  }

  /** @description 보드의 위젯 한 칸. */
  public class WidgetView {
    @AuraEnabled
    public String widgetKey;
    @AuraEnabled
    public String componentName;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String size;
    @AuraEnabled
    public Integer position;
    @AuraEnabled
    public String configJson;
    /** OK, NO_ACCESS, UNAVAILABLE */
    @AuraEnabled
    public String state;
    @AuraEnabled
    public Boolean hasSchema = false;
    @AuraEnabled
    public Boolean mobileSupported = true;
  }

  /** @description 갤러리 위젯. */
  public class GalleryItem {
    @AuraEnabled
    public String widgetKey;
    @AuraEnabled
    public String componentName;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public String category;
    @AuraEnabled
    public String defaultSize;
    @AuraEnabled
    public String defaultConfigJson;
    @AuraEnabled
    public Boolean hasSchema = false;
    @AuraEnabled
    public Boolean mobileSupported = true;
  }

  /**
   * @description 내 보드(처음이면 역할 템플릿으로 만든다).
   * @param systemCode QMS 또는 PMS
   * @return 보드
   * @throws AuraHandledException 잘못된 입력
   */
  @AuraEnabled
  public static BoardView getBoard(String systemCode) {
    try {
      return toView(systemCode, CMN_DashboardService.load(systemCode));
    } catch (Exception e) {
      throw toAura(e, 'CMN_DashboardController.getBoard');
    }
  }

  /**
   * @description 배치 저장 후 다시 읽은 보드.
   * @param systemCode QMS 또는 PMS
   * @param layoutJson [{widgetKey, size, order, config}]
   * @return 보드
   * @throws AuraHandledException 배치·설정 오류
   */
  @AuraEnabled
  public static BoardView saveBoard(String systemCode, String layoutJson) {
    try {
      CMN_DashboardService.save(systemCode, layoutJson);
      return toView(systemCode, CMN_DashboardService.load(systemCode));
    } catch (Exception e) {
      throw toAura(e, 'CMN_DashboardController.saveBoard');
    }
  }

  /**
   * @description 템플릿으로 초기화.
   * @param systemCode QMS 또는 PMS
   * @return 보드
   * @throws AuraHandledException 잘못된 입력
   */
  @AuraEnabled
  public static BoardView resetBoard(String systemCode) {
    try {
      return toView(systemCode, CMN_DashboardService.reset(systemCode));
    } catch (Exception e) {
      throw toAura(e, 'CMN_DashboardController.resetBoard');
    }
  }

  /**
   * @description 위젯 갤러리(권한 있는 활성 위젯, BR-2).
   * @param systemCode QMS 또는 PMS
   * @return 위젯
   * @throws AuraHandledException 잘못된 입력
   */
  @AuraEnabled
  public static List<GalleryItem> getGallery(String systemCode) {
    try {
      List<GalleryItem> out = new List<GalleryItem>();
      for (CMN_Widget__mdt w : CMN_DashboardService.gallery(systemCode)) {
        GalleryItem g = new GalleryItem();
        g.widgetKey = w.DeveloperName;
        g.componentName = w.ComponentName__c;
        g.title = CMN_DashboardService.titleOf(w);
        g.description = CMN_DashboardService.labelText(w.DescLabel__c);
        g.category = w.Category__c;
        g.defaultSize = w.DefaultSize__c ?? 'M';
        g.defaultConfigJson = String.isBlank(w.DefaultConfig__c)
          ? '{}'
          : w.DefaultConfig__c;
        g.hasSchema = String.isNotBlank(w.ConfigSchema__c);
        g.mobileSupported = w.MobileSupported__c;
        out.add(g);
      }
      return out;
    } catch (Exception e) {
      throw toAura(e, 'CMN_DashboardController.getGallery');
    }
  }

  private static BoardView toView(
    String systemCode,
    CMN_DashboardService.Board b
  ) {
    BoardView v = new BoardView();
    v.systemCode = systemCode;
    v.sourceTemplate = b.sourceTemplate;
    Map<String, CMN_Widget__mdt> widgets = CMN_DashboardService.widgets();
    for (CMN_DashboardService.Item i : b.items) {
      CMN_Widget__mdt w = widgets.get(i.widgetKey ?? '');
      WidgetView wv = new WidgetView();
      wv.widgetKey = i.widgetKey;
      wv.size = i.size;
      wv.position = i.position;
      wv.configJson = JSON.serialize(i.config);
      wv.state = CMN_DashboardService.widgetState(w, systemCode);
      wv.title = w == null ? i.widgetKey : CMN_DashboardService.titleOf(w);
      // 권한·사용 불가 위젯은 컴포넌트를 내려보내지 않는다(자리표시만)
      wv.componentName = wv.state == CMN_DashboardService.OK
        ? w.ComponentName__c
        : null;
      wv.hasSchema = w != null && String.isNotBlank(w.ConfigSchema__c);
      wv.mobileSupported = w == null || w.MobileSupported__c;
      v.items.add(wv);
    }
    return v;
  }

  private static AuraHandledException toAura(Exception e, String source) {
    String message;
    if (e instanceof CMN_ValidationException) {
      message = e.getMessage();
    } else {
      CMN_Logger.error(source, e.getMessage(), null, e);
      message = Label.CMN_Common_UnexpectedError;
    }
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
