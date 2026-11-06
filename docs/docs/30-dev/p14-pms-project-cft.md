# P14 PMS 기준·프로젝트 착수·CFT

PMS 트랙의 첫 페이즈다. 업무 순서는 "PMO가 표준 WBS를 준비 → 수주 확정 프로젝트 등록 → 품번·고객 마일스톤 → CFT 구성·보안서약 → 고객 요구사항(SOR) 기준선"이다. 이 페이즈가 끝나면 프로젝트 하나가 사람·권한·요구사항까지 갖춘 상태가 되고, P15에서 실행 WBS를 만들 수 있다. 명세는 [Vol.P1](../10-workitems/volp1-pms02-03-project-resource.md)·[Vol.P2](../10-workitems/volp2-pms04-07-schedule-activity.md)·[Vol.P6](../10-workitems/volp6-pms12-13-integration-performance.md), 계약은 [pms-architecture.md](../10-workitems/pms-architecture.md)다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | 표준 WBS 템플릿 등록·활성화, 프로젝트 등록(유형·수명주기·표준 WBS 추천)·품번·고객 마일스톤, CFT 구성과 보안서약 전 접근 차단, PROJECT_ROLE 결재선, SOR 등록·기준선 결재가 Scratch Org에서 동작 |
| 기간(기본 인원) | 누적 약 70영업일(PMS 팀 3명, 기반 P3 종료 후 약 17일). [개발 플랜](dev-plan.md) 9.2절 |
| 마일스톤 | 표준 WBS → 프로젝트 생성 → CFT 승인·보안서약 → SOR 기준선 |
| 착수 조건 | 기반 P2 `개발 완료`(PMS 트랙 첫 페이즈는 P3 진행 중 당겨 착수 가능, [개발 플랜](dev-plan.md) 4.1절). 같은 Org PMS·QMS(D-1·D-P9) |
| 다음 페이즈로 당겨 착수 가능 | P15 중 ACT-001(WBS-001·002, PRJ-001, CFT-001 뒤) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 9건 · 46 M/D · W1 9 · SF 트랙 9건 · 외부 트랙 0건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | PMS-04-WBS-001 | 표준 WBS 템플릿·버전·필수 액티비티 | W1 | 7 | SF | — | PMO 기준정보라 프로젝트보다 먼저. PROJECT_ROLE·CUSTOMER_MILESTONE 코드 그룹은 MDM-007 데이터로 먼저 적재(그룹 규칙 소유는 CFT-001·PRJ-003) — 순환 해소 CR-13 |
| A2 | PMS-04-WBS-002 | 표준 WBS 산출물·완료 조건 정의 | W1 | 5 | SF | WBS-001 | — |
| B1 | PMS-02-PRJ-001 | 프로젝트 기준정보·유형·수명주기(수주·SOP·EOP·연식) | W1 | 6 | SF | PMS-04-WBS-001 | 플랫폼 이벤트 PMS_ProjectEvent__e(Enterprise Scratch, D-P8 적용) |
| B2 | PMS-02-PRJ-002 | 프로젝트 품번·사양 구성(개발처·생산처) | W1 | 3 | SF | PRJ-001 | — |
| B3 | PMS-02-PRJ-003 | 고객 마일스톤·액티비티 매핑 | W1 | 4 | SF | PMS-04-WBS-001, PRJ-001 | — |
| C1 | PMS-03-CFT-001 | CFT 구성·프로젝트 역할·여유율 조회 | W1 | 7 | SF | PMS-02-PRJ-001 | — |
| C2 | PMS-03-CFT-003 | 보안서약서 관리(TISAX) | W1 | 4 | SF | CFT-001 | — |
| C3 | PMS-12-APV-001 | 프로젝트 역할(PROJECT_ROLE) 결재선 해석 | W1 | 4 | SF | PMS-03-CFT-001 | PROJECT_ROLE 결재선 해석 — SOR·CFT·산출물·Gate 결재가 쓰므로 먼저. APV-002 플러그인 변경 요청 함께 |
| C4 | PMS-02-SOR-001 | 고객 요구사항(SOR) 등록·버전 | W1 | 6 | SF | PRJ-001, PMS-03-CFT-001, PMS-12-APV-001 | — |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

### 레인 A — 표준 WBS(WBS-001 → WBS-002)

PMO 기준정보라 프로젝트보다 먼저 만든다. 프로젝트 등록(PRJ-001)의 표준 WBS 추천과 P15 실행 WBS 생성이 이것을 읽는다.

1. **WBS-001**: `PMS_WbsTemplate__c`·`PMS_WbsTemplateActivity__c`(레벨·선후행 4종·기간·DEV_PHASE·DEV_ACTIVITY_TYPE·주관 역할·앵커 마일스톤), 버전(DRAFT → ACTIVE, 개정 시 새 버전), 필수 액티비티 보호, 활성화 검사(순환·앵커 코드·액티비티 수 상한). 그리드는 UX-006. **순환 해소(CR-13)**: PROJECT_ROLE·CUSTOMER_MILESTONE 코드 그룹은 MDM-007 코드 데이터로 먼저 적재한다. 그룹 규칙(검증)의 소유는 CFT-001·PRJ-003 그대로다.
2. **WBS-002**: 표준 산출물·완료 조건 정의(DeliverableType 값은 `STD_FORM`으로 통일 — DP3-14, 유형별 ApprovalRequired 규칙), 완료 조건 규칙 키 등록부. Vol.P3 요청(`InputDeliverableCodes__c`, TemplateDocument → `CMN_DocTemplate__c`)을 함께 반영한다.

### 레인 B — 프로젝트(PRJ-001 → PRJ-002, PRJ-003)

1. **PRJ-001**: `PMS_Project__c`(유형·수명주기·고객·차종·제품군·개발처/생산처 공장), 등록 화면 `pmsProjectCreate`(3단계), 상태 전이와 `PMS_ProjectEvent__e`(Enterprise Scratch — D-P8 적용 완료), 표준 WBS 추천 `PMS_WbsTemplateRecommender`, 프로젝트 공유 모델(DP1-1: 공장 그룹 Read, CFT Apex 공유 Edit). 레코드 페이지는 UX-004 생성기 + 탭 예외(DP1-15). Vol.P3·P5가 요청한 필드(`CostRag__c`·`CostRagAsOf__c`, Q 상태 3개)를 데이터 모델에 함께 둔다.
2. **PRJ-002**: 프로젝트 품번·사양(가품번 → SAP 품번 연결, IsLeadPart, 생산 공장). QMS 인정시험·초기유동 요청과 레슨런 매칭의 기준 목록이다.
3. **PRJ-003**: `PMS_CustomerMilestone__c`(프로젝트 생성 시 자동 생성, 그리드), SOP 단일 원천 동기화(DP1-11), 날짜 변경 통제·이력·이벤트(MILESTONE_CHANGED, 제안). `Activity__c` Lookup 필드는 P15 WBS-003이 만든다(Vol.P1 계약 변경 요청 6).

### 레인 C — CFT·결재선·요구사항(CFT-001 → CFT-003, APV-001 → SOR-001)

1. **CFT-001**: `PMS_CftMember__c`(역할·권한, Employee 연결 필수), 조직도 후보 검색·여유율(계획은 P15 EFF-001 뒤에 채워짐 — 지금은 참여 프로젝트 수만), 역할 → 사람 해석 서비스, ACTIVE 구성원만 프로젝트 공유. CFT 상태에 DRAFT 추가(DP1-16).
2. **CFT-003**: 보안서약서(프로젝트별, 고객 그룹별 양식, 서명자 소유·프로젝트 Lookup — DP1-3·4). 서약 전에는 프로젝트 데이터 접근 차단(DP1-2).
3. **PMS-12-APV-001**: PROJECT_ROLE 결재선 해석. **Vol.0 변경 요청 선반영**: APV-002 결재선 해석기 플러그인(PROJECT_ROLE), 템플릿 변형 키, 공장 필드 경로(현재 `Plant__c`만 읽음). SOR·CFT·산출물·Gate 결재가 모두 이것을 쓰므로 레인 C에서 가장 먼저 끝낸다.
4. **SOR-001**: 요구사항 단위 등록·버전(버전당 1행 + 기준선 결재 객체, DP1-9), 타당성·준수 회신, 품질·설계 합의, 팀장 승인.

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| 에디션 | Enterprise Scratch(`config/project-scratch-def.json`) | 플랫폼 이벤트 한도 50(D-P8 적용, 2026-11-06) |
| SL PMS 앱·PSG | `PMS_PSG_PM`·`CFT`·`TeamLead`·`PMO`·`Finance`, `SL_PMS` 앱(SEC-001 BR-4) | PSG 배포 충돌은 HEAD와 비교 후 `--ignore-conflicts` |
| 코드 그룹 | DEV_PHASE·DEV_ACTIVITY_TYPE(Vol.4 LEL 소유, 데이터), PROJECT_ROLE, CUSTOMER_MILESTONE, PMS 코드(Vol.P1 3절) | 코드 데이터 CSV로 먼저 적재(CR-13) |
| 결재 유형 | PMS_CFT_ASSIGN, SOR 기준선, PROJECT_ROLE 해석 | APV-001 하위 객체 공유 변경 요청(V0-5·TargetShareMode) 반영 여부 확인 |
| 데모 사용자 | PM·CFT·팀장·PMO 페르소나(내부 사용자 4명 한도 — 검토 페르소나와 겹침) | [화면 우선 플랜](screen-first-plan.md) 4.6절 |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| HR 임직원·조직(CMN-00-INT-002) | 기준정보 데모(임직원·부서) |
| 투입 계획(P15 EFF-001) | CFT 후보 여유율은 참여 프로젝트 수만 표시, 여유율 그래프는 P15 뒤 확인 |
| 실행 WBS(P15) | 표준 WBS 추천·앵커 점검만 확인(PRJ-003 AC-6은 표준 WBS 앵커 기준) |
| 보안서약 전자서명 | 체크·동의 기록(종이 서약은 PDF 업로드 + PM 확인, DP1-4) |

## 6. 데모 데이터

**공백**: 데모 데이터(`data/demo`)에 PMS 객체가 없다. S6 시나리오는 PMS 프로젝트·액티비티를 텍스트 Id로만 가리킨다. P14 착수 전에 **PMS 데모 데이터 세트(데이터 작업 요청 DD-P1)**를 만든다.

| 세트 | 내용(최소) | 쓰는 페이즈 |
| --- | --- | --- |
| 표준 WBS | 2종(헤드램프 신차종 약 120 액티비티, 연식 변경 약 40 액티비티), 산출물·완료 조건, Gate 마일스톤 G0~G9 | P14~P17 |
| 프로젝트 | 3건(BMW 신차종 진행 중 DESIGN, HKMC F/L 진행 중 PV, 종료 1건 SOP+2개월), 품번·사양, 고객 마일스톤 | P14~P20 |
| CFT·서약 | 프로젝트별 8~12명, 서약 완료·미완료 혼합 | P14·P16 |
| SOR | 프로젝트별 30~50 요구사항, 기준선 2판(개정 차이 포함) | P14·P18 |
| 성능 데이터(별도 생성기) | 프로젝트 200 × 액티비티 600(CPM 성능, P15 G15-5) | P15 |

S6 레슨런 시나리오의 텍스트 Id(`scenario_keys.json` s6Project)는 이 세트의 실제 레코드로 바꾼다. 라이선스 문구(VDA 등)는 데모에 넣지 않는다.

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G14-1 | 새 Org 배포·테스트·P14까지 적재 | dev-plan 6.4절 | 실패 0 |
| G14-2 | 표준 WBS 활성화(순환·앵커 오류 차단), 새 버전 개정 | WBS-001 AC | 오류 메시지·버전 이력 |
| G14-3 | 프로젝트 등록 → 표준 WBS 추천 1순위 → 착수 검사 | PRJ-001 AC, PRJ-003 AC-6 | 추천·앵커 누락 차단 |
| G14-4 | 품번 가품번 등록 → SAP 품번 연결 | PRJ-002 AC | 연결 이력 |
| G14-5 | CFT 구성 → 서약 전 접근 차단 → 서약 → ACTIVE 접근 | CFT-001·003 AC, DP1-2 | 공유 행 생성·삭제 |
| G14-6 | PROJECT_ROLE 결재선(PM·QE·팀장) 해석 | PMS-12-APV-001 AC | 결재 단계 사람 해석, 공장별 템플릿 |
| G14-7 | SOR 등록 → 기준선 결재 → 개정판 차이 | SOR-001 AC | 기준선 1·2, 변경 요구 표시 |
| G14-8 | 회귀: 기반 P0~P3 게이트 요약 | 6.4절 | 통과 |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D-P1(단계·Gate 모델), D-P9(같은 Org), DP1-1~5, DP1-9·11·12·13·15·16, DP2-13(표준 WBS 개정), DP6-10(PROJECT_ROLE 해석 규칙) |
| 명세 | CR-13 WBS-001 선행에서 PRJ-003·CFT-001 제거(코드 데이터 선적재) |
| 명세 | Vol.P1~P3 계약 정합: `StartDate__c`, PRJ 상태 전이(PLANNING → IN_PROGRESS는 WBS-005 일정 확정 시 — Vol.P1 요청, Vol.P2 미반영), DeliverableType `STD_FORM`(DP3-14) |
| Vol.0 변경 | APV-001 Master-Detail 대상 공유(V0-5, TargetShareMode), APV-002 PROJECT_ROLE 플러그인·공장 경로, MDM-007 코드 그룹 추가, SEC-001 PMS PSG 페르소나 |
| 데이터 | DD-P1 PMS 데모 데이터 세트(6절) |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| 결재 엔진이 Master-Detail 하위 대상에서 예외(Vol.P1·P3이 같이 발견) | P14 착수 전 Vol.0 변경 요청(V0-5)을 APV-001 보완 PR로 먼저 머지 |
| 코드 그룹 소유가 Vol.4(LEL)·Vol.P1·P2에 흩어져 순환 | 코드 데이터 선적재(CR-13), 그룹 규칙은 소유 WI가 추가 |
| 프로젝트 공유(CFT Apex 공유)와 공장 격리(SEC-002)의 충돌 | DP1-1 권고(공장 그룹 Read + CFT Edit), 권한 비교 테스트(PM·CFT·다른 공장) |
| 내부 사용자 라이선스 4명 | 페르소나 겸용, 나머지는 관리자 + runAs 테스트로 확인 |

## 10. 게이트 기록

| 일자 | Org | 결과 | 비고 |
| --- | --- | --- | --- |
