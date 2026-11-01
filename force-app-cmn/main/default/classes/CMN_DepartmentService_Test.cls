/**
 * @description 부서 계층 검증(CMN-00-MDM-001).
 * @group CMN-00-MDM-001
 */
@IsTest
private class CMN_DepartmentService_Test {
  @TestSetup
  static void setup() {
    // SL > 품질본부 > 품질경영팀(A→B→C), 별도 본부 D
    CMN_Department__c sl = dept('D0', 'SL', null);
    insert sl;
    CMN_Department__c quality = dept('D1', 'Quality HQ', sl.Id);
    CMN_Department__c dev = dept('D2', 'Dev HQ', sl.Id);
    insert new List<CMN_Department__c>{ quality, dev };
    insert dept('D11', 'QM Team', quality.Id);
  }

  @IsTest
  static void test_AC01_parentUnderOwnChildRejected() {
    // Given: Quality HQ 아래 QM Team
    CMN_Department__c quality = byCode('D1');
    CMN_Department__c team = byCode('D11');

    // When: Quality HQ의 상위를 QM Team으로
    quality.Parent__c = team.Id;
    Database.SaveResult r = Database.update(quality, false);

    // Then: 순환 참조 오류(상위 부서 필드)
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      Label.CMN_Org_DepartmentCycle,
      r.getErrors()[0].getMessage()
    );
    Assert.areEqual(
      new List<String>{ 'Parent__c' },
      r.getErrors()[0].getFields()
    );
  }

  @IsTest
  static void test_AC01_selfParentRejected() {
    // Given / When: 자기 자신을 상위로
    CMN_Department__c sl = byCode('D0');
    sl.Parent__c = sl.Id;
    Database.SaveResult r = Database.update(sl, false);

    // Then
    Assert.isFalse(r.isSuccess());
  }

  @IsTest
  static void test_AC02_moveRecalculatesDescendantsAsync() {
    // Given: Quality HQ > QM Team
    CMN_Department__c quality = byCode('D1');
    Assert.areEqual('SL > Quality HQ > QM Team', byCode('D11').FullPath__c);

    // When: Quality HQ를 Dev HQ 아래로 이동
    Test.startTest();
    quality.Parent__c = byCode('D2').Id;
    update quality;
    // Then(동기): 자기 경로는 저장 때 바뀌고, 하위는 아직이다
    Assert.areEqual('SL > Dev HQ > Quality HQ', byCode('D1').FullPath__c);
    Assert.areEqual('SL > Quality HQ > QM Team', byCode('D11').FullPath__c);
    Test.stopTest();

    // Then(비동기 후): 하위 전체가 새 경로
    Assert.areEqual(
      'SL > Dev HQ > Quality HQ > QM Team',
      byCode('D11').FullPath__c
    );
  }

  @IsTest
  static void test_BR2_renameRefreshesDescendants() {
    // Given / When: 최상위 이름 변경
    Test.startTest();
    update new CMN_Department__c(Id = byCode('D0').Id, Name = 'SL Corp');
    Test.stopTest();

    // Then
    Assert.areEqual(
      'SL Corp > Quality HQ > QM Team',
      byCode('D11').FullPath__c
    );
  }

  @IsTest
  static void test_BR2_deepChainKeepsNearestEightLevels() {
    // Given: QM Team 아래 8단계 더(총 11단계)
    Id parent = byCode('D11').Id;
    for (Integer i = 1; i <= 8; i++) {
      CMN_Department__c d = dept('X' + i, 'L' + i, parent);
      insert d;
      parent = d.Id;
    }

    // When: 가장 깊은 부서의 경로
    String p = byCode('X8').FullPath__c;

    // Then: 가까운 8단계만 남고 앞은 …
    Assert.areEqual(
      CMN_DepartmentService.ELLIPSIS +
      ' > L1 > L2 > L3 > L4 > L5 > L6 > L7 > L8',
      p
    );
  }

  @IsTest
  static void test_BR1_deleteBlockedDeactivateAllowed() {
    // Given: QM Team
    CMN_Department__c team = byCode('D11');

    // When: 삭제
    Database.DeleteResult r = Database.delete(team, false);

    // Then: 차단, 비활성화는 된다
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      Label.CMN_Master_DeleteNotAllowed,
      r.getErrors()[0].getMessage()
    );
    update new CMN_Department__c(Id = team.Id, IsActive__c = false);
    Assert.isFalse(byCode('D11').IsActive__c);
  }

  @IsTest
  static void test_bulk200Departments() {
    // Given: 품질본부 아래 200개
    Id parent = byCode('D1').Id;
    List<CMN_Department__c> depts = new List<CMN_Department__c>();
    for (Integer i = 0; i < 200; i++) {
      depts.add(dept('B' + i, 'Team ' + i, parent));
    }

    // When
    Integer before = Limits.getQueries();
    insert depts;
    Integer used = Limits.getQueries() - before;

    // Then: 트리 조회 1회, 경로 200개
    Assert.isTrue(used <= 1, 'SOQL ' + used);
    Assert.areEqual(
      200,
      [
        SELECT COUNT()
        FROM CMN_Department__c
        WHERE FullPath__c LIKE 'SL > Quality HQ > Team %'
      ]
    );
  }

  @IsTest
  static void test_userDepartmentAndPlantResolved() {
    // Given: 부서 코드·기본 공장 코드를 가진 사용자
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
    User u = hrUser('T9001', ' d11 ', 'kr01');

    // When: 저장하고 서비스로 해석
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert u;
    }
    CMN_Department__c dept = CMN_UserOrgService.departmentsOf(
        new Set<Id>{ u.Id }
      )
      .get(u.Id);
    CMN_Plant__c plant = CMN_UserOrgService.primaryPlantsOf(new Set<Id>{ u.Id })
      .get(u.Id);

    // Then: 재직 상태 기본 ACTIVE, 부서·공장 레코드로 풀린다(대소문자·공백 무관)
    Assert.areEqual(
      'ACTIVE',
      [SELECT HrStatus__c FROM User WHERE Id = :u.Id].HrStatus__c
    );
    Assert.areEqual('SL > Quality HQ > QM Team', dept.FullPath__c);
    Assert.areEqual('KR01', plant.PlantCode__c);
  }

  @IsTest
  static void test_negative_unknownDepartmentCodeRejected() {
    // Given: 없는 부서 코드
    User u = hrUser('T9002', 'NOPE', null);

    // When
    Database.SaveResult r;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      r = Database.insert(u, false);
    }

    // Then: 부서 코드 필드 오류
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      String.format(
        Label.CMN_Org_UnknownDepartmentCode,
        new List<Object>{ 'NOPE' }
      ),
      r.getErrors()[0].getMessage()
    );
  }

  @IsTest
  static void test_negative_unknownPlantCodeOnUpdateRejected() {
    // Given: 부서 코드만 있는 사용자
    User u = hrUser('T9003', 'D11', null);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert u;
    }

    // When: 없는 기본 공장 코드로 갱신
    Database.SaveResult r;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      r = Database.update(
        new User(Id = u.Id, PrimaryPlantCode__c = 'ZZ99'),
        false
      );
    }

    // Then: 기본 공장 코드 필드 오류
    Assert.isFalse(r.isSuccess());
    Assert.areEqual(
      new List<String>{ 'PrimaryPlantCode__c' },
      r.getErrors()[0].getFields()
    );
  }

  @IsTest
  static void test_demoFixturesLoadDepartments() {
    // Given / When: 데모 픽스처의 부서(2단계 적재: 생성 후 상위·부서장)
    CMN_TestDataFactory.loadFixtures(new Set<String>{ 'CMN_Department__c' });

    // Then: 데모 부서가 계층 경로를 갖는다
    Id d = CMN_TestDataFactory.idOf('CMN_Department__c', 'D1000');
    Assert.isNotNull(d);
    Assert.isTrue(
      [SELECT FullPath__c FROM CMN_Department__c WHERE Id = :d]
        .FullPath__c.contains(' > ')
    );
  }

  // ------------------------------------------------------------------ 도우미
  private static CMN_Department__c dept(String code, String name, Id parent) {
    return new CMN_Department__c(
      DeptCode__c = code,
      Name = name,
      Parent__c = parent
    );
  }

  private static User hrUser(String empNo, String deptCode, String plantCode) {
    User u = CMN_TestDataFactory.newUser(
      empNo,
      'HR',
      CMN_TestDataFactory.profileIdForLicense('Salesforce Platform')
    );
    u.EmployeeNo__c = empNo;
    u.DepartmentCode__c = deptCode;
    u.PrimaryPlantCode__c = plantCode;
    return u;
  }

  private static CMN_Department__c byCode(String code) {
    return [
      SELECT Id, Name, Parent__c, FullPath__c, IsActive__c
      FROM CMN_Department__c
      WHERE DeptCode__c = :code
    ];
  }
}
