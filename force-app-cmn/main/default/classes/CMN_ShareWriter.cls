/**
 * @description Apex 관리 공유 행 쓰기(CMN-00-SEC-002).
 * @group CMN-00-SEC-002
 */
// SHARING-EXCEPTION: CMN-00-SEC-002 Apex 공유 사유(CMN_Plant·CMN_Supplier)로 공유 행을 만들고 지우는 일은 시스템 문맥이어야 한다.
// with sharing 문맥에서 일반 사용자가 레코드를 저장하면 공유 행 삽입이 "invalid row cause"로 거부된다(테스트로 확인).
// 이 클래스는 CMN_SharingService가 계산한 공유 행의 삽입·삭제만 하고 조회·판단은 하지 않는다.
public without sharing class CMN_ShareWriter {
  /**
   * @description 공유 행 반영.
   * @param remove 지울 공유 행
   * @param add 만들 공유 행
   */
  public static void write(List<SObject> remove, List<SObject> add) {
    if (!remove.isEmpty()) {
      Database.delete(remove, AccessLevel.SYSTEM_MODE);
    }
    if (!add.isEmpty()) {
      Database.insert(add, AccessLevel.SYSTEM_MODE);
    }
  }
}
