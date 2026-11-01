/**
 * @description 법인·공장·라인·공정 규칙과 공장 시간대 서비스(CMN-00-MDM-002).
 * 공장 시간대는 일 마감·채번 연도(ARC-003)·SLA 계산의 기준이다. 공장 조회는 트랜잭션 안에서 한 번만 한다.
 * @group CMN-00-MDM-002
 */
public with sharing class CMN_PlantService {
  private static final Map<String, CMN_Plant__c> BY_CODE = new Map<String, CMN_Plant__c>();
  private static final Map<Id, CMN_Plant__c> BY_ID = new Map<Id, CMN_Plant__c>();

  // ------------------------------------------------------------------ 공장 시간대
  /**
   * @description 공장 코드의 시간대.
   * @param plantCode 공장 코드(대소문자 무관)
   * @return 공장 시간대
   * @throws CMN_ValidationException 공장이 없을 때
   */
  public static TimeZone timeZoneOf(String plantCode) {
    return TimeZone.getTimeZone(plant(plantCode).TimeZone__c);
  }

  /**
   * @description 공장 Id의 시간대.
   * @param plantId 공장 Id
   * @return 공장 시간대
   * @throws CMN_ValidationException 공장이 없을 때
   */
  public static TimeZone timeZoneOf(Id plantId) {
    return TimeZone.getTimeZone(plant(plantId).TimeZone__c);
  }

  /**
   * @description 어느 시각이 공장 현지 시간으로 며칠인지(일 마감·채번 연도 판정, AC-2).
   * @param plantCode 공장 코드
   * @param instant 시각(null이면 지금)
   * @return 공장 현지 날짜
   */
  public static Date localDate(String plantCode, Datetime instant) {
    return toLocalDate(timeZoneOf(plantCode), instant);
  }

  /**
   * @description localDate의 공장 Id 판.
   * @param plantId 공장 Id
   * @param instant 시각(null이면 지금)
   * @return 공장 현지 날짜
   */
  public static Date localDate(Id plantId, Datetime instant) {
    return toLocalDate(timeZoneOf(plantId), instant);
  }

  /**
   * @description 여러 공장을 한 번에 읽어 캐시에 올린다(채번처럼 레코드 여러 건을 다룰 때 루프 전에 호출).
   * @param plantIds 공장 Id
   */
  public static void preload(Set<Id> plantIds) {
    load(new Set<String>(), plantIds);
  }

  // ------------------------------------------------------------------ 트리거 규칙
  /**
   * @description BR-2: 법인·공장·라인·공정은 삭제하지 않고 비활성화한다(주종 관계라 상위 삭제도 막는다).
   * @param records 삭제 대상(Trigger.old)
   */
  public static void preventDelete(List<SObject> records) {
    for (SObject r : records) {
      r.addError(Label.CMN_Site_DeleteNotAllowed);
    }
  }

  /**
   * @description BR-1: 라인 외부 키 = {PlantCode}-{LineCode}. 사용자가 넣은 값은 덮어쓴다. 같은 공장의 같은 라인 코드는 오류.
   * @param lines 저장할 라인(before insert·update)
   */
  public static void assignLineKeys(List<CMN_Line__c> lines) {
    Set<Id> plantIds = new Set<Id>();
    for (CMN_Line__c l : lines) {
      plantIds.add(l.Plant__c);
    }
    load(new Set<String>(), plantIds);
    Map<String, SObject> byKey = new Map<String, SObject>();
    for (CMN_Line__c l : lines) {
      CMN_Plant__c p = BY_ID.get(l.Plant__c);
      if (p == null || String.isBlank(l.LineCode__c)) {
        continue;
      }
      l.LineCode__c = l.LineCode__c.trim();
      l.ExternalKey__c = p.PlantCode__c + '-' + l.LineCode__c;
      claim(
        byKey,
        l,
        CMN_Line__c.LineCode__c,
        Label.CMN_Site_DuplicateLineCode
      );
    }
    rejectExisting(
      byKey,
      CMN_PlantSelector.linesByExternalKey(byKey.keySet()),
      CMN_Line__c.LineCode__c,
      Label.CMN_Site_DuplicateLineCode
    );
  }

  /**
   * @description 공정 외부 키 = {라인 외부 키}-{OpCode}. 같은 라인의 같은 공정 코드는 오류.
   * @param operations 저장할 공정(before insert·update)
   */
  public static void assignOperationKeys(List<CMN_Operation__c> operations) {
    Set<Id> lineIds = new Set<Id>();
    for (CMN_Operation__c o : operations) {
      lineIds.add(o.Line__c);
    }
    Map<Id, CMN_Line__c> lines = CMN_PlantSelector.linesById(lineIds);
    Map<String, SObject> byKey = new Map<String, SObject>();
    for (CMN_Operation__c o : operations) {
      CMN_Line__c l = lines.get(o.Line__c);
      if (l == null || String.isBlank(o.OpCode__c)) {
        continue;
      }
      o.OpCode__c = o.OpCode__c.trim();
      o.ExternalKey__c = l.ExternalKey__c + '-' + o.OpCode__c;
      claim(
        byKey,
        o,
        CMN_Operation__c.OpCode__c,
        Label.CMN_Site_DuplicateOpCode
      );
    }
    rejectExisting(
      byKey,
      CMN_PlantSelector.operationsByExternalKey(byKey.keySet()),
      CMN_Operation__c.OpCode__c,
      Label.CMN_Site_DuplicateOpCode
    );
  }

  /**
   * @description 라인 외부 키가 바뀌면(이관 모드에서 코드 정정) 그 라인 공정의 외부 키를 다시 만든다.
   * @param newLines 갱신 후 라인
   * @param oldMap 갱신 전 라인
   */
  public static void refreshOperationKeys(
    List<CMN_Line__c> newLines,
    Map<Id, SObject> oldMap
  ) {
    Set<Id> changed = new Set<Id>();
    for (CMN_Line__c l : newLines) {
      if (
        l.ExternalKey__c != ((CMN_Line__c) oldMap.get(l.Id))?.ExternalKey__c
      ) {
        changed.add(l.Id);
      }
    }
    if (changed.isEmpty()) {
      return;
    }
    List<CMN_Operation__c> ops = CMN_PlantSelector.operationsByLine(changed);
    if (!ops.isEmpty()) {
      // 공정 트리거가 새 라인 키로 외부 키를 다시 만든다
      Database.update(ops, AccessLevel.SYSTEM_MODE);
    }
  }

  // ------------------------------------------------------------------ 내부
  private static Date toLocalDate(TimeZone tz, Datetime instant) {
    return Date.valueOf(
      (instant ?? Datetime.now()).format('yyyy-MM-dd', tz.getID())
    );
  }

  private static CMN_Plant__c plant(String plantCode) {
    String key = plantCode?.trim().toUpperCase();
    if (key != null && !BY_CODE.containsKey(key)) {
      load(new Set<String>{ key }, new Set<Id>());
    }
    CMN_Plant__c p = key == null ? null : BY_CODE.get(key);
    if (p == null) {
      throw unknown(plantCode);
    }
    return p;
  }

  private static CMN_Plant__c plant(Id plantId) {
    if (plantId != null && !BY_ID.containsKey(plantId)) {
      load(new Set<String>(), new Set<Id>{ plantId });
    }
    CMN_Plant__c p = plantId == null ? null : BY_ID.get(plantId);
    if (p == null) {
      throw unknown(plantId);
    }
    return p;
  }

  private static void load(Set<String> codes, Set<Id> ids) {
    Set<String> missingCodes = new Set<String>();
    for (String c : codes) {
      if (!BY_CODE.containsKey(c)) {
        missingCodes.add(c);
      }
    }
    Set<Id> missingIds = new Set<Id>(ids);
    missingIds.removeAll(BY_ID.keySet());
    missingIds.remove(null);
    if (missingCodes.isEmpty() && missingIds.isEmpty()) {
      return;
    }
    for (CMN_Plant__c p : CMN_PlantSelector.plants(missingCodes, missingIds)) {
      BY_CODE.put(p.PlantCode__c.toUpperCase(), p);
      BY_ID.put(p.Id, p);
    }
  }

  /** 같은 저장 묶음 안의 중복 키를 찾는다. 키는 대소문자 무관(유일 필드가 대소문자를 구분하지 않음). */
  private static void claim(
    Map<String, SObject> byKey,
    SObject record,
    Schema.SObjectField codeField,
    String message
  ) {
    String key = ((String) record.get('ExternalKey__c')).toUpperCase();
    if (byKey.containsKey(key)) {
      record.addError(codeField, format(message, record.get(codeField)));
    } else {
      byKey.put(key, record);
    }
  }

  private static void rejectExisting(
    Map<String, SObject> byKey,
    List<SObject> existing,
    Schema.SObjectField codeField,
    String message
  ) {
    for (SObject e : existing) {
      SObject incoming = byKey.get(
        ((String) e.get('ExternalKey__c')).toUpperCase()
      );
      if (incoming != null && incoming.Id != e.Id) {
        incoming.addError(codeField, format(message, incoming.get(codeField)));
      }
    }
  }

  private static String format(String message, Object value) {
    return String.format(message, new List<Object>{ value });
  }

  private static CMN_ValidationException unknown(Object plant) {
    return new CMN_ValidationException(
      format(Label.CMN_Site_UnknownPlant, String.valueOf(plant))
    );
  }
}
