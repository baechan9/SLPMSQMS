/**
 * @description 위젯 대시보드 엔진(CMN-00-DSH-001): 사용자 배치 조회·저장, 역할 템플릿 복사(BR-3), 위젯 권한(BR-2), 확장 해석기·검증기.
 * 배치 항목 JSON = {widgetKey, size, order, config}(Apex에서는 order를 position으로 다룬다). 위젯 콘텐츠는 QMS-07·PMS 대시보드 WI가 메타데이터로 더한다.
 * @group CMN-00-DSH-001
 */
public with sharing class CMN_DashboardService {
  public static final String QMS = 'QMS';
  public static final String PMS = 'PMS';
  public static final Set<String> SYSTEMS = new Set<String>{ QMS, PMS };
  public static final Set<String> SIZES = new Set<String>{ 'S', 'M', 'L' };
  public static final String OK = 'OK';
  public static final String NO_ACCESS = 'NO_ACCESS';
  public static final String UNAVAILABLE = 'UNAVAILABLE';
  @TestVisible
  private static final Integer MAX_WIDGETS = 24;
  private static final Integer MAX_CONFIG = 8000;
  private static final Integer MAX_LAYOUT = 32768;
  private static final Pattern COMPONENT_NAME = Pattern.compile(
    '^[a-z][A-Za-z0-9]{1,79}$'
  );

  /** 배치 한 칸. */
  public class Item {
    public String widgetKey;
    public String size;
    public Integer position;
    public Map<String, Object> config = new Map<String, Object>();
  }

  /** 보드(배치 + 위젯 상태). */
  public class Board {
    public String sourceTemplate;
    public List<Item> items = new List<Item>();
  }

  @TestVisible
  private static Map<String, CMN_Widget__mdt> widgetsOverride;
  @TestVisible
  private static Map<String, List<CMN_DashboardTemplateItem__mdt>> templateItemsOverride;
  @TestVisible
  private static List<CMN_DashboardTemplate__mdt> templatesOverride;
  @TestVisible
  private static List<Object> extensionsOverride;
  private static Map<String, CMN_Widget__mdt> widgetCache;
  private static Map<Id, List<Set<String>>> permissionCache = new Map<Id, List<Set<String>>>();

  // ------------------------------------------------------------------ 조회·저장
  /**
   * @description 내 보드. 없으면 역할 템플릿을 복사해 저장한다(BR-3, AC-1).
   * @param systemCode QMS 또는 PMS
   * @return 보드
   */
  public static Board load(String systemCode) {
    requireSystem(systemCode);
    CMN_UserDashboard__c row = CMN_DashboardSelector.board(
      uniqueKey(systemCode)
    );
    if (row == null) {
      Board b = fromTemplate(systemCode);
      write(systemCode, null, b);
      return b;
    }
    Board b = new Board();
    b.sourceTemplate = row.SourceTemplate__c;
    b.items = parse(row.LayoutJson__c);
    return b;
  }

  /**
   * @description 배치를 저장한다(AC-2). 새로 넣는 위젯은 등록·활성·권한을 확인하고, 이미 있던 위젯은 권한을 잃었어도 유지할 수 있다(BR-2 자리표시).
   * @param systemCode QMS 또는 PMS
   * @param layoutJson [{widgetKey, size, order, config}]
   * @throws CMN_ValidationException 배치·설정 오류(라벨 문구)
   */
  public static void save(String systemCode, String layoutJson) {
    requireSystem(systemCode);
    List<Item> items;
    try {
      items = parse(layoutJson);
    } catch (Exception e) {
      throw new CMN_ValidationException(Label.CMN_WidgetBoard_InvalidLayout);
    }
    if (items.size() > MAX_WIDGETS) {
      throw new CMN_ValidationException(
        String.format(
          Label.CMN_WidgetBoard_TooManyWidgets,
          new List<Object>{ MAX_WIDGETS }
        )
      );
    }
    CMN_UserDashboard__c existing = CMN_DashboardSelector.board(
      uniqueKey(systemCode)
    );
    Set<String> kept = new Set<String>();
    for (Item i : parse(existing?.LayoutJson__c)) {
      kept.add(i.widgetKey);
    }
    Map<String, CMN_Widget__mdt> widgets = widgets();
    List<CMN_WidgetConfigValidator> validators = validators(systemCode);
    Integer seq = 1;
    for (Item i : items) {
      CMN_Widget__mdt w = widgets.get(i.widgetKey ?? '');
      Boolean added = !kept.contains(i.widgetKey);
      if (
        w == null ||
        !SIZES.contains(i.size) ||
        JSON.serialize(i.config).length() > MAX_CONFIG ||
        (added && widgetState(w, systemCode) != OK)
      ) {
        throw new CMN_ValidationException(Label.CMN_WidgetBoard_InvalidLayout);
      }
      for (CMN_WidgetConfigValidator v : validators) {
        String reason = v.validate(i.widgetKey, i.config);
        if (String.isNotBlank(reason)) {
          throw new CMN_ValidationException(
            String.format(
              Label.CMN_WidgetBoard_InvalidConfig,
              new List<Object>{ titleOf(w) + ' — ' + reason }
            )
          );
        }
      }
      i.position = seq++;
    }
    Board b = new Board();
    b.sourceTemplate = existing?.SourceTemplate__c;
    b.items = items;
    write(systemCode, existing?.Id, b);
  }

  /**
   * @description 템플릿으로 초기화(BR-3).
   * @param systemCode QMS 또는 PMS
   * @return 새 보드
   */
  public static Board reset(String systemCode) {
    requireSystem(systemCode);
    CMN_UserDashboard__c existing = CMN_DashboardSelector.board(
      uniqueKey(systemCode)
    );
    Board b = fromTemplate(systemCode);
    write(systemCode, existing?.Id, b);
    return b;
  }

  /**
   * @description 갤러리: 이 시스템 보드에 넣을 수 있고 사용자가 권한을 가진 활성 위젯(BR-2).
   * @param systemCode QMS 또는 PMS
   * @return 위젯
   */
  public static List<CMN_Widget__mdt> gallery(String systemCode) {
    requireSystem(systemCode);
    List<CMN_Widget__mdt> out = new List<CMN_Widget__mdt>();
    for (CMN_Widget__mdt w : widgets().values()) {
      if (widgetState(w, systemCode) == OK) {
        out.add(w);
      }
    }
    return out;
  }

  // ------------------------------------------------------------------ 위젯 정보
  /**
   * @description 등록된 위젯(트랜잭션 캐시).
   * @return DeveloperName → 위젯
   */
  public static Map<String, CMN_Widget__mdt> widgets() {
    if (widgetCache == null) {
      widgetCache = widgetsOverride ?? CMN_DashboardSelector.widgets();
    }
    return widgetCache;
  }

  /**
   * @description 사용자에게 위젯 상태: OK, NO_ACCESS(권한 없음), UNAVAILABLE(비활성·미배포·이 시스템에서 쓸 수 없음).
   * @param w 위젯(null이면 UNAVAILABLE)
   * @param systemCode QMS 또는 PMS
   * @return 상태
   */
  public static String widgetState(CMN_Widget__mdt w, String systemCode) {
    if (
      w == null ||
      !w.IsActive__c ||
      !COMPONENT_NAME.matcher(w.ComponentName__c ?? '').matches()
    ) {
      return UNAVAILABLE;
    }
    if (!availableIn(w, systemCode)) {
      return UNAVAILABLE;
    }
    if (
      String.isNotBlank(w.RequiredPermissionSet__c) &&
      !permissions()[0].contains(w.RequiredPermissionSet__c)
    ) {
      return NO_ACCESS;
    }
    return OK;
  }

  /**
   * @description 위젯 제목(사용자 언어 라벨, 라벨이 없으면 메타데이터 라벨).
   * @param w 위젯
   * @return 제목
   */
  public static String titleOf(CMN_Widget__mdt w) {
    return labelText(w?.TitleLabel__c) ?? w?.MasterLabel ?? w?.DeveloperName;
  }

  /**
   * @description Custom Label 이름 → 사용자 언어 문구.
   * @param name 라벨 이름
   * @return 문구(없으면 null)
   */
  public static String labelText(String name) {
    if (String.isBlank(name)) {
      return null;
    }
    try {
      return System.Label.get('', name);
    } catch (Exception e) {
      // 콘텐츠 WI가 아직 라벨을 배포하지 않았으면 메타데이터 라벨을 쓴다
      return null;
    }
  }

  // ------------------------------------------------------------------ 내부
  private static Board fromTemplate(String systemCode) {
    Board b = new Board();
    String key = templateKey(systemCode);
    if (key == null) {
      return b;
    }
    b.sourceTemplate = key;
    Map<String, CMN_Widget__mdt> widgets = widgets();
    List<CMN_DashboardTemplateResolver> resolvers = resolvers(systemCode);
    List<CMN_DashboardTemplateItem__mdt> rows = templateItemsOverride
      ?.get(key) ?? CMN_DashboardSelector.templateItems(key);
    Integer seq = 1;
    for (CMN_DashboardTemplateItem__mdt t : rows) {
      CMN_Widget__mdt w = widgets.get(t.Widget__r?.DeveloperName ?? '');
      // 미배포·비활성·권한 없는 위젯은 건너뛴다(Vol.7 변경 요청)
      if (widgetState(w, systemCode) != OK) {
        continue;
      }
      String configJson = String.isNotBlank(t.Config__c)
        ? t.Config__c
        : w.DefaultConfig__c;
      for (CMN_DashboardTemplateResolver r : resolvers) {
        configJson = r.resolveConfig(configJson, UserInfo.getUserId()) ??
          configJson;
      }
      Item i = new Item();
      i.widgetKey = w.DeveloperName;
      i.size = SIZES.contains(t.Size__c)
        ? t.Size__c
        : (w.DefaultSize__c ?? 'M');
      i.position = seq++;
      i.config = toConfig(configJson);
      b.items.add(i);
      if (b.items.size() >= MAX_WIDGETS) {
        break;
      }
    }
    return b;
  }

  /** 해석기 → PSG가 맞는 템플릿(우선순위) → 시스템 기본. */
  private static String templateKey(String systemCode) {
    List<CMN_DashboardTemplate__mdt> templates = templatesOverride ??
      CMN_DashboardSelector.templates(systemCode);
    Set<String> keys = new Set<String>();
    for (CMN_DashboardTemplate__mdt t : templates) {
      keys.add(t.DeveloperName);
    }
    Set<String> groups = permissions()[1];
    for (CMN_DashboardTemplateResolver r : resolvers(systemCode)) {
      String chosen = r.templateFor(systemCode, UserInfo.getUserId(), groups);
      if (String.isNotBlank(chosen) && keys.contains(chosen)) {
        return chosen;
      }
    }
    String fallback;
    for (CMN_DashboardTemplate__mdt t : templates) {
      for (String g : (t.PermissionSetGroups__c ?? '').split(',')) {
        if (groups.contains(g.trim())) {
          return t.DeveloperName;
        }
      }
      if (t.IsDefault__c && fallback == null) {
        fallback = t.DeveloperName;
      }
    }
    return fallback;
  }

  private static Boolean availableIn(CMN_Widget__mdt w, String systemCode) {
    if (String.isNotBlank(w.AvailableSystems__c)) {
      for (String s : w.AvailableSystems__c.split(',')) {
        if (s.trim() == systemCode) {
          return true;
        }
      }
      return false;
    }
    return w.System__c == 'CMN' || w.System__c == systemCode;
  }

  private static List<Set<String>> permissions() {
    Id me = UserInfo.getUserId();
    if (!permissionCache.containsKey(me)) {
      permissionCache.put(me, CMN_DashboardSelector.permissionNames(me));
    }
    return permissionCache.get(me);
  }

  private static List<CMN_DashboardTemplateResolver> resolvers(
    String systemCode
  ) {
    List<CMN_DashboardTemplateResolver> out = new List<CMN_DashboardTemplateResolver>();
    for (Object o : extensions('TEMPLATE_RESOLVER', systemCode)) {
      if (o instanceof CMN_DashboardTemplateResolver) {
        out.add((CMN_DashboardTemplateResolver) o);
      }
    }
    return out;
  }

  private static List<CMN_WidgetConfigValidator> validators(String systemCode) {
    List<CMN_WidgetConfigValidator> out = new List<CMN_WidgetConfigValidator>();
    for (Object o : extensions('CONFIG_VALIDATOR', systemCode)) {
      if (o instanceof CMN_WidgetConfigValidator) {
        out.add((CMN_WidgetConfigValidator) o);
      }
    }
    return out;
  }

  private static List<Object> extensions(String kind, String systemCode) {
    if (extensionsOverride != null) {
      return extensionsOverride;
    }
    List<Object> out = new List<Object>();
    for (
      String className : CMN_DashboardSelector.extensionClasses(
        kind,
        systemCode
      )
    ) {
      System.Type t = System.Type.forName(className ?? '');
      if (t == null) {
        // 등록만 되고 아직 배포되지 않은 확장은 건너뛴다(보드를 멈추지 않는다)
        CMN_Logger.warn(
          'CMN_DashboardService.extensions',
          'Extension class not found: ' + className,
          null
        );
        continue;
      }
      out.add(t.newInstance());
    }
    return out;
  }

  /** 저장된 배치 JSON → 항목(형식이 틀리면 예외). */
  @TestVisible
  private static List<Item> parse(String layoutJson) {
    List<Item> out = new List<Item>();
    if (String.isBlank(layoutJson)) {
      return out;
    }
    if (layoutJson.length() > MAX_LAYOUT) {
      throw new CMN_ValidationException(Label.CMN_WidgetBoard_InvalidLayout);
    }
    for (Object o : (List<Object>) JSON.deserializeUntyped(layoutJson)) {
      Map<String, Object> m = (Map<String, Object>) o;
      Item i = new Item();
      i.widgetKey = (String) m.get('widgetKey');
      i.size = (String) m.get('size');
      i.position = m.get('order') == null
        ? null
        : Integer.valueOf(m.get('order'));
      Object c = m.get('config');
      i.config = c == null
        ? new Map<String, Object>()
        : (Map<String, Object>) c;
      out.add(i);
    }
    return out;
  }

  private static Map<String, Object> toConfig(String configJson) {
    if (String.isBlank(configJson)) {
      return new Map<String, Object>();
    }
    try {
      return (Map<String, Object>) JSON.deserializeUntyped(configJson);
    } catch (Exception e) {
      // 메타데이터 설정이 깨졌어도 보드는 연다(위젯이 기본값으로 동작)
      CMN_Logger.warn(
        'CMN_DashboardService.toConfig',
        'Invalid widget config JSON',
        null
      );
      return new Map<String, Object>();
    }
  }

  private static void write(String systemCode, Id existingId, Board b) {
    List<Map<String, Object>> rows = new List<Map<String, Object>>();
    for (Item i : b.items) {
      rows.add(
        new Map<String, Object>{
          'widgetKey' => i.widgetKey,
          'size' => i.size,
          'order' => i.position,
          'config' => i.config
        }
      );
    }
    String layout = JSON.serialize(rows);
    if (layout.length() > MAX_LAYOUT) {
      throw new CMN_ValidationException(Label.CMN_WidgetBoard_InvalidLayout);
    }
    CMN_UserDashboard__c row = new CMN_UserDashboard__c(
      Id = existingId,
      LayoutJson__c = layout,
      SourceTemplate__c = b.sourceTemplate
    );
    if (existingId == null) {
      row.Name = (UserInfo.getName() + ' ' + systemCode).left(80);
      row.User__c = UserInfo.getUserId();
      row.System__c = systemCode;
      row.UniqueKey__c = uniqueKey(systemCode);
      Database.insert(row, AccessLevel.USER_MODE);
    } else {
      Database.update(row, AccessLevel.USER_MODE);
    }
  }

  private static String uniqueKey(String systemCode) {
    return UserInfo.getUserId() + ':' + systemCode;
  }

  private static void requireSystem(String systemCode) {
    if (!SYSTEMS.contains(systemCode ?? '')) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
  }
}
