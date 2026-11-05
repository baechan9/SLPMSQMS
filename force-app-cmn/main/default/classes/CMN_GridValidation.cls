/**
 * @description 그리드 저장 전 검증 결과(CMN-00-UX-006 BR-4). Provider validate가 만든다.
 * 행 오류는 validate에 받은 rows 목록의 순번(0부터)으로 단다. 서버가 순번을 화면 행 키로 바꿔 돌려준다.
 * @group CMN-00-UX-006
 */
public with sharing class CMN_GridValidation {
  /** @description 행 오류 하나. */
  public class Issue {
    /** rows 목록 순번(0부터) */
    public Integer rowIndex;
    /** 강조할 셀 필드(없으면 행 전체) */
    public String fieldApiName;
    /** 화면 문구(Custom Label 값) */
    public String message;
  }

  /** 행 오류 */
  public List<Issue> rowIssues = new List<Issue>();
  /** 그리드 전체 오류(행과 무관) */
  public List<String> gridErrors = new List<String>();

  /**
   * @description 행 오류를 단다.
   * @param rowIndex rows 순번
   * @param message 문구
   * @return this
   */
  public CMN_GridValidation addRowError(Integer rowIndex, String message) {
    return addRowError(rowIndex, null, message);
  }

  /**
   * @description 셀(필드) 오류를 단다.
   * @param rowIndex rows 순번
   * @param fieldApiName 필드 API명
   * @param message 문구
   * @return this
   */
  public CMN_GridValidation addRowError(
    Integer rowIndex,
    String fieldApiName,
    String message
  ) {
    Issue i = new Issue();
    i.rowIndex = rowIndex;
    i.fieldApiName = fieldApiName;
    i.message = message;
    rowIssues.add(i);
    return this;
  }

  /**
   * @description 그리드 전체 오류를 단다.
   * @param message 문구
   * @return this
   */
  public CMN_GridValidation addGridError(String message) {
    gridErrors.add(message);
    return this;
  }

  /**
   * @description 오류가 있는가.
   * @return 행 또는 그리드 오류가 하나라도 있으면 true
   */
  public Boolean hasErrors() {
    return !rowIssues.isEmpty() || !gridErrors.isEmpty();
  }
}
