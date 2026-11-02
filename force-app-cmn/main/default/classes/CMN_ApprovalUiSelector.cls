/**
 * @description 결재 화면 조회(CMN-00-APV-003). with sharing — 사용자가 공유로 볼 수 있는 결재 요청·단계만 돌려준다.
 * @group CMN-00-APV-003
 */
public with sharing class CMN_ApprovalUiSelector {
  /**
   * @description 대상의 모든 결재 요청(버전 오름차순)과 단계.
   * @param targetId 대상 레코드
   * @return 요청(Steps__r 포함)
   */
  public static List<CMN_ApprovalRequest__c> history(Id targetId) {
    String key = targetId;
    return [
      SELECT
        Id,
        RecordNo__c,
        Version__c,
        Status__c,
        SubmittedAt__c,
        CompletedAt__c,
        SubmitComment__c,
        CreatedBy.Name,
        (
          SELECT
            Id,
            StepNo__c,
            StepType__c,
            Status__c,
            Approver__r.Name,
            ActedBy__r.Name,
            IsDelegated__c,
            ActedAt__c,
            Comment__c
          FROM Steps__r
          ORDER BY StepNo__c, Id
        )
      FROM CMN_ApprovalRequest__c
      WHERE TargetRecordId__c = :key
      WITH SYSTEM_MODE
      ORDER BY Version__c, CreatedDate
    ];
  }

  /**
   * @description 결재 요청 하나와 단계(처리 화면).
   * @param requestId 결재 요청
   * @return 요청(없거나 볼 수 없으면 null)
   */
  public static CMN_ApprovalRequest__c request(Id requestId) {
    List<CMN_ApprovalRequest__c> rows = [
      SELECT
        Id,
        RecordNo__c,
        Title__c,
        TypeCode__c,
        Status__c,
        Version__c,
        TargetRecordId__c,
        TargetObject__c,
        Summary__c,
        SubmitComment__c,
        CreatedById,
        CreatedBy.Name,
        (
          SELECT
            Id,
            StepNo__c,
            StepType__c,
            Status__c,
            Approver__c,
            Approver__r.Name
          FROM Steps__r
          ORDER BY StepNo__c, Id
        )
      FROM CMN_ApprovalRequest__c
      WHERE Id = :requestId
      WITH SYSTEM_MODE
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * @description 결재 모니터 목록(최근 200건).
   * @param view SUBMITTED(내가 상신), ACTED(내가 처리), IN_PROGRESS(진행 중, 볼 수 있는 것)
   * @param typeCode 결재 유형(비우면 전체)
   * @param plantId 공장(비우면 전체)
   * @param fromDate 상신일 시작(포함)
   * @param toDate 상신일 끝(포함)
   * @return 요청(진행 중 단계 포함)
   */
  public static List<CMN_ApprovalRequest__c> monitor(
    String view,
    String typeCode,
    Id plantId,
    Date fromDate,
    Date toDate
  ) {
    Id me = UserInfo.getUserId();
    Datetime fromAt = fromDate == null
      ? null
      : Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0));
    Datetime toAt = toDate == null
      ? null
      : Datetime.newInstance(toDate.addDays(1), Time.newInstance(0, 0, 0, 0));
    String soql =
      'SELECT Id, RecordNo__c, Title__c, TypeCode__c, Status__c, Version__c, SubmittedAt__c, CurrentStepNo__c,' +
      ' TargetRecordId__c, Plant__r.PlantCode__c, CreatedBy.Name,' +
      ' (SELECT Id, Approver__r.Name, PendingAt__c FROM Steps__r WHERE Status__c = \'PENDING\')' +
      ' FROM CMN_ApprovalRequest__c WHERE Id != NULL';
    if (view == 'SUBMITTED') {
      soql += ' AND CreatedById = :me';
    } else if (view == 'ACTED') {
      soql += ' AND Id IN (SELECT Request__c FROM CMN_ApprovalStep__c WHERE ActedBy__c = :me)';
    } else {
      soql += ' AND Status__c = \'IN_PROGRESS\'';
    }
    if (String.isNotBlank(typeCode)) {
      soql += ' AND TypeCode__c = :typeCode';
    }
    if (plantId != null) {
      soql += ' AND Plant__c = :plantId';
    }
    if (fromAt != null) {
      soql += ' AND SubmittedAt__c >= :fromAt';
    }
    if (toAt != null) {
      soql += ' AND SubmittedAt__c < :toAt';
    }
    soql += ' ORDER BY SubmittedAt__c DESC NULLS LAST LIMIT 200';
    return Database.queryWithBinds(
      soql,
      new Map<String, Object>{
        'me' => me,
        'typeCode' => typeCode,
        'plantId' => plantId,
        'fromAt' => fromAt,
        'toAt' => toAt
      },
      AccessLevel.USER_MODE
    );
  }

  /**
   * @description 결재자 검색(BR-1): 이름·사번·부서명, 활성 사용자만, 20명.
   * @param term 검색어(2자 이상)
   * @return 사용자
   */
  public static List<User> searchUsers(String term) {
    String likeTerm = '%' + term + '%';
    Set<String> deptCodes = new Set<String>();
    for (CMN_Department__c d : [
      SELECT DeptCode__c
      FROM CMN_Department__c
      WHERE Name LIKE :likeTerm
      WITH SYSTEM_MODE
      LIMIT 50
    ]) {
      deptCodes.add(d.DeptCode__c);
    }
    return [
      SELECT Id, Name, EmployeeNo__c, DepartmentCode__c
      FROM User
      WHERE
        IsActive = TRUE
        AND UserType = 'Standard'
        AND (Name LIKE :likeTerm
        OR EmployeeNo__c LIKE :likeTerm
        OR DepartmentCode__c IN :deptCodes)
      WITH SYSTEM_MODE
      ORDER BY Name
      LIMIT 20
    ];
  }

  /**
   * @description 부서 코드 → 부서명.
   * @param codes 부서 코드
   * @return 코드 → 이름
   */
  public static Map<String, String> departmentNames(Set<String> codes) {
    Map<String, String> out = new Map<String, String>();
    for (CMN_Department__c d : [
      SELECT DeptCode__c, Name
      FROM CMN_Department__c
      WHERE DeptCode__c IN :codes
      WITH SYSTEM_MODE
    ]) {
      out.put(d.DeptCode__c, d.Name);
    }
    return out;
  }

  /**
   * @description 내 개인 결재선 템플릿(유형별).
   * @param typeCode 결재 유형
   * @return 템플릿
   */
  public static List<CMN_ApprovalTemplate__c> personalTemplates(
    String typeCode
  ) {
    Id me = UserInfo.getUserId();
    return [
      SELECT Id, Name
      FROM CMN_ApprovalTemplate__c
      WHERE
        Scope__c = 'PERSONAL'
        AND TypeCode__c = :typeCode
        AND OwnerId = :me
        AND IsActive__c = TRUE
      WITH USER_MODE
      ORDER BY Name
    ];
  }

  /**
   * @description 사용자 이름.
   * @param userIds 사용자
   * @return Id → 이름
   */
  public static Map<Id, User> users(Set<Id> userIds) {
    return new Map<Id, User>(
      [SELECT Id, Name FROM User WHERE Id IN :userIds WITH SYSTEM_MODE]
    );
  }
}
