/**
 * @description 문서 버전 비교(CMN-00-AI-003, A단계 화면): 같은 문서 두 리비전 비교(프로토 목 응답: 변경 목록·표 셀·요약),
 * 텍스트 없는 형식 비교 불가·AI 호출 0회(AC-2), 엔진 미연결 상태, 리비전 선택 오류, 요약 반영 자리 구현.
 * 실제 추출·정렬·LLM 요약(AC-1)은 P12에서 확인한다.
 * @group CMN-00-AI-003
 */
@IsTest
private class CMN_DocumentCompareController_Test {
  private static final String BUNDLE =
    '{"version":1,"dwh":{"CMN_DOC_COMPARE":{"ok":{"queryKey":"CMN_DOC_COMPARE","mode":"AI","comparable":true,' +
    '"summary":"3 specs changed","changes":[{"type":"CHANGED","section":"3","before":"2.10","after":"2.05"},' +
    '{"type":"ADDED","section":"5","before":null,"after":"stop line"},{"type":"REMOVED","section":"B","before":"old","after":null}],' +
    '"table":{"keyLabel":"Char No","rows":[{"key":"C10","column":"USL","before":"2.10","after":"2.05"},' +
    '{"key":"C14","column":"LSL","before":"3.0","after":"3.2"},{"key":"C22","column":"Points","before":"5","after":"9"}]}}}}}';

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
    insert new CMN_Code__c(
      CodeGroup__c = g.Id,
      Code__c = 'CONTROL_PLAN',
      Name = 'CONTROL_PLAN',
      IsActive__c = true
    );
    insert new CMN_TestRecord__c(
      Name = 'cp-parent',
      Plant__c = p.Id,
      Status__c = 'DRAFT'
    );
  }

  @IsTest
  static void test_AC01_twoRevisionsShowChangesTableAndSummary() {
    // Given: 관리계획서 Rev1 → Rev2(규격 3개 변경 — 예시 응답)
    List<Id> revs = uploadRevisions(new List<String>{ 'cp.xlsx', 'cp.xlsx' });
    usePrototype(true);

    // When
    CMN_DocumentCompareController.Comparison c = CMN_DocumentCompareController.compare(
      revs[0],
      revs[1]
    );

    // Then: 변경 3건(구분 라벨), 표 셀 3건, 요약, 예시 표시, 리비전 라벨
    Assert.areEqual('OK', c.state);
    Assert.isTrue(c.isMock);
    Assert.areEqual('Rev.1', c.fromLabel);
    Assert.areEqual('Rev.2', c.toLabel);
    Assert.areEqual('3 specs changed', c.summary);
    Assert.areEqual(3, c.changes.size());
    Assert.areEqual(Label.CMN_DocCompare_Changed, c.changes[0].typeLabel);
    Assert.areEqual(Label.CMN_DocCompare_Added, c.changes[1].typeLabel);
    Assert.isNull(c.changes[1].beforeText);
    Assert.areEqual('Char No', c.rowKeyLabel);
    Assert.areEqual(3, c.cells.size());
    Assert.areEqual('C10', c.cells[0].rowKey);
    Assert.areEqual('2.05', c.cells[0].afterText);
  }

  @IsTest
  static void test_AC02_noTextFormatIsNotComparableWithoutAiCall() {
    // Given: Rev1 xlsx, Rev2 스캔 이미지
    List<Id> revs = uploadRevisions(
      new List<String>{ 'cp.xlsx', 'cp-scan.tif' }
    );
    usePrototype(true);

    // When
    CMN_DocumentCompareController.Comparison c = CMN_DocumentCompareController.compare(
      revs[0],
      revs[1]
    );

    // Then: 비교 불가 문구, AI 호출 0회
    Assert.areEqual('NOT_COMPARABLE', c.state);
    Assert.areEqual(Label.CMN_DocCompare_NotComparable, c.message);
    Assert.areEqual(0, CMN_DocumentCompareController.aiCalls);
  }

  @IsTest
  static void test_notAvailablePickErrorsAndApplyStub() {
    List<Id> revs = uploadRevisions(new List<String>{ 'a.docx', 'a.docx' });
    // 엔진 미연결(프로토 모드 아님)
    usePrototype(false);
    CMN_DocumentCompareController.Comparison c = CMN_DocumentCompareController.compare(
      revs[0],
      revs[1]
    );
    Assert.areEqual('NOT_AVAILABLE', c.state);
    Assert.areEqual(Label.CMN_Prototype_NotYetAvailable, c.message);
    // 같은 리비전·하나만 고름
    assertMessage(Label.CMN_DocCompare_PickTwo, revs[0], revs[0]);
    assertMessage(Label.CMN_DocCompare_PickTwo, revs[0], null);
    // 요약 반영은 상세 기능 단계에서 동작
    String message;
    try {
      CMN_DocumentCompareController.applySummary(revs[1], 'edited');
    } catch (AuraHandledException e) {
      message = e.getMessage();
    }
    Assert.areEqual(Label.CMN_Prototype_NotYetAvailable, message);
  }

  private static void assertMessage(String expected, Id a, Id b) {
    String message;
    try {
      CMN_DocumentCompareController.compare(a, b);
    } catch (AuraHandledException e) {
      message = e.getMessage();
    }
    Assert.areEqual(expected, message);
  }

  /** 같은 부모·같은 분류로 차례로 올리면 한 문서의 리비전이 늘어난다(DOC-001) */
  private static List<Id> uploadRevisions(List<String> fileNames) {
    Id parentId = [SELECT Id FROM CMN_TestRecord__c LIMIT 1].Id;
    Id classId = [SELECT Id FROM CMN_Code__c WHERE Code__c = 'CONTROL_PLAN'].Id;
    List<Id> out = new List<Id>();
    Integer i = 0;
    for (String name : fileNames) {
      ContentVersion v = new ContentVersion(
        Title = name,
        PathOnClient = name,
        VersionData = Blob.valueOf('content ' + i++)
      );
      insert v;
      Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :v.Id]
      .ContentDocumentId;
      out.add(
        CMN_DocumentService.registerFiles(
            parentId,
            classId,
            new List<Id>{ docId },
            null,
            false
          )[0]
          .revisionId
      );
    }
    return out;
  }

  private static void usePrototype(Boolean active) {
    CMN_Prototype.bundleOverride = BUNDLE;
    CMN_Prototype.scratchOverride = active;
    CMN_FeatureSwitch.userPermissionSets = new Set<String>{
      'QMS_PS_Prototype_Review'
    };
  }
}
