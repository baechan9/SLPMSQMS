trigger CMN_ApprovalEventTrigger on CMN_ApprovalEvent__e(after insert) {
  new CMN_ApprovalEventTriggerHandler().run();
}
