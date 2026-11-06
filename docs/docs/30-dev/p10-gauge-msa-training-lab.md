# P10 측정기·MSA·교육·분석실·한도견본

Vol.6b 전체(측정기 GAU, MSA, 교육·자격 TRN, 분석실 LAB, 한도견본 LMS)와 측정기·신뢰성 시스템 연계의 Salesforce 쪽을 만든다. 모두 W2지만 앞 페이즈가 남겨 둔 연결점 — 검사 훅(측정기·검사원), 바인딩 LAB_REQUEST·AUDITOR_QUALIFICATION, 심사 증빙 제공자, PPAP MSA 증빙 수집기 — 이 여기서 실제 구현으로 채워진다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | 측정기 등록 → 교정 → 사용 통제·검사 훅 → 교정 불합격 영향 분석, MSA 계획 → 측정 입력 → 계산(목 응답) → 승인, 교육 → 이수 → 자격 → 검사원 훅·심사원 배정, 분석 의뢰 → 실행 → 보고서, 한도견본 등록 → 실물 관리 → 검사 화면 연결이 동작 |
| 기간(기본 인원) | 누적 227영업일(P9 이후 약 13일, 대부분 P9와 겹쳐 진행). QMS 4명·PMS 3명 시뮬레이션(2026-11-06, [개발 플랜](dev-plan.md) 9.2절) |
| 마일스톤 | S8 MSA, S12 교정 불합격, S2 분석 의뢰(`S2-LAB`) |
| 착수 조건 | P9 IAU-005(GAU-004·TRN-004), P3 DWH-004 `callProcedure`(MSA-003, CR-9), P7 RPP-002(MSA-005) |
| 다음 페이즈로 당겨 착수 가능 | P11 위젯 중 선행 메뉴가 끝난 것(DSH-005~009·011) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 23건 · 115 M/D · W2 23 · SF 트랙 23건 · 외부 트랙 0건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | QMS-06-GAU-001 | 측정기 마스터·등록·QR 라벨·위치 관리 | W2 | 5 | SF | — | QR 생성 방식 확인(CR-8) |
| A2 | QMS-06-GAU-002 | 교정 계획·교정 실행·성적서·판정 | W2 | 6 | SF + DW 목 | GAU-001 | — |
| A3 | QMS-06-GAU-003 | 사용 통제·검사 훅 구현·수리·분실·폐기 | W2 | 5 | SF | GAU-002 | — |
| A4 | QMS-06-GAU-004 | 교정 불합격 영향 분석·교정 현황 심사 증빙 | W2 | 5 | SF + DW 목 | GAU-002 | — |
| A5 | QMS-06-GAU-005 | 기존 측정기 시스템 이관·연계 수신 계약 | W2 | 3 | SF + 연계 시뮬 | GAU-001, GAU-002 | — |
| A6 | QMS-09-INT-017 | 측정기 시스템 → 측정기·교정 동기화(IF-GAU-001) | W2 | 5 | SF + 연계 시뮬 | QMS-06-GAU-005 | — |
| B1 | QMS-06-MSA-001 | MSA 대상·연구 계획·주기 관리 | W2 | 4 | SF + DW 목 | GAU-001 | — |
| B2 | QMS-06-MSA-002 | MSA 연구 데이터 모델·측정 입력 그리드 | W2 | 6 | SF + DW 목 | MSA-001, GAU-003, TRN-004 | — |
| B3 | QMS-06-MSA-003 | Gage R&R 계산(ANOVA·평균범위법)·판정 | W2 | 7 | SF + DW 목 + 연계 시뮬 | MSA-002 | callProcedure 필요(CR-9) |
| B4 | QMS-06-MSA-004 | 편의·직선성·안정성·계수형 일치성 계산 | W2 | 6 | SF + DW 목 | TRN-004, MSA-003 | — |
| B5 | QMS-06-MSA-005 | MSA 승인·보고서·PPAP 증빙 수집기·측정기 연결 | W2 | 5 | SF + DW 목 | MSA-003, MSA-004 | — |
| C1 | QMS-06-TRN-001 | 교육 과정·연간 교육 계획·교육 차수 | W2 | 5 | SF | — | — |
| C2 | QMS-06-TRN-002 | 교육 실행·출석·평가·이수 기록 | W2 | 5 | SF | TRN-001 | — |
| C3 | QMS-06-TRN-003 | 자격 유형·자격 인증·자격 매트릭스·재인증 | W2 | 6 | SF + DW 목 | TRN-002 | — |
| C4 | QMS-06-TRN-004 | 자격 검증 서비스·검사원 훅·심사원 배정 API | W2 | 4 | SF | TRN-003 | — |
| D1 | QMS-06-LMS-001 | 관능 검사 조건·한도견본 등록·개정·고객 승인 | W2 | 6 | SF | — | — |
| D2 | QMS-09-INT-018 | 신뢰성 시스템 시험 의뢰·상태·결과 연계(IF-REL-001·002) | W2 | 6 | SF + 연계 시뮬 | — | — |
| D3 | QMS-06-LAB-001 | 분석 항목(실험실 범위)·분석 의뢰 데이터 모델 | W2 | 5 | SF | GAU-001 | — |
| D4 | QMS-06-LMS-002 | 실물 견본 보관·배포·정기 점검·교체 | W2 | 4 | SF + 포털 | LMS-001 | — |
| D5 | QMS-06-LAB-002 | 분석 의뢰·검토·승인·시료 접수 | W2 | 5 | SF | LAB-001 | — |
| D6 | QMS-06-LMS-003 | 검사 화면 견본 연결·모바일·포털 조회 | W2 | 3 | SF + 포털 | LMS-001, LMS-002 | — |
| D7 | QMS-06-LAB-003 | 분석 실행·대기열·결과 입력·결과 보고서 | W2 | 6 | SF | GAU-003, LAB-002, TRN-004 | — |
| D8 | QMS-06-LAB-004 | 정기 분석 일정·처리 기간 KPI | W2 | 3 | SF + DW 목 | LAB-003 | — |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

레인 B의 MSA-002와 레인 D의 LAB-003은 레인 A의 GAU-003, 레인 C의 TRN-004를 기다린다. GAU-001~003과 TRN-001~004를 먼저 끝낸다.

### 레인 A — 측정기(GAU-001 → 002 → 003, 004, 005, INT-017)

1. **GAU-001**: `QMS_Gauge__c`(분석 장비 포함 Category LAB_INSTRUMENT, D6B-5), 유형별 기본값, 등록·이동, QR 라벨(**CR-8 QR 생성 방식**), 모바일 조회, 채번 — RecordNo 접두를 GaugeNo와 구분할지(데모 보강 요청: `GAU-` 안).
2. **GAU-002**: `QMS_Calibration__c`, 계획 배치, 월간 계획·외부 발송 화면, 결과 입력·판정, 측정기 반영, 기한 경과 정지, 주기 조정 제안, GAU KPI.
3. **GAU-003**: 상태 변경 이력, 사용 가능 판정 서비스, 정지·해제, **측정기 검사 훅 구현**(`QMS_InspectionHook`, Context IQC·FQC, 운영 모드 WARN → 공장별 BLOCK, D6B-1), 수리·분실·폐기.
4. **GAU-004**(IAU-005 뒤): `QMS_GaugeImpactAnalysis__c`, Snowflake 영향 조회(측정기 번호가 기록된 검사 결과, D6B-9), 위험 마진, 판정·조치·종결, NCR 바인딩으로 요청(GAUGE_IMPACT), 심사 증빙 제공자 EV-GAUGE-CAL.
5. **GAU-005**: 공장별 마스터 원천 설정, 이관 CSV 도구, IF-GAU-001 수신 계약, LEGACY 원천 공장 편집 잠금. review-pack 3절 1건.
6. **INT-017**(Salesforce 쪽): 측정기 → 교정 순서 upsert 계약 확인. Mule 쪽은 외부 트랙.

### 레인 B — MSA(MSA-001 → 002 → 003 → 004 → 005)

1. **MSA-001**: 대상·연구 계획·주기, 일 배치 연구 생성, 측정기 이벤트에 따른 비정기 연구 제안, 캘린더.
2. **MSA-002**(GAU-003·TRN-004 뒤): `QMS_MsaStudy__c`·`QMS_MsaAppraiser__c`, 유형별 기본 설계, 측정 전 검사(측정기·평가자), 입력 그리드(GRR·편의·직선성·안정성·계수형), 블라인드 순서표.
3. **MSA-003**: Queueable 콜아웃 → `CMN_DwQueryService.callProcedure` → Mule → Snowflake 프로시저(Snowpark — 외부 트랙), 판정 규칙(D6B-4), 결과 필드·차트 데이터.
4. **MSA-004**: 편의·직선성·안정성·계수형 결과 필드·판정·화면, 계수형 평가자 결과의 자격 반영.
5. **MSA-005**: 결재·판정 확정, 이전 연구 폐기, 보고서 PDF(차트 포함), 조회 서비스, `QMS_MsaEvent__e`, 측정기 패널, **PPAP MSA 증빙 수집기 등록**(P7 RPP-002 인터페이스).

### 레인 C — 교육·자격(TRN-001 → 002 → 003 → 004)

1. **TRN-001**: 교육 과정·버전·교재, 연간 계획·결재, `QMS_TrainingNeedsService`, 차수 생성. 대상은 `CMN_Employee__c`(라이선스 없는 현장 인원 포함, D6B-6).
2. **TRN-002**: 대상자 등록, 출석(사원증 바코드·명단, 휴대폰 QR 없음), 점수·이수 판정, 외부 이수, 개인 이력.
3. **TRN-003**: 자격 유형·필수 과정, `QMS_Qualification__c`, 요건 평가, 부여·외부 자격 결재, 만료·재인증·정지, 자격 매트릭스·최소 인원 경고, TRN KPI. review-pack 3절 1건.
4. **TRN-004**: `QMS_QualificationService.isQualified`·검색 API, 활동 실적 API, **검사원 훅 구현**(IQC·FQC), 운영 모드, 캐시, 바인딩 **AUDITOR_QUALIFICATION** 구현과 심사원 자격 유형 초기 데이터, 증빙 제공자 EV-TRAINING.

### 레인 D — 분석실·한도견본(LAB-001 → 002 → 003 → 004, LMS-001 → 002 → 003, INT-018)

1. **LAB-001**: 분석 항목 마스터, 의뢰·의뢰 항목, 상태 전이, 스냅숏, 공유(의뢰자 공장 포함). 데모 보강: RequestItem ExternalKey.
2. **LAB-002**: 의뢰 화면, `QMS_LabRequestService.createFromSource`, 바인딩 **LAB_REQUEST** 구현, 결재, 실험실 접수·반려, 시료 QR 라벨(CR-8), 완료 예정일.
3. **LAB-003**(GAU-003·TRN-004 뒤): 대기열, 배정·착수(장비 교정·분석자 자격 검사), 결과 입력·판정, 결과 승인 결재, 보고서 PDF·개정.
4. **LAB-004**: 정기 분석 일정, 일 배치 의뢰, 추세, LAB KPI.
5. **LMS-001**: 관능 검사 조건, `QMS_LimitSample__c` 세트·이미지·버전, 사내 결재, 고객 승인 기록, 특성 개정 연동.
6. **LMS-002**: 실물 사본 QR 라벨(CR-8), 정기 점검(사내 모바일·협력사 포털), 만료·손상, 구 버전 회수, LMS KPI.
7. **LMS-003**: 조회 서비스, 재사용 LWC `qmsLimitSampleLink`, 포털 조회, Platform Cache. 검사 화면(IQC-003, DVQ-007, FQC-002)에 배치하는 일은 그 WI 쪽 작업이므로 변경 요청으로 올린다.
8. **INT-018**(Salesforce 쪽): `QMS_QualLineRequested__e`(P4 DVQ-006 발행) 구독은 Mule. Salesforce에서는 외부 결과 수신 핸들러(Vol.2 외부 반영 서비스 — 변경 요청)를 확인한다.

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| 게이트웨이 바인딩 | LAB_REQUEST, AUDITOR_QUALIFICATION 추가 | P5 CLM-009, P9 IAU-002 회귀 |
| 검사 훅 | `QMS_InspectionHook__mdt`에 측정기·검사원 훅 등록, 운영 모드 WARN | IQC-003·FQC-002 회귀 |
| 증빙 제공자 | EV-TRAINING, EV-GAUGE-CAL 등록 | P9 IAU-005 회귀 |
| PPAP 증빙 수집기 | MSA 수집기 등록 | P7 RPP-002 회귀 |
| QR·바코드 | Visualforce PDF 라벨, 모바일 스캔 | CR-8 결정 방식 |
| Platform Cache | LMS-003, TRN-004 | 용량 없으면 캐시 미스 경로 |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| MSA 계산(Snowpark 프로시저) | `mocks/dwh/QMS_MSA_CALC/`(ok-msa1·2·3, failed-constant, error-timeout), `QMS_MSA_CHART`, `QMS_MSA_GAUGE_USAGE` |
| 교정 불합격 영향 조회 | `mocks/dwh/QMS_GAU_IMPACT_RESULTS/ok.json` |
| 측정기 시스템(INT-017), 신뢰성 시스템(INT-018) | 수신 계약 CSV, 결과 이벤트 발행 |

## 6. 데모 데이터

```bash
scripts/demo/load_salesforce.sh qms-int --upto-phase 10
```

| 파일 | 객체 | 적재 | 비고 |
| --- | --- | --- | --- |
| 34 | QMS_LabAnalysisItem__c | 전부 | 8 |
| 35, 79 | 자격 유형·자격 | 전부 | 10 + 60 |
| 36, 77, 78 | 교육 과정·차수·출석 | 전부 | 12 + 24 + 90 |
| 67, 74 | 분석 의뢰·항목 | 전부 | 25 + 29(S2-LAB X-ray 보이드 31%) |
| 73, 75, 76 | 측정기·교정·영향 분석 | 전부 | 60 + 154 + 1(S12-IMPACT OPEN) |
| 82 | QMS_LimitSample__c | 전부 | 15 |
| 94, 95 | MSA 연구·평가자 | 전부 | Snowflake 데이터 작업 소유 |
| 45 | QMS_Claim__c | 다시 실행해 분석 의뢰 연결 채움 | 이 페이즈에서 전부 |
| 85 | CMN_Todo__c | 다시 실행해 남은 원천 채움 | 이 페이즈에서 전부 |

이 페이즈 게이트에서 Salesforce 데모 CSV 전부(01~97)가 적재된 상태가 된다.

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G10-1 | 새 Org 배포·테스트·**전체** 데모 적재 | 6.4절 | 실패 0, 모든 CSV 행 적재(실패 행 0 또는 사유 기록) |
| G10-2 | S12: GA-KR01-0456 교정 불합격 → 영향 분석 → 대상 로트 → NCR 요청 | `expected/gauge_S12.json`, GAU-004 | 대상 로트 목록 일치, NCR(GAUGE_IMPACT) |
| G10-3 | 교정 기한 경과 측정기로 수입검사 결과 저장(WARN·BLOCK) | GAU-003, IQC-003 AC-5 | WARN은 경고 후 저장, BLOCK은 차단 |
| G10-4 | S8: GRR 연구 입력 → 계산(목 ok-msa1·2) → 판정 → 승인 → PPAP 증빙 | `expected/msa_S8.json`, MSA-002~005 | %GRR·ndc 일치(허용 오차 D6B-3), 증빙 수집 |
| G10-5 | 계산 실패·시간 초과(목 failed-constant·error-timeout) | MSA-003 | 오류 상태 표시, 재시도 경로 |
| G10-6 | 교육 이수 → 자격 부여 → 검사원 훅, 심사원 배정 | TRN-002~004, IAU-002 | 자격 없는 검사원 경고, 자격 없는 심사원 배정 처리(D6C-11 전환 여부) |
| G10-7 | S2: 클레임 "분석 의뢰" → 분석 의뢰 생성 → 결과 → 보고서 | CLM-009 AC-1(회귀), LAB-002·003 | To-Do가 아니라 의뢰 생성, 결과 보고서 |
| G10-8 | 한도견본 등록 → 실물 사본 QR → 검사 화면에서 견본 보기, 협력사 포털 조회 | LMS-001~003 | 자기 부품 견본만 공개(D6B-8) |
| G10-9 | 심사 증빙 패널의 교육·교정 제공자 | IAU-005 회귀 | 증빙 표시 |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D6B-1 훅 WARN → BLOCK 전환 기준, D6B-2 측정기 마스터 원천, D6B-3 MSA 계산 엔진·Minitab 대조 오차, D6B-4 MSA 판정 기준 초기값 |
| 결정 | D6B-5 분석 장비 = 측정기, D6B-6 교육 대상, D6B-7 한도견본 기본값, D6B-8 협력사 견본 공개, D6B-9 영향 분석 범위 |
| 결정 | CR-8 QR 생성 방식(GAU-001, LMS-002, LAB-002) |
| 명세 | CR-9 `callProcedure`가 P3 DWH-004에 들어갔는지 확인(안 들어갔으면 MSA-003 착수 전 DWH-004 보완) |
| 명세 | 데모 보강(CR-6): LAB-001 ExternalKey, GAU-001 RecordNo 접두 |
| 명세 | review-pack 3절: GAU-005 1, TRN-003 1. Vol.3·4 측정기 번호 기록(P8에서 확인) |
| 명세 | LMS-003 컴포넌트 배치, INT-018 외부 결과 반영 서비스(Vol.2) — 둘 다 다른 WI 변경 요청 |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| 훅을 BLOCK으로 켜면 앞 페이즈 시나리오가 막힘 | 기본 WARN, BLOCK 전환은 공장별 메타데이터 값으로만 |
| MSA 계산 정확도(Snowpark)가 외부 트랙에만 있음 | Salesforce 완료 기준은 목 응답 대조, 실계산은 L3에서 `msa_S8.json` 대조 |
| QR 생성 방식 미정 | P9 중 CR-8 결정. 결정 전에는 라벨 PDF에 텍스트 키만 |

## 10. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| | | | |
