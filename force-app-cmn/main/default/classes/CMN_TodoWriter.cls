/**
 * @description To-Do 저장(CMN-00-TDO-001).
 * @group CMN-00-TDO-001
 */
// SHARING-EXCEPTION: CMN-00-TDO-001 To-Do는 Owner = Assignee인 Private 레코드라(BR-1) 여는 쪽·닫는 쪽은 대개 소유자가 아니다.
// with sharing 문맥에서는 남의 To-Do 갱신(종료·재오픈)이 거부되므로, CMN_TodoService가 검증한 뒤 저장만 이 클래스가 한다.
public without sharing class CMN_TodoWriter {
  /**
   * @description ExternalKey 기준 upsert(DML 1회).
   * @param rows To-Do
   */
  public static void upsertByKey(List<CMN_Todo__c> rows) {
    if (!rows.isEmpty()) {
      Database.upsert(
        rows,
        CMN_Todo__c.ExternalKey__c,
        true,
        AccessLevel.SYSTEM_MODE
      );
    }
  }

  /**
   * @description 갱신(DML 1회).
   * @param rows To-Do
   */
  public static void save(List<CMN_Todo__c> rows) {
    if (!rows.isEmpty()) {
      Database.update(rows, AccessLevel.SYSTEM_MODE);
    }
  }
}
