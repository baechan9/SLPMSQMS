/**
 * @description 코멘트 조회(CMN-00-UX-003).
 * @group CMN-00-UX-003
 */
// SHARING-EXCEPTION: CMN-00-UX-003 BR-3 코멘트 공유는 부모 레코드 접근을 따른다. 코멘트는 OWD Private(Owner = 작성자)라
// 다른 사람 코멘트는 공유로 보이지 않으므로, 호출 측(CMN_CommentController)이 UserRecordAccess로 부모 읽기 권한을 확인한
// 부모의 코멘트만 이 클래스로 읽는다. 읽기 전용이다.
public without sharing class CMN_CommentSelector {
  /**
   * @description 부모 레코드의 코멘트(최신순).
   * @param parentId 부모 레코드(읽기 권한 확인 후)
   * @param maxRows 최대 건수
   * @return 코멘트
   */
  public static List<CMN_Comment__c> forParent(Id parentId, Integer maxRows) {
    String key = parentId;
    return [
      SELECT
        Id,
        Body__c,
        MentionedUserIds__c,
        IsEdited__c,
        CreatedById,
        CreatedBy.Name,
        CreatedDate,
        LastModifiedDate
      FROM CMN_Comment__c
      WHERE ParentRecordId__c = :key
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC, Id DESC
      LIMIT :maxRows
    ];
  }

  /**
   * @description 저장된 작성자·작성 시각(수정·삭제 판정 기준).
   * @param commentIds 코멘트
   * @return 코멘트 Id → 코멘트(CreatedById, CreatedDate)
   */
  public static Map<Id, CMN_Comment__c> authorship(Set<Id> commentIds) {
    return new Map<Id, CMN_Comment__c>(
      [
        SELECT Id, CreatedById, CreatedDate
        FROM CMN_Comment__c
        WHERE Id IN :commentIds
        WITH SYSTEM_MODE
      ]
    );
  }

  /**
   * @description 사내 사용자(UserType Standard)만 고른다(멘션 알림 대상).
   * @param userIds 사용자
   * @return 사내 사용자 Id
   */
  public static Set<Id> internalUsers(Set<Id> userIds) {
    return new Map<Id, User>(
        [
          SELECT Id
          FROM User
          WHERE Id IN :userIds AND UserType = 'Standard'
          WITH SYSTEM_MODE
        ]
      )
      .keySet();
  }

  /**
   * @description 사용자 이름(멘션 표시).
   * @param userIds 사용자
   * @return 사용자
   */
  public static Map<Id, User> users(Set<Id> userIds) {
    return new Map<Id, User>(
      [SELECT Id, Name FROM User WHERE Id IN :userIds WITH SYSTEM_MODE]
    );
  }
}
