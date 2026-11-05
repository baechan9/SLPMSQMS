/**
 * @description CMN_GridProvider 기본 구현(CMN-00-UX-006). 네 메서드 모두 제약 없음이다. 업무 Provider는 이것을 상속해
 * 필요한 메서드만 재정의한다.
 * @group CMN-00-UX-006
 */
public abstract with sharing class CMN_GridProviderBase implements CMN_GridProvider {
  /**
   * @description 새 행 기본값 없음.
   * @param parentId 부모 레코드 Id
   * @return 빈 맵
   */
  public virtual Map<String, Object> defaults(Id parentId) {
    return new Map<String, Object>();
  }

  /**
   * @description 모든 행 삭제 가능, 잠긴 열·경고 없음.
   * @param parentId 부모 레코드 Id
   * @param rows 현재 행
   * @return 빈 맵
   */
  public virtual Map<Id, CMN_GridRowMeta> rowMeta(
    Id parentId,
    List<SObject> rows
  ) {
    return new Map<Id, CMN_GridRowMeta>();
  }

  /**
   * @description 업무 검증 없음.
   * @param parentId 부모 레코드 Id
   * @param rows 저장할 행
   * @param deletedIds 삭제할 행 Id
   * @return 오류 없는 결과
   */
  public virtual CMN_GridValidation validate(
    Id parentId,
    List<SObject> rows,
    List<Id> deletedIds
  ) {
    return new CMN_GridValidation();
  }

  /**
   * @description 저장 후 처리 없음.
   * @param parentId 부모 레코드 Id
   * @param savedRows 저장한 행
   * @param deletedIds 삭제한 행 Id
   */
  public virtual void afterSave(
    Id parentId,
    List<SObject> savedRows,
    List<Id> deletedIds
  ) {
    return;
  }

  /**
   * @description 행의 필드 값. 조회하지 않은 필드(열이 아니거나 읽기 권한이 없는 필드)면 null.
   * @param row 행
   * @param fieldApiName 필드 API명
   * @return 값 또는 null
   */
  protected Object valueOf(SObject row, String fieldApiName) {
    try {
      return row?.get(fieldApiName);
    } catch (SObjectException e) {
      return null;
    }
  }
}
