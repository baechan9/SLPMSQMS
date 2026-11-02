/**
 * @description CMN_MeetingAttendee__c 트리거(CMN-00-MTG-001): 참석자 이름, 회의 읽기 공유, 공지된 회의면 새 참석자 초대.
 * @group CMN-00-MTG-001
 */
public with sharing class CMN_MeetingAttendeeTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    for (CMN_MeetingAttendee__c a : (List<CMN_MeetingAttendee__c>) newRecords) {
      if (String.isBlank(a.Name)) {
        a.Name = (a.ExternalEmail__c ?? String.valueOf(a.User__c) ?? '-')
          .left(80);
      }
    }
  }

  protected override void afterInsert() {
    if (!isMigrationMode()) {
      CMN_MeetingService.onAttendeesAdded(
        (List<CMN_MeetingAttendee__c>) newRecords
      );
    }
  }
}
