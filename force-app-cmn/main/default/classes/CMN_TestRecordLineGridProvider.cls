/**
 * @description 테스트 라인 샘플 그리드의 Provider(CMN-00-UX-006, 개발 플랜 DEV-3). 업무 그리드 Provider를 만드는 본보기다.
 * - 기본값: 구분 계획, 수량 1, 시작일 오늘
 * - 행 메타: 완료 행은 삭제 불가·일정·수량 잠금, 종료일이 지났는데 완료되지 않은 행은 경고
 * - 검증: 종료일 < 시작일, 수량 < 0
 * @group CMN-00-UX-006
 */
public with sharing class CMN_TestRecordLineGridProvider extends CMN_GridProviderBase {
  private static final String DONE = 'IsDone__c';
  private static final String START_DATE = 'StartDate__c';
  private static final String END_DATE = 'EndDate__c';
  private static final String QUANTITY = 'Quantity__c';

  /**
   * @description 새 행 기본값.
   * @param parentId 테스트 레코드 Id
   * @return 필드 → 값
   */
  public override Map<String, Object> defaults(Id parentId) {
    return new Map<String, Object>{
      'Category__c' => 'PLAN',
      QUANTITY => Decimal.valueOf(1),
      START_DATE => Date.today()
    };
  }

  /**
   * @description 완료 행 삭제·일정 잠금, 기한 경과 경고.
   * @param parentId 테스트 레코드 Id
   * @param rows 현재 행
   * @return 행 Id → 메타
   */
  public override Map<Id, CMN_GridRowMeta> rowMeta(
    Id parentId,
    List<SObject> rows
  ) {
    Map<Id, CMN_GridRowMeta> out = new Map<Id, CMN_GridRowMeta>();
    Date today = Date.today();
    for (SObject r : rows) {
      CMN_GridRowMeta meta = new CMN_GridRowMeta();
      Boolean isDone = valueOf(r, DONE) == true;
      Date endDate = (Date) valueOf(r, END_DATE);
      if (isDone) {
        meta.blockDelete(Label.CMN_Grid_SampleDoneLocked)
          .lock(START_DATE)
          .lock(END_DATE)
          .lock(QUANTITY);
      } else if (endDate != null && endDate < today) {
        meta.warn(Label.CMN_Grid_WarnOverdue);
      }
      out.put(r.Id, meta);
    }
    return out;
  }

  /**
   * @description 종료일 < 시작일, 음수 수량을 막는다.
   * @param parentId 테스트 레코드 Id
   * @param rows 저장할 행
   * @param deletedIds 삭제할 행 Id
   * @return 행 오류
   */
  public override CMN_GridValidation validate(
    Id parentId,
    List<SObject> rows,
    List<Id> deletedIds
  ) {
    CMN_GridValidation result = new CMN_GridValidation();
    for (Integer i = 0; i < rows.size(); i++) {
      Date startDate = (Date) valueOf(rows[i], START_DATE);
      Date endDate = (Date) valueOf(rows[i], END_DATE);
      Decimal qty = (Decimal) valueOf(rows[i], QUANTITY);
      if (startDate != null && endDate != null && endDate < startDate) {
        result.addRowError(i, END_DATE, Label.CMN_Grid_SampleEndBeforeStart);
      }
      if (qty != null && qty < 0) {
        result.addRowError(i, QUANTITY, Label.CMN_Grid_SampleNegativeQty);
      }
    }
    return result;
  }
}
