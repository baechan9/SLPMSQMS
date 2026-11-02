/**
 * @description 회의 업무 규칙(CMN-00-MTG-001).
 * - 저장: 회의 유형은 MEETING_TYPE 코드, 종료 > 시작, 연관 객체는 연관 Id에서. 확정된 회의록은 바꿀 수 없고(BR-2) 확정 상태는 confirmMinutes로만.
 * - 공지(BR-1): SCHEDULED가 되거나 일정이 바뀌면 참석자에게 벨 알림 + 일정 파일(.ics) 메일(CMN_MeetingInviteJob).
 * - 회의록 확정(BR-2): 참석자 전원 알림, 회의의 진행 중 조치 항목 담당자에게 To-Do(AC-1).
 * - 정기 회의(BR-4): 반복 규칙이 있으면 회차가 개최·확정된 뒤 다음 회차(SCHEDULED)와 참석자를 만든다.
 * - 공유: 공장(SEC-002 설정) + 참석자 읽기(CMN_Attendee 사유).
 * @group CMN-00-MTG-001
 */
public with sharing class CMN_MeetingService {
  public static final String SCHEDULED = 'SCHEDULED';
  public static final String HELD = 'HELD';
  public static final String MINUTES_DRAFT = 'MINUTES_DRAFT';
  public static final String MINUTES_CONFIRMED = 'MINUTES_CONFIRMED';
  public static final String TYPE_GROUP = 'MEETING_TYPE';
  public static final String SCHEDULED_EVENT = 'CMN_MEETING_SCHEDULED';
  public static final String MINUTES_EVENT = 'CMN_MEETING_MINUTES';
  public static final String CAUSE_ATTENDEE = 'CMN_Attendee__c';

  /** confirmMinutes 안에서만 확정 상태로 바꿀 수 있다 */
  private static Boolean confirming = false;

  /**
   * @description 저장 전 검증.
   * @param rows 회의
   * @param oldMap 이전 값(삽입이면 null)
   */
  public static void prepare(
    List<CMN_Meeting__c> rows,
    Map<Id, SObject> oldMap
  ) {
    Set<Id> codes = new Set<Id>();
    for (CMN_Meeting__c m : rows) {
      codes.add(m.Category__c);
    }
    Map<Id, CMN_Code__c> categories = CMN_DocumentSelector.classGroups(codes);
    for (CMN_Meeting__c m : rows) {
      CMN_Meeting__c old = (CMN_Meeting__c) oldMap?.get(m.Id);
      if (old?.Status__c == MINUTES_CONFIRMED) {
        if (m.Minutes__c != old.Minutes__c || m.Status__c != old.Status__c) {
          m.addError(Label.CMN_Meeting_MinutesLocked);
          continue;
        }
      } else if (
        m.Status__c == MINUTES_CONFIRMED &&
        !confirming &&
        !CMN_TriggerHandler.isMigrationMode()
      ) {
        m.addError(Label.CMN_Meeting_ConfirmOnlyByService);
        continue;
      }
      if (
        categories.get(m.Category__c)?.CodeGroup__r?.GroupCode__c != TYPE_GROUP
      ) {
        m.addError(Label.CMN_Meeting_InvalidCategory);
        continue;
      }
      if (m.EndAt__c <= m.StartAt__c) {
        m.addError(Label.CMN_Meeting_InvalidPeriod);
        continue;
      }
      m.RelatedObject__c = objectOf(m.RelatedRecordId__c);
    }
  }

  /**
   * @description 저장 후: 공지, 다음 회차.
   * @param rows 회의
   * @param oldMap 이전 값(삽입이면 null)
   */
  public static void afterSave(
    List<CMN_Meeting__c> rows,
    Map<Id, SObject> oldMap
  ) {
    Set<Id> invite = new Set<Id>();
    List<CMN_Meeting__c> recurring = new List<CMN_Meeting__c>();
    for (CMN_Meeting__c m : rows) {
      CMN_Meeting__c old = (CMN_Meeting__c) oldMap?.get(m.Id);
      if (
        m.Status__c == SCHEDULED &&
        (old == null ||
        old.Status__c != SCHEDULED ||
        old.StartAt__c != m.StartAt__c ||
        old.EndAt__c != m.EndAt__c)
      ) {
        invite.add(m.Id);
      }
      Boolean happened =
        m.Status__c == HELD ||
        m.Status__c == MINUTES_DRAFT ||
        m.Status__c == MINUTES_CONFIRMED;
      if (
        happened &&
        m.IsRegular__c &&
        m.Recurrence__c != null &&
        m.Recurrence__c != 'NONE' &&
        m.NextMeeting__c == null
      ) {
        recurring.add(m);
      }
    }
    if (!invite.isEmpty()) {
      inviteAttendees(invite, null);
    }
    if (!recurring.isEmpty()) {
      createNextMeetings(recurring);
    }
  }

  /**
   * @description 참석자 저장 후: 회의 읽기 공유, 이미 공지된 회의면 새 참석자에게 공지.
   * @param attendees 새 참석자
   */
  public static void onAttendeesAdded(List<CMN_MeetingAttendee__c> attendees) {
    Map<Id, CMN_Meeting__c> meetings = new Map<Id, CMN_Meeting__c>(
      CMN_MeetingSelector.meetings(new Set<Id>(meetingIds(attendees)))
    );
    Map<Id, Set<Id>> usersByMeeting = new Map<Id, Set<Id>>();
    Set<Id> newAttendees = new Set<Id>();
    Set<Id> scheduledMeetings = new Set<Id>();
    for (CMN_MeetingAttendee__c a : attendees) {
      newAttendees.add(a.Id);
      CMN_Meeting__c m = meetings.get(a.Meeting__c);
      if (m?.Status__c == SCHEDULED) {
        scheduledMeetings.add(m.Id);
      }
      // 소유자는 이미 접근할 수 있어 공유 행을 만들지 않는다
      if (a.User__c == null || a.User__c == m?.OwnerId) {
        continue;
      }
      if (!usersByMeeting.containsKey(a.Meeting__c)) {
        usersByMeeting.put(a.Meeting__c, new Set<Id>());
      }
      usersByMeeting.get(a.Meeting__c).add(a.User__c);
    }
    shareWithAttendees(usersByMeeting);
    if (!scheduledMeetings.isEmpty()) {
      inviteAttendees(scheduledMeetings, newAttendees);
    }
  }

  /**
   * @description 회의록을 확정한다(BR-2, AC-1).
   * @param meetingId 회의
   * @return 담당자 To-Do를 연 조치 항목 수
   * @throws CMN_ValidationException 편집 권한 없음, 확정할 수 없는 상태
   */
  public static Integer confirmMinutes(Id meetingId) {
    if (
      !CMN_DocumentSelector.editableParents(new Set<Id>{ meetingId })
        .contains(meetingId)
    ) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    CMN_Meeting__c m = CMN_MeetingSelector.meetings(
      new Set<Id>{ meetingId }
    )[0];
    if (m.Status__c != HELD && m.Status__c != MINUTES_DRAFT) {
      throw new CMN_ValidationException(Label.CMN_Meeting_CannotConfirm);
    }
    confirming = true;
    try {
      CMN_MeetingWriter.save(
        new List<SObject>{
          new CMN_Meeting__c(
            Id = meetingId,
            Status__c = MINUTES_CONFIRMED,
            MinutesConfirmedAt__c = Datetime.now()
          )
        }
      );
    } finally {
      confirming = false;
    }
    List<CMN_ActionItem__c> actions = CMN_MeetingSelector.openActions(
      new Set<Id>{ meetingId }
    );
    CMN_ActionItemService.openTodos(actions);
    Set<Id> recipients = new Set<Id>();
    for (
      CMN_MeetingAttendee__c a : CMN_MeetingSelector.attendees(
        new Set<Id>{ meetingId }
      )
    ) {
      if (a.User__c != null) {
        recipients.add(a.User__c);
      }
    }
    CMN_NotificationService.send(
      MINUTES_EVENT,
      recipients,
      meetingId,
      new Map<String, String>{
        'Title' => m.Name,
        'ActionCount' => String.valueOf(actions.size())
      }
    );
    return actions.size();
  }

  /**
   * @description 회의가 확정됐는지(조치 항목 To-Do 시점 판단).
   * @param meetingIds 회의
   * @return 확정된 회의 Id
   */
  public static Set<Id> confirmed(Set<Id> meetingIds) {
    Set<Id> out = new Set<Id>();
    for (CMN_Meeting__c m : CMN_MeetingSelector.meetings(meetingIds)) {
      if (m.Status__c == MINUTES_CONFIRMED) {
        out.add(m.Id);
      }
    }
    return out;
  }

  // ------------------------------------------------------------------ 내부
  private static void inviteAttendees(
    Set<Id> meetingIds,
    Set<Id> onlyAttendees
  ) {
    Map<Id, Set<Id>> users = new Map<Id, Set<Id>>();
    List<CMN_NotificationService.Message> bells = new List<CMN_NotificationService.Message>();
    Map<Id, CMN_Meeting__c> meetings = new Map<Id, CMN_Meeting__c>(
      CMN_MeetingSelector.meetings(meetingIds)
    );
    Set<Id> attendeeIds = new Set<Id>();
    for (CMN_MeetingAttendee__c a : CMN_MeetingSelector.attendees(meetingIds)) {
      if (onlyAttendees != null && !onlyAttendees.contains(a.Id)) {
        continue;
      }
      attendeeIds.add(a.Id);
      if (a.User__c != null) {
        if (!users.containsKey(a.Meeting__c)) {
          users.put(a.Meeting__c, new Set<Id>());
        }
        users.get(a.Meeting__c).add(a.User__c);
      }
    }
    for (Id meetingId : users.keySet()) {
      CMN_Meeting__c m = meetings.get(meetingId);
      bells.add(
        new CMN_NotificationService.Message(
          SCHEDULED_EVENT,
          users.get(meetingId),
          meetingId,
          new Map<String, String>{
            'Title' => m.Name,
            'When' => m.StartAt__c.format('yyyy-MM-dd HH:mm'),
            'Location' => m.Location__c ?? m.OnlineUrl__c ?? ''
          }
        )
      );
    }
    CMN_NotificationService.send(bells);
    if (
      !attendeeIds.isEmpty() &&
      Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()
    ) {
      System.enqueueJob(new CMN_MeetingInviteJob(attendeeIds));
    }
  }

  private static void createNextMeetings(List<CMN_Meeting__c> current) {
    Map<Id, CMN_Meeting__c> nextByCurrent = new Map<Id, CMN_Meeting__c>();
    for (CMN_Meeting__c m : current) {
      Integer days = m.Recurrence__c == 'WEEKLY' ? 7 : null;
      Datetime start = days != null
        ? m.StartAt__c.addDays(days)
        : m.StartAt__c.addMonths(1);
      Long length = m.EndAt__c.getTime() - m.StartAt__c.getTime();
      nextByCurrent.put(
        m.Id,
        new CMN_Meeting__c(
          Name = m.Name,
          Category__c = m.Category__c,
          IsRegular__c = true,
          Recurrence__c = m.Recurrence__c,
          StartAt__c = start,
          EndAt__c = Datetime.newInstance(start.getTime() + length),
          Location__c = m.Location__c,
          OnlineUrl__c = m.OnlineUrl__c,
          RelatedRecordId__c = m.RelatedRecordId__c,
          Plant__c = m.Plant__c,
          Status__c = SCHEDULED,
          OwnerId = m.OwnerId
        )
      );
    }
    CMN_MeetingWriter.save(nextByCurrent.values());
    List<SObject> links = new List<SObject>();
    for (Id currentId : nextByCurrent.keySet()) {
      links.add(
        new CMN_Meeting__c(
          Id = currentId,
          NextMeeting__c = nextByCurrent.get(currentId).Id
        )
      );
    }
    List<CMN_MeetingAttendee__c> copies = new List<CMN_MeetingAttendee__c>();
    for (
      CMN_MeetingAttendee__c a : CMN_MeetingSelector.attendees(
        nextByCurrent.keySet()
      )
    ) {
      copies.add(
        new CMN_MeetingAttendee__c(
          Meeting__c = nextByCurrent.get(a.Meeting__c).Id,
          Name = a.Name,
          User__c = a.User__c,
          ExternalEmail__c = a.ExternalEmail__c,
          Role__c = a.Role__c
        )
      );
    }
    CMN_MeetingWriter.save(links);
    CMN_MeetingWriter.save(copies);
  }

  private static void shareWithAttendees(Map<Id, Set<Id>> usersByMeeting) {
    List<SObject> rows = new List<SObject>();
    for (Id meetingId : usersByMeeting.keySet()) {
      for (Id u : usersByMeeting.get(meetingId)) {
        rows.add(
          new CMN_Meeting__Share(
            ParentId = meetingId,
            UserOrGroupId = u,
            AccessLevel = 'Read',
            RowCause = CAUSE_ATTENDEE
          )
        );
      }
    }
    CMN_ShareWriter.write(new List<SObject>(), rows);
  }

  private static List<Id> meetingIds(List<CMN_MeetingAttendee__c> attendees) {
    List<Id> out = new List<Id>();
    for (CMN_MeetingAttendee__c a : attendees) {
      out.add(a.Meeting__c);
    }
    return out;
  }

  private static String objectOf(String recordId) {
    try {
      return String.isBlank(recordId)
        ? null
        : String.valueOf(Id.valueOf(recordId).getSObjectType());
    } catch (Exception e) {
      return null;
    }
  }
}
