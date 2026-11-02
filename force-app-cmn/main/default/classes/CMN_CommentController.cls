/**
 * @description cmnCommentTimeline 진입점(CMN-00-UX-003). 입력을 다시 검증하고, 조회는 부모 레코드를 읽을 수 있을 때만 돌려준다(AC-1).
 * @group CMN-00-UX-003
 */
public with sharing class CMN_CommentController {
  private static final Integer MAX_ROWS = 200;
  private static final Integer BODY_MAX = 32768;
  private static final Set<StatusCode> NO_ACCESS = new Set<StatusCode>{
    StatusCode.INSUFFICIENT_ACCESS_OR_READONLY,
    StatusCode.INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
  };

  /** @description 코멘트 한 건(화면에 필요한 값만). */
  public class CommentItem {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String body;
    @AuraEnabled
    public Id authorId;
    @AuraEnabled
    public String authorName;
    @AuraEnabled
    public Datetime createdDate;
    @AuraEnabled
    public Boolean isEdited;
    @AuraEnabled
    public Boolean canEdit;
    @AuraEnabled
    public List<Mention> mentions = new List<Mention>();
  }

  /** @description 멘션 사용자. */
  public class Mention {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String name;
  }

  /**
   * @description 부모 레코드의 코멘트(최신순 200건). 부모를 읽을 수 없으면 빈 목록.
   * @param parentId 부모 레코드
   * @return 코멘트
   * @throws AuraHandledException 잘못된 입력
   */
  @AuraEnabled
  public static List<CommentItem> getComments(Id parentId) {
    List<CommentItem> out = new List<CommentItem>();
    try {
      requireId(parentId);
      if (
        !CMN_CommentService.readableParents(new Set<Id>{ parentId })
          .contains(parentId)
      ) {
        return out;
      }
      List<CMN_Comment__c> rows = CMN_CommentSelector.forParent(
        parentId,
        MAX_ROWS
      );
      Set<Id> mentioned = new Set<Id>();
      for (CMN_Comment__c c : rows) {
        mentioned.addAll(CMN_CommentService.parseIds(c.MentionedUserIds__c));
      }
      Map<Id, User> users = mentioned.isEmpty()
        ? new Map<Id, User>()
        : CMN_CommentSelector.users(mentioned);
      Id me = UserInfo.getUserId();
      for (CMN_Comment__c c : rows) {
        CommentItem item = new CommentItem();
        item.id = c.Id;
        item.body = c.Body__c;
        item.authorId = c.CreatedById;
        item.authorName = c.CreatedBy.Name;
        item.createdDate = c.CreatedDate;
        item.isEdited = c.IsEdited__c;
        item.canEdit =
          c.CreatedById == me &&
          CMN_CommentService.withinEditWindow(c.CreatedDate);
        for (Id u : CMN_CommentService.parseIds(c.MentionedUserIds__c)) {
          Mention m = new Mention();
          m.id = u;
          m.name = users.get(u)?.Name ?? '';
          item.mentions.add(m);
        }
        out.add(item);
      }
      return out;
    } catch (Exception e) {
      throw toAura(e, 'CMN_CommentController.getComments');
    }
  }

  /**
   * @description 코멘트를 쓴다.
   * @param parentId 부모 레코드
   * @param body 본문
   * @param mentionedUserIds 멘션 사용자
   * @return 코멘트 Id
   * @throws AuraHandledException 입력 오류, 접근 권한 없음
   */
  @AuraEnabled
  public static Id postComment(
    Id parentId,
    String body,
    List<Id> mentionedUserIds
  ) {
    try {
      requireId(parentId);
      requireBody(body);
      return CMN_CommentService.post(parentId, body, users(mentionedUserIds));
    } catch (Exception e) {
      throw toAura(e, 'CMN_CommentController.postComment');
    }
  }

  /**
   * @description 본인 코멘트를 고친다.
   * @param commentId 코멘트
   * @param body 본문
   * @param mentionedUserIds 멘션 사용자
   * @throws AuraHandledException 입력 오류, 작성자 아님, 기한 경과
   */
  @AuraEnabled
  public static void editComment(
    Id commentId,
    String body,
    List<Id> mentionedUserIds
  ) {
    try {
      requireComment(commentId);
      requireBody(body);
      CMN_CommentService.edit(commentId, body, users(mentionedUserIds));
    } catch (Exception e) {
      throw toAura(e, 'CMN_CommentController.editComment');
    }
  }

  /**
   * @description 본인 코멘트를 지운다.
   * @param commentId 코멘트
   * @throws AuraHandledException 작성자 아님, 기한 경과
   */
  @AuraEnabled
  public static void deleteComment(Id commentId) {
    try {
      requireComment(commentId);
      CMN_CommentService.remove(commentId);
    } catch (Exception e) {
      throw toAura(e, 'CMN_CommentController.deleteComment');
    }
  }

  // ------------------------------------------------------------------ 검증
  private static void requireId(Id value) {
    if (value == null) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
  }

  private static void requireComment(Id value) {
    if (value == null || value.getSObjectType() != CMN_Comment__c.SObjectType) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
  }

  private static void requireBody(String body) {
    if (String.isBlank(body)) {
      throw new CMN_ValidationException(Label.CMN_Comment_BodyRequired);
    }
    if (body.length() > BODY_MAX) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
  }

  /** 멘션은 사용자 Id만 받는다. */
  private static List<Id> users(List<Id> ids) {
    List<Id> out = new List<Id>();
    for (Id i : ids ?? new List<Id>()) {
      if (i == null || i.getSObjectType() != User.SObjectType) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      out.add(i);
    }
    return out;
  }

  /** 검증·저장 규칙 오류는 라벨 문구 그대로, 그 밖의 오류는 기록하고 공통 문구로. */
  private static AuraHandledException toAura(Exception e, String source) {
    String message;
    if (e instanceof CMN_ValidationException) {
      message = e.getMessage();
    } else if (
      e instanceof DmlException &&
      ((DmlException) e).getDmlType(0) ==
      StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION
    ) {
      message = ((DmlException) e).getDmlMessage(0);
    } else if (
      e instanceof DmlException &&
      NO_ACCESS.contains(((DmlException) e).getDmlType(0))
    ) {
      // 남의 코멘트(Private, Owner = 작성자)는 공유 단계에서 막힌다
      message = Label.CMN_Comment_NotAuthor;
    } else {
      CMN_Logger.error(source, e.getMessage(), null, e);
      message = Label.CMN_Common_UnexpectedError;
    }
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
