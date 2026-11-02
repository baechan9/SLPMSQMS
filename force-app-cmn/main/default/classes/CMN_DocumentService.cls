/**
 * @description 문서·리비전 업무 규칙(CMN-00-DOC-001). 업무 WI는 이 서비스로 문서를 등록한다(sf-dev 공통 서비스).
 * - 문서 단위(BR-1): 같은 부모·같은 DocClass = 한 문서. DocClass Attribute2__c = MULTI_FILE(사진 등)이면 파일명까지 같아야 같은 문서.
 *   다시 올리면 새 리비전(RevisionNo + 1).
 * - 공개(BR-2·BR-3): DeliverableType = APPROVAL이면 DRAFT로 두고 결재(CMN_DOC_RELEASE 또는 업무 지정 유형) 승인 콜백에서 RELEASED,
 *   그 밖은 등록 즉시 RELEASED. 새 RELEASED가 나오면 이전 RELEASED는 SUPERSEDED, 문서의 CurrentRevision을 바꾼다.
 * - 크기(BR-4): Salesforce 파일은 CMN_DOC_MAX_FILE_MB(기본 50) 이하. 넘으면 올린 파일을 지우고 외부 링크 등록을 안내한다.
 *   DocClass Attribute1__c = LINK_ONLY(도면 등)는 링크만 허용.
 * - 중복(BR-5): 플랫폼 체크섬이 같은 파일이 다른 부모의 리비전에 있으면 경고 표시와 원본 리비전을 남긴다(차단하지 않음).
 * - 파일 공개: 문서에 파일을 연결(ShareType I = 문서 접근을 따름). 협력사 공개 문서는 Visibility AllUsers(검토 반영 Vol.3).
 * - 권한: 등록은 부모 레코드 편집 권한이 있는 사용자만. 검증을 마친 뒤 문서·리비전·파일 연결은 CMN_DocumentWriter가 저장한다
 *   (상태·번호·해시는 사용자 FLS가 읽기이고, 다른 사람이 만든 문서에도 리비전을 더해야 한다).
 * - 산출물 유형: DocClass Attribute3__c(ATTACHMENT·STD_FORM·LINK·APPROVAL·SYSTEM_LINK, 비우면 ATTACHMENT).
 * @group CMN-00-DOC-001
 */
public with sharing class CMN_DocumentService {
  public static final String CLASS_GROUP = 'DOC_CLASS';
  public static final String RELEASE_TYPE = 'CMN_DOC_RELEASE';
  public static final String DRAFT = 'DRAFT';
  public static final String IN_APPROVAL = 'IN_APPROVAL';
  public static final String RELEASED = 'RELEASED';
  public static final String SUPERSEDED = 'SUPERSEDED';
  public static final String REJECTED = 'REJECTED';
  public static final String LINK_ONLY = 'LINK_ONLY';
  public static final String MULTI_FILE = 'MULTI_FILE';
  private static final Set<String> LINK_STORAGE = new Set<String>{
    'SHAREPOINT',
    'PDM',
    'DMS',
    'URL',
    'SF_RECORD'
  };
  private static final Long MB = 1024 * 1024;

  /** @description 등록 결과. */
  public class Result {
    @AuraEnabled
    public Id documentId;
    @AuraEnabled
    public Id revisionId;
    @AuraEnabled
    public Integer revisionNo;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Boolean duplicate = false;
  }

  /**
   * @description 업로드한 Salesforce 파일을 부모 레코드의 문서 리비전으로 등록한다.
   * @param parentId 부모 업무 레코드
   * @param docClassId DOC_CLASS 코드
   * @param contentDocumentIds 업로드한 파일(사용자 개인 파일)
   * @param changeNote 변경 사유
   * @param supplierVisible 협력사 공개
   * @return 파일별 결과
   * @throws CMN_ValidationException 부모 접근 없음, 분류 오류, 링크 전용, 크기 초과, 결재 중, 단일 문서 분류에 여러 파일
   */
  public static List<Result> registerFiles(
    Id parentId,
    Id docClassId,
    List<Id> contentDocumentIds,
    String changeNote,
    Boolean supplierVisible
  ) {
    CMN_Code__c docClass = checkTarget(parentId, docClassId);
    if (docClass.Attribute1__c == LINK_ONLY) {
      throw new CMN_ValidationException(Label.CMN_Doc_LinkOnly);
    }
    if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    Boolean multi = docClass.Attribute2__c == MULTI_FILE;
    if (!multi && contentDocumentIds.size() > 1) {
      throw new CMN_ValidationException(Label.CMN_Doc_OneFileOnly);
    }
    List<ContentVersion> files = CMN_DocumentSelector.latestVersions(
      new Set<Id>(contentDocumentIds)
    );
    if (files.size() != new Set<Id>(contentDocumentIds).size()) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    String sizeError = sizeError(oversized(files));
    if (sizeError != null) {
      // 파일 삭제는 예외로 되돌려지므로 호출 측이 먼저 rejectOversized로 지운다(CMN_DocumentController)
      throw new CMN_ValidationException(sizeError);
    }

    List<Result> out = new List<Result>();
    List<CMN_DocumentRevision__c> revisions = new List<CMN_DocumentRevision__c>();
    Map<String, CMN_Document__c> docs = documentsFor(
      parentId,
      docClass,
      files,
      supplierVisible
    );
    Map<Id, Integer> lastNo = new Map<Id, Integer>();
    for (ContentVersion v : files) {
      CMN_Document__c doc = docs.get(
        keyOf(docClass, v.PathOnClient ?? v.Title, multi)
      );
      CMN_DocumentRevision__c r = newRevision(doc, changeNote, lastNo);
      r.StorageType__c = 'SF_FILE';
      r.ContentDocumentId__c = v.ContentDocumentId;
      r.FileName__c = (v.PathOnClient ?? v.Title)?.left(255);
      r.FileSize__c = v.ContentSize;
      r.FileHash__c = v.Checksum;
      revisions.add(r);
    }
    markDuplicates(revisions, parentId);
    CMN_DocumentWriter.save(revisions);
    linkFiles(revisions, supplierVisible == true);
    afterRegister(docs, revisions, out);
    return out;
  }

  /**
   * @description 외부 저장소 링크를 문서 리비전으로 등록한다(대용량·도면·외부 문서 번호).
   * @param parentId 부모 업무 레코드
   * @param docClassId DOC_CLASS 코드
   * @param storageType SHAREPOINT, PDM, DMS, URL, SF_RECORD
   * @param url 링크(https)
   * @param externalRef 외부 문서 번호(도면 번호 등)
   * @param title 표시 이름
   * @param changeNote 변경 사유
   * @return 결과
   * @throws CMN_ValidationException 부모 접근 없음, 분류 오류, 저장소·링크 오류, 결재 중
   */
  public static Result registerLink(
    Id parentId,
    Id docClassId,
    String storageType,
    String url,
    String externalRef,
    String title,
    String changeNote
  ) {
    CMN_Code__c docClass = checkTarget(parentId, docClassId);
    if (
      !LINK_STORAGE.contains(storageType) ||
      (String.isBlank(url) && String.isBlank(externalRef)) ||
      (String.isNotBlank(url) && !url.startsWithIgnoreCase('https://'))
    ) {
      throw new CMN_ValidationException(Label.CMN_Doc_InvalidLink);
    }
    String name = String.isBlank(title) ? (externalRef ?? url) : title;
    Map<String, CMN_Document__c> docs = documentsFor(
      parentId,
      docClass,
      new List<ContentVersion>{ new ContentVersion(PathOnClient = name) },
      false
    );
    CMN_Document__c doc = docs.get(
      keyOf(docClass, name, docClass.Attribute2__c == MULTI_FILE)
    );
    CMN_DocumentRevision__c r = newRevision(
      doc,
      changeNote,
      new Map<Id, Integer>()
    );
    r.StorageType__c = storageType;
    r.ExternalUrl__c = url?.left(255);
    r.ExternalRef__c = externalRef?.left(255);
    r.FileName__c = name?.left(255);
    CMN_DocumentWriter.save(new List<SObject>{ r });
    List<Result> out = new List<Result>();
    afterRegister(docs, new List<CMN_DocumentRevision__c>{ r }, out);
    return out[0];
  }

  /**
   * @description 결재형 문서의 DRAFT 리비전을 결재 상신한다(BR-3). 상태 전이는 CMN_DocumentApprovalCallback이 한다.
   * @param documentId 문서
   * @param typeCode 결재 유형(비우면 CMN_DOC_RELEASE)
   * @param steps 결재선
   * @param comment 상신 의견
   * @return 결재 요청 Id
   * @throws CMN_ValidationException 결재형 문서가 아니거나 DRAFT 리비전이 없음
   */
  public static Id submitForApproval(
    Id documentId,
    String typeCode,
    List<CMN_ApprovalStepSpec> steps,
    String comment
  ) {
    CMN_Document__c doc = CMN_DocumentSelector.documentWithRevisions(
      documentId
    );
    if (doc == null || doc.DeliverableType__c != 'APPROVAL') {
      throw new CMN_ValidationException(Label.CMN_Doc_NotApprovalType);
    }
    Id parentId = Id.valueOf(doc.ParentRecordId__c);
    if (
      !CMN_DocumentSelector.editableParents(new Set<Id>{ parentId })
        .contains(parentId)
    ) {
      throw new CMN_ValidationException(Label.CMN_Doc_NoAccess);
    }
    return CMN_ApprovalService.submit(
      documentId,
      String.isBlank(typeCode) ? RELEASE_TYPE : typeCode,
      steps,
      comment
    );
  }

  /**
   * @description 리비전을 공개한다(RELEASED). 같은 문서의 이전 RELEASED는 SUPERSEDED, 문서 CurrentRevision 갱신.
   * @param revisionIds 공개할 리비전(문서당 1건)
   */
  public static void release(Set<Id> revisionIds) {
    // 문서마다 번호가 가장 높은 리비전만 공개하고, 같이 넘어온 낮은 번호는 대체한다
    Map<Id, CMN_DocumentRevision__c> latest = new Map<Id, CMN_DocumentRevision__c>();
    for (
      CMN_DocumentRevision__c r : CMN_DocumentSelector.revisionsById(
        revisionIds
      )
    ) {
      CMN_DocumentRevision__c cur = latest.get(r.Document__c);
      if (cur == null || r.RevisionNo__c > cur.RevisionNo__c) {
        latest.put(r.Document__c, r);
      }
    }
    Set<Id> releasing = new Set<Id>();
    for (CMN_DocumentRevision__c r : latest.values()) {
      releasing.add(r.Id);
    }
    List<SObject> updates = new List<SObject>();
    for (Id i : revisionIds) {
      if (!releasing.contains(i)) {
        updates.add(
          new CMN_DocumentRevision__c(Id = i, Status__c = SUPERSEDED)
        );
      }
    }
    for (
      CMN_DocumentRevision__c old : CMN_DocumentSelector.releasedOf(
        latest.keySet()
      )
    ) {
      if (!revisionIds.contains(old.Id)) {
        updates.add(
          new CMN_DocumentRevision__c(Id = old.Id, Status__c = SUPERSEDED)
        );
      }
    }
    List<CMN_Document__c> docs = new List<CMN_Document__c>();
    for (CMN_DocumentRevision__c r : latest.values()) {
      updates.add(
        new CMN_DocumentRevision__c(
          Id = r.Id,
          Status__c = RELEASED,
          ReleasedAt__c = Datetime.now()
        )
      );
      docs.add(
        new CMN_Document__c(Id = r.Document__c, CurrentRevision__c = r.Id)
      );
    }
    // 상태·현재 리비전은 사용자 FLS가 읽기라 서비스가 시스템 모드로 쓴다(검증은 위에서 끝남)
    CMN_DocumentWriter.save(updates);
    CMN_DocumentWriter.save(docs);
  }

  /**
   * @description 문서의 결재 중(또는 작성 중) 리비전 상태를 바꾼다(결재 콜백용).
   * @param documentId 문서
   * @param fromStatuses 바꿀 대상 상태
   * @param toStatus 새 상태
   * @return 바뀐 리비전 Id
   */
  public static Set<Id> moveRevisions(
    Id documentId,
    Set<String> fromStatuses,
    String toStatus
  ) {
    Set<Id> moved = new Set<Id>();
    List<SObject> updates = new List<SObject>();
    for (
      CMN_DocumentRevision__c r : CMN_DocumentSelector.documentWithRevisions(
          documentId
        )
        ?.Revisions__r ?? new List<CMN_DocumentRevision__c>()
    ) {
      if (fromStatuses.contains(r.Status__c)) {
        moved.add(r.Id);
        updates.add(
          new CMN_DocumentRevision__c(Id = r.Id, Status__c = toStatus)
        );
      }
    }
    CMN_DocumentWriter.save(updates);
    return moved;
  }

  /**
   * @description 표준 양식(BR-7): 사용자 언어 → en_US → ko. 같은 언어는 버전이 높은 것.
   * @param docClassId DOC_CLASS 코드
   * @param language 사용자 언어
   * @return 양식(없으면 null)
   */
  public static CMN_DocTemplate__c templateFor(Id docClassId, String language) {
    return templatesFor(new Set<Id>{ docClassId }, language).get(docClassId);
  }

  /**
   * @description 분류별 표준 양식(SOQL 1회).
   * @param docClassIds DOC_CLASS 코드
   * @param language 사용자 언어
   * @return 분류 Id → 양식
   */
  public static Map<Id, CMN_DocTemplate__c> templatesFor(
    Set<Id> docClassIds,
    String language
  ) {
    Map<Id, Map<String, CMN_DocTemplate__c>> byClass = new Map<Id, Map<String, CMN_DocTemplate__c>>();
    for (CMN_DocTemplate__c t : CMN_DocumentSelector.templates(docClassIds)) {
      if (!byClass.containsKey(t.DocClass__c)) {
        byClass.put(t.DocClass__c, new Map<String, CMN_DocTemplate__c>());
      }
      Map<String, CMN_DocTemplate__c> byLanguage = byClass.get(t.DocClass__c);
      if (!byLanguage.containsKey(t.Language__c)) {
        byLanguage.put(t.Language__c, t);
      }
    }
    Map<Id, CMN_DocTemplate__c> out = new Map<Id, CMN_DocTemplate__c>();
    for (Id classId : byClass.keySet()) {
      Map<String, CMN_DocTemplate__c> byLanguage = byClass.get(classId);
      CMN_DocTemplate__c t = byLanguage.get(language) ??
        byLanguage.get('en_US') ?? byLanguage.get('ko');
      if (t != null) {
        out.put(classId, t);
      }
    }
    return out;
  }

  /**
   * @description 크기 한도(BR-4)를 넘은 업로드 파일을 지운다. 등록 전에 호출 측(화면 컨트롤러)이 부르고, 오류 문구를
   * 예외가 아니라 반환값으로 받아야 삭제가 유지된다(예외는 트랜잭션 전체를 되돌린다).
   * @param contentDocumentIds 업로드한 파일
   * @return 크기 초과 안내 문구(넘은 파일이 없으면 null)
   */
  public static String rejectOversized(List<Id> contentDocumentIds) {
    return discard(
      CMN_DocumentSelector.latestVersions(new Set<Id>(contentDocumentIds))
    );
  }

  @TestVisible
  private static String discard(List<ContentVersion> files) {
    List<ContentDocument> over = oversized(files);
    if (!over.isEmpty()) {
      // 사용자가 방금 올린 개인 파일만 지운다(문서에 연결되기 전)
      Database.delete(over, AccessLevel.USER_MODE);
    }
    return sizeError(over);
  }

  private static List<ContentDocument> oversized(List<ContentVersion> files) {
    Integer maxMb = CMN_Settings.getInteger('CMN_DOC_MAX_FILE_MB', 50);
    List<ContentDocument> out = new List<ContentDocument>();
    for (ContentVersion v : files) {
      if (tooLarge(v.ContentSize, maxMb)) {
        out.add(new ContentDocument(Id = v.ContentDocumentId));
      }
    }
    return out;
  }

  private static String sizeError(List<ContentDocument> over) {
    return over.isEmpty()
      ? null
      : String.format(
          Label.CMN_Doc_TooLarge,
          new List<Object>{
            String.valueOf(CMN_Settings.getInteger('CMN_DOC_MAX_FILE_MB', 50))
          }
        );
  }

  /**
   * @description 크기 판정(AC-3: 60MB > 50MB).
   * @param bytes 파일 크기
   * @param maxMb 한도(MB)
   * @return 한도 초과
   */
  public static Boolean tooLarge(Long bytes, Integer maxMb) {
    return bytes != null && bytes > maxMb * MB;
  }

  // ------------------------------------------------------------------ 내부
  private static CMN_Code__c checkTarget(Id parentId, Id docClassId) {
    if (parentId == null || docClassId == null) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
    if (
      !CMN_DocumentSelector.editableParents(new Set<Id>{ parentId })
        .contains(parentId)
    ) {
      throw new CMN_ValidationException(Label.CMN_Doc_NoAccess);
    }
    CMN_Code__c c = CMN_DocumentSelector.docClass(docClassId);
    if (
      c == null ||
      c.CodeGroup__r.GroupCode__c != CLASS_GROUP ||
      !c.IsActive__c
    ) {
      throw new CMN_ValidationException(Label.CMN_Doc_InvalidClass);
    }
    return c;
  }

  private static String keyOf(
    CMN_Code__c docClass,
    String fileName,
    Boolean multi
  ) {
    return docClass.Id + (multi ? '|' + (fileName ?? '').toLowerCase() : '');
  }

  /** 같은 부모·분류(·파일명) 문서를 찾고 없으면 만든다. 결재 중인 문서에는 새 리비전을 올릴 수 없다. */
  private static Map<String, CMN_Document__c> documentsFor(
    Id parentId,
    CMN_Code__c docClass,
    List<ContentVersion> files,
    Boolean supplierVisible
  ) {
    Boolean multi = docClass.Attribute2__c == MULTI_FILE;
    Map<String, CMN_Document__c> out = new Map<String, CMN_Document__c>();
    for (
      CMN_Document__c d : CMN_DocumentSelector.documentsOf(
        parentId,
        docClass.Id
      )
    ) {
      String fileName = d.Revisions__r.isEmpty()
        ? d.Name
        : d.Revisions__r[0].FileName__c;
      String key = keyOf(docClass, multi ? fileName : null, multi);
      if (!out.containsKey(key)) {
        out.put(key, d);
      }
    }
    Map<String, Object> parent = parentValues(parentId);
    List<CMN_Document__c> created = new List<CMN_Document__c>();
    for (ContentVersion v : files) {
      String fileName = v.PathOnClient ?? v.Title;
      String key = keyOf(docClass, fileName, multi);
      CMN_Document__c d = out.get(key);
      if (d != null) {
        for (CMN_DocumentRevision__c r : d.Revisions__r) {
          if (r.Status__c == IN_APPROVAL) {
            throw new CMN_ValidationException(Label.CMN_Doc_InApproval);
          }
        }
        continue;
      }
      d = new CMN_Document__c(
        Name = (multi ? fileName : docClass.Name)?.left(80),
        ParentRecordId__c = parentId,
        DocClass__c = docClass.Id,
        DeliverableType__c = docClass.Attribute3__c ?? 'ATTACHMENT',
        Plant__c = (Id) parent.get('Plant__c'),
        Supplier__c = (Id) parent.get('Supplier__c'),
        SupplierVisible__c = supplierVisible == true
      );
      out.put(key, d);
      created.add(d);
    }
    CMN_DocumentWriter.save(created);
    return out;
  }

  /** 다음 리비전 번호. 같은 요청에서 같은 문서에 여러 파일이 오면(MULTI_FILE 같은 이름) 이어서 매긴다. */
  private static CMN_DocumentRevision__c newRevision(
    CMN_Document__c doc,
    String changeNote,
    Map<Id, Integer> lastNo
  ) {
    Integer last = lastNo.get(doc.Id);
    if (last == null) {
      last = 0;
      for (
        CMN_DocumentRevision__c r : doc.Revisions__r ??
          new List<CMN_DocumentRevision__c>()
      ) {
        last = Math.max(last, r.RevisionNo__c?.intValue() ?? 0);
      }
    }
    lastNo.put(doc.Id, last + 1);
    return new CMN_DocumentRevision__c(
      Document__c = doc.Id,
      Name = ('Rev.' + (last + 1)),
      RevisionNo__c = last + 1,
      Status__c = DRAFT,
      ChangeNote__c = changeNote?.left(1000)
    );
  }

  /** BR-5: 같은 체크섬이 다른 부모의 리비전에 있으면 경고(차단하지 않음). */
  private static void markDuplicates(
    List<CMN_DocumentRevision__c> revisions,
    Id parentId
  ) {
    Set<String> hashes = new Set<String>();
    for (CMN_DocumentRevision__c r : revisions) {
      if (String.isNotBlank(r.FileHash__c)) {
        hashes.add(r.FileHash__c);
      }
    }
    if (hashes.isEmpty()) {
      return;
    }
    Map<String, CMN_DocumentRevision__c> firstByHash = new Map<String, CMN_DocumentRevision__c>();
    for (
      CMN_DocumentRevision__c r : CMN_DocumentSelector.revisionsWithHashes(
        hashes,
        String.valueOf(parentId)
      )
    ) {
      if (!firstByHash.containsKey(r.FileHash__c)) {
        firstByHash.put(r.FileHash__c, r);
      }
    }
    for (CMN_DocumentRevision__c r : revisions) {
      CMN_DocumentRevision__c original = firstByHash.get(r.FileHash__c);
      if (original != null) {
        r.IsDuplicateFile__c = true;
        r.DuplicateOfRevision__c = original.Id;
      }
    }
  }

  /** 파일을 문서에 연결한다. 문서 접근을 따르고(I), 협력사 공개면 포털에도 보인다. */
  private static void linkFiles(
    List<CMN_DocumentRevision__c> revisions,
    Boolean supplierVisible
  ) {
    List<ContentDocumentLink> links = new List<ContentDocumentLink>();
    for (CMN_DocumentRevision__c r : revisions) {
      links.add(
        new ContentDocumentLink(
          ContentDocumentId = r.ContentDocumentId__c,
          LinkedEntityId = r.Document__c,
          ShareType = 'I',
          Visibility = supplierVisible ? 'AllUsers' : 'InternalUsers'
        )
      );
    }
    CMN_DocumentWriter.save(links);
  }

  /** 등록 후: 결재형이 아니면 바로 공개, 결과 채우기. */
  private static void afterRegister(
    Map<String, CMN_Document__c> docs,
    List<CMN_DocumentRevision__c> revisions,
    List<Result> out
  ) {
    Map<Id, CMN_Document__c> byId = new Map<Id, CMN_Document__c>();
    for (CMN_Document__c d : docs.values()) {
      byId.put(d.Id, d);
    }
    // 문서마다 새 리비전 중 가장 높은 번호만 남기고, 그보다 앞선 작성 중 리비전(이전 업로드·같은 요청의 낮은 번호)은 대체한다.
    // 결재형 문서에 작성 중 리비전이 둘 이상 남아 함께 결재되는 일을 막는다
    Map<Id, CMN_DocumentRevision__c> newest = new Map<Id, CMN_DocumentRevision__c>();
    for (CMN_DocumentRevision__c r : revisions) {
      CMN_DocumentRevision__c cur = newest.get(r.Document__c);
      if (cur == null || r.RevisionNo__c > cur.RevisionNo__c) {
        newest.put(r.Document__c, r);
      }
    }
    Set<Id> kept = new Set<Id>();
    for (CMN_DocumentRevision__c r : newest.values()) {
      kept.add(r.Id);
    }
    List<SObject> toSupersede = new List<SObject>();
    for (CMN_DocumentRevision__c r : revisions) {
      if (!kept.contains(r.Id)) {
        r.Status__c = SUPERSEDED;
        toSupersede.add(
          new CMN_DocumentRevision__c(Id = r.Id, Status__c = SUPERSEDED)
        );
      }
    }
    for (Id docId : newest.keySet()) {
      for (
        CMN_DocumentRevision__c old : byId.get(docId)?.Revisions__r ??
          new List<CMN_DocumentRevision__c>()
      ) {
        if (old.Status__c == DRAFT) {
          toSupersede.add(
            new CMN_DocumentRevision__c(Id = old.Id, Status__c = SUPERSEDED)
          );
        }
      }
    }
    CMN_DocumentWriter.save(toSupersede);
    Set<Id> toRelease = new Set<Id>();
    for (CMN_DocumentRevision__c r : newest.values()) {
      if (byId.get(r.Document__c).DeliverableType__c != 'APPROVAL') {
        toRelease.add(r.Id);
      }
    }
    if (!toRelease.isEmpty()) {
      release(toRelease);
    }
    for (CMN_DocumentRevision__c r : revisions) {
      Result res = new Result();
      res.documentId = r.Document__c;
      res.revisionId = r.Id;
      res.revisionNo = r.RevisionNo__c.intValue();
      res.status = toRelease.contains(r.Id)
        ? RELEASED
        : (kept.contains(r.Id) ? DRAFT : SUPERSEDED);
      res.duplicate = r.IsDuplicateFile__c;
      out.add(res);
    }
  }

  /** 부모의 공장·협력사(필드가 있을 때만). */
  private static Map<String, Object> parentValues(Id parentId) {
    Schema.SObjectType t = parentId.getSObjectType();
    Map<String, Schema.SObjectField> fields = t.getDescribe(
        SObjectDescribeOptions.DEFERRED
      )
      .fields.getMap();
    List<String> columns = new List<String>{ 'Id' };
    for (String f : new List<String>{ 'Plant__c', 'Supplier__c' }) {
      if (fields.containsKey(f.toLowerCase())) {
        columns.add(f);
      }
    }
    if (columns.size() == 1) {
      return new Map<String, Object>();
    }
    return Database.queryWithBinds(
        'SELECT ' +
          String.join(columns, ', ') +
          ' FROM ' +
          String.escapeSingleQuotes(String.valueOf(t)) +
          ' WHERE Id = :id',
        new Map<String, Object>{ 'id' => parentId },
        AccessLevel.SYSTEM_MODE
      )[0]
      .getPopulatedFieldsAsMap();
  }
}
