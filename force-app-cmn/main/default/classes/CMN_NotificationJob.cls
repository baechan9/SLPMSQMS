/**
 * @description 알림 발송 Queueable(CMN-00-NTF-001). 한 번에 수신자 CMN_NTF_CHUNK_SIZE명(기본 100)까지 보내고 나머지는 다음 Queueable로 넘긴다(AC-3).
 * - 메일: setTargetObjectId(사용자) + setSaveAsActivity(false)로 일일 외부 메일 한도를 쓰지 않는다(BR-2). 포털 사용자도 User Id로 보낸다.
 * - 벨: Custom Notification Type `CMN_General`(모바일 푸시 포함). 언어별로 한 번씩 보낸다.
 * - 링크: 사내 사용자는 Lightning 레코드 URL, 포털 사용자는 CMN_RecipientUrlResolver 구현이 있으면 그 URL(BR-5).
 * - 실패는 CMN_Logger ERROR로 남기고 다음 수신자·다음 묶음을 계속 보낸다(BR-4).
 * @group CMN-00-NTF-001
 */
public with sharing class CMN_NotificationJob implements Queueable {
  private static final String NOTIFICATION_TYPE = 'CMN_General';
  private static final Integer BELL_TITLE_MAX = 250;
  private static final Integer BELL_BODY_MAX = 750;

  /** 테스트: 발송 내용 기록(채널·언어·수신자·제목·본문) */
  @TestVisible
  private static List<Delivery> delivered = new List<Delivery>();
  /** 테스트: 다음 Queueable로 넘긴 알림(테스트에서는 Queueable을 잇지 못한다) */
  @TestVisible
  private static List<CMN_NotificationService.Message> chained;

  private List<CMN_NotificationService.Message> messages;

  /** @description 발송 기록 한 건. */
  public class Delivery {
    public String channel;
    public String language;
    public Set<Id> userIds;
    public String subject;
    public String body;
    public Id recordId;
  }

  /**
   * @description 보낼 알림.
   * @param messages 알림(규칙 활성·수신자 정리 끝난 것)
   */
  public CMN_NotificationJob(List<CMN_NotificationService.Message> messages) {
    this.messages = messages;
  }

  /**
   * @description 묶음 하나를 보내고 나머지를 잇는다.
   * @param context Queueable 문맥
   */
  public void execute(QueueableContext context) {
    Integer capacity = Math.max(
      1,
      CMN_Settings.getInteger('CMN_NTF_CHUNK_SIZE', 100)
    );
    List<CMN_NotificationService.Message> now = new List<CMN_NotificationService.Message>();
    List<CMN_NotificationService.Message> rest = new List<CMN_NotificationService.Message>();
    for (CMN_NotificationService.Message m : messages) {
      if (capacity <= 0) {
        rest.add(m);
        continue;
      }
      if (m.recipientIds.size() <= capacity) {
        now.add(m);
        capacity -= m.recipientIds.size();
        continue;
      }
      now.add(slice(m, 0, capacity));
      rest.add(slice(m, capacity, m.recipientIds.size()));
      capacity = 0;
    }
    try {
      deliver(now);
    } catch (Exception e) {
      CMN_Logger.error(
        'CMN_NotificationJob',
        e.getMessage(),
        now.isEmpty() ? null : now[0].recordId,
        e
      );
    }
    if (!rest.isEmpty()) {
      if (Test.isRunningTest()) {
        chained = rest;
      } else {
        System.enqueueJob(new CMN_NotificationJob(rest));
      }
    }
  }

  // ------------------------------------------------------------------ 내부
  private static CMN_NotificationService.Message slice(
    CMN_NotificationService.Message m,
    Integer fromIndex,
    Integer toIndex
  ) {
    CMN_NotificationService.Message out = new CMN_NotificationService.Message(
      m.eventCode,
      new Set<Id>(),
      m.recordId,
      m.params
    );
    out.actorId = m.actorId;
    for (Integer i = fromIndex; i < toIndex; i++) {
      out.recipientIds.add(m.recipientIds[i]);
    }
    return out;
  }

  private static void deliver(List<CMN_NotificationService.Message> batch) {
    Set<Id> userIds = new Set<Id>();
    Set<Id> recordIds = new Set<Id>();
    for (CMN_NotificationService.Message m : batch) {
      userIds.addAll(m.recipientIds);
      userIds.add(m.actorId);
      recordIds.add(m.recordId);
    }
    recordIds.remove(null);
    Map<Id, User> users = new Map<Id, User>(
      [
        SELECT Id, Name, IsActive, LanguageLocaleKey, UserType
        FROM User
        WHERE Id IN :userIds
        WITH SYSTEM_MODE
      ]
    );
    Map<Id, Map<String, String>> recordTokens = recordTokens(recordIds);
    Id notificationTypeId = notificationTypeId();
    Id fromAddressId = fromAddressId();
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    List<Delivery> bells = new List<Delivery>();
    for (CMN_NotificationService.Message m : batch) {
      CMN_NotificationRule__mdt rule = CMN_NotificationService.ruleOf(
        m.eventCode
      );
      Set<String> channels = new Set<String>(
        (rule.Channels__c ?? '').toUpperCase().deleteWhitespace().split(',')
      );
      Map<Id, String> urls = urls(m, users);
      Map<String, Delivery> bellByLanguage = new Map<String, Delivery>();
      for (Id userId : m.recipientIds) {
        User u = users.get(userId);
        if (u == null || !u.IsActive) {
          continue;
        }
        Map<String, String> tokens = tokens(
          m,
          users,
          recordTokens,
          urls.get(userId)
        );
        String subject = CMN_NotificationService.render(
          rule.SubjectLabel__c,
          u.LanguageLocaleKey,
          tokens
        );
        String body = CMN_NotificationService.render(
          rule.BodyLabel__c,
          u.LanguageLocaleKey,
          tokens
        );
        if (subject == null || body == null) {
          CMN_Logger.warn(
            'CMN_NotificationJob',
            'Missing label for notification event: ' + m.eventCode,
            m.recordId
          );
          break;
        }
        if (channels.contains(CMN_NotificationService.CHANNEL_EMAIL)) {
          emails.add(email(u.Id, subject, body, fromAddressId));
          delivered.add(record('EMAIL', u, subject, body, m.recordId));
        }
        if (
          channels.contains(CMN_NotificationService.CHANNEL_BELL) &&
          notificationTypeId != null &&
          m.recordId != null
        ) {
          // 벨 본문에는 링크가 필요 없다(알림을 누르면 레코드로 이동). 언어가 같으면 한 번에 보낸다.
          Delivery d = bellByLanguage.get(u.LanguageLocaleKey);
          if (d == null) {
            d = record('BELL', u, subject, body, m.recordId);
            d.userIds.clear();
            bellByLanguage.put(u.LanguageLocaleKey, d);
          }
          d.userIds.add(u.Id);
        }
      }
      bells.addAll(bellByLanguage.values());
    }
    sendEmails(emails);
    sendBells(bells, notificationTypeId);
  }

  private static Map<String, String> tokens(
    CMN_NotificationService.Message m,
    Map<Id, User> users,
    Map<Id, Map<String, String>> recordTokens,
    String url
  ) {
    Map<String, String> out = new Map<String, String>{
      'RecordNo' => '',
      'Title' => '',
      'DueDate' => '',
      'Actor' => users.get(m.actorId)?.Name ?? '',
      'Url' => url ?? ''
    };
    out.putAll(recordTokens.get(m.recordId) ?? new Map<String, String>());
    out.putAll(m.params);
    return out;
  }

  /** 레코드의 업무 번호·제목(RecordNo__c, Name). 객체별 SOQL 1회. */
  private static Map<Id, Map<String, String>> recordTokens(Set<Id> recordIds) {
    Map<Schema.SObjectType, Set<Id>> byType = new Map<Schema.SObjectType, Set<Id>>();
    for (Id i : recordIds) {
      Schema.SObjectType t = i.getSObjectType();
      if (!byType.containsKey(t)) {
        byType.put(t, new Set<Id>());
      }
      byType.get(t).add(i);
    }
    Map<Id, Map<String, String>> out = new Map<Id, Map<String, String>>();
    for (Schema.SObjectType t : byType.keySet()) {
      Map<String, Schema.SObjectField> fields = t.getDescribe(
          SObjectDescribeOptions.DEFERRED
        )
        .fields.getMap();
      List<String> columns = new List<String>{ 'Id' };
      if (fields.containsKey('recordno__c')) {
        columns.add('RecordNo__c');
      }
      if (
        fields.containsKey('name') &&
        fields.get('name').getDescribe().isNameField()
      ) {
        columns.add('Name');
      }
      if (columns.size() == 1) {
        continue;
      }
      for (
        SObject r : Database.queryWithBinds(
          'SELECT ' +
            String.join(columns, ', ') +
            ' FROM ' +
            String.escapeSingleQuotes(String.valueOf(t)) +
            ' WHERE Id IN :ids',
          new Map<String, Object>{ 'ids' => byType.get(t) },
          AccessLevel.SYSTEM_MODE
        )
      ) {
        Map<String, Object> values = r.getPopulatedFieldsAsMap();
        String recordNo = (String) values.get('RecordNo__c');
        String name = (String) values.get('Name');
        out.put(
          r.Id,
          new Map<String, String>{
            'RecordNo' => recordNo ?? '',
            'Title' => String.join(
                new List<String>{ recordNo ?? '', name ?? '' },
                ' '
              )
              .trim()
          }
        );
      }
    }
    return out;
  }

  /** 수신자별 링크: 사내 = Lightning 레코드 URL, 포털 = 등록된 변환 클래스(없으면 사내 링크). */
  @TestVisible
  private static Map<Id, String> urls(
    CMN_NotificationService.Message m,
    Map<Id, User> users
  ) {
    Map<Id, String> out = new Map<Id, String>();
    if (m.recordId == null) {
      return out;
    }
    String internal =
      Url.getOrgDomainUrl().toExternalForm() +
      '/lightning/r/' +
      String.valueOf(m.recordId.getSObjectType()) +
      '/' +
      m.recordId +
      '/view';
    Set<Id> portal = new Set<Id>();
    for (Id userId : m.recipientIds) {
      out.put(userId, internal);
      if (
        users.get(userId)?.UserType != null &&
        users.get(userId).UserType != 'Standard'
      ) {
        portal.add(userId);
      }
    }
    String resolverClass = CMN_Settings.getString(
      'CMN_NTF_PORTAL_URL_RESOLVER',
      null
    );
    if (!portal.isEmpty() && resolverClass != null) {
      Type t = Type.forName(resolverClass);
      if (t == null) {
        CMN_Logger.warn(
          'CMN_NotificationJob',
          'Portal URL resolver not found: ' + resolverClass,
          m.recordId
        );
      } else {
        out.putAll(
          ((CMN_RecipientUrlResolver) t.newInstance())
            .urlsFor(m.recordId, portal)
        );
      }
    }
    return out;
  }

  private static Messaging.SingleEmailMessage email(
    Id userId,
    String subject,
    String body,
    Id fromAddressId
  ) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setTargetObjectId(userId);
    mail.setSaveAsActivity(false);
    mail.setSubject(subject);
    mail.setPlainTextBody(body);
    mail.setCharset('UTF-8');
    if (fromAddressId != null) {
      mail.setOrgWideEmailAddressId(fromAddressId);
    }
    return mail;
  }

  private static Delivery record(
    String channel,
    User u,
    String subject,
    String body,
    Id recordId
  ) {
    Delivery d = new Delivery();
    d.channel = channel;
    d.language = u.LanguageLocaleKey;
    d.userIds = new Set<Id>{ u.Id };
    d.subject = subject;
    d.body = body;
    d.recordId = recordId;
    return d;
  }

  private static void sendEmails(List<Messaging.SingleEmailMessage> emails) {
    if (emails.isEmpty()) {
      return;
    }
    try {
      for (Messaging.SendEmailResult r : Messaging.sendEmail(emails, false)) {
        if (!r.isSuccess()) {
          CMN_Logger.error(
            'CMN_NotificationJob.sendEmails',
            String.valueOf(r.getErrors()[0].getMessage()),
            r.getErrors()[0].getTargetObjectId()
          );
        }
      }
    } catch (System.EmailException e) {
      // 메일 발송 비활성(Deliverability) 등 Org 설정 문제. 벨 알림은 계속 보낸다.
      CMN_Logger.error(
        'CMN_NotificationJob.sendEmails',
        e.getMessage(),
        null,
        e
      );
    }
  }

  private static void sendBells(List<Delivery> bells, Id notificationTypeId) {
    for (Delivery d : bells) {
      Set<String> recipients = new Set<String>();
      for (Id i : d.userIds) {
        recipients.add(i);
      }
      Messaging.CustomNotification n = new Messaging.CustomNotification();
      n.setNotificationTypeId(notificationTypeId);
      n.setTitle(d.subject.abbreviate(BELL_TITLE_MAX));
      n.setBody(d.body.abbreviate(BELL_BODY_MAX));
      n.setTargetId(d.recordId);
      try {
        n.send(recipients);
        delivered.add(d);
      } catch (Exception e) {
        CMN_Logger.error(
          'CMN_NotificationJob.sendBells',
          e.getMessage(),
          d.recordId,
          e
        );
      }
    }
  }

  private static Id notificationTypeId() {
    List<CustomNotificationType> types = [
      SELECT Id
      FROM CustomNotificationType
      WHERE DeveloperName = :NOTIFICATION_TYPE
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return types.isEmpty() ? null : types[0].Id;
  }

  private static Id fromAddressId() {
    String address = CMN_Settings.getString('CMN_NTF_FROM_ADDRESS', null);
    if (address == null) {
      return null;
    }
    List<OrgWideEmailAddress> rows = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = :address
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0].Id;
  }
}
