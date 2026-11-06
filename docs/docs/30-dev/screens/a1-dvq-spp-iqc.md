# A1 개발 품질·부품/협력사 품질 화면 인벤토리

화면 우선 플랜 4.1 1단계 산출물이다. 묶음 A1 WI 30개(QMS-02 10개, QMS-03 20개)의 "화면/UX"·"데이터 모델"·"권한" 절을 읽고 화면을 빠짐없이 적었다. 화면 유형과 공통 부품은 [화면 전략](../../10-workitems/screen-strategy.md)을 따른다. 기준일 2026-11-06.

- 묶음 브랜치: `ui/a1-dvq-spp-iqc`
- 검토 Org 준비: `scripts/org/build-scratch.sh qms-int --reuse --bundle A1 --review`
- 진행 상태: `screen-map.csv`의 `화면상태`(대기 → 화면 개발 중 → 화면 완료 → 검토 중 → 승인 / 재작업)
- 범위: 화면 대상 WI 27개, 화면 60개. 화면이 없는 WI는 3개다. QMS-02-DVQ-005(결재·연계 서비스, B단계), QMS-03-IQC-007(Snowflake 적재, 외부 트랙), QMS-03-IQC-008(이상 성적서 탐지, B단계 P13). DVQ-005의 상신·취소 버튼은 DVQ-003 계획 화면에 둔다.
- 약칭: 품질 업무 = SL QMS 품질 업무, 현장 = SL QMS 현장, 허브 02·허브 03 = 품질 업무 → 메뉴 허브 → 02 개발 품질·03 부품/협력사 품질 그룹, 포털 = 협력사 포털 `/supplier`.
- 진입 타일: 배포된 기능 타일 6개(`QMS_02_DVQ`, `QMS_03_SPP`·`IQC`·`PWT`·`PPA`·`PIS`, 지금은 TargetType NONE)에 대상을 넣는다. 그 밖의 타일·앱 페이지 이름은 제안이다(10절 5단계).
- 페르소나: E1101 품질팀장, E1102 품질 엔지니어, E1104 수입검사원(모바일), E1112 SQE, E1901 관리자(품질경영팀·시험 담당·개발 엔지니어 역할 대리), 포털 = 협력사 포털 사용자(알파광학 품질 담당 `CT-V10001-01`).
- 명세에 없는 이름에는 `(제안)`을 붙였다.

## 1. 화면 목록

유형: T1 업무 레코드, T2 그리드, T3 현장 입력, T4 체크리스트, T5 대시보드·위젯, T6 기준정보·설정, T7 포털, T8 메뉴 허브·앱 페이지·작업함. 상태는 모두 대기다.

### 1.1 QMS-02 개발 품질(DVQ) — 18개

| 화면 ID | 화면 | 유형 | 객체 | 컴포넌트·공통 부품 | 진입 경로 | 페르소나 | 모바일 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| QMS-02-DVQ-001-S01 | 시험 항목 목록·레코드 | T6 | `QMS_TestItem__c` | 표준 리스트뷰(인라인 편집, 카테고리별)·레코드 페이지, 필드 이력 | 허브 02 › 시험 항목 | E1901 편집, E1102 조회 | 카드(컴팩트) | 대기 |
| QMS-02-DVQ-001-S02 | 시험 항목 CSV 일괄 등록 | T6 | `QMS_TestItem__c` | `qmsTestItemImport`(행별 오류 표시) | 허브 02 › 인정시험 설정(앱 페이지, 제안) | E1901 | 데스크톱 전용 | 대기 |
| QMS-02-DVQ-002-S01 | 시험 기준 목록·레코드 | T6 | `QMS_TestStandard__c`, `QMS_TestStandardLine__c` | 표준 리스트뷰(Status·TriggerType별)·레코드 페이지, 라인 관련 목록 | 허브 02 › 시험 기준 | E1901, E1102 조회 | 카드 | 대기 |
| QMS-02-DVQ-002-S02 | 시험 기준 편집기(라이브러리 검색 + 세트 라인) | T6 + T2 | `QMS_TestStandardLine__c` | `qmsTestStandardEditor` = 라이브러리 패널 + `cmnEditableGrid` gridKey `QMS_TestStandardLine`(제안), Provider `QMS_TestStandardLineGridProvider`(제안) | 시험 기준 레코드 → 첫 탭 | E1901 | 읽기 전용 카드 | 대기 |
| QMS-02-DVQ-003-S01 | 인정시험 계획 레코드(PART·PRODUCT) | T1 | `QMS_QualPlan__c` | UX-004 생성기 페이지(헤더 7, `cmnStatusPath`, 현재 단계·상세·관련·이력, `cmnDecisionRail`), UX-005 규칙. 목록 전체·내 것·진행 중·기한 경과 | 품질 업무 → 인정시험 탭, 허브 02 › 인정시험 계획 | E1102, E1101 결재 | 카드, 레일은 본문 아래 | 대기 |
| QMS-02-DVQ-003-S02 | 시험 라인 레코드(시료 결과 목록) | T1 | `QMS_QualPlanLine__c`, `QMS_QualSampleResult__c` | UX-004 생성기 페이지(라인 상태 진행바, 레일 코멘트·문서), 시료 결과 읽기 관련 목록 | 계획 → 라인 행, 시험실 대기열 | E1102, E1901(시험 담당) | 카드 | 대기 |
| QMS-02-DVQ-004-S01 | 계획 생성 마법사(기본정보 → 기준 세트 → 라인 미리보기) | T1 | `QMS_QualPlan__c`, `QMS_QualPlanLine__c` | `qmsQualPlanWizard`(새로 만들기 오버라이드) | 인정시험 탭 → 새로 만들기 | E1102 | 단계별 1열 | 대기 |
| QMS-02-DVQ-004-S02 | 라인 편집 그리드(면제·일정 막대·붙여넣기) | T2 | `QMS_QualPlanLine__c` | `cmnEditableGrid` gridKey `QMS_QualPlanLine`, Provider `QMS_QualPlanLineGridProvider`, 편집 규칙 `QMS_QualPlanLineGrid` | 계획 → 현재 단계 탭(DRAFT) | E1102 | 읽기 전용 카드(BR-7) | 대기 |
| QMS-02-DVQ-004-S03 | 라이브러리에서 라인 추가 | T2 보조 | `QMS_TestItem__c` | `qmsQualPlanLibraryPicker`(모달) → `CMN_GridRefresh__c` 발행 | 계획 → 그리드 위 버튼 | E1102 | 데스크톱 전용 | 대기 |
| QMS-02-DVQ-004-S04 | 이전 계획 복사 | T1 액션 | `QMS_QualPlan__c` | `qmsQualPlanCopy`(레코드 액션) | 계획 → 헤더 액션 | E1102 | 대화상자 | 대기 |
| QMS-02-DVQ-006-S01 | 시험실 작업 대기열(접수·착수 일괄) | T8 | `QMS_QualPlanLine__c` | `qmsLabQueue`(내 부서 REQUESTED·RECEIVED·IN_PROGRESS, PlannedStart 순, 지연 표시) | 품질 업무·현장 → 시험실 작업(앱 페이지, 제안) | E1901(시험 담당) | 1열 목록 | 대기 |
| QMS-02-DVQ-006-S02 | 시험 의뢰(PLANNED 라인 다중 선택) | T1 액션 | `QMS_QualPlanLine__c` | `qmsQualLineRequest`(제안, 계획 레코드 액션) | 계획 → 헤더 "시험 의뢰" | E1102 | 대화상자 | 대기 |
| QMS-02-DVQ-007-S01 | 시험 결과 입력(순차·표, NG 사진, 성적서) | T3 | `QMS_QualPlanLine__c`, `QMS_QualSampleResult__c` | 진입점 `qmsQualResultEntry` → `cmnFieldEntryShell`, Provider `QMS_QualResultEntryProvider`(`CMN_FieldEntryProvider__mdt` 등록). REPORT 항목은 `cmnDocumentPanel` | 라인 → "결과 입력", 대기열, `CMN_FieldEntry?c__recordId=` | E1901(시험 담당), E1102(외부 기관 라인) | 순차 모드 | 대기 |
| QMS-02-DVQ-008-S01 | 종합 판정(유효 결과 요약·제안 판정·조건) | T1 | `QMS_QualPlan__c`, `QMS_QualPlanLine__c` | `qmsQualJudgment`(현재 단계 탭) + 레일 결재 패널 | 계획(IN_TEST·JUDGMENT_APPROVAL) → 현재 단계 탭 | E1102 상신, E1101 결재 | 1열 | 대기 |
| QMS-02-DVQ-009-S01 | DVP&R PDF(머리말·본문·면제·맺음말) | T1 문서 출력 | `QMS_QualPlan__c`, `QMS_ReportFormat__mdt` | Visualforce `QMS_DvprPdf`(renderAs pdf) | 계획 → "중간 보고서" | E1102 | 해당 없음 | 대기 |
| QMS-02-DVQ-009-S02 | 보고서 버튼(재생성·Excel·중간 보고서) | T1 액션 | `QMS_QualPlan__c` | `qmsDvprExport`(제안), SheetJS 정적 리소스 | 계획 → 헤더 액션 | E1102 | 데스크톱 전용 | 대기 |
| QMS-02-DVQ-010-S01 | 협력사 시험 성적서 제출(시료 입력·즉시 합불·업로드) | T7 | `QMS_SupplierTestSubmission__c` | `qmsSupplierTestSubmit`, `qmsPortalDocUpload`(TEST_REPORT), 합불 모듈 `cmnFieldEntryJudge` | 포털 → 할 일 / 시험 성적서 | 포털 사용자 | 포털 반응형 | 대기 |
| QMS-02-DVQ-010-S02 | SQE 성적서 검토(승인·반려·차수 이력) | T1 | `QMS_SupplierTestSubmission__c` | 레코드 페이지 + `cmnSubmissionReview`(R-4 공용) | 시험 라인 → 관련, 할 일 | E1112 | 카드 | 대기 |

### 1.2 QMS-03 협력사 포털(SPP) — 8개

| 화면 ID | 화면 | 유형 | 객체 | 컴포넌트·공통 부품 | 진입 경로 | 페르소나 | 모바일 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| QMS-03-SPP-001-S01 | 포털 사이트 골격·로그인·언어 선택 | T7 | — | LWR 사이트 "SL Supplier Quality"(Build Your Own), 로그인·비밀번호 재설정(게스트), 내비게이션 메뉴 | `/supplier` | 포털 사용자 | 포털 반응형 | 대기 |
| QMS-03-SPP-001-S02 | 협력사 포털 사용자 관리 | T6 | `Contact`, `Account` | `qmsSupplierUserAdmin`(협력사 Account 레코드 페이지) | 허브 › 기준정보 → 고객·협력사 → 협력사 | E1112 | 데스크톱 전용 | 대기 |
| QMS-03-SPP-002-S01 | 포털 홈(내 할 일·최근 알림·공지) | T7 + T8 | `CMN_Todo__c`, `QMS_PortalNotice__c` | `qmsPortalHome`(DTO `QMS_PortalHomeDTO`(제안)) | 포털 → 홈 | 포털 사용자 | 포털 반응형 | 대기 |
| QMS-03-SPP-002-S02 | 품번 목록(PPAP 상태·검사 수준·안정화·합격률) | T7 | `CMN_SupplierItem__c`, `CMN_KpiValue__c` | `qmsPortalItemList` | 포털 → 품번 | 포털 사용자 | 포털 반응형 | 대기 |
| QMS-03-SPP-002-S03 | 포털 문서 업로드(공용 부품) | T7 부품 | `CMN_Document__c` | `qmsPortalDocUpload`(parentId·docClass·maxFiles, 50MB) | 각 제출 화면 안 | 포털 사용자 | 포털 반응형 | 대기 |
| QMS-03-SPP-002-S04 | 포털 공지 관리 | T6 | `QMS_PortalNotice__c` | 표준 리스트뷰(게시 중·예약)·레코드 페이지 | 허브 03 › 포털 공지 | E1112 | 카드 | 대기 |
| QMS-03-SPP-003-S01 | 협력사 인증서 등록·제출 | T7 | `QMS_SupplierCertificate__c` | `qmsSupplierCertForm`, `qmsPortalDocUpload`(CERT_SUPPLIER) | 포털 → 인증서 | 포털 사용자 | 포털 반응형 | 대기 |
| QMS-03-SPP-003-S02 | SQE 인증서 확인(VERIFIED·REJECTED) | T1 | `QMS_SupplierCertificate__c`, `Account` | 레코드 페이지 + `cmnSubmissionReview`, 협력사 Account 관련 목록 | 할 일, 협력사 → 관련 | E1112 | 카드 | 대기 |

### 1.3 QMS-03 수입검사(IQC) — 14개

| 화면 ID | 화면 | 유형 | 객체 | 컴포넌트·공통 부품 | 진입 경로 | 페르소나 | 모바일 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| QMS-03-IQC-001-S01 | 샘플링 계획·행 | T6 | `QMS_SamplingPlan__c`, `QMS_SamplingPlanRow__c` | 표준 레코드 페이지 + 행 관련 목록 인라인 편집 | 허브 03 › 수입검사 기준 | E1112 | 카드 | 대기 |
| QMS-03-IQC-001-S02 | 기준서 편집기(특성 선택·공통 점검·미리보기) | T6 + T2 | `QMS_IqcStandard__c`, `QMS_IqcStandardLine__c` | `qmsIqcStandardEditor`(특성 선택·미리보기) + `cmnEditableGrid` gridKey `QMS_IqcStandardLine`(제안), Provider `QMS_IqcStandardLineGridProvider`(제안) | 기준서 레코드 → 첫 탭 | E1112 | 읽기 전용 카드 | 대기 |
| QMS-03-IQC-001-S03 | 기준서 일괄 등록 | T6 | `QMS_IqcStandard__c` | `qmsIqcStandardImport` | 품질 업무 → 수입검사 설정(앱 페이지) | E1112 | 데스크톱 전용 | 대기 |
| QMS-03-IQC-002-S01 | 검사 로트 레코드(결과 라인·수준·성적서 상태) | T1 | `QMS_IqcLot__c`, `QMS_IqcResult__c` | UX-004 생성기 페이지(헤더 기한 = DueAt), 결과 관련 목록. 목록 대기·기한 경과·불합격 | 허브 03 › 검사 로트 | E1104, E1112 | 카드 | 대기 |
| QMS-03-IQC-003-S01 | 수입검사 대기열(필터·바코드·착수) | T3 대기열 | `QMS_IqcLot__c` | `qmsIqcWorkbench`(DTO `QMS_IqcQueueDTO`(제안)) | 품질 업무 → 수입검사(앱 페이지), 현장 → 검사 입력 | E1104 | 1열 목록 + 스캔 | 대기 |
| QMS-03-IQC-003-S02 | 검사 결과 입력(항목 카드·즉시 합불·사진·측정기 스캔) | T3 | `QMS_IqcLot__c`, `QMS_IqcResult__c` | `cmnFieldEntryShell` + Provider `QMS_IqcInspectionProvider`(제안), 진입점 `qmsIqcInspection` | 대기열 → 착수, 로트 → 액션 | E1104 | 순차 모드(태블릿 우선) | 대기 |
| QMS-03-IQC-003-S03 | 로트 판정 확정(불량 유형·불량 시료 수·사유, 예외 합격, 재개) | T3 보조 | `QMS_IqcLot__c` | `qmsIqcDecisionDialog`(제안), `cmnCodePicker`(DEFECT_TYPE) | 셸 "판정 확정" 다음, 로트 액션 | E1104, E1112(SQ_MANAGER) | 대화상자 | 대기 |
| QMS-03-IQC-004-S01 | 포털 수입검사 결과(최근 6개월) | T7 | `QMS_IqcLot__c` | `qmsPortalIqcResults`(필드를 고른 DTO) | 포털 → 수입검사 결과 | 포털 사용자 | 포털 반응형 | 대기 |
| QMS-03-IQC-005-S01 | 검사 수준 패널(기본·유효 수준, Hold, 최근 20로트 띠) | T1 패널 | `CMN_SupplierItem__c`, `QMS_IqcLevelHold__c`, `QMS_IqcLevelChange__c` | `qmsIqcLevelPanel` | 협력사 품번 레코드, 로트 → 첫 탭 상단 | E1112, E1101 | 1열 | 대기 |
| QMS-03-IQC-005-S02 | 수준 변경 이력·Hold 목록 | T6 | `QMS_IqcLevelChange__c`, `QMS_IqcLevelHold__c` | 표준 리스트뷰(활성 Hold·최근 변경)·레코드 페이지 | 허브 03 › 검사 수준 | E1112 | 카드 | 대기 |
| QMS-03-IQC-006-S01 | 포털 출하 성적서 입력(CoaCheck 항목·세로 붙여넣기) | T7 | `QMS_SupplierCoa__c` | `qmsSupplierCoaForm`, `cmnFieldEntryJudge`, `qmsPortalDocUpload`(SUPPLIER_COA) | 포털 → 성적서 | 포털 사용자 | 포털 반응형 | 대기 |
| QMS-03-IQC-006-S02 | 포털 성적서 CSV 일괄 등록 | T7 | `QMS_SupplierCoa__c` | `qmsSupplierCoaImport` | 포털 → 성적서 → CSV | 포털 사용자 | 데스크톱 전용 | 대기 |
| QMS-03-IQC-006-S03 | 사내 성적서 목록·레코드(출하 보류 대기열) | T1 | `QMS_SupplierCoa__c` | 표준 레코드 페이지 + `cmnStatusPath`. 목록 OOS_HOLD·미매칭 | 허브 03 › 협력사 성적서 | E1112, E1104 | 카드 | 대기 |
| QMS-03-IQC-006-S04 | 로트 성적서 매칭(후보·요청·면제) | T1 패널 | `QMS_IqcLot__c`, `QMS_SupplierCoa__c` | `qmsIqcCoaMatch`(제안) | 로트 → 첫 탭 | E1104, E1112 | 1열 | 대기 |

### 1.4 QMS-03 보증시험(PWT)·Re-PPAP(PPA)·초기안정화(PIS) — 20개

| 화면 ID | 화면 | 유형 | 객체 | 컴포넌트·공통 부품 | 진입 경로 | 페르소나 | 모바일 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| QMS-03-PWT-001-S01 | 보증시험 일정 목록·레코드 | T6 | `QMS_PeriodicTestSchedule__c` | 표준 리스트뷰(ACTIVE·기한 임박)·레코드 페이지 | 허브 03 › 보증시험 일정 | E1112 | 카드 | 대기 |
| QMS-03-PWT-001-S02 | 일정 일괄 등록·연간 캘린더 | T6 + T5 | `QMS_PeriodicTestSchedule__c`, `CMN_SupplierItem__c` | `qmsPeriodicTestSetup` | 허브 03 › 보증시험 등록 | E1112 | 데스크톱 전용 | 대기 |
| QMS-03-PWT-002-S01 | 준수 현황 보드(12개월 준수율·지연) | T5 | `QMS_PeriodicTestSchedule__c`, `QMS_QualPlan__c` | `qmsPeriodicTestBoard` | 허브 03 › 보증시험 현황 | E1112, E1101 | 1열 | 대기 |
| QMS-03-PWT-002-S02 | 감사 증빙(최근 3회 계획·판정·DVP&R) | T1 패널 | `QMS_PeriodicTestSchedule__c`, `CMN_Document__c` | `qmsPeriodicTestEvidence` | 일정 레코드 페이지 | E1112 | 1열 | 대기 |
| QMS-03-PPA-001-S01 | 요소 마스터·레벨 매트릭스(S/R/C/N) | T6 | `QMS_PpapElement__c` | 명세 `qmsPpapMatrixEditor` → 요소 세트별 리스트뷰 인라인 편집(8절) | 허브 03 › PPAP 설정 | E1901 | 카드 | 대기 |
| QMS-03-PPA-001-S02 | 레벨 규칙·규칙 시뮬레이션 | T6 | `QMS_PpapLevelRule__c` | 리스트뷰·레코드 페이지, `qmsPpapRuleSimulator`(제안) | 허브 03 › PPAP 설정 | E1901, E1112 | 카드 | 대기 |
| QMS-03-PPA-002-S01 | PPAP 레코드(요소 라인·진척·원천) | T1 | `QMS_Ppap__c`, `QMS_PpapElementLine__c` | UX-004 생성기 페이지, 요소 라인 관련 목록 | 허브 03 › PPAP, 협력사 품번 → 관련 | E1112, E1101 | 카드, 레일은 본문 아래 | 대기 |
| QMS-03-PPA-002-S02 | PPAP 요구 생성(트리거·기한 입력) | T1 액션 | `CMN_SupplierItem__c`, `QMS_Ppap__c` | `qmsPpapCreateAction`(제안) | 협력사 품번 → "PPAP 요구" | E1112 | 대화상자 | 대기 |
| QMS-03-PPA-003-S01 | 포털 PPAP 제출(요소별 입력·자동 점검) | T7 | `QMS_PpapSubmission__c`, `QMS_PpapElementLine__c` | `qmsSupplierPpapSubmit`, `qmsPortalDocUpload`(요소 DocClass) | 포털 → PPAP | 포털 사용자 | 포털 반응형(표 입력은 데스크톱) | 대기 |
| QMS-03-PPA-003-S02 | SQE 요소별 검토(파일·자동 점검·공정능력·치수·해시 경고) | T1 | `QMS_Ppap__c`, `QMS_PpapElementLine__c`, `QMS_PpapSubmission__c` | `qmsPpapReview`(첫 탭) + `cmnSubmissionReview`(차수 이력) | PPAP(SUBMITTED·IN_REVIEW) → 첫 탭 | E1112 | 1열(요소 선택) | 대기 |
| QMS-03-PPA-004-S01 | PPAP 판정·상신(APPROVED·INTERIM·REJECTED) | T1 | `QMS_Ppap__c` | `qmsPpapDecision` + 레일 결재 패널 | PPAP(검토 완료) → 첫 탭 | E1112 상신, E1101 결재 | 1열 | 대기 |
| QMS-03-PPA-004-S02 | 승인 통보서 PDF | T1 문서 출력 | `QMS_Ppap__c` | Visualforce `QMS_PpapNoticePdf` | PPAP → 문서 패널 미리보기 | E1112 | 해당 없음 | 대기 |
| QMS-03-PIS-001-S01 | 초기안정화 계획 레코드(목표·강화 조치·실적) | T1 | `QMS_StabilizationPlan__c` | UX-004 생성기 페이지 | 허브 03 › 초기안정화, PPAP → 관련 | E1112, E1101 | 카드, 레일은 본문 아래 | 대기 |
| QMS-03-PIS-001-S02 | 포털 초기안정화 조회(목표·진행) | T7 | `QMS_StabilizationPlan__c` | `qmsPortalStabilization` | 포털 → 초기안정화 | 포털 사용자 | 포털 반응형 | 대기 |
| QMS-03-PIS-002-S01 | 안정화 모니터(경과·로트·PPM·협력사 보고) | T5(T1 안) | `QMS_StabilizationPlan__c`, `QMS_StabilizationReport__c` | `qmsStabilizationMonitor`(DWH-004 쿼리, A1은 표) | 계획 → 첫 탭 | E1112 | 1열 | 대기 |
| QMS-03-PIS-002-S02 | 안정화 목록(공장·협력사별 RAG) | T5 | `QMS_StabilizationPlan__c` | `qmsStabilizationList` | 허브 03 › 초기안정화 | E1112, E1101 | 1열 | 대기 |
| QMS-03-PIS-002-S03 | 포털 강화 검사 보고 입력 | T7 | `QMS_StabilizationReport__c` | `qmsSupplierStabReport`, 포털용 코드 선택 `qmsPortalCodePicker`(제안) | 포털 → 할 일 / 초기안정화 | 포털 사용자 | 포털 반응형 | 대기 |
| QMS-03-PIS-002-S04 | SQE 보고 확인 | T1 | `QMS_StabilizationReport__c` | 레코드 페이지 + `cmnSubmissionReview` | 계획 → 관련, 할 일 | E1112 | 카드 | 대기 |
| QMS-03-PIS-003-S01 | 해제 판정·상신(조건별 충족, 조기 해제) | T1 | `QMS_StabilizationPlan__c` | `qmsStabilizationRelease` + 레일 결재 패널 | 계획(EXIT_REVIEW) → 첫 탭 | E1112 상신, E1101 결재 | 1열 | 대기 |
| QMS-03-PIS-003-S02 | 연장·취소 | T1 액션 | `QMS_StabilizationPlan__c` | `qmsStabilizationExtend`(제안) | 계획 → 헤더 액션 | E1112 | 대화상자 | 대기 |

### 1.5 `screen-map.csv` 화면유형 확정(자동 분류와 다른 것만)

| WI | 자동 분류 | 확정 | WI | 자동 분류 | 확정 |
| --- | --- | --- | --- | --- | --- |
| DVQ-002 | T6 | T6 + T2 | IQC-006 | T7 | T7 + T1 |
| DVQ-006 | T1 | T8 + T1 | PWT-001 | T2 | T6 + T5 |
| DVQ-010 | T7 | T7 + T1 | PWT-002 | T1 | T5 + T1 |
| SPP-001 | T7 | T7 + T6 | PPA-001 | T2 + T6 | T6 |
| SPP-003 | T1 | T7 + T1 | PPA-002 | T1 + T2 | T1 |
| IQC-001 | T6 | T6 + T2 | PPA-003 | T7 | T7 + T1 |
| IQC-004 | T1 | T7 | PIS-001 | T1 + T2 | T1 + T7 |
| IQC-005 | T1 | T1(패널) + T6 | PIS-002 | T5 | T5 + T7 + T1 |

## 2. 업무 동작 자리 구현(A단계)

- 본문은 `CMN_Prototype.notYetAvailable()`만 부른다. 화면 컨트롤러는 아래 서비스를 부른다.
- 결재 컴포넌트는 결재선 표시·편집까지 실제다. 상신 버튼은 결재 유형(QMS_QUAL_PLAN, QMS_QUAL_JUDGMENT, QMS_PPAP_APPROVE, QMS_IQC_SKIP_APPROVE, QMS_STAB_RELEASE, QMS_STAB_EXTEND) 등록 전까지 비활성 사유를 보인다.
- 표준 저장(레코드 편집, 그리드 저장, 제출 레코드 DRAFT 저장, 문서 업로드)은 실제로 동작한다. 셸 중간 저장(`save(isFinal=false)`)은 값만 저장하고 서버 판정 계산은 하지 않는다.

| 화면 ID | 버튼·동작 | 서비스 메서드(명세 시그니처, 없으면 제안) | A단계 동작 |
| --- | --- | --- | --- |
| QMS-02-DVQ-001-S02 | 가져오기(upsert) | `QMS_TestItemService.importCsv(String csv)`(제안) | CSV 형식 미리보기는 실제, 반영은 안내 |
| QMS-02-DVQ-002-S02 | 새 버전 만들기 / 활성화 | `QMS_TestStandardService.newVersion(Id)`·`activate(Id)`(제안) | 안내 |
| QMS-02-DVQ-003-S01 | 계획 상신 / 취소 | `QMS_QualPlanService.submitPlan(Id planId, String comment)` / `cancel(Id planId, String reason)` | 안내(사유 입력 대화상자까지 완성) |
| QMS-02-DVQ-003-S02 | 일정 변경 / 재시험 생성 / 재개 | `QMS_QualPlanService.reschedule(Id lineId, Date start, Date end, String reason)`(제안), `QMS_QualResultService.createRetest(Id lineId)`·`reopen(Id lineId, String reason)`(제안) | 안내 |
| QMS-02-DVQ-004-S01 | 저장(DRAFT 계획 생성) | `QMS_QualPlanService.createFromSource(QMS_QualPlanRequest req)` | 안내. 2단계 기준 세트는 ACTIVE·Scope·TriggerType 단순 조회 |
| QMS-02-DVQ-004-S03 | 라인 추가 | `QMS_QualPlanLineService.addFromLibrary(Id planId, List<Id> testItemIds)`(제안) | 안내 |
| QMS-02-DVQ-004-S04 | 계획 복사 | `QMS_QualPlanService.copyPlan(Id sourcePlanId, Date targetDate)`(제안) | 안내 |
| QMS-02-DVQ-006-S02 | 시험 의뢰 | `QMS_QualLineService.request(Set<Id> lineIds)`(제안) | 안내 |
| QMS-02-DVQ-006-S01 | 접수 / 착수(일괄) | `QMS_QualLineService.receive(Set<Id> lineIds, Id testerId, Date receivedDate)`·`start(Set<Id> lineIds, Date actualStart)`(제안) | 안내 |
| QMS-02-DVQ-007-S01 | 판정 확정(DONE·불합격 후속) | `QMS_QualResultEntryProvider.save(Id recordId, List<CMN_FieldEntry.Value> values, Boolean isFinal)`의 isFinal=true 분기, `QMS_NcrGateway.requestFromQualification(Id lineId)` | 안내. isFinal=false는 시료 값 저장 실제 |
| QMS-02-DVQ-008-S01 | 판정 상신 | `QMS_QualPlanService.submitJudgment(Id planId, String finalResult, String condition, String comment)`(제안) | 안내. 제안 판정 칸은 "—" |
| QMS-02-DVQ-009-S02 | 보고서 재생성 | `QMS_DvprReportService.regenerate(Id planId, String language)`(제안) | 안내. Excel·중간 보고서는 11절 A1-10 |
| QMS-02-DVQ-010-S01 | 제출 | `QMS_SupplierTestSubmissionService.submit(Id submissionId)`(제안) | 안내 |
| QMS-02-DVQ-010-S02 | 승인 / 반려 | `QMS_SupplierTestSubmissionService.accept(Id submissionId, String result)`·`returnSubmission(Id submissionId, String comment)`(제안) | 안내 |
| QMS-03-SPP-001-S02 | 활성화 / 비활성화 / 비밀번호 재설정 메일 | `QMS_SupplierPortalUserService.activate(Id contactId, ...)`·`deactivate(Id contactId)`·`resetPassword(Id contactId)`(제안) | 안내. 검토 사용자는 스크립트로 생성 |
| QMS-03-SPP-003-S01 | 제출 | `QMS_SupplierCertificateService.submit(Id certId)`(제안) | 안내 |
| QMS-03-SPP-003-S02 | 확인 / 반려 | `QMS_SupplierCertificateService.verify(Id certId)`·`reject(Id certId, String comment)`(제안) | 안내 |
| QMS-03-IQC-001-S02 | 새 버전 / 활성화 / 미리보기 | `QMS_IqcStandardService.newVersion(Id)`·`activate(Id)`(제안), `QMS_SamplingService.determine(Id planId, Decimal lotQty, String level)` | 안내. 특성 선택 라인 추가는 실제(표준 생성) |
| QMS-03-IQC-001-S03 | 가져오기 | `QMS_IqcStandardService.importCsv(String csv)`(제안) | 안내 |
| QMS-03-IQC-003-S01 | 착수 / 인계 | `QMS_IqcLotService.start(Id lotId)`·`takeOver(Id lotId)`(제안) | 안내. 바코드 찾기는 실제 조회 |
| QMS-03-IQC-003-S02 | 판정 확정 | `QMS_IqcInspectionProvider.save(..., isFinal=true)`(제안 클래스) | 안내. isFinal=false는 `SampleValuesJson__c` 저장 실제 |
| QMS-03-IQC-003-S03 | 판정 확정 / 예외 합격 / 재개 | `QMS_IqcLotService.decide(Id lotId, String decision, Id defectTypeId, String reason)`, `approveException(Id lotId, String reason)`·`reopen(Id lotId, String reason)`(제안) | 안내 |
| QMS-03-IQC-005-S01 | 수동 변경 / 수동 Hold / 완화 확인 / 무검사 상신 | `QMS_IqcLevelService.changeLevel(Id, String level, String reason)`(제안), `addHold(Id supplierItemId, String holdType, String minLevel, Boolean full, Id sourceId, String sourceNo)`, `confirmReduced(Id)`·`submitSkip(Id)`(제안) | 안내 |
| QMS-03-IQC-006-S01 | 제출 / VOID | `QMS_SupplierCoaService.submit(Id coaId)`·`voidCoa(Id coaId, String reason)`(제안) | 안내 |
| QMS-03-IQC-006-S02 | 업로드 | `QMS_SupplierCoaService.importCsv(String csv)`(제안) | 안내 |
| QMS-03-IQC-006-S04 | 수동 연결 / 성적서 요청 / 면제 | `QMS_SupplierCoaService.matchManually(Id coaId, Id lotId)`·`requestCoa(Id lotId)`·`waive(Id lotId, String reason)`(제안) | 안내 |
| QMS-03-PWT-001-S02 | 일괄 생성 | `QMS_PeriodicTestService.createSchedules(List<Id> supplierItemIds, Id standardId, String frequency, Date firstDue, Integer leadDays)`(제안) | 안내 |
| QMS-03-PPA-001-S02 | 규칙 시뮬레이션 | `QMS_PpapRuleService.resolve(scope, trigger, changeTypes, itemId, customerGroup)` | 안내 |
| QMS-03-PPA-002-S01 | 요구 / 취소 | `QMS_PpapService.request(Id ppapId)` / `cancel(Id ppapId, String reason)` | 안내 |
| QMS-03-PPA-002-S02 | PPAP 요구 생성 | `QMS_PpapService.createFromSource(QMS_PpapRequest req)` | 안내 |
| QMS-03-PPA-003-S01 | 자동 점검 / 제출 | `QMS_PpapSubmissionService.autoCheck(Id)`·`submit(Id submissionId)`(제안) | 안내. 표 입력·CSV 읽기는 실제 |
| QMS-03-PPA-003-S02 | 요소 판정 저장 / 검토 완료 | `QMS_PpapReviewService.saveElementReviews(Id ppapId, List<...>)`·`completeReview(Id submissionId)`(제안) | 안내 |
| QMS-03-PPA-004-S01 | 판정 상신 | `QMS_PpapService.submitDecision(Id ppapId, String result, Date interimExpiry, String conditions, String comment)`(제안) | 안내 |
| QMS-03-PIS-001-S01 | 확정 / 취소 / 계획 변경 | `QMS_StabilizationService.activate(Id planId)` / `cancel(Id planId, String reason)`, `changePlan(Id planId, String reason)`(제안) | 안내 |
| QMS-03-PIS-002-S03 | 제출 | `QMS_StabilizationReportService.submit(Id reportId)`(제안) | 안내 |
| QMS-03-PIS-002-S04 | 확인 / 반려 | `QMS_StabilizationReportService.confirm(Id)`·`returnReport(Id, String comment)`(제안) | 안내 |
| QMS-03-PIS-003-S01 | 해제 상신 / 조기 해제 | `QMS_StabilizationService.submitRelease(Id planId, Boolean early, String comment)`(제안) | 안내 |
| QMS-03-PIS-003-S02 | 연장 / 취소 | `QMS_StabilizationService.extend(Id planId, Integer addDays, Integer addLots, String reason)`(제안) / `cancel(Id planId, String reason)` | 안내 |

B단계 완료 조건: `python3 scripts/ci/check-prototype-stubs.py --menu QMS-02`와 `--menu QMS-03` 참조 0건.

## 3. Snowflake·AI 목 응답

| 화면 ID | 조회 키·응답 | 목 원본 | 예시 데이터 표시 |
| --- | --- | --- | --- |
| QMS-03-PIS-002-S01 | QMS_STAB_DAILY_SERIES(planId → date, lots, rejectLots, receivedQty, defectQty, ppm, specialDefects) | 없음 → `data/demo/mocks/dwh/QMS_STAB_DAILY_SERIES/ok.json`·`empty.json` 새로 작성(S3-STB, `spec-snowflake-display.md` 열 정의) | `cmnPrototypeBadge` |
| QMS-03-PIS-002-S01 | QMS_STAB_LOT_LIST(planId, fromDate, toDate → lotNo, grDate, decision, defectType, ngCount) | 없음 → 같은 위치에 새로 작성 | `cmnPrototypeBadge` |
| (A1 화면 미사용) | QMS_IQC_LOT_DETAIL | 있음 `data/demo/mocks/dwh/QMS_IQC_LOT_DETAIL/ok.json`·`empty.json` | SQM·대시보드 드릴다운(A6·A7)용. IQC-005 최근 20로트 띠는 Salesforce 로트에서 읽는다 |
| QMS-03-SPP-002-S02 | KPI QMS_IQC_LAR(월, 최근 3개월) | Snowflake 목 아님. `90_CMN_KpiValue__c.csv` 96행(A0 적재) | 없음(실제 레코드) |
| QMS-03-PWT-002-S01 | KPI QMS_PERIODIC_TEST_COMPLIANCE | KPI 데모 없음. A1은 일정 레코드로 화면에서 계산해 보이고 asOf 칸은 비움 | 없음(proto 일정 레코드 기준) |
| QMS-03-IQC-003-S01 | Apex DTO `QMS_IqcQueueDTO`(제안) | `data/demo/mocks/apex/qmsIqcQueue/KR01.json` | DTO 형태·Jest 픽스처로만 쓰고 화면은 실제 로트를 읽는다 |
| QMS-03-SPP-002-S01 | Apex DTO `QMS_PortalHomeDTO`(제안) | `data/demo/mocks/apex/qmsPortalHome/V10003.json` | 같은 방식. 8D·NCR 카드는 A3·A4 객체라 빈 상태로 둔다 |

- 새 목은 `scripts/dev/build-prototype-mocks.py`로 정적 리소스 `CMN_PrototypeMocks`에 다시 묶는다.
- AI 응답이 필요한 A1 화면은 없다. 레일 AI 패널은 기본 패널(빈 목록)이다. IQC-008 이상 성적서 기록은 B단계다.
- 차트(PIS-002 일별 막대·누적 PPM, PWT-001 캘린더 막대)는 Chart.js가 A2에 들어오므로 A1은 표와 수치 칸으로 그린다.

## 4. 데모 데이터

| 객체 | 원본 | 건수 | 비고 |
| --- | --- | --- | --- |
| Contact(협력사 담당자) | `18_Contact.csv` | 16 | 포털 검토 사용자 후보. `ExternalKey__c` 필요(CR-6) |
| 시험 항목·기준·기준 라인 | `24~26_*.csv` | 12 + 5 + 30 | 기준·라인 `ExternalKey__c` 필요 |
| 샘플링 계획·행, 기준서·라인 | `27~30_*.csv` | 2 + 18 + 21 + 77 | 샘플링 표는 c=0 가정 값. RFP 원문 문구 금지 |
| PPAP 요소·레벨 규칙 | `31`, `32_*.csv` | 18 + 5 | 레벨별 S/R은 데모 가정(Guidance에 표시) |
| 검사 로트·결과 | `48`, `49_*.csv` | 1,359 + 4,859 | DECIDED 1,351, IN_INSPECTION 8, WAITING 0 |
| 협력사 성적서 | `50_QMS_SupplierCoa__c.csv` | 811 | MATCHED 810, OOS_HOLD 1, DRAFT 0 |
| 수준 변경·Hold | `51`, `52_*.csv` | 5 + 6 | Hold 원천 Id는 토큰(NCR·안정화) |
| 인정시험 계획·라인 | `55`, `56`, `63a_*.csv` | 15 + 98 | 계획 모두 CLOSED, 라인 모두 DONE, SUPPLIER·RELIABILITY_SYS 라인 없음 |
| PPAP·요소 라인·제출 | `57~59_*.csv` | 18 + 324 + 18 | APPROVED 17, APPROVAL 1, 제출 모두 REVIEWED |
| 문서·리비전 | `63`, `64a_*.csv` | | 시험 성적서·PPAP 문서 |
| 초기안정화 계획 | `66_QMS_StabilizationPlan__c.csv` | 2 | ACTIVE 1, RELEASED 1 |
| 협력사 인증서 | `81_QMS_SupplierCertificate__c.csv` | 8 | 모두 VERIFIED |
| KPI 값 | `90_CMN_KpiValue__c.csv` | A1 관련 192 | QMS_IQC_LAR·QMS_IQC_LOTS 각 96(A0 적재) |
| 결재 요청·To-Do | `83`, `85_*.csv` | | PPAP·인정시험 대상 행 확인 |
| 상태별 보강(proto) | `data/demo/proto/QMS_QualPlan__c.csv` 외 | 계획 4, 라인 약 20, 시료 결과 약 40 | DRAFT·PLANNED·IN_TEST·JUDGMENT_APPROVAL 계획, REQUESTED~IN_PROGRESS·FAIL 재시험·SUPPLIER·RELIABILITY_SYS 라인 |
| 상태별 보강(proto) | `QMS_SupplierTestSubmission__c`, `QMS_PpapSubmission__c`, `QMS_Ppap__c` | 3 + 2 + 3 | 제출 DRAFT·SUBMITTED·RETURNED, PPAP REQUESTED·IN_REVIEW(2차 DRAFT 제출)·INTERIM |
| 상태별 보강(proto) | `QMS_IqcLot__c`, `QMS_SupplierCoa__c`, `QMS_SupplierCertificate__c` | 6 + 2 + 2 | WAITING·기한 경과 로트, 성적서 DRAFT, 인증서 DRAFT·SUBMITTED |
| 신규(proto) | `QMS_PeriodicTestSchedule__c`, `QMS_StabilizationReport__c`, `QMS_PortalNotice__c` | 10 + 4 + 3 | 예정·진행·지연 일정, 보고 SUBMITTED·확인, 공지 |
| 신규(proto) | `QMS_StabilizationPlan__c` | 2 | DRAFT, EXIT_REVIEW(해제 화면용) |

데모 CSV 13개(26, 28, 30, 32, 49~52, 56, 58, 59, 66, 81)에는 `Name` 열이 없다. 7.1절 Name 규칙을 먼저 정한다.

## 5. 프로토 한계

| 화면 ID | 한계 | B단계에서 바뀌는 것 |
| --- | --- | --- |
| 공통 | 공장·협력사 격리 없음(검토 PS View All), 채번 없음(데모 RecordNo), To-Do·알림·이벤트 발행 없음, UX-005 서버 잠금 없음 | 공유 등록, 채번 규칙, 서비스·콜백·이벤트 |
| QMS-02-DVQ-003-S01·S02 | 상태 전이·스냅숏 잠금 없음, 결재 상신 비활성 | 서비스 전이, 결재 유형·콜백, 필드 잠금 |
| QMS-02-DVQ-004-S01 | 기준 세트 점수 정렬·합집합 없음, 저장 안내 | `QMS_TestStandardSelector.select`, 생성·스냅숏·자동 일정 |
| QMS-02-DVQ-004-S02 | Provider 규칙 없음(경고 행·필수 라인 삭제 차단·상신 검증·자동 일정), 표준 저장만 | Provider rowMeta·validate·defaults |
| QMS-02-DVQ-006-S01 | 접수·착수 안내, IsAtRisk·지연은 데모 값 그대로 | 위험 재계산 배치, 지연 알림 |
| QMS-02-DVQ-007-S01 | 중간 저장은 시료 값만(IsPass 계산 없음), DONE 조건·NCR 게이트웨이 없음, 한도견본 링크 자리만 | Provider 판정, 게이트웨이 To-Do, `qmsLimitSampleLink`(A5) |
| QMS-02-DVQ-008-S01 | 유효 결과 요약은 라인 조회, 제안 판정 없음 | BR-1~3 판정 규칙 |
| QMS-02-DVQ-009-S01·S02 | 표준 형식(en_US) 레이아웃만, 재생성 안내 | 고객별 형식, Queueable 생성·문서 등록 |
| QMS-02-DVQ-010-S01·S02 | 제출·승인·반려 안내, 라인 정보 표시 방식 미정(11절 A1-03) | 제출 서비스, 시료 결과 복사·DONE 처리 |
| QMS-03-SPP-001-S01·S02 | 사용자 활성화 안내, 알림 링크 변환·MFA·90일 미로그인 없음 | 활성화 서비스, `QMS_PortalUrlResolver`, 로그인 정책 |
| QMS-03-SPP-002-S01~S03 | 8D·NCR 카드 빈 상태, 업로드 DRAFT 서버 검사 없음, 공지 조건 단순 | 카드 데이터(A3·A4 이후), 서버 검사, 공지 대상 공유 |
| QMS-03-IQC-001-S02 | 미리보기·새 버전·활성화 안내, 특별특성 누락 점검·Provider 규칙 없음 | 시료 수 결정, 버전·누락 점검 |
| QMS-03-IQC-002-S01 | 로트 초기화·채번·SAP 수신 없음(데모 로트만) | 초기화 서비스, 수신 계약 |
| QMS-03-IQC-003-S02·S03 | 중간 저장은 JSON만(Judgment·Min·Max·Mean 계산 없음), 판정·검사 훅 없음 | Provider 판정, `QMS_InspectionHook`, decide 후속 |
| QMS-03-IQC-005-S01 | "다음 전환까지 남은 로트 수" 칸 "—", 수동 변경·상신 안내 | 전환 규칙 평가, 무검사 결재 |
| QMS-03-IQC-006-S01~S04 | OOS 계산·매칭 없음(데모 매칭 값 표시) | 제출 점검, 매칭, 4M 초품 처리 |
| QMS-03-PWT-001·002 | 일괄 생성 안내, 배치 계획 생성 없음, 준수율은 proto 일정으로 화면 계산 | 일 배치, 판정 반영, KPI 수신 |
| QMS-03-PPA-001~004 | 시뮬레이션·요구·제출·검토·상신 안내, 요소 재계산·시스템 링크 없음, 통보서 레이아웃만 | 서비스 전체, 결재 콜백, 통보서 등록 |
| QMS-03-PIS-001~003 | 확정·연장·해제 안내, Hold 연동 없음, 차트 대신 표, 해제 조건은 목표·실적 나란히 표시만 | Hold API, 일 집계 수신, 조건 판정·결재 |

## 6. 화면 확인 기록

| 날짜 | 페르소나 | 화면 ID | 결과 | 메모 |
| --- | --- | --- | --- | --- |

## 7. 데이터 모델 착수 목록

### 7.1 A1 전 객체 공통 규칙

- 정의 파일은 객체당 하나(`meta-src/qms/{객체}.json`, R-8). 뒤 Vol.이 더하는 필드도 같은 파일에 넣고 필드마다 `wi`를 남긴다.
- 외부 키(CR-6): `ExternalKey__c`(Text, External ID, Unique)를 TestStandard·TestStandardLine·QualPlanLine·SamplingPlanRow·IqcStandard·IqcStandardLine·IqcResult·IqcLevelChange·IqcLevelHold·PpapLevelRule·PpapElementLine·PpapSubmission·SupplierCertificate와 Contact에 더한다.
- Name: 데모 CSV에 Name이 없는 상세·이력·제출 객체는 AutoNumber Name(제안, 예 `QPL-{0000000}`)으로 한다. 업무 헤더인 `QMS_StabilizationPlan__c`·`QMS_SupplierCoa__c`·`QMS_SupplierCertificate__c`는 Text Name을 두고 데모 생성기에서 채운다(제안).
- 공유: 기준정보는 사내 OWD Public Read Only, 업무 객체는 Private + Apex 공유 사유 `CMN_Plant__c`·`CMN_Supplier__c`(협력사 공개 객체)·`CMN_Approval__c`(결재 대상), Master-Detail 상세는 ControlledByParent. 외부 OWD는 모두 Private(SPP-001 BR-5). `CMN_SharingConfig__mdt` 등록은 B단계(포털 예외는 11절 A1-02). `QMS_PS_Prototype_Review`에 A1 업무 객체 View All을 더한다.
- T1 헤더(UX-004): 계획·라인·로트·PPAP·안정화 계획에 `DaysToDue__c`(Formula)와 컴팩트 레이아웃 `{객체}_Header`를 만든다. 기준일: 계획 TargetDate, PPAP DueDate, 라인 PlannedEnd(제안), 안정화 StartDate + MinDays(제안). 로트는 DueAt 시각이라 대체 필드 `DueAt__c`를 쓰고 정의 파일에 사유를 적는다.
- 원천 링크(R-7): `SourceLink__c`(Formula HYPERLINK)를 QualPlan·Ppap·StabilizationPlan·IqcLevelHold·IqcLevelChange에 더한다. 같은 방식으로 `NcrLink__c`(라인·로트), `CurrentPlanLink__c`·`LastPlanLink__c`(보증시험 일정)를 제안한다. 모두 "명세 차이"로 기록한다.
- 상태 진행바: QualPlan·QualPlanLine·IqcLot·SupplierCoa·Ppap·PpapElementLine·StabilizationPlan·제출 객체 4종의 `CMN_StatusFlow__mdt` 레코드.
- 레코드 타입: QualPlan(PART, PRODUCT), Ppap(SUPPLIER, CUSTOMER), StabilizationPlan(PART, PRODUCT), StabilizationReport(SUPPLIER, INTERNAL — Vol.4 변경 요청).
- Platform Event 5개는 정의만 만든다(발행·구독은 B단계).
- User Lookup 필수(R-10: Sqe·Tester·Inspector·DecidedBy)는 레이아웃·Dynamic Forms에서 필수 표시만 한다.
- 시료 값 JSON(R-12): `SampleValuesJson__c`·`ValuesJson__c`·`SampleResultsJson__c`를 읽고 쓰는 공용 모듈 `QMS_SampleValueCodec`(제안, Apex)를 A1에서 만들고 A2 출하검사가 쓴다.
- Vol.4 확장(R-8): Vol.3 객체에 Vol.4가 더하는 필드·값·레코드 타입은 A1에서 함께 만든다. PRODUCT·CUSTOMER 화면(레이아웃·레코드 페이지)은 A2에서 만든다. Vol.4 신규 객체(`QMS_PpapEvidence__c`, `QMS_PpapCustomerSubmission__c`, `QMS_PpapCollector__mdt`, `QMS_PpapElementOwnerRule__mdt`)는 A2다.
- 업무 기준 mdt(O-6): `QMS_IqcSwitchRule__mdt`·`QMS_StabilizationDefault__mdt`는 변경이 드물어 mdt를 유지한다(나안). `QMS_ReportFormat__mdt`·`QMS_PortalRoute__mdt`·`QMS_InspectionHook__mdt`는 시스템 설정이다. 시험 기준·PPAP 레벨 규칙은 이미 커스텀 객체다.

### 7.2 WI별 객체

필드 수는 명세 데이터 모델 표 기준(Name 제외)이다.

| WI | 객체(종류) | 필드 | 공유 기준 | A1에서 함께 반영 |
| --- | --- | --- | --- | --- |
| DVQ-001 | `QMS_TestItem__c` | 18(DisplayName__c 포함) | 사내 공개 읽기 | — |
| DVQ-002 | `QMS_TestStandard__c` / `QMS_TestStandardLine__c`(MD) | 10 / 6 | 사내 공개 읽기 / MD | ExternalKey 2, TriggerType PERIODIC·Phase REQUAL(Vol.3 변경 요청), ChangeTypes 값 = CHANGE_TYPE 경로 키 |
| DVQ-003 | `QMS_QualPlan__c` | 25 + 1(AtRiskLines, DVQ-006) | Plant(협력사 공유 없음) | DaysToDue, SourceLink, `ClosedAt__c`(DVQ-008 BR-6, 명세 누락), TriggerType·Phase 값 추가 |
| DVQ-003·006 | `QMS_QualPlanLine__c`(MD) | 30 + 5(DVQ-006) | MD | ExternalKey, `ExternalSyncStatus__c`·`ExternalSyncMessage__c`(Vol.9 변경 요청), `EquipmentNo__c`(Vol.6b 선택, 보류 권고) |
| DVQ-003 | `QMS_QualSampleResult__c`(MD) | 6 | MD | AutoNumber Name |
| DVQ-005 | `QMS_QualPlanEvent__e` | 5 | — | 정의만 |
| DVQ-006 | `QMS_QualLineRequested__e` | Vol.9 INT-018 제안 필드 | — | 정의만, EventType REQUESTED·CANCELLED·RESCHEDULED |
| DVQ-009 | `QMS_ReportFormat__mdt` | 6 | — | Vol.4 3필드(ReportType·ShowSampleValues·FileNamePattern), 표준 형식 레코드 1 |
| DVQ-010 | `QMS_SupplierTestSubmission__c` | 10 | Plant + Supplier | 라인 정보 스냅숏(11절 A1-03), 포털 PS(11절 A1-15) |
| SPP-001 | `Contact` 확장 / `QMS_PortalRoute__mdt` | 3 / 3 | — | Contact ExternalKey, A1 포털 경로 레코드(9절) |
| SPP-002 | `QMS_PortalNotice__c` | 7 | 사내 공개 읽기, 외부는 11절 A1-14 | — |
| SPP-003 | `QMS_SupplierCertificate__c` | 9 | Supplier(사내 공개 읽기) | ExternalKey. Account `IatfCertified__c`·`IatfExpiry__c`·`PortalEnabled__c`는 배포됨 |
| IQC-001 | `QMS_SamplingPlan__c` / `QMS_SamplingPlanRow__c`(MD) | 4 / 7 | 사내 공개 읽기 / MD | Row ExternalKey |
| IQC-001 | `QMS_IqcStandard__c` / `QMS_IqcStandardLine__c`(MD) | 10 / 11 | Plant(협력사 읽기는 11절 A1-03) / MD | ExternalKey 2 |
| IQC-002 | `QMS_IqcLot__c` | 38 | Plant + Supplier | `Coa__c`(Lookup, IQC-006 BR-3이 쓰나 명세 누락), `GrPostedAt__c`(Vol.9), `RejectDefectType__c`·`RejectNgSampleQty__c`·`RejectReason__c`(Vol.6a) |
| IQC-002 | `QMS_IqcResult__c`(MD) | 25 | MD | ExternalKey |
| IQC-003 | `QMS_InspectionHook__mdt` | 3 | — | 레코드 없음(구현 등록은 A5·B) |
| IQC-004 | `QMS_IqcDecision__e` | 13 | — | 정의만 |
| IQC-005 | `QMS_IqcLevelChange__c` / `QMS_IqcLevelHold__c` | 7 / 8 | 기준 없음(R-11) → `Plant__c`·`Supplier__c` 복사 필드(제안) + Plant 공유 | ExternalKey 2 |
| IQC-005 | `QMS_IqcSwitchRule__mdt` | 2 | — | BR-2 기본값 레코드 |
| IQC-006 | `QMS_SupplierCoa__c` | 18 | Plant + Supplier, 협력사 소유 | Name 규칙 |
| PWT-001 | `QMS_PeriodicTestSchedule__c` | 17 | Plant + Supplier | 계획 링크 수식(제안) |
| PPA-001 | `QMS_PpapElement__c` / `QMS_PpapLevelRule__c` | 15 / 10 | 사내 공개 읽기 | LevelRule ExternalKey |
| PPA-002 | `QMS_Ppap__c` | 27 | Plant + Supplier(InternalNote는 포털 FLS 없음) | DaysToDue, SourceLink, Vol.4 RPP-001 9필드·Status 2값·RT CUSTOMER, (선택) `PdsSyncStatus__c`·`PdsSyncMessage__c`(Vol.9) |
| PPA-002 | `QMS_PpapElementLine__c`(MD) / `QMS_PpapEvent__e` | 18 / 6 | MD / — | ExternalKey, Vol.4 `Responsible__c`·`ElementDueDate__c`, 이벤트 `Scope__c`·CUSTOMER_SUBMITTED |
| PPA-003 | `QMS_PpapSubmission__c` | 12 | Plant + Supplier, 협력사 소유 | ExternalKey |
| PIS-001 | `QMS_StabilizationPlan__c` | 29 | Plant + Supplier | `LastResultAsOf__c`(Snowflake 표시 명세), DaysToDue, SourceLink, Vol.4 EFC-001 19필드·Trigger 3값 |
| PIS-001 | `QMS_StabilizationDefault__mdt` | 9 | — | Vol.4 8필드, 기본값 레코드 |
| PIS-002 | `QMS_StabilizationReport__c` | 11 | Plant + Supplier, 협력사 소유 | Vol.4 `Line__c`·`ProdDate__c`·`Shift__c`, Status 값 정리(11절 A1-01) |
| PIS-003 | `QMS_StabilizationEvent__e` | 4 | — | 정의만 |

합계: 커스텀 객체 26, 커스텀 메타데이터 5, Platform Event 5(모두 36) + Contact 확장. 게이트웨이 프레임워크(`QMS_GatewayBinding__mdt`, CR-3)는 B단계 DVQ-007에서 만든다.

### 7.3 다른 메뉴 객체 참조

- Lookup 가능(배포된 CMN 중 A1이 참조하는 것, `meta-src/cmn/*.json` 기준): `CMN_Item__c`, `CMN_SupplierItem__c`, `CMN_Plant__c`, `CMN_Line__c`, `CMN_Operation__c`, `CMN_Department__c`, `CMN_ProductGroup__c`, `CMN_Vehicle__c`, `CMN_Characteristic__c`, `CMN_Code__c`, `CMN_Document__c`(Supplier__c·SupplierVisible__c 배포됨), `CMN_Todo__c`, `CMN_KpiValue__c`, Account(고객·협력사), Contact, User.
- 같은 묶음의 메뉴 간 Lookup: `QMS_PeriodicTestSchedule__c.Standard__c` → `QMS_TestStandard__c`(R-13, PWT-001 선행 DVQ-002). A1에서 함께 배포한다.
- 텍스트 Id만(대상 미배포 또는 명세가 텍스트로 정함): NCR(`NcrRecordId__c` 라인·로트, Hold `SourceRecordId__c`), 4M(계획·PPAP·안정화 `SourceRecordId__c`, 로트·성적서 `Supplier4mRecordNo__c`), PMS 원천, 보증시험의 `CurrentPlanId__c`·`LastPlanId__c`, PPAP 요소 `LinkedRecordId__c`·`AcceptedRevisionId__c`, 측정기 `GaugeNo__c`.
- 링크·버튼만 두는 메뉴 간 이동: NCR 등록 요청(DVQ-007, IQC-004 — 게이트웨이 B), 4M 원천 열기(`SourceLink__c`), 한도견본(A5 `qmsLimitSampleLink`), 협력사 실적(A6).

## 8. 공통 부품 적용(화면 전략 8.1)

WI 문서는 고치지 않았다. 아래는 변경 요청이다.

| WI | 명세 컴포넌트 | 바꾸는 방식 | 변경 요청(WI 본문) |
| --- | --- | --- | --- |
| QMS-02-DVQ-004 | qmsQualPlanGrid | `cmnEditableGrid` + `QMS_QualPlanLineGridProvider` | 반영됨(7 → 4 M/D) |
| QMS-02-DVQ-007 | qmsQualResultEntry | `cmnFieldEntryShell` + `QMS_QualResultEntryProvider` | 반영됨(7 → 5). VISUAL 한도견본은 `qmsLimitSampleLink`(Vol.6b 변경 요청) |
| QMS-03-IQC-003 | qmsIqcInspection | `cmnFieldEntryShell` + `QMS_IqcInspectionProvider`(제안, `CMN_FieldEntryProvider__mdt` ObjectApiName `QMS_IqcLot__c`). `qmsIqcInspection`은 진입점으로 남긴다 | 화면/UX 표 행을 "셸 진입점"으로 바꾸고 Provider 책임(load: 결과 라인 → 셸 항목, save: JSON·BR-2 계산·BR-3 판정 조건·decide, validateScan: GAUGE → 검사 훅) 추가. BR-8(5초 자동 저장)을 UX-008 BR-4·5로 대체. 선행 UX-008 추가, 공수 7 → 5(제안) |
| QMS-03-PPA-001 | qmsPpapMatrixEditor | 8.1은 UX-006 그리드지만 `CMN_GridDefinition__mdt.ParentField__c`가 필수라 부모 없는 요소 마스터에 맞지 않는다. 요소 세트별 리스트뷰 인라인 편집(Level1~5 선택 목록) + `qmsPpapRuleSimulator`(제안)로 바꾼다 | 화면/UX 문단 교체, 공수 4 → 3(제안) |
| QMS-02-DVQ-002(8.1 밖) | qmsTestStandardEditor | 오른쪽 라인 그리드를 `cmnEditableGrid` gridKey `QMS_TestStandardLine`(제안) + Provider `QMS_TestStandardLineGridProvider`(제안, ACTIVE 잠금·OBSOLETE 제외). 드래그 순서는 OrderField(Sequence). 왼쪽 검색은 `qmsQualPlanLibraryPicker`를 공용화 | BR-5 문장 교체, 선행 UX-006 추가 |
| QMS-03-IQC-001(8.1 밖) | qmsIqcStandardEditor | 라인은 `cmnEditableGrid` gridKey `QMS_IqcStandardLine`(제안) + Provider `QMS_IqcStandardLineGridProvider`(제안, CheckType 기본값·ACTIVE 잠금·FrequencyN 검증). 특성 선택·공통 점검·미리보기만 편집기에 남긴다 | BR-7 문장 교체, 선행 UX-006 추가. Vol.4 변경 요청의 공용 이름 `qmsInspStandardEditor`(mode)와 함께 정한다(11절 A1-06) |
| DVQ-010, SPP-003, PIS-002, PPA-003 | (SQE 검토 화면 이름 없음) | 공용 `cmnSubmissionReview`(R-4·O-4) + 객체별 `CMN_SubmissionReviewProvider`(제안) | 각 WI 화면 절에 "SQE 검토 = cmnSubmissionReview" 추가 |
| DVQ-010, IQC-006, PPA-003 포털 입력 | qmsSupplierTestSubmit 등 | 셸은 사내 대상(lightning__AppPage·RecordPage·RecordAction)만 있어 포털에 쓰지 않는다. 포털 LWC를 유지하고 즉시 합불은 `cmnFieldEntryJudge` 모듈, JSON은 `QMS_SampleValueCodec`(제안)을 쓴다 | BR에 "즉시 합불은 cmnFieldEntryJudge" 명시 |
| DVQ-006, IQC-003 대기열 | qmsLabQueue, qmsIqcWorkbench | 해당 공통 부품 없음(바코드·일괄 처리). 메뉴 LWC 유지 | IQC-003은 Vol.4 공용 이름 `qmsInspectionWorkbench`(mode IQC) 결정(11절 A1-06) |

## 9. 포털

### 9.1 A1에서 만드는 것

- 사이트: Experience Cloud "SL Supplier Quality", Build Your Own(LWR), 경로 `/supplier`. 사이트 언어 선택기(ko, en_US, zh_CN). 로고·색은 Experience Builder 설정.
- 라이선스: D-5·D3-1 미결이라 Customer Community Plus로 가정한다. 검토 Scratch Org에 Plus 5·Plus Login 5가 있다(p00 S-3). 검토 사용자 1명(`CT-V10001-01`, Member)을 만든다.
- 사용자 준비: 프로필 `SL Supplier Portal User`, 포털 역할 Manager. 협력사 Account Owner에게 역할이 있어야 포털 사용자를 만들 수 있다. 활성화 서비스가 B단계라 생성은 스크립트로 한다(`scripts/apex/seed-portal-user.apex`, 제안).
- 권한: PSG `QMS_PSG_SupplierPortal`(정의됨)에 PS `QMS_PS_Portal_Base`·`_Coa`·`_Ppap`·`_Stab`·`_Cert`와 시험 성적서 PS(11절 A1-15)를 넣는다. 게스트 사용자 객체 권한은 0.
- 외부 OWD: QMS·CMN 업무 객체와 `CMN_Item__c`는 Private, `CMN_Plant__c`·`CMN_CodeGroup__c`·`CMN_Code__c`만 Public Read Only(SPP-001 BR-5).
- 포털 LWC 규칙: `lightningCommunity__Page`·`lightningCommunity__Default` 대상의 순수 LWC, `force:*` 금지, Apex는 `with sharing` + `WITH USER_MODE`, 사내 `cmnDocumentPanel`·검색 컴포넌트 미배치, 사내 필드명·내부 코드 비노출, SLDS 1 기준 별도 검수(DS-2).

### 9.2 페이지

| 포털 메뉴 | 페이지 경로(제안, `QMS_PortalRoute__mdt`) | LWC | WI | A1 동작 |
| --- | --- | --- | --- | --- |
| 홈 | `/` | `qmsPortalHome` | SPP-002 | 할 일(기한 경과 우선)·공지 실제 조회, 8D·NCR 카드 빈 상태 |
| 품번 | `/items` | `qmsPortalItemList` | SPP-002 | 자기 품번 조회, 합격률은 KPI 데모 |
| 시험 성적서 | `/test-submission/{id}` | `qmsSupplierTestSubmit` | DVQ-010 | DRAFT 저장·업로드 실제, 제출 안내 |
| 성적서 | `/coa/{id}`(명세 예시), `/coa` | `qmsSupplierCoaForm`, `qmsSupplierCoaImport` | IQC-006 | 같음 |
| 수입검사 결과 | `/iqc-results` | `qmsPortalIqcResults` | IQC-004 | 6개월 조회 실제 |
| PPAP | `/ppap/{id}` | `qmsSupplierPpapSubmit` | PPA-003 | 요소 입력·업로드 실제, 점검·제출 안내 |
| 초기안정화 | `/stabilization/{id}` | `qmsPortalStabilization`, `qmsSupplierStabReport` | PIS-001·002 | 조회 실제, 보고 제출 안내 |
| 인증서 | `/certificate/{id}`, `/certificate` | `qmsSupplierCertForm` | SPP-003 | 같음 |
| 부적합·8D 회신, 4M 신청, 품질 실적 | 자리 페이지 "준비 중" | — | A3·A4·A6·A7 | 메뉴만 |

- 명세는 기능마다 컴포넌트 하나만 정한다. 목록이 필요한 메뉴(성적서·인증서·PPAP)는 같은 컴포넌트가 recordId가 없으면 목록을 보이게 한다(제안).

### 9.3 미루는 것(B단계·R1 뒤)

- 협력사 격리 검증(SPP-001 AC-2, 각 WI의 "협력사 B 접근 불가" AC). A1은 검토 사용자 1명으로 화면만 본다.
- 사용자 활성화·비활성화 서비스, 90일 미로그인, Member·Login 혼용 운영.
- 알림 링크 변환(`QMS_PortalUrlResolver`, NTF-001 `CMN_RecipientUrlResolver` 배포됨), 포털 To-Do의 사내 홈 제외(TDO-001 변경 요청).
- 이메일 일회용 코드(MFA), SSO 검토(오픈 이슈), 업로드 서버 검사(DRAFT·소유).
- 포털 품질 요약 슬롯 `qmsPortalQualitySummary`(Vol.7 변경 요청)와 스코어카드(Vol.6c)는 A6·A7.

## 10. 구현 순서 제안

1. 착수 준비: 11절 기본값 적용, `screen-map.csv` 화면유형 보정(1.5절), 데이터 모델 변경 요청 반영 목록 확정(7.2절 마지막 열).
2. 데이터 모델 QMS-02: DVQ-001 → DVQ-002 → DVQ-003(+DVQ-006 필드) → DVQ-010 객체, 이벤트 2, `QMS_ReportFormat__mdt`. `python3 scripts/dev/metagen.py`.
3. 데이터 모델 QMS-03: 기준(IQC-001, PPA-001, SPP-002 공지, mdt 4) → 업무(IQC-002, IQC-005, IQC-006, PWT-001, PPA-002·003, PIS-001·002, SPP-003, Contact 확장) → 이벤트 3. PWT-001은 DVQ-002 뒤(Standard Lookup).
4. 권한: PS(`QMS_PS_TestLibrary_Admin`, `QMS_PS_Qual_Read`·`_Edit`·`_LabExecute`, `QMS_PS_Iqc_Read`·`_Inspect`·`_Admin`·`_Integration`, `QMS_PS_Ppap_Read`·`_Edit`, `QMS_PS_PpapConfig_Admin`, `QMS_PS_Stab_Read`·`_Edit`, `QMS_PS_PeriodicTest_Edit`, `QMS_PS_SupplierPortal_Admin`, 포털 PS) → PSG, 탭, 검토용 PS 갱신. 데모 적재 `--upto-bundle A1` + proto CSV.
5. 표준 화면: 리스트뷰·레이아웃·컴팩트 레이아웃, `CMN_StatusFlow__mdt`, UX-004 레코드 페이지(계획, 라인, 로트, PPAP, 안정화 계획) + UX-005 규칙 + `CMN_RailPanel__mdt`. 메뉴 허브 기능 타일 6개에 대상을 넣고 추가 타일(시험 항목·시험 기준·시험실 작업·검사 로트·기준서·성적서·검사 수준·보증시험 등록·PPAP 설정, 제안)을 만든다. 품질 업무 앱 "인정시험·검사" 탭, 현장 앱 "검사 입력". 협력사 품번·협력사 Account 레코드 페이지는 QMS 패키지에 새로 만든다(CMN 페이지가 QMS 컴포넌트를 참조하지 않게).
6. 공통 부품 설정: 그리드 3개(`QMS_QualPlanLine`, `QMS_TestStandardLine`, `QMS_IqcStandardLine`)와 Provider 뼈대(규칙 없음), 현장 입력 Provider 2개(`QMS_QualResultEntryProvider`, `QMS_IqcInspectionProvider`) 등록, `cmnSubmissionReview` 신규 공용 부품(DVQ-010·SPP-003·PIS-002 사내 검토 화면의 선행).
7. 컨트롤러·서비스 자리: 2절 서비스(본문 `notYetAvailable`), 선택기(USER_MODE), DTO(`QMS_IqcQueueDTO`·`QMS_PortalHomeDTO` 제안 형태), `QMS_SampleValueCodec`.
8. 사내 커스텀 LWC(메뉴 순서): DVQ(마법사·라이브러리·복사 → 의뢰·대기열 → 결과 입력 진입 → 판정 → 보고서 버튼, VF `QMS_DvprPdf`), IQC(대기열 → 판정 대화상자 → 기준서 편집기·가져오기 → 수준 패널 → 성적서 매칭), PWT(등록·캘린더 → 보드·증빙), PPA(시뮬레이터 → 요구 액션 → 검토 → 판정, VF `QMS_PpapNoticePdf`), PIS(모니터·목록 → 해제·연장), SPP 사용자 관리.
9. 포털: 사이트·게스트·외부 OWD → 검토 사용자 → 공용 `qmsPortalDocUpload` → 홈·품번 → 제출 화면(DVQ-010, IQC-006, PPA-003, PIS-002, SPP-003) → 조회 화면(IQC-004, PIS-001) → 경로 레코드 → 자리 페이지.
10. 목 2개 작성·리소스 재생성 → `wi-check.sh` → 배포 → 페르소나별 화면 확인(6절 기록) → `screen-map.csv` 화면 완료 → WI 단위 커밋 → `[A1] 개발 품질·부품/협력사 품질 1차 화면 완료`.

선행 관계: DVQ-003 → DVQ-004·006·007·008·009, DVQ-007 → DVQ-010, IQC-001 → IQC-002 → IQC-003 → IQC-005·006, PPA-001 → PPA-002 → PPA-003 → PPA-004, PIS-001 → PIS-002 → PIS-003, SPP-001 → SPP-002 → 모든 포털 화면.

## 11. 결정·확인 필요

자율 진행 원칙에 따라 권고안으로 진행하고 R1에서 확정한다.

| ID | 항목 | 영향 화면 | 권고(기본값) |
| --- | --- | --- | --- |
| A1-01 | 협력사 제출 상태 값과 공용 검토 화면(R-4·O-4). A1 제출 객체 5종 값이 다르다: 시험 성적 ACCEPTED·RETURNED, 안정화 보고 CONFIRMED·RETURNED, 인증서 VERIFIED·REJECTED·EXPIRED, PPAP 제출 REVIEWED, 성적서는 검토 없음 | DVQ-010-S02, SPP-003-S02, PIS-002-S04, PPA-003-S02 | 의미 4종(작성 중·제출·승인·반려)으로 맞춘다. 안정화 보고 CONFIRMED → ACCEPTED로 값 변경. 인증서는 수명 상태라 값 유지, PPAP 제출은 요소별 판정이라 REVIEWED 유지. `cmnSubmissionReview`는 객체별 값 매핑을 설정으로 받는다 |
| A1-02 | 포털 데이터 노출. B단계 공유 전에는 외부 OWD Private + `with sharing`이라 포털 화면이 빈다(검토용 View All PS는 사내 페르소나용) | 포털 화면 전부 | Supplier__c가 있는 A1 객체 9개(SupplierTestSubmission, SupplierCertificate, IqcLot, SupplierCoa, PeriodicTestSchedule, Ppap, PpapSubmission, StabilizationPlan, StabilizationReport)의 `CMN_SharingConfig__mdt` SupplierField 등록만 A1로 당긴다(`CMN_SharingService` 배포됨). Plant 등록은 B단계 |
| A1-03 | 포털이 읽어야 하는데 협력사에 공유되지 않는 헤더: DVQ-010 라인 정보(계획 공유 없음, DVQ-003 BR-5), IQC-006 CoaCheck 라인(기준서는 Plant 공유만) | DVQ-010-S01, IQC-006-S01 | 시험 제출에 라인 스냅숏 필드(`LineSnapshotJson__c`, 제안)를 둔다. 기준서는 `CMN_Item__c`와 같은 방식으로 협력사 품번 기준 Read 공유(사유 CMN_Supplier, 제안). `without sharing` 조회는 쓰지 않는다 |
| A1-04 | PPAP 매트릭스 편집(8.1 그리드 대상이지만 부모 없음) | PPA-001-S01 | 리스트뷰 인라인 편집 + 시뮬레이터 LWC |
| A1-05 | 수입검사 셸 차이: ATTRIBUTE "NG 수만 입력" 모드가 셸에 없음, 5초 자동 저장(IQC-003 BR-8)과 UX-008 저장 규칙이 다름, REJECT 입력(불량 유형·시료 수)이 셸 DTO에 없음 | IQC-003-S02·S03 | A1은 시료별 OK/NG만, 저장은 UX-008 규칙, 판정 입력은 별도 대화상자. NG 수 입력은 UX-008 항목 유형 추가 여부를 R1에서 정한다 |
| A1-06 | Vol.4 변경 요청의 공용 이름(`qmsInspectionWorkbench`·`qmsInspStandardEditor`, mode IQC·FQC) | IQC-001-S02, IQC-003-S01 | A2 재사용이 확정적이라 A1부터 공용 이름 + mode 속성으로 만든다(명세 차이 기록). 검사 입력은 셸로 대체되어 `qmsInspectionEntry`는 만들지 않는다 |
| A1-07 | 포털 라이선스(D-5·D3-1) | 포털 전부 | Customer Community Plus 가정, 확정은 SL |
| A1-08 | 데모 상태 부족: 계획 전부 CLOSED, PPAP 대부분 APPROVED, WAITING 로트·DRAFT 제출 없음, 일정·보고·공지 데모 없음 | DVQ·PPA·PIS·PWT 다수 | 4절 proto CSV 작성. 생성기 변경 요청에도 기록 |
| A1-09 | Name 열 없는 데모 CSV 13개 | 적재 | 7.1절 규칙(상세·이력·제출은 AutoNumber, 헤더 3개는 Text + 생성기 보강) |
| A1-10 | DVP&R Excel 내려받기(SheetJS 정적 리소스 이름 미정, sf-dev 6절 "WI 지정 이름") | DVQ-009-S02 | 이름 `cmnSheetJs`(제안), 데이터를 읽기만 하므로 A1에서 실제 동작. 중간 보고서 PDF도 VF 직접 열기로 실제 |
| A1-11 | 마법사 저장(A단계 자리 구현이면 A1에서 새 계획을 못 만든다) | DVQ-004-S01 | 안내로 두고 proto 계획으로 화면 확인 |
| A1-12 | Vol.4 확장 필드를 A1에서 만들지(R-8) | 계획·PPAP·안정화 | 만든다. PRODUCT·CUSTOMER 화면은 A2 |
| A1-13 | 검사 수준 이력·Hold 공유 기준(R-11) | IQC-005 | `Plant__c`·`Supplier__c` 복사 필드 + Plant 공유. Master-Detail(협력사 품번)안은 삭제 연쇄 때문에 권고하지 않음 |
| A1-14 | 포털 공지의 외부 노출(설정 객체인데 외부 OWD 규칙에 없음) | SPP-002-S01 | 외부 Public Read Only, 대상 협력사 필터는 Apex. 협력사별 비공개 공지가 필요하면 B단계에서 공유로 바꾼다 |
| A1-15 | 시험 성적 제출 객체의 포털 PS가 명세에 없음(Vol.3 3절은 Coa·Ppap·Stab·Cert만) | DVQ-010-S01 | `QMS_PS_Portal_QualTest`(제안) 신설 |
| A1-16 | Vol.2 PS → PSG 매핑 미정(DVQ-003 BR-6이 8절을 가리키지만 표 없음), "신뢰성팀장 PSG" 없음 | DVQ 전체 | Qual_Read: Viewer·QualityManager·SupplierQuality, Qual_Edit: QualityEngineer·DevEngineer, Qual_LabExecute: LabTester, TestLibrary_Admin: QualityAdmin(신뢰성팀장은 개인 할당) |
| A1-17 | 협력사 품번·협력사 Account 레코드 페이지 소유 | IQC-005-S01, PPA-002-S02, SPP-001-S02 | QMS 패키지에 새 레코드 페이지를 만들고 앱 기본 보기로 지정 |
