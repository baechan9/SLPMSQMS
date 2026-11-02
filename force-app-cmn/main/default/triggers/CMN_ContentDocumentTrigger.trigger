trigger CMN_ContentDocumentTrigger on ContentDocument(before delete) {
  new CMN_ContentDocumentTriggerHandler().run();
}
