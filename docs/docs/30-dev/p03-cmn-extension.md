# P3 공통 확장·QMS 연계 공통

결재 UI·위임·독촉, 모바일, 회의, 위젯 대시보드 프레임워크와 홈, 포탈 To-Do API, Snowflake ↔ Salesforce 수신·조회 경로, AI 추천 기록, QMS 연계 공통 프레임을 만든다. QMS 업무 WI가 W1에서 바로 쓰는 공통 기능이다. DWH-004(W2)는 W1 WI 10건의 선행이라 여기로 당겼다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | QMS 업무 화면이 붙을 결재 UI·홈·위젯 보드, Snowflake KPI·알람 수신과 드릴다운 호출 경로, AI 추천 기록 서비스가 동작 |
| 기간(4명 기준) | 누적 51영업일(P2 이후 약 17일) |
| 마일스톤 | 결재 UI·위임, KPI 수신, 위젯 보드. 외부 트랙이 준비되면 첫 L3 연결 |
| 착수 조건 | CMN WI는 선행이 끝나면 P2 게이트 전에도 착수(롤링). QMS-09-INT-001~003은 QMS WI이므로 W0(P1·P2) 전부 `개발 완료` 후 |
| 다음 페이즈로 당겨 착수 가능 | P4 중 DVQ-001, PPA-001, IQC-001, SPP-001(선행이 CMN뿐인 것) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 22건 · 109 M/D · W0 2 · W1 17 · W2 3 · SF 트랙 21건 · 외부 트랙 1건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | CMN-00-APV-004 | 대리결재(위임) | W1 | 4 | SF | — | — |
| A2 | CMN-00-APV-005 | 결재 지연 알림·에스컬레이션 | W2 | 2 | SF | — | — |
| A3 | CMN-00-MTG-001 | 회의 관리 | W2 | 5 | SF | — | 앞당김: UX-009의 선행 |
| A4 | CMN-00-UX-001 | 모바일·멀티 브라우저 지원 | W1 | 3 | SF | — | — |
| A5 | CMN-00-APV-003 | 결재 상신·처리·이력 UI | W1 | 6 | SF | UX-001 | — |
| A6 | CMN-00-UX-006 | 공통 편집 그리드 | W1 | 7 | SF | UX-004, UX-005 | 화면 전략 2026-11-05 공통 화면 부품(A0에서 완성) |
| A7 | CMN-00-UX-008 | 현장 입력 셸 | W1 | 7 | SF | UX-001, UX-006 | 화면 전략 2026-11-05 공통 화면 부품(A0에서 완성) |
| A8 | CMN-00-UX-009 | 체크리스트 수행 화면 | W1 | 6 | SF | UX-001, UX-004, UX-006, MTG-001 | 화면 전략 2026-11-05 공통 화면 부품(A0에서 완성) |
| B1 | CMN-00-DSH-001 | 위젯 대시보드 프레임워크 | W1 | 7 | SF | — | 앞당김: UX-004의 선행 |
| B2 | CMN-00-TDO-003 | 포탈 To-Do 연계 API | W1 | 5 | SF + 연계 시뮬 | — | — |
| B3 | CMN-00-TDO-004 | QMS·PMS 메인 홈 | W1 | 3 | SF | DSH-001 | — |
| B4 | CMN-00-UX-004 | 업무 레코드 작업공간 템플릿·결정 지원 레일 | W0 | 6 | SF | DSH-001 | 화면 전략 2026-11-05 공통 화면 부품(A0에서 완성) |
| B5 | CMN-00-UX-005 | 상태·권한 화면 제어 매트릭스 | W0 | 5 | SF | UX-004 | 화면 전략 2026-11-05 공통 화면 부품(A0에서 완성) |
| B6 | CMN-00-UX-007 | 앱 구성·메뉴 허브 | W1 | 4 | SF | TDO-004 | 화면 전략 2026-11-05 공통 화면 부품(A0에서 완성) |
| C1 | CMN-00-DWH-003 | Snowflake → Salesforce KPI·알람 전달 | W1 | 6 | SF + DW 목 + 연계 시뮬 | — | — |
| C2 | CMN-00-DWH-004 | 상세 데이터 조회 API(드릴다운) | W2 | 4 | SF + DW 목 + 연계 시뮬 | — | callProcedure 확장 함께 반영 권고(CR-9) / 앞당김: QMS-04-RPP-002·QMS-04-SPC-003·QMS-04-SPC-006 외의 선행 |
| C3 | QMS-09-INT-001 | QMS 연계 공통 프레임·카탈로그·코드 매핑 | W1 | 6 | SF + DW 목 + 연계 시뮬 | — | — |
| C4 | QMS-09-INT-002 | 외부 요청 수신 규약·동기화 상태 모니터·재전송 | W1 | 5 | SF + DW 목 + 연계 시뮬 | DWH-003, INT-001 | — |
| C5 | QMS-09-INT-003 | 연계 테스트 환경·목(mock)·PoC 데이터 주입 | W1 | 4 | SF + DW 목 + 연계 시뮬 | INT-001 | — |
| D1 | CMN-00-AI-001 | Agentforce·Trust Layer 기반 설정 | W1 | 4 | SF + Agentforce + Data Cloud(Sandbox) | — | Agentforce 스파이크 결과에 따름 |
| D2 | CMN-00-AI-004 | AI 추천 기록·채택·정확도 측정 | W1 | 5 | SF + DW 목 | AI-001, DWH-002 | — |
| X1 | CMN-00-DWH-002 | Salesforce → Snowflake 복제 | W1 | 5 | 외부 트랙 | — | — |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

### 레인 A — 결재 UI·모바일·회의(UX-001 → APV-003, APV-004, APV-005, MTG-001)

1. **UX-001**: 모바일 앱·모바일 웹·멀티 브라우저 기준, `formFactors` Small 포함 규칙, 사진 첨부 시 장변 1920px 축소. AC-1(NCR 사진)은 테스트 대상 객체로, P5 NCR-002에서 다시 확인. review-pack 변경 요청 1건.
2. **APV-003**: `cmnApprovalLine`, 상신·처리·이력 LWC(버전 구분), 개인 결재선 저장·불러오기, 반려 의견 필수(화면·서버).
3. **APV-004**: `CMN_Delegation__c`(유형 범위 TypeCodes, 기간), 위임자·수임자 To-Do 동시 표시와 자동 종료. 데모 보강: `ExternalKey__c`(`DLG-{위임자 사번}-{시작일}`).
4. **APV-005**: 공장 09:00 독촉 잡(공장 시간대), 같은 날 중복 방지, 에스컬레이션.
5. **MTG-001**: 회의·조치 항목, 회의록 확정 시 담당자별 To-Do, 확정 후 수정 차단. review-pack 변경 요청 1건. P9 CER-002(경영검토)가 이것을 쓴다.

### 레인 B — 위젯 보드·홈·포탈 API(DSH-001 → TDO-004, TDO-003)

1. **DSH-001**: `CMN_Widget__mdt`(위젯 계약 `@api config`, `@api size`, ConfigSchema — Vol.7 요청), `cmnWidgetBoard`(편집 모드·저장·위젯 단위 오류 격리), 역할 템플릿 복사. 테스트용 위젯 1~2개로 확인한다. review-pack 변경 요청 1건.
2. **TDO-004**: SL QMS 홈(To-Do 목록 + 위젯 보드, 기본 필터 QMS, 위젯 지연 로딩).
3. **TDO-003**: 포탈 To-Do 연계 REST API(건수·목록, category·lang 파라미터). 외부 포탈 인증 방식(OAuth 클라이언트 자격 증명 등)은 Connected App·External Client App 중 Org에서 지원되는 것으로. AC-3(동시 500, p95 1초)은 UAT 항목으로 넘긴다.

### 레인 C — Snowflake 수신·조회와 QMS 연계 공통(DWH-003, DWH-004 → QMS-09-INT-001 → INT-002, INT-003)

1. **DWH-003**(Salesforce 쪽): `CMN_KpiValue__c`(ExternalKey 해시, 13개월 보존 삭제), `CMN_ResultInbound__e`, `CMN_InboundRoute__mdt`, `CMN_InboundHandler`, `CMN_InboundReceipt__c`(멱등, UNROUTED, FAILED·재처리 버튼). review-pack 변경 요청 7건(KPI 키 `QMS_CPK` → `QMS_SPC_CPK` 포함). 이 WI에서 `scripts/apex/publish-inbound.apex`(EventType·Payload를 받아 이벤트 발행)를 만들어 이후 모든 페이즈가 알람을 흉내 낼 때 쓴다.
2. **DWH-004**(Salesforce 쪽): `CMN_DwQueryService.query`, `CMN_DwQuery__mdt`(SqlTemplate, AllowedParams, MaxRows), Named Credential + External Credential, 공장 권한 파라미터 강제, `truncated`. **CR-9**: 프로시저 호출 모드 `callProcedure`도 이 WI에서 함께 만든다(P10 MSA-003이 필요, QMS-09-INT-020이 Mule 쪽). 화면 상태 표준은 `spec-snowflake-display.md`를 따른다. review-pack 변경 요청 5건.
3. **QMS-09-INT-001**(Salesforce 쪽): 이벤트 구독·upsert 템플릿 클래스, 코드 매핑 메타데이터, 인터페이스 28건 `CMN_Interface__mdt` 등록, 환경 매핑. Mule 공통 라이브러리는 외부 트랙.
4. **QMS-09-INT-002**: 동기화 모니터 설정·화면(`qmsSyncMonitor`), 재전송 인터페이스, 자동 재동기화 잡, 수동 완료, 외부 요청 이벤트 규약과 핸들러 기반 클래스, 연계 KPI(QMS_INT_FAILED 등). 이후 원천 요청 핸들러는 이 기반 클래스를 상속한다.
5. **QMS-09-INT-003**: 계약 스키마(`integration/contracts/{if-id}.schema.json` — 디렉터리 이름은 P0 CR-7 결정), PoC 주입 스크립트 틀. 목 Mule 앱·합성 데이터 프로시저는 외부 트랙에서 우선 진행한다(L3의 전제).

### 레인 D — AI 기반(AI-001 → AI-004)

1. **AI-001**: Agentforce Employee Agent 2개 틀(`SL Quality Assistant`, `SL Project Assistant`), 공통 Action `CMN_AiAction_*`(Invocable, `with sharing` + `WITH USER_MODE`), Trust Layer 설정, 기능 스위치 키(QMS_AI_RCA 등, review-pack 요청 1건). P0 스파이크(S-4)에서 Agentforce가 안 켜졌으면 Apex Action과 테스트만 여기서 하고, 에이전트 메타데이터는 대안 Org에서 확인한다.
2. **AI-004**: `CMN_AiRecommendation__c`·`CMN_AiRecommendationService`·`CMN_AiHitRule`·`cmnAiRecommendationList`(채택·제외 사유 필수·확정 비교). UseCase 값 추가 4건(QMS_COA_ANOMALY, QMS_4M_TEST 등, review-pack). 정확도 KPI 계산은 DWH-002(외부 트랙)를 거쳐 Snowflake에서 하므로 Scratch Org에서는 기록·채택·적중 판정까지 확인한다.

### 레인 X — 외부 트랙(DWH-002)

Mule Bulk API `queryAll` 증분 추출 → `RAW.SF_*` → `CORE.SF_*` MERGE. `CMN_DwhSyncConfig__mdt` 레코드(Salesforce 메타데이터)는 이 WI 범위이므로 SF 쪽 메타데이터만 Scratch Org에 배포해 둔다.

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| Named Credential·External Credential(`prc-dw-query-api`) | DWH-004 메타데이터. 주소는 Mule DEV, 인증 값은 사용자별 수동 입력 | 비밀값을 저장소에 두지 않음 |
| Agentforce | P0 S-4 결과 | 안 되면 대안 Org |
| 포탈 API 인증 | Connected App 또는 External Client App 메타데이터 | 클라이언트 비밀값은 수동 |
| Lightning 앱 홈 페이지 | TDO-004 메타데이터 | |
| 모바일 확인 | Salesforce 모바일 앱으로 Scratch Org 로그인(My Domain) | UX-001, APV-003 |

## 5. 목·대체

| 의존 | L1(단위) | L2(Scratch 화면) | L3(연계) |
| --- | --- | --- | --- |
| Snowflake KPI(DWH-003) | 핸들러 단위 테스트 | `90_CMN_KpiValue__c.csv` 적재 | Mule이 MART 뷰를 읽어 upsert |
| Snowflake 알람(DWH-003) | 이벤트 발행 테스트 | `scripts/apex/publish-inbound.apex`로 `CMN_TEST` 발행 | `SHARE.OUTBOUND_EVENT` → Mule 1분 폴링 → 발행(AC-2) |
| 드릴다운(DWH-004) | `HttpCalloutMock` + `data/demo/mocks/dwh` | 오류·지연 상태 표시까지 | Mule DEV `prc-dw-query-api` 연결 |
| 포탈 To-Do API 소비자 | Apex REST 테스트 | `curl`로 세션 토큰 호출 | 사내 포탈(SIT) |

외부 트랙이 이 페이즈 안에 `mock-source-systems`와 `prc-dw-query-api`를 DEV에 올리면 L3를 여기서 처음 확인한다. 못 하면 L3 확인은 다음 페이즈 게이트로 넘기고 게이트 기록에 남긴다. DEV-1(개발 목 응답 모드) 결정이 이 페이즈 착수 전에 필요하다.

## 6. 데모 데이터

```bash
scripts/demo/load_salesforce.sh qms-int --upto-phase 3
```

| 파일 | 객체 | 비고 |
| --- | --- | --- |
| 23 | CMN_Delegation__c | E1101 → E1102, 2026-12-01~12-05 |
| 90 | CMN_KpiValue__c | Snowflake 데이터 작업 소유 CSV |

**데모 기준일 주의**: 데모 데이터는 기준일 2026-12-01에 맞춰 만들어졌다. Scratch Org의 오늘은 실제 날짜라서, 위임 기간·기한 경과·독촉처럼 오늘과 비교하는 시나리오는 게이트 날짜에 따라 결과가 달라진다. P0 데모 로더 작업과 함께 생성기 기준일 지정(`generate_all.py --today`)으로 게이트 날짜 기준으로 데이터와 기대값을 다시 만들기를 권한다(dev-plan 11절). 그 전에는 날짜를 바꾼 테스트 레코드로 확인한다.

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G3-1 | 새 Org 배포·RunLocalTests·데모 P3까지 적재 | 6.4절 | 실패 0 |
| G3-2 | 모바일 웹에서 의견 없이 반려, 이력, 개인 결재선 | APV-003 AC-1~3 | 차단, 버전 구분, 필수 단계 유지 |
| G3-3 | 위임 기간 안 A 결재 도래, 기간 후, 유형 제한 | APV-004 AC-1~3 | A·B To-Do, B 처리 시 A 종료, 기간 후 없음, 유형 밖 없음 |
| G3-4 | 독촉 잡 2회 실행 | APV-005 AC-1 | 알림 1건 |
| G3-5 | 회의록 확정·수정 | MTG-001 AC-1·2 | 조치 담당별 To-Do, 수정 차단 |
| G3-6 | 신규 품질팀장 홈, 편집 저장, 위젯 1개 예외 | DSH-001 AC-1~3 | 템플릿 표시, 재로그인 후 같은 배치, 나머지 정상 |
| G3-7 | QMS·PMS To-Do가 섞인 홈 | TDO-004 AC-1 | 기본 QMS만, 전체 필터 시 모두 |
| G3-8 | 포탈 To-Do API category·lang | TDO-003 AC-1·2 | 건수·제목 언어 |
| G3-9 | `CMN_TEST` 2회 발행, 미등록 유형 | DWH-003 AC-1, BR-3 | 핸들러 1회, UNROUTED + WARN |
| G3-10 | 미등록 QueryKey, KR01 사용자의 CN01 조회(목) | DWH-004 AC-1·2 | 예외, 0건 |
| G3-11 | 추천 3건 중 2위 채택·제외 사유 없이 제외 | AI-004 AC-1·2 | 적중 집계, 차단 |
| G3-12 | 동기화 모니터에서 실패 건 재전송 | QMS-09-INT-002 | 재전송 기록 |
| G3-13 | (외부 트랙 준비 시) L3: `CMN_TEST` 왕복, 등록 쿼리 1건 | DWH-003 AC-2, DWH-004 | 2분 안에 PROCESSED, 실제 응답 |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D-4 Data Cloud 범위(DWH-002 복제 방식, DWH-004 대체 여부, AI-002) |
| 결정 | DEV-1 개발 목 응답 모드(dev-plan 7.2절) |
| 결정 | D-10 AI "학습" 정의(AI-004 정확도 측정 방식) |
| 결정 | CR-3 게이트웨이 프레임워크 분리(`QMS-02-DVQ-007a`) — 승인되면 이 페이즈 레인 B에서 착수(선행 ARC-002·TDO-001) |
| 명세 | review-pack 2절 Vol.0 변경 요청 20건: DWH-003 7, DWH-004 5, AI-004 4, AI-001 1, DSH-001 1, MTG-001 1, UX-001 1 |
| 명세 | CR-9 DWH-004에 `callProcedure` 추가, 데모 보강 APV-004 Delegation ExternalKey |
| 명세 | review-pack 3절 중 QMS-09·interfaces.md 대상 각 1건 |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| 외부 트랙 미준비로 L3 확인 지연 | L1·L2로 WI 완료, L3는 별도 기록. P4 게이트까지 L3 첫 연결을 목표로 외부 트랙 우선순위 조정 |
| Agentforce 미지원 | AI-001은 Apex·테스트만 완료 처리하고 에이전트 확인을 P12 전 대안 Org로 |
| 위젯 프레임워크 계약이 Vol.7 요구와 어긋남 | DSH-001 착수 전 Vol.7 DSH-003·004 계약(ConfigSchema)을 함께 읽는다 |

## 10. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| | | | |
