/**
 * @description 현장 입력 셸 컨트롤러(CMN-00-UX-008, LWC cmnFieldEntryShell). 레코드 객체의 Provider를
 * CMN_FieldEntryProvider__mdt에서 찾아 Type.forName으로 만들고(BR-1) 시트 로드·저장·스캔 확인을 맡긴다.
 * 셸 공통 규칙만 여기서 다시 확인한다: 편집 가능 여부(Sheet.editable), 값의 항목·시료 범위, 최종 저장의 NG 사진 필수(BR-7).
 * 판정 규칙과 값 저장은 Provider가 한다(셸에 업무 분기 없음).
 * @group CMN-00-UX-008
 */
public with sharing class CMN_FieldEntryController {
  private static final Integer MAX_VALUES = 5000;
  private static final Integer MAX_SCAN_LENGTH = 100;
  private static final Pattern CLASS_PATTERN = Pattern.compile(
    '^[A-Za-z][A-Za-z0-9_]{0,79}$'
  );
  /** 테스트에서 등록 메타데이터 대신 쓰는 값(객체 → Provider 클래스, null이면 미등록) */
  @TestVisible
  private static Map<String, String> registryOverride;

  /**
   * @description 입력 시트.
   * @param recordId 업무 레코드 Id
   * @return 시트(헤더 보조 정보 라벨은 화면 문구로 채운다)
   * @throws AuraHandledException Provider 미등록·설정 오류·권한 없음(라벨 문구)
   */
  @AuraEnabled
  public static CMN_FieldEntry.Sheet load(Id recordId) {
    try {
      CMN_FieldEntry.Sheet sheet = provider(recordId).load(recordId);
      for (
        CMN_FieldEntry.HeaderField f : sheet?.header?.extras ??
          new List<CMN_FieldEntry.HeaderField>()
      ) {
        f.label = labelText(f.labelKey) ?? f.labelKey;
      }
      return sheet;
    } catch (Exception e) {
      throw toAura(e, 'load', recordId);
    }
  }

  /**
   * @description 입력값 저장(중간·최종). 편집할 수 없으면 거부, 최종 저장은 NG 사진 필수를 먼저 확인한다.
   * @param recordId 업무 레코드 Id
   * @param valuesJson CMN_FieldEntry.Value 목록 JSON
   * @param isFinal 최종 판정 여부
   * @return 저장 결과
   * @throws AuraHandledException 요청 형식 오류·설정 오류(라벨 문구)
   */
  @AuraEnabled
  public static CMN_FieldEntry.SaveResult save(
    Id recordId,
    String valuesJson,
    Boolean isFinal
  ) {
    try {
      CMN_FieldEntryProvider p = provider(recordId);
      List<CMN_FieldEntry.Value> values = parse(valuesJson);
      CMN_FieldEntry.Sheet sheet = p.load(recordId);
      CMN_FieldEntry.SaveResult result = new CMN_FieldEntry.SaveResult();
      if (sheet?.editable != true) {
        result.errors.add(
          CMN_FieldEntry.issue(null, null, Label.CMN_FieldEntry_NotEditable)
        );
        return result;
      }
      checkRange(sheet, values);
      if (isFinal == true) {
        result.errors.addAll(shellIssues(sheet, values));
        if (!result.errors.isEmpty()) {
          return result;
        }
      }
      return p.save(recordId, values, isFinal == true);
    } catch (Exception e) {
      throw toAura(e, 'save', recordId);
    }
  }

  /**
   * @description 스캔 값 확인(BR-6). 로트·측정기 번호만 받는다.
   * @param recordId 업무 레코드 Id
   * @param scanType LOT 또는 GAUGE
   * @param value 스캔·입력 값
   * @return 오류 문구, 문제없으면 null
   * @throws AuraHandledException 설정 오류·예상하지 못한 오류(라벨 문구)
   */
  @AuraEnabled
  public static String validateScan(
    Id recordId,
    String scanType,
    String value
  ) {
    try {
      if (
        (scanType != CMN_FieldEntry.SCAN_LOT &&
        scanType != CMN_FieldEntry.SCAN_GAUGE) ||
        String.isBlank(value) ||
        value.length() > MAX_SCAN_LENGTH
      ) {
        return Label.CMN_FieldEntry_InvalidScan;
      }
      String key = provider(recordId)
        .validateScan(recordId, scanType, value.trim());
      return key == null
        ? null
        : (labelText(key) ?? Label.CMN_FieldEntry_InvalidScan);
    } catch (Exception e) {
      throw toAura(e, 'validateScan', recordId);
    }
  }

  // ------------------------------------------------------------------ 내부
  private static CMN_FieldEntryProvider provider(Id recordId) {
    if (recordId == null) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    String objectName = recordId.getSObjectType()
      .getDescribe(SObjectDescribeOptions.DEFERRED)
      .getName();
    String className;
    if (registryOverride != null) {
      className = registryOverride.get(objectName);
    } else {
      for (CMN_FieldEntryProvider__mdt r : [
        SELECT ProviderClass__c
        FROM CMN_FieldEntryProvider__mdt
        WHERE ObjectApiName__c = :objectName AND IsActive__c = TRUE
        WITH SYSTEM_MODE
        LIMIT 1
      ]) {
        className = r.ProviderClass__c;
      }
    }
    if (String.isBlank(className)) {
      throw new CMN_ValidationException(Label.CMN_FieldEntry_NoProvider);
    }
    Object instance;
    try {
      instance = CLASS_PATTERN.matcher(className).matches()
        ? Type.forName(className)?.newInstance()
        : null;
    } catch (Exception e) {
      instance = null;
    }
    if (!(instance instanceof CMN_FieldEntryProvider)) {
      CMN_Logger.error(
        'CMN_FieldEntryController',
        'provider ' + objectName + ': ' + className,
        recordId
      );
      throw new CMN_ValidationException(Label.CMN_FieldEntry_NoProvider);
    }
    return (CMN_FieldEntryProvider) instance;
  }

  private static List<CMN_FieldEntry.Value> parse(String valuesJson) {
    List<CMN_FieldEntry.Value> values;
    try {
      values = String.isBlank(valuesJson)
        ? new List<CMN_FieldEntry.Value>()
        : (List<CMN_FieldEntry.Value>) JSON.deserialize(
            valuesJson,
            List<CMN_FieldEntry.Value>.class
          );
    } catch (Exception e) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    if (values == null || values.size() > MAX_VALUES) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    return values;
  }

  /** 값은 시트의 항목·시료 범위 안이어야 한다(화면을 거치지 않은 호출 차단). */
  private static void checkRange(
    CMN_FieldEntry.Sheet sheet,
    List<CMN_FieldEntry.Value> values
  ) {
    Map<String, CMN_FieldEntry.Item> items = itemsByKey(sheet);
    for (CMN_FieldEntry.Value v : values) {
      CMN_FieldEntry.Item item = v == null ? null : items.get(v.itemKey);
      if (
        item == null ||
        v.sampleNo == null ||
        v.sampleNo < 1 ||
        v.sampleNo > (item.sampleQty ?? 1) ||
        (v.okNg != null &&
        v.okNg != CMN_FieldEntry.OK &&
        v.okNg != CMN_FieldEntry.NG)
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
    }
  }

  /**
   * 최종 저장 전 셸 공통 규칙: 외관 항목이나 NG 사진 필수 항목에서 NG인데 사진이 없는 시료(BR-7),
   * 측정기 필수 항목인데 측정기 번호가 없는 값(BR-6).
   */
  private static List<CMN_FieldEntry.Issue> shellIssues(
    CMN_FieldEntry.Sheet sheet,
    List<CMN_FieldEntry.Value> values
  ) {
    List<CMN_FieldEntry.Issue> out = new List<CMN_FieldEntry.Issue>();
    Map<String, CMN_FieldEntry.Item> items = itemsByKey(sheet);
    Set<String> gaugeMissing = new Set<String>();
    for (CMN_FieldEntry.Value v : values) {
      CMN_FieldEntry.Item item = items.get(v.itemKey);
      if (
        item.gaugeRequired == true &&
        v.numValue != null &&
        String.isBlank(v.gaugeNo) &&
        gaugeMissing.add(item.key)
      ) {
        out.add(
          CMN_FieldEntry.issue(
            item.key,
            null,
            String.format(
              Label.CMN_FieldEntry_GaugeRequired,
              new List<Object>{ item.label }
            )
          )
        );
      }
      Boolean needsPhoto =
        item.type == CMN_FieldEntry.TYPE_VISUAL ||
        item.photoRequiredOnNg == true;
      if (
        needsPhoto &&
        v.okNg == CMN_FieldEntry.NG &&
        (v.photoIds == null || v.photoIds.isEmpty())
      ) {
        out.add(
          CMN_FieldEntry.issue(
            v.itemKey,
            v.sampleNo,
            String.format(
              Label.CMN_FieldEntry_PhotoRequired,
              new List<Object>{ item.label, v.sampleNo }
            )
          )
        );
      }
    }
    return out;
  }

  private static Map<String, CMN_FieldEntry.Item> itemsByKey(
    CMN_FieldEntry.Sheet sheet
  ) {
    Map<String, CMN_FieldEntry.Item> out = new Map<String, CMN_FieldEntry.Item>();
    for (
      CMN_FieldEntry.Item i : sheet?.items ?? new List<CMN_FieldEntry.Item>()
    ) {
      out.put(i.key, i);
    }
    return out;
  }

  private static String labelText(String name) {
    if (String.isBlank(name)) {
      return null;
    }
    try {
      return System.Label.get('', name);
    } catch (Exception e) {
      return null;
    }
  }

  /** 검증 예외는 라벨 문구 그대로, 그 밖의 예외는 원문을 로그에 남기고 일반 문구로 바꾼다. */
  private static AuraHandledException toAura(
    Exception e,
    String method,
    Id recordId
  ) {
    String message = e.getMessage();
    if (!(e instanceof CMN_ValidationException)) {
      CMN_Logger.error(
        'CMN_FieldEntryController.' + method,
        message,
        recordId,
        e
      );
      message = Label.CMN_Common_UnexpectedError;
    }
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
