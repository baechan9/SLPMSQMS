/**
 * @description 삭제 통제·삭제 기록 검증(CMN-00-SEC-003). 4M·NCR 대신 테스트 대상 객체(규칙: Status__c, DRAFT만 삭제)로 검증한다(CR-11·DEV-3).
 * @group CMN-00-SEC-003
 */
@IsTest
private class CMN_DeleteGuardService_Test {
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
    insert new List<CMN_TestRecord__c>{
      new CMN_TestRecord__c(
        Name = 'approved',
        Plant__c = p.Id,
        Status__c = 'APPROVED'
      ),
      new CMN_TestRecord__c(
        Name = 'draft',
        Plant__c = p.Id,
        Status__c = 'DRAFT'
      )
    };
  }

  @IsTest
  static void test_AC01_approvedRecordCannotBeDeletedEvenByAdmin() {
    // Given: APPROVED 레코드, 실행 사용자는 관리자. 핸들러 코드 우회도 켬
    CMN_TestRecord__c approved = byName('approved');
    CMN_TriggerHandler.bypass('CMN_TestRecord__c');

    // When: 삭제
    Database.DeleteResult r = Database.delete(approved.Id, false);

    // Then: 차단(상태가 든 라벨 문구), 기록 없음
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      String.format(
        Label.CMN_Delete_NotAllowedStatus,
        new List<Object>{ 'APPROVED' }
      ),
      r.getErrors()[0].getMessage()
    );
    Assert.areEqual(0, [SELECT COUNT() FROM CMN_DeleteLog__c]);
  }

  @IsTest
  static void test_AC02_draftDeleteLeavesSnapshot() {
    // Given: DRAFT 레코드와 UI 삭제 사유
    CMN_TestRecord__c draft = byName('draft');
    CMN_DeleteGuardService.setReason('오입력');

    // When
    delete draft;

    // Then: 삭제 기록 1건(전 필드 JSON, 번호·삭제자·사유)
    CMN_DeleteLog__c log = [
      SELECT
        ObjectApiName__c,
        RecordIdText__c,
        RecordNo__c,
        Snapshot__c,
        DeletedBy__c,
        DeletedAt__c,
        Reason__c
      FROM CMN_DeleteLog__c
    ];
    Assert.areEqual('CMN_TestRecord__c', log.ObjectApiName__c);
    Assert.areEqual(String.valueOf(draft.Id), log.RecordIdText__c);
    Assert.areEqual(draft.RecordNo__c, log.RecordNo__c);
    Assert.areEqual(UserInfo.getUserId(), log.DeletedBy__c);
    Assert.areEqual('오입력', log.Reason__c);
    Map<String, Object> snap = (Map<String, Object>) JSON.deserializeUntyped(
      log.Snapshot__c
    );
    Assert.areEqual('DRAFT', snap.get('Status__c'));
    Assert.areEqual('draft', snap.get('Name'));
    Assert.isTrue(snap.containsKey('Plant__c'));
    Assert.isTrue(snap.containsKey('CreatedDate'));
  }

  @IsTest
  static void test_AC03_deleteLogCannotBeChangedByAnyone() {
    // Given: 삭제 기록 1건, 권한 없는 일반 사용자
    delete byName('draft');
    CMN_DeleteLog__c log = [SELECT Id FROM CMN_DeleteLog__c];
    User normal = CMN_TestDataFactory.newUser(
      'dlog1',
      'Normal',
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert normal;
    }

    // When / Then: 일반 사용자 수정은 권한 없음(객체 접근 거부)
    System.runAs(normal) {
      try {
        Database.update(
          new CMN_DeleteLog__c(Id = log.Id, Reason__c = 'x'),
          AccessLevel.USER_MODE
        );
        Assert.fail('권한 없음이어야 한다');
      } catch (SecurityException e) {
        Assert.isNotNull(e.getMessage());
      }
    }
    // 관리자 수정·삭제·직접 생성도 트리거가 막는다
    Database.SaveResult upd = Database.update(
      new CMN_DeleteLog__c(Id = log.Id, Reason__c = 'x'),
      false
    );
    Database.DeleteResult del = Database.delete(log.Id, false);
    Database.SaveResult ins = Database.insert(
      new CMN_DeleteLog__c(
        ObjectApiName__c = 'X',
        RecordIdText__c = 'x',
        DeletedBy__c = UserInfo.getUserId(),
        DeletedAt__c = Datetime.now()
      ),
      false
    );
    Assert.areEqual(
      Label.CMN_Delete_LogReadOnly,
      upd.getErrors()[0].getMessage()
    );
    Assert.isFalse(del.isSuccess());
    Assert.isFalse(ins.isSuccess());
  }

  @IsTest
  static void test_bulk200DraftDeletes() {
    // Given: DRAFT 200건
    Id plant = [SELECT Id FROM CMN_Plant__c].Id;
    List<CMN_TestRecord__c> recs = new List<CMN_TestRecord__c>();
    for (Integer i = 0; i < 200; i++) {
      recs.add(
        new CMN_TestRecord__c(
          Name = 'B' + i,
          Plant__c = plant,
          Status__c = 'DRAFT'
        )
      );
    }
    insert recs;

    // When
    Integer dmlBefore = Limits.getDmlStatements();
    delete recs;
    Integer dml = Limits.getDmlStatements() - dmlBefore;

    // Then: 기록 200건, 삭제 1회 + 기록 1회
    Assert.areEqual(200, [SELECT COUNT() FROM CMN_DeleteLog__c]);
    Assert.areEqual(2, dml);
  }

  @IsTest
  static void test_unregisteredObjectNotGuarded() {
    // Given: 규칙을 비활성으로(등록 없음과 같게) 덮어씀
    CMN_DeleteGuardService.guardsOverride = new Map<String, CMN_DeleteGuard__mdt>{
      'CMN_TestRecord__c' => new CMN_DeleteGuard__mdt(
        ObjectApiName__c = 'CMN_TestRecord__c'
      )
    };

    // When: APPROVED 삭제
    Database.DeleteResult r = Database.delete(byName('approved').Id, false);

    // Then: 상태 필드가 없는 규칙은 막지 않고 기록만 남긴다
    Assert.isTrue(r.isSuccess());
    Assert.areEqual(1, [SELECT COUNT() FROM CMN_DeleteLog__c]);
  }

  private static CMN_TestRecord__c byName(String name) {
    return [SELECT Id, RecordNo__c FROM CMN_TestRecord__c WHERE Name = :name];
  }
}
