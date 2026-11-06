# PMS 공통 설계(Vol.P1~P6의 계약)

기준일 2026-11-06. PMS Vol.P1~P6은 이 문서의 메뉴·WI 번호·객체 이름·상태값·이벤트·QMS 접점을 그대로 쓴다. 이 문서와 Vol. 본문이 다르면 이 문서가 이긴다(바꿀 때는 이 문서부터 고친다). Vol. 간 소유 등록은 `interfaces.md` 6절에도 요약해 둔다.

## 1. 범위와 번호

- 원천: PMS RFP(P-1~71, 13개 모듈), 신제품개발 회사표준 개선 RFP(신제품 개발 프로세스 약 10단계 개정 26.11~27.04, PMS·회사표준 시스템 연계 27년~), 분석 노트.
- 범위: 수주 확정부터 SOP + 성과 평가까지 신차 개발 프로젝트 전 주기. 양산 이후 품질은 QMS.
- 메뉴 번호 = PMS RFP 3장 절 번호(3.2 → PMS-02). QMS와 같은 규칙이다.
- **PMS-01 일반(P-1~3)은 Vol.을 만들지 않는다.** 다국어·모바일·화면 가이드는 CMN-00(I18N-001, UX-001, UX-002)이다.
- Vol.0이 이미 덮는 요구: P-4(MDM-003·004 기준정보 부분), P-7(MDM-001, INT-002), P-17·18·22·23(NTF-001 알림), P-19·63(TDO, UX-007), P-34·36·39·45(DOC-001), P-38·65~68(APV), P-40(MTG-001), P-47(UX-003 코멘트), P-55(DSH-001 프레임), P-57(SEC-002 공장 격리), P-58~62(AI 공통), P-64(INT-001), P-69(AI-002). PMS Vol.은 이 WI를 선행으로 쓰고 같은 기능을 다시 만들지 않는다.

| Vol. | 파일 | 메뉴(기능코드) | RFP |
| --- | --- | --- | --- |
| Vol.P1 | `volp1-pms02-03-project-resource.md` | PMS-02 프로젝트 정보(PRJ, SOR), PMS-03 자원(CFT, EFF) | P-4~14 |
| Vol.P2 | `volp2-pms04-07-schedule-activity.md` | PMS-04 일정(WBS), PMS-07 Task·Activity·Milestone(ACT) | P-15~28, P-41~47 |
| Vol.P3 | `volp3-pms05-06-cost-deliverable.md` | PMS-05 비용(CST), PMS-06 산출물(DLV) | P-29~40 |
| Vol.P4 | `volp4-pms08-09-risk-gate.md` | PMS-08 리스크·문제점(RSK, ISS), PMS-09 Gate(GAT) | P-48~54 |
| Vol.P5 | `volp5-pms10-11-dashboard-ai.md` | PMS-10 대시보드·보고(DSH), PMS-11 AI(AIP) | P-55~62 |
| Vol.P6 | `volp6-pms12-13-integration-performance.md` | PMS-12 연계·결재(INT, APV), PMS-13 성과·변경(PRF, CHG) | P-63~71 |

## 2. 업무 흐름

    수주 확정(PRJ) → 프로젝트 생성·품번·고객 마일스톤 → SOR 등록
      → CFT 구성 요청 → 팀장 승인 → 보안서약서
      → 표준 WBS 선택 → 실행 WBS 생성(시작일·고객 마일스톤 → CPM 자동 일정) → 일정 확정(기준선 1) → CFT To-Do
      → 액티비티 수행: 투입 계획·주간 실적 / 진척률 / 산출물 등록·결재 / 완료 조건(필수 데이터·QMS 조건) → 완료
      → Gate(단계 관문): 평가표(CMN 질문지 템플릿 GATE) + 산출물 자동 점검 + 이상 징후 → RAG → 결재 → 통과·조건부·실패
      → 리스크·문제점 상시 관리(QMS 클레임·NCR·레슨런 연계) / 일정·자원·산출물 변경 요청
      → 양산 이관 Gate(SOP) → QMS 초기유동 생성 → 과제 종료 → SOP + 2개월 성과 평가·수평평가 → HR

## 3. 개발 단계·Gate 모델(공통 코드)

- **DEV_PHASE**(Vol.4 LEL이 만든 공통 코드, QMS와 같이 쓴다): 회사표준 개정 결과(약 10단계)를 값으로 둔다. 개정 전 가정 값은 `QUOTE 수주·견적, KICKOFF 개발 착수, CONCEPT 구조 검토, DESIGN 설계, PROTO 시작품, DV 설계 검증, TOOLING 금형·설비, PV 생산 검증, LAUNCH 양산 준비, SOP 양산 이관` 10개다. 각 값에 Attribute1 = APQP 단계(1 계획·정의 ~ 5 양산·피드백)를 넣어 고객 APQP 보고에 매핑한다.
- **DEV_ACTIVITY_TYPE**(Vol.4 LEL, 2레벨): 표준 WBS 액티비티 유형. LELE 체크포인트 매칭 키다(D4-7).
- **CUSTOMER_MILESTONE**(신규 코드 그룹, PMS-02-PRJ-003): 고객별 마일스톤 코드(예: 고객 그룹별 P1·P2·PPAP·SOP 빌드). Attribute1 = 고객 그룹.
- **PROJECT_ROLE**(신규 코드 그룹, PMS-03-CFT-001): PM, PE 제품 설계, ELE 전장, OPT 광학, ME 생산기술, QE 품질, SQE 협력사 품질, PUR 구매, CST 원가, PMO, VIEWER. 결재선 PROJECT_ROLE 해석(PMS-12-APV-001)과 WBS 담당 역할의 키다.
- **Gate**: `PMS_GateDefinition__c`(코드 G0~G9, 단계, 평가표 질문지 Family). 표준 WBS의 Gate 마일스톤 액티비티가 GateCode를 가진다. 고객별 Gate 이름 차이는 CustomerGroup 행으로 덮어쓴다.

## 4. WI 목록(번호·제목·추적·Wave·공수 초안)

공수·Wave는 각 Vol. 작성 시 조정할 수 있다. 번호와 제목의 의미는 바꾸지 않는다.

| WI | 제목 | 추적 | Wave | M/D |
| --- | --- | --- | --- | --- |
| PMS-02-PRJ-001 | 프로젝트 기준정보·유형·수명주기(수주·SOP·EOP·연식) | P-4 | W1 | 5 |
| PMS-02-PRJ-002 | 프로젝트 품번·사양 구성(개발처·생산처) | P-4 | W1 | 3 |
| PMS-02-PRJ-003 | 고객 마일스톤·액티비티 매핑 | P-5 | W1 | 4 |
| PMS-02-SOR-001 | 고객 요구사항(SOR) 등록·버전 | P-6 | W1 | 5 |
| PMS-02-SOR-002 | 요구사항 충족 추적·충족률 | P-6, P-37 | W2 | 5 |
| PMS-03-CFT-001 | CFT 구성·프로젝트 역할·여유율 조회 | P-8, P-9 | W1 | 6 |
| PMS-03-CFT-002 | CFT 할당 요청·팀장 승인·변경 | P-12, P-13 | W1 | 5 |
| PMS-03-CFT-003 | 보안서약서 관리(TISAX) | P-14 | W1 | 3 |
| PMS-03-EFF-001 | 투입 기여도 계획(일 8시간·주 52시간 상한) | P-10 | W1 | 5 |
| PMS-03-EFF-002 | 투입 실적 주간 입력·PM 승인 | P-11 | W1 | 6 |
| PMS-03-EFF-003 | 자원 부하·여유율 집계 | P-8, P-10 | W2 | 4 |
| PMS-04-WBS-001 | 표준 WBS 템플릿·버전·필수 액티비티 | P-15 | W1 | 7 |
| PMS-04-WBS-002 | 표준 WBS 산출물·완료 조건 정의 | P-15, P-21, P-36 | W1 | 5 |
| PMS-04-WBS-003 | 실행 WBS 생성(시작일·고객 마일스톤 기반) | P-16 | W1 | 6 |
| PMS-04-WBS-004 | 일정 엔진(선후행 4종·CPM·여유시간·경고) | P-16, P-17, P-26 | W1 | 8 |
| PMS-04-WBS-005 | 일정 확정·기준선·CFT 알림·To-Do | P-18, P-19 | W1 | 4 |
| PMS-04-WBS-006 | 일정 변경 요청·승인·이력 | P-22, P-23 | W1 | 6 |
| PMS-04-WBS-007 | 진척률 산식·주간 진척·RAG | P-20, P-24 | W1 | 5 |
| PMS-04-WBS-008 | 일정 Viewer(Gantt·CPM·Milestone) | P-27 | W1 | 8 |
| PMS-04-WBS-009 | 과제 종료 승인·SOP 초과 알림 | P-25 | W1 | 3 |
| PMS-04-WBS-010 | 협력사 부품개발 일정 연계 | P-28 | W2 | 5 |
| PMS-07-ACT-001 | 액티비티 레코드·주/보조 담당·프로세스 속성 | P-9, P-41 | W1 | 5 |
| PMS-07-ACT-002 | WBS 편집(레벨 이동·필수 액티비티 보호) | P-42 | W1 | 5 |
| PMS-07-ACT-003 | 프로젝트 복사(WBS·CFT) | P-43 | W1 | 4 |
| PMS-07-ACT-004 | 완료 조건 검증·완료 승인·자동 종료·재시작·강제 완료 | P-21, P-44 | W1 | 7 |
| PMS-07-ACT-005 | 담당자 변경 요청·일괄 변경 | P-46 | W1 | 3 |
| PMS-05-CST-001 | 비용 계획(예산 항목·ED&D 산정) | P-29 | W1 | 6 |
| PMS-05-CST-002 | 비용 실적(ED&D 자동·출장비·금형비) | P-30, P-32 | W1 | 6 |
| PMS-05-CST-003 | 직급 평균 임율·비용 권한 분리 | P-29, P-30, P-57 | W1 | 3 |
| PMS-05-CST-004 | 비용 계획/실적 대시보드·Excel 가져오기/내보내기 | P-31, P-33 | W2 | 5 |
| PMS-06-DLV-001 | 액티비티 산출물(유형 5종·일괄 등록) | P-34, P-45 | W1 | 5 |
| PMS-06-DLV-002 | 산출물 결재(팀장 필수)·연계 데이터 동기화 | P-38, P-65 | W1 | 5 |
| PMS-06-DLV-003 | 입력/출력 추적성(디지털 스레드) | P-37 | W2 | 6 |
| PMS-06-DLV-004 | 산출물 개정·영향도 분석 | P-39 | W2 | 5 |
| PMS-06-DLV-005 | 프로젝트 산출물 검색·표준 양식 내려받기 | P-35, P-36 | W1 | 3 |
| PMS-08-RSK-001 | 리스크 로그(정량 평가·주/월 검토·에스컬레이션) | P-48, P-50 | W1 | 6 |
| PMS-08-RSK-002 | 리스크 경감 대책 ↔ QMS 선행 품질 점검 추적 | P-50 | W2 | 4 |
| PMS-08-RSK-003 | 리스크·문제점 현황 대시보드 | P-51 | W1 | 3 |
| PMS-08-ISS-001 | 문제점 등록·대책서·승인·종결 | P-48, P-49 | W1 | 6 |
| PMS-08-ISS-002 | 문제점 ↔ QMS 6pi/8D·품질 이력 연계 | P-49 | W2 | 5 |
| PMS-09-GAT-001 | Gate 정의·프로젝트 Gate 일정(마일스톤 통합) | P-52, P-53 | W1 | 4 |
| PMS-09-GAT-002 | Gate 평가표 템플릿(CMN 질문지 GATE)·판 관리 | P-54 | W1 | 4 |
| PMS-09-GAT-003 | Gate 평가 수행(체크리스트·산출물 자동 점검·RAG) | P-52, P-53, P-54 | W1 | 7 |
| PMS-09-GAT-004 | Gate 결재·조건부 통과·후속 조치 | P-52, P-53 | W1 | 4 |
| PMS-09-GAT-005 | 산출물 이상 징후 탐지(데이터 대조·AI) | P-54 | W2 | 5 |
| PMS-09-GAT-006 | 양산 이관 Gate(SOP)와 QMS 초기유동·레슨런 연결 | P-52 | W1 | 4 |
| PMS-10-DSH-001 | PMS 위젯·역할별 대시보드 템플릿 | P-55 | W1 | 5 |
| PMS-10-DSH-002 | PMO 전체 프로젝트 현황 보드 | P-56 | W1 | 6 |
| PMS-10-DSH-003 | 일간/주간 보고(공장-차종 양식, 비용 권한 분리) | P-57 | W1 | 5 |
| PMS-10-DSH-004 | 의사결정사항 관리 | P-56 | W2 | 3 |
| PMS-11-AIP-001 | 마일스톤 기반 일정 자동 생성·조정 추천 | P-59 | W2 | 7 |
| PMS-11-AIP-002 | 산출물 초안 작성 | P-60 | W2 | 5 |
| PMS-11-AIP-003 | 일정·리소스 조기경보 | P-61 | W2 | 6 |
| PMS-11-AIP-004 | PMS 자연어 Q&A 범위 | P-62 | W2 | 4 |
| PMS-11-AIP-005 | SOR 문서 분해 초안 | P-6, P-60 | W2 | 4 |
| PMS-12-INT-001 | 프로세스 포탈(BPA) 프로세스·액티비티 속성 연계 | P-15, P-41, P-64 | W2 | 5 |
| PMS-12-INT-002 | HR 임율·평가 연계 | P-29, P-70 | W2 | 4 |
| PMS-12-INT-003 | DMS 금형·검사구 비용·수정비 연계 | P-32, P-71 | W2 | 5 |
| PMS-12-INT-004 | 부품개발시스템·PDM·ALM 연계 | P-28, P-64 | W2 | 6 |
| PMS-12-INT-005 | QMS 디지털 스레드(같은 Org: 레슨런·인정시험·초기유동·클레임) | P-21, P-49, P-50, P-64 | W1 | 5 |
| PMS-12-APV-001 | 프로젝트 역할(PROJECT_ROLE) 결재선 해석 | P-65 | W1 | 3 |
| PMS-13-PRF-001 | SOP + 2개월 성과 입력·자동 지표 | P-70 | W2 | 4 |
| PMS-13-PRF-002 | PM·CFT 수평평가·HR 전송 | P-70 | W2 | 4 |
| PMS-13-CHG-001 | 프로젝트 변경 요청·이력(일정·자원·산출물·비용) | P-71 | W2 | 5 |
| PMS-13-CHG-002 | DMS 수정비·부품개발 비용 단계 적용 | P-71 | W3 | 4 |

## 5. 객체 소유(이름 고정)

모든 업무 객체는 `PMS_` 접두어, Name = 사람이 읽는 제목, 업무 번호 = `RecordNo__c` + 채번(ARC-003). 공유 기준은 프로젝트다: 업무 객체는 `PMS_Project__c`의 Master-Detail 하위(또는 Project__c Lookup + Apex 공유)로 두어 CFT 구성원에게 공유한다(PMS-03-CFT-001이 프로젝트 공유를 만든다). 공장 격리(SEC-002)는 `PMS_Project__c.ProdPlant__c` 기준이다.

| 객체 | 소유 WI | 요약 |
| --- | --- | --- |
| PMS_Project__c | PRJ-001 | 프로젝트. RecordNo PRJ-{YYYY}-{SEQ:5}, Customer·Vehicle·ProductGroup·ProjectType(NEW_MODEL, MODEL_YEAR, FACELIFT, DERIVATIVE, CARRY_OVER)·ModelYear·DevSite·ProdPlant·PM·OrderConfirmedDate·SopDate·EopDate·StandardWbs·CurrentPhase(DEV_PHASE)·Status·OverallRag·ScheduleRag·CostRag |
| PMS_ProjectPart__c | PRJ-002 | 프로젝트 품번·사양(MD Project). Item, Variant, IsLeadPart, ProdPlant |
| PMS_CustomerMilestone__c | PRJ-003 | 고객 마일스톤(MD Project). MilestoneCode(CUSTOMER_MILESTONE), PlannedDate, ActualDate, Activity(Lookup PMS_Activity__c) |
| PMS_Requirement__c | SOR-001 | SOR 요구사항(MD Project). RequirementNo, Category, Text, Version, Status, VerificationMethod, IsSafety, IsRegulatory, SourceDocument(CMN_Document), AlmRef |
| PMS_RequirementLink__c | SOR-002 | 요구사항 충족 연결(MD Requirement). TargetType, TargetRecordId(텍스트), Status(PLANNED, VERIFIED, FAILED) |
| PMS_CftMember__c | CFT-001 | CFT 구성원(MD Project). User, Employee, Department, ProjectRole(PROJECT_ROLE), AccessLevel(PM, EDIT, VIEWER), Status(REQUESTED, APPROVED, REJECTED, ACTIVE, RELEASED), ApprovedBy |
| PMS_SecurityPledge__c | CFT-003 | 보안서약서(Lookup CftMember, MD Project). SignedAt, Document, PledgeVersion, Status |
| PMS_EffortPlan__c | EFF-001 | 투입 계획(MD Project). CftMember, Activity, WeekStart, PlannedHours |
| PMS_EffortActual__c | EFF-002 | 투입 실적(MD Project). CftMember, WeekStart, MonHours~SunHours, Status(DRAFT, SUBMITTED, APPROVED, RETURNED) |
| PMS_WbsTemplate__c | WBS-001 | 표준 WBS(사내 공개 읽기). Code, CustomerGroup, ProductGroup, ProjectType, Version, Status(DRAFT, ACTIVE, OBSOLETE) |
| PMS_WbsTemplateActivity__c | WBS-001 | 표준 액티비티(MD Template). ActivityCode, Parent, Level, DevPhase, ActivityType, DurationDays, ResponsibleRole, IsMandatory, IsMilestone, GateCode, AnchorMilestoneCode, ProcessPortalActivityId |
| PMS_WbsTemplateDependency__c | WBS-001 | 표준 선후행(MD Template). Predecessor, Successor, Type(FS, FF, SF, SS), LagDays |
| PMS_WbsTemplateDeliverable__c | WBS-002 | 표준 산출물(MD TemplateActivity). DeliverableCode, DeliverableType(ATTACHMENT, STANDARD_FORM, LINK, APPROVAL, SYSTEM_LINK), DocClass, TemplateDocument, IsMandatory, ApprovalRequired, SystemLinkType, CompletionRuleKey |
| PMS_CompletionRule__mdt | WBS-002 | 완료 조건 규칙. RuleKey, CheckerClass(PMS_CompletionChecker 구현), Description |
| PMS_Activity__c | WBS-003, ACT-001 | 실행 액티비티(MD Project). WbsCode, Parent, Level, DevPhase, ActivityType, PlannedStart/End(기준선), ForecastStart/End, ActualStart/End, DurationDays, TotalFloat, IsCritical, Progress, Status(NOT_STARTED, IN_PROGRESS, COMPLETION_REQUESTED, COMPLETED, FORCE_COMPLETED, CANCELLED), Owner, IsMandatory, IsMilestone, GateCode, Rag |
| PMS_ActivityDependency__c | WBS-004 | 실행 선후행(MD Project). Predecessor, Successor, Type, LagDays |
| PMS_ActivityAssignee__c | ACT-001 | 보조 담당(MD Activity). User |
| PMS_ActivityProgress__c | WBS-007 | 주간 진척(MD Activity). WeekStart, ProgressPct, Comment |
| PMS_ScheduleBaseline__c | WBS-005 | 기준선(MD Project). BaselineNo, ApprovedAt, SnapshotJson |
| PMS_ScheduleChange__c | WBS-006 | 일정 변경(MD Project). ChangeType, Reason, ImpactJson, Status(DRAFT, REQUESTED, APPROVED, REJECTED, APPLIED) |
| PMS_SupplierPartSchedule__c | WBS-010 | 협력사 부품개발 일정(Lookup Project). SupplierItem, MilestoneCode, PlannedDate, ActualDate, ExternalKey |
| PMS_CostBudget__c | CST-001 | 예산(MD Project). Category(TOOLING, EDD, PIECE_PRICE, TRAVEL, CONTINGENCY), PlannedAmount, CurrencyIsoCode 문자열, Basis |
| PMS_CostActual__c | CST-002 | 실적(MD Project). Category, PeriodMonth, Amount, Source(EFFORT_AUTO, DMS, MANUAL, SAP), SourceRef |
| PMS_LaborRate__c | CST-003 | 직급 평균 임율(비공개, 원가 PS만). JobGradeCode, Year, HourlyRate |
| PMS_Deliverable__c | DLV-001 | 실행 산출물(MD Activity). TemplateDeliverable, DeliverableType, Document(CMN_Document), ExternalUrl, SystemLinkType, SystemRecordId, Status(NOT_SUBMITTED, SUBMITTED, IN_APPROVAL, APPROVED, REJECTED, NOT_APPLICABLE), IsMandatory, ApprovalRequired, AnomalyStatus(GAT-005) |
| PMS_DeliverableTrace__c | DLV-003 | 입력/출력 연결(MD Project). FromType, FromRecordId, ToType, ToRecordId, RelationType(INPUT_OF, DERIVED_FROM, VERIFIES) |
| PMS_ImpactAssessment__c | DLV-004 | 영향도 분석(MD Project). SourceDeliverable, AffectedJson, Status |
| PMS_Risk__c | RSK-001 | 리스크(MD Project). Category(RISK_CATEGORY), Probability(1~5), Impact(1~5), Score, Level, Status(OPEN, MITIGATING, CLOSED, OCCURRED), MitigationPlan, Owner, EscalatedAt |
| PMS_RiskReview__c | RSK-001 | 리스크 주/월 검토(MD Risk) |
| PMS_RiskQualityLink__c | RSK-002 | 리스크 ↔ QMS 점검 연결(MD Risk). TargetType, TargetRecordId(텍스트) |
| PMS_Issue__c | ISS-001 | 문제점(MD Project). Status(REGISTERED, ACCEPTED, APPROVAL_REQUESTED, APPROVED, CLOSED, REJECTED), CountermeasureDocument, Risk(Lookup), QMS 원천 텍스트 Id(ClaimRecordId, NcrRecordId, EightDRecordId), IsLessonCandidate |
| PMS_GateDefinition__c | GAT-001 | Gate 정의(사내 공개 읽기). GateCode, DevPhase, Sequence, QuestionnaireFamily, CustomerGroup |
| PMS_GateReview__c | GAT-001, GAT-003 | 프로젝트 Gate(MD Project). GateCode, PlannedDate, ActualDate, Status(PLANNED, PREPARING, IN_REVIEW, APPROVAL, PASSED, CONDITIONAL, FAILED, CANCELLED), ResultRag(GREEN, AMBER, RED), ScorePct, TemplateId·TemplateVersion(질문지 스냅숏), Conditions, FollowUpDue |
| PMS_GateCheckItem__c | GAT-003 | Gate 평가 항목 스냅숏(MD GateReview). ItemKey, ItemNo, Text, IsMandatory, AutoCheckRule, AutoResult(MET, NOT_MET, NA, ERROR), Answer, Score, EvidenceDeliverableIds, Comment |
| PMS_WeeklyReport__c | DSH-003 | 일간/주간 보고(Lookup Project, ProdPlant). ReportType(DAILY, WEEKLY), PeriodStart, Status, CostVisible |
| PMS_Decision__c | DSH-004 | 의사결정사항(MD Project). Meeting(CMN_Meeting), DecidedAt, Status, ActionItem |
| PMS_ProjectPerformance__c | PRF-001 | 성과(MD Project). DueDate(SOP + 2개월), 자동 지표(일정 준수율, 비용 차이율, Gate 1회 통과율, 양산 초기 NCR·클레임 수), Status |
| PMS_PeerEvaluation__c | PRF-002 | 수평평가(MD Performance, 비공개). Evaluator, Evaluatee, Scores, HrSyncStatus |
| PMS_ProjectChange__c | CHG-001 | 프로젝트 변경(MD Project). ChangeType(SCHEDULE, RESOURCE, DELIVERABLE, COST, SCOPE), Status, ImpactSummary, DmsRef |

**공통 질문지 템플릿(새 CMN WI)**: Gate 평가표는 `CMN-00-QNR-001 표준 질문지 템플릿`의 `CMN_QuestionnaireTemplate__c`(Domain = GATE), `CMN_QuestionnaireItem__c`, `CMN_QuestionnaireGradeRule__c`를 쓴다. QMS 심사 질문지(Vol.6c IAU-001)도 같은 객체로 옮긴다(Domain = AUDIT). 근거와 결정은 6절.

## 6. 표준 질문지 판(版)을 받아 템플릿으로 관리하는 방식(검토 결과·권고)

**질문**: 표준 질문지(VDA 6.3, IATF 16949 시스템 심사, 고객 Gate·APQP 점검표, SL 신제품개발 Gate 평가표)를 판째 받아 시스템 템플릿으로 등록해 쓰는 것이 좋은가.

**권고: 받는다.** 판을 그대로 "버전 템플릿"으로 등록하고, 심사·Gate 평가는 시작 시점의 판을 스냅숏으로 복사해 쓴다. 템플릿 엔진은 CMN-00 공통으로 하나만 둔다.

| 근거 | 내용 |
| --- | --- |
| 개정이 잦다 | 신제품개발 회사표준이 26.11~27.04에 개정되고(PMS 구축 착수 27.01과 겹침) Gate 평가표가 그 결과로 바뀐다. IATF 16949 2판(2027 예정), VDA 6.3 개정판도 들어온다. 질문을 화면·코드에 넣으면 개정마다 개발이 필요하다 |
| 재현성 | 감사·고객 심사에서 "그때 어떤 판의 어떤 질문으로 판정했나"를 보여야 한다. 진행 중 평가는 시작한 판을 끝까지 쓰고, 새 판은 다음 평가부터 적용한다 |
| 비교 | 판 사이 문항 대응(같음·바뀜·새 문항·삭제)을 템플릿에 두면 판이 바뀌어도 프로젝트·심사 간 점수 추세를 비교할 수 있다 |
| 저작권 | VDA·AIAG 원문은 SL이 라이선스로 확보한 판을 SL이 입력한다(D6C-2, DS-6). 개발 산출물에 원문을 넣지 않는다. 받은 원문 파일은 문서(CMN-00-DOC-001)로 템플릿에 붙인다 |
| 같은 엔진 | 질문지 판 관리·가져오기·활성화·스냅숏·등급 규칙은 QMS 심사, 자체 평가, LPA, PMS Gate가 똑같이 쓴다. Vol.0 2절 공통 판정 기준 (2)에 해당하므로 CMN-00으로 옮긴다 |

**받는 단위**: Family(질문지 계열, 예: `SL-GDP-G5`, `VDA63-PROC`, `IATF-SYS`, `CUST-GATE-BMW-RG3`) × 판(StandardEdition, 예: "VDA 6.3 2023", "SL 신제품개발 Rev02") × 시스템 버전(Version, 오탈자·안내 수정까지 포함해 1씩 증가). 판이 바뀌면 같은 Family의 새 Version으로 받고 `EditionChange__c = true`로 표시한다.

**받는 방법**: 품질경영팀(QMS)·PMO(PMS)가 CSV(문항 번호·요소·문구 3개 언어·안내·답 형태·배점·필수·자동 점검 규칙 키·이전 판 문항 키)로 DRAFT에 넣고, 시뮬레이터로 확인한 뒤 활성화한다. 원문 파일과 발효일을 함께 등록한다.

**하지 않는 것**: 프로젝트마다 질문을 새로 쓰는 방식(비교·재현 불가), 코드·초기 데이터 스크립트에 질문·등급 숫자를 넣는 방식(개정 때 개발 필요, 저작권 위험).

**반영**: Vol.0에 `CMN-00-QNR-001`(공통 템플릿)을 추가하고, Vol.6c IAU-001을 "QMS 심사 질문지 설정(CMN 템플릿 사용)"으로 바꾸며, PMS Gate는 PMS-09-GAT-002·003이 같은 템플릿을 쓴다.

## 7. 공통 재사용(다시 만들지 않는 것)

| 기능 | CMN WI | PMS 사용처 |
| --- | --- | --- |
| 결재 | APV-001~005 | 일정 확정·변경, 산출물, Gate, CFT 승인, 투입 실적 승인(PM), 과제 종료, 변경 요청. PROJECT_ROLE 해석은 PMS-12-APV-001 |
| To-Do·포탈 | TDO-001~004, UX-007 | 액티비티 To-Do(P-19), 승인 요청, 성과 입력 알림 |
| 알림 | NTF-001 | 일정 확정·변경 메일(P-17·18·22·23), 여유시간 경고, SOP 초과 |
| 문서 | DOC-001, AI-002·003 | 산출물 파일·리비전·버전 비교(P-39·58), 표준 양식(P-36) |
| 회의 | MTG-001 | 회의록(P-40), 설계 검토(DR), 의사결정사항 |
| 화면 부품 | UX-003·004·005·006·009 | 코멘트(P-47), 업무 레코드 표준, 상태별 버튼, 그리드(투입 계획·예산·표준 WBS·CFT), Gate 평가표(체크리스트 셸 + PMS Provider) |
| 대시보드 | DSH-001 | PMS 위젯 콘텐츠(PMS-10) |
| AI | AI-001·002·003·004·005 | UseCase PMS_SCHEDULE, PMS_DELIVERABLE_DRAFT, PMS_EW(정의됨), PMS_SOR_EXTRACT·PMS_DOC_ANOMALY(Vol.0 변경 요청) |
| 질문지 템플릿 | QNR-001(신규) | Gate 평가표 |
| 기준정보 | MDM-001~007 | 고객·차종·제품군·품번·공장·부서·임직원, 공통 코드 |

## 8. QMS 접점(같은 Org 가정, D-1)

PMS는 QMS 객체를 Lookup하지 않는다(텍스트 Id + 서비스·게이트웨이·이벤트). QMS도 PMS 객체를 Lookup하지 않는다.

| 접점 | QMS 쪽 계약(이미 정의) | PMS 쪽 구현(이 Vol.들) |
| --- | --- | --- |
| 레슨런 체크포인트 추천·반영 | `QMS_LeleApplicationService.propose`, `QMS_LeleRecommendService`(Vol.4 LEL-005, Vol.8 AIQ-007·008), 매칭 키 DEV_PHASE·DEV_ACTIVITY_TYPE | 표준 WBS 액티비티에 두 코드 속성(WBS-001), WBS 확정·액티비티 착수 시 호출(INT-005), 액티비티 페이지에 `qmsLeleAiRecommend` 배치 |
| 액티비티 완료 조건 | `QMS_LeleApplicationService.hasOpenMandatory(activityId)`(Vol.4 LEL-005 BR-6), 인정시험 판정 `QMS_QualPlanEvent__e` JUDGED·FinalResult(Vol.2 DVQ-005) | 완료 조건 규칙 키 `QMS_LELE_NO_OPEN_MANDATORY`, `QMS_QUAL_PASS`(D2-4 CONDITIONAL 허용 여부는 결정 대기) — ACT-004 |
| 인정시험 의뢰 | Vol.2 DVQ-005 `createFromSource`(TriggerType NEW_DEV, SourceObject PMS_Activity__c) | DV·PV 액티비티 착수 시 게이트웨이 QUALIFICATION 호출(INT-005) |
| 양산 이관 | Vol.4 EFC-001 `createFromSource(PRODUCT, NEW_PRODUCT, sopDate, sourceId = Gate Id)` | SOP Gate 통과 시 호출(GAT-006) |
| 클레임·NCR·8D·레슨런 | `QMS_ClaimEvent__e`, `QMS_NcrEvent__e`, LESSON_LEARNED 게이트웨이(Vol.9 INT-021 BR-6과 같은 계약) | 프로젝트 품번 관련 이벤트 구독·문제점 연결, 문제점 "레슨런 후보" 종결 시 게이트웨이 요청(ISS-002) |
| 수평전개 대상 | Vol.4 HZD `TargetProjectId__c` 텍스트 | 프로젝트 검색 API 제공(INT-005) |
| 성과 지표 | NCR·클레임 KPI(CMN_KpiValue__c) | SOP 후 초기 NCR·클레임 수 자동 채움(PRF-001) |

## 9. 이벤트(정의 이름 고정)

`PMS_ProjectEvent__e`(CREATED, STATUS_CHANGED, SOP_CONFIRMED, CLOSED), `PMS_ActivityEvent__e`(STARTED, COMPLETION_REQUESTED, COMPLETED, REOPENED, DATES_CHANGED), `PMS_GateEvent__e`(SCHEDULED, PASSED, CONDITIONAL, FAILED), `PMS_IssueEvent__e`(CREATED, CLOSED, LESSON_CANDIDATE). 발행 측은 구독을 구현하지 않는다.

**환경 제약**: 개발 Scratch Org(Developer 에디션)는 플랫폼 이벤트 정의가 5개로 제한되고 CMN이 5개를 쓴다. 2026-11-06 Scratch 정의를 Enterprise 에디션으로 바꿨다(결정 D-P8 적용, Enterprise 이벤트 정의 한도 50).

## 10. 권한(PSG 이름 고정)

`PMS_PSG_PM`(프로젝트 생성·WBS·CFT 요청·승인), `PMS_PSG_CFT`(담당 액티비티·산출물·투입 실적), `PMS_PSG_TeamLead`(CFT 할당 승인, 산출물 결재 필수 결재자), `PMS_PSG_PMO`(전체 조회·표준 WBS·Gate 정의·평가표), `PMS_PSG_Finance`(임율·비용 원문), `CMN_PSG_Executive`(경영 대시보드). 비용 정보는 PS `PMS_PS_Cost_Read`가 있어야 보인다(P-57 "Cost 정보 권한 분리").

## 11. 설계 결정(Vol. 검토 요청에 넣는 항목)

| ID | 결정 | 권고 |
| --- | --- | --- |
| D-P1 | 신제품개발 단계 모델(10단계 가정)과 Gate 수·이름 | 회사표준 개정 결과를 DEV_PHASE·PMS_GateDefinition__c 데이터로 받는다(개정 전 가정 값으로 개발) |
| D-P2 | Gantt 화면 자산 | 연구소 PMS 간트 자산(DKBMC 사전 보유, 별도 패키지 ARC-001) 재사용. 상용 라이브러리는 외부 JS 승인 목록 밖이라 사용자 승인 필요 |
| D-P3 | 일정 엔진 위치 | Apex CPM(프로젝트당 액티비티 약 2,000개까지, 비동기 Queueable). 다프로젝트 부하·조기경보 집계는 Snowflake |
| D-P4 | 투입 실적 입력 단위 | 사용자 × 프로젝트 × 주 1행(요일별 7칸). 일별 행은 만들지 않는다(데이터량) |
| D-P5 | 비용 통화 | Multi-Currency 결정(D-3) 전까지 금액 + 통화 코드 텍스트, 환산은 Snowflake |
| D-P6 | Gate 평가표 판 관리 | 6절 권고(CMN-00-QNR-001 공통 템플릿, 시작 시점 스냅숏) |
| D-P7 | 산출물 파일 저장 위치 | DOC-001 결정(D-7)을 따른다. 도면은 PDM 링크(SYSTEM_LINK) |
| D-P8 | Scratch·Sandbox 에디션 | 적용(2026-11-06, 사용자 지시): Scratch 정의를 Enterprise로 바꾸고 개발 Org를 새로 만들었다 |
| D-P9 | PMS·QMS 같은 Org(D-1) | 같은 Org 전제로 쓴다. 다른 Org면 Vol.9 INT-021 경로 |
