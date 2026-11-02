/**
 * @description 위젯 설정 검증(CMN-00-DSH-001, Vol.7 변경 요청). CMN_DashboardResolver__mdt(Kind CONFIG_VALIDATOR)에 등록하면
 * 보드 저장 때 모든 위젯 설정에 대해 호출된다. 스키마 규약 검증은 QMS-07-DSH-004가 구현한다.
 * @group CMN-00-DSH-001
 */
public interface CMN_WidgetConfigValidator {
  /**
   * @description 위젯 설정을 검증한다.
   * @param widgetKey 위젯(CMN_Widget__mdt DeveloperName)
   * @param config 설정(JSON 객체)
   * @return 오류 사유(통과면 null)
   */
  String validate(String widgetKey, Map<String, Object> config);
}
