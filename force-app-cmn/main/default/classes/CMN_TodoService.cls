/**
 * @description 통합 To-Do 서비스(CMN-00-TDO-001). 사람에게 일을 시키는 모든 기능은 이 서비스로 To-Do를 열고 닫는다.
 * - open: ExternalKey(`{SourceType}/{SourceRecordId}/{AssigneeId}`) 기준 upsert. 이미 OPEN이면 무시, 끝난 To-Do는 다시 연다.
 * - close/cancel: 원천 레코드의 OPEN To-Do를 DONE/CANCELLED로 바꾼다.
 * - Owner = Assignee(BR-1). 레코드를 소유할 수 없는 사용자 유형(대량 포털·게스트)은 Owner를 바꾸지 않는다.
 * - 변경마다 CMN_TodoChanged__e를 발행한다(BR-4, TDO-003 푸시).
 * 제목은 받는 사람 언어로 renderTitle이 만든다(BR-3). TitleFallback__c는 기본 언어 렌더링 사본이다(검색·리포트).
 * @group CMN-00-TDO-001
 */
public with sharing class CMN_TodoService {
  public static final String OPEN = 'OPEN';
  public static final String DONE = 'DONE';
  public static final String CANCELLED = 'CANCELLED';
  /** 결재 단계 To-Do 원천 유형(SourceRecordId = 결재 단계) */
  public static final String SOURCE_APPROVAL = 'CMN_APPROVAL';
  private static final String FALLBACK_LANGUAGE = 'en_US';
  private static final Set<String> OWNER_USER_TYPES = new Set<String>{
    'Standard',
    'PowerPartner',
    'PowerCustomerSuccess'
  };

  /** 테스트에서 발행 이벤트 확인용 */
  @TestVisible
  private static List<CMN_TodoChanged__e> published = new List<CMN_TodoChanged__e>();

  /**
   * @description To-Do를 연다. SOQL 1회·DML 1회(건수와 무관).
   * @param specs 명세
   * @throws CMN_ValidationException 처리자·원천·제목 라벨 누락, 비활성 처리자, 치환값 1000자 초과
   */
  public static void open(List<CMN_TodoSpec> specs) {
    if (specs == null || specs.isEmpty()) {
      return;
    }
    Map<String, CMN_TodoSpec> byKey = new Map<String, CMN_TodoSpec>();
    Set<Id> assignees = new Set<Id>();
    for (CMN_TodoSpec s : specs) {
      validate(s);
      byKey.put(s.externalKey(), s);
      assignees.add(s.assigneeId);
    }
    Map<Id, User> users = CMN_TodoSelector.assigneesWithTodos(
      assignees,
      byKey.keySet()
    );
    Map<String, String> statusByKey = new Map<String, String>();
    for (User u : users.values()) {
      for (CMN_Todo__c t : u.Todos__r) {
        statusByKey.put(t.ExternalKey__c, t.Status__c);
      }
    }

    String defaultLanguage = defaultLanguage();
    List<CMN_Todo__c> rows = new List<CMN_Todo__c>();
    for (String key : byKey.keySet()) {
      if (statusByKey.get(key) == OPEN) {
        continue;
      }
      CMN_TodoSpec s = byKey.get(key);
      User assignee = users.get(s.assigneeId);
      if (assignee == null || !assignee.IsActive) {
        throw new CMN_ValidationException(Label.CMN_Todo_AssigneeRequired);
      }
      CMN_Todo__c t = new CMN_Todo__c(
        ExternalKey__c = key,
        Assignee__c = s.assigneeId,
        Category__c = s.category,
        System__c = s.systemCode,
        SourceType__c = s.sourceType,
        SourceRecordId__c = s.sourceRecordId,
        SourceObject__c = String.valueOf(s.sourceRecordId.getSObjectType()),
        TargetRecordId__c = s.targetRecordId,
        RecordNo__c = s.recordNo?.left(40),
        TitleLabel__c = s.titleLabel,
        TitleParams__c = params(s.titleParams),
        DueDate__c = s.dueDate,
        Plant__c = s.plantId,
        IsDelegated__c = s.isDelegated == true,
        DelegatedFrom__c = s.delegatedFromId,
        Status__c = OPEN,
        CompletedAt__c = null
      );
      t.TitleFallback__c = (String.isNotBlank(s.titleFallback)
          ? s.titleFallback
          : renderTitle(t, defaultLanguage) ?? s.titleLabel)
        .left(255);
      t.Name = t.TitleFallback__c.left(80);
      if (OWNER_USER_TYPES.contains(assignee.UserType)) {
        t.OwnerId = assignee.Id;
      }
      rows.add(t);
    }
    CMN_TodoWriter.upsertByKey(rows);
    publish(rows, employeeNos(users.values()), OPEN);
  }

  /**
   * @description 원천 레코드의 OPEN To-Do를 완료한다.
   * @param sourceType 원천 유형
   * @param sourceIds 원천 레코드
   * @param assigneeOrNull 처리자(null이면 해당 원천 전체, 예: 대결 To-Do 포함)
   */
  public static void close(
    String sourceType,
    Set<Id> sourceIds,
    Id assigneeOrNull
  ) {
    finish(sourceType, sourceIds, assigneeOrNull, DONE);
  }

  /**
   * @description 원천 레코드의 OPEN To-Do를 취소한다(업무 취소·결재 반려·회수).
   * @param sourceType 원천 유형
   * @param sourceIds 원천 레코드
   */
  public static void cancel(String sourceType, Set<Id> sourceIds) {
    finish(sourceType, sourceIds, null, CANCELLED);
  }

  /**
   * @description 받는 사람 언어로 제목을 만든다(BR-3). 라벨 번역이 없으면 en_US, 라벨이 없으면 TitleFallback__c.
   * 치환값이 JSON 배열이면 {0}·{1}…, JSON 객체면 {key}를 바꾼다.
   * @param t To-Do(TitleLabel__c, TitleParams__c, TitleFallback__c)
   * @param languageLocaleKey 받는 사람 언어(예: ko, en_US, zh_CN). 비우면 기본 언어
   * @return 제목
   */
  public static String renderTitle(CMN_Todo__c t, String languageLocaleKey) {
    String template = labelText(t.TitleLabel__c, languageLocaleKey);
    return template == null
      ? t.TitleFallback__c
      : substitute(template, t.TitleParams__c);
  }

  // ------------------------------------------------------------------ 내부
  private static void finish(
    String sourceType,
    Set<Id> sourceIds,
    Id assigneeOrNull,
    String status
  ) {
    if (
      String.isBlank(sourceType) ||
      sourceIds == null ||
      sourceIds.isEmpty()
    ) {
      return;
    }
    Set<String> ids = new Set<String>();
    for (Id i : sourceIds) {
      ids.add(i);
    }
    List<CMN_Todo__c> rows = CMN_TodoSelector.openBySource(
      sourceType,
      ids,
      assigneeOrNull
    );
    Map<Id, String> employeeNos = new Map<Id, String>();
    for (CMN_Todo__c t : rows) {
      t.Status__c = status;
      t.CompletedAt__c = Datetime.now();
      employeeNos.put(t.Assignee__c, t.Assignee__r?.EmployeeNo__c);
    }
    CMN_TodoWriter.save(rows);
    publish(rows, employeeNos, status);
  }

  private static void validate(CMN_TodoSpec s) {
    if (s.assigneeId == null) {
      throw new CMN_ValidationException(Label.CMN_Todo_AssigneeRequired);
    }
    if (
      String.isBlank(s.sourceType) ||
      s.sourceType.length() > 80 ||
      s.sourceRecordId == null ||
      s.targetRecordId == null ||
      String.isBlank(s.titleLabel) ||
      s.titleLabel.length() > 80 ||
      (params(s.titleParams)?.length() ?? 0) > 1000
    ) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
  }

  /** 치환값 직렬화: List·Map은 JSON, 문자열 하나는 [값]. */
  private static String params(Object value) {
    if (value == null) {
      return null;
    }
    if (value instanceof String) {
      return JSON.serialize(new List<Object>{ value });
    }
    return JSON.serialize(value);
  }

  private static String labelText(String name, String languageLocaleKey) {
    if (String.isBlank(name)) {
      return null;
    }
    String language = String.isBlank(languageLocaleKey)
      ? defaultLanguage()
      : languageLocaleKey;
    try {
      if (!System.Label.translationExists('', name, language)) {
        language = FALLBACK_LANGUAGE;
      }
      return System.Label.get('', name, language);
    } catch (System.InvalidParameterValueException e) {
      // 라벨이 없거나(다른 메뉴 WI가 아직 만들지 않음) 지원하지 않는 언어면 기본 제목을 쓴다
      return null;
    }
  }

  private static String substitute(String template, String paramsJson) {
    if (String.isBlank(paramsJson)) {
      return template;
    }
    String out = template;
    try {
      Object parsed = JSON.deserializeUntyped(paramsJson);
      if (parsed instanceof List<Object>) {
        List<Object> values = (List<Object>) parsed;
        for (Integer i = 0; i < values.size(); i++) {
          out = out.replace('{' + i + '}', String.valueOf(values[i] ?? ''));
        }
      } else if (parsed instanceof Map<String, Object>) {
        Map<String, Object> values = (Map<String, Object>) parsed;
        for (String k : values.keySet()) {
          out = out.replace('{' + k + '}', String.valueOf(values.get(k) ?? ''));
        }
      }
    } catch (JSONException e) {
      CMN_Logger.warn(
        'CMN_TodoService.renderTitle',
        'Invalid TitleParams JSON',
        null
      );
    }
    return out;
  }

  private static String defaultLanguage() {
    return CMN_Settings.getString('CMN_DEFAULT_LANGUAGE', 'ko');
  }

  private static Map<Id, String> employeeNos(List<User> users) {
    Map<Id, String> out = new Map<Id, String>();
    for (User u : users) {
      out.put(u.Id, u.EmployeeNo__c);
    }
    return out;
  }

  private static void publish(
    List<CMN_Todo__c> rows,
    Map<Id, String> employeeNos,
    String changeType
  ) {
    if (rows.isEmpty()) {
      return;
    }
    List<CMN_TodoChanged__e> events = new List<CMN_TodoChanged__e>();
    for (CMN_Todo__c t : rows) {
      events.add(
        new CMN_TodoChanged__e(
          AssigneeEmployeeNo__c = employeeNos.get(t.Assignee__c),
          AssigneeId__c = t.Assignee__c,
          TodoId__c = t.Id,
          ChangeType__c = changeType
        )
      );
    }
    published.addAll(events);
    EventBus.publish(events);
  }
}
