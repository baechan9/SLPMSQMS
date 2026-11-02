/**
 * @description 결재 엔진의 상태 쓰기(CMN-00-APV-001).
 * @group CMN-00-APV-001
 */
// SHARING-EXCEPTION: CMN-00-APV-001 결재자는 요청·대상에 읽기 공유만 받는다(BR-6). 결재자가 단계를 처리하면 엔진이
// 요청·단계 상태를 바꾸고 대상 잠금을 풀어야 하는데, with sharing 문맥에서는 주종 하위(단계) 갱신이 상위 편집 권한 부족으로 거부된다.
// 처리 가능 여부(처리 차례·결재자 본인·기안자)는 CMN_ApprovalService가 먼저 검증하고, 이 클래스는 저장과 잠금만 한다.
public without sharing class CMN_ApprovalWriter {
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

  /**
   * @description 대상 잠금(BR-5).
   * @param targetId 대상
   */
  public static void lock(Id targetId) {
    Approval.lock(targetId);
  }

  /**
   * @description 대상 잠금 해제(잠겨 있을 때만).
   * @param targetId 대상
   */
  public static void unlock(Id targetId) {
    if (Approval.isLocked(targetId)) {
      Approval.unlock(targetId);
    }
  }
}
