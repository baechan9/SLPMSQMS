/**
 * @description 품질 특성 화면 진입점(CMN-00-MDM-006): 새 버전 만들기, 활성화. 입력을 다시 검증하고 오류는 라벨 문구로 돌려준다.
 * @group CMN-00-MDM-006
 */
public with sharing class CMN_CharacteristicController {
  /**
   * @description ACTIVE 특성의 새 버전(DRAFT)을 만든다(AC-2의 "새 버전 생성").
   * @param characteristicId ACTIVE 특성 Id
   * @param effectiveFrom 새 버전 적용 시작일
   * @return 새 초안 Id
   * @throws AuraHandledException 권한·입력·상태 오류
   */
  @AuraEnabled
  public static Id createNewVersion(Id characteristicId, Date effectiveFrom) {
    checkAccess(characteristicId);
    try {
      return CMN_CharacteristicService.newVersion(
        characteristicId,
        effectiveFrom
      );
    } catch (CMN_ValidationException e) {
      throw aura(e.getMessage());
    } catch (Exception e) {
      CMN_Logger.error(
        'CMN_CharacteristicController.createNewVersion',
        e.getMessage(),
        characteristicId,
        e
      );
      throw aura(Label.CMN_Common_UnexpectedError);
    }
  }

  /**
   * @description 초안을 활성화한다(이전 ACTIVE 버전은 닫힌다).
   * @param characteristicId DRAFT 특성 Id
   * @throws AuraHandledException 권한·입력·상태 오류
   */
  @AuraEnabled
  public static void activate(Id characteristicId) {
    checkAccess(characteristicId);
    try {
      CMN_CharacteristicService.activate(new Set<Id>{ characteristicId });
    } catch (Exception e) {
      throw toAura(
        e,
        'CMN_CharacteristicController.activate',
        characteristicId
      );
    }
  }

  private static void checkAccess(Id characteristicId) {
    if (
      characteristicId == null ||
      characteristicId.getSObjectType() != CMN_Characteristic__c.SObjectType
    ) {
      throw aura(Label.CMN_Common_InvalidInput);
    }
    if (
      !Schema.SObjectType.CMN_Characteristic__c.isCreateable() ||
      !Schema.SObjectType.CMN_Characteristic__c.isUpdateable()
    ) {
      throw aura(Label.CMN_Common_NoPermission);
    }
  }

  /** 검증 오류는 라벨 문구 그대로, 그 밖의 오류는 기록하고 공통 문구로 바꾼다(원문을 화면에 보내지 않는다). */
  private static AuraHandledException toAura(
    Exception e,
    String source,
    Id recordId
  ) {
    if (e instanceof CMN_ValidationException) {
      return aura(e.getMessage());
    }
    CMN_Logger.error(source, e.getMessage(), recordId, e);
    return aura(Label.CMN_Common_UnexpectedError);
  }

  private static AuraHandledException aura(String message) {
    AuraHandledException e = new AuraHandledException(message);
    e.setMessage(message);
    return e;
  }
}
