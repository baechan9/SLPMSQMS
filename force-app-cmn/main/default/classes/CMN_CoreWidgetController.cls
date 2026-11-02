/**
 * @description 공통 기본 위젯 데이터(CMN-00-DSH-001 BR-5: 실시간 업무 건수는 집계 SOQL): 내 To-Do 요약, 내 결재 대기.
 * 보드 공통 필터(BR-6)는 config의 system·plantId로 들어온다.
 * @group CMN-00-DSH-001
 */
public with sharing class CMN_CoreWidgetController {
  private static final Integer DEFAULT_ROWS = 5;
  private static final Integer MAX_ROWS = 20;

  /** @description To-Do 요약. */
  public class TodoSummary {
    @AuraEnabled
    public Integer task = 0;
    @AuraEnabled
    public Integer approval = 0;
    @AuraEnabled
    public Integer overdue = 0;
  }

  /** @description 결재 대기 요약. */
  public class ApprovalSummary {
    @AuraEnabled
    public Integer total = 0;
    @AuraEnabled
    public List<ApprovalRow> rows = new List<ApprovalRow>();
  }

  /** @description 결재 대기 한 건. */
  public class ApprovalRow {
    @AuraEnabled
    public Id requestId;
    @AuraEnabled
    public String recordNo;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public Integer pendingDays;
  }

  /**
   * @description 내 열린 To-Do 건수(할 일·결재)와 기한 경과(시스템 필터: 그 시스템 + CMN).
   * @param configJson 위젯 설정({system, plantId})
   * @return 요약
   * @throws AuraHandledException 잘못된 설정
   */
  @AuraEnabled
  public static TodoSummary todoSummary(String configJson) {
    try {
      Filter f = new Filter(configJson);
      Id me = UserInfo.getUserId();
      Date today = Date.today();
      TodoSummary s = new TodoSummary();
      String plantCondition = f.plantId == null
        ? ''
        : ' AND Plant__c = :plantId';
      Map<String, Object> binds = new Map<String, Object>{
        'me' => me,
        'systems' => f.systems,
        'plantId' => f.plantId,
        'today' => today
      };
      String base =
        ' FROM CMN_Todo__c WHERE Assignee__c = :me AND Status__c = \'OPEN\' AND System__c IN :systems' +
        plantCondition;
      for (
        AggregateResult r : (List<AggregateResult>) Database.queryWithBinds(
          'SELECT Category__c category, COUNT(Id) n' +
            base +
            ' GROUP BY Category__c',
          binds,
          AccessLevel.USER_MODE
        )
      ) {
        Integer n = (Integer) r.get('n');
        if ((String) r.get('category') == 'APPROVAL') {
          s.approval += n;
        } else {
          s.task += n;
        }
      }
      s.overdue = Database.countQueryWithBinds(
        'SELECT COUNT()' + base + ' AND DueDate__c < :today',
        binds,
        AccessLevel.USER_MODE
      );
      return s;
    } catch (Exception e) {
      throw toAura(e, 'CMN_CoreWidgetController.todoSummary');
    }
  }

  /**
   * @description 내가 처리할 결재(오래 기다린 순)와 건수.
   * @param configJson 위젯 설정({maxRows, plantId})
   * @return 요약
   * @throws AuraHandledException 잘못된 설정
   */
  @AuraEnabled
  public static ApprovalSummary approvalSummary(String configJson) {
    try {
      Filter f = new Filter(configJson);
      Id me = UserInfo.getUserId();
      ApprovalSummary s = new ApprovalSummary();
      String soql =
        'SELECT Id, Request__c, Request__r.RecordNo__c, Request__r.Title__c, PendingAt__c FROM CMN_ApprovalStep__c' +
        ' WHERE Approver__c = :me AND Status__c = \'PENDING\'' +
        (f.plantId == null ? '' : ' AND Request__r.Plant__c = :plantId');
      Map<String, Object> binds = new Map<String, Object>{
        'me' => me,
        'plantId' => f.plantId
      };
      s.total = Database.countQueryWithBinds(
        'SELECT COUNT() FROM CMN_ApprovalStep__c WHERE Approver__c = :me AND Status__c = \'PENDING\'' +
        (f.plantId == null ? '' : ' AND Request__r.Plant__c = :plantId'),
        binds,
        AccessLevel.USER_MODE
      );
      Date today = Date.today();
      for (
        CMN_ApprovalStep__c st : (List<CMN_ApprovalStep__c>) Database.queryWithBinds(
          soql + ' ORDER BY PendingAt__c ASC NULLS LAST LIMIT ' + f.maxRows,
          binds,
          AccessLevel.USER_MODE
        )
      ) {
        ApprovalRow row = new ApprovalRow();
        row.requestId = st.Request__c;
        row.recordNo = st.Request__r?.RecordNo__c;
        row.title = st.Request__r?.Title__c;
        row.pendingDays = st.PendingAt__c == null
          ? null
          : st.PendingAt__c.date().daysBetween(today);
        s.rows.add(row);
      }
      return s;
    } catch (Exception e) {
      throw toAura(e, 'CMN_CoreWidgetController.approvalSummary');
    }
  }

  /** 위젯 설정 해석·검증(보드 필터가 이미 병합된 config). */
  private class Filter {
    Set<String> systems = new Set<String>{ 'CMN' };
    Id plantId;
    Integer maxRows = DEFAULT_ROWS;

    Filter(String configJson) {
      Map<String, Object> c;
      try {
        c = String.isBlank(configJson)
          ? new Map<String, Object>()
          : (Map<String, Object>) JSON.deserializeUntyped(configJson);
      } catch (Exception e) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      String sys = String.valueOf(c.get('system') ?? '');
      if (sys == 'QMS' || sys == 'PMS') {
        systems.add(sys);
      } else {
        systems.addAll(new Set<String>{ 'QMS', 'PMS' });
      }
      Object plant = c.get('plantId');
      if (plant != null && String.isNotBlank(String.valueOf(plant))) {
        try {
          plantId = Id.valueOf(String.valueOf(plant));
        } catch (Exception e) {
          throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
        }
        if (plantId.getSObjectType() != CMN_Plant__c.SObjectType) {
          throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
        }
      }
      Object rows = c.get('maxRows');
      if (rows != null) {
        try {
          maxRows = Math.max(
            1,
            Math.min(MAX_ROWS, Integer.valueOf(String.valueOf(rows)))
          );
        } catch (Exception e) {
          throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
        }
      }
    }
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
