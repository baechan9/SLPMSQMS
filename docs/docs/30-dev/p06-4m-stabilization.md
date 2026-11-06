# P6 4M 변경·초기안정화·부품 확장

4M 변경 전 과정(Vol.6a 4MC-001~008)과 그것이 부르는 부품 쪽 기능 — 협력사 출하 성적서(IQC-006), 초기안정화(PIS-001~003), 보증시험(PWT), 고객 PPAP 기본(RPP-001·004) — 그리고 협력사 포털 제출 화면 나머지(DVQ-010, CLM-005, SPP-003)와 비용·구상(CLM-010, NCR-007)을 만든다. PoC 시나리오 S3(4M)의 Salesforce 부분이 여기서 완성된다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | 협력사·사내 4M 신청 → 리스크 확정 → 검증 계획 결재(인정시험·PPAP 자동 생성) → 검증 → 적용 결재 → 첫 적용 로트 → 초기안정화 → 종료가 동작 |
| 기간(기본 인원) | 누적 128영업일(P5 이후 약 26일). QMS 4명·PMS 3명 시뮬레이션(2026-11-06, [개발 플랜](dev-plan.md) 9.2절) |
| 마일스톤 | S3 4M 완성(Salesforce 부분), S9 성적서 이상(OOS_HOLD), S2 협력사 8D 포털 제출 |
| 착수 조건 | P5 NCR-001, P4 IQC-005·PPA-004·DVQ-005 `개발 완료`. **CLM-010·NCR-007은 D-3(Multi-Currency) 결정 후** |
| 다음 페이즈로 당겨 착수 가능 | P7 중 SPC-001, LEL-003, QMS-07-DSH-001(IQC-007 뒤) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 24건 · 124 M/D · W1 8 · W2 16 · SF 트랙 22건 · 외부 트랙 2건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | QMS-06-4MC-001 | 변경 유형 기준표·리스크 체크리스트 | W1 | 5 | SF | — | — |
| A2 | QMS-06-4MC-002 | 4M 변경 데이터 모델·상태 규칙·이벤트 | W1 | 6 | SF | 4MC-001 | — |
| A3 | QMS-06-4MC-003 | 4M 신청·영향 범위·리스크 평가 화면 | W1 | 6 | SF + DW 목 | 4MC-002 | — |
| A4 | QMS-06-4MC-004 | 협력사 4M 포털 신청·SQE 접수 | W2 | 6 | SF + 포털 | 4MC-003 | — |
| A5 | QMS-06-4MC-005 | 검증 계획 자동 구성·계획 결재·고객 통보·승인 | W1 | 6 | SF | 4MC-003 | — |
| A6 | QMS-06-4MC-006 | 검증 진행 게이트·적용 승인 결재 | W1 | 5 | SF | 4MC-005 | — |
| A7 | QMS-06-4MC-007 | 적용 시점 관리(구 재고·첫 적용 로트·로트 추적) | W1 | 7 | SF + DW 목 | QMS-03-IQC-006, 4MC-006, QMS-03-PIS-001 | — |
| A8 | QMS-06-4MC-008 | 4M 종료·변경 이력 대장·KPI | W2 | 4 | SF + DW 목 | 4MC-007, QMS-03-PIS-003 | 앞당김: QMS-07-DSH-007·QMS-08-AIQ-003의 선행 |
| B1 | QMS-03-IQC-006 | 협력사 출하 성적서(COA) 제출·자동 점검·로트 매칭 | W2 | 6 | SF + 포털 | — | 앞당김: QMS-06-4MC-007의 선행 |
| B2 | QMS-03-PIS-001 | 초기안정화 계획·목표·해제 기준 | W2 | 5 | SF | — | 앞당김: PMS-09-GAT-006·QMS-06-4MC-007의 선행 |
| B3 | QMS-03-PWT-001 | 보증시험 주기 계획·자동 계획 생성 | W2 | 5 | SF | — | — |
| B4 | QMS-03-SPP-003 | 협력사 인증서 관리 | W2 | 3 | SF + 포털 | — | — |
| B5 | QMS-03-PWT-002 | 보증시험 준수 현황·불합격 연계 | W2 | 4 | SF + DW 목 | PWT-001 | — |
| B6 | QMS-03-PIS-002 | 안정화 실적 집계·협력사 강화 검사 보고 | W2 | 6 | SF + 포털 + DW 목 | IQC-007, PIS-001 | — |
| B7 | QMS-03-PIS-003 | 안정화 해제 판정·결재·연장 | W2 | 4 | SF | PIS-002 | — |
| C1 | QMS-02-DVQ-009 | DVP&R 보고서 생성(PDF·Excel) | W2 | 5 | SF | — | 앞당김: QMS-04-RPP-002의 선행 |
| C2 | QMS-02-DVQ-010 | 협력사 시험 성적서 제출·검토(부품) | W2 | 6 | SF + 포털 | — | — |
| C3 | QMS-04-RPP-001 | 고객 PPAP 레코드타입·트리거·요소 담당 배정 | W1 | 5 | SF | — | — |
| C4 | QMS-04-RPP-004 | 고객 제출·판정 추적·4M 적용 연계 이벤트 | W1 | 5 | SF | RPP-001 | — |
| D1 | QMS-05-CLM-005 | 협력사 8D 포털 제출·SQE 단계 검토 | W2 | 7 | SF + 포털 | — | — |
| D2 | QMS-05-CLM-010 | 클레임 비용·협력사 구상 | W2 | 5 | SF + 포털 | — | — |
| D3 | QMS-06-NCR-007 | 부적합 비용(COPQ)·협력사 구상 | W2 | 5 | SF + 포털 | — | 앞당김: QMS-09-INT-007의 선행 |
| X1 | QMS-06-NCR-008 | 부적합 실적 Snowflake 집계·KPI | W2 | 4 | 외부 트랙 | — | 앞당김: QMS-07-DSH-007·QMS-08-AIQ-002·QMS-08-AIQ-003 외의 선행 |
| X2 | QMS-03-IQC-007 | 수입검사 실적 Snowflake 적재·협력사 KPI | W2 | 4 | 외부 트랙 | IQC-006 | 앞당김: QMS-07-DSH-001·QMS-07-DSH-005·QMS-08-AIQ-003 외의 선행 |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

레인 A의 4MC-007은 레인 B의 IQC-006·PIS-001을 기다린다. 레인 B는 IQC-006·PIS-001을 먼저 끝낸다.

### 레인 A — 4M 변경(4MC-001 → 002 → 003 → 005 → 006 → 007 → 008, 004)

1. **4MC-001**: CHANGE_TYPE 코드 계층 초기 값, `QMS_ChangeTypeRule__c`(L3 → L2 → 없음 순 해석, 여러 유형 합성), 체크리스트 템플릿, `QMS_ChangeTypeRuleService`, 기준표 편집 화면. 데모 보강: ExternalKey.
2. **4MC-002**: `QMS_FourMChange__c`(RecordType INTERNAL·SUPPLIER)·Item·Verification, 상태 전이, 리드타임 준수, `QMS_FourMEvent__e`, 채번·공유·삭제 통제. 데모 보강: Item·Verification ExternalKey, `QMS_FourMStatusDTO` 필드 정의, 검증 그리드 DTO(`mocks/apex/QMS_FourMStatusDTO/S3-4M.json`, `qmsFourMVerificationGrid/S3-4M.json`).
3. **4MC-003**: 신청 마법사, BOM 역전개 영향 품번(`QMS_BOM_WHERE_USED`), 리스크 체크리스트, 규칙 결과 미리보기, AI 추천 표시 자리(P13 AIQ-014). review-pack 3절 1건.
4. **4MC-005**: 계획 결재(`QMS_4M_PLAN`, 결재선 추가 규칙), 승인 콜백에서 `QMS_QualPlanService.createFromSource`·`QMS_PpapService.createFromSource` 호출(멱등), 고객 통보·승인 입력.
5. **4MC-006**: 검증 이벤트 구독(인정시험·PPAP·고객 PPAP), 조건부(CONDITIONAL, D6A-3)·실패·면제, 게이트 판정, 적용 결재(`QMS_4M_APPROVE`).
6. **4MC-007**(IQC-006·PIS-001 뒤): 적용 준비, 구 재고 조회(`QMS_4M_OLD_STOCK`), 안정화 생성 호출, 첫 적용 로트(협력사: 수입검사 이벤트, 사내: MES 이벤트·수동), 로트 추적 드릴다운(`QMS_4M_LOT_TRACE`), 첫 고객 출하 기록. review-pack 3절 1건.
7. **4MC-008**: 안정화 종료 이벤트 구독·종료 판정, 무단 4M 사후 등록, 이력 대장·내보내기, `QMS_FourMHistoryService`.
8. **4MC-004**(4MC-003 뒤, 포털): `QMS_SupplierFourMRequest__c`, 포털 신청·조회, SQE 접수·반려·불허, 4M 생성 변환.

### 레인 B — 부품 품질 확장(IQC-006 → PIS-001 → 002 → 003, PWT-001 → 002, SPP-003)

1. **IQC-006**: `QMS_SupplierCoa__c`, 포털 입력·CSV 업로드, 제출 시 규격 점검(OOS_HOLD), 로트 자동 매칭(IQC-002 `Coa__c` 보강 필요), 성적서 누락 처리, 4M 초품 표시 → 로트 강화·전수. review-pack 3절 1건.
2. **PIS-001**: `QMS_StabilizationPlan__c`(RecordType PART), 기본값 메타데이터, PPAP 승인 이벤트·4M 원천으로 자동 생성(멱등), STABILIZATION Hold, 협력사 공개.
3. **PIS-002**: Snowflake 일 집계 수신(이벤트, 멱등), 협력사 강화 검사 보고 객체·포털 화면, 알람, 모니터.
4. **PIS-003**: 해제 조건 자동 점검, 해제·조기 해제·연장 결재, Hold 해제, 이벤트.
5. **PWT-001·002**: 보증시험 주기 계획(YEARLY·LOT_COUNT), 일 배치 계획 생성(인정시험 엔진 TriggerType PERIODIC), 준수 현황 보드, FAIL → PERIODIC_TEST_FAIL Hold.
6. **SPP-003**: 협력사 인증서(IATF 만료 반영·알림), Account 인증 필드.

### 레인 C — 고객 PPAP·시험 보고서(RPP-001 → RPP-004, DVQ-009 → DVQ-010)

1. **RPP-001**: `QMS_Ppap__c` RecordType CUSTOMER(BMW는 VDA 2 요소 세트), 고객 기본 레벨, 요소 담당 배정(Role)과 To-Do. 증빙 자동 수집(RPP-002)은 P7.
2. **RPP-004**: 고객 제출 차수, 판정 기록, 재제출, 잠정 승인 만료, `QMS_PpapEvent__e`(4MC-006이 구독), 고객 PPAP 보드.
3. **DVQ-009**: DVP&R 보고서 — Visualforce `QMS_DvprPdf`(Queueable `getContentAsPDF()`), Excel 내려받기(정적 리소스 SheetJS, 버전 고정 — `sf-dev.md` 6절 승인 목록), 고객 형식 메타데이터.
4. **DVQ-010**: 협력사 시험 성적서 제출·검토(포털, 제출 객체 + SQE 승인 — D2-5).

### 레인 D — 포털 8D·비용(CLM-005, CLM-010, NCR-007)

1. **CLM-005**: `QMS_EightDSubmission__c`(스테이지·차수), 협력사 포털 8D 작성, 제출 검증, SQE 검토(수락 시 8D 단계 승인·복사), 기한·에스컬레이션. 데모 보강: ExternalKey. S2의 D5 협력사 제출이 이것이다.
2. **CLM-010**(D-3 결정 후): 클레임 비용(통화·환율 → 원화 합계), 구상·결재·협력사 포털 확인·이의, 정산 기록.
3. **NCR-007**(D-3 결정 후): COPQ 비용 라인(처분 기반 제안, 표준가는 Snowflake 조회), 구상 청구·결재·협력사 확인, 비용 권한 분리(`QMS_PS_NcrCost`, Custom Permission `QMS_ViewCost`, D6A-9).

### 레인 X — 외부 트랙(IQC-007, NCR-008)

수입검사·NCR 실적의 Snowflake 적재와 KPI 뷰. Salesforce 쪽 산출물은 복제 대상 등록(`CMN_DwhSyncConfig__mdt` 레코드)뿐이며 같은 PR로 넣는다. KPI 값은 `90_CMN_KpiValue__c.csv`로 화면을 확인한다. **NCR-008은 임계 경로 위에 있다**(P12 AIQ-002·003·010·011의 선행). 외부 트랙이 이 WI를 늦추면 AI 페이즈가 그만큼 밀린다.

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| Multi-Currency | **D-3 결정에 따라** 정의 파일 변경 → `qms-int`·개발 Org 재생성 | 켜면 되돌릴 수 없음. 운영과 같게 |
| 정적 리소스 SheetJS | 버전 고정 파일을 `force-app-qms/.../staticresources`에(이름은 DVQ-009 지정) | 라이선스 확인 |
| 포털 화면 7종 | 4MC-004, IQC-006, PIS-002, DVQ-010, CLM-005, CLM-010, NCR-007, SPP-003 | 시나리오 협력사 포털 사용자 |
| 비용 권한 | `QMS_PS_NcrCost`, `QMS_ViewCost` | 비용 열람 사용자 1명 지정 |
| 일 배치 | PWT-001, PIS-002·003, SPP-003, 4MC-008 | 게이트 Org 등록 스크립트 |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| 구 재고·로트 추적·BOM 역전개(Snowflake) | `mocks/dwh/QMS_4M_OLD_STOCK`, `QMS_4M_LOT_TRACE`, `QMS_BOM_WHERE_USED` |
| 안정화 일 집계(Snowflake → 이벤트) | `scripts/apex/publish-inbound.apex`로 집계 이벤트 발행(같은 EVENT_ID 2회 → 1회 처리, PIS-002 AC-3) |
| 사내 4M 첫 생산 로트(MES, P8 INT-012) | 이벤트 수동 발행 또는 수동 등록 경로 |
| 표준가·환율(Snowflake `CORE.SAP_*`, P4 INT-008) | 등록 쿼리 목을 WI가 L1으로 만든다(데모 목 없음) |
| 수입검사·NCR KPI(외부 트랙) | `90_CMN_KpiValue__c.csv` |

## 6. 데모 데이터

```bash
scripts/demo/load_salesforce.sh qms-int --upto-phase 6
```

| 파일 | 객체 | 적재 | 비고 |
| --- | --- | --- | --- |
| 33 | QMS_ChangeTypeRule__c | 전부 | 5 |
| 50 | QMS_SupplierCoa__c | 전부 | 811 |
| 52, 55, 57 | Hold·인정시험 계획·PPAP | 다시 실행해 4M·안정화 원천 채움 | |
| 60~62 | 4M·품번·검증 | 전부 | 12 + 13 + 17(S3, 무단 변경 1 포함) |
| 65 | QMS_SupplierFourMRequest__c | 전부 | 1 |
| 66 | QMS_StabilizationPlan__c | 전부 | 2(S3-STB 포함) |
| 68 | QMS_EightDSubmission__c | 전부 | 3 |
| 81 | QMS_SupplierCertificate__c | 전부 | 8 |
| 83 | CMN_ApprovalRequest__c | 다시 실행해 4M 대상 채움(이 페이즈에서 전부) | |

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G6-1 | 새 Org 배포·테스트·P6까지 적재 | 6.4절 | 실패 0 |
| G6-2 | 유형 규칙 해석(L3 없음 → L2, 규칙 없음, 유형 2개 합성) | 4MC-001 AC-2~4 | 대체 규칙, RiskClass A, 엄한 값 |
| G6-3 | 렌즈 품번 4M 신청 → BOM 영향 FG 3개 → 리스크 확정 | 4MC-003 AC-1·3·4 | 영향 품번, 리스크 상향, PFMEA·CP 필수 항목 |
| G6-4 | 계획 결재 승인 → 인정시험 2·PPAP 1 생성, 콜백 재처리 | 4MC-005 AC-2·3 | 생성, 멱등 |
| G6-5 | 협력사 4M 포털 신청 → SQE 접수 | 4MC-004 AC-2·4 | SUPPLIER 4M 생성, 타 협력사 권한 없음 |
| G6-6 | 4M 초품 성적서 → 로트 매칭 → 강화·전수, 첫 적용 로트 | IQC-006 AC-4, 4MC-007 | TIGHTENED·전수, 첫 로트 기록 |
| G6-7 | 성적서 규격 이탈(S9 감마LED) | IQC-006 AC-1 | OOS_HOLD, SQE 알림 |
| G6-8 | PPAP 승인 이벤트 → 안정화 계획·Hold → 일 집계 이벤트 2회 → 해제 | PIS-001 AC-1, PIS-002 AC-3, PIS-003 AC-1·3 | 계획 1·Hold 1, 갱신 1회, 해제 후 기본 수준 |
| G6-9 | S3 전체: `S3-4M` → `S3-QUAL` → `S3-PPAP` → 적용 결재 → `S3-IQC-FIRST` → `S3-STB` ACTIVE 2로트 | 데모 S3 | 각 단계 레코드와 상태가 연결되어 보임, 새 4M 1건으로 같은 흐름 재현 |
| G6-10 | S2 협력사 8D: CONTAINMENT 제출 → 수락 | CLM-005 AC-1·3·4 | 봉쇄 없으면 차단, 수락 시 D1~D3 APPROVED |
| G6-11 | 보증시험 배치 2회, FAIL → Hold → 다음 PASS → 해제 | PWT-001 AC-1·2, PWT-002 AC-2·3 | 계획 1건, Hold 생성·해제 |
| G6-12 | DVP&R PDF(BMW 형식)·Excel, 재시험 이력 | DVQ-009 AC-1·2 | Rev 1 RELEASED, 1차 FAIL·2차 PASS 한 행 |
| G6-13 | 클레임 비용 KRW·USD 합계, 사내 귀책 구상 | CLM-010 AC-1·2 | 5,800,000원, 차단 |
| G6-14 | **회귀 AC(실제 객체)**: APPROVED 4M 삭제, CN01 4M 결재선, 4M 적용 결재 위임 | SEC-003 AC-1, APV-002 AC-1, APV-004 AC-3 | 차단, 王OO, 유형별 위임 |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | **D-3 Multi-Currency**(CLM-010·NCR-007 착수 전, 정의 파일 영향) |
| 결정 | D2-4·D6A-3(CONDITIONAL로 적용 허용), D6A-1(4M 결재 2회), D6A-2(협력사 4M 신청 객체), D6A-4(첫 적용 로트 기준), D6A-8(처분 SAP는 이벤트로), D6A-9(COPQ 단가·비용 권한) |
| 결정 | D3-7(안정화 엔진 공용·자동 생성), D3-8(보증시험은 인정시험 엔진), D4-9(고객 PPAP 레코드타입), D5-7(구상은 포털 합의까지) |
| 명세 | 데모 보강(CR-6): 4MC-001 ExternalKey, 4MC-002 ExternalKey·DTO 2종, CLM-005 ExternalKey, SPP-003 ExternalKey |
| 명세 | review-pack 3절 약 16건(DVQ-009·010, IQC-006·007, PIS-001·002·003, PWT-002, 4MC-003·007, NCR-008, B2B-003·CLM-010) |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| D-3 지연 | CLM-010·NCR-007을 레인 D 마지막으로 미루고 나머지 먼저. 결정이 P7까지 넘어가면 두 WI를 P7로 옮김(`phase-map.csv`) |
| 4M ↔ 인정시험 ↔ PPAP ↔ 안정화 이벤트 사슬이 길어 디버깅 어려움 | 사슬의 각 이벤트를 `CMN_Log__c` INFO로 남기는 테스트 설정, S3 흐름을 통합 테스트 클래스 하나로 묶어 회귀 |
| 포털 화면이 한꺼번에 7종 | `qmsPortalDocUpload` 공통 컴포넌트와 SPP 규칙을 먼저 재확인, 화면별 Jest 상태 테스트 |

## 10. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| | | | |
