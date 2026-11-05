/**
 * @description 테스트 객체 현장 입력 샘플 Provider(CMN-00-UX-008, 개발 플랜 DEV-3). 업무 Provider(IQC·OQC·시험 결과 등)의 본보기다.
 * - 항목 5개: 계량형 2(양쪽 규격 CC, 한쪽 규격 SC), 계수형 1(NG 사진 필수), 외관 1, 서술 1
 * - 값은 레코드의 EntryJson__c에 JSON 묶음으로 저장한다(시료마다 레코드를 만들지 않는다)
 * - 편집 가능 = UX-005 COMPONENT 규칙 TestFieldEntryEdit(작성 중·진행 중)
 * - 판정은 공용 규격 비교(CMN_FieldEntry.judgeItem), 최종 저장은 EntryResult__c에 전체 판정
 * - 스캔: 로트 = 레코드 번호, 측정기 번호 = G-0000 형식
 * @group CMN-00-UX-008
 */
public with sharing class CMN_TestFieldEntryProvider implements CMN_FieldEntryProvider {
  private static final String EDIT_RULE = 'TestFieldEntryEdit';
  private static final String PHOTO_CLASS = 'TEST_PHOTO';
  private static final Pattern GAUGE = Pattern.compile('^G-\\d{4}$');

  /**
   * @description 입력 시트.
   * @param recordId 테스트 레코드 Id
   * @return 시트
   */
  public CMN_FieldEntry.Sheet load(Id recordId) {
    CMN_TestRecord__c r = record(recordId);
    CMN_FieldEntry.Sheet s = new CMN_FieldEntry.Sheet();
    s.header.title = r.Name;
    s.header.recordNo = r.RecordNo__c;
    s.header.lotNo = r.RecordNo__c;
    s.header.plant = r.Plant__r?.Name;
    CMN_FieldEntry.HeaderField status = new CMN_FieldEntry.HeaderField();
    status.labelKey = 'CMN_FieldEntry_SampleLotLabel';
    status.value = r.RecordNo__c;
    s.header.extras.add(status);
    s.items = items();
    s.values = stored(r.EntryJson__c);
    s.editable = CMN_UiRuleService.canExecute(recordId, EDIT_RULE);
    s.defaultMode = CMN_FieldEntry.MODE_TABLE;
    s.photoDocClass = PHOTO_CLASS;
    s.lotCheck = true;
    return s;
  }

  /**
   * @description 값을 합쳐 저장하고 항목별로 판정한다. 최종이면 전체 판정을 레코드에 남긴다.
   * @param recordId 테스트 레코드 Id
   * @param values 입력값
   * @param isFinal 최종 판정 여부
   * @return 저장 결과
   */
  public CMN_FieldEntry.SaveResult save(
    Id recordId,
    List<CMN_FieldEntry.Value> values,
    Boolean isFinal
  ) {
    CMN_FieldEntry.SaveResult result = new CMN_FieldEntry.SaveResult();
    if (!CMN_UiRuleService.canExecute(recordId, EDIT_RULE)) {
      result.errors.add(
        CMN_FieldEntry.issue(null, null, Label.CMN_FieldEntry_NotEditable)
      );
      return result;
    }
    CMN_TestRecord__c r = record(recordId);
    Map<String, CMN_FieldEntry.Value> merged = new Map<String, CMN_FieldEntry.Value>();
    for (CMN_FieldEntry.Value v : stored(r.EntryJson__c)) {
      merged.put(v.itemKey + '#' + v.sampleNo, v);
    }
    for (CMN_FieldEntry.Value v : values) {
      merged.put(v.itemKey + '#' + v.sampleNo, v);
    }
    List<CMN_FieldEntry.Value> all = merged.values();
    for (CMN_FieldEntry.Item item : items()) {
      result.itemResults.put(item.key, CMN_FieldEntry.judgeItem(item, all));
    }
    result.overall = CMN_FieldEntry.overall(result.itemResults);
    CMN_TestRecord__c changes = new CMN_TestRecord__c(
      Id = recordId,
      EntryJson__c = JSON.serialize(all)
    );
    if (isFinal) {
      changes.EntryResult__c = result.overall;
      if (result.overall == CMN_FieldEntry.FAIL) {
        result.nextActionLabel = Label.CMN_FieldEntry_SampleNextNcr;
      }
    }
    Database.update(changes, AccessLevel.USER_MODE);
    result.success = true;
    return result;
  }

  /**
   * @description 로트는 레코드 번호와 같아야 하고, 측정기 번호는 G-0000 형식이어야 한다.
   * @param recordId 테스트 레코드 Id
   * @param scanType LOT 또는 GAUGE
   * @param value 값
   * @return 오류 라벨 이름 또는 null
   */
  public String validateScan(Id recordId, String scanType, String value) {
    if (scanType == CMN_FieldEntry.SCAN_LOT) {
      return value.equalsIgnoreCase(record(recordId).RecordNo__c)
        ? null
        : 'CMN_FieldEntry_SampleLotMismatch';
    }
    return GAUGE.matcher(value).matches()
      ? null
      : 'CMN_FieldEntry_SampleGaugeInvalid';
  }

  // ------------------------------------------------------------------ 내부
  private static CMN_TestRecord__c record(Id recordId) {
    return [
      SELECT Id, Name, RecordNo__c, Plant__r.Name, EntryJson__c
      FROM CMN_TestRecord__c
      WHERE Id = :recordId
      WITH USER_MODE
      LIMIT 1
    ];
  }

  private static List<CMN_FieldEntry.Value> stored(String raw) {
    return String.isBlank(raw)
      ? new List<CMN_FieldEntry.Value>()
      : (List<CMN_FieldEntry.Value>) JSON.deserialize(
          raw,
          List<CMN_FieldEntry.Value>.class
        );
  }

  private static List<CMN_FieldEntry.Item> items() {
    List<CMN_FieldEntry.Item> out = new List<CMN_FieldEntry.Item>();
    CMN_FieldEntry.Item outerDia = item(
      'OUTER',
      Label.CMN_FieldEntry_SampleOuter,
      CMN_FieldEntry.TYPE_VARIABLE,
      5
    );
    outerDia.lsl = 1.0;
    outerDia.usl = 2.0;
    outerDia.nominal = 1.5;
    outerDia.unit = 'mm';
    outerDia.decimals = 2;
    outerDia.specialClass = 'CC';
    outerDia.method = Label.CMN_FieldEntry_SampleMethod;
    outerDia.gaugeRequired = true;
    out.add(outerDia);
    CMN_FieldEntry.Item height = item(
      'HEIGHT',
      Label.CMN_FieldEntry_SampleHeight,
      CMN_FieldEntry.TYPE_VARIABLE,
      3
    );
    height.lsl = 10;
    height.unit = 'mm';
    height.decimals = 1;
    height.specialClass = 'SC';
    out.add(height);
    CMN_FieldEntry.Item bubble = item(
      'BUBBLE',
      Label.CMN_FieldEntry_SampleBubble,
      CMN_FieldEntry.TYPE_ATTRIBUTE,
      5
    );
    bubble.photoRequiredOnNg = true;
    out.add(bubble);
    out.add(
      item(
        'SCRATCH',
        Label.CMN_FieldEntry_SampleScratch,
        CMN_FieldEntry.TYPE_VISUAL,
        2
      )
    );
    out.add(
      item('NOTE', Label.CMN_FieldEntry_SampleNote, CMN_FieldEntry.TYPE_TEXT, 1)
    );
    for (Integer n = 0; n < out.size(); n++) {
      out[n].sequence = n + 1;
    }
    return out;
  }

  private static CMN_FieldEntry.Item item(
    String key,
    String text,
    String kind,
    Integer qty
  ) {
    CMN_FieldEntry.Item i = new CMN_FieldEntry.Item();
    i.key = key;
    i.label = text;
    i.type = kind;
    i.sampleQty = qty;
    return i;
  }
}
