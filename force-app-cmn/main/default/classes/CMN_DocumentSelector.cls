/**
 * @description 문서·리비전 조회(CMN-00-DOC-001).
 * @group CMN-00-DOC-001
 */
// SHARING-EXCEPTION: CMN-00-DOC-001 문서 단위 판정(BR-1: 같은 부모·분류 문서 찾기)과 중복 파일 탐지(BR-5: 다른 공장·다른 부모의
// 같은 파일)는 사용자가 볼 수 없는 문서까지 봐야 한다. 패널 조회는 호출 측이 부모 접근(UserRecordAccess)을 확인한 부모의 문서만 읽는다(BR-6).
// 읽기 전용이며 중복 탐지 결과는 경고 표시와 원본 리비전 Id만 남긴다.
public without sharing class CMN_DocumentSelector {
  /**
   * @description 현재 사용자가 편집할 수 있는 부모 레코드.
   * @param parentIds 부모
   * @return 편집 가능한 것
   */
  public static Set<Id> editableParents(Set<Id> parentIds) {
    Set<Id> out = new Set<Id>();
    for (UserRecordAccess a : [
      SELECT RecordId, HasEditAccess
      FROM UserRecordAccess
      WHERE UserId = :UserInfo.getUserId() AND RecordId IN :parentIds
      WITH SYSTEM_MODE
    ]) {
      if (a.HasEditAccess) {
        out.add(a.RecordId);
      }
    }
    return out;
  }

  /**
   * @description DOC_CLASS 코드(그룹·속성 포함).
   * @param codeId 코드
   * @return 코드(없으면 null)
   */
  public static CMN_Code__c docClass(Id codeId) {
    List<CMN_Code__c> rows = [
      SELECT
        Id,
        Name,
        NameEn__c,
        NameZh__c,
        Code__c,
        IsActive__c,
        Attribute1__c,
        Attribute2__c,
        Attribute3__c,
        CodeGroup__r.GroupCode__c
      FROM CMN_Code__c
      WHERE Id = :codeId
      WITH SYSTEM_MODE
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * @description DOC_CLASS 코드(코드 값으로).
   * @param codes 코드 값(예: 8D_REPORT). 비우면 전체
   * @return 코드
   */
  public static List<CMN_Code__c> docClasses(Set<String> codes) {
    String groupCode = CMN_DocumentService.CLASS_GROUP;
    List<CMN_Code__c> rows = [
      SELECT
        Id,
        Name,
        NameEn__c,
        NameZh__c,
        Code__c,
        IsActive__c,
        Attribute1__c,
        Attribute2__c,
        Attribute3__c,
        SortOrder__c
      FROM CMN_Code__c
      WHERE CodeGroup__r.GroupCode__c = :groupCode AND IsActive__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY SortOrder__c, Name
    ];
    if (codes == null || codes.isEmpty()) {
      return rows;
    }
    List<CMN_Code__c> out = new List<CMN_Code__c>();
    for (CMN_Code__c c : rows) {
      if (codes.contains(c.Code__c)) {
        out.add(c);
      }
    }
    return out;
  }

  /**
   * @description 부모·분류의 문서와 리비전(최신 번호부터).
   * @param parentId 부모
   * @param docClassId 분류(null이면 전체)
   * @return 문서
   */
  public static List<CMN_Document__c> documentsOf(Id parentId, Id docClassId) {
    String key = parentId;
    List<CMN_Document__c> out = new List<CMN_Document__c>();
    for (CMN_Document__c d : [
      SELECT
        Id,
        Name,
        DocClass__c,
        DeliverableType__c,
        SupplierVisible__c,
        CurrentRevision__c,
        (
          SELECT
            Id,
            Name,
            RevisionNo__c,
            Status__c,
            StorageType__c,
            ContentDocumentId__c,
            ExternalUrl__c,
            ExternalRef__c,
            FileName__c,
            FileSize__c,
            IsDuplicateFile__c,
            DuplicateOfRevision__r.Document__r.ParentRecordId__c,
            DuplicateOfRevision__r.Document__r.ParentObject__c,
            ChangeNote__c,
            ReleasedAt__c,
            CreatedBy.Name,
            CreatedDate
          FROM Revisions__r
          ORDER BY RevisionNo__c DESC
        )
      FROM CMN_Document__c
      WHERE ParentRecordId__c = :key
      WITH SYSTEM_MODE
      ORDER BY Name
    ]) {
      if (docClassId == null || d.DocClass__c == docClassId) {
        out.add(d);
      }
    }
    return out;
  }

  /**
   * @description 코드와 그룹 코드(문서 분류 확인).
   * @param codeIds 코드
   * @return 코드 Id → 코드
   */
  public static Map<Id, CMN_Code__c> classGroups(Set<Id> codeIds) {
    return new Map<Id, CMN_Code__c>(
      [
        SELECT Id, CodeGroup__r.GroupCode__c
        FROM CMN_Code__c
        WHERE Id IN :codeIds
        WITH SYSTEM_MODE
      ]
    );
  }

  /**
   * @description 문서들의 리비전 상태(삭제 통제).
   * @param documentIds 문서
   * @return 리비전
   */
  public static List<CMN_DocumentRevision__c> revisionsOf(Set<Id> documentIds) {
    return [
      SELECT Id, Document__c, Status__c, RevisionNo__c
      FROM CMN_DocumentRevision__c
      WHERE Document__c IN :documentIds
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 문서와 리비전.
   * @param documentId 문서
   * @return 문서(없으면 null)
   */
  public static CMN_Document__c documentWithRevisions(Id documentId) {
    List<CMN_Document__c> rows = [
      SELECT
        Id,
        DeliverableType__c,
        ParentRecordId__c,
        (
          SELECT Id, Status__c, RevisionNo__c
          FROM Revisions__r
          ORDER BY RevisionNo__c DESC
        )
      FROM CMN_Document__c
      WHERE Id = :documentId
      WITH SYSTEM_MODE
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * @description 리비전.
   * @param revisionIds 리비전
   * @return 리비전
   */
  public static List<CMN_DocumentRevision__c> revisionsById(
    Set<Id> revisionIds
  ) {
    return [
      SELECT Id, Document__c, Status__c, RevisionNo__c
      FROM CMN_DocumentRevision__c
      WHERE Id IN :revisionIds
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 문서들의 RELEASED 리비전.
   * @param documentIds 문서
   * @return 리비전
   */
  public static List<CMN_DocumentRevision__c> releasedOf(Set<Id> documentIds) {
    return [
      SELECT Id, Document__c
      FROM CMN_DocumentRevision__c
      WHERE Document__c IN :documentIds AND Status__c = 'RELEASED'
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 같은 체크섬의 다른 부모 리비전(오래된 것부터, BR-5).
   * @param hashes 체크섬
   * @param parentId 제외할 부모
   * @return 리비전
   */
  public static List<CMN_DocumentRevision__c> revisionsWithHashes(
    Set<String> hashes,
    String parentId
  ) {
    return [
      SELECT Id, FileHash__c
      FROM CMN_DocumentRevision__c
      WHERE
        FileHash__c IN :hashes
        AND Document__r.ParentRecordId__c != :parentId
      WITH SYSTEM_MODE
      ORDER BY CreatedDate, Id
    ];
  }

  /**
   * @description 파일 최신 버전(사용자가 볼 수 있는 파일만).
   * @param contentDocumentIds 파일
   * @return 최신 버전
   */
  public static List<ContentVersion> latestVersions(
    Set<Id> contentDocumentIds
  ) {
    return [
      SELECT Id, ContentDocumentId, Title, PathOnClient, ContentSize, Checksum
      FROM ContentVersion
      WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = TRUE
      WITH USER_MODE
    ];
  }

  /**
   * @description 공개·대체된 리비전이 쓰는 파일(BR-2 파일 교체·삭제 차단).
   * @param contentDocumentIds 파일
   * @return 잠긴 파일 Id
   */
  public static Set<String> lockedFiles(Set<String> contentDocumentIds) {
    Set<String> out = new Set<String>();
    for (CMN_DocumentRevision__c r : [
      SELECT ContentDocumentId__c
      FROM CMN_DocumentRevision__c
      WHERE
        ContentDocumentId__c IN :contentDocumentIds
        AND Status__c IN ('RELEASED', 'SUPERSEDED', 'IN_APPROVAL')
      WITH SYSTEM_MODE
    ]) {
      out.add(r.ContentDocumentId__c);
    }
    return out;
  }

  /**
   * @description 분류들의 사용 중 양식(버전 최신순).
   * @param docClassIds 분류
   * @return 양식
   */
  public static List<CMN_DocTemplate__c> templates(Set<Id> docClassIds) {
    return [
      SELECT
        Id,
        Name,
        DocClass__c,
        Language__c,
        ContentDocumentId__c,
        Version__c
      FROM CMN_DocTemplate__c
      WHERE DocClass__c IN :docClassIds AND IsActive__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Version__c DESC NULLS LAST
    ];
  }
}
