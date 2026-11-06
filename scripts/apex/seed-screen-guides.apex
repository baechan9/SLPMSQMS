// 개발·검토 Scratch 전용(CMN-00-UX-002): 화면 가이드 샘플을 외부 키로 upsert한다(다시 실행해도 같은 건수).
// 사용: sf apex run -o <alias> -f scripts/apex/seed-screen-guides.apex
// 운영 가이드는 관리자가 SL Admin 앱 "화면 가이드" 탭에서 쓴다. 이 스크립트는 운영·SIT에서 실행하지 않는다.
List<CMN_ScreenGuide__c> guides = new List<CMN_ScreenGuide__c>();
Map<String, List<String>> ko = new Map<String, List<String>>{
  'CMN_QMS_Home' => new List<String>{
    'SL QMS 홈 사용법',
    '<p><b>할 일</b>: 내가 처리할 결재·To-Do가 기한 순으로 나옵니다. 제목을 누르면 그 업무 화면으로 갑니다.</p><p><b>위젯 보드</b>: 오른쪽 위 편집으로 위젯을 더하거나 순서를 바꿉니다.</p>'
  },
  'CMN_MenuHub' => new List<String>{
    '메뉴 허브 사용법',
    '<p>메뉴 번호(02~09)를 고르면 그 메뉴의 기능 타일이 나옵니다. 위 검색창에 기능 이름이나 키워드를 넣으면 전체 메뉴에서 찾습니다.</p><p>"준비 중" 타일은 다음 단계에서 열리는 화면입니다.</p>'
  },
  'CMN_UnifiedSearch' => new List<String>{
    '통합 검색 사용법',
    '<p>번호·제목·품번으로 레코드를 찾고, 문서 내용으로 관련 문서를 찾습니다.</p><ul><li>AI 요약은 참고용입니다. 근거 문서를 열어 확인하세요.</li><li>"이전 리비전 포함"을 켜면 대체된 리비전도 나옵니다.</li></ul>'
  },
  'CMN_TestRecord__c.RECORD' => new List<String>{
    '샘플 업무 레코드 화면',
    '<ol><li>위 진행 표시에서 현재 단계를 확인합니다.</li><li>"현재 단계" 탭의 입력을 채우고 저장합니다.</li><li>오른쪽 레일에서 AI 추천·결재·할 일을 확인합니다.</li></ol>'
  }
};
for (String key : ko.keySet()) {
  guides.add(
    new CMN_ScreenGuide__c(
      Name = ko.get(key)[0],
      PageKey__c = key,
      Language__c = 'ko',
      Content__c = ko.get(key)[1],
      IsPublished__c = true,
      ExternalKey__c = key + '-ko'
    )
  );
}
// 영어 가이드 1건(언어 대체 확인용: 중국어 사용자는 이 가이드를 본다)
guides.add(
  new CMN_ScreenGuide__c(
    Name = 'Sample business record screen',
    PageKey__c = 'CMN_TestRecord__c.RECORD',
    Language__c = 'en_US',
    Content__c = '<ol><li>Check the current stage in the path.</li><li>Fill in the Current Stage tab and save.</li><li>Use the right rail for AI recommendations, approvals and to-dos.</li></ol>',
    IsPublished__c = true,
    ExternalKey__c = 'CMN_TestRecord__c.RECORD-en_US'
  )
);
Database.UpsertResult[] results = Database.upsert(
  guides,
  CMN_ScreenGuide__c.ExternalKey__c,
  false
);
Integer ok = 0;
for (Database.UpsertResult r : results) {
  ok += r.isSuccess() ? 1 : 0;
}
System.debug('화면 가이드 ' + ok + '/' + results.size());
