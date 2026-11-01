/**
 * @description 품질 특성 조회(CMN-00-MDM-006). 버전 처리는 서비스가 상태를 바꾸므로 시스템 모드로 읽는다(특성은 사내 공개 읽기).
 * @group CMN-00-MDM-006
 */
public with sharing class CMN_CharacteristicSelector {
  /**
   * @description 특성(버전 복제에 필요한 필드 전체).
   * @param ids 특성 Id
   * @return 특성 목록
   */
  public static List<CMN_Characteristic__c> byIds(Set<Id> ids) {
    return [
      SELECT
        Id,
        Name,
        Item__c,
        CharNo__c,
        CharType__c,
        Nominal__c,
        USL__c,
        LSL__c,
        Unit__c,
        SpecialClass__c,
        CustomerSymbol__c,
        SpcRequired__c,
        TargetCpk__c,
        Status__c,
        EffectiveFrom__c,
        EffectiveTo__c
      FROM CMN_Characteristic__c
      WHERE Id IN :ids
      WITH SYSTEM_MODE
    ];
  }

  /**
   * @description 품번·특성 번호의 현재 ACTIVE 버전.
   * @param itemIds 품번 Id
   * @param charNos 특성 번호
   * @return ACTIVE 특성 목록
   */
  public static List<CMN_Characteristic__c> activeVersions(
    Set<Id> itemIds,
    Set<String> charNos
  ) {
    return [
      SELECT Id, Item__c, CharNo__c, EffectiveFrom__c
      FROM CMN_Characteristic__c
      WHERE
        Item__c IN :itemIds
        AND CharNo__c IN :charNos
        AND Status__c = 'ACTIVE'
      WITH SYSTEM_MODE
    ];
  }
}
