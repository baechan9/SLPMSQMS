/**
 * @description 공통 편집 그리드 화면 진입점(CMN-00-UX-006, LWC cmnEditableGrid). 처리는 CMN_GridService가 한다.
 * 업무 오류(편집 불가·버전 충돌·행 오류)는 SaveResult로, 요청·설정·권한 오류는 라벨 문구의 AuraHandledException으로 돌려준다.
 * 편집 화면이라 조회도 cacheable이 아니다(저장 뒤 최신 행을 다시 읽어야 한다).
 * @group CMN-00-UX-006
 */
public with sharing class CMN_GridController {
  /**
   * @description 그리드 로드(열 정의·행·편집 가능 여부·버전).
   * @param gridKey 그리드 키(CMN_GridDefinition__mdt DeveloperName)
   * @param parentId 부모 레코드 Id(레코드 페이지 recordId)
   * @return 화면 데이터
   * @throws AuraHandledException 키·부모 형식 오류, 정의 없음, 권한 없음, 설정 오류, 예상하지 못한 오류(라벨 문구)
   */
  @AuraEnabled
  public static CMN_GridService.GridView load(String gridKey, Id parentId) {
    try {
      return CMN_GridService.load(gridKey, parentId);
    } catch (Exception e) {
      throw toAura(e, 'load', parentId);
    }
  }

  /**
   * @description 그리드 저장(바뀐 행만, 오류가 있으면 아무 행도 저장하지 않음).
   * @param gridKey 그리드 키
   * @param parentId 부모 레코드 Id
   * @param rowsJson [{key, id, values}] JSON
   * @param deletedIds 삭제할 행 Id
   * @param clientVersion 로드 때 받은 버전
   * @return 저장 결과(성공 시 최신 그리드 포함)
   * @throws AuraHandledException 요청 형식 오류, 설정 오류, 예상하지 못한 오류(라벨 문구)
   */
  @AuraEnabled
  public static CMN_GridService.SaveResult save(
    String gridKey,
    Id parentId,
    String rowsJson,
    List<Id> deletedIds,
    String clientVersion
  ) {
    try {
      return CMN_GridService.save(
        gridKey,
        parentId,
        rowsJson,
        deletedIds,
        clientVersion
      );
    } catch (Exception e) {
      throw toAura(e, 'save', parentId);
    }
  }

  /**
   * @description 붙여넣기·셀 편집의 참조 확인(이름·외부 키·Id → 레코드와 표시명). 한 번 호출로 여러 열을 확인한다.
   * @param gridKey 그리드 키
   * @param parentId 부모 레코드 Id
   * @param keysJson {"필드 API명": ["값", …]} JSON(서로 다른 값 최대 200개)
   * @return 값별 결과
   * @throws AuraHandledException 형식 오류, 값 개수 초과, 예상하지 못한 오류(라벨 문구)
   */
  @AuraEnabled
  public static List<CMN_GridService.LookupMatch> resolveLookups(
    String gridKey,
    Id parentId,
    String keysJson
  ) {
    try {
      return CMN_GridService.resolveLookups(gridKey, parentId, keysJson);
    } catch (Exception e) {
      throw toAura(e, 'resolveLookups', parentId);
    }
  }

  /** 검증 예외는 라벨 문구 그대로, 그 밖의 예외는 원문을 로그에 남기고 일반 문구로 바꾼다. */
  private static AuraHandledException toAura(
    Exception e,
    String method,
    Id parentId
  ) {
    String message = e.getMessage();
    if (!(e instanceof CMN_ValidationException)) {
      CMN_Logger.error('CMN_GridController.' + method, message, parentId, e);
      message = Label.CMN_Common_UnexpectedError;
    }
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
