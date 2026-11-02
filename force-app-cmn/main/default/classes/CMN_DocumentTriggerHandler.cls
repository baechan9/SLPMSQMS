/**
 * @description CMN_Document__c 트리거(CMN-00-DOC-001). 공장·협력사 공유는 프레임워크(SEC-002)가 한다.
 * - 저장: 소속 객체를 부모 Id에서 채우고, 문서 분류가 DOC_CLASS 코드인지 확인한다. 부모는 바꿀 수 없다.
 * - 삭제: 작성 중·반려 리비전만 있는 문서만 지울 수 있다(공개·대체·결재 중 리비전은 주종 삭제로도 지우지 않는다, BR-2).
 * @group CMN-00-DOC-001
 */
public with sharing class CMN_DocumentTriggerHandler extends CMN_TriggerHandler {
  private static final Set<String> DELETABLE = new Set<String>{
    CMN_DocumentService.DRAFT,
    CMN_DocumentService.REJECTED
  };

  protected override void beforeInsert() {
    prepare((List<CMN_Document__c>) newRecords, null);
  }

  protected override void beforeUpdate() {
    prepare((List<CMN_Document__c>) newRecords, oldMap);
  }

  protected override void beforeDelete() {
    Set<Id> blocked = new Set<Id>();
    for (
      CMN_DocumentRevision__c r : CMN_DocumentSelector.revisionsOf(
        oldMap.keySet()
      )
    ) {
      if (!DELETABLE.contains(r.Status__c)) {
        blocked.add(r.Document__c);
      }
    }
    for (CMN_Document__c d : (List<CMN_Document__c>) oldRecords) {
      if (blocked.contains(d.Id)) {
        d.addError(Label.CMN_Doc_CannotDelete);
      }
    }
  }

  private static void prepare(
    List<CMN_Document__c> rows,
    Map<Id, SObject> oldMap
  ) {
    Set<Id> classIds = new Set<Id>();
    for (CMN_Document__c d : rows) {
      classIds.add(d.DocClass__c);
    }
    Map<Id, CMN_Code__c> classes = CMN_DocumentSelector.classGroups(classIds);
    for (CMN_Document__c d : rows) {
      CMN_Document__c old = (CMN_Document__c) oldMap?.get(d.Id);
      if (old != null) {
        d.ParentRecordId__c = old.ParentRecordId__c;
      }
      Id parentId = idOf(d.ParentRecordId__c);
      if (parentId == null) {
        d.addError(Label.CMN_Common_InvalidInput);
        continue;
      }
      d.ParentRecordId__c = parentId;
      d.ParentObject__c = String.valueOf(parentId.getSObjectType());
      CMN_Code__c c = classes.get(d.DocClass__c);
      if (c?.CodeGroup__r?.GroupCode__c != CMN_DocumentService.CLASS_GROUP) {
        d.addError(Label.CMN_Doc_InvalidClass);
      }
    }
  }

  private static Id idOf(String value) {
    try {
      return String.isBlank(value) ? null : Id.valueOf(value);
    } catch (StringException e) {
      return null;
    }
  }
}
