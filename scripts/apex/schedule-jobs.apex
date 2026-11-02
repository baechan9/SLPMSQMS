// 공통 스케줄 잡 예약(Scratch·Sandbox 빌드 후 1회). 이미 예약된 이름은 건너뛴다.
// 실행: sf apex run -o <alias> -f scripts/apex/schedule-jobs.apex
Map<String, Schedulable> jobs = new Map<String, Schedulable>{
  // CMN-00-APV-005: 매시 정각, 공장 현지 09:00인 공장만 처리
  'CMN_ApprovalReminderJob' => new CMN_ApprovalReminderJob()
};
Map<String, String> crons = new Map<String, String>{
  'CMN_ApprovalReminderJob' => '0 0 * * * ?'
};
Set<String> existing = new Set<String>();
for (CronTrigger t : [SELECT CronJobDetail.Name FROM CronTrigger]) {
  existing.add(t.CronJobDetail.Name);
}
for (String name : jobs.keySet()) {
  if (!existing.contains(name)) {
    System.schedule(name, crons.get(name), jobs.get(name));
    System.debug('scheduled ' + name);
  }
}
