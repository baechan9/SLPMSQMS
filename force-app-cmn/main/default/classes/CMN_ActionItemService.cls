/**
 * @description 공통 조치 항목 규칙(CMN-00-MTG-001 BR-3). 회의 외 업무도 같은 객체·서비스를 쓴다.
 * - 담당자(Owner__c) 필수, 공장은 회의에서 복사, 완료 일시 기록.
 * - To-Do(SourceType CMN_ACTION_ITEM): 회의 조치는 회의록 확정 때(AC-1), 회의 밖 조치나 확정 뒤 추가된 조치는 저장 때 연다.
 *   담당자·기한이 바뀌면 다시 열고, DONE이면 종료, CANCELLED면 취소.
 * - 담당자에게 조치 항목 편집 공유(담당자 사유).
 * @group CMN-00-MTG-001
 */
public with sharing class CMN_ActionItemService {
  public static final String SOURCE = 'CMN_ACTION_ITEM';
  public static final String CAUSE_OWNER = 'CMN_Attendee__c';

  /**
   * @description 저장 전 검증·기본값.
   * @param rows 조치 항목
   * @param oldMap 이전 값(삽입이면 null)
   */
  public static void prepare(
    List<CMN_ActionItem__c> rows,
    Map<Id, SObject> oldMap
  ) {
    Set<Id> meetingIds = new Set<Id>();
    for (CMN_ActionItem__c a : rows) {
      if (a.Meeting__c != null && a.Plant__c == null) {
        meetingIds.add(a.Meeting__c);
      }
    }
    Map<Id, CMN_Meeting__c> meetings = meetingIds.isEmpty()
      ? new Map<Id, CMN_Meeting__c>()
      : new Map<Id, CMN_Meeting__c>(CMN_MeetingSelector.meetings(meetingIds));
    for (CMN_ActionItem__c a : rows) {
      if (a.Owner__c == null) {
        a.addError(Label.CMN_Action_OwnerRequired);
        continue;
      }
      if (a.Plant__c == null && a.Meeting__c != null) {
        a.Plant__c = meetings.get(a.Meeting__c)?.Plant__c;
      }
      String before = (String) oldMap?.get(a.Id)?.get('Status__c');
      if (a.Status__c == 'DONE' && before != 'DONE') {
        a.CompletedAt__c = Datetime.now();
      } else if (a.Status__c != 'DONE') {
        a.CompletedAt__c = null;
      }
    }
  }

  /**
   * @description 저장 후: To-Do 열기·종료·취소, 담당자 공유.
   * @param rows 조치 항목
   * @param oldMap 이전 값(삽입이면 null)
   */
  public static void afterSave(
    List<CMN_ActionItem__c> rows,
    Map<Id, SObject> oldMap
  ) {
    Set<Id> meetingIds = new Set<Id>();
    for (CMN_ActionItem__c a : rows) {
      if (a.Meeting__c != null) {
        meetingIds.add(a.Meeting__c);
      }
    }
    Set<Id> confirmed = meetingIds.isEmpty()
      ? new Set<Id>()
      : CMN_MeetingService.confirmed(meetingIds);
    List<CMN_ActionItem__c> toOpen = new List<CMN_ActionItem__c>();
    Set<Id> toClose = new Set<Id>();
    Set<Id> toCancel = new Set<Id>();
    List<SObject> shares = new List<SObject>();
    for (CMN_ActionItem__c a : rows) {
      CMN_ActionItem__c old = (CMN_ActionItem__c) oldMap?.get(a.Id);
      Boolean ownerChanged = old != null && old.Owner__c != a.Owner__c;
      if (a.Status__c == 'DONE' && old?.Status__c != 'DONE') {
        toClose.add(a.Id);
      } else if (a.Status__c == 'CANCELLED' && old?.Status__c != 'CANCELLED') {
        toCancel.add(a.Id);
      } else if (
        a.Status__c == 'OPEN' &&
        (a.Meeting__c == null || confirmed.contains(a.Meeting__c)) &&
        (old == null ||
        ownerChanged ||
        old.DueDate__c != a.DueDate__c ||
        old.Status__c != 'OPEN')
      ) {
        if (ownerChanged) {
          toCancel.add(a.Id);
        }
        toOpen.add(a);
      }
      if (a.Owner__c != a.OwnerId && (old == null || ownerChanged)) {
        shares.add(
          new CMN_ActionItem__Share(
            ParentId = a.Id,
            UserOrGroupId = a.Owner__c,
            AccessLevel = 'Edit',
            RowCause = CAUSE_OWNER
          )
        );
      }
    }
    CMN_ShareWriter.write(new List<SObject>(), shares);
    CMN_TodoService.close(SOURCE, toClose, null);
    CMN_TodoService.cancel(SOURCE, toCancel);
    openTodos(toOpen);
  }

  /**
   * @description 조치 담당자 To-Do를 연다(기한 = 조치 기한).
   * @param items 진행 중 조치 항목
   */
  public static void openTodos(List<CMN_ActionItem__c> items) {
    List<CMN_TodoSpec> specs = new List<CMN_TodoSpec>();
    for (CMN_ActionItem__c a : items) {
      CMN_TodoSpec spec = new CMN_TodoSpec(
        a.Owner__c,
        SOURCE,
        a.Id,
        a.Id,
        'CMN_Todo_' + SOURCE
      );
      spec.systemCode = 'CMN';
      spec.titleParams = new List<Object>{ a.Name };
      spec.dueDate = a.DueDate__c;
      spec.plantId = a.Plant__c;
      specs.add(spec);
    }
    CMN_TodoService.open(specs);
  }
}
