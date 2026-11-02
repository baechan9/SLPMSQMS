/**
 * @description 회의·참석자·조치 항목 시스템 저장(CMN-00-MTG-001).
 * @group CMN-00-MTG-001
 */
// SHARING-EXCEPTION: CMN-00-MTG-001 회의록 확정 일시·다음 회차 연결·조치 항목 기한 알림일은 사용자 FLS가 읽기인 서비스 필드이고,
// 다음 회차와 참석자 복사는 원래 회의 소유자 기준으로 만들어야 한다. 검증을 마친 서비스가 저장만 맡긴다.
public without sharing class CMN_MeetingWriter {
  /**
   * @description 저장(새 레코드는 삽입, 기존은 갱신).
   * @param records 같은 종류의 레코드
   */
  public static void save(List<SObject> records) {
    List<SObject> inserts = new List<SObject>();
    List<SObject> updates = new List<SObject>();
    for (SObject r : records) {
      if (r.Id == null) {
        inserts.add(r);
      } else {
        updates.add(r);
      }
    }
    if (!inserts.isEmpty()) {
      Database.insert(inserts, AccessLevel.SYSTEM_MODE);
    }
    if (!updates.isEmpty()) {
      Database.update(updates, AccessLevel.SYSTEM_MODE);
    }
  }
}
