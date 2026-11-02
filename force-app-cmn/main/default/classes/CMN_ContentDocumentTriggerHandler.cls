/**
 * @description ContentDocument 트리거(CMN-00-DOC-001 BR-2). 공개·대체·결재 중 리비전이 쓰는 파일은 지울 수 없다(감사 증빙).
 * @group CMN-00-DOC-001
 */
public with sharing class CMN_ContentDocumentTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeDelete() {
    Set<String> ids = new Set<String>();
    for (SObject d : oldRecords) {
      ids.add(d.Id);
    }
    Set<String> locked = CMN_DocumentSelector.lockedFiles(ids);
    for (SObject d : oldRecords) {
      if (locked.contains(d.Id)) {
        d.addError(Label.CMN_Doc_ReleasedLocked);
      }
    }
  }
}
