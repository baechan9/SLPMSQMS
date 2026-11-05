/**
 * @description 공통 편집 그리드 조회(CMN-00-UX-006). 그리드·열 정의는 모든 사용자에게 같은 메타데이터라 시스템 모드로 읽는다
 * (긴 텍스트 필드가 없어 SOQL 한도에 세어지지 않는다). 행·참조 조회는 서비스가 만든 동적 SOQL을 사용자 권한으로 실행한다.
 * @group CMN-00-UX-006
 */
public with sharing class CMN_GridSelector {
  /** 테스트에서 메타데이터 레코드 대신 쓰는 값(GridKey → 정의) */
  @TestVisible
  private static Map<String, CMN_GridDefinition__mdt> definitionsOverride;
  /** 테스트에서 메타데이터 레코드 대신 쓰는 값(GridKey → 열) */
  @TestVisible
  private static Map<String, List<CMN_GridColumn__mdt>> columnsOverride;

  /**
   * @description 그리드 정의.
   * @param gridKey 그리드 키(DeveloperName)
   * @return 정의 또는 null
   */
  public static CMN_GridDefinition__mdt definition(String gridKey) {
    if (definitionsOverride != null) {
      return definitionsOverride.get(gridKey);
    }
    return CMN_GridDefinition__mdt.getInstance(gridKey);
  }

  /**
   * @description 그리드 열(순서대로).
   * @param gridKey 그리드 키
   * @return 열 정의
   */
  public static List<CMN_GridColumn__mdt> columns(String gridKey) {
    if (columnsOverride != null) {
      return columnsOverride.get(gridKey) ?? new List<CMN_GridColumn__mdt>();
    }
    return [
      SELECT
        DeveloperName,
        FieldApiName__c,
        LabelKey__c,
        Order__c,
        Editable__c,
        Required__c,
        Frozen__c,
        WidthWeight__c,
        InputType__c,
        CodeGroup__c,
        LookupFilter__c,
        ShowOnPhone__c
      FROM CMN_GridColumn__mdt
      WHERE Grid__r.DeveloperName = :gridKey
      WITH SYSTEM_MODE
      ORDER BY Order__c, DeveloperName
    ];
  }

  /**
   * @description 서비스가 만든 행·참조 SOQL을 사용자 권한으로 실행한다(객체·필드 권한과 공유 적용).
   * @param soql 바인드 변수를 쓴 SOQL(식별자는 describe로 검증·escape된 값만)
   * @param binds 바인드 값
   * @return 레코드
   */
  public static List<SObject> query(String soql, Map<String, Object> binds) {
    return Database.queryWithBinds(soql, binds, AccessLevel.USER_MODE);
  }

  /**
   * @description 현재 사용자가 레코드를 편집할 수 있는가(공유·소유 기준).
   * @param recordId 레코드 Id
   * @return 편집 권한 여부
   */
  public static Boolean hasEditAccess(Id recordId) {
    List<UserRecordAccess> access = [
      SELECT RecordId, HasEditAccess
      FROM UserRecordAccess
      WHERE UserId = :UserInfo.getUserId() AND RecordId = :recordId
      WITH USER_MODE
    ];
    return !access.isEmpty() && access[0].HasEditAccess == true;
  }
}
