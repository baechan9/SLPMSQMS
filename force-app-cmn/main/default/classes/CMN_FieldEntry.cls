/**
 * @description 현장 입력 셸 계약 DTO와 공용 규격 비교(CMN-00-UX-008). Provider와 컨트롤러·LWC가 같은 모양을 쓴다.
 * judgeValue·judgeItem·overall은 셸 미리보기(LWC)와 같은 규격 비교다. Provider는 그대로 쓰거나 업무 판정을 더한다.
 * @group CMN-00-UX-008
 */
public with sharing class CMN_FieldEntry {
  public static final String MODE_SEQUENTIAL = 'SEQUENTIAL';
  public static final String MODE_TABLE = 'TABLE';
  public static final String TYPE_VARIABLE = 'VARIABLE';
  public static final String TYPE_ATTRIBUTE = 'ATTRIBUTE';
  public static final String TYPE_VISUAL = 'VISUAL';
  public static final String TYPE_REPORT = 'REPORT';
  public static final String TYPE_TEXT = 'TEXT';
  public static final String OK = 'OK';
  public static final String NG = 'NG';
  public static final String PASS = 'PASS';
  public static final String FAIL = 'FAIL';
  public static final String INCOMPLETE = 'INCOMPLETE';
  public static final String SCAN_LOT = 'LOT';
  public static final String SCAN_GAUGE = 'GAUGE';

  /** @description 입력 시트. */
  public class Sheet {
    @AuraEnabled
    public Header header = new Header();
    @AuraEnabled
    public List<Item> items = new List<Item>();
    @AuraEnabled
    public List<Value> values = new List<Value>();
    @AuraEnabled
    public Boolean editable = false;
    /** SEQUENTIAL 또는 TABLE(데스크톱 기본값. 휴대폰·태블릿은 항상 순차) */
    @AuraEnabled
    public String defaultMode = MODE_TABLE;
    /** 사진 문서 분류 코드(DOC_CLASS, Provider가 정한다) */
    @AuraEnabled
    public String photoDocClass;
    /** 헤더에 로트 확인(스캔) 칸을 둔다 */
    @AuraEnabled
    public Boolean lotCheck = false;
  }

  /** @description 시트 헤더. */
  public class Header {
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String recordNo;
    @AuraEnabled
    public String itemNo;
    @AuraEnabled
    public String lotNo;
    @AuraEnabled
    public String plant;
    /** 보조 정보(라벨 키 → 화면 문구는 컨트롤러가 채운다) */
    @AuraEnabled
    public List<HeaderField> extras = new List<HeaderField>();
  }

  /** @description 헤더 보조 정보 한 칸. */
  public class HeaderField {
    @AuraEnabled
    public String labelKey;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;
  }

  /** @description 검사 항목. */
  public class Item {
    @AuraEnabled
    public String key;
    /** 사용자 언어 이름 */
    @AuraEnabled
    public String label;
    /** VARIABLE, ATTRIBUTE, VISUAL, REPORT, TEXT */
    @AuraEnabled
    public String type;
    @AuraEnabled
    public Integer sampleQty = 1;
    @AuraEnabled
    public Decimal lsl;
    @AuraEnabled
    public Decimal usl;
    @AuraEnabled
    public Decimal nominal;
    @AuraEnabled
    public String unit;
    @AuraEnabled
    public Integer decimals;
    /** 특별특성 기호(CC, SC) */
    @AuraEnabled
    public String specialClass;
    @AuraEnabled
    public String method;
    @AuraEnabled
    public Boolean gaugeRequired = false;
    @AuraEnabled
    public Boolean photoRequiredOnNg = false;
    /** 한도견본·작업표준 문서 */
    @AuraEnabled
    public Id referenceDocId;
    @AuraEnabled
    public Integer sequence;
  }

  /** @description 시료 값 하나. */
  public class Value {
    @AuraEnabled
    public String itemKey;
    @AuraEnabled
    public Integer sampleNo;
    @AuraEnabled
    public Decimal numValue;
    /** OK, NG */
    @AuraEnabled
    public String okNg;
    @AuraEnabled
    public String text;
    @AuraEnabled
    public List<Id> photoIds = new List<Id>();
    @AuraEnabled
    public String gaugeNo;
  }

  /** @description 저장 결과. */
  public class SaveResult {
    @AuraEnabled
    public Boolean success = false;
    /** 항목 키 → PASS, FAIL, INCOMPLETE */
    @AuraEnabled
    public Map<String, String> itemResults = new Map<String, String>();
    @AuraEnabled
    public String overall;
    @AuraEnabled
    public List<Issue> errors = new List<Issue>();
    /** 후속 안내 문구(예: NCR 등록 검토) */
    @AuraEnabled
    public String nextActionLabel;
  }

  /** @description 항목·시료별 오류. sampleNo가 비면 항목 전체. */
  public class Issue {
    @AuraEnabled
    public String itemKey;
    @AuraEnabled
    public Integer sampleNo;
    @AuraEnabled
    public String message;
  }

  /**
   * @description 오류 하나를 만든다.
   * @param itemKey 항목 키
   * @param sampleNo 시료 번호(없으면 항목 전체)
   * @param message 화면 문구
   * @return 오류
   */
  public static Issue issue(String itemKey, Integer sampleNo, String message) {
    Issue i = new Issue();
    i.itemKey = itemKey;
    i.sampleNo = sampleNo;
    i.message = message;
    return i;
  }

  /**
   * @description 시료 값 하나의 규격 비교(BR-2). 계량형은 decimals 자리로 반올림(HALF_UP)한 뒤 LSL ≤ 값 ≤ USL(경계 포함,
   * 한쪽 규격만 있으면 그쪽만), 계수형·외관·성적서는 NG면 불합격, 서술형은 입력하면 합격.
   * @param item 항목
   * @param v 값(null이면 미입력)
   * @return PASS, FAIL, INCOMPLETE
   */
  public static String judgeValue(Item item, Value v) {
    if (v == null) {
      return INCOMPLETE;
    }
    if (item.type == TYPE_VARIABLE) {
      if (v.numValue == null) {
        return INCOMPLETE;
      }
      Decimal x = item.decimals == null
        ? v.numValue
        : v.numValue.setScale(item.decimals, System.RoundingMode.HALF_UP);
      Boolean out =
        (item.lsl != null && x < item.lsl) ||
        (item.usl != null &&
        x > item.usl);
      return out ? FAIL : PASS;
    }
    if (item.type == TYPE_TEXT) {
      return String.isBlank(v.text) ? INCOMPLETE : PASS;
    }
    if (v.okNg != OK && v.okNg != NG) {
      return INCOMPLETE;
    }
    return v.okNg == NG ? FAIL : PASS;
  }

  /**
   * @description 항목 판정: 시료 하나라도 불합격이면 불합격, 빈 시료가 있으면 입력 중, 모두 합격이면 합격.
   * @param item 항목
   * @param values 이 항목의 값
   * @return PASS, FAIL, INCOMPLETE
   */
  public static String judgeItem(Item item, List<Value> values) {
    Map<Integer, Value> bySample = new Map<Integer, Value>();
    for (Value v : values ?? new List<Value>()) {
      if (v?.itemKey == item.key) {
        bySample.put(v.sampleNo, v);
      }
    }
    Boolean missing = false;
    for (Integer n = 1; n <= (item.sampleQty ?? 1); n++) {
      String r = judgeValue(item, bySample.get(n));
      if (r == FAIL) {
        return FAIL;
      }
      missing = missing || r == INCOMPLETE;
    }
    return missing ? INCOMPLETE : PASS;
  }

  /**
   * @description 전체 판정: 불합격 항목이 있으면 불합격, 입력 중 항목이 있으면 입력 중, 아니면 합격.
   * @param itemResults 항목 판정
   * @return PASS, FAIL, INCOMPLETE
   */
  public static String overall(Map<String, String> itemResults) {
    Set<String> results = new Set<String>(itemResults.values());
    if (results.contains(FAIL)) {
      return FAIL;
    }
    return results.contains(INCOMPLETE) ? INCOMPLETE : PASS;
  }
}
