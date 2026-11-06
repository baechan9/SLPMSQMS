# P0 착수 준비

개발을 시작할 수 있는 환경·도구·결정을 갖춘다. WI는 CMN-00-ARC-001 하나지만, 그 밖의 준비 작업(스파이크, 데모 로더 보강, 현황표 정비)이 함께 들어간다. 이 페이즈만 엄격한 장벽이다. P0 게이트 전에는 어떤 WI도 착수하지 않는다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | 정의 파일로 필요한 기능이 켜진 Scratch Org를 만들고, 재현 스크립트·CI·단계 적재 로더가 동작하며, P1~P2 착수에 필요한 결정이 끝난 상태 |
| 기간(기본 인원) | 누적 4영업일. 결정은 사용자 일정에 따름 |
| 마일스톤 | 정의 파일·재현 스크립트·CI 동작 |
| 다음 페이즈 착수 조건 | 이 문서 7절 게이트 통과 + Vol.0 W0 WI 승인 |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 1건 · 4 M/D · W0 1 · SF 트랙 1건 · 외부 트랙 0건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | CMN-00-ARC-001 | 개발 환경·저장소·CI/CD 표준 | W0 | 4 | SF + DW 목 + 연계 시뮬 | — | P0 스파이크 결과를 보고서에 기록 |
<!-- END:WI-TABLE -->

## 3. 작업

WI 밖 작업에도 번호(T0-n)를 붙여 DEV-STATUS 비고와 게이트 기록에서 가리킨다.

| 번호 | 작업 | 담당 | 산출물 | 공수 | 상태(2026-11-02) |
| --- | --- | --- | --- | --- | --- |
| T0-1 | 결정·검토 | 사용자 | 8절 결정 기록, Vol.0 W0 26건 승인(`workitem-index.csv` 상태) | — | 일부 완료: 검토 전 명세 착수 동의(승인 대신), DEV-4·CR-5 권고안 채택. D-1·D-3·D-6 등 대기 |
| T0-2 | 도구 준비 | 개발 | `sf update`, `npm install`(husky 훅 활성), `sf plugins install code-analyzer`. `npm run lint`·`npm run test:unit`·`npm run prettier:verify`가 빈 저장소에서 통과 | 0.5 | **완료**(3.5절) |
| T0-3 | ARC-001 구현 | 개발 | 3.1절 | 4(WI 공수) | **일부 완료**(보고서 `docs/wi/CMN-00-ARC-001.md`, AC 남은 확인 3건) |
| T0-4 | 스파이크 | 개발 | 3.2절 결과표(ARC-001 보고서에 첨부) | 1 | **완료**(S-9 제외, 3.4절) |
| T0-5 | 데모 도구 보강 | 개발 | 3.3절(로더 단계 적재), 생성기 기준일 이동 `--today` 확인(dev-plan 8.2절). 이관 모드 권한 부여·회수는 CR-12 결정 후 | 1.5 | **완료**(이관 모드 제외) |
| T0-6 | 현황표 정비 | 개발 | DEV-STATUS 원칙 문구를 이 플랜으로 바꿈(CR-10), 진행 표에 페이즈·레인 열 추가, 227건 행을 `대기`로 미리 채움 | 0.5 | **완료**(표는 `build_dev_plan.py`가 배정표로 다시 씀, 진행 값 보존) |
| T0-7 | 원격 저장소 | 사용자 | `main` push, 브랜치 보호(PR 필수, CI 통과 필수), GitHub Secrets 등록(`SF_AUTH_URL_CI`), 공개 여부 재결정 | — | 대기 |
| T0-8 | 외부 트랙 준비 시작 | 사용자·외부 트랙 담당 | Snowflake DEV 계정·`SL_QDW_DEV`, Anypoint DEV 접근. P2(DWH-001)·P3(L3 연결) 전에 필요 | — | 대기 |

### 3.1 ARC-001 구현 범위(Scratch Org 기준)

| 산출물 | 내용 | 확인 |
| --- | --- | --- |
| `sfdx-project.json` | 패키지 디렉터리 `force-app-cmn`(default)·`force-app-qms`·`force-app-pms`. 빈 `force-app/` 제거. 분해 옵션(`sourceBehaviorOptions`) 적용 여부 반영 | `sf project deploy start --dry-run` 성공 |
| `config/project-scratch-def.json` | dev-plan 5.3절 제안안을 스파이크 결과로 확정. MultiCurrency·Platform Encryption은 D-3·D-6 결정 전 넣지 않음 | 생성 성공, 기능 켜짐 확인 |
| `code-analyzer.yml` | Recommended 규칙, 심각도 기준 2, 제외 경로(`docs/`, `data/`, `scripts/`) | `sf code-analyzer run` 동작 |
| `.github/workflows/ci.yml` | dev-plan 6.3절 작업 4종. 트리거는 `pull_request`·`push`(main)·`schedule` | 샘플 PR에서 동작 |
| `scripts/ci/check-coverage.py` | 테스트 결과 JSON에서 클래스별 커버리지를 읽어 85% 미만 클래스명을 출력하고 실패 | AC-2 |
| `scripts/org/build-scratch.sh` | dev-plan 5.5절 8단계 | 빈 소스로 끝까지 동작 |
| `jest.config.js` | 데모 목 경로(`data/demo/mocks/apex`) 매핑(DEV-STATUS 비고) | Jest가 목 JSON을 읽음 |
| `snowflake/migrations/V001__init.sql`, schemachange 설정 | 외부 트랙 뼈대(AC-3은 외부 트랙에서 확인) | — |
| Mule 디렉터리 | ARC-001 `mule/` 대 QMS-09 `integration/` 중 하나로 정함(CR-7), README만 | — |
| `docs/wi/CMN-00-ARC-001.md` | 완료 보고서. 스파이크 결과표, 수동 설정 목록(dev-plan 5.6절 확정본) 포함 | — |

ARC-001 AC-1("CMN 테스트가 전부 통과")은 CMN 코드가 생기는 P1 게이트에서 확인한다. 보고서 "명세 차이"에 이 사실을 적는다.

### 3.2 스파이크 확인 항목

`qms-spike`(또는 만료 전 `scratchOrg`)에서 확인하고, 결과를 표로 남긴다.

| 번호 | 확인 | 방법 | 결과에 따른 조치 |
| --- | --- | --- | --- |
| S-1 | 정의 파일로 Org 생성 성공, 생성 시간 | `sf org create scratch` | 실패 기능은 정의 파일에서 빼고 대안 기록 |
| S-2 | Translation Workbench 활성, 번역 언어 5종 활성 방법 | Setup 확인, Translation 메타데이터 배포 | 메타데이터로 안 되면 수동 설정 목록 |
| S-3 | Experience Cloud: LWR 사이트 생성·게시, Customer Community Plus 라이선스 수 | `sf community create`, `sf community publish`, Company Information의 라이선스 | 수량에 맞춰 포털 데모 사용자 수 결정 |
| S-4 | Agentforce: Einstein·Agent 설정이 켜지는지, 에이전트 메타데이터 배포 | Setup 확인, 샘플 에이전트 배포 | 안 되면 dev-plan 7.5절 대안 Org |
| S-5 | 사용자 라이선스: Salesforce·Salesforce Platform·Integration 수 | Company Information | 데모 로더 `--max-users`, 통합 사용자 방식 |
| S-6 | Platform Cache 용량 | Setup Platform Cache | 0이면 캐시 미스 경로로만 동작(테스트로 보장) |
| S-7 | 메일 발송 수준 기본값 | Deliverability | 알림(NTF-001) 메일 확인 방법 |
| S-8 | 분해 옵션 이름과 동작 | `sfdx-project.json`에 넣고 retrieve·deploy | 적용 여부 결정 |
| S-9 | 다른 Scratch Org를 SAML IdP로 쓸 수 있는지 | IdP 활성, Connected App | P2 TDO-002 검증 방식 |

### 3.3 데모 로더 단계 적재(`scripts/demo/sf_demo_loader.py`)

구현 완료(2026-11-01).

- `--upto-phase N` 옵션: `docs/docs/30-dev/phase-map.csv`와 아래 "객체 → 소유 WI" 표(`scripts/demo/object-owner.json`)로 페이즈 N까지 소유 객체의 파일만 적재한다. 대응표는 생성 산출물 폴더(`data/demo/salesforce`)가 아니라 로더 옆에 둔다(산출물은 손으로 고치지 않는 규칙).
- 배포 여부는 실행 시작 때 `sf sobject list`로 한 번 확인하고, 배포되지 않은 객체 파일은 건너뛴다.
- 적재 범위 밖 객체를 가리키는 `{{ref:…}}` 토큰은 조회하지 않고 빈 값으로 적재한 뒤 보정 목록에 남긴다. 외부 키 열의 토큰이면 그 행을 다음 실행으로 미룬다.
- 객체에 아직 없는 열(뒤 페이즈 WI가 만드는 필드, 명세 불일치)은 빼고 적재하고 마지막 요약에 파일별로 보여 준다. 외부 키 필드가 없으면 그 파일을 건너뛴다.
- 사용자 생성: 남은 라이선스에 맞춰 Salesforce → Platform 순으로 배정하고, Org 언어로 바뀐 표준 프로필 이름(`표준 사용자` 등)을 찾아 쓴다. `User.EmployeeNo__c`(MDM-001)가 없으면 사용자를 만들지 않는다.
- 고친 결함: 보정 패스에서도 외부 키 토큰이 안 풀리는 행이 목록에 다시 들어가 반복이 끝나지 않던 문제(전체 적재에서는 드러나지 않았음).
- 확인(dry-run): `--upto-phase 1` → 21개 파일(01~16, 17a, 17b), `--upto-phase 2` → P2 파일 추가와 미해결 136건(문서·결재 요청·To-Do의 QMS 대상), `--upto-phase 10`과 옵션 없음 → 전체, 미해결 0건. dev-plan 8절 표와 같다.

| 객체 | 소유 WI | 페이즈 | 데모 파일 |
| --- | --- | --- | --- |
| CMN_Department__c | CMN-00-MDM-001 | P1 | 16, 17b |
| User(EmployeeNo__c 등) | CMN-00-MDM-001 | P1 | 17a |
| CMN_Company__c | CMN-00-MDM-002 | P1 | 01 |
| CMN_Plant__c | CMN-00-MDM-002 | P1 | 03 |
| CMN_Line__c | CMN-00-MDM-002 | P1 | 04 |
| CMN_Operation__c | CMN-00-MDM-002 | P1 | 05 |
| Account(고객·협력사) | CMN-00-MDM-003·005 | P1 | 08, 09 |
| CMN_Vehicle__c | CMN-00-MDM-003 | P1 | 10 |
| CMN_ProductGroup__c | CMN-00-MDM-004 | P1 | 02, 02a |
| CMN_Item__c | CMN-00-MDM-004 | P1 | 11 |
| CMN_ItemPlant__c | CMN-00-MDM-004 | P1 | 12 |
| CMN_ItemVehicle__c | CMN-00-MDM-004 | P1 | 13 |
| CMN_SupplierItem__c | CMN-00-MDM-005 | P1 | 14 |
| CMN_Characteristic__c | CMN-00-MDM-006 | P1 | 15 |
| CMN_CodeGroup__c | CMN-00-MDM-007 | P1 | 06 |
| CMN_Code__c | CMN-00-MDM-007 | P1 | 07, 07a, 07b |
| CMN_Employee__c | CMN-00-INT-002 | P2 | 17, 17c |
| CMN_UserPlantAccess__c | CMN-00-SEC-002 | P2 | 19 |
| CMN_RoleAssignment__c | CMN-00-APV-002 | P2 | 20 |
| CMN_ApprovalTemplate__c | CMN-00-APV-002 | P2 | 21 |
| CMN_ApprovalTemplateStep__c | CMN-00-APV-002 | P2 | 22 |
| CMN_ApprovalRequest__c | CMN-00-APV-001 | P2 | 83 |
| CMN_ApprovalStep__c | CMN-00-APV-001 | P2 | 84 |
| CMN_Document__c | CMN-00-DOC-001 | P2 | 63, 64a |
| CMN_DocumentRevision__c | CMN-00-DOC-001 | P2 | 64 |
| CMN_Todo__c | CMN-00-TDO-001 | P2 | 85 |
| CMN_Delegation__c | CMN-00-APV-004 | P3 | 23 |
| CMN_KpiValue__c | CMN-00-DWH-003 | P3 | 90 |
| QMS_TestItem__c | QMS-02-DVQ-001 | P4 | 24 |
| QMS_TestStandard__c | QMS-02-DVQ-002 | P4 | 25 |
| QMS_TestStandardLine__c | QMS-02-DVQ-002 | P4 | 26 |
| QMS_QualPlan__c | QMS-02-DVQ-003 | P4 | 55 |
| QMS_QualPlanLine__c | QMS-02-DVQ-003 | P4 | 56, 63a |
| QMS_SamplingPlan__c | QMS-03-IQC-001 | P4 | 27 |
| QMS_SamplingPlanRow__c | QMS-03-IQC-001 | P4 | 28 |
| QMS_IqcStandard__c | QMS-03-IQC-001 | P4 | 29 |
| QMS_IqcStandardLine__c | QMS-03-IQC-001 | P4 | 30 |
| QMS_IqcLot__c | QMS-03-IQC-002 | P4 | 48 |
| QMS_IqcResult__c | QMS-03-IQC-002 | P4 | 49 |
| QMS_IqcLevelChange__c | QMS-03-IQC-005 | P4 | 51 |
| QMS_IqcLevelHold__c | QMS-03-IQC-005 | P4 | 52 |
| QMS_PpapElement__c | QMS-03-PPA-001 | P4 | 31 |
| QMS_PpapLevelRule__c | QMS-03-PPA-001 | P4 | 32 |
| QMS_Ppap__c | QMS-03-PPA-002 | P4 | 57 |
| QMS_PpapElementLine__c | QMS-03-PPA-002 | P4 | 58 |
| QMS_PpapSubmission__c | QMS-03-PPA-003 | P4 | 59 |
| Contact(협력사 담당자) | QMS-03-SPP-001 | P4 | 18 |
| QMS_NCR__c | QMS-06-NCR-001 | P5 | 40, 45a |
| QMS_NcrContainment__c | QMS-06-NCR-003 | P5 | 46 |
| QMS_NcrDisposition__c | QMS-06-NCR-003 | P5 | 47 |
| QMS_EightD__c | QMS-05-CLM-001 | P5 | 41 |
| QMS_EightDStep__c | QMS-05-CLM-001 | P5 | 42 |
| QMS_EightDTeamMember__c | QMS-05-CLM-001 | P5 | 43 |
| QMS_EightDAction__c | QMS-05-CLM-001 | P5 | 44 |
| QMS_Claim__c | QMS-05-CLM-007 | P5 | 45, 45b |
| QMS_CustomerDefectMap__c | QMS-05-B2B-001 | P5 | 96 |
| QMS_CustomerPartMap__c | QMS-05-B2B-001 | P5 | 97 |
| QMS_LessonLearned__c | QMS-04-LEL-001 | P5 | 53 |
| QMS_SupplierCoa__c | QMS-03-IQC-006 | P6 | 50 |
| QMS_StabilizationPlan__c | QMS-03-PIS-001 | P6 | 66 |
| QMS_SupplierCertificate__c | QMS-03-SPP-003 | P6 | 81 |
| QMS_EightDSubmission__c | QMS-05-CLM-005 | P6 | 68 |
| QMS_ChangeTypeRule__c | QMS-06-4MC-001 | P6 | 33 |
| QMS_FourMChange__c | QMS-06-4MC-002 | P6 | 60 |
| QMS_FourMItem__c | QMS-06-4MC-002 | P6 | 61 |
| QMS_FourMVerification__c | QMS-06-4MC-002 | P6 | 62 |
| QMS_SupplierFourMRequest__c | QMS-06-4MC-004 | P6 | 65 |
| QMS_LeleCheckpoint__c | QMS-04-LEL-003 | P7 | 54 |
| QMS_SpcPlan__c | QMS-04-SPC-001 | P7 | 91, 92u |
| QMS_SpcLimit__c | QMS-04-SPC-001 | P7 | 92 |
| QMS_SpcAlarm__c | QMS-04-SPC-005 | P7 | 93 |
| QMS_AuditChecklist__c | QMS-06-IAU-001 | P9 | 37 |
| QMS_AuditQuestion__c | QMS-06-IAU-001 | P9 | 38 |
| QMS_AuditGradeRule__c | QMS-06-IAU-001 | P9 | 39 |
| QMS_Audit__c | QMS-06-IAU-002 | P9 | 69, 69a |
| QMS_AuditResultItem__c | QMS-06-IAU-002 | P9 | 70 |
| QMS_AuditFinding__c | QMS-06-IAU-004 | P9 | 71 |
| QMS_CustomerAuditPrepTask__c | QMS-06-CAU-001 | P9 | 72 |
| QMS_Certification__c | QMS-06-CER-001 | P9 | 80 |
| QMS_Gauge__c | QMS-06-GAU-001 | P10 | 73 |
| QMS_Calibration__c | QMS-06-GAU-002 | P10 | 75 |
| QMS_GaugeImpactAnalysis__c | QMS-06-GAU-004 | P10 | 76 |
| QMS_MsaStudy__c | QMS-06-MSA-002 | P10 | 94 |
| QMS_MsaAppraiser__c | QMS-06-MSA-002 | P10 | 95 |
| QMS_TrainingCourse__c | QMS-06-TRN-001 | P10 | 36 |
| QMS_TrainingSession__c | QMS-06-TRN-001 | P10 | 77 |
| QMS_TrainingAttendance__c | QMS-06-TRN-002 | P10 | 78 |
| QMS_QualificationType__c | QMS-06-TRN-003 | P10 | 35 |
| QMS_Qualification__c | QMS-06-TRN-003 | P10 | 79 |
| QMS_LabAnalysisItem__c | QMS-06-LAB-001 | P10 | 34 |
| QMS_LabRequest__c | QMS-06-LAB-001 | P10 | 67 |
| QMS_LabRequestItem__c | QMS-06-LAB-001 | P10 | 74 |
| QMS_LimitSample__c | QMS-06-LMS-001 | P10 | 82 |

소유 WI는 각 Vol. 데이터 모델 표에서 그 객체를 처음 정의한 WI다. 같은 객체에 필드를 더하는 WI(예: User의 LanguageOverride__c는 I18N-001)는 같은 페이즈이거나 앞이라 적재 순서에 영향이 없다.

### 3.4 스파이크 결과(2026-11-01)

정의 파일(dev-plan 5.3절의 처음 안)로 `qms-spike`(myDevHub, Developer, 3일)를 만들어 확인했다. 비교용 Org 3개(Enterprise 에디션, 라이선스 기능 2종)는 확인 후 지웠다.

| 번호 | 결과 | 조치 |
| --- | --- | --- |
| S-1 | 성공, 33초. `language: ko`·`country: KR` 반영(ko_KR, Asia/Seoul), API 68.0 | — |
| S-2 | Translation Workbench 켜짐. Custom Label의 en_US·zh_CN·pl·es·pt_BR 번역이 메타데이터 배포로 저장됨. `enableEndUserLanguages`는 false | 정의 파일에 `enableEndUserLanguages: true` 추가(폴란드어 UI). 번역 언어는 수동 설정 불필요 |
| S-3 | Communities 켜짐. Customer Community Plus 5, Plus Login 5, Partner Community 5. LWR 사이트 `sf community create` 완료(비동기), `sf community publish` 접수 | 포털 데모 사용자는 시나리오 협력사 담당자 5명 + Login 5명까지. D3-1 가정과 맞음 |
| S-4 | Einstein·Agent 플랫폼 켜짐. Agentforce(Default) 3, Einstein Prompt Templates 3,000, Einstein Agent 사용자 201. `sf agent` 명령 사용 가능. `enableEinsteinGptGlobalLangSupport` false | 정의 파일에 Global Lang Support 추가(한·중 응답). 샘플 에이전트 배포는 P3 AI-001에서 |
| S-5 | Salesforce 2(관리자 1 사용), Salesforce Platform 3, Salesforce Integration 1, Cloud Integration User 1. `ForceComPlatform` → Platform +1(수량 `:n` 표기는 생성 거부). Enterprise 에디션은 Salesforce 5지만 Platform·포털 라이선스 0 | Developer 유지 + `ForceComPlatform`. 새 내부 사용자 **최대 5명** → DEV-4 결정(dev-plan 8.4절) |
| S-6 | Org 캐시 1MB 파티션 배포 성공 | 캐시 사용 가능(캐시 미스 경로는 그대로 테스트) |
| S-7 | 메일 발송 수준은 메타데이터(EmailAdministrationSettings)에 없음 | 수동 설정 목록에 남김(P2) |
| S-8 | 분해 옵션: `decomposeCustomLabelsBeta2`, `decomposePermissionSetBeta2`, `decomposeSharingRulesBeta`, `decomposeWorkflowBeta`, `decomposeExternalServiceRegistrationBeta` | ARC-001에서 Custom Label·Permission Set 분해 적용 여부 결정 |
| S-9 | 미확인 | P2 TDO-002 착수 때 확인 |
| 추가 | **ko Org는 표준 프로필 이름이 한국어**(`표준 사용자`, `표준 플랫폼 사용자`). 영어 이름으로 `sf org create user` 하면 실패, 한국어 이름은 성공 | 데모 로더 수정 완료. `CMN_TestDataFactory`는 프로필을 `UserLicense.Name`으로 찾도록 ARC-002에 반영 |
| 추가 | 세션 시간 기본값 TwoHours, 도메인 잠금 true | SEC-004 기준과 같음 |

### 3.5 도구 준비 결과(2026-11-01)

| 항목 | 결과 |
| --- | --- |
| sf CLI | 2.136.8 → 2.156.8 |
| npm 의존성 | 설치(eslint 9.39.5 등). 운영 의존성 취약점 0, 개발 도구 쪽 low·moderate 41건(`npm audit`) |
| husky | `core.hooksPath = .husky/_`, 커밋 시 lint-staged 실행 |
| Code Analyzer | 5.16.0 설치. Java 25 있음(PMD 엔진용) |
| `npm run lint` | 실패(종료 2)였음 → `--no-error-on-unmatched-pattern` 추가. 이 프로젝트는 Aura가 없어 그대로면 항상 실패 |
| `npm run test:unit` | 테스트가 없을 때 실패였음 → 스크립트에 `--passWithNoTests` 추가 |
| `npm run prettier:verify` | 132개 파일 위반이었음(생성 데이터 85, 문서 39, 설정 8) → `.prettierignore`에 `docs/`·`data/`·`**/*.md` 추가, 설정 파일 4개(`package.json`, `manifest/package.xml`, `jest.config.js`, `eslint.config.js`) 포맷 |
| 최종 | lint·test:unit·test:unit --coverage·prettier:verify 모두 종료 코드 0. 샘플 LWC 파일로 ESLint 설정 로드 확인 |

## 4. Scratch Org 준비

- `scratchOrg`(2026-12-01 만료)를 스파이크에 쓰거나 `qms-spike`를 새로 만든다. 스파이크 Org는 끝나면 지운다(`sf org delete scratch`).
- P0 게이트 때 `qms-int`와 `qms-ci`를 처음 만든다(빈 소스).

## 5. 목·대체

해당 없음.

## 6. 데모 데이터

- 적재 없음. 로더 보강 후 `scripts/demo/load_salesforce.sh qms-spike --dry-run --upto-phase 1`로 파일 선택과 순서만 확인한다.

## 7. 게이트

| 번호 | 확인 | 통과 기준 |
| --- | --- | --- |
| G0-1 | 정의 파일 | 확정 정의 파일로 Org 생성 성공. 스파이크 결과표 9항목 기록 |
| G0-2 | 재현 스크립트 | `build-scratch.sh qms-int --no-data`가 1~8단계를 끝까지 수행 |
| G0-3 | CI | 샘플 PR에서 정적 검사·배포 검증 동작. 커버리지 80% 클래스를 넣은 임시 PR이 차단되고 클래스명 표시(ARC-001 AC-2). 임시 브랜치는 폐기 |
| G0-4 | 로더 | `--dry-run --upto-phase 1`이 P1 파일만 고름 |
| G0-5 | 결정 | 8절 결정 기록. Vol.0 W0 26건 승인 |
| G0-6 | 현황표 | DEV-STATUS 원칙 문구·페이즈 열 반영 |

## 8. 선결 결정·명세 보강

| 구분 | 항목 | 이유 | 상태(2026-11-02) |
| --- | --- | --- | --- |
| 결정 | D-1 PMS·QMS 단일 Org | 연계 설계·INT-021 착수 여부 | 대기(P2 INT-001 전까지) |
| 결정 | D-3 Multi-Currency | 켜면 되돌릴 수 없음. 정의 파일에 넣을지가 여기서 정해짐(비용 WI는 P6) | 대기 — 정의 파일에서 뺀 채 진행 |
| 결정 | D-6 Shield(Platform Encryption, Field Audit Trail) | 정의 파일, SEC-003·004 | 대기 — 정의 파일에서 뺀 채 진행 |
| 결정 | API 버전 | 5.7절 | 66.0 유지(운영 릴리즈 확정 전) |
| 결정 | 저장소 공개 여부 | CI 시크릿, 명세 노출 | 대기(현재 공개) |
| 결정 | DEV-2 PoC 경로 | 이 플랜 일정과 PoC 일정이 다르면 착수 순서가 바뀜 | 대기 |
| 결정 | DEV-4 데모 사용자 5명 한도 | dev-plan 8.4절 | **채택: 페이즈별 사용자 선택**(`scripts/demo/phase-users.json`) |
| 결정 | 검토 전 명세 착수 | `/implement-wi` 승인 확인 | **동의**(2026-11-02) |
| 결정 | 이 플랜(페이즈·레인 배정) 승인 | — | 진행 지시로 갈음 |
| 명세 | CR-5 ARC-001 BR-2 문구 | 정의 파일 기능 목록 | **권고안 채택**(TW·Communities 켬, Platform Encryption 뺌). Vol.0 문구 수정 요청 |
| 명세 | CR-7 Mule 디렉터리 이름 | 저장소 구조 | `mule/`(애플리케이션) + `integration/`(계약·목·PoC) 병존으로 해석 |
| 명세 | ARC-001 오픈 이슈 (2) Unlocked Package 전환 시점, (3) DKBMC 사전 보유 자산 디렉터리 | 패키지 디렉터리 구조 | 대기 |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| Agentforce 기능이 정의 파일로 안 켜짐 | 정의 파일에서 빼고 P3 AI-001 전까지 대안 Org 확보(dev-plan 7.5절) |
| 포털 라이선스가 부족 | 시나리오 협력사 담당자만 포털 사용자로 |
| 결정 지연 | P1은 D-3·D-6 없이도 착수 가능(정의 파일에서 빼둠). D-1은 P2 INT-001 전까지, D-3은 P6 비용 WI 전까지 필요 |

## 10. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| 2026-11-02 | `qms-int`(LSPMSQMS), `qms-ci`(myDevHub), `qms-spike` | G0-1 통과(확정 정의 파일 생성·설정 확인), G0-2 통과(`build-scratch.sh qms-int --no-data` 8단계), G0-4 통과(로더 dry-run·빈 Org 실행), G0-6 통과(DEV-STATUS 227행). G0-3 일부: 커버리지 검사기·Code Analyzer 차단을 로컬에서 확인 | G0-3 GitHub Actions 실행(push·브랜치 보호·`SF_AUTH_URL_CI` 등록 후, T0-7). G0-5 일부: D-1·D-3·D-6·DEV-1~3 대기. ARC-001 AC-1(P1 게이트)·AC-3(외부 트랙) |
