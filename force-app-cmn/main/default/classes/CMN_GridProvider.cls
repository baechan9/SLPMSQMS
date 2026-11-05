/**
 * @description 공통 편집 그리드의 업무 확장점(CMN-00-UX-006). 그리드마다 LWC를 새로 만들지 않고, 업무 차이(새 행 기본값,
 * 행별 삭제·잠금·경고, 저장 전 검증, 저장 후 처리)를 이 구현으로 낸다. 직접 구현하지 말고 CMN_GridProviderBase를 상속해
 * 필요한 메서드만 재정의한다. 구현 클래스 이름은 그리드 정의 ProviderClass__c에 적는다(공개 기본 생성자 필요).
 * @group CMN-00-UX-006
 */
public interface CMN_GridProvider {
  /**
   * @description 새 행 기본값. 그리드 열이 아닌 필드도 넣을 수 있다(서버가 새 행에 채운다).
   * @param parentId 부모 레코드 Id
   * @return 필드 API명 → 값
   */
  Map<String, Object> defaults(Id parentId);

  /**
   * @description 행별 삭제 가능 여부·잠긴 열·경고(BR-11). 로드와 저장 때 현재 저장된 행으로 부른다.
   * 행에는 그리드 열 필드만 조회돼 있다(열이 아닌 필드가 필요하면 Provider가 직접 조회한다).
   * @param parentId 부모 레코드 Id
   * @param rows 현재 행
   * @return 행 Id → 메타(없는 행은 제약 없음)
   */
  Map<Id, CMN_GridRowMeta> rowMeta(Id parentId, List<SObject> rows);

  /**
   * @description 저장 전 업무 검증(BR-4). 오류가 하나라도 있으면 아무 행도 저장하지 않는다.
   * @param parentId 부모 레코드 Id
   * @param rows 저장할 행(수정 행은 현재 값에 변경을 합친 전체 값, 새 행은 Id 없음). 오류 위치는 이 목록의 순번
   * @param deletedIds 삭제할 행 Id
   * @return 행·그리드 오류
   */
  CMN_GridValidation validate(
    Id parentId,
    List<SObject> rows,
    List<Id> deletedIds
  );

  /**
   * @description 저장 후 처리(재계산 등). 같은 트랜잭션이라 예외가 나면 그리드 저장 전체가 되돌아간다.
   * @param parentId 부모 레코드 Id
   * @param savedRows 저장한 행(새 행에도 Id가 있다)
   * @param deletedIds 삭제한 행 Id
   */
  void afterSave(Id parentId, List<SObject> savedRows, List<Id> deletedIds);
}
