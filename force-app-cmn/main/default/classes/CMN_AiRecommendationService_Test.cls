/**
 * @description AI 추천 기록·채택·적중(CMN-00-AI-004): 2위 채택·적중 집계(AC-1), 제외 사유 필수(AC-2), 재추천 만료(BR-2),
 * 목록·공장 공유·결정 권한(BR-3), 입력 검증. 원천 업무 레코드는 테스트 객체(공장 Lookup 있음)로 대신한다.
 * 화면 동작(레일 3건·더 보기·배지·결정 알림)은 Jest에서 확인한다.
 * @group CMN-00-AI-004
 */
@IsTest
private class CMN_AiRecommendationService_Test {
  private static final String RCA = 'QMS_RCA';

  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    List<CMN_Plant__c> plants = new List<CMN_Plant__c>{
      plant(c.Id, 'KR01', 'Asia/Seoul'),
      plant(c.Id, 'CN01', 'Asia/Shanghai')
    };
    insert plants;
    CMN_CodeGroup__c g = new CMN_CodeGroup__c(
      Name = 'AI_EXCLUDE_REASON',
      GroupCode__c = 'AI_EXCLUDE_REASON',
      MaxLevel__c = 1
    );
    insert g;
    insert new List<CMN_Code__c>{
      code(g.Id, 'NOT_RELEVANT', 10),
      code(g.Id, 'WEAK_EVIDENCE', 20)
    };
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    List<User> users = new List<User>{
      CMN_TestDataFactory.newUser('aikre', 'KR Editor', profileId),
      CMN_TestDataFactory.newUser('aikrr', 'KR Reader', profileId),
      CMN_TestDataFactory.newUser('aicne', 'CN Editor', profileId)
    };
    System.runAs(new User(Id = UserInfo.getUserId())) {
      CMN_PlantGroupService.ensureGroups(
        new Map<Id, CMN_Plant__c>(plants).keySet()
      );
      insert users;
      // 사내 페르소나 PSG와 같이 공통 코드 읽기(제외 사유 표시·코드 선택)를 함께 준다
      List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
      for (PermissionSet ps : [
        SELECT Id
        FROM PermissionSet
        WHERE Name IN ('CMN_PS_AiRecommendation_User', 'CMN_PS_Code_Read')
      ]) {
        for (User u : users) {
          psas.add(
            new PermissionSetAssignment(
              AssigneeId = u.Id,
              PermissionSetId = ps.Id
            )
          );
        }
      }
      insert psas;
    }
    insert new List<CMN_UserPlantAccess__c>{
      access(users[0].Id, plants[0].Id, 'Edit'),
      access(users[1].Id, plants[0].Id, 'Read'),
      access(users[2].Id, plants[1].Id, 'Edit')
    };
    System.runAs(new User(Id = UserInfo.getUserId())) {
      CMN_PlantGroupService.syncMembers(new Map<Id, User>(users).keySet());
    }
    insert new CMN_TestRecord__c(
      Name = 'AI source KR01',
      Plant__c = plants[0].Id,
      Status__c = 'DRAFT'
    );
  }

  @IsTest
  static void test_AC01_secondRankAdoptedCountsAsTop3Hit() {
    // Given: 원인 추천 3건(A·B·C)
    Id source = source();
    List<Id> ids = CMN_AiRecommendationService.record(
      RCA,
      source,
      recs(new List<String>{ 'A', 'B', 'C' })
    );

    // When: KR01 편집자가 2위를 채택하고, 업무 확정 결과가 B
    System.runAs(user('aikre')) {
      CMN_AiRecommendationController.Item adopted = CMN_AiRecommendationController.decide(
        ids[1],
        CMN_AiRecommendationService.ADOPTED,
        null
      );
      Assert.areEqual('ADOPTED', adopted.status);
      Assert.isTrue(adopted.canDecide);
    }
    Integer evaluated = CMN_AiRecommendationService.finalize(
      source,
      RCA,
      '{"causeCode":"B"}',
      new CauseHitRule()
    );

    // Then: 2위만 적중 → Top-1 미적중, Top-3 적중. 결정자·결정 시각·확정 시각 기록
    Assert.areEqual(3, evaluated);
    Map<Integer, CMN_AiRecommendation__c> byRank = byRank(source);
    Assert.isFalse(byRank.get(1).IsHit__c);
    Assert.isTrue(byRank.get(2).IsHit__c);
    Assert.isFalse(byRank.get(3).IsHit__c);
    Boolean top1 = byRank.get(1).IsHit__c;
    Boolean top3 = false;
    for (CMN_AiRecommendation__c r : byRank.values()) {
      top3 = top3 || (r.Rank__c <= 3 && r.IsHit__c);
    }
    Assert.isFalse(top1);
    Assert.isTrue(top3);
    Assert.areEqual(user('aikre').Id, byRank.get(2).DecidedBy__c);
    Assert.isNotNull(byRank.get(2).DecidedAt__c);
    Assert.isNotNull(byRank.get(2).FinalizedAt__c);
    Assert.areEqual('{"causeCode":"B"}', byRank.get(2).FinalOutcomeJson__c);

    // 확정 평가된 추천은 더 결정할 수 없다
    System.runAs(user('aikre')) {
      assertAuraMessage(
        Label.CMN_AiRec_Closed,
        ids[0],
        'EXCLUDED',
        'NOT_RELEVANT'
      );
    }
  }

  @IsTest
  static void test_AC02_excludeWithoutReasonIsBlocked() {
    // Given: 추천 2건
    Id source = source();
    List<Id> ids = CMN_AiRecommendationService.record(
      RCA,
      source,
      recs(new List<String>{ 'A', 'B' })
    );
    System.runAs(user('aikre')) {
      // When: 사유 없이 제외 → Then 차단, 상태 그대로
      assertAuraMessage(
        Label.CMN_AiRec_ReasonRequired,
        ids[0],
        'EXCLUDED',
        null
      );
      assertAuraMessage(
        Label.CMN_AiRec_ReasonRequired,
        ids[0],
        'EXCLUDED',
        'NO_SUCH_CODE'
      );
      // 사유 코드 값 또는 코드 Id로 제외
      CMN_AiRecommendationController.Item byValue = CMN_AiRecommendationController.decide(
        ids[0],
        'EXCLUDED',
        'NOT_RELEVANT'
      );
      Assert.areEqual('EXCLUDED', byValue.status);
      Assert.areEqual('NOT_RELEVANT', byValue.excludeReason);
      Id weak = [SELECT Id FROM CMN_Code__c WHERE Code__c = 'WEAK_EVIDENCE'].Id;
      Assert.areEqual(
        'EXCLUDED',
        CMN_AiRecommendationController.decide(ids[1], 'EXCLUDED', weak).status
      );
    }
    Assert.areEqual(
      0,
      [
        SELECT COUNT()
        FROM CMN_AiRecommendation__c
        WHERE Status__c = 'EXCLUDED' AND ExcludeReason__c = NULL
      ]
    );
    // 서비스를 거치지 않은 저장도 검증 규칙이 막는다
    CMN_AiRecommendation__c direct = new CMN_AiRecommendation__c(
      Id = ids[0],
      ExcludeReason__c = null
    );
    Database.SaveResult sr = Database.update(direct, false);
    Assert.isFalse(sr.isSuccess());
  }

  @IsTest
  static void test_BR02_rerecommendExpiresOpenProposals() {
    // Given: 1차 추천 2건 중 1건 채택
    Id source = source();
    List<Id> first = CMN_AiRecommendationService.record(
      RCA,
      source,
      recs(new List<String>{ 'A', 'B' })
    );
    System.runAs(user('aikre')) {
      CMN_AiRecommendationController.decide(first[0], 'ADOPTED', null);
    }

    // When: 같은 대상에 2차 추천 3건
    Test.startTest();
    CMN_AiRecommendationService.record(
      RCA,
      source,
      recs(new List<String>{ 'C', 'D', 'E' })
    );
    Integer queries = Limits.getQueries();
    Test.stopTest();

    // Then: 1차의 결정 안 한 제안만 만료, 채택은 남는다. 목록은 만료 제외 4건, 제안 3건
    Assert.areEqual(
      'EXPIRED',
      [SELECT Status__c FROM CMN_AiRecommendation__c WHERE Id = :first[1]]
      .Status__c
    );
    Assert.areEqual(
      'ADOPTED',
      [SELECT Status__c FROM CMN_AiRecommendation__c WHERE Id = :first[0]]
      .Status__c
    );
    Assert.isTrue(queries < 10, 'record() queries: ' + queries);
    System.runAs(user('aikre')) {
      CMN_AiRecommendationController.View v = CMN_AiRecommendationController.getRecommendations(
        source,
        RCA
      );
      Assert.areEqual(4, v.items.size());
      Assert.areEqual(3, v.proposedCount);
      // 만료된 추천은 결정할 수 없다
      assertAuraMessage(Label.CMN_AiRec_Closed, first[1], 'ADOPTED', null);
    }
  }

  @IsTest
  static void test_BR03_listFollowsPlantSharingAndEditAccess() {
    // Given: KR01 레코드 추천 1건(내용 키·근거 출처 포함)
    Id source = source();
    CMN_AiRecommendationService.Rec r = rec(1, 'A');
    r.title = null;
    r.contentJson = '{"title":"Lens seal","text":"Seal swelled","items":[{"label":"Cause","value":"A"}]}';
    r.sourceRefsJson = JSON.serialize(
      new List<Object>{
        new Map<String, Object>{ 'id' => source, 'label' => 'Similar case' },
        'not-an-id'
      }
    );
    r.rationale = 'Same supplier lot';
    r.score = 0.8765;
    Id recId = CMN_AiRecommendationService.record(
      RCA,
      source,
      new List<CMN_AiRecommendationService.Rec>{ r }
    )[0];
    CMN_AiRecommendation__c saved = [
      SELECT Name, Plant__r.PlantCode__c, SourceObject__c
      FROM CMN_AiRecommendation__c
      WHERE Id = :recId
    ];
    Assert.areEqual('Lens seal', saved.Name);
    Assert.areEqual('KR01', saved.Plant__r.PlantCode__c);
    Assert.areEqual('CMN_TestRecord__c', saved.SourceObject__c);

    // When/Then: KR01 읽기 사용자는 보지만 결정할 수 없다
    System.runAs(user('aikrr')) {
      CMN_AiRecommendationController.View v = CMN_AiRecommendationController.getRecommendations(
        source,
        null
      );
      Assert.areEqual(1, v.items.size());
      CMN_AiRecommendationController.Item i = v.items[0];
      Assert.isFalse(i.canDecide);
      Assert.areEqual('Seal swelled', i.text);
      Assert.areEqual(1, i.details.size());
      Assert.areEqual('Cause', i.details[0].label);
      Assert.areEqual(1, i.refs.size());
      Assert.areEqual('Similar case', i.refs[0].label);
      Assert.areEqual(88, i.scorePercent);
      Assert.areEqual('Same supplier lot', i.rationale);
      assertAuraMessage(Label.CMN_AiRec_NoAccess, recId, 'ADOPTED', null);
    }
    // KR01 편집자는 결정할 수 있다
    System.runAs(user('aikre')) {
      Assert.isTrue(
        CMN_AiRecommendationController.getRecommendations(source, RCA)
          .items[0]
          .canDecide
      );
    }
    // CN01 사용자에게는 보이지 않고 결정도 거부된다
    System.runAs(user('aicne')) {
      Assert.areEqual(
        0,
        CMN_AiRecommendationController.getRecommendations(source, null)
          .items.size()
      );
      assertAuraMessage(Label.CMN_AiRec_NoAccess, recId, 'ADOPTED', null);
    }
  }

  @IsTest
  static void test_invalidInputsAreRejected() {
    Id source = source();
    // 잘못된 UseCase·대상 없음·빈 목록
    assertInvalid('QMS_UNKNOWN', source, recs(new List<String>{ 'A' }));
    assertInvalid(RCA, null, recs(new List<String>{ 'A' }));
    assertInvalid(RCA, source, new List<CMN_AiRecommendationService.Rec>());
    // 순위 중복·깨진 JSON·점수 범위·프롬프트 버전 누락
    List<CMN_AiRecommendationService.Rec> dup = recs(
      new List<String>{ 'A', 'B' }
    );
    dup[1].rank = 1;
    assertInvalid(RCA, source, dup);
    List<CMN_AiRecommendationService.Rec> broken = recs(
      new List<String>{ 'A' }
    );
    broken[0].contentJson = '{broken';
    assertInvalid(RCA, source, broken);
    List<CMN_AiRecommendationService.Rec> score = recs(new List<String>{ 'A' });
    score[0].score = 1.5;
    assertInvalid(RCA, source, score);
    List<CMN_AiRecommendationService.Rec> prompt = recs(
      new List<String>{ 'A' }
    );
    prompt[0].promptVersion = ' ';
    assertInvalid(RCA, source, prompt);
    // 확정: 규칙 없음·결과 JSON 아님
    Boolean failed = false;
    try {
      CMN_AiRecommendationService.finalize(source, RCA, 'x', null);
    } catch (CMN_ValidationException e) {
      failed = true;
    }
    Assert.isTrue(failed);
    // 화면: 잘못된 UseCase·결정 값
    List<Id> ids = CMN_AiRecommendationService.record(
      RCA,
      source,
      recs(new List<String>{ 'A' })
    );
    assertAuraMessage(Label.CMN_Common_InvalidInput, ids[0], 'PROPOSED', null);
    failed = false;
    try {
      CMN_AiRecommendationController.getRecommendations(source, 'QMS_UNKNOWN');
    } catch (AuraHandledException e) {
      failed = e.getMessage() == Label.CMN_Common_InvalidInput;
    }
    Assert.isTrue(failed);
    // 서비스를 거치지 않은 적재(데모)도 제목이 채워진다
    CMN_AiRecommendation__c loaded = new CMN_AiRecommendation__c(
      UseCase__c = RCA,
      SourceRecordId__c = source,
      SourceObject__c = 'CMN_TestRecord__c',
      Rank__c = 9,
      ContentJson__c = '{}',
      PromptVersion__c = 'demo',
      ModelInfo__c = 'demo'
    );
    insert loaded;
    Assert.areEqual(
      'QMS_RCA #9',
      [SELECT Name FROM CMN_AiRecommendation__c WHERE Id = :loaded.Id].Name
    );
  }

  private class CauseHitRule implements CMN_AiHitRule {
    public Boolean isHit(CMN_AiRecommendation__c rec, String outcomeJson) {
      Map<String, Object> content = (Map<String, Object>) JSON.deserializeUntyped(
        rec.ContentJson__c
      );
      Map<String, Object> outcome = (Map<String, Object>) JSON.deserializeUntyped(
        outcomeJson
      );
      return content.get('causeCode') == outcome.get('causeCode');
    }
  }

  private static void assertInvalid(
    String useCase,
    Id source,
    List<CMN_AiRecommendationService.Rec> input
  ) {
    Boolean failed = false;
    try {
      CMN_AiRecommendationService.record(useCase, source, input);
    } catch (CMN_ValidationException e) {
      failed = e.getMessage() == Label.CMN_Common_InvalidInput;
    }
    Assert.isTrue(failed, 'expected invalid input');
  }

  private static void assertAuraMessage(
    String expected,
    Id recId,
    String status,
    String reason
  ) {
    String message;
    try {
      CMN_AiRecommendationController.decide(recId, status, reason);
    } catch (AuraHandledException e) {
      message = e.getMessage();
    }
    Assert.areEqual(expected, message);
  }

  private static List<CMN_AiRecommendationService.Rec> recs(
    List<String> causes
  ) {
    List<CMN_AiRecommendationService.Rec> out = new List<CMN_AiRecommendationService.Rec>();
    for (Integer i = 0; i < causes.size(); i++) {
      out.add(rec(i + 1, causes[i]));
    }
    return out;
  }

  private static CMN_AiRecommendationService.Rec rec(
    Integer rank,
    String cause
  ) {
    CMN_AiRecommendationService.Rec r = new CMN_AiRecommendationService.Rec();
    r.rank = rank;
    r.title = 'Cause ' + cause;
    r.contentJson = '{"causeCode":"' + cause + '"}';
    r.promptVersion = 'rca-v1';
    r.modelInfo = 'test-model';
    r.score = 0.5;
    return r;
  }

  private static Map<Integer, CMN_AiRecommendation__c> byRank(Id source) {
    Map<Integer, CMN_AiRecommendation__c> out = new Map<Integer, CMN_AiRecommendation__c>();
    String sourceText = source;
    for (CMN_AiRecommendation__c r : [
      SELECT
        Rank__c,
        IsHit__c,
        DecidedBy__c,
        DecidedAt__c,
        FinalizedAt__c,
        FinalOutcomeJson__c
      FROM CMN_AiRecommendation__c
      WHERE SourceRecordId__c = :sourceText
    ]) {
      out.put(r.Rank__c.intValue(), r);
    }
    return out;
  }

  private static Id source() {
    return [SELECT Id FROM CMN_TestRecord__c LIMIT 1].Id;
  }

  private static CMN_Plant__c plant(Id companyId, String code, String tz) {
    return new CMN_Plant__c(
      Name = code,
      PlantCode__c = code,
      Company__c = companyId,
      Region__c = 'KR',
      TimeZone__c = tz,
      DefaultLanguage__c = 'ko'
    );
  }

  private static CMN_Code__c code(Id groupId, String value, Integer sortOrder) {
    return new CMN_Code__c(
      Name = value,
      NameEn__c = value,
      CodeGroup__c = groupId,
      Code__c = value,
      Level__c = 1,
      SortOrder__c = sortOrder,
      IsActive__c = true
    );
  }

  private static CMN_UserPlantAccess__c access(
    Id userId,
    Id plantId,
    String level
  ) {
    return new CMN_UserPlantAccess__c(
      User__c = userId,
      Plant__c = plantId,
      AccessLevel__c = level
    );
  }

  private static User user(String alias) {
    return [SELECT Id FROM User WHERE Alias = :alias LIMIT 1];
  }
}
