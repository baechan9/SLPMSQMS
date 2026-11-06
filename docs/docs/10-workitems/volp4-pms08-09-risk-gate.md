# SL PMS 워크아이템 Vol.P4 — PMS-08 리스크·문제점, PMS-09 Gate

Nov 6, 2026 · @배창욱

## 1. 개요

Vol.P4는 PMS RFP의 **3.8 리스크/문제점 관리(P-48~51)**와 **3.9 Gate 관리(P-52~54)**를 11개 워크아이템으로 내린다. 리스크(RSK)와 문제점(ISS)은 프로젝트 기간 내내 상시로 관리하는 기록이고, Gate(GAT)는 개발 단계를 닫을 때마다 "다음 단계로 가도 되는가"를 판정하는 관문 심사다. 두 메뉴는 Gate 평가에서 만난다. Gate 평가표의 자동 점검이 미결 High 리스크와 미결 문제점을 확인하고, 조건부 통과의 후속 조치는 리스크로 넘길 수 있다.

번호·객체·상태값·이벤트 이름은 `pms-architecture.md`(PMS 계약)를 그대로 쓴다. 계약 5절 표는 요약이므로 이 Vol.이 소유 객체에 더하는 필드는 계약 변경이 아니다. 계약에 없는 새 객체·메타데이터·클래스·코드 그룹은 `(제안)`으로 표시하고 9절 변경 요청에 모았다.

**도메인 정의**

- **리스크(Risk)**: 아직 일어나지 않았지만 일어나면 일정·비용·품질·고객 대응에 영향을 주는 사건. "원인 → 사건 → 영향" 한 문장으로 쓰고, 발생 가능성(Probability 1~5)과 영향도(Impact 1~5)를 곱한 점수로 등급을 정한다. 기존 RISK Management Log(엑셀)의 유형·코드·속성·진행 상태를 그대로 옮긴다(P-48). PM이 주·월 단위로 다시 평가하고 High 리스크는 상위로 올린다(P-50).
- **FMEA와의 관계**: FMEA의 S(심각도)·O(발생도)·D(검출도)와 AP(조치 우선순위 H·M·L)는 설계·공정 고장 모드 단위의 분석이고, 프로젝트 리스크는 프로젝트 목표 단위의 관리 기록이다. 품질·기술 리스크에는 관련 FMEA 항목과 AP를 참고 값으로 남기고, AP H인 고장 모드에서 나온 리스크는 등급 하한을 둔다(RSK-001 BR-4). FMEA 점수로 리스크 점수를 대신하지 않는다.
- **문제점(Issue)**: 이미 일어난 문제. 등록 → 접수(대책서 작성) → 승인 요청 → 승인 → 종결 절차를 밟는다(P-49). 리스크가 실제로 일어나면 문제점으로 전환한다(리스크 OCCURRED).
- **6pi·8D·품질 이력 단일화(P-49)**: 개발 중 문제가 QMS 클레임·부적합(NCR)으로도 등록되면 대책서는 QMS 8D(HKMC 고객은 6pi 양식) 하나로 쓰고, PMS 문제점은 그 8D를 가리킨다. 같은 대책을 두 시스템에 두 번 쓰지 않는다.
- **Gate**: 개발 단계의 출구 관문(G0~G9, 단계 모델은 D-P1). PM이 산출물·평가표를 준비하고 PMO가 진행하며, 평가 결과(달성률·RAG)를 결재로 확정한다. 결과는 통과(PASSED), 조건부 통과(CONDITIONAL: 조치와 기한을 붙여 다음 단계 진행 허용), 실패(FAILED: 재심사)다.
- **Gate 평가표**: SL 신제품개발 회사표준 Gate 평가표와 고객 Gate 점검표를 판(版)째 받은 버전 템플릿(CMN-00-QNR-001, Domain GATE)이다. 평가는 시작 시점의 판을 스냅숏으로 복사해 끝까지 쓴다(D-P6).
- **자동 점검**: 평가표 문항마다 규칙 키(예: DELIVERABLE_APPROVED)를 두어 "산출물이 등록됐나, 결재됐나, QMS 조건을 만족하나"를 시스템 데이터로 먼저 판정한다(P-54 "시스템 등록 산출물 자동 체크").
- **이상 징후(거짓 문서 판별의 범위)**: 문서의 진위를 판정하지 않는다. 빈 양식, 다른 프로젝트 파일 복사(같은 해시), 프로젝트·차종·날짜 불일치, 필수 항목 누락, 다른 시스템 데이터와 불일치(성적서는 합격인데 QMS 인정시험 기록이 없음) 같은 신호를 찾아 "검토 필요"로 표시하고 검토자에게 알린다. 자동으로 불합격시키지 않는다(GAT-005).
- **양산 이관 Gate(SOP Gate)**: 양산 준비 완료(Run@Rate 증빙, 고객 승인, 미결 문제 정리)를 확인하는 마지막 Gate. 통과하면 QMS 제품 초기유동(EFC)을 자동으로 만들고 미결 문제점·리스크를 레슨런 후보로 넘긴다(GAT-006).
- **RAG**: GREEN(계획대로), AMBER(주의, 조건부), RED(실패·중대 미충족). Gate RAG는 평가표의 등급 규칙(달성률 구간 + 필수 미충족 강등)으로만 계산한다.

**선행 공통 WI**: ARC-002·003, MDM-001·003·004·007, SEC-001·002·003, UX-003·004·005·006·009, QNR-001, APV-001·002·003, TDO-001, NTF-001, DOC-001, MTG-001, DSH-001, AI-001·004.

**선행 PMS WI(계약 기준, 다른 Vol.)**: PMS-02-PRJ-001·002·003(프로젝트·품번·고객 마일스톤), PMS-03-CFT-001(CFT·프로젝트 공유), PMS-04-WBS-001·002·003(표준 WBS·산출물·완료 규칙, 실행 WBS), PMS-07-ACT-001·004(액티비티, 완료 조건), PMS-06-DLV-001·002(산출물·결재), PMS-12-APV-001(PROJECT_ROLE 결재선), PMS-12-INT-005(QMS 디지털 스레드 구독).

**다른 메뉴와의 경계**

| 연결 대상 | 이 Vol.이 하는 것 | 상대 메뉴가 하는 것 |
| --- | --- | --- |
| 프로젝트·마일스톤 (PMS-02) | Gate 일정을 고객 마일스톤과 묶어 표시, PMS_GateEvent__e 발행 | 이벤트 구독으로 현재 단계(CurrentPhase) 전진, SOP 확정 이벤트(PRJ-001, 9절 요청) |
| 일정·액티비티 (PMS-04·07) | WBS Gate 마일스톤(GateCode)으로 Gate 일정 생성·동기화, 단계 범위 액티비티의 완료 조건 판정 결과 사용 | 마일스톤 액티비티 GateCode·DevPhase, PMS_ActivityEvent__e 발행, 완료 조건 규칙(PMS_CompletionChecker) |
| 산출물 (PMS-06) | 산출물 등록·결재 상태 자동 점검, 이상 징후 상태(AnomalyStatus) 필드와 탐지 | 산출물 등록·결재·리비전 |
| 대시보드·AI (PMS-10·11) | 리스크·문제점 위젯 2개, Gate 요약 조회 서비스, 리스크 생성 서비스 | PMO 보드(DSH-002)에서 사용, 조기경보(AIP-003)가 리스크 후보 생성 |
| QMS 레슨런 (QMS-04 LEL) | 리스크 경감 ↔ 레슨런 체크포인트·반영 검토 연결, 레슨런 후보 요청(LESSON_LEARNED 게이트웨이), Gate 자동 점검 QMS_LELE_NO_OPEN_MANDATORY | 매칭·반영 검토 서비스, 레슨런 생성 |
| QMS 클레임·8D (QMS-05) | QMS_ClaimEvent__e·QMS_EightDEvent__e 수신으로 문제점 생성·상태 반영, 8D를 대책서로 사용 | 클레임·8D·6pi 보고서 |
| QMS 부적합 (QMS-06 NCR) | 문제점에서 NCR 요청(NCR 게이트웨이), QMS_NcrEvent__e 수신 | NCR 생성·원천 Id 회신(QMS_NcrSourceConfig__mdt) |
| QMS 인정시험 (QMS-02) | 자동 점검 QMS_QUAL_PASS(완료 조건 규칙 위임), 이상 징후 "성적서 합격·QMS 기록 없음" 대조 | 판정 결과·getStatusBySource |
| QMS 초기유동 (QMS-04 EFC) | SOP Gate 통과 시 createFromSource(PRODUCT, NEW_PRODUCT) 호출 | 초기유동 계획·출하검사 강화 |

**앞 Vol. 상태**: Vol.0·2~9는 검토 대기, Vol.P1~P3·P5·P6은 이 Vol.과 함께 작성 중이다. 다른 PMS Vol.의 필드 이름은 계약(`pms-architecture.md` 5절)만 믿고 쓰며, 계약에 없는 의존은 9절 "다른 PMS Vol. 변경 요청"으로 남겼다.

## 2. 업무 흐름

    [리스크]  등록(PM·CFT, 엑셀 로그 붙여넣기) → P×I 점수·등급 → High면 에스컬레이션 1단계(PM·PMO·팀장)
              → 주간(High)·월간 검토(그리드 일괄 입력, 검토 이력) → 경감 대책 ↔ QMS 레슨런 체크포인트·반영 검토 연결
              → 종결(경감 완료·미발생·수용·전가) 또는 발생 → 문제점 전환
    [문제점]  등록(수동·리스크 발생·QMS 클레임/NCR 이벤트) → 접수(PM: 담당·기한) → 대책서(직접 작성 또는 QMS 8D/6pi)
              → 승인 요청(결재) → 승인 → 실행·효과 확인 → 종결 → (레슨런 후보면) QMS 레슨런 요청
    [Gate]    WBS Gate 마일스톤 → Gate 일정 생성(PLANNED) → D-14 준비(PREPARING, 사전 점검)
              → 평가 시작(IN_REVIEW): 발효 중 평가표 판 스냅숏(SL 표준 + 고객 점검표) → 자동 점검(산출물·QMS·리스크·문제점)
              → 이상 징후 "검토 필요" 확인 → 체크리스트 평가(UX-009) → 달성률·RAG 계산
              → 결재(APPROVAL) → 통과 / 조건부(후속 조치·기한) / 실패(재심사 Round + 1)
              → PMS_GateEvent__e → (SOP Gate) QMS 초기유동 생성·미결 문제 정리·레슨런 후보

## 3. 데이터 모델 개요

| 객체 | 구분 | 관계 | 역할 | 정의 WI |
| --- | --- | --- | --- | --- |
| PMS_Risk__c | 업무 | Project(MD), Activity·ProjectPart(Lookup) | 리스크 1건(RISK Management Log 1행) | RSK-001 |
| PMS_RiskReview__c | 업무 | Risk(MD) | 주·월 검토 1회분 스냅숏 | RSK-001 |
| PMS_RiskQualityLink__c | 업무 | Risk(MD) | 리스크 ↔ QMS 선행 품질 점검(텍스트 Id) | RSK-002 |
| PMS_Issue__c | 업무 | Project(MD), Risk·Activity·ProjectPart(Lookup) | 문제점 1건, QMS 클레임·NCR·8D 텍스트 Id | ISS-001 |
| PMS_GateDefinition__c | 설정 | — | Gate 정의(코드·단계·평가표 Family, 고객 그룹 덮어쓰기) | GAT-001 |
| PMS_GateReview__c | 업무 | Project(MD), GateDefinition·Activity·CustomerMilestone(Lookup) | 프로젝트 Gate 1회차(일정·평가·결정) | GAT-001, GAT-003, GAT-004 |
| PMS_GateCheckItem__c | 업무 | GateReview(MD) | 평가표 문항 스냅숏·자동 점검·답 | GAT-003 |
| PMS_GateCheckRule__mdt (제안) | 설정 | — | 자동 점검 규칙 키 등록부(키·인자 형식·점검 클래스) | GAT-002 |
| PMS_DeliverableAnomaly__c (제안) | 업무 | Deliverable(MD) | 산출물 이상 징후 신호 1건 | GAT-005 |
| PMS_AnomalyRule__mdt (제안) | 설정 | — | 이상 징후 규칙(신호 종류·대상 DocClass·사용 여부) | GAT-005 |

**상태값**

| 대상 | 값(순서) |
| --- | --- |
| PMS_Risk__c.Status__c | OPEN → MITIGATING → CLOSED / OCCURRED (OPEN에서도 CLOSED·OCCURRED 가능) |
| PMS_Risk__c.Level__c | HIGH · MEDIUM · LOW (서비스 계산) |
| PMS_Issue__c.Status__c | REGISTERED → ACCEPTED → APPROVAL_REQUESTED → APPROVED → CLOSED / REJECTED(REGISTERED·ACCEPTED에서) |
| PMS_GateReview__c.Status__c | PLANNED → PREPARING → IN_REVIEW → APPROVAL → PASSED / CONDITIONAL / FAILED · CANCELLED |
| PMS_GateReview__c.ResultRag__c | GREEN · AMBER · RED |
| PMS_GateCheckItem__c.AutoResult__c | MET · NOT_MET · NA · ERROR |
| PMS_Deliverable__c.AnomalyStatus__c | NONE · REVIEW_REQUIRED · CONFIRMED_OK · CONFIRMED_ISSUE |
| PMS_DeliverableAnomaly__c.Status__c (제안) | OPEN → DISMISSED / CONFIRMED |

**공통 기반 등록(각 객체 정의 WI에서 수행)**

| 항목 | 리스크(RSK-001) | 문제점(ISS-001) | Gate(GAT-001) |
| --- | --- | --- | --- |
| 채번(ARC-003) | RSK-{YYYY}-{SEQ:6} | ISS-{YYYY}-{SEQ:6} | GTR-{YYYY}-{SEQ:6} |
| 공유 | 프로젝트 MD(CFT-001 공유 상속) | 프로젝트 MD | 프로젝트 MD, 정의는 사내 공개 읽기 |
| 삭제 통제(SEC-003) | OPEN이고 검토 이력 0건일 때 등록자·PM만 | REGISTERED만 | PLANNED이고 평가 항목 0건일 때 PMO만 |
| 상태 진행바(UX-003) | CMN_StatusFlow__mdt 등록 | 등록 | 등록 |
| 상태·권한 규칙(UX-005) | `meta-src/ui-rules/PMS_Risk__c.json` | `PMS_Issue__c.json` | `PMS_GateReview__c.json` |
| 필드 이력 | Status, Probability, Impact, Level, Owner, DueDate | Status, Owner, DueDate, Severity | Status, PlannedDate, ResultRag, ScorePct |
| DWH 복제(DWH-002) | 15분 | 15분 | 15분(CheckItem 포함) |
| 번역 | ko·en_US·zh_CN | 같음 | 같음 |

**공통 코드(Vol.0 MDM-007 변경 요청)**

| 그룹 | 레벨 | 초기 값(SL 현행 RISK Management Log 코드로 교체) |
| --- | --- | --- |
| RISK_CATEGORY (제안) | 2 | SCHEDULE 일정(고객 일정 변경, 내부 지연), COST 비용(투자 초과, 원가), QUALITY 품질(신뢰성, 외관, 광학), TECHNICAL 기술(신기술, 설계 난이도), SUPPLIER 협력사(개발 능력, 금형), CUSTOMER 고객(사양 변경, 승인 지연), RESOURCE 자원(인력, 설비), REGULATORY 법규·인증 |
| ISSUE_TYPE (제안) | 2 | DESIGN 설계, TEST 시험·검증, SUPPLIER_PART 협력사 부품, TOOLING 금형·설비, PROCESS 공정·조립, CUSTOMER 고객 요구·변경, SCHEDULE 일정, COST 비용, SOFTWARE 소프트웨어, OTHER |
| DOC_CLASS 값 추가 | 1 | ISSUE_COUNTERMEASURE 문제점 대책서, GATE_MINUTES Gate 회의록, RUN_AT_RATE Run@Rate 증빙, LAUNCH_READINESS 양산 준비 점검 결과 |
| APPROVAL_ROLE 값 추가 | 1 | PMO_MANAGER PMO 팀장, BU_HEAD 사업부장(연구소장) |
| MEETING_TYPE 값 확인 | 1 | GATE_REVIEW(MTG-001 예시에 있음, 코드 값 확정) |

**결재 유형(APV-001 CMN_ApprovalType__mdt)**

| TypeCode | 대상 | 정의 WI | LockOnSubmit / KeepLocked |
| --- | --- | --- | --- |
| PMS_ISSUE_COUNTERMEASURE | PMS_Issue__c | ISS-001 | true / false |
| PMS_GATE_REVIEW | PMS_GateReview__c | GAT-004 | true / true(결정 후 잠금 유지) |
| PMS_GATE_WAIVE | PMS_GateReview__c(생략) | GAT-001 | true / true |

**알림 EventCode(NTF-001)·To-Do SourceType(TDO-001)**

| 종류 | 이름 | 정의 WI |
| --- | --- | --- |
| 알림 | PMS_RISK_HIGH, PMS_RISK_ESCALATED, PMS_RISK_REVIEW_DUE | RSK-001 |
| 알림 | PMS_ISSUE_REGISTERED, PMS_ISSUE_OVERDUE, PMS_ISSUE_RESULT | ISS-001 |
| 알림 | PMS_ISSUE_QMS_LINKED | ISS-002 |
| 알림 | PMS_GATE_PREPARING, PMS_GATE_MILESTONE_MISSING | GAT-001 |
| 알림 | PMS_GATE_RESULT, PMS_GATE_FOLLOWUP_OVERDUE | GAT-004 |
| 알림 | PMS_GATE_ANOMALY | GAT-005 |
| 알림 | PMS_SOP_HANDOVER_FAILED | GAT-006 |
| To-Do | PMS_RISK_REVIEW, PMS_RISK_PLAN | RSK-001 |
| To-Do | PMS_ISSUE_ACCEPT, PMS_ISSUE_COUNTERMEASURE, PMS_ISSUE_CLOSE | ISS-001 |
| To-Do | PMS_GATE_PREPARE, PMS_GATE_MILESTONE_MISSING | GAT-001 |
| To-Do | PMS_GATE_EVALUATE | GAT-003 |
| To-Do | PMS_GATE_ANOMALY_REVIEW | GAT-005 |
| To-Do | PMS_SOP_HANDOVER | GAT-006 |

**권한 셋(이 Vol.이 만드는 PS와 PSG 매핑)**

| PS | 내용 | PSG(계약 10절) |
| --- | --- | --- |
| PMS_PS_Risk_Read / PMS_PS_Risk_Edit | 리스크·검토·QMS 연결 조회 / 등록·편집 | Read: CMN_PSG_Executive, PMS_PSG_TeamLead · Edit: PMS_PSG_PM, PMS_PSG_CFT, PMS_PSG_PMO |
| PMS_PS_Issue_Read / PMS_PS_Issue_Edit | 문제점 조회 / 등록·대책서 작성 | Read: CMN_PSG_Executive, PMS_PSG_TeamLead · Edit: PMS_PSG_PM, PMS_PSG_CFT, PMS_PSG_PMO |
| PMS_PS_Gate_Read | Gate 일정·결과·평가 항목 조회 | 모든 PMS PSG, CMN_PSG_Executive |
| PMS_PS_Gate_Evaluate | 평가 시작·답 입력·자동 점검 실행·상신 | PMS_PSG_PM, PMS_PSG_PMO, PMS_PSG_CFT(분담 문항 답만, Provider 판정) |
| PMS_PS_Gate_Admin | Gate 정의·자동 점검 규칙 확인·이상 징후 규칙 | PMS_PSG_PMO(+ CMN_PS_Questionnaire_Admin, Custom Permission CMN_QnrAdmin_Gate) |

**Custom Permission(UX-005 명명)**: PMS_RSK_Escalate(2단계 에스컬레이션), PMS_RSK_Close(타인 리스크 종결), PMS_ISS_Accept(접수·반려), PMS_ISS_Close(종결), PMS_GATE_Start(평가 시작·재심사), PMS_GATE_Decide(결정 상신), PMS_GATE_Waive(생략 요청), PMS_GATE_AnomalyReview(이상 징후 판정).

**KPI 키(CMN_KpiValue__c, Snowflake `MART.V_SF_KPI_PMS_RISK_GATE` (제안))**

| 키 | 정의 | 주기 | 차원 | 계산 위치 |
| --- | --- | --- | --- | --- |
| PMS_RISK_OPEN | 미종결 리스크 수(OPEN·MITIGATING) | 일 | ProdPlant, Project | Snowflake |
| PMS_RISK_HIGH_OPEN | 미종결 HIGH 리스크 수 | 일 | ProdPlant, Project | Snowflake |
| PMS_ISSUE_OPEN | 미종결 문제점 수(REGISTERED~APPROVED) | 일 | ProdPlant, Project, IssueType | Snowflake |
| PMS_ISSUE_CLOSE_RATE | 월 기한 도래 문제점 중 기한 내 종결 비율 % | 월 | ProdPlant | Snowflake |
| PMS_GATE_FIRST_PASS_RATE | 결정된 Gate 중 Round 1에서 PASSED 비율 % | 월 | ProdPlant, GateCode | Snowflake |
| PMS_GATE_CONDITION_OVERDUE | 기한 경과 조건부 후속 조치 수 | 일 | ProdPlant | Snowflake |

실시간 건수(내 프로젝트의 미결 건)는 위젯이 Salesforce 집계 SOQL로 읽고, 추세는 위 KPI를 읽는다(DSH-001 BR-5).

**이 Vol.이 다른 메뉴에 제공하는 계약**

| 이름 | 종류 | 정의 WI | 사용처 |
| --- | --- | --- | --- |
| PMS_RiskService.createFromSource / getStatusBySource / markOccurred | Apex | RSK-001 | ISS-001(발생 전환), GAT-004(조건 → 리스크), PMS-11-AIP-003(조기경보) |
| PMS_IssueService.createFromSource / getStatusBySource | Apex | ISS-001 | ISS-002(QMS 이벤트), RSK-001 화면(발생 처리), GAT-006 |
| PMS_IssueEvent__e(CREATED, CLOSED, LESSON_CANDIDATE) | Platform Event | ISS-001, ISS-002 | PMS-10, PMS-12-INT-005(다른 Org 중계) |
| PMS_LessonCandidateService (제안) | Apex | ISS-002 | RSK-002, GAT-006 |
| PMS_IssueQmsService.handleClaimEvents / handleNcrEvents / handleEightDEvents (제안) | Apex | ISS-002 | PMS-12-INT-005 구독 트리거 |
| PMS_RiskQualityService.getRisksByQmsTarget (제안) | Apex | RSK-002 | QMS-04 LEL 화면(선택) |
| PMS_GateEvent__e(SCHEDULED, PASSED, CONDITIONAL, FAILED) | Platform Event | GAT-001, GAT-004 | PMS-02-PRJ-001, PMS-07-ACT-004, PMS-10, PMS-13-PRF-001 |
| PMS_GateQueryService (제안) | Apex | GAT-001 | PMS-10-DSH-002 PMO 보드, PMS-07-ACT-004(마일스톤 완료 조건) |
| PMS_GateChecklistProvider | CMN_ChecklistProvider 구현 | GAT-003 | UX-009 셸 |
| PMS_GateRagScorer (제안) | CMN_QuestionnaireScorer 구현(Scheme GATE_RAG) | GAT-002 | QNR-001 시뮬레이터, GAT-003 |
| PMS_GateAutoCheckService, PMS_GateAutoChecker (제안) | Apex | GAT-003 | GAT-001 사전 점검, GAT-006 |
| PMS_GateQuestionnaireUsageCheck (제안) | CMN_QuestionnaireUsageCheck 구현 | GAT-003 | QNR-001 BR-10 |
| PMS_AnomalyDetectionService (제안) | Apex | GAT-005 | GAT-003, PMS-06 산출물 화면 |
| CMN_AiRecommendation__c UseCase PMS_DOC_ANOMALY | AI 기록 | GAT-005(Vol.0 변경 요청) | AI-004 |

## 4. 리스크 (RSK-001~003)

### PMS-08-RSK-001 리스크 로그(정량 평가·주/월 검토·에스컬레이션)

추적 P-48, P-50 · 필수 · W1 · SF · DM, APEX, LWC · Customization · 선행 PMS-02-PRJ-001, PMS-02-PRJ-002, PMS-03-CFT-001, PMS-04-WBS-003, ARC-003, MDM-007, SEC-002, SEC-003, UX-003, UX-004, UX-005, UX-006, TDO-001, NTF-001 · 6 M/D

**목적**: 프로젝트마다 엑셀로 관리하던 RISK Management Log를 프로젝트 하위 레코드로 옮겨, PM이 주·월 단위로 같은 기준(발생 가능성 × 영향도)으로 다시 평가하고 High 리스크가 PMO·팀장에게 자동으로 올라가게 한다. 검토 이력이 남아야 "언제부터 위험했고 무엇을 했는가"를 Gate와 고객 보고에서 보일 수 있다.

**범위** In: 리스크·검토 객체, 점수·등급 계산, 리스크 로그 그리드와 일괄 검토, 검토 주기 To-Do, 에스컬레이션 2단계, 종결·발생 서비스, 생성 서비스(다른 WI용), 레코드 페이지. Out: QMS 점검 연결(RSK-002), 대시보드 위젯(RSK-003), 발생 시 문제점 생성(PMS-08-ISS-001이 이 WI의 markOccurred 호출), 조기경보 탐지(PMS-11-AIP-003), 의사결정 기록(PMS-10-DSH-004).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_Risk__c.Project__c | Master-Detail(PMS_Project__c) | Y | 공유 기준(CFT-001) |
| PMS_Risk__c.RecordNo__c | Text(40), Unique, External ID | Y | RSK-{YYYY}-{SEQ:6}(ARC-003) |
| PMS_Risk__c.Name | Text(80) | Y | 짧은 제목(예: "렌즈 금형 T1 지연") |
| PMS_Risk__c.Description__c | Long Text(4000) | Y | "원인 → 사건 → 영향" 서술 |
| PMS_Risk__c.Category__c / CategoryPath__c | Lookup(CMN_Code__c, RISK_CATEGORY 리프) / Text(255) | Y / — | 유형·코드(P-48). Path는 저장 시 복사 |
| PMS_Risk__c.Source__c | Picklist (MANUAL 수동, GATE_CONDITION Gate 조건, EARLY_WARNING 조기경보, CUSTOMER 고객 요청, LELE 레슨런, IMPORT 기존 로그 이관) | Y | 기본 MANUAL |
| PMS_Risk__c.SourceRecordId__c / SourceObject__c / SourceRecordNo__c | Text(18) / Text(80) / Text(40) | MANUAL·IMPORT 외 Y | 생성 원천 |
| PMS_Risk__c.Activity__c | Lookup(PMS_Activity__c, 같은 프로젝트 필터) | N | 관련 액티비티 |
| PMS_Risk__c.ProjectPart__c | Lookup(PMS_ProjectPart__c, 같은 프로젝트 필터) | N | 관련 품번(QMS 연결 키) |
| PMS_Risk__c.DevPhase__c | Text(40) | N | DEV_PHASE 코드. Activity가 있으면 액티비티 값 복사 |
| PMS_Risk__c.Probability__c / Impact__c | Number(1,0) | Y | 1~5(BR-2 척도) |
| PMS_Risk__c.Score__c | Formula(Number) | — | Probability × Impact |
| PMS_Risk__c.Level__c | Picklist (HIGH, MEDIUM, LOW) | — | 서비스 계산(BR-3·4), FLS 읽기 |
| PMS_Risk__c.ImpactAreas__c | Multi-Picklist (SCHEDULE, COST, QUALITY, CUSTOMER, SAFETY_REGULATORY) | Y | 영향 영역 |
| PMS_Risk__c.ExpectedDelayDays__c | Number(4,0) | N | 정량 영향: 예상 지연 일수 |
| PMS_Risk__c.ExpectedCostImpact__c / CostCurrency__c | Number(16,2) / Text(3) | N | 정량 영향: 예상 비용(D-P5, 통화 코드 텍스트). PMS_PS_Cost_Read 보유자만 FLS 읽기 |
| PMS_Risk__c.FmeaRef__c / FmeaActionPriority__c | Text(80) / Picklist (H, M, L) | N | 관련 FMEA 항목(문서 번호·고장 모드 Id)과 AP(참고) |
| PMS_Risk__c.Owner__c | Lookup(User) | Y | 리스크 담당(대책 책임). 기본 등록자 |
| PMS_Risk__c.Strategy__c | Picklist (AVOID 회피, MITIGATE 경감, TRANSFER 전가, ACCEPT 수용) | MITIGATING이면 Y | 대응 전략 |
| PMS_Risk__c.MitigationPlan__c | Long Text(4000) | MITIGATING이면 Y, HIGH면 등록 후 7일 안에 Y | 경감 대책(계약 필드) |
| PMS_Risk__c.DueDate__c | Date | MITIGATING이면 Y | 경감 목표일 |
| PMS_Risk__c.DaysToDue__c | Formula(Number, 0) | — | DueDate − TODAY()(UX-004 BR-4) |
| PMS_Risk__c.TargetProbability__c / TargetImpact__c | Number(1,0) | N | 경감 후 목표 값 |
| PMS_Risk__c.ResidualScore__c | Formula(Number) | — | 목표 값이 있으면 TargetProbability × TargetImpact |
| PMS_Risk__c.Status__c | Picklist (OPEN, MITIGATING, CLOSED, OCCURRED) | Y | 서비스로만 변경 |
| PMS_Risk__c.ReviewCycle__c | Picklist (WEEKLY, MONTHLY) | Y | BR-6 기본값 |
| PMS_Risk__c.LastReviewedOn__c / NextReviewDate__c | Date | — | 서비스 갱신 |
| PMS_Risk__c.IsReviewOverdue__c | Formula(Checkbox) | — | 미종결이고 NextReviewDate < TODAY() |
| PMS_Risk__c.Trend__c | Picklist (NEW, UP, FLAT, DOWN) | — | 직전 검토 대비 점수 변화(BR-7) |
| PMS_Risk__c.ReviewComment__c | Long Text(4000) | N | 이번 검토 의견(그리드 입력, 저장 시 검토 이력으로 복사 후 유지) |
| PMS_Risk__c.EscalationLevel__c | Number(1,0) | Y | 0 없음, 1 PMO·팀장, 2 경영(BR-8). 기본 0 |
| PMS_Risk__c.EscalatedAt__c / EscalatedTo__c | DateTime / Lookup(User) | 단계 1 이상이면 Y | 계약 필드 EscalatedAt |
| PMS_Risk__c.CloseReason__c | Picklist (MITIGATED 경감 완료, NOT_OCCURRED 기간 경과·미발생, ACCEPTED 수용, TRANSFERRED 전가, DUPLICATE 중복·오등록) | CLOSED면 Y | |
| PMS_Risk__c.CloseComment__c / ClosedAt__c | Long Text(4000) / DateTime | CLOSED면 Y / — | |
| PMS_Risk__c.OccurredAt__c / OccurredIssue__c | Date / Lookup(PMS_Issue__c) | OCCURRED면 Y | ISS-001이 markOccurred로 채움(Lookup 필드는 ISS-001이 만든다, 아래 주) |
| PMS_Risk__c.IsLessonCandidate__c | Checkbox | N | 종결 시 레슨런 후보(RSK-002가 사용) |
| PMS_Risk__c.ExternalKey__c | Text(80), External ID, Unique | N | 원천 멱등 키 `{ProjectId}-{SourceRecordId}`(원천이 있을 때만) |
| PMS_RiskReview__c.Risk__c | Master-Detail(PMS_Risk__c) | Y | |
| PMS_RiskReview__c.PeriodType__c / PeriodStart__c | Picklist (WEEKLY, MONTHLY) / Date | Y | 주 = 월요일, 월 = 1일(공장 시간대 무관 날짜) |
| PMS_RiskReview__c.Probability__c / Impact__c / Score__c / Level__c | Number(1,0) / Number(1,0) / Number(2,0) / Text(10) | Y | 검토 시점 스냅숏 |
| PMS_RiskReview__c.Status__c / Strategy__c | Text(20) / Text(20) | Y / N | 스냅숏 |
| PMS_RiskReview__c.Trend__c | Text(10) | Y | 직전 검토 대비 |
| PMS_RiskReview__c.Comment__c | Long Text(4000) | N | 진행 의견 |
| PMS_RiskReview__c.ReviewedBy__c / ReviewedAt__c | Lookup(User) / DateTime | Y | |
| PMS_RiskReview__c.ExternalKey__c | Text(80), External ID, Unique | Y | `{RiskId}-{PeriodType}-{PeriodStart}`(같은 기간 1행, 다시 저장하면 갱신) |

주: `OccurredIssue__c`는 PMS_Issue__c를 가리키므로 PMS_Issue__c가 생긴 뒤 ISS-001이 만든다. 이 WI의 markOccurred는 Id만 받아 `OccurredAt__c`와 상태를 바꾸고, ISS-001 배포 뒤에 Lookup을 채운다(BR-11).

**서비스 API (`PMS_RiskService`)**

    Id createFromSource(PMS_RiskRequest req)
    // req: projectId, title, description, categoryCode(RISK_CATEGORY Code__c), probability, impact,
    //      impactAreas(List<String>), ownerId, dueDate, source, sourceId, sourceObject, sourceNo,
    //      activityId, projectPartId, mitigationPlan
    void recordReviews(List<PMS_RiskReviewInput> inputs)   // 그리드·화면 일괄 검토(BR-6)
    void escalate(Id riskId, Integer level, Id toUserId, String comment)
    void close(Id riskId, String reason, String comment, Boolean lessonCandidate)
    void markOccurred(Id riskId, Id issueId, Date occurredOn) // ISS-001이 호출
    void reopen(Id riskId, String comment)                   // CLOSED → OPEN(PM·PMO)
    PMS_RiskStatusDTO getStatusBySource(Id sourceId)          // riskId, recordNo, status, level, ownerName

**비즈니스 규칙**

- BR-1: 등록 — 프로젝트의 CFT 구성원(ACTIVE, AccessLevel PM·EDIT)과 PMO가 등록한다. 필수: 제목, 서술, 유형, P, I, 영향 영역, 담당. 프로젝트 Status가 CLOSED·CANCELLED면 등록 차단. 같은 프로젝트에 같은 제목의 미종결 리스크가 있으면 저장 전 경고(차단 아님).

- BR-2: 정량 척도 — 화면에 아래 척도 안내를 보여준다. 문구·기준 숫자는 CMN 설정 `PMS_RISK_SCALE_GUIDE`(JSON, 언어별 라벨 키)로 두고 SL 기준으로 교체한다. 기본값:

| 값 | 발생 가능성(P) | 영향도(I) — 일정 | 영향도(I) — 품질·고객 |
| --- | --- | --- | --- |
| 1 | 10% 미만 | 내부 일정 1주 미만 지연 | 내부에서 흡수 |
| 2 | 10~30% | 내부 일정 1~2주 | 내부 재작업 |
| 3 | 30~50% | 고객 마일스톤 영향 가능 | 고객 샘플 재제출 |
| 4 | 50~70% | 고객 마일스톤 지연 | 고객 승인 지연·클레임 가능 |
| 5 | 70% 이상 | SOP 지연 | 안전·법규 또는 SOP 위험 |

  영향 영역이 여러 개면 가장 큰 영향도를 I로 입력하도록 안내한다. ExpectedDelayDays·ExpectedCostImpact는 참고 정량 값이며 점수 계산에 쓰지 않는다.

- BR-3: 등급 — 트리거(before insert·update)가 계산한다. 기준 값은 CMN 설정: `PMS_RISK_HIGH_SCORE`(기본 15), `PMS_RISK_MEDIUM_SCORE`(기본 8), `PMS_RISK_HIGH_IMPACT`(기본 5).
  - HIGH: Score ≥ HIGH_SCORE, 또는 Impact ≥ HIGH_IMPACT이고 Probability ≥ 2.
  - MEDIUM: HIGH가 아니고 Score ≥ MEDIUM_SCORE.
  - LOW: 그 외.

- BR-4: FMEA 하한 — FmeaActionPriority = H이면 등급 하한을 CMN 설정 `PMS_RISK_FMEA_H_MIN_LEVEL`(기본 MEDIUM)로 둔다. 하한으로 올라간 경우 화면에 "FMEA AP H 하한 적용"을 표시한다.

- BR-5: 상태 전이(서비스만, Status FLS 읽기) — OPEN → MITIGATING: Strategy·MitigationPlan·DueDate가 모두 채워지면 저장 시 자동. MITIGATING → OPEN: 대책을 지우면 자동(드묾). OPEN·MITIGATING → CLOSED: `close`(사유 필수, DUPLICATE 외에는 종결 의견 필수). OPEN·MITIGATING → OCCURRED: `markOccurred`만. CLOSED → OPEN: `reopen`(PM·PMO, 의견 필수, 코멘트 자동 기록). OCCURRED는 되돌리지 않는다.

- BR-6: 검토 주기 — ReviewCycle 기본값: HIGH = WEEKLY, 그 외 MONTHLY. 등급이 HIGH로 오르면 WEEKLY로 바꾸고, 내려가도 사용자가 고친 값은 유지한다. NextReviewDate = 마지막 검토일의 다음 주 월요일(WEEKLY) 또는 다음 달 1일(MONTHLY). 등록 시 NextReviewDate = 등록일 기준 같은 규칙.
  - `recordReviews`는 리스크마다 PMS_RiskReview__c를 ExternalKey upsert(같은 기간 1행)로 만들고 리스크의 P·I·Strategy·MitigationPlan·DueDate 변경을 함께 저장한다. LastReviewedOn = 오늘, NextReviewDate 재계산.
  - 스케줄 잡 `PMS_RiskReviewReminderJob`(매일 07:00 KST): NextReviewDate ≤ 오늘인 미종결 리스크를 프로젝트·담당별로 묶어 담당에게 To-Do "리스크 검토 {n}건: {projectNo}"(SourceType PMS_RISK_REVIEW, 기한 = 가장 이른 NextReviewDate + 2일) 1건과 알림 PMS_RISK_REVIEW_DUE. 검토가 저장되면 해당 리스크가 묶음에서 빠지고 0건이면 To-Do를 닫는다.
  - 검토 기한을 7일 넘긴 리스크가 있으면 PM에게 같은 To-Do를 1회 추가로 연다.

- BR-7: 추세 — 검토 저장 시 직전 검토 Score와 비교해 UP(증가)·DOWN(감소)·FLAT, 첫 검토는 NEW. 리스크 Trend에도 복사한다.

- BR-8: 에스컬레이션.
  - 1단계(자동): 등급이 처음 HIGH가 되는 저장(신규 포함)에서 EscalationLevel = 1, EscalatedAt = 현재, EscalatedTo = 프로젝트 PMO 역할 CFT 구성원(PROJECT_ROLE PMO, 없으면 APPROVAL_ROLE PMO_MANAGER), 알림 PMS_RISK_HIGH: PM, 담당, EscalatedTo, 담당 부서장(MDM-001 Manager). MitigationPlan이 비어 있으면 담당에게 To-Do "High 리스크 대책 수립: {RecordNo}"(SourceType PMS_RISK_PLAN, 기한 7일), 대책이 저장되면 닫는다.
  - 2단계(수동): Custom Permission PMS_RSK_Escalate 보유자(PM·PMO)가 "경영 보고" 액션으로 `escalate(riskId, 2, toUserId, comment)`. 대상 기본값 = APPROVAL_ROLE BU_HEAD(프로젝트 ProdPlant 기준 해석, APV-002 BR-2). 알림 PMS_RISK_ESCALATED, 코멘트 자동 기록. 의사결정 기록은 PMS-10-DSH-004 범위다.
  - 자동 재알림: HIGH이고 EscalationLevel = 1인 상태가 CMN 설정 `PMS_RISK_ESCALATE_DAYS`(기본 14)일 이상이고 그 사이 점수가 내려가지 않았으면 PMO와 PM에게 "2단계 보고 검토" 알림을 1회 보낸다(자동 2단계 전환은 하지 않는다).
  - HIGH에서 내려가도 EscalationLevel은 이력으로 남긴다(값 유지, 화면에 "해제됨" 표시는 Level로 판단).

- BR-9: 편집 권한 — 프로젝트 PM(PMS_Project__c.PM__c 또는 CFT AccessLevel PM), PMO PSG, 리스크 Owner만 리스크 필드를 고친다. 그 외 CFT 구성원은 등록과 조회만 한다. MD 하위라 부모 편집 권한이 있으면 저장 자체는 가능하므로, 트리거 before update에서 이 규칙을 검사하고 위반 시 행 오류(라벨 `PMS_Risk_EditNotAllowed`)를 붙인다. 종결은 Owner·PM·PMO(Custom Permission PMS_RSK_Close가 있으면 타인 리스크도).

- BR-10: 생성 서비스 — `createFromSource`는 OPEN 리스크를 만들고 ExternalKey `{ProjectId}-{SourceRecordId}`로 멱등(이미 있으면 기존 Id 반환, 미종결이면 서술 끝에 원천 번호만 코멘트로 추가). 담당이 없으면 PM. HIGH면 BR-8 1단계가 그대로 적용되고, 그 외에는 알림 없이 다음 검토 묶음 To-Do(BR-6)에 들어간다.

- BR-11: 발생 — `markOccurred(riskId, issueId, occurredOn)`: Status OCCURRED, OccurredAt, OccurredIssue(ISS-001 배포 후 필드가 있을 때, `Schema` 확인 후 세팅), 열린 PMS_RISK_* To-Do 취소. 이미 OCCURRED면 무시(멱등).

- BR-12: 기존 로그 이관 — 리스크 로그 그리드의 붙여넣기(UX-006 BR-3)로 엑셀 행을 넣는다. 유형은 CODE 열(RISK_CATEGORY Name 또는 ExternalKey)로 매핑하고, 이관 행은 Source = IMPORT. 과거 검토 이력은 이관하지 않고 서술 끝에 원본 엑셀 행 번호를 남긴다.

- BR-13: 공통 기반 — 3절 표(채번·삭제 통제·상태 진행바·UX-005 규칙·필드 이력·DWH 복제·번역)를 이 WI에서 등록한다.

**화면/UX**: 화면 유형 T1 + T2. 리스크 레코드는 UX-004 표준, 프로젝트의 리스크 목록·검토는 UX-006 그리드를 쓴다.

| 화면 | 위치 | 구성 |
| --- | --- | --- |
| PMS_Risk__c 레코드 페이지 | 생성기 정의 `meta-src/record-pages/PMS_Risk__c.json` | 헤더 7개: RecordNo, Name, Status, 프로젝트 번호(고객 자리 대체: 리스크는 고객보다 프로젝트가 식별 키), Level(품번 자리 대체), ProdPlant(프로젝트 수식), DueDate(D-day). 현재 단계 탭: 평가(P·I·영향 영역·정량 값·FMEA), 대응(Strategy·MitigationPlan·DueDate·목표 P·I), 검토 이력 관련 목록. 액션(Dynamic Actions): "검토 기록", "경영 보고", "종결", "발생 처리(문제점 등록)"(ISS-001 배포 후 활성), "다시 열기" |
| 리스크 로그 그리드 `cmnEditableGrid` gridKey `PMS_RiskLog` | 프로젝트 레코드 페이지 "리스크" 탭 | 열: 번호(읽기), 제목, 유형(CODE RISK_CATEGORY), P, I, 점수(읽기), 등급(읽기), 담당, 전략, 경감 대책, 목표일, 상태(읽기), 다음 검토(읽기), 이번 검토 의견. 고정 필터 미종결(OPEN·MITIGATING). 종결·발생 건까지 보는 전체 보기는 Filter 없는 읽기 전용 gridKey `PMS_RiskLogAll`을 같은 탭의 두 번째 하위 탭에 둔다 |
| 휴대폰 | 그리드 카드(번호·제목·등급·다음 검토) | 카드 → 레코드 페이지에서 "검토 기록" 액션 |

  Provider `PMS_RiskLogGridProvider`(CMN_GridProviderBase 상속):
  - `defaults`: Owner = 현재 사용자, Source = MANUAL, ReviewCycle = MONTHLY.
  - `rowMeta`: HIGH 행 경고 표시(라벨 "High 리스크"), 검토 기한 경과 행 경고, BR-9 편집 불가 행은 모든 열 잠금, 검토 이력이 있는 행은 삭제 불가.
  - `validate`: P·I 1~5, MITIGATING 전환 조건(BR-5), HIGH 등록 7일 경과 후 대책 공란 오류.
  - `afterSave`: ReviewComment가 바뀌었거나 P·I가 바뀐 행은 `recordReviews`로 검토 이력을 만든다(그리드 일괄 입력 = 주간·월간 검토, P-50).

**권한**: PMS_PS_Risk_Read(조회), PMS_PS_Risk_Edit(등록·편집, BR-9 행 단위 제한), Custom Permission PMS_RSK_Escalate(PMS_PSG_PM, PMS_PSG_PMO), PMS_RSK_Close(PMS_PSG_PMO). ExpectedCostImpact·CostCurrency FLS는 PMS_PS_Cost_Read에만 둔다.

**수용 기준**

- AC-1: Given P 3·I 5(테스트 설정 HIGH_SCORE 15, HIGH_IMPACT 5), When 등록, Then Score 15, Level HIGH, ReviewCycle WEEKLY, EscalationLevel 1, PM·담당·PMO·담당 부서장 알림, 대책 공란이면 담당 To-Do PMS_RISK_PLAN 1건.

- AC-2: Given P 2·I 3, FmeaActionPriority H(하한 MEDIUM), When 저장, Then Score 6, Level MEDIUM, "FMEA AP H 하한 적용" 표시.

- AC-3: Given 그리드에서 리스크 5건의 P·I와 검토 의견 수정, When 저장, Then PMS_RiskReview__c 5건(같은 주 다시 저장하면 5건 유지·갱신), 각 리스크 LastReviewedOn = 오늘, NextReviewDate 재계산, Trend 계산.

- AC-4: Given 다른 사용자 소유 리스크, 일반 CFT 사용자(PM 아님), When API로 Probability 수정, Then 행 오류 PMS_Risk_EditNotAllowed.

- AC-5: Given NextReviewDate가 어제인 리스크 3건(담당 같음), When 리마인더 잡, Then 담당 To-Do 1건(제목에 3건). 3건 검토 저장 후 To-Do DONE.

- AC-6: Given Strategy·MitigationPlan·DueDate 입력, When 저장, Then Status MITIGATING. Status를 API로 직접 CLOSED로 바꾸면 차단.

- AC-7: Given createFromSource 같은 원천으로 2회, When 호출, Then 리스크 1건, 같은 Id.

- AC-8: Given 엑셀 10행(유형 이름 1개 오타) 붙여넣기, When 미리보기, Then 오류 셀 1개, 나머지 9행 저장 시 Source IMPORT.

- AC-9: Given 리스크 200건 일괄 insert, When 트리거, Then 등급·검토일 계산 SOQL 3회 이하, 거버너 오류 없음.

**에이전트 주의**: 등급 기준 숫자를 코드 상수로 두지 않는다(CMN 설정). 검토 이력을 Field History로 대신하지 않는다(주·월 단위 스냅숏이 보고 근거). 리스크 이벤트(Platform Event)를 새로 만들지 않는다(계약 9절에 없고 Scratch 이벤트 한도, D-P8). PMS_Issue__c Lookup을 이 WI에서 만들지 않는다(ISS-001 소유, BR-11). 그리드 대신 리스크 전용 표 LWC를 만들지 않는다.

**오픈 이슈**: SL 현행 RISK Management Log의 유형·코드·속성 목록과 등급 기준(5×5 행렬의 셀별 등급을 따로 정했는지), 2단계 에스컬레이션 대상(사업부장·연구소장·경영회의), 비용 영향 금액을 PM 외에 공개할지.

### PMS-08-RSK-002 리스크 경감 대책 ↔ QMS 선행 품질 점검 추적

추적 P-50 · 필수 · W2 · SF · DM, APEX, LWC · Customization · 선행 RSK-001, PMS-08-ISS-002, QMS-04-LEL-004, QMS-04-LEL-005, UX-004 · 4 M/D

**목적**: 품질·기술 리스크의 경감 대책이 QMS 선행 품질 점검 항목(레슨런 체크포인트와 그 반영 검토)으로 실제 수행되는지 양방향으로 추적한다(P-50 디지털 스레드). "대책을 세웠다"가 아니라 "해당 액티비티에서 체크포인트가 반영·확인됐다"까지 보여야 리스크를 닫을 수 있다.

**범위** In: 연결 객체, 체크포인트 찾기(LEL-004 매칭), 반영 검토 요청(LEL-005 propose), 연결 상태 갱신, 종결 검사, 리스크 레슨런 후보 요청, QMS에서 보는 역방향 조회 서비스, 레일 패널. Out: 레슨런·체크포인트·반영 검토 레코드(QMS-04 LEL 소유), 레슨런 후보 요청 공통 서비스(PMS-08-ISS-002), AI 추천(QMS-08 AIQ-007·008, PMS 액티비티 화면 배치는 PMS-12-INT-005).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_RiskQualityLink__c.Risk__c | Master-Detail(PMS_Risk__c) | Y | |
| PMS_RiskQualityLink__c.TargetType__c | Picklist (LELE_CHECKPOINT 레슨런 체크포인트, LELE_APPLICATION 반영 검토, LESSON_LEARNED 레슨런, QUAL_PLAN 인정시험 계획, OTHER) | Y | 계약 필드 |
| PMS_RiskQualityLink__c.TargetRecordId__c | Text(18) | Y | 계약 필드(QMS 레코드 Id, Lookup 금지) |
| PMS_RiskQualityLink__c.TargetRecordNo__c / TargetTitle__c | Text(40) / Text(255) | Y / N | 연결 시점 사본(레슨런 번호·체크 문장) |
| PMS_RiskQualityLink__c.LinkRole__c | Picklist (MITIGATION_CHECK 경감 확인 항목, ORIGIN 리스크 근거, REFERENCE 참고) | Y | MITIGATION_CHECK만 종결 검사 대상(BR-5) |
| PMS_RiskQualityLink__c.ActivityId__c / ActivityName__c | Text(18) / Text(255) | MITIGATION_CHECK면 Y | 체크포인트를 반영할 PMS 액티비티(같은 프로젝트) |
| PMS_RiskQualityLink__c.ApplicationId__c | Text(18) | N | propose로 생긴 QMS_LeleApplication__c Id |
| PMS_RiskQualityLink__c.TargetStatus__c | Text(40) | N | QMS 쪽 상태 사본(PROPOSED, UNDER_REVIEW, APPLIED, VERIFIED, NOT_APPLICABLE, DEFERRED, CANCELLED 등) |
| PMS_RiskQualityLink__c.IsSatisfied__c | Formula(Checkbox) | — | TargetStatus가 APPLIED·VERIFIED·NOT_APPLICABLE이면 true |
| PMS_RiskQualityLink__c.StatusSyncedAt__c | DateTime | N | |
| PMS_RiskQualityLink__c.Origin__c | Picklist (LELE_MATCH 매칭 결과, MANUAL 수동) | Y | |
| PMS_RiskQualityLink__c.Comment__c | Text(1000) | N | |
| PMS_RiskQualityLink__c.ExternalKey__c | Text(60), External ID, Unique | Y | `{RiskId}-{TargetRecordId}` |
| PMS_Risk__c.QualityLinkCount__c | Roll-up(COUNT) | — | 연결 수 |
| PMS_Risk__c.QualityLinkOpen__c | Number(4,0) | — | 미충족 MITIGATION_CHECK 수. Roll-up 필터에 수식 필드를 쓰지 않도록 link·refreshStatus가 갱신 |

**서비스 API (`PMS_RiskQualityService`)**

    List<QMS_LeleMatch> findCheckpoints(Id riskId, Integer limitN)          // LEL-004 match 위임
    void link(Id riskId, List<PMS_RiskQualityLinkInput> inputs)            // 선택 결과 연결(+ 선택 시 propose)
    void refreshStatus(Set<Id> riskIds)                                     // QMS 상태 다시 읽기
    List<PMS_RiskQualityRefDTO> getRisksByQmsTarget(String targetRecordId) // QMS 화면용 역방향 조회

**비즈니스 규칙**

- BR-1: 체크포인트 찾기 — `findCheckpoints`는 `QMS_LeleContext`를 프로젝트·리스크에서 만들어 `QMS_LeleMatchService.match(ctx, limitN 기본 20)`를 부른다. customerId·customerGroup = 프로젝트 고객, vehicleId = 프로젝트 차종, productGroupId = 프로젝트 제품군, partCategories = ProjectPart(있으면 그 품번, 없으면 프로젝트 전체 품번)의 PartCategory 목록, devPhaseCode = 리스크 DevPhase, activityTypeCodes = 리스크 Activity의 ActivityType(없으면 빈 목록), keywords = 리스크 제목 + 유형 이름. 결과는 저장하지 않는다(LEL-004 BR-7).

- BR-2: 연결 — 사용자가 결과(체크포인트 단위)를 고르고 역할을 정하면 `link`가 ExternalKey upsert로 연결을 만든다. MITIGATION_CHECK이면 반영할 액티비티(같은 프로젝트, CANCELLED 제외)를 필수로 받고 `QMS_LeleApplicationService.propose(ctx, proj, 'MANUAL', 선택한 QMS_LeleMatch 목록)`를 호출한다(proj: projectId·projectNo·projectName·activityId·activityName, reviewerId = 액티비티 Owner, qualityOwnerId = 프로젝트 QE 역할 CFT 구성원, activityStartDate). 반환 Id를 ApplicationId에, TargetType LELE_CHECKPOINT, TargetStatus PROPOSED로 저장한다. propose가 기존 반영 검토를 돌려주면(LEL-005 BR-1 멱등) 그 상태를 그대로 쓴다.

- BR-3: 수동 연결 — 레슨런 번호(LL-…) 또는 인정시험 계획 번호(QTP-…)를 입력해 연결할 수 있다. 번호 → Id 해석은 각 QMS 서비스의 getStatusBySource가 아니라 번호 조회가 필요하므로, 레슨런은 `QMS_LeleMatchService.match`(keywords = 번호) 결과에서, 인정시험은 `QMS_QualPlanService.getStatusBySource(activityId)`가 돌려준 계획 중에서 고르게 한다. QMS 객체를 직접 SOQL하지 않는다.

- BR-4: 상태 갱신 — (a) 리스크 레코드 페이지 패널을 열 때와 "상태 새로 고침" 버튼에서 `refreshStatus`: 프로젝트 단위 `QMS_LeleApplicationService.getByProject(projectId)` 1회 호출 결과로 ApplicationId가 일치하는 연결의 TargetStatus·StatusSyncedAt을 갱신한다. (b) 매일 05:00 배치 `PMS_RiskQualitySyncJob`이 미종결 리스크의 연결이 있는 프로젝트마다 같은 방식으로 갱신한다(프로젝트당 호출 1회). 실시간 이벤트(QMS_LeleApplicationEvent__e) 구독은 PMS-12-INT-005 범위이며, INT-005가 이벤트를 받으면 `refreshStatus`를 부르도록 요청한다(9절).

- BR-5: 종결 검사 — CloseReason = MITIGATED로 종결할 때 MITIGATION_CHECK 연결 중 IsSatisfied = false가 있으면 목록과 함께 확인 대화상자를 띄운다. 계속하면 종결 의견에 "미충족 점검 {n}건 상태로 종결" 문장을 자동 추가하고 PM에게 알림을 보낸다(차단하지 않음, PM 판단). 다른 사유는 검사하지 않는다.

- BR-6: 레슨런 후보 — 리스크를 종결(MITIGATED 또는 NOT_OCCURRED)하면서 IsLessonCandidate = true이면 `PMS_LessonCandidateService.request(riskId)`(ISS-002)를 호출한다. payloadJson.pmsSourceType = RISK, 현상 = 서술, 대책 = MitigationPlan, isVerified = MITIGATION_CHECK 연결이 모두 IsSatisfied.

- BR-7: 역방향 조회 — `getRisksByQmsTarget(targetRecordId)`는 TargetRecordId 또는 ApplicationId가 일치하는 연결의 리스크(번호, 제목, 등급, 상태, 프로젝트 번호)를 돌려준다. QMS 레슨런·반영 검토 화면이 같은 Org에서 이 서비스를 호출할 수 있다(QMS 쪽 배치는 선택, 9절). 실행 사용자의 프로젝트 공유를 따른다(with sharing).

- BR-8: 일괄 연결 제한 — 한 번에 연결 20건, 리스크당 연결 100건까지.

**화면/UX**: 화면 유형 T1(레일 패널). 리스크 레코드 레일에 패널 `pmsRiskQualityPanel`(CMN_RailPanel__mdt: ObjectApiName PMS_Risk__c, PanelKey CONTEXT_QMS_CHECK, 기본 접힘)을 둔다. 레일 패널 계약(UX-004 BR-6)을 지킨다.
- 상단: 연결 목록(역할, 레슨런 번호·체크 문장, 반영 액티비티, QMS 상태, 충족 아이콘+텍스트). 미충족 MITIGATION_CHECK 수를 `railbadge`로 알린다.
- "체크포인트 찾기" 모달: 매칭 결과(점수·근거 matchedKeys)를 체크박스로 고르고 역할·액티비티를 정한 뒤 "연결".
- 레슨런 번호를 누르면 QMS 레슨런 레코드(Lightning URL)를 연다.

**권한**: PMS_PS_Risk_Edit(연결·propose 요청 — 실제 propose는 QMS_PS_Lele_Edit 없이도 서비스가 실행돼야 하므로 QMS 쪽 서비스 권한 확인 필요, 오픈 이슈), PMS_PS_Risk_Read(조회). 실행 사용자에게 QMS_PS_Lele_Read가 있어야 매칭이 된다(PMS PSG에 QMS_PS_Lele_Read 포함 요청, 9절).

**수용 기준**

- AC-1: Given 프로젝트(BMW, LENS 품번), 리스크(DevPhase DESIGN, 액티비티 유형 OPT_DESIGN), When 체크포인트 찾기, Then LEL-004에 넘긴 ctx가 고객군 BMW·부품 분류 LENS·DESIGN·[OPT_DESIGN]을 담고 결과가 점수순으로 표시된다(Test.createStub로 매칭 서비스 대체).

- AC-2: Given 체크포인트 2개를 MITIGATION_CHECK로 연결(액티비티 A1), When 연결, Then 연결 2건, propose 1회 호출(매치 2개), ApplicationId 저장, TargetStatus PROPOSED.

- AC-3: Given QMS 반영 검토가 APPLIED로 바뀜, When refreshStatus, Then 해당 연결 IsSatisfied = true, 프로젝트당 getByProject 1회.

- AC-4: Given 미충족 MITIGATION_CHECK 1건, When MITIGATED 종결 계속 선택, Then 종결되고 종결 의견에 자동 문장, PM 알림 1건.

- AC-5: Given IsLessonCandidate = true로 종결, When 처리, Then PMS_LessonCandidateService.request 1회(payload pmsSourceType RISK).

- AC-6: Given QMS 반영 검토 Id, When getRisksByQmsTarget, Then 연결된 리스크 1건(번호·등급·프로젝트 번호).

**에이전트 주의**: QMS 객체(QMS_LeleCheckpoint__c 등)를 Lookup하거나 PMS Apex에서 직접 SOQL하지 않는다(서비스 호출만). propose를 체크포인트마다 반복 호출하지 않는다(한 번에 목록). 연결 상태를 QMS 쪽에 쓰지 않는다.

**오픈 이슈**: 리스크에서 만든 반영 검토의 Reviewer를 액티비티 담당으로 둘지 리스크 담당으로 둘지, QMS 레슨런 화면에 연결 리스크를 보여줄지(QMS-04 화면 변경 필요).

### PMS-08-RSK-003 리스크·문제점 현황 대시보드

추적 P-51 · 필수 · W1 · SF, SNOW · LWC, APEX, SQL · Customization · 선행 RSK-001, PMS-08-ISS-001, DSH-001, DWH-002, DWH-003 · 3 M/D

**목적**: PM·PMO·경영진이 리스크·문제점의 등록·처리 건수와 완료율을 유형별·항목별로 한눈에 본다(P-51). PMO 전체 보드(PMS-10-DSH-002)와 역할별 대시보드가 같은 위젯을 쓴다.

**범위** In: DSH-001 위젯 2개와 설정 스키마, 위젯 데이터 서비스, 리스트뷰, KPI 뷰·적재 규칙. Out: 위젯 배치 템플릿(PMS-10-DSH-001), PMO 보드 화면(PMS-10-DSH-002), Gate 위젯(PMS-10).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| CMN_Widget__mdt 레코드 PMS_RiskIssueSummary | Custom Metadata | — | ComponentName `pmsRiskIssueSummaryWidget`, System PMS, DefaultSize M, RequiredPermissionSet PMS_PS_Risk_Read |
| CMN_Widget__mdt 레코드 PMS_RiskMatrix | Custom Metadata | — | ComponentName `pmsRiskMatrixWidget`, System PMS, DefaultSize S, RequiredPermissionSet PMS_PS_Risk_Read |
| Snowflake `MART.V_SF_KPI_PMS_RISK_GATE` (제안) | View | — | 3절 KPI 키 6개(일·월), DWH-002 복제 테이블 기준 |
| 리스트뷰 | List View | — | PMS_Risk__c: 내 리스크, 내 프로젝트 HIGH, 검토 기한 경과 · PMS_Issue__c: 내 문제점, 기한 경과, 승인 대기 |

**서비스 API (`PMS_RiskIssueWidgetController`)**

    @AuraEnabled(cacheable=true)
    PMS_RiskIssueSummaryDTO getSummary(String configJson)
    // config: scope(MY_PROJECTS, PROJECT, PLANT, ALL), projectId, plantId, periodMonths(기본 6), groupBy(TYPE, PHASE, OWNER)
    // 응답: risk{open, high, mitigating, closedInPeriod, overdueReview}, issue{registered, inProgress, closed, overdue, closeRatePct},
    //       byGroup[{key, label, riskOpen, issueOpen, issueClosed}], trend[{month, kpiKey, value}](CMN_KpiValue__c)
    @AuraEnabled(cacheable=true)
    List<PMS_RiskMatrixCell> getMatrix(String configJson) // 25칸 {p, i, count, level}

**비즈니스 규칙**

- BR-1: 집계 — 건수는 USER_MODE 집계 SOQL(GROUP BY)로 계산한다. 화면에 보이는 숫자는 사용자가 볼 수 있는 프로젝트만이다(공유·공장 격리 SEC-002가 그대로 적용). 위젯당 SOQL 4회 이하.

- BR-2: 정의 — 리스크 미결 = OPEN·MITIGATING. 문제점 처리 중 = ACCEPTED·APPROVAL_REQUESTED·APPROVED, 등록 = REGISTERED, 종결 = CLOSED(기간 내 ClosedAt), 기한 경과 = 미종결이고 DueDate < 오늘. 문제점 완료율 = 기간 내 기한 도래 문제점 중 기한 내 CLOSED 비율(REJECTED 제외, 분모 0이면 "—").

- BR-3: 유형별·항목별 — groupBy TYPE은 리스크 RISK_CATEGORY 1레벨과 문제점 ISSUE_TYPE 1레벨을 각각 세고 같은 표에 두 구역으로 보인다. PHASE는 DevPhase, OWNER는 담당자별.

- BR-4: 추세 — 최근 periodMonths의 KPI(PMS_RISK_OPEN, PMS_ISSUE_OPEN, PMS_ISSUE_CLOSE_RATE)를 CMN_KpiValue__c에서 읽어 선 그래프(cmnChartJs)로 보인다. KPI가 없으면 추세 영역에 "추세 데이터 준비 중"을 표시하고 나머지는 정상 표시한다.

- BR-5: 행렬 — `pmsRiskMatrixWidget`은 미결 리스크를 P(세로)×I(가로) 5×5 칸에 건수로 보이고 칸 등급(HIGH·MEDIUM·LOW)은 RSK-001 BR-3 설정으로 서버가 계산해 준다. 칸을 누르면 해당 조건의 리스트뷰(필터 URL)로 이동한다. 색만으로 구분하지 않고 칸에 등급 약어(H·M·L)를 함께 쓴다.

- BR-6: KPI 적재 — `MART.V_SF_KPI_PMS_RISK_GATE`가 DWH-002 복제 테이블(PMS_RISK__C, PMS_ISSUE__C, PMS_GATEREVIEW__C, CMN_ACTIONITEM__C)로 3절 KPI를 계산하고 DWH-003 경로(CMN_KpiValue__c)로 매일 06:00 적재한다. Gate KPI 2개도 이 뷰에 두어 Gate 위젯(PMS-10)이 읽는다.

- BR-7: 위젯 계약(DSH-001 BR-4) — `@api config`, `@api size`, 비동기 로드, 오류는 위젯 안에서만. 보드 공통 필터(공장, 기간)가 config보다 우선.

**화면/UX**: 화면 유형 T5. 위젯 2개는 PMS 홈 보드(TDO-004)·PMO 보드(PMS-10-DSH-002)·프로젝트 레코드 페이지 "리스크" 탭 상단(config scope PROJECT, projectId는 레코드 페이지가 넣음)에 배치한다. 요약 위젯: 상단 숫자 카드 6개(리스크 미결·HIGH·검토 경과, 문제점 처리 중·기한 경과·완료율) → 유형별 표 → 추세 그래프. 숫자 카드를 누르면 같은 조건의 리스트뷰로 간다. 휴대폰은 숫자 카드만.

**권한**: 위젯은 PMS_PS_Risk_Read·PMS_PS_Issue_Read 보유자에게만 갤러리에 나온다(DSH-001 BR-2). 컨트롤러 클래스 접근은 두 Read PS에 넣는다.

**수용 기준**

- AC-1: Given 프로젝트 2개 중 1개만 공유된 사용자, When 요약 위젯(MY_PROJECTS), Then 공유된 프로젝트 건수만 집계.

- AC-2: Given 기간 내 기한 도래 문제점 4건 중 3건 기한 내 종결, 1건 반려(REJECTED), When 완료율, Then 100%(반려 제외 분모 3).

- AC-3: Given P 4·I 4 미결 리스크 2건, When 행렬, Then (4,4) 칸 2건, 등급 HIGH(테스트 설정), 칸 클릭 시 리스트뷰 이동.

- AC-4: Given CMN_KpiValue__c에 KPI 없음, When 위젯 표시, Then 추세 영역에 준비 중 표시, 숫자 카드 정상.

- AC-5: Given 리스크 5,000건·문제점 5,000건 테스트 데이터, When getSummary, Then SOQL 4회 이하, 2초 이내(UAT).

**에이전트 주의**: 위젯에서 Snowflake를 직접 호출하지 않는다(DSH-001 BR-5). CRM Analytics·표준 대시보드로 대신하지 않는다. 비용 영향 금액(ExpectedCostImpact)을 위젯에 넣지 않는다(비용 권한 분리).

**오픈 이슈**: 경영 보고용 "주간 Top 리스크" 목록 형식(PMS-10-DSH-003 주간 보고에 넣을지).

## 5. 문제점 (ISS-001~002)

### PMS-08-ISS-001 문제점 등록·대책서·승인·종결

추적 P-48, P-49 · 필수 · W1 · SF · DM, APEX, LWC, CFG · Customization · 선행 RSK-001, PMS-02-PRJ-001, PMS-02-PRJ-002, PMS-03-CFT-001, PMS-12-APV-001, ARC-003, MDM-007, SEC-003, UX-003, UX-004, UX-005, UX-006, APV-001, APV-002, APV-003, TDO-001, NTF-001, DOC-001 · 6 M/D

**목적**: 프로젝트에서 발생한 문제를 등록 → 접수(담당·기한 확정, 대책서 작성) → 승인 요청 → 승인 → 종결 절차로 관리한다(P-49). 대책서는 결재로 확정하고, 리스크가 실제로 일어난 경우 리스크와 문제점을 연결해 "예상했던 위험이 현실이 됐다"는 이력을 남긴다.

**범위** In: 문제점 객체·상태 서비스, 결재 유형·콜백, 리스크 발생 전환, 기한·지연 알림, 이벤트 PMS_IssueEvent__e 정의와 CREATED·CLOSED 발행, 레코드 페이지, 프로젝트 문제점 그리드. Out: QMS 클레임·NCR·8D 연결과 레슨런 후보(ISS-002), 대시보드(RSK-003).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_Issue__c.Project__c | Master-Detail(PMS_Project__c) | Y | |
| PMS_Issue__c.RecordNo__c | Text(40), Unique, External ID | Y | ISS-{YYYY}-{SEQ:6} |
| PMS_Issue__c.Name | Text(80) | Y | 제목 |
| PMS_Issue__c.Description__c | Long Text(32768) | Y | 현상(언제·어디서·무엇이·얼마나) |
| PMS_Issue__c.IssueType__c / IssueTypePath__c | Lookup(CMN_Code__c, ISSUE_TYPE 리프) / Text(255) | Y | |
| PMS_Issue__c.Severity__c | Picklist (CRITICAL 안전·법규·SOP 위험, MAJOR 고객 마일스톤 영향, MINOR 내부 영향) | Y | 기본 MAJOR |
| PMS_Issue__c.Source__c | Picklist (MANUAL 수동, RISK_OCCURRED 리스크 발생, GATE Gate 평가, QMS_CLAIM 고객 클레임, QMS_NCR 부적합, CUSTOMER 고객 지적) | Y | |
| PMS_Issue__c.SourceRecordId__c / SourceObject__c / SourceRecordNo__c | Text(18) / Text(80) / Text(40) | MANUAL·CUSTOMER 외 Y | |
| PMS_Issue__c.Risk__c | Lookup(PMS_Risk__c, 같은 프로젝트 필터) | RISK_OCCURRED면 Y | 계약 필드 |
| PMS_Issue__c.Activity__c / ProjectPart__c | Lookup(PMS_Activity__c) / Lookup(PMS_ProjectPart__c) | N | 같은 프로젝트 필터 |
| PMS_Issue__c.Item__c | Lookup(CMN_Item__c) | N | ProjectPart에서 복사(QMS 연결 키) |
| PMS_Issue__c.DevPhase__c | Text(40) | N | DEV_PHASE 코드(Activity에서 복사) |
| PMS_Issue__c.DetectedDate__c / Reporter__c | Date / Lookup(User) | Y | 기본 오늘·등록자 |
| PMS_Issue__c.Owner__c | Lookup(User) | ACCEPTED 이후 Y | 대책 담당 |
| PMS_Issue__c.DueDate__c | Date | ACCEPTED 이후 Y | 대책 완료 기한 |
| PMS_Issue__c.DaysToDue__c / IsOverdue__c | Formula(Number, 0) / Formula(Checkbox) | — | UX-004 D-day, 미종결이고 기한 경과 |
| PMS_Issue__c.ContainmentAction__c | Long Text(4000) | N | 긴급 조치 |
| PMS_Issue__c.RootCause__c | Long Text(4000) | 승인 요청 시 Y(BR-4 예외 있음) | 원인 |
| PMS_Issue__c.Countermeasure__c | Long Text(4000) | 승인 요청 시 Y(BR-4 예외 있음) | 대책 요약 |
| PMS_Issue__c.CountermeasureDocument__c | Lookup(CMN_Document__c) | 승인 요청 시 Y(BR-4 예외 있음) | 대책서(DocClass ISSUE_COUNTERMEASURE). 계약 필드 |
| PMS_Issue__c.CountermeasureMode__c | Picklist (PMS_DOC 대책서 직접 작성, QMS_8D QMS 8D·6pi 사용) | Y | 기본 PMS_DOC. QMS_8D는 ISS-002가 세팅 |
| PMS_Issue__c.CloseOnApproval__c | Checkbox | N | 대책이 이미 실행·확인된 경우 승인 즉시 종결 |
| PMS_Issue__c.EffectivenessResult__c | Long Text(4000) | CLOSED면 Y | 실행·효과 확인 결과 |
| PMS_Issue__c.Status__c | Picklist (REGISTERED, ACCEPTED, APPROVAL_REQUESTED, APPROVED, CLOSED, REJECTED) | Y | 서비스로만 변경 |
| PMS_Issue__c.RejectReason__c | Text(500) | REJECTED면 Y | 문제 아님·중복 등 |
| PMS_Issue__c.AcceptedAt__c / ApprovedAt__c / ClosedAt__c | DateTime | — | |
| PMS_Issue__c.ExternalKey__c | Text(80), External ID, Unique | N | `{ProjectId}-{SourceRecordId}`(원천이 있을 때) |
| PMS_Issue__c.ClaimRecordId__c / NcrRecordId__c / EightDRecordId__c, IsLessonCandidate__c | — | — | 계약 필드. ISS-002가 만든다 |
| PMS_Risk__c.OccurredIssue__c | Lookup(PMS_Issue__c) | — | RSK-001 BR-11의 Lookup(이 WI가 만든다) |
| PMS_IssueEvent__e | Platform Event(Publish After Commit) | — | IssueId__c, RecordNo__c, ProjectId__c, ProjectNo__c, EventType__c(CREATED, CLOSED, LESSON_CANDIDATE), Status__c, IssueTypeCode__c, Severity__c, Source__c, ItemId__c, RiskId__c, ClaimRecordId__c, NcrRecordId__c, EightDRecordId__c, LessonRecordId__c, SourceRecordId__c(= IssueId), SourceObject__c('PMS_Issue__c') |

**서비스 API (`PMS_IssueService`)**

    Id createFromSource(PMS_IssueRequest req)
    // req: projectId, title, description, issueTypeCode, severity, source, sourceId, sourceObject, sourceNo,
    //      riskId, activityId, projectPartId, itemId, reporterId, ownerId, dueDate
    Id createFromRisk(Id riskId, String description, Date detectedDate) // 리스크 "발생 처리"
    void accept(Id issueId, Id ownerId, Date dueDate, String comment)
    void reject(Id issueId, String reason)
    void submitCountermeasure(Id issueId, String comment)               // APV 상신 래퍼
    void close(Id issueId, String effectivenessResult)
    PMS_IssueStatusDTO getStatusBySource(Id sourceId)

**비즈니스 규칙**

- BR-1: 등록 — 프로젝트 CFT 구성원·PMO가 등록한다. 필수: 제목, 현상, 유형, 심각도, 발견일. 저장 시 REGISTERED, PM에게 To-Do "문제점 접수: {RecordNo}"(SourceType PMS_ISSUE_ACCEPT, 기한 = 등록 + CMN 설정 `PMS_ISSUE_ACCEPT_DAYS` 기본 2일)와 알림 PMS_ISSUE_REGISTERED. CRITICAL이면 PMO 역할 CFT 구성원과 PM 부서장에게도 즉시 알림. 이벤트 CREATED.

- BR-2: 접수 — PM(또는 CFT AccessLevel PM, Custom Permission PMS_ISS_Accept)이 `accept`: Owner·DueDate 필수, DueDate ≥ 오늘. ACCEPTED로 바꾸고 접수 To-Do를 닫고 Owner에게 To-Do "대책서 작성: {RecordNo}"(SourceType PMS_ISSUE_COUNTERMEASURE, 기한 DueDate). 반려는 `reject`(사유 필수) → REJECTED, 등록자 알림 PMS_ISSUE_RESULT, 이벤트 CLOSED(Status REJECTED).

- BR-3: 대책서 — ACCEPTED에서 Owner가 원인·대책·긴급 조치를 입력하고 대책서를 DOC-001 문서 패널(DocClass ISSUE_COUNTERMEASURE, 표준 양식 다운로드 가능)로 올린다. 대책서를 다시 올리면 새 리비전(DOC-001 BR-1).

- BR-4: 승인 요청 — `submitCountermeasure`는 UX-005 `assertCanExecute`(ACTION `PMS_Issue_SubmitCountermeasure`) 후 필수 검사: CountermeasureMode = PMS_DOC이면 RootCause·Countermeasure·대책서(RELEASED 또는 DRAFT 리비전 1개 이상). QMS_8D이면 ISS-002 BR-5 조건(8D 진행 단계)으로 대신한다. 결재 유형 PMS_ISSUE_COUNTERMEASURE로 상신한다.
  - 결재선 기본 템플릿(APV-002, 이 WI 초기 데이터): 기안 Owner → (Severity CRITICAL·MAJOR이고 IssueType이 DESIGN·TEST·SUPPLIER_PART·TOOLING·PROCESS 계열이면) PROJECT_ROLE QE 합의 → PROJECT_ROLE PM 승인. PROJECT_ROLE 해석은 PMS-12-APV-001. CRITICAL은 마지막에 APPROVAL_ROLE PMO_MANAGER 승인 단계를 더한다(결재선 기여 인터페이스 `CMN_ApprovalLineContributor`, Vol.2 변경 요청과 같은 확장).
  - 기안자가 PM 본인이면 PM 단계는 PM 부서장(DRAFTER_MANAGER)으로 바뀐다(APV-001 BR-1 기안자 결재 금지).

- BR-5: 콜백 `PMS_IssueApprovalCallback` — onSubmitted → APPROVAL_REQUESTED, 대책서 To-Do 닫기. onApproved → APPROVED, ApprovedAt, 대책서 리비전 RELEASED(DOC-001 BR-3), Owner에게 To-Do "대책 실행·효과 확인: {RecordNo}"(SourceType PMS_ISSUE_CLOSE, 기한 DueDate). CloseOnApproval = true면 EffectivenessResult가 있어야 하고 바로 CLOSED(BR-6 처리 포함). onRejected·onRecalled → ACCEPTED, Owner에게 대책서 To-Do 다시 열기.

- BR-6: 종결 — APPROVED에서 `close`(Owner 또는 PM, Custom Permission PMS_ISS_Close가 있으면 PMO도): EffectivenessResult 필수. CLOSED, ClosedAt, 열린 PMS_ISSUE_* To-Do 모두 닫기, 이벤트 CLOSED, 등록자·PM 알림 PMS_ISSUE_RESULT. 종결 후 수정 불가(정정은 코멘트).

- BR-7: 리스크 발생 전환 — 리스크 레코드의 "발생 처리" 액션(RSK-001 화면)이 `createFromRisk`: 리스크 제목·서술·액티비티·품번·DevPhase를 복사하고 Source RISK_OCCURRED, Risk = 리스크, IssueType은 리스크 유형 1레벨과 같은 이름의 ISSUE_TYPE이 있으면 그 값, 없으면 사용자가 고른다. 저장 후 `PMS_RiskService.markOccurred(riskId, issueId, detectedDate)`. 같은 리스크로 두 번 전환하면 기존 문제점 Id를 반환한다(ExternalKey `{ProjectId}-{RiskId}`).

- BR-8: 생성 서비스 — `createFromSource`는 REGISTERED 문제점을 만들고 ExternalKey로 멱등. GAT-004(Gate 실패·조건 항목에서 문제점 등록)와 ISS-002(QMS 이벤트)가 호출한다. ownerId·dueDate가 주어지면 BR-2 접수를 같은 트랜잭션에서 하지 않고 PM 접수 To-Do를 연다(사람이 접수를 확인).

- BR-9: 기한 — 매일 07:00 배치 `PMS_IssueDueJob`: 미종결이고 DueDate − 오늘 = 3이면 Owner 알림, 기한 경과면 Owner·PM 알림 PMS_ISSUE_OVERDUE(하루 1회), 경과 7일이면 PM 부서장·PMO 1회.

- BR-10: 편집 권한 — 상태별 섹션 편집은 UX-005 규칙으로 정한다: REGISTERED 기본 정보(등록자·PM), ACCEPTED 대책 섹션(Owner·PM), APPROVAL_REQUESTED 이후 모두 읽기(결재 잠금), APPROVED 효과 확인 섹션(Owner·PM). Status·Source 필드는 FLS 읽기.

- BR-11: 공통 기반 — 3절 표(채번·삭제 통제·상태 진행바·UX-005 규칙·필드 이력·DWH 복제·번역)를 등록한다. 기존 엑셀 문제점 목록은 그리드 붙여넣기로 이관(Source MANUAL, 상태는 REGISTERED·ACCEPTED만 허용하고 종결 건은 이관하지 않음).

**화면/UX**: 화면 유형 T1 + T2.

| 화면 | 위치 | 구성 |
| --- | --- | --- |
| PMS_Issue__c 레코드 페이지 | 생성기 정의 `meta-src/record-pages/PMS_Issue__c.json` | 헤더 7개: RecordNo, Name, Status, 프로젝트 번호(고객 자리 대체), 품번(ProjectPart 품번), ProdPlant, DueDate(D-day). 진행 단계 등록 → 접수 → 승인 요청 → 승인 → 종결. 현재 단계 탭: 상태별 섹션(BR-10), 대책서 문서 패널은 레일 DOCUMENT 패널(allowedDocClasses ISSUE_COUNTERMEASURE). 액션: "접수", "반려", "승인 요청"(레일 APPROVAL), "종결" |
| 문제점 그리드 `cmnEditableGrid` gridKey `PMS_IssueLog` | 프로젝트 레코드 페이지 "문제점" 탭 | 열: 번호(읽기), 제목, 유형(CODE ISSUE_TYPE), 심각도, 발견일, 담당, 기한, 상태(읽기), 원천(읽기), 리스크(읽기). REGISTERED 행만 편집, 그 외 행 잠금 |
| 리스크 레코드 액션 "발생 처리" | PMS_Risk__c | 빠른 작업 LWC `pmsRiskToIssue`(현상·발견일 입력 → createFromRisk → 새 문제점으로 이동) |

  Provider `PMS_IssueLogGridProvider`: `rowMeta`(REGISTERED 외 잠금, 기한 경과 경고), `validate`(필수 값), `defaults`(Reporter·DetectedDate·Severity MAJOR).

**권한**: PMS_PS_Issue_Read, PMS_PS_Issue_Edit, Custom Permission PMS_ISS_Accept(PMS_PSG_PM, PMS_PSG_PMO), PMS_ISS_Close(PMS_PSG_PMO).

**수용 기준**

- AC-1: Given CRITICAL 문제점 등록, When 저장, Then REGISTERED, PM 접수 To-Do 1건, PM·PMO·PM 부서장 알림, CREATED 이벤트 1건.

- AC-2: Given ACCEPTED, 대책서 없음(PMS_DOC), When 승인 요청, Then 차단 + 누락 항목 표시.

- AC-3: Given MAJOR·DESIGN 유형 대책 승인 요청, When 결재선 해석, Then Owner 기안 → QE 합의 → PM 승인. CRITICAL이면 마지막에 PMO_MANAGER 승인 추가.

- AC-4: Given 결재 반려, When 콜백, Then ACCEPTED, Owner 대책서 To-Do 재생성.

- AC-5: Given CloseOnApproval = true, EffectivenessResult 있음, When 승인, Then CLOSED, CLOSED 이벤트 1건, 열린 To-Do 0건.

- AC-6: Given OPEN 리스크, When 발생 처리 2회, Then 문제점 1건(Source RISK_OCCURRED, Risk 연결), 리스크 OCCURRED, OccurredIssue = 그 문제점.

- AC-7: Given 기한 경과 1일 문제점, When 배치 2회(같은 날), Then Owner·PM 알림 각 1건.

- AC-8: Given 문제점 200건 일괄 등록, When 트리거, Then 채번 중복 없음, To-Do open 1회 호출(묶음), 이벤트 200건 발행.

**에이전트 주의**: 표준 Case 객체를 쓰지 않는다(프로젝트 공유·대책서 결재·QMS 연결이 맞지 않음). 결재를 표준 Approval Process로 만들지 않는다(APV). 문제점 상태를 화면·Flow에서 직접 바꾸지 않는다. 대책서 파일을 문제점 레코드 Files 관련 목록에만 두지 않는다(DOC-001 문서·리비전).

**오픈 이슈**: SL 현행 문제점 대책서 양식과 결재선(팀장 필수 여부), "접수"를 PM만 할지 담당 팀장도 할지, 심각도 기준.

### PMS-08-ISS-002 문제점 ↔ QMS 6pi/8D·품질 이력 연계

추적 P-49, P-50 · 필수 · W2 · SF · APEX, LWC, CFG · Customization · 선행 ISS-001, RSK-001, PMS-12-INT-005, QMS-05-CLM-001, QMS-05-CLM-007, QMS-06-NCR-001, QMS-06-NCR-002, QMS-04-LEL-002, QMS-04-LEL-004 · 5 M/D

**목적**: 개발 중 문제가 QMS 고객 클레임·부적합(NCR)으로도 다뤄질 때 대책서를 QMS 8D(HKMC는 6pi 양식) 하나로 쓰고, PMS 문제점은 그 8D 상태를 따라가게 한다(P-49 "6pi/8D/품질이력 데이터 연계 단일화"). 반대로 PMS 문제점에서 QMS 부적합을 요청하고, 종결한 문제점·리스크를 레슨런 후보로 QMS에 넘겨 다음 프로젝트 체크포인트가 되게 한다.

**범위** In: QMS 클레임·NCR·8D 이벤트 핸들러(프로젝트 품번 매칭, 문제점 자동 생성·상태 반영), 8D 대책서 모드, NCR 요청(NCR 게이트웨이), NCR 원천 회신 등록(QMS_NcrSourceConfig__mdt 레코드), 레슨런 후보 공통 서비스, LESSON_CANDIDATE 이벤트, 문제점 QMS 연결 레일 패널. Out: 구독 트리거 자체(PMS-12-INT-005, 9절), 8D·6pi 작성·보고서(QMS-05 CLM-002·006), NCR 처리(QMS-06), 레슨런 작성(QMS-04 LEL), 다른 Org 중계(QMS-09-INT-021).

**데이터 모델**(PMS_Issue__c에 이 WI가 추가하는 필드)

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_Issue__c.ClaimRecordId__c / ClaimRecordNo__c | Text(18) / Text(40) | N | QMS 클레임(계약 필드 ClaimRecordId) |
| PMS_Issue__c.NcrRecordId__c / NcrRecordNo__c | Text(18) / Text(40) | N | QMS NCR(계약 필드 NcrRecordId). NCR이 회신으로 채운다(BR-6) |
| PMS_Issue__c.EightDRecordId__c / EightDRecordNo__c | Text(18) / Text(40) | N | QMS 8D(계약 필드 EightDRecordId) |
| PMS_Issue__c.QmsStatus__c | Text(40) | N | 연결 원천(클레임·NCR) 상태 사본 |
| PMS_Issue__c.EightDStatus__c / EightDCurrentStep__c | Text(20) / Text(4) | N | 8D 상태·현재 단계 사본(D1~D8) |
| PMS_Issue__c.QmsSyncedAt__c | DateTime | N | |
| PMS_Issue__c.IsLessonCandidate__c | Checkbox | N | 계약 필드. 종결 시 레슨런 후보 요청 |
| PMS_Issue__c.LessonRecordId__c / LessonRecordNo__c / LessonRequestedAt__c | Text(18) / Text(40) / DateTime | N | 게이트웨이 요청 결과 |
| PMS_Risk__c.LessonRecordId__c / LessonRequestedAt__c | Text(18) / DateTime | N | 리스크 후보 결과(RSK-002 BR-6) |
| QMS_NcrSourceConfig__mdt 레코드 PMS_Issue | Custom Metadata(Vol.6a 정의 타입) | — | SourceObject__c PMS_Issue__c, NcrIdField__c NcrRecordId__c, NcrNoField__c NcrRecordNo__c, IsActive__c true |

**서비스 API**

    // PMS_IssueQmsService
    void handleClaimEvents(List<QMS_ClaimEvent__e> events)   // INT-005 구독 트리거가 호출
    void handleNcrEvents(List<QMS_NcrEvent__e> events)
    void handleEightDEvents(List<QMS_EightDEvent__e> events)
    Id requestNcr(Id issueId, PMS_IssueNcrInput input)        // NCR 게이트웨이 requestNcr
    void linkExisting(Id issueId, String qmsType, String recordId) // 수동 연결(CLAIM, NCR)
    // PMS_LessonCandidateService (제안)
    Id request(Id sourceId)                                    // PMS_Issue__c 또는 PMS_Risk__c Id

**비즈니스 규칙**

- BR-1: 프로젝트 매칭 — 이벤트의 ItemId가 다음 조건의 PMS_ProjectPart__c.Item__c와 같으면 그 프로젝트를 대상으로 한다: 프로젝트 Status가 종료·취소가 아니고, SopDate가 비었거나 오늘 ≤ SopDate + CMN 설정 `PMS_ISS_QMS_LINK_DAYS_AFTER_SOP`(기본 90)이며, ProjectPart.ProdPlant가 비었거나 이벤트 PlantId와 같다. 여러 프로젝트가 맞으면(같은 품번 파생 프로젝트) 모두 대상이다. 조회는 이벤트 묶음당 SOQL 1회(ItemId IN).

- BR-2: 자동 생성 — 대상 프로젝트마다 `PMS_IssueService.createFromSource`로 REGISTERED 문제점을 만든다(ExternalKey `{ProjectId}-{원천 Id}` 멱등).
  - 클레임: EventType RECEIVED. Source QMS_CLAIM, 제목 = "[클레임] {RecordNo}", 심각도 = 클레임 Severity(같은 값), 유형 = ISSUE_TYPE CUSTOMER, ClaimRecordId·No. CMN 설정 `PMS_ISS_AUTO_FROM_CLAIM`(기본 true)이 false면 만들지 않고 PM 알림만.
  - NCR: EventType OPENED이고 Severity가 CMN 설정 `PMS_ISS_AUTO_FROM_NCR_SEVERITIES`(기본 A,B)에 있을 때. Source QMS_NCR, 심각도 A → CRITICAL, B → MAJOR, C → MINOR, 유형 = 원천 RecordType SUPPLIER면 SUPPLIER_PART, 아니면 PROCESS, NcrRecordId·No, EightDRecordId(이벤트 EightDId가 있으면).
  - 생성 시 CountermeasureMode = QMS_8D, 알림 PMS_ISSUE_QMS_LINKED(PM, 프로젝트 QE 역할 구성원).

- BR-3: 상태 반영 — 연결된 문제점의 QmsStatus·EightDStatus·EightDCurrentStep·QmsSyncedAt을 이벤트로 갱신한다.
  - QMS_ClaimEvent__e: 모든 EventType의 Status__c → QmsStatus. CANCELLED면 문제점이 REGISTERED·ACCEPTED일 때 PM To-Do "연결 클레임 취소 확인"(자동 반려하지 않음).
  - QMS_NcrEvent__e: Status 변화 → QmsStatus, EightDId__c가 오면 EightDRecordId 세팅.
  - QMS_EightDEvent__e: SourceRecordId가 문제점의 ClaimRecordId·NcrRecordId와 같으면 EightDRecordId·No, CurrentStep(StepNo), 상태(CLOSED·CANCELLED) 반영.
  - 이벤트를 놓쳤을 때를 위해 레일 패널 "새로 고침"과 매일 05:30 배치가 EIGHT_D 게이트웨이 `getStatus(sourceId = ClaimRecordId 또는 NcrRecordId)`로 다시 읽는다(문제점당 1회, 미종결만).

- BR-4: 8D 대책서 모드(단일화) — CountermeasureMode = QMS_8D이면 문제점의 원인·대책 입력란과 PMS 대책서 문서는 숨기고, 레일 패널에 8D 번호·현재 단계·고객 회신 보고서(DocClass EIGHTD_REPORT, HKMC면 6pi 양식) 링크를 보인다. 원인·대책 요약은 8D 상태 DTO의 값으로 화면에만 보이고 PMS에 복사 저장하지 않는다(원본은 QMS 하나).

- BR-5: 8D 모드의 승인·종결 조건 — ISS-001 BR-4 승인 요청은 EightDCurrentStep이 CMN 설정 `PMS_ISS_8D_SUBMIT_STEP`(기본 D6, 영구 대책 실행 단계) 이상이거나 8D CLOSED일 때만 허용한다. 종결(ISS-001 BR-6)은 8D CLOSED여야 하고 EffectivenessResult 기본값 = "QMS 8D {번호} 종결(D8)". 8D가 CANCELLED면 PM이 모드를 PMS_DOC로 바꿀 수 있다(코멘트 자동 기록).

- BR-6: NCR 요청 — ACCEPTED 문제점에서 "QMS 부적합 요청"(PM·QE): 입력(공장, 품번, 협력사(선택), 불량 유형, 수량, 로트, 현상, 사진 문서) → `QMS_NcrGateway gw = (QMS_NcrGateway) QMS_GatewayFactory.get('NCR'); gw.requestNcr(req)`. req: sourceType OTHER, sourceId = 문제점 Id, sourceObject 'PMS_Issue__c', sourceNo = RecordNo, recordType = 협력사가 있으면 SUPPLIER 아니면 INTERNAL, plantId, itemId, supplierId, defectTypeId, qty, lotNos, description, severity(CRITICAL → A, MAJOR → B, MINOR → C), detectedAt = DetectedDate, requestedById = 현재 사용자, documentIds. NCR이 생성되면 Vol.6a NCR-002 BR-6이 QMS_NcrSourceConfig__mdt(이 WI가 등록한 PMS_Issue 레코드)로 NcrRecordId·No를 채운다. NCR 메뉴 배포 전 기본 구현은 To-Do(QMS_NCR_REQUEST)다. 요청 후 CountermeasureMode = QMS_8D.

- BR-7: 수동 연결 — "QMS 건 연결"(PM·QE)은 QMS 클레임·NCR 레코드 Id(15·18자리, QMS 레코드 페이지에서 복사)를 받는다. QMS 객체를 SOQL하지 않으므로 번호 검색은 하지 않는다. 서버는 Id 형식과 Key Prefix가 QMS_Claim__c 또는 QMS_NCR__c인지(`Schema.getGlobalDescribe()`의 KeyPrefix 비교) 확인하고, EIGHT_D 게이트웨이 `getStatus(그 Id)`로 연결된 8D 번호·상태를 읽어 채운다(8D가 아직 없으면 공란). 번호(ClaimRecordNo·NcrRecordNo)는 사용자가 함께 입력하고 이후 이벤트가 오면 이벤트 값으로 덮어쓴다. 연결 후 CountermeasureMode = QMS_8D.

- BR-8: 레슨런 후보 — `PMS_LessonCandidateService.request(sourceId)`:
  - 대상: CLOSED 문제점(IsLessonCandidate = true) 또는 CLOSED 리스크(RSK-002 BR-6). 문제점 종결(ISS-001 BR-6) 시 IsLessonCandidate가 true면 자동 호출, 종결 후에도 PM이 "레슨런 후보로 보내기" 버튼으로 호출할 수 있다.
  - 8D 모드 문제점은 QMS 쪽 8D D7이 레슨런을 이미 요청하므로 요청하지 않고 "8D에서 레슨런 진행"을 안내한다(중복 방지).
  - 호출: `QMS_LessonLearnedGateway gw = (QMS_LessonLearnedGateway) QMS_GatewayFactory.get('LESSON_LEARNED'); Id lessonId = gw.request(req)`. req(QMS_FollowUpRequest): sourceId = 문제점·리스크 Id, sourceObject 'OTHER', sourceNo = RecordNo, title = 제목, description = 현상(리스크는 서술), plantId = 프로젝트 ProdPlant, itemId, customerId = 프로젝트 고객, requestedById = 현재 사용자, payloadJson = {sourceType: DEV_ISSUE, pmsSourceType: ISSUE 또는 RISK, origin: DEVELOPMENT, projectNo, vehicleId, devPhaseCode, rootCause, countermeasure, isVerified}.
  - 결과 Id를 LessonRecordId, LessonRequestedAt에 저장하고(번호는 getStatus로 채움) 이벤트 PMS_IssueEvent__e LESSON_CANDIDATE(문제점일 때)를 발행한다. 멱등은 LEL-002 BR-1(같은 SourceRecordId)에 맡긴다.
  - LEL-002 BR-7 매핑상 sourceObject OTHER + payloadJson.sourceType DEV_ISSUE가 레슨런 SourceType DEV_ISSUE가 된다. Vol.9 INT-021 BR-6의 'PMS_RISK'는 같은 계약으로 맞추도록 요청한다(9절).

- BR-9: 품질 이력 패널 — 문제점 레일 패널 `pmsIssueQmsPanel`(CMN_RailPanel__mdt: PMS_Issue__c, PanelKey CONTEXT_QMS, 기본 펼침)이 보인다: (a) 연결된 클레임·NCR·8D 번호·상태·현재 단계·보고서 링크, (b) 같은 품번의 미결 NCR 수(`QMS_NcrQueryService.openNcrCount`, 품번·공장 기준), (c) 유사 레슨런 상위 5건(`QMS_LeleMatchService.match`: 프로젝트 고객·제품군·부품 분류 + keywords = 문제점 제목, 결과 저장 없음)과 레슨런 링크. 미종결 8D가 있으면 `railbadge` 1.

- BR-10: 오류 격리 — 이벤트 핸들러는 레코드별로 처리하고 실패 건은 CMN_Logger ERROR와 PM To-Do "QMS 연결 실패 확인"으로 남긴다. 다른 이벤트 처리를 멈추지 않는다. QMS 게이트웨이·서비스가 없으면(기본 구현) 레일 패널에 "QMS 연결 준비 중"을 표시한다.

**화면/UX**: 화면 유형 T1(레일 패널·액션). `pmsIssueQmsPanel`(레일 패널 계약 준수), 액션 "QMS 부적합 요청"(빠른 작업 LWC `pmsIssueNcrRequest`, 입력 7개와 사진 업로드 `cmnDocumentPanel` 재사용), "QMS 건 연결", "레슨런 후보로 보내기". 8D 모드에서는 ISS-001 대책 섹션 대신 UX-005 규칙(ExtraCondition `CountermeasureMode__c=QMS_8D`)으로 8D 안내 섹션을 보인다.

**권한**: PMS_PS_Issue_Edit(요청·연결), 이벤트 핸들러는 구독 트리거의 자동화 사용자로 실행(SYSTEM_MODE 명시, sf-dev 3절). 패널 조회에 QMS_PS_Lele_Read, QMS NCR 조회 서비스 권한이 필요하다(PMS PSG 포함 요청, 9절).

**수용 기준**

- AC-1: Given 프로젝트 P1(품번 X, ProdPlant KR01, SOP 30일 후)과 종료 프로젝트 P0(품번 X), When 클레임 RECEIVED 이벤트(품번 X, KR01), Then P1에만 문제점 1건(Source QMS_CLAIM, CountermeasureMode QMS_8D), 같은 이벤트 재수신 시 1건 유지.

- AC-2: Given NCR OPENED 이벤트 Severity C(설정 A,B), When 처리, Then 문제점 생성 없음.

- AC-3: Given 연결 문제점, 8D CurrentStep D4, When 승인 요청, Then 차단(설정 D6). 8D 이벤트로 D6이 되면 승인 요청 가능.

- AC-4: Given 8D 모드 문제점, 8D 미종결, When 종결 시도, Then 차단. 8D CLOSED 이벤트 후 종결 가능, EffectivenessResult 기본 문구.

- AC-5: Given 문제점에서 NCR 요청(협력사 지정), When 게이트웨이 호출, Then requestNcr 1회(sourceType OTHER, sourceObject PMS_Issue__c, recordType SUPPLIER, severity B). NCR 회신 시뮬레이션 후 NcrRecordId 채워짐(테스트는 게이트웨이 바인딩 교체).

- AC-6: Given IsLessonCandidate = true인 PMS_DOC 모드 문제점 종결, When 처리, Then LESSON_LEARNED 게이트웨이 request 1회(sourceObject OTHER, payload sourceType DEV_ISSUE·pmsSourceType ISSUE), LessonRecordId 저장, LESSON_CANDIDATE 이벤트 1건.

- AC-7: Given 8D 모드 문제점이 레슨런 후보, When 종결, Then 게이트웨이 호출 없음, "8D에서 레슨런 진행" 안내.

- AC-8: Given 클레임 이벤트 200건(품번 50개), When 핸들러, Then 프로젝트 매칭 SOQL 1회, 문제점 insert 1회, 거버너 오류 없음.

**에이전트 주의**: QMS 객체(QMS_Claim__c, QMS_NCR__c, QMS_EightD__c)를 Lookup하거나 PMS Apex에서 SOQL하지 않는다(이벤트·게이트웨이·조회 서비스만, 계약 8절). 8D 원인·대책을 PMS 필드로 복사하지 않는다(단일화). 클레임을 PMS에서 만들지 않는다(클레임 접수는 QMS-05). QMS 이벤트 구독 트리거를 이 WI에서 따로 만들지 않는다(INT-005 구독 트리거가 이 핸들러를 호출, 9절 요청이 거절되면 그때 이 WI가 만든다).

**오픈 이슈**: 개발 단계(시작품·P1 빌드) 고객 지적을 QMS 클레임으로 등록하는지 PMS 문제점으로만 두는지(SL 현행), HKMC 6pi 양식 원본, 자동 생성 대상 NCR 심각도 기준, 같은 품번을 쓰는 여러 프로젝트에 모두 문제점을 만들지 대표 프로젝트 하나에만 만들지.

## 6. Gate 설정·일정 (GAT-001~002)

### PMS-09-GAT-001 Gate 정의·프로젝트 Gate 일정(마일스톤 통합)

추적 P-52, P-53 · 필수 · W1 · SF · DM, APEX, LWC, CFG · Customization · 선행 PMS-02-PRJ-001, PMS-02-PRJ-003, PMS-04-WBS-001, PMS-04-WBS-003, PMS-03-CFT-001, MDM-003, MDM-007, ARC-003, SEC-003, UX-003, UX-004, UX-005, UX-006, APV-001, TDO-001, NTF-001 · 5 M/D

**목적**: 회사표준 개정 결과(단계·Gate 수와 이름, D-P1)를 개발 없이 데이터로 받는 Gate 정의를 두고, 프로젝트 WBS의 Gate 마일스톤에서 Gate 일정을 만들어 고객 마일스톤과 Gate 결과를 한 화면에서 본다(P-52 "Milestone-Gate 평가 현황 통합 표시", P-53).

**범위** In: Gate 정의 객체(고객 그룹 덮어쓰기), 프로젝트 Gate 객체의 일정·상태 필드, WBS 마일스톤에서 Gate 일정 생성·날짜 동기화, 준비(PREPARING) 전환, Gate 생략 결재, 이벤트 PMS_GateEvent__e 정의와 SCHEDULED 발행, Gate 일정 그리드(마일스톤 통합), 조회 서비스. Out: 평가표 템플릿(GAT-002), 평가 수행·RAG(GAT-003), 결정·후속 조치(GAT-004), PMO 전체 보드 화면(PMS-10-DSH-002), 현재 단계 전진(PMS-02-PRJ-001, 9절).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_GateDefinition__c.GateCode__c | Text(10) | Y | G0~G9(회사표준 개정 결과로 교체 가능) |
| PMS_GateDefinition__c.Name / NameEn__c / NameZh__c | Text(80) | Y / N / N | 표시명(예: "G5 양산 준비 승인") |
| PMS_GateDefinition__c.CustomerGroup__c | Picklist (MDM-003 CustomerGroup 값) | N | 공란 = SL 표준 행. 값이 있으면 그 고객 그룹 프로젝트에서 표준 행을 덮어쓴다 |
| PMS_GateDefinition__c.DevPhase__c | Text(40) | Y | 이 Gate가 닫는 DEV_PHASE 코드 |
| PMS_GateDefinition__c.ScopePhases__c | Text(255) | N | 자동 점검 범위 단계(DEV_PHASE 코드 쉼표). 공란 = DevPhase 하나 |
| PMS_GateDefinition__c.Sequence__c | Number(3,0) | Y | 순서 |
| PMS_GateDefinition__c.QuestionnaireFamily__c | Text(40) | Y | SL 표준 평가표 Family(CMN_QuestionnaireTemplate__c Domain GATE). 계약 필드 |
| PMS_GateDefinition__c.CustomerQuestionnaireFamily__c | Text(40) | N | 고객 Gate 점검표 Family(고객 행에서만, GAT-002 BR-3) |
| PMS_GateDefinition__c.ApplicableProjectTypes__c | Multi-Picklist (NEW_MODEL, MODEL_YEAR, FACELIFT, DERIVATIVE, CARRY_OVER) | N | 공란 = 전체 |
| PMS_GateDefinition__c.IsMandatory__c | Checkbox | Y | 생략하려면 PMS_GATE_WAIVE 결재(BR-7) |
| PMS_GateDefinition__c.IsSopGate__c | Checkbox | Y | 양산 이관 Gate(GAT-006). 활성 표준 행 중 1개만 true |
| PMS_GateDefinition__c.PrepLeadDays__c | Number(3,0) | Y | 준비 시작 일수(기본 14) |
| PMS_GateDefinition__c.FollowUpDefaultDays__c | Number(3,0) | Y | 조건부 후속 조치 기본 기한 일수(기본 30, GAT-004) |
| PMS_GateDefinition__c.ApprovalTypeCode__c | Text(80) | Y | 기본 PMS_GATE_REVIEW |
| PMS_GateDefinition__c.Status__c | Picklist (ACTIVE, INACTIVE) | Y | |
| PMS_GateDefinition__c.ExternalKey__c | Text(60), External ID, Unique | Y | `{GateCode}-{CustomerGroup 또는 STD}` |
| PMS_GateReview__c.Project__c | Master-Detail(PMS_Project__c) | Y | |
| PMS_GateReview__c.RecordNo__c | Text(40), Unique, External ID | Y | GTR-{YYYY}-{SEQ:6} |
| PMS_GateReview__c.Name | Text(80) | Y | "{GateCode} {정의 Name}"(서비스 세팅) |
| PMS_GateReview__c.GateDefinition__c | Lookup(PMS_GateDefinition__c) | Y | 해석된 정의(고객 행 또는 표준 행) |
| PMS_GateReview__c.GateCode__c / DevPhase__c / Sequence__c | Text(10) / Text(40) / Number(3,0) | Y | 정의에서 복사(계약 필드 GateCode) |
| PMS_GateReview__c.IsSopGate__c | Checkbox | Y | 정의에서 복사 |
| PMS_GateReview__c.Round__c | Number(2,0) | Y | 1부터. 재심사마다 + 1(GAT-004) |
| PMS_GateReview__c.PreviousReview__c / IsCurrent__c | Lookup(PMS_GateReview__c) / Checkbox | N / Y | 같은 GateCode의 직전 회차, 최신 회차 여부 |
| PMS_GateReview__c.MilestoneActivity__c | Lookup(PMS_Activity__c) | N | 같은 GateCode의 WBS 마일스톤 액티비티 |
| PMS_GateReview__c.CustomerMilestone__c | Lookup(PMS_CustomerMilestone__c) | N | 마일스톤 액티비티에 연결된 고객 마일스톤(PRJ-003 Activity 역참조) |
| PMS_GateReview__c.CustomerMilestoneCode__c / CustomerMilestonePlanned__c / CustomerMilestoneActual__c | Formula(Text) / Formula(Date) / Formula(Date) | — | 통합 표시용 |
| PMS_GateReview__c.BaselineDate__c | Date | N | 마일스톤 액티비티 PlannedEnd(기준선) |
| PMS_GateReview__c.PlannedDate__c | Date | Y | 현재 계획일 = 마일스톤 액티비티 ForecastEnd. 계약 필드 |
| PMS_GateReview__c.ActualDate__c | Date | N | 결정일(GAT-004). 계약 필드 |
| PMS_GateReview__c.ScheduleVarianceDays__c | Formula(Number, 0) | — | PlannedDate − BaselineDate |
| PMS_GateReview__c.DaysToDue__c | Formula(Number, 0) | — | PlannedDate − TODAY()(UX-004 D-day) |
| PMS_GateReview__c.Moderator__c | Lookup(User) | N | Gate 진행자. 기본 프로젝트 PMO 역할 CFT 구성원 |
| PMS_GateReview__c.Status__c | Picklist (PLANNED, PREPARING, IN_REVIEW, APPROVAL, PASSED, CONDITIONAL, FAILED, CANCELLED) | Y | 계약 필드, 서비스로만 변경 |
| PMS_GateReview__c.CancelReason__c / WaiverApprovalId__c | Text(500) / Text(18) | CANCELLED면 Y / 필수 Gate 생략이면 Y | |
| PMS_GateReview__c.ExternalKey__c | Text(80), External ID, Unique | Y | `{ProjectId}-{GateCode}-R{Round}` |
| PMS_GateEvent__e | Platform Event(Publish After Commit) | — | GateReviewId__c, ProjectId__c, ProjectNo__c, GateCode__c, DevPhase__c, Round__c, IsSopGate__c, EventType__c(SCHEDULED, PASSED, CONDITIONAL, FAILED), PlannedDate__c, ActualDate__c, ResultRag__c, ScorePct__c, FollowUpDue__c, MilestoneActivityId__c, SourceRecordId__c(= GateReviewId), SourceObject__c('PMS_GateReview__c') |

**서비스 API**

    // PMS_GateScheduleService
    PMS_GateSyncResult syncFromWbs(Id projectId)        // 생성·날짜 동기화(멱등)
    void requestWaiver(Id gateReviewId, String reason)  // 생략 결재
    // PMS_GateQueryService (제안)
    List<PMS_GateSummaryDTO> getGateSummary(Set<Id> projectIds)
    // DTO: projectId, gateCode, name, round, status, plannedDate, baselineDate, actualDate, varianceDays,
    //      resultRag, scorePct, openFollowUps, followUpDue, customerMilestoneCode, customerMilestonePlanned
    Boolean isDecided(Id milestoneActivityId)           // PASSED·CONDITIONAL이면 true(ACT-004 완료 조건용)

**비즈니스 규칙**

- BR-1: 정의 해석 — 프로젝트의 고객 그룹(Project.Customer__r.CustomerGroup__c)과 GateCode로 (GateCode, CustomerGroup = 고객 그룹, ACTIVE) 행을 먼저 찾고 없으면 (GateCode, CustomerGroup 공란, ACTIVE) 표준 행을 쓴다. 고객 행은 표준 행 전체를 대신한다(필드별 상속 없음). "고객 행 만들기" 액션이 표준 행을 복사해 고객 행 초안을 만든다. ApplicableProjectTypes에 프로젝트 ProjectType이 없으면 그 Gate는 만들지 않는다.

- BR-2: 일정 생성 `syncFromWbs` — 프로젝트의 PMS_Activity__c 중 IsMilestone = true, GateCode가 있고 Status가 CANCELLED가 아닌 것마다:
  - 같은 GateCode의 IsCurrent 회차가 없으면 PLANNED 회차(Round 1)를 만든다(ExternalKey 멱등). Moderator 기본값, MilestoneActivity, CustomerMilestone(그 액티비티를 가리키는 PMS_CustomerMilestone__c 1건, 없으면 공란).
  - 있으면 BaselineDate = PlannedEnd, PlannedDate = ForecastEnd(없으면 PlannedEnd)로 갱신한다. 결정된 회차(PASSED·CONDITIONAL·FAILED·CANCELLED)는 날짜를 바꾸지 않는다.
  - PlannedDate가 바뀐 미결 회차와 새 회차는 PMS_GateEvent__e SCHEDULED를 발행한다.
  - 마일스톤 액티비티가 사라진(CANCELLED) PLANNED 회차는 CANCELLED(사유 "WBS 마일스톤 취소")로 바꾼다.
  - 적용 대상(BR-1) 필수 Gate인데 WBS에 마일스톤이 없으면 PM에게 To-Do "Gate 마일스톤 없음: {GateCode}"(SourceType PMS_GATE_MILESTONE_MISSING)와 알림 PMS_GATE_MILESTONE_MISSING.

- BR-3: 동기화 시점 — (a) PMS_ActivityEvent__e(DATES_CHANGED, 그리고 STARTED·COMPLETED) 구독 트리거 `PMS_ActivityEventGateSubscriber`가 이벤트의 ProjectId를 모아 프로젝트별 1회 Queueable `syncFromWbs`를 실행한다(CPM 재계산으로 이벤트가 수천 건이어도 프로젝트당 1회). (b) PMS_ProjectEvent__e STATUS_CHANGED·CLOSED 구독: 종료·취소 프로젝트의 PLANNED·PREPARING 회차를 CANCELLED. (c) 프로젝트 레코드 액션 "Gate 일정 동기화"(PM·PMO). (d) 매일 03:00 배치가 활성 프로젝트 전체를 다시 동기화(이벤트 유실 대비). 구독 트리거는 sObject 트리거 규칙과 별개로 이벤트 구독자마다 둔다(발행 WI는 구독을 구현하지 않는다).

- BR-4: 준비 전환 — 매일 06:00 배치: PLANNED 회차 중 PlannedDate − 오늘 ≤ PrepLeadDays이면 PREPARING, PM에게 To-Do "Gate 준비: {GateCode} {PlannedDate}"(SourceType PMS_GATE_PREPARE, 기한 = PlannedDate − 3일), Moderator·CFT 구성원(ACTIVE 전원) 알림 PMS_GATE_PREPARING. 사전 점검(자동 점검 미리보기)은 GAT-003 BR-9.

- BR-5: 상태 전이 소유 — PLANNED → PREPARING(이 WI), PREPARING·PLANNED → IN_REVIEW(GAT-003 평가 시작), IN_REVIEW → APPROVAL과 결정 상태(GAT-004), → CANCELLED(이 WI: 마일스톤 취소·프로젝트 종료·생략 승인). 모든 전이는 서비스 메서드로만 한다(Status FLS 읽기, UX-005 서버 검증).

- BR-6: 동시성 — 같은 프로젝트의 동기화가 겹치지 않도록 Queueable은 프로젝트 Id 기준으로 중복 실행을 건너뛴다(같은 트랜잭션 묶음 내 Set, 이미 큐에 있으면 다음 배치에 맡김). 동기화는 DML 2회(upsert 1, update 1) 이하.

- BR-7: 생략 — PM이 "Gate 생략"(Custom Permission PMS_GATE_Waive)으로 사유를 넣으면, IsMandatory가 아닌 Gate는 바로 CANCELLED, 필수 Gate는 결재 유형 PMS_GATE_WAIVE(PM 기안 → APPROVAL_ROLE PMO_MANAGER 승인) 승인 후 CANCELLED(WaiverApprovalId 기록). IN_REVIEW 이후에는 생략할 수 없다.

- BR-8: 정의 보호 — 회차에서 쓰인 정의는 삭제할 수 없고 INACTIVE만 가능하다. 정의의 GateCode·CustomerGroup은 쓰인 뒤 바꿀 수 없다(ExternalKey 고정). Name·평가표 Family·준비 일수 변경은 이후 생성·평가에만 적용된다.

- BR-9: 통합 조회 — `getGateSummary`는 IsCurrent 회차 기준으로 프로젝트당 Gate 목록을 Sequence 순서로 돌려준다(SOQL 2회 이하, 프로젝트 200개까지). PMS-10-DSH-002 PMO 보드와 이 WI의 그리드가 같은 값을 쓴다. openFollowUps·followUpDue는 GAT-004 배포 후 채워지고 그 전에는 0·공란이다.

- BR-10: 공통 기반 — 3절 표(채번·삭제 통제·상태 진행바·UX-005 규칙·필드 이력·DWH 복제·번역)를 등록한다. PMS_GateDefinition__c OWD는 Public Read Only, 편집은 PMS_PS_Gate_Admin.

**화면/UX**: 화면 유형 T6(정의) + T2(Gate 일정) + T1(회차 레코드).

| 화면 | 위치 | 구성 |
| --- | --- | --- |
| Gate 정의 리스트뷰(인라인 편집) | SL PMS 앱 메뉴 허브 "09 Gate 설정"(UX-007) | GateCode·고객 그룹·단계·순서·평가표 Family·필수·SOP·상태. "고객 행 만들기" 액션 |
| Gate 일정 그리드 `cmnEditableGrid` gridKey `PMS_GateSchedule` | 프로젝트 레코드 페이지 "Gate·마일스톤" 탭 | 행 = IsCurrent 회차(Filter IsCurrent__c=true), 순서 Sequence. 열: GateCode, 이름, 회차, 상태, 고객 마일스톤 코드, 고객 마일스톤 계획일, 기준선, 계획일, 실적일, 편차 일수, RAG, 달성률, 미결 후속 조치. 편집 열은 Moderator만. 일정 막대 보기(ScheduleStart = BaselineDate, ScheduleEnd = PlannedDate)로 마일스톤 지연을 막대 길이로 본다 |
| PMS_GateReview__c 레코드 페이지 | 생성기 정의 `meta-src/record-pages/PMS_GateReview__c.json` | 헤더 7개: RecordNo, Name, Status, 프로젝트 번호(고객 자리 대체), ResultRag(품번 자리 대체), ProdPlant, PlannedDate(D-day). 현재 단계 탭은 상태별: PREPARING 사전 점검 패널(GAT-003), IN_REVIEW 체크리스트(GAT-003), APPROVAL·결정 상태 결정 섹션(GAT-004) |

  Provider `PMS_GateScheduleGridProvider`: `rowMeta`(모든 행 삭제 불가, Moderator 외 열 잠금, 편차 > 0이고 미결이면 경고 "기준선 대비 {n}일 지연", PlannedDate < 오늘이고 미결이면 경고 "계획일 경과"), `defaults` 없음(행 추가 불가, AllowAdd false).

**권한**: PMS_PS_Gate_Read(조회), PMS_PS_Gate_Evaluate(동기화 액션), PMS_PS_Gate_Admin(정의 편집), Custom Permission PMS_GATE_Waive(PMS_PSG_PM).

**수용 기준**

- AC-1: Given BMW 프로젝트, 정의 G5-STD와 G5-BMW(ACTIVE), When syncFromWbs, Then G5 회차의 GateDefinition = G5-BMW, Name이 BMW 행 이름.

- AC-2: Given WBS 마일스톤 3개(G3·G4·G5), When syncFromWbs 2회, Then 회차 3건(Round 1), SCHEDULED 이벤트 3건(두 번째 실행은 날짜 변화 없으므로 0건).

- AC-3: Given CPM 재계산으로 G5 마일스톤 ForecastEnd가 10일 늦어짐(액티비티 이벤트 500건), When 구독 처리, Then syncFromWbs 1회, G5 PlannedDate 갱신, 편차 10, SCHEDULED 1건.

- AC-4: Given PlannedDate − 오늘 = 14, PrepLeadDays 14, When 06:00 배치, Then PREPARING, PM To-Do 1건, CFT 알림.

- AC-5: Given 필수 Gate 생략 요청, When 승인 전, Then 상태 유지. 승인 후 CANCELLED, WaiverApprovalId 기록.

- AC-6: Given CARRY_OVER 프로젝트, G1 정의 ApplicableProjectTypes = NEW_MODEL, When 동기화, Then G1 회차 생성 없음, 누락 To-Do 없음.

- AC-7: Given 프로젝트 200개, When getGateSummary, Then SOQL 2회 이하.

- AC-8: Given 결정된(PASSED) 회차, When 마일스톤 날짜 변경 동기화, Then PlannedDate 변경 없음.

**에이전트 주의**: Gate 일정을 프로젝트마다 손으로 만들지 않는다(WBS 마일스톤이 원천). PMS_Activity__c 트리거에 이 WI 로직을 넣지 않는다(다른 WI 소유, 이벤트 구독). Gate 결과로 프로젝트·액티비티 필드를 직접 바꾸지 않는다(이벤트 발행까지). 고객 마일스톤을 Gate로 바꾸지 않는다(고객 마일스톤은 PRJ-003 원천, 여기서는 연결해 보여줄 뿐).

**오픈 이슈**: 회사표준 개정 후 Gate 수·이름·단계 매핑(D-P1), 고객 그룹별 Gate 이름 차이 목록, 해외 공장 프로젝트의 Gate 진행자(PMO 역할) 지정 방식.

### PMS-09-GAT-002 Gate 평가표 템플릿(CMN 질문지 GATE)·판 관리

추적 P-54 · 필수 · W1 · SF · APEX, CFG, LWC · Customization · 선행 GAT-001, QNR-001, DOC-001, SEC-001 · 5 M/D

**목적**: SL 신제품개발 회사표준 Gate 평가표와 고객 Gate 점검표를 판(版)째 받아 CMN-00-QNR-001 공통 템플릿(Domain GATE)으로 등록하고 관리하는 규칙을 정한다. 회사표준이 26.11~27.04에 개정되므로 평가표 문항을 화면·코드에 넣지 않고, 새 판을 받으면 발효일부터 새 Gate 평가에 적용되게 한다(D-P6, 계약 6절).

**범위** In: Gate 도메인 사용 규칙(Family·UsageKeys·Scheme·답 형태·등급 규칙), 자동 점검 규칙 키 등록부 `PMS_GateCheckRule__mdt`(제안)와 키·인자 검증기, Gate RAG 계산기 `PMS_GateRagScorer`(제안, Scheme GATE_RAG), 판 수령 절차와 Gate 설정 화면, 고객 점검표 합성 규칙. Out: 템플릿 객체·편집기·CSV 가져오기·판 비교·발효(QNR-001), 자동 점검 실행·스냅숏·수행 화면(GAT-003), 이상 징후(GAT-005).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_GateCheckRule__mdt (제안) | Custom Metadata | — | 자동 점검 규칙 1개. DeveloperName = 규칙 키 |
| PMS_GateCheckRule__mdt.CheckerClass__c | Text(80) | Y | `PMS_GateAutoChecker` 구현 클래스(GAT-003) |
| PMS_GateCheckRule__mdt.Scope__c | Picklist (PHASE 단계 범위 액티비티, PROJECT 프로젝트 전체) | Y | 기본 범위. 인자 `scope:PROJECT`로 바꿀 수 있는 규칙은 AllowScopeOverride |
| PMS_GateCheckRule__mdt.AllowScopeOverride__c | Checkbox | — | |
| PMS_GateCheckRule__mdt.ParamPattern__c | Text(255) | N | 인자 형식 정규식(검증기 사용) |
| PMS_GateCheckRule__mdt.ParamHelpLabel__c / DescriptionLabel__c | Text(80) | Y | 인자 안내·설명 Custom Label |
| PMS_GateCheckRule__mdt.IsActive__c | Checkbox | — | |
| CMN_QuestionnaireScorer__mdt 레코드 GATE_RAG | Custom Metadata(QNR-001 타입) | — | Scheme__c GATE_RAG, ScorerClass__c PMS_GateRagScorer, IsActive__c true |

**Gate 도메인 템플릿 규칙**

| 항목 | SL 표준 평가표 | 고객 Gate 점검표 |
| --- | --- | --- |
| Domain / Scheme | GATE / GATE_RAG | GATE / GATE_RAG |
| Family | `SL-GDP-{GateCode}`(예: SL-GDP-G5) | `CUST-GATE-{CustomerGroup}-{고객 Gate 코드}`(예: CUST-GATE-BMW-RG3) |
| UsageKeys | GateCode(쉼표, 보통 1개) | 적용 GateCode |
| CustomerGroup | 공란 | 고객 그룹 |
| StandardRef / StandardEdition | "SL 신제품개발 프로세스" / 회사표준 판(예: Rev02) | 고객 문서명 / 고객 판 |
| TextSource | SL_WORDING | 고객 제공 양식이면 LICENSED_ORIGINAL(고객 사용 허락 근거 LicenseRef), 아니면 SL_WORDING |
| ResponsibleDept | PMO | PMO(고객 담당 PM 협의) |
| 답 형태 | COMPLIANCE, YES_NO, TEXT(QNR-001 BR-6) | 같음 |
| 문항 범위 키 ScopeKeys | DEV_ACTIVITY_TYPE 코드(해당 유형 액티비티가 프로젝트에 있을 때만 문항 포함) | 같음 |
| 자동 점검 | AutoCheckRuleKey / AutoCheckParams(아래 규칙 키) | 같음 |
| 등급 규칙 | GRADE_BAND GREEN·AMBER·RED, DOWNGRADE MANDATORY_NOT_MET_GE | 같음(고객 기준) |

**자동 점검 규칙 키(초기 등록, 구현은 GAT-003)**

| 규칙 키 | 범위 | 인자(AutoCheckParams) | MET 조건 요약 |
| --- | --- | --- | --- |
| DELIVERABLE_REGISTERED | PHASE | `code:DFMEA,DVPR` 또는 `docClass:TEST_REPORT`, 선택 `phase:DV` | 대상 산출물이 모두 제출 이상(SUBMITTED·IN_APPROVAL·APPROVED) 또는 NOT_APPLICABLE |
| DELIVERABLE_APPROVED | PHASE | 같음 | 대상 산출물이 모두 APPROVED(결재 불필요 산출물은 SUBMITTED) 또는 NOT_APPLICABLE |
| DELIVERABLE_ALL_MANDATORY | PHASE | 없음, 선택 `phase:` | 범위 액티비티의 필수 산출물이 모두 DELIVERABLE_APPROVED 기준 충족 |
| ACTIVITY_COMPLETED | PHASE | `type:OPT_DESIGN` 또는 `wbs:3.2.1`(쉼표) | 대상 액티비티가 COMPLETED(FORCE_COMPLETED는 MET + "강제 완료" 표시) |
| MILESTONE_ACHIEVED | PROJECT | `cm:P1,PPAP`(CUSTOMER_MILESTONE 코드) | 대상 고객 마일스톤 ActualDate 있음 |
| QMS_QUAL_PASS | PHASE | 선택 `type:`, `phase:` | 범위 액티비티의 QMS_QUAL_PASS 완료 조건이 모두 충족(PMS_CompletionChecker 위임) |
| QMS_LELE_NO_OPEN_MANDATORY | PHASE(`scope:PROJECT` 허용) | 선택 `scope:PROJECT` | 범위 액티비티에 미결 필수 레슨런 반영 검토 없음(PMS_CompletionChecker 위임) |
| FIELD_NOT_BLANK | PROJECT | `field:SopDate__c,ProdPlant__c`(PMS_Project__c 허용 목록) | 지정 프로젝트 필드가 모두 값 있음 |
| RISK_NO_OPEN_HIGH | PROJECT | 선택 `max:0` | 미결 HIGH 리스크 수 ≤ max, 그리고 미결 HIGH 모두 MitigationPlan 있음 |
| ISSUE_NO_OPEN | PROJECT | 선택 `sev:CRITICAL,MAJOR`, `allowApproved:true` | 해당 심각도 미결 문제점 없음(allowApproved면 APPROVED는 미결로 보지 않음) |
| PREV_GATE_CONDITIONS_CLOSED | PROJECT | 없음 | 직전 Sequence Gate가 CONDITIONAL이면 후속 조치가 모두 DONE |

인자 문법: 토큰은 `;`로, 토큰 안 값은 `,`로 나눈다. 토큰 이름이 없는 값은 `code:`로 본다. 예: `code:DFMEA,PFMEA;phase:DESIGN,PROTO`.

**비즈니스 규칙**

- BR-1: 평가표 해석 — Gate 평가 시작(GAT-003) 때 SL 표준 템플릿 = `CMN_QuestionnaireService.activeTemplate('GATE', 정의 QuestionnaireFamily, null, 시작일)`, 고객 템플릿 = 정의 CustomerQuestionnaireFamily가 있으면 `activeTemplate('GATE', 그 Family, 프로젝트 고객 그룹, 시작일)`. 템플릿 UsageKeys가 비어 있지 않은데 GateCode를 포함하지 않으면 사용하지 않고 평가 시작을 막는다(설정 오류 안내).

- BR-2: 판 수령 절차(PMO, 화면 안내 문구로 제공)
  1. 회사표준 새 판(예: Rev02)을 받으면 Gate 설정 화면에서 해당 Family의 "새 판으로 새 버전"(QNR-001 newVersion, editionChange true)을 만든다.
  2. StandardEdition·EditionIssuedDate·원문 파일(SourceDocument, DocClass QUESTIONNAIRE_SOURCE)을 넣는다.
  3. CSV(QNR-001 BR-12 형식, AutoCheckRuleKey·AutoCheckParams·PreviousItemKey·MappingType 포함)로 문항을 올린다.
  4. "규칙 키 점검"(BR-4)과 시뮬레이터(BR-5)로 확인한다.
  5. 발효일(회사표준 시행일)로 활성화한다(QNR-001 activate). 발효일 전에 시작한 Gate 평가는 이전 판 스냅숏을 끝까지 쓴다.
  6. 판 비교 결과(QNR-001 compareVersions)를 Gate 설정 화면에서 내려받아 PM 공지에 쓴다.

- BR-3: 고객 점검표 합성 — 고객 그룹 정의 행에 CustomerQuestionnaireFamily가 있으면 그 Gate 평가는 SL 표준 문항 뒤에 고객 문항을 별도 섹션(섹션 이름 = 고객 템플릿 Name)으로 붙여 한 번에 평가한다(DP4-2). 점수·등급은 템플릿별로 계산하고 최종 RAG는 둘 중 나쁜 값이다(GAT-003 BR-6). 고객 문항이 SL 표준 문항과 같은 내용이면 고객 템플릿 문항의 Guidance에 "SL 표준 {ItemNo}와 같음"을 적고 AutoCheckRuleKey를 같게 둔다(자동 점검 결과가 같게 나온다).

- BR-4: 규칙 키 검증기 `PMS_GateTemplateValidator.validate(templateId)` — 문항마다 AutoCheckRuleKey가 있으면 `PMS_GateCheckRule__mdt`에 있고 IsActive인지, AutoCheckParams가 ParamPattern에 맞는지, `field:` 값이 허용 목록(CMN 설정 `PMS_GATE_FIELD_ALLOWLIST`, 기본 SopDate__c,ProdPlant__c,StandardWbs__c,PM__c)에 있는지, `code:`·`docClass:`·`type:`·`cm:` 값이 각각 표준 산출물 코드(PMS_WbsTemplateDeliverable__c)·DOC_CLASS·DEV_ACTIVITY_TYPE·CUSTOMER_MILESTONE에 있는지 확인해 문항별 오류·경고를 돌려준다. ScopeKeys 값이 DEV_ACTIVITY_TYPE에 있는지도 본다. 결과는 Gate 설정 화면에서 보이고, 오류가 있는 템플릿을 Gate 정의에 연결하면 경고한다. QNR-001 활성화를 막는 도메인 훅은 Vol.0 변경 요청(9절)이고, 반영 전까지는 이 점검을 활성화 체크리스트(화면 안내)로 둔다.

- BR-5: Gate RAG 계산기 `PMS_GateRagScorer implements CMN_QuestionnaireScorer` — 템플릿 하나의 스냅숏과 답으로 계산한다(QNR-001 시뮬레이터와 GAT-003이 같은 클래스를 쓴다).
  - 대상 문항: AnswerType COMPLIANCE·YES_NO이고 NA가 아닌 문항(TEXT 제외).
  - 문항 점수: COMPLIANT·YES = Weight, NONCOMPLIANT·NO = 0, 미답 = 0(미답 수 별도 집계).
  - 달성률 = Σ 문항 점수 ÷ Σ 대상 문항 Weight × 100(소수 둘째 자리 반올림). 대상이 0이면 달성률 공란, 등급 공란.
  - 등급 전: GRADE_BAND(Min ≤ 달성률 < Max, 마지막 구간 Max 포함).
  - 강등: DOWNGRADE를 Sequence 순서로 적용. MANDATORY_NOT_MET_GE = IsMandatory 문항 중 NONCOMPLIANT·NO 수 ≥ Threshold, ANY_ITEM_SCORE_LE·STAR_ITEM_SCORE_LE = 해당 문항 점수 ≤ Threshold, ELEMENT_PERCENT_LT = 요소(Element)별 달성률 < Threshold. 조건이 맞고 현재 등급이 AppliesToGrades에 있으면 ResultGrade로 바꾸고 Description을 강등 사유로 남긴다. 다른 조건 값(MAJOR_FINDING_COUNT_GE 등)은 Gate에서 무시하고 경고 로그.
  - 결과: percent, gradeBeforeDowngrade, grade, downgradeReasons, elementPercents, unansweredCount, mandatoryNotMetCount.
  - 숫자 기준(구간·임계)은 모두 템플릿 등급 규칙에서 읽는다. 테스트는 가상 템플릿(예: 0~70 RED, 70~90 AMBER, 90~100 GREEN, 필수 미충족 1 이상 → RED)으로 한다.

- BR-6: 사용 중 보호 — 이미 Gate 평가에서 쓰인 템플릿 판단은 GAT-003의 `PMS_GateQuestionnaireUsageCheck`가 답한다(QNR-001 BR-10).

- BR-7: Gate 설정 화면 `pmsGateSetup`(제안) — 행 = ACTIVE Gate 정의. 열: GateCode, 고객 그룹, SL 표준 Family·발효 중 버전·판·발효일, 다음 버전(DRAFT 또는 발효 대기) 판·발효일, 고객 Family·발효 중 버전, 규칙 키 점검 결과(오류·경고 수). 행 동작: 템플릿 열기(QNR-001 편집기), 새 판 받기(BR-2 안내 대화상자 → newVersion), 규칙 키 점검, 판 비교 내려받기(CSV). 정의 연결이 없는 GATE 템플릿과 템플릿이 없는 정의를 위쪽 "설정 확인 필요"에 모은다.

**화면/UX**: 화면 유형 T6. `pmsGateSetup`은 SL PMS 앱 메뉴 허브 "09 Gate 설정" 앱 페이지(PMS_PS_Gate_Admin 보유자). 템플릿 편집·CSV·시뮬레이터·판 비교는 QNR-001 화면(Domain GATE 필터)을 연다. 휴대폰 미지원(관리 화면).

**권한**: PMS_PS_Gate_Admin + CMN_PS_Questionnaire_Admin + Custom Permission CMN_QnrAdmin_Gate(PMS_PSG_PMO). 조회는 CMN_PS_Questionnaire_Read(PMS 사내 PSG 전부에 포함 요청, 9절).

**수용 기준**

- AC-1: Given G5 정의(Family SL-GDP-G5), V1 ACTIVE, V2를 다음 달 1일 발효로 활성화, When 오늘 평가 시작(GAT-003 호출 경로), Then V1 해석. 발효일 이후 시작이면 V2.

- AC-2: Given 문항 AutoCheckRuleKey = DELIVERABLE_APPROVD(오타), When 규칙 키 점검, Then 해당 문항 오류 "등록되지 않은 규칙 키".

- AC-3: Given `field:Cost__c`(허용 목록 밖), When 점검, Then 오류.

- AC-4: Given 가상 템플릿(문항 10개 Weight 1, 필수 2개), 답 9개 COMPLIANT·필수 1개 NONCOMPLIANT, When PMS_GateRagScorer, Then 달성률 90.00, 강등 전 GREEN, 강등 후 RED, 사유 1개, mandatoryNotMetCount 1.

- AC-5: Given NA 2개·TEXT 1개 포함 문항 10개, When 계산, Then 분모는 7개 문항 Weight 합.

- AC-6: Given UsageKeys = G4인 템플릿을 G5 정의 Family로 지정, When 평가 시작 해석, Then 시작 차단과 설정 오류 안내.

- AC-7: Given QNR-001 시뮬레이터에서 Scheme GATE_RAG 템플릿 계산, When 실행, Then PMS_GateRagScorer 결과가 표시된다(CMN_QuestionnaireScorer__mdt 등록 확인).

**에이전트 주의**: Gate 문항·등급 숫자를 코드·초기 데이터 스크립트에 넣지 않는다(QNR-001 BR-9). 테스트 데이터에 고객 Gate 점검표 문구를 쓰지 않는다. 템플릿 객체를 PMS에 따로 만들지 않는다. 계산기는 상태 없는 순수 계산으로 만들고 DML을 하지 않는다.

**오픈 이슈**: 회사표준 Gate 평가표 개정판 발효일과 문항 수, 고객별 Gate 점검표 원본과 사용 허락 범위(고객 제공 양식 원문 탑재 가능 여부), 고객 점검표를 SL 표준과 같은 회의에서 평가하는지(DP4-2).

## 7. Gate 평가·결정 (GAT-003~004)

### PMS-09-GAT-003 Gate 평가 수행(체크리스트·산출물 자동 점검·RAG)

추적 P-52, P-53, P-54 · 필수 · W1 · SF · DM, APEX, LWC, CFG · Customization · 선행 GAT-001, GAT-002, QNR-001, UX-009, MTG-001, PMS-06-DLV-001, PMS-06-DLV-002, PMS-04-WBS-002, PMS-07-ACT-004, RSK-001, PMS-08-ISS-001 · 7 M/D

**목적**: Gate 평가를 시작하는 순간 발효 중인 평가표 판을 프로젝트 Gate에 스냅숏으로 복사하고, 시스템에 등록된 산출물·액티비티·QMS 조건·리스크·문제점을 규칙 키로 먼저 자동 점검한 뒤, 평가자가 UX-009 체크리스트 셸에서 확인·보완해 달성률과 RAG를 낸다(P-54 Check List DB화·등록 산출물 자동 체크, PoC 시나리오 5). PMS Gate 점검은 W1부터 UX-009 셸을 쓴다(UX-009 오픈 이슈 "적용 시점" 결정).

**범위** In: 평가 시작·스냅숏, 평가 항목 객체, 자동 점검 엔진·규칙 11개 구현, 사전 점검(미리보기), Provider `PMS_GateChecklistProvider`, 분담 배정, 답 저장·제출 검증, 점수·RAG 반영, 템플릿 사용 확인 클래스, 평가 화면 배치. Out: 평가표 템플릿·계산기(GAT-002), 결재·결정·후속 조치(GAT-004), 이상 징후 신호 생성(GAT-005, 이 WI는 신호를 읽어 표시·확인 요구만), 액티비티 완료 조건 규칙 구현(PMS-07-ACT-004).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_GateCheckItem__c.GateReview__c | Master-Detail(PMS_GateReview__c) | Y | |
| PMS_GateCheckItem__c.ItemKey__c | Text(80) | Y | 템플릿 문항 ExternalKey(계약 필드) |
| PMS_GateCheckItem__c.ItemNo__c / Sequence__c | Text(20) / Number(4,0) | Y | 계약 필드 ItemNo |
| PMS_GateCheckItem__c.SourceTemplate__c | Picklist (SL_STANDARD, CUSTOMER) | Y | 합성 출처(GAT-002 BR-3) |
| PMS_GateCheckItem__c.Element__c / SubElement__c / SectionLabel__c | Text(20) / Text(20) / Text(80) | N | 섹션(요소) |
| PMS_GateCheckItem__c.Text__c / TextEn__c / TextZh__c | Long Text(2000) | Y / N / N | 문항 문구 스냅숏(계약 필드 Text) |
| PMS_GateCheckItem__c.Guidance__c | Long Text(4000) | N | |
| PMS_GateCheckItem__c.AnswerType__c | Picklist (COMPLIANCE, YES_NO, TEXT) | Y | |
| PMS_GateCheckItem__c.Weight__c | Number(5,2) | Y | |
| PMS_GateCheckItem__c.IsMandatory__c / IsStar__c / AllowNA__c | Checkbox | Y | 계약 필드 IsMandatory |
| PMS_GateCheckItem__c.ScopeKeys__c / EvidenceKeys__c | Text(255) | N | 스냅숏 |
| PMS_GateCheckItem__c.AutoCheckRule__c / AutoCheckParams__c | Text(80) / Text(255) | N | 계약 필드 AutoCheckRule = 템플릿 AutoCheckRuleKey |
| PMS_GateCheckItem__c.PreviousItemKey__c / MappingType__c | Text(80) / Text(10) | N | 판 간 추세 비교용 스냅숏 |
| PMS_GateCheckItem__c.AutoResult__c | Picklist (MET, NOT_MET, NA, ERROR) | N | 계약 필드. 규칙 키 없으면 공란 |
| PMS_GateCheckItem__c.AutoDetail__c | Long Text(4000) | N | 판정 근거 JSON `{labelKey, params, total, met, notMetRefs:[번호]}`(화면은 사용자 언어로 렌더링) |
| PMS_GateCheckItem__c.AutoCheckedAt__c | DateTime | N | |
| PMS_GateCheckItem__c.EvidenceDeliverableIds__c | Long Text(4000) | N | 계약 필드. 점검에 쓴 산출물 Id(쉼표, 최대 100개) |
| PMS_GateCheckItem__c.AnomalyFlag__c / AnomalyAcknowledged__c | Checkbox / Checkbox | — | 증빙 산출물에 열린 이상 징후가 있음 / 평가자가 확인함(GAT-005 연동) |
| PMS_GateCheckItem__c.Answer__c | Picklist (COMPLIANT, NONCOMPLIANT, YES, NO, NA) | 제출 시 Y(TEXT 제외) | 계약 필드 Answer |
| PMS_GateCheckItem__c.AnswerText__c | Long Text(4000) | TEXT 문항 제출 시 Y | |
| PMS_GateCheckItem__c.NaReason__c | Text(255) | NA면 Y | |
| PMS_GateCheckItem__c.Score__c | Number(5,2) | — | 문항 점수(계약 필드, 계산기 기준 Weight 또는 0) |
| PMS_GateCheckItem__c.Comment__c | Long Text(4000) | BR-7 조건이면 Y | 계약 필드. 관찰 메모 |
| PMS_GateCheckItem__c.IsOverridden__c | Checkbox | — | 답이 자동 결과와 반대(MET인데 부적합, NOT_MET인데 적합) |
| PMS_GateCheckItem__c.AssignedTo__c | Lookup(User) | N | 분담(BR-4) |
| PMS_GateCheckItem__c.AnsweredBy__c / AnsweredAt__c | Lookup(User) / DateTime | N | |
| PMS_GateCheckItem__c.FollowUpActionId__c | Text(18) | N | 후속 조치 CMN_ActionItem__c Id |
| PMS_GateCheckItem__c.PhotoDocumentIds__c | Text(1000) | N | 사진·파일 CMN_Document Id(쉼표) |
| PMS_GateCheckItem__c.ExternalKey__c | Text(120), External ID, Unique | Y | `{GateReviewId}-{ItemKey}` |
| PMS_GateReview__c.TemplateId__c / TemplateVersion__c | Text(18) / Number(3,0) | IN_REVIEW 이후 Y | 계약 필드(SL 표준 템플릿) |
| PMS_GateReview__c.TemplateFamily__c / TemplateEdition__c | Text(40) / Text(40) | IN_REVIEW 이후 Y | |
| PMS_GateReview__c.CustomerTemplateId__c / CustomerTemplateVersion__c / CustomerTemplateFamily__c / CustomerTemplateEdition__c | Text(18) / Number(3,0) / Text(40) / Text(40) | 고객 점검표가 있으면 Y | |
| PMS_GateReview__c.GradeRulesJson__c | Long Text(32768) | IN_REVIEW 이후 Y | 시작 시점 등급 규칙 스냅숏(템플릿별) |
| PMS_GateReview__c.EvaluationStartedAt__c / EvaluationStartedBy__c | DateTime / Lookup(User) | IN_REVIEW 이후 Y | |
| PMS_GateReview__c.ScorePct__c / ResultRag__c | Percent(5,2) / Picklist (GREEN, AMBER, RED) | 제출 시 Y | 계약 필드 |
| PMS_GateReview__c.CustomerScorePct__c / CustomerRag__c | Percent(5,2) / Text(10) | N | 고객 점검표 결과 |
| PMS_GateReview__c.RagBeforeDowngrade__c / DowngradeReasons__c | Text(10) / Long Text(4000) | N | |
| PMS_GateReview__c.MandatoryNotMetCount__c / AutoNotMetCount__c / AutoErrorCount__c / AnomalyOpenCount__c / UnansweredCount__c | Number(4,0) | — | 서비스 갱신 |
| PMS_GateReview__c.LastAutoCheckAt__c / EvaluationSubmittedAt__c | DateTime | N | |
| PMS_GateReview__c.GateMeeting__c | Lookup(CMN_Meeting__c) | N | Gate 회의(MTG-001, MEETING_TYPE GATE_REVIEW) |
| CMN_ChecklistProvider__mdt 레코드 PMS_GateReview | Custom Metadata(UX-009 타입) | — | ObjectApiName PMS_GateReview__c, ProviderClass PMS_GateChecklistProvider |

**서비스 API**

    // PMS_GateEvaluationService
    void start(Id gateReviewId)                               // 스냅숏 + 자동 점검 큐
    void rerunAutoCheck(Id gateReviewId)
    // PMS_GateAutoCheckService
    void run(Id gateReviewId)                                 // 저장된 항목 기준(Queueable에서 호출)
    List<PMS_GateAutoCheck.PreviewRow> preview(Id gateReviewId) // 저장 없이 발효 중 템플릿으로(사전 점검)
    // 규칙 계약 (제안)
    public interface PMS_GateAutoChecker {
      Map<String, PMS_GateAutoCheck.Result> check(PMS_GateAutoCheck.Context ctx, List<PMS_GateAutoCheck.ItemRef> items);
    }
    // Context: gateReviewId, projectId, gateCode, devPhase, scopePhases(Set<String>), scopeActivityIds(Set<Id>),
    //          projectActivityIds(Set<Id>), customerGroup, asOf
    // ItemRef: itemKey, ruleKey, params(Map<String, List<String>>), isMandatory
    // Result: autoResult, detailLabel, detailParams(Map<String,Object>), evidenceIds(List<Id>), refs(List<String>)
    public interface PMS_GateAutoCheckExtension {        // (제안) BR-3 확장
      void afterRun(Id gateReviewId, List<PMS_GateCheckItem__c> items);
    }
    // PMS_GateChecklistProvider extends CMN_ChecklistDefaultProvider implements CMN_ChecklistProvider
    // PMS_GateQuestionnaireUsageCheck implements CMN_QuestionnaireUsageCheck

**비즈니스 규칙**

- BR-1: 평가 시작 `start` — `assertCanExecute(gateReviewId, 'PMS_GateReview_StartEvaluation')` 후 Status가 PLANNED·PREPARING이어야 한다(Custom Permission PMS_GATE_Start, 기본 PM·Moderator).
  - GAT-002 BR-1로 템플릿을 해석해 `CMN_QuestionnaireService.snapshot(templateId)`를 받는다(SL 표준, 있으면 고객).
  - 문항 필터: ScopeKeys가 있으면 프로젝트의 CANCELLED 아닌 액티비티 중 ActivityType이 그 목록에 있는 것이 하나 이상일 때만 포함한다. 빈 문항은 공통.
  - 문항마다 PMS_GateCheckItem__c를 만든다(SL 표준 먼저, 고객 문항은 Sequence + 10000으로 뒤에). 템플릿 Id·버전·Family·판, 등급 규칙 JSON을 회차에 기록한다.
  - Status IN_REVIEW, EvaluationStartedAt·By. 같은 트랜잭션에서 자동 점검 Queueable을 큐에 넣는다.
  - 문항이 200개를 넘으면 시작을 막는다(설정 확인 안내, 평가표 1개 = 200문항 이하 가정).

- BR-2: 점검 범위 — scopeActivityIds = 프로젝트 액티비티 중 DevPhase가 정의 ScopePhases(공란이면 DevPhase)에 있고 CANCELLED가 아닌 것. 인자 `phase:`가 있으면 그 단계로 바꾼다. projectActivityIds = 프로젝트 전체(CANCELLED 제외). 범위 산출물 = 범위 액티비티의 PMS_Deliverable__c.

- BR-3: 자동 점검 엔진 `run` — 규칙 키별로 문항을 모아 `PMS_GateCheckRule__mdt.CheckerClass__c`를 `Type.forName`으로 만들어 키당 1회 `check`를 호출한다. 클래스가 없거나 예외면 그 키의 문항은 ERROR(AutoDetail에 오류 라벨, CMN_Logger ERROR). 결과를 AutoResult·AutoDetail·EvidenceDeliverableIds·AutoCheckedAt에 저장하고 회차의 AutoNotMetCount·AutoErrorCount·LastAutoCheckAt을 갱신한다. 한 회차 처리 SOQL 20회 이하, DML 2회 이하(문항 update 1, 회차 update 1, 확장 처리 제외).
  - 확장: 저장 뒤 CMN 설정 `PMS_GATE_AUTOCHECK_EXTENSIONS`(클래스 이름 쉼표, 기본 공란)에 등록된 `PMS_GateAutoCheckExtension`(제안) 구현의 `afterRun(gateReviewId, items)`를 차례로 호출한다. GAT-005가 이상 징후 표시를 여기에 등록한다(이 WI는 GAT-005 클래스를 직접 참조하지 않는다). 확장 예외는 로그만 남기고 자동 점검 결과는 유지한다.

- BR-4: 규칙 구현(GAT-002 표의 11개, 클래스 `PMS_GateDeliverableChecker`·`PMS_GateActivityChecker`·`PMS_GateQmsChecker`·`PMS_GateProjectChecker`로 묶는다).
  - DELIVERABLE_REGISTERED·APPROVED: 대상 = 범위 산출물 중 TemplateDeliverable의 DeliverableCode가 `code:`에 있거나 Document의 DocClass 코드가 `docClass:`에 있는 것. 대상이 0건이면 문항이 필수면 NOT_MET("WBS에 해당 산출물 없음"), 아니면 NA. 하나라도 조건 미충족이면 NOT_MET, refs = 미충족 산출물의 액티비티 WBS 코드·산출물 이름. evidenceIds = 대상 산출물 Id.
  - DELIVERABLE_ALL_MANDATORY: 대상 = 범위 산출물 중 IsMandatory. 판정은 APPROVED 기준과 같다.
  - ACTIVITY_COMPLETED: 대상 = 범위 액티비티 중 `type:` 또는 `wbs:` 일치. 0건 처리는 위와 같다.
  - MILESTONE_ACHIEVED: 프로젝트 PMS_CustomerMilestone__c 중 `cm:` 코드. 없으면 NA. ActualDate가 모두 있으면 MET.
  - QMS_QUAL_PASS·QMS_LELE_NO_OPEN_MANDATORY: `PMS_CompletionRule__mdt`에서 같은 RuleKey 행의 CheckerClass(`PMS_CompletionChecker` 구현, PMS-04-WBS-002·PMS-07-ACT-004)를 찾아 범위 액티비티마다 판정하고 모두 충족이면 MET. 대상 액티비티 = `type:`이 있으면 그 유형, 없으면 표준 산출물 CompletionRuleKey가 그 키인 액티비티(QMS_LELE는 범위 전체). `scope:PROJECT`면 프로젝트 전체 액티비티. 완료 조건 행이 없으면 ERROR("완료 조건 규칙 미등록"). QMS 서비스를 이 WI에서 직접 부르지 않는다(규칙 한곳, ACT-004).
  - FIELD_NOT_BLANK: 허용 목록 필드만 USER_MODE로 읽어 모두 값이 있으면 MET.
  - RISK_NO_OPEN_HIGH: Level HIGH, Status OPEN·MITIGATING 수 ≤ max(기본 0)이면 MET. 초과하지 않았어도 MitigationPlan 공란 HIGH가 있으면 NOT_MET. refs = 리스크 번호.
  - ISSUE_NO_OPEN: 심각도 `sev:`(기본 CRITICAL,MAJOR)의 미결 문제점(REGISTERED·ACCEPTED·APPROVAL_REQUESTED, allowApproved false면 APPROVED 포함)이 0건이면 MET.
  - PREV_GATE_CONDITIONS_CLOSED: Sequence가 바로 앞인 IsCurrent 회차가 CONDITIONAL이면 그 회차를 원천으로 하는 CMN_ActionItem__c가 모두 DONE·CANCELLED일 때 MET, 앞 회차가 PASSED면 MET, 없거나 CANCELLED면 NA.

- BR-5: 자동 결과와 답 — 자동 점검이 끝나면 미답 문항에 제안 답을 넣지 않는다(사람이 확정). 셸 화면에는 자동 결과를 표시하고(BR-8), 평가자가 답을 고른다. 답이 자동 결과와 반대면 IsOverridden = true이고 관찰 메모(Comment)가 필수다. 자동 점검을 다시 실행해 결과가 바뀌면 답은 유지하고 IsOverridden만 다시 계산한다. ERROR 문항은 평가자가 수동으로 답하고 메모를 남긴다.

- BR-6: 점수·RAG — `preview`와 제출 시 템플릿별로 스냅숏 문항(PMS_GateCheckItem__c에서 재구성한 `CMN_Questionnaire.Snapshot`, 등급 규칙은 GradeRulesJson)과 답으로 `PMS_GateRagScorer`(GAT-002 BR-5)를 호출한다. ScorePct·RagBeforeDowngrade·DowngradeReasons·MandatoryNotMetCount = SL 표준 결과, CustomerScorePct·CustomerRag = 고객 결과, ResultRag = 두 등급 중 나쁜 값(RED > AMBER > GREEN). 문항 Score는 계산기 문항 점수를 저장한다.

- BR-7: 제출 검증(`saveAnswers(isFinal = true)`) — 모두 충족해야 저장한다. 실패 항목은 문항 키별 오류로 돌려준다(UX-009 BR-3).
  - TEXT 외 모든 문항에 답이 있다(NA는 AllowNA 문항만, NaReason 필수).
  - NONCOMPLIANT·NO 답과 IsOverridden 문항은 Comment가 있다.
  - 필수 문항 NONCOMPLIANT는 후속 조치(FollowUpActionId) 또는 Comment에 "후속 조치 없음 사유"가 있다(UX-009 BR-3·noFollowUpReason).
  - AnomalyFlag 문항은 AnomalyAcknowledged = true다(평가자가 "이상 징후 확인함" 체크, GAT-005).
  - AutoResult가 비어 있는 규칙 문항이 없다(자동 점검이 끝나지 않았으면 "자동 점검 진행 중" 오류).
  - 성공하면 BR-6 결과 저장, EvaluationSubmittedAt, UnansweredCount = 0. 결재 상신은 GAT-004(같은 화면 버튼).

- BR-8: Provider `PMS_GateChecklistProvider`(CMN_ChecklistDefaultProvider 상속).
  - `load`: Sheet.title = 회차 Name, recordNo = RecordNo, subtitle = 프로젝트 번호·고객·차종·SL 판(고객 판), sections = SectionLabel(고객 섹션은 "고객: {템플릿 이름}" 접두), questions = 평가 항목(key = ItemKey, no = ItemNo, text = 사용자 언어 문구(없으면 ko), isStar, answerType, allowNa, noteRequiredAtOrBelow = 0(부적합 시 메모 필수 안내), assignedToId = AssignedTo), answers = 저장된 답. 자동 결과는 UX-009 Question DTO 확장 필드(9절 Vol.0 변경 요청: autoResultLabel, autoResultSeverity, evidenceLinks)로 주고, 확장 전에는 guidance 맨 앞에 "[자동 점검: 충족/미충족/해당 없음/오류] 근거 문장"과 증빙 산출물 번호를 넣는다. editable = 회차 IN_REVIEW이고 사용자가 PM·Moderator·PMS_PS_Gate_Evaluate 보유 CFT(분담 문항만, BR-10). scoreVisible = true. photoDocClass = GATE_MINUTES.
  - `saveAnswers`: 중간 저장은 바뀐 문항만 update, isFinal은 BR-7. 답 저장 시 AnsweredBy·At, IsOverridden 계산.
  - `preview`: BR-6 결과(percent, grade, gradeBeforeDowngrade, downgradeReasons, sectionPercents, unansweredCount).
  - `raiseFollowUp`: 기본 구현(CMN_ActionItem__c, SourceRecordId = 회차 Id, SourceKey = ItemKey)을 호출하고 Id를 FollowUpActionId에 저장한다. 기한 기본 = 오늘 + 정의 FollowUpDefaultDays.

- BR-9: 사전 점검 — PREPARING에서 PM이 "사전 점검"을 누르면 `preview(gateReviewId)`가 발효 중 템플릿 문항으로 자동 점검을 저장 없이 실행해 문항별 결과(규칙 문항만)와 미충족 근거를 보인다. 평가 항목을 만들지 않고 템플릿도 고정하지 않는다. 결과 목록에서 미충족 산출물의 액티비티로 이동하는 링크와 "담당자에게 알림"(액티비티 Owner별 알림 1건) 버튼을 준다.

- BR-10: 분담 — 시작 시 문항의 AssignedTo = ScopeKeys 액티비티 유형과 일치하는 범위 액티비티 중 첫 번째(WBS 코드 순)의 Owner, 없으면 PM. PM·Moderator는 "분담 변경"으로 문항 묶음(섹션)별 담당을 바꿀 수 있다. 분담받은 사람에게 묶음 To-Do "Gate 평가 문항 {n}건: {RecordNo}"(SourceType PMS_GATE_EVALUATE, 기한 = PlannedDate − 1일) 1건, 그 사람의 문항이 모두 답해지면 닫는다. CFT 구성원은 자기 분담 문항만 저장할 수 있다(Provider가 문항 키별 오류로 거부).

- BR-11: 회의 — 회차 액션 "Gate 회의 만들기"가 CMN_Meeting__c(Category GATE_REVIEW, RelatedRecordId = 회차 Id, 참석자 = CFT ACTIVE + Moderator)를 MTG-001 서비스로 만들고 GateMeeting에 연결한다. 회의록 확정은 MTG-001 규칙을 따른다.

- BR-12: 템플릿 사용 확인 — `PMS_GateQuestionnaireUsageCheck.isUsed(templateId)`는 TemplateId 또는 CustomerTemplateId가 그 값인 회차가 있으면 true(QNR-001 BR-10 등록).

- BR-13: 화면 잠금 — APPROVAL 이후 평가 항목은 수정할 수 없다(UX-005 COMPONENT 규칙 `PMS_GateChecklist` 편집 = IN_REVIEW). 결재 반려로 IN_REVIEW로 돌아오면 다시 편집 가능.

**화면/UX**: 화면 유형 T4(UX-009 체크리스트 셸) + T1. PMS_GateReview__c 레코드 페이지 "현재 단계" 탭에 상태별로 둔다.
- PREPARING: 사전 점검 패널 `pmsGatePrecheck`(결과 표: 문항 번호, 문항, 자동 결과 아이콘+텍스트, 근거, 미충족 산출물 링크), "평가 시작" 버튼.
- IN_REVIEW: `cmnChecklistRunner`(속성 recordId, 내 분담만 기본 켬은 CFT 사용자에게만) + 상단 요약 줄(자동 미충족 수, 오류 수, 이상 징후 수, 미답 수) + 버튼 "자동 점검 다시 실행", "분담 변경", "Gate 회의 만들기". 셸 전체 화면 탭으로 열기 가능(태블릿 회의 진행).
- 휴대폰: 셸 순차 모드(UX-009 BR-1).
- 이상 징후 문항: UX-009 확장(9절 Vol.0 변경 요청)이 반영되면 카드에 경고 아이콘·"검토 필요" 텍스트·확인 체크를 보인다. 반영 전에는 상단 요약 줄의 "이상 징후 n건"이 대화상자 `pmsGateAnomalyAck`(GAT-005)를 열고, 거기서 문항별로 확인한다. 확인 체크를 TEXT 보조 문항 같은 가짜 문항으로 만들지 않는다.

**권한**: PMS_PS_Gate_Evaluate(시작·답·제출·사전 점검), PMS_PS_Gate_Read(조회), Custom Permission PMS_GATE_Start(PMS_PSG_PM, PMS_PSG_PMO). `CMN_PS_UiFramework_User`(셸 컨트롤러)는 UX-009가 준다.

**수용 기준**

- AC-1: Given G5 정의(SL 표준 V3 문항 40개, 고객 템플릿 문항 12개), ScopeKeys가 프로젝트에 없는 유형인 문항 2개, When 평가 시작, Then 평가 항목 50개(SL 38, 고객 12), TemplateVersion 3·CustomerTemplateVersion 기록, IN_REVIEW, 자동 점검 큐 1건.

- AC-2: Given 평가 시작 후 SL 표준 V4 활성화, When 평가 항목 조회, Then V3 문항 그대로(AC-5 QNR-001과 같음).

- AC-3: Given DELIVERABLE_APPROVED `code:DFMEA` 문항, 범위 DFMEA 산출물 2건 중 1건 SUBMITTED(결재 필요), When 자동 점검, Then NOT_MET, refs에 해당 산출물, EvidenceDeliverableIds 2개.

- AC-4: Given 같은 문항, 범위에 DFMEA 산출물 없음, 문항 필수, When 자동 점검, Then NOT_MET("WBS에 해당 산출물 없음"). 비필수면 NA.

- AC-5: Given QMS_LELE_NO_OPEN_MANDATORY 문항, PMS_CompletionRule__mdt 행 없음, When 자동 점검, Then ERROR, 다른 규칙 문항은 정상 판정.

- AC-6: Given 자동 결과 NOT_MET 문항에 COMPLIANT 답·메모 없음, When 제출, Then 해당 문항 오류. 메모 입력 후 제출 성공, IsOverridden = true.

- AC-7: Given 가상 템플릿 등급 규칙(90 이상 GREEN, 필수 미충족 1 이상 RED), 모든 문항 적합·고객 템플릿 AMBER, When 제출, Then ScorePct 100, SL 등급 GREEN, CustomerRag AMBER, ResultRag AMBER.

- AC-8: Given CFT 사용자에게 분담된 문항 5개, When 다른 문항 답 저장, Then 문항 키별 오류. 자기 문항 5개를 모두 답하면 PMS_GATE_EVALUATE To-Do DONE.

- AC-9: Given PREPARING 회차, When 사전 점검, Then 평가 항목 0건 유지, 규칙 문항별 결과 표시.

- AC-10: Given 규칙 문항 120개(산출물 300개 프로젝트), When 자동 점검 Queueable, Then SOQL 20회 이하, DML 2회, 거버너 오류 없음.

- AC-11: Given AnomalyFlag 문항 미확인, When 제출, Then 오류 "이상 징후 확인 필요".

**에이전트 주의**: 평가표 문항을 PMS 코드·초기 데이터에 두지 않는다(템플릿 스냅숏만). 평가 화면을 새로 만들지 않는다(UX-009 셸 + Provider). 점수·RAG를 LWC나 Provider 안에서 따로 계산하지 않는다(PMS_GateRagScorer 하나). 자동 결과로 답을 자동 확정하지 않는다(사람 확정). QMS 서비스·객체를 이 WI의 규칙 클래스에서 직접 부르지 않는다(완료 조건 규칙 위임). 이상 징후를 이유로 문항을 자동 부적합 처리하지 않는다.

**오픈 이슈**: Gate 평가 분담을 액티비티 담당으로 자동 배정할지 PMO가 직접 배정할지, 평가표 1개 문항 수 상한(200), 고객 점검표 문항과 SL 문항의 중복 처리.

### PMS-09-GAT-004 Gate 결재·조건부 통과·후속 조치

추적 P-52, P-53 · 필수 · W1 · SF · APEX, LWC, CFG · Customization · 선행 GAT-003, RSK-001, PMS-08-ISS-001, PMS-12-APV-001, APV-001, APV-002, APV-003, MTG-001, TDO-001, NTF-001, UX-005, UX-006 · 5 M/D

**목적**: 평가 결과(RAG)를 근거로 통과·조건부 통과·실패를 결재로 확정하고, 조건부 통과의 조치를 기한과 담당이 있는 후속 조치로 추적한다. 실패하면 재심사 회차를 만들어 Gate 이력(P-52 "수행 결과 이력")을 남긴다.

**범위** In: 결정 필드, 제안 결정 규칙, 결재 유형·결재선 기여·콜백, PMS_GateEvent__e PASSED·CONDITIONAL·FAILED 발행, 후속 조치(CMN_ActionItem__c) 관리·기한 알림, 조건 → 리스크·문제점 등록, 재심사 회차. Out: 프로젝트 현재 단계 전진·마일스톤 액티비티 완료(PMS-02-PRJ-001, PMS-07-ACT-004, 9절), SOP Gate 후속(GAT-006).

**데이터 모델**(PMS_GateReview__c에 이 WI가 추가하는 필드)

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_GateReview__c.ProposedDecision__c | Picklist (PASS, CONDITIONAL, FAIL) | — | ResultRag로 제안(BR-1) |
| PMS_GateReview__c.Decision__c | Picklist (PASS, CONDITIONAL, FAIL) | 상신 시 Y | 상신자가 고른 결정 |
| PMS_GateReview__c.IsLenientDecision__c | Checkbox | — | 제안보다 완화된 결정(BR-2) |
| PMS_GateReview__c.DecisionComment__c | Long Text(4000) | 상신 시 Y | 결정 근거 |
| PMS_GateReview__c.Conditions__c | Long Text(4000) | CONDITIONAL이면 Y | 조건 요약(계약 필드) |
| PMS_GateReview__c.FollowUpDue__c | Date | CONDITIONAL이면 Y | 후속 조치 최종 기한(계약 필드, 조치 DueDate 최댓값) |
| PMS_GateReview__c.FollowUpOpenCount__c | Number(4,0) | — | 미결 후속 조치 수(서비스 갱신) |
| PMS_GateReview__c.ConditionStatus__c | Picklist (NONE, OPEN, OVERDUE, CLOSED) | Y | 기본 NONE |
| PMS_GateReview__c.ConditionsClosedAt__c | DateTime | N | |
| PMS_GateReview__c.ApprovalRequestId__c | Text(18) | N | 최신 결재 요청 |
| PMS_GateReview__c.DecidedAt__c | DateTime | N | ActualDate(GAT-001 필드) = 결정일 |

**비즈니스 규칙**

- BR-1: 제안 결정 — ResultRag GREEN → PASS, AMBER → CONDITIONAL, RED → FAIL. 제출(GAT-003 BR-7) 직후 서비스가 ProposedDecision을 넣는다.

- BR-2: 결정 선택 — 상신자는 제안과 같거나 더 엄격한 결정을 자유롭게 고른다(PASS 제안 → PASS·CONDITIONAL·FAIL). 제안보다 완화(RED인데 CONDITIONAL, AMBER인데 PASS)는 DecisionComment 200자 이상과 결재선 추가 단계(BR-4)를 조건으로 허용하고 IsLenientDecision = true로 남긴다. RED → PASS는 허용하지 않는다.

- BR-3: 상신 — 회차 IN_REVIEW, 평가 제출 완료(EvaluationSubmittedAt 있음) 상태에서 "결정 상신"(Custom Permission PMS_GATE_Decide: PM·Moderator). `assertCanExecute(id, 'PMS_GateReview_SubmitDecision')`. CONDITIONAL이면 후속 조치가 1개 이상 있고 모두 담당·기한(≤ 다음 Gate PlannedDate, 다음 Gate가 없으면 제한 없음)이 있어야 한다. 결재 유형 PMS_GATE_REVIEW(정의 ApprovalTypeCode)로 상신한다. Summary 스냅숏: GateCode·회차·판·달성률·RAG·강등 사유·자동 미충족 문항·IsOverridden 문항·이상 징후 확인 문항·결정·조건·후속 조치 목록.

- BR-4: 결재선 — 기본 템플릿(이 WI 초기 데이터, APV-002): 기안 PM → PROJECT_ROLE QE 합의 → APPROVAL_ROLE PMO_MANAGER 검토 → APPROVAL_ROLE BU_HEAD 승인(프로젝트 ProdPlant 기준). 결재선 기여 `PMS_GateApprovalContributor`(CMN_ApprovalLineContributor): IsLenientDecision이거나 IsSopGate이면 BU_HEAD 승인이 필수 단계로 고정되고, 그 외 GREEN·PASS는 PMO_MANAGER 승인으로 끝내도록 BU_HEAD 단계를 CC로 바꾼다. PROJECT_ROLE 해석은 PMS-12-APV-001.

- BR-5: 콜백 `PMS_GateApprovalCallback` — onSubmitted → APPROVAL. onApproved → Decision에 따라 PASSED·CONDITIONAL·FAILED, ActualDate = 승인일(공장 시간대), DecidedAt, CONDITIONAL이면 ConditionStatus OPEN·FollowUpDue 계산, 이벤트 PMS_GateEvent__e(EventType = 결정, ResultRag, ScorePct, FollowUpDue), 알림 PMS_GATE_RESULT(CFT ACTIVE 전원, PM 부서장, PMO), 열린 PMS_GATE_* To-Do 닫기. onRejected·onRecalled → IN_REVIEW(평가 수정 가능, GAT-003 BR-13), 상신자 알림.

- BR-6: 후속 조치 — CMN_ActionItem__c(SourceRecordId = 회차 Id, SourceKey = 문항 ItemKey 또는 'DECISION')를 쓴다. 평가 중 문항에서 만든 조치(GAT-003 BR-8)와 결정 섹션에서 추가한 조치가 같은 목록이다. 조치 To-Do·알림은 MTG-001 BR-3 그대로. 매일 07:30 배치 `PMS_GateFollowUpJob`: CONDITIONAL 회차마다 미결 수(FollowUpOpenCount) 갱신, 모두 DONE·CANCELLED면 ConditionStatus CLOSED·ConditionsClosedAt, 기한 경과 조치가 있으면 OVERDUE와 알림 PMS_GATE_FOLLOWUP_OVERDUE(조치 담당·PM, 경과 7일이면 PMO_MANAGER 1회).

- BR-7: 조건 → 리스크·문제점 — 후속 조치 행의 "리스크로 등록"은 `PMS_RiskService.createFromSource`(Source GATE_CONDITION, sourceId = 조치 Id, 제목 = 조치 제목, P·I 사용자 입력), "문제점으로 등록"은 `PMS_IssueService.createFromSource`(Source GATE)를 부르고 생성 번호를 조치 설명 끝에 남긴다. 실패 결정 시 RED 강등 사유가 된 필수 문항마다 문제점 등록을 제안하는 체크 목록을 보인다(선택한 것만 생성).

- BR-8: 재심사 — FAILED 회차에서 "재심사 준비"(PMS_GATE_Start): 새 회차(Round + 1, PreviousReview = 원 회차, PREPARING, 같은 정의·마일스톤, PlannedDate = 입력한 재심사일)를 만들고 원 회차 IsCurrent = false. 일정 영향은 PM이 일정 변경 요청(PMS-04-WBS-006)으로 처리하도록 안내 링크를 준다. CONDITIONAL 회차는 재심사하지 않는다(조치 완료로 닫는다).

- BR-9: 결정 후 잠금 — PASSED·CONDITIONAL·FAILED 회차는 결정·평가 필드를 고칠 수 없다(KeepLockedAfterApproval true, UX-005). 후속 조치 추가·변경만 PM·Moderator가 할 수 있다.

- BR-10: 이력 — 회차 레코드 페이지 "이력" 탭에 결재 이력(APV-003)과 같은 GateCode 이전 회차 목록(Round, 결정, RAG, 달성률, 결정일)을 보인다.

- BR-11: 결정 확장 — 인터페이스 `PMS_GateDecisionExtension`(제안): `List<String> validateSubmit(Id gateReviewId)`(상신 차단 사유 라벨 목록), `void onDecided(Id gateReviewId, String decision)`. CMN 설정 `PMS_GATE_DECISION_EXTENSIONS`(클래스 이름 쉼표, 기본 공란)에 등록된 구현을 BR-3 상신 검증 끝과 BR-5 onApproved 끝에서 호출한다. onDecided는 콜백 트랜잭션과 분리된 Queueable `PMS_GateDecisionExtensionJob`에서 호출해 확장 실패가 결재 결과를 되돌리지 않게 한다. GAT-006이 SOP 이관을 여기에 등록한다(이 WI는 GAT-006 클래스를 직접 참조하지 않는다).

**화면/UX**: 화면 유형 T1 + T2.
- 결정 섹션(현재 단계 탭, IN_REVIEW에서 제출 후·APPROVAL·결정 상태): 결과 요약(SL·고객 달성률, RAG, 강등 사유, 자동 미충족·재정의·이상 징후 확인 문항 수), 제안 결정, 결정 선택, 결정 근거, 조건 요약.
- 후속 조치 그리드 `cmnEditableGrid` gridKey `PMS_GateFollowUp`(행 객체 CMN_ActionItem__c, ParentField SourceRecordId__c — UX-006 텍스트 부모 필드 허용 요청, 9절). 열: 제목(Description), 담당(Owner), 기한(DueDate), 상태, 원천 문항(SourceKey, 읽기), 동작(리스크로 등록·문제점으로 등록 행 버튼은 Provider rowMeta가 아닌 그리드 위 "선택 행 → 리스크 등록" 버튼). Provider `PMS_GateFollowUpGridProvider`: validate(담당·기한 필수, 기한 ≤ 다음 Gate 계획일), afterSave(FollowUpDue·FollowUpOpenCount 재계산).
- 결재: 레일 APPROVAL 패널(cmnApprovalLine, typeCode PMS_GATE_REVIEW).

**권한**: PMS_PS_Gate_Evaluate(결정 섹션 입력), Custom Permission PMS_GATE_Decide(상신, PMS_PSG_PM·PMS_PSG_PMO), PMS_GATE_Start(재심사). 후속 조치는 CMN_ActionItem__c 권한(MTG-001)을 따른다.

**수용 기준**

- AC-1: Given ResultRag AMBER, When 제출, Then ProposedDecision CONDITIONAL. 상신자가 PASS 선택 시 근거 200자 미만이면 차단, 200자 이상이면 IsLenientDecision true, 결재선에 BU_HEAD 승인 고정.

- AC-2: Given RED, When PASS 선택, Then 차단.

- AC-3: Given CONDITIONAL, 후속 조치 0건, When 상신, Then 차단. 조치 2건(기한 다음 Gate 이전) 후 상신 성공, APPROVAL.

- AC-4: Given CONDITIONAL 승인, When 콜백, Then Status CONDITIONAL, ConditionStatus OPEN, FollowUpDue = 두 조치 기한 중 늦은 날, PMS_GateEvent__e CONDITIONAL 1건, PMS_GATE_RESULT 알림.

- AC-5: Given 조치 1건 기한 경과, When 07:30 배치, Then OVERDUE, 담당·PM 알림. 두 조치 DONE 후 배치에서 CLOSED.

- AC-6: Given FAILED 회차, When 재심사 준비, Then Round 2 PREPARING, 원 회차 IsCurrent false, Gate 일정 그리드에 Round 2 표시.

- AC-7: Given 결재 반려, When 콜백, Then IN_REVIEW, 평가 항목 편집 가능.

- AC-8: Given 조치 행 "리스크로 등록", When 실행, Then 리스크 1건(Source GATE_CONDITION, SourceRecordId = 조치 Id), 다시 실행해도 1건.

**에이전트 주의**: 결정 결과로 PMS_Project__c·PMS_Activity__c를 직접 갱신하지 않는다(이벤트 발행까지, 구독은 소유 WI). 표준 Approval Process를 쓰지 않는다. 후속 조치 전용 객체를 새로 만들지 않는다(CMN_ActionItem__c). 결정 이벤트에 새 EventType을 추가하지 않는다(계약 9절 4개).

**오픈 이슈**: Gate 결재선(사업부장 승인이 모든 Gate인지 SOP Gate만인지), 완화 결정 허용 여부와 근거 길이, 조건부 후속 조치 기한 상한.

## 8. 이상 징후·양산 이관 (GAT-005~006)

### PMS-09-GAT-005 산출물 이상 징후 탐지(데이터 대조·AI)

추적 P-54 · 필수 · W2 · SF, AF · DM, APEX, LWC, AGENT · Customization · 선행 GAT-003, PMS-06-DLV-001, PMS-06-DLV-002, DOC-001, AI-001, AI-002, AI-004, QMS-02-DVQ-005, UX-004 · 5 M/D

**목적**: P-54의 "거짓 문서 판별·산출물 수준(적절성) 평가"를 실현 가능한 범위로 좁혀, 등록된 산출물에서 이상 신호를 찾아 "검토 필요"로 표시하고 검토자에게 알린다. 문서가 진짜인지 판정하지 않으며 자동으로 불합격시키지 않는다. 가장 믿을 만한 신호는 규칙 기반 데이터 대조(같은 파일 해시, 빈 양식, 다른 시스템 기록 없음)이고, 내용 불일치는 AI가 보조한다.

**범위** In: 산출물 이상 상태 필드(AnomalyStatus, 계약 표기), 신호 객체, 규칙 메타데이터, 규칙 신호 6종 탐지, AI 신호 3종(기능 스위치, UseCase PMS_DOC_ANOMALY), 탐지 시점(배치·수동·Gate 자동 점검 확장), 검토(확인·기각) 화면과 To-Do, Gate 평가 항목 표시 연동. Out: 산출물 등록·결재(PMS-06), Gate 판정(GAT-003·004), 문서 색인(AI-002), 프롬프트 공통 기반(AI-001).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_Deliverable__c.AnomalyStatus__c | Picklist (NONE, REVIEW_REQUIRED, CONFIRMED_OK, CONFIRMED_ISSUE) | Y | 계약 필드(GAT-005). 기본 NONE, 서비스로만 변경 |
| PMS_Deliverable__c.AnomalyCheckedAt__c | DateTime | N | 마지막 탐지 시각 |
| PMS_Deliverable__c.AnomalyCheckedRevision__c | Text(18) | N | 탐지한 CMN_DocumentRevision__c Id(같은 리비전 재탐지 생략) |
| PMS_DeliverableAnomaly__c (제안).Deliverable__c | Master-Detail(PMS_Deliverable__c) | Y | |
| PMS_DeliverableAnomaly__c.Project__c | Lookup(PMS_Project__c) | Y | 조회·집계용(공유는 부모 따름) |
| PMS_DeliverableAnomaly__c.SignalType__c | Picklist (DUPLICATE_FILE 다른 프로젝트와 같은 파일, EMPTY_TEMPLATE 빈 양식, NAME_MISMATCH 파일명에 다른 프로젝트·차종, STALE_DATE 날짜 이상, SYSTEM_RECORD_MISSING 다른 시스템 기록 없음, RESULT_MISMATCH 결과 불일치, CONTENT_PROJECT_MISMATCH 내용상 프로젝트·차종 불일치, MANDATORY_SECTION_MISSING 필수 항목 누락, CONTENT_DATE_MISMATCH 내용상 날짜 불일치) | Y | 앞 6개 규칙, 뒤 3개 AI |
| PMS_DeliverableAnomaly__c.Method__c | Picklist (RULE, AI) | Y | |
| PMS_DeliverableAnomaly__c.RevisionId__c | Text(18) | Y | 대상 리비전 |
| PMS_DeliverableAnomaly__c.DetailLabel__c / DetailParams__c | Text(80) / Long Text(4000) | Y / N | 사용자 언어 설명 라벨 + 치환 JSON(예: 원본 프로젝트 번호) |
| PMS_DeliverableAnomaly__c.RelatedRecordId__c / RelatedRecordNo__c | Text(18) / Text(40) | N | 비교 대상(원본 리비전·다른 프로젝트·QMS 계획) |
| PMS_DeliverableAnomaly__c.AiRecommendationId__c | Text(18) | AI면 Y | CMN_AiRecommendation__c Id |
| PMS_DeliverableAnomaly__c.Confidence__c | Number(5,4) | AI면 Y | |
| PMS_DeliverableAnomaly__c.Status__c | Picklist (OPEN, DISMISSED, CONFIRMED) | Y | |
| PMS_DeliverableAnomaly__c.ReviewedBy__c / ReviewedAt__c / ReviewComment__c | Lookup(User) / DateTime / Text(1000) | 판정 시 Y | 기각·확인 사유 |
| PMS_DeliverableAnomaly__c.ExternalKey__c | Text(80), External ID, Unique | Y | `{RevisionId}-{SignalType}`(같은 리비전 같은 신호 1건) |
| PMS_AnomalyRule__mdt (제안) | Custom Metadata | — | DeveloperName = SignalType. Method__c, IsActive__c, DocClasses__c(대상 DocClass 쉼표, 공란 = 전체), Params__c(JSON, 예: 날짜 허용 일수), Severity__c(HIGH, MEDIUM) |
| CMN_AiRecommendation__c.UseCase__c 값 PMS_DOC_ANOMALY | Picklist 값(Vol.0 변경 요청) | — | AI 신호 기록 |

**서비스 API (`PMS_AnomalyDetectionService`)**

    void detect(Set<Id> deliverableIds, Boolean includeAi)   // Queueable 진입
    void review(Id anomalyId, String decision, String comment) // DISMISSED / CONFIRMED
    // GAT-003 자동 점검 확장(PMS_GateAutoCheckExtension 구현, BR-8)
    void afterRun(Id gateReviewId, List<PMS_GateCheckItem__c> items)

**비즈니스 규칙**

- BR-1: 탐지 시점 — (a) 매일 02:30 배치: 전날 이후 리비전이 바뀐 산출물(Status SUBMITTED·IN_APPROVAL·APPROVED) 중 AnomalyCheckedRevision이 현재 리비전과 다른 것. (b) 산출물 레코드 액션 "이상 징후 점검"(산출물 담당·PM·PMO). (c) Gate 자동 점검(GAT-003 BR-3) 확장: 범위 산출물 중 아직 탐지하지 않은 리비전을 탐지한 뒤 평가 항목에 표시(BR-8). 같은 리비전은 다시 탐지하지 않는다(수동 "다시 점검"은 예외, 기존 OPEN 신호 유지).

- BR-2: 규칙 신호(Method RULE)
  - DUPLICATE_FILE: 리비전 `IsDuplicateFile__c = true`이고 `DuplicateOfRevision__c`의 문서 ParentRecordId가 다른 프로젝트 소속 레코드(다른 프로젝트 산출물)일 때. RelatedRecord = 원본 프로젝트·산출물(DOC-001 BR-5 해시 근거). 같은 프로젝트 안 재사용은 신호 없음.
  - EMPTY_TEMPLATE: 리비전 FileHash가 CMN_DocTemplate__c 양식 파일(활성)의 해시와 같을 때(양식을 받은 그대로 올림). 양식 해시는 배치가 양식 ContentVersion에서 계산해 캐시(Platform Cache 24시간)한다.
  - NAME_MISMATCH: 파일명에 다른 활성 프로젝트의 RecordNo 또는 다른 차종 코드(CMN_Vehicle__c 코드, 프로젝트 차종 제외)가 들어 있을 때. 코드 3자 이하 차종은 제외(오탐 방지).
  - STALE_DATE: 리비전 업로드일이 액티비티 ActualStart보다 CMN 설정 일수(PMS_AnomalyRule__mdt Params daysBeforeStart, 기본 30) 이상 이를 때, 또는 파일의 원본 수정일(ContentVersion ContentModifiedDate)이 프로젝트 OrderConfirmedDate보다 이를 때.
  - SYSTEM_RECORD_MISSING: DeliverableType SYSTEM_LINK인데 SystemRecordId가 비었거나, DocClass TEST_REPORT·DVPR 산출물의 액티비티에 대해 `QMS_QualPlanService.getStatusBySource(activityId)`가 계획 없음을 돌려줄 때(시험 성적서는 있는데 QMS 인정시험 기록 없음).
  - RESULT_MISMATCH: 같은 경우 QMS 계획이 있는데 판정이 FAIL이거나 아직 판정 전(CLOSED 아님)인데 산출물이 APPROVED일 때.
  - 규칙별 사용 여부·대상 DocClass는 PMS_AnomalyRule__mdt로 끈다.

- BR-3: AI 신호(Method AI) — 기능 스위치 `PMS_AI_DOC_ANOMALY`가 켜지고 리비전 IndexStatus = INDEXED(AI-002)이며 DocClass가 규칙 대상일 때만 실행한다. Prompt Template `PMS_DocAnomalyCheck`(AI-001 Trust Layer)에 문서 본문 발췌(색인 청크, 최대 8,000자)와 기대 값(프로젝트 번호·이름, 고객, 차종, 품번, 액티비티 기간, 표준 양식의 필수 항목 목록 = CMN_DocTemplate__c 연결 문서에서 관리자가 지정한 라벨 목록 Params requiredSections)을 넣고, 응답 JSON `{signals:[{type, evidenceText, confidence}]}`를 받는다. confidence ≥ CMN 설정 `PMS_ANOMALY_AI_MIN_CONF`(기본 0.7)인 신호만 저장한다. 모든 AI 결과는 `CMN_AiRecommendationService.record('PMS_DOC_ANOMALY', deliverableId, recs)`로 기록하고 Id를 AiRecommendationId에 둔다. 판정(BR-5)은 decide(ADOPTED = CONFIRMED, EXCLUDED = DISMISSED, 사유 코드 AI_EXCLUDE_REASON)로 AI-004에 남긴다.

- BR-4: 상태 — 신호가 하나라도 OPEN이면 산출물 AnomalyStatus = REVIEW_REQUIRED. 모든 신호가 DISMISSED면 CONFIRMED_OK, 하나라도 CONFIRMED면 CONFIRMED_ISSUE. 새 리비전이 올라오면 이전 리비전 신호는 그대로 두고 상태는 새 리비전 탐지 결과로 다시 정한다. 이 상태는 산출물 결재(PMS-06-DLV-002)를 막지 않는다.

- BR-5: 검토 — 신호가 생기면 검토자에게 To-Do "산출물 이상 징후 검토: {산출물 이름}"(SourceType PMS_GATE_ANOMALY_REVIEW, 기한 3일)과 알림 PMS_GATE_ANOMALY. 검토자 = 진행 중(PREPARING·IN_REVIEW) Gate 회차의 Moderator, 없으면 프로젝트 PMO 역할 CFT 구성원, 없으면 PM. 산출물 담당에게는 알림만. 검토자(Custom Permission PMS_GATE_AnomalyReview)가 `review`: DISMISSED(사유 필수, 예: "같은 협력사 공용 성적서로 확인") 또는 CONFIRMED(사유 필수). CONFIRMED면 산출물 담당에게 To-Do "산출물 보완: {이름}"과 PM 알림. 자동으로 산출물 상태를 바꾸거나 반려하지 않는다.

- BR-6: 오탐 관리 — 같은 프로젝트·같은 SignalType이 3회 연속 DISMISSED면 다음 탐지부터 그 프로젝트에서 해당 규칙을 7일 동안 건너뛰고 PMO에게 "규칙 조정 검토" 알림을 1회 보낸다(규칙 자체는 PMS_AnomalyRule__mdt에서 관리자가 끈다).

- BR-7: 성능 — 배치는 산출물 200건 단위. 규칙 신호는 산출물 200건당 SOQL 8회 이하, AI 신호는 Queueable 체인으로 1건씩(콜아웃 한도), 하루 상한 CMN 설정 `PMS_ANOMALY_AI_DAILY_MAX`(기본 300건).

- BR-8: Gate 연동 — `afterRun`(GAT-003이 CMN 설정 `PMS_GATE_AUTOCHECK_EXTENSIONS`에 등록된 확장 클래스를 자동 점검 끝에 호출): 평가 항목의 EvidenceDeliverableIds 중 AnomalyStatus REVIEW_REQUIRED인 산출물이 있으면 AnomalyFlag = true(없으면 false, 확인 체크는 유지), 회차 AnomalyOpenCount 갱신. 평가자가 확인 체크(AnomalyAcknowledged)를 하려면 해당 신호 목록을 본 기록이 있어야 한다(대화상자 열람 시 서버 기록).

- BR-9: 표시 문구 — 화면·알림은 "이상 징후"·"검토 필요"만 쓴다. "위조", "거짓", "부정" 같은 판정 표현을 쓰지 않는다(라벨 검사 테스트 포함).

**화면/UX**: 화면 유형 T1(레일 패널) + T4 연동.
- 산출물 레코드 레일 패널 `pmsDeliverableAnomalyPanel`(CMN_RailPanel__mdt: PMS_Deliverable__c, PanelKey CONTEXT_ANOMALY, REVIEW_REQUIRED면 펼침): 신호 목록(종류, 설명, 비교 대상 링크, 방법 RULE·AI 표시, 신뢰도), 검토자에게는 "확인"·"기각" 버튼(사유 입력). OPEN 수를 `railbadge`로 알린다.
- Gate 평가(GAT-003): 상단 요약 줄 "이상 징후 n건" → 대화상자 `pmsGateAnomalyAck`(문항별 증빙 산출물의 신호 목록, 문항별 "확인함" 체크).
- 리스트뷰 "검토 필요 산출물"(AnomalyStatus = REVIEW_REQUIRED, PMO용).

**권한**: PMS_PS_Gate_Read(신호 조회, 산출물 읽기 권한 필요), Custom Permission PMS_GATE_AnomalyReview(PMS_PSG_PMO, PMS_PSG_PM), PMS_DeliverableAnomaly__c 편집은 서비스만. AI 실행 사용자 권한은 AI-001 기준.

**수용 기준**

- AC-1: Given 프로젝트 P2 산출물 리비전의 해시가 P1 산출물 리비전과 같음(IsDuplicateFile true), When 탐지, Then DUPLICATE_FILE 신호 1건(RelatedRecordNo = P1 번호), AnomalyStatus REVIEW_REQUIRED, 검토자 To-Do 1건.

- AC-2: Given 같은 프로젝트 안 재사용 파일, When 탐지, Then 신호 없음.

- AC-3: Given 양식 파일 그대로 업로드, When 탐지, Then EMPTY_TEMPLATE 1건.

- AC-4: Given DVPR 산출물 APPROVED, 액티비티에 QMS 인정시험 계획 없음(getStatusBySource null, 스텁), When 탐지, Then SYSTEM_RECORD_MISSING 1건. 계획이 FAIL이면 RESULT_MISMATCH.

- AC-5: Given 기능 스위치 꺼짐, When 탐지, Then AI 호출 0회, 규칙 신호만.

- AC-6: Given AI 응답 confidence 0.6(기준 0.7), When 처리, Then 신호 저장 없음, CMN_AiRecommendation__c 기록은 남음.

- AC-7: Given 신호 1건 DISMISSED(사유), When 처리, Then AnomalyStatus CONFIRMED_OK, 산출물 Status 변화 없음.

- AC-8: Given Gate 평가 항목의 증빙 산출물이 REVIEW_REQUIRED, When 자동 점검 후 확장 실행, Then 항목 AnomalyFlag true, 회차 AnomalyOpenCount 1, 확인 전 제출 차단(GAT-003 AC-11).

- AC-9: Given 화면 라벨 전체, When 라벨 검사 테스트, Then 금지 표현 0건.

**에이전트 주의**: 이상 징후로 산출물·Gate를 자동 반려·불합격시키지 않는다. 문서 원문 전체를 프롬프트에 넣지 않는다(색인 발췌만, Trust Layer). QMS 객체를 직접 SOQL하지 않는다(QMS_QualPlanService 조회). 파일 해시를 이 WI에서 다시 계산하지 않는다(DOC-001이 저장한 값 사용, 양식 해시만 계산). AI 결과를 산출물 필드에 직접 쓰지 않는다(신호 레코드 + AI-004 기록).

**오픈 이슈**: 대상 DocClass 범위(성적서·FMEA·관리계획서·DR 회의록 우선), 협력사 공용 성적서처럼 정상적인 파일 공유 사례, 표준 양식별 필수 항목 목록 작성 주체, AI 사용 범위(PoC 시나리오 5 시연 포함 여부).

### PMS-09-GAT-006 양산 이관 Gate(SOP)와 QMS 초기유동·레슨런 연결

추적 P-52, P-50 · 필수 · W1 · SF · APEX, LWC, CFG · Customization · 선행 GAT-004, PMS-02-PRJ-002, PMS-08-ISS-002, QMS-04-EFC-001, QMS-03-PIS-001, TDO-001, NTF-001 · 4 M/D

**목적**: 양산 이관 Gate(SOP Gate)에서 양산 준비 완료를 확인하고, 통과하는 순간 QMS 제품 초기유동 계획을 품번·공장별로 만들어 양산 초기 품질 관리가 끊기지 않게 한다. 남은 문제점·리스크는 처리 방향을 정하고 교훈은 레슨런 후보로 넘긴다(개발 → 양산 디지털 스레드).

**범위** In: SOP Gate 전용 점검 묶음(평가표 권장 문항 규칙 키), 미결 문제점·리스크 처리 방향 입력, 통과 시 초기유동 생성 호출·결과 기록·재시도, 레슨런 후보 일괄 요청, 이관 패널. Out: 초기유동 계획 내용·해제(QMS-04 EFC), 프로젝트 SOP 확정·종료(PMS-02-PRJ-001, PMS-04-WBS-009, 9절), 성과 평가(PMS-13-PRF-001).

**데이터 모델**(PMS_GateReview__c에 이 WI가 추가하는 필드)

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_GateReview__c.HandoverStatus__c | Picklist (NOT_REQUIRED, PENDING, DONE, PARTIAL, FAILED, MANUAL) | Y | 기본 NOT_REQUIRED, SOP Gate 결정 시 PENDING |
| PMS_GateReview__c.HandoverResultJson__c | Long Text(32768) | N | `[{projectPartId, itemId, itemNo, plantId, plantCode, planId, planNo, result: CREATED/EXISTING/FAILED/SKIPPED, message}]` |
| PMS_GateReview__c.HandoverAt__c | DateTime | N | |
| PMS_Issue__c.SopDisposition__c | Picklist (CLOSE_BEFORE_SOP SOP 전 종결, CARRY_TO_CLOSURE 과제 종료까지 PMS에서 관리, HANDOVER_QMS QMS 이관(NCR 또는 레슨런)) | SOP Gate 상신 시 미결 문제점은 Y | |
| PMS_Risk__c.SopDisposition__c | Picklist (CLOSE_BEFORE_SOP, CARRY_TO_CLOSURE, ACCEPT_AT_SOP SOP에서 수용 종결) | SOP Gate 상신 시 미결 리스크는 Y | |

**SOP Gate 평가표 권장 문항(템플릿은 PMO가 등록, 규칙 키만 이 WI가 정함)**

| 확인 항목 | 규칙 키·인자 예 |
| --- | --- |
| Run@Rate(양산 속도 생산 검증) 결과 승인 | DELIVERABLE_APPROVED `docClass:RUN_AT_RATE` |
| 고객 PPAP 제출서(PSW) 승인 | DELIVERABLE_APPROVED `docClass:PPAP_PSW` |
| 양산 준비 점검 결과 승인 | DELIVERABLE_APPROVED `docClass:LAUNCH_READINESS` |
| PV 인정시험 판정 | QMS_QUAL_PASS `phase:PV` |
| 필수 레슨런 반영 검토 전체 결정 | QMS_LELE_NO_OPEN_MANDATORY `scope:PROJECT` |
| 고객 SOP 빌드 마일스톤 달성 | MILESTONE_ACHIEVED `cm:SOP` |
| 중대 문제점 없음 | ISSUE_NO_OPEN `sev:CRITICAL,MAJOR;allowApproved:false` |
| High 리스크 없음 | RISK_NO_OPEN_HIGH `max:0` |
| 직전 Gate 조건 완료 | PREV_GATE_CONDITIONS_CLOSED |
| 생산 공장·SOP일 확정 | FIELD_NOT_BLANK `field:SopDate__c,ProdPlant__c` |

**비즈니스 규칙**

- BR-1: SOP Gate 식별 — 회차 IsSopGate = true(GAT-001). 프로젝트당 IsCurrent SOP 회차는 1개다.

- BR-2: 상신 전 처리 방향 — SOP Gate 결정 상신(GAT-004 BR-3) 전에 프로젝트의 미결 문제점(REGISTERED~APPROVED)과 미결 리스크(OPEN·MITIGATING) 모두에 SopDisposition이 있어야 한다. 결정 섹션 위에 이관 패널(BR-7)을 두고 일괄 입력한다. 누락이 있으면 상신을 막는다. 검사는 `PMS_SopHandoverService implements PMS_GateDecisionExtension`(GAT-004 BR-11)의 `validateSubmit`이 하고, 이 클래스를 CMN 설정 `PMS_GATE_DECISION_EXTENSIONS`에 등록한다. SOP 회차가 아니면 빈 목록을 돌려준다.

- BR-3: 초기유동 생성 — SOP 회차가 PASSED 또는 CONDITIONAL로 결정되면 `onDecided`(GAT-004 BR-11, 콜백과 분리된 Queueable)가 다음을 한다. FAILED면 아무것도 하지 않는다.
  - CMN 설정 `PMS_SOP_EFC_ENABLED`(기본 false, QMS-04 EFC 배포 후 true)가 false면 HandoverStatus = MANUAL, 프로젝트 QE 역할 구성원에게 To-Do "초기유동 계획 수동 생성: {projectNo}"(SourceType PMS_SOP_HANDOVER)와 품번 목록 알림.
  - true면 대상 = PMS_ProjectPart__c 중 품번 ItemType FG·SFG이고 생산 공장(ProjectPart.ProdPlant, 없으면 Project.ProdPlant)이 있는 것. 품번·공장 조합마다 `QMS_StabilizationService.createFromSource(req)` 호출: recordType PRODUCT, itemId, plantId, customerId = 프로젝트 고객, trigger NEW_PRODUCT, sopDate = Project.SopDate, sourceId = 회차 Id, sourceObject 'PMS_GateReview__c', sourceNo = 회차 RecordNo, ownerId = 프로젝트 QE 역할 구성원(없으면 공장 QUALITY_MANAGER는 QMS 기본값에 맡김).
  - 결과를 HandoverResultJson에 품번별로 기록한다(QMS가 기존 계획 Id를 돌려주면 EXISTING, EFC-001 BR-2 멱등). 모두 성공이면 DONE, 일부 실패면 PARTIAL, 전부 실패면 FAILED. 실패 건은 CMN_Logger ERROR, 알림 PMS_SOP_HANDOVER_FAILED(PM, QE, PMO)와 To-Do.
  - 호출은 품번 단위로 예외를 잡아 다른 품번 처리를 계속한다. 품번 50개 초과면 Queueable 체인으로 나눈다.

- BR-4: 재시도 — 이관 패널 "초기유동 다시 요청"(PM·QE·PMO)이 FAILED 품번만 다시 호출한다. QMS 멱등이므로 성공 건을 다시 불러도 중복 계획이 생기지 않는다.

- BR-5: 처리 방향 실행 — 결정 후 같은 Queueable에서:
  - HANDOVER_QMS 문제점: 8D 모드(QMS 건 연결)면 연결 유지만 하고, PMS_DOC 모드면 IsLessonCandidate = true로 표시하고 종결 시 레슨런 요청(ISS-002 BR-8). 아직 종결 전이므로 PM에게 "QMS 이관 문제점 종결" To-Do를 연다(QMS NCR이 필요하면 ISS-002 NCR 요청을 안내).
  - CARRY_TO_CLOSURE: 변화 없음(과제 종료 PMS-04-WBS-009에서 다시 확인하도록 9절 요청).
  - ACCEPT_AT_SOP 리스크: `PMS_RiskService.close(riskId, 'ACCEPTED', 'SOP Gate 수용', false)`.
  - CLOSE_BEFORE_SOP인데 아직 미결인 건이 있으면 상신이 막혔어야 하므로 결정 후에는 PM에게 경고 To-Do만 연다.

- BR-6: 레슨런 후보 일괄 — 이관 패널 "레슨런 후보 보내기"가 프로젝트의 종결 문제점·리스크 중 IsLessonCandidate = true이고 LessonRecordId가 없는 건을 목록으로 보이고, 선택한 건마다 `PMS_LessonCandidateService.request`를 부른다(한 번에 50건까지).

- BR-7: 이관 패널 `pmsSopHandoverPanel` — SOP 회차 현재 단계 탭: (a) 미결 문제점·리스크 표(번호, 제목, 심각도·등급, 상태, 처리 방향 선택), (b) 초기유동 대상 품번·공장 목록과 생성 결과(계획 번호 링크, 결과, 메시지), (c) 레슨런 후보 목록. 처리 방향 일괄 저장은 서비스 1회 호출(DML 2회).

- BR-8: 이벤트 — SOP 회차 결정 이벤트는 GAT-004 PMS_GateEvent__e(IsSopGate = true)다. 프로젝트 SOP 확정 처리(PMS_ProjectEvent__e SOP_CONFIRMED 발행)는 PMS-02-PRJ-001이 이 이벤트를 구독해 한다(9절 요청).

**화면/UX**: 화면 유형 T1. SOP 회차 레코드 페이지 현재 단계 탭에 `pmsSopHandoverPanel`을 결정 섹션 위에 둔다(GAT-004 화면 위). 휴대폰은 결과 목록만 읽기.

**권한**: PMS_PS_Gate_Evaluate(처리 방향 입력·재시도), PMS_PS_Issue_Edit·PMS_PS_Risk_Edit(처리 방향 필드 FLS), 초기유동 생성은 QMS 서비스가 실행 사용자 권한으로 동작하므로 결정 Queueable은 자동화 사용자 컨텍스트에서 QMS_PS_StabProduct_Edit 권한이 필요하다(오픈 이슈).

**수용 기준**

- AC-1: Given 미결 문제점 2건 중 1건 처리 방향 공란, When SOP Gate 상신, Then 차단 + 누락 목록.

- AC-2: Given PMS_SOP_EFC_ENABLED true, 프로젝트 품번 3개(FG 2, 부품 1), When SOP Gate PASSED, Then createFromSource 2회(FG만, NEW_PRODUCT, sourceObject PMS_GateReview__c), HandoverStatus DONE, 결과 JSON 2행.

- AC-3: Given 품번 2개 중 1개 호출 예외(스텁), When 처리, Then PARTIAL, 실패 1행 메시지, 알림 1건, 다른 품번 계획 생성됨. 재시도 시 실패 품번만 호출.

- AC-4: Given PMS_SOP_EFC_ENABLED false, When PASSED, Then MANUAL, QE To-Do 1건, QMS 호출 0회.

- AC-5: Given ACCEPT_AT_SOP 리스크, When 결정 처리, Then 리스크 CLOSED(CloseReason ACCEPTED).

- AC-6: Given 레슨런 후보 5건(그중 1건 이미 요청), When 일괄 보내기, Then 게이트웨이 request 4회.

**에이전트 주의**: QMS_StabilizationPlan__c를 PMS에서 직접 만들거나 Lookup하지 않는다(서비스 호출, sourceId 텍스트). 결재 콜백 트랜잭션 안에서 QMS를 동기 호출하지 않는다(실패가 결재를 되돌리지 않도록 Queueable). 프로젝트 SopDate·Status를 이 WI에서 바꾸지 않는다.

**오픈 이슈**: 초기유동 대상(리드 품번만인지 생산 품번 전체인지, DP4-9), SOP Gate 통과와 고객 SOP의 선후(SOP Gate가 SOP 이후에 열리는 경우), 이관 후 미결 문제점의 소유(PMS 유지 또는 QMS NCR 전환).

## 9. 검토 요청

Vol.P4는 **11개 워크아이템, 약 55 M/D**다. W1 8개(41 M/D)가 리스크 로그·문제점 절차·Gate 일정·평가표·평가·결정·SOP 이관과 리스크·문제점 위젯이고, W2 3개(14 M/D)는 QMS 레슨런 점검 추적, 6pi/8D 단일화, 산출물 이상 징후다. 계약 초안(52 M/D) 대비 GAT-001(4 → 5, 이벤트 동기화·일정 그리드), GAT-002(4 → 5, Gate RAG 계산기를 여기서 구현), GAT-004(4 → 5, 결재선 기여·후속 조치 그리드)를 늘리고 GAT-003은 계산기를 GAT-002로 옮겨 7로 두었다.

| WI | 제목 | Wave | 공수(M/D) |
| --- | --- | --- | --- |
| PMS-08-RSK-001 | 리스크 로그(정량 평가·주/월 검토·에스컬레이션) | W1 | 6 |
| PMS-08-RSK-002 | 리스크 경감 대책 ↔ QMS 선행 품질 점검 추적 | W2 | 4 |
| PMS-08-RSK-003 | 리스크·문제점 현황 대시보드 | W1 | 3 |
| PMS-08-ISS-001 | 문제점 등록·대책서·승인·종결 | W1 | 6 |
| PMS-08-ISS-002 | 문제점 ↔ QMS 6pi/8D·품질 이력 연계 | W2 | 5 |
| PMS-09-GAT-001 | Gate 정의·프로젝트 Gate 일정(마일스톤 통합) | W1 | 5 |
| PMS-09-GAT-002 | Gate 평가표 템플릿(CMN 질문지 GATE)·판 관리 | W1 | 5 |
| PMS-09-GAT-003 | Gate 평가 수행(체크리스트·산출물 자동 점검·RAG) | W1 | 7 |
| PMS-09-GAT-004 | Gate 결재·조건부 통과·후속 조치 | W1 | 5 |
| PMS-09-GAT-005 | 산출물 이상 징후 탐지(데이터 대조·AI) | W2 | 5 |
| PMS-09-GAT-006 | 양산 이관 Gate(SOP)와 QMS 초기유동·레슨런 연결 | W1 | 4 |

**PoC 시나리오 5(Gate 평가) 시연 범위**: GAT-001(일정) → GAT-002(평가표 V1·V2 판 비교) → GAT-003(평가 시작 스냅숏, 자동 점검으로 미승인 산출물 NOT_MET, 체크리스트 평가, RAG) → GAT-004(조건부 통과·후속 조치) → GAT-005(같은 해시 복사 문서 "검토 필요" 표시, 규칙 신호만). AI 신호는 기능 스위치로 선택 시연.

**결정이 필요한 항목**(자율 진행 지시에 따라 권고안으로 작성했다. 검토 때 확정)

- [ ] DP4-1 Gate 평가표 적용 시점 — 평가 시작(IN_REVIEW 진입) 날짜 기준으로 발효 중인 판을 스냅숏하고 끝까지 쓴다. PMS Gate 점검은 W1부터 UX-009 체크리스트 셸을 쓴다(UX-009 오픈 이슈 해소). 권고: 승인

- [ ] DP4-2 고객 Gate 점검표 처리 — SL 표준 평가표 뒤에 고객 점검표를 별도 섹션으로 붙여 같은 Gate에서 함께 평가하고, 최종 RAG는 둘 중 나쁜 값(GAT-002 BR-3). 대안: 고객 Gate를 별도 Gate(고객 마일스톤)로 따로 평가. 권고: 합성 평가

- [ ] DP4-3 Gate RAG 규칙 — 달성률 구간(GRADE_BAND) + 필수 문항 미충족 1개 이상 RED 강등(MANDATORY_NOT_MET_GE), 숫자는 PMO가 템플릿에 입력(코드 없음). 제안 결정 GREEN = 통과, AMBER = 조건부, RED = 실패. 권고: 승인

- [ ] DP4-4 완화 결정 — 제안보다 완화된 결정(RED → 조건부, AMBER → 통과)을 근거 200자 + 사업부장 승인으로 허용, RED → 통과는 금지(GAT-004 BR-2). 권고: 승인

- [ ] DP4-5 리스크 등급 기준 — P×I(1~5) 점수 15 이상 또는 영향도 5·가능성 2 이상 HIGH, 8 이상 MEDIUM, FMEA AP H 리스크 하한 MEDIUM, HIGH 주간·그 외 월간 검토(모두 CMN 설정). SL 현행 행렬이 있으면 그 값으로 교체. 권고: 설정값으로 시작

- [ ] DP4-6 High 리스크 에스컬레이션 — 1단계 자동(PMO·팀장 알림·대책 To-Do), 2단계 수동(경영 보고, 사업부장), 14일 미개선 시 2단계 검토 알림만(자동 2단계 없음). 권고: 승인

- [ ] DP4-7 QMS 이벤트로 문제점 자동 생성 범위 — 활성 프로젝트(SOP + 90일까지) 품번의 고객 클레임 전부, NCR은 심각도 A·B만. 같은 품번을 쓰는 프로젝트가 여러 개면 모두 생성. 권고: 승인(대표 프로젝트 1개만으로 바꿀지 SL 확인)

- [ ] DP4-8 대책서 단일화 — QMS 클레임·NCR과 연결된 문제점은 QMS 8D(HKMC 6pi)를 대책서로 쓰고 PMS에 원인·대책을 복사하지 않음. 승인 요청은 8D D6 이후, 종결은 8D 종결 후. 권고: 승인

- [ ] DP4-9 SOP Gate 초기유동 대상 — 프로젝트 품번 중 완제품·반제품(FG·SFG) 전체 × 생산 공장마다 생성(리드 품번만 아님). 권고: 전체

- [ ] DP4-10 산출물 이상 징후 범위 — 규칙 신호 6종(W2)을 기본으로 하고 AI 내용 신호 3종은 기능 스위치(기본 꺼짐), "검토 필요" 표시만 하고 산출물·Gate를 자동 반려하지 않음. 권고: 승인

- [ ] DP4-11 Gate 결재선 — PM 기안 → QE 합의 → PMO 팀장 검토 → 사업부장 승인. GREEN 통과는 PMO 팀장 승인으로 끝내고 사업부장 참조(SOP Gate·완화 결정은 사업부장 승인 필수). 권고: 승인

**Vol.0에 반영이 필요한 변경**

| 대상 WI | 변경 내용 | 근거 |
| --- | --- | --- |
| CMN-00-MDM-007 | 코드 그룹 RISK_CATEGORY(2레벨)·ISSUE_TYPE(2레벨) 추가, DOC_CLASS 값 ISSUE_COUNTERMEASURE·GATE_MINUTES·RUN_AT_RATE·LAUNCH_READINESS, MEETING_TYPE 값 GATE_REVIEW 확정 | 3절 공통 코드 |
| CMN-00-APV-002 | APPROVAL_ROLE 값 PMO_MANAGER(PMO 팀장)·BU_HEAD(사업부장·연구소장) 추가. 결재선 기여 인터페이스 CMN_ApprovalLineContributor(Vol.2 요청과 같음)를 PMS도 사용 | RSK-001 BR-8, ISS-001 BR-4, GAT-004 BR-4 |
| CMN-00-AI-004 | UseCase 값 PMS_DOC_ANOMALY 추가(계약 7절에 이미 명시) | GAT-005 BR-3 |
| CMN-00-UX-009 | CMN_Checklist.Question DTO에 autoResultLabel(String)·autoResultSeverity(String)·evidenceLinks(List: label, recordId)·anomalyCount(Integer) 추가, 카드에 자동 결과 배지·증빙 링크·이상 징후 확인 체크 표시. 반영 전에는 Provider가 guidance로 대체 | GAT-003 BR-8 |
| CMN-00-UX-006 | ParentField에 Text(18) 원천 Id 필드 허용(CMN_ActionItem__c.SourceRecordId__c처럼 다형 연결) | GAT-004 후속 조치 그리드 |
| CMN-00-QNR-001 | (1) 활성화 시 도메인 검증 훅(예: 인터페이스 `CMN_QuestionnaireDomainValidator`, 도메인별 등록)으로 GATE 템플릿의 자동 점검 규칙 키를 검사, (2) Snapshot에 AutoCheckRuleKey·AutoCheckParams·ScopeKeys·EvidenceKeys·PreviousItemKey·MappingType·IsMandatory·Weight가 모두 포함됨을 명시 | GAT-002 BR-4, GAT-003 BR-1 |
| CMN-00-DOC-001 | 데이터 모델 표에 구현된 CMN_DocumentRevision__c.IsDuplicateFile__c·DuplicateOfRevision__c를 BR-5 경고 플래그 필드로 명시 | GAT-005 BR-2 |
| CMN-00-SEC-001 | PMS PSG(PM·CFT·TeamLead·PMO)에 CMN_PS_Questionnaire_Read 포함, PMS_PSG_PMO에 CMN_PS_Questionnaire_Admin + CMN_QnrAdmin_Gate | GAT-002 권한 |

**QMS Vol.에 반영이 필요한 변경**

| 대상 WI | 변경 내용 | 근거 |
| --- | --- | --- |
| QMS-09-INT-021 BR-6 | 리스크·문제점 레슨런 후보의 sourceObject를 'PMS_RISK' 대신 같은 Org 경로와 같은 'OTHER' + payloadJson.sourceType DEV_ISSUE, pmsSourceType RISK·ISSUE로 맞춤(LEL-002 BR-7 매핑 목록 밖 값 예외 방지) | ISS-002 BR-8 |
| QMS-04-LEL-002 BR-7 | payloadJson 키 pmsSourceType·projectNo·devPhaseCode를 레슨런 원천 설명에 반영(선택), SourceRecordNo = PMS 문제점·리스크 번호 | ISS-002 BR-8 |
| QMS-06-NCR-002 | QMS_NcrSourceConfig__mdt에 PMS 패키지가 PMS_Issue 레코드를 등록함을 명시(SourceObject PMS_Issue__c, NcrRecordId__c·NcrRecordNo__c), requestNcr sourceType OTHER·sourceObject PMS_Issue__c에서 라인·공정 없이 DRAFT 허용 확인 | ISS-002 BR-6 |
| QMS-04-EFC-001 | PMS 호출 값 확정: sourceId = PMS_GateReview__c Id, sourceObject 'PMS_GateReview__c', 품번·공장 조합마다 1회 호출, ownerId = 프로젝트 QE(없으면 QMS 기본값) | GAT-006 BR-3 |
| QMS-04-LEL-005 | (선택) 반영 검토 화면에 PMS 리스크 연결 표시 — PMS_RiskQualityService.getRisksByQmsTarget 호출 | RSK-002 BR-7 |
| QMS-02 D2-4 | CONDITIONAL 인정시험 판정을 QMS_QUAL_PASS 충족으로 볼지 결정 — Gate 자동 점검은 ACT-004 완료 조건 판정을 그대로 따름 | GAT-003 BR-4 |
| interfaces.md 5절 | PMS가 LESSON_LEARNED·NCR·EIGHT_D 게이트웨이를 쓰므로 게이트웨이 프레임워크(QMS 공통 패키지)를 PMS 패키지보다 먼저 배포하는 순서 명시 | ISS-002 |

**다른 PMS Vol. 변경 요청**

| 대상 WI | 변경 내용 | 근거 |
| --- | --- | --- |
| PMS-02-PRJ-001 | PMS_GateEvent__e PASSED·CONDITIONAL 구독으로 CurrentPhase를 다음 단계로 전진, SOP Gate(IsSopGate) 결정 시 PMS_ProjectEvent__e SOP_CONFIRMED 발행. 프로젝트에 고객 그룹 수식 필드(Customer__r.CustomerGroup__c) | GAT-001 BR-1, GAT-006 BR-8 |
| PMS-04-WBS-001·003 | 마일스톤 액티비티 GateCode 값은 PMS_GateDefinition__c.GateCode와 같은 값 목록을 쓴다. PMS_ActivityEvent__e에 ProjectId__c·IsMilestone__c·GateCode__c 필드 포함 | GAT-001 BR-2·3 |
| PMS-07-ACT-004 | Gate 마일스톤 액티비티 완료 조건 규칙 키 GATE_DECIDED(`PMS_GateQueryService.isDecided(activityId)`) 추가 또는 PMS_GateEvent__e 구독 자동 완료. PMS_CompletionChecker는 액티비티 단건·다건 판정을 공개 메서드로 제공(Gate 자동 점검 위임) | GAT-003 BR-4, GAT-001 서비스 |
| PMS-04-WBS-009 | 과제 종료 승인 시 SopDisposition CARRY_TO_CLOSURE 문제점·리스크 미결 여부 확인 | GAT-006 BR-5 |
| PMS-06-DLV-001 | PMS_Deliverable__c.AnomalyStatus__c·AnomalyCheckedAt__c·AnomalyCheckedRevision__c는 GAT-005가 만든다(계약 표기와 같음). 산출물 레일에 CONTEXT_ANOMALY 패널 행 허용 | GAT-005 |
| PMS-10-DSH-002 | PMO 보드의 Gate·리스크·문제점 영역은 PMS_GateQueryService.getGateSummary와 RSK-003 위젯 2개 사용 | RSK-003, GAT-001 BR-9 |
| PMS-11-AIP-003 | 조기경보 결과를 리스크로 만들 때 PMS_RiskService.createFromSource(Source EARLY_WARNING) 사용 | RSK-001 BR-10 |
| PMS-12-INT-005 | QMS_ClaimEvent__e·QMS_NcrEvent__e·QMS_EightDEvent__e 구독 트리거에서 PMS_IssueQmsService.handle*Events를 호출(구독 트리거는 INT-005 한 곳), QMS_LeleApplicationEvent__e 수신 시 PMS_RiskQualityService.refreshStatus 호출 | ISS-002, RSK-002 BR-4 |
| PMS-13-PRF-001 | Gate 1회 통과율 = SOP까지 결정된 Gate 중 Round 1 PASSED 비율(PMS_GateReview__c 기준, KPI PMS_GATE_FIRST_PASS_RATE와 같은 정의) | 3절 KPI |
| pms-architecture.md·interfaces.md 6절 | 새 이름 등록: PMS_GateCheckRule__mdt, PMS_DeliverableAnomaly__c, PMS_AnomalyRule__mdt, PMS_GateAutoChecker·PMS_GateAutoCheckExtension·PMS_GateDecisionExtension, PMS_GateRagScorer, PMS_GateQueryService, PMS_LessonCandidateService, PMS_RiskQualityService, PMS_GateQuestionnaireUsageCheck, PMS_AnomalyDetectionService, PMS_SopHandoverService, MART.V_SF_KPI_PMS_RISK_GATE, KPI 키 6개, 코드 그룹 RISK_CATEGORY·ISSUE_TYPE | 3절 |

**SL 확인이 필요한 사실 정보**: 현행 RISK Management Log 양식(유형·코드·속성·등급 기준·검토 주기), 문제점 대책서 양식과 결재선, 회사표준 개정 후 개발 단계·Gate 수·이름·평가표 문항과 발효일, 고객별 Gate 점검표 원본과 사용 허락 범위, Gate 결재권자(사업부장·연구소장), Run@Rate·양산 준비 점검 증빙 형태, HKMC 6pi 양식, 개발 단계 고객 지적의 QMS 클레임 등록 여부, 같은 품번을 쓰는 파생 프로젝트 운영 방식.

**다음 순서**: 검토 의견을 반영해 Vol.P4 승인분을 마스터 워크아이템 xlsx로 옮기고, 개발은 Vol.P1~P3의 W1(프로젝트·WBS·산출물) 뒤에 RSK-001·ISS-001 → GAT-001·002 → GAT-003·004 → GAT-006 순서로 착수한다. W2 3개는 QMS-04 LEL·QMS-05 CLM·QMS-06 NCR 배포 후 진행한다.
