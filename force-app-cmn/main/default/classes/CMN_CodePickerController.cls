/**
 * @description cmnCodePicker 데이터(CMN-00-MDM-007). 사용자 언어로 이름을 고르고(I18N-001 BR-3 규칙 — MDM-007 AC-1, I18N-001 AC-3),
 * 비활성 코드와 그 하위는 빼고(AC-3) 돌려준다.
 * @group CMN-00-MDM-007
 */
public with sharing class CMN_CodePickerController {
  private static final Pattern GROUP_CODE = Pattern.compile(
    '^[A-Za-z0-9_]{1,40}$'
  );

  /**
   * @description 피커 응답.
   */
  public class PickerData {
    @AuraEnabled
    public String groupCode;
    @AuraEnabled
    public Integer maxLevel;
    @AuraEnabled
    public List<CodeOption> codes = new List<CodeOption>();
  }

  /**
   * @description 코드 한 건(화면에 필요한 값만).
   */
  public class CodeOption {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public Id parentId;
    @AuraEnabled
    public Integer level;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String path;
    @AuraEnabled
    public String externalKey;
  }

  /**
   * @description 그룹의 사용 가능한 코드(정렬: 단계 → 정렬 순서 → 이름).
   * @param groupCode 코드 그룹(예: DEFECT_TYPE)
   * @return 피커 데이터(그룹이 없으면 코드 없는 응답)
   * @throws AuraHandledException 잘못된 그룹 코드
   */
  @AuraEnabled(cacheable=true)
  public static PickerData getCodes(String groupCode) {
    if (String.isBlank(groupCode) || !GROUP_CODE.matcher(groupCode).matches()) {
      AuraHandledException e = new AuraHandledException(
        Label.CMN_Common_InvalidInput
      );
      e.setMessage(Label.CMN_Common_InvalidInput);
      throw e;
    }
    PickerData data = new PickerData();
    data.groupCode = groupCode;
    CMN_CodeGroup__c g = CMN_CodeSelector.groupWithCodes(groupCode);
    if (g == null) {
      return data;
    }
    data.maxLevel = g.MaxLevel__c?.intValue();
    String lang = UserInfo.getLanguage();
    Map<Id, CMN_Code__c> byId = new Map<Id, CMN_Code__c>(g.Codes__r);
    Map<Id, String> labels = new Map<Id, String>();
    for (CMN_Code__c c : g.Codes__r) {
      labels.put(c.Id, localized(c, lang));
    }
    for (CMN_Code__c c : g.Codes__r) {
      if (!activeChain(c, byId)) {
        continue;
      }
      CodeOption o = new CodeOption();
      o.id = c.Id;
      o.parentId = c.Parent__c;
      o.level = c.Level__c?.intValue();
      o.label = labels.get(c.Id);
      o.path = path(c, byId, labels);
      o.externalKey = c.ExternalKey__c;
      data.codes.add(o);
    }
    return data;
  }

  /** I18N-001 BR-3과 같은 규칙: ko → 이름, zh → 중문·영문·이름, 그 외(en·pl·es·pt) → 영문·이름. */
  @TestVisible
  private static String localized(CMN_Code__c c, String lang) {
    String prefix = lang?.left(2);
    if (prefix == 'ko') {
      return c.Name;
    }
    if (prefix == 'zh' && String.isNotBlank(c.NameZh__c)) {
      return c.NameZh__c;
    }
    return String.isBlank(c.NameEn__c) ? c.Name : c.NameEn__c;
  }

  /** 자신과 모든 상위가 사용 중이어야 보인다(AC-3). */
  private static Boolean activeChain(CMN_Code__c c, Map<Id, CMN_Code__c> byId) {
    CMN_Code__c cur = c;
    Integer guard = 0;
    while (cur != null && guard++ < 10) {
      if (!cur.IsActive__c) {
        return false;
      }
      cur = byId.get(cur.Parent__c);
    }
    return true;
  }

  private static String path(
    CMN_Code__c c,
    Map<Id, CMN_Code__c> byId,
    Map<Id, String> labels
  ) {
    List<String> upward = new List<String>();
    CMN_Code__c cur = c;
    Integer guard = 0;
    while (cur != null && guard++ < 10) {
      upward.add(labels.get(cur.Id));
      cur = byId.get(cur.Parent__c);
    }
    List<String> parts = new List<String>();
    for (Integer i = upward.size() - 1; i >= 0; i--) {
      parts.add(upward[i]);
    }
    return String.join(parts, ' > ');
  }
}
