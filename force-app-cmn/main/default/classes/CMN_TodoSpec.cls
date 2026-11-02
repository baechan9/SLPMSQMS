/**
 * @description To-Do 생성 명세(CMN-00-TDO-001). 사람에게 일을 시키는 모든 기능이 이 명세로 CMN_TodoService.open을 부른다.
 * 제목은 받는 사람 언어로 렌더링하도록 라벨 이름({접두어}_Todo_{SourceType})과 치환값만 넘긴다.
 * @group CMN-00-TDO-001
 */
public with sharing class CMN_TodoSpec {
  /** @description 처리자(필수). 사내·포털 사용자 */
  public Id assigneeId;
  /** @description TASK(업무) 또는 APPROVAL(결재) */
  public String category = 'TASK';
  /** @description QMS, PMS, CMN */
  public String systemCode = 'QMS';
  /** @description 원천 유형(예: CMN_APPROVAL, QMS_8D_STEP) */
  public String sourceType;
  /** @description To-Do를 만든 레코드(결재면 결재 단계) */
  public Id sourceRecordId;
  /** @description 클릭 시 열 업무 레코드 */
  public Id targetRecordId;
  /** @description 업무 번호 사본 */
  public String recordNo;
  /** @description 제목 Custom Label 이름 */
  public String titleLabel;
  /** @description 치환값: List({0}, {1}…) 또는 Map({key}) */
  public Object titleParams;
  /** @description 기본 제목. 비우면 기본 언어로 렌더링한다 */
  public String titleFallback;
  /** @description 기한(공장 시간대 기준 날짜) */
  public Date dueDate;
  /** @description 공장 */
  public Id plantId;
  /** @description 대결 To-Do 여부 */
  public Boolean isDelegated = false;
  /** @description 위임자 */
  public Id delegatedFromId;

  /**
   * @description 필수값으로 만든다.
   * @param assigneeId 처리자
   * @param sourceType 원천 유형
   * @param sourceRecordId 원천 레코드
   * @param targetRecordId 업무 레코드
   * @param titleLabel 제목 라벨 이름
   */
  public CMN_TodoSpec(
    Id assigneeId,
    String sourceType,
    Id sourceRecordId,
    Id targetRecordId,
    String titleLabel
  ) {
    this.assigneeId = assigneeId;
    this.sourceType = sourceType;
    this.sourceRecordId = sourceRecordId;
    this.targetRecordId = targetRecordId;
    this.titleLabel = titleLabel;
  }

  /**
   * @description ExternalKey(`{SourceType}/{SourceRecordId}/{AssigneeId}`).
   * @return 키
   */
  public String externalKey() {
    return sourceType + '/' + sourceRecordId + '/' + assigneeId;
  }
}
