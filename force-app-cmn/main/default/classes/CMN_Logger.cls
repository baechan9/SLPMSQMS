/**
 * @description 공통 로거. CMN_LogEvent__e(즉시 발행)를 발행하고 구독 트리거가 CMN_Log__c를 만든다.
 *              즉시 발행이라 호출한 트랜잭션이 롤백돼도 로그가 남는다(BR-4). 최소 수준(CMN_LogSetting__c.MinLevel__c,
 *              기본 INFO) 미만은 발행하지 않는다. 이벤트 발행은 DML 문 한도를 쓰므로 루프 안에서 부르지 않는다.
 *              개인정보·비용 원문·토큰은 넘기지 않는다(sf-dev 3절).
 * @group CMN-00-ARC-002
 */
public with sharing class CMN_Logger {
  private static final Map<String, Integer> RANK = new Map<String, Integer>{
    'DEBUG' => 0,
    'INFO' => 1,
    'WARN' => 2,
    'ERROR' => 3
  };
  private static final Integer MESSAGE_MAX = 32768;
  private static final Integer PAYLOAD_MAX = 131072;

  @TestVisible
  private static String minLevelOverride;

  /**
   * @description 오류 로그. 화면에는 라벨 문구를 보내고, 원문은 여기에 남긴다.
   * @param source `클래스.메서드`
   * @param message 내용
   * @param recordId 관련 레코드(없으면 null)
   * @param ex 예외(형식·메시지·스택이 Payload에 들어감, 없으면 null)
   */
  public static void error(
    String source,
    String message,
    Id recordId,
    Exception ex
  ) {
    publish('ERROR', source, message, recordId, describe(ex));
  }

  /**
   * @description 예외 없는 오류 로그.
   * @param source `클래스.메서드`
   * @param message 내용
   * @param recordId 관련 레코드
   */
  public static void error(String source, String message, Id recordId) {
    publish('ERROR', source, message, recordId, null);
  }

  /**
   * @description 경고 로그.
   * @param source `클래스.메서드`
   * @param message 내용
   * @param recordId 관련 레코드
   */
  public static void warn(String source, String message, Id recordId) {
    publish('WARN', source, message, recordId, null);
  }

  /**
   * @description 정보 로그.
   * @param source `클래스.메서드`
   * @param message 내용
   */
  public static void info(String source, String message) {
    publish('INFO', source, message, null, null);
  }

  /**
   * @description 디버그 로그(기본 최소 수준 INFO에서는 발행되지 않음).
   * @param source `클래스.메서드`
   * @param message 내용
   */
  public static void debug(String source, String message) {
    publish('DEBUG', source, message, null, null);
  }

  /**
   * @description 수준·Payload를 직접 지정하는 로그(연계 요청·응답 원문 등).
   * @param level ERROR, WARN, INFO, DEBUG
   * @param source `클래스.메서드`
   * @param message 내용
   * @param recordId 관련 레코드
   * @param payload 상세 원문
   */
  public static void log(
    String level,
    String source,
    String message,
    Id recordId,
    String payload
  ) {
    publish(level, source, message, recordId, payload);
  }

  /**
   * @description 이 수준의 로그가 발행되는지.
   * @param level ERROR, WARN, INFO, DEBUG
   * @return 최소 수준 이상이면 true
   */
  public static Boolean isEnabled(String level) {
    Integer levelRank = RANK.get(level?.toUpperCase());
    return levelRank != null && levelRank >= RANK.get(minLevel());
  }

  private static void publish(
    String level,
    String source,
    String message,
    Id recordId,
    String payload
  ) {
    String lv = level?.toUpperCase();
    if (!isEnabled(lv)) {
      return;
    }
    CMN_LogEvent__e e = new CMN_LogEvent__e(
      Level__c = lv,
      Source__c = String.isBlank(source) ? 'unknown' : source.abbreviate(255),
      Message__c = (message ?? '').abbreviate(MESSAGE_MAX),
      RecordId__c = recordId,
      Payload__c = payload?.abbreviate(PAYLOAD_MAX),
      TransactionId__c = transactionId()
    );
    Database.SaveResult sr = EventBus.publish(e);
    if (!sr.isSuccess()) {
      // 로그 발행 실패로 업무를 막지 않는다. 디버그 로그에만 남긴다.
      System.debug(
        LoggingLevel.ERROR,
        'CMN_Logger publish failed: ' + sr.getErrors()
      );
    }
  }

  private static String minLevel() {
    String v = (minLevelOverride ??
        CMN_LogSetting__c.getInstance()?.MinLevel__c)
      ?.toUpperCase();
    return RANK.containsKey(v) ? v : 'INFO';
  }

  private static String transactionId() {
    return Request.getCurrent()?.getRequestId() ?? 'unknown';
  }

  private static String describe(Exception ex) {
    if (ex == null) {
      return null;
    }
    return ex.getTypeName() +
      ': ' +
      ex.getMessage() +
      '\n' +
      ex.getStackTraceString();
  }
}
