# P12 품질 AI

Vol.8 품질 AI(AIQ-001~013·016)와 CMN AI 나머지(문서 검색 AI-002, 버전 비교 AI-003, 자연어 Q&A 프레임워크 AI-005), Snowflake 프로시저 호출 모드 운영 규약(QMS-09-INT-020)을 만든다. 바인딩 EIGHT_D_ASSIST가 실제 구현으로 바뀌고, P11에서 꺼 둔 AI 위젯을 켠다. PoC 시나리오 S1·S2·S5·S6의 AI 부분이 여기서 완성된다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | 원인 추천(8D D4·심사 지적·SPC 알람), 8D 초안, LELE 추천, 조기경보, 품질 Q&A(업무 현황·추세 통계), 품질 문서 검색이 사람 확정 원칙과 공장 권한을 지키며 동작하고, 모든 추천이 `CMN_AiRecommendation__c`에 기록됨 |
| 기간(4명 기준) | 누적 290영업일(P11 이후 약 26일) |
| 마일스톤 | S1·S2·S5·S6 AI 완성, S11 조기경보 |
| 착수 조건 | P0 S-4 결과에 따른 Agentforce 환경(Scratch Org 또는 대안 Org), D-4·D8-1 결정, AI 기대값 파일(9절) |
| 다음 페이즈로 당겨 착수 가능 | P13 AIQ-014·015(AIQ-006 뒤) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 18건 · 104 M/D · W1 10 · W2 8 · SF 트랙 15건 · 외부 트랙 3건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | CMN-00-AI-005 | 자연어 데이터 Q&A 프레임워크 | W2 | 6 | SF + DW 목 + 연계 시뮬 + Agentforce | — | 앞당김: QMS-08-AIQ-009·QMS-08-AIQ-010의 선행 |
| A2 | QMS-08-AIQ-001 | 품질 어시스턴트 토픽·공통 지시·사용 정책 | W1 | 5 | SF + Agentforce | — | — |
| A3 | QMS-08-AIQ-009 | 품질 Q&A — 업무 현황 Action | W1 | 5 | SF + Agentforce | AIQ-001, AI-005 | — |
| A4 | QMS-08-AIQ-010 | 품질 Q&A — 추세·통계(Cortex Analyst 시맨틱 모델·공장 권한) | W1 | 8 | SF + DW 목 + 연계 시뮬 + Agentforce | AIQ-001, AI-005, AIQ-002 | — |
| B1 | QMS-08-AIQ-002 | 품질 사례·레슨런 코퍼스와 의미 검색 서비스 | W1 | 7 | SF + DW 목 + 연계 시뮬 | AIQ-001 | — |
| B2 | QMS-08-AIQ-004 | 원인 추천 서비스·원천 어댑터·화면 연결 | W1 | 6 | SF + Agentforce | AIQ-001, AIQ-002, AIQ-003 | — |
| B3 | QMS-08-AIQ-005 | 8D 초안 지원(QMS_EightDAssist 구현) | W1 | 7 | SF + Agentforce | AIQ-004 | — |
| B4 | QMS-08-AIQ-006 | 추천 확정·적중 평가 자동화와 확정 사례 반영 | W1 | 5 | SF + DW 목 | AIQ-004 | — |
| C1 | QMS-08-AIQ-012 | 조기경보 처리·위험 화면·후속 조치 | W2 | 5 | SF + Agentforce | AIQ-001, AIQ-011 | 앞당김: QMS-07-DSH-012의 선행 |
| C2 | QMS-08-AIQ-007 | LELE 추천 서비스(규칙 후보 + 의미 순위 + 반영 초안) | W1 | 7 | SF + DW 목 + Agentforce | AIQ-001, AIQ-002 | — |
| C3 | QMS-08-AIQ-008 | PMS 연계 흐름·PoC 시나리오 6 시연 | W1 | 5 | SF + 연계 시뮬 | AIQ-007 | — |
| C4 | QMS-08-AIQ-016 | AI 평가·출시 기준·프롬프트 버전·사용량 운영 | W2 | 5 | SF + DW 목 + Agentforce | AIQ-001, AIQ-003, AIQ-007, AIQ-010, AIQ-011, AIQ-004 | 앞당김: QMS-07-DSH-012의 선행 |
| D1 | CMN-00-AI-002 | 문서 통합 검색·요약 | W2 | 8 | SF + 연계 시뮬 + Agentforce + Data Cloud(Sandbox) | — | Data Cloud 부분은 D-4 결정 후 Sandbox |
| D2 | CMN-00-AI-003 | 문서 버전 비교·변경 요약 | W2 | 4 | SF + Agentforce | AI-002 | — |
| D3 | QMS-08-AIQ-013 | 품질 문서 검색 범위·QMS 검색 구성·리비전 비교 사용처 | W2 | 4 | SF + Agentforce + Data Cloud(Sandbox) | AIQ-001, AI-002, AI-003 | Data Cloud 부분은 Sandbox |
| X1 | QMS-08-AIQ-011 | 위험 점수 계산(피처·점수·이상 탐지, Snowflake) | W2 | 7 | 외부 트랙 | — | 앞당김: QMS-07-DSH-012의 선행 |
| X2 | QMS-09-INT-020 | Snowflake 프로시저 호출 모드 구현·AI 호출 모드 운영 규약(IF-DW-001, IF-AI-001·002) | W2 | 4 | 외부 트랙 | — | — |
| X3 | QMS-08-AIQ-003 | 원인 후보 순위 엔진(원인 분포·유사 사례·맥락 신호) | W1 | 6 | 외부 트랙 | AIQ-002 | — |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

공통 원칙(D8-2·D8-3): LLM 생성은 Salesforce Prompt Builder(Trust Layer)로만 하고, 원인 코드·위험 점수·순위는 결정적 로직이 정한다. LLM은 근거 문장만 쓰고, 후보 밖 코드·입력에 없는 숫자는 자동 폐기한다. 확정은 언제나 사람이다.

### 레인 A — 에이전트·Q&A(AIQ-001 → AI-005 → AIQ-009, AIQ-010)

1. **AIQ-001**: `SL Quality Assistant` 토픽 7개·분류 기준·지시문, 공통 프롬프트 블록 `QMS_PT_Common`, 공장 정책(중국 공장 비활성, D8-8)·사용 한도·카운터(D8-9), `QMS_AiJobEvent__e`, 기능 스위치 키, PS, `QMS_AiGuard`.
2. **AI-005**: 자연어 데이터 Q&A 프레임워크(공장 범위 강제, 골든 질문 평가). review-pack 변경 요청 1건.
3. **AIQ-009**: 업무 현황 Action 3개(조회 정의 메타데이터), 답변 형식, 골든 질문 20개. 레코드 변경 금지.
4. **AIQ-010**(SNOW·MULE·AF·SF): Salesforce 쪽 = `qmsQualityAssistant`(유틸리티 바, `QMS_AskQualityChannel` 구독 → 즉시 ACK → 패널 → `QMS_QualityAssistantController.ask`), 공장 범위 교집합(BR-10), Agent API 경로와 대체 경로. Snowflake 보안 뷰·시맨틱 모델·행 접근 정책·Mule analyst 연산은 외부 트랙(D8-5).

### 레인 B — 원인 추천·8D 초안(AIQ-002 → AIQ-004 → AIQ-005, AIQ-006)

1. **AIQ-002**(SNOW·MULE·SF): 코퍼스 Dynamic Table·Cortex Search Service·Mule 검색 API는 외부 트랙, Salesforce 쪽 = 검색 서비스(접근 확인·재순위), 레코드 기반 질의 생성. NCR·8D·레슨런·SPC 알람·심사 지적이 코퍼스 원천이라 P5~P9가 끝난 뒤에야 의미 있는 결과가 나온다.
2. **AIQ-004**: `QMS_RcaRecommendService`(공용 파이프라인), 어댑터 3종(8D, 심사 지적, SPC 알람 — NCR 화면에는 두지 않음, D8-11), 근거 문장 프롬프트, 응답 검증, `qmsAiRecommendLauncher`, 에이전트 액션 2개. 순위는 AIQ-003(외부 트랙)이 계산한다.
3. **AIQ-005**: `QMS_EightDAssistImpl`(바인딩 **EIGHT_D_ASSIST**), D2·D4·D5 초안, 8D 이벤트에 따른 자동 초안, 효과 확인 대책 사례 뷰, 에이전트 액션. P5 CLM-002 AC-4(버튼 숨김)가 이제 버튼 표시로 바뀐다.
4. **AIQ-006**: 확정 설정 메타데이터, 일 배치, LELE 결정 이벤트 구독, 적중 규칙 5종, 제외 피드백 180일 억제(D8-4), AI 정확도 KPI 키 규칙(`AI_HIT_TOP1_*` 등).

### 레인 C — LELE·조기경보·운영(AIQ-007 → AIQ-008, AIQ-012 → AIQ-016)

1. **AIQ-007**: `QMS_LeleRecommendService`·REST `/qms/v1/lele/recommend`, 결합 순위(규칙 0.6 + 의미 0.4, D8-7), 의미 추가 후보, 체크 문장 초안, AI-004 기록, `propose` 호출, 추천 화면, 에이전트 액션 2개, 제외 억제.
2. **AIQ-008**: PMS 연계 흐름(같은 Org 호출 경로, 다른 Org는 Mule 중계 — D-1), PoC 시나리오 6 데모 데이터·스크립트·시퀀스, 성공 기준. PMS 없이 문맥 입력 화면으로 시연(D8-10).
3. **AIQ-012**: `QMS_EarlyWarning__c`, 수신 핸들러(EVENT_TYPE `QMS_EW_ALERT`·`QMS_EW_FOLLOWUP`), 담당자 해석, 설명 생성, 조치(개선 과제 게이트웨이·감시·무시), 만료, 위험 보드 `qmsRiskBoard`·`qmsRiskTopWidget`, 에이전트 액션. 점수는 AIQ-011(외부 트랙).
4. **AIQ-016**: 평가셋 저장 규칙, 평가 실행기, 평가 결과 객체, 출시 기준표, 프롬프트 설정 메타데이터·버전 교체, JSON 검증 공통 클래스, 운영 콘솔 `qmsAiOpsConsole`, 비용 상한 대응.
5. **P11 DSH-012 후속(CR-1)**: AIQ-011·012·016이 끝나면 Vol.8 위젯(`QMS_W_EW_*`, `QMS_W_AI_USAGE`)의 `IsActive`를 켜고, 종합 Dashboard(DSH-014) 질문 위젯이 ACK 경로로 바뀌었는지 확인한다. CR-1을 `-a`·`-b` 분할로 정했다면 DSH-012b WI로 처리한다.

### 레인 D — 문서 검색·프로시저 모드(AI-002 → AI-003 → AIQ-013, INT-020)

1. **AI-002**: 문서 통합 검색·요약. 검색 엔진은 D-4·D8-1 결정을 따른다 — Data Cloud면 그 부분은 Sandbox, Cortex Search로 통일하면 외부 트랙. Scratch Org에서는 Apex·LWC(`cmnUnifiedSearch`), 색인 상태 관리, 접근 권한 필터만. review-pack 변경 요청 1건(INDEX_SCOPE NONE 제외).
2. **AI-003**: 리비전 비교·변경 요약(스캔 PDF는 AI 호출 0회).
3. **AIQ-013**: 품질 DocClass 색인 범위, 검색 프리셋, 품질 탭 구성, 에이전트 문서 토픽, 리비전 비교 버튼 배치.

### 레인 X — 외부 트랙(AIQ-003, AIQ-011, INT-020)

원인 분포·맥락 신호·순위 프로시저(AIQ-003), 위험 점수·이상 탐지(AIQ-011), 프로시저 호출 모드 운영 규약(INT-020). Salesforce 쪽 결과물은 목 응답과 이벤트로 먼저 확인하고 L3에서 기대값과 대조한다.

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| Agentforce·Einstein | 정의 파일(P0 S-4) 또는 대안 Org | 대안 Org면 이 페이즈 산출물만 그 Org에 배포해 확인 |
| 에이전트 메타데이터 | 토픽·액션·프롬프트 템플릿 배포, `sf agent` 명령으로 활성·테스트 | |
| Agent API | AIQ-010 BR-10. 쓸 수 없으면 대체 경로(직접 ask) | |
| 유틸리티 바 | `qmsQualityAssistant`를 SL QMS 앱 유틸리티 바에 | |
| 게이트웨이 바인딩 | EIGHT_D_ASSIST 추가 | P5 CLM-002 회귀 |
| 위젯 활성화 | DSH-012 Vol.8 위젯 IsActive | |
| 생성형 AI 호출 한도 | 평가셋 전체 실행은 Sandbox(dev-plan 7.5절) | Scratch Org에서는 골든 질문 몇 개만 |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| 의미 검색(Cortex Search) | 검색 API 응답 목(WI가 L1 목 작성 — 데모 목 없음) |
| 원인 순위(AIQ-003) | 순위 프로시저 응답 목 + `expected/ai_rca_S1.json`·`ai_rca_S2.json`(생성 요청 필요) |
| 위험 점수(AIQ-011) | `QMS_EW_ALERT` 이벤트 발행 + `expected/ew_S11.json`(생성 요청 필요) |
| Q&A 추세·통계(Cortex Analyst) | analyst 응답 목 + `expected/qa_S5.json`(생성 요청 필요) |
| PMS(S6) | 문맥 입력 화면 + `scenario_keys.json` `s6Project` |
| Data Cloud 문서 검색 | Sandbox 또는 D8-1에 따라 Cortex Search 목 |

## 6. 데모 데이터

새 Salesforce CSV는 없다. 코퍼스는 P5~P10 데이터(종결 NCR 62·클레임 18·8D 원인 분포, 레슨런 18, 심사 지적 등 S0 사례)다. **AI 기대값 파일 5종**(`ai_rca_S1.json`, `ai_rca_S2.json`, `lele_S6.json`, `ew_S11.json`, `qa_S5.json`)은 데모 명세 2절에 정의만 있고 아직 없다. P11 중에 데모 데이터(AI 시나리오) 작업에 생성을 요청한다. 데모 명세의 S1 기대 상위 3(DISPENSER_FLOW, VENT_MEMBRANE, HSG_WARP, 확정 = DISPENSER_FLOW → Top-1 적중)을 그 전의 임시 기준으로 쓴다.

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G12-1 | 새 Org(또는 대안 Org) 배포·테스트·전체 데모 적재, 에이전트 활성 | 6.4절 | 실패 0 |
| G12-2 | S1: `S1-8D` D4 원인 추천 → 2위 채택 → D8 승인 → 적중 판정 | `ai_rca_S1.json`, AIQ-004, CLM-004 AC-6 | 상위 3 일치, 채택 기록, Top-1 적중 |
| G12-3 | S2: 8D 초안 요청(D2·D4·D5) → 적용 → 수정 후 제출 | AIQ-005, CLM-002 AC-5 | 버튼 표시, 초안은 필드 자동 입력 아님, MODIFIED 기록 |
| G12-4 | S6: BE3 문맥 → LELE 추천(규칙 + 의미) → 반영 초안 → 결정 | `lele_S6.json`, AIQ-007·008 | 필수 체크포인트 항상 포함, 결정 이벤트 → 적중 |
| G12-5 | S11: 위험 경보 수신 → 위험 보드 → 개선 과제 조치 | `ew_S11.json`, AIQ-012 | 14일 중복 방지, 개선 과제 생성 |
| G12-6 | S5: 종합 Dashboard 질문 → ACK → 답변(결론·표·기준 시각·범위) | AIQ-010 AC-8, DSH-012 | 1.5초 안 ACK, 공장 범위 밖 질문은 범위 내로 |
| G12-7 | KR01 사용자가 CN01 부적합 질문, 영어 사용자 한국어 데이터 질문 | AI-001 AC-1·2, AI-005 AC-2 | 데이터 없음 응답, 영어 + 출처 |
| G12-8 | 중국 공장 사용자 AI 기능 | D8-8 | 비활성 |
| G12-9 | 사용 한도 초과, 후보 밖 원인 코드 응답(목) | AIQ-001, D8-3 | 차단 안내, 자동 폐기 |
| G12-10 | 문서 검색 권한 필터, 스캔 PDF 비교 | AI-002 AC-2, AI-003 AC-2 | 권한 없는 문서 제외, AI 호출 0회 |
| G12-11 | AI 정확도·사용량 위젯 활성 후 표시 | DSH-012, AIQ-016 | 위젯 표시, 운영 콘솔 드릴다운 |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D-4 Data Cloud 범위, D-10 AI 학습 정의 |
| 결정 | D8-1 의미 검색 엔진, D8-2 LLM은 Prompt Builder로만, D8-3 결정적 로직, D8-4 학습 = 확정 사례 재사용, D8-5 Q&A 공장 권한, D8-6 조기경보 기준, D8-7 LELE 결합 가중치, D8-8 중국 공장 AI, D8-9 사용 한도, D8-10 S6 시연 방식, D8-11 원인 추천 대상 |
| 명세 | review-pack 2절 Vol.0 변경 요청 2건(AI-002, AI-005), 3절 Vol.8 대상 1건 |
| 명세 | CR-1 DSH-012 후속 처리 |
| 데이터 | AI 기대값 파일 5종(6절) |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| Scratch Org에서 Agentforce를 못 씀 | P0에서 대안 Org 확보, 이 페이즈 게이트는 대안 Org에서 |
| 외부 트랙(Cortex Search·Analyst·순위·위험 점수)이 늦음 | Salesforce 쪽은 목 응답으로 완료, 기대값 대조는 L3 게이트 |
| 생성형 AI 호출 한도·비용 | 평가셋 실행은 Sandbox, Scratch Org는 골든 질문 일부 |
| LLM 응답 비결정성으로 테스트가 흔들림 | Apex 테스트는 프롬프트 호출을 Stub, 응답 검증 로직(JSON·숫자 검사)만 결정적으로 검사 |

## 10. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| | | | |
