trigger CMN_ContentVersionTrigger on ContentVersion(before insert) {
  new CMN_ContentVersionTriggerHandler().run();
}
