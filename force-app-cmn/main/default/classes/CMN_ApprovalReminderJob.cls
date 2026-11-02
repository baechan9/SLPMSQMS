/**
 * @description 결재 지연 독촉·에스컬레이션(CMN-00-APV-005). 매시 정각 실행하고 공장 현지 시각이 CMN_APV_REMINDER_HOUR(기본 9)인
 * 공장의 PENDING 단계만 처리한다(BR-1, 공장이 없는 결재는 CMN_DEFAULT_TIMEZONE).
 * - 체류일수 = 대기 시작(PendingAt, 없으면 상신 시각)의 현지 날짜부터 오늘까지 달력 일수.
 * - 체류일수 ≥ ReminderDays(기본 2) → 결재자와 유효 대리인에게 독촉, ≥ EscalationDays(기본 5) → 결재자 부서장에게 에스컬레이션(BR-2·BR-3).
 * - 같은 현지 날짜에는 다시 보내지 않는다(LastReminderOn·LastEscalationOn).
 * 예약: `System.schedule('CMN_ApprovalReminderJob', '0 0 * * * ?', new CMN_ApprovalReminderJob())`(scripts/apex/schedule-jobs.apex).
 * @group CMN-00-APV-005
 */
public with sharing class CMN_ApprovalReminderJob implements Schedulable {
  public static final String REMINDER_EVENT = 'APV_REMINDER';
  public static final String ESCALATION_EVENT = 'APV_ESCALATION';
  private static final Integer DEFAULT_REMINDER_DAYS = 2;
  private static final Integer DEFAULT_ESCALATION_DAYS = 5;

  @TestVisible
  private static Datetime nowOverride;

  /**
   * @description 스케줄 진입점.
   * @param context 스케줄 문맥
   */
  public void execute(SchedulableContext context) {
    run();
  }

  /**
   * @description 지금 현지 실행 시각인 공장의 지연 단계를 처리한다.
   * @return 보낸 알림 수(독촉 + 에스컬레이션)
   */
  public static Integer run() {
    Datetime now = nowOverride ?? Datetime.now();
    Integer hour = CMN_Settings.getInteger('CMN_APV_REMINDER_HOUR', 9);
    String defaultZone = CMN_Settings.getString(
      'CMN_DEFAULT_TIMEZONE',
      'Asia/Seoul'
    );
    List<CMN_ApprovalStep__c> steps = CMN_ApprovalReminderSelector.pendingSteps();
    Set<Id> plants = new Set<Id>();
    Set<Id> approvers = new Set<Id>();
    for (CMN_ApprovalStep__c s : steps) {
      if (s.Request__r.Plant__c != null) {
        plants.add(s.Request__r.Plant__c);
      }
      approvers.add(s.Approver__c);
    }
    CMN_PlantService.preload(plants);

    List<CMN_ApprovalStep__c> due = new List<CMN_ApprovalStep__c>();
    Map<Id, Date> todayByStep = new Map<Id, Date>();
    Map<Id, Integer> daysByStep = new Map<Id, Integer>();
    for (CMN_ApprovalStep__c s : steps) {
      String zone = s.Request__r.Plant__c == null
        ? defaultZone
        : CMN_PlantService.timeZoneOf(s.Request__r.Plant__c).getID();
      if (Integer.valueOf(now.format('H', zone)) != hour) {
        continue;
      }
      Datetime since = s.PendingAt__c ?? s.Request__r.SubmittedAt__c;
      if (since == null) {
        continue;
      }
      Date today = Date.valueOf(now.format('yyyy-MM-dd', zone));
      todayByStep.put(s.Id, today);
      daysByStep.put(
        s.Id,
        Date.valueOf(since.format('yyyy-MM-dd', zone)).daysBetween(today)
      );
      due.add(s);
    }
    if (due.isEmpty()) {
      return 0;
    }

    Map<Id, List<CMN_Delegation__c>> delegations = CMN_DelegationService.activeFor(
      approvers
    );
    Map<Id, CMN_Department__c> depts = CMN_UserOrgService.departmentsOf(
      approvers
    );
    List<CMN_NotificationService.Message> messages = new List<CMN_NotificationService.Message>();
    List<SObject> marks = new List<SObject>();
    for (CMN_ApprovalStep__c s : due) {
      CMN_ApprovalType__mdt approvalType = CMN_ApprovalType__mdt.getInstance(
        s.Request__r.TypeCode__c
      );
      Integer days = daysByStep.get(s.Id);
      Date today = todayByStep.get(s.Id);
      CMN_ApprovalStep__c mark = new CMN_ApprovalStep__c(Id = s.Id);
      Boolean changed = false;
      Integer reminderDays = approvalType?.ReminderDays__c?.intValue() ??
        DEFAULT_REMINDER_DAYS;
      if (days >= reminderDays && s.LastReminderOn__c != today) {
        Set<Id> recipients = new Set<Id>{ s.Approver__c };
        recipients.addAll(
          CMN_DelegationService.delegatesFor(
            delegations.get(s.Approver__c),
            s.Request__r.TypeCode__c
          )
        );
        messages.add(message(REMINDER_EVENT, recipients, s, days));
        mark.LastReminderOn__c = today;
        changed = true;
      }
      Integer escalationDays = approvalType?.EscalationDays__c?.intValue() ??
        DEFAULT_ESCALATION_DAYS;
      Id manager = depts.get(s.Approver__c)?.Manager__c;
      if (
        days >= escalationDays &&
        s.LastEscalationOn__c != today &&
        manager != null &&
        manager != s.Approver__c
      ) {
        messages.add(
          message(ESCALATION_EVENT, new Set<Id>{ manager }, s, days)
        );
        mark.LastEscalationOn__c = today;
        changed = true;
      }
      if (changed) {
        marks.add(mark);
      }
    }
    // 발송 기록은 사용자 FLS가 읽기라 결재 엔진 Writer로 저장한다
    CMN_ApprovalWriter.save(marks);
    CMN_NotificationService.send(messages);
    return messages.size();
  }

  private static CMN_NotificationService.Message message(
    String eventCode,
    Set<Id> recipients,
    CMN_ApprovalStep__c s,
    Integer days
  ) {
    return new CMN_NotificationService.Message(
      eventCode,
      recipients,
      s.Request__r.TargetRecordId__c,
      new Map<String, String>{
        'Title' => s.Request__r.Title__c ?? '',
        'RecordNo' => s.Request__r.TargetRecordNo__c ??
          s.Request__r.RecordNo__c ?? '',
        'Days' => String.valueOf(days),
        'ApproverName' => s.Approver__r?.Name ?? ''
      }
    );
  }
}
