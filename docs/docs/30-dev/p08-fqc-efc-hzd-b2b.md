# P8 출하검사·초기유동·수평전개·고객 B2B

제품 쪽 검사·안정화(출하검사 FQC, 제품 초기유동 EFC), 수평전개(HZD), 고객 B2B 데이터 수집·KPI·경보·분석(B2B-002~007)과 이에 딸린 SAP·MES·필드클레임 연계의 Salesforce 쪽을 만든다. 바인딩 HORIZONTAL_DEPLOY가 실제 구현으로 바뀌어 8D D7·NCR 종결의 수평전개 요청이 To-Do가 아닌 수평전개 건이 된다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | 출하검사 로트 → 판정 → 출하 보류·NCR·Hold, 제품 초기유동 생성·집계·해제, 수평전개 요청 → 대상 선정 → 사내·협력사 실행 → 효과 점검, 고객 데이터 업로드·KPI·추세 경보·분석 화면이 동작 |
| 기간(4명 기준) | 누적 193영업일(P7 이후 약 26일) |
| 마일스톤 | S10 고객 B2B, S13 EOL·출하 |
| 착수 조건 | P6 PIS-001·003(EFC), P5 CLM-007·NCR-001·002(FQC-003, B2B-005), P6 RPP-004·NCR-007(EFC 트리거, INT-007) |
| 다음 페이즈로 당겨 착수 가능 | P9 중 IAU-001, SQM-001, IMP-001(선행이 앞 페이즈뿐) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 23건 · 122 M/D · W1 8 · W2 15 · SF 트랙 20건 · 외부 트랙 3건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | QMS-04-FQC-001 | 출하검사 기준서 | W2 | 5 | SF | — | — |
| A2 | QMS-04-FQC-002 | 출하검사 로트 생성·결과 입력·판정 | W2 | 8 | SF + DW 목 | FQC-001 | — |
| A3 | QMS-04-FQC-003 | 출하 보류·NCR 연계·SAP 출하 차단·출하검사 강도 Hold | W2 | 7 | SF | FQC-002 | — |
| A4 | QMS-04-FQC-004 | EOL 전수 시험·출하검사 실적 Snowflake 적재·KPI | W2 | 4 | SF + DW 목 | FQC-002 | 앞당김: QMS-07-DSH-006·QMS-09-INT-011의 선행 |
| A5 | QMS-04-FQC-005 | 고객 출하 검사 성적서 | W2 | 4 | SF | FQC-002 | — |
| A6 | QMS-09-INT-006 | SAP 납품 → 출하검사 로트, 출하 판정 → 출하 차단·해제(IF-SAP-005·006) | W2 | 6 | SF + 연계 시뮬 | QMS-04-FQC-002, QMS-04-FQC-003 | — |
| B1 | QMS-04-EFC-001 | 제품 초기유동 계획(PRODUCT)·트리거·강화 조치 | W2 | 5 | SF | — | — |
| B2 | QMS-09-INT-007 | NCR 처분 재고 이동·협력사 구상 차변 메모(IF-SAP-007·008) | W1 | 5 | SF + 연계 시뮬 | — | — |
| B3 | QMS-04-EFC-002 | MES 실적 집계·초기유동 관리 검사 기록 | W2 | 6 | SF + DW 목 | EFC-001 | 앞당김: QMS-07-DSH-006·QMS-09-INT-011의 선행 |
| B4 | QMS-04-EFC-003 | 초기유동 해제 판정·출하검사 강화 해제 | W2 | 4 | SF | FQC-003, EFC-002 | — |
| C1 | QMS-04-HZD-001 | 수평전개 건·대상 데이터 모델·생성 서비스 | W2 | 7 | SF | — | — |
| C2 | QMS-04-HZD-002 | 수평전개 대상 선정 지원 | W2 | 5 | SF + DW 목 | HZD-001 | — |
| C3 | QMS-04-HZD-003 | 대상별 실행·확인·지연 관리·효과 점검·현황 | W2 | 6 | SF + 포털 | HZD-002 | — |
| D1 | QMS-05-B2B-002 | 연계 없는 고객 데이터 파일 업로드·수집 현황 | W1 | 6 | SF + DW 목 + 연계 시뮬 | — | — |
| D2 | QMS-05-B2B-003 | 고객 품질 KPI 계산·목표·적재 | W1 | 4 | SF + DW 목 + 연계 시뮬 | — | — |
| D3 | QMS-05-B2B-004 | Trend Monitoring 규칙 엔진 | W2 | 5 | SF + DW 목 | B2B-003 | — |
| D4 | QMS-05-B2B-006 | 고객 품질 분석 화면·드릴다운 | W1 | 6 | SF + DW 목 | B2B-003 | — |
| D5 | QMS-09-INT-016 | 고객 데이터 업로드 파일 처리(IF-B2B-001) | W1 | 4 | SF + DW 목 + 연계 시뮬 | QMS-05-B2B-002 | — |
| D6 | QMS-05-B2B-005 | 고객 품질 경보 처리·후속 조치 연결 | W2 | 5 | SF | B2B-004 | — |
| D7 | QMS-05-B2B-007 | OEM 고객 평가(스코어카드)·에스컬레이션 추적 | W2 | 3 | SF | B2B-005 | — |
| X1 | QMS-09-INT-014 | 필드클레임 → Snowflake 고객 품질 원천(IF-FC-001) | W1 | 6 | 외부 트랙 | — | — |
| X2 | QMS-09-INT-011 | MES → Snowflake 생산·불량 실적과 EOL 시험(IF-MES-002·003) | W1 | 6 | 외부 트랙 | QMS-04-FQC-004, QMS-04-EFC-002 | — |
| X3 | QMS-09-INT-012 | 로트 계보(CORE.LOT_TRACE)·4M 첫 생산 로트 감지(IF-MES-004) | W1 | 5 | 외부 트랙 | INT-011 | — |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

### 레인 A — 출하검사(FQC-001 → 002 → 003·004·005, INT-006)

1. **FQC-001**: 출하검사 기준서·라인, 선택 규칙·버전, 로트 단위 설정(기본 품번·공장·생산일, D4-4), 고객 성적서 요구 표시. 샘플링은 Vol.3 `QMS_SamplingService` 재사용.
2. **FQC-002**: `QMS_FinalInspLot__c`·Result, 로트 생성 3경로(Snowflake 생산 실적, SAP 납품 수신 계약, 수동), 초기화, 검사 입력·판정(수입검사 공용 컴포넌트·검사 훅 Context FQC), EOL 라인 판정, 재개. **측정 결과에 측정기 번호를 남긴다**(P10 GAU-004 교정 불합격 영향 분석의 전제, Vol.6b 변경 요청). review-pack 3절 1건.
3. **FQC-003**: `QMS_FinalInspDecision__e`, 출하 보류·해제, NCR 요청(바인딩 NCR, sourceType FQC), SAP 회신 상태, `QMS_FinalInspLevelService`·`QMS_FinalInspHold__c`(출하검사 강도 Hold, 수입검사와 같은 방식), 클레임·사내 NCR 이벤트 구독 Hold.
4. **FQC-004**(SNOW·SF): `CORE.EOL_TEST_RESULT` 수신 계약, 출하검사 시료 펼침(SOURCE 'FQC'), EOL 요약 쿼리, KPI, EOL 직행률 급락 알람 핸들러. Snowflake 쪽은 외부 트랙.
5. **FQC-005**: 고객 출하 검사 성적서 PDF(로트·납품 묶음, 고객별 양식), 송부 기록.
6. **INT-006**(Salesforce 쪽): 납품 → 출하검사 로트 upsert 계약(LotUnit DELIVERY), 출하 차단·해제 회신 필드, 이미 출고된 납품 경보.

### 레인 B — 제품 초기유동(EFC-001 → 002 → 003, INT-007)

1. **EFC-001**(P6 PIS-001 뒤): `QMS_StabilizationPlan__c` RecordType PRODUCT, 기본값 메타데이터 확장, 트리거별 호출 계약(PMS SOP, 고객 PPAP 승인 `QMS_PpapEvent__e`, 사내 4M, 수동), 생성 즉시 출하검사 강화 Hold(D4-10), 생성 마법사.
2. **EFC-002**(SNOW·SF): MES 생산·불량 수신 컬럼 계약, `QMS_MesDefectMap__c`(MES 불량 코드 매핑), 일 집계 수신, 일 보고(INTERNAL), 알람, 모니터 PRODUCT 모드, KPI. review-pack 3절 1건.
3. **EFC-003**(FQC-003 뒤): PRODUCT 해제 조건, 결재 유형 `QMS_EFC_RELEASE`·`QMS_EFC_EXTEND`(생산팀장 합의), 출하검사 Hold 해제.
4. **INT-007**(Salesforce 쪽): NCR 처분(DISPOSITION_DONE)·구상 합의(CHARGEBACK_AGREED) 이벤트 계약 확인과 회신 필드 갱신. 전기는 Mule(외부 트랙).

### 레인 C — 수평전개(HZD-001 → 002 → 003)

1. **HZD-001**: `QMS_HorizontalDeploy__c`·`Target__c`, `QMS_HorizontalDeployService.createFromSource`, 바인딩 HORIZONTAL_DEPLOY 구현 등록, `QMS_HorizontalDeployEvent__e`, 상태 규칙, 공유(전사 조회, 협력사는 자기 대상만 — D4-5), 진척 집계.
2. **HZD-002**: 후보 검색(같은 품번군·공정·공장·협력사), BOM 역전개(`QMS_BOM_WHERE_USED`), 점수, 선택·배정·배포.
3. **HZD-003**: 사내 실행 화면, 협력사 포털 실행 화면, 발행자 확인·반려, 기한 변경 요청, 지연 에스컬레이션, 종결, 효과 점검, 현황 보드, KPI.

### 레인 D — 고객 B2B(B2B-002 → 003 → 004 → 005, 006, 007, INT-016)

1. **B2B-002**: 업로드 형식 메타데이터, 업로드 배치 객체, 업로드 화면(정적 리소스 SheetJS로 앞 50행 미리보기 — **CR-8**: SheetJS 승인 근거 WI에 B2B-002 추가 필요), `QMS_B2bUploadRequested__e` 계약, 결과 수신 핸들러, 교체·취소, 수집 현황·지연 알림. Salesforce에서 행을 파싱·저장하지 않는다(D5-3). review-pack 3절 1건.
2. **B2B-003**(SNOW·MULE·SF): KPI 계산 뷰·분모 규칙은 외부 트랙, Salesforce 쪽은 연간 목표 객체와 KPI 정의 등록(P7 DSH-001 레지스트리).
3. **B2B-004**: 규칙 객체·편집 화면, 규칙 시뮬레이션(Snowflake 평가는 외부 트랙), 경보 이벤트 계약(`QMS_B2B_ALERT`).
4. **B2B-005**: `QMS_CustomerQualityAlert__c`, 경보 수신 핸들러(중복·억제), 담당 배정(`QMS_CustomerQualityOwnerResolver`)·기한, 판단 화면, 후속 조치 연결(클레임 서비스, IMPROVEMENT 게이트웨이 — P9까지 기본 구현, HORIZONTAL_DEPLOY 게이트웨이 — 레인 C).
5. **B2B-006**: 분석 페이지 LWC, 등록 쿼리 6개(Snowflake 뷰·함수는 외부 트랙), 필터·드릴다운·내보내기, 수동 경보 진입.
6. **B2B-007**: OEM 스코어카드 객체·입력·CSV 등록, 하락·에스컬레이션 감지·알림, 개선 과제 연결(IMPROVEMENT 게이트웨이).
7. **INT-016**(Salesforce 쪽): 업로드 이벤트 구독 측은 Mule. Salesforce에서는 상태 갱신 계약과 결과 수신을 B2B-002와 함께 확인한다.

### 레인 X — 외부 트랙(INT-011, INT-012, INT-014)

MES 생산·불량·EOL 실적(INT-011), 로트 계보 `CORE.LOT_TRACE`와 4M 첫 생산 로트 감지(INT-012 — P6 4MC-007의 사내 경로가 실데이터로), 필드클레임 원천(INT-014 — S10의 실데이터). S3의 INT-012 연계는 여기서 L3로 확인한다.

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| 게이트웨이 바인딩 | HORIZONTAL_DEPLOY 레코드 추가 | P5 CLM-004·NCR-006 회귀 |
| 정적 리소스 SheetJS | P6 DVQ-009의 리소스 재사용 | CR-8 결정 후 |
| 포털 화면 | HZD-003 협력사 실행 | |
| PDF | FQC-005 성적서 | |
| 모바일 | 출하검사 입력(수입검사 공용 컴포넌트) | |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| 생산 실적 기반 출하검사 로트 생성(Snowflake) | 수동 생성 경로 + SAP 납품 계약 CSV(INT-006 계약) |
| EOL 요약·직행률 알람 | `mocks/dwh/QMS_FQC_EOL_SUMMARY`, 알람은 `publish-inbound.apex` |
| 초기유동 집계·불량 Pareto | `mocks/dwh/QMS_EFC_DEFECT_PARETO`, 일 집계 이벤트 발행 |
| B2B 분석 쿼리 6개 | `mocks/dwh/QMS_B2B_DETAIL`·`LAST_LOADED`·`MIS_CURVE`·`PARETO`·`TOP_ITEMS`·`TREND` |
| B2B 업로드 처리(Mule·Snowflake) | 업로드 이벤트 발행 확인 → 결과 수신 이벤트를 `publish-inbound.apex`로 흉내 |
| B2B 추세 경보 | `QMS_B2B_ALERT` 이벤트 발행 |

## 6. 데모 데이터

```bash
scripts/demo/load_salesforce.sh qms-int --upto-phase 8
```

새로 적재할 Salesforce CSV가 없다. 출하검사 로트·결과, 초기유동 계획(PRODUCT), 수평전개 건, 고객 품질 경보·OEM 스코어카드는 데모 CSV가 없고, S10·S13은 Snowflake 기대값(`expected/b2b_S10.json`, `expected/eol_S13.json`)만 있다. 게이트 전에 둘 중 하나를 고른다.

1. 데모 데이터 작업에 S13(CN01 KC1 조준, 출하검사 강화 Hold 1건)·S10 경보·수평전개 사례 CSV 추가를 요청한다(권고).
2. 게이트 때 화면으로 직접 만들고, 만든 절차를 `scripts/demo/`에 시나리오 스크립트로 남긴다.

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G8-1 | 새 Org 배포·테스트·P8까지 적재 | 6.4절 | 실패 0 |
| G8-2 | 출하검사 로트(납품 계약 CSV 2회) → 검사 → REJECT → 출하 보류·NCR·Hold | FQC-002·003, INT-006 | 로트 1건, 보류, NCR(FQC), 강화 Hold |
| G8-3 | S13: EOL 직행률 급락 알람 → 출하검사 강화, 조준각 I-MR 신호(P7 화면) | `expected/eol_S13.json`, 데모 S13 | 알람·Hold 1건, 요약 쿼리 목 값 일치 |
| G8-4 | 고객 PPAP 승인 이벤트 → 제품 초기유동 + 출하검사 Hold → 일 집계 → 해제 결재 | EFC-001~003 | 계획 생성·Hold, 해제 시 Hold 해제 |
| G8-5 | 8D D7에서 수평전개 요청 → 수평전개 건 생성 → 대상 선정(BOM) → 협력사 포털 실행 → 확인 → 효과 점검 | HZD-001~003, CLM-004 AC-3 | 바인딩이 실제 구현, 대상별 상태, 종결 |
| G8-6 | 회귀: NCR 종결 시 SHORT_CAPA 수평전개 요청 | NCR-006 | 수평전개 건 생성(To-Do 아님) |
| G8-7 | 고객 파일 업로드(미리보기 50행) → 이벤트 → 결과 수신 → 교체·취소 | B2B-002 | 상태 전환, Salesforce에 행 저장 없음 |
| G8-8 | S10: BMW BE1 0km PPM 상승 경보 → 판단 → 클레임 생성 연결 | `expected/b2b_S10.json`, B2B-004·005 | 경보 1건(중복 억제), 클레임 연결 |
| G8-9 | 고객 품질 분석 화면 필터·드릴다운·내보내기(목 6종) | B2B-006 | 상태 표시, 드릴다운 |
| G8-10 | OEM 스코어카드 하락 → 에스컬레이션 알림 | B2B-007 | 알림, 개선 과제 연결(기본 구현 To-Do) |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D4-4 출하검사 로트 기준, D4-10 제품 초기유동 즉시 강화·해제 결재 |
| 결정 | D5-2 B2B 원천은 Snowflake만, D5-3 파일 업로드 → Mule → Snowflake, D5-9 VIN 해시 |
| 결정 | D9-2 출하 차단 방식(납품 차단·배치 제한·보류 재고), D9-3 MES 수집 방식, D9-5 Snowflake 적재 방식 |
| 결정 | CR-8 SheetJS 사용 범위(B2B-002) |
| 명세 | review-pack 3절: FQC-002 1, EFC-002 1, B2B-002 1, Vol.5 B2B 화면 컴포넌트 1 |
| 명세 | Vol.6b 변경 요청: FQC-002 측정 결과에 측정기 번호(IQC-003에도 같은 요청 — P4에서 반영하지 않았으면 이 페이즈에 IQC-003 보완 PR) |
| 데이터 | S13·S10·수평전개 데모 CSV(6절) |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| 데모 CSV 없음으로 게이트 시나리오 준비가 길어짐 | 6절 1안을 P7 중에 요청 |
| 수입검사 공용 컴포넌트 재사용 중 IQC 쪽 회귀 | 공용 컴포넌트 Context(IQC·FQC)별 Jest·Apex 테스트를 함께 실행 |
| 측정기 번호 기록 누락이 P10에서 발견됨 | 이 페이즈 게이트 항목에 "결과 라인 측정기 번호" 확인을 넣음 |

## 10. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| | | | |
