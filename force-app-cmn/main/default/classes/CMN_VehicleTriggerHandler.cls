/**
 * @description 차종 트리거: 외부 키 설정·중복 검사, 삭제 금지(기준정보).
 * @group CMN-00-MDM-003
 */
public with sharing class CMN_VehicleTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    CMN_CustomerService.assignVehicleKeys((List<CMN_Vehicle__c>) newRecords);
  }

  protected override void beforeUpdate() {
    CMN_CustomerService.assignVehicleKeys((List<CMN_Vehicle__c>) newRecords);
  }

  protected override void beforeDelete() {
    CMN_MasterDataGuard.preventDelete(oldRecords);
  }
}
