/**
 * @description 앱 메뉴 허브 설정 조회(화면 우선 플랜 A0 앱 내비게이션 골격). 메뉴 설정은 모든 사용자에게 같은 메타데이터라 시스템 모드로 읽는다.
 * @group A0-PROTO-KIT
 */
public with sharing class CMN_AppMenuSelector {
  /** 테스트에서 메타데이터 레코드 대신 쓰는 값 */
  @TestVisible
  private static List<CMN_AppMenu__mdt> menusOverride;
  @TestVisible
  private static List<CMN_AppMenuItem__mdt> itemsOverride;

  /**
   * @description 메뉴 1건.
   * @param menuKey 메뉴 키(DeveloperName)
   * @return 메뉴(없으면 null)
   */
  public static CMN_AppMenu__mdt menu(String menuKey) {
    List<CMN_AppMenu__mdt> rows = menusOverride ??
      [
        SELECT
          DeveloperName,
          System__c,
          TitleLabel__c,
          DescLabel__c,
          IconName__c,
          IsActive__c
        FROM CMN_AppMenu__mdt
        WHERE DeveloperName = :menuKey
        WITH SYSTEM_MODE
        LIMIT 1
      ];
    for (CMN_AppMenu__mdt m : rows) {
      if (m.DeveloperName == menuKey) {
        return m;
      }
    }
    return null;
  }

  /**
   * @description 메뉴의 활성 기능 타일(순서대로).
   * @param menuKey 메뉴 키
   * @return 타일
   */
  public static List<CMN_AppMenuItem__mdt> items(String menuKey) {
    if (itemsOverride != null) {
      List<CMN_AppMenuItem__mdt> out = new List<CMN_AppMenuItem__mdt>();
      for (CMN_AppMenuItem__mdt i : itemsOverride) {
        if (i.Menu__r?.DeveloperName == menuKey && i.IsActive__c) {
          out.add(i);
        }
      }
      return out;
    }
    return [
      SELECT
        DeveloperName,
        Menu__r.DeveloperName,
        Order__c,
        FeatureCode__c,
        TitleLabel__c,
        DescLabel__c,
        IconName__c,
        TargetType__c,
        Target__c,
        Bundle__c,
        IsActive__c
      FROM CMN_AppMenuItem__mdt
      WHERE Menu__r.DeveloperName = :menuKey AND IsActive__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Order__c ASC NULLS LAST, DeveloperName ASC
    ];
  }
}
