/**
 * @description 전사 설정(“CMN 설정”, CMN_Setting__mdt) 읽기. 키는 DeveloperName. 값이 없거나 형식이 틀리면 호출 측 기본값을 쓴다
 * (설정 하나가 잘못돼도 업무가 멈추지 않게). Custom Metadata getInstance는 SOQL 한도를 쓰지 않는다.
 * @group CMN-00-MDM-003
 */
public with sharing class CMN_Settings {
  @TestVisible
  private static Map<String, String> overrides = new Map<String, String>();

  /**
   * @description 문자열 값.
   * @param key 설정 키
   * @param defaultValue 없을 때 값
   * @return 값
   */
  public static String getString(String key, String defaultValue) {
    String v = raw(key);
    return String.isBlank(v) ? defaultValue : v.trim();
  }

  /**
   * @description 정수 값.
   * @param key 설정 키
   * @param defaultValue 없거나 숫자가 아닐 때 값
   * @return 값
   */
  public static Integer getInteger(String key, Integer defaultValue) {
    Decimal d = getDecimal(key, null);
    return d == null ? defaultValue : d.intValue();
  }

  /**
   * @description 숫자 값.
   * @param key 설정 키
   * @param defaultValue 없거나 숫자가 아닐 때 값
   * @return 값
   */
  public static Decimal getDecimal(String key, Decimal defaultValue) {
    String v = getString(key, null);
    if (v == null) {
      return defaultValue;
    }
    try {
      return Decimal.valueOf(v);
    } catch (TypeException e) {
      CMN_Logger.warn('CMN_Settings.getDecimal', 'Not a number: ' + key, null);
      return defaultValue;
    }
  }

  /**
   * @description 참거짓 값(true·false, 대소문자 무관).
   * @param key 설정 키
   * @param defaultValue 없을 때 값
   * @return 값
   */
  public static Boolean getBoolean(String key, Boolean defaultValue) {
    String v = getString(key, null);
    return v == null ? defaultValue : v.equalsIgnoreCase('true');
  }

  /**
   * @description 쉼표 구분 목록(공백 제거, 빈 항목 제외). 예: QMS_IQC_SAP_SYNC_PLANTS = KR01,CN01.
   * @param key 설정 키
   * @return 목록(없으면 빈 목록)
   */
  public static List<String> getList(String key) {
    List<String> out = new List<String>();
    for (String part : (getString(key, '')).split(',')) {
      if (String.isNotBlank(part)) {
        out.add(part.trim());
      }
    }
    return out;
  }

  private static String raw(String key) {
    if (String.isBlank(key)) {
      return null;
    }
    if (overrides.containsKey(key)) {
      return overrides.get(key);
    }
    return CMN_Setting__mdt.getInstance(key)?.Value__c;
  }
}
