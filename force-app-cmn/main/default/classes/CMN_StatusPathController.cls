/**
 * @description cmnStatusPath 데이터(CMN-00-UX-003 BR-1). 레코드 객체의 상태 흐름 정의(CMN_StatusFlow__mdt·CMN_StatusStep__mdt)를
 * 사용자 언어 라벨로 돌려준다. 현재 상태 값은 화면이 LDS(getRecord)로 읽어 상태가 바뀌면 바로 반영한다.
 * 단계 이름: LabelKey__c(Custom Label, 사용자 언어 → en_US) → 선택 목록 라벨(사용자 언어) → 값.
 * @group CMN-00-UX-003
 */
public with sharing class CMN_StatusPathController {
  /** @description 상태 흐름. */
  public class Path {
    @AuraEnabled
    public String objectApiName;
    @AuraEnabled
    public String statusField;
    @AuraEnabled
    public List<Step> steps = new List<Step>();
  }

  /** @description 단계 하나. */
  public class Step {
    @AuraEnabled
    public String value;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public Boolean isTerminal;
  }

  /**
   * @description 레코드 객체의 상태 흐름(순서대로). 설정이 없으면 null.
   * @param recordId 레코드
   * @return 상태 흐름
   * @throws AuraHandledException 잘못된 입력
   */
  @AuraEnabled(cacheable=true)
  public static Path getPath(Id recordId) {
    if (recordId == null) {
      throw aura(Label.CMN_Common_InvalidInput);
    }
    String objectName = String.valueOf(recordId.getSObjectType());
    CMN_StatusFlow__mdt flow = CMN_StatusFlowSelector.flowFor(objectName);
    if (flow == null) {
      return null;
    }
    Path p = new Path();
    p.objectApiName = objectName;
    p.statusField = flow.StatusField__c;
    Map<String, String> picklistLabels = picklistLabels(
      recordId.getSObjectType(),
      flow.StatusField__c
    );
    String language = UserInfo.getLanguage();
    for (
      CMN_StatusStep__mdt s : CMN_StatusFlowSelector.stepsOf(flow.DeveloperName)
    ) {
      Step step = new Step();
      step.value = s.Value__c;
      step.isTerminal = s.IsTerminal__c;
      step.label = CMN_NotificationService.render(
        s.LabelKey__c,
        language,
        new Map<String, String>()
      ) ?? picklistLabels.get(s.Value__c) ?? s.Value__c;
      p.steps.add(step);
    }
    return p;
  }

  private static Map<String, String> picklistLabels(
    Schema.SObjectType t,
    String fieldName
  ) {
    Map<String, String> out = new Map<String, String>();
    Schema.SObjectField f = t.getDescribe(SObjectDescribeOptions.DEFERRED)
      .fields.getMap()
      .get(fieldName);
    if (f == null) {
      return out;
    }
    for (Schema.PicklistEntry e : f.getDescribe().getPicklistValues()) {
      out.put(e.getValue(), e.getLabel());
    }
    return out;
  }

  private static AuraHandledException aura(String message) {
    AuraHandledException e = new AuraHandledException(message);
    e.setMessage(message);
    return e;
  }
}
