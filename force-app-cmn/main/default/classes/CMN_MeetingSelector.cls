/**
 * @description 회의·참석자·조치 항목 조회(CMN-00-MTG-001).
 * @group CMN-00-MTG-001
 */
// SHARING-EXCEPTION: CMN-00-MTG-001 회의 공지·확정·다음 회차 생성은 참석자 전원(다른 공장·외부 메일 포함)과 조치 항목 담당자를
// 대상으로 한다. 이를 계산하는 사용자가 모든 참석자·조치 항목 레코드를 공유로 볼 수 있다는 보장이 없어 키 조회만 시스템 기준으로 한다.
// 화면 조회는 CMN_MeetingController가 회의 읽기 권한을 확인한 뒤에만 쓴다.
public without sharing class CMN_MeetingSelector {
  /**
   * @description 회의.
   * @param meetingIds 회의
   * @return 회의
   */
  public static List<CMN_Meeting__c> meetings(Set<Id> meetingIds) {
    return [
      SELECT
        Id,
        Name,
        OwnerId,
        Status__c,
        StartAt__c,
        EndAt__c,
        Location__c,
        OnlineUrl__c,
        Plant__c,
        MinutesConfirmedAt__c,
        NextMeeting__c
      FROM CMN_Meeting__c
      WHERE Id IN :meetingIds
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 회의 참석자.
   * @param meetingIds 회의
   * @return 참석자
   */
  public static List<CMN_MeetingAttendee__c> attendees(Set<Id> meetingIds) {
    return [
      SELECT
        Id,
        Name,
        Meeting__c,
        User__c,
        ExternalEmail__c,
        Role__c,
        User__r.LanguageLocaleKey,
        Meeting__r.Name,
        Meeting__r.StartAt__c,
        Meeting__r.EndAt__c,
        Meeting__r.Location__c,
        Meeting__r.OnlineUrl__c,
        Meeting__r.LastModifiedDate
      FROM CMN_MeetingAttendee__c
      WHERE Meeting__c IN :meetingIds
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 참석자(Id로).
   * @param attendeeIds 참석자
   * @return 참석자(회의 정보 포함)
   */
  public static List<CMN_MeetingAttendee__c> attendeesById(
    Set<Id> attendeeIds
  ) {
    return [
      SELECT
        Id,
        Meeting__c,
        User__c,
        ExternalEmail__c,
        User__r.LanguageLocaleKey,
        Meeting__r.Name,
        Meeting__r.StartAt__c,
        Meeting__r.EndAt__c,
        Meeting__r.Location__c,
        Meeting__r.OnlineUrl__c,
        Meeting__r.Owner.Name,
        Meeting__r.LastModifiedDate
      FROM CMN_MeetingAttendee__c
      WHERE Id IN :attendeeIds
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 회의들의 진행 중 조치 항목.
   * @param meetingIds 회의
   * @return 조치 항목
   */
  public static List<CMN_ActionItem__c> openActions(Set<Id> meetingIds) {
    return [
      SELECT Id, Name, Owner__c, DueDate__c, Status__c, Meeting__c, Plant__c
      FROM CMN_ActionItem__c
      WHERE Meeting__c IN :meetingIds AND Status__c = 'OPEN'
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 회의의 조치 항목(화면, 최신순).
   * @param meetingId 회의
   * @return 조치 항목
   */
  public static List<CMN_ActionItem__c> actionsOf(Id meetingId) {
    return [
      SELECT Id, Name, Owner__c, Owner__r.Name, DueDate__c, Status__c
      FROM CMN_ActionItem__c
      WHERE Meeting__c = :meetingId
      WITH SYSTEM_MODE
      ORDER BY DueDate__c, Name
    ];
  }

  /**
   * @description 기한 알림 대상(진행 중, 기한이 내일이거나 지남, 오늘 아직 알리지 않음).
   * @param today 기준 날짜
   * @return 조치 항목
   */
  public static List<CMN_ActionItem__c> dueActions(Date today) {
    Date tomorrow = today.addDays(1);
    return [
      SELECT Id, Name, Owner__c, DueDate__c, LastDueAlertOn__c
      FROM CMN_ActionItem__c
      WHERE
        Status__c = 'OPEN'
        AND Owner__c != NULL
        AND DueDate__c <= :tomorrow
        AND (LastDueAlertOn__c = NULL
        OR LastDueAlertOn__c < :today)
      WITH SYSTEM_MODE
      LIMIT 10000
    ];
  }
}
