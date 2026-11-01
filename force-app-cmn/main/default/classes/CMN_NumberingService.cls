/**
 * @description 업무 문서 번호 채번(CMN-00-ARC-003). 업무 객체 핸들러의 beforeInsert에서 `assign(records)`를 부른다.
 * - 카운터 키 = {객체}/{범위}/{기간}. 범위는 공장 코드(규칙 ScopeField가 공장 Lookup) 또는 *(전사 연번, 검토 반영 LL-·LA-).
 * - 기간(연·월)은 발행 시점의 공장 시간대(CMN_PlantService) 기준. 공장 범위가 없으면 사용자 시간대(BR-1, AC-2).
 * - 카운터는 FOR UPDATE로 잠그고 묶음 크기만큼 한 번에 올린다. 없으면 만든다(BR-2).
 * - 이관 모드(CR-12)에서 번호가 이미 있으면 그대로 두고 카운터를 그 번호까지 올린다(데모·이관 선적재, CR-6).
 * @group CMN-00-ARC-003
 */
public with sharing class CMN_NumberingService {
  public static final String DEFAULT_NUMBER_FIELD = 'RecordNo__c';
  private static final Set<String> SIMPLE_TOKENS = new Set<String>{
    'PLANT',
    'YYYY',
    'YY',
    'MM'
  };
  private static final Pattern TOKEN = Pattern.compile('\\{([^}]*)\\}');
  private static final Pattern SEQ = Pattern.compile('^SEQ:([1-9][0-9]?)$');

  @TestVisible
  private static Map<String, CMN_NumberingRule__mdt> rulesOverride;
  @TestVisible
  private static Datetime nowOverride;

  /**
   * @description 번호를 발행해 레코드의 번호 필드에 넣는다(before insert).
   * @param records 같은 객체의 새 레코드
   * @throws CMN_Exception 규칙이 없거나 패턴이 잘못되면(설정 오류)
   */
  public static void assign(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return;
    }
    String objectName = String.valueOf(records[0].getSObjectType());
    CMN_NumberingRule__mdt rule = ruleFor(objectName);
    validatePattern(rule.Pattern__c);
    String numberField = String.isBlank(rule.NumberField__c)
      ? DEFAULT_NUMBER_FIELD
      : rule.NumberField__c;
    Boolean keepExisting = CMN_TriggerHandler.isMigrationMode();
    Datetime now = nowOverride ?? Datetime.now();

    // 1) 공장 미리 읽기(시간대·코드)
    Set<Id> plantIds = new Set<Id>();
    if (String.isNotBlank(rule.ScopeField__c)) {
      for (SObject r : records) {
        Object v = r.get(rule.ScopeField__c);
        if (
          v instanceof Id &&
          ((Id) v).getSObjectType() == CMN_Plant__c.SObjectType
        ) {
          plantIds.add((Id) v);
        }
      }
      CMN_PlantService.preload(plantIds);
    }

    // 2) 레코드별 범위·기간 → 카운터 키
    Map<String, List<Slot>> slotsByKey = new Map<String, List<Slot>>();
    Map<String, Long> preloaded = new Map<String, Long>();
    for (SObject r : records) {
      Slot s = slotFor(r, rule, objectName, now);
      if (s == null) {
        continue;
      }
      String existing = (String) r.get(numberField);
      if (keepExisting && String.isNotBlank(existing)) {
        Long seq = sequenceOf(existing, s, rule.Pattern__c);
        if (seq != null) {
          preloaded.put(s.key, Math.max(preloaded.get(s.key) ?? 0, seq));
        }
        continue;
      }
      if (!slotsByKey.containsKey(s.key)) {
        slotsByKey.put(s.key, new List<Slot>());
      }
      slotsByKey.get(s.key).add(s);
    }
    Set<String> keys = new Set<String>(slotsByKey.keySet());
    keys.addAll(preloaded.keySet());
    if (keys.isEmpty()) {
      return;
    }

    // 3) 카운터 잠금·증가
    Map<String, CMN_NumberCounter__c> counters = lockCounters(keys);
    for (String key : keys) {
      CMN_NumberCounter__c c = counters.get(key);
      Long last = c.LastValue__c == null ? 0 : c.LastValue__c.longValue();
      last = Math.max(last, preloaded.get(key) ?? 0);
      for (Slot s : slotsByKey.get(key) ?? new List<Slot>()) {
        last++;
        s.record.put(numberField, format(rule.Pattern__c, s, last));
      }
      c.LastValue__c = last;
    }
    Database.update(counters.values(), AccessLevel.SYSTEM_MODE);
  }

  /**
   * @description 패턴 검사(BR-4). 지원 토큰: {PLANT} {YYYY} {YY} {MM} {SEQ:n}(n 1~99), SEQ는 정확히 1개.
   * @param pattern 채번 패턴
   * @throws CMN_Exception 지원하지 않는 토큰이나 SEQ 누락
   */
  public static void validatePattern(String pattern) {
    if (String.isBlank(pattern)) {
      throw badPattern('(blank)');
    }
    Integer seqCount = 0;
    Matcher m = TOKEN.matcher(pattern);
    while (m.find()) {
      String t = m.group(1);
      if (SEQ.matcher(t).matches()) {
        seqCount++;
      } else if (!SIMPLE_TOKENS.contains(t)) {
        throw badPattern('{' + t + '}');
      }
    }
    if (seqCount != 1) {
      throw badPattern('{SEQ:n}');
    }
  }

  // ------------------------------------------------------------------ 내부
  /** 레코드 한 건의 범위·기간. */
  private class Slot {
    SObject record;
    String scope;
    String yyyy;
    String mm;
    String key;
  }

  private static Slot slotFor(
    SObject r,
    CMN_NumberingRule__mdt rule,
    String objectName,
    Datetime now
  ) {
    Slot s = new Slot();
    s.record = r;
    TimeZone tz = UserInfo.getTimeZone();
    if (String.isBlank(rule.ScopeField__c)) {
      s.scope = '*';
    } else {
      Object v = r.get(rule.ScopeField__c);
      if (v == null || String.isBlank(String.valueOf(v))) {
        r.addError(Label.CMN_Numbering_NoScope);
        return null;
      }
      if (
        v instanceof Id && ((Id) v).getSObjectType() == CMN_Plant__c.SObjectType
      ) {
        tz = CMN_PlantService.timeZoneOf((Id) v);
        s.scope = CMN_PlantService.plantCodeOf((Id) v);
      } else {
        s.scope = String.valueOf(v);
      }
    }
    s.yyyy = now.format('yyyy', tz.getID());
    s.mm = now.format('MM', tz.getID());
    String period = rule.ResetPolicy__c == 'MONTHLY'
      ? s.yyyy + s.mm
      : rule.ResetPolicy__c == 'NEVER' ? '*' : s.yyyy;
    s.key = objectName + '/' + s.scope + '/' + period;
    return s;
  }

  private static String format(String pattern, Slot s, Long value) {
    String out = pattern
      .replace('{PLANT}', s.scope == '*' ? '' : s.scope)
      .replace('{YYYY}', s.yyyy)
      .replace('{YY}', s.yyyy.right(2))
      .replace('{MM}', s.mm);
    Matcher m = TOKEN.matcher(out);
    while (m.find()) {
      Matcher seq = SEQ.matcher(m.group(1));
      if (seq.matches()) {
        Integer width = Integer.valueOf(seq.group(1));
        out = out.replace(
          m.group(0),
          String.valueOf(value).leftPad(width, '0')
        );
        break;
      }
    }
    return out;
  }

  /** 이관 모드에서 이미 있는 번호의 연번(같은 범위·기간 패턴과 맞을 때만). */
  private static Long sequenceOf(String existing, Slot s, String pattern) {
    String prefix = format(pattern, s, 0);
    Matcher m = TOKEN.matcher(pattern);
    Integer width = 0;
    while (m.find()) {
      Matcher seq = SEQ.matcher(m.group(1));
      if (seq.matches()) {
        width = Integer.valueOf(seq.group(1));
      }
    }
    String zeros = '0'.repeat(width);
    Integer at = prefix.indexOf(zeros);
    if (at < 0 || existing.length() < at + width) {
      return null;
    }
    String before = prefix.left(at);
    String after = prefix.substring(at + width);
    String digits = existing.substring(at, existing.length() - after.length());
    if (
      !existing.startsWith(before) ||
      !existing.endsWith(after) ||
      !digits.isNumeric()
    ) {
      return null;
    }
    return Long.valueOf(digits);
  }

  private static Map<String, CMN_NumberCounter__c> lockCounters(
    Set<String> keys
  ) {
    Map<String, CMN_NumberCounter__c> byKey = query(keys);
    List<CMN_NumberCounter__c> missing = new List<CMN_NumberCounter__c>();
    for (String k : keys) {
      if (!byKey.containsKey(k)) {
        missing.add(new CMN_NumberCounter__c(Key__c = k, LastValue__c = 0));
      }
    }
    if (!missing.isEmpty()) {
      // 다른 트랜잭션이 같은 키를 먼저 만들면 유일 제약으로 실패한다. 실패한 키는 다시 잠가 읽는다
      Database.insert(missing, false, AccessLevel.SYSTEM_MODE);
      byKey = query(keys);
    }
    return byKey;
  }

  private static Map<String, CMN_NumberCounter__c> query(Set<String> keys) {
    Map<String, CMN_NumberCounter__c> byKey = new Map<String, CMN_NumberCounter__c>();
    for (CMN_NumberCounter__c c : [
      SELECT Id, Key__c, LastValue__c
      FROM CMN_NumberCounter__c
      WHERE Key__c IN :keys
      WITH SYSTEM_MODE
      FOR UPDATE
    ]) {
      byKey.put(c.Key__c, c);
    }
    return byKey;
  }

  private static CMN_NumberingRule__mdt ruleFor(String objectName) {
    if (rulesOverride != null && rulesOverride.containsKey(objectName)) {
      return rulesOverride.get(objectName);
    }
    for (CMN_NumberingRule__mdt r : CMN_NumberingRule__mdt.getAll().values()) {
      if (r.ObjectApiName__c == objectName) {
        return r;
      }
    }
    throw new CMN_Exception(
      String.format(Label.CMN_Numbering_NoRule, new List<Object>{ objectName })
    );
  }

  private static CMN_Exception badPattern(String token) {
    return new CMN_Exception(
      String.format(Label.CMN_Numbering_BadPattern, new List<Object>{ token })
    );
  }
}
