/**
 * @description 결정 지원 레일(CMN-00-UX-004 BR-5·6·7).
 * - getPanels: 기본(*) 패널과 객체 패널을 PanelKey로 합치고(객체 행 우선), 비활성·권한 없는 패널을 빼고 순서대로 돌려준다.
 * - resolveBindings: 문맥 분석 패널이 위젯 config에 넣을 레코드 필드 값(사용자 권한).
 * - getOpenTodos: 레코드에 걸린 열린 To-Do(TODO 패널).
 * @group CMN-00-UX-004
 */
public with sharing class CMN_RailPanelController {
  /** ObjectApiName__c 값: 모든 업무 레코드의 기본 패널 */
  public static final String ALL_OBJECTS = '*';
  @TestVisible
  private static final Integer MAX_TODOS = 20;
  @TestVisible
  private static final Integer MAX_BINDINGS = 10;
  private static final Pattern OBJECT_PATTERN = Pattern.compile(
    '^[A-Za-z][A-Za-z0-9_]{1,79}$'
  );
  private static final Pattern COMPONENT_PATTERN = Pattern.compile(
    '^c/[a-z][A-Za-z0-9]{1,79}$'
  );

  /** @description 레일 패널 하나. */
  public class PanelView {
    @AuraEnabled
    public String key;
    /** c/cmnXxx */
    @AuraEnabled
    public String componentName;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public Integer order;
    @AuraEnabled
    public Integer phoneOrder;
    @AuraEnabled
    public Boolean defaultOpen = false;
    /** 패널 설정 JSON(문자열 그대로) */
    @AuraEnabled
    public String config;
  }

  /** @description TODO 패널의 To-Do 한 줄. */
  public class TodoView {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String recordNo;
    @AuraEnabled
    public String assigneeName;
    @AuraEnabled
    public Date dueDate;
    @AuraEnabled
    public Boolean isOverdue = false;
  }

  /**
   * @description 레일 패널 목록(순서대로). 형식이 틀린 객체 이름이면 빈 목록.
   * @param objectApiName 업무 객체 API명(레코드 페이지가 넣어 준다)
   * @return 패널
   */
  @AuraEnabled(cacheable=true)
  public static List<PanelView> getPanels(String objectApiName) {
    List<PanelView> out = new List<PanelView>();
    if (
      String.isBlank(objectApiName) ||
      !OBJECT_PATTERN.matcher(objectApiName).matches()
    ) {
      return out;
    }
    // 같은 PanelKey면 객체 행이 기본(*) 행을 덮어쓴다(BR-5)
    Map<String, CMN_RailPanel__mdt> byKey = new Map<String, CMN_RailPanel__mdt>();
    for (Boolean objectRows : new List<Boolean>{ false, true }) {
      for (CMN_RailPanel__mdt r : CMN_RailPanelSelector.panels(objectApiName)) {
        Boolean isObjectRow = r.ObjectApiName__c == objectApiName;
        Boolean isDefaultRow = r.ObjectApiName__c == ALL_OBJECTS;
        if (
          (objectRows && isObjectRow) ||
          (!objectRows &&
          isDefaultRow &&
          !isObjectRow)
        ) {
          byKey.put(r.PanelKey__c, r);
        }
      }
    }
    for (CMN_RailPanel__mdt r : byKey.values()) {
      PanelView v = toView(r);
      if (v != null) {
        out.add(v);
      }
    }
    out.sort(new ByOrder());
    return out;
  }

  /**
   * @description 레코드 필드 값(문맥 분석 패널 bind, BR-7). 사용자가 읽을 수 없는 객체·필드는 결과에 넣지 않는다.
   * @param recordId 업무 레코드 Id
   * @param fieldNames 필드 API명(최대 10개)
   * @return 필드 API명 → 값
   * @throws AuraHandledException 예상하지 못한 오류
   */
  @AuraEnabled
  public static Map<String, Object> resolveBindings(
    Id recordId,
    List<String> fieldNames
  ) {
    Map<String, Object> out = new Map<String, Object>();
    try {
      if (
        recordId == null ||
        fieldNames == null ||
        fieldNames.isEmpty() ||
        fieldNames.size() > MAX_BINDINGS
      ) {
        return out;
      }
      Schema.DescribeSObjectResult d = recordId.getSObjectType()
        .getDescribe(SObjectDescribeOptions.DEFERRED);
      if (!d.isAccessible()) {
        return out;
      }
      Map<String, Schema.SObjectField> fieldMap = d.fields.getMap();
      List<String> readable = new List<String>();
      for (String name : fieldNames) {
        Schema.DescribeFieldResult fd = String.isBlank(name)
          ? null
          : fieldMap.get(name)?.getDescribe();
        if (
          fd != null &&
          fd.isAccessible() &&
          !readable.contains(fd.getName())
        ) {
          readable.add(fd.getName());
        }
      }
      if (readable.isEmpty()) {
        return out;
      }
      List<String> escaped = new List<String>();
      for (String f : readable) {
        escaped.add(String.escapeSingleQuotes(f));
      }
      List<SObject> rows = Database.queryWithBinds(
        'SELECT ' +
          String.join(escaped, ', ') +
          ' FROM ' +
          String.escapeSingleQuotes(d.getName()) +
          ' WHERE Id = :rid LIMIT 1',
        new Map<String, Object>{ 'rid' => recordId },
        AccessLevel.USER_MODE
      );
      if (rows.isEmpty()) {
        return out;
      }
      for (String f : readable) {
        out.put(f, rows[0].get(f));
      }
      return out;
    } catch (QueryException e) {
      // 레코드 공유·권한 밖이면 값 없이 위젯을 보인다
      return new Map<String, Object>();
    } catch (Exception e) {
      throw toAura(e, 'resolveBindings');
    }
  }

  /**
   * @description 레코드에 걸린 열린 To-Do(TODO 패널, 최대 20건, 받는 사람 언어 제목).
   * @param recordId 업무 레코드 Id
   * @return To-Do
   * @throws AuraHandledException 예상하지 못한 오류
   */
  @AuraEnabled(cacheable=true)
  public static List<TodoView> getOpenTodos(Id recordId) {
    List<TodoView> out = new List<TodoView>();
    if (recordId == null) {
      return out;
    }
    try {
      String language = UserInfo.getLanguage();
      for (
        CMN_Todo__c t : CMN_RailPanelSelector.openTodos(recordId, MAX_TODOS)
      ) {
        TodoView v = new TodoView();
        v.id = t.Id;
        v.title = CMN_TodoService.renderTitle(t, language);
        v.recordNo = t.RecordNo__c;
        v.assigneeName = t.Assignee__r?.Name;
        v.dueDate = t.DueDate__c;
        v.isOverdue = t.IsOverdue__c == true;
        out.add(v);
      }
      return out;
    } catch (QueryException e) {
      // To-Do 읽기 권한이 없으면 빈 목록
      return out;
    } catch (Exception e) {
      throw toAura(e, 'getOpenTodos');
    }
  }

  // ------------------------------------------------------------------ 내부
  /** 비활성·컴포넌트 이름 형식 오류·권한 없는 패널은 null. */
  private static PanelView toView(CMN_RailPanel__mdt r) {
    if (
      r.IsActive__c != true ||
      String.isBlank(r.ComponentName__c) ||
      !COMPONENT_PATTERN.matcher(r.ComponentName__c).matches()
    ) {
      return null;
    }
    if (
      String.isNotBlank(r.RequiredPermission__c) &&
      !hasPermission(r.RequiredPermission__c)
    ) {
      return null;
    }
    PanelView v = new PanelView();
    v.key = r.PanelKey__c;
    v.componentName = r.ComponentName__c;
    v.title = labelText(r.TitleLabel__c) ?? r.PanelKey__c;
    v.order = r.Order__c?.intValue();
    v.phoneOrder = (r.PhoneOrder__c ?? r.Order__c)?.intValue();
    v.defaultOpen = r.DefaultOpen__c == true;
    v.config = r.Config__c;
    return v;
  }

  /** 순서(비면 맨 뒤), 같으면 패널 키. */
  private class ByOrder implements Comparator<PanelView> {
    public Integer compare(PanelView a, PanelView b) {
      Integer x = a.order ?? 999;
      Integer y = b.order ?? 999;
      if (x != y) {
        return x < y ? -1 : 1;
      }
      return (a.key ?? '').compareTo(b.key ?? '');
    }
  }

  private static Boolean hasPermission(String customPermission) {
    try {
      return FeatureManagement.checkPermission(customPermission);
    } catch (Exception e) {
      // 아직 배포되지 않은 Custom Permission이면 보이지 않는다
      return false;
    }
  }

  private static String labelText(String name) {
    if (String.isBlank(name)) {
      return null;
    }
    try {
      return System.Label.get('', name);
    } catch (Exception e) {
      return null;
    }
  }

  private static AuraHandledException toAura(Exception e, String method) {
    CMN_Logger.error(
      'CMN_RailPanelController.' + method,
      e.getMessage(),
      null,
      e
    );
    String message = Label.CMN_Common_UnexpectedError;
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
