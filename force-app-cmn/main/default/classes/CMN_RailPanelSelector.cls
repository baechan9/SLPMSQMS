/**
 * @description 결정 지원 레일 조회(CMN-00-UX-004). 패널 설정은 모든 사용자에게 같은 메타데이터라 시스템 모드로,
 * 레코드의 열린 To-Do는 사용자 권한(USER_MODE)으로 읽는다.
 * @group CMN-00-UX-004
 */
public with sharing class CMN_RailPanelSelector {
  /** 테스트에서 메타데이터 레코드 대신 쓰는 값 */
  @TestVisible
  private static List<CMN_RailPanel__mdt> panelsOverride;

  /**
   * @description 기본(*) 패널과 객체 패널(비활성 포함, 거르기는 호출 측).
   * @param objectApiName 업무 객체 API명
   * @return 패널 설정
   */
  public static List<CMN_RailPanel__mdt> panels(String objectApiName) {
    if (panelsOverride != null) {
      return panelsOverride;
    }
    Set<String> objects = new Set<String>{
      CMN_RailPanelController.ALL_OBJECTS,
      objectApiName
    };
    return [
      SELECT
        DeveloperName,
        ObjectApiName__c,
        PanelKey__c,
        ComponentName__c,
        TitleLabel__c,
        Order__c,
        PhoneOrder__c,
        DefaultOpen__c,
        RequiredPermission__c,
        Config__c,
        IsActive__c
      FROM CMN_RailPanel__mdt
      WHERE ObjectApiName__c IN :objects
      WITH SYSTEM_MODE
      ORDER BY Order__c ASC NULLS LAST, DeveloperName ASC
    ];
  }

  /**
   * @description 레코드에 걸린(원천 또는 대상) 열린 To-Do. 사용자 권한으로 보이는 것만.
   * @param recordId 업무 레코드 Id
   * @param rowLimit 최대 건수
   * @return To-Do(기한 순)
   */
  public static List<CMN_Todo__c> openTodos(Id recordId, Integer rowLimit) {
    String rid = String.valueOf(recordId);
    String open = CMN_TodoService.OPEN;
    return [
      SELECT
        Id,
        TitleLabel__c,
        TitleParams__c,
        TitleFallback__c,
        RecordNo__c,
        DueDate__c,
        IsOverdue__c,
        Assignee__r.Name
      FROM CMN_Todo__c
      WHERE
        Status__c = :open
        AND (SourceRecordId__c = :rid
        OR TargetRecordId__c = :rid)
      WITH USER_MODE
      ORDER BY DueDate__c ASC NULLS LAST, CreatedDate ASC, Id ASC
      LIMIT :rowLimit
    ];
  }
}
