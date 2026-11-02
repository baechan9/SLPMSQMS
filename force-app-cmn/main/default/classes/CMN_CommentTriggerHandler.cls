/**
 * @description CMN_Comment__c 트리거(CMN-00-UX-003). 화면·API 어디서 저장해도 같은 규칙을 강제한다.
 * - 삽입: 부모 레코드 읽기 권한 확인, 대상 객체·요약(Name) 채우기, 멘션 정리·인원 제한.
 * - 수정: 작성자 본인·기한 안에서만, 부모 변경 불가, 본문이 바뀌면 IsEdited.
 * - 삭제: 작성자 본인·기한 안에서만.
 * - 저장 후: 새 멘션 알림.
 * @group CMN-00-UX-003
 */
public with sharing class CMN_CommentTriggerHandler extends CMN_TriggerHandler {
  private static final Integer NAME_MAX = 80;

  protected override void beforeInsert() {
    List<CMN_Comment__c> rows = (List<CMN_Comment__c>) newRecords;
    Set<Id> parents = new Set<Id>();
    for (CMN_Comment__c c : rows) {
      Id parentId = parentIdOf(c);
      if (parentId != null) {
        parents.add(parentId);
      }
    }
    Set<Id> readable = CMN_CommentService.readableParents(parents);
    for (CMN_Comment__c c : rows) {
      Id parentId = parentIdOf(c);
      if (parentId == null || !readable.contains(parentId)) {
        c.addError(Label.CMN_Comment_NoAccess);
        continue;
      }
      c.ParentRecordId__c = parentId;
      c.ParentObject__c = String.valueOf(parentId.getSObjectType());
      c.IsEdited__c = false;
      prepare(c);
    }
  }

  protected override void beforeUpdate() {
    Integer hours = CMN_CommentService.editHours();
    Map<Id, CMN_Comment__c> stored = CMN_CommentSelector.authorship(
      oldMap.keySet()
    );
    for (CMN_Comment__c c : (List<CMN_Comment__c>) newRecords) {
      CMN_Comment__c old = (CMN_Comment__c) oldMap.get(c.Id);
      if (!guard(c, stored.get(c.Id), hours)) {
        continue;
      }
      c.ParentRecordId__c = old.ParentRecordId__c;
      c.ParentObject__c = old.ParentObject__c;
      if (c.Body__c != old.Body__c) {
        c.IsEdited__c = true;
      }
      prepare(c);
    }
  }

  protected override void beforeDelete() {
    Integer hours = CMN_CommentService.editHours();
    Map<Id, CMN_Comment__c> stored = CMN_CommentSelector.authorship(
      oldMap.keySet()
    );
    for (CMN_Comment__c old : (List<CMN_Comment__c>) oldRecords) {
      guard(old, stored.get(old.Id), hours);
    }
  }

  protected override void afterInsert() {
    CMN_CommentService.notifyMentions(
      (List<CMN_Comment__c>) newRecords,
      new Map<Id, Set<Id>>()
    );
  }

  protected override void afterUpdate() {
    Map<Id, Set<Id>> before = new Map<Id, Set<Id>>();
    for (SObject o : oldRecords) {
      before.put(
        o.Id,
        CMN_CommentService.parseIds(((CMN_Comment__c) o).MentionedUserIds__c)
      );
    }
    CMN_CommentService.notifyMentions(
      (List<CMN_Comment__c>) newRecords,
      before
    );
  }

  /** 작성자 본인·기한 확인(감사 추적). 판정은 저장된 작성자·작성 시각으로 한다. 위반이면 오류를 달고 false. */
  private static Boolean guard(
    CMN_Comment__c target,
    CMN_Comment__c stored,
    Integer hours
  ) {
    if (stored?.CreatedById != UserInfo.getUserId()) {
      target.addError(Label.CMN_Comment_NotAuthor);
      return false;
    }
    if (!CMN_CommentService.withinEditWindow(stored.CreatedDate)) {
      target.addError(
        String.format(
          Label.CMN_Comment_EditExpired,
          new List<Object>{ String.valueOf(hours) }
        )
      );
      return false;
    }
    return true;
  }

  /** 본문 필수, 요약(Name), 멘션 정리(사용자 Id만, 중복 제거, 인원 제한). */
  private static void prepare(CMN_Comment__c c) {
    if (String.isBlank(c.Body__c)) {
      c.addError(Label.CMN_Comment_BodyRequired);
      return;
    }
    c.Name = c.Body__c.normalizeSpace().abbreviate(NAME_MAX);
    Set<Id> mentions = CMN_CommentService.parseIds(c.MentionedUserIds__c);
    Integer max = CMN_Settings.getInteger('CMN_COMMENT_MAX_MENTIONS', 20);
    if (mentions.size() > max) {
      c.addError(
        String.format(
          Label.CMN_Comment_TooManyMentions,
          new List<Object>{ String.valueOf(max) }
        )
      );
      return;
    }
    c.MentionedUserIds__c = mentions.isEmpty()
      ? null
      : String.join(new List<Id>(mentions), ',');
  }

  private static Id parentIdOf(CMN_Comment__c c) {
    try {
      return String.isBlank(c.ParentRecordId__c)
        ? null
        : Id.valueOf(c.ParentRecordId__c);
    } catch (StringException e) {
      return null;
    }
  }
}
