/**
 * @description cmnDocumentPanel 진입점(CMN-00-DOC-001). 부모 레코드를 읽을 수 없으면 빈 패널을 준다(BR-6).
 * 분류별 문서·현재 리비전·이력, 필수 분류 누락, 양식(사용자 언어 → en_US → ko), 등록·링크·결재 상신.
 * @group CMN-00-DOC-001
 */
public with sharing class CMN_DocumentController {
  /** 이번 요청에서 사용자가 읽을 수 있는 중복 원본 부모 */
  private static Set<Id> readableDuplicates = new Set<Id>();
  private static final Pattern CODE_LIST = Pattern.compile(
    '^[A-Za-z0-9_, ]{0,2000}$'
  );

  /** @description 패널 데이터. */
  public class Panel {
    @AuraEnabled
    public Boolean canRead = false;
    @AuraEnabled
    public Boolean canEdit = false;
    @AuraEnabled
    public Integer maxFileMb;
    @AuraEnabled
    public List<ClassGroup> classes = new List<ClassGroup>();
  }

  /** @description 업로드 등록 응답. 크기 초과는 예외 대신 error로 돌려준다(예외는 초과 파일 삭제까지 되돌린다). */
  public class Registration {
    @AuraEnabled
    public List<CMN_DocumentService.Result> results = new List<CMN_DocumentService.Result>();
    @AuraEnabled
    public String error;
  }

  /** @description 문서 분류 하나. */
  public class ClassGroup {
    @AuraEnabled
    public Id classId;
    @AuraEnabled
    public String code;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Boolean required = false;
    @AuraEnabled
    public Boolean missing = false;
    @AuraEnabled
    public Boolean linkOnly = false;
    @AuraEnabled
    public Boolean multiFile = false;
    @AuraEnabled
    public String templateDocumentId;
    @AuraEnabled
    public List<Doc> documents = new List<Doc>();
  }

  /** @description 문서 하나. */
  public class Doc {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String deliverableType;
    @AuraEnabled
    public Boolean supplierVisible;
    @AuraEnabled
    public Boolean canSubmit = false;
    @AuraEnabled
    public Rev current;
    @AuraEnabled
    public List<Rev> revisions = new List<Rev>();
  }

  /** @description 리비전 하나. */
  public class Rev {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public Integer revisionNo;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String statusLabel;
    @AuraEnabled
    public String storageType;
    @AuraEnabled
    public String fileName;
    @AuraEnabled
    public Decimal fileSize;
    @AuraEnabled
    public String contentDocumentId;
    @AuraEnabled
    public String url;
    @AuraEnabled
    public String externalRef;
    @AuraEnabled
    public Boolean duplicate;
    @AuraEnabled
    public String duplicateParentId;
    @AuraEnabled
    public String duplicateParentObject;
    @AuraEnabled
    public String changeNote;
    @AuraEnabled
    public Datetime releasedAt;
    @AuraEnabled
    public String createdByName;
    @AuraEnabled
    public Datetime createdDate;
  }

  /**
   * @description 패널 데이터.
   * @param parentId 부모 레코드
   * @param allowedDocClasses 허용 분류 코드(쉼표, 비우면 전체)
   * @param requiredDocClasses 필수 분류 코드(쉼표)
   * @return 패널
   * @throws AuraHandledException 잘못된 입력
   */
  @AuraEnabled
  public static Panel getPanel(
    Id parentId,
    String allowedDocClasses,
    String requiredDocClasses
  ) {
    try {
      if (
        parentId == null ||
        !CODE_LIST.matcher(allowedDocClasses ?? '').matches() ||
        !CODE_LIST.matcher(requiredDocClasses ?? '').matches()
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      Panel p = new Panel();
      p.maxFileMb = CMN_Settings.getInteger('CMN_DOC_MAX_FILE_MB', 50);
      if (
        !CMN_CommentService.readableParents(new Set<Id>{ parentId })
          .contains(parentId)
      ) {
        return p;
      }
      p.canRead = true;
      p.canEdit = CMN_DocumentSelector.editableParents(new Set<Id>{ parentId })
        .contains(parentId);
      Set<String> allowed = codes(allowedDocClasses);
      Set<String> required = codes(requiredDocClasses);
      Set<String> wanted = new Set<String>(allowed);
      if (!allowed.isEmpty()) {
        wanted.addAll(required);
      }
      List<CMN_Code__c> classes = CMN_DocumentSelector.docClasses(wanted);
      Map<Id, List<CMN_Document__c>> docsByClass = new Map<Id, List<CMN_Document__c>>();
      // 포털(협력사) 사용자에게는 협력사 공개 문서만(검토 반영 Vol.3 BR-4)
      Boolean portal = UserInfo.getUserType() != 'Standard';
      List<CMN_Document__c> parentDocs = new List<CMN_Document__c>();
      Set<Id> dupParents = new Set<Id>();
      for (
        CMN_Document__c d : CMN_DocumentSelector.documentsOf(parentId, null)
      ) {
        if (portal && !d.SupplierVisible__c) {
          continue;
        }
        parentDocs.add(d);
        for (CMN_DocumentRevision__c r : d.Revisions__r) {
          String dup = r.DuplicateOfRevision__r?.Document__r?.ParentRecordId__c;
          if (dup != null) {
            dupParents.add(Id.valueOf(dup));
          }
        }
      }
      // 중복 원본 레코드는 사용자가 볼 수 있을 때만 알려 준다
      readableDuplicates = CMN_CommentService.readableParents(dupParents);
      for (CMN_Document__c d : parentDocs) {
        if (!docsByClass.containsKey(d.DocClass__c)) {
          docsByClass.put(d.DocClass__c, new List<CMN_Document__c>());
        }
        docsByClass.get(d.DocClass__c).add(d);
      }
      Set<Id> classIds = new Set<Id>();
      for (CMN_Code__c c : classes) {
        classIds.add(c.Id);
      }
      Map<Id, CMN_DocTemplate__c> templates = CMN_DocumentService.templatesFor(
        classIds,
        UserInfo.getLanguage()
      );
      Map<String, String> statusLabels = statusLabels();
      for (CMN_Code__c c : classes) {
        ClassGroup g = new ClassGroup();
        g.classId = c.Id;
        g.code = c.Code__c;
        g.label = localized(c);
        g.required = required.contains(c.Code__c);
        g.linkOnly = c.Attribute1__c == CMN_DocumentService.LINK_ONLY;
        g.multiFile = c.Attribute2__c == CMN_DocumentService.MULTI_FILE;
        g.templateDocumentId = templates.get(c.Id)?.ContentDocumentId__c;
        Boolean released = false;
        for (
          CMN_Document__c d : docsByClass.get(c.Id) ??
            new List<CMN_Document__c>()
        ) {
          Doc doc = toDoc(d, statusLabels, p.canEdit);
          released = released || doc.current != null;
          g.documents.add(doc);
        }
        g.missing = g.required && !released;
        p.classes.add(g);
      }
      return p;
    } catch (Exception e) {
      throw toAura(e, 'CMN_DocumentController.getPanel');
    }
  }

  /**
   * @description 업로드한 파일을 문서 리비전으로 등록한다.
   * @param parentId 부모 레코드
   * @param docClassId 분류
   * @param contentDocumentIds 업로드한 파일
   * @param changeNote 변경 사유
   * @param supplierVisible 협력사 공개
   * @return 결과(크기 초과면 error만)
   * @throws AuraHandledException 검증 오류
   */
  @AuraEnabled
  public static Registration registerFiles(
    Id parentId,
    Id docClassId,
    List<Id> contentDocumentIds,
    String changeNote,
    Boolean supplierVisible
  ) {
    try {
      for (Id i : contentDocumentIds ?? new List<Id>()) {
        if (i == null || i.getSObjectType() != ContentDocument.SObjectType) {
          throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
        }
      }
      Registration r = new Registration();
      r.error = CMN_DocumentService.rejectOversized(
        contentDocumentIds ?? new List<Id>()
      );
      if (r.error != null) {
        return r;
      }
      r.results = CMN_DocumentService.registerFiles(
        parentId,
        docClassId,
        contentDocumentIds,
        changeNote,
        supplierVisible
      );
      return r;
    } catch (Exception e) {
      throw toAura(e, 'CMN_DocumentController.registerFiles');
    }
  }

  /**
   * @description 외부 링크를 문서 리비전으로 등록한다.
   * @param parentId 부모 레코드
   * @param docClassId 분류
   * @param storageType 저장소
   * @param url 링크
   * @param externalRef 외부 문서 번호
   * @param title 표시 이름
   * @param changeNote 변경 사유
   * @return 결과
   * @throws AuraHandledException 검증 오류
   */
  @AuraEnabled
  public static CMN_DocumentService.Result registerLink(
    Id parentId,
    Id docClassId,
    String storageType,
    String url,
    String externalRef,
    String title,
    String changeNote
  ) {
    try {
      return CMN_DocumentService.registerLink(
        parentId,
        docClassId,
        storageType,
        url,
        externalRef,
        title,
        changeNote
      );
    } catch (Exception e) {
      throw toAura(e, 'CMN_DocumentController.registerLink');
    }
  }

  /**
   * @description 결재형 문서를 결재선 템플릿으로 상신한다(편집은 결재 화면 APV-003).
   * @param documentId 문서
   * @param comment 상신 의견
   * @return 결재 요청 Id
   * @throws AuraHandledException 템플릿 없음, 상신 불가
   */
  @AuraEnabled
  public static Id submitDocument(Id documentId, String comment) {
    try {
      if (
        documentId == null ||
        documentId.getSObjectType() != CMN_Document__c.SObjectType
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      List<CMN_ApprovalStepSpec> line = CMN_ApprovalLineResolver.resolve(
        documentId,
        CMN_DocumentService.RELEASE_TYPE
      );
      if (line.isEmpty()) {
        throw new CMN_ValidationException(Label.CMN_Doc_NoApprovalLine);
      }
      return CMN_DocumentService.submitForApproval(
        documentId,
        null,
        line,
        comment
      );
    } catch (Exception e) {
      throw toAura(e, 'CMN_DocumentController.submitDocument');
    }
  }

  // ------------------------------------------------------------------ 내부
  private static Doc toDoc(
    CMN_Document__c d,
    Map<String, String> statusLabels,
    Boolean canEdit
  ) {
    Doc doc = new Doc();
    doc.id = d.Id;
    doc.name = d.Name;
    doc.deliverableType = d.DeliverableType__c;
    doc.supplierVisible = d.SupplierVisible__c;
    for (CMN_DocumentRevision__c r : d.Revisions__r) {
      Rev rev = new Rev();
      rev.id = r.Id;
      rev.revisionNo = r.RevisionNo__c?.intValue();
      rev.status = r.Status__c;
      rev.statusLabel = statusLabels.get(r.Status__c) ?? r.Status__c;
      rev.storageType = r.StorageType__c;
      rev.fileName = r.FileName__c;
      rev.fileSize = r.FileSize__c;
      rev.contentDocumentId = r.ContentDocumentId__c;
      // 링크는 https만 내보낸다(javascript: 등 저장형 XSS 방지)
      rev.url = r.ExternalUrl__c?.startsWithIgnoreCase('https://') == true
        ? r.ExternalUrl__c
        : null;
      rev.externalRef = r.ExternalRef__c;
      rev.duplicate = r.IsDuplicateFile__c;
      String dupParent = r.DuplicateOfRevision__r
        ?.Document__r
        ?.ParentRecordId__c;
      if (
        dupParent != null && readableDuplicates.contains(Id.valueOf(dupParent))
      ) {
        rev.duplicateParentId = dupParent;
        rev.duplicateParentObject = r.DuplicateOfRevision__r
          ?.Document__r
          ?.ParentObject__c;
      }
      rev.changeNote = r.ChangeNote__c;
      rev.releasedAt = r.ReleasedAt__c;
      rev.createdByName = r.CreatedBy?.Name;
      rev.createdDate = r.CreatedDate;
      doc.revisions.add(rev);
      if (r.Id == d.CurrentRevision__c) {
        doc.current = rev;
      }
      if (
        canEdit &&
        d.DeliverableType__c == 'APPROVAL' &&
        r.Status__c == CMN_DocumentService.DRAFT
      ) {
        doc.canSubmit = true;
      }
    }
    return doc;
  }

  private static Map<String, String> statusLabels() {
    Map<String, String> out = new Map<String, String>();
    for (
      Schema.PicklistEntry e : CMN_DocumentRevision__c.Status__c.getDescribe()
        .getPicklistValues()
    ) {
      out.put(e.getValue(), e.getLabel());
    }
    return out;
  }

  /** I18N-001 BR-3 규칙: ko → 이름, zh → 중문·영문·이름, 그 외 → 영문·이름. */
  private static String localized(CMN_Code__c c) {
    String prefix = UserInfo.getLanguage()?.left(2);
    if (prefix == 'ko') {
      return c.Name;
    }
    if (prefix == 'zh' && String.isNotBlank(c.NameZh__c)) {
      return c.NameZh__c;
    }
    return String.isBlank(c.NameEn__c) ? c.Name : c.NameEn__c;
  }

  private static Set<String> codes(String value) {
    Set<String> out = new Set<String>();
    for (String s : (value ?? '').split(',')) {
      if (String.isNotBlank(s)) {
        out.add(s.trim());
      }
    }
    return out;
  }

  private static AuraHandledException toAura(Exception e, String source) {
    String message;
    if (e instanceof CMN_ValidationException) {
      message = e.getMessage();
    } else if (
      e instanceof DmlException &&
      ((DmlException) e).getDmlType(0) ==
      StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION
    ) {
      message = ((DmlException) e).getDmlMessage(0);
    } else {
      CMN_Logger.error(source, e.getMessage(), null, e);
      message = Label.CMN_Common_UnexpectedError;
    }
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
