/**
 * @description 조치 항목 기한 알림(CMN-00-MTG-001 BR-3). 매일 실행해 기한이 내일이면 CMN_ACTION_DUE, 지났으면 CMN_ACTION_OVERDUE를
 * 담당자에게 보낸다. 같은 날에는 다시 보내지 않는다(LastDueAlertOn).
 * 예약: scripts/apex/schedule-jobs.apex(매일 09:00, 예약 사용자 시간대).
 * @group CMN-00-MTG-001
 */
public with sharing class CMN_ActionItemReminderJob implements Schedulable {
  public static final String DUE_EVENT = 'CMN_ACTION_DUE';
  public static final String OVERDUE_EVENT = 'CMN_ACTION_OVERDUE';

  @TestVisible
  private static Date todayOverride;

  /**
   * @description 스케줄 진입점.
   * @param context 스케줄 문맥
   */
  public void execute(SchedulableContext context) {
    run();
  }

  /**
   * @description 오늘 알릴 조치 항목에 알림을 보낸다.
   * @return 보낸 알림 수
   */
  public static Integer run() {
    Date today = todayOverride ?? Date.today();
    List<CMN_NotificationService.Message> messages = new List<CMN_NotificationService.Message>();
    List<SObject> marks = new List<SObject>();
    for (CMN_ActionItem__c a : CMN_MeetingSelector.dueActions(today)) {
      String code = a.DueDate__c < today
        ? OVERDUE_EVENT
        : (a.DueDate__c == today.addDays(1) ? DUE_EVENT : null);
      if (code == null) {
        continue;
      }
      messages.add(
        new CMN_NotificationService.Message(
          code,
          new Set<Id>{ a.Owner__c },
          a.Id,
          new Map<String, String>{
            'Title' => a.Name,
            'DueDate' => String.valueOf(a.DueDate__c)
          }
        )
      );
      marks.add(new CMN_ActionItem__c(Id = a.Id, LastDueAlertOn__c = today));
    }
    CMN_MeetingWriter.save(marks);
    CMN_NotificationService.send(messages);
    return messages.size();
  }
}
