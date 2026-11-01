# WI 변경 요청 — Salesforce 데모 데이터 작업

데모 CSV를 만들며 확인한 WI 정의 누락·불일치다. 2단계 WI 보강 작업이 반영한다. 생성기(`gen_salesforce.py`)가 다시 만들므로 손으로 고치지 않는다.

| 대상 WI | 내용 | 데모에서 쓴 임시 값 |
| --- | --- | --- |
| CMN-00-APV-001 | CMN_ApprovalStep__c에 ExternalKey__c 추가(결재 요청 RecordNo + 단계 번호) | {APV 번호}-S{StepNo} |
| CMN-00-APV-002 | CMN_RoleAssignment__c·CMN_ApprovalTemplate__c·CMN_ApprovalTemplateStep__c에 ExternalKey__c 추가 | RA-{Role}-{Plant 또는 ALL}-{사번}, TPL-{TypeCode}, TPL-{TypeCode}-{StepNo} |
| CMN-00-APV-004 | CMN_Delegation__c에 ExternalKey__c 추가 | DLG-{위임자 사번}-{시작일 yyyymmdd} |
| CMN-00-ARC-003 | 데모·이관 적재 시 RecordNo가 이미 있으면 채번하지 않고 카운터를 그 값 이상으로 맞추는 동작 필요(데모 명세 4절과 같음) | CSV RecordNo 그대로 적재 |
| CMN-00-DOC-001 | CMN_Document__c에 ExternalKey__c(업서트 키) 추가. CMN_DocumentRevision__c.ExternalKey__c는 "외부 저장소 키"로 정의돼 있어 업서트 키와 이름이 충돌 → 외부 저장소 키를 ExternalRef__c로 바꾸고 ExternalKey__c를 External ID로 | DOC-{부모 키}-{DocClass}, 리비전 = {문서 키}-R1(데모는 ExternalKey__c를 업서트 키로 사용) |
| CMN-00-DOC-001 | CMN_Document__c.Supplier__c·SupplierVisible__c(Vol.3 요청)를 본문에 추가 | 협력사 공개 문서만 채움 |
| CMN-00-MDM-001 | User.EmployeeNo__c External ID는 정의돼 있으나 데모 사용자 수가 Scratch Org 라이선스에 묶임 — 미생성 사용자 Lookup의 대체 규칙(실행 관리자) 필요 | 로더 onMissingUser: skip/admin |
| CMN-00-MDM-002 | CMN_Operation__c에 ExternalKey__c(Text(80), External ID, Unique) 추가. 이관·데모 upsert 키 | {PlantCode}-{LineCode}-{OpCode} |
| CMN-00-MDM-003 | Account.RootCauseDueDays__c(Vol.5 요청)를 MDM-003 본문에 추가 | 고객별 7~10일 |
| CMN-00-MDM-004 | CMN_ItemVehicle__c에 ExternalKey__c 추가(UsagePerVehicle__c는 Vol.5 요청) | {ItemNo}-{VehicleKey} |
| CMN-00-MDM-006 | Unit__c 값에 lm, cc/min, mA 추가 | 해당 특성 Unit = ETC, 이름에 단위 표기는 마스터 unitNotes 기준 |
| CMN-00-MDM-007 | CMN_Code__c.ExternalKey__c를 계층 경로 전체 {Group}/{L1}/{L2}/{L3}로 정의(같은 그룹 안 하위 코드 이름 중복 허용) | 예: CHANGE_TYPE/METHOD/CONDITION/PROCESS_PARAM |
| CMN-00-MDM-007 | 코드 그룹 GAUGE_TYPE·IQC_COMMON_CHECK·DEFECT_LOCATION 초기값, DOC_CLASS 값(PPAP 하위 18요소 포함) 확정 | demo_master.json·gen_salesforce.codes() 값 |
| CMN-00-MDM-007 | GAUGE_TYPE에 DIAL_GAUGE·HARDNESS_TESTER·MOISTURE_ANALYZER·MICROSCOPE 추가(분석실 장비) | 데모 코드로 추가 |
| CMN-00-TDO-001 | CMN_Todo__c.ExternalKey__c = {SourceType}/{SourceRecordId}/{AssigneeId}가 Salesforce Id를 포함해 이관·데모 CSV에서 미리 만들 수 없음 — 적재 시 Id 치환 필요(데모 로더가 토큰으로 처리) | {SourceType}/{{ref:…}}/{{user:사번}} |
| QMS-02-DVQ-002 | QMS_TestStandard__c·QMS_TestStandardLine__c에 ExternalKey__c 추가, ChangeTypes__c 값 형식을 CHANGE_TYPE 경로 키(쉼표 구분)로 명시 | TS-{요지}, TS-{요지}-{nn} |
| QMS-02-DVQ-003 | QMS_QualPlanLine__c에 ExternalKey__c 추가(라인 Id를 문서 부모·NCR 원천으로 참조) | {계획 번호}-L{nn} |
| QMS-03-IQC-001 | QMS_SamplingPlanRow__c·QMS_IqcStandard__c·QMS_IqcStandardLine__c에 ExternalKey__c 추가 | C0-DEMO-{Level}-{From}, IQS-{ItemNo}-{Plant}-V{n}, IQS-...-L{nn} |
| QMS-03-IQC-001 | 데모 샘플링 표는 가정 값(c=0, 6구간). SL 현행 표로 교체 | C0-DEMO |
| QMS-03-IQC-002 | QMS_IqcResult__c에 ExternalKey__c 추가(로트 키 + 라인 번호), QMS_IqcLot__c에 Coa__c 필드 정의 누락(IQC-006 BR-3이 사용) — 데모는 COA.MatchedLot만 채움 | {로트 ExternalKey}-R{nn} |
| QMS-03-IQC-003 | 수입검사 대기열 화면 Apex DTO 정의 없음 | mocks/apex/qmsIqcQueue/KR01.json(제안 DTO) |
| QMS-03-IQC-005 | QMS_IqcLevelChange__c·QMS_IqcLevelHold__c에 ExternalKey__c 추가 | LC-{SupplierItem}-{yyyymmdd}, HOLD-{원천 번호} |
| QMS-03-PPA-001 | PPAP 요소 레벨별 S/R 값 확정(품질경영팀 매뉴얼 검수) | 데모 가정: 레벨3 = 샘플·마스터 샘플·검사 보조구 R, 나머지 S. Guidance에 [데모 가정] 표시 |
| QMS-03-PPA-001 | QMS_PpapLevelRule__c에 ExternalKey__c 추가 | PLR-{요지} |
| QMS-03-PPA-002 | QMS_PpapElementLine__c·QMS_PpapSubmission__c에 ExternalKey__c 추가 | {PPAP 번호}-{요소 코드}, {PPAP 번호}-R{n} |
| QMS-03-SPP-001 | Contact에 ExternalKey__c 추가(협력사 담당자 이관·데모 upsert) | CT-{VendorNo}-{nn} |
| QMS-03-SPP-002 | 협력사 포털 홈 Apex DTO 정의 없음 | mocks/apex/qmsPortalHome/V10003.json(제안 DTO) |
| QMS-03-SPP-003 | QMS_SupplierCertificate__c에 ExternalKey__c 추가 | SC-{VendorNo}-{CertType} |
| QMS-05-CLM-001 | QMS_EightDTeamMember__c·QMS_EightDAction__c에 ExternalKey__c 추가(EightDStep은 정의됨) | {8D 번호}-TM{nn}, {8D 번호}-{ActionNo} |
| QMS-05-CLM-001 | QMS_Claim__c에 MIS(판매 후 개월)·VIN 해시 수 필드 없음 — S2 D2 초안 요소(MIS·VIN 해시 수)를 둘 곳이 없음. 필드 추가 또는 Snowflake B2B 조회로 표시 규칙 명시 | LotInfo__c·DefectDescription__c 텍스트에 기록 |
| QMS-05-CLM-001 | QMS_EightDStatusDTO 외 8D 작성 화면 초기 로드 DTO가 없음 | mocks/apex/qmsEightDScreen/S1-8D.json(제안 DTO) |
| QMS-05-CLM-005 | QMS_EightDSubmission__c에 ExternalKey__c 추가, SubmittedBy__c(포털 사용자 Lookup)는 데모에서 비움 | {8D 번호}-{Stage}-R{Round} |
| QMS-06-4MC-001 | QMS_ChangeTypeRule__c에 ExternalKey__c 추가(SL 기준표 이관 키) | CTR-{요지} |
| QMS-06-4MC-002 | QMS_FourMItem__c·QMS_FourMVerification__c에 ExternalKey__c 추가 | {4M 번호}-I{nn}, {4M 번호}-V{nn} |
| QMS-06-4MC-002 | QMS_FourMStatusDTO 필드 정의 없음(getStatusBySource 반환형만 있음), 검증 그리드 DTO 없음 | mocks/apex/QMS_FourMStatusDTO/S3-4M.json, qmsFourMVerificationGrid/S3-4M.json(제안 DTO) |
| QMS-06-GAU-001 | 측정기 RecordNo 패턴 GA-{PLANT}-{SEQ:6}과 GaugeNo(GA-KR01-0123)가 같은 접두라 혼동 — RecordNo 접두를 'GAU-'로 바꾸는 안 | 데모는 WI 패턴 그대로 GA-KR01-000001 형식 |
| QMS-06-IAU-001 | QMS_AuditGradeRule__c에 ExternalKey__c 추가, 등급·강등 규칙 실제 값 확정(원문 검수) | [데모 가정] A≥90, B≥80, C<80, 별표 0점 → C |
| QMS-06-IAU-002 | QMS_AuditResultItem__c·QMS_CustomerAuditPrepTask__c에 ExternalKey__c 추가 | {심사 번호}-{질문 번호}, {심사 번호}-T{nn} |
| QMS-06-LAB-001 | QMS_LabRequestItem__c에 ExternalKey__c 추가 | {의뢰 번호}-I{nn} |
| QMS-06-NCR-003 | QMS_NcrContainment__c에 ExternalKey__c 추가(Disposition은 정의됨) | {NCR 번호}-C{nn}, {NCR 번호}-D{nn} |
| 데모 명세 5절 S0 | NCR 70건·클레임 20건·4M 12건·인정시험 15건·PPAP 18건에 시나리오(S1·S2·S3) 레코드 포함 여부가 명시되지 않음 — 데모는 포함해 합계를 맞춤 | NCR 70(INTERNAL 45·SUPPLIER 25·종결 62, S1·S2 포함), 클레임 20(S2 포함), 4M 12·인정시험 15·PPAP 18(S3 포함) |
| 데모 명세 8절 | 변경 요청 파일을 데이터 작업별로 나눔(Salesforce: wi-change-requests-salesforce.md, Snowflake: wi-change-requests-snowflake.md). 명세의 wi-change-requests.md 단일 파일 표기와 다름 | 두 파일로 운영 |
