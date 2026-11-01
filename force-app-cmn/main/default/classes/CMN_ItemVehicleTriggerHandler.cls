/**
 * @description 적용 차종 트리거: 외부 키·중복. 잘못 연결한 차종은 지울 수 있다(업무 레코드는 품번·차종을 직접 참조).
 * @group CMN-00-MDM-004
 */
public with sharing class CMN_ItemVehicleTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_ItemService.assignItemVehicleKeys(
      (List<CMN_ItemVehicle__c>) newRecords
    );
  }

  protected override void beforeUpdate() {
    CMN_ItemService.assignItemVehicleKeys(
      (List<CMN_ItemVehicle__c>) newRecords
    );
  }
}
