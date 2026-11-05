/**
 * @description 화면 우선 개발 A단계 공용 자리 구현(A0 프로토 공용 장치, docs/wi/A0-prototype-kit.md, 화면 우선 플랜 4.3).
 * - notYetAvailable(): 업무 동작 서비스 메서드(명세 시그니처 그대로)의 A단계 본문. 라벨 문구의 검증 예외를 던진다.
 *   B단계에서 서비스 본문을 채우면 참조가 사라진다(scripts/ci/check-prototype-stubs.py가 메뉴·WI별로 센다).
 * - mockResponse(queryKey, params): Snowflake 표시 화면의 예시 응답(정적 리소스 CMN_PrototypeMocks, spec-snowflake-display.md 형식).
 *   업무 코드에 목을 섞지 않으려고 여기 한곳에 둔다. 세 조건을 모두 만족할 때만 응답하고, 아니면 null이다:
 *   기능 스위치 CMN_PROTOTYPE_MODE가 켜짐, 사용자에게 검토용 PS(QMS_PS_Prototype_Review), Scratch Org.
 *   운영·SIT에서는 응답하지 않는다(결정 SF-2).
 * 전 메뉴 B단계 후 이 클래스·정적 리소스·검토용 PS를 삭제한다(사용자 승인).
 * @group A0-PROTOTYPE
 */
public with sharing class CMN_Prototype {
  public static final String SWITCH_KEY = 'CMN_PROTOTYPE_MODE';
  public static final String RESOURCE = 'CMN_PrototypeMocks';
  public static final String DEFAULT_CASE = 'ok';
  public static final String MOCK_FLAG = 'isMock';
  private static Boolean scratchOrg;
  private static Map<String, Object> bundle;
  @TestVisible
  private static Boolean scratchOverride;
  @TestVisible
  private static String bundleOverride;

  /**
   * @description A단계 업무 동작 자리 구현: "상세 기능 개발 단계에서 동작" 안내로 멈춘다.
   * @throws CMN_ValidationException 항상(라벨 CMN_Prototype_NotYetAvailable)
   */
  public static void notYetAvailable() {
    throw new CMN_ValidationException(Label.CMN_Prototype_NotYetAvailable);
  }

  /**
   * @description 프로토 모드인가(스위치 + 검토용 PS + Scratch Org).
   * @return 목 응답을 쓸 수 있으면 true
   */
  public static Boolean isActive() {
    return CMN_FeatureSwitch.isOn(SWITCH_KEY) && isScratchOrg();
  }

  /**
   * @description Snowflake 조회 예시 응답. 응답 맵에 isMock = true를 더한다(화면이 "예시 데이터"를 표시).
   * @param queryKey 조회 키(예: QMS_B2B_PARETO)
   * @param params 조회 매개변수. case(ok·empty·stale·truncated·error-timeout)로 응답을 고른다(없거나 모르면 ok)
   * @return 응답(JSON 맵) 또는 null(프로토 모드 아님·모르는 키)
   */
  public static Object mockResponse(
    String queryKey,
    Map<String, Object> params
  ) {
    if (String.isBlank(queryKey) || !isActive()) {
      return null;
    }
    Object dwh = mocks().get('dwh');
    Object cases = dwh instanceof Map<String, Object>
      ? ((Map<String, Object>) dwh).get(queryKey)
      : null;
    if (!(cases instanceof Map<String, Object>)) {
      return null;
    }
    Map<String, Object> byCase = (Map<String, Object>) cases;
    Object wanted = params?.get('case');
    Object response = byCase.get(
      wanted instanceof String && byCase.containsKey((String) wanted)
        ? (String) wanted
        : DEFAULT_CASE
    );
    if (response instanceof Map<String, Object>) {
      Map<String, Object> copy = new Map<String, Object>(
        (Map<String, Object>) response
      );
      copy.put(MOCK_FLAG, true);
      return copy;
    }
    return response;
  }

  // ------------------------------------------------------------------ 내부
  private static Boolean isScratchOrg() {
    if (scratchOverride != null) {
      return scratchOverride;
    }
    if (scratchOrg == null) {
      Organization o = [
        SELECT IsSandbox, TrialExpirationDate
        FROM Organization
        WITH SYSTEM_MODE
        LIMIT 1
      ];
      // Scratch Org는 샌드박스이면서 만료일이 있다(SIT 샌드박스·운영은 만료일 없음)
      scratchOrg = o.IsSandbox && o.TrialExpirationDate != null;
    }
    return scratchOrg;
  }

  private static Map<String, Object> mocks() {
    if (bundle == null) {
      String body = bundleOverride;
      if (body == null) {
        List<StaticResource> rows = [
          SELECT Body
          FROM StaticResource
          WHERE Name = :RESOURCE
          WITH SYSTEM_MODE
          LIMIT 1
        ];
        body = rows.isEmpty() ? '{}' : rows[0].Body.toString();
      }
      Object parsed = JSON.deserializeUntyped(body);
      bundle = parsed instanceof Map<String, Object>
        ? (Map<String, Object>) parsed
        : new Map<String, Object>();
    }
    return bundle;
  }
}
