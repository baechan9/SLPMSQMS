/**
 * @description 공통 알림 서비스 검증(CMN-00-NTF-001).
 * @group CMN-00-NTF-001
 */
@IsTest
private class CMN_NotificationService_Test {
  private static final String EVENT = 'APV_STEP_PENDING';

  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    CMN_Plant__c p = new CMN_Plant__c(
      Name = 'KR01',
      PlantCode__c = 'KR01',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
    insert p;
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User ko = CMN_TestDataFactory.newUser('ntfko', 'ntfko', profileId);
    User en = CMN_TestDataFactory.newUser('ntfen', 'ntfen', profileId);
    en.LanguageLocaleKey = 'en_US';
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ ko, en };
    }
    insert new CMN_TestRecord__c(
      Name = 'target',
      Plant__c = p.Id,
      Status__c = 'DRAFT'
    );
  }

  @IsTest
  static void test_AC01_eachRecipientGetsOwnLanguageMailAndBell() {
    // Given: 수신자 2명(ko, en_US)
    User ko = user('ntfko');
    User en = user('ntfen');
    CMN_TestRecord__c rec = record();
    CMN_Settings.overrides.put(
      'CMN_NTF_FROM_ADDRESS',
      'not-registered@example.com'
    );

    // When
    Test.startTest();
    CMN_NotificationService.send(
      EVENT,
      new Set<Id>{ ko.Id, en.Id },
      rec.Id,
      new Map<String, String>{ 'Title' => 'NCR-KR01-2026-000001 X' }
    );
    Test.stopTest();

    // Then: 각자 언어 메일 1건·벨 1건, 링크는 Lightning 레코드 URL, 보낸 사람 이름 치환
    Map<String, CMN_NotificationJob.Delivery> mail = byLanguage('EMAIL');
    Map<String, CMN_NotificationJob.Delivery> bell = byLanguage('BELL');
    Assert.areEqual(2, mail.size());
    Assert.areEqual(2, bell.size());
    Assert.areEqual(
      '[결재 요청] NCR-KR01-2026-000001 X',
      mail.get('ko').subject
    );
    Assert.areEqual(
      '[Approval Request] NCR-KR01-2026-000001 X',
      mail.get('en_US').subject
    );
    Assert.isTrue(
      mail.get('en_US')
        .body.contains('/lightning/r/CMN_TestRecord__c/' + rec.Id + '/view'),
      mail.get('en_US').body
    );
    Assert.isTrue(
      mail.get('en_US').body.startsWith(UserInfo.getName()),
      mail.get('en_US').body
    );
    Assert.areEqual(new Set<Id>{ en.Id }, bell.get('en_US').userIds);
  }

  @IsTest
  static void test_AC02_inactiveRuleSendsNothingAndLogsWarn() {
    // Given: IsActive=false 규칙, 미등록 코드
    User ko = user('ntfko');

    // When
    Integer before = Limits.getQueueableJobs();
    CMN_NotificationService.send(
      'CMN_TEST_INACTIVE',
      new Set<Id>{ ko.Id },
      record().Id,
      null
    );
    Integer jobs = Limits.getQueueableJobs() - before;
    Test.getEventBus().deliver();

    // Then: 발송 0건(큐 등록 없음), WARN 로그 1건
    Assert.areEqual(0, jobs);
    Assert.areEqual(0, CMN_NotificationService.queued.size());
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM CMN_Log__c
        WHERE Level__c = 'WARN' AND Source__c = 'CMN_NotificationService.send'
      ]
    );
    CMN_NotificationService.send(
      'NO_SUCH_EVENT',
      new Set<Id>{ ko.Id },
      null,
      null
    );
    Assert.areEqual(before, Limits.getQueueableJobs());
  }

  @IsTest
  static void test_AC03_300RecipientsAreSentInChunks() {
    // Given: 수신자 300명(실제 사용자 2명 + 사용자 Id 298개, Scratch Org에서 300명을 만들 수 없음), 1회 100명
    CMN_Settings.overrides.put('CMN_NTF_CHUNK_SIZE', '100');
    Set<Id> recipients = new Set<Id>{ user('ntfko').Id, user('ntfen').Id };
    String prefix = User.SObjectType.getDescribe(
        SObjectDescribeOptions.DEFERRED
      )
      .getKeyPrefix();
    for (Integer i = 1; recipients.size() < 300; i++) {
      recipients.add(
        Id.valueOf(prefix + 'Z' + String.valueOf(i).leftPad(11, '0'))
      );
    }
    Integer before = Limits.getQueueableJobs();
    CMN_NotificationService.send(EVENT, recipients, record().Id, null);
    Assert.areEqual(
      1,
      Limits.getQueueableJobs() - before,
      'Queueable 1개로 등록'
    );

    // When: Queueable을 이어서 실행(테스트에서는 실제로 잇지 못해 직접 실행)
    CMN_NotificationJob job = new CMN_NotificationJob(
      CMN_NotificationService.queued
    );
    Integer runs = 0;
    while (job != null) {
      CMN_NotificationJob.chained = null;
      job.execute(null);
      runs++;
      job = CMN_NotificationJob.chained == null
        ? null
        : new CMN_NotificationJob(CMN_NotificationJob.chained);
    }

    // Then: 3번에 나눠 보내고, 실제 사용자 2명만 메일을 받는다
    Assert.areEqual(3, runs);
    Assert.areEqual(2, byLanguage('EMAIL').size());
  }

  @IsTest
  static void test_BR_approvalEventsQueueNotifications() {
    // Given: 결재자 ntfko
    User approver = user('ntfko');
    Id target = record().Id;
    CMN_ApprovalService.submit(
      target,
      'CMN_TEST_APPROVE',
      new List<CMN_ApprovalStepSpec>{
        new CMN_ApprovalStepSpec(1, 'APPROVE', approver.Id, null)
      },
      null
    );

    // When: PENDING 이벤트 처리
    Test.getEventBus().deliver();

    // Then: 결재자에게 결재 요청 알림(보낸 사람 = 기안자, 링크 = 대상)
    CMN_NotificationService.Message pending = only('APV_STEP_PENDING');
    Assert.areEqual(new List<Id>{ approver.Id }, pending.recipientIds);
    Assert.areEqual(UserInfo.getUserId(), pending.actorId);
    Assert.areEqual(target, pending.recordId);

    // When: 반려 → 기안자에게 반려 알림(보낸 사람 = 반려자)
    System.runAs(approver) {
      CMN_ApprovalService.reject(
        [SELECT Id FROM CMN_ApprovalStep__c WHERE Approver__c = :approver.Id]
        .Id,
        'no'
      );
    }
    Test.getEventBus().deliver();
    CMN_NotificationService.Message rejected = only('APV_REJECTED');
    Assert.areEqual(
      new List<Id>{ UserInfo.getUserId() },
      rejected.recipientIds
    );
    Assert.areEqual(approver.Id, rejected.actorId);

    // When: 재상신 후 승인 → 기안자에게 승인 알림
    CMN_ApprovalService.submit(
      target,
      'CMN_TEST_APPROVE',
      new List<CMN_ApprovalStepSpec>{
        new CMN_ApprovalStepSpec(1, 'APPROVE', approver.Id, null)
      },
      null
    );
    Test.getEventBus().deliver();
    System.runAs(approver) {
      CMN_ApprovalService.approve(
        [
          SELECT Id
          FROM CMN_ApprovalStep__c
          WHERE Approver__c = :approver.Id AND Status__c = 'PENDING'
        ]
        .Id,
        'ok'
      );
    }
    Test.getEventBus().deliver();
    Assert.areEqual(
      new List<Id>{ UserInfo.getUserId() },
      only('APV_APPROVED').recipientIds
    );
  }

  @IsTest
  static void test_BR4_missingLabelAndInactiveRecipientAreSkipped() {
    // Given: 라벨이 없는 규칙, 비활성 수신자
    CMN_NotificationService.rulesOverride = new Map<String, CMN_NotificationRule__mdt>{
      'CMN_TEST_NOLABEL' => new CMN_NotificationRule__mdt(
        DeveloperName = 'CMN_TEST_NOLABEL',
        Channels__c = 'EMAIL, BELL',
        SubjectLabel__c = 'CMN_Ntf_NotDeployedYet',
        BodyLabel__c = 'CMN_Ntf_NotDeployedYet',
        IsActive__c = true
      )
    };
    User ko = user('ntfko');

    // When: 업무 트랜잭션이 아니라 Queueable에서 실패를 처리한다
    Test.startTest();
    CMN_NotificationService.send(
      'CMN_TEST_NOLABEL',
      new Set<Id>{ ko.Id },
      record().Id,
      null
    );
    Test.stopTest();
    Test.getEventBus().deliver();

    // Then: 발송 0건, WARN 로그
    Assert.areEqual(0, CMN_NotificationJob.delivered.size());
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM CMN_Log__c
        WHERE Level__c = 'WARN' AND Source__c = 'CMN_NotificationJob'
      ]
    );
  }

  @IsTest
  static void test_BR1_renderUsesLanguageThenEnglish() {
    Map<String, String> tokens = new Map<String, String>{ 'Title' => 'T-1' };
    Assert.areEqual(
      '[审批请求] T-1',
      CMN_NotificationService.render(
        'CMN_Ntf_ApvStepPending_Subject',
        'zh_CN',
        tokens
      )
    );
    Assert.areEqual(
      '[Approval Request] T-1',
      CMN_NotificationService.render(
        'CMN_Ntf_ApvStepPending_Subject',
        'ja',
        tokens
      )
    );
    Assert.isNull(
      CMN_NotificationService.render('CMN_Ntf_NotDeployedYet', 'ko', tokens)
    );
    Assert.isNull(CMN_NotificationService.render(null, 'ko', tokens));
    Assert.isNull(CMN_NotificationService.ruleOf(''));
  }

  @IsTest
  static void test_BR5_portalRecipientsUseRegisteredResolver() {
    // Given: 사내 사용자와 포털 사용자(사용자 유형은 쓸 수 없는 필드라 JSON으로 만든다), 변환 클래스 등록
    User internal = user('ntfko');
    User portal = (User) JSON.deserialize(
      '{"Id":"' +
        user('ntfen').Id +
        '","UserType":"PowerPartner","IsActive":true}',
      User.class
    );
    Id recordId = record().Id;
    CMN_NotificationService.Message m = new CMN_NotificationService.Message(
      EVENT,
      new Set<Id>{ internal.Id, portal.Id },
      recordId,
      null
    );
    Map<Id, User> users = new Map<Id, User>{
      internal.Id => new User(Id = internal.Id),
      portal.Id => portal
    };
    CMN_Settings.overrides.put(
      'CMN_NTF_PORTAL_URL_RESOLVER',
      'CMN_NotificationService_Test.PortalResolver'
    );

    // When
    Map<Id, String> urls = CMN_NotificationJob.urls(m, users);

    // Then: 포털 사용자는 변환 URL, 사내 사용자는 Lightning URL
    Assert.areEqual(
      'https://portal.example.com/supplier/' + recordId,
      urls.get(portal.Id)
    );
    Assert.isTrue(
      urls.get(internal.Id)
        .endsWith('/lightning/r/CMN_TestRecord__c/' + recordId + '/view')
    );

    // 등록한 클래스가 없으면 사내 링크 + WARN
    CMN_Settings.overrides.put(
      'CMN_NTF_PORTAL_URL_RESOLVER',
      'CMN_NoSuchResolver'
    );
    Assert.isTrue(
      CMN_NotificationJob.urls(m, users)
        .get(portal.Id)
        .contains('/lightning/r/')
    );
  }

  /** 포털 링크 변환 예(QMS-03-SPP-001이 실제 구현). */
  public class PortalResolver implements CMN_RecipientUrlResolver {
    public Map<Id, Map<Id, String>> urlsFor(
      Map<Id, Set<Id>> portalUsersByRecord
    ) {
      Map<Id, Map<Id, String>> out = new Map<Id, Map<Id, String>>();
      for (Id recordId : portalUsersByRecord.keySet()) {
        Map<Id, String> urls = new Map<Id, String>();
        for (Id u : portalUsersByRecord.get(recordId)) {
          urls.put(u, 'https://portal.example.com/supplier/' + recordId);
        }
        out.put(recordId, urls);
      }
      return out;
    }
  }

  // ------------------------------------------------------------------ 도우미
  private static User user(String alias) {
    return [
      SELECT Id
      FROM User
      WHERE Alias = :alias
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
  }

  private static CMN_TestRecord__c record() {
    return [SELECT Id FROM CMN_TestRecord__c LIMIT 1];
  }

  private static Map<String, CMN_NotificationJob.Delivery> byLanguage(
    String channel
  ) {
    Map<String, CMN_NotificationJob.Delivery> out = new Map<String, CMN_NotificationJob.Delivery>();
    for (CMN_NotificationJob.Delivery d : CMN_NotificationJob.delivered) {
      if (d.channel == channel) {
        out.put(d.language, d);
      }
    }
    return out;
  }

  private static CMN_NotificationService.Message only(String eventCode) {
    CMN_NotificationService.Message found;
    for (CMN_NotificationService.Message m : CMN_NotificationService.queued) {
      if (m.eventCode == eventCode) {
        Assert.isNull(found, '알림 1건: ' + eventCode);
        found = m;
      }
    }
    Assert.isNotNull(found, eventCode);
    return found;
  }
}
