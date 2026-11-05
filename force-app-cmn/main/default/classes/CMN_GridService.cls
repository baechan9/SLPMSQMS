/**
 * @description 공통 편집 그리드 서비스(CMN-00-UX-006). 그리드 정의(CMN_GridDefinition__mdt·CMN_GridColumn__mdt)와 업무
 * Provider(CMN_GridProvider)로 행 로드·저장·붙여넣기 참조 확인을 한다. 화면 진입점은 CMN_GridController.
 * - 로드(BR-1): 행 조회 1회(USER_MODE). 읽을 수 없는 필드의 열은 응답에서 빼고, 편집 권한이 없는 필드는 읽기 전용으로 내린다.
 *   편집 가능 = 부모 레코드 편집 권한 AND (EditRuleKey가 없거나 UX-005 canExecute). clientVersion = 행 수 + 최대 LastModifiedDate.
 * - 저장(BR-4·5·11): 버전 확인 → 행 조립(형식·잠긴 셀·필수) → Provider validate → Savepoint 안에서 upsert 1회 + delete 1회
 *   → Provider afterSave. 오류가 하나라도 있으면 아무 행도 저장하지 않는다.
 * - 참조 확인(BR-3): 붙여넣은 이름·외부 키(ExternalKey__c·External ID 텍스트 필드)·Id를 Lookup·CODE 열 대상 레코드로 바꾼다
 *   (한 번 호출, 서로 다른 값 최대 200개).
 * @group CMN-00-UX-006
 */
public with sharing class CMN_GridService {
  public static final Integer HARD_MAX_ROWS = 500;
  public static final Integer DEFAULT_MAX_ROWS = 200;
  public static final Integer MAX_LOOKUP_KEYS = 200;
  public static final String DISPLAY_PREFIX = '__d_';
  public static final String TYPE_TEXT = 'TEXT';
  public static final String TYPE_NUMBER = 'NUMBER';
  public static final String TYPE_DATE = 'DATE';
  public static final String TYPE_PICKLIST = 'PICKLIST';
  public static final String TYPE_LOOKUP = 'LOOKUP';
  public static final String TYPE_CHECKBOX = 'CHECKBOX';
  public static final String TYPE_CODE = 'CODE';
  /** 표시 전용(날짜시간·다중 선택 등 그리드에서 편집하지 않는 타입) */
  public static final String TYPE_DISPLAY = 'DISPLAY';
  private static final Integer MAX_KEY_LENGTH = 40;
  private static final Integer MAX_JSON_LENGTH = 1000000;
  private static final Integer MAX_LOOKUP_ROWS = 2000;
  private static final Integer MAX_KEY_FIELDS = 4;
  private static final String EXTERNAL_KEY = 'ExternalKey__c';
  private static final String DISPLAY_NAME = 'DisplayName__c';
  private static final Pattern KEY_PATTERN = Pattern.compile(
    '^[A-Za-z][A-Za-z0-9_]{0,39}$'
  );
  private static final Pattern CLASS_PATTERN = Pattern.compile(
    '^[A-Za-z][A-Za-z0-9_]{0,79}$'
  );
  private static final Pattern FIELD_PATTERN = Pattern.compile(
    '^[A-Za-z][A-Za-z0-9_]{0,79}$'
  );
  private static final Pattern DATE_PATTERN = Pattern.compile(
    '^\\d{4}-\\d{2}-\\d{2}$'
  );
  private static Map<String, Set<String>> picklistCache = new Map<String, Set<String>>();

  /** 테스트에서 Provider 대신 쓰는 구현(GridKey → Provider) */
  @TestVisible
  private static Map<String, CMN_GridProvider> providerOverride;

  // ------------------------------------------------------------------ 화면 DTO
  /** @description 그리드 화면 데이터. */
  public class GridView {
    @AuraEnabled
    public String gridKey;
    @AuraEnabled
    public String objectApiName;
    @AuraEnabled
    public List<ColumnView> columns = new List<ColumnView>();
    /** 행: Id, 열 필드 값, __d_{필드}(참조 표시명), __deletable, __deleteBlocked, __locked, __warning */
    @AuraEnabled
    public List<Map<String, Object>> rows = new List<Map<String, Object>>();
    @AuraEnabled
    public Boolean editable = false;
    @AuraEnabled
    public Boolean allowAdd = false;
    @AuraEnabled
    public Boolean allowDelete = false;
    @AuraEnabled
    public Boolean allowPaste = false;
    @AuraEnabled
    public String scheduleStartField;
    @AuraEnabled
    public String scheduleEndField;
    @AuraEnabled
    public Integer maxRows;
    @AuraEnabled
    public Boolean truncated = false;
    @AuraEnabled
    public String clientVersion;
    /** 새 행 기본값(편집 열만) */
    @AuraEnabled
    public Map<String, Object> defaults = new Map<String, Object>();
  }

  /** @description 열 하나. */
  public class ColumnView {
    @AuraEnabled
    public String fieldApiName;
    @AuraEnabled
    public String label;
    /** TEXT, NUMBER, DATE, PICKLIST, LOOKUP, CHECKBOX, CODE, DISPLAY */
    @AuraEnabled
    public String inputType;
    @AuraEnabled
    public Boolean editable = false;
    @AuraEnabled
    public Boolean required = false;
    @AuraEnabled
    public Boolean frozen = false;
    @AuraEnabled
    public Integer widthWeight;
    @AuraEnabled
    public List<Option> options;
    @AuraEnabled
    public String codeGroup;
    @AuraEnabled
    public String referenceTo;
    @AuraEnabled
    public List<FilterTerm> lookupFilter;
    @AuraEnabled
    public Boolean showOnPhone = false;
    @AuraEnabled
    public Boolean isNameField = false;
    @AuraEnabled
    public Integer scale;
    @AuraEnabled
    public Integer length;
  }

  /** @description 선택 목록 값. */
  public class Option {
    @AuraEnabled
    public String value;
    @AuraEnabled
    public String label;
  }

  /** @description 고정 필터 조건 하나(필드 = 값). */
  public class FilterTerm {
    @AuraEnabled
    public String fieldPath;
    @AuraEnabled
    public String value;
  }

  /** @description 저장 결과. */
  public class SaveResult {
    @AuraEnabled
    public Boolean success = false;
    /** 다른 사용자가 먼저 저장(BR-5) */
    @AuraEnabled
    public Boolean conflict = false;
    @AuraEnabled
    public List<RowError> rowErrors = new List<RowError>();
    @AuraEnabled
    public List<String> gridErrors = new List<String>();
    @AuraEnabled
    public Integer savedCount = 0;
    @AuraEnabled
    public Integer deletedCount = 0;
    /** 성공하면 저장 뒤 그리드(다시 읽지 않아도 된다) */
    @AuraEnabled
    public GridView view;
  }

  /** @description 행 오류(행 키 → 문구). */
  public class RowError {
    @AuraEnabled
    public String key;
    @AuraEnabled
    public List<String> messages = new List<String>();
    @AuraEnabled
    public List<String> fieldNames = new List<String>();
  }

  /** @description 참조 확인 결과 하나. */
  public class LookupMatch {
    @AuraEnabled
    public String fieldApiName;
    @AuraEnabled
    public String key;
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String label;
    /** 같은 값이 여러 레코드와 일치 */
    @AuraEnabled
    public Boolean ambiguous = false;
  }

  // ------------------------------------------------------------------ 공개 API
  /**
   * @description 그리드 로드(BR-1·11).
   * @param gridKey 그리드 키
   * @param parentId 부모 레코드 Id
   * @return 화면 데이터
   * @throws CMN_ValidationException 키·부모 형식 오류, 정의 없음, 권한 없음, 설정 오류(라벨 문구)
   */
  public static GridView load(String gridKey, Id parentId) {
    return view(context(gridKey, parentId));
  }

  /**
   * @description 그리드 저장(BR-4·5·11). 업무 오류는 결과로 돌려주고 아무 행도 저장하지 않는다.
   * @param gridKey 그리드 키
   * @param parentId 부모 레코드 Id
   * @param rowsJson [{key, id(새 행은 없음), values:{필드: 값}}] — 바뀐 편집 열만
   * @param deletedIds 삭제할 행 Id
   * @param clientVersion 로드 때 받은 버전
   * @return 저장 결과
   * @throws CMN_ValidationException 요청 형식 오류·설정 오류(라벨 문구)
   */
  public static SaveResult save(
    String gridKey,
    Id parentId,
    String rowsJson,
    List<Id> deletedIds,
    String clientVersion
  ) {
    Context ctx = context(gridKey, parentId);
    SaveResult result = new SaveResult();
    if (!editable(ctx)) {
      result.gridErrors.add(Label.CMN_Grid_NotEditable);
      return result;
    }
    List<Id> deletes = deletedIds == null
      ? new List<Id>()
      : new List<Id>(new Set<Id>(deletedIds));
    List<RowInput> inputs = parseRows(rowsJson, ctx, new Set<Id>(deletes));
    if (inputs.size() > ctx.maxRows || deletes.size() > ctx.maxRows) {
      result.gridErrors.add(
        String.format(
          Label.CMN_Grid_TooManyRows,
          new List<Object>{ ctx.maxRows }
        )
      );
      return result;
    }
    List<SObject> current = CMN_GridSelector.query(
      rowQuery(ctx),
      rowBinds(ctx, ctx.maxRows + 1)
    );
    if (version(ctx, current) != clientVersion) {
      result.conflict = true;
      result.gridErrors.add(Label.CMN_Grid_Conflict);
      return result;
    }
    if (inputs.isEmpty() && deletes.isEmpty()) {
      result.success = true;
      result.view = view(ctx);
      return result;
    }
    Map<Id, SObject> byId = new Map<Id, SObject>(current);
    Map<Id, CMN_GridRowMeta> metas = rowMetas(ctx, current);
    Errors errors = new Errors();
    Plan plan = buildPlan(ctx, inputs, byId, metas, errors);
    checkDeletes(ctx, deletes, byId, metas, errors);
    if (errors.isEmpty()) {
      errors.addValidation(
        ctx.provider.validate(parentId, plan.merged, deletes),
        plan.keys
      );
    }
    if (!errors.isEmpty()) {
      errors.copyTo(result);
      return result;
    }
    Savepoint sp = Database.setSavepoint();
    Exception failure;
    try {
      write(ctx, plan, deletes, errors);
      if (errors.isEmpty()) {
        ctx.provider.afterSave(parentId, plan.merged, deletes);
      }
    } catch (CMN_ValidationException e) {
      // Provider가 사용자 문구로 멈춘 경우
      errors.grid.add(e.getMessage());
    } catch (Exception e) {
      failure = e;
      errors.grid.add(Label.CMN_Grid_SaveFailed);
    }
    if (!errors.isEmpty()) {
      Database.rollback(sp);
      errors.log(gridKey, parentId, failure);
      errors.copyTo(result);
      return result;
    }
    result.success = true;
    result.savedCount = plan.dml.size();
    result.deletedCount = deletes.size();
    ctx.editable = null;
    result.view = view(ctx);
    return result;
  }

  /**
   * @description 붙여넣기 참조 확인(BR-3). Lookup·CODE 열마다 이름·외부 키(ExternalKey__c)·Id로 대상 레코드를 찾는다.
   * 사용자 권한으로 조회하고, 같은 값이 여러 레코드와 맞으면 ambiguous로 돌려준다(찾지 못한 값은 id 없음).
   * @param gridKey 그리드 키
   * @param parentId 부모 레코드 Id
   * @param keysJson {"필드 API명": ["값", …]}
   * @return 값별 결과
   * @throws CMN_ValidationException 형식 오류, 서로 다른 값 200개 초과(라벨 문구)
   */
  public static List<LookupMatch> resolveLookups(
    String gridKey,
    Id parentId,
    String keysJson
  ) {
    Context ctx = context(gridKey, parentId);
    Map<String, List<String>> request = parseKeys(keysJson);
    Integer total = 0;
    for (List<String> keys : request.values()) {
      total += keys.size();
    }
    if (total > MAX_LOOKUP_KEYS) {
      throw new CMN_ValidationException(
        String.format(
          Label.CMN_Grid_LookupTooMany,
          new List<Object>{ MAX_LOOKUP_KEYS }
        )
      );
    }
    List<LookupMatch> out = new List<LookupMatch>();
    List<Col> targets = new List<Col>();
    for (String field : request.keySet()) {
      Col col = ctx.colByField.get(field);
      if (
        col != null &&
        (col.inputType == TYPE_LOOKUP ||
        col.inputType == TYPE_CODE) &&
        col.labelField != null
      ) {
        targets.add(col);
      }
    }
    // 열(대상 객체)마다 1회. 행 수와 무관하게 Lookup·CODE 열 수로 묶인다
    for (Col col : targets) {
      out.addAll(matchLookups(ctx, col, request.get(col.name)));
    }
    return out;
  }

  // ------------------------------------------------------------------ 문맥
  private class Context {
    public String gridKey;
    public Id parentId;
    public CMN_GridDefinition__mdt def;
    public Schema.DescribeSObjectResult rowDescribe;
    public Map<String, Schema.SObjectField> fieldMap;
    public String parentField;
    public String orderField;
    public Integer maxRows;
    public List<Col> cols = new List<Col>();
    public Map<String, Col> colByField = new Map<String, Col>();
    public List<FilterTerm> filter = new List<FilterTerm>();
    public Map<String, Object> filterValues = new Map<String, Object>();
    public CMN_GridProvider provider;
    public Boolean editable;
  }

  private class Col {
    public CMN_GridColumn__mdt meta;
    public Schema.DescribeFieldResult fd;
    public String name;
    public String label;
    public String inputType;
    public Boolean editable = false;
    public Boolean required = false;
    public String referenceTo;
    public String relationshipName;
    public String labelField;
    public String nameField;
  }

  private static Context context(String gridKey, Id parentId) {
    if (
      String.isBlank(gridKey) ||
      !KEY_PATTERN.matcher(gridKey).matches() ||
      parentId == null
    ) {
      throw new CMN_ValidationException(Label.CMN_Grid_InvalidRequest);
    }
    CMN_GridDefinition__mdt def = CMN_GridSelector.definition(gridKey);
    if (def == null) {
      throw new CMN_ValidationException(Label.CMN_Grid_NotFound);
    }
    Context ctx = new Context();
    ctx.gridKey = gridKey;
    ctx.parentId = parentId;
    ctx.def = def;
    ctx.rowDescribe = describe(def.ObjectApiName__c);
    if (ctx.rowDescribe == null) {
      throw configError(gridKey, 'object ' + def.ObjectApiName__c);
    }
    if (!ctx.rowDescribe.isAccessible()) {
      throw new CMN_ValidationException(Label.CMN_Grid_NoAccess);
    }
    ctx.fieldMap = ctx.rowDescribe.fields.getMap();
    Schema.DescribeFieldResult parent = fieldDescribe(
      ctx.fieldMap,
      def.ParentField__c
    );
    if (parent == null || parent.getType() != Schema.DisplayType.REFERENCE) {
      throw configError(gridKey, 'parent ' + def.ParentField__c);
    }
    if (!parent.getReferenceTo().contains(parentId.getSObjectType())) {
      throw new CMN_ValidationException(Label.CMN_Grid_InvalidRequest);
    }
    if (!parent.isAccessible()) {
      throw new CMN_ValidationException(Label.CMN_Grid_NoAccess);
    }
    ctx.parentField = parent.getName();
    Integer configured = def.MaxRows__c?.intValue();
    ctx.maxRows = (configured == null ||
      configured < 1)
      ? DEFAULT_MAX_ROWS
      : Math.min(configured, HARD_MAX_ROWS);
    Schema.DescribeFieldResult order = fieldDescribe(
      ctx.fieldMap,
      def.OrderField__c
    );
    if (order != null && order.isAccessible() && order.isSortable()) {
      ctx.orderField = order.getName();
    }
    parseFilter(ctx);
    for (CMN_GridColumn__mdt c : CMN_GridSelector.columns(gridKey)) {
      Col col = toCol(ctx, c);
      if (col != null && !ctx.colByField.containsKey(col.name)) {
        ctx.cols.add(col);
        ctx.colByField.put(col.name, col);
      }
    }
    ctx.provider = provider(def);
    return ctx;
  }

  private static Col toCol(Context ctx, CMN_GridColumn__mdt c) {
    Schema.DescribeFieldResult fd = fieldDescribe(
      ctx.fieldMap,
      c.FieldApiName__c
    );
    if (fd == null || !fd.isAccessible()) {
      return null; // 읽을 수 없는 필드의 열은 응답에서 뺀다(BR-1, AC-6)
    }
    Col col = new Col();
    col.meta = c;
    col.fd = fd;
    col.name = fd.getName();
    col.label = labelText(c.LabelKey__c) ?? fd.getLabel();
    col.inputType = inputType(c, fd);
    col.editable =
      c.Editable__c == true &&
      fd.isUpdateable() &&
      col.inputType != TYPE_DISPLAY &&
      !fd.isCalculated() &&
      !fd.isAutoNumber();
    col.required =
      c.Required__c == true ||
      (!fd.isNillable() &&
      !fd.isDefaultedOnCreate() &&
      col.inputType != TYPE_CHECKBOX);
    if (col.inputType == TYPE_LOOKUP || col.inputType == TYPE_CODE) {
      setDisplay(col);
    }
    return col;
  }

  /** CODE는 공통 코드 Lookup + 코드 그룹이 있을 때만. 그 밖의 지정은 필드 타입을 따른다. */
  private static String inputType(
    CMN_GridColumn__mdt c,
    Schema.DescribeFieldResult fd
  ) {
    String natural = naturalType(fd.getType());
    if (
      c.InputType__c == TYPE_CODE &&
      natural == TYPE_LOOKUP &&
      fd.getReferenceTo().size() == 1 &&
      fd.getReferenceTo()[0] == CMN_Code__c.SObjectType &&
      String.isNotBlank(c.CodeGroup__c)
    ) {
      return TYPE_CODE;
    }
    return natural;
  }

  private static String naturalType(Schema.DisplayType t) {
    switch on t {
      when BOOLEAN {
        return TYPE_CHECKBOX;
      }
      when DATE {
        return TYPE_DATE;
      }
      when DOUBLE, INTEGER, LONG, CURRENCY, PERCENT {
        return TYPE_NUMBER;
      }
      when PICKLIST {
        return TYPE_PICKLIST;
      }
      when REFERENCE {
        return TYPE_LOOKUP;
      }
      when STRING, TEXTAREA, EMAIL, PHONE, URL {
        return TYPE_TEXT;
      }
      when else {
        return TYPE_DISPLAY;
      }
    }
  }

  /** 참조 열 표시명: 대상 객체의 DisplayName__c(사용자 언어, I18N-001) 또는 이름 필드. 읽을 수 없으면 표시명 없이 Id. */
  private static void setDisplay(Col col) {
    List<Schema.SObjectType> targets = col.fd.getReferenceTo();
    if (targets.size() != 1 || String.isBlank(col.fd.getRelationshipName())) {
      return;
    }
    Schema.DescribeSObjectResult td = targets[0]
      .getDescribe(SObjectDescribeOptions.DEFERRED);
    col.referenceTo = td.getName();
    if (!td.isAccessible()) {
      return;
    }
    Map<String, Schema.SObjectField> tf = td.fields.getMap();
    String nameField = nameFieldOf(tf);
    if (nameField == null) {
      return;
    }
    Schema.DescribeFieldResult display = tf.get(DISPLAY_NAME)?.getDescribe();
    col.nameField = nameField;
    col.labelField = (display != null && display.isAccessible())
      ? display.getName()
      : nameField;
    col.relationshipName = col.fd.getRelationshipName();
  }

  private static String nameFieldOf(Map<String, Schema.SObjectField> tf) {
    Schema.DescribeFieldResult name = tf.get('Name')?.getDescribe();
    if (name != null && name.isNameField()) {
      return name.isAccessible() ? name.getName() : null;
    }
    for (Schema.SObjectField f : tf.values()) {
      Schema.DescribeFieldResult d = f.getDescribe();
      if (d.isNameField()) {
        return d.isAccessible() ? d.getName() : null;
      }
    }
    return null;
  }

  private static void parseFilter(Context ctx) {
    Integer n = 0;
    for (FilterTerm t : parseTerms(ctx.gridKey, ctx.def.Filter__c)) {
      Schema.DescribeFieldResult fd = fieldDescribe(ctx.fieldMap, t.fieldPath);
      if (fd == null || !fd.isFilterable()) {
        throw configError(ctx.gridKey, 'filter ' + t.fieldPath);
      }
      if (!fd.isAccessible()) {
        throw new CMN_ValidationException(Label.CMN_Grid_NoAccess);
      }
      t.fieldPath = fd.getName();
      ctx.filter.add(t);
      ctx.filterValues.put('f' + n, typedValue(ctx.gridKey, fd, t.value));
      n++;
    }
  }

  /** "Field__c=VALUE, Other__c=X" → 조건 목록. 형식이 틀리면 설정 오류(필터를 조용히 버리면 행이 더 보일 수 있다). */
  private static List<FilterTerm> parseTerms(String gridKey, String spec) {
    List<FilterTerm> out = new List<FilterTerm>();
    if (String.isBlank(spec)) {
      return out;
    }
    for (String part : spec.split(',')) {
      if (String.isBlank(part)) {
        continue;
      }
      List<String> kv = part.split('=', 2);
      String field = kv[0].trim();
      if (kv.size() != 2 || !FIELD_PATTERN.matcher(field).matches()) {
        throw configError(gridKey, 'filter ' + part);
      }
      FilterTerm t = new FilterTerm();
      t.fieldPath = field;
      t.value = kv[1].trim();
      out.add(t);
    }
    return out;
  }

  private static Object typedValue(
    String gridKey,
    Schema.DescribeFieldResult fd,
    String raw
  ) {
    if (String.isBlank(raw) || raw == 'null') {
      return null;
    }
    try {
      switch on fd.getType() {
        when BOOLEAN {
          return raw.equalsIgnoreCase('true');
        }
        when DOUBLE, CURRENCY, PERCENT {
          return Decimal.valueOf(raw);
        }
        when INTEGER {
          return Integer.valueOf(raw);
        }
        when LONG {
          return Long.valueOf(raw);
        }
        when DATE {
          return Date.valueOf(raw);
        }
        when else {
          return raw;
        }
      }
    } catch (Exception e) {
      throw configError(gridKey, 'filter value ' + fd.getName());
    }
  }

  private static CMN_GridProvider provider(CMN_GridDefinition__mdt def) {
    if (
      providerOverride != null &&
      providerOverride.containsKey(def.DeveloperName)
    ) {
      return providerOverride.get(def.DeveloperName);
    }
    String name = def.ProviderClass__c;
    if (String.isBlank(name)) {
      return new Unrestricted();
    }
    Object instance;
    try {
      instance = CLASS_PATTERN.matcher(name).matches()
        ? Type.forName(name)?.newInstance()
        : null;
    } catch (Exception e) {
      instance = null;
    }
    if (!(instance instanceof CMN_GridProvider)) {
      throw configError(def.DeveloperName, 'provider ' + name);
    }
    return (CMN_GridProvider) instance;
  }

  /** ProviderClass__c가 비었을 때: 제약 없음 */
  private class Unrestricted extends CMN_GridProviderBase {
  }

  // ------------------------------------------------------------------ 로드
  private static GridView view(Context ctx) {
    List<SObject> rows = CMN_GridSelector.query(
      rowQuery(ctx),
      rowBinds(ctx, ctx.maxRows + 1)
    );
    GridView v = new GridView();
    v.gridKey = ctx.gridKey;
    v.objectApiName = ctx.rowDescribe.getName();
    v.maxRows = ctx.maxRows;
    v.clientVersion = version(ctx, rows);
    v.truncated = rows.size() > ctx.maxRows;
    while (rows.size() > ctx.maxRows) {
      rows.remove(rows.size() - 1);
    }
    Boolean gridEditable = editable(ctx);
    v.editable = gridEditable;
    v.allowAdd =
      gridEditable &&
      ctx.def.AllowAdd__c == true &&
      ctx.rowDescribe.isCreateable();
    v.allowDelete =
      gridEditable &&
      ctx.def.AllowDelete__c == true &&
      ctx.rowDescribe.isDeletable();
    v.allowPaste = gridEditable && ctx.def.AllowPaste__c == true;
    for (Col c : ctx.cols) {
      v.columns.add(columnView(ctx, c, gridEditable));
    }
    String startField = scheduleField(ctx, ctx.def.ScheduleStartField__c);
    String endField = scheduleField(ctx, ctx.def.ScheduleEndField__c);
    if (startField != null && endField != null) {
      v.scheduleStartField = startField;
      v.scheduleEndField = endField;
    }
    Map<Id, CMN_GridRowMeta> metas = rowMetas(ctx, rows);
    for (SObject r : rows) {
      v.rows.add(rowView(ctx, r, metas.get(r.Id)));
    }
    if (v.allowAdd) {
      v.defaults = clientDefaults(ctx);
    }
    return v;
  }

  private static Boolean editable(Context ctx) {
    if (ctx.editable == null) {
      Boolean ok =
        (ctx.rowDescribe.isUpdateable() || ctx.rowDescribe.isCreateable()) &&
        CMN_GridSelector.hasEditAccess(ctx.parentId);
      if (ok && String.isNotBlank(ctx.def.EditRuleKey__c)) {
        ok = CMN_UiRuleService.canExecute(ctx.parentId, ctx.def.EditRuleKey__c);
      }
      ctx.editable = ok;
    }
    return ctx.editable;
  }

  private static ColumnView columnView(
    Context ctx,
    Col c,
    Boolean gridEditable
  ) {
    ColumnView v = new ColumnView();
    v.fieldApiName = c.name;
    v.label = c.label;
    v.inputType = c.inputType;
    v.editable = gridEditable && c.editable;
    v.required = c.required;
    v.frozen = c.meta.Frozen__c == true;
    v.widthWeight = c.meta.WidthWeight__c?.intValue();
    v.showOnPhone = c.meta.ShowOnPhone__c == true;
    v.isNameField = c.fd.isNameField();
    v.scale = c.fd.getScale();
    v.length = c.fd.getLength();
    if (c.inputType == TYPE_PICKLIST) {
      v.options = new List<Option>();
      for (Schema.PicklistEntry e : c.fd.getPicklistValues()) {
        if (e.isActive()) {
          Option o = new Option();
          o.value = e.getValue();
          o.label = e.getLabel();
          v.options.add(o);
        }
      }
    }
    if (c.inputType == TYPE_LOOKUP || c.inputType == TYPE_CODE) {
      v.referenceTo = c.referenceTo;
      v.lookupFilter = parseTerms(ctx.gridKey, c.meta.LookupFilter__c);
    }
    if (c.inputType == TYPE_CODE) {
      v.codeGroup = c.meta.CodeGroup__c;
    }
    return v;
  }

  /** 일정 막대 필드는 보이는 날짜 열이어야 한다(행 값이 화면에 있어야 그린다). */
  private static String scheduleField(Context ctx, String field) {
    Col c = String.isBlank(field)
      ? null
      : ctx.colByField.get(fieldDescribe(ctx.fieldMap, field)?.getName());
    return c != null && c.inputType == TYPE_DATE ? c.name : null;
  }

  private static Map<String, Object> rowView(
    Context ctx,
    SObject r,
    CMN_GridRowMeta meta
  ) {
    Map<String, Object> m = new Map<String, Object>{ 'Id' => r.Id };
    for (Col c : ctx.cols) {
      m.put(c.name, r.get(c.name));
      if (c.relationshipName != null) {
        m.put(
          DISPLAY_PREFIX + c.name,
          r.getSObject(c.relationshipName)?.get(c.labelField)
        );
      }
    }
    m.put('__deletable', meta == null || meta.deletable != false);
    m.put('__deleteBlocked', meta?.deleteBlockedLabel);
    m.put(
      '__locked',
      meta?.lockedFields == null
        ? new List<String>()
        : new List<String>(meta.lockedFields)
    );
    m.put('__warning', meta?.warningLabel);
    return m;
  }

  private static Map<String, Object> clientDefaults(Context ctx) {
    Map<String, Object> out = new Map<String, Object>();
    Map<String, Object> defaults = ctx.provider.defaults(ctx.parentId) ??
      new Map<String, Object>();
    for (String field : defaults.keySet()) {
      Col c = ctx.colByField.get(fieldDescribe(ctx.fieldMap, field)?.getName());
      if (c != null && c.editable) {
        out.put(c.name, defaults.get(field));
      }
    }
    return out;
  }

  private static Map<Id, CMN_GridRowMeta> rowMetas(
    Context ctx,
    List<SObject> rows
  ) {
    if (rows.isEmpty()) {
      return new Map<Id, CMN_GridRowMeta>();
    }
    return ctx.provider.rowMeta(ctx.parentId, rows) ??
      new Map<Id, CMN_GridRowMeta>();
  }

  private static String rowQuery(Context ctx) {
    Set<String> fields = new Set<String>{ 'Id', 'LastModifiedDate' };
    for (Col c : ctx.cols) {
      fields.add(c.name);
      if (c.relationshipName != null) {
        fields.add(c.relationshipName + '.' + c.labelField);
      }
    }
    if (ctx.orderField != null) {
      fields.add(ctx.orderField);
    }
    List<String> escaped = new List<String>();
    for (String f : fields) {
      escaped.add(String.escapeSingleQuotes(f));
    }
    String soql =
      'SELECT ' +
      String.join(escaped, ', ') +
      ' FROM ' +
      String.escapeSingleQuotes(ctx.rowDescribe.getName()) +
      ' WHERE ' +
      String.escapeSingleQuotes(ctx.parentField) +
      ' = :parentId';
    for (Integer i = 0; i < ctx.filter.size(); i++) {
      soql +=
        ' AND ' +
        String.escapeSingleQuotes(ctx.filter[i].fieldPath) +
        ' = :f' +
        i;
    }
    soql +=
      ' ORDER BY ' +
      (ctx.orderField == null
        ? ''
        : String.escapeSingleQuotes(ctx.orderField) + ' ASC NULLS LAST, ') +
      'CreatedDate ASC, Id ASC LIMIT :lim';
    return soql;
  }

  private static Map<String, Object> rowBinds(Context ctx, Integer lim) {
    Map<String, Object> binds = new Map<String, Object>(ctx.filterValues);
    binds.put('parentId', ctx.parentId);
    binds.put('lim', lim);
    return binds;
  }

  /**
   * 행 수 + 최대 LastModifiedDate + 보이는 열 값 해시. 다른 사용자가 행을 더하거나 지우거나 고치면 달라진다(BR-5).
   * LastModifiedDate는 초 단위라 같은 초 안의 저장을 놓칠 수 있어 값 해시를 더한다.
   */
  private static String version(Context ctx, List<SObject> rows) {
    Long latest = 0;
    List<String> parts = new List<String>();
    for (SObject r : rows) {
      Datetime d = (Datetime) r.get('LastModifiedDate');
      if (d != null && d.getTime() > latest) {
        latest = d.getTime();
      }
      parts.add(String.valueOf(r.Id));
      for (Col c : ctx.cols) {
        parts.add(String.valueOf(r.get(c.name)));
      }
    }
    String hash = EncodingUtil.convertToHex(
        Crypto.generateDigest('SHA-256', Blob.valueOf(String.join(parts, '|')))
      )
      .left(16);
    return rows.size() + ':' + latest + ':' + hash;
  }

  // ------------------------------------------------------------------ 저장
  private class RowInput {
    public String key;
    public Id id;
    public Map<String, Object> values;
  }

  private class Plan {
    public List<SObject> merged = new List<SObject>();
    public List<SObject> dml;
    public List<String> keys = new List<String>();
  }

  private class Errors {
    public Map<String, RowError> rows = new Map<String, RowError>();
    public List<String> grid = new List<String>();
    public List<String> logs = new List<String>();

    public void row(String key, String field, String message) {
      RowError e = rows.get(key);
      if (e == null) {
        e = new RowError();
        e.key = key;
        rows.put(key, e);
      }
      if (!e.messages.contains(message)) {
        e.messages.add(message);
      }
      if (field != null && !e.fieldNames.contains(field)) {
        e.fieldNames.add(field);
      }
    }

    public Boolean isEmpty() {
      return rows.isEmpty() && grid.isEmpty();
    }

    public void addValidation(CMN_GridValidation val, List<String> keys) {
      if (val == null) {
        return;
      }
      for (CMN_GridValidation.Issue i : val.rowIssues) {
        Boolean known =
          i.rowIndex != null &&
          i.rowIndex >= 0 &&
          i.rowIndex < keys.size();
        if (known) {
          row(keys[i.rowIndex], i.fieldApiName, i.message);
        } else {
          grid.add(i.message);
        }
      }
      grid.addAll(val.gridErrors);
    }

    public void copyTo(SaveResult r) {
      r.rowErrors.addAll(rows.values());
      r.gridErrors.addAll(grid);
    }

    public void log(String gridKey, Id parentId, Exception failure) {
      if (failure == null && logs.isEmpty()) {
        return;
      }
      CMN_Logger.error(
        'CMN_GridService.save',
        gridKey +
          ' ' +
          String.join(logs, ' / ') +
          (failure == null ? '' : ' ' + failure.getMessage()),
        parentId,
        failure
      );
    }
  }

  private static List<RowInput> parseRows(
    String rowsJson,
    Context ctx,
    Set<Id> deletes
  ) {
    List<RowInput> out = new List<RowInput>();
    if (String.isBlank(rowsJson)) {
      return out;
    }
    if (rowsJson.length() > MAX_JSON_LENGTH) {
      throw new CMN_ValidationException(Label.CMN_Grid_InvalidRequest);
    }
    Object parsed;
    try {
      parsed = JSON.deserializeUntyped(rowsJson);
    } catch (JSONException e) {
      throw new CMN_ValidationException(Label.CMN_Grid_InvalidRequest);
    }
    if (!(parsed instanceof List<Object>)) {
      throw new CMN_ValidationException(Label.CMN_Grid_InvalidRequest);
    }
    Set<String> keys = new Set<String>();
    for (Object o : (List<Object>) parsed) {
      RowInput r = toInput(o, ctx);
      if (!keys.add(r.key)) {
        throw new CMN_ValidationException(Label.CMN_Grid_InvalidRequest);
      }
      if (r.id == null || !deletes.contains(r.id)) {
        out.add(r); // 삭제할 행의 수정은 버린다
      }
    }
    return out;
  }

  private static RowInput toInput(Object o, Context ctx) {
    Map<String, Object> m = o instanceof Map<String, Object>
      ? (Map<String, Object>) o
      : null;
    Object key = m?.get('key');
    Object values = m?.get('values');
    if (
      !(key instanceof String) ||
      String.isBlank((String) key) ||
      ((String) key).length() > MAX_KEY_LENGTH ||
      (values != null && !(values instanceof Map<String, Object>))
    ) {
      throw new CMN_ValidationException(Label.CMN_Grid_InvalidRequest);
    }
    RowInput r = new RowInput();
    r.key = (String) key;
    r.values = values == null
      ? new Map<String, Object>()
      : (Map<String, Object>) values;
    Object rawId = m.get('id');
    if (rawId != null) {
      r.id = asId(String.valueOf(rawId), ctx.rowDescribe.getSObjectType());
      if (r.id == null) {
        throw new CMN_ValidationException(Label.CMN_Grid_InvalidRequest);
      }
    }
    return r;
  }

  private static Plan buildPlan(
    Context ctx,
    List<RowInput> inputs,
    Map<Id, SObject> byId,
    Map<Id, CMN_GridRowMeta> metas,
    Errors errors
  ) {
    Plan plan = new Plan();
    // upsert는 구체 타입 목록이어야 한다
    plan.dml = (List<SObject>) Type.forName(
        'List<' + ctx.rowDescribe.getName() + '>'
      )
      .newInstance();
    Schema.SObjectType rowType = ctx.rowDescribe.getSObjectType();
    Boolean canAdd =
      ctx.def.AllowAdd__c == true && ctx.rowDescribe.isCreateable();
    Map<String, Object> defaults;
    Decimal nextOrder = nextOrder(ctx, byId.values());
    for (RowInput input : inputs) {
      SObject current = input.id == null ? null : byId.get(input.id);
      if (input.id != null && current == null) {
        errors.row(input.key, null, Label.CMN_Grid_RowNotFound);
        continue;
      }
      if (input.id == null && !canAdd) {
        errors.row(input.key, null, Label.CMN_Grid_NotEditable);
        continue;
      }
      SObject merged;
      SObject change;
      if (current != null) {
        merged = current.clone(true, false);
        change = rowType.newSObject(input.id);
      } else {
        defaults = defaults ??
          (ctx.provider.defaults(ctx.parentId) ?? new Map<String, Object>());
        merged = rowType.newSObject();
        change = rowType.newSObject();
        newRowValues(ctx, defaults, nextOrder, merged, change);
        nextOrder += 1;
      }
      applyValues(
        ctx,
        input,
        current,
        metas.get(input.id),
        merged,
        change,
        errors
      );
      checkRequired(ctx, input.key, merged, errors);
      plan.merged.add(merged);
      plan.dml.add(change);
      plan.keys.add(input.key);
    }
    return plan;
  }

  /** 새 행: Provider 기본값 → 부모 → 순서(마지막 + 1). 화면 값이 이어서 덮어쓴다. */
  private static void newRowValues(
    Context ctx,
    Map<String, Object> defaults,
    Decimal order,
    SObject merged,
    SObject change
  ) {
    for (String field : defaults.keySet()) {
      Schema.DescribeFieldResult fd = fieldDescribe(ctx.fieldMap, field);
      if (fd == null || !fd.isCreateable()) {
        continue;
      }
      try {
        merged.put(fd.getName(), defaults.get(field));
        change.put(fd.getName(), defaults.get(field));
      } catch (SObjectException e) {
        throw configError(ctx.gridKey, 'default ' + field);
      }
    }
    merged.put(ctx.parentField, ctx.parentId);
    change.put(ctx.parentField, ctx.parentId);
    Schema.DescribeFieldResult orderFd = fieldDescribe(
      ctx.fieldMap,
      ctx.orderField
    );
    if (orderFd != null && orderFd.isCreateable()) {
      merged.put(ctx.orderField, order);
      change.put(ctx.orderField, order);
    }
  }

  private static Decimal nextOrder(Context ctx, List<SObject> rows) {
    Decimal max = 0;
    if (ctx.orderField == null) {
      return 1;
    }
    for (SObject r : rows) {
      Object v = r.get(ctx.orderField);
      if (v instanceof Decimal && (Decimal) v > max) {
        max = (Decimal) v;
      }
    }
    return max.round(System.RoundingMode.FLOOR) + 1;
  }

  private static void applyValues(
    Context ctx,
    RowInput input,
    SObject current,
    CMN_GridRowMeta meta,
    SObject merged,
    SObject change,
    Errors errors
  ) {
    Set<String> locked = meta?.lockedFields ?? new Set<String>();
    for (String field : input.values.keySet()) {
      Col col = ctx.colByField.get(field);
      if (col == null || !col.editable) {
        errors.row(
          input.key,
          null,
          String.format(
            Label.CMN_Grid_ColumnNotEditable,
            new List<Object>{ col?.label ?? field }
          )
        );
        continue;
      }
      Object value;
      try {
        value = convert(col, input.values.get(field));
      } catch (CMN_ValidationException e) {
        errors.row(
          input.key,
          col.name,
          String.format(
            Label.CMN_Grid_InvalidValue,
            new List<Object>{ col.label }
          )
        );
        continue;
      }
      if (
        current != null &&
        locked.contains(col.name) &&
        !sameValue(current.get(col.name), value)
      ) {
        errors.row(
          input.key,
          col.name,
          String.format(
            Label.CMN_Grid_CellLocked,
            new List<Object>{ col.label }
          )
        );
        continue;
      }
      merged.put(col.name, value);
      change.put(col.name, value);
    }
  }

  private static void checkRequired(
    Context ctx,
    String key,
    SObject merged,
    Errors errors
  ) {
    List<String> missing = new List<String>();
    List<String> fields = new List<String>();
    for (Col c : ctx.cols) {
      if (c.required && c.editable && isBlank(merged.get(c.name))) {
        missing.add(c.label);
        fields.add(c.name);
      }
    }
    if (missing.isEmpty()) {
      return;
    }
    String message = String.format(
      Label.CMN_Grid_RequiredMissing,
      new List<Object>{ String.join(missing, ', ') }
    );
    for (String f : fields) {
      errors.row(key, f, message);
    }
  }

  private static void checkDeletes(
    Context ctx,
    List<Id> deletes,
    Map<Id, SObject> byId,
    Map<Id, CMN_GridRowMeta> metas,
    Errors errors
  ) {
    if (deletes.isEmpty()) {
      return;
    }
    if (!(ctx.def.AllowDelete__c == true && ctx.rowDescribe.isDeletable())) {
      errors.grid.add(Label.CMN_Grid_NotEditable);
      return;
    }
    for (Id rowId : deletes) {
      String key = String.valueOf(rowId);
      if (!byId.containsKey(rowId)) {
        errors.row(key, null, Label.CMN_Grid_RowNotFound);
        continue;
      }
      CMN_GridRowMeta meta = metas.get(rowId);
      if (meta != null && meta.deletable == false) {
        errors.row(
          key,
          null,
          String.isBlank(meta.deleteBlockedLabel)
            ? Label.CMN_Grid_DeleteBlocked
            : meta.deleteBlockedLabel
        );
      }
    }
  }

  /** upsert 1회 + delete 1회(사용자 권한). 실패 행은 행 오류로 모은다(호출한 쪽이 Savepoint로 되돌린다). */
  private static void write(
    Context ctx,
    Plan plan,
    List<Id> deletes,
    Errors errors
  ) {
    if (!plan.dml.isEmpty()) {
      List<Database.UpsertResult> results = Database.upsert(
        plan.dml,
        false,
        AccessLevel.USER_MODE
      );
      for (Integer i = 0; i < results.size(); i++) {
        if (results[i].isSuccess()) {
          plan.merged[i].put('Id', results[i].getId());
          continue;
        }
        for (Database.Error e : results[i].getErrors()) {
          errors.row(
            plan.keys[i],
            firstField(ctx, e),
            dmlMessage(ctx, e, errors)
          );
        }
      }
    }
    if (errors.isEmpty() && !deletes.isEmpty()) {
      List<Database.DeleteResult> results = Database.delete(
        deletes,
        false,
        AccessLevel.USER_MODE
      );
      for (Integer i = 0; i < results.size(); i++) {
        if (!results[i].isSuccess()) {
          for (Database.Error e : results[i].getErrors()) {
            errors.row(
              String.valueOf(deletes[i]),
              null,
              dmlMessage(ctx, e, errors)
            );
          }
        }
      }
    }
  }

  private static String firstField(Context ctx, Database.Error e) {
    for (String f : e.getFields() ?? new List<String>()) {
      Schema.DescribeFieldResult fd = fieldDescribe(ctx.fieldMap, f);
      if (fd != null) {
        return fd.getName();
      }
    }
    return null;
  }

  /** 검증 규칙·addError 문구는 이미 사용자용 문구라 그대로, 그 밖의 시스템 오류는 라벨로 바꾸고 원문은 로그에 남긴다. */
  private static String dmlMessage(
    Context ctx,
    Database.Error e,
    Errors errors
  ) {
    StatusCode code = e.getStatusCode();
    if (code == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
      return e.getMessage();
    }
    if (code == StatusCode.REQUIRED_FIELD_MISSING) {
      List<String> labels = new List<String>();
      for (String f : e.getFields() ?? new List<String>()) {
        labels.add(fieldDescribe(ctx.fieldMap, f)?.getLabel() ?? f);
      }
      return String.format(
        Label.CMN_Grid_RequiredMissing,
        new List<Object>{ String.join(labels, ', ') }
      );
    }
    if (
      code == StatusCode.INSUFFICIENT_ACCESS_OR_READONLY ||
      code == StatusCode.INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
    ) {
      return Label.CMN_Grid_NotEditable;
    }
    errors.logs.add(code + ': ' + e.getMessage());
    return Label.CMN_Grid_SaveFailed;
  }

  /** 화면 값(JSON) → 필드 타입 값. 형식이 틀리면 CMN_ValidationException. 빈 값은 null(체크박스는 false). */
  private static Object convert(Col col, Object raw) {
    Schema.DisplayType t = col.fd.getType();
    if (isBlank(raw)) {
      return t == Schema.DisplayType.BOOLEAN ? (Object) false : null;
    }
    String s = String.valueOf(raw).trim();
    Object out;
    try {
      switch on t {
        when BOOLEAN {
          out = s.equalsIgnoreCase('true')
            ? (Object) true
            : (s.equalsIgnoreCase('false') ? (Object) false : null);
        }
        when DATE {
          out = DATE_PATTERN.matcher(s).matches() ? Date.valueOf(s) : null;
        }
        when DOUBLE, CURRENCY, PERCENT {
          out = Decimal.valueOf(s);
        }
        when INTEGER {
          out = Integer.valueOf(s);
        }
        when LONG {
          out = Long.valueOf(s);
        }
        when REFERENCE {
          Id refId = asId(s, null);
          out = refId != null &&
            col.fd.getReferenceTo().contains(refId.getSObjectType())
            ? refId
            : null;
        }
        when PICKLIST {
          out = picklistValues(col).contains(s) ? s : null;
        }
        when STRING, TEXTAREA, EMAIL, PHONE, URL {
          out = s.length() <= col.fd.getLength() ? s : null;
        }
      }
    } catch (Exception e) {
      out = null;
    }
    if (out == null) {
      throw new CMN_ValidationException(Label.CMN_Grid_InvalidValue);
    }
    return out;
  }

  private static Set<String> picklistValues(Col col) {
    String cacheKey = col.fd.getSObjectType() + '.' + col.name;
    if (!picklistCache.containsKey(cacheKey)) {
      Set<String> values = new Set<String>();
      for (Schema.PicklistEntry e : col.fd.getPicklistValues()) {
        if (e.isActive()) {
          values.add(e.getValue());
        }
      }
      picklistCache.put(cacheKey, values);
    }
    return picklistCache.get(cacheKey);
  }

  // ------------------------------------------------------------------ 참조 확인
  private static Map<String, List<String>> parseKeys(String keysJson) {
    Map<String, List<String>> out = new Map<String, List<String>>();
    Object parsed;
    try {
      parsed = String.isBlank(keysJson)
        ? null
        : JSON.deserializeUntyped(keysJson);
    } catch (JSONException e) {
      parsed = null;
    }
    if (!(parsed instanceof Map<String, Object>)) {
      throw new CMN_ValidationException(Label.CMN_Grid_InvalidRequest);
    }
    Map<String, Object> m = (Map<String, Object>) parsed;
    for (String field : m.keySet()) {
      if (!(m.get(field) instanceof List<Object>)) {
        throw new CMN_ValidationException(Label.CMN_Grid_InvalidRequest);
      }
      Set<String> keys = new Set<String>();
      for (Object v : (List<Object>) m.get(field)) {
        String s = v == null ? '' : String.valueOf(v).trim();
        if (String.isNotBlank(s) && s.length() <= 255) {
          keys.add(s);
        }
      }
      out.put(field, new List<String>(keys));
    }
    return out;
  }

  private static List<LookupMatch> matchLookups(
    Context ctx,
    Col col,
    List<String> keys
  ) {
    List<LookupMatch> out = new List<LookupMatch>();
    if (keys == null || keys.isEmpty()) {
      return out;
    }
    Schema.DescribeSObjectResult td = describe(col.referenceTo);
    Map<String, Schema.SObjectField> tf = td.fields.getMap();
    List<String> keyFields = keyFieldsOf(tf, col.nameField);
    List<String> names = new List<String>();
    List<Id> ids = new List<Id>();
    for (String k : keys) {
      Id maybe = asId(k, td.getSObjectType());
      if (maybe != null) {
        ids.add(maybe);
      } else {
        names.add(k);
      }
    }
    Set<String> fields = new Set<String>{ 'Id', col.labelField };
    fields.addAll(keyFields);
    List<String> escaped = new List<String>();
    for (String f : fields) {
      escaped.add(String.escapeSingleQuotes(f));
    }
    Map<String, Object> binds = new Map<String, Object>{
      'names' => names,
      'ids' => ids,
      'lim' => MAX_LOOKUP_ROWS
    };
    String soql =
      'SELECT ' +
      String.join(escaped, ', ') +
      ' FROM ' +
      String.escapeSingleQuotes(td.getName()) +
      ' WHERE (Id IN :ids';
    for (String f : keyFields) {
      soql += ' OR ' + String.escapeSingleQuotes(f) + ' IN :names';
    }
    soql += ')' + lookupFilterClause(ctx, col, tf, binds) + ' LIMIT :lim';
    Map<String, Set<Id>> hits = new Map<String, Set<Id>>();
    Map<Id, String> labels = new Map<Id, String>();
    for (SObject s : CMN_GridSelector.query(soql, binds)) {
      labels.put(
        s.Id,
        String.valueOf(s.get(col.labelField) ?? s.get(col.nameField))
      );
      for (String f : keyFields) {
        index(hits, String.valueOf(s.get(f)), s.Id);
      }
    }
    for (String k : keys) {
      LookupMatch m = new LookupMatch();
      m.fieldApiName = col.name;
      m.key = k;
      Id asIdKey = asId(k, td.getSObjectType());
      Set<Id> found = asIdKey != null
        ? (labels.containsKey(asIdKey) ? new Set<Id>{ asIdKey } : null)
        : hits.get(k.toLowerCase());
      if (found != null && found.size() == 1) {
        m.id = new List<Id>(found)[0];
        m.label = labels.get(m.id);
      } else if (found != null && found.size() > 1) {
        m.ambiguous = true;
      }
      out.add(m);
    }
    return out;
  }

  /**
   * 붙여넣은 값과 맞춰 볼 대상 필드: 이름 필드 + 외부 키(ExternalKey__c, External ID 텍스트 필드 — 공장 코드·품번·벤더 번호 등).
   * 엑셀에는 레코드 이름보다 업무 코드가 들어 있는 경우가 많다. 조회 조건이 커지지 않게 이름 외 최대 3개.
   */
  private static List<String> keyFieldsOf(
    Map<String, Schema.SObjectField> tf,
    String nameField
  ) {
    List<String> out = new List<String>{ nameField };
    for (Schema.SObjectField f : tf.values()) {
      Schema.DescribeFieldResult d = f.getDescribe();
      Boolean isKey =
        d.getName() == EXTERNAL_KEY ||
        (d.isExternalId() && d.getType() == Schema.DisplayType.STRING);
      if (
        isKey &&
        d.isAccessible() &&
        d.isFilterable() &&
        !out.contains(d.getName()) &&
        out.size() < MAX_KEY_FIELDS
      ) {
        out.add(d.getName());
      }
    }
    return out;
  }

  /** Lookup 고정 필터(LookupFilter__c)와 CODE 열의 코드 그룹·활성 조건. */
  private static String lookupFilterClause(
    Context ctx,
    Col col,
    Map<String, Schema.SObjectField> tf,
    Map<String, Object> binds
  ) {
    String clause = '';
    Integer n = 0;
    for (FilterTerm t : parseTerms(ctx.gridKey, col.meta.LookupFilter__c)) {
      Schema.DescribeFieldResult fd = fieldDescribe(tf, t.fieldPath);
      if (fd == null || !fd.isFilterable() || !fd.isAccessible()) {
        throw configError(ctx.gridKey, 'lookup filter ' + t.fieldPath);
      }
      clause +=
        ' AND ' +
        String.escapeSingleQuotes(fd.getName()) +
        ' = :lf' +
        n;
      binds.put('lf' + n, typedValue(ctx.gridKey, fd, t.value));
      n++;
    }
    if (col.inputType == TYPE_CODE) {
      clause += ' AND CodeGroup__r.GroupCode__c = :codeGroup AND IsActive__c = TRUE';
      binds.put('codeGroup', col.meta.CodeGroup__c);
    }
    return clause;
  }

  private static void index(Map<String, Set<Id>> hits, String key, Id recId) {
    if (String.isBlank(key)) {
      return;
    }
    String k = key.toLowerCase();
    if (!hits.containsKey(k)) {
      hits.put(k, new Set<Id>());
    }
    hits.get(k).add(recId);
  }

  // ------------------------------------------------------------------ 공용
  private static Schema.DescribeSObjectResult describe(String objectApiName) {
    if (
      String.isBlank(objectApiName) ||
      !FIELD_PATTERN.matcher(objectApiName).matches()
    ) {
      return null;
    }
    try {
      return Schema.describeSObjects(
        new List<String>{ objectApiName },
        SObjectDescribeOptions.DEFERRED
      )[0];
    } catch (Exception e) {
      return null;
    }
  }

  private static Schema.DescribeFieldResult fieldDescribe(
    Map<String, Schema.SObjectField> fieldMap,
    String field
  ) {
    return String.isBlank(field) ? null : fieldMap.get(field)?.getDescribe();
  }

  private static Id asId(String value, Schema.SObjectType expected) {
    if (
      String.isBlank(value) || (value.length() != 15 && value.length() != 18)
    ) {
      return null;
    }
    try {
      Id parsed = Id.valueOf(value);
      return expected == null ||
        parsed.getSObjectType() == expected
        ? parsed
        : null;
    } catch (Exception e) {
      return null;
    }
  }

  private static Boolean isBlank(Object v) {
    return v == null || (v instanceof String && String.isBlank((String) v));
  }

  private static Boolean sameValue(Object a, Object b) {
    if (isBlank(a) || isBlank(b)) {
      return isBlank(a) && isBlank(b);
    }
    if (a instanceof Decimal && b instanceof Decimal) {
      return ((Decimal) a) - ((Decimal) b) == 0;
    }
    return a == b;
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

  /** 그리드 설정 오류: 원인은 로그에, 화면에는 그리드 키만. */
  private static CMN_ValidationException configError(
    String gridKey,
    String detail
  ) {
    CMN_Logger.error(
      'CMN_GridService',
      'config ' + gridKey + ': ' + detail,
      null
    );
    return new CMN_ValidationException(
      String.format(Label.CMN_Grid_ConfigError, new List<Object>{ gridKey })
    );
  }
}
