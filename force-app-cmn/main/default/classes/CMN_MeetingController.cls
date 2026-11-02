/**
 * @description cmnMeetingPanel 진입점(CMN-00-MTG-001). 회의를 읽을 수 없으면 빈 패널, 편집 권한이 있어야 확정·조치 추가.
 * @group CMN-00-MTG-001
 */
public with sharing class CMN_MeetingController {
  /** @description 패널 데이터. */
  public class Panel {
    @AuraEnabled
    public Boolean canRead = false;
    @AuraEnabled
    public Boolean canEdit = false;
    @AuraEnabled
    public Boolean canConfirm = false;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public List<ActionRow> actions = new List<ActionRow>();
  }

  /** @description 조치 항목 한 줄. */
  public class ActionRow {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String ownerName;
    @AuraEnabled
    public Date dueDate;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String statusLabel;
    @AuraEnabled
    public Boolean canComplete;
  }

  /**
   * @description 패널 데이터.
   * @param meetingId 회의
   * @return 패널
   * @throws AuraHandledException 잘못된 입력
   */
  @AuraEnabled
  public static Panel getPanel(Id meetingId) {
    try {
      requireMeeting(meetingId);
      Panel p = new Panel();
      if (
        !CMN_CommentService.readableParents(new Set<Id>{ meetingId })
          .contains(meetingId)
      ) {
        return p;
      }
      p.canRead = true;
      p.canEdit = CMN_DocumentSelector.editableParents(new Set<Id>{ meetingId })
        .contains(meetingId);
      CMN_Meeting__c m = CMN_MeetingSelector.meetings(
        new Set<Id>{ meetingId }
      )[0];
      p.status = m.Status__c;
      p.canConfirm =
        p.canEdit &&
        (m.Status__c == CMN_MeetingService.HELD ||
        m.Status__c == CMN_MeetingService.MINUTES_DRAFT);
      Map<String, String> labels = new Map<String, String>();
      for (
        Schema.PicklistEntry e : CMN_ActionItem__c.Status__c.getDescribe()
          .getPicklistValues()
      ) {
        labels.put(e.getValue(), e.getLabel());
      }
      Id me = UserInfo.getUserId();
      for (CMN_ActionItem__c a : CMN_MeetingSelector.actionsOf(meetingId)) {
        ActionRow r = new ActionRow();
        r.id = a.Id;
        r.name = a.Name;
        r.ownerName = a.Owner__r?.Name;
        r.dueDate = a.DueDate__c;
        r.status = a.Status__c;
        r.statusLabel = labels.get(a.Status__c) ?? a.Status__c;
        r.canComplete =
          a.Status__c == 'OPEN' && (p.canEdit || a.Owner__c == me);
        p.actions.add(r);
      }
      return p;
    } catch (Exception e) {
      throw toAura(e, 'CMN_MeetingController.getPanel');
    }
  }

  /**
   * @description 회의록 확정(BR-2).
   * @param meetingId 회의
   * @return To-Do를 연 조치 항목 수
   * @throws AuraHandledException 권한·상태 오류
   */
  @AuraEnabled
  public static Integer confirmMinutes(Id meetingId) {
    try {
      requireMeeting(meetingId);
      return CMN_MeetingService.confirmMinutes(meetingId);
    } catch (Exception e) {
      throw toAura(e, 'CMN_MeetingController.confirmMinutes');
    }
  }

  /**
   * @description 조치 항목 추가.
   * @param meetingId 회의
   * @param title 조치 내용(80자)
   * @param ownerId 담당자
   * @param dueDate 기한
   * @return 조치 항목 Id
   * @throws AuraHandledException 입력·권한 오류
   */
  @AuraEnabled
  public static Id addAction(
    Id meetingId,
    String title,
    Id ownerId,
    Date dueDate
  ) {
    try {
      requireMeeting(meetingId);
      if (
        String.isBlank(title) ||
        ownerId == null ||
        ownerId.getSObjectType() != User.SObjectType ||
        dueDate == null
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      if (
        !CMN_DocumentSelector.editableParents(new Set<Id>{ meetingId })
          .contains(meetingId)
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      CMN_ActionItem__c a = new CMN_ActionItem__c(
        Name = title.left(80),
        Description__c = title,
        Meeting__c = meetingId,
        Owner__c = ownerId,
        DueDate__c = dueDate
      );
      Database.insert(a, AccessLevel.USER_MODE);
      return a.Id;
    } catch (Exception e) {
      throw toAura(e, 'CMN_MeetingController.addAction');
    }
  }

  /**
   * @description 조치 항목 완료(담당자 또는 회의 편집자).
   * @param actionId 조치 항목
   * @throws AuraHandledException 권한 오류
   */
  @AuraEnabled
  public static void completeAction(Id actionId) {
    try {
      if (
        actionId == null ||
        actionId.getSObjectType() != CMN_ActionItem__c.SObjectType
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      Database.update(
        new CMN_ActionItem__c(Id = actionId, Status__c = 'DONE'),
        AccessLevel.USER_MODE
      );
    } catch (Exception e) {
      throw toAura(e, 'CMN_MeetingController.completeAction');
    }
  }

  private static void requireMeeting(Id meetingId) {
    if (
      meetingId == null ||
      meetingId.getSObjectType() != CMN_Meeting__c.SObjectType
    ) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
  }

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
    } else {
      CMN_Logger.error(source, e.getMessage(), null, e);
      message = Label.CMN_Common_UnexpectedError;
    }
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
