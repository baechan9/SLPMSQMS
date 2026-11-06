/**
 * @description 통합 검색(CMN-00-AI-002 BR-3, A단계 화면): 등록 객체 SOSL 레코드 검색(사용자 권한), 문서 의미 검색 자리
 * (프로토 목 응답·이전 리비전 필터·엔진 미연결 상태), 검색어 검증. 의미 검색 정확도(AC-1)·권한 필터(AC-2)·색인(AC-3)은 P12에서 확인한다.
 * @group CMN-00-AI-002
 */
@IsTest
private class CMN_UnifiedSearchController_Test {
  private static final String BUNDLE =
    '{"version":1,"dwh":{"CMN_DOC_SEARCH":{"ok":{"queryKey":"CMN_DOC_SEARCH","mode":"AI",' +
    '"summary":{"text":"Vent spec raised","sources":[{"label":"DOC-1 Rev.2"}]},' +
    '"documents":[{"title":"8D lens fog","docNo":"DOC-1","revisionLabel":"Rev.2","docClass":"8D","snippet":"vent","score":0.912,"superseded":false},' +
    '{"title":"8D lens fog","docNo":"DOC-1","revisionLabel":"Rev.1","docClass":"8D","snippet":"temp","score":0.8,"superseded":true}]}}}}';

  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    // 검색 대상: 검색이 켜진 공장 객체(테스트 대상 객체는 검색이 꺼져 있다)
    insert new CMN_Plant__c(
      Name = 'Lens plant',
      PlantCode__c = 'KR01',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
  }

  @IsTest
  static void test_BR03_recordsAndDocumentsInOneSearch() {
    // Given: 등록 객체 3개(아직 배포 안 된 메뉴 객체, 공장, 비활성 회사), 프로토 모드
    useScopes();
    usePrototype(true);
    CMN_Plant__c rec = [SELECT Id FROM CMN_Plant__c LIMIT 1];
    Test.setFixedSearchResults(new List<Id>{ rec.Id });

    // When: 검색(이전 리비전 제외)
    CMN_UnifiedSearchController.Result r = CMN_UnifiedSearchController.search(
      '  lens fog ',
      false
    );

    // Then: 레코드 1묶음 1건(번호·제목·보조), 문서 1건(이전 리비전 제외)·AI 요약·출처·예시 표시
    Assert.areEqual('lens fog', r.term);
    Assert.areEqual(1, r.records.size());
    Assert.areEqual(1, r.recordCount);
    CMN_UnifiedSearchController.Hit h = r.records[0].hits[0];
    Assert.areEqual(rec.Id, h.id);
    Assert.areEqual('KR01', h.numberText);
    Assert.areEqual('Lens plant', h.title);
    Assert.areEqual('KR', h.subtitle);
    Assert.areEqual('CMN_Plant__c', r.records[0].objectApiName);
    Assert.areEqual('OK', r.documents.state);
    Assert.isTrue(r.documents.isMock);
    Assert.areEqual('Vent spec raised', r.documents.summary);
    Assert.areEqual('DOC-1 Rev.2', r.documents.sources[0].text);
    Assert.areEqual(1, r.documents.items.size());
    Assert.areEqual(91, r.documents.items[0].scorePercent);

    // 이전 리비전 포함이면 2건
    Assert.areEqual(
      2,
      CMN_UnifiedSearchController.search('lens fog', true)
        .documents.items.size()
    );
  }

  @IsTest
  static void test_documentsNotAvailableOutsidePrototype() {
    // Given: 프로토 모드 아님(엔진 연결 전 운영·SIT와 같다)
    useScopes();
    usePrototype(false);
    Test.setFixedSearchResults(new List<Id>());

    // When
    CMN_UnifiedSearchController.Result r = CMN_UnifiedSearchController.search(
      'housing',
      false
    );

    // Then: 레코드 결과 없음, 문서는 준비 중 문구
    Assert.areEqual(0, r.recordCount);
    Assert.areEqual('NOT_AVAILABLE', r.documents.state);
    Assert.areEqual(Label.CMN_Prototype_NotYetAvailable, r.documents.message);
  }

  @IsTest
  static void test_termLengthAndEscaping() {
    for (String bad : new List<String>{ null, ' a ', 'x'.repeat(101) }) {
      String message;
      try {
        CMN_UnifiedSearchController.search(bad, false);
      } catch (AuraHandledException e) {
        message = e.getMessage();
      }
      Assert.areEqual(Label.CMN_Search_TermLength, message);
    }
    // SOSL 예약 문자는 글자로 찾는다
    Assert.areEqual(
      'C10\\-A \\(R1\\) 2\\*',
      CMN_UnifiedSearchController.escape('C10-A (R1) 2*')
    );
    // 배포된 등록(검색 범위 메타데이터)으로도 오류 없이 동작한다
    Test.setFixedSearchResults(new List<Id>());
    Assert.isNotNull(CMN_UnifiedSearchController.search('lens', false));
  }

  private static void useScopes() {
    CMN_UnifiedSearchController.scopesOverride = new List<CMN_SearchScope__mdt>{
      new CMN_SearchScope__mdt(
        ObjectApiName__c = 'QMS_NotDeployed__c',
        TitleField__c = 'Name',
        Order__c = 1,
        IsActive__c = true
      ),
      new CMN_SearchScope__mdt(
        ObjectApiName__c = 'CMN_Plant__c',
        NumberField__c = 'PlantCode__c',
        TitleField__c = 'Name',
        SubtitleField__c = 'Region__c',
        Order__c = 5,
        MaxRows__c = 50,
        IsActive__c = true
      ),
      new CMN_SearchScope__mdt(
        ObjectApiName__c = 'CMN_Company__c',
        TitleField__c = 'Name',
        Order__c = 9,
        IsActive__c = false
      )
    };
  }

  private static void usePrototype(Boolean active) {
    CMN_Prototype.bundleOverride = BUNDLE;
    CMN_Prototype.scratchOverride = active;
    CMN_FeatureSwitch.userPermissionSets = new Set<String>{
      'QMS_PS_Prototype_Review'
    };
  }
}
