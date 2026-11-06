// 개발·검토 Scratch 전용(CMN-00-UX-004~009 공통 화면 부품 시연): 테스트 객체 샘플 레코드 1건과 그리드 행 6개를 만든다.
// 사용: sf apex run -o <alias> -f scripts/apex/seed-common-parts-demo.apex
// 이미 있으면 건너뛴다. 번호는 채번(ARC-003)이 매긴다(새 Org의 첫 건 = TST-KR01-{YYYY}-000001).
// 날짜는 오늘 기준으로 놓아 기한 경과 1건·완료 1건·진행 중 일정 막대가 보이게 한다. 운영·SIT에서 실행하지 않는다.
CMN_Plant__c plant = [
  SELECT Id
  FROM CMN_Plant__c
  WHERE PlantCode__c = 'KR01'
  LIMIT 1
];
List<CMN_TestRecord__c> existing = [
  SELECT Id, RecordNo__c
  FROM CMN_TestRecord__c
  WHERE Name = 'UX-004 Standard Record Sample'
  LIMIT 1
];
CMN_TestRecord__c rec;
if (existing.isEmpty()) {
  rec = new CMN_TestRecord__c(
    Name = 'UX-004 Standard Record Sample',
    Plant__c = plant.Id,
    Status__c = 'IN_PROGRESS',
    DueDate__c = Date.today().addDays(-2)
  );
  insert rec;
} else {
  rec = existing[0];
}
if (
  [SELECT COUNT() FROM CMN_TestRecordLine__c WHERE TestRecord__c = :rec.Id] == 0
) {
  Map<String, Id> codes = new Map<String, Id>();
  for (CMN_Code__c c : [
    SELECT Id, ExternalKey__c
    FROM CMN_Code__c
    WHERE
      ExternalKey__c IN (
        'DEFECT_TYPE/APPEARANCE/FOREIGN',
        'DEFECT_TYPE/APPEARANCE/HAZE',
        'DEFECT_TYPE/APPEARANCE/SCRATCH'
      )
  ]) {
    codes.put(c.ExternalKey__c.substringAfterLast('/'), c.Id);
  }
  List<String> categories = new List<String>{ 'PLAN', 'CHECK', 'ACTION' };
  List<String> codeKeys = new List<String>{ 'FOREIGN', 'HAZE', 'SCRATCH' };
  List<Integer> starts = new List<Integer>{ -14, -12, -4, 1, 6, 11 };
  List<Integer> ends = new List<Integer>{ -7, -2, 7, 14, 21, 28 };
  List<CMN_TestRecordLine__c> lines = new List<CMN_TestRecordLine__c>();
  for (Integer i = 0; i < 6; i++) {
    lines.add(
      new CMN_TestRecordLine__c(
        TestRecord__c = rec.Id,
        LineNo__c = i + 1,
        Category__c = categories[Math.mod(i, 3)],
        Quantity__c = i + 1,
        StartDate__c = Date.today().addDays(starts[i]),
        EndDate__c = Date.today().addDays(ends[i]),
        Code__c = codes.get(codeKeys[Math.mod(i, 3)]),
        Plant__c = plant.Id,
        IsDone__c = i == 0
      )
    );
  }
  insert lines;
}
System.debug(
  [SELECT RecordNo__c FROM CMN_TestRecord__c WHERE Id = :rec.Id].RecordNo__c
);
