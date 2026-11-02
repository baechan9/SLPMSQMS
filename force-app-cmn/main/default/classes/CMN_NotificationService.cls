/**
 * @description 공통 알림 서비스(CMN-00-NTF-001). 메일·벨(모바일 푸시 포함)을 받는 사람 언어로 보낸다.
 * - 규칙: CMN_NotificationRule__mdt(DeveloperName = EventCode). 비활성·미등록이면 보내지 않고 WARN 로그(BR-3).
 * - 발송은 CMN_NotificationJob(Queueable)이 한다. 업무 트랜잭션은 큐 등록만 하고 발송 실패에 영향받지 않는다(BR-4).
 * - 문구는 규칙의 Custom Label만 쓴다(Email Template 금지). 토큰 {RecordNo} {Title} {Url} {DueDate} {Actor}는 서비스가 채우고,
 *   업무별 토큰은 params로 넘긴다(같은 이름이면 params가 우선).
 * @group CMN-00-NTF-001
 */
public with sharing class CMN_NotificationService {
  public static final String CHANNEL_EMAIL = 'EMAIL';
  public static final String CHANNEL_BELL = 'BELL';

  @TestVisible
  private static Map<String, CMN_NotificationRule__mdt> rulesOverride;
  /** 테스트: 큐에 넣은 알림 */
  @TestVisible
  private static List<Message> queued = new List<Message>();

  /** @description 알림 한 건(이벤트·수신자·레코드·치환값). 여러 건을 한 Queueable로 보낼 때 쓴다. */
  public class Message {
    public String eventCode;
    public List<Id> recipientIds;
    public Id recordId;
    public Map<String, String> params;
    public Id actorId;

    /**
     * @description 알림 한 건을 만든다. 보낸 사람(Actor)은 현재 사용자.
     * @param eventCode 규칙 코드
     * @param recipientUserIds 수신자(사내·포털 사용자)
     * @param recordId 알림 레코드({Url} 대상)
     * @param params 업무별 치환값
     */
    public Message(
      String eventCode,
      Set<Id> recipientUserIds,
      Id recordId,
      Map<String, String> params
    ) {
      this.eventCode = eventCode;
      this.recipientIds = new List<Id>(recipientUserIds ?? new Set<Id>());
      this.recordId = recordId;
      this.params = params ?? new Map<String, String>();
      this.actorId = UserInfo.getUserId();
    }
  }

  /**
   * @description 알림을 보낸다(비동기).
   * @param eventCode 규칙 코드(예: APV_STEP_PENDING)
   * @param recipientUserIds 수신자
   * @param recordId 알림 레코드
   * @param params 업무별 치환값
   */
  public static void send(
    String eventCode,
    Set<Id> recipientUserIds,
    Id recordId,
    Map<String, String> params
  ) {
    send(
      new List<Message>{
        new Message(eventCode, recipientUserIds, recordId, params)
      }
    );
  }

  /**
   * @description 여러 알림을 Queueable 하나로 보낸다(트리거·이벤트 구독의 일괄 처리용).
   * @param messages 알림
   */
  public static void send(List<Message> messages) {
    List<Message> active = new List<Message>();
    Set<String> skipped = new Set<String>();
    Id skippedRecord;
    for (Message m : messages ?? new List<Message>()) {
      CMN_NotificationRule__mdt rule = ruleOf(m.eventCode);
      if (rule == null || !rule.IsActive__c) {
        skipped.add(m.eventCode);
        skippedRecord = skippedRecord ?? m.recordId;
        continue;
      }
      Set<Id> recipients = new Set<Id>(m.recipientIds);
      recipients.remove(null);
      m.recipientIds = new List<Id>(recipients);
      if (!m.recipientIds.isEmpty()) {
        active.add(m);
      }
    }
    if (!skipped.isEmpty()) {
      // 반복문 안에서 로그 이벤트를 발행하지 않도록 한 번에 남긴다
      CMN_Logger.warn(
        'CMN_NotificationService.send',
        'Inactive or unknown notification event: ' +
        String.join(new List<String>(skipped), ', '),
        skippedRecord
      );
    }
    if (active.isEmpty()) {
      return;
    }
    if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
      CMN_Logger.error(
        'CMN_NotificationService.send',
        'Queueable limit reached, notifications dropped: ' + active.size(),
        active[0].recordId
      );
      return;
    }
    queued.addAll(active);
    System.enqueueJob(new CMN_NotificationJob(active));
  }

  /**
   * @description 규칙.
   * @param eventCode 규칙 코드
   * @return 규칙(없으면 null)
   */
  public static CMN_NotificationRule__mdt ruleOf(String eventCode) {
    if (String.isBlank(eventCode)) {
      return null;
    }
    if (rulesOverride != null) {
      return rulesOverride.get(eventCode);
    }
    return CMN_NotificationRule__mdt.getInstance(eventCode);
  }

  /**
   * @description 라벨을 받는 사람 언어로 가져와 {key} 토큰을 바꾼다(BR-1). 번역이 없으면 en_US, 라벨이 없으면 null.
   * @param labelName Custom Label 이름
   * @param languageLocaleKey 언어
   * @param tokens 치환값
   * @return 문구
   */
  public static String render(
    String labelName,
    String languageLocaleKey,
    Map<String, String> tokens
  ) {
    if (String.isBlank(labelName)) {
      return null;
    }
    String language = languageLocaleKey ?? 'en_US';
    String text;
    try {
      if (!System.Label.translationExists('', labelName, language)) {
        language = 'en_US';
      }
      text = System.Label.get('', labelName, language);
    } catch (System.InvalidParameterValueException e) {
      return null;
    }
    for (String k : tokens.keySet()) {
      text = text.replace('{' + k + '}', tokens.get(k) ?? '');
    }
    return text;
  }
}
