/**
 * @description 그리드 행 하나의 메타(CMN-00-UX-006 BR-11). Provider rowMeta가 만든다. 화면은 삭제 버튼 막기·셀 읽기 전용·경고
 * 표시에 쓰고, 서버 저장은 같은 메타로 삭제 불가 행 삭제와 잠긴 셀 변경을 다시 거부한다. 문구는 Custom Label 값(Label.X)을 넣는다.
 * @group CMN-00-UX-006
 */
public with sharing class CMN_GridRowMeta {
  /** 삭제 가능 여부 */
  public Boolean deletable = true;
  /** 삭제할 수 없는 이유(화면 안내 문구) */
  public String deleteBlockedLabel;
  /** 이 행에서 읽기 전용인 필드 API명 */
  public Set<String> lockedFields = new Set<String>();
  /** 경고 문구(아이콘과 함께 표시) */
  public String warningLabel;

  /**
   * @description 삭제를 막는다.
   * @param reason 이유 문구
   * @return this
   */
  public CMN_GridRowMeta blockDelete(String reason) {
    this.deletable = false;
    this.deleteBlockedLabel = reason;
    return this;
  }

  /**
   * @description 필드를 이 행에서 읽기 전용으로 둔다.
   * @param fieldApiName 필드 API명
   * @return this
   */
  public CMN_GridRowMeta lock(String fieldApiName) {
    if (String.isNotBlank(fieldApiName)) {
      this.lockedFields.add(fieldApiName);
    }
    return this;
  }

  /**
   * @description 경고 문구를 단다.
   * @param message 경고 문구
   * @return this
   */
  public CMN_GridRowMeta warn(String message) {
    this.warningLabel = message;
    return this;
  }
}
