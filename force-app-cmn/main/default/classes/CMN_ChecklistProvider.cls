/**
 * @description 체크리스트 수행 화면의 업무 확장점(CMN-00-UX-009). 심사·자체 평가·레슨런 점검·PMS Gate처럼 질문 목록에 점수·적합·관찰·증빙을
 * 남기는 화면(T4)은 cmnChecklistRunner 하나를 쓰고, 질문지 구성·필수 입력 규칙·점수 계산·후속 조치만 업무 WI가 구현한다.
 * 질문지·점수 객체는 업무 메뉴가 갖는다(QMS 심사는 Vol.6c IAU-001·003, CAU-002). 구현 클래스는 CMN_ChecklistProvider__mdt에 등록한다.
 * 직접 구현하기보다 CMN_ChecklistDefaultProvider를 상속하면 후속 조치 기본 구현(조치 항목)을 그대로 쓸 수 있다.
 * @group CMN-00-UX-009
 */
public interface CMN_ChecklistProvider {
  /**
   * @description 수행 시트(요소·질문·저장된 답·편집 가능·점수 공개). 질문 문구는 사용자 언어로 준다.
   * @param recordId 업무 레코드 Id
   * @return 시트
   */
  CMN_Checklist.Sheet load(Id recordId);

  /**
   * @description 답 저장. isFinal=false는 중간 저장, true는 제출(필수 입력 규칙 확인).
   * @param recordId 업무 레코드 Id
   * @param answers 답(중간 저장은 바뀐 질문만, 제출은 전체)
   * @param isFinal 제출 여부
   * @return 성공 여부와 질문 키별 오류
   */
  CMN_Checklist.SaveResult saveAnswers(
    Id recordId,
    List<CMN_Checklist.Answer> answers,
    Boolean isFinal
  );

  /**
   * @description 점수 미리보기(달성률·등급·강등·미답). 셸은 계산하지 않는다.
   * @param recordId 업무 레코드 Id
   * @return 미리보기
   */
  CMN_Checklist.ScorePreview preview(Id recordId);

  /**
   * @description 질문의 후속 조치를 만든다.
   * @param recordId 업무 레코드 Id
   * @param questionKey 질문 키
   * @param input 제목·내용·담당·기한·심각도
   * @return 만든 레코드 Id
   */
  Id raiseFollowUp(
    Id recordId,
    String questionKey,
    CMN_Checklist.FollowUpInput input
  );
}
