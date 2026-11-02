/**
 * @description 문서·리비전 관리 검증(CMN-00-DOC-001). 부모는 테스트 대상 객체(CR-11·DEV-3).
 * @group CMN-00-DOC-001
 */
@IsTest
private class CMN_DocumentService_Test {
  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    CMN_Plant__c p = new CMN_Plant__c(
      Name = 'KR01',
      PlantCode__c = 'KR01',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
    insert p;
    CMN_CodeGroup__c g = new CMN_CodeGroup__c(
      Name = 'DOC_CLASS',
      GroupCode__c = 'DOC_CLASS',
      MaxLevel__c = 2
    );
    insert g;
    insert new List<CMN_Code__c>{
      code(g.Id, '8D_REPORT', null, null, null),
      code(g.Id, 'NCR_PHOTO', null, 'MULTI_FILE', null),
      code(g.Id, 'DRAWING', 'LINK_ONLY', null, null),
      code(g.Id, 'PPAP_PSW', null, null, 'APPROVAL')
    };
    insert new List<CMN_TestRecord__c>{
      new CMN_TestRecord__c(
        Name = 'ncr-1',
        Plant__c = p.Id,
        Status__c = 'DRAFT'
      ),
      new CMN_TestRecord__c(
        Name = 'ncr-2',
        Plant__c = p.Id,
        Status__c = 'DRAFT'
      )
    };
    User u = CMN_TestDataFactory.newUser(
      'docapv',
      'docapv',
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert u;
    }
  }

  @IsTest
  static void test_AC01_sameClassUploadCreatesNextRevisionAndSupersedes() {
    // Given: NCR에 8D_REPORT Rev1 RELEASED
    Id ncr = parent('ncr-1');
    CMN_DocumentService.Result r1 = upload(ncr, 'D8', 'report-v1.pdf', 'v1')[0];
    Assert.areEqual(1, r1.revisionNo);
    Assert.areEqual('RELEASED', r1.status);

    // When: 같은 분류로 다시 올림
    CMN_DocumentService.Result r2 = upload(ncr, 'D8', 'report-v2.pdf', 'v2')[0];

    // Then: 같은 문서의 Rev2 RELEASED, Rev1 SUPERSEDED, 현재 리비전 = Rev2
    Assert.areEqual(r1.documentId, r2.documentId);
    Assert.areEqual(2, r2.revisionNo);
    Map<Id, CMN_DocumentRevision__c> revs = new Map<Id, CMN_DocumentRevision__c>(
      [
        SELECT Id, Status__c, ReleasedAt__c, FileName__c, FileHash__c
        FROM CMN_DocumentRevision__c
      ]
    );
    Assert.areEqual('SUPERSEDED', revs.get(r1.revisionId).Status__c);
    Assert.areEqual('RELEASED', revs.get(r2.revisionId).Status__c);
    Assert.isNotNull(revs.get(r2.revisionId).ReleasedAt__c);
    Assert.areEqual('report-v2.pdf', revs.get(r2.revisionId).FileName__c);
    CMN_Document__c doc = [
      SELECT CurrentRevision__c, ParentObject__c, Plant__c, Name
      FROM CMN_Document__c
      WHERE Id = :r1.documentId
    ];
    Assert.areEqual(r2.revisionId, doc.CurrentRevision__c);
    Assert.areEqual('CMN_TestRecord__c', doc.ParentObject__c);
    Assert.isNotNull(doc.Plant__c, '부모 공장 복사');
    // 파일은 문서에 연결된다
    Assert.areEqual(
      2,
      [
        SELECT COUNT()
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :r1.documentId
      ]
    );
  }

  @IsTest
  static void test_AC02_releasedRevisionFileCannotBeReplaced() {
    // Given: RELEASED 리비전
    Id ncr = parent('ncr-1');
    CMN_DocumentService.Result r = upload(ncr, 'D8', 'report.pdf', 'v1')[0];
    CMN_DocumentRevision__c rev = [
      SELECT Id, ContentDocumentId__c
      FROM CMN_DocumentRevision__c
      WHERE Id = :r.revisionId
    ];

    // When / Then: 리비전의 파일 교체, Files 새 버전 업로드, 파일 삭제 모두 차단
    try {
      update new CMN_DocumentRevision__c(
        Id = rev.Id,
        FileName__c = 'other.pdf'
      );
      Assert.fail('교체 차단');
    } catch (DmlException e) {
      Assert.isTrue(
        e.getDmlType(0) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION
      );
    }
    try {
      insert new ContentVersion(
        ContentDocumentId = rev.ContentDocumentId__c,
        Title = 'other',
        PathOnClient = 'other.pdf',
        VersionData = Blob.valueOf('changed')
      );
      Assert.fail('새 버전 차단');
    } catch (DmlException e) {
      Assert.areEqual(Label.CMN_Doc_ReleasedLocked, e.getDmlMessage(0));
    }
    try {
      delete new ContentDocument(Id = rev.ContentDocumentId__c);
      Assert.fail('파일 삭제 차단');
    } catch (DmlException e) {
      Assert.areEqual(Label.CMN_Doc_ReleasedLocked, e.getDmlMessage(0));
    }
    // 공개 리비전·문서도 지울 수 없다
    try {
      delete new CMN_Document__c(Id = r.documentId);
      Assert.fail('문서 삭제 차단');
    } catch (DmlException e) {
      Assert.areEqual(Label.CMN_Doc_CannotDelete, e.getDmlMessage(0));
    }
  }

  @IsTest
  static void test_AC03_fileOver50MbIsBlockedAndRemoved() {
    // Given: 60MB 파일(테스트 힙 한도로 실제 파일 대신 크기만 60MB로 둔 버전)
    Assert.isTrue(CMN_DocumentService.tooLarge(60L * 1024 * 1024, 50));
    Assert.isFalse(CMN_DocumentService.tooLarge(50L * 1024 * 1024, 50));
    Id contentDocumentId = newFile('big.zip', 'x');
    ContentVersion big = (ContentVersion) JSON.deserialize(
      JSON.serialize(
        new Map<String, Object>{
          'ContentDocumentId' => contentDocumentId,
          'ContentSize' => 60 *
          1024 *
          1024
        }
      ),
      ContentVersion.class
    );

    // When / Then: 외부 링크 안내 문구를 예외가 아닌 값으로 돌려줘 삭제가 유지된다(보안 리뷰 반영)
    Assert.areEqual(
      String.format(Label.CMN_Doc_TooLarge, new List<Object>{ '50' }),
      CMN_DocumentService.discard(new List<ContentVersion>{ big })
    );
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM ContentDocument WHERE Id = :contentDocumentId]
    );
    // 화면 경로: 한도 안 파일은 오류 없이 등록
    CMN_DocumentController.Registration ok = CMN_DocumentController.registerFiles(
      parent('ncr-1'),
      classId('8D_REPORT'),
      new List<Id>{ newFile('small.pdf', 'small') },
      null,
      false
    );
    Assert.isNull(ok.error);
    Assert.areEqual(1, ok.results.size());
  }

  @IsTest
  static void test_review_newDraftSupersedesOlderDraftAndApprovesOnce() {
    // Given: 결재형 문서에 작성 중 리비전 2개(v1 → v2)
    Id ncr = parent('ncr-1');
    User approver = [SELECT Id FROM User WHERE Alias = 'docapv' LIMIT 1];
    CMN_DocumentService.Result r1 = upload(ncr, 'PSW', 'psw-v1.pdf', 'v1')[0];
    CMN_DocumentService.Result r2 = upload(ncr, 'PSW', 'psw-v2.pdf', 'v2')[0];

    // Then: 이전 작성 중 리비전은 대체, 상신·승인은 최신 1건만
    Assert.areEqual('SUPERSEDED', statusOf(r1.revisionId));
    Id req = CMN_DocumentService.submitForApproval(
      r2.documentId,
      null,
      line(approver.Id),
      null
    );
    System.runAs(approver) {
      CMN_ApprovalService.approve(
        [SELECT Id FROM CMN_ApprovalStep__c WHERE Request__c = :req].Id,
        'ok'
      );
    }
    Assert.areEqual('RELEASED', statusOf(r2.revisionId));
    Assert.areEqual('SUPERSEDED', statusOf(r1.revisionId));
    // 작성 중 리비전의 파일·링크도 바꿀 수 없다(유효성 규칙)
    Database.SaveResult sr = Database.update(
      new CMN_DocumentRevision__c(Id = r1.revisionId, FileName__c = 'x.pdf'),
      false
    );
    Assert.isFalse(sr.isSuccess());
  }

  @IsTest
  static void test_review_submitRequiresAccess() {
    // Given: 부모 접근이 없는 사용자
    Id ncr = parent('ncr-1');
    CMN_DocumentService.Result r = upload(ncr, 'PSW', 'psw.pdf', 'psw')[0];
    User outsider = [SELECT Id FROM User WHERE Alias = 'docapv' LIMIT 1];

    // When / Then: 문서 상신도, 결재 엔진 직접 상신도 막힌다
    System.runAs(outsider) {
      try {
        CMN_DocumentService.submitForApproval(
          r.documentId,
          null,
          line(UserInfo.getUserId()),
          null
        );
        Assert.fail('부모 편집 권한 필요');
      } catch (CMN_ValidationException e) {
        Assert.areEqual(Label.CMN_Doc_NoAccess, e.getMessage());
      }
      try {
        CMN_ApprovalService.submit(
          r.documentId,
          'CMN_DOC_RELEASE',
          line(UserInfo.getUserId()),
          null
        );
        Assert.fail('대상 읽기 권한 필요');
      } catch (CMN_ValidationException e) {
        Assert.areEqual(Label.CMN_Approval_NoTargetAccess, e.getMessage());
      }
    }
  }

  @IsTest
  static void test_review_linkGoesToItsOwnMultiFileDocument() {
    // Given: 사진 분류(MULTI_FILE)에 기존 문서 1개
    Id ncr = parent('ncr-1');
    CMN_DocumentService.Result photo = CMN_DocumentService.registerFiles(
      ncr,
      classId('NCR_PHOTO'),
      new List<Id>{ newFile('p1.jpg', '1') },
      null,
      false
    )[0];

    // When: 다른 이름의 링크 등록
    CMN_DocumentService.Result link = CMN_DocumentService.registerLink(
      ncr,
      classId('NCR_PHOTO'),
      'URL',
      'https://share.example.com/p2.jpg',
      null,
      'p2.jpg',
      null
    );

    // Then: 새 문서의 Rev1, 기존 사진은 그대로 공개 상태
    Assert.areNotEqual(photo.documentId, link.documentId);
    Assert.areEqual(1, link.revisionNo);
    Assert.areEqual('RELEASED', statusOf(photo.revisionId));
  }

  @IsTest
  static void test_AC04_sameHashOnOtherParentIsFlaggedNotBlocked() {
    // Given: ncr-1에 올린 파일과 같은 내용
    Id ncr1 = parent('ncr-1');
    Id ncr2 = parent('ncr-2');
    CMN_DocumentService.Result original = upload(
      ncr1,
      'D8',
      'a.pdf',
      'same'
    )[0];

    // When: 다른 부모(ncr-2)에 같은 파일
    CMN_DocumentService.Result copy = upload(ncr2, 'D8', 'b.pdf', 'same')[0];

    // Then: 업로드 성공 + 경고 플래그·원본 리비전
    Assert.areEqual('RELEASED', copy.status);
    Assert.isTrue(copy.duplicate);
    CMN_DocumentRevision__c rev = [
      SELECT IsDuplicateFile__c, DuplicateOfRevision__c, FileHash__c
      FROM CMN_DocumentRevision__c
      WHERE Id = :copy.revisionId
    ];
    Assert.areEqual(original.revisionId, rev.DuplicateOfRevision__c);
    Assert.isNotNull(rev.FileHash__c);
    // 처음 올린 파일은 경고가 없다
    Assert.isFalse(original.duplicate);
  }

  @IsTest
  static void test_BR3_approvalTypeReleasesOnApproval() {
    // Given: 결재형 분류(PPAP_PSW) 업로드 → DRAFT
    Id ncr = parent('ncr-1');
    User approver = [SELECT Id FROM User WHERE Alias = 'docapv' LIMIT 1];
    CMN_DocumentService.Result r = upload(ncr, 'PSW', 'psw.pdf', 'psw')[0];
    Assert.areEqual('DRAFT', r.status);
    try {
      CMN_DocumentService.submitForApproval(
        upload(ncr, 'D8', 'x.pdf', 'x')[0].documentId,
        null,
        line(approver.Id),
        null
      );
      Assert.fail('결재형 아님');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Doc_NotApprovalType, e.getMessage());
    }

    // When: 상신 → 결재 중, 새 리비전 업로드 차단
    Id req = CMN_DocumentService.submitForApproval(
      r.documentId,
      null,
      line(approver.Id),
      'go'
    );
    Assert.areEqual('IN_APPROVAL', statusOf(r.revisionId));
    try {
      upload(ncr, 'PSW', 'psw2.pdf', 'psw2');
      Assert.fail('결재 중');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Doc_InApproval, e.getMessage());
    }

    // Then: 승인 → RELEASED, 현재 리비전
    System.runAs(approver) {
      CMN_ApprovalService.approve(
        [SELECT Id FROM CMN_ApprovalStep__c WHERE Request__c = :req].Id,
        'ok'
      );
    }
    Assert.areEqual('RELEASED', statusOf(r.revisionId));
    Assert.areEqual(
      r.revisionId,
      [SELECT CurrentRevision__c FROM CMN_Document__c WHERE Id = :r.documentId]
      .CurrentRevision__c
    );

    // 다음 리비전은 반려되면 REJECTED, 이전 RELEASED 유지
    CMN_DocumentService.Result r2 = upload(ncr, 'PSW', 'psw2.pdf', 'psw2')[0];
    Id req2 = CMN_DocumentService.submitForApproval(
      r2.documentId,
      null,
      line(approver.Id),
      null
    );
    System.runAs(approver) {
      CMN_ApprovalService.reject(
        [
          SELECT Id
          FROM CMN_ApprovalStep__c
          WHERE Request__c = :req2
        ]
        .Id,
        'no'
      );
    }
    Assert.areEqual('REJECTED', statusOf(r2.revisionId));
    Assert.areEqual('RELEASED', statusOf(r.revisionId));
  }

  @IsTest
  static void test_BR3_recallReturnsToDraft() {
    Id ncr = parent('ncr-1');
    User approver = [SELECT Id FROM User WHERE Alias = 'docapv' LIMIT 1];
    CMN_DocumentService.Result r = upload(ncr, 'PSW', 'psw.pdf', 'psw')[0];
    Id req = CMN_DocumentService.submitForApproval(
      r.documentId,
      'CMN_DOC_RELEASE',
      line(approver.Id),
      null
    );
    CMN_ApprovalService.recall(req, 'later');
    Assert.areEqual('DRAFT', statusOf(r.revisionId));
    Assert.isNull(new CMN_DocumentApprovalCallback().canSubmit(r.documentId));
    Assert.areEqual(
      Label.CMN_Doc_NotApprovalType,
      new CMN_DocumentApprovalCallback().canSubmit(parent('ncr-1'))
    );
  }

  @IsTest
  static void test_BR2_documentParentFixedAndDraftDocumentDeletable() {
    // Given: 결재형 문서(작성 중 리비전만)
    Id ncr = parent('ncr-1');
    CMN_DocumentService.Result r = upload(ncr, 'PSW', 'psw.pdf', 'psw')[0];

    // When: 부모를 바꾸려 하면 원래 부모 유지, 분류 오류는 거절
    update new CMN_Document__c(
      Id = r.documentId,
      ParentRecordId__c = parent('ncr-2')
    );
    Assert.areEqual(
      String.valueOf(ncr),
      [SELECT ParentRecordId__c FROM CMN_Document__c WHERE Id = :r.documentId]
      .ParentRecordId__c
    );
    try {
      update new CMN_Document__c(Id = r.documentId, DocClass__c = null);
      Assert.fail('분류 필수');
    } catch (DmlException e) {
      Assert.isNotNull(e.getDmlMessage(0));
    }

    // Then: 작성 중 리비전만 있는 문서는 지울 수 있다
    delete new CMN_Document__c(Id = r.documentId);
    Assert.areEqual(0, [SELECT COUNT() FROM CMN_DocumentRevision__c]);
  }

  @IsTest
  static void test_BR4_linkOnlyClassAndLinks() {
    // Given: 도면(LINK_ONLY)
    Id ncr = parent('ncr-1');

    // When / Then: 파일 차단, PDM 링크는 등록·즉시 공개
    try {
      upload(ncr, 'DRAWING', 'dwg.pdf', 'dwg');
      Assert.fail('링크 전용');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Doc_LinkOnly, e.getMessage());
    }
    CMN_DocumentService.Result link = CMN_DocumentService.registerLink(
      ncr,
      classId('DRAWING'),
      'PDM',
      null,
      'DWG-HL-0001',
      null,
      'initial'
    );
    Assert.areEqual('RELEASED', link.status);
    CMN_DocumentRevision__c rev = [
      SELECT StorageType__c, ExternalRef__c, FileName__c
      FROM CMN_DocumentRevision__c
      WHERE Id = :link.revisionId
    ];
    Assert.areEqual('PDM', rev.StorageType__c);
    Assert.areEqual('DWG-HL-0001', rev.FileName__c);
    // https가 아닌 링크·저장소 오류
    for (String bad : new List<String>{ 'http://x', null }) {
      try {
        CMN_DocumentService.registerLink(
          ncr,
          classId('DRAWING'),
          bad == null ? 'FTP' : 'URL',
          bad,
          null,
          'x',
          null
        );
        Assert.fail('링크 오류');
      } catch (CMN_ValidationException e) {
        Assert.areEqual(Label.CMN_Doc_InvalidLink, e.getMessage());
      }
    }
  }

  @IsTest
  static void test_BR1_multiFileClassKeepsDocumentPerFile() {
    // Given: 사진(MULTI_FILE) 2장 + 같은 이름 다시
    Id ncr = parent('ncr-1');
    List<CMN_DocumentService.Result> photos = CMN_DocumentService.registerFiles(
      ncr,
      classId('NCR_PHOTO'),
      new List<Id>{ newFile('p1.jpg', '1'), newFile('p2.jpg', '2') },
      null,
      true
    );
    Assert.areNotEqual(photos[0].documentId, photos[1].documentId);
    CMN_DocumentService.Result again = CMN_DocumentService.registerFiles(
      ncr,
      classId('NCR_PHOTO'),
      new List<Id>{ newFile('p1.jpg', '1b') },
      null,
      true
    )[0];
    Assert.areEqual(photos[0].documentId, again.documentId);
    Assert.areEqual(2, again.revisionNo);
    // 협력사 공개 = 파일 링크 AllUsers
    Assert.areEqual(
      'AllUsers',
      [
        SELECT Visibility
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :photos[0].documentId
        LIMIT 1
      ]
      .Visibility
    );
    // 단일 분류에 파일 여러 개는 거절
    try {
      CMN_DocumentService.registerFiles(
        ncr,
        classId('8D_REPORT'),
        new List<Id>{ newFile('a.pdf', 'a'), newFile('b.pdf', 'b') },
        null,
        false
      );
      Assert.fail('단일 분류');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Doc_OneFileOnly, e.getMessage());
    }
  }

  @IsTest
  static void test_BR6_panelFollowsParentAccess() {
    // Given: 8D 보고서 1건, 필수 분류 PSW
    Id ncr = parent('ncr-1');
    upload(ncr, 'D8', 'report.pdf', 'v1');
    insert new CMN_DocTemplate__c(
      Name = 'PSW form',
      DocClass__c = classId('PPAP_PSW'),
      Language__c = 'en_US',
      ContentDocumentId__c = newFile('psw-form.xlsx', 'form'),
      IsActive__c = true
    );

    // When
    CMN_DocumentController.Panel p = CMN_DocumentController.getPanel(
      ncr,
      '8D_REPORT, PPAP_PSW',
      'PPAP_PSW'
    );

    // Then: 분류 2개, PSW 필수 누락, 양식은 en_US 대체, 8D 현재 리비전
    Assert.isTrue(p.canEdit);
    Assert.areEqual(2, p.classes.size());
    Map<String, CMN_DocumentController.ClassGroup> byCode = new Map<String, CMN_DocumentController.ClassGroup>();
    for (CMN_DocumentController.ClassGroup g : p.classes) {
      byCode.put(g.code, g);
    }
    Assert.isTrue(byCode.get('PPAP_PSW').missing);
    Assert.isNotNull(byCode.get('PPAP_PSW').templateDocumentId);
    Assert.areEqual(1, byCode.get('8D_REPORT').documents[0].current.revisionNo);
    Assert.isNotNull(byCode.get('8D_REPORT').documents[0].current.statusLabel);

    // 부모를 볼 수 없는 사용자는 빈 패널, 등록도 차단
    User outsider = [SELECT Id FROM User WHERE Alias = 'docapv' LIMIT 1];
    System.runAs(outsider) {
      CMN_DocumentController.Panel none = CMN_DocumentController.getPanel(
        ncr,
        null,
        null
      );
      Assert.isFalse(none.canRead);
      Assert.areEqual(0, none.classes.size());
      try {
        CMN_DocumentController.registerLink(
          ncr,
          classId('DRAWING'),
          'URL',
          'https://x.example.com/a',
          null,
          'a',
          null
        );
        Assert.fail('권한 없음');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Doc_NoAccess, e.getMessage());
      }
    }
  }

  @IsTest
  static void test_negative_inputAndTemplates() {
    Id ncr = parent('ncr-1');
    // 분류 아님(다른 그룹의 코드 = 부모 Id), 빈 파일 목록, 잘못된 코드 목록
    try {
      CMN_DocumentService.registerFiles(ncr, ncr, new List<Id>(), null, false);
      Assert.fail('분류 오류');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Doc_InvalidClass, e.getMessage());
    }
    try {
      CMN_DocumentService.registerFiles(
        ncr,
        classId('8D_REPORT'),
        new List<Id>(),
        null,
        false
      );
      Assert.fail('파일 없음');
    } catch (CMN_ValidationException e) {
      Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
    }
    try {
      CMN_DocumentController.getPanel(ncr, 'X;DROP', null);
      Assert.fail('입력 오류');
    } catch (AuraHandledException e) {
      Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
    }
    try {
      CMN_DocumentController.registerFiles(
        ncr,
        classId('8D_REPORT'),
        new List<Id>{ ncr },
        null,
        false
      );
      Assert.fail('파일 Id만');
    } catch (AuraHandledException e) {
      Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
    }
    try {
      CMN_DocumentController.submitDocument(ncr, null);
      Assert.fail('문서 Id만');
    } catch (AuraHandledException e) {
      Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
    }
    // 결재선 템플릿이 없으면 상신 불가
    CMN_DocumentService.Result psw = upload(ncr, 'PSW', 'psw.pdf', 'p')[0];
    try {
      CMN_DocumentController.submitDocument(psw.documentId, null);
      Assert.fail('템플릿 없음');
    } catch (AuraHandledException e) {
      Assert.areEqual(Label.CMN_Doc_NoApprovalLine, e.getMessage());
    }
    // 양식: 사용자 언어(ko) 우선, 없으면 en_US
    Id cls = classId('8D_REPORT');
    insert new List<CMN_DocTemplate__c>{
      new CMN_DocTemplate__c(
        Name = 'en',
        DocClass__c = cls,
        Language__c = 'en_US',
        ContentDocumentId__c = '069000000000001AAA'
      ),
      new CMN_DocTemplate__c(
        Name = 'ko',
        DocClass__c = cls,
        Language__c = 'ko',
        ContentDocumentId__c = '069000000000002AAA'
      )
    };
    Assert.areEqual('ko', CMN_DocumentService.templateFor(cls, 'ko').Name);
    Assert.areEqual('en', CMN_DocumentService.templateFor(cls, 'pl').Name);
    Assert.isNull(CMN_DocumentService.templateFor(classId('DRAWING'), 'ko'));
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_Code__c code(
    Id groupId,
    String value,
    String attr1,
    String attr2,
    String attr3
  ) {
    return new CMN_Code__c(
      CodeGroup__c = groupId,
      Code__c = value,
      Name = value,
      IsActive__c = true,
      Attribute1__c = attr1,
      Attribute2__c = attr2,
      Attribute3__c = attr3
    );
  }

  private static Id parent(String name) {
    return [SELECT Id FROM CMN_TestRecord__c WHERE Name = :name].Id;
  }

  private static Id classId(String code) {
    return [
      SELECT Id
      FROM CMN_Code__c
      WHERE Code__c = :code AND CodeGroup__r.GroupCode__c = 'DOC_CLASS'
    ]
    .Id;
  }

  private static Id newFile(String name, String content) {
    ContentVersion v = new ContentVersion(
      Title = name,
      PathOnClient = name,
      VersionData = Blob.valueOf(content)
    );
    insert v;
    return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :v.Id]
    .ContentDocumentId;
  }

  /** 분류 약칭: D8 = 8D_REPORT, PSW = PPAP_PSW */
  private static List<CMN_DocumentService.Result> upload(
    Id parentId,
    String cls,
    String fileName,
    String content
  ) {
    String code = cls == 'D8' ? '8D_REPORT' : cls == 'PSW' ? 'PPAP_PSW' : cls;
    return CMN_DocumentService.registerFiles(
      parentId,
      classId(code),
      new List<Id>{ newFile(fileName, content) },
      null,
      false
    );
  }

  private static String statusOf(Id revisionId) {
    return [
      SELECT Status__c
      FROM CMN_DocumentRevision__c
      WHERE Id = :revisionId
    ]
    .Status__c;
  }

  private static List<CMN_ApprovalStepSpec> line(Id approverId) {
    return new List<CMN_ApprovalStepSpec>{
      new CMN_ApprovalStepSpec(1, 'APPROVE', approverId, null)
    };
  }
}
