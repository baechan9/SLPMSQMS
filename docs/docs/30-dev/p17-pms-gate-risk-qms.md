# P17 PMS Gate·리스크·문제점·QMS 접점

단계 관문(Gate) 평가와 결재, 리스크 로그·문제점 대책서, 그리고 PMS ↔ QMS 디지털 스레드(레슨런·인정시험·초기유동·클레임·NCR)를 만든다. SOP Gate 통과 → QMS 초기유동 생성으로 개발에서 양산으로 넘어가는 끝점이 여기다. QMS 트랙 WI와의 트랙 간 선행이 가장 많은 페이즈이므로 [개발 플랜](dev-plan.md) 4.3절 표와 함께 본다. 명세는 [Vol.P4](../10-workitems/volp4-pms08-09-risk-gate.md)·[Vol.P6](../10-workitems/volp6-pms12-13-integration-performance.md)이다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | Gate 정의·일정 → 평가표 판(질문지 템플릿 GATE) 스냅숏 → 자동 점검 + 체크리스트 → RAG → 결재(통과·조건부·실패) → 후속 조치, SOP Gate → QMS 초기유동 요청, 리스크(P×I)·문제점(대책서 결재), QMS 이벤트 구독·게이트웨이 호출(연결 대장) |
| 기간(기본 인원) | 누적 약 156영업일(P16 이후. W2 ISS-002·RSK-002가 QMS 트랙 레슨런 P7을 기다리는 구간 포함, W1 Gate는 그 전에 끝남) |
| 마일스톤 | Gate 평가·결재(PoC 시나리오 5), SOP 이관 → QMS 초기유동(기본 구현 To-Do → EFC 바인딩) |
| 착수 조건 | P16 ACT-004·DLV-002, 기반 QNR-001·UX-009·MTG-001. QMS: DVQ-005·007(P4 — 게이트웨이 프레임워크), CLM-007·NCR-001(P5 — 이벤트 정의), LEL-005(P7 — `QMS_LeleApplicationEvent__e`) |
| 다음 페이즈로 당겨 착수 가능 | P18 중 DSH-004(MTG-001 뒤), DSH-001(대시보드 공용 라이브러리는 기반 P3) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 11건 · 57 M/D · W1 9 · W2 2 · SF 트랙 11건 · 외부 트랙 0건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | PMS-09-GAT-001 | Gate 정의·프로젝트 Gate 일정(마일스톤 통합) | W1 | 5 | SF | — | — |
| A2 | PMS-09-GAT-002 | Gate 평가표 템플릿(CMN 질문지 GATE)·판 관리 | W1 | 5 | SF | GAT-001 | — |
| A3 | PMS-09-GAT-003 | Gate 평가 수행(체크리스트·산출물 자동 점검·RAG) | W1 | 7 | SF | PMS-08-RSK-001, GAT-001, PMS-08-ISS-001, GAT-002 | — |
| A4 | PMS-09-GAT-004 | Gate 결재·조건부 통과·후속 조치 | W1 | 5 | SF | PMS-08-RSK-001, PMS-08-ISS-001, GAT-003 | — |
| A5 | PMS-09-GAT-006 | 양산 이관 Gate(SOP)와 QMS 초기유동·레슨런 연결 | W1 | 4 | SF | PMS-12-INT-005, GAT-004 | 초기유동 요청은 INT-005 requestEarlyProductionContainment(게이트웨이 STABILIZATION)로 한다 — QMS 클래스 직접 호출 제거(CR-14). EFC-001(P8) 바인딩 전에는 기본 구현(담당자 To-Do). EFC-001 실연결과 레슨런 후보 일괄 보내기(ISS-002)는 연결 확인 L-2 |
| B1 | PMS-08-RSK-001 | 리스크 로그(정량 평가·주/월 검토·에스컬레이션) | W1 | 6 | SF | — | — |
| B2 | PMS-08-ISS-001 | 문제점 등록·대책서·승인·종결 | W1 | 6 | SF | RSK-001 | — |
| B3 | PMS-08-RSK-003 | 리스크·문제점 현황 대시보드 | W1 | 3 | SF + DW 목 | RSK-001, ISS-001 | — |
| C1 | PMS-12-INT-005 | QMS 디지털 스레드(같은 Org: 레슨런·인정시험·초기유동·클레임) | W1 | 7 | SF | — | PMS ↔ QMS 디지털 스레드 기반(연결 대장·게이트웨이 바인딩 키) / QMS 선행: QMS-06-NCR-001(P5)·QMS-02-DVQ-005(P4)·QMS-02-DVQ-007(P4)·QMS-05-CLM-007(P5)·QMS-04-LEL-005(P7) |
| C2 | PMS-08-ISS-002 | 문제점 ↔ QMS 6pi/8D·품질 이력 연계 | W2 | 5 | SF | RSK-001, ISS-001, PMS-12-INT-005 | QMS 선행: QMS-06-NCR-001(P5)·QMS-04-LEL-002(P5)·QMS-05-CLM-001(P5)·QMS-05-CLM-007(P5)·QMS-06-NCR-002(P5)·QMS-04-LEL-004(P7) / 앞당김: PMS-09-GAT-006의 선행 |
| C3 | PMS-08-RSK-002 | 리스크 경감 대책 ↔ QMS 선행 품질 점검 추적 | W2 | 4 | SF | RSK-001, ISS-002 | QMS 선행: QMS-04-LEL-004(P7)·QMS-04-LEL-005(P7) |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

### 레인 A — Gate(GAT-001 → 002 → 003 → 004 → 006)

1. **GAT-001**: `PMS_GateDefinition__c`(G0~G9, 단계, 평가표 Family, 고객 그룹 행 덮어쓰기 — D-P1 데이터로 받음), 프로젝트 Gate 일정(WBS Gate 마일스톤에서 생성), 마일스톤-Gate 통합 표시.
2. **GAT-002**: 평가표 템플릿 = CMN-00-QNR-001 Domain GATE(판·발효일·문항 대응). 고객 Gate 점검표는 별도 섹션(DP4-2). RAG 계산기 `PMS_GateRagScorer`(점수 구간 + 필수 미충족 → RED, DP4-3)를 여기 둔다. QNR-001 변경 요청(템플릿 활성화 검증 훅)을 함께 반영.
3. **GAT-003**: 평가 시작 시 판 스냅숏(DP4-1), 자동 점검(`PMS_GateCheckRule__mdt` — 산출물·액티비티·QMS 조건·리스크·문제점 규칙 키, 산출물은 `PMS_DeliverableQueryService.byCodes`), UX-009 체크리스트 셸 + PMS Provider. UX-009 변경 요청(자동 점검 결과 필드)을 반영.
4. **GAT-004**: 결정 결재(DP4-11 결재선, 완화 결정은 사유 + 사업부장 승인, RED → PASS 차단 — DP4-4), 조건부 통과 후속 조치(공통 조치 항목·To-Do), 실패 시 재심사 회차. 결정 확장점 `PMS_GateDecisionExtension`.
5. **GAT-006**: SOP Gate — 미결 문제점·리스크 처리 방향 일괄 입력, 통과 시 초기유동 요청. **CR-14**: 명세 BR-3의 `QMS_StabilizationService.createFromSource` 직접 호출을 INT-005 `requestEarlyProductionContainment`(게이트웨이 STABILIZATION)로 바꾼다. EFC-001(QMS P8, W2) 바인딩 전에는 게이트웨이 기본 구현(QE 담당 To-Do "초기유동 계획 수동 생성")으로 동작하고, EFC 실연결과 레슨런 후보 일괄 보내기(ISS-002)는 연결 확인 L-2다. 초기유동 대상은 FG·SFG 전 품번(DP4-9).

### 레인 B — 리스크·문제점(RSK-001 → ISS-001 → RSK-003)

1. **RSK-001**: 리스크 로그(P×I, FMEA AP=H 최소 등급 — DP4-5, 설정값), 주·월 재평가 이력, High 리스크 2단계 에스컬레이션(DP4-6).
2. **ISS-001**: 문제점 등록 → 접수 → 대책서 → 승인 → 종결(결재), 리스크 ↔ 문제점 연결.
3. **RSK-003**: 리스크·문제점 현황 위젯(공용 라이브러리 — 기반 P3로 당긴 QMS-07-DSH-001~004 사용).

### 레인 C — QMS 접점(INT-005 → ISS-002 → RSK-002)

1. **INT-005**: 연결 대장 `PMS_SystemLink__c`·핸들러 등록부·코드 맵(DP6-1, P20 외부 연계가 재사용). QMS 호출은 게이트웨이만(DP6-2 — 바인딩 키 QUALIFICATION·LELE_PROJECT·STABILIZATION·LESSON_LEARNED, 반대 방향 PMS_PROJECT). 구독: `QMS_QualPlanEvent__e`(이미 배포), `QMS_ClaimEvent__e`·`QMS_NcrEvent__e`(QMS P5), `QMS_LeleApplicationEvent__e`(QMS P7 LEL-005). 일정 확정 SCHEDULE_CONFIRMED 구독 → 레슨런 추천(액티비티 50개 단위 Queueable). P16 ACT-004의 QMS 조건 키 구현체를 여기서 등록한다.
2. **ISS-002**(W2지만 QMS 접점이라 여기): 문제점 ↔ QMS 8D/6pi 단일화(DP4-8), QMS 이벤트로 문제점 자동 생성(DP4-7), 레슨런 후보 → LESSON_LEARNED 게이트웨이. Vol.9 INT-021 BR-6 값 정정(sourceType DEV_ISSUE — Vol.P4 변경 요청).
3. **RSK-002**(W2): 리스크 경감 대책 ↔ QMS 레슨런 체크포인트 반영 추적.

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| 게이트웨이 바인딩 | `QMS_GatewayBinding__mdt` 행: QUALIFICATION·LELE_PROJECT·STABILIZATION(QMS 소유 WI가 등록), PMS_PROJECT(INT-005가 등록) | QMS 쪽 미배포 바인딩은 기본 구현 |
| 기능 스위치 | `PMS_SOP_EFC_ENABLED`(GAT-006 BR-3) — CR-14 적용 후 게이트웨이 바인딩 유무로 대체 가능 | |
| 질문지 | Domain GATE 템플릿 1판(데모 — 회사표준 원문 금지, 가상 문항) | QNR-001 |
| 이벤트 | `PMS_GateEvent__e`, `PMS_IssueEvent__e` | |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| QMS 초기유동 EFC-001(P8, W2) | STABILIZATION 기본 구현(To-Do) — L-2 |
| QMS 레슨런 LEL-005(P7) | 착수 조건(구독 이벤트 정의가 필요). 늦으면 INT-005 레슨런 구독 부분만 분리(선택, dev-plan 4.3절) |
| 고객 Gate 점검표 원문 | 가상 문항 |
| AI 이상 징후(P19 GAT-005) | 해당 없음(W2) |

## 6. 데모 데이터

DD-P1 세트에 Gate 정의 G0~G9, 평가표 1판(가상 문항 30개), 진행 중 프로젝트의 Gate 2회차(PASS·CONDITIONAL), 리스크 15건(High 2), 문제점 10건(QMS 클레임 연결 1건 — S2 클레임 데이터와 품번 맞춤)을 더한다.

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G17-1 | 새 Org 배포·테스트·P17까지 적재 | 6.4절 | 실패 0 |
| G17-2 | Gate 평가 시작 → 판 스냅숏 → 자동 점검 → 체크리스트 → RAG(PoC 시나리오 5) | GAT-002·003 AC | 필수 미충족 RED |
| G17-3 | 결정 결재: 조건부 통과 → 후속 조치, 완화 결정 사업부장 단계, RED → PASS 차단 | GAT-004 AC | |
| G17-4 | SOP Gate 통과(EFC 미배포) → QE To-Do | GAT-006 AC(CR-14 반영) | To-Do 1건, 대장 MANUAL |
| G17-5 | 리스크 P×I·에스컬레이션, 문제점 대책서 결재 | RSK-001, ISS-001 AC | |
| G17-6 | 일정 확정 → 레슨런 추천 요청(게이트웨이), 인정시험 판정 이벤트 → 연결 대장·완료 조건 | INT-005 AC | |
| G17-7 | QMS 클레임 이벤트 → 문제점 자동 생성 → 8D 상태 추종 | ISS-002 AC | |
| G17-8 | 회귀: P14~P16 게이트 요약 | 6.4절 | 통과 |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D-P6(Gate 평가표 판 관리), DP4-1~9·11, DP6-1·2, D2-4(CONDITIONAL — DP2-8과 연결) |
| 명세 | CR-14 GAT-006 초기유동 요청 경로(INT-005 게이트웨이), 선행 EFC-001·PIS-001 → INT-005 |
| 명세 | QMS 쪽 확인: LEL-002·NCR-002·EFC-001 호출 값, INT-021 BR-6 sourceType(Vol.P4 9절) |
| Vol.0 변경 | QNR-001 활성화 검증 훅, UX-009 자동 점검 필드, AI UseCase PMS_DOC_ANOMALY(P19), APV 역할 PMO_MANAGER·BU_HEAD |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| QMS 트랙 지연(LEL-005·이벤트 정의)으로 INT-005가 막힘 | 4.3절 대기 표 매주 확인. 필요하면 INT-005를 -a(대장·게이트웨이·판정 구독)/-b(레슨런·클레임 구독)로 분할 |
| 같은 Org 전제(D-1) 변경 | 다른 Org면 Vol.9 INT-021 경로(D-P9) — 게이트웨이 구현체만 교체 |
| 회사표준 Gate 개정(26.11~27.04) | 평가표·Gate 정의를 데이터로(D-P1·D-P6), 진행 중 Gate는 스냅숏 유지 |

## 10. 게이트 기록

| 일자 | Org | 결과 | 비고 |
| --- | --- | --- | --- |
