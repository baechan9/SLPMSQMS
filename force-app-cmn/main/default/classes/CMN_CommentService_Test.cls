/**
 * @description 코멘트 타임라인 서버 검증(CMN-00-UX-003).
 * @group CMN-00-UX-003
 */
@IsTest
private class CMN_CommentService_Test {
  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    CMN_Plant__c kr02 = new CMN_Plant__c(
      Name = 'KR02',
      PlantCode__c = 'KR02',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
    insert kr02;
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    List<User> users = new List<User>();
    for (String a : new List<String>{ 'cmta', 'cmtb', 'cmtc', 'cmtd' }) {
      users.add(CMN_TestDataFactory.newUser(a, a, profileId));
    }
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert users;
      // 부모 객체 읽기 권한(공유는 따로): 접근 차이는 레코드 공유로만 만든다
      PermissionSet parentRead = new PermissionSet(
        Name = 'CMN_TST_CommentParentRead',
        Label = 'CMN TST Comment Parent Read'
      );
      insert parentRead;
      insert new ObjectPermissions(
        ParentId = parentRead.Id,
        SobjectType = 'CMN_TestRecord__c',
        PermissionsRead = true
      );
      Id commentPs = [
        SELECT Id
        FROM PermissionSet
        WHERE Name = 'CMN_PS_Comment_User'
      ]
      .Id;
      List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
      for (User u : users) {
        psa.add(
          new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = commentPs
          )
        );
        psa.add(
          new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = parentRead.Id
          )
        );
      }
      insert psa;
    }
    CMN_TestRecord__c ncr = new CMN_TestRecord__c(
      Name = 'KR02 NCR',
      Plant__c = kr02.Id,
      Status__c = 'IN_PROGRESS'
    );
    insert ncr;
    // A(cmta)만 공유 없음
    List<CMN_TestRecord__Share> shares = new List<CMN_TestRecord__Share>();
    for (User u : users) {
      if (u.Alias != 'cmta') {
        shares.add(
          new CMN_TestRecord__Share(
            ParentId = ncr.Id,
            UserOrGroupId = u.Id,
            AccessLevel = 'Read',
            RowCause = 'Manual'
          )
        );
      }
    }
    insert shares;
  }

  @IsTest
  static void test_AC01_noParentAccessReturnsEmpty() {
    // Given: B가 KR02 NCR에 코멘트, A는 NCR 접근 권한 없음
    Id ncr = parentId();
    System.runAs(user('cmtb')) {
      CMN_CommentController.postComment(ncr, 'containment started', null);
    }

    // When: A가 조회 API 호출
    List<CMN_CommentController.CommentItem> seen;
    System.runAs(user('cmta')) {
      seen = CMN_CommentController.getComments(ncr);
      // 쓰기도 막힌다
      expectAura(Label.CMN_Comment_NoAccess, ncr, 'hi');
    }

    // Then: 빈 결과. 접근 권한이 있는 C는 1건
    Assert.areEqual(0, seen.size());
    System.runAs(user('cmtc')) {
      List<CMN_CommentController.CommentItem> c = CMN_CommentController.getComments(
        ncr
      );
      Assert.areEqual(1, c.size());
      Assert.areEqual('containment started', c[0].body);
      Assert.isFalse(c[0].canEdit, '남의 코멘트');
    }
  }

  @IsTest
  static void test_AC02_editBlockedAfter24Hours() {
    // Given: B의 코멘트 2건(하나는 25시간 전)
    Id ncr = parentId();
    User b = user('cmtb');
    Id fresh;
    Id old;
    System.runAs(b) {
      fresh = CMN_CommentController.postComment(ncr, 'fresh', null);
      old = CMN_CommentController.postComment(ncr, 'old', null);
    }
    Test.setCreatedDate(old, Datetime.now().addHours(-25));

    System.runAs(b) {
      // When / Then: 25시간 지난 코멘트 수정·삭제 차단
      String expired = String.format(
        Label.CMN_Comment_EditExpired,
        new List<Object>{ '24' }
      );
      try {
        CMN_CommentController.editComment(old, 'changed', null);
        Assert.fail('수정이 막혀야 한다');
      } catch (AuraHandledException e) {
        Assert.areEqual(expired, e.getMessage());
      }
      try {
        CMN_CommentController.deleteComment(old);
        Assert.fail('삭제가 막혀야 한다');
      } catch (AuraHandledException e) {
        Assert.areEqual(expired, e.getMessage());
      }
      // 기한 안이면 수정되고 '수정됨' 표시
      CMN_CommentController.editComment(fresh, 'fresh v2', null);
      Map<Id, CMN_CommentController.CommentItem> byId = new Map<Id, CMN_CommentController.CommentItem>();
      for (
        CMN_CommentController.CommentItem i : CMN_CommentController.getComments(
          ncr
        )
      ) {
        byId.put(i.id, i);
      }
      Assert.isTrue(byId.get(fresh).isEdited);
      Assert.isTrue(byId.get(fresh).canEdit);
      Assert.isFalse(byId.get(old).canEdit);
      Assert.areEqual('fresh v2', byId.get(fresh).body);
      CMN_CommentController.deleteComment(fresh);
    }
    Assert.areEqual(1, [SELECT COUNT() FROM CMN_Comment__c]);
  }

  @IsTest
  static void test_AC03_mentionNotifiesUserOnce() {
    // Given: B가 C를 멘션(자기 자신도 멘션)
    Id ncr = parentId();
    User b = user('cmtb');
    User c = user('cmtc');
    User d = user('cmtd');
    Id commentId;

    // When
    System.runAs(b) {
      commentId = CMN_CommentController.postComment(
        ncr,
        '@cmtc please check',
        new List<Id>{ c.Id, b.Id, c.Id }
      );
    }

    // Then: C에게 멘션 알림 1건(작성자 제외), 링크 = 부모 레코드
    List<CMN_NotificationService.Message> sent = mentions();
    Assert.areEqual(1, sent.size());
    Assert.areEqual(new List<Id>{ c.Id }, sent[0].recipientIds);
    Assert.areEqual(ncr, sent[0].recordId);
    Assert.areEqual('@cmtc please check', sent[0].params.get('Comment'));

    // 수정에서 D를 더하면 D에게만 알림
    System.runAs(b) {
      CMN_CommentController.editComment(
        commentId,
        '@cmtc @cmtd please check',
        new List<Id>{ c.Id, d.Id }
      );
    }
    sent = mentions();
    Assert.areEqual(2, sent.size());
    Assert.areEqual(new List<Id>{ d.Id }, sent[1].recipientIds);
    System.runAs(c) {
      List<CMN_CommentController.CommentItem> items = CMN_CommentController.getComments(
        ncr
      );
      Assert.areEqual(2, items[0].mentions.size());
    }
  }

  @IsTest
  static void test_BR2_onlyAuthorCanEditOrDelete() {
    // Given: B의 코멘트
    Id ncr = parentId();
    Id commentId;
    System.runAs(user('cmtb')) {
      commentId = CMN_CommentController.postComment(ncr, 'mine', null);
    }

    // When / Then: C(부모 접근 있음)가 수정·삭제 → 작성자만
    System.runAs(user('cmtc')) {
      for (Integer i = 0; i < 2; i++) {
        try {
          if (i == 0) {
            CMN_CommentController.editComment(commentId, 'x', null);
          } else {
            CMN_CommentController.deleteComment(commentId);
          }
          Assert.fail('작성자만');
        } catch (AuraHandledException e) {
          Assert.areEqual(Label.CMN_Comment_NotAuthor, e.getMessage());
        }
      }
    }
    // 시스템 문맥(관리자 자동화)도 작성자가 아니면 막힌다(감사 추적)
    try {
      update new CMN_Comment__c(Id = commentId, Body__c = 'admin');
      Assert.fail('작성자만');
    } catch (DmlException e) {
      Assert.areEqual(Label.CMN_Comment_NotAuthor, e.getDmlMessage(0));
    }
  }

  @IsTest
  static void test_negative_inputValidation() {
    Id ncr = parentId();
    System.runAs(user('cmtb')) {
      expectAura(Label.CMN_Comment_BodyRequired, ncr, '  ');
      expectAura(Label.CMN_Common_InvalidInput, null, 'x');
      try {
        CMN_CommentController.postComment(ncr, 'x', new List<Id>{ ncr });
        Assert.fail('사용자 Id만');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
      }
      try {
        CMN_CommentController.editComment(ncr, 'x', null);
        Assert.fail('코멘트 Id만');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
      }
      // 멘션 인원 제한
      CMN_Settings.overrides.put('CMN_COMMENT_MAX_MENTIONS', '1');
      try {
        CMN_CommentController.postComment(
          ncr,
          'x',
          new List<Id>{ user('cmtc').Id, user('cmtd').Id }
        );
        Assert.fail('멘션 초과');
      } catch (AuraHandledException e) {
        Assert.areEqual(
          String.format(
            Label.CMN_Comment_TooManyMentions,
            new List<Object>{ '1' }
          ),
          e.getMessage()
        );
      }
    }
    Assert.areEqual(
      0,
      CMN_CommentService.parseIds('abc, 001000000000001').size()
    );
  }

  @IsTest
  static void test_BR3_triggerRulesForDirectDml() {
    // Given: 부모 소유자(관리자)
    Id ncr = parentId();
    List<Database.SaveResult> results = Database.insert(
      new List<CMN_Comment__c>{
        new CMN_Comment__c(ParentRecordId__c = 'not-an-id', Body__c = 'x'),
        new CMN_Comment__c(ParentRecordId__c = ncr, Body__c = ' '),
        new CMN_Comment__c(ParentRecordId__c = ncr, Body__c = 'ok')
      },
      false
    );

    // Then: 잘못된 부모 → 접근 없음, 빈 본문 → 필수, 정상 1건
    Assert.areEqual(
      Label.CMN_Comment_NoAccess,
      results[0].getErrors()[0].getMessage()
    );
    Assert.areEqual(
      Label.CMN_Comment_BodyRequired,
      results[1].getErrors()[0].getMessage()
    );
    Assert.isTrue(results[2].isSuccess());

    // 부모는 바꿀 수 없다(원래 부모 유지)
    update new CMN_Comment__c(
      Id = results[2].getId(),
      ParentRecordId__c = UserInfo.getUserId(),
      Body__c = 'ok2'
    );
    CMN_Comment__c saved = [
      SELECT ParentRecordId__c, IsEdited__c
      FROM CMN_Comment__c
      WHERE Id = :results[2].getId()
    ];
    Assert.areEqual(String.valueOf(ncr), saved.ParentRecordId__c);
    Assert.isTrue(saved.IsEdited__c);
  }

  @IsTest
  static void test_bulk200CommentsConstantQueries() {
    // Given: 부모 소유자(관리자)가 200건 일괄 저장
    Id ncr = parentId();
    List<CMN_Comment__c> rows = new List<CMN_Comment__c>();
    for (Integer i = 0; i < 200; i++) {
      rows.add(
        new CMN_Comment__c(ParentRecordId__c = ncr, Body__c = 'bulk ' + i)
      );
    }

    // When
    Integer q0 = Limits.getQueries();
    insert rows;

    // Then: 트리거 SOQL은 건수와 무관(부모 접근 1회)
    Assert.isTrue(
      Limits.getQueries() - q0 <= 2,
      'SOQL ' + (Limits.getQueries() - q0)
    );
    Assert.areEqual(
      'CMN_TestRecord__c',
      [SELECT ParentObject__c FROM CMN_Comment__c LIMIT 1].ParentObject__c
    );
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

  private static Id parentId() {
    return [SELECT Id FROM CMN_TestRecord__c LIMIT 1].Id;
  }

  private static List<CMN_NotificationService.Message> mentions() {
    List<CMN_NotificationService.Message> out = new List<CMN_NotificationService.Message>();
    for (CMN_NotificationService.Message m : CMN_NotificationService.queued) {
      if (m.eventCode == CMN_CommentService.MENTION_EVENT) {
        out.add(m);
      }
    }
    return out;
  }

  private static void expectAura(String expected, Id parentId, String body) {
    try {
      CMN_CommentController.postComment(parentId, body, null);
      Assert.fail('예외가 나야 한다: ' + expected);
    } catch (AuraHandledException e) {
      Assert.areEqual(expected, e.getMessage());
    }
  }
}
