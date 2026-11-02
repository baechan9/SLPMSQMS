/**
 * @description 대시보드 템플릿 해석기(CMN-00-DSH-001 BR-3, Vol.7 변경 요청). CMN_DashboardResolver__mdt(Kind TEMPLATE_RESOLVER)에 등록한다.
 * 예: QMS_DashboardPersonaResolver(QMS-07-DSH-013)가 사용자 직무·공장으로 템플릿을 고르고 {userPlantId} 같은 토큰을 채운다.
 * @group CMN-00-DSH-001
 */
public interface CMN_DashboardTemplateResolver {
  /**
   * @description 사용자에게 줄 템플릿 키(CMN_DashboardTemplate__mdt DeveloperName).
   * @param systemCode QMS 또는 PMS
   * @param userId 사용자
   * @param permissionSetGroups 사용자의 PSG DeveloperName
   * @return 템플릿 키(정하지 않으면 null — 다음 해석기·기본 규칙)
   */
  String templateFor(
    String systemCode,
    Id userId,
    Set<String> permissionSetGroups
  );

  /**
   * @description 템플릿 항목 config JSON의 토큰을 사용자 값으로 바꾼다(템플릿 복사 때만).
   * @param configJson 설정 JSON
   * @param userId 사용자
   * @return 바꾼 JSON(바꿀 것이 없으면 그대로)
   */
  String resolveConfig(String configJson, Id userId);
}
