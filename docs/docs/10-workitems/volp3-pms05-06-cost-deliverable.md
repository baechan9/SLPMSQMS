# SL PMS 워크아이템 Vol.P3 — PMS-05 비용 · PMS-06 산출물

Nov 6, 2026 · @배창욱

## 1. 개요

Vol.P3는 PMS RFP **3.5 비용 관리(P-29~33)**와 **3.6 산출물 관리(P-34~40)**를 9개 워크아이템(PMS-05-CST-001~004, PMS-06-DLV-001~005)으로 내린다. 3.10 P-57의 "Cost 정보 권한 분리" 중 데이터 권한은 CST-003이 만들고, 일간/주간 보고 화면에 적용하는 일은 PMS-10-DSH-003이 한다. P-40 회의록은 Vol.0 CMN-00-MTG-001이 덮으므로 이 Vol.은 회의록을 산출물로 연결하는 방법(시스템 링크 유형 `CMN_MEETING`)만 정한다.

**계약**: WI 번호·제목, 객체 이름, 상태값, 이벤트, PSG 이름은 `pms-architecture.md`(PMS 공통 설계)를 그대로 쓴다. 계약에 없는 이름은 본문에 **(제안)**으로 표시하고 6절 "계약 변경 요청"에 모았다. 계약 이름을 바꾼 곳은 없다. 공수는 계약 초안 44 M/D에서 50 M/D로 조정했다(6절).

**도메인 정의**

| 용어 | 뜻 | 이 Vol.에서의 처리 |
| --- | --- | --- |
| ED&D | Engineering Design & Development. 설계·개발 인건비가 중심이고 시작품 제작비·외부 시험비·외주 설계비가 붙는다 | 인건비 = 투입 시간 × 법인·직급 평균 임율(자동), 나머지는 수동·SAP 행 |
| Tooling | 금형·지그·검사구와 부대 비용(제비용). 고객이 비용을 지급해 고객 소유가 되는 경우가 많다 | 금액 원천은 DMS(개발비 관리 시스템). 투자 주체(FundingType)를 예산 행에 표시 |
| Piece Price | 양산 부품 1개당 단가. 금액 합계가 아니라 목표 단가 대비 견적·실적 단가로 관리한다 | PIECE_PRICE 행은 합계에서 빼고 품번별 단가로 비교 |
| 출장비 | 고객사 회의·현지 빌드·협력사 점검 출장 경비 | W1은 수동 입력(출장자·목적지·기간), SAP 경비 연계는 SL 확인 후 |
| Contingency | 예비비. 위험 대비로 잡아 두고 필요할 때 다른 항목으로 옮겨 쓴다 | 실적을 직접 붙이지 않는다. "예비비 사용"으로 예산을 이전 |
| 산출물 5종 | 일반 첨부, 표준 양식 첨부, Link, 결재 문서, 시스템 Link | 아래 표 |
| 디지털 스레드 | 상류 입력(고객 요구사항)과 하류 출력(설계 도면, 신뢰성 시험 결과)을 끊김 없이 잇는 연결 | DLV-003 연결 객체 + SOR-002 요구사항 연결을 하나의 그래프로 |
| 영향도 분석 | 산출물이 바뀔 때 연결된 하류 산출물·후행 액티비티·연계 시스템 데이터·통과한 Gate에 미치는 영향을 찾는 일 | DLV-004 분석 + 사람 판정 + 재검토 To-Do |

**산출물 5종**(계약 DeliverableType 값)

| 값 | 이름 | 등록 방법 | 결재 | 예 |
| --- | --- | --- | --- | --- |
| ATTACHMENT | 일반 첨부 | 파일 업로드(50MB 초과는 SharePoint 등 외부 링크, DOC-001 BR-4) | ApprovalRequired 선택 | 고객 회의 자료, 벤치마킹 보고서 |
| STANDARD_FORM | 표준 양식 첨부 | 양식 내려받기(DLV-005) → 작성 → 업로드 | ApprovalRequired 선택 | DFMEA, PFMEA, 관리계획서, 공정 흐름도, 제조 타당성 검토서 |
| LINK | Link | https 링크 등록(SharePoint, 고객 포털 등) | 없음(원본 시스템에서 관리) | 고객 포털에 올린 PPAP 패키지 링크 |
| APPROVAL | 결재 문서 | 파일 업로드 후 결재 | 항상 필요(팀장 필수) | 개발 착수 품의서, DR 결과 보고서 |
| SYSTEM_LINK | 시스템 Link | 다른 시스템 레코드 선택(리졸버) | 없음(원본 시스템 상태로 충족 판단) | QMS 인정시험 판정, PDM 도면·리비전, DR 회의록, IMDS 등록 번호 |

**선행 공통 WI**: ARC-002·003, MDM-001·002·007, SEC-001·002·003·004, UX-003·004·005·006·007, APV-001·002·003, TDO-001, NTF-001, DOC-001, DSH-001, DWH-002·003·004, AI-002·003, INT-001·002.

**착수 순서**(번호 순서와 다르다): CST-003 → CST-001 → CST-002 → CST-004, DLV-001 → DLV-002 → DLV-005 → DLV-003 → DLV-004.

**다른 메뉴와의 경계**

| 연결 대상 | 이 Vol.이 하는 것 | 상대 메뉴가 하는 것 |
| --- | --- | --- |
| 투입 계획·실적(PMS-03-EFF) | 계획 시간 → ED&D 예산, 승인 실적 → ED&D 실적 계산 | 투입 시간 입력·승인(일 8시간·주 52시간) |
| 표준 WBS(PMS-04-WBS-002) | 표준 산출물 정의를 실행 산출물로 생성 | 표준 산출물·양식·결재 필요 여부 정의 |
| 액티비티 완료(PMS-07-ACT-004) | 액티비티 롤업(필수 산출물 수·충족 수), 완료 조건 검사기 | 완료 조건 판정·자동 종료·재시작 |
| Gate(PMS-09-GAT-003·005) | 산출물 상태 조회 서비스, 이상 징후 필드 자리 | 자동 점검 규칙, 이상 징후 탐지 |
| 결재선 역할(PMS-12-APV-001) | 산출물별 추가 결재 단계 규칙 | PROJECT_ROLE → 사용자 해석 |
| HR·DMS·PDM·QMS 연계(PMS-12-INT-002~005) | 수신 계약(upsert 키), 시스템 링크 리졸버 인터페이스, 산출물 이벤트 | Mule 구현, 리졸버 구현·등록, 이벤트 구독 |
| QMS Re-PPAP(Vol.4 RPP-002) | 승인된 FMEA·관리계획서·공정 흐름도를 품번 문서로 게시 | 품번 문서를 증빙으로 수집(변경 없음) |
| 대시보드·보고(PMS-10) | 비용 요약·포트폴리오 쿼리·CostRag, 비용 권한 확인 도우미 | 위젯 배치, 일간/주간 보고의 비용 숨김 |
| 프로젝트 변경(PMS-13-CHG-001) | 예산 기준선 재확정 서비스 | 비용 변경 요청·승인 후 재확정 호출 |

## 2. 업무 흐름

**비용**

    HR 직급 평균 임율(INT-002) ─▶ PMS_LaborRate__c (재무만 열람)
    투입 계획(EFF-001) ─▶ ED&D 계획 산정(CST-001, 액티비티 × 통화) ┐
    금형·출장비·예비비·목표 단가 수동 예산(CST-001 그리드·가져오기) ─┴▶ PMS_CostBudget__c ─▶ 예산 확정(기준선 1)
    투입 실적 승인(EFF-002) ─▶ ED&D 실적(CST-002, 프로젝트 × 월 × 통화) ┐
    DMS 금형·지그·검사구·제비용(INT-003) ─────────────────────────────┼▶ PMS_CostActual__c ─▶ 월 마감(익월 5일 동결)
    출장비·시작품비·실적 단가 수동 입력(CST-002) ──────────────────────┘
    Salesforce → Snowflake 복제 ─▶ 환산·월 분배·EAC ─▶ CostRag(P4 이벤트) / 포트폴리오(P2 쿼리) (CST-004)
    프로젝트 비용 탭 = Salesforce 집계(실시간) + 보고 통화 환산 합계(Snowflake)

**산출물**

    표준 WBS 산출물 정의(WBS-002) ─▶ 실행 WBS 생성 후 실행 산출물 생성(DLV-001 syncFromTemplate)
      → 담당(주·보조)이 파일·링크 등록(cmnDocumentPanel) 또는 시스템 레코드 선택(리졸버)
      → DOC-001 문서 리스너가 산출물 상태 계산(NOT_SUBMITTED → SUBMITTED)
      → 결재 필요 산출물: 상신(팀장 필수 + 산출물별 역할 단계) → 승인 → 리비전 RELEASED → APPROVED(DLV-002)
           ├ 품번 문서 게시(PPAP 관련 DocClass) → QMS Re-PPAP 증빙 수집기가 읽음
           ├ PMS_DeliverableEvent__e APPROVED → INT(QMS·DMS·PDM) 구독
           └ 액티비티 롤업 갱신 → 완료 조건(ACT-004) → 마일스톤·Gate 자동 점검(GAT-003)
      → 입력/출력 연결(DLV-003) → 개정 시작 → 영향도 분석·판정·재검토 To-Do → 새 리비전 승인(DLV-004)
      → 프로젝트·액티비티·파일명·등록자 검색, 표준 양식 내려받기(DLV-005)

## 3. 데이터 모델 개요

비용 객체는 **금액이 있는 업무 객체 2개와 비공개 설정 1개**다. 금액은 객체 권한(PS)이 없으면 화면·리포트·API·AI 답변 어디에도 나오지 않는다. 산출물 객체는 **액티비티 하위의 실행 산출물**과 **프로젝트 하위의 연결·영향 기록**으로 나뉜다. 파일·리비전은 DOC-001의 `CMN_Document__c`·`CMN_DocumentRevision__c`가 그대로 갖고, 산출물은 상태·결재·연결만 갖는다.

| 객체 | 구분 | 관계 | 역할 | 정의 WI |
| --- | --- | --- | --- | --- |
| PMS_CostBudget__c | 업무 | Project(MD), Activity·ProjectPart(Lookup) | 예산 행(범주·금액·통화·기준선) | CST-001 |
| PMS_CostActual__c | 업무 | Project(MD), Budget·ProjectPart(Lookup) | 실적 행(월·금액·원천) | CST-002 |
| PMS_LaborRate__c | 설정(비공개) | Company(Lookup) | 법인·직급·연도별 평균 임율 | CST-003 |
| PMS_Deliverable__c | 업무 | Activity(MD), TemplateDeliverable·Document(Lookup) | 실행 산출물 1건 | DLV-001 |
| PMS_DeliverableTrace__c | 업무 | Project(MD) | 입력/출력 연결 1건(상류 → 하류) | DLV-003 |
| PMS_ImpactAssessment__c | 업무 | Project(MD), SourceDeliverable(Lookup) | 영향도 분석 1건 | DLV-004 |
| PMS_ImpactItem__c (제안) | 업무 | ImpactAssessment(MD) | 영향 대상 1건과 판정 | DLV-004 |
| PMS_SystemLinkType__mdt (제안) | 설정 | — | 시스템 링크 유형·리졸버·충족 규칙 | DLV-001 |
| PMS_DeliverableApprovalRule__mdt (제안) | 설정 | — | 산출물별 추가 결재 단계(P-65) | DLV-002 |
| PMS_DeliverablePublishRule__mdt (제안) | 설정 | — | 승인본 품번 문서 게시 규칙 | DLV-002 |
| PMS_DeliverableEvent__e (제안) | 이벤트 | — | 산출물 사실 통지(제출·승인·반려·개정) | DLV-001 |

**상태값**

| 대상 | 값(순서) |
| --- | --- |
| PMS_Deliverable__c.Status__c | NOT_SUBMITTED → SUBMITTED → IN_APPROVAL → APPROVED / REJECTED, 어느 단계에서든 NOT_APPLICABLE(계약 값). 상태는 문서 리비전에서 계산한다(DLV-001 BR-4) |
| PMS_ImpactAssessment__c.Status__c | ANALYZED → IN_REVIEW → CONFIRMED → CLOSED / CANCELLED |
| PMS_ImpactItem__c.Decision__c | PENDING → IMPACTED / NO_IMPACT |
| PMS_CostBudget__c 기준선 | BaselineNo 비어 있음(미확정) → 1 → 2 … (재확정은 CHG-001 승인 또는 PMO·재무 권한) |
| PMS_CostActual__c.IsLocked__c | false(열린 달) → true(월 마감) |

**공통 기반 등록**

| 항목 | PMS_CostBudget__c / PMS_CostActual__c | PMS_LaborRate__c | PMS_Deliverable__c | PMS_DeliverableTrace__c | PMS_ImpactAssessment__c / PMS_ImpactItem__c |
| --- | --- | --- | --- | --- | --- |
| 채번(ARC-003) | 없음(행 단위) | 없음 | `DLV-{YYYY}-{SEQ:6}` | 없음 | `IA-{YYYY}-{SEQ:5}` / 없음 |
| 공유 | 프로젝트 MD(CFT 공유 상속) + 객체 권한 | OWD Private, 공유 없음 | 액티비티 MD(프로젝트 공유 상속) | 프로젝트 MD | 프로젝트 MD |
| 삭제 통제(SEC-003) | 트리거 규칙(기준선·마감·연계 행 삭제 금지) + 삭제 로그 | 삭제 금지(IsActive로 대체) | DeleteGuard(Status NOT_SUBMITTED) + 임의 산출물만 | 작성자·PM, 로그 | DeleteGuard(Status ANALYZED, CANCELLED) |
| 진행 단계(UX-003) | — | — | CMN_StatusFlow 등록 | — | CMN_StatusFlow 등록 |
| 필드 이력 | PlannedAmount, BaselineAmount, Category, CurrencyIsoCode / Amount, IsLocked | HourlyRate, IsActive | Status, IsMandatory, ApprovalRequired, NotApplicableReason, DocClass | — | Status / Decision |
| DWH 복제(DWH-002) | 15분(금액 열 마스킹, 3.5절) | **복제하지 않음** | 15분 | 15분 | 15분 |
| 번역 | ko·en_US·zh_CN | 같음 | 같음 | 같음 | 같음 |

**권한 셋**(PS는 기능 WI가 만들고 PSG에 넣는다. PSG 이름은 계약 10절)

| PS | 내용 | 넣는 PSG |
| --- | --- | --- |
| PMS_PS_Cost_Read (계약) | 예산·실적 객체 Read, 금액 필드 FLS Read, Custom Permission `PMS_ViewCost`, 비용 조회 Apex | PMS_PSG_PM, PMS_PSG_PMO, PMS_PSG_Finance, CMN_PSG_Executive |
| PMS_PS_Cost_Edit (제안) | 예산·수동 실적 Create·Edit, Custom Permission `PMS_CST_Edit`, 가져오기 | PMS_PSG_PM, PMS_PSG_Finance |
| PMS_PS_Cost_Portfolio (제안) | Custom Permission `PMS_CST_Portfolio`(전체 프로젝트 비용 포트폴리오) | PMS_PSG_PMO, PMS_PSG_Finance, CMN_PSG_Executive |
| PMS_PS_LaborRate_Admin (제안) | PMS_LaborRate__c Read·Create·Edit, Custom Permission `PMS_CST_RateAdmin`, `PMS_CST_CloseAdmin`(월 마감 해제), `PMS_CST_Rebaseline` | PMS_PSG_Finance |
| PMS_PS_Cost_Integration (제안) | 비용 객체·임율 upsert, Custom Permission `PMS_CST_IntegrationWrite` | 통합 사용자(INT-001 BR-2) |
| PMS_PS_Deliverable_Read (제안) | 산출물·연결·영향도 객체 Read, 조회 Apex | 모든 PMS PSG(PM, CFT, TeamLead, PMO, Finance), CMN_PSG_Executive |
| PMS_PS_Deliverable_Edit (제안) | 산출물 제출·시스템 링크·연결 생성·영향 판정, Custom Permission `PMS_DLV_Submit` | PMS_PSG_CFT, PMS_PSG_PM |
| PMS_PS_Deliverable_Manage (제안) | 임의 산출물 추가·삭제, 해당 없음 지정, 영향도 확정, Custom Permission `PMS_DLV_Manage` | PMS_PSG_PM, PMS_PSG_PMO |

**이 Vol.이 제공하는 계약**(다른 Vol.이 쓰는 이름)

| 이름 | 종류 | 정의 WI | 사용처 |
| --- | --- | --- | --- |
| PMS_EddCostService.price | Apex | CST-003 | CST-001·002 |
| PMS_CostAccess.canViewCost / canEditCost / assertCanViewProject | Apex | CST-003 | PMS-10-DSH-002·003, PMS-11-AIP-004 |
| PMS_CostPlanService.confirmBaseline | Apex | CST-001 | PMS-13-CHG-001 |
| PMS_CostActual__c upsert 계약(ExternalKey) | 수신 계약 | CST-002 | PMS-12-INT-003(DMS), SAP 경비(미정) |
| PMS_LaborRate__c upsert 계약(ExternalKey) | 수신 계약 | CST-003 | PMS-12-INT-002 |
| CMN_DwQuery PMS_CST_PORTFOLIO, PMS_CST_PROJECT_FX / EVENT_TYPE PMS_CST_RAG_CHANGED | Snowflake | CST-004 | PMS-10-DSH-002 |
| PMS_DeliverableService.syncFromTemplate / applySystemStatus | Apex | DLV-001 | PMS-04-WBS-003, PMS-07-ACT-002·003, PMS-12-INT-004·005 |
| PMS_DeliverableQueryService.byActivities / byCodes / byId | Apex | DLV-001 | PMS-07-ACT-004, PMS-09-GAT-003·005, PMS-11 |
| PMS_DeliverableCompletionChecker(RuleKey `PMS_DLV_MANDATORY_DONE`) | Apex | DLV-001 | PMS-07-ACT-004 |
| PMS_SystemLinkResolver, PMS_SystemLinkType__mdt | 인터페이스·설정 | DLV-001 | PMS-12-INT-004·005 |
| PMS_DeliverableEvent__e | 이벤트 | DLV-001 | PMS-12-INT-003·004·005, PMS-07-ACT-004(선택) |
| PMS_TraceGraphService.getGraph | Apex | DLV-003 | DLV-004, PMS-11-AIP |

**Snowflake 객체**(DB `SL_QDW`)

| 이름 | 종류 | 정의 WI | 내용 |
| --- | --- | --- | --- |
| CORE.SF_PMS_COSTBUDGET, CORE.SF_PMS_COSTACTUAL | 복제 테이블 | CST-001·002(등록) | 금액 열에 Masking Policy(ROLE_FINANCE_READ, ROLE_SF_READER만 원문) |
| MART.V_PMS_COST_LINE_MONTH | 뷰 | CST-004 | 프로젝트·범주·통화·월별 계획(월 분배)·실적 |
| MART.V_PMS_COST_PROJECT | 뷰 | CST-004 | 프로젝트별 기준선·계획·실적·EAC, 보고 통화 환산(CORE.SAP_FX_RATE) |
| TASK_PMS_CST_RAG | Task(일 04:00 KST) | CST-004 | CostRag 계산 → SHARE.OUTBOUND_EVENT |
| CORE.SF_PMS_DELIVERABLE, CORE.SF_PMS_DELIVERABLETRACE, CORE.SF_PMS_IMPACTASSESSMENT | 복제 테이블 | DLV-001·003·004(등록) | 마스킹 없음 |
| MART.V_PMS_TRACE_EDGE | 뷰 | DLV-003 | 산출물 연결 + 요구사항 연결 + 시스템 링크를 한 간선 표로 |

**KPI**(`CMN_KpiValue__c`, 계산 위치 Snowflake. 위젯은 PMS-10)

| KpiKey | 정의 | 주기 | 차원 | 계산 위치 |
| --- | --- | --- | --- | --- |
| PMS_DLV_ONTIME_RATE | 기한 안에 충족된 필수 산출물 수 ÷ 그 달 기한이 온 필수 산출물 수 | MONTH | Plant(ProdPlant), Customer | MART.V_SF_KPI_PMS_DLV |
| PMS_DLV_FIRST_PASS_RATE | 1회 상신으로 승인된 결재 산출물 수 ÷ 그 달 승인된 결재 산출물 수 | MONTH | Plant | MART.V_SF_KPI_PMS_DLV |
| PMS_DLV_OVERDUE | 기한이 지났는데 충족되지 않은 필수 산출물 수 | DAY | Plant, Customer | MART.V_SF_KPI_PMS_DLV |

**비용 KPI는 `CMN_KpiValue__c`에 넣지 않는다.** 이 객체는 사내 공개 읽기(OWD Read)라 금액이 새어 나간다(spec-snowflake-display 5절, Vol.7 D7-4와 같은 원칙). 비용 화면은 권한을 확인하는 Apex 집계(P0)와 RequiredPermission이 걸린 등록 쿼리(P2)로만 읽는다.

## 4. PMS-05 비용(CST)

### PMS-05-CST-001 비용 계획(예산 항목·ED&D 산정)

추적 P-29 · 필수 · W1 · SF · DM, APEX, LWC, CFG · Customization · 선행 CST-003, ARC-002, MDM-007, UX-005, UX-006, PMS-02-PRJ-001, PMS-02-PRJ-002, PMS-03-EFF-001, PMS-04-WBS-003 · 6 M/D

**목적**: 프로젝트 예산을 Tooling·ED&D·Piece Price·출장비·예비비 다섯 범주로 세우고, ED&D는 액티비티별 투입 계획 시간 × 법인·직급 평균 임율로 자동 산정한다(P-29 "CFT 임율 × 참여도"). 예산을 확정하면 기준선이 남아 이후 계획 변경과 실적을 기준선과 비교한다.

**범위** In: `PMS_CostBudget__c`, ED&D 계획 산정 서비스·배치, 예산 확정(기준선)·재확정, 예비비 사용, 예산 그리드 2개(수동·자동), 비용 탭 액션, 코드 그룹 `PMS_COST_SUBCATEGORY` 값. Out: 임율·가격 계산 엔진(CST-003), 실적(CST-002), 요약 화면·Excel(CST-004), 비용 변경 요청 결재(PMS-13-CHG-001).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_CostBudget__c.Project__c | Master-Detail(PMS_Project__c) | Y | 계약 |
| PMS_CostBudget__c.Name | Text(80) | Y | 예산 항목명(예: "메인 렌즈 금형", "ED&D 3.2.1 광학 설계") |
| PMS_CostBudget__c.Category__c | Picklist, 전역 값 집합 `PMS_CostCategory`(제안): TOOLING, EDD, PIECE_PRICE, TRAVEL, CONTINGENCY | Y | 계약 값. CST-002와 같은 값 집합 |
| PMS_CostBudget__c.SubCategory__c | Lookup(CMN_Code__c, Group `PMS_COST_SUBCATEGORY`) | N | 2레벨 코드, Attribute1 = Category. Lookup 필터로 같은 범주만 |
| PMS_CostBudget__c.Activity__c | Lookup(PMS_Activity__c) | EDD 자동이면 Y(프로젝트 공통 투입은 비움) | 같은 프로젝트 액티비티만(BR-7) |
| PMS_CostBudget__c.ProjectPart__c | Lookup(PMS_ProjectPart__c) | PIECE_PRICE면 Y, TOOLING 권장 | 같은 프로젝트 품번만 |
| PMS_CostBudget__c.PeriodMonth__c | Date | N | 지출 예정 월(그 달 1일). EDD 자동 행은 비움(월 분배는 CST-004가 투입 계획 주로 계산) |
| PMS_CostBudget__c.PlannedHours__c | Number(10,1) | EDD 자동이면 Y | 투입 계획 시간 합 |
| PMS_CostBudget__c.PlannedAmount__c | Number(16,2) | Y | 계약 PlannedAmount. 현재 계획 금액. PIECE_PRICE는 목표 단가(1개당) |
| PMS_CostBudget__c.CurrencyIsoCode__c | Text(3) | Y | 계약 "CurrencyIsoCode 문자열"(D-P5). ISO 4217, CMN 설정 `PMS_COST_CURRENCIES` 안의 값. 기본값 `PMS_COST_DEFAULT_CURRENCY`(KRW) |
| PMS_CostBudget__c.Basis__c | Long Text(4000) | N | 계약 Basis. 산정 근거. EDD 자동 행은 서비스가 쓴다(BR-2 (f)) |
| PMS_CostBudget__c.Source__c | Picklist (MANUAL, EFFORT_PLAN, IMPORT) | Y | EFFORT_PLAN = ED&D 자동 |
| PMS_CostBudget__c.FundingType__c | Picklist (SL_INVEST 자사 투자, CUSTOMER_PAID 고객 일시 지급, AMORTIZED 단가 상각) | TOOLING이면 Y | 투자 주체(고객 소유 금형 구분) |
| PMS_CostBudget__c.BaselineAmount__c | Number(16,2) | N | 예산 확정 시 PlannedAmount 사본. 확정 후 추가된 행은 0 |
| PMS_CostBudget__c.BaselineNo__c / BaselinedAt__c | Number(3,0) / DateTime | N | 확정 차수·일시 |
| PMS_CostBudget__c.ChangeReason__c | Text(255) | 확정 후 PlannedAmount 변경 시 Y | 최근 변경 사유(전체 이력은 필드 이력) |
| PMS_CostBudget__c.VarianceAmount__c | Formula(Number) | — | PlannedAmount − BLANKVALUE(BaselineAmount, 0) |
| PMS_CostBudget__c.IsUnitPrice__c | Formula(Checkbox) | — | ISPICKVAL(Category__c, 'PIECE_PRICE'). 합계 제외 표시 |
| PMS_CostBudget__c.IsAutoEdd__c | Formula(Checkbox) | — | ISPICKVAL(Source__c, 'EFFORT_PLAN'). 그리드 필터용 |
| PMS_CostBudget__c.ExternalKey__c | Text(120), External ID, Unique | 자동·가져오기면 Y | EDD 자동 `EDDP/{프로젝트 RecordNo}/{ActivityId 또는 PROJECT}/{통화}`, 가져오기 `IMP/{프로젝트 RecordNo}/B/{LineKey}` |
| PMS_CostBudget__c.SortOrder__c | Number(4,0) | N | 그리드 행 순서 |
| CMN_Code__c Group `PMS_COST_SUBCATEGORY` | 코드(Vol.0 변경 요청) | — | TOOLING: MOLD 금형, JIG 지그, CHECKING_FIXTURE 검사구, TOOLING_MOD 금형 수정비, TOOLING_OTHER 제비용 / EDD: LABOR 인건비(자동 전용), PROTOTYPE 시작품, TEST 시험·인증, OUTSOURCE 외주 설계, EDD_OTHER / PIECE_PRICE: TARGET 목표 단가 / TRAVEL: DOMESTIC 국내, OVERSEAS 해외 / CONTINGENCY: 없음 |

**ED&D 계획 서비스**

    public with sharing class PMS_CostPlanService {
        // 투입 계획으로 EDD 자동 행을 다시 만든다(멱등). 반환: 갱신한 행 수
        public static Integer recalculateEdd(Set<Id> projectIds);
        // 예산 확정(기준선 n+1). comment는 프로젝트 코멘트(UX-003)로 남긴다
        public static Integer confirmBaseline(Id projectId, String comment);
        // 예비비 사용: CONTINGENCY 행 → 대상 행으로 금액 이전
        public static void useContingency(Id contingencyLineId, Id targetLineId, Decimal amount, String reason);
    }

**비즈니스 규칙**

- BR-1: 범주 규칙.
  - PIECE_PRICE: PlannedAmount는 목표 단가(부품 1개)다. ProjectPart 필수. 총예산·차이 합계에서 빼고 화면에서 "단가"로 따로 보인다.
  - CONTINGENCY: 프로젝트·통화마다 1행 이하. 실적 행을 직접 붙일 수 없다(CST-002 BR-1). 쓰려면 BR-6 "예비비 사용"으로 다른 행에 옮긴다.
  - EDD 자동 행(Source EFFORT_PLAN, SubCategory LABOR)은 서비스만 만들고 고친다. 사용자는 Name과 SortOrder만 바꿀 수 있다. EDD 수동 행(PROTOTYPE, TEST, OUTSOURCE, EDD_OTHER)은 사용자가 만든다. 수동 행에 SubCategory LABOR를 고를 수 없다.
  - TOOLING: FundingType 필수. CUSTOMER_PAID·AMORTIZED여도 금액은 그대로 넣고, 순투자(SL 부담) 계산은 CST-004가 FundingType으로 나눈다.
- BR-2: ED&D 산정 `recalculateEdd(projectIds)` 순서.
  - (a) `PMS_EffortPlan__c`를 프로젝트별로 집계한다: GROUP BY Activity__c, CftMember__c, CALENDAR_YEAR(WeekStart__c), SUM(PlannedHours__c). 연도는 주 시작일 기준이다(주가 해를 넘겨도 나누지 않는다).
  - (b) CFT 구성원 → 임직원(CftMember.Employee, 없으면 User로 CMN_Employee__c 검색) → 직급(JobGradeCode__c)과 법인(Department__r.Plant__r.Company__c, 없으면 CMN 설정 `PMS_DEFAULT_COMPANY_CODE`).
  - (c) 시간 묶음(키 = 액티비티 Id 또는 PROJECT)을 만들어 `PMS_EddCostService.price(buckets, PLAN)`(CST-003)을 한 번 호출한다. 결과는 키 × 통화별 시간·금액이다.
  - (d) 키 × 통화마다 EDD 자동 행을 ExternalKey로 upsert한다. Name = "ED&D " + WBS 코드 + " " + 액티비티명(80자 자름), 통화가 둘 이상이면 끝에 " (통화)".
  - (e) 더 이상 계획 시간이 없는 기존 자동 행: 기준선이 있으면(BaselineNo 있음) 시간·금액을 0으로 두고, 없으면 삭제한다.
  - (f) Basis에는 "계획 시간 n h, 법인·직급 조합 m개, 임율 연도 yyyy~yyyy, 기본 임율 적용 k h, 상승률 적용 연도 수 j, 임율 누락 x h"를 쓴다. 임율 값과 개인 이름은 쓰지 않는다.
  - (g) 임율 누락 시간(x > 0)이 있으면 행은 만들되 금액은 누락분을 뺀 값이고, 그리드 경고("임율 누락 x h")를 보인다. 누락 알림은 CST-003 BR-6이 보낸다.
- BR-3: 재산정 시점.
  - 비용 탭 "ED&D 재산정" 버튼(Custom Permission `PMS_CST_Edit`).
  - 야간 배치 `PMS_EddPlanBatch`(매일 03:00 KST, 배치 크기 10 프로젝트): 지난 26시간 안에 투입 계획이 바뀐 프로젝트와, 임율(`PMS_LaborRate__c`)이 바뀐 연도에 계획 시간이 있는 진행 중 프로젝트.
  - 종료·취소 프로젝트는 재산정하지 않는다.
- BR-4: 총예산(통화별) = Σ PlannedAmount(PIECE_PRICE 제외). 기준선 총액 = Σ BaselineAmount(PIECE_PRICE 제외). 통화가 다른 금액은 더하지 않는다(환산은 Snowflake, D-P5).
- BR-5: 예산 확정 `confirmBaseline(projectId, comment)`.
  - 행이 1개 이상이어야 한다. 모든 행에 BaselineAmount = PlannedAmount, BaselineNo = 현재 최댓값 + 1, BaselinedAt = 지금을 넣는다.
  - 첫 확정(BaselineNo 1)은 `PMS_CST_Edit` 보유자. 재확정(2 이상)은 PMS-13-CHG-001의 비용 변경 승인 콜백이 호출하거나, CHG-001 배포 전에는 Custom Permission `PMS_CST_Rebaseline`(재무, PMS_PS_LaborRate_Admin) 보유자만. PMO가 재확정을 요청하면 재무가 처리한다.
  - 프로젝트 코멘트(UX-003)에 "비용 기준선 n 확정: {comment}"를 남긴다. 금액은 코멘트에 쓰지 않는다.
- BR-6: 예비비 사용 `useContingency`. 같은 프로젝트·같은 통화만, 금액 > 0, CONTINGENCY 잔액(PlannedAmount) 이하, 사유 필수. CONTINGENCY 행 PlannedAmount −= 금액, 대상 행 += 금액을 한 트랜잭션에서 바꾸고 두 행의 ChangeReason에 "예비비 사용: {사유}"를 넣는다. 대상은 PIECE_PRICE·CONTINGENCY·EDD 자동 행일 수 없다(EDD 인건비 초과는 EDD_OTHER 행을 대상으로 한다).
- BR-7: 검증(트리거 before insert/update, `PMS_CostBudgetTriggerHandler`).
  - PlannedAmount ≥ 0. 통화는 허용 목록 안.
  - Activity·ProjectPart는 같은 프로젝트 소속(벌크 조회 1회).
  - 기준선이 있는 행의 PlannedAmount가 바뀌면 ChangeReason 필수(같은 저장에서 바뀌어야 한다).
  - Source EFFORT_PLAN 행의 PlannedHours·PlannedAmount·Category·Activity·통화 변경은 `CMN_UiRuleService.runAsService` 안(서비스)에서만 허용.
- BR-8: 삭제. MANUAL·IMPORT 행 중 BaselineNo가 없는 행만 `PMS_CST_Edit` 보유자가 삭제한다. 기준선이 있는 행은 0으로 바꾸고 사유를 남긴다. 삭제 시 CMN_DeleteLog__c(SEC-003)에 스냅숏을 남긴다(금액 포함, 로그 객체 자체가 관리자 전용).
- BR-9: 그리드(UX-006) 두 개를 비용 탭에 둔다.
  - gridKey `PMS_CostBudget_Manual`: 부모 PMS_Project__c, Filter `IsAutoEdd__c=false`, MaxRows 500, OrderField SortOrder__c. 열: 범주, 세부 범주(CODE), 항목명, 품번, 지출 월, 계획 금액, 통화, 투자 주체, 기준선 금액(읽기), 차이(읽기), 변경 사유, 원천(읽기). EditRuleKey `PMS_CostBudgetGrid`.
  - gridKey `PMS_CostBudget_Edd`: Filter `IsAutoEdd__c=true`, AllowAdd·AllowDelete·AllowPaste false. 열: 항목명, 액티비티(읽기), 계획 시간(읽기), 계획 금액(읽기), 통화(읽기), 기준선 금액(읽기), 차이(읽기). 일정 막대 없음.
  - Provider `PMS_CostBudgetGridProvider`가 하는 것: (a) `defaults`: Source MANUAL, 통화 기본값, SortOrder 다음 번호. (b) `rowMeta`: 기준선 행 deletable = false(안내 "기준선 행은 0으로 바꾸고 사유를 남기세요"), 임율 누락 경고(EDD 자동). (c) `validate`: BR-1·BR-7과 같은 규칙. CST-004 가져오기도 이 메서드를 쓴다.
- BR-10: UX-005 규칙(`meta-src/ui-rules/PMS_Project__c.json`에 행 추가).
  - COMPONENT `PMS_CostTab`: 모든 상태, CustomPermission `PMS_ViewCost`(비용 탭 표시).
  - COMPONENT `PMS_CostBudgetGrid`: PRJ-001의 진행 상태 값(종료·취소 제외), CustomPermission `PMS_CST_Edit`.
  - 비용 탭 액션 컴포넌트의 버튼 3개(ED&D 재산정, 예산 확정, 예비비 사용)는 서버 메서드 첫 줄에서 `CMN_UiRuleService.assertCanExecute(projectId, 'PMS_CostBudgetGrid')`를 호출한다.

**화면/UX**: 화면 유형 T2(프로젝트 T1 레코드의 "비용" 탭) · 공통 부품 UX-006 그리드 2개, UX-005 규칙, UX-003 코멘트.
- 프로젝트 레코드 페이지(PRJ-001 생성기 정의 파일)에 "비용" 탭을 더한다. 탭 가시성은 UX-005 COMPONENT `PMS_CostTab`. 비용 권한이 없는 사용자에게는 탭 자체가 없다.
- 탭 위쪽: `pmsCostPlanActions`(제안, 작은 LWC) — 버튼 "ED&D 재산정", "예산 확정", "예비비 사용"(모달: 예비비 행·대상 행·금액·사유). 확정 차수와 마지막 확정 일시를 텍스트로 보인다. 요약 카드는 CST-004가 같은 탭 맨 위에 더한다.
- 그 아래 그리드 2개(수동 예산 → ED&D 자동). 휴대폰에서는 UX-006 BR-7 카드 목록(읽기 전용).

**권한**: 예산 조회 PMS_PS_Cost_Read, 편집·확정·예비비 사용 PMS_PS_Cost_Edit, 재확정 `PMS_CST_Rebaseline`(PMS_PS_LaborRate_Admin에 포함, 재무만. CHG-001 배포 후에는 비용 변경 승인 콜백이 호출). CFT·팀장 PSG는 이 객체 권한이 없다.

**수용 기준**

- AC-1: Given 액티비티 A에 KR01 법인 G3 직급 100h(2027), CN01 법인 G2 직급 50h(2027) 투입 계획, When ED&D 재산정, Then EDD 자동 행 2건(KRW 100h, CNY 50h)이 생기고 금액 = 시간 × 해당 임율이며, Basis에 임율 숫자가 없다.
- AC-2: Given 같은 투입 계획, When 재산정 2회, Then 행 수·금액 변화 없음(멱등).
- AC-3: Given PIECE_PRICE 행에 품번 없음, When 그리드 저장, Then 행 오류로 차단.
- AC-4: Given 기준선 1 확정 후, When 수동 행 PlannedAmount를 사유 없이 변경, Then 차단. 사유를 넣으면 저장되고 필드 이력이 남는다.
- AC-5: Given CONTINGENCY 10,000 KRW, When TRAVEL(KRW) 행으로 3,000 이전, Then 7,000 / +3,000, 두 행 ChangeReason 기록. EUR 대상 행이면 차단.
- AC-6: Given PMS_PSG_CFT만 가진 사용자, When 프로젝트 페이지 열기와 `SELECT ... FROM PMS_CostBudget__c WITH USER_MODE`, Then 비용 탭이 없고 쿼리는 권한 오류.
- AC-7: Given EDD 자동 행, When 그리드 API로 PlannedAmount 변경, Then 서버에서 거부.
- AC-8: Given 기준선 1이 있는 프로젝트, When `PMS_CST_Rebaseline` 없는 PM이 재확정, Then 차단.
- AC-9: Given 액티비티 300개 × 구성원 20명 투입 계획, When 재산정, Then SOQL 8회 이하, DML 3회 이하(벌크 테스트).
- AC-10: Given TOOLING 500(KRW)·EDD 300·PIECE_PRICE 12.5·CONTINGENCY 50, When 총예산 표시, Then 850 KRW(PIECE_PRICE 제외).

**에이전트 주의**: 임율을 이 WI 코드에서 직접 조회하지 않는다(CST-003 `PMS_EddCostService`만). 서로 다른 통화를 더하거나 Apex에서 환율을 곱하지 않는다. 금액·임율을 `CMN_Logger`·코멘트·To-Do 제목에 쓰지 않는다. Category 값을 Picklist마다 따로 정의하지 말고 전역 값 집합 하나를 두 객체가 같이 쓴다.

**오픈 이슈**: SL 현행 예산 양식의 세부 범주(시작품·시험·인증비를 ED&D로 볼지 별도 범주로 볼지), 고객 지급 금형의 회수(정산) 추적 필요 여부, 프로젝트 공통 투입(액티비티 없는 시간) 허용 여부(EFF-001).

### PMS-05-CST-002 비용 실적(ED&D 자동·출장비·금형비)

추적 P-30, P-32 · 필수 · W1 · SF · DM, APEX, CFG · Customization · 선행 CST-001, CST-003, INT-001, TDO-001, UX-006, PMS-03-EFF-002 · 6 M/D

**목적**: 승인된 주간 투입 실적으로 ED&D 인건비 실적을 월별로 자동 계산하고(P-30), DMS의 금형·지그·검사구·제비용 금액을 프로젝트 기준으로 받아(P-32), 출장비·시작품비·실적 단가는 직접 입력한다. 월 마감 후 숫자를 동결해 보고 숫자가 바뀌지 않게 한다.

**범위** In: `PMS_CostActual__c`, ED&D 실적 계산 서비스·배치, 월 마감·마감 해제, 수동 실적 그리드, 연계 행 보호, DMS·SAP 수신 계약(upsert 키·필드). Out: Mule 구현(PMS-12-INT-003 DMS, SAP 경비 연계는 SL 확인 후 PMS-12 신규 WI), 요약·차이 화면(CST-004), DMS 수정비 단계 적용(PMS-13-CHG-002).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_CostActual__c.Project__c | Master-Detail(PMS_Project__c) | Y | 계약 |
| PMS_CostActual__c.Name | Text(80) | Y | 예: "ED&D 인건비 2027-03", "BMW 뮌헨 고객 회의 출장" |
| PMS_CostActual__c.Category__c | Picklist, 전역 값 집합 `PMS_CostCategory` | Y | 계약. CONTINGENCY는 검증으로 막는다(BR-1) |
| PMS_CostActual__c.SubCategory__c | Lookup(CMN_Code__c, Group `PMS_COST_SUBCATEGORY`) | N | |
| PMS_CostActual__c.PeriodMonth__c | Date | Y | 계약. 귀속 월(그 달 1일) |
| PMS_CostActual__c.Amount__c | Number(16,2) | Y | 계약. PIECE_PRICE는 그 달 실적(견적·승인) 단가 |
| PMS_CostActual__c.CurrencyIsoCode__c | Text(3) | Y | ISO 4217, 허용 목록 |
| PMS_CostActual__c.ActualHours__c | Number(10,1) | EDD 자동이면 Y | 그 달 승인 투입 시간 |
| PMS_CostActual__c.Source__c | Picklist (EFFORT_AUTO, DMS, MANUAL, SAP) | Y | 계약 |
| PMS_CostActual__c.SourceRef__c | Text(80) | DMS·SAP면 Y | 계약. DMS 항목 번호, SAP 전표 번호·행 |
| PMS_CostActual__c.Budget__c | Lookup(PMS_CostBudget__c) | N | 대응 예산 행(같은 프로젝트·범주·통화) |
| PMS_CostActual__c.ProjectPart__c | Lookup(PMS_ProjectPart__c) | PIECE_PRICE면 Y | |
| PMS_CostActual__c.VendorName__c | Text(120) | N | 금형 제작처, 시험 기관 등 |
| PMS_CostActual__c.Traveler__c / Destination__c / TravelFrom__c / TravelTo__c | Lookup(User) / Text(120) / Date / Date | TRAVEL이면 Y | 출장자·목적지·기간 |
| PMS_CostActual__c.IsLocked__c | Checkbox | — | 월 마감 후 true(서비스만) |
| PMS_CostActual__c.IsProvisionalRate__c | Checkbox | — | EDD 자동: 그 해 임율이 없어 전년 임율을 임시 적용 |
| PMS_CostActual__c.AdjustmentOfMonth__c | Date | N | 마감 월의 지연 승인분 조정 행이면 원래 월 |
| PMS_CostActual__c.IsSystemSource__c | Formula(Checkbox) | — | NOT(ISPICKVAL(Source__c, 'MANUAL')). 그리드 필터용 |
| PMS_CostActual__c.ExternalKey__c | Text(120), External ID, Unique | 자동·연계면 Y | BR-3·BR-6 키 규칙 |
| PMS_CostActual__c.Note__c | Text(255) | DMS 미연계 공장의 TOOLING 수동 행이면 Y | |

**ED&D 실적 서비스**

    public with sharing class PMS_CostActualService {
        // 열린 달의 EDD 자동 행을 다시 계산하고, 마감 월의 지연 승인분은 조정 행으로 만든다(멱등)
        public static Integer recalculateEdd(Set<Id> projectIds);
        // 월 마감: periodMonth 이전(포함) 모든 행 IsLocked = true
        public static Integer closeMonth(Date periodMonth);
        // 마감 해제(재무, 사유 필수): 한 프로젝트의 한 달
        public static void reopenMonth(Id projectId, Date periodMonth, String reason);
    }

**비즈니스 규칙**

- BR-1: 범주 × 원천 허용 표.

  | 범주 | 허용 원천 | 비고 |
  | --- | --- | --- |
  | EDD | EFFORT_AUTO(SubCategory LABOR, 서비스만), MANUAL·SAP(PROTOTYPE, TEST, OUTSOURCE, EDD_OTHER) | 수동 행에 LABOR 금지 |
  | TOOLING | DMS, MANUAL(DMS 미연계 공장만, Note 필수) | DMS 행은 읽기 전용 |
  | PIECE_PRICE | MANUAL, SAP | ProjectPart 필수, 합산하지 않음 |
  | TRAVEL | MANUAL, SAP | 출장자·목적지·기간 필수 |
  | CONTINGENCY | 없음 | 저장 차단(CST-001 BR-6으로 이전해 쓴다) |

- BR-2: 시스템 원천 행(EFFORT_AUTO, DMS, SAP)은 사용자가 만들거나 고치거나 지울 수 없다. 트리거가 막고, `CMN_UiRuleService.runAsService` 안(서비스)이거나 실행 사용자가 Custom Permission `PMS_CST_IntegrationWrite`(통합 사용자)를 가질 때만 허용한다.
- BR-3: ED&D 실적 `recalculateEdd(projectIds)` 순서.
  - (a) 열린 달 = IsLocked 행이 없는 달. 대상 기간 = 가장 이른 열린 달 1일 − 6일 ~ 오늘.
  - (b) `PMS_EffortActual__c` 중 Status = APPROVED(EFF-002)만 읽는다. 요일 칸(MonHours~SunHours)마다 날짜 = WeekStart + n일로 바꾸고, 그 날짜의 월·연도에 시간을 귀속한다. 주가 두 달에 걸치면 요일별로 나뉜다.
  - (c) 구성원 → 직급·법인은 CST-001 BR-2 (b)와 같은 방법이다(계산 시점의 현재 직급).
  - (d) 시간 묶음 키 = 프로젝트 Id + 월(yyyy-MM). `PMS_EddCostService.price(buckets, ACTUAL)`를 한 번 호출한다. ACTUAL 모드는 상승률을 쓰지 않고, 그 해 임율이 없으면 직전 연도 임율을 쓰고 `provisional = true`를 돌려준다.
  - (e) 열린 달: 키 `EDD/{프로젝트 RecordNo}/{yyyy-MM}/{통화}`로 upsert(Name "ED&D 인건비 yyyy-MM", Category EDD, SubCategory LABOR, Source EFFORT_AUTO, ActualHours, Amount, IsProvisionalRate). 시간이 0이 된 열린 달 행은 지운다.
  - (f) 마감 월(L): 지금 다시 계산한 금액·시간과 마감 행의 금액·시간의 차이가 있으면, 가장 이른 열린 달(P)에 조정 행 `EDD-ADJ/{프로젝트 RecordNo}/{L yyyy-MM}/{P yyyy-MM}/{통화}`를 upsert한다(AdjustmentOfMonth = L, 차이 금액·시간, Name "ED&D 조정(yyyy-MM분)"). 마감 행 자체는 바꾸지 않는다. 차이가 0이면 조정 행을 지운다.
  - (g) 지연 승인·반려로 시간이 줄면 조정 금액이 음수일 수 있다(허용).
- BR-4: 재계산 시점.
  - 야간 배치 `PMS_EddActualBatch`(매일 02:30 KST, 배치 크기 10 프로젝트): 지난 26시간 안에 투입 실적이 바뀐 프로젝트, 임율이 바뀐 연도의 열린 달이 있는 진행 중 프로젝트, IsProvisionalRate 행이 있는 프로젝트.
  - 비용 탭 "실적 재계산" 버튼(`PMS_CST_Edit`).
- BR-5: 월 마감.
  - 스케줄 `PMS_CostCloseJob`: 매월 CMN 설정 `PMS_COST_CLOSE_DAY`(기본 5)일 06:00 KST에 전월까지의 모든 프로젝트를 먼저 `recalculateEdd`로 마지막 계산한 뒤 `closeMonth(전월 1일)`로 IsLocked = true.
  - 마감 행은 누구도 고칠 수 없다(연계 포함). 정정은 열린 달에 새 행(수동) 또는 연계 새 키로 넣는다.
  - 마감 해제 `reopenMonth`는 Custom Permission `PMS_CST_CloseAdmin`(재무)만, 프로젝트·월 단위, 사유 필수. 프로젝트 코멘트에 "yyyy-MM 비용 마감 해제: 사유"를 남긴다. 해제된 달은 다음 마감 작업에서 다시 잠긴다.
- BR-6: DMS 수신 계약(구현 PMS-12-INT-003, Mule이 Composite·Bulk upsert).
  - 키 `DMS/{DMS 항목 번호}/{귀속 yyyy-MM}`. 필드: Project__r.RecordNo__c(외부 참조), Category TOOLING, SubCategory(코드 외부 키 `PMS_COST_SUBCATEGORY/MOLD` 등), PeriodMonth(검수·지급 월), Amount, CurrencyIsoCode, SourceRef(DMS 항목 번호), VendorName, Name("금형 {품명}" 등).
  - 금액은 DMS가 원본이다. Salesforce에서 고치지 않는다. 바뀌면 DMS가 같은 키로 다시 보낸다. 마감된 달 정정은 열린 달을 귀속 월로 한 새 키로 보낸다(BR-5).
  - 프로젝트 대응 키(DMS 프로젝트 코드 ↔ PMS 프로젝트 번호)는 INT-003이 정한다. 대응이 없는 행은 Mule이 적재하지 않고 CMN_InterfaceLog__c에 남긴다.
  - SAP 원천(경비 전표)을 연계하면 키 `SAP/{회사 코드}/{전표 번호}/{행}`을 쓴다.
- BR-7: 수동 실적 그리드(UX-006).
  - gridKey `PMS_CostActual_Manual`: 부모 PMS_Project__c, Filter `IsSystemSource__c=false`, MaxRows 500, OrderField PeriodMonth__c. 열: 범주, 세부 범주, 항목명, 귀속 월, 금액, 통화, 예산 행, 품번, 출장자, 목적지, 출장 시작, 출장 종료, 거래처, 비고, 마감(읽기). EditRuleKey `PMS_CostBudgetGrid`(CST-001과 같은 규칙).
  - Provider `PMS_CostActualGridProvider`: (a) `defaults`: Source MANUAL, 귀속 월 = 이번 달, 통화 기본값. (b) `rowMeta`: IsLocked 행은 모든 열 잠금·삭제 불가(안내 "마감된 달입니다"). (c) `validate`: BR-1 표, TRAVEL 필수 필드와 TravelFrom ≤ TravelTo, 귀속 월이 마감 월이면 오류, 귀속 월 > 이번 달이면 오류(미래 실적 금지), Budget은 같은 프로젝트·범주·통화, PIECE_PRICE는 ProjectPart 필수.
  - gridKey `PMS_CostActual_System`: Filter `IsSystemSource__c=true`, 편집·추가·삭제 없음(조회 전용). 열: 원천, 항목명, 귀속 월, 시간, 금액, 통화, 원천 번호, 거래처, 조정 원래 월, 임시 임율, 마감.
- BR-8: ED&D 실적은 프로젝트 × 월 × 통화 한 행으로만 남긴다. 직급별·개인별 분해는 Salesforce에 저장하지 않는다(임율 역산 방지, DP3-2).

**화면/UX**: 화면 유형 T2(프로젝트 "비용" 탭) · 공통 부품 UX-006 그리드 2개, UX-005 규칙.
- 비용 탭의 예산 그리드 아래에 "실적" 구역: 수동 실적 그리드 → 연계·자동 실적 그리드.
- `pmsCostPlanActions`(CST-001)에 버튼 "실적 재계산"과 재무용 "마감 해제"(모달: 월·사유)를 더한다.

**권한**: 조회 PMS_PS_Cost_Read, 수동 입력·재계산 PMS_PS_Cost_Edit, 마감 해제 PMS_PS_LaborRate_Admin(`PMS_CST_CloseAdmin`), 연계 적재 PMS_PS_Cost_Integration.

**수용 기준**

- AC-1: Given 2027-03-29(월) 시작 주의 승인 실적 월~수 8h, 목·금 8h, When 재계산, Then 2027-03 행 24h, 2027-04 행 16h.
- AC-2: Given SUBMITTED(미승인) 실적, When 재계산, Then 포함되지 않는다.
- AC-3: Given 2027-02 마감 후 2월 실적 10h가 3월에 승인, When 재계산, Then 2월 행은 그대로이고 3월에 조정 행(AdjustmentOfMonth 2027-02, 10h 금액) 1건.
- AC-4: Given 통합 사용자가 같은 DMS 키로 2회 upsert, When 적재, Then 1행(멱등). Given 일반 사용자, When DMS 행 금액 수정, Then 차단.
- AC-5: Given TRAVEL 행에 출장자 없음, When 그리드 저장, Then 행 오류.
- AC-6: Given CONTINGENCY 실적, When 저장, Then 차단.
- AC-7: Given 2028년 1월 승인 실적, 2028년 임율 없음, When 재계산, Then 2027년 임율로 계산되고 IsProvisionalRate = true. 2028년 임율 등록 다음 날 배치 후 false로 바뀌고 금액이 다시 계산된다(열린 달만).
- AC-8: Given 마감 행, When 재무가 아닌 사용자가 reopenMonth 호출, Then 차단. 재무가 사유와 함께 호출하면 IsLocked = false, 코멘트 1건.
- AC-9: Given 프로젝트 50개 × 구성원 30명 × 5주 실적, When 배치(크기 10), Then execute당 SOQL 10회 이하.
- AC-10: Given 계산 중 오류 로그, When CMN_Log__c 확인, Then 금액·임율 숫자가 메시지·Payload에 없다.

**에이전트 주의**: 투입 실적의 반올림·자정 경계를 사용자 시간대로 바꾸지 않는다(날짜 = WeekStart + n일, 시간대 변환 없음). 마감 행을 "정정"한다고 직접 update하지 않는다(조정 행). DMS 행을 그리드에서 편집 가능하게 열지 않는다. 출장비 영수증 파일은 이 객체에 붙이지 않는다(경비 증빙은 SAP·경비 시스템 원본).

**오픈 이슈**: 출장비 원천(SAP 경비 전표·그룹웨어 출장 시스템 연계 여부), 월 마감일(재무 결산 일정), DMS가 주는 금액 기준(발주·검수·지급 중 무엇), 해외 법인 실적 통화.

### PMS-05-CST-003 직급 평균 임율·비용 권한 분리

추적 P-29, P-30, P-57, NFR-4.2 · 필수 · W1 · SF, SNOW · DM, APEX, CFG · Customization · 선행 ARC-002, SEC-001, SEC-004, MDM-001, MDM-002, INT-002, DWH-002, PMS-03-CFT-001 · 4 M/D

**목적**: 직급 평균 임율은 인사 민감 정보다. 재무만 원문을 보고, PM·PMO·경영진은 임율을 곱한 금액만 보며, CFT 구성원은 비용 자체를 보지 않는다(P-57 "Cost 정보 권한 분리"). 임율을 읽는 코드를 한 곳으로 모아 다른 WI가 임율을 직접 조회하지 못하게 한다.

**범위** In: `PMS_LaborRate__c`, 임율 적용 엔진 `PMS_EddCostService`, 비용 권한 도우미 `PMS_CostAccess`, 비용 PS 5개·Custom Permission, 임율 관리 리스트뷰·다음 연도 복사 Flow, Snowflake 마스킹·복제 제외 설정, 임율 누락 알림. Out: HR 연계 구현(PMS-12-INT-002), 보고서 화면의 비용 숨김(PMS-10-DSH-003), 예산·실적 객체(CST-001·002).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_LaborRate__c | Custom Object, OWD Private, 공유 규칙·Apex 공유 없음 | — | 계약 "비공개, 원가 PS만". Name = "{법인 코드}-{직급}-{연도}"(트리거가 채움) |
| PMS_LaborRate__c.Company__c | Lookup(CMN_Company__c) | Y | (제안) 법인. 임율은 법인·국가별로 다르다 |
| PMS_LaborRate__c.JobGradeCode__c | Text(10) | Y | 계약. HR 직급 코드(CMN_Employee__c.JobGradeCode__c와 같은 값). `DEFAULT` = 직급을 모를 때 쓰는 법인 기본 임율 |
| PMS_LaborRate__c.Year__c | Number(4,0) | Y | 계약. 적용 연도 |
| PMS_LaborRate__c.HourlyRate__c | Number(12,2) | Y | 계약. 시간당 평균 임율 원문(> 0) |
| PMS_LaborRate__c.CurrencyIsoCode__c | Text(3) | Y | (제안) 임율 통화(법인 현지 통화). 허용 목록 |
| PMS_LaborRate__c.Source__c | Picklist (HR, MANUAL) | Y | HR = INT-002 적재, MANUAL = 재무 입력 |
| PMS_LaborRate__c.ExternalKey__c | Text(40), External ID, Unique | Y | `{CompanyCode}-{JobGradeCode}-{Year}`. 연계·입력 모두 같은 키 |
| PMS_LaborRate__c.IsActive__c | Checkbox | Y | 기본 true. 삭제 대신 false |
| PMS_LaborRate__c.Note__c | Text(255) | N | |
| Custom Permission | `PMS_ViewCost`, `PMS_CST_Edit`, `PMS_CST_Portfolio`, `PMS_CST_RateAdmin`, `PMS_CST_CloseAdmin`, `PMS_CST_Rebaseline`, `PMS_CST_IntegrationWrite` | — | 3절 권한 셋 표대로 PS에 넣는다 |
| CMN_Code__c Group `APPROVAL_ROLE` 값 `COST_CONTROLLER` | 코드(Vol.0 변경 요청) | — | 법인별 원가 담당(임율 누락 알림 수신). CMN_RoleAssignment__c로 지정 |

**서비스 API**

    public with sharing class PMS_EddCostService {
        public enum Mode { PLAN, ACTUAL }
        public class HourBucket { public String key; public Id companyId; public String jobGradeCode; public Integer year; public Decimal hours; }
        public class Priced { public String key; public String currencyIsoCode; public Decimal hours; public Decimal amount;
                              public Decimal defaultRateHours; public Decimal missingRateHours; public Boolean provisional; public Integer escalatedYears; }
        // 임율을 곱한 금액만 돌려준다. 임율 값은 어떤 반환값에도 넣지 않는다
        public static List<Priced> price(List<HourBucket> buckets, Mode mode);
        // 내부: private without sharing class RateReader — 유일한 임율 조회 지점
    }
    public with sharing class PMS_CostAccess {
        public static Boolean canViewCost();                    // FeatureManagement.checkPermission('PMS_ViewCost')
        public static Boolean canEditCost();                    // 'PMS_CST_Edit'
        public static void assertCanViewProject(Id projectId);  // canViewCost + 프로젝트 읽기(UserRecordAccess), 아니면 CMN_ValidationException
    }

**비즈니스 규칙**

- BR-1: 객체 접근. Read·Create·Edit 권한은 PMS_PS_LaborRate_Admin(재무)과 PMS_PS_Cost_Integration에만 있다. Delete 권한은 누구에게도 주지 않는다(IsActive로 대체). 리스트뷰·리포트·글로벌 검색·Agentforce는 객체 권한으로 자동 차단된다. 시스템 관리자(View All Data)의 열람은 오픈 이슈.
- BR-2: 검증. ExternalKey 중복 금지, HourlyRate > 0, Year 2020~2100, 통화 허용 목록. Source HR 행의 HourlyRate·통화는 사용자(재무 포함)가 고칠 수 없다(`PMS_CST_IntegrationWrite` 보유자만). 재무는 HR이 주지 않는 조합을 MANUAL로 만들 수 있고, 나중에 HR이 같은 키를 보내면 HR 값으로 덮이고 Source가 HR로 바뀐다.
- BR-3: 임율 선택(키 = 법인·직급·연도, IsActive만).
  - (a) 정확히 일치하는 행.
  - (b) 없으면 같은 법인·직급의 가장 최근 이전 연도 행. PLAN 모드는 연도 차이 n만큼 `(1 + PMS_LABOR_RATE_ESCALATION_PCT/100)^n`을 곱하고(escalatedYears = n), ACTUAL 모드는 곱하지 않고 provisional = true.
  - (c) 그래도 없으면 같은 법인 `DEFAULT` 직급으로 (a)·(b)를 반복(defaultRateHours에 합산).
  - (d) 그래도 없으면 금액 0, missingRateHours에 합산.
  - 대상 연도보다 이후 연도 행만 있는 경우(과거 실적)는 가장 이른 행을 쓰고 provisional = true.
- BR-4: `RateReader`는 `PMS_EddCostService` 안의 private inner class로 `without sharing`이며 클래스 머리에 `// SHARING-EXCEPTION: PMS-05-CST-003 비공개 임율을 금액 계산에만 읽는다(읽기 전용, 값은 반환하지 않음)`를 단다. SOQL은 `WITH SYSTEM_MODE`, 필요한 법인·직급·연도 집합으로 1회. 다른 클래스에서 `PMS_LaborRate__c`를 조회하는 코드를 만들지 않는다(코드 리뷰·정적 검사 대상).
- BR-5: 로그 금지. `price`와 그 호출자는 임율·금액·시간 × 임율을 `CMN_Logger`, 예외 메시지, 디버그 로그(`System.debug`)에 쓰지 않는다. 로그에는 버킷 수·누락 조합 수·소요 시간만 남긴다.
- BR-6: 임율 누락 알림. `price` 결과에 missingRateHours > 0인 법인·직급·연도가 있으면, 법인의 Role `COST_CONTROLLER`(CMN_RoleAssignment__c, 법인 소속 공장 기준, 없으면 전사)에게 To-Do(SourceType `PMS_CST_RATE_MISSING`, SourceRecordId = 법인 Id, 제목 "임율 등록 필요: {법인} {직급} {연도}")를 연다. 같은 조합의 열린 To-Do가 있으면 새로 만들지 않는다(TDO ExternalKey 멱등). 임율이 등록되면 다음 배치가 To-Do를 닫는다.
- BR-7: 다음 연도 복사. Screen Flow `PMS_LaborRate_Screen_Rollover`(재무 리스트뷰 버튼) → Invocable `PMS_LaborRateService.rollover(fromYear, toYear, pct, companyIds)`: fromYear의 활성 행을 toYear MANUAL 행으로 복사하고 HourlyRate × (1 + pct/100). 이미 있는 키는 건너뛴다. 결과는 생성·건너뜀 건수만 보인다.
- BR-8: Snowflake.
  - `PMS_LaborRate__c`는 DWH-002 복제 대상에 넣지 않는다. 필드 이력 적재(CORE.SF_FIELD_HISTORY)에서도 `PMS_LaborRate__History`를 뺀다.
  - CORE.SF_PMS_COSTBUDGET·SF_PMS_COSTACTUAL의 금액 열(PLANNEDAMOUNT__C, BASELINEAMOUNT__C, AMOUNT__C)과 이 두 객체의 필드 이력 OLDVALUE·NEWVALUE에 Masking Policy `MP_PMS_COST`를 건다: ROLE_FINANCE_READ·ROLE_SF_READER만 원문, 그 외 NULL. 정의는 schemachange 스크립트 `V{nnn}__pms_cost_masking.sql`(SEC-004·DWH-001 규칙).
- BR-9: 비용 화면·서비스 공통 규칙. 비용을 보여주거나 돌려주는 모든 `@AuraEnabled` 메서드는 첫 줄에서 `PMS_CostAccess.assertCanViewProject(projectId)`(프로젝트 단위) 또는 `canViewCost()`(포트폴리오는 `PMS_CST_Portfolio`도)를 확인한다. 화면 숨김만으로 통제하지 않는다. Agentforce Action(PMS-11-AIP-004)은 USER_MODE로 읽으므로 FLS·객체 권한이 없는 사용자의 답에는 금액이 나오지 않는다.
- BR-10: 비용 PS·PSG 매핑은 3절 표대로 한다. PSG 자체(계약 10절 이름)는 Vol.P1이 만들고, 이 WI는 PS를 만들어 PSG 구성 요소로 넣는다. `CMN_PSG_Executive`에는 PMS_PS_Cost_Read와 PMS_PS_Cost_Portfolio를 넣는다(Vol.0 SEC-001 변경 요청).

**화면/UX**: 화면 유형 T6(마스터 관리) · 공통 부품 없음(리스트뷰 + Screen Flow).
- SL PMS 앱의 재무 전용 탭 "임율"(탭 가시성은 객체 권한으로 결정). 리스트뷰 "올해 임율"(Year = THIS_YEAR), "임율 누락 후보"(법인별 DEFAULT 없음), 인라인 편집(MANUAL 행만).
- 리스트뷰 버튼 "다음 연도 임율 만들기"(BR-7 Flow).

**권한**: 임율 원문 PMS_PS_LaborRate_Admin(PMS_PSG_Finance)만. 계산된 금액 조회는 PMS_PS_Cost_Read.

**수용 기준**

- AC-1: Given PMS_PSG_CFT·PMS_PSG_PM 사용자, When `SELECT HourlyRate__c FROM PMS_LaborRate__c WITH USER_MODE`, Then 권한 오류.
- AC-2: Given KR01 법인 G3 직급 2027 임율 X, 2028 없음, 상승률 3%, When price(2028, PLAN), Then 금액 = 시간 × X × 1.03, escalatedYears 1. When price(2028, ACTUAL), Then 시간 × X, provisional = true.
- AC-3: Given 직급이 없는 임직원 40h, 법인 DEFAULT 임율 있음, When price, Then defaultRateHours 40.
- AC-4: Given 법인 임율이 하나도 없음, When price, Then 금액 0, missingRateHours = 시간, 원가 담당 To-Do 1건. 같은 날 다시 호출해도 To-Do는 1건.
- AC-5: Given price를 실행한 테스트, When CMN_Log__c와 예외 메시지 확인, Then 임율·금액 문자열이 없다.
- AC-6: Given 버킷 200개(법인 5 × 직급 8 × 연도 5 조합), When price, Then SOQL 2회 이하.
- AC-7: Given `PMS_ViewCost`가 없는 사용자, When 비용 컨트롤러 메서드 직접 호출, Then 라벨 오류(`PMS_Cost_NoAccess`).
- AC-8: Given Source HR 행, When 재무가 HourlyRate 수정, Then 차단. 통합 사용자는 성공.
- AC-9: Given Snowflake ROLE_QMS_ANALYST, When CORE.SF_PMS_COSTACTUAL.AMOUNT__C 조회, Then NULL. ROLE_FINANCE_READ는 원문.
- AC-10: Given 2027 행 20개, When 2028로 5% 복사, Then 20건 생성, 다시 실행하면 0건 생성·20건 건너뜀.

**에이전트 주의**: 임율을 Platform Cache, 정적 리소스, 테스트 픽스처 공용 파일(데모 데이터)에 넣지 않는다(테스트는 메서드 안에서 만든다). `PMS_LaborRate__c`에 Lookup을 거는 다른 객체를 만들지 않는다(관련 목록으로 노출됨). 금액 필드를 Formula로 다른 객체(프로젝트 등)에 끌어오지 않는다(FLS 우회 위험). 비용 롤업 요약 필드를 PMS_Project__c에 만들지 않는다.

**오픈 이슈**: HR이 주는 임율 단위(직급 평균 시간당·월 단가, 법인별 여부)와 갱신 주기, 직급 코드 체계(법인별 상이 여부), 시스템 관리자의 임율 열람 허용 여부(Shield 감사 필요 여부), 해외 법인 임율 제공 가능 여부.

### PMS-05-CST-004 비용 계획/실적 대시보드·Excel 가져오기/내보내기

추적 P-31, P-33, P-56 · 필수 · W2 · SF, SNOW · LWC, APEX, SQL, CFG · Customization · 선행 CST-001, CST-002, DSH-001, DWH-002, DWH-003, DWH-004, DOC-001 · 7 M/D

**목적**: PM은 자기 프로젝트의 계획·실적·차이를 실시간으로 보고(P-31), PMO·경영진은 전체 프로젝트 비용 상태를 같은 통화로 비교한다(P-56). 현업이 쓰던 Excel 표준 양식으로 예산·실적을 주고받는다(P-33).

**범위** In: 프로젝트 비용 요약 `pmsCostSummary`, 포트폴리오 위젯 `pmsCostPortfolioWidget`, Snowflake 뷰·Task·등록 쿼리 2개, CostRag 인바운드 핸들러, Excel 내보내기·가져오기 `pmsCostExcel`과 가져오기 서비스, 표준 양식 등록. Out: PMO 보드 배치(PMS-10-DSH-002), 일간/주간 보고의 비용 영역(PMS-10-DSH-003), AI 비용 초과 예측(PMS-11-AIP-003).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_Project__c.CostRagAsOf__c | Date | N | (제안, 이 WI가 PRJ-001 객체에 추가) CostRag 계산 기준일. P4 순서 보장(spec-snowflake-display 7절) |
| PMS_Project__c.CostRag__c | Picklist (GREEN, AMBER, RED) | — | 계약 필드(PRJ-001 생성). 이 WI의 핸들러만 쓴다. 금액이 아니므로 프로젝트 조회자 전원에게 보인다(DP3-6) |
| CMN_DwQuery__mdt `PMS_CST_PORTFOLIO` | Custom Metadata | — | Mode QUERY, PlantParam plantCodes, RequiredPermission `PMS_CST_Portfolio`, LatencyClass FAST, CacheSeconds 600, MaxRows 500, OwnerWi PMS-05-CST-004 |
| CMN_DwQuery__mdt `PMS_CST_PROJECT_FX` | Custom Metadata | — | Mode QUERY, 파라미터 projectId·reportingCurrency·asOfMonth, RequiredPermission `PMS_ViewCost`, FAST, CacheSeconds 600 |
| CMN_InboundRoute__mdt `PMS_CST_RAG_CHANGED` | Custom Metadata | — | HandlerClass `PMS_CostRagInboundHandler` |
| CMN_Widget__mdt `PMS_CostPortfolio` | Custom Metadata | — | ComponentName `pmsCostPortfolioWidget`, System PMS, Category COST, DefaultSize L, RequiredPermissionSet PMS_PS_Cost_Portfolio |
| CMN_DocTemplate__c (DocClass `PMS_COST_TEMPLATE`) | 데이터 | — | 비용 Excel 표준 양식(ko·en_US), 버전 1 |
| Snowflake MART.V_PMS_COST_LINE_MONTH / MART.V_PMS_COST_PROJECT / TASK_PMS_CST_RAG | SQL | — | BR-3·BR-4 |

**비즈니스 규칙**

- BR-1: 프로젝트 요약 `PMS_CostSummaryController.getProjectSummary(projectId, currency)`(cacheable, 첫 줄 `assertCanViewProject`). Salesforce 집계 SOQL(USER_MODE)로 만든다.
  - 통화별 카드: 기준선 총액, 현재 계획, 누계 실적(PeriodMonth ≤ 이번 달), 잔여(계획 − 실적), EAC, 차이율((EAC − 기준선) ÷ 기준선).
  - EAC = 범주별 max(계획, 실적)의 합(PIECE_PRICE 제외). 계획이 실적보다 작아진 범주는 실적을 예상 최종으로 본다.
  - 범주 표: 범주·세부 범주별 기준선·계획·실적·잔여·차이율, 투자 주체별 금형(SL_INVEST만 "SL 순투자"로 소계).
  - 단가 표: 품번별 목표 단가(PIECE_PRICE 예산)와 최신 실적 단가(가장 최근 PeriodMonth 실적), 차이율.
  - 월 차트: 월별 계획·실적 막대와 누계 선(S-curve). EDD 자동 행의 월 계획 = 그 행 금액 × (그 액티비티의 그 달 계획 시간 ÷ 액티비티 총 계획 시간). 투입 계획은 주 시작일 월에 귀속한다. EDD 외 행은 PeriodMonth, 비어 있으면 "월 미지정" 막대 하나로 보인다. 같은 분배 규칙을 Snowflake 뷰도 쓴다(BR-3).
  - 보고 통화 환산 합계는 `PMS_CST_PROJECT_FX` 등록 쿼리(P2)로 받아 카드 아래에 "보고 통화 환산 합계(기준 시각 asOf)"로 보인다. 실패·지연이면 이 줄만 오류·stale 배지(spec-snowflake-display 4절), 나머지는 정상 표시.
- BR-2: 포트폴리오 `pmsCostPortfolioWidget`(DSH-001 위젯 계약). 등록 쿼리 `PMS_CST_PORTFOLIO`(파라미터 plantCodes 강제, sopYearFrom·sopYearTo, customerCodes 선택, reportingCurrency, asOfMonth). 열: 프로젝트 번호·이름, 고객, 차종, 생산 공장, SOP, 기준선, EAC, 누계 실적, 차이율, 진행률(실적 ÷ EAC), CostRag(텍스트+아이콘). 차이율 내림차순, 행 클릭 → 프로젝트 레코드. Apex 래퍼는 `PMS_CST_Portfolio` 권한을 다시 확인한다.
- BR-3: Snowflake 뷰.
  - `MART.V_PMS_COST_LINE_MONTH`: CORE.SF_PMS_COSTBUDGET, SF_PMS_COSTACTUAL, SF_PMS_EFFORTPLAN(시간만), SF_PMS_PROJECT를 써서 프로젝트·범주·세부 범주·통화·월별 PLAN_AMOUNT(BR-1 분배 규칙)·ACTUAL_AMOUNT·BASELINE_AMOUNT. 임율은 쓰지 않는다.
  - `MART.V_PMS_COST_PROJECT`: 프로젝트별 원통화 합계와 보고 통화 환산. 환산은 CORE.SAP_FX_RATE(Vol.9)의 asOf 월 평균 환율 하나를 기준선·계획·실적·EAC에 똑같이 쓴다(환율 변동이 차이율을 만들지 않게). 환율이 없는 통화는 환산 NULL + FX_MISSING = TRUE.
  - 등록 쿼리 SqlTemplate은 이 두 뷰만 읽고, plantCodes 조건(PMS_Project ProdPlant)을 본문에 쓴다(spec-snowflake-display 2.2).
- BR-4: CostRag(P4 결과 반영).
  - TASK_PMS_CST_RAG(매일 04:00 KST): 기준선이 있는 진행 중 프로젝트마다 보고 통화로 EAC 차이율 = (EAC − 기준선) ÷ 기준선, 진행 속도 차이 = (누계 실적 − 누계 계획) ÷ 누계 계획(누계 계획 > 0일 때)을 계산한다.
  - 판정(MART.KPI_RAG_RULE 행 `PMS_CST_EAC_VAR`, `PMS_CST_PACE`): EAC 차이율 ≥ 10% → RED, ≥ 5% 또는 진행 속도 차이 ≥ 15% → AMBER, 그 외 GREEN. 기준선이 없거나 FX_MISSING이면 이벤트를 만들지 않는다.
  - 값이 전날과 다른 프로젝트만 SHARE.OUTBOUND_EVENT에 EVENT_TYPE `PMS_CST_RAG_CHANGED`, PAYLOAD `{projectId, rag, reasonCode(EAC_OVERRUN, PACE, OK), asOfDate, batchId, part, partCount}`(200건 단위)로 넣는다. 금액은 넣지 않는다. EVENT_ID = hash(projectId, asOfDate).
  - `PMS_CostRagInboundHandler`(CMN_InboundHandler): payload asOfDate가 CostRagAsOf보다 새로울 때만 CostRag·CostRagAsOf 갱신. RED로 바뀌면 PM과 PMO(프로젝트 PMO 역할, 없으면 PMS_PSG_PMO의 공장 담당)에게 알림 `PMS_CST_RAG_RED`(문구에 금액 없음).
- BR-5: Excel 내보내기(`pmsCostExcel`, 버튼 "Excel 내려받기").
  - Apex `PMS_CostExcelController.exportRows(projectId)`(assertCanViewProject)가 예산·실적 DTO를 주고, LWC가 정적 리소스 `cmnSheetJs`(Vol.0 변경 요청 V0-9 이름)로 xlsx를 만든다. 파일은 저장하지 않는다.
  - 시트 `Budget`, `Actual`, `Summary`. 1행 = 양식 키와 버전(`PMS_COST_TEMPLATE v1`), 2행 = 열 키, 3행부터 데이터. 열 순서는 BR-6 표.
  - 행마다 LineKey를 넣는다: 가져오기 행은 ExternalKey의 LineKey, 그 밖은 `ID:{Salesforce Id}`. 다시 가져오면 같은 행을 고친다(왕복 편집).
- BR-6: Excel 가져오기(버튼 "Excel 가져오기", `PMS_CST_Edit`).
  - LWC가 SheetJS로 파일을 읽어(5MB 이하, 시트당 500행 이하) 1행 양식 키·버전을 확인하고, 미리보기 표에 열 매핑·형식 오류를 셀 단위로 보인다.
  - 시트 열 키

    | 시트 | 필수 열 | 선택 열 | 읽기 전용(가져오기 때 무시) |
    | --- | --- | --- | --- |
    | Budget | LineKey, Category, Name, PlannedAmount, Currency | SubCategoryCode, ActivityWbsCode, PartNo, PeriodMonth(yyyy-mm), FundingType, ChangeReason, Note | Source, PlannedHours, BaselineAmount, Variance |
    | Actual | LineKey, Category, Name, PeriodMonth, Amount, Currency | SubCategoryCode, PartNo, TravelerEmployeeNo, Destination, TravelFrom, TravelTo, VendorName, Note | Source, IsLocked |

  - 제출하면 `PMS_CostImportService.importRows(projectId, sheet, rowsJson)`이 행을 SObject로 바꾸고 CST-001·002 Provider의 `validate`를 그대로 호출한다. 오류가 하나라도 있으면 아무 행도 저장하지 않고 행 번호별 오류를 돌려준다.
  - LineKey가 `ID:`로 시작하면 그 Id 행을 고치고(같은 프로젝트·수동 행인지 확인), 그 밖은 `IMP/{프로젝트 RecordNo}/B/{LineKey}`(Budget)·`IMP/{프로젝트 RecordNo}/A/{LineKey}`(Actual)로 upsert. Source는 IMPORT(예산)·MANUAL(실적).
  - 파일에 EDD 자동 행·시스템 원천 행·마감 월 행이 있으면 저장하지 않고 "건너뜀 n행(자동·연계·마감)"으로 알린다.
- BR-7: 성능. 프로젝트 요약은 SOQL 10회 이하, 3초 이내(행 1,000개 기준). 포트폴리오는 p95 3초(FAST, 캐시).

**화면/UX**: 화면 유형 T5(분석) · 공통 부품 DSH-001 위젯 계약, DWH-004 등록 쿼리, `cmnDwDataState` 상태 표시, 정적 리소스 cmnChartJs·cmnSheetJs.
- 프로젝트 "비용" 탭 맨 위에 `pmsCostSummary`(통화 선택, 카드·범주 표·단가 표·월 차트), 오른쪽 위 버튼 "Excel 내려받기"·"Excel 가져오기".
- PMO 보드·경영진 홈에 `pmsCostPortfolioWidget`(L 크기). 차트·표 상태는 LOADING·EMPTY·ERROR·READY와 STALE·TRUNCATED·SCOPE 배지(spec-snowflake-display 4절).
- 색만으로 RAG를 구분하지 않는다(텍스트 + 아이콘). 휴대폰은 카드와 범주 표만(차트 숨김).

**권한**: 프로젝트 요약·Excel 내보내기 PMS_PS_Cost_Read, 가져오기 PMS_PS_Cost_Edit, 포트폴리오 PMS_PS_Cost_Portfolio. CostRag 필드는 프로젝트 조회 권한이면 보인다.

**수용 기준**

- AC-1: Given 기준선 1,000,000 KRW, EAC 1,120,000, When Task 실행, Then 이벤트 1건(rag RED, reasonCode EAC_OVERRUN, 금액 필드 없음), 핸들러가 CostRag RED·CostRagAsOf를 넣고 PM·PMO 알림 1건씩.
- AC-2: Given CostRagAsOf 2027-05-10인 프로젝트, When asOfDate 2027-05-09 이벤트 수신, Then 값이 바뀌지 않는다.
- AC-3: Given `PMS_CST_Portfolio`가 없는 PM, When 위젯 갤러리·Apex 래퍼 호출, Then 위젯이 보이지 않고 래퍼는 FORBIDDEN_SCOPE.
- AC-4: Given KR01 공장 권한만 있는 PMO, When 포트폴리오 조회(plantCodes [KR01, CN01]), Then KR01 프로젝트만, scopeNote 표시.
- AC-5: Given 액티비티 EDD 행 1,200(KRW)과 투입 계획 3월 40h·4월 80h, When 월 차트, Then 3월 계획 400, 4월 800. 같은 프로젝트의 Snowflake 뷰 값도 같다(계약 테스트).
- AC-6: Given 내보낸 파일에서 수동 예산 2행 금액 변경, When 다시 가져오기, Then 같은 2행이 고쳐지고 새 행은 생기지 않는다.
- AC-7: Given 가져오기 30행 중 2행 통화 오류, When 제출, Then 아무 행도 저장되지 않고 2개 행 번호와 사유가 보인다.
- AC-8: Given 파일에 EDD 자동 행 5개, When 가져오기, Then 그 5행은 바뀌지 않고 "건너뜀 5행" 안내.
- AC-9: Given 비용 KPI 처리 전체, When CMN_KpiValue__c 확인, Then KpiKey가 `PMS_CST_`로 시작하는 행이 없다.

**에이전트 주의**: 위젯·LWC에서 Snowflake를 직접 부르지 않는다(DWH-004 래퍼만). 환율을 Apex에서 곱하지 않는다. CostRag를 Apex 배치로 다시 계산하지 않는다(단일 원천 = Snowflake Task). 엑셀 파싱을 서버(Apex)에서 하지 않는다(브라우저 SheetJS, 서버는 검증·저장만). 차트 라이브러리는 cmnChartJs만 쓴다.

**오픈 이슈**: 보고 통화(KRW 고정 vs 사용자 선택), CostRag 임계값(5%·10%·15%)과 경영 보고 기준, SL 현행 비용 Excel 양식 열 구성(이 양식에 맞춰 v1 확정), 환율 기준(월 평균 vs 예산 환율).

## 5. PMS-06 산출물(DLV)

### PMS-06-DLV-001 액티비티 산출물(유형 5종·일괄 등록)

추적 P-34, P-37, P-44, P-45 · 필수 · W1 · SF · DM, APEX, LWC, CFG · Customization · 선행 DOC-001, ARC-003, SEC-003, UX-003, UX-004, UX-005, PMS-04-WBS-002, PMS-04-WBS-003, PMS-07-ACT-001 · 6 M/D

**목적**: 액티비티마다 무엇을 내야 하는지(표준 산출물)를 실행 산출물로 만들고, 담당자가 5가지 형태로 등록하면 상태가 자동으로 바뀌어 액티비티 완료·Gate 점검의 근거가 된다. 파일·리비전·링크·중복 탐지는 DOC-001을 그대로 쓰고 다시 만들지 않는다.

**범위** In: `PMS_Deliverable__c`, 표준 산출물 → 실행 산출물 생성(syncFromTemplate), 임의 산출물 추가·삭제, 해당 없음(N/A), 문서 리스너(DOC-001 V0-1)로 상태 계산, 시스템 링크 리졸버 구조와 기본 리졸버, 일괄 등록, 액티비티 롤업 필드, 기한 알림, 산출물 레코드 페이지, 액티비티 산출물 패널, 조회 서비스·완료 조건 검사기, 이벤트 `PMS_DeliverableEvent__e` 정의. Out: 결재(DLV-002), 연결·영향(DLV-003·004), 검색·양식 내려받기(DLV-005), QMS·PDM 리졸버 구현(PMS-12-INT-004·005), 이상 징후 판정(PMS-09-GAT-005).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_Deliverable__c.Activity__c | Master-Detail(PMS_Activity__c) | Y | 계약 MD Activity |
| PMS_Deliverable__c.RecordNo__c | Text(40), Unique, External ID | Y | (제안) `DLV-{YYYY}-{SEQ:6}`(ARC-003) |
| PMS_Deliverable__c.Name | Text(80) | Y | 산출물명(표준 산출물명 사본, 예: "DFMEA") |
| PMS_Deliverable__c.TemplateDeliverable__c | Lookup(PMS_WbsTemplateDeliverable__c) | 표준이면 Y | 계약 |
| PMS_Deliverable__c.DeliverableCode__c | Text(40) | Y | 표준 산출물 코드 사본. 임의 산출물은 DocClass 코드 |
| PMS_Deliverable__c.DeliverableType__c | Picklist (ATTACHMENT, STANDARD_FORM, LINK, APPROVAL, SYSTEM_LINK) | Y | 계약 값(STD_FORM 통일은 DP3-14) |
| PMS_Deliverable__c.DocClass__c | Lookup(CMN_Code__c, Group `DOC_CLASS`) | SYSTEM_LINK 외 Y | 문서 분류. SYSTEM_LINK도 링크 리비전 분류로 쓴다(기본 `PMS_DLV > SYSTEM_RECORD`) |
| PMS_Deliverable__c.IsMandatory__c | Checkbox | Y | 계약. 표준 사본. 표준 필수는 PM도 해제 불가 |
| PMS_Deliverable__c.ApprovalRequired__c | Checkbox | Y | 계약. APPROVAL이면 항상 true, LINK·SYSTEM_LINK면 항상 false(BR-2) |
| PMS_Deliverable__c.Status__c | Picklist (NOT_SUBMITTED, SUBMITTED, IN_APPROVAL, APPROVED, REJECTED, NOT_APPLICABLE) | Y | 계약. FLS 읽기. 서비스만 바꾼다(BR-4) |
| PMS_Deliverable__c.IsSatisfied__c | Checkbox | — | (제안) 완료 조건 충족(BR-4). 롤업 필터용이라 Formula가 아닌 일반 필드 |
| PMS_Deliverable__c.IsAdHoc__c | Checkbox | — | PM 임의 추가 |
| PMS_Deliverable__c.Document__c | Lookup(CMN_Document__c) | N | 계약. 대표 문서(첫 문서). MULTI_FILE 분류는 같은 부모의 문서가 여럿 |
| PMS_Deliverable__c.CurrentRevisionNo__c | Number(4,0) | N | 최신 RELEASED 리비전 번호(리스너) |
| PMS_Deliverable__c.LatestFileName__c | Text(255) | N | 최신 리비전 파일명·링크 제목(검색용, 리스너) |
| PMS_Deliverable__c.LatestContentDocumentId__c | Text(18) | N | 미리보기용(리스너) |
| PMS_Deliverable__c.LatestRevisionDuplicate__c | Checkbox | — | 최신 리비전의 IsDuplicateFile(DOC-001 BR-5) 사본. Gate 이상 징후 입력 |
| PMS_Deliverable__c.LastSubmittedBy__c / LastSubmittedAt__c | Lookup(User) / DateTime | N | 최신 리비전 등록자·일시(검색 "등록자") |
| PMS_Deliverable__c.ExternalUrl__c | URL | LINK면 Y | 계약. 최신 링크(리스너) |
| PMS_Deliverable__c.SystemLinkType__c | Text(40) | SYSTEM_LINK면 Y | 계약. PMS_SystemLinkType__mdt DeveloperName |
| PMS_Deliverable__c.SystemRecordId__c | Text(80) | SYSTEM_LINK 등록 후 Y | 계약. Salesforce Id(18) 또는 외부 키(도면 번호 + 리비전 등) |
| PMS_Deliverable__c.SystemRecordNo__c / SystemRecordLabel__c | Text(80) / Text(255) | N | 표시 사본 |
| PMS_Deliverable__c.SystemStatusLabel__c / SystemStatusSatisfied__c / SystemStatusCheckedAt__c | Text(80) / Checkbox / DateTime | N | 리졸버 결과 |
| PMS_Deliverable__c.NotApplicableReason__c | Text(500) | NOT_APPLICABLE이면 Y | |
| PMS_Deliverable__c.NotApplicableBy__c / NotApplicableAt__c | Lookup(User) / DateTime | N | |
| PMS_Deliverable__c.AnomalyStatus__c | Picklist (NONE, SUSPECTED, CONFIRMED, CLEARED) | Y | 계약(GAT-005). 이 WI가 필드를 만들고 기본 NONE, 값 쓰기는 GAT-005만(FLS 읽기) |
| PMS_Deliverable__c.DueDate__c | Formula(Date) | — | BLANKVALUE(Activity__r.ForecastEnd__c, Activity__r.PlannedEnd__c) |
| PMS_Deliverable__c.DaysToDue__c | Formula(Number, 0) | — | DueDate__c − TODAY()(UX-004 D-day) |
| PMS_Deliverable__c.ProjectNo__c / CustomerName__c / ProdPlantCode__c / ActivityLabel__c | Formula(Text) | — | 헤더·목록 표시(Activity__r.Project__r …) |
| PMS_Activity__c.DlvTotal__c | Roll-up COUNT(Status ≠ NOT_APPLICABLE) | — | (제안, 이 WI가 ACT-001 객체에 추가) |
| PMS_Activity__c.DlvDone__c | Roll-up COUNT(IsSatisfied = true, Status ≠ NOT_APPLICABLE) | — | (제안) |
| PMS_Activity__c.DlvMandatory__c / DlvMandatoryDone__c | Roll-up COUNT(IsMandatory = true, Status ≠ NOT_APPLICABLE / + IsSatisfied = true) | — | (제안) ACT-004 완료 조건 |
| PMS_Activity__c.DlvInApproval__c | Roll-up COUNT(Status = IN_APPROVAL) | — | (제안) |
| PMS_Activity__c.DlvCompletionPct__c | Formula(Percent) | — | IF(DlvTotal = 0, 1, DlvDone ÷ DlvTotal). P-44 산출물 완료율(WBS-007이 사용) |
| PMS_SystemLinkType__mdt | Custom Metadata | — | (제안) DeveloperName = 유형 키, TargetSystem__c(QMS, CMN, PDM, ALM, DMS, RELIABILITY, IMDS, OTHER), StorageType__c(SF_RECORD, PDM, DMS, URL), TargetObject__c(SF_RECORD 대상 객체 API명), NumberField__c, LabelField__c, UrlTemplate__c(`{key}` 자리, 외부만), ResolverClass__c, SatisfiedRule__c, ManualStatusAllowed__c, LabelKey__c, IsActive__c |
| PMS_DeliverableEvent__e | Platform Event(Publish After Commit) | — | (제안) DeliverableId__c, ActivityId__c, ProjectId__c, DeliverableCode__c, DocClassCode__c, EventType__c(SUBMITTED, NOT_APPLICABLE, SYSTEM_STATUS_CHANGED, APPROVAL_SUBMITTED, APPROVED, REJECTED, REVISION_STARTED, REVISED), RevisionNo__c, DocumentRevisionId__c, SystemLinkType__c, SystemRecordId__c, ImpactAssessmentId__c, ActorId__c |

**서비스 API**

    public with sharing class PMS_DeliverableService {
        public static Integer syncFromTemplate(Set<Id> activityIds);                 // 멱등(Activity + TemplateDeliverable)
        public static Id addAdHoc(Id activityId, PMS_DeliverableSpec spec);          // PM: 이름, DocClass, 유형, 필수, 결재 필요
        public static void removeAdHoc(Id deliverableId);                            // PM: 임의 + NOT_SUBMITTED만
        public static void setNotApplicable(Set<Id> deliverableIds, String reason);  // PM
        public static void clearNotApplicable(Set<Id> deliverableIds);               // PM → 상태 다시 계산
        public static void linkSystemRecord(Id deliverableId, String key);           // 리졸버 확인 후 DOC-001 링크 리비전 등록
        public static void setManualSystemStatus(Id deliverableId, Boolean satisfied, String statusLabel); // ManualStatusAllowed 유형만
        public static void applySystemStatus(String systemLinkType, Set<String> keys); // INT 구독 측이 호출
        public static List<Id> registerBulk(List<Id> deliverableIds, List<Id> contentDocumentIds, String changeNote); // DOC-001 V0-2
        public static void recalculate(Set<Id> deliverableIds);                      // 상태·사본 필드 다시 계산(리스너가 호출)
    }
    public interface PMS_SystemLinkResolver {
        Map<String, PMS_SystemLinkInfo> resolve(PMS_SystemLinkType__mdt typeDef, Set<String> keys);
        List<PMS_SystemLinkInfo> search(PMS_SystemLinkType__mdt typeDef, Id projectId, String term, Integer maxRows);
    }
    // PMS_SystemLinkInfo: key, recordNo, label, statusLabel, isSatisfied(Boolean, null = 판단 불가), url, accessible, message
    public with sharing class PMS_DeliverableQueryService {
        public static Map<Id, List<PMS_DeliverableStatusDTO>> byActivities(Set<Id> activityIds);
        public static List<PMS_DeliverableStatusDTO> byCodes(Id projectId, Set<String> deliverableCodes);
        public static PMS_DeliverableStatusDTO byId(Id deliverableId);
    }
    // PMS_DeliverableStatusDTO: deliverableId, recordNo, name, activityId, wbsCode, deliverableCode, docClassCode, deliverableType,
    //   status, isMandatory, approvalRequired, isSatisfied, isUnderRevision, reviewRequired, currentRevisionNo, lastSubmittedAt,
    //   dueDate, isOverdue, systemLinkType, systemRecordId, systemStatusSatisfied, latestRevisionDuplicate, anomalyStatus

**비즈니스 규칙**

- BR-1: 생성 `syncFromTemplate(activityIds)`.
  - 액티비티의 표준 액티비티(WBS-003이 남긴 원본 키)에 달린 `PMS_WbsTemplateDeliverable__c`마다 실행 산출물 1건을 만든다. 키 = Activity + TemplateDeliverable(이미 있으면 건너뜀).
  - 복사 필드: Name, DeliverableCode, DeliverableType, DocClass, IsMandatory, ApprovalRequired, SystemLinkType. Status NOT_SUBMITTED, AnomalyStatus NONE.
  - 호출 지점: WBS-003 실행 WBS 생성, ACT-002 액티비티 추가, ACT-003 프로젝트 복사의 마지막 단계(Vol.P2 요청). 그 WI가 먼저 구현돼 있으면 이 WI 구현 때 호출 한 줄을 더하고 완료 보고서 "명세 차이"에 남긴다.
  - 안전망: 일 배치 `PMS_DeliverableSyncBatch`(04:30 KST)가 진행 중 프로젝트에서 산출물이 빠진 액티비티를 찾아 만든다.
  - 프로젝트 복사(ACT-003)는 산출물 정의만 복사하고 파일·상태·연결은 복사하지 않는다.
- BR-2: 유형 규칙(저장 검증).
  - APPROVAL → ApprovalRequired = true(강제). LINK·SYSTEM_LINK → ApprovalRequired = false(원본 시스템에서 승인 관리).
  - ApprovalRequired = true인 산출물은 MULTI_FILE 분류(DocClass Attribute2 = MULTI_FILE)를 쓸 수 없다(결재 대상 리비전이 하나여야 한다).
  - STANDARD_FORM은 양식이 있어야 한다(DLV-005 BR-4 확인). 없으면 저장은 되고 패널에 "양식 미등록" 경고.
  - DocClass Attribute1 = LINK_ONLY(도면 등)면 파일 업로드 대신 링크·시스템 링크만(DOC-001 BR-4).
- BR-3: 등록 경로. 파일·링크는 DOC-001 `cmnDocumentPanel`(부모 = 산출물)로 올린다. 시스템 링크는 `linkSystemRecord`로 올린다. 이 WI는 업로드 화면을 새로 만들지 않는다.
  - 문서 리스너 `PMS_DeliverableDocumentListener`(DOC-001 V0-1의 `CMN_DocumentListener` 구현, `CMN_DocumentListener__mdt` 행 ParentObject `PMS_Deliverable__c`, ApprovalHandledByParent = true, LinkFilesToParent = true)를 등록한다.
  - `deliverableTypeFor(parentId, docClassId)`: 산출물이 ApprovalRequired면 `APPROVAL`, 아니면 ATTACHMENT→`ATTACHMENT`, STANDARD_FORM→`STD_FORM`, LINK→`LINK`, SYSTEM_LINK→`SYSTEM_LINK`(CMN 값).
  - `afterRevisionChange(revisions)`: 부모 산출물 Id를 모아 `recalculate`를 한 번 호출한다.
  - 등록 차단(리스너가 `CMN_ValidationException`): 산출물 NOT_APPLICABLE, 액티비티 CANCELLED·COMPLETION_REQUESTED, 액티비티 COMPLETED·FORCE_COMPLETED(DLV-004 배포 후에는 IsUnderRevision = true면 허용), 사용자가 액티비티 주·보조 담당·PM이 아님.
  - 산출물 DocClass가 아닌 분류로 올리는 것은 패널 allowedDocClasses로 막고, 리스너가 서버에서 다시 막는다.
- BR-4: 상태 계산 `recalculate`(한 함수가 유일한 상태 원천).
  - NOT_APPLICABLE은 그대로 둔다(수동 상태).
  - ApprovalRequired: IN_APPROVAL 리비전이 있으면 IN_APPROVAL. 아니면 최신 리비전 DRAFT → SUBMITTED. 최신 REJECTED → RELEASED 리비전이 있으면 APPROVED, 없으면 REJECTED. 최신 RELEASED → APPROVED. 리비전 없음 → NOT_SUBMITTED. IsSatisfied = RELEASED 리비전이 있음.
  - 결재 불필요(ATTACHMENT·STANDARD_FORM·LINK): RELEASED 리비전이 있으면 SUBMITTED·IsSatisfied true, 없으면 NOT_SUBMITTED·false.
  - SYSTEM_LINK: 링크 리비전이 있으면 SUBMITTED. IsSatisfied = SystemStatusSatisfied(리졸버 또는 수동 확인).
  - 사본 필드(Document, CurrentRevisionNo, LatestFileName, LatestContentDocumentId, LatestRevisionDuplicate, LastSubmittedBy·At, ExternalUrl)를 같이 채운다.
  - 상태·IsSatisfied가 바뀐 산출물만 갱신하고(`CMN_UiRuleService.runAsService`), 바뀐 상태에 맞는 이벤트(SUBMITTED 등)를 발행한다. 결재 상태(IN_APPROVAL·APPROVED·REJECTED) 이벤트는 DLV-002 콜백이 발행하므로 여기서 중복 발행하지 않는다.
  - 문서 조회는 DOC-001 서비스가 제공하는 리비전 조회(부모 Id 집합)로 SOQL 1회.
- BR-5: 시스템 링크.
  - `linkSystemRecord(deliverableId, key)`: 유형 정의 → 리졸버 `resolve`로 존재·접근 확인(accessible false면 차단) → DOC-001 `registerLink(parent = 산출물, DocClass, StorageType = 유형의 StorageType, url = 리졸버 url, externalRef = key, title = 번호 + 이름)` → SystemRecordId·No·Label·상태 사본 저장.
  - 기본 리졸버 2개를 이 WI가 만든다. `PMS_SfRecordLinkResolver`: TargetObject를 동적 SOQL(`Database.queryWithBinds`, USER_MODE, 필드는 유형 정의의 NumberField·LabelField·SatisfiedRule 필드만 허용 목록)로 읽는다. 대상 객체가 Org에 없으면 accessible = false, message "대상 시스템 미배포". `PMS_ExternalLinkResolver`: UrlTemplate로 url만 만들고 isSatisfied = null(수동 확인).
  - SatisfiedRule 형식: `필드=값1,값2;필드=값`(모두 만족). 예: `Status__c=CLOSED;FinalResult__c=PASS`.
  - 이 WI가 등록하는 유형: `CMN_MEETING`(CMN_Meeting__c, 충족 = Status__c=MINUTES_CONFIRMED, DR 회의록), `IMDS_MDS`(외부, ManualStatusAllowed, IMDS MDS ID, 고객 승인 시 수동 확인), `PDM_DRAWING`(외부 URL 템플릿, 수동 확인. INT-004가 리졸버로 교체), `EXTERNAL_URL`(일반). QMS 유형(`QMS_QUAL_PLAN`, `QMS_PPAP` 등)은 PMS-12-INT-005가 등록한다.
  - `applySystemStatus(type, keys)`: 그 유형·키를 가진 산출물들을 다시 resolve해 사본을 갱신하고 `recalculate`. 바뀐 건만 SYSTEM_STATUS_CHANGED 발행. 안전망 배치 `PMS_SystemLinkRefreshBatch`(일 05:00 KST)가 충족되지 않은 SYSTEM_LINK 산출물을 다시 확인한다.
- BR-6: 임의 산출물·N/A(P-45).
  - PM(Custom Permission `PMS_DLV_Manage`)만 `addAdHoc`. DocClass는 `PMS_DLV` 하위 또는 PPAP 하위 코드만. IsAdHoc = true.
  - 삭제는 IsAdHoc이고 NOT_SUBMITTED인 산출물만(CMN_DeleteGuard Status NOT_SUBMITTED + 트리거의 IsAdHoc 확인). 표준 산출물은 삭제 대신 N/A.
  - `setNotApplicable`: 사유 필수, IN_APPROVAL이면 차단. 필수 산출물도 N/A할 수 있다(DP3-8). NotApplicableBy·At 기록, 이벤트 NOT_APPLICABLE, 프로젝트 PM·액티비티 담당에게 알림 `PMS_DLV_NA`. Gate 점검(GAT-003)은 N/A 건수를 따로 보여준다.
- BR-7: 일괄 등록(P-34 "동일 산출물 일괄 업로드").
  - `pmsDeliverableBulkUpload` 모달: 1단계 파일 선택(한 번 업로드), 2단계 대상 선택(같은 DeliverableCode 또는 같은 DocClass, 사용자가 편집할 수 있는 프로젝트, 상태 NOT_SUBMITTED·SUBMITTED·REJECTED, 액티비티 진행 중), 3단계 확인.
  - 대상은 CMN 설정 `PMS_DLV_BULK_MAX`(기본 20)개 이하. `registerBulk`는 DOC-001 V0-2 `registerFilesToParents`를 1회 호출한다(같은 호출 안의 부모끼리는 중복 경고 없이 PublishedFromRevision으로 묶임). 결재 필요 산출물은 각각 SUBMITTED가 되고 결재는 건별로 상신한다.
- BR-8: 기한 알림. 시간별 잡 `PMS_DeliverableDueJob`이 프로젝트 생산 공장 현지 08:00에 해당하는 프로젝트만 처리한다(APV-005 BR-1과 같은 방식).
  - 필수·미충족(NOT_SUBMITTED, SUBMITTED-결재 필요, REJECTED) 산출물 중 DaysToDue가 CMN 설정 `PMS_DLV_DUE_SOON_DAYS`(기본 3) → 액티비티 주·보조 담당에게 `PMS_DLV_DUE_SOON` 1회.
  - DaysToDue < 0 → 매일 `PMS_DLV_OVERDUE`(담당), 7일 경과부터 PM 참조.
  - 산출물 등록을 위한 별도 To-Do는 만들지 않는다(액티비티 To-Do가 이미 있다, WBS-005).
- BR-9: 완료 조건 검사기 `PMS_DeliverableCompletionChecker`(WBS-002 `PMS_CompletionChecker` 구현, `PMS_CompletionRule__mdt` RuleKey `PMS_DLV_MANDATORY_DONE`): DlvMandatory = DlvMandatoryDone이면 통과, 아니면 미충족 산출물 이름 목록을 메시지로 돌려준다. 시그니처는 WBS-002 본문을 따른다.
- BR-10: 공통 기반 등록 — 채번 규칙, CMN_StatusFlow(Status), CMN_DeleteGuard(NOT_SUBMITTED), 필드 이력(Status, IsMandatory, ApprovalRequired, NotApplicableReason, DocClass), DWH-002 복제(15분), 번역, UX-005 규칙 파일 `meta-src/ui-rules/PMS_Deliverable__c.json`(액션: 시스템 링크 선택 = NOT_SUBMITTED·SUBMITTED·REJECTED + `PMS_DLV_Submit`, N/A 지정 = NOT_APPLICABLE·IN_APPROVAL 외 + `PMS_DLV_Manage`, N/A 해제 = NOT_APPLICABLE + `PMS_DLV_Manage`, 임의 삭제 = NOT_SUBMITTED + `PMS_DLV_Manage` + ExtraCondition `IsAdHoc__c=true`).

**화면/UX**: 화면 유형 T1(산출물 레코드) + 액티비티 T1의 단계 전용 패널 · 공통 부품 UX-004 레코드 표준·레일, UX-005 규칙, UX-003 진행 단계, DOC-001 `cmnDocumentPanel`, APV-003 `cmnApprovalLine`.
- 산출물 레코드 페이지(UX-004 생성기 `meta-src/record-pages/PMS_Deliverable__c.json`).
  - 헤더 7개: RecordNo, Name, Status, CustomerName(고객), ActivityLabel(품번 자리 대체: 산출물은 품번이 아니라 액티비티에 속한다), ProdPlantCode, DaysToDue.
  - 현재 단계 탭: `pmsDeliverableContent`(제안) — 유형에 따라 `cmnDocumentPanel`(allowedDocClasses·requiredDocClasses = 이 산출물 DocClass 코드)을 감싸 보여주고, STANDARD_FORM이면 "양식 받기"(DLV-005), SYSTEM_LINK면 `pmsSystemLinkPicker`(제안, 유형별 리졸버 search·선택, 수동 확인 버튼)를 보인다. 결재 상신 버튼은 두지 않는다(레일 APPROVAL 패널).
  - 레일: APPROVAL(`cmnApprovalLine`, Config `{"typeCode":"PMS_DELIVERABLE"}`, DLV-002), COMMENT, TODO 기본 패널. DOCUMENT 패널은 이 객체에서 IsActive = false(현재 단계 탭과 중복). AI 패널은 PMS-11-AIP-002 배포 전 비활성.
- 액티비티 레코드 페이지(ACT-001)의 현재 단계 탭에 `pmsDeliverablePanel`(제안).
  - 목록: 산출물명, 유형 아이콘·텍스트, 필수 표시, 상태(텍스트 + 아이콘), Rev, 파일명, 결재 상태(결재 중이면 현재 결재자·체류일, DOC-001 V0-4 일괄 조회), 기한 D-day.
  - 행 동작: 열기(레코드), 올리기(모달로 `pmsDeliverableContent`), 양식 받기, N/A(PM), 위쪽 "산출물 추가"(PM)·"일괄 등록".
  - 이 패널은 파일 업로드·링크·양식 같은 행 동작이 있어 셀 편집 그리드(UX-006) 범위 밖이다. 행 편집 그리드를 흉내 내지 않는다.
- 휴대폰: 패널은 카드 목록(산출물명·상태·기한), 올리기는 레코드 페이지에서. 현장 사진 업로드는 cmnDocumentPanel 기본 기능.

**권한**: 조회 PMS_PS_Deliverable_Read(모든 PMS PSG), 등록·시스템 링크 PMS_PS_Deliverable_Edit(CFT·PM), 임의 추가·삭제·N/A PMS_PS_Deliverable_Manage(PM·PMO). 실제 등록 가능 여부는 BR-3의 담당 확인까지 통과해야 한다.

**수용 기준**

- AC-1: Given 표준 액티비티에 표준 산출물 3개, When 실행 WBS 생성 후 syncFromTemplate 2회, Then 산출물 3건(멱등), Status NOT_SUBMITTED, RecordNo 부여.
- AC-2: Given 결재 불필요 STANDARD_FORM 산출물, When cmnDocumentPanel로 파일 업로드, Then 리비전 RELEASED, 산출물 SUBMITTED·IsSatisfied true, 액티비티 DlvDone 1 증가, SUBMITTED 이벤트 1건.
- AC-3: Given 결재 필요 산출물, When 업로드, Then 리비전 DRAFT, 산출물 SUBMITTED·IsSatisfied false, cmnDocumentPanel에 문서 단위 상신 버튼이 없다(ApprovalHandledByParent).
- AC-4: Given 액티비티 COMPLETED, When 산출물 업로드, Then 리스너가 차단하고 "개정 시작 후 올리세요" 라벨 메시지.
- AC-5: Given CFT 구성원이지만 그 액티비티의 주·보조 담당이 아님, When 업로드, Then 차단.
- AC-6: Given SYSTEM_LINK 유형 CMN_MEETING, When 회의록 MINUTES_DRAFT 회의 연결, Then SUBMITTED·IsSatisfied false. 회의록 확정 후 applySystemStatus 호출, Then IsSatisfied true, SYSTEM_STATUS_CHANGED 1건.
- AC-7: Given 유형 정의의 TargetObject가 Org에 없음(QMS 미배포), When 연결 시도, Then "대상 시스템 미배포" 메시지로 차단, 예외 없음.
- AC-8: Given 필수 표준 산출물, When PM이 삭제, Then 차단. N/A(사유 입력)는 성공하고 DlvMandatory에서 빠진다.
- AC-9: Given 같은 파일을 산출물 5건에 일괄 등록, When 완료, Then 리비전 5건, 서로 중복 경고 없음(PublishedFromRevision 연결), SOQL은 대상 수와 무관하게 15회 이하.
- AC-10: Given 필수 산출물 2개 중 1개만 충족, When ACT-004가 검사기 호출, Then 실패와 미충족 산출물명.
- AC-11: Given 다른 CFT 구성원(조회만), When 산출물 파일 미리보기, Then 열린다(파일이 산출물 레코드에도 연결됨, V0-1 LinkFilesToParent).

**에이전트 주의**: 업로드·리비전·해시를 이 WI에서 다시 만들지 않는다(DOC-001만). 상태를 화면·Flow에서 직접 바꾸지 않는다(`recalculate` 한 곳). QMS 객체를 정적 SOQL·Lookup으로 참조하지 않는다(리졸버의 동적 조회 + 유형 메타데이터). AnomalyStatus 값을 이 WI 코드가 쓰지 않는다. 롤업 필터에 Formula 필드를 쓰지 않는다(IsSatisfied는 일반 Checkbox).

**오픈 이슈**: 현행 신제품개발 표준 산출물 목록·양식(회사표준 개정 26.11~27.04 결과), 보조 담당도 결재 상신자가 될 수 있는지, IMDS 등록 확인 방식(고객 승인 화면 캡처 첨부 여부), 대용량 파일 저장소(SharePoint, D-7).

### PMS-06-DLV-002 산출물 결재(팀장 필수)·연계 데이터 동기화

추적 P-38, P-44, P-65, P-66, P-68 · 필수 · W1 · SF · APEX, CFG, DM · Customization · 선행 DLV-001, APV-001, APV-002, APV-003, TDO-001, NTF-001, PMS-02-PRJ-002, PMS-12-APV-001 · 5 M/D

**목적**: 결재가 필요한 산출물은 작성자의 팀장이 반드시 승인하고, 산출물 종류에 따라 품질·생산기술 같은 프로젝트 역할의 합의를 거친다(P-38, P-65). 승인 즉시 산출물이 공식 등록되고 액티비티·Gate·QMS·DMS 쪽 데이터가 따라 움직인다.

**범위** In: 결재 유형 `PMS_DELIVERABLE` 설정, 콜백, 결재선 기여자(팀장 보정·산출물별 역할 단계), 산출물별 결재 규칙 메타데이터, 승인본 품번 문서 게시, 결재 이벤트·알림·보완 To-Do. Out: 결재 엔진·UI(APV-001~003), PROJECT_ROLE 해석(PMS-12-APV-001), 이벤트 구독(PMS-12-INT-003~005), 액티비티 자동 종료(ACT-004), 개정 분기(DLV-004).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_Deliverable__c.ApprovalRequest__c | Lookup(CMN_ApprovalRequest__c) | N | 최신 결재 요청 |
| PMS_Deliverable__c.ApprovalVersion__c | Number(3,0) | N | 재상신 차수 |
| PMS_Deliverable__c.ApprovalSubmittedAt__c / ApprovedAt__c | DateTime | N | |
| PMS_Deliverable__c.LastRejectComment__c | Text(1000) | N | 마지막 반려 의견 사본(패널 표시) |
| CMN_ApprovalType__mdt `PMS_DELIVERABLE` | Custom Metadata | — | TargetObject PMS_Deliverable__c, CallbackClass `PMS_DeliverableApprovalCallback`, LineContributorClass `PMS_DeliverableLineContributor`, LockOnSubmit true, KeepLockedAfterApproval false, RequireDrafterManager **false**(BR-2), ReminderDays 2, EscalationDays 5, ShareTargetPath `Activity__r.Project__c`(Vol.0 V0-5) |
| CMN_ApprovalTemplate__c(TypeCode PMS_DELIVERABLE, Plant 공란, SYSTEM, IsDefault, AllowUserEdit true) + 단계 | 데이터(설치 스크립트 `scripts/apex/pms-dlv-approval-setup.apex`) | — | StepNo 90, APPROVE, ResolverType DRAFTER_MANAGER, IsMandatory true |
| PMS_DeliverableApprovalRule__mdt | Custom Metadata | — | (제안) DeliverableCode__c 또는 DocClassCode__c(둘 중 하나), CustomerGroup__c(선택), StepNo__c(10~89 또는 91~99), StepType__c(REVIEW, AGREE, APPROVE, CC), ResolverType__c(PROJECT_ROLE, ROLE), RoleCode__c, IsMandatory__c, IsActive__c |
| PMS_DeliverablePublishRule__mdt | Custom Metadata | — | (제안) DocClassCode__c, PublishTo__c(ITEM), PartScope__c(LEAD_PART, ALL_PARTS), IsActive__c |
| NTF EventCode | `PMS_DLV_APPROVED`, `PMS_DLV_REJECTED`, `PMS_DLV_PUBLISH_FAILED` | — | 문구는 Custom Label |
| To-Do SourceType | `PMS_DLV_REWORK`(반려 보완), `PMS_DLV_PUBLISH_FAILED` | — | |

**비즈니스 규칙**

- BR-1: 상신 조건(콜백 `canSubmit`, APV-003 BR-2): ApprovalRequired, Status SUBMITTED이고 DRAFT 리비전이 있음, 현재 사용자가 액티비티 주·보조 담당, 액티비티가 CANCELLED·COMPLETION_REQUESTED가 아님. 거절 사유는 라벨 문구로 돌려준다.
- BR-2: 팀장 필수(P-38·P-44).
  - 템플릿 단계 StepNo 90 DRAFTER_MANAGER(기안자 부서장) APPROVE, IsMandatory.
  - 기여자 보정: 해석된 팀장이 기안자 본인이면(기안자가 팀장) 부서 Parent__c를 따라 올라가 기안자가 아닌 첫 Manager__c(최대 3단계)로 바꾼다. 없으면 상신 차단("팀장 결재자 없음: {부서}").
  - RequireDrafterManager는 false로 둔다. APV-001 BR-1 검사는 기안자 = 부서장일 때 자기 결재 오류가 나기 때문이다(Vol.0 V0-6 반영 후 true로 바꿀 수 있다). 대신 기여자가 낸 팀장 단계는 IsMandatory라 APV-002 `enforceTemplate`이 상신 때 삭제를 막는다.
  - 방어선: `onSubmitted`에서 요청 단계에 팀장(위 규칙으로 정한 사용자)의 APPROVE 단계가 있는지 다시 확인하고, 없으면 예외(라벨 `PMS_Dlv_TeamLeadRequired`)로 상신 전체를 되돌린다(템플릿 데이터가 빠진 환경 대비).
- BR-3: 산출물별 결재 단계(P-65 "산출물별 결재선 지정").
  - 기여자가 `PMS_DeliverableApprovalRule__mdt`에서 DeliverableCode 일치 행, 없으면 DocClassCode 일치 행을 고른다. CustomerGroup이 프로젝트 고객 그룹과 같은 행이 있으면 그 행이 우선한다.
  - PROJECT_ROLE 단계는 PMS-12-APV-001의 해석 메서드로 그 프로젝트 CFT의 ACTIVE 구성원을 구한다(여러 명이면 같은 StepNo 병렬). ROLE은 APV-002 Role 해석(프로젝트 생산 공장 기준).
  - 기안자 본인은 빼고, 같은 사람이 여러 단계에 나오면 가장 뒤 단계만 남긴다. 결재자가 없으면 IsMandatory 단계는 상신 차단("프로젝트 역할 {코드} 담당 없음"), 아니면 건너뛴다.
  - 기본 규칙(설치 데이터, PMO가 조정): DFMEA → 20 AGREE PROJECT_ROLE QE, PFMEA → 20 AGREE ME + 30 AGREE QE, CONTROL_PLAN → 20 AGREE QE + 30 AGREE ME, PROCESS_FLOW → 20 AGREE ME, DR 결과 보고서 → 95 CC PM.
  - 사용자는 APV-002 BR-3 범위에서 비필수 단계를 지우거나 사람을 더할 수 있다(P-66).
- BR-4: 콜백 `PMS_DeliverableApprovalCallback`(CMN_ApprovalCallback). 문서 리비전 이동은 DOC-001 서비스로만 한다. 산출물 상태는 리비전 변화에 따라 DLV-001 리스너가 계산한다.
  - onSubmitted: 산출물 문서의 DRAFT 리비전 → IN_APPROVAL(`CMN_DocumentService.moveRevisions`), ApprovalRequest·ApprovalVersion·ApprovalSubmittedAt 기록, BR-2 방어선, 이벤트 APPROVAL_SUBMITTED.
  - onApproved: IN_APPROVAL 리비전 → `CMN_DocumentService.release`(이전 RELEASED는 SUPERSEDED), ApprovedAt 기록, 열린 `PMS_DLV_REWORK` To-Do 종료, 알림 `PMS_DLV_APPROVED`(액티비티 주·보조 담당, PM), 이벤트 APPROVED, BR-5 게시 큐 등록.
  - onRejected: IN_APPROVAL → REJECTED, LastRejectComment(반려 단계 의견), 기안자에게 To-Do `PMS_DLV_REWORK`("산출물 보완: {RecordNo} {Name}"), 알림 `PMS_DLV_REJECTED`, 이벤트 REJECTED.
  - onRecalled: IN_APPROVAL → DRAFT. 이벤트 없음.
  - 한 산출물의 문서가 둘 이상이면(DLV-001 BR-2로 결재 산출물은 MULTI_FILE 금지라 생기지 않음) 첫 문서만 처리하고 WARN 로그.
- BR-5: 승인본 품번 문서 게시(QMS 동기화, DP3-9).
  - 산출물 DocClass 코드에 활성 `PMS_DeliverablePublishRule__mdt`가 있으면 Queueable `PMS_DeliverablePublishJob`이 대상 품번(LEAD_PART = 프로젝트 대표 품번 PMS_ProjectPart__c.IsLeadPart의 Item, ALL_PARTS = 프로젝트 품번의 서로 다른 Item 최대 20개)마다 DOC-001 V0-3 `publishCopy(approvedRevisionId, itemId)`를 호출한다.
  - 결과: 품번(CMN_Item__c)에 같은 DocClass 문서의 새 RELEASED 리비전(PublishedFromRevision = 산출물 리비전). Vol.4 RPP-002 `QMS_DocumentCollector`가 "같은 품번 부모의 최신 RELEASED"로 이 문서를 읽는다.
  - 기본 규칙: PPAP > DFMEA·PFMEA·CONTROL_PLAN·PROCESS_FLOW·DESIGN_RECORD 하위 코드 → ALL_PARTS.
  - 실패하면 CMN_Logger ERROR + PM에게 To-Do `PMS_DLV_PUBLISH_FAILED`(재시도 버튼은 산출물 페이지 "품번 게시 다시 하기", PM). 결재 결과는 되돌리지 않는다.
- BR-6: 연계 동기화 대상과 담당(P-38 "기간 시스템 연관 데이터·마일스톤 상호 동기화").

  | 대상 | 방법 | 구현 WI |
  | --- | --- | --- |
  | 액티비티 완료·자동 종료 | 롤업 DlvMandatoryDone 변화로 액티비티 저장 절차가 돌고, 완료 조건 검사기(DLV-001 BR-9) 통과 시 종료 | PMS-07-ACT-004 |
  | 고객 마일스톤 실적일 | 마일스톤 액티비티 COMPLETED → 마일스톤 ActualDate | PMS-02-PRJ-003, ACT-004 |
  | Gate 자동 점검 | 평가 시 `PMS_DeliverableQueryService.byCodes` 조회 | PMS-09-GAT-003 |
  | QMS Re-PPAP 증빙 | BR-5 품번 문서 게시 | 이 WI(Vol.4 변경 없음) |
  | QMS 기타(레슨런 반영 증빙, 인정시험 착수 조건) | `PMS_DeliverableEvent__e` APPROVED 구독 | PMS-12-INT-005 |
  | DMS(금형 발주·검수 승인 문서) | 이벤트 구독 → Mule → DMS | PMS-12-INT-003 |
  | PDM(도면 승인 상태) | 이벤트 구독 | PMS-12-INT-004 |

  - 이벤트는 Publish After Commit이다(롤백된 결재가 통지되지 않게). Mule 경로 목표 지연 1분 이내.
- BR-7: 진행 상태 조회(P-68). 산출물 패널·검색 목록의 결재 열은 DOC-001이 아니라 APV `getStatuses`(V0-4, 일괄)로 현재 단계·결재자·체류일을 받는다. 전체 결재 현황은 APV-003 `cmnApprovalMonitor`(유형 필터 PMS_DELIVERABLE)를 SL PMS 앱에 배치한다.
- BR-8: 결재자 열람. APV-001 BR-6 공유는 Master-Detail 하위인 산출물에 공유 행을 만들 수 없으므로 ShareTargetPath `Activity__r.Project__c`로 프로젝트 Read를 준다(V0-5). 파일은 산출물 레코드에 연결돼 있어(V0-1 LinkFilesToParent) 프로젝트를 읽을 수 있는 결재자가 미리보기할 수 있다. 결재자는 비용 PS가 없으므로 비용은 보이지 않는다.

**화면/UX**: 화면 유형 T1(산출물 레코드의 레일 APPROVAL 패널) · 공통 부품 APV-003 `cmnApprovalLine`·`cmnApprovalHistory`·`cmnApprovalMonitor`. 이 WI는 새 LWC를 만들지 않는다.
- 산출물 레코드: 레일 APPROVAL 패널(결재선 요약·상신·회수), 이력 탭에 `cmnApprovalHistory`.
- 반려되면 현재 단계 탭 위쪽에 LastRejectComment를 경고 상자로 보인다(`pmsDeliverableContent`, DLV-001).
- SL PMS 앱 내비게이션 "결재 현황" = `cmnApprovalMonitor`.

**권한**: 상신은 PMS_PS_Deliverable_Edit + BR-1 담당 확인. 결재자 처리는 APV 엔진 규칙(PMS_PSG_TeamLead에 PMS_PS_Deliverable_Read 포함). 규칙 메타데이터 변경은 배포(관리자).

**수용 기준**

- AC-1: Given 기안자 A(설계팀, 팀장 B), DFMEA 규칙(20 AGREE QE = C), When 결재선 해석, Then [20 AGREE C, 90 APPROVE B(필수)].
- AC-2: Given 기안자가 설계팀장 B 본인(상위 부서장 D), When 해석, Then 90 APPROVE D.
- AC-3: Given 사용자가 팀장 단계를 지우고 상신, When 서버 처리, Then 차단(APV-002 필수 단계).
- AC-4: Given 템플릿 데이터가 없는 환경, When 팀장 없이 상신, Then onSubmitted 방어선이 예외를 내고 결재 요청이 남지 않는다.
- AC-5: Given 승인 완료, When 처리, Then Rev2 RELEASED·Rev1 SUPERSEDED, 산출물 APPROVED·IsSatisfied true, 액티비티 DlvMandatoryDone +1, APPROVED 이벤트 1건(커밋 후), 알림 대상 = 담당·PM.
- AC-6: Given PFMEA 승인, 프로젝트 품번 3개(Item 서로 다름), When 게시 잡 실행, Then 품번 3개에 PFMEA 문서 새 RELEASED 리비전, PublishedFromRevision 설정, IsDuplicateFile false.
- AC-7: Given 반려, When 처리, Then 리비전 REJECTED, 산출물 REJECTED(이전 승인본이 없을 때), 기안자 To-Do 1건, 새 리비전 업로드 시 SUBMITTED로 돌아간다.
- AC-8: Given 다른 공장 소속 팀장 결재자, When 상신, Then 그 팀장이 산출물과 파일을 열 수 있다.
- AC-9: Given 보조 담당이 아닌 PM, When 상신 버튼, Then 비활성 + 서버 차단.

**에이전트 주의**: 표준 Approval Process를 만들지 않는다. 산출물 Status를 콜백에서 직접 쓰지 않는다(리비전 이동 → 리스너 계산). QMS·DMS 객체를 콜백에서 갱신하지 않는다(이벤트만, 품번 게시는 DOC-001 서비스). 결재 엔진이 만드는 결재자 To-Do를 콜백에서 다시 만들지 않는다(APV-001 BR-9).

**오픈 이슈**: "팀장"의 정의(작성자 소속 팀장 vs 액티비티 주관 부서장), 고객 제출 산출물에 PM 최종 승인 필요 여부, 품번 게시 대상 범위(대표 품번만 vs 전 품번)와 게시 문서의 공장 공개 범위.

### PMS-06-DLV-003 입력/출력 추적성(디지털 스레드)

추적 P-37, P-6 · 필수 · W2 · SF, SNOW · DM, APEX, LWC, SQL · Customization · 선행 DLV-001, DWH-002, DWH-004, UX-004, PMS-02-SOR-002, PMS-04-WBS-004 · 7 M/D

**목적**: "IP6K9K 방수 요구사항 → 하우징 설계 사양서 → PDM 도면 → DFMEA → 신뢰성 방수 시험 판정"처럼 상류 입력과 하류 출력을 연결해, 어떤 요구가 어디서 검증됐고 무엇이 무엇에서 나왔는지 프로젝트 안팎에서 따라간다(P-37). PoC 시나리오 3(설계 변경의 연쇄 추적)의 데이터 모델이다.

**범위** In: `PMS_DeliverableTrace__c`, 그래프 조회 서비스, 연결 생성·검증(중복·순환), 표준 입력 정의에 따른 자동 연결, 추적 탐색 화면, 레일 요약 패널, Snowflake 간선 뷰와 전사 계보 쿼리. Out: 요구사항 연결 저장(SOR-002 `PMS_RequirementLink__c`가 원본, DP3-13), 영향도 분석(DLV-004), 외부 시스템 원천 적재(PMS-12-INT-004).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_DeliverableTrace__c.Project__c | Master-Detail(PMS_Project__c) | Y | 계약. 하류(To) 쪽 프로젝트 |
| PMS_DeliverableTrace__c.FromType__c / ToType__c | Picklist (DELIVERABLE, ACTIVITY, SYSTEM) | Y | 계약 FromType·ToType. REQUIREMENT는 저장하지 않는다(BR-1) |
| PMS_DeliverableTrace__c.FromRecordId__c / ToRecordId__c | Text(80) | Y | 계약. Salesforce Id(18) 또는 시스템 외부 키 |
| PMS_DeliverableTrace__c.FromSystemLinkType__c / ToSystemLinkType__c | Text(40) | SYSTEM이면 Y | (제안) PMS_SystemLinkType__mdt 키 |
| PMS_DeliverableTrace__c.FromLabel__c / ToLabel__c | Text(255) | Y | (제안) 표시 사본(번호 + 이름 + Rev) |
| PMS_DeliverableTrace__c.RelationType__c | Picklist (INPUT_OF, DERIVED_FROM, VERIFIES) | Y | 계약. 의미는 BR-2 |
| PMS_DeliverableTrace__c.FromRevisionNo__c / ToRevisionNo__c | Number(4,0) | N | (제안) 연결 당시 리비전 |
| PMS_DeliverableTrace__c.IsStale__c | Checkbox | — | (제안) From이 연결 이후 개정됨(DLV-004가 설정) |
| PMS_DeliverableTrace__c.Source__c | Picklist (MANUAL, TEMPLATE, SYSTEM) | Y | (제안) TEMPLATE = 표준 입력 정의 자동, SYSTEM = 연계 |
| PMS_DeliverableTrace__c.UniqueKey__c | Text(255), Unique | Y | (제안) `{FromType}:{FromKey}>{RelationType}>{ToType}:{ToKey}`(Key = SystemLinkType/RecordId 또는 RecordId) |
| PMS_DeliverableTrace__c.Note__c | Text(255) | N | |

**서비스 API**

    public with sharing class PMS_TraceGraphService {
        // direction: UP(상류), DOWN(하류), BOTH. depth 1~5(CMN 설정 PMS_TRACE_MAX_DEPTH)
        public static PMS_TraceGraph getGraph(String nodeType, String nodeKey, String systemLinkType, Integer depth, String direction);
        public static Id link(PMS_TraceSpec spec);   // 검증(BR-3) 후 생성
        public static void unlink(Id traceId);
    }
    // PMS_TraceGraph: nodes[{nodeKey, type(REQUIREMENT, DELIVERABLE, ACTIVITY, SYSTEM), recordId, systemLinkType, label, statusLabel,
    //   revisionNo, isStale, reviewRequired, accessible, url, level}], edges[{fromKey, toKey, relationType, traceId, source, isStale}], truncated

**비즈니스 규칙**

- BR-1: 간선 원천 세 가지를 한 그래프로 합친다.
  - (a) `PMS_DeliverableTrace__c`(이 WI).
  - (b) `PMS_RequirementLink__c`(SOR-002): 요구사항 → TargetType·TargetRecordId. 요구사항에서 나가는 연결은 SOR-002 화면·서비스에서만 만들고 이 객체에 다시 저장하지 않는다(중복 금지). 간선 관계는 TargetType이 시험·검증이면 VERIFIES, 그 외 DERIVED_FROM으로 표시한다(SOR-002의 관계 값이 있으면 그것을 쓴다).
  - (c) 암묵 간선(저장하지 않음): 액티비티 → 그 산출물(PRODUCES), SYSTEM_LINK 산출물 → 연결된 시스템 레코드(LINKS).
- BR-2: 방향은 항상 상류(From) → 하류(To)다. 관계의 뜻: INPUT_OF = "From이 To의 입력이다", DERIVED_FROM = "To가 From에서 나왔다", VERIFIES = "To가 From을 검증한다". 예: DFMEA INPUT_OF DVP 계획, 설계 사양서 → 도면 DERIVED_FROM, 요구사항 → 시험 판정 VERIFIES.
- BR-3: 연결 검증 `link(spec)`.
  - 자기 자신 연결 금지, UniqueKey 중복 금지.
  - 순환 금지: To에서 하류로 깊이 10·노드 500까지 탐색해 From에 닿으면 차단("순환 연결").
  - To는 사용자가 편집할 수 있는 프로젝트의 산출물·액티비티이거나, 그 프로젝트 산출물이 가리키는 시스템 레코드여야 한다(트레이스는 To 쪽 프로젝트에 속함). From은 사용자가 읽을 수 있는 레코드(다른 프로젝트 가능, 예: 캐리오버 부품의 이전 프로젝트 DFMEA).
  - VERIFIES의 To가 시험·검증 성격(DocClass `PMS_DLV > TEST_RESULT`·`DVPR`, 시스템 유형 QMS_QUAL_PLAN·RELIABILITY_TEST)이 아니면 경고만 한다(저장은 허용).
  - 연결 당시 From·To 리비전 번호와 라벨을 저장한다.
- BR-4: 표준 입력 정의 자동 연결. WBS-002의 `PMS_WbsTemplateDeliverable__c.InputDeliverableCodes__c`(Vol.P2 요청, 쉼표 구분 코드)가 있으면 `syncFromTemplate` 직후 같은 프로젝트에서 그 코드를 가진 산출물(같은 코드가 여럿이면 WBS 순서상 가장 가까운 선행 액티비티의 것) → 이 산출물로 INPUT_OF(Source TEMPLATE)를 만든다. 멱등. 필드가 없으면 건너뛴다.
- BR-5: 그래프 조회 `getGraph`.
  - 깊이별 너비 우선 탐색. 깊이마다 트레이스 2회(From·To 키 집합)·요구사항 연결 1회·노드 정보 1~2회 SOQL. 노드 최대 CMN 설정 `PMS_TRACE_MAX_NODES`(200), 넘으면 truncated = true.
  - 노드 접근 확인: Salesforce 레코드는 UserRecordAccess(200개 단위 조회)로 확인하고, 읽을 수 없으면 type만 남기고 label·url을 비운 "권한 없음" 노드로 보인다. 시스템 노드는 리졸버 `resolve`의 accessible을 따른다.
  - 노드 상태 표시: 산출물은 Status·Rev·IsUnderRevision·ReviewRequired, 요구사항은 SOR 상태, 시스템은 리졸버 statusLabel.
- BR-6: 연결 삭제. MANUAL은 작성자·PM, TEMPLATE은 PM(사유를 Note에), SYSTEM은 연계만. 삭제는 CMN_DeleteLog(SEC-003)에 남긴다.
- BR-7: Snowflake.
  - DWH-002 등록: PMS_DeliverableTrace__c, PMS_Deliverable__c(DLV-001), PMS_RequirementLink__c(SOR-002) 15분.
  - `MART.V_PMS_TRACE_EDGE`: 세 원천을 FROM_KEY·TO_KEY·RELATION·PROJECT_ID·PLANT_CODE 열로 합친 뷰. PDM·ALM·DMS 원천(INT-004 적재)과 같은 키 규칙(SystemLinkType/외부 키)을 써서 PoC 시나리오 3의 시스템 간 연쇄를 같은 표에서 잇는다.
  - 등록 쿼리 `PMS_DLV_LINEAGE`(QUERY, FAST, PlantParam plantCodes, 파라미터 rootKey·direction·maxDepth ≤ 10, 재귀 CTE, MaxRows 1,000): 화면의 "전체 계보(전사)" 보기에서만 부른다. 결과 노드는 Apex가 BR-5와 같은 접근 확인을 한 뒤에만 화면에 보낸다.

**화면/UX**: 화면 유형 T5(탐색, 산출물·프로젝트 T1 레코드의 탭) · 공통 부품 UX-004 레일 패널 계약, DWH-004 등록 쿼리, `cmnDwDataState`.
- `pmsTraceExplorer`(제안): 산출물 레코드 "추적성" 탭, 프로젝트 레코드 "디지털 스레드" 탭.
  - 가운데 기준 노드, 왼쪽 상류 단계, 오른쪽 하류 단계의 열 배치. 카드 = 유형 아이콘·텍스트, 번호·이름, 상태, Rev, "상류 개정됨"·"재검토 필요" 배지.
  - 간선은 LWC가 그리는 SVG 선(외부 라이브러리 없음, 색은 SLDS 전역 훅). 관계 이름을 선 가운데 텍스트로.
  - 카드를 누르면 그 노드를 기준으로 다시 그린다. 깊이(1~5)·방향 선택, "전체 계보(전사)" 토글(BR-7).
  - "연결 추가" 모달: 관계 선택 → 대상 검색(프로젝트 산출물·액티비티, 시스템 유형별 리졸버 search). 요구사항은 "요구사항 화면에서 연결" 안내와 링크.
- `pmsTraceSummaryPanel`(제안, 레일 패널 CONTEXT_TRACE, 산출물 객체 행): 입력 n·출력 m, 상류 개정 k건 경고, 탭 열기 링크. `railbadge` = 상류 개정 수.
- 휴대폰: 들여쓰기 트리 목록(그래프 그림 없음).

**권한**: 조회 PMS_PS_Deliverable_Read, 연결 생성·삭제 PMS_PS_Deliverable_Edit(+ BR-3 To 쪽 편집 권한), TEMPLATE 연결 삭제 `PMS_DLV_Manage`.

**수용 기준**

- AC-1: Given 요구사항 R1 → 사양서 D1(SOR-002 연결), D1 → 도면 P1(시스템 PDM_DRAWING, DERIVED_FROM), R1 → 인정시험 Q1(SOR-002, 시험), When getGraph(D1, 깊이 2, BOTH), Then 노드 R1·D1·P1·Q1과 간선 3개, R1 간선의 원천은 RequirementLink.
- AC-2: Given 같은 연결, When 다시 link, Then 차단(UniqueKey).
- AC-3: Given A→B→C, When C→A 연결, Then "순환 연결"로 차단.
- AC-4: Given 접근 권한이 없는 다른 프로젝트 산출물이 상류에 있음, When 그래프 조회, Then 그 노드는 "권한 없음"으로 label·url이 비어 있다.
- AC-5: Given 하류 노드 300개, When 조회, Then 200개 + truncated true.
- AC-6: Given 표준 산출물 PFMEA의 InputDeliverableCodes = DFMEA, When syncFromTemplate 2회, Then DFMEA → PFMEA INPUT_OF(TEMPLATE) 1건.
- AC-7: Given 깊이 5 그래프, When 조회, Then SOQL 25회 이하, 2초 이내(노드 200 기준).
- AC-8: Given KR01 권한 사용자, When 전체 계보 쿼리, Then KR01 프로젝트 간선만, 접근 불가 노드는 "권한 없음".

**에이전트 주의**: 그래프 라이브러리(d3, vis 등)를 쓰지 않는다(승인 목록 밖). 요구사항 연결을 이 객체에 복사하지 않는다. QMS·PDM 레코드를 Lookup하지 않는다(텍스트 키 + 리졸버). 트레이스를 산출물 Master-Detail 하위로 만들지 않는다(다른 프로젝트 상류를 가리켜야 함).

**오픈 이슈**: PDM 도면·BOM 키 체계(도면 번호 + 리비전), ALM(Codebeamer) 요구 항목을 SYSTEM 노드로 넣을 범위, 표준 WBS에 입력 산출물을 정의할 주체(PMO)와 시점.

### PMS-06-DLV-004 산출물 개정·영향도 분석

추적 P-39, P-58, P-71 · 필수 · W2 · SF · DM, APEX, LWC, CFG · Customization · 선행 DLV-002, DLV-003, AI-003, TDO-001, NTF-001, UX-004, UX-006, PMS-04-WBS-004, PMS-09-GAT-003 · 6 M/D

**목적**: 완료된 액티비티의 산출물도 개정할 수 있게 하되(P-39), 이전 승인본은 새 판이 승인될 때까지 유효하게 두고, 바뀐 내용이 하류 산출물·후행 액티비티·연계 시스템·통과한 Gate에 미치는 영향을 찾아 사람이 판정하고 재검토를 시킨다.

**범위** In: 개정 시작·취소, 개정 중 상태 규칙, 콜백 개정 분기, 영향도 분석 서비스, `PMS_ImpactAssessment__c`·`PMS_ImpactItem__c`, 판정 그리드, 재검토 To-Do·완료 처리, 상류 개정 표시. Out: 버전 비교·변경 요약(AI-003 그대로), 프로젝트 변경 요청 결재(PMS-13-CHG-001), AI 영향 순위 추천(PMS-11, 이 Vol. 범위 밖).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| PMS_Deliverable__c.IsUnderRevision__c | Checkbox | — | 개정 진행 중 |
| PMS_Deliverable__c.RevisionReason__c | Lookup(CMN_Code__c, Group `PMS_DLV_REVISION_REASON`) | 개정 중 Y | CUSTOMER_CHANGE 고객 변경, DESIGN_CHANGE 설계 변경, FOURM 4M 변경, ISSUE_CORRECTION 문제점 대책, PERIODIC 정기 갱신(FMEA 등), ERROR_FIX 오류 정정, OTHER |
| PMS_Deliverable__c.RevisionNote__c | Text(1000) | 개정 중 Y | |
| PMS_Deliverable__c.RevisionStartedAt__c / RevisionStartedBy__c | DateTime / Lookup(User) | N | |
| PMS_Deliverable__c.ReviewRequired__c | Checkbox | — | 상류 개정 영향으로 재검토 필요(영향 판정 IMPACTED 시) |
| PMS_Deliverable__c.ReviewRequiredBy__c | Lookup(PMS_ImpactAssessment__c) | N | 재검토를 요구한 영향도 분석 |
| PMS_ImpactAssessment__c.Project__c | Master-Detail(PMS_Project__c) | Y | |
| PMS_ImpactAssessment__c.RecordNo__c | Text(40), Unique, External ID | Y | (제안) `IA-{YYYY}-{SEQ:5}` |
| PMS_ImpactAssessment__c.Name | Text(80) | Y | "{산출물명} Rev{n} 개정 영향" |
| PMS_ImpactAssessment__c.SourceDeliverable__c | Lookup(PMS_Deliverable__c) | Y | 계약 |
| PMS_ImpactAssessment__c.SourceRevisionNo__c | Number(4,0) | Y | 개정 대상(새) 리비전 번호, 시작 시점엔 현재 + 1 |
| PMS_ImpactAssessment__c.TriggerType__c | Picklist (REVISION_STARTED, MANUAL) | Y | |
| PMS_ImpactAssessment__c.ChangeSummary__c | Long Text(32768) | N | 개정 사유·메모, 새 리비전 RELEASED 후 AI-003 AiChangeSummary(확정본은 ChangeNote) 사본 |
| PMS_ImpactAssessment__c.AffectedJson__c | Long Text(131072) | Y | 계약. 분석 스냅숏 `[{nodeKey, type, recordId, systemLinkType, label, path, depth, reason}]` |
| PMS_ImpactAssessment__c.Status__c | Picklist (ANALYZED, IN_REVIEW, CONFIRMED, CLOSED, CANCELLED) | Y | 계약 Status |
| PMS_ImpactAssessment__c.Coordinator__c | Lookup(User) | Y | 개정 시작자(판정 책임) |
| PMS_ImpactAssessment__c.DueDate__c / DaysToDue__c | Date / Formula(Number, 0) | Y / — | 기본 시작일 + CMN 설정 `PMS_IA_DUE_DAYS`(5) |
| PMS_ImpactAssessment__c.ItemCount__c / OpenItemCount__c | Roll-up COUNT(전체 / Decision PENDING 또는 IMPACTED·IsDone false) | — | |
| PMS_ImpactAssessment__c.ConfirmedAt__c / ConfirmedBy__c | DateTime / Lookup(User) | N | |
| PMS_ImpactItem__c.ImpactAssessment__c | Master-Detail(PMS_ImpactAssessment__c) | Y | (제안 객체) |
| PMS_ImpactItem__c.ItemType__c | Picklist (DELIVERABLE, ACTIVITY, SUCCESSOR_ACTIVITY, SYSTEM, REQUIREMENT, GATE, PUBLISHED_DOC) | Y | |
| PMS_ImpactItem__c.TargetRecordId__c / SystemLinkType__c / TargetLabel__c | Text(80) / Text(40) / Text(255) | Y / SYSTEM이면 Y / Y | |
| PMS_ImpactItem__c.PathText__c / Depth__c | Text(255) / Number(2,0) | Y | 예: "DFMEA → PFMEA → 관리계획서" |
| PMS_ImpactItem__c.Responsible__c | Lookup(User) | Y | BR-4 규칙 |
| PMS_ImpactItem__c.Decision__c | Picklist (PENDING, IMPACTED, NO_IMPACT) | Y | 기본 PENDING |
| PMS_ImpactItem__c.DecisionReason__c | Text(500) | NO_IMPACT면 Y | |
| PMS_ImpactItem__c.ActionDueDate__c | Date | IMPACTED면 Y | |
| PMS_ImpactItem__c.IsDone__c / DoneNote__c | Checkbox / Text(500) | — / 수동 완료면 Y | |

**비즈니스 규칙**

- BR-1: 개정 시작(액션 "개정 시작", Custom Permission `PMS_DLV_Submit` + 액티비티 주·보조 담당 또는 PM).
  - 대상: IsSatisfied = true(APPROVED, 또는 결재 불필요 SUBMITTED)이고 IsUnderRevision = false, 액티비티 CANCELLED 아님. 액티비티가 COMPLETED여도 된다(P-39).
  - RevisionReason·RevisionNote 필수. IsUnderRevision = true, RevisionStarted 기록, 이벤트 REVISION_STARTED.
  - 하류 그래프(BR-3)에 노드가 1개 이상이면 영향도 분석을 바로 만든다(TriggerType REVISION_STARTED). 없으면 만들지 않고 "하류 연결 없음"을 안내한다.
  - 액티비티를 재시작(REOPENED)하지 않는다. 다시 열지는 PM이 ACT-004로 정한다(DP3-11).
- BR-2: 개정 중 규칙.
  - DLV-001 리스너는 IsUnderRevision이면 완료 액티비티에도 업로드를 허용한다.
  - 이전 RELEASED 리비전이 유효하므로 IsSatisfied는 true로 유지된다(DLV-001 BR-4 규칙 그대로: RELEASED가 있으면 충족). 액티비티 롤업은 변하지 않는다.
  - 결재 산출물: 새 리비전 DRAFT → 상태 SUBMITTED, 상신·승인은 DLV-002 그대로(재승인, P-39). 반려되면 이전 승인본이 있으므로 상태 APPROVED, LastRejectComment 표시, IsUnderRevision 유지.
  - DLV-002 콜백 개정 분기(이 WI가 콜백에 더함): onApproved에서 IsUnderRevision이면 false로 바꾸고 이벤트 REVISED(RevisionNo, DocumentRevisionId, ImpactAssessmentId)를 APPROVED와 함께 발행한다.
  - 결재 불필요 산출물: 새 리비전이 바로 RELEASED → 리스너가 IsUnderRevision false, REVISED 발행.
  - REVISED 시: 이 산출물이 From인 트레이스를 IsStale = true, 열린 영향도 분석의 ChangeSummary에 AI-003 요약(없으면 ChangeNote)을 넣는다. 품번 게시 규칙 대상이면 DLV-002 BR-5 게시를 다시 한다.
  - 개정 취소(액션, 시작자·PM, IN_APPROVAL이 아닐 때): DRAFT 리비전 → REJECTED(`moveRevisions`), IsUnderRevision false, 열린 영향도 분석 CANCELLED(사유 "개정 취소").
- BR-3: 영향도 분석 `PMS_ImpactAnalysisService.analyze(deliverableId, triggerType)`.
  - (a) 하류: `PMS_TraceGraphService.getGraph(DELIVERABLE, id, DOWN, CMN 설정 PMS_IA_DEPTH(기본 3))`의 산출물·액티비티·시스템 노드.
  - (b) 검증 대상: 이 산출물이 To인 VERIFIES 간선의 From(요구사항 등) — 검증 결과가 바뀌면 요구사항 충족이 흔들린다.
  - (c) 후행 액티비티: 이 산출물 액티비티의 직접 후행(PMS_ActivityDependency__c, WBS-004). COMPLETED 후행은 reason "완료 후 재검토 필요".
  - (d) Gate: PASSED·CONDITIONAL 상태 Gate의 `PMS_GateCheckItem__c.EvidenceDeliverableIds__c`에 이 산출물 Id가 있는 항목(GAT-003, 쉼표 구분 Id LIKE 검색).
  - (e) 게시 문서: 이 산출물 리비전에서 게시된 품번 문서(PublishedFromRevision, DLV-002) → PUBLISHED_DOC(QMS Re-PPAP 증빙 영향).
  - 중복 노드는 가장 짧은 경로 하나만 남긴다. 최대 CMN 설정 `PMS_IA_MAX_ITEMS`(200), 넘으면 AffectedJson에 truncated 표시와 함께 앞 200개.
  - AffectedJson 스냅숏과 항목 행을 만든다. Status ANALYZED, Coordinator에게 To-Do `PMS_DLV_IMPACT_REVIEW`("영향도 판정: {RecordNo}").
  - "다시 분석"(ANALYZED·IN_REVIEW에서): PENDING 항목만 지우고 새로 만든다. 판정한 항목은 유지.
- BR-4: 담당 지정(Responsible). 산출물 → 그 액티비티 주담당, 액티비티·후행 → 주담당, 시스템 → TargetSystem별 프로젝트 역할(QMS → QE, PDM → PE, DMS → ME, ALM → ELE, 그 외 PM, PMS-12-APV-001 해석), 요구사항 → PM, Gate → PM, 게시 문서 → QE(없으면 PM).
- BR-5: 판정(그리드). 첫 판정 저장 시 IN_REVIEW. NO_IMPACT는 사유 필수, IMPACTED는 조치 기한 필수(기본 = 오늘 + 10일).
- BR-6: 확정 "영향 확정"(Coordinator 또는 PM, `PMS_DLV_Manage` 또는 Coordinator 본인): PENDING 항목이 없어야 한다. CONFIRMED, ConfirmedAt·By. IMPACTED 항목별 후속:
  - DELIVERABLE: 대상 산출물 ReviewRequired = true·ReviewRequiredBy = 이 분석, Responsible에게 To-Do `PMS_DLV_RECHECK`("산출물 재검토: {대상} (원인 {원천 산출물} Rev{n})"), 알림 `PMS_DLV_REVISED`.
  - ACTIVITY·SUCCESSOR_ACTIVITY·SYSTEM·REQUIREMENT·GATE·PUBLISHED_DOC: Responsible에게 To-Do `PMS_DLV_RECHECK`(항목 라벨·경로).
  - 확정 사실은 이벤트 REVISED에 ImpactAssessmentId로 이미 실리므로 별도 이벤트를 만들지 않는다. 연계 시스템 쪽 작업 요청은 To-Do로 사람에게 준다(다른 메뉴에 일을 시키는 이벤트 금지, interfaces 1절).
- BR-7: 완료.
  - DELIVERABLE 항목: 대상 산출물이 새 리비전을 RELEASED(REVISED)하면 자동 IsDone, ReviewRequired false, To-Do 종료. 변경이 필요 없으면 Responsible이 대상 산출물에서 "재검토 완료(변경 없음)"(DoneNote 필수) → 같은 처리.
  - 그 밖의 항목: Responsible이 항목 그리드의 "완료" 처리(DoneNote 필수) → IsDone, To-Do 종료.
  - IMPACTED 항목이 모두 IsDone이면 CLOSED, Coordinator·PM 알림. 기한(DueDate) 경과 시 Coordinator·PM 매일 알림.
- BR-8: 버전 비교·이력(P-39 "버전별 변경내용 비교", "최종버전 및 전체 히스토리"). 산출물 페이지 현재 단계 탭의 `cmnDocumentPanel` 리비전 이력·비교(AI-003)를 그대로 쓴다. 스캔 PDF·CAD는 AI-003 BR-4로 "비교 불가"를 보인다. 이력 탭은 결재 이력(APV-003)과 필드 이력.
- BR-9: 공통 기반 — 채번 IA, CMN_StatusFlow, DeleteGuard(ANALYZED·CANCELLED), 필드 이력, DWH-002 복제, 번역, UX-005 규칙 파일 `PMS_ImpactAssessment__c.json`·`PMS_Deliverable__c.json`(개정 시작·취소, 재검토 완료 액션 추가).

**화면/UX**: 화면 유형 T1 + T2(영향도 분석 레코드 안의 판정 그리드) · 공통 부품 UX-004 레코드 표준, UX-005 규칙, UX-006 그리드, AI-003 비교.
- 산출물 레코드 Dynamic Actions: "개정 시작"(LWC 빠른 작업 `pmsRevisionStart`(제안): 사유 코드·메모, 하류 노드 수 미리보기), "개정 취소", "재검토 완료". 개정 중이면 현재 단계 탭 위쪽에 "개정 중(사유)" 배지, ReviewRequired면 "상류 변경으로 재검토 필요: {원천}" 경고.
- 영향도 분석 레코드 페이지(UX-004 생성기). 헤더: RecordNo, Name, Status, CustomerName(프로젝트 고객), 원천 산출물(품번 자리 대체), ProdPlant, DaysToDue.
  - 현재 단계 탭: 변경 요약(ChangeSummary) 읽기 섹션, 판정 그리드 `cmnEditableGrid` gridKey `PMS_ImpactItem`(부모 PMS_ImpactAssessment__c, AllowAdd false, AllowDelete false, MaxRows 200). 열: 유형(읽기), 대상(읽기, 링크), 경로(읽기), 깊이(읽기), 담당, 판정, 사유, 조치 기한, 완료(읽기), 완료 메모. Provider `PMS_ImpactItemGridProvider`: rowMeta(CONFIRMED 후 판정 열 잠금, 완료는 Responsible만), validate(BR-5).
  - 액션: "영향 확정", "다시 분석", "분석 취소". 레일: TODO, COMMENT.
- 산출물 레일 CONTEXT_TRACE 패널(DLV-003)이 상류 개정 수를 배지로 보인다.

**권한**: 개정 시작·재검토 완료 PMS_PS_Deliverable_Edit(+ 담당 확인), 판정 PMS_PS_Deliverable_Edit(Coordinator·Responsible), 확정·취소 Coordinator 또는 PMS_PS_Deliverable_Manage.

**수용 기준**

- AC-1: Given COMPLETED 액티비티의 APPROVED DFMEA(하류 PFMEA·관리계획서, 후행 액티비티 1개), When 사유 없이 개정 시작, Then 차단. 사유 입력 시 IsUnderRevision true, 분석 1건(항목 3개 이상), Coordinator To-Do 1건, REVISION_STARTED 1건.
- AC-2: Given 개정 중, When 새 리비전 업로드, Then 액티비티 DlvMandatoryDone 변화 없음, 산출물 SUBMITTED·IsSatisfied true.
- AC-3: Given 새 Rev3 승인, When 처리, Then Rev2 SUPERSEDED, 산출물 APPROVED·IsUnderRevision false, REVISED 1건, DFMEA→PFMEA 트레이스 IsStale true.
- AC-4: Given 개정 리비전 반려, When 처리, Then 산출물 APPROVED(Rev2 유효), LastRejectComment, IsUnderRevision true.
- AC-5: Given PENDING 항목이 남음, When 영향 확정, Then 차단. NO_IMPACT 사유 없음, Then 그리드 행 오류.
- AC-6: Given IMPACTED 산출물 2·Gate 1, When 확정, Then 산출물 2건 ReviewRequired true, To-Do 3건(산출물 담당 2, PM 1).
- AC-7: Given IMPACTED PFMEA의 새 리비전 RELEASED, When 처리, Then 항목 IsDone, ReviewRequired false, To-Do 종료. 모든 항목 완료 시 분석 CLOSED.
- AC-8: Given 하류 노드 250개, When 분석, Then 항목 200개, AffectedJson truncated 표시.
- AC-9: Given 통과한 Gate 평가 항목 증빙에 이 산출물 Id, When 분석, Then GATE 항목 1건.

**에이전트 주의**: 개정 시작 때 이전 RELEASED 리비전을 바꾸지 않는다(DOC-001 BR-2가 새 RELEASED 때 SUPERSEDED 처리). 액티비티 상태를 이 WI가 바꾸지 않는다. 영향 항목을 JSON만으로 관리하지 않는다(판정·To-Do·완료 추적은 항목 행, JSON은 분석 스냅숏). 연계 시스템 데이터를 이 WI가 직접 고치지 않는다.

**오픈 이슈**: 기본 분석 깊이(3)와 자동 분석 대상(모든 개정 vs 결재 산출물만), 오류 정정(ERROR_FIX) 개정에 영향도 분석을 생략할지, 고객 승인 문서(PPAP 제출본) 개정 시 고객 재제출 알림 필요 여부.

### PMS-06-DLV-005 프로젝트 산출물 검색·표준 양식 내려받기

추적 P-35, P-36, P-69 · 필수 · W1 · SF · APEX, LWC, CFG · Customization · 선행 DLV-001, DOC-001, AI-002, UX-007, PMS-04-WBS-002 · 3 M/D

**목적**: "작년 BMW 프로젝트의 PFMEA", "김 책임이 올린 DR 보고서"처럼 프로젝트명·액티비티명·파일명·등록자로 산출물을 찾고(P-35), 표준 WBS가 정한 양식을 액티비티에서 바로 내려받는다(P-36). 문서 내용 검색은 AI-002 통합 검색이 맡는다(P-69).

**범위** In: 산출물 검색 서비스·화면, 프로젝트 "산출물" 탭, 표준 양식 결정 규칙·내려받기, 양식 모음 보기, AI-002 검색 범위 등록, 메뉴 등록. Out: 문서 내용 의미 검색·요약(AI-002), 양식 파일 등록·버전(DOC-001 CMN_DocTemplate__c, PMO가 관리), 표준 산출물 정의(WBS-002).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| CMN_SearchScope__mdt `PMS_Deliverable` | Custom Metadata | — | ObjectApiName PMS_Deliverable__c, NumberField RecordNo__c, TitleField Name, SubtitleField LatestFileName__c, Order 30, MaxRows 10, IsActive |
| CMN_AppMenuItem__mdt(SL PMS) | Custom Metadata | — | "산출물 검색" 앱 페이지, "표준 양식" 탭 항목(UX-007) |
| (검색 조건 DTO) PMS_DeliverableSearchCriteria | Apex | — | projectText, activityText, fileName, registeredByText, deliverableCodes, docClassIds, statuses, devPhases, overdueOnly, dateFrom, dateTo, projectId(고정), pageOffset |

**비즈니스 규칙**

- BR-1: 검색 `PMS_DeliverableSearchController.search(criteria)`(cacheable = false, USER_MODE). 선택적인 조건부터 Id 집합으로 좁힌다.
  - 프로젝트어(번호·이름 부분 일치): PMS_Project__c SOQL LIMIT 200 → projectIds. projectId가 주어지면(프로젝트 탭) 그것만.
  - 액티비티어(WBS 코드·이름): PMS_Activity__c SOQL(projectIds가 있으면 그 안) LIMIT 2,000 → activityIds.
  - 등록자어(이름·사번): User SOQL LIMIT 50 → LastSubmittedBy__c IN.
  - 파일명: 프로젝트·액티비티 범위가 있으면 `LatestFileName__c LIKE`, 범위가 없으면 SOSL `FIND :term IN ALL FIELDS RETURNING PMS_Deliverable__c(Id) LIMIT 2000`(산출물명·번호·파일명이 함께 걸린다)로 Id를 구한다.
  - 마지막 SOQL: PMS_Deliverable__c(위 Id 조건 + DeliverableCode·DocClass·Status·Activity__r.DevPhase__c·기한 경과·등록일 범위), ORDER BY LastSubmittedAt__c DESC NULLS LAST, Id, LIMIT 51 OFFSET n(최대 2,000). 51번째가 있으면 "다음".
  - 조건이 하나도 없으면 검색하지 않고 "조건을 하나 이상 넣으세요"(전체 스캔 방지).
  - 파일명은 최신 리비전 기준이다. 이전 리비전 파일명·문서 내용은 AI-002 통합 검색으로 안내한다.
- BR-2: 결과 열: 프로젝트 번호·이름, 액티비티(WBS·이름), 산출물 번호·이름·유형, 상태(텍스트 + 아이콘), Rev, 파일명, 등록자, 등록일, 기한 D-day, 결재 상태(DLV-002 BR-7 일괄 조회, 현재 페이지 행만). 동작: 열기, 파일 미리보기(LatestContentDocumentId, filePreview), 액티비티로 이동.
- BR-3: 권한. 결과는 USER_MODE·with sharing이라 사용자가 볼 수 있는 프로젝트의 산출물만 나온다. 파일 미리보기는 산출물 레코드 연결(V0-1)로 같은 범위다.
- BR-4: 표준 양식 결정 `PMS_DeliverableTemplateService.templateFor(deliverableId)`(사용자 언어 기준).
  - (a) 표준 산출물(WBS-002)의 TemplateDocument가 있으면 그것(대상 객체는 CMN_DocTemplate__c 권고, Vol.P2 요청). 고객 그룹별 표준 WBS가 고객 양식을 가리킨다.
  - (b) 없으면 산출물 DocClass의 CMN_DocTemplate__c를 DOC-001 BR-7 순서(사용자 언어 → en_US → ko, 같은 언어는 최신 버전)로 `CMN_DocumentService.templatesFor` 1회 호출로 찾는다.
  - (c) 둘 다 없으면 "양식 미등록"과 PMO 문의 안내.
  - 내려받기는 양식 ContentDocument의 표준 다운로드 URL로 한다(CMN_DocTemplate__c는 사내 공개 읽기, 파일 공유는 DOC-001 구현을 따른다). 다운로드 시 양식 버전을 토스트로 알린다.
- BR-5: 양식 모음 "표준 양식" 탭(`pmsDeliverableSearch`의 두 번째 탭): 개발 단계(DEV_PHASE)·DocClass(`PMS_DLV`·PPAP 하위)·언어로 활성 CMN_DocTemplate__c 목록과 내려받기. 양식 추가·개정은 DOC-001 관리 화면(PMO).
- BR-6: 통합 검색 연계. CMN_SearchScope__mdt `PMS_Deliverable` 등록으로 AI-002 `cmnUnifiedSearch`의 레코드 검색에 산출물이 나온다. 산출물 문서(ParentObject PMS_Deliverable__c)는 AI-002 색인 파이프라인이 그대로 색인하고, 결과 권한은 AI-002 BR-2(부모 레코드 UserRecordAccess)로 거른다. 이 WI는 색인을 따로 만들지 않는다.

**화면/UX**: 화면 유형 T5(조회 목록) · 공통 부품 UX-007 메뉴 허브 등록. `cmnEditableGrid`는 쓰지 않는다(편집 없음, 표준 `lightning-datatable` 읽기 전용).
- `pmsDeliverableSearch`(제안): SL PMS 앱 페이지 "산출물 검색"(탭 "산출물 검색"·"표준 양식"), 프로젝트 레코드 "산출물" 탭(속성 projectId, 프로젝트 조건 숨김).
- 위쪽 조건 영역(접기), 아래 결과 표 50행 + "다음". 상태 텍스트·아이콘, 기한 경과는 텍스트로("기한 경과 n일").
- 액티비티 산출물 패널(DLV-001)과 산출물 레코드의 "양식 받기" 버튼이 BR-4를 부른다.
- 휴대폰: 조건은 프로젝트어·파일명 2개, 결과는 카드 목록.

**권한**: 조회 PMS_PS_Deliverable_Read. 양식 내려받기는 사내 사용자 전원(CMN_DocTemplate__c 공개 읽기).

**수용 기준**

- AC-1: Given 사용자가 CFT인 프로젝트 2개와 아닌 프로젝트 1개에 "PFMEA" 산출물, When 파일명 "PFMEA" 검색, Then 2개 프로젝트 산출물만.
- AC-2: Given 조건 없음, When 검색, Then 쿼리 없이 안내 문구.
- AC-3: Given 결과 120건, When 첫 화면, Then 50건 + "다음", 세 번째 페이지에서 20건.
- AC-4: Given 표준 산출물 TemplateDocument 없음, DocClass 양식 ko·en_US, 사용자 언어 zh_CN, When 양식 받기, Then en_US 양식.
- AC-5: Given 둘 다 없음, When 양식 받기, Then "양식 미등록" 안내, 오류 없음.
- AC-6: Given 통합 검색에 산출물 번호 입력, When 검색, Then 산출물 레코드가 결과에 나온다.
- AC-7: Given 프로젝트 탭, When 열기, Then 그 프로젝트 산출물만 등록일 내림차순, 3초 이내(산출물 600개 프로젝트).

**에이전트 주의**: CMN_DocumentRevision__c를 PMS 코드에서 직접 조회해 파일명 검색을 하지 않는다(문서는 Private이고 DOC-001 선택기만 예외로 읽는다, 사본 필드 LatestFileName을 쓴다). 동적 SOQL 문자열에 검색어를 이어 붙이지 않는다(바인드). SOSL 검색어는 특수문자를 이스케이프한다.

**오픈 이슈**: 이전 리비전 파일명까지 검색이 필요한지(필요하면 DOC-001에 파일명 검색 API 요청), 양식을 고객 그룹별로 둘 범위(BMW·HKMC 고유 양식 목록).

## 6. 검토 요청

Vol.P3는 **9개 워크아이템, 50 M/D**다. W1 6개(30 M/D)가 비용 계획·실적·권한과 산출물 등록·결재·검색의 기본 사이클이고, W2 3개(20 M/D)가 비용 분석·Excel, 디지털 스레드, 개정·영향도 분석이다. 계약 초안(44 M/D) 대비 CST-003(+1, 임율 엔진을 이 WI로 모음), CST-004(+2, Snowflake 뷰·CostRag 이벤트·Excel 왕복), DLV-001(+1, 시스템 링크 리졸버 구조), DLV-003(+1, Snowflake 계보 쿼리)을 늘렸다.

| WI | 제목 | Wave | 공수(M/D) |
| --- | --- | --- | --- |
| PMS-05-CST-001 | 비용 계획(예산 항목·ED&D 산정) | W1 | 6 |
| PMS-05-CST-002 | 비용 실적(ED&D 자동·출장비·금형비) | W1 | 6 |
| PMS-05-CST-003 | 직급 평균 임율·비용 권한 분리 | W1 | 4 |
| PMS-05-CST-004 | 비용 계획/실적 대시보드·Excel 가져오기/내보내기 | W2 | 7 |
| PMS-06-DLV-001 | 액티비티 산출물(유형 5종·일괄 등록) | W1 | 6 |
| PMS-06-DLV-002 | 산출물 결재(팀장 필수)·연계 데이터 동기화 | W1 | 5 |
| PMS-06-DLV-003 | 입력/출력 추적성(디지털 스레드) | W2 | 7 |
| PMS-06-DLV-004 | 산출물 개정·영향도 분석 | W2 | 6 |
| PMS-06-DLV-005 | 프로젝트 산출물 검색·표준 양식 내려받기 | W1 | 3 |

**결정이 필요한 항목**(자율 진행 지시에 따라 권고안으로 작성했다)

- [ ] DP3-1 비용 권한 범위 — PM·PMO·재무·경영진은 금액 조회, PM·재무는 편집, CFT·팀장은 비용 객체 권한 없음, 전체 포트폴리오는 PMO·재무·경영진만. 원가 역할(PROJECT_ROLE CST) CFT에게는 개인별로 PMS_PS_Cost_Read를 준다. 권고: 승인
- [ ] DP3-2 ED&D 공개 세분도 — 액티비티별(계획)·월별(실적) 금액과 시간을 Cost_Read 보유자에게 보이므로 혼자 맡은 액티비티에서 직급 임율을 역산할 수 있다. 임율 원문·직급별 분해는 재무만, Snowflake에는 임율을 복제하지 않는다. 권고: 역산 가능성 수용(직급 평균값이라 개인 급여가 아님)
- [ ] DP3-3 ED&D 실적 산정 기준 — 승인(APPROVED) 투입 실적만, 요일별 날짜로 월 귀속, 익월 5일 마감·동결, 지연 승인분은 열린 달 조정 행, 그 해 임율이 없으면 전년 임율 임시 적용. 권고: 승인
- [ ] DP3-4 미래 연도 임율 상승률 기본값(`PMS_LABOR_RATE_ESCALATION_PCT`) — 권고: 0%(재무 확인 후 설정)
- [ ] DP3-5 비용 범주 규칙 — Piece Price는 단가로 관리(합계 제외), Tooling에 투자 주체(자사·고객 지급·단가 상각) 표시, 예비비에는 실적을 붙이지 않고 "예비비 사용"으로 이전. 권고: 승인
- [ ] DP3-6 CostRag 산식·공개 — EAC 차이 5%(AMBER)·10%(RED), 진행 속도 15%(AMBER), 같은 환율로 기준선·EAC 환산, RAG는 프로젝트 조회자 전원에게 공개(금액 비공개). 권고: 승인
- [ ] DP3-7 산출물 결재 팀장 정의 — 기안자 소속 부서장(기안자가 부서장이면 상위 부서장), 기안자는 액티비티 주·보조 담당만. 권고: 승인
- [ ] DP3-8 필수 산출물 해당 없음(N/A) — PM이 사유만 입력(결재 없음), Gate 점검에서 N/A 건수를 따로 보인다. 권고: 승인
- [ ] DP3-9 승인본 품번 문서 게시 — FMEA·관리계획서·공정 흐름도·설계 기록 승인본을 프로젝트 품번 문서로 게시해 QMS Re-PPAP 증빙 수집기가 읽게 한다. 권고: 승인(전 품번)
- [ ] DP3-10 산출물 이벤트 `PMS_DeliverableEvent__e` 신설(계약 9절 변경) — 대안은 PMS_ActivityEvent__e에 DELIVERABLE_* 값 추가. 권고: 신설(Enterprise Scratch 교체 D-P8 전제)
- [ ] DP3-11 개정 중 완료 인정 — 새 판이 승인될 때까지 이전 승인본을 유효로 보고 액티비티를 자동 재시작하지 않는다. Gate 점검은 "개정 중" 표시만. 권고: 승인
- [ ] DP3-12 영향 항목 객체 `PMS_ImpactItem__c` 추가(계약의 AffectedJson은 분석 스냅숏으로 유지), 기본 분석 깊이 3. 권고: 승인
- [ ] DP3-13 요구사항 연결의 원본은 SOR-002 `PMS_RequirementLink__c`이고 DLV-003은 저장하지 않고 합쳐 보인다. 권고: 승인
- [ ] DP3-14 DeliverableType 값 `STANDARD_FORM`을 이미 배포된 CMN 값 `STD_FORM`으로 통일(계약 5절 변경). 승인 전까지는 DLV-001 BR-3의 값 대응으로 동작. 권고: 통일
- [ ] DP3-15 출장비 실적 원천 — W1은 수동 입력, SAP 경비·출장 시스템 연계는 SL 확인 후 PMS-12 신규 WI. 권고: 승인

**계약(`pms-architecture.md`) 변경 요청**

| 절 | 변경 내용 | 근거 |
| --- | --- | --- |
| 4 | 공수 CST-003 3→4, CST-004 5→7, DLV-001 5→6, DLV-003 6→7(Vol.P3 44→50 M/D) | 6절 머리말 |
| 5 | PMS_WbsTemplateDeliverable__c·PMS_Deliverable__c의 DeliverableType 값 STANDARD_FORM → STD_FORM | DP3-14 |
| 5 | PMS_Deliverable__c에 RecordNo `DLV-{YYYY}-{SEQ:6}`, IsSatisfied, IsAdHoc, 사본 필드(LatestFileName 등), DLV-002·004 필드 | DLV-001·002·004 데이터 모델 |
| 5 | PMS_ImpactAssessment__c에 RecordNo `IA-{YYYY}-{SEQ:5}`, Status 값(ANALYZED, IN_REVIEW, CONFIRMED, CLOSED, CANCELLED) | DLV-004 |
| 5 | 신규 객체 PMS_ImpactItem__c(MD ImpactAssessment) | DP3-12 |
| 5 | PMS_DeliverableTrace__c 필드 추가(From·ToSystemLinkType, Label, RevisionNo, IsStale, Source, UniqueKey), FromType·ToType 값(DELIVERABLE, ACTIVITY, SYSTEM) | DLV-003 |
| 5 | PMS_CostBudget__c·PMS_CostActual__c 필드 추가(SubCategory, Activity, ProjectPart, 기준선, 마감, ExternalKey 등), PMS_LaborRate__c에 Company·CurrencyIsoCode·ExternalKey 추가 | CST-001~003 |
| 5 | 다른 WI 객체에 이 Vol.이 더하는 필드: PMS_Activity__c 롤업 6개(DLV-001), PMS_Project__c.CostRagAsOf__c(CST-004) | DLV-001, CST-004 |
| 7 | 커스텀 메타데이터 PMS_SystemLinkType__mdt, PMS_DeliverableApprovalRule__mdt, PMS_DeliverablePublishRule__mdt | DLV-001·002 |
| 9 | 이벤트 PMS_DeliverableEvent__e(SUBMITTED, NOT_APPLICABLE, SYSTEM_STATUS_CHANGED, APPROVAL_SUBMITTED, APPROVED, REJECTED, REVISION_STARTED, REVISED) | DP3-10 |
| 10 | PS 추가: PMS_PS_Cost_Edit, PMS_PS_Cost_Portfolio, PMS_PS_LaborRate_Admin, PMS_PS_Cost_Integration, PMS_PS_Deliverable_Read·Edit·Manage. Custom Permission PMS_ViewCost 외 9개 | 3절 권한 셋 표 |

**Vol.0에 반영이 필요한 변경**(Vol.0 검토 시 함께 확인)

| ID | 대상 WI | 변경 내용 | 사용처 |
| --- | --- | --- | --- |
| V0-1 | CMN-00-DOC-001 | 문서 부모 리스너: 인터페이스 `CMN_DocumentListener`(deliverableTypeFor(parentId, docClassId) — 문서 생성 시 유형 결정, afterRevisionChange(revisions) — 리비전 생성·상태 변경 후 같은 트랜잭션), 메타데이터 `CMN_DocumentListener__mdt`(ParentObject, ListenerClass, ApprovalHandledByParent — 패널 문서 단위 상신 숨김·서버 거부, LinkFilesToParent — 파일을 부모 업무 레코드에도 ShareType I로 연결). 문서 리비전 조회(부모 Id 집합) 공개 메서드 | DLV-001 BR-3·BR-4, DLV-002 |
| V0-2 | CMN-00-DOC-001 | 다중 부모 등록 `registerFilesToParents(parentIds ≤ 20, docClassId, contentDocumentIds, changeNote)`: SOQL 수가 부모 수와 무관, 같은 호출 안 부모끼리 중복 경고 없음 | DLV-001 BR-7 |
| V0-3 | CMN-00-DOC-001 | 승인본 게시 `publishCopy(sourceRevisionId, targetParentId)`: RELEASED 리비전만, 대상 객체는 CMN 설정 `CMN_DOC_PUBLISH_TARGETS`(CMN_Item__c) 허용 목록, 즉시 RELEASED. 신규 필드 CMN_DocumentRevision__c.PublishedFromRevision__c(Lookup self) — 설정되면 해시 중복 경고 제외 | DLV-002 BR-5, DLV-004 |
| V0-4 | CMN-00-APV-001 | 일괄 결재 상태 `CMN_ApprovalService.getStatuses(Set<Id> targetIds)`(최대 200, SOQL 2회) | DLV-001 패널, DLV-002 BR-7, DLV-005 |
| V0-5 | CMN-00-APV-001 | BR-6 공유: Share 테이블이 없는 대상(Master-Detail 하위)은 `CMN_ApprovalType__mdt.ShareTargetPath__c`(예: `Activity__r.Project__c`)가 가리키는 레코드에 Read 공유. 경로가 없으면 WARN 로그 후 건너뜀(현재 구현은 하위 객체에서 예외) | DLV-002 BR-8 |
| V0-6 | CMN-00-APV-002 | DRAFTER_MANAGER 해석과 RequireDrafterManager 검사: 기안자가 부서장이면 상위 부서장으로 | DLV-002 BR-2 |
| V0-7 | CMN-00-MDM-007 | DOC_CLASS 값 `PMS_DLV` 하위(SOR_REVIEW, DESIGN_SPEC, DESIGN_REVIEW, DR_REPORT, FEASIBILITY, DRAWING_LINK(LINK_ONLY), BOM_LINK(LINK_ONLY), TEST_RESULT, IMDS, TOOLING_ORDER, PACKAGING_SPEC, TIMING_PLAN, CUSTOMER_APPROVAL, KICKOFF_APPROVAL, SYSTEM_RECORD, OTHER)와 `PMS_COST_TEMPLATE`. FMEA·관리계획서·공정 흐름도·설계 기록은 기존 PPAP 하위 코드를 같이 쓴다. 코드 그룹 PMS_COST_SUBCATEGORY(2레벨), PMS_DLV_REVISION_REASON. APPROVAL_ROLE 값 COST_CONTROLLER | CST-001·003, DLV-001·004 |
| V0-8 | CMN-00-SEC-001 | CMN_PSG_Executive에 PMS_PS_Cost_Read·PMS_PS_Cost_Portfolio·PMS_PS_Deliverable_Read 추가, 페르소나 표의 PMS PSG에 PMS_PSG_TeamLead·PMS_PSG_Finance 추가 | CST-003, DLV |
| V0-9 | Vol.0 3.3·sf-dev.md 6절 | SheetJS 정적 리소스 이름을 `cmnSheetJs`(force-app-cmn, cmnChartJs와 같은 규칙)로 고정. 먼저 구현하는 WI가 만든다 | CST-004, QMS-02-DVQ-009, Vol.5 |
| V0-10 | CMN-00-SEC-004, DWH-001·002 | Masking Policy `MP_PMS_COST`(PMS 비용 금액 열과 그 필드 이력 값: ROLE_FINANCE_READ·ROLE_SF_READER만 원문), PMS_LaborRate__c와 그 이력은 복제 제외 | CST-003 BR-8 |

**PMS 다른 Vol.에 요청**

| 대상 | 요청 |
| --- | --- |
| Vol.P1 PRJ-001 | PMS_Project__c.CostRag__c 쓰기 주체는 CST-004 핸들러, CostRagAsOf__c 추가 수용, 레코드 페이지 정의에 "비용"(UX-005 PMS_CostTab)·"산출물"·"디지털 스레드" 탭 자리, PMS PSG 생성 시 3절 PS 구성 |
| Vol.P1 PRJ-002 | PMS_ProjectPart__c.IsLeadPart·Item 필드(DLV-002 품번 게시 대상) |
| Vol.P1 CFT-001 | CftMember에 Employee 연결 필수(ED&D 직급·법인), 프로젝트 공유는 결재자 프로젝트 Read(APV V0-5)와 공존 |
| Vol.P1 EFF-001·002 | PMS_EffortPlan__c·PMS_EffortActual__c DWH-002 복제 등록(시간만), 실적 Status APPROVED 의미 고정 |
| Vol.P1 SOR-002 | PMS_RequirementLink__c.TargetType 값에 DELIVERABLE·ACTIVITY·SYSTEM(+SystemLinkType) 포함, 관계 값(VERIFIES·DERIVED_FROM)을 두면 DLV-003이 그대로 쓴다 |
| Vol.P2 WBS-002 | DeliverableType STD_FORM, TemplateDocument → Lookup(CMN_DocTemplate__c), SystemLinkType = PMS_SystemLinkType__mdt 키, InputDeliverableCodes__c(Text 255) 추가, 유형별 ApprovalRequired 규칙(APPROVAL ⇒ true, LINK·SYSTEM_LINK ⇒ false) |
| Vol.P2 WBS-003, ACT-002, ACT-003 | 액티비티 생성·추가·복사 마지막 단계에서 `PMS_DeliverableService.syncFromTemplate` 호출 |
| Vol.P2 ACT-001 | 액티비티 레코드 현재 단계 탭에 `pmsDeliverablePanel`, 롤업 필드 6개 수용 |
| Vol.P2 ACT-004 | 완료 조건 RuleKey `PMS_DLV_MANDATORY_DONE`(PMS_DeliverableCompletionChecker) 등록, 롤업 변화 시 자동 종료 판단 |
| Vol.P2 WBS-007 | P-44 산출물 완료율 = PMS_Activity__c.DlvCompletionPct__c |
| Vol.P4 GAT-003 | 산출물 자동 점검은 `PMS_DeliverableQueryService.byCodes`, EvidenceDeliverableIds 형식은 쉼표 구분 Id(DLV-004가 검색) |
| Vol.P4 GAT-005 | AnomalyStatus__c 값 쓰기, LatestRevisionDuplicate__c 사용, PublishedFromRevision이 있는 리비전은 복사 문서로 보지 않음 |
| Vol.P5 DSH-002·003, AIP-004 | 비용 표시 전 `PMS_CostAccess` 확인, 포트폴리오는 `PMS_CST_PORTFOLIO`, 산출물 KPI 3종 뷰 구현·위젯 |
| Vol.P5 AIP-002 | 산출물 레코드 레일 AI 패널(UseCase PMS_DELIVERABLE_DRAFT) 활성화 |
| Vol.P6 APV-001 | PROJECT_ROLE 해석 메서드 공개(DLV-002 기여자가 호출) |
| Vol.P6 INT-002 | PMS_LaborRate__c upsert(ExternalKey `{CompanyCode}-{JobGradeCode}-{Year}`, Source HR) |
| Vol.P6 INT-003 | DMS → PMS_CostActual__c 수신 계약(CST-002 BR-6), 산출물 이벤트 구독(금형 관련 DocClass) |
| Vol.P6 INT-004 | PDM_DRAWING·PDM_BOM 리졸버 구현·유형 교체, MART.V_PMS_TRACE_EDGE와 같은 키 규칙 |
| Vol.P6 INT-005 | QMS_QUAL_PLAN·QMS_PPAP 등 SYSTEM_LINK 유형·리졸버 등록, QMS 이벤트 수신 시 `applySystemStatus` 호출, 산출물 이벤트 구독 |
| Vol.P6 CHG-001 | 비용 변경 승인 시 `PMS_CostPlanService.confirmBaseline` 호출(재확정) |

**QMS Vol. 변경**

| 대상 | 내용 |
| --- | --- |
| Vol.4 RPP-002 | 변경 없음(확인 요청). QMS_DocumentCollector의 가정 "관리계획서·FMEA·공정 흐름도는 품번 레코드에 DocClass로 등록"을 DLV-002 품번 게시가 채운다. DocClass는 PPAP 하위 코드를 같이 쓴다 |
| Vol.2 DVQ-005 | 변경 없음. SYSTEM_LINK QMS_QUAL_PLAN 충족 규칙(Status CLOSED + FinalResult PASS, CONDITIONAL 포함 여부는 D2-4 결과)을 INT-005가 등록 |
| Vol.9 | CORE.SAP_FX_RATE 소비자에 CST-004 추가(정의 변경 없음) |

**SL 확인이 필요한 사실 정보**: HR 임율 제공 형태(직급 평균·법인별·갱신 주기)와 직급 코드 체계, DMS 금액 기준(발주·검수·지급)과 프로젝트 대응 키, 출장비 원천 시스템, 재무 월 마감일과 보고 통화·환율 기준, 현행 비용 Excel 양식, 신제품개발 표준 산출물 목록·양식과 결재 필요 산출물(회사표준 개정 결과), "팀장"의 정의, PDM 도면 링크 형식·API, IMDS 처리 방식, 대용량 문서 저장소(SharePoint, D-7).

**다음 순서**: 검토 결과를 반영해 `pms-architecture.md`(4·5·7·9·10절)와 `interfaces.md` PMS 절을 갱신하고, Vol.P2(일정·액티비티)의 WBS-002·ACT-004 정의와 이 Vol.의 연결점을 맞춘다. 승인분은 마스터 워크아이템 xlsx로 옮긴다.
