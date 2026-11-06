# P7 SPC·레슨런·고객 PPAP 증빙

SPC의 Salesforce 쪽(계획·한계·알람·OCAP·관리도 화면), 품질 대시보드 공용 기반(KPI 정의 레지스트리, 위젯 데이터 서비스, 차트·KPI 컴포넌트, 위젯 설정 폼), 레슨런 체크포인트·규칙 매칭·후속 모델 반영, 고객 PPAP 증빙 수집·PSW 결재를 만든다. SPC 화면(SPC-006)이 차트 라이브러리(QMS-07-DSH-003)를 쓰므로 대시보드 기반을 여기로 당겼다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | SPC 알람 → OCAP 조치 → NCR 요청, 관리도·공정능력 화면(목 응답 상태 5종), 레슨런 규칙 매칭과 반영 검토가 동작(KPI 위젯 공용 컴포넌트는 2026-11-06 기반 P3로 옮김) |
| 기간(기본 인원) | 누적 155영업일(P6 이후 약 27일). QMS 4명·PMS 3명 시뮬레이션(2026-11-06, [개발 플랜](dev-plan.md) 9.2절) |
| 마일스톤 | S7 SPC(알람·화면, 계산은 외부 트랙), S6 규칙 매칭(AI 제외) |
| 착수 조건 | P5 NCR-002, P4 DVQ-007·009(RPP-002는 DVQ-009). 레슨런 LEL-005는 PMS 트랙 P17 INT-005(레슨런 이벤트 구독)의 선행이므로 레인 C를 늦추지 않는다 |
| 다음 페이즈로 당겨 착수 가능 | P8 중 FQC-001, HZD-001, B2B-002(선행이 앞 페이즈뿐인 것) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 12건 · 65 M/D · W1 10 · W2 2 · SF 트랙 11건 · 외부 트랙 1건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | QMS-04-SPC-001 | SPC 계획·관리도 설정 | W1 | 5 | SF + DW 목 | — | — |
| A2 | QMS-04-SPC-002 | 측정 데이터·부분군·관리 한계·이상 판정(Snowflake) | W1 | 7 | SF + DW 목 | SPC-001 | — |
| A3 | QMS-04-SPC-005 | SPC 알람 수신·OCAP 조치·NCR 연계 | W1 | 7 | SF | SPC-001 | — |
| A4 | QMS-04-SPC-003 | 공정능력(Cp·Cpk·Pp·Ppk) 계산·KPI·조회 서비스 | W1 | 5 | SF + DW 목 | SPC-002 | — |
| A5 | QMS-04-SPC-004 | 관리 한계 재계산·승인 | W2 | 4 | SF + DW 목 | SPC-001, SPC-002 | — |
| A6 | QMS-04-SPC-006 | 관리도·공정능력 화면 | W1 | 6 | SF | SPC-002, SPC-003 | — |
| C1 | QMS-04-LEL-003 | 체크포인트(개발 단계·액티비티 유형별 확인 항목) | W1 | 4 | SF | — | — |
| C2 | QMS-04-LEL-004 | 규칙 기반 매칭 서비스(QMS_LeleMatchService) | W1 | 5 | SF | LEL-003 | — |
| C3 | QMS-04-LEL-005 | 후속 모델 반영 검토·이력(QMS_LeleApplication__c) | W1 | 6 | SF | LEL-004 | — |
| D1 | QMS-04-RPP-002 | SL 내부 증빙 자동 수집 | W1 | 6 | SF + DW 목 | SPC-003 | — |
| D2 | QMS-04-RPP-003 | 내부 검토·PSW 서명 결재·제출 패키지 생성 | W2 | 5 | SF | RPP-002 | — |
| X1 | QMS-09-INT-010 | MES → Snowflake SPC 측정값(IF-MES-001) | W1 | 5 | 외부 트랙 | QMS-04-SPC-002 | — |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

레인 A의 SPC-006은 기반 P3로 옮긴 QMS-07-DSH-003을, 레인 D의 RPP-002는 레인 A의 SPC-003을 기다린다.

### 레인 A — SPC(SPC-001 → 002 → 003 → 004·005·006)

1. **SPC-001**: `QMS_SpcPlan__c`·`QMS_SpcLimit__c`, 이상 판정 규칙 메타데이터(R1~R8 중 활성), 계획 일괄 설정 화면, 1단계 한계 확정(W1 단순 확정), 복제 대상 등록.
2. **SPC-002**(플랫폼 SNOW·SF): Snowflake 쪽(CORE 측정·부분군·신호 테이블, 관리도 상수, 규칙 평가, 송출)은 외부 트랙 담당과 함께, Salesforce 쪽은 **한계 수신 핸들러**만. 상수는 데모 명세대로 계산식으로 구하고 표 값을 기억으로 넣지 않는다.
3. **SPC-003**(SNOW·SF): `CORE.SPC_CAPABILITY` 계산은 외부 트랙, Salesforce 쪽은 공정능력 조회 서비스와 KPI 키(`QMS_SPC_CPK`).
4. **SPC-004**: 한계 재계산 요청·미리보기(`QMS_SPC_LIMIT_PREVIEW`)·결재·적용 시점, 4M·정기 재검토 표시.
5. **SPC-005**: `QMS_OcapTemplate__c`·Step, `QMS_SpcAlarm__c`(신호 수신·묶음, EVENT_TYPE `QMS_SPC_ALARM` 핸들러), 확인 SLA·에스컬레이션, 모바일 조치 기록, NCR 게이트웨이 요청(SPC_ALARM), 공정능력 미달·데이터 누락 처리(D4-3: 미달 → NCR 자동은 PoC 데모 설정만), 공장 알람 보드. review-pack 3절 1건.
6. **SPC-006**(DSH-003 뒤): `qmsSpcChart`(Chart.js), 공정능력 카드(히스토그램), SPC 현황 페이지, 등록 쿼리, CSV 내보내기. 위젯으로 재사용할 수 있게 `@api config`·`@api size` 계약을 지킨다. review-pack 3절 1건.

### 레인 B — 대시보드 공용(2026-11-06 기반 P3로 옮김)

> 아래 네 WI는 PMS 대시보드(P18)도 쓰는 공용 라이브러리라 [P3](p03-cmn-extension.md) 레인 B로 옮겼다. 작업 내용 설명은 그대로 둔다(P3에서 이 설명을 따른다).

1. **DSH-001**: `QMS_KpiDefinition__mdt`(KPI 정의 레지스트리 — 이후 새 KPI는 반드시 등록, Vol.0 3.3 DoD 변경 요청), 정의 조회 서비스, `MART.KPI_RAG_RULE` 동기화(Snowflake 쪽 외부 트랙), 정의 누락·미적재 점검 리포트. 지금까지 각 Vol.이 만든 KPI 키를 모두 등록한다.
2. **DSH-002**: KPI 조회(스냅숏·시계열·차원 분해), 등록 쿼리 래퍼, 등록 집계·목록 실행기, 허용 목록 메타데이터 3종(`QMS_WidgetQuery__mdt`·`Count`·`List`), 공장 권한 필터(전 공장은 Custom Permission `QMS_DashboardAllPlants`, D7-2), 비용 권한(`QMS_ViewCost`), Platform Cache(용량 없으면 캐시 미스 경로).
3. **DSH-003**: 공통 JS 모듈, 컴포넌트 7종(`qmsKpiTile`, `qmsKpiTrend` 등), 정적 리소스 `cmnChartJs`(Chart.js 버전 고정, **`force-app-cmn`에 둠** — CR-7), 접근성(색만으로 구분 금지)·모바일, Jest.
4. **DSH-004**: `CMN_Widget__mdt.ConfigSchema__c` 규약, `cmnWidgetConfigForm`, 스키마 검증, 위젯 등록 규칙·체크리스트(P11 위젯 WI들이 따른다).

### 레인 C — 레슨런(LEL-003 → 004 → 005)

1. **LEL-003**: `QMS_LeleCheckpoint__c`, 편집 그리드, 상위 코드 집계, 액티비티 유형별 체크리스트 보기, CSV 내보내기.
2. **LEL-004**: `QMS_LeleMatchService.match`·REST, 가중치 메타데이터, 결과 설명. S6 기대값(`expected/lele_S6.json`)과 비교 — **이 파일은 아직 없다**(데모 명세가 AI 시나리오 작업 산출물로 둠). 데모 데이터 작업에 생성을 요청하거나, 그 전에는 규칙 점수 단위 테스트로 대신한다.
3. **LEL-005**: `QMS_LeleApplication__c`, `QMS_LeleApplicationService`(propose·decide·verify·getByProject·hasOpenMandatory), REST, 이벤트, 필수 미적용 결재(`QMS_LELE_WAIVE`, D4-8), 프로젝트 보드, PoC 문맥 입력 화면(PMS 없이 S6 시연, D8-10), KPI. review-pack 3절 2건.

### 레인 D — 고객 PPAP 증빙·서명(RPP-002 → RPP-003)

1. **RPP-002**(SPC-003 뒤): `QMS_PpapEvidence__c`, 수집기 인터페이스 `QMS_PpapEvidenceCollector`·`QMS_PpapCollector__mdt`, 수집기 구현(문서, 인정시험, 공정능력, 하위 부품 PPAP), 증빙 패널, 채택 규칙. MSA 수집기는 P10 MSA-005가 구현해 등록한다.
2. **RPP-003**: 요소 내부 검토, PSW·VDA 2 표지 입력·PDF, 서명 결재, 제출 패키지(목차 PDF + ZIP). Apex ZIP 생성 방식(플랫폼 Compression 기능 지원 여부)을 착수 때 확인한다.

### 레인 X — 외부 트랙(INT-010)

MES → Snowflake SPC 측정값. SPC-002의 Snowflake 쪽과 함께 L3의 실데이터가 된다.

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| `cmnChartJs` | Chart.js 버전 고정 파일(라이선스 확인)을 `force-app-cmn` 정적 리소스로 | SPC-006·P11 위젯 공용 |
| Platform Cache 파티션 | DSH-002 메타데이터(P0 S-6 결과) | 없으면 캐시 없이 |
| Custom Permission | `QMS_DashboardAllPlants`, `QMS_ViewCost`(P6) | 경영진·품질경영팀 PSG(`CMN_PSG_Executive` 등)에 포함. 데모 사용자(최대 5명)에 없으면 관리자 E1901로 확인 |
| REST | `/qms/v1/lele/...`(LEL-004·005) | `curl`로 확인, PMS 측 호출은 P12 AIQ-008 |
| 모바일 OCAP | 모바일 앱으로 알람 조치 | |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| SPC 계산·신호(Snowflake) | `93_QMS_SpcAlarm__c.csv`(기존 알람) + `publish-inbound.apex`로 `QMS_SPC_ALARM` 새 신호 발행 |
| 관리도·공정능력 조회 | `mocks/dwh/QMS_SPC_SUBGROUPS`(ok·empty·stale·truncated·error-timeout), `QMS_SPC_SIGNALS`, `QMS_SPC_LIMITS`, `QMS_SPC_CAPABILITY_*`, `QMS_SPC_HISTOGRAM`, `QMS_SPC_SPEC`, `QMS_SPC_PLAN_SUMMARY`, `QMS_SPC_MSA_STATUS`, `QMS_SPC_LIMIT_PREVIEW` |
| KPI 값 | `90_CMN_KpiValue__c.csv` |
| PMS 프로젝트·액티비티(S6) | PoC 문맥 입력 화면 + `scenario_keys.json`의 `s6Project` 텍스트 Id |

`mocks/dwh/QMS_SPC_SUBGROUPS`의 다섯 경우로 `spec-snowflake-display.md` 상태 표준(로딩·빈 결과·오류·지연·잘림)을 모두 화면에서 확인한다. 이 페이즈가 Snowflake 연계 화면 상태 표시의 기준 구현이 된다.

## 6. 데모 데이터

```bash
scripts/demo/load_salesforce.sh qms-int --upto-phase 7
```

| 파일 | 객체 | 적재 | 비고 |
| --- | --- | --- | --- |
| 54 | QMS_LeleCheckpoint__c | 전부 | 18 |
| 91, 92, 92u | SPC 계획·한계·계획 현재 한계 갱신 | 전부 | S7 렌즈 두께, S1 비드 폭, S13 조준각 포함 |
| 93 | QMS_SpcAlarm__c | 전부 | |

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G7-1 | 새 Org 배포·테스트·P7까지 적재 | 6.4절 | 실패 0 |
| G7-2 | S7 계획(`S7-PLAN`) 관리도 화면, 목 응답 5종 | SPC-006, spec-snowflake-display | 상태별 표시, 신호 점 표시 |
| G7-3 | S7 기대값 대조(목 응답 기준) | `expected/spc_S7.json#KR01-L02-OP10-C10` | R2 최초 발생일, R1 부분군, Cpk 값 일치(상대 1e-6) |
| G7-4 | `QMS_SPC_ALARM` 발행 2회 → 알람 묶음 → OCAP 조치(모바일) → NCR 요청 | SPC-005 | 알람 1건, 조치 기록, NCR 생성(바인딩 NCR) |
| G7-5 | 공정능력 미달 알람(PoC 설정 켬·끔) | SPC-005, D4-3 | 켬: NCR 자동, 끔: 개선 검토 To-Do |
| G7-6 | 한계 재계산 미리보기 → 결재 → 적용 | SPC-004 | 새 한계 적용 시점 |
| G7-7 | KPI 타일·추이(KR01 사용자, 전 공장 권한 사용자) | DSH-002·003, D7-2 | 공장 필터, 전 공장 보기 |
| G7-8 | 위젯 설정 폼 스키마 검증 | DSH-004 | 잘못된 config 저장 차단 |
| G7-9 | S6: 문맥 입력(BE3, OPT_DESIGN 등 7 액티비티) → 규칙 매칭 → 반영 제안 → 필수 미적용 결재 | LEL-004·005 | 액티비티별 추천(기대값 파일이 생기면 대조), `hasOpenMandatory` |
| G7-10 | 고객 PPAP 증빙 자동 수집 → 내부 검토 → PSW 서명 → 패키지 | RPP-002·003 | 증빙 패널, PDF·ZIP |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D4-1 SPC 계산 위치(MES에 SPC가 있으면 SPC-002 축소), D4-2 SPC 대상, D4-3 미달 → NCR 자동 |
| 결정 | D4-7 LELE ↔ PMS 매칭 키, D4-8 필수 체크포인트 미적용 결재 |
| 결정 | D7-1 RAG 단일화, D7-2 위젯 공장 권한, D7-3 RAG 초기 기준값 |
| 명세 | CR-7 `cmnChartJs`·메시지 채널 경로 |
| 명세 | review-pack 3절: SPC-005 1, SPC-006 1, LEL-004·005 1, LEL-005 1, Vol.4 KPI 뷰 전체 1 |
| 데이터 | `expected/lele_S6.json`(그리고 P12의 `ai_rca_S1`·`ai_rca_S2`·`ew_S11`·`qa_S5`) 생성 요청 — 데모 명세 2절에 있으나 아직 없음 |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| SPC 계산이 외부 트랙에만 있어 Salesforce 쪽 완료를 판단하기 어려움 | WI 완료 = 수신 핸들러·화면이 목 응답과 기대값 파일로 검증됨. 실계산 대조는 L3 게이트로 분리 |
| 대시보드 공용 계약이 P11 위젯 30여 종에 영향 | DSH-002 응답 DTO와 DSH-004 ConfigSchema를 이 페이즈 게이트에서 동결하고, 바꾸면 변경 요청으로 |
| Chart.js 버전·라이선스 | 버전을 정적 리소스 이름이나 메타 설명에 기록, 업데이트는 WI 변경으로만 |

## 10. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| | | | |
