/**
 * @description 코멘트 업무 규칙(CMN-00-UX-003 BR-2·BR-3).
 * - 쓰기: 부모 레코드를 읽을 수 있는 사용자만. 수정·삭제는 작성자 본인만, 작성 후 CMN_COMMENT_EDIT_HOURS(기본 24)시간 안에서만.
 *   같은 규칙을 트리거(CMN_CommentTriggerHandler)가 강제하므로 API·화면 어디서 바꿔도 같다.
 * - 멘션: 새로 멘션한 사내 사용자(작성자·포털 사용자 제외)에게 NTF-001 `CMN_COMMENT_MENTION` 알림. 멘션이 부모 접근 권한을 주지는 않는다.
 * - 조회: 부모 접근(UserRecordAccess)을 확인한 레코드의 코멘트만 돌려준다.
 * @group CMN-00-UX-003
 */
public with sharing class CMN_CommentService {
  public static final String MENTION_EVENT = 'CMN_COMMENT_MENTION';
  private static final Integer SNIPPET = 200;

  /**
   * @description 코멘트를 쓴다.
   * @param parentId 부모 레코드
   * @param body 본문
   * @param mentionedUserIds 멘션 사용자
   * @return 코멘트 Id
   * @throws CMN_ValidationException 본문 없음, 부모 접근 없음, 멘션 초과
   */
  public static Id post(Id parentId, String body, List<Id> mentionedUserIds) {
    CMN_Comment__c c = new CMN_Comment__c(
      ParentRecordId__c = parentId,
      Body__c = body,
      MentionedUserIds__c = joinIds(mentionedUserIds)
    );
    Database.insert(c, AccessLevel.USER_MODE);
    return c.Id;
  }

  /**
   * @description 본인 코멘트를 고친다.
   * @param commentId 코멘트
   * @param body 본문
   * @param mentionedUserIds 멘션 사용자(새로 추가된 사용자에게만 알림)
   * @throws CMN_ValidationException 작성자 아님, 수정 기한 경과, 본문 없음
   */
  public static void edit(
    Id commentId,
    String body,
    List<Id> mentionedUserIds
  ) {
    Database.update(
      new CMN_Comment__c(
        Id = commentId,
        Body__c = body,
        MentionedUserIds__c = joinIds(mentionedUserIds)
      ),
      AccessLevel.USER_MODE
    );
  }

  /**
   * @description 본인 코멘트를 지운다.
   * @param commentId 코멘트
   * @throws CMN_ValidationException 작성자 아님, 기한 경과
   */
  public static void remove(Id commentId) {
    Database.delete(new CMN_Comment__c(Id = commentId), AccessLevel.USER_MODE);
  }

  /**
   * @description 현재 사용자가 읽을 수 있는 부모 레코드.
   * @param parentIds 부모 레코드
   * @return 읽을 수 있는 것
   */
  public static Set<Id> readableParents(Set<Id> parentIds) {
    Set<Id> out = new Set<Id>();
    if (parentIds.isEmpty()) {
      return out;
    }
    for (UserRecordAccess a : [
      SELECT RecordId, HasReadAccess
      FROM UserRecordAccess
      WHERE UserId = :UserInfo.getUserId() AND RecordId IN :parentIds
      WITH SYSTEM_MODE
    ]) {
      if (a.HasReadAccess) {
        out.add(a.RecordId);
      }
    }
    return out;
  }

  /**
   * @description 수정·삭제 가능 시간.
   * @return 시간
   */
  public static Integer editHours() {
    return CMN_Settings.getInteger('CMN_COMMENT_EDIT_HOURS', 24);
  }

  /**
   * @description 작성 시각 기준으로 아직 수정할 수 있는지.
   * @param createdDate 작성 시각
   * @return 수정 가능
   */
  public static Boolean withinEditWindow(Datetime createdDate) {
    return createdDate == null ||
      createdDate.addHours(editHours()) > Datetime.now();
  }

  /**
   * @description 쉼표 목록의 사용자 Id(형식이 틀린 값은 버린다).
   * @param value MentionedUserIds__c
   * @return 사용자 Id
   */
  public static Set<Id> parseIds(String value) {
    Set<Id> out = new Set<Id>();
    for (String s : (value ?? '').split(',')) {
      String v = s.trim();
      if (v.length() >= 15 && v.length() <= 18 && v.startsWith('005')) {
        try {
          out.add(Id.valueOf(v));
        } catch (StringException e) {
          continue;
        }
      }
    }
    return out;
  }

  /**
   * @description 멘션 알림(새로 멘션한 사용자만, 작성자 제외). 코멘트 여러 건을 Queueable 하나로 보낸다.
   * @param comments 저장된 코멘트
   * @param oldMentions 코멘트 Id → 이전 멘션(새 코멘트는 없음)
   */
  public static void notifyMentions(
    List<CMN_Comment__c> comments,
    Map<Id, Set<Id>> oldMentions
  ) {
    Map<Id, Set<Id>> targetsByComment = new Map<Id, Set<Id>>();
    Set<Id> all = new Set<Id>();
    for (CMN_Comment__c c : comments) {
      Set<Id> targets = parseIds(c.MentionedUserIds__c);
      targets.removeAll(oldMentions.get(c.Id) ?? new Set<Id>());
      targets.remove(UserInfo.getUserId());
      if (!targets.isEmpty()) {
        targetsByComment.put(c.Id, targets);
        all.addAll(targets);
      }
    }
    if (all.isEmpty()) {
      return;
    }
    // 포털(협력사) 사용자는 멘션 알림을 받지 않는다: 알림에 사내 레코드 번호·제목·코멘트 일부가 들어간다
    Set<Id> internal = CMN_CommentSelector.internalUsers(all);
    List<CMN_NotificationService.Message> messages = new List<CMN_NotificationService.Message>();
    for (CMN_Comment__c c : comments) {
      Set<Id> targets = targetsByComment.get(c.Id);
      if (targets == null) {
        continue;
      }
      targets.retainAll(internal);
      if (targets.isEmpty()) {
        continue;
      }
      messages.add(
        new CMN_NotificationService.Message(
          MENTION_EVENT,
          targets,
          c.ParentRecordId__c,
          new Map<String, String>{ 'Comment' => c.Body__c.abbreviate(SNIPPET) }
        )
      );
    }
    CMN_NotificationService.send(messages);
  }

  private static String joinIds(List<Id> ids) {
    if (ids == null || ids.isEmpty()) {
      return null;
    }
    return String.join(new List<Id>(new Set<Id>(ids)), ',');
  }
}
