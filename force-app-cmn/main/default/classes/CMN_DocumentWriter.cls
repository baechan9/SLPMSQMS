/**
 * @description 문서·리비전·파일 연결 저장(CMN-00-DOC-001).
 * @group CMN-00-DOC-001
 */
// SHARING-EXCEPTION: CMN-00-DOC-001 문서 등록은 부모 레코드 편집 권한만 확인하고(CMN_DocumentService), 같은 부모의 기존 문서
// (다른 사용자가 만들어 공유 계산 전이거나 읽기 공유만 있는 문서)에 리비전을 더해야 한다. 상태·번호·해시는 사용자 FLS가 읽기라
// 서비스가 검증을 마친 뒤 이 클래스가 저장만 한다.
public without sharing class CMN_DocumentWriter {
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
