/**
 * @description 상태·권한 화면 제어의 서버 검증(CMN-00-UX-005 BR-1·4·5). 화면의 섹션·버튼 노출(FlexiPage 가시성)과
 * 같은 규칙(CMN_UiRule__mdt)으로 판정한다. 화면에서 숨기는 것만으로는 권한 통제가 아니므로
 * - 업무 액션 Apex는 첫 줄에서 assertCanExecute(recordId, actionKey)를 부른다.
 * - 업무 객체 트리거는 before update에서 addLockErrors(newRecords, oldMap)를 부른다(이전 상태에서 편집할 수 없는 섹션의 필드 변경 차단).
 * - 상태 전이처럼 서비스가 잠긴 필드를 바꿔야 하면 runAsService 안에서 바꾼다.
 * 해석: 대상의 활성 규칙 행 중 하나라도 (상태 ∈ 값 AND 권한 AND 레코드 타입 AND 추가 조건)을 만족하면 허용. 규칙이 없으면 거부(섹션은 읽기 전용).
 * @group CMN-00-UX-005
 */
public with sharing class CMN_UiRuleService {
  public static final String TARGET_SECTION = 'SECTION';
  public static final String TARGET_ACTION = 'ACTION';
  public static final String TARGET_COMPONENT = 'COMPONENT';
  public static final String ALL_STATUSES = '*';
  private static final String RECORD_TYPE_FIELD = 'RecordTypeId';
  private static Integer bypassDepth = 0;
  private static Map<String, Boolean> permissionCache = new Map<String, Boolean>();

  /**
   * @description 레코드에 업무 액션(또는 화면 컴포넌트 편집)을 할 수 있는가. 레코드를 사용자 권한으로 읽을 수 없으면 false.
   * @param recordId 업무 레코드 Id
   * @param actionKey ACTION·COMPONENT 규칙의 TargetKey(예: 액션 API명, 그리드 EditRuleKey)
   * @return 허용 여부
   */
  public static Boolean canExecute(Id recordId, String actionKey) {
    if (recordId == null || String.isBlank(actionKey)) {
      return false;
    }
    Schema.DescribeSObjectResult d = recordId.getSObjectType()
      .getDescribe(SObjectDescribeOptions.DEFERRED);
    List<CMN_UiRule__mdt> rows = new List<CMN_UiRule__mdt>();
    for (CMN_UiRule__mdt r : CMN_UiRuleSelector.rules(d.getName())) {
      if (
        r.TargetKey__c == actionKey &&
        (r.TargetType__c == TARGET_ACTION ||
        r.TargetType__c == TARGET_COMPONENT)
      ) {
        rows.add(r);
      }
    }
    if (rows.isEmpty()) {
      return false;
    }
    SObject rec = loadRecord(recordId, d, rows);
    return rec != null && anyAllows(rows, rec, d);
  }

  /**
   * @description canExecute가 false면 업무 액션을 멈춘다.
   * @param recordId 업무 레코드 Id
   * @param actionKey 액션 키
   * @throws CMN_ValidationException 상태·권한상 허용되지 않음(라벨 CMN_UiRule_ActionNotAllowed)
   */
  public static void assertCanExecute(Id recordId, String actionKey) {
    if (!canExecute(recordId, actionKey)) {
      throw new CMN_ValidationException(Label.CMN_UiRule_ActionNotAllowed);
    }
  }

  /**
   * @description 레코드별로, 이전 상태 기준 편집할 수 없는 섹션에서 바뀐 필드. 서비스 우회 중이면 빈 결과.
   * @param newRecords 트리거 새 값
   * @param oldMap 트리거 이전 값
   * @return 레코드 Id → 잠긴 필드 API명
   */
  public static Map<Id, Set<String>> lockedFieldViolations(
    List<SObject> newRecords,
    Map<Id, SObject> oldMap
  ) {
    Map<Id, Set<String>> out = new Map<Id, Set<String>>();
    if (
      bypassDepth > 0 ||
      newRecords == null ||
      newRecords.isEmpty() ||
      oldMap == null
    ) {
      return out;
    }
    Schema.DescribeSObjectResult d = newRecords[0]
      .getSObjectType()
      .getDescribe(SObjectDescribeOptions.DEFERRED);
    List<CMN_UiSection__mdt> sections = CMN_UiRuleSelector.sections(
      d.getName()
    );
    if (sections.isEmpty()) {
      return out;
    }
    Map<String, List<CMN_UiRule__mdt>> bySection = new Map<String, List<CMN_UiRule__mdt>>();
    for (CMN_UiRule__mdt r : CMN_UiRuleSelector.rules(d.getName())) {
      if (r.TargetType__c == TARGET_SECTION) {
        if (!bySection.containsKey(r.TargetKey__c)) {
          bySection.put(r.TargetKey__c, new List<CMN_UiRule__mdt>());
        }
        bySection.get(r.TargetKey__c).add(r);
      }
    }
    for (SObject n : newRecords) {
      SObject o = oldMap.get(n.Id);
      if (o == null) {
        continue;
      }
      Set<String> locked = new Set<String>();
      for (CMN_UiSection__mdt s : sections) {
        List<CMN_UiRule__mdt> rows = bySection.get(s.SectionKey__c) ??
          new List<CMN_UiRule__mdt>();
        if (anyAllows(rows, o, d)) {
          continue;
        }
        for (String f : split(s.Fields__c)) {
          if (n.get(f) != o.get(f)) {
            locked.add(f);
          }
        }
      }
      if (!locked.isEmpty()) {
        out.put(n.Id, locked);
      }
    }
    return out;
  }

  /**
   * @description 트리거 before update용: 잠긴 필드를 바꾼 레코드에 행 오류(라벨 CMN_UiRule_FieldLocked, 필드 라벨 목록).
   * @param newRecords 트리거 새 값
   * @param oldMap 트리거 이전 값
   */
  public static void addLockErrors(
    List<SObject> newRecords,
    Map<Id, SObject> oldMap
  ) {
    Map<Id, Set<String>> violations = lockedFieldViolations(newRecords, oldMap);
    if (violations.isEmpty()) {
      return;
    }
    Map<String, Schema.SObjectField> fieldMap = newRecords[0]
      .getSObjectType()
      .getDescribe(SObjectDescribeOptions.DEFERRED)
      .fields.getMap();
    for (SObject n : newRecords) {
      Set<String> fields = violations.get(n.Id);
      if (fields == null) {
        continue;
      }
      List<String> labels = new List<String>();
      for (String f : fields) {
        labels.add(fieldMap.get(f)?.getDescribe().getLabel() ?? f);
      }
      labels.sort();
      n.addError(
        String.format(
          Label.CMN_UiRule_FieldLocked,
          new List<Object>{ String.join(labels, ', ') }
        )
      );
    }
  }

  /**
   * @description 서비스가 잠긴 필드를 바꿔야 할 때(상태 전이 등) 이 안에서 DML을 한다. 우회는 이 호출 안에서만 유효하다.
   * @param action 실행할 작업(call('run', null)로 부른다)
   * @return 작업 결과
   */
  public static Object runAsService(Callable action) {
    bypassDepth++;
    try {
      return action.call('run', null);
    } finally {
      bypassDepth--;
    }
  }

  // ------------------------------------------------------------------ 내부
  /** 규칙 행 중 하나라도 레코드에 맞으면 true. 행이 없으면 false(기본 거부). */
  private static Boolean anyAllows(
    List<CMN_UiRule__mdt> rows,
    SObject rec,
    Schema.DescribeSObjectResult d
  ) {
    for (CMN_UiRule__mdt r : rows) {
      if (matches(r, rec, d)) {
        return true;
      }
    }
    return false;
  }

  private static Boolean matches(
    CMN_UiRule__mdt r,
    SObject rec,
    Schema.DescribeSObjectResult d
  ) {
    if (r.StatusValues__c != ALL_STATUSES) {
      Object status = valueOf(rec, r.StatusField__c ?? 'Status__c');
      if (
        status == null ||
        !split(r.StatusValues__c).contains(String.valueOf(status))
      ) {
        return false;
      }
    }
    if (
      String.isNotBlank(r.CustomPermission__c) &&
      !hasPermission(r.CustomPermission__c)
    ) {
      return false;
    }
    if (String.isNotBlank(r.RecordTypes__c)) {
      Id rtId = (Id) valueOf(rec, RECORD_TYPE_FIELD);
      Schema.RecordTypeInfo info = rtId == null
        ? null
        : d.getRecordTypeInfosById().get(rtId);
      if (
        info == null ||
        !split(r.RecordTypes__c).contains(info.getDeveloperName())
      ) {
        return false;
      }
    }
    return extraMatches(r.ExtraCondition__c, rec);
  }

  /** 추가 조건 하나: Field__c=VALUE 또는 Field__c!=VALUE(빈 값은 빈 문자열로 비교). */
  private static Boolean extraMatches(String condition, SObject rec) {
    if (String.isBlank(condition)) {
      return true;
    }
    Boolean negate = condition.contains('!=');
    List<String> parts = condition.split(negate ? '!=' : '=', 2);
    if (parts.size() != 2) {
      return false;
    }
    Object v = valueOf(rec, parts[0].trim());
    Boolean equal = (v == null ? '' : String.valueOf(v)) == parts[1].trim();
    return negate ? !equal : equal;
  }

  /** 레코드에 없는(조회하지 않은) 필드는 null. */
  private static Object valueOf(SObject rec, String field) {
    try {
      return rec.get(field);
    } catch (SObjectException e) {
      return null;
    }
  }

  /** 판정에 필요한 필드만 사용자 권한으로 읽는다. 읽을 수 없으면 null. */
  private static SObject loadRecord(
    Id recordId,
    Schema.DescribeSObjectResult d,
    List<CMN_UiRule__mdt> rows
  ) {
    Map<String, Schema.SObjectField> fieldMap = d.fields.getMap();
    Set<String> wanted = new Set<String>{ 'Id' };
    for (CMN_UiRule__mdt r : rows) {
      wanted.add(r.StatusField__c ?? 'Status__c');
      if (String.isNotBlank(r.RecordTypes__c)) {
        wanted.add(RECORD_TYPE_FIELD);
      }
      if (String.isNotBlank(r.ExtraCondition__c)) {
        wanted.add(r.ExtraCondition__c.split('!?=', 2)[0].trim());
      }
    }
    List<String> fields = new List<String>();
    for (String f : wanted) {
      Schema.SObjectField sf = fieldMap.get(f);
      if (sf != null) {
        fields.add(String.escapeSingleQuotes(sf.getDescribe().getName()));
      }
    }
    try {
      List<SObject> rows2 = Database.queryWithBinds(
        'SELECT ' +
          String.join(fields, ', ') +
          ' FROM ' +
          String.escapeSingleQuotes(d.getName()) +
          ' WHERE Id = :rid LIMIT 1',
        new Map<String, Object>{ 'rid' => recordId },
        AccessLevel.USER_MODE
      );
      return rows2.isEmpty() ? null : rows2[0];
    } catch (QueryException e) {
      // 객체·필드 권한이 없으면 실행할 수 없다
      return null;
    }
  }

  private static Boolean hasPermission(String customPermission) {
    if (!permissionCache.containsKey(customPermission)) {
      Boolean granted;
      try {
        granted = FeatureManagement.checkPermission(customPermission);
      } catch (Exception e) {
        // 아직 배포되지 않은 Custom Permission은 없는 권한으로 본다
        granted = false;
      }
      permissionCache.put(customPermission, granted);
    }
    return permissionCache.get(customPermission);
  }

  private static Set<String> split(String csv) {
    Set<String> out = new Set<String>();
    for (String s : (csv ?? '').split(',')) {
      if (String.isNotBlank(s)) {
        out.add(s.trim());
      }
    }
    return out;
  }
}
