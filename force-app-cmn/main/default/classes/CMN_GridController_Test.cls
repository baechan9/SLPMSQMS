/**
 * @description 공통 편집 그리드(CMN-00-UX-006): 로드 조회 수(AC-1), 붙여넣기 참조 확인(AC-2), 저장 DML 수(AC-3),
 * Provider 오류 시 전체 미저장(AC-4), 버전 충돌(AC-5), FLS 없는 열(AC-6), 편집 규칙(AC-9), 행 메타 서버 재검증(BR-11),
 * 200행 일괄, 후처리 실패 롤백, 입력·설정 오류. 배포된 샘플 그리드(CMN_TestRecordLines)와 대체 정의를 함께 쓴다.
 * @group CMN-00-UX-006
 */
@IsTest
private class CMN_GridController_Test {
  private static final String GRID = 'CMN_TestRecordLines';
  private static final String LINE = 'CMN_TestRecordLine__c';

  @TestSetup
  static void setup() {
    Id profileId = CMN_TestDataFactory.profileIdForLicense(
      'Salesforce Platform'
    );
    User owner = CMN_TestDataFactory.newUser('grdown', 'Grid Owner', profileId);
    User fls = CMN_TestDataFactory.newUser('grdfls', 'Grid Fls', profileId);
    User bare = CMN_TestDataFactory.newUser('grdbar', 'Grid Bare', profileId);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<User>{ owner, fls, bare };
      Id full = testPermissionSet('CMN_GridTest_Full', new Set<String>());
      Id noNote = testPermissionSet(
        'CMN_GridTest_NoNote',
        new Set<String>{ LINE + '.Note__c' }
      );
      List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>{
        new PermissionSetAssignment(
          AssigneeId = owner.Id,
          PermissionSetId = full
        ),
        new PermissionSetAssignment(
          AssigneeId = fls.Id,
          PermissionSetId = noNote
        )
      };
      for (PermissionSet ps : [
        SELECT Id
        FROM PermissionSet
        WHERE Name IN ('CMN_PS_Site_Read', 'CMN_PS_Code_Read')
      ]) {
        psas.add(
          new PermissionSetAssignment(
            AssigneeId = owner.Id,
            PermissionSetId = ps.Id
          )
        );
        psas.add(
          new PermissionSetAssignment(
            AssigneeId = fls.Id,
            PermissionSetId = ps.Id
          )
        );
      }
      insert psas;
    }
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    insert new List<CMN_Plant__c>{
      new CMN_Plant__c(
        Name = 'KR01',
        PlantCode__c = 'KR01',
        Company__c = c.Id,
        Region__c = 'KR',
        TimeZone__c = 'Asia/Seoul',
        DefaultLanguage__c = 'ko'
      ),
      new CMN_Plant__c(
        Name = 'KR02',
        PlantCode__c = 'P-02',
        Company__c = c.Id,
        Region__c = 'KR',
        TimeZone__c = 'Asia/Seoul',
        DefaultLanguage__c = 'ko'
      )
    };
    CMN_CodeGroup__c g = new CMN_CodeGroup__c(
      Name = 'Defect type',
      GroupCode__c = 'DEFECT_TYPE',
      MaxLevel__c = 2
    );
    insert g;
    CMN_Code__c appearance = new CMN_Code__c(
      CodeGroup__c = g.Id,
      Code__c = 'APPEARANCE',
      Name = 'Appearance'
    );
    insert appearance;
    insert new List<CMN_Code__c>{
      new CMN_Code__c(
        CodeGroup__c = g.Id,
        Code__c = 'SCRATCH',
        Name = 'Scratch',
        Parent__c = appearance.Id
      ),
      new CMN_Code__c(
        CodeGroup__c = g.Id,
        Code__c = 'SCRATCH2',
        Name = 'Scratch',
        Parent__c = appearance.Id
      )
    };
  }

  @IsTest
  static void test_AC01_loadReadsRowsWithOneQuery() {
    // Given: 60행 × 12열 그리드(대체 정의, 시스템 필드 2열 포함)
    Id parent = parentFor(user('grdown'), 'DRAFT');
    insertLines(parent, 60, Date.today());
    List<String> fields = new List<String>{
      'LineNo__c',
      'Name',
      'Category__c',
      'Quantity__c',
      'StartDate__c',
      'EndDate__c',
      'Code__c',
      'Plant__c',
      'IsDone__c',
      'Note__c',
      'CreatedDate',
      'CreatedById'
    };
    useDefinition(definition('Big', new Map<String, Object>()), fields);
    System.runAs(user('grdown')) {
      // When
      Integer before = Limits.getQueries();
      CMN_GridService.GridView v = CMN_GridController.load('Big', parent);
      Integer used = Limits.getQueries() - before;

      // Then: 행 조회 1회 + 부모 편집 권한 1회 + 편집 규칙 1회(행·열 수와 무관)
      Assert.isTrue(used <= 3, 'SOQL ' + used);
      Assert.areEqual(12, v.columns.size());
      Assert.areEqual(60, v.rows.size());
      Assert.isTrue(v.editable);
      Assert.isTrue(v.allowAdd && v.allowDelete && v.allowPaste);
      Assert.isFalse(v.truncated);
      Assert.areEqual('StartDate__c', v.scheduleStartField);
      Assert.isTrue(v.clientVersion.startsWith('60:'), v.clientVersion);
      Assert.areEqual(1, ((Decimal) v.rows[0].get('LineNo__c')).intValue());
      Assert.areEqual('KR01', v.rows[0].get('__d_Plant__c'));
      Map<String, CMN_GridService.ColumnView> byField = columns(v);
      Assert.areEqual('DISPLAY', byField.get('CreatedDate').inputType);
      Assert.isFalse(byField.get('CreatedDate').editable);
      Assert.areEqual('PICKLIST', byField.get('Category__c').inputType);
      Assert.areEqual(3, byField.get('Category__c').options.size());
      Assert.isTrue(byField.get('Name').required);
      Assert.areEqual('PLAN', v.defaults.get('Category__c'));
    }

    // Given: 최대 50행 → When 로드 → Then 앞 50행과 잘림 표시
    useDefinition(
      definition('Big', new Map<String, Object>{ 'MaxRows__c' => 50 }),
      fields
    );
    System.runAs(user('grdown')) {
      CMN_GridService.GridView cut = CMN_GridController.load('Big', parent);
      Assert.isTrue(cut.truncated);
      Assert.areEqual(50, cut.rows.size());
      Assert.isTrue(cut.clientVersion.startsWith('51:'), cut.clientVersion);
    }
  }

  @IsTest
  static void test_AC02_resolveLookupsForPaste() {
    // Given: 공장 KR01·KR02, 같은 이름 코드 2개(Scratch)
    Id parent = parentFor(user('grdown'), 'DRAFT');
    CMN_Code__c appearance = [
      SELECT Id, ExternalKey__c
      FROM CMN_Code__c
      WHERE Code__c = 'APPEARANCE'
    ];
    System.runAs(user('grdown')) {
      // When: 이름(대소문자 무시)·없는 값·외부 키·같은 이름 여러 건, 참조가 아닌 열
      List<CMN_GridService.LookupMatch> found = CMN_GridController.resolveLookups(
        GRID,
        parent,
        JSON.serialize(
          new Map<String, Object>{
            'Plant__c' => new List<String>{ 'KR01', 'kr02', 'ZZ99', 'P-02' },
            'Code__c' => new List<String>{
              appearance.ExternalKey__c,
              'Scratch'
            },
            'Note__c' => new List<String>{ 'x' }
          }
        )
      );

      // Then
      Map<String, CMN_GridService.LookupMatch> byKey = new Map<String, CMN_GridService.LookupMatch>();
      for (CMN_GridService.LookupMatch m : found) {
        byKey.put(m.fieldApiName + '|' + m.key, m);
      }
      Assert.areEqual(6, found.size(), 'Note__c(참조 아님)는 무시');
      // 이름이 아니라 External ID(공장 코드)로도 찾는다
      Assert.isNotNull(byKey.get('Plant__c|P-02').id);
      Assert.areEqual(
        [SELECT Id FROM CMN_Plant__c WHERE PlantCode__c = 'KR01'].Id,
        byKey.get('Plant__c|KR01').id
      );
      Assert.isNotNull(byKey.get('Plant__c|kr02').id);
      Assert.isNull(byKey.get('Plant__c|ZZ99').id);
      Assert.areEqual(
        appearance.Id,
        byKey.get('Code__c|' + appearance.ExternalKey__c).id
      );
      Assert.isNull(byKey.get('Code__c|Scratch').id);
      Assert.isTrue(byKey.get('Code__c|Scratch').ambiguous);

      // When: Id로 표시명 확인(셀 편집 뒤)
      Id kr01 = byKey.get('Plant__c|KR01').id;
      List<CMN_GridService.LookupMatch> byId = CMN_GridController.resolveLookups(
        GRID,
        parent,
        JSON.serialize(
          new Map<String, Object>{ 'Plant__c' => new List<String>{ kr01 } }
        )
      );
      Assert.areEqual(kr01, byId[0].id);
      Assert.areEqual('KR01', byId[0].label);

      // When: 서로 다른 값 201개 → Then 거부
      List<String> many = new List<String>();
      for (Integer i = 0; i < 201; i++) {
        many.add('P' + i);
      }
      try {
        CMN_GridController.resolveLookups(
          GRID,
          parent,
          JSON.serialize(new Map<String, Object>{ 'Plant__c' => many })
        );
        Assert.fail('201개는 거부');
      } catch (AuraHandledException e) {
        Assert.areEqual(
          String.format(Label.CMN_Grid_LookupTooMany, new List<Object>{ 200 }),
          e.getMessage()
        );
      }
      // When: 형식 오류 → Then 거부
      try {
        CMN_GridController.resolveLookups(GRID, parent, '[1]');
        Assert.fail('형식 오류는 거부');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Grid_InvalidRequest, e.getMessage());
      }
    }
  }

  @IsTest
  static void test_AC03_saveWritesWithTwoDataDml() {
    // Given: 5행
    Id parent = parentFor(user('grdown'), 'DRAFT');
    List<CMN_TestRecordLine__c> lines = insertLines(parent, 5, Date.today());
    System.runAs(user('grdown')) {
      CMN_GridService.GridView v = CMN_GridController.load(GRID, parent);
      List<Map<String, Object>> rows = new List<Map<String, Object>>{
        change(lines[0].Id, new Map<String, Object>{ 'Quantity__c' => 7 }),
        change(lines[1].Id, new Map<String, Object>{ 'Name' => 'Renamed' }),
        change(
          lines[2].Id,
          new Map<String, Object>{
            'EndDate__c' => String.valueOf(Date.today().addDays(10))
          }
        ),
        newRow('new-1', new Map<String, Object>{ 'Name' => 'Added' })
      };

      // When: 3행 수정 + 1행 추가 + 1행 삭제
      Integer before = Limits.getDmlStatements();
      CMN_GridService.SaveResult r = CMN_GridController.save(
        GRID,
        parent,
        JSON.serialize(rows),
        new List<Id>{ lines[4].Id },
        v.clientVersion
      );
      Integer used = Limits.getDmlStatements() - before;

      // Then: upsert 1 + delete 1 (+ Savepoint 1), 결과 반영, 최신 그리드 반환
      Assert.isTrue(r.success, String.valueOf(r.rowErrors) + r.gridErrors);
      Assert.areEqual(3, used, 'DML 문 ' + used);
      Assert.areEqual(4, r.savedCount);
      Assert.areEqual(1, r.deletedCount);
      Assert.areEqual(5, r.view.rows.size());
      Assert.areNotEqual(v.clientVersion, r.view.clientVersion);
    }
    Map<String, CMN_TestRecordLine__c> byName = new Map<String, CMN_TestRecordLine__c>();
    for (CMN_TestRecordLine__c l : [
      SELECT Name, Quantity__c, EndDate__c, LineNo__c, Category__c, StartDate__c
      FROM CMN_TestRecordLine__c
      WHERE TestRecord__c = :parent
    ]) {
      byName.put(l.Name, l);
    }
    Assert.areEqual(5, byName.size());
    Assert.areEqual(7, byName.get('Line 1').Quantity__c.intValue());
    Assert.isTrue(byName.containsKey('Renamed'));
    Assert.areEqual(Date.today().addDays(10), byName.get('Line 3').EndDate__c);
    Assert.isFalse(byName.containsKey('Line 5'));
    // 새 행: 마지막 순서 + 1, Provider 기본값
    Assert.areEqual(6, byName.get('Added').LineNo__c.intValue());
    Assert.areEqual('PLAN', byName.get('Added').Category__c);
    Assert.areEqual(Date.today(), byName.get('Added').StartDate__c);
  }

  @IsTest
  static void test_AC04_providerErrorsSaveNothing() {
    // Given: 3행
    Id parent = parentFor(user('grdown'), 'DRAFT');
    List<CMN_TestRecordLine__c> lines = insertLines(parent, 3, Date.today());
    System.runAs(user('grdown')) {
      CMN_GridService.GridView v = CMN_GridController.load(GRID, parent);
      String past = String.valueOf(Date.today().addDays(-5));
      List<Map<String, Object>> rows = new List<Map<String, Object>>{
        change(lines[0].Id, new Map<String, Object>{ 'EndDate__c' => past }),
        change(lines[1].Id, new Map<String, Object>{ 'Quantity__c' => -1 }),
        change(lines[2].Id, new Map<String, Object>{ 'Name' => 'Valid' })
      };

      // When
      CMN_GridService.SaveResult r = CMN_GridController.save(
        GRID,
        parent,
        JSON.serialize(rows),
        null,
        v.clientVersion
      );

      // Then: 2행 오류(셀 강조 필드 포함), 저장 없음
      Assert.isFalse(r.success);
      Assert.areEqual(2, r.rowErrors.size());
      Map<String, CMN_GridService.RowError> byKey = new Map<String, CMN_GridService.RowError>();
      for (CMN_GridService.RowError e : r.rowErrors) {
        byKey.put(e.key, e);
      }
      Assert.areEqual(
        Label.CMN_Grid_SampleEndBeforeStart,
        byKey.get(lines[0].Id).messages[0]
      );
      Assert.areEqual('EndDate__c', byKey.get(lines[0].Id).fieldNames[0]);
      Assert.areEqual('Quantity__c', byKey.get(lines[1].Id).fieldNames[0]);
    }
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM CMN_TestRecordLine__c WHERE Name = 'Valid']
    );
  }

  @IsTest
  static void test_AC05_conflictWhenSomeoneSavedFirst() {
    // Given: 사용자가 그리드를 연 뒤 다른 사용자가 행을 더함
    Id parent = parentFor(user('grdown'), 'DRAFT');
    List<CMN_TestRecordLine__c> lines = insertLines(parent, 2, Date.today());
    CMN_GridService.GridView v;
    System.runAs(user('grdown')) {
      v = CMN_GridController.load(GRID, parent);
    }
    insert new CMN_TestRecordLine__c(TestRecord__c = parent, Name = 'Other');

    System.runAs(user('grdown')) {
      // When
      CMN_GridService.SaveResult r = CMN_GridController.save(
        GRID,
        parent,
        JSON.serialize(
          new List<Object>{
            change(lines[0].Id, new Map<String, Object>{ 'Name' => 'Mine' })
          }
        ),
        null,
        v.clientVersion
      );
      // Then: 저장 차단과 새로 고침 안내(덮어쓰지 않음)
      Assert.isFalse(r.success);
      Assert.isTrue(r.conflict);
      Assert.areEqual(Label.CMN_Grid_Conflict, r.gridErrors[0]);
    }
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM CMN_TestRecordLine__c WHERE Name = 'Mine']
    );
  }

  @IsTest
  static void test_AC06_columnWithoutFlsIsHidden() {
    // Given: 비고(Note__c) FLS가 없는 사용자
    Id parent = parentFor(user('grdfls'), 'DRAFT');
    List<CMN_TestRecordLine__c> lines = insertLines(parent, 2, Date.today());
    System.runAs(user('grdfls')) {
      // When
      CMN_GridService.GridView v = CMN_GridController.load(GRID, parent);

      // Then: 열과 행 값 모두 없다
      Assert.isFalse(columns(v).containsKey('Note__c'));
      Assert.isFalse(v.rows[0].containsKey('Note__c'));
      Assert.isTrue(columns(v).containsKey('Quantity__c'));

      // When: 보이지 않는 열에 값을 보냄 → Then 거부
      CMN_GridService.SaveResult r = CMN_GridController.save(
        GRID,
        parent,
        JSON.serialize(
          new List<Object>{
            change(lines[0].Id, new Map<String, Object>{ 'Note__c' => 'x' })
          }
        ),
        null,
        v.clientVersion
      );
      Assert.isFalse(r.success);
      Assert.areEqual(
        String.format(
          Label.CMN_Grid_ColumnNotEditable,
          new List<Object>{ 'Note__c' }
        ),
        r.rowErrors[0].messages[0]
      );
    }
  }

  @IsTest
  static void test_AC07_phoneFieldsLimitedToFour() {
    // Given / When: 배포된 샘플 그리드
    Id parent = parentFor(user('grdown'), 'DRAFT');
    System.runAs(user('grdown')) {
      CMN_GridService.GridView v = CMN_GridController.load(GRID, parent);
      Integer phone = 0;
      for (CMN_GridService.ColumnView c : v.columns) {
        phone += c.showOnPhone ? 1 : 0;
      }
      // Then: 휴대폰 카드 열은 4개 이하(화면 카드 표시는 Jest에서 확인)
      Assert.isTrue(phone > 0 && phone <= 4, 'phone ' + phone);
    }
  }

  @IsTest
  static void test_AC09_editRuleBlocksEditAndSave() {
    // Given: 편집 규칙(TestLinesEdit = DRAFT·IN_PROGRESS) 밖의 완료 상태
    Id parent = parentFor(user('grdown'), 'DONE');
    List<CMN_TestRecordLine__c> lines = insertLines(parent, 1, Date.today());
    System.runAs(user('grdown')) {
      // When
      CMN_GridService.GridView v = CMN_GridController.load(GRID, parent);
      // Then: 읽기 전용
      Assert.isFalse(v.editable);
      Assert.isFalse(v.allowAdd || v.allowDelete || v.allowPaste);
      for (CMN_GridService.ColumnView c : v.columns) {
        Assert.isFalse(c.editable, c.fieldApiName);
      }
      Assert.isTrue(v.defaults.isEmpty());

      // When: 저장 API 직접 호출 → Then 거부
      CMN_GridService.SaveResult r = CMN_GridController.save(
        GRID,
        parent,
        JSON.serialize(
          new List<Object>{
            change(lines[0].Id, new Map<String, Object>{ 'Name' => 'Hack' })
          }
        ),
        null,
        v.clientVersion
      );
      Assert.isFalse(r.success);
      Assert.areEqual(Label.CMN_Grid_NotEditable, r.gridErrors[0]);
    }
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM CMN_TestRecordLine__c WHERE Name = 'Hack']
    );
  }

  @IsTest
  static void test_BR11_rowMetaIsEnforcedOnServer() {
    // Given: 완료 행 1개(삭제 불가·일정 잠금), 종료일이 지난 미완료 행 1개(경고)
    Id parent = parentFor(user('grdown'), 'DRAFT');
    List<CMN_TestRecordLine__c> lines = insertLines(
      parent,
      2,
      Date.today().addDays(-10)
    );
    lines[0].IsDone__c = true;
    lines[1].EndDate__c = Date.today().addDays(-1);
    update lines;
    System.runAs(user('grdown')) {
      // When
      CMN_GridService.GridView v = CMN_GridController.load(GRID, parent);
      // Then: 화면 메타
      Map<String, Object> done = v.rows[0];
      Assert.isFalse((Boolean) done.get('__deletable'));
      Assert.areEqual(
        Label.CMN_Grid_SampleDoneLocked,
        done.get('__deleteBlocked')
      );
      Assert.isTrue(
        ((List<String>) done.get('__locked')).contains('StartDate__c')
      );
      Assert.areEqual(Label.CMN_Grid_WarnOverdue, v.rows[1].get('__warning'));

      // When: 잠긴 셀 변경 + 삭제 불가 행 삭제 → Then 서버가 다시 거부
      CMN_GridService.SaveResult r = CMN_GridController.save(
        GRID,
        parent,
        JSON.serialize(
          new List<Object>{
            change(
              lines[0].Id,
              new Map<String, Object>{
                'StartDate__c' => String.valueOf(Date.today()),
                'Name' => 'Allowed'
              }
            )
          }
        ),
        new List<Id>{ lines[0].Id },
        v.clientVersion
      );
      Assert.isFalse(r.success);
      // 삭제할 행의 수정은 버리고 삭제 불가로 거부
      Assert.areEqual(1, r.rowErrors.size());
      Assert.areEqual(
        Label.CMN_Grid_SampleDoneLocked,
        r.rowErrors[0].messages[0]
      );

      CMN_GridService.SaveResult locked = CMN_GridController.save(
        GRID,
        parent,
        JSON.serialize(
          new List<Object>{
            change(
              lines[0].Id,
              new Map<String, Object>{
                'StartDate__c' => String.valueOf(Date.today())
              }
            )
          }
        ),
        null,
        v.clientVersion
      );
      Assert.isFalse(locked.success);
      Assert.areEqual('StartDate__c', locked.rowErrors[0].fieldNames[0]);

      // When: 잠긴 셀을 같은 값으로 보냄 → Then 허용(바뀌지 않은 값)
      CMN_GridService.SaveResult same = CMN_GridController.save(
        GRID,
        parent,
        JSON.serialize(
          new List<Object>{
            change(
              lines[0].Id,
              new Map<String, Object>{
                'StartDate__c' => String.valueOf(lines[0].StartDate__c),
                'Note__c' => 'ok'
              }
            )
          }
        ),
        null,
        v.clientVersion
      );
      Assert.isTrue(same.success, String.valueOf(same.rowErrors));
    }
  }

  @IsTest
  static void test_bulk200NewRows() {
    // Given: 빈 그리드에 200행 추가
    Id parent = parentFor(user('grdown'), 'DRAFT');
    System.runAs(user('grdown')) {
      CMN_GridService.GridView v = CMN_GridController.load(GRID, parent);
      List<Map<String, Object>> rows = new List<Map<String, Object>>();
      for (Integer i = 0; i < 200; i++) {
        rows.add(
          newRow(
            'n' + i,
            new Map<String, Object>{
              'Name' => 'Bulk ' + i,
              'Quantity__c' => '1,5'.replace(',', '.'),
              'Category__c' => 'CHECK',
              'IsDone__c' => 'false'
            }
          )
        );
      }
      // When
      Integer queries = Limits.getQueries();
      CMN_GridService.SaveResult r = CMN_GridController.save(
        GRID,
        parent,
        JSON.serialize(rows),
        null,
        v.clientVersion
      );
      // Then: 200행 저장, 조회 수는 행 수와 무관
      Assert.isTrue(r.success, String.valueOf(r.rowErrors) + r.gridErrors);
      Assert.areEqual(200, r.savedCount);
      Assert.areEqual(200, r.view.rows.size());
      Assert.isTrue(Limits.getQueries() - queries <= 8, 'SOQL');
    }
    Assert.areEqual(
      200,
      [SELECT COUNT() FROM CMN_TestRecordLine__c WHERE TestRecord__c = :parent]
    );
    Decimal maxNo = (Decimal) [
        SELECT MAX(LineNo__c) m
        FROM CMN_TestRecordLine__c
        WHERE TestRecord__c = :parent
      ][0]
      .get('m');
    Assert.areEqual(200, maxNo.intValue());
  }

  @IsTest
  static void test_afterSaveFailureRollsBack() {
    // Given: 후처리에서 실패하는 Provider
    Id parent = parentFor(user('grdown'), 'DRAFT');
    CMN_GridService.providerOverride = new Map<String, CMN_GridProvider>{
      GRID => new FailingProvider(false)
    };
    System.runAs(user('grdown')) {
      CMN_GridService.GridView v = CMN_GridController.load(GRID, parent);
      String rows = JSON.serialize(
        new List<Object>{
          newRow(
            'n1',
            new Map<String, Object>{
              'Name' => 'X',
              'StartDate__c' => String.valueOf(Date.today())
            }
          )
        }
      );
      // When
      CMN_GridService.SaveResult r = CMN_GridController.save(
        GRID,
        parent,
        rows,
        null,
        v.clientVersion
      );
      // Then: 전체 롤백, 일반 오류 문구
      Assert.isFalse(r.success);
      Assert.areEqual(Label.CMN_Grid_SaveFailed, r.gridErrors[0]);

      // Given: 업무 문구로 멈추는 Provider → Then 그 문구
      CMN_GridService.providerOverride.put(GRID, new FailingProvider(true));
      CMN_GridService.SaveResult stopped = CMN_GridController.save(
        GRID,
        parent,
        rows,
        null,
        v.clientVersion
      );
      Assert.areEqual(Label.CMN_Grid_SampleNegativeQty, stopped.gridErrors[0]);
    }
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM CMN_TestRecordLine__c WHERE TestRecord__c = :parent]
    );
  }

  @IsTest
  static void test_filterAndUnrestrictedProvider() {
    // Given: 고정 필터(구분 = 점검), Provider 없음
    Id parent = parentFor(user('grdown'), 'DRAFT');
    List<CMN_TestRecordLine__c> lines = insertLines(parent, 4, Date.today());
    lines[0].Category__c = 'CHECK';
    lines[1].Category__c = 'CHECK';
    update lines;
    useDefinition(
      definition(
        'Checks',
        new Map<String, Object>{
          'Filter__c' => 'Category__c=CHECK, IsDone__c=false',
          'ProviderClass__c' => null,
          'EditRuleKey__c' => null,
          'OrderField__c' => null
        }
      ),
      new List<String>{ 'Name', 'Category__c', 'IsDone__c' }
    );
    System.runAs(user('grdown')) {
      // When
      CMN_GridService.GridView v = CMN_GridController.load('Checks', parent);
      // Then
      Assert.areEqual(2, v.rows.size());
      Assert.isTrue(v.editable);
      Assert.isNull(
        v.scheduleStartField,
        '일정 필드가 열에 없으면 일정 보기 없음'
      );
      Assert.isTrue(v.defaults.isEmpty());
      CMN_GridService.SaveResult r = CMN_GridController.save(
        'Checks',
        parent,
        JSON.serialize(
          new List<Object>{
            change(lines[0].Id, new Map<String, Object>{ 'IsDone__c' => true })
          }
        ),
        null,
        v.clientVersion
      );
      Assert.isTrue(r.success, String.valueOf(r.rowErrors));
      Assert.areEqual(1, r.view.rows.size(), '필터 밖으로 나간 행');
    }
  }

  @IsTest
  static void test_providerReadsOnlyQueriedFields() {
    // Given: 샘플 Provider가 쓰는 완료·일정 열이 없는 그리드(조회하지 않은 필드는 null로 읽는다)
    Id parent = parentFor(user('grdown'), 'DRAFT');
    List<CMN_TestRecordLine__c> lines = insertLines(parent, 1, Date.today());
    lines[0].IsDone__c = true;
    update lines;
    useDefinition(
      definition('NameOnly', new Map<String, Object>()),
      new List<String>{ 'Name' }
    );
    System.runAs(user('grdown')) {
      // When
      CMN_GridService.GridView v = CMN_GridController.load('NameOnly', parent);
      // Then: 완료 값을 몰라 잠그지 않는다(업무 Provider는 필요한 필드를 열로 두거나 직접 조회한다)
      Assert.isTrue((Boolean) v.rows[0].get('__deletable'));
      Assert.isNull(v.scheduleStartField);
    }
  }

  @IsTest
  static void test_negative_invalidRequestsAndValues() {
    Id parent = parentFor(user('grdown'), 'DRAFT');
    Id other = parentFor(user('grdown'), 'DRAFT');
    List<CMN_TestRecordLine__c> mine = insertLines(parent, 1, Date.today());
    List<CMN_TestRecordLine__c> foreign = insertLines(other, 1, Date.today());
    Id plant = [SELECT Id FROM CMN_Plant__c LIMIT 1].Id;
    System.runAs(user('grdown')) {
      // 형식 오류 키·없는 그리드·다른 객체 부모
      expectAura(Label.CMN_Grid_InvalidRequest, '../x', parent);
      expectAura(Label.CMN_Grid_NotFound, 'No_Such_Grid', parent);
      expectAura(Label.CMN_Grid_InvalidRequest, GRID, plant);

      CMN_GridService.GridView v = CMN_GridController.load(GRID, parent);
      // 깨진 JSON·중복 키
      for (String bad : new List<String>{ '{', '{"a":1}', '[{"key":""}]' }) {
        try {
          CMN_GridController.save(GRID, parent, bad, null, v.clientVersion);
          Assert.fail('거부: ' + bad);
        } catch (AuraHandledException e) {
          Assert.areEqual(Label.CMN_Grid_InvalidRequest, e.getMessage());
        }
      }
      // 다른 부모의 행·형식 오류 값·필수 누락
      List<Map<String, Object>> rows = new List<Map<String, Object>>{
        change(foreign[0].Id, new Map<String, Object>{ 'Name' => 'X' }),
        change(
          mine[0].Id,
          new Map<String, Object>{
            'StartDate__c' => '2026.13.01',
            'Category__c' => 'NOPE',
            'Quantity__c' => 'abc',
            'Plant__c' => parent,
            'IsDone__c' => 'maybe'
          }
        ),
        newRow('n1', new Map<String, Object>{ 'Name' => '' })
      };
      CMN_GridService.SaveResult r = CMN_GridController.save(
        GRID,
        parent,
        JSON.serialize(rows),
        new List<Id>{ foreign[0].Id },
        v.clientVersion
      );
      Assert.isFalse(r.success);
      Map<String, CMN_GridService.RowError> byKey = new Map<String, CMN_GridService.RowError>();
      for (CMN_GridService.RowError e : r.rowErrors) {
        byKey.put(e.key, e);
      }
      Assert.areEqual(
        Label.CMN_Grid_RowNotFound,
        byKey.get(foreign[0].Id).messages[0]
      );
      Assert.areEqual(5, byKey.get(mine[0].Id).fieldNames.size());
      Assert.areEqual(
        String.format(
          Label.CMN_Grid_RequiredMissing,
          new List<Object>{ columns(v).get('Name').label }
        ),
        byKey.get('n1').messages[0]
      );
      // 너무 많은 행
      List<Map<String, Object>> many = new List<Map<String, Object>>();
      for (Integer i = 0; i < 201; i++) {
        many.add(newRow('m' + i, new Map<String, Object>{ 'Name' => 'M' }));
      }
      CMN_GridService.SaveResult tooMany = CMN_GridController.save(
        GRID,
        parent,
        JSON.serialize(many),
        null,
        v.clientVersion
      );
      Assert.isFalse(tooMany.success);
      // 변경 없음 → 성공(그대로)
      CMN_GridService.SaveResult none = CMN_GridController.save(
        GRID,
        parent,
        '[]',
        new List<Id>(),
        v.clientVersion
      );
      Assert.isTrue(none.success);
    }
    // 권한 없는 사용자
    System.runAs(user('grdbar')) {
      expectAura(Label.CMN_Grid_NoAccess, GRID, parent);
    }
    // 설정 오류: Provider가 인터페이스를 구현하지 않음·없는 클래스·잘못된 필터
    for (
      Map<String, Object> wrong : new List<Map<String, Object>>{
        new Map<String, Object>{ 'ProviderClass__c' => 'CMN_GridSelector' },
        new Map<String, Object>{ 'ProviderClass__c' => 'No_Such_Class' },
        new Map<String, Object>{ 'Filter__c' => 'Broken' },
        new Map<String, Object>{ 'ParentField__c' => 'Name' }
      }
    ) {
      useDefinition(definition('Wrong', wrong), new List<String>{ 'Name' });
      System.runAs(user('grdown')) {
        expectAura(
          String.format(
            Label.CMN_Grid_ConfigError,
            new List<Object>{ 'Wrong' }
          ),
          'Wrong',
          parent
        );
      }
    }
  }

  @IsTest
  static void test_providerGridErrorsAndUnexpectedFailures() {
    // Given: 그리드 전체 오류·범위 밖 행 순번을 돌려주는 Provider
    Id parent = parentFor(user('grdown'), 'DRAFT');
    List<CMN_TestRecordLine__c> lines = insertLines(parent, 1, Date.today());
    CMN_GridService.providerOverride = new Map<String, CMN_GridProvider>{
      GRID => new ExplodingProvider('grid')
    };
    String rows = JSON.serialize(
      new List<Object>{
        change(lines[0].Id, new Map<String, Object>{ 'Name' => 'G' })
      }
    );
    System.runAs(user('grdown')) {
      CMN_GridService.GridView v = CMN_GridController.load(GRID, parent);
      // When
      CMN_GridService.SaveResult r = CMN_GridController.save(
        GRID,
        parent,
        rows,
        null,
        v.clientVersion
      );
      // Then: 범위 밖 순번은 그리드 오류로, 그리드 오류는 그대로
      Assert.isFalse(r.success);
      Assert.areEqual(new List<String>{ 'row 99', 'whole grid' }, r.gridErrors);
      Assert.isTrue(r.rowErrors.isEmpty());

      // Given: 검증에서 예상하지 못한 예외 → Then 일반 오류 문구(원문 숨김)
      CMN_GridService.providerOverride.put(
        GRID,
        new ExplodingProvider('validate')
      );
      try {
        CMN_GridController.save(GRID, parent, rows, null, v.clientVersion);
        Assert.fail('예외');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_UnexpectedError, e.getMessage());
      }
      // Given: 행 메타에서 예상하지 못한 예외 → Then 로드도 일반 오류 문구
      CMN_GridService.providerOverride.put(GRID, new ExplodingProvider('meta'));
      try {
        CMN_GridController.load(GRID, parent);
        Assert.fail('예외');
      } catch (AuraHandledException e) {
        Assert.areEqual(Label.CMN_Common_UnexpectedError, e.getMessage());
      }
    }
  }

  // ------------------------------------------------------------------ 도우미
  /** 후처리 실패 Provider: business=true면 업무 문구(CMN_ValidationException), 아니면 시스템 예외 */
  private class FailingProvider extends CMN_GridProviderBase {
    private Boolean business;
    public FailingProvider(Boolean business) {
      this.business = business;
    }
    public override void afterSave(
      Id parentId,
      List<SObject> savedRows,
      List<Id> deletedIds
    ) {
      if (business) {
        throw new CMN_ValidationException(Label.CMN_Grid_SampleNegativeQty);
      }
      Integer zero = 0;
      Integer boom = 1 / zero;
    }
  }

  /** grid: 그리드 오류 반환, validate: 검증 중 예외, meta: 행 메타 중 예외 */
  private class ExplodingProvider extends CMN_GridProviderBase {
    private String mode;
    public ExplodingProvider(String mode) {
      this.mode = mode;
    }
    public override Map<Id, CMN_GridRowMeta> rowMeta(
      Id parentId,
      List<SObject> rows
    ) {
      if (mode == 'meta') {
        CMN_GridRowMeta missing;
        missing.lock('Name');
      }
      return super.rowMeta(parentId, rows);
    }
    public override CMN_GridValidation validate(
      Id parentId,
      List<SObject> rows,
      List<Id> deletedIds
    ) {
      if (mode == 'validate') {
        CMN_GridValidation missing;
        return missing.addGridError('x');
      }
      CMN_GridValidation result = new CMN_GridValidation()
        .addRowError(99, 'row 99')
        .addGridError('whole grid');
      Assert.isTrue(result.hasErrors());
      return result;
    }
  }

  private static void expectAura(String message, String gridKey, Id parentId) {
    try {
      CMN_GridController.load(gridKey, parentId);
      Assert.fail('거부: ' + gridKey);
    } catch (AuraHandledException e) {
      Assert.areEqual(message, e.getMessage());
    }
  }

  private static Map<String, Object> change(
    Id rowId,
    Map<String, Object> values
  ) {
    return new Map<String, Object>{
      'key' => String.valueOf(rowId),
      'id' => rowId,
      'values' => values
    };
  }

  private static Map<String, Object> newRow(
    String key,
    Map<String, Object> values
  ) {
    return new Map<String, Object>{ 'key' => key, 'values' => values };
  }

  private static Map<String, CMN_GridService.ColumnView> columns(
    CMN_GridService.GridView v
  ) {
    Map<String, CMN_GridService.ColumnView> out = new Map<String, CMN_GridService.ColumnView>();
    for (CMN_GridService.ColumnView c : v.columns) {
      out.put(c.fieldApiName, c);
    }
    return out;
  }

  private static CMN_GridDefinition__mdt definition(
    String key,
    Map<String, Object> overrides
  ) {
    Map<String, Object> m = new Map<String, Object>{
      'DeveloperName' => key,
      'ObjectApiName__c' => LINE,
      'ParentField__c' => 'TestRecord__c',
      'OrderField__c' => 'LineNo__c',
      'MaxRows__c' => 200,
      'AllowAdd__c' => true,
      'AllowDelete__c' => true,
      'AllowPaste__c' => true,
      'ScheduleStartField__c' => 'StartDate__c',
      'ScheduleEndField__c' => 'EndDate__c',
      'ProviderClass__c' => 'CMN_TestRecordLineGridProvider',
      'EditRuleKey__c' => 'TestLinesEdit'
    };
    m.putAll(overrides);
    return (CMN_GridDefinition__mdt) JSON.deserialize(
      JSON.serialize(m),
      CMN_GridDefinition__mdt.class
    );
  }

  private static void useDefinition(
    CMN_GridDefinition__mdt def,
    List<String> fields
  ) {
    List<CMN_GridColumn__mdt> cols = new List<CMN_GridColumn__mdt>();
    for (Integer i = 0; i < fields.size(); i++) {
      cols.add(
        (CMN_GridColumn__mdt) JSON.deserialize(
          JSON.serialize(
            new Map<String, Object>{
              'DeveloperName' => def.DeveloperName +
              '_' +
              i,
              'FieldApiName__c' => fields[i],
              'Order__c' => i,
              'Editable__c' => true,
              'Required__c' => fields[i] == 'Name',
              'InputType__c' => fields[i] == 'Code__c' ? 'CODE' : 'AUTO',
              'CodeGroup__c' => fields[i] == 'Code__c' ? 'DEFECT_TYPE' : null,
              'ShowOnPhone__c' => i < 4
            }
          ),
          CMN_GridColumn__mdt.class
        )
      );
    }
    CMN_GridSelector.definitionsOverride = new Map<String, CMN_GridDefinition__mdt>{
      def.DeveloperName => def
    };
    CMN_GridSelector.columnsOverride = new Map<String, List<CMN_GridColumn__mdt>>{
      def.DeveloperName => cols
    };
  }

  private static Id parentFor(User owner, String status) {
    CMN_TestRecord__c r = new CMN_TestRecord__c(
      Name = 'Grid ' + status,
      Plant__c = [SELECT Id FROM CMN_Plant__c WHERE PlantCode__c = 'KR01']
      .Id,
      Status__c = status,
      OwnerId = owner.Id
    );
    insert r;
    return r.Id;
  }

  private static List<CMN_TestRecordLine__c> insertLines(
    Id parent,
    Integer count,
    Date start
  ) {
    Id plant = [SELECT Id FROM CMN_Plant__c WHERE PlantCode__c = 'KR01'].Id;
    List<CMN_TestRecordLine__c> lines = new List<CMN_TestRecordLine__c>();
    for (Integer i = 1; i <= count; i++) {
      lines.add(
        new CMN_TestRecordLine__c(
          TestRecord__c = parent,
          Name = 'Line ' + i,
          LineNo__c = i,
          Category__c = 'PLAN',
          Quantity__c = i,
          StartDate__c = start,
          EndDate__c = start.addDays(7),
          Plant__c = plant
        )
      );
    }
    insert lines;
    return lines;
  }

  /** 테스트 객체 두 개의 객체·필드 권한(필드는 제외 목록 빼고 전부). */
  private static Id testPermissionSet(String name, Set<String> withoutFields) {
    PermissionSet ps = new PermissionSet(Name = name, Label = name);
    insert ps;
    insert new List<ObjectPermissions>{
      new ObjectPermissions(
        ParentId = ps.Id,
        SobjectType = 'CMN_TestRecord__c',
        PermissionsRead = true,
        PermissionsCreate = true,
        PermissionsEdit = true
      ),
      new ObjectPermissions(
        ParentId = ps.Id,
        SobjectType = LINE,
        PermissionsRead = true,
        PermissionsCreate = true,
        PermissionsEdit = true,
        PermissionsDelete = true
      )
    };
    List<FieldPermissions> fps = new List<FieldPermissions>();
    for (
      Schema.SObjectType t : new List<Schema.SObjectType>{
        CMN_TestRecord__c.SObjectType,
        CMN_TestRecordLine__c.SObjectType
      }
    ) {
      Schema.DescribeSObjectResult d = t.getDescribe();
      for (Schema.SObjectField f : d.fields.getMap().values()) {
        Schema.DescribeFieldResult fd = f.getDescribe();
        String full = d.getName() + '.' + fd.getName();
        if (!fd.isPermissionable() || withoutFields.contains(full)) {
          continue;
        }
        fps.add(
          new FieldPermissions(
            ParentId = ps.Id,
            SobjectType = d.getName(),
            Field = full,
            PermissionsRead = true,
            PermissionsEdit = fd.isUpdateable() && !fd.isCalculated()
          )
        );
      }
    }
    insert fps;
    return ps.Id;
  }

  private static User user(String alias) {
    return [
      SELECT Id
      FROM User
      WHERE Alias = :alias AND Username LIKE '%@test.slqms.example.com'
      LIMIT 1
    ];
  }
}
