/**
 * @description 메인 홈 To-Do 목록(CMN-00-TDO-004). 내 열린 To-Do를 업무·결재 탭과 시스템 필터로 20건씩 보여주고,
 * 항목을 누르면 열 레코드(업무 = 업무 레코드, 결재 = 결재 요청)를 알려준다(BR-1·BR-2).
 * 시스템 필터는 그 시스템 + 공통(CMN) To-Do다. 위젯 To-Do 요약(DSH-001)과 같은 기준이다.
 * @group CMN-00-TDO-004
 */
public with sharing class CMN_TodoListController {
  @TestVisible
  private static final Integer PAGE_SIZE = 20;
  /** SOQL OFFSET 한도 */
  private static final Integer MAX_OFFSET = 2000;
  private static final String TASK = 'TASK';
  private static final String APPROVAL = 'APPROVAL';
  private static final Map<String, Set<String>> SYSTEMS = new Map<String, Set<String>>{
    'QMS' => new Set<String>{ 'QMS', 'CMN' },
    'PMS' => new Set<String>{ 'PMS', 'CMN' },
    'ALL' => new Set<String>{ 'QMS', 'PMS', 'CMN' }
  };

  /** @description To-Do 한 화면. */
  public class TodoPage {
    @AuraEnabled
    public List<TodoItem> items = new List<TodoItem>();
    @AuraEnabled
    public Boolean hasMore = false;
    /** 탭 배지: 현재 시스템 필터의 업무·결재 건수 */
    @AuraEnabled
    public Integer taskCount = 0;
    @AuraEnabled
    public Integer approvalCount = 0;
  }

  /** @description To-Do 한 건. */
  public class TodoItem {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String recordNo;
    @AuraEnabled
    public Date dueDate;
    @AuraEnabled
    public Boolean isOverdue = false;
    @AuraEnabled
    public String systemCode;
    @AuraEnabled
    public String plantName;
    @AuraEnabled
    public Boolean isDelegated = false;
    /** 누르면 열 레코드 */
    @AuraEnabled
    public Id navigationId;
  }

  /**
   * @description 내 열린 To-Do 한 화면(기한 빠른 순, 기한 없음은 뒤).
   * @param category TASK 또는 APPROVAL
   * @param systemFilter QMS, PMS, ALL
   * @param offsetRows 건너뛸 건수(더 보기, 0~2000)
   * @return 한 화면과 탭 건수
   * @throws AuraHandledException 잘못된 조건, 조회 실패
   */
  @AuraEnabled
  public static TodoPage getTodos(
    String category,
    String systemFilter,
    Integer offsetRows
  ) {
    try {
      Integer offsetValue = offsetRows ?? 0;
      if (
        (category != TASK &&
        category != APPROVAL) ||
        !SYSTEMS.containsKey(systemFilter ?? '') ||
        offsetValue < 0 ||
        offsetValue > MAX_OFFSET
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      Id me = UserInfo.getUserId();
      Set<String> systems = SYSTEMS.get(systemFilter);
      Integer rowLimit = PAGE_SIZE + 1;
      List<CMN_Todo__c> rows = [
        SELECT
          Id,
          TitleLabel__c,
          TitleParams__c,
          TitleFallback__c,
          RecordNo__c,
          DueDate__c,
          IsOverdue__c,
          System__c,
          SourceType__c,
          SourceRecordId__c,
          TargetRecordId__c,
          IsDelegated__c,
          Plant__r.DisplayName__c
        FROM CMN_Todo__c
        WHERE
          Assignee__c = :me
          AND Status__c = 'OPEN'
          AND Category__c = :category
          AND System__c IN :systems
        WITH USER_MODE
        ORDER BY DueDate__c ASC NULLS LAST, CreatedDate DESC, Id ASC
        LIMIT :rowLimit
        OFFSET :offsetValue
      ];
      TodoPage page = new TodoPage();
      page.hasMore = rows.size() > PAGE_SIZE;
      if (page.hasMore) {
        rows.remove(PAGE_SIZE);
      }
      Map<String, Id> requestByStep = approvalRequests(rows);
      String language = UserInfo.getLanguage();
      for (CMN_Todo__c t : rows) {
        page.items.add(toItem(t, language, requestByStep));
      }
      for (AggregateResult r : [
        SELECT Category__c category, COUNT(Id) n
        FROM CMN_Todo__c
        WHERE Assignee__c = :me AND Status__c = 'OPEN' AND System__c IN :systems
        WITH USER_MODE
        GROUP BY Category__c
      ]) {
        Integer n = (Integer) r.get('n');
        if ((String) r.get('category') == APPROVAL) {
          page.approvalCount += n;
        } else {
          page.taskCount += n;
        }
      }
      return page;
    } catch (Exception e) {
      throw toAura(e);
    }
  }

  // ------------------------------------------------------------------ 내부
  private static TodoItem toItem(
    CMN_Todo__c t,
    String language,
    Map<String, Id> requestByStep
  ) {
    TodoItem item = new TodoItem();
    item.id = t.Id;
    item.title = CMN_TodoService.renderTitle(t, language);
    item.recordNo = t.RecordNo__c;
    item.dueDate = t.DueDate__c;
    item.isOverdue = t.IsOverdue__c;
    item.systemCode = t.System__c;
    item.plantName = t.Plant__r?.DisplayName__c;
    item.isDelegated = t.IsDelegated__c;
    item.navigationId = toId(requestByStep.get(t.SourceRecordId__c)) ??
      toId(t.TargetRecordId__c) ?? toId(t.SourceRecordId__c);
    return item;
  }

  /**
   * 결재 To-Do는 원천이 결재 단계라 그 결재 요청을 연다(BR-2). 단계를 읽을 수 없으면(권한) 업무 레코드로 대신한다.
   */
  private static Map<String, Id> approvalRequests(List<CMN_Todo__c> rows) {
    Set<Id> stepIds = new Set<Id>();
    for (CMN_Todo__c t : rows) {
      Id stepId = toId(t.SourceRecordId__c);
      if (
        t.SourceType__c == CMN_TodoService.SOURCE_APPROVAL &&
        stepId?.getSObjectType() == CMN_ApprovalStep__c.SObjectType
      ) {
        stepIds.add(stepId);
      }
    }
    Map<String, Id> out = new Map<String, Id>();
    if (stepIds.isEmpty()) {
      return out;
    }
    try {
      for (CMN_ApprovalStep__c s : [
        SELECT Id, Request__c
        FROM CMN_ApprovalStep__c
        WHERE Id IN :stepIds
        WITH USER_MODE
      ]) {
        out.put(String.valueOf(s.Id), s.Request__c);
      }
    } catch (QueryException e) {
      // 결재 단계 읽기 권한이 없으면 업무 레코드로 이동한다
      out.clear();
    }
    return out;
  }

  private static Id toId(Object value) {
    if (value == null || String.isBlank(String.valueOf(value))) {
      return null;
    }
    try {
      return Id.valueOf(String.valueOf(value));
    } catch (Exception e) {
      return null;
    }
  }

  private static AuraHandledException toAura(Exception e) {
    String message;
    if (e instanceof CMN_ValidationException) {
      message = e.getMessage();
    } else {
      CMN_Logger.error(
        'CMN_TodoListController.getTodos',
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
