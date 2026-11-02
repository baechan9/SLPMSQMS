/**
 * @description ContentVersion 트리거(CMN-00-DOC-001 BR-2·AC-2). 공개·대체·결재 중 리비전의 파일에는 새 버전을 올릴 수 없다
 * (Files의 "새 버전 업로드"로 공개 문서 내용을 바꾸는 것을 막는다). 새 내용은 문서 패널에서 새 리비전으로 올린다.
 * @group CMN-00-DOC-001
 */
public with sharing class CMN_ContentVersionTriggerHandler extends CMN_TriggerHandler {
  protected override void beforeInsert() {
    Set<String> docs = new Set<String>();
    for (ContentVersion v : (List<ContentVersion>) newRecords) {
      if (v.ContentDocumentId != null) {
        docs.add(v.ContentDocumentId);
      }
    }
    if (docs.isEmpty()) {
      return;
    }
    Set<String> locked = CMN_DocumentSelector.lockedFiles(docs);
    for (ContentVersion v : (List<ContentVersion>) newRecords) {
      if (locked.contains(v.ContentDocumentId)) {
        v.addError(Label.CMN_Doc_ReleasedLocked);
      }
    }
  }
}
