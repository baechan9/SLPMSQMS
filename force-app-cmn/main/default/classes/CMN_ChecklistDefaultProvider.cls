/**
 * @description 체크리스트 Provider 기본 구현(CMN-00-UX-009 BR-5). 후속 조치는 MTG-001 조치 항목(CMN_ActionItem__c)으로 만든다.
 * 원천 레코드 Id(SourceRecordId__c)와 질문 키(SourceKey__c)를 남기고, 담당자 To-Do·공유는 조치 항목 서비스(트리거)가 맡는다.
 * 업무 Provider는 이것을 상속해 load·saveAnswers·preview를 구현한다. QMS 심사 Provider는 raiseFollowUp을 재정의해 IAU-004 지적을 만든다.
 * @group CMN-00-UX-009
 */
public abstract with sharing class CMN_ChecklistDefaultProvider implements CMN_ChecklistProvider {
  private static final Integer TITLE_LENGTH = 80;

  /**
   * @description 수행 시트.
   * @param recordId 업무 레코드 Id
   * @return 시트
   */
  public abstract CMN_Checklist.Sheet load(Id recordId);

  /**
   * @description 답 저장.
   * @param recordId 업무 레코드 Id
   * @param answers 답
   * @param isFinal 제출 여부
   * @return 저장 결과
   */
  public abstract CMN_Checklist.SaveResult saveAnswers(
    Id recordId,
    List<CMN_Checklist.Answer> answers,
    Boolean isFinal
  );

  /**
   * @description 점수 미리보기.
   * @param recordId 업무 레코드 Id
   * @return 미리보기
   */
  public abstract CMN_Checklist.ScorePreview preview(Id recordId);

  /**
   * @description 후속 조치를 조치 항목으로 만든다(사용자 권한). 담당을 비우면 현재 사용자.
   * @param recordId 업무 레코드 Id
   * @param questionKey 질문 키
   * @param input 입력
   * @return 조치 항목 Id
   * @throws CMN_ValidationException 제목·기한 누락(라벨 문구)
   */
  public virtual Id raiseFollowUp(
    Id recordId,
    String questionKey,
    CMN_Checklist.FollowUpInput input
  ) {
    if (input == null || String.isBlank(input.title) || input.dueDate == null) {
      throw new CMN_ValidationException(
        Label.CMN_Checklist_FollowUpTitleRequired
      );
    }
    CMN_ActionItem__c item = new CMN_ActionItem__c(
      Name = input.title.trim().left(TITLE_LENGTH),
      Description__c = input.description,
      Owner__c = input.ownerId ?? UserInfo.getUserId(),
      DueDate__c = input.dueDate,
      Status__c = 'OPEN',
      SourceRecordId__c = recordId,
      SourceKey__c = questionKey,
      Plant__c = plantOf(recordId)
    );
    Database.insert(item, AccessLevel.USER_MODE);
    return item.Id;
  }

  /**
   * @description 조치 항목에 넣을 공장(공장 공유·To-Do 범위). 기본은 없음, 업무 Provider가 재정의한다.
   * @param recordId 업무 레코드 Id
   * @return 공장 Id 또는 null
   */
  protected virtual Id plantOf(Id recordId) {
    return null;
  }
}
