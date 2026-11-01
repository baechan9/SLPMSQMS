trigger CMN_UserTrigger on User(
  before insert,
  before update,
  after insert,
  after update
) {
  new CMN_UserTriggerHandler().run();
}
