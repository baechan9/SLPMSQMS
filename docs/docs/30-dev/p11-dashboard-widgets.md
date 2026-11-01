# P11 품질 위젯·대시보드

Vol.7의 위젯 콘텐츠(DSH-005~012), 역할별 템플릿(DSH-013), 품질 종합 Dashboard(DSH-014, PoC 시나리오 5), 협력사 포털 요약(DSH-015), 운영 위젯(DSH-016)을 만든다. P7에서 만든 공용 라이브러리(DSH-001~004)와 각 메뉴의 KPI·등록 쿼리를 소비하는 페이즈다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | 메뉴별 위젯 90여 종이 공장·비용 권한과 화면 상태 표준을 지키며 표시되고, 역할별 템플릿과 품질 종합 Dashboard가 동작. 질문 위젯은 Vol.8 없이 대체 경로로 동작 |
| 기간(4명 기준) | 누적 264영업일(P10 이후 약 13일) |
| 마일스톤 | S5 대시보드(질문은 대체 경로, 응답은 P12) |
| 착수 조건 | 위젯이 보여 줄 메뉴의 KPI·쿼리 WI `개발 완료`(DSH-005: P6·P9, DSH-006: P7·P8, DSH-007: P6, DSH-008: P5·P8, DSH-009: P9, DSH-010: P10, DSH-011: P4~P8) |
| 다음 페이즈로 당겨 착수 가능 | P12 AIQ-001(선행 CMN뿐), AI-002·003 |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 12건 · 50 M/D · W1 7 · W2 5 · SF 트랙 12건 · 외부 트랙 0건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | QMS-07-DSH-005 | 수입검사·협력사 품질 위젯 | W1 | 5 | SF | — | — |
| A2 | QMS-07-DSH-006 | 공정·제품 품질 위젯(SPC·초기유동·출하검사·EOL) | W1 | 5 | SF | — | — |
| A3 | QMS-07-DSH-007 | 부적합·4M 위젯 | W1 | 4 | SF | — | — |
| A4 | QMS-07-DSH-008 | 고객 품질 위젯(B2B·클레임·8D) | W1 | 5 | SF | — | — |
| B1 | QMS-07-DSH-009 | 심사·인증·개선 과제 위젯 | W2 | 4 | SF | — | — |
| B2 | QMS-07-DSH-010 | 측정·교육·분석실·한도견본 위젯 | W2 | 3 | SF | — | — |
| B3 | QMS-07-DSH-011 | 레슨런·수평전개·PPAP 위젯 | W2 | 3 | SF | — | — |
| C1 | QMS-07-DSH-012 | AI 조기경보·AI 정확도·품질 질문 위젯 | W1 | 5 | SF + Agentforce | — | 순환 해소: Vol.8 위젯은 IsActive=false로 두고 P12에서 활성화(CR-1) |
| C2 | QMS-07-DSH-013 | 역할별 추천 템플릿·페르소나 해석 | W1 | 4 | SF | DSH-006, DSH-008, DSH-007, DSH-005 | — |
| C3 | QMS-07-DSH-014 | 품질 종합 Dashboard(PoC 시나리오 5) | W1 | 5 | SF | DSH-012, DSH-006, DSH-008, DSH-007, DSH-005 | 질문 응답은 P12에서 완성 |
| D1 | QMS-07-DSH-015 | 협력사 포털 품질 요약 | W2 | 3 | SF + 포털 | — | — |
| D2 | QMS-07-DSH-016 | KPI 신선도·위젯 성능·사용 현황·연계 상태 위젯 | W2 | 4 | SF | DSH-013 | — |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

모든 위젯 WI는 P7 DSH-004의 등록 규칙·체크리스트를 따른다. 새 KPI가 필요하면 그 KPI의 소유 WI에 변경 요청을 올리고, 위젯 WI가 KPI를 만들지 않는다.

### 레인 A — 업무 위젯 1(DSH-005·006·007·008)

| WI | 위젯 | 원천 |
| --- | --- | --- |
| DSH-005 | 수입검사·협력사 품질 14종 | IQC-007·PWT-002·SQM-002 KPI |
| DSH-006 | 공정·제품 품질 15종, `qmsSpcChart` 위젯 등록 | SPC·FQC·EOL·EFC KPI와 쿼리 |
| DSH-007 | 부적합·4M 13종, 리스트뷰 7개 | NCR-008·4MC-008 KPI, 비용 데이터 보안(NCR-008 BR-4) |
| DSH-008 | 고객 품질 14종, Vol.5 컴포넌트 2종 등록 | B2B·클레임·8D KPI와 쿼리 |

### 레인 B — 업무 위젯 2(DSH-009·010·011)

| WI | 위젯 | 원천 |
| --- | --- | --- |
| DSH-009 | 심사·인증·개선 과제 12종 | IAU-007·CER-001·IMP-002 |
| DSH-010 | 측정·교육·분석실·한도견본 13종 | GAU-002·MSA-005·TRN-003·LAB-004·LMS-002 |
| DSH-011 | 레슨런·수평전개·PPAP 11종 | LEL-005·HZD-003·RPP-004·PPA-004 |

### 레인 C — AI 위젯·템플릿·종합 Dashboard(DSH-012 → DSH-013 → DSH-014)

1. **DSH-012**(CR-1): Lightning Message Channel `QMS_AskQualityChannel`(`force-app-qms`, CR-7), `qmsAskQualityWidget`(ASK 발행 → 1.5초 ACK 대기 → **ACK 없으면 클립보드 대체 경로**, BR-1(d)), `qmsAiAccuracyWidget`, `QMS_SuggestedQuestion__mdt`(ko·en_US·zh_CN). Vol.8 위젯(`qmsRiskTopWidget`, `qmsEarlyWarningWidget`의 쿼리 `QMS_EW_TOP_RISKS`, AI 사용량)은 **IsActive = false로 등록**하고 P12에서 켠다(BR-3).
2. **DSH-013**: 템플릿 9종(`CMN_DashboardTemplate__mdt`·Item), 페르소나 해석 규칙 메타데이터와 해석기(우선순위 D7-6), config 토큰, PMS 템플릿 권고.
3. **DSH-014**: 앱 페이지 `QMS_Quality_Overview`(왼쪽 대시보드 + 오른쪽 Agentforce 패널 자리), `qmsQualityOverview`, `qmsOverviewFilterBar`, 채널 `QMS_DashboardFilterChannel`, 섹션 구성(섹션 5 질문 = DSH-012 채널), PoC 데모 데이터 생성 스크립트(합성 데이터만, D7-8).

### 레인 D — 포털·운영(DSH-015, DSH-016)

1. **DSH-015**: 포털 홈 요약 컴포넌트, 포털 전용 집계 Apex, 포털 공개 KPI 6종(완료 월만, 타사 순위 비공개 — D7-7). 포털 홈 배치는 SPP-002 변경 요청.
2. **DSH-016**: KPI 신선도 점검 잡·결과 객체, `QMS_WidgetTelemetry__e`·`QMS_WidgetUsageDaily__c`, 운영 화면, 캐시 비우기, 관리자 템플릿 연계 상태·KPI 지연 위젯 5종(QMS-09-INT-002 모니터 소비).

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| Lightning 앱 페이지 `QMS_Quality_Overview` | DSH-014 메타데이터 | Agentforce 패널 자리는 P12에서 채움 |
| 메시지 채널 2종 | `QMS_AskQualityChannel`, `QMS_DashboardFilterChannel` | |
| 템플릿·페르소나 | 데모 사용자별 PSG로 페르소나 확인(품질팀장 E1101, 엔지니어 E1102·E1103, 검사원 E1104, SQ 팀장 E1111, SQE E1112, 고객품질 E1202, 계측 E1151) | |
| 포털 홈 | DSH-015 컴포넌트 배치 | 시나리오 협력사 포털 사용자 |
| 위젯 텔레메트리 | Platform Event 발행 한도 확인 | |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| KPI 값 | `90_CMN_KpiValue__c.csv`, S5 기대값 `expected/kpi_S5.csv` |
| 등록 쿼리(Snowflake) | 메뉴별 `mocks/dwh` 목(P5~P10에서 만든 L1 목 포함) |
| Vol.8 질문 응답 | ACK 없음 → 클립보드 대체 경로(명세가 정한 동작) |
| 조기경보·AI 정확도 KPI | 위젯 비활성(P12에서 활성) |

## 6. 데모 데이터

새 Salesforce CSV는 없다. `qms-int`는 P10까지의 전체 데모 데이터를 그대로 쓴다. DSH-014의 PoC 데모 데이터 생성 스크립트는 기존 데모 데이터와 키가 겹치지 않게 만들고(`DEMO-` 키 운영 배포 차단, D7-8), 데모 데이터 생성기(`data/demo/generator`)와 역할이 겹치면 생성기 쪽에 합치는 것을 권한다.

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G11-1 | 새 Org 배포·테스트·전체 데모 적재 | 6.4절 | 실패 0 |
| G11-2 | 페르소나별 첫 홈(데모 사용자 7명) | DSH-013, CMN DSH-001 AC-1 | 템플릿대로 위젯 구성 |
| G11-3 | KR01 사용자와 전 공장 권한 사용자의 같은 위젯 | DSH-002, D7-2 | 공장 필터 차이 |
| G11-4 | 비용 위젯을 `QMS_ViewCost` 없는 사용자로 | DSH-007, D7-4 | 비용 미표시 |
| G11-5 | 등록 쿼리 위젯 상태 5종(목) | spec-snowflake-display | 로딩·빈 결과·오류·지연·잘림 표시 |
| G11-6 | S5: `QMS_Quality_Overview` 필터 변경 → 섹션 위젯 동기화 | DSH-014, `expected/kpi_S5.csv` | 필터 채널 반영, KPI 값 일치 |
| G11-7 | 질문 위젯에서 질문(Vol.8 없음) | DSH-012 BR-1(d) | 1.5초 뒤 클립보드 복사 + 안내 토스트 |
| G11-8 | 협력사 포털 요약 | DSH-015, D7-7 | 공개 KPI 6종, 완료 월만, 타사 정보 없음 |
| G11-9 | KPI 신선도 지연 경보, 위젯 사용 현황 집계 | DSH-016 | 지연 KPI 표시, 일별 집계 |
| G11-10 | 홈 첫 화면 3초(위젯 8개) | CMN DSH-001 AC-4 | Scratch Org에서는 참고 측정, 판정은 UAT |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D7-4 비용 정보 통일, D7-5 종합 Dashboard 고정 구성, D7-6 템플릿·페르소나 우선순위, D7-7 포털 공개 KPI, D7-8 PoC 합성 데이터 |
| 명세 | CR-1 DSH-012 선행 정리(분할 또는 선행 수정) |
| 명세 | SPP-002 포털 홈 배치(DSH-015 요청), 새 KPI가 필요한 위젯은 KPI 소유 WI 변경 요청 |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| 위젯 90여 종의 KPI 키·쿼리 키가 소유 Vol.과 어긋남 | DSH-001 정의 누락·미적재 점검 리포트를 게이트 전 실행, 누락 0 |
| 위젯마다 비슷한 코드가 늘어남 | 위젯 WI는 메타데이터 등록 중심, 새 컴포넌트는 DSH-003 라이브러리로 안 될 때만 |
| 페르소나 해석이 PSG 이름 변경에 취약 | 해석 규칙을 메타데이터(`QMS_DashboardPersonaRule__mdt`)로 |

## 10. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| | | | |
