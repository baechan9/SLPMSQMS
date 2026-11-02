/**
 * @description 회의 일정 파일(.ics) 메일(CMN-00-MTG-001 BR-1). 사내 참석자는 사용자 대상(setTargetObjectId, 활동 기록 없음),
 * 외부 참석자는 메일 주소로 보낸다. 일정이 바뀌면 같은 UID에 SEQUENCE를 올려 다시 보낸다(달력 앱이 기존 일정을 갱신).
 * 문구는 알림 규칙 CMN_MEETING_SCHEDULED의 라벨을 받는 사람 언어로(외부는 기본 언어) 쓴다.
 * @group CMN-00-MTG-001
 */
public with sharing class CMN_MeetingInviteJob implements Queueable {
  private Set<Id> attendeeIds;

  /** 테스트: 만든 메일 수 */
  @TestVisible
  private static Integer prepared = 0;

  /**
   * @description 초대할 참석자.
   * @param attendeeIds 참석자
   */
  public CMN_MeetingInviteJob(Set<Id> attendeeIds) {
    this.attendeeIds = attendeeIds;
  }

  /**
   * @description 참석자별 초대 메일을 보낸다.
   * @param context Queueable 문맥
   */
  public void execute(QueueableContext context) {
    CMN_NotificationRule__mdt rule = CMN_NotificationService.ruleOf(
      CMN_MeetingService.SCHEDULED_EVENT
    );
    String defaultLanguage = CMN_Settings.getString(
      'CMN_DEFAULT_LANGUAGE',
      'ko'
    );
    List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    for (
      CMN_MeetingAttendee__c a : CMN_MeetingSelector.attendeesById(attendeeIds)
    ) {
      String language = a.User__r?.LanguageLocaleKey ?? defaultLanguage;
      Map<String, String> tokens = new Map<String, String>{
        'Title' => a.Meeting__r.Name,
        'When' => a.Meeting__r.StartAt__c.format('yyyy-MM-dd HH:mm'),
        'Location' => a.Meeting__r.Location__c ?? a.Meeting__r.OnlineUrl__c ??
          '',
        'Actor' => a.Meeting__r.Owner?.Name ?? '',
        'Url' => Url.getOrgDomainUrl().toExternalForm() +
        '/' +
        a.Meeting__c
      };
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      if (a.User__c != null) {
        mail.setTargetObjectId(a.User__c);
        mail.setSaveAsActivity(false);
      } else if (String.isNotBlank(a.ExternalEmail__c)) {
        mail.setToAddresses(new List<String>{ a.ExternalEmail__c });
      } else {
        continue;
      }
      mail.setSubject(
        CMN_NotificationService.render(
          rule?.SubjectLabel__c,
          language,
          tokens
        ) ?? a.Meeting__r.Name
      );
      mail.setPlainTextBody(
        CMN_NotificationService.render(rule?.BodyLabel__c, language, tokens) ??
          a.Meeting__r.Name
      );
      Messaging.EmailFileAttachment ics = new Messaging.EmailFileAttachment();
      ics.setFileName('invite.ics');
      ics.setContentType('text/calendar; charset=UTF-8; method=REQUEST');
      ics.setBody(Blob.valueOf(ics(a)));
      mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ ics });
      mails.add(mail);
    }
    prepared += mails.size();
    if (mails.isEmpty()) {
      return;
    }
    try {
      Messaging.sendEmail(mails, false);
    } catch (System.EmailException e) {
      CMN_Logger.error('CMN_MeetingInviteJob', e.getTypeName(), null);
    }
  }

  /**
   * @description iCalendar(RFC 5545) 본문. UID = 회의 Id, SEQUENCE = 마지막 수정 시각(초) — 바뀌면 달력 앱이 갱신한다.
   * @param a 참석자(회의 정보 포함)
   * @return ICS 텍스트
   */
  @TestVisible
  private static String ics(CMN_MeetingAttendee__c a) {
    String fmt = 'yyyyMMdd\'T\'HHmmss\'Z\'';
    List<String> lines = new List<String>{
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//SL QMS//CMN Meeting//EN',
      'METHOD:REQUEST',
      'BEGIN:VEVENT',
      'UID:' +
      a.Meeting__c +
      '@slqms',
      'SEQUENCE:' +
      String.valueOf(
        (a.Meeting__r.LastModifiedDate ?? Datetime.now()).getTime() / 1000
      ),
      'DTSTAMP:' + Datetime.now().formatGmt(fmt),
      'DTSTART:' + a.Meeting__r.StartAt__c.formatGmt(fmt),
      'DTEND:' + a.Meeting__r.EndAt__c.formatGmt(fmt),
      'SUMMARY:' + escape(a.Meeting__r.Name),
      'LOCATION:' +
      escape(a.Meeting__r.Location__c ?? a.Meeting__r.OnlineUrl__c ?? ''),
      'END:VEVENT',
      'END:VCALENDAR'
    };
    return String.join(lines, '\r\n') + '\r\n';
  }

  private static String escape(String value) {
    return (value ?? '')
      .replace('\\', '\\\\')
      .replace(';', '\\;')
      .replace(',', '\\,')
      .replace('\n', '\\n');
  }
}
