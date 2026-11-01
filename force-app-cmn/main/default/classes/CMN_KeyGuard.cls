/**
 * @description 기준정보 외부 키 중복 검사 공통(라인·공정·차종·공장별 품번·적용 차종 …). 트리거가 키를 채운 뒤 호출한다.
 * 같은 저장 묶음과 이미 저장된 레코드를 모두 보고(대소문자 무관 — 유일 필드가 대소문자를 구분하지 않음),
 * DB 유일 제약 오류 대신 라벨 문구로 해당 필드에 오류를 단다.
 * @group CMN-00-MDM-004
 */
public with sharing class CMN_KeyGuard {
  /**
   * @description 키 중복을 막는다(before insert·update).
   * @param records 저장할 레코드(같은 객체)
   * @param keyField 외부 키 필드(Text, 유일)
   * @param errorField 오류를 달 필드
   * @param valueField 문구 {0}에 넣을 값의 필드
   * @param message Custom Label 문구
   */
  public static void rejectDuplicates(
    List<SObject> records,
    Schema.SObjectField keyField,
    Schema.SObjectField errorField,
    Schema.SObjectField valueField,
    String message
  ) {
    Map<String, SObject> byKey = new Map<String, SObject>();
    for (SObject r : records) {
      String key = (String) r.get(keyField);
      if (String.isBlank(key)) {
        continue;
      }
      if (byKey.containsKey(key.toUpperCase())) {
        r.addError(errorField, format(message, r.get(valueField)));
      } else {
        byKey.put(key.toUpperCase(), r);
      }
    }
    if (byKey.isEmpty()) {
      return;
    }
    String field = String.escapeSingleQuotes(keyField.getDescribe().getName());
    String soql =
      'SELECT Id, ' +
      field +
      ' FROM ' +
      String.escapeSingleQuotes(String.valueOf(records[0].getSObjectType())) +
      ' WHERE ' +
      field +
      ' IN :keys';
    // 기준정보는 사내 전체 공개라 시스템 모드로 본다(사용자에게 안 보이는 중복도 막아야 한다)
    for (
      SObject e : Database.queryWithBinds(
        soql,
        new Map<String, Object>{ 'keys' => byKey.keySet() },
        AccessLevel.SYSTEM_MODE
      )
    ) {
      SObject incoming = byKey.get(((String) e.get(keyField)).toUpperCase());
      if (incoming != null && incoming.Id != e.Id) {
        incoming.addError(
          errorField,
          format(message, incoming.get(valueField))
        );
      }
    }
  }

  private static String format(String message, Object value) {
    return String.format(message, new List<Object>{ value });
  }
}
