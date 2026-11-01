trigger CMN_LogEventTrigger on CMN_LogEvent__e(after insert) {
  new CMN_LogEventTriggerHandler().run();
}
