/**
 * @description 현장 입력 셸의 업무 확장점(CMN-00-UX-008). 수입·출하 검사, 시험 결과, 교정, 초기유동 점검처럼 시료 값을 넣는
 * 화면(T3)은 셸(cmnFieldEntryShell) 하나를 쓰고, 입력 시트 구성·판정·저장·스캔 확인만 업무 WI가 이 인터페이스로 구현한다.
 * 구현 클래스는 CMN_FieldEntryProvider__mdt에 객체별로 등록한다(공개 기본 생성자 필요).
 * 측정값을 시료마다 레코드로 만들지 않는다. 항목별 JSON 묶음 등으로 저장한다(Vol.0 3절).
 * @group CMN-00-UX-008
 */
public interface CMN_FieldEntryProvider {
  /**
   * @description 입력 시트(헤더·항목·저장된 값·편집 가능 여부). 레코드 접근은 USER_MODE로 확인한다.
   * @param recordId 업무 레코드 Id
   * @return 시트
   */
  CMN_FieldEntry.Sheet load(Id recordId);

  /**
   * @description 값 저장과 판정. isFinal=false는 중간 저장(받은 항목 값만 합친다), true는 최종 판정과 후속 처리.
   * @param recordId 업무 레코드 Id
   * @param values 입력값(중간 저장은 바뀐 항목만, 최종은 전체)
   * @param isFinal 최종 판정 여부
   * @return 항목별 판정·전체 판정·오류·후속 안내
   */
  CMN_FieldEntry.SaveResult save(
    Id recordId,
    List<CMN_FieldEntry.Value> values,
    Boolean isFinal
  );

  /**
   * @description 스캔 값 확인(로트·측정기 번호).
   * @param recordId 업무 레코드 Id
   * @param scanType LOT 또는 GAUGE
   * @param value 스캔·입력 값
   * @return 오류 Custom Label 이름, 문제없으면 null
   */
  String validateScan(Id recordId, String scanType, String value);
}
