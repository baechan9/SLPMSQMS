// 개발·검토 Scratch 전용(CMN-00-AI-004): 샘플 테스트 레코드에 원인 추천 3건을 기록해 결정 지원 레일 AI 패널을 확인한다.
// 사용: sf apex run -o <alias> -f scripts/apex/seed-ai-recommendations.apex
// 다시 실행하면 서비스 규칙(BR-2)대로 이전 제안은 만료되고 새 3건이 생긴다. 운영·SIT에서 실행하지 않는다.
// 화면 확인용 샘플(UX-006 그리드 데모와 같은 레코드)을 우선 고르고, 없으면 가장 먼저 만든 테스트 레코드
List<CMN_TestRecord__c> targets = [
  SELECT Id, RecordNo__c
  FROM CMN_TestRecord__c
  WHERE RecordNo__c = 'TST-KR01-2026-000001'
  LIMIT 1
];
if (targets.isEmpty()) {
  targets = [
    SELECT Id, RecordNo__c
    FROM CMN_TestRecord__c
    ORDER BY CreatedDate
    LIMIT 1
  ];
}
if (targets.isEmpty()) {
  System.debug('샘플 테스트 레코드가 없다 — 건너뜀');
} else {
  List<String> titles = new List<String>{
    '렌즈-하우징 실링 접착 불량',
    '하우징 사출 휨(금형 냉각 편차)',
    '커넥터 체결 불완전'
  };
  List<String> texts = new List<String>{
    '수밀 시험 누수 위치가 실링 라인 코너와 일치한다.',
    '같은 주간 사출 로트에서 평면도 편차가 커졌다.',
    '조립 공정 체결 확인 누락 이력이 있다.'
  };
  List<CMN_AiRecommendationService.Rec> recs = new List<CMN_AiRecommendationService.Rec>();
  for (Integer i = 0; i < titles.size(); i++) {
    CMN_AiRecommendationService.Rec r = new CMN_AiRecommendationService.Rec();
    r.rank = i + 1;
    r.title = titles[i];
    r.contentJson = JSON.serialize(
      new Map<String, Object>{
        'text' => texts[i],
        'items' => new List<Object>{
          new Map<String, Object>{
            'label' => '원인 분류',
            'value' => i == 0
              ? '재료/접착'
              : (i == 1 ? '설비/금형' : '작업/체결')
          },
          new Map<String, Object>{
            'label' => '유사 사례',
            'value' => String.valueOf(5 - i) + '건'
          }
        }
      }
    );
    r.rationale = '최근 12개월 같은 품번군 사례와 4M 변경 이력 기준(예시 데이터)';
    r.sourceRefsJson = JSON.serialize(
      new List<Object>{
        new Map<String, Object>{
          'id' => targets[0].Id,
          'label' => targets[0].RecordNo__c
        }
      }
    );
    r.score = 0.82 - i * 0.17;
    r.promptVersion = 'demo-rca-v1';
    r.modelInfo = 'demo(예시)';
    recs.add(r);
  }
  System.debug(
    CMN_AiRecommendationService.record('QMS_RCA', targets[0].Id, recs)
  );
}
