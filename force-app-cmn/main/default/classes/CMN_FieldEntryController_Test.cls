/**
 * @description 현장 입력 셸(CMN-00-UX-008): 규격 비교·반올림(AC-1), NG 사진 필수(AC-5), 편집 불가(AC-7), 중간·최종 저장,
 * 스캔 확인(BR-6), Provider 등록·설정 오류, 입력 범위 검증. 샘플 Provider(CMN_TestFieldEntryProvider)와 테스트 객체를 쓴다.
 * 화면 동작(즉시 미리보기·서버 호출 없는 이동·초안 복원·세로 붙여넣기·전송 대기)은 Jest에서 확인한다.
 * @group CMN-00-UX-008
 */
@IsTest
private class CMN_FieldEntryController_Test {
  @TestSetup
  static void setup() {
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User owner = CMN_TestDataFactory.newUser(
      'fenown',
      'Entry Owner',
      profileId
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert owner;
      insert new PermissionSetAssignment(
        AssigneeId = owner.Id,
        PermissionSetId = [
          SELECT Id
          FROM PermissionSet
          WHERE Name = 'CMN_PS_DataMigration'
        ]
        .Id
      );
    }
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    insert new CMN_Plant__c(
      Name = 'KR01',
      PlantCode__c = 'KR01',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
  }

  @IsTest
  static void test_AC01_variableRoundsBeforeComparingSpecs() {
    // Given: LSL 1.0, USL 2.0, 소수 2자리 / 한쪽 규격(LSL 10)
    CMN_FieldEntry.Item item = new CMN_FieldEntry.Item();
    item.key = 'OUTER';
    item.type = CMN_FieldEntry.TYPE_VARIABLE;
    item.lsl = 1.0;
    item.usl = 2.0;
    item.decimals = 2;
    // When / Then
    Assert.areEqual(
      CMN_FieldEntry.FAIL,
      CMN_FieldEntry.judgeValue(item, num(2.05))
    );
    Assert.areEqual(
      CMN_FieldEntry.PASS,
      CMN_FieldEntry.judgeValue(item, num(2.004))
    );
    Assert.areEqual(
      CMN_FieldEntry.PASS,
      CMN_FieldEntry.judgeValue(item, num(1.0))
    );
    Assert.areEqual(
      CMN_FieldEntry.FAIL,
      CMN_FieldEntry.judgeValue(item, num(0.994))
    );
    Assert.areEqual(
      CMN_FieldEntry.PASS,
      CMN_FieldEntry.judgeValue(item, num(0.995))
    );
    Assert.areEqual(
      CMN_FieldEntry.INCOMPLETE,
      CMN_FieldEntry.judgeValue(item, null)
    );
    item.usl = null;
    item.lsl = 10;
    item.decimals = null;
    Assert.areEqual(
      CMN_FieldEntry.PASS,
      CMN_FieldEntry.judgeValue(item, num(99))
    );
    Assert.areEqual(
      CMN_FieldEntry.FAIL,
      CMN_FieldEntry.judgeValue(item, num(9.99))
    );
    // 계수형·서술형
    CMN_FieldEntry.Item attr = new CMN_FieldEntry.Item();
    attr.type = CMN_FieldEntry.TYPE_ATTRIBUTE;
    CMN_FieldEntry.Value ng = new CMN_FieldEntry.Value();
    ng.okNg = CMN_FieldEntry.NG;
    Assert.areEqual(CMN_FieldEntry.FAIL, CMN_FieldEntry.judgeValue(attr, ng));
    CMN_FieldEntry.Item text = new CMN_FieldEntry.Item();
    text.type = CMN_FieldEntry.TYPE_TEXT;
    Assert.areEqual(
      CMN_FieldEntry.INCOMPLETE,
      CMN_FieldEntry.judgeValue(text, new CMN_FieldEntry.Value())
    );
    Assert.areEqual(
      CMN_FieldEntry.FAIL,
      CMN_FieldEntry.overall(
        new Map<String, String>{
          'A' => CMN_FieldEntry.PASS,
          'B' => CMN_FieldEntry.FAIL,
          'C' => CMN_FieldEntry.INCOMPLETE
        }
      )
    );
  }

  @IsTest
  static void test_loadAndSaveThroughSampleProvider() {
    // Given: 진행 중 테스트 레코드
    Id rec = record('IN_PROGRESS');
    System.runAs(user()) {
      // When: 시트 로드
      CMN_FieldEntry.Sheet s = CMN_FieldEntryController.load(rec);
      // Then: 항목 5개, 편집 가능, 헤더 보조 정보 라벨
      Assert.areEqual(5, s.items.size());
      Assert.isTrue(s.editable);
      Assert.isTrue(s.lotCheck);
      Assert.areEqual(
        Label.CMN_FieldEntry_SampleLotLabel,
        s.header.extras[0].label
      );
      Assert.areEqual(1, s.items[0].sequence);

      // When: 외경 5시료 중간 저장(1개 불합격)
      List<CMN_FieldEntry.Value> outerValues = new List<CMN_FieldEntry.Value>();
      for (Integer n = 1; n <= 5; n++) {
        outerValues.add(value('OUTER', n, n == 3 ? 2.05 : 1.5));
      }
      CMN_FieldEntry.SaveResult mid = CMN_FieldEntryController.save(
        rec,
        JSON.serialize(outerValues),
        false
      );
      // Then: 항목 불합격, 전체 불합격, 레코드 판정은 아직 없음
      Assert.isTrue(mid.success);
      Assert.areEqual(CMN_FieldEntry.FAIL, mid.itemResults.get('OUTER'));
      Assert.areEqual(CMN_FieldEntry.INCOMPLETE, mid.itemResults.get('HEIGHT'));
      Assert.isNull(
        [SELECT EntryResult__c FROM CMN_TestRecord__c WHERE Id = :rec]
        .EntryResult__c
      );

      // When: 한 시료를 고쳐 다시 저장(합치기) → 다시 열면 값이 남아 있다
      CMN_FieldEntryController.save(
        rec,
        JSON.serialize(new List<Object>{ value('OUTER', 3, 2.004) }),
        false
      );
      CMN_FieldEntry.Sheet again = CMN_FieldEntryController.load(rec);
      Assert.areEqual(5, again.values.size());

      // When: 나머지 항목을 채워 최종 판정
      List<CMN_FieldEntry.Value> rest = new List<CMN_FieldEntry.Value>();
      for (Integer n = 1; n <= 3; n++) {
        rest.add(value('HEIGHT', n, 10.5));
      }
      for (Integer n = 1; n <= 5; n++) {
        rest.add(okNg('BUBBLE', n, CMN_FieldEntry.OK));
      }
      rest.add(okNg('SCRATCH', 1, CMN_FieldEntry.OK));
      rest.add(okNg('SCRATCH', 2, CMN_FieldEntry.OK));
      CMN_FieldEntry.Value note = new CMN_FieldEntry.Value();
      note.itemKey = 'NOTE';
      note.sampleNo = 1;
      note.text = 'ok';
      rest.add(note);
      // 측정기 번호 없는 외경 값으로 최종 저장 → 측정기 필수 오류(BR-6)
      List<CMN_FieldEntry.Value> withOuter = new List<CMN_FieldEntry.Value>(
        rest
      );
      for (Integer n = 1; n <= 5; n++) {
        withOuter.add(value('OUTER', n, n == 3 ? 2.004 : 1.5));
      }
      CMN_FieldEntry.SaveResult noGauge = CMN_FieldEntryController.save(
        rec,
        JSON.serialize(withOuter),
        true
      );
      Assert.isFalse(noGauge.success);
      Assert.areEqual(1, noGauge.errors.size());
      Assert.areEqual('OUTER', noGauge.errors[0].itemKey);
      for (CMN_FieldEntry.Value v : withOuter) {
        v.gaugeNo = v.itemKey == 'OUTER' ? 'G-0012' : null;
      }
      CMN_FieldEntry.SaveResult fin = CMN_FieldEntryController.save(
        rec,
        JSON.serialize(withOuter),
        true
      );
      // Then: 반올림 2.00으로 합격 → 전체 합격, 레코드에 판정
      Assert.isTrue(fin.success, String.valueOf(fin.errors));
      Assert.areEqual(CMN_FieldEntry.PASS, fin.overall);
      Assert.isNull(fin.nextActionLabel);
    }
    Assert.areEqual(
      CMN_FieldEntry.PASS,
      [SELECT EntryResult__c FROM CMN_TestRecord__c WHERE Id = :rec]
      .EntryResult__c
    );
  }

  @IsTest
  static void test_AC05_ngWithoutPhotoBlocksFinalSave() {
    // Given: NG 사진 필수 항목(기포)과 외관 항목(긁힘)에 사진 없는 NG
    Id rec = record('IN_PROGRESS');
    System.runAs(user()) {
      List<CMN_FieldEntry.Value> values = new List<CMN_FieldEntry.Value>{
        okNg('BUBBLE', 2, CMN_FieldEntry.NG),
        okNg('SCRATCH', 1, CMN_FieldEntry.NG),
        okNg('SCRATCH', 2, CMN_FieldEntry.OK)
      };
      // When
      CMN_FieldEntry.SaveResult r = CMN_FieldEntryController.save(
        rec,
        JSON.serialize(values),
        true
      );
      // Then: 미충족 2건, 저장 안 됨
      Assert.isFalse(r.success);
      Assert.areEqual(2, r.errors.size());
      Assert.areEqual('BUBBLE', r.errors[0].itemKey);
      Assert.areEqual(2, r.errors[0].sampleNo);

      // When: 사진을 붙이면 → Then 최종 저장(불합격 → 후속 안내)
      values[0].photoIds = new List<Id>{ rec };
      values[1].photoIds = new List<Id>{ rec };
      CMN_FieldEntry.SaveResult ok = CMN_FieldEntryController.save(
        rec,
        JSON.serialize(values),
        true
      );
      Assert.isTrue(ok.success, String.valueOf(ok.errors));
      Assert.areEqual(CMN_FieldEntry.FAIL, ok.overall);
      Assert.areEqual(Label.CMN_FieldEntry_SampleNextNcr, ok.nextActionLabel);

      // 중간 저장은 사진을 묻지 않는다
      CMN_FieldEntry.SaveResult mid = CMN_FieldEntryController.save(
        rec,
        JSON.serialize(
          new List<Object>{ okNg('BUBBLE', 3, CMN_FieldEntry.NG) }
        ),
        false
      );
      Assert.isTrue(mid.success);
    }
  }

  @IsTest
  static void test_AC07_readOnlyWhenRuleDenies() {
    // Given: 완료 상태(편집 규칙 밖)
    Id rec = record('DONE');
    System.runAs(user()) {
      // When
      CMN_FieldEntry.Sheet s = CMN_FieldEntryController.load(rec);
      CMN_FieldEntry.SaveResult r = CMN_FieldEntryController.save(
        rec,
        JSON.serialize(new List<Object>{ value('OUTER', 1, 1.5) }),
        false
      );
      // Then: 읽기 전용, 저장 거부
      Assert.isFalse(s.editable);
      Assert.isFalse(r.success);
      Assert.areEqual(Label.CMN_FieldEntry_NotEditable, r.errors[0].message);
    }
    Assert.isNull(
      [SELECT EntryJson__c FROM CMN_TestRecord__c WHERE Id = :rec].EntryJson__c
    );
  }

  @IsTest
  static void test_BR6_validateScan() {
    Id rec = record('IN_PROGRESS');
    String no = [SELECT RecordNo__c FROM CMN_TestRecord__c WHERE Id = :rec]
    .RecordNo__c;
    System.runAs(user()) {
      Assert.isNull(
        CMN_FieldEntryController.validateScan(rec, 'LOT', no.toLowerCase())
      );
      Assert.areEqual(
        Label.CMN_FieldEntry_SampleLotMismatch,
        CMN_FieldEntryController.validateScan(rec, 'LOT', 'OTHER')
      );
      Assert.isNull(
        CMN_FieldEntryController.validateScan(rec, 'GAUGE', 'G-0012')
      );
      Assert.areEqual(
        Label.CMN_FieldEntry_SampleGaugeInvalid,
        CMN_FieldEntryController.validateScan(rec, 'GAUGE', '12')
      );
      Assert.areEqual(
        Label.CMN_FieldEntry_InvalidScan,
        CMN_FieldEntryController.validateScan(rec, 'SERIAL', 'x')
      );
      Assert.areEqual(
        Label.CMN_FieldEntry_InvalidScan,
        CMN_FieldEntryController.validateScan(rec, 'LOT', ' ')
      );
    }
  }

  @IsTest
  static void test_negative_registryAndInputs() {
    Id rec = record('IN_PROGRESS');
    Id plant = [SELECT Id FROM CMN_Plant__c LIMIT 1].Id;
    System.runAs(user()) {
      // 등록 없는 객체·레코드 없음
      expectAura(Label.CMN_FieldEntry_NoProvider, plant);
      expectAura(Label.CMN_Common_InvalidInput, null);
      // 범위 밖 시료·없는 항목·잘못된 OK/NG·깨진 JSON
      for (
        String bad : new List<String>{
          JSON.serialize(new List<Object>{ value('OUTER', 6, 1.5) }),
          JSON.serialize(new List<Object>{ value('NOPE', 1, 1.5) }),
          JSON.serialize(new List<Object>{ okNg('BUBBLE', 1, 'MAYBE') }),
          '{broken'
        }
      ) {
        try {
          CMN_FieldEntryController.save(rec, bad, false);
          Assert.fail('거부: ' + bad);
        } catch (AuraHandledException e) {
          Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
        }
      }
    }
    // 설정 오류: 인터페이스를 구현하지 않은 클래스·없는 클래스
    for (
      String cls : new List<String>{ 'CMN_FieldEntry', 'No_Such_Class', '../x' }
    ) {
      CMN_FieldEntryController.registryOverride = new Map<String, String>{
        'CMN_TestRecord__c' => cls
      };
      System.runAs(user()) {
        expectAura(Label.CMN_FieldEntry_NoProvider, rec);
      }
    }
    // 예상하지 못한 오류(Provider 안 예외)는 일반 문구
    CMN_FieldEntryController.registryOverride = new Map<String, String>{
      'CMN_TestRecord__c' => 'CMN_TestFieldEntryProvider'
    };
    // 레코드를 읽을 수 없게 되면(이관 권한 회수) Provider 조회가 실패한다
    Id ownerId = user().Id;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      delete [
        SELECT Id
        FROM PermissionSetAssignment
        WHERE
          AssigneeId = :ownerId
          AND PermissionSet.Name = 'CMN_PS_DataMigration'
      ];
    }
    System.runAs(user()) {
      expectAura(Label.CMN_Common_UnexpectedError, rec);
      try {
        CMN_FieldEntryController.validateScan(rec, 'LOT', 'x');
        Assert.fail('예외');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_UnexpectedError, e.getMessage());
      }
    }
  }

  // ------------------------------------------------------------------ 도우미
  private static void expectAura(String message, Id recordId) {
    try {
      CMN_FieldEntryController.load(recordId);
      Assert.fail('거부');
    } catch (AuraHandledException e) {
      Assert.areEqual(message, e.getMessage());
    }
  }

  private static CMN_FieldEntry.Value num(Decimal v) {
    CMN_FieldEntry.Value x = new CMN_FieldEntry.Value();
    x.numValue = v;
    return x;
  }

  private static CMN_FieldEntry.Value value(String key, Integer n, Decimal v) {
    CMN_FieldEntry.Value x = num(v);
    x.itemKey = key;
    x.sampleNo = n;
    return x;
  }

  private static CMN_FieldEntry.Value okNg(String key, Integer n, String r) {
    CMN_FieldEntry.Value x = new CMN_FieldEntry.Value();
    x.itemKey = key;
    x.sampleNo = n;
    x.okNg = r;
    return x;
  }

  private static Id record(String status) {
    CMN_TestRecord__c r = new CMN_TestRecord__c(
      Name = 'Entry ' + status,
      Plant__c = [SELECT Id FROM CMN_Plant__c LIMIT 1]
      .Id,
      Status__c = status,
      OwnerId = user().Id
    );
    insert r;
    return r.Id;
  }

  private static User user() {
    return [
      SELECT Id
      FROM User
      WHERE Alias = 'fenown' AND Username LIKE '%@test.slqms.example.com'
      LIMIT 1
    ];
  }
}
