/**
 * @description 고객 요구사항(CSR)과 차종 규칙(CMN-00-MDM-003). 기한 필드가 비면 CMN 설정의 전사 기본값을 쓴다(BR-2).
 * @group CMN-00-MDM-003
 */
public with sharing class CMN_CustomerService {
  public static final String KEY_CONTAINMENT_DAYS = 'CMN_CSR_CONTAINMENT_DUE_DAYS';
  public static final String KEY_8D_DAYS = 'CMN_CSR_8D_DUE_DAYS';
  public static final String KEY_ROOT_CAUSE_DAYS = 'CMN_CSR_ROOT_CAUSE_DUE_DAYS';

  /** 설정이 없을 때 쓰는 명세 기본값(BR-2: D3 1일, 8D 30일, 원인 10일). */
  private static final Integer FALLBACK_CONTAINMENT = 1;
  private static final Integer FALLBACK_8D = 30;
  private static final Integer FALLBACK_ROOT_CAUSE = 10;

  /**
   * @description 고객 요구사항(기본값을 채운 값). 클레임·8D·4M·NCR·PPAP가 고객별 기한·양식을 정할 때 쓴다.
   */
  public class Requirements {
    @AuraEnabled
    public Id customerId;
    @AuraEnabled
    public String oemCode;
    @AuraEnabled
    public String customerGroup;
    @AuraEnabled
    public Integer containmentDueDays;
    @AuraEnabled
    public Integer eightDDueDays;
    @AuraEnabled
    public Integer rootCauseDueDays;
    @AuraEnabled
    public String ppapDefaultLevel;
    @AuraEnabled
    public List<String> auditStandards;
    @AuraEnabled
    public String claimFormTemplate;
    @AuraEnabled
    public Integer changeNoticeLeadDays;
    @AuraEnabled
    public Boolean concessionCustomerApproval;
  }

  /**
   * @description 고객별 요구사항.
   * @param customerIds 고객 Account Id
   * @return Account Id → 요구사항(없는 Id는 빠진다)
   */
  public static Map<Id, Requirements> requirements(Set<Id> customerIds) {
    Integer containment = CMN_Settings.getInteger(
      KEY_CONTAINMENT_DAYS,
      FALLBACK_CONTAINMENT
    );
    Integer eightD = CMN_Settings.getInteger(KEY_8D_DAYS, FALLBACK_8D);
    Integer rootCause = CMN_Settings.getInteger(
      KEY_ROOT_CAUSE_DAYS,
      FALLBACK_ROOT_CAUSE
    );
    Map<Id, Requirements> result = new Map<Id, Requirements>();
    for (Account a : CMN_CustomerSelector.customers(customerIds)) {
      Requirements r = new Requirements();
      r.customerId = a.Id;
      r.oemCode = a.OemCode__c;
      r.customerGroup = a.CustomerGroup__c;
      r.containmentDueDays = a.ContainmentDueDays__c?.intValue() ?? containment;
      r.eightDDueDays = a.EightDDueDays__c?.intValue() ?? eightD;
      r.rootCauseDueDays = a.RootCauseDueDays__c?.intValue() ?? rootCause;
      r.ppapDefaultLevel = a.PpapDefaultLevel__c;
      r.auditStandards = String.isBlank(a.AuditStandard__c)
        ? new List<String>()
        : a.AuditStandard__c.split(';');
      r.claimFormTemplate = a.ClaimFormTemplate__c;
      r.changeNoticeLeadDays = a.ChangeNoticeLeadDays__c?.intValue();
      r.concessionCustomerApproval = a.ConcessionCustomerApproval__c;
      result.put(a.Id, r);
    }
    return result;
  }

  /**
   * @description 차종 외부 키 = {OemCode}-{VehicleCode}. 같은 고객의 같은 차종 코드는 오류.
   * @param vehicles 저장할 차종(before insert·update)
   */
  public static void assignVehicleKeys(List<CMN_Vehicle__c> vehicles) {
    Set<Id> customerIds = new Set<Id>();
    for (CMN_Vehicle__c v : vehicles) {
      customerIds.add(v.Customer__c);
    }
    Map<Id, Account> customers = new Map<Id, Account>(
      CMN_CustomerSelector.customers(customerIds)
    );
    for (CMN_Vehicle__c v : vehicles) {
      Account c = customers.get(v.Customer__c);
      if (
        c == null ||
        String.isBlank(c.OemCode__c) ||
        String.isBlank(v.VehicleCode__c)
      ) {
        continue;
      }
      v.VehicleCode__c = v.VehicleCode__c.trim();
      v.ExternalKey__c = c.OemCode__c + '-' + v.VehicleCode__c;
    }
    CMN_KeyGuard.rejectDuplicates(
      vehicles,
      CMN_Vehicle__c.ExternalKey__c,
      CMN_Vehicle__c.VehicleCode__c,
      CMN_Vehicle__c.VehicleCode__c,
      Label.CMN_Customer_DuplicateVehicleCode
    );
  }
}
