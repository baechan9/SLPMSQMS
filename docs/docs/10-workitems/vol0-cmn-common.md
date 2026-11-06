# SL QMS 워크아이템 Vol.0 — 공통(CMN) 메뉴

Nov 1, 2026 · @배창욱

## 1. 개요

본 문서는 SL QMS(RFP-QMS-2026-001)를 Salesforce + Snowflake(+MuleSoft) 위에 AI 개발 에이전트가 구현할 수 있도록 내린 워크아이템 중 **Vol.0 공통(CMN) 메뉴**다. PMS(RFP-PMS-2026-001)와 함께 쓰는 기반 기능을 먼저 정의해야 QMS 메뉴 워크아이템이 이를 참조할 수 있으므로 공통을 첫 번째로 작성했다.

**근거 자료**: QMS RFP v2(요구 45개), PMS RFP v2(요구 71개), QMS Fit-Gap 분석서 v2, 품질경영 회사표준 개선 RFP 2종(신제품개발 Rev01, 양산품질 Rev00), 내부 분석 노트(SL PMS·QMS RFP 분석 및 Q&A).

**번호 체계**: `{시스템}-{메뉴No}-{기능코드}-{순번}`

| 구분 | 형식                              | 예시           | 설명                             |
|------|-----------------------------------|----------------|----------------------------------|
| 공통 | CMN-00-{기능}-{nnn}               | CMN-00-APV-002 | PMS·QMS 공용. 메뉴번호 00 고정   |
| QMS  | QMS-{RFP 모듈 2자리}-{기능}-{nnn} | QMS-03-IQC-001 | 메뉴번호 = QMS RFP 2.1 모듈 번호 |
| PMS  | PMS-{RFP 모듈 2자리}-{기능}-{nnn} | PMS-04-WBS-010 | 예약. PMS 작업 시 동일 규칙 적용 |

- 순번은 기능코드 내 001부터, 10 단위 공백 없이 연속 부여. 분할이 필요하면 `-a`, `-b` 접미사(예: QMS-06-NCR-003a)를 붙이고 기존 번호는 바꾸지 않는다.
- 모든 워크아이템은 RFP 추적 ID를 가진다: `Q-##`(QMS RFP 번호), `P-##`(PMS RFP 번호), `NFR-x.x`(비기능 절).

**작성 순서와 개발 순서는 다르다.** 작성은 메뉴 순서(00 → 02 → … → 09)로 하되, 각 워크아이템에 `선행 WI`와 `Wave`를 표기해 개발 에이전트는 의존성 순서로 착수한다. 예: 수입검사(메뉴 03)는 부적합 NCR(메뉴 06) 객체를 참조하므로 NCR 데이터 모델이 Wave 1에 먼저 나온다.

**검토 후 처리**: 메뉴별 문서 검토가 끝나면 승인된 워크아이템만 마스터 파일(xlsx)로 옮기고 분류 레벨(L1 시스템 / L2 메뉴 / L3 기능 / L4 워크아이템 + 유형·플랫폼·Wave·Fit-Gap 등급)을 추가한다.

## 2. 메뉴 구조와 공통 기능 분리

QMS RFP 45개 요구 중 15개가 PMS RFP와 같은 기능이거나 같은 엔진을 쓴다. 이 15개와 두 시스템이 공유해야 하는 기반(기준정보·권한·연계·DW)을 **공통 메뉴 CMN-00**으로 분리했고, QMS 메뉴 02~09에는 품질 고유 기능만 남겼다.

| 메뉴                    | 기능코드                                                            | 범위                                                                                                                                                   | QMS RFP                                                           | PMS RFP 대응                           | 작성 Vol.       |
|-------------------------|---------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|----------------------------------------|-----------------|
| CMN-00 공통             | ARC, MDM, SEC, I18N, UX, QNR, APV, TDO, NTF, DOC, DSH, MTG, INT, DWH, AI | 개발 표준, 기준정보, 권한, 다국어, 모바일, 표준 질문지 템플릿, 결재, To-Do, 알림, 문서, 위젯 프레임워크, 회의, 연계, Snowflake, AI 공통                                    | Q-1~3, 29, 34(프레임워크), 35, 39(프레임워크), 41~45, NFR 4.1~4.4 | P-1~3, 7, 19, 34~40, 47, 55, 58, 62~69 | Vol.0 (본 문서) |
| QMS-02 개발 품질        | DVQ                                                                 | 부품·제품 인정시험 기획/실행                                                                                                                           | Q-4, 5                                                            | P-21, 37 (산출물 스레드)               | Vol.2           |
| QMS-03 부품/협력사 품질 | SPP, IQC, PWT, PPA, PIS                                             | 협력사 포털, 수입검사, 부품 보증시험, 부품 Re-PPAP, 부품 초기안정화                                                                                    | Q-6~9                                                             | P-28                                   | Vol.3           |
| QMS-04 제품/공정 품질   | EFC, SPC, FQC, HZD, LEL, RPP                                        | 초기유동, SPC, 제품/출하 검사, 수평전개, 레슨런(LELE), 제품 Re-PPAP                                                                                    | Q-10~15                                                           | P-15, 50 (LELE↔WBS)                    | Vol.4           |
| QMS-05 고객 품질        | B2B, CLM                                                            | 고객 B2B 데이터, 고객 Claim·8D·6pi                                                                                                                     | Q-16, 17                                                          | P-49 (문제점↔8D)                       | Vol.5           |
| QMS-06 품질 운영 지원   | SQM, 4MC, NCR, LMS, TRN, GAU, MSA, LAB, IMP, IAU, SAU, CAU, CER     | 협력사 실적, 4M(사내/협력사), 부적합(사내/부품), 한도견본, 교육·자격, 측정기, MSA, 분석실, 개선과제, 내부심사, 협력사 Audit, 고객 Audit(VDA 6.3), 인증 | Q-18~28, 30~33                                                    | P-50                                   | Vol.6           |
| QMS-07 Dashboard        | DSH                                                                 | 품질 위젯 콘텐츠와 역할별 템플릿                                                                                                                       | Q-34 (콘텐츠)                                                     | —                                      | Vol.7           |
| QMS-08 AI               | AIQ                                                                 | Root Cause 추천, CAPA/8D 초안, Early Warning, 품질 Q&A 토픽, PMS 연계 LELE 추천                                                                        | Q-36~40                                                           | P-59, 61 (공통 피드백 루프)            | Vol.8           |
| QMS-09 연계             | INT                                                                 | MES(SPC·초기유동), 필드클레임, PMS 양방향 스레드, 측정기 시스템                                                                                        | Q-42 (QMS 고유 대상)                                              | P-64                                   | Vol.9           |

**공통으로 판정한 기준**: (1) 두 RFP에 같은 문장으로 존재(다국어, 결재선 3종, SSO/To-Do), (2) 같은 엔진을 쓰고 콘텐츠만 다름(대시보드 위젯, 문서 검색, 자연어 Q&A, AI 추천 피드백), (3) 디지털 스레드를 위해 두 시스템이 같은 레코드를 봐야 함(고객·차종·품번·조직·특성 마스터).

**QMS-01 일반 메뉴는 별도 Vol.을 만들지 않는다.** Q-1~3이 전부 CMN-00으로 이동했기 때문이다.

## 3. 목표 아키텍처와 개발 에이전트 공통 규칙

원칙은 하나다: **업무 흐름·결재·화면은 Salesforce, 대량 원천 데이터·통계 계산은 Snowflake, 시스템 간 이동은 MuleSoft.** 측정값 한 건 한 건(SPC, 검사 측정치, B2B 원천, MES 이력)은 Salesforce 레코드로 만들지 않는다.

### 3.1 플랫폼 역할 분담

| 플랫폼                          | 담당                                                                                                                              | 담당하지 않는 것                                      |
|---------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------|
| Salesforce Platform (Lightning) | 기준정보, 업무 객체(부적합·4M·8D·Audit 등), 결재, To-Do, 화면(LWC), 알림, 권한, 집계 결과 표시                                    | 원천 측정 데이터 저장, Cpk·Gage R&R 등 대량 통계 계산 |
| Experience Cloud                | 협력사 포털(성적서, NCR 회신, 4M 신청, Re-PPAP 제출)                                                                              | 사내 사용자 화면                                      |
| Snowflake                       | QDW(품질 DW): MES 측정, 검사 상세, B2B·필드클레임 원천, SAP 실적 이력; SPC·MSA 통계(SQL, Dynamic Table, Snowpark Python); AI 피처 | 업무 상태 관리, 결재                                  |
| MuleSoft                        | HR·SAP·MES·포탈·필드클레임·측정기 시스템 API, Snowflake → Salesforce 결과 전달, 재시도·로그                                       | 업무 규칙 판단                                        |
| Data Cloud                      | Snowflake Zero Copy 조회, 문서 벡터 인덱스(RAG), Agentforce 그라운딩                                                              | 트랜잭션 원장                                         |
| Agentforce                      | 문서 검색 요약, Q&A, Root Cause·8D 초안, LELE 추천                                                                                | 최종 판정·확정(항상 사람 확정)                        |

### 3.2 명명 규칙 (모든 워크아이템 공통)

| 대상                             | 규칙                                                                | 예시                                           |
|----------------------------------|---------------------------------------------------------------------|------------------------------------------------|
| 커스텀 객체                      | `{접두어}_{PascalCase}__c` (접두어 = CMN / QMS / PMS)               | `CMN_Plant__c`, `QMS_NCR__c`                   |
| 필드                             | 접두어 없이 PascalCase, Lookup은 대상명                             | `Plant__c`, `DueDate__c`                       |
| Apex                             | `{접두어}_{도메인}{역할}`                                           | `CMN_ApprovalService`, `QMS_NcrTriggerHandler` |
| LWC                              | `{소문자 접두어}{PascalCase}` (cmn / qms / pms)                     | `cmnApprovalLine`, `qmsNcrForm`                |
| Flow                             | `{접두어}_{객체}_{시점}_{동작}`                                     | `QMS_NCR_AfterSave_NotifyOwner`                |
| Custom Metadata / Platform Event | `{접두어}_{이름}__mdt` / `__e`                                      | `CMN_Widget__mdt`, `CMN_ResultInbound__e`      |
| Permission Set (Group)           | `{접두어}_PS_{기능}_{권한}` / `{접두어}_PSG_{페르소나}`             | `QMS_PS_NCR_Edit`, `QMS_PSG_QualityEngineer`   |
| Custom Label                     | `{접두어}_{화면}_{키}`                                              | `CMN_Approval_BtnSubmit`                       |
| Snowflake 객체                   | DB `SL_QDW`, 스키마 `RAW`/`STG`/`CORE`/`MART`/`ML`, 대문자 스네이크 | `CORE.SPC_MEASUREMENT`                         |
| Mule API                         | `{계층}-{대상}-api` (계층 = sys / prc / exp)                        | `sys-sap-material-api`                         |

### 3.3 코딩·완료 기준(DoD)

- Apex: 트리거는 객체당 1개, CMN 트리거 프레임워크 경유(CMN-00-ARC-002). SOQL/DML 루프 금지, 200건 벌크 테스트 필수. 기본 `with sharing`, SOQL은 `WITH USER_MODE`. ID·레코드타입 하드코딩 금지(DeveloperName 사용).
- 화면 문구는 전부 Custom Label 또는 Translation Workbench. 한국어 하드코딩 금지. ko·en·zh_CN 3개 언어 번역 파일 포함이 완료 조건.
- 테스트: 클래스별 커버리지 85% 이상, 각 수용 기준(AC)을 1개 이상의 테스트 메서드로 검증하고 메서드명에 AC 번호 포함(예: `test_AC03_rejectReturnsToDrafter`).
- 권한: 워크아이템이 만드는 모든 객체·필드는 같은 워크아이템 안에서 Permission Set에 반영.
- 산출물: SFDX 소스(force-app), `manifest/package.xml`, 워크아이템 ID를 커밋 메시지 접두어로 사용(`[CMN-00-APV-001] ...`).
- AI 출력은 항상 “초안/추천” 상태로 저장하고 사용자가 채택해야 업무 레코드에 반영된다.
- LWC 데이터 접근: 기본은 Apex 컨트롤러. 서버 업무 규칙이 없는 단일 레코드 조회·편집에 한해 Lightning Data Service(uiRecordApi, record-form)를 허용한다(2026-11-01 결정).
- LWC 외부 JavaScript: 승인 목록(Chart.js = 정적 리소스 cmnChartJs, SheetJS)만 정적 리소스 + loadScript로 쓴다. 목록 추가는 WI 변경과 승인이 필요하다(2026-11-01 결정).
- 구현 단계의 상세 규칙(보안·거버너·명명 보충·테스트·배포·완료 보고)은 저장소 루트 `.claude/rules/sf-dev.md`, 진행 절차는 `/implement-wi` 스킬을 따른다. 이 절과 충돌하면 이 절이 우선한다.

### 3.4 화면 표준 (2026-11-05 화면 전략)

화면 구성의 기준 문서는 `docs/10-workitems/screen-strategy.md`다. 모든 WI는 아래를 따른다.

- **화면 유형:** WI "화면/UX" 항목 첫 줄에 유형 코드와 쓰는 공통 부품(UX-004~009)을 적는다. 유형 코드는 다음 8개다.
  - T1 단계형 업무 레코드
  - T2 계획-실행 그리드
  - T3 현장 입력 셸
  - T4 체크리스트 평가
  - T5 분석·모니터링
  - T6 마스터 관리
  - T7 협력사 포털
  - T8 홈·작업함
  - 기존 WI의 유형은 `docs/30-dev/screen-map.csv`의 `화면유형` 열에 있다.
- **레코드 페이지:** 상태가 있는 업무 객체는 UX-004 표준(헤더 7개 필드, 진행 단계, "현재 단계" 첫 탭, 결정 지원 레일)으로 만든다. 섹션·버튼 노출과 서버 허용은 UX-005 규칙 하나에서 만든다. 화면에서 숨기는 것만으로 권한 통제를 대신하지 않는다.
- **공통 부품:** 행 편집 화면은 UX-006 그리드, 시료·측정 입력은 UX-008 입력 셸, 질문지 평가는 UX-009 체크리스트를 설정과 Provider 구현으로 쓴다. 같은 일을 하는 메뉴 전용 컴포넌트를 새로 만들지 않는다.
- **스타일:** 커스텀 CSS는 SLDS 전역 스타일링 훅(`--slds-g-*`)과 SLDS 클래스만 쓴다. 색 리터럴, 컴포넌트 스타일링 훅(`--slds-c-*`), `--lwc-*` 토큰은 금지다(CI `scripts/ci/check-lwc-styling.py`, UX-004).
- **앱:** 콘솔 앱을 쓰지 않는다(DS-7 결정). 모든 앱은 표준 내비게이션이다. 콘솔 기능(하위 탭, 고정 영역)을 전제로 화면을 설계하지 않는다.
- **문구:** 화면 문구는 "동사 + 대상"(예: "부적합 등록")으로 쓴다. 오류 메시지는 원인과 고치는 법을 한 문장에 담는다.

## 4. 워크아이템 템플릿

모든 워크아이템은 아래 항목을 같은 순서로 가진다. 개발 에이전트는 **데이터 모델 → 비즈니스 규칙(BR) → 수용 기준(AC)** 순서로 읽고, AC를 테스트 코드로 먼저 작성한 뒤 구현한다.

| 항목          | 내용                                                                                           |
|---------------|------------------------------------------------------------------------------------------------|
| 메타 라인     | 추적(RFP ID) · 우선순위(필수/권장) · Wave · 플랫폼 · 유형 · Fit-Gap 예상 · 선행 WI · 공수(M/D) |
| 목적          | 왜 필요한가. 자동차 품질·PM 도메인 맥락 1~3문장                                                |
| 범위          | In: 이 WI가 만드는 것 / Out: 다른 WI로 넘기는 것(해당 WI ID 명시)                              |
| 데이터 모델   | 객체·필드 API명, 타입, 필수 여부, 설명. 객체 공통 필드(Name, Owner, 생성/수정 정보)는 생략     |
| 비즈니스 규칙 | BR-1, BR-2 … 검증·상태 전이·계산식                                                             |
| 화면/UX       | 첫 줄에 화면 유형(T1~T8)과 공통 부품(3.4절). 이어서 LWC·레코드 페이지·리스트뷰 구성, 모바일 여부 |
| 권한          | 어떤 Permission Set이 무엇을 할 수 있는가                                                      |
| 수용 기준     | AC-1, AC-2 … Given / When / Then                                                               |
| 에이전트 주의 | 흔한 오해, 하지 말아야 할 구현                                                                 |
| 오픈 이슈     | SL 확인이 필요한 항목(검토 시 결정)                                                            |

**코드값 정의**

- Wave: W0 기반(착수 1~2개월, 모든 메뉴의 전제) · W1 핵심(필수 + PoC 시나리오) · W2 확장(필수 중 후순위) · W3 고도화(권장·AI 학습)
- 플랫폼: SF(Salesforce Platform) · EXP(Experience Cloud) · SNOW(Snowflake) · MULE(MuleSoft) · DC(Data Cloud) · AF(Agentforce)
- 유형: DM(데이터 모델) · CFG(설정) · APEX · LWC · FLOW · INT(연계) · SQL · SNOWPARK · AGENT · DOC(가이드/산출물)
- Fit-Gap 예상: Fit-Gap 분석서 기준(OOTB / Tailoring / Customization). 공수는 AI 코딩 보조를 전제로 한 개발자 1인 기준 M/D이며 분석·통합테스트는 제외

## 5. CMN-00-ARC 개발 기반

### CMN-00-ARC-001 개발 환경·저장소·CI/CD 표준

추적 NFR-4.3 · 필수 · W0 · SF, SNOW, MULE · CFG, DOC · Tailoring · 선행 없음 · 4 M/D

**목적**: 100개 이상의 워크아이템을 여러 개발자와 AI 에이전트가 병렬 개발하고, Salesforce 연 3회 정기 릴리즈에도 커스터마이징이 보존되도록(RFP 4.3) 환경과 배포 경로를 고정한다.

**범위** In: Org·Sandbox 구성, Git 저장소 구조, PR 검증 파이프라인, Snowflake 스키마 마이그레이션 도구. Out: 앱 기능 일체.

**구성 기준**

| 환경 | Salesforce                                     | Snowflake                      | 용도                   |
|------|------------------------------------------------|--------------------------------|------------------------|
| DEV  | Scratch Org(정의 파일) + Developer Sandbox 2개 | DB `SL_QDW_DEV`                | 개인/에이전트 개발     |
| SIT  | Partial Copy Sandbox                           | DB `SL_QDW_TEST`               | 통합·연계 테스트       |
| UAT  | Full Sandbox                                   | DB `SL_QDW_TEST` (스키마 분리) | 현업 검증, 성능 테스트 |
| PROD | Production                                     | DB `SL_QDW`                    | 운영                   |

저장소 구조(단일 모노레포):

    sl-platform/
      sfdx-project.json        # packageDirectories: cmn, qms, pms
      force-app-cmn/  force-app-qms/  force-app-pms/
      config/project-scratch-def.json
      snowflake/migrations/V{nnn}__{설명}.sql   # schemachange
      mule/{api-name}/
      docs/wi/{WI-ID}.md       # 워크아이템별 구현 노트

**비즈니스 규칙**

- BR-1: `main` 직접 커밋 금지. PR 병합 조건 = 소스 validate 배포 성공 + 로컬 Apex 테스트 전체 통과 + 클래스별 커버리지 85% 이상 + Salesforce Code Analyzer 심각도 1~2 위반 0건.
- BR-2: Scratch Org 정의 파일은 Translation Workbench, Experience Cloud(Communities), Platform Encryption 비활성 상태로 시작하며 기능 플래그는 이 파일 한 곳에서 관리한다.
- BR-3: 비밀번호·토큰·Snowflake 키는 저장소에 두지 않는다. Salesforce는 Named Credential + External Credential, Mule은 Secure Properties, CI는 파이프라인 시크릿만 사용.
- BR-4: Snowflake DDL은 schemachange 버전 스크립트로만 변경하며 수동 DDL은 금지한다.

**수용 기준**

- AC-1: Given 신규 개발자가 저장소를 받았을 때, When `sf org create scratch -f config/project-scratch-def.json` 후 소스를 배포하면, Then 오류 없이 배포되고 CMN 테스트가 전부 통과한다.
- AC-2: Given 커버리지 80% 클래스를 포함한 PR, When 파이프라인이 실행되면, Then 병합이 차단되고 미달 클래스명이 표시된다.
- AC-3: Given schemachange 스크립트 V002, When DEV에 적용하면, Then `SL_QDW_DEV.PUBLIC.SCHEMACHANGE_HISTORY`에 기록된다.

**에이전트 주의**: 패키지 디렉터리를 객체 접두어와 일치시킨다(CMN 객체는 반드시 force-app-cmn). 다른 접두어 디렉터리에 객체를 만들면 IP 귀속 구분(사전 보유 자산 vs SL 귀속 산출물)이 깨진다.

**오픈 이슈**: (1) Multi-Currency 활성화 여부 — 활성화 후 되돌릴 수 없으므로 W0 종료 전 결정(PMS 비용 관리에 EUR·USD·CNY 필요 예상). (2) Unlocked Package 전환 시점. (3) DKBMC 연구소 PMS 에셋을 별도 패키지 디렉터리로 둘지.

### CMN-00-ARC-002 Apex 공통 프레임워크 (트리거·로그·예외·기능 스위치)

추적 NFR-4.3, NFR-4.2 · 필수 · W0 · SF · APEX, DM · Customization · 선행 ARC-001 · 5 M/D

**목적**: 모든 객체가 같은 방식으로 트리거·오류 기록·기능 on/off를 처리해 에이전트별 구현 편차를 없앤다.

**범위** In: 트리거 핸들러 베이스, 로거, 예외 클래스, 기능 스위치. Out: 감사 로그(SEC-003), 연계 로그(INT-001).

**데이터 모델**

| 객체 / 필드                     | 타입                                 | 필수 | 설명                                                                              |
|---------------------------------|--------------------------------------|------|-----------------------------------------------------------------------------------|
| CMN_Log__c.Level__c         | Picklist (ERROR, WARN, INFO, DEBUG)  | Y    | 로그 수준                                                                         |
| CMN_Log__c.Source__c        | Text(255)                            | Y    | `클래스.메서드`                                                                   |
| CMN_Log__c.Message__c       | Long Text(32768)                     | Y    | 메시지                                                                            |
| CMN_Log__c.RecordId__c      | Text(18)                             | N    | 관련 레코드                                                                       |
| CMN_Log__c.Payload__c       | Long Text(131072)                    | N    | 요청/응답 원문, 스택트레이스                                                      |
| CMN_Log__c.TransactionId__c | Text(36)                             | Y    | `Request.getCurrent().getRequestId()`                                             |
| CMN_LogEvent__e               | Platform Event (Publish Immediately) | —    | 위 필드와 동일 구성. 롤백돼도 로그가 남도록 사용                                  |
| CMN_TriggerSetting__mdt       | Custom Metadata                      | —    | ObjectApiName__c, IsActive__c, BypassPermission__c(Custom Permission API명) |
| CMN_FeatureSwitch__mdt        | Custom Metadata                      | —    | IsOn__c, RequiredPermissionSet__c(선택)                                       |
| CMN_LogSetting__c             | Hierarchy Custom Setting             | —    | MinLevel__c. 사용자·프로필별 로그 수준                                          |

**비즈니스 규칙**

- BR-1: `CMN_TriggerHandler`(virtual)는 beforeInsert~afterUndelete 7개 메서드를 제공하고, 트리거 본문은 `new QMS_NcrTriggerHandler().run();` 한 줄만 둔다.
- BR-2: 다음 중 하나면 핸들러를 건너뛴다: 해당 객체 `IsActive__c = false`, 실행 사용자가 BypassPermission__c 보유, 코드에서 `CMN_TriggerHandler.bypass('QMS_NCR__c')` 호출.
- BR-3: 같은 트랜잭션에서 같은 레코드·같은 컨텍스트가 재진입하면 한 번만 처리(재귀 방지).
- BR-4: `CMN_Logger.error(source, message, recordId, ex)`는 이벤트를 발행하고, 이벤트 트리거가 `CMN_Log__c`를 생성한다. MinLevel 미만 로그는 발행하지 않는다.
- BR-5: 스케줄 배치 `CMN_LogPurgeBatch`가 매일 02:00(KST) INFO·DEBUG 30일 초과, WARN 90일 초과, ERROR 365일 초과 로그를 삭제한다.
- BR-6: `CMN_FeatureSwitch.isOn('QMS_AI_RCA')`는 IsOn__c가 true이고 RequiredPermissionSet__c가 비어 있거나 사용자가 해당 PS를 보유할 때만 true. 미등록 키는 false.

**권한**: `CMN_PS_Admin_Ops` 보유자만 CMN_Log__c 조회. 일반 사용자 접근 불가.

**수용 기준**

- AC-1: Given 200건 일괄 insert, When 핸들러가 실행되면, Then SOQL 1회·DML 1회 이하로 처리된다(Limits 측정 테스트).
- AC-2: Given 트랜잭션이 예외로 롤백될 때, When 롤백 전에 `CMN_Logger.error`를 호출했으면, Then CMN_Log__c 1건이 남는다.
- AC-3: Given IsActive__c = false, When 레코드 저장, Then 핸들러 로직이 실행되지 않는다.
- AC-4: Given 존재하지 않는 스위치 키, When isOn 호출, Then false를 반환하고 예외가 없다.

**에이전트 주의**: Flow와 Apex 트리거를 같은 객체·같은 시점에 혼용하지 않는다. 저장 전 필드 기본값은 Before-Save Flow 대신 핸들러 beforeInsert에 둔다(실행 순서 예측성 확보).

### CMN-00-ARC-003 업무 문서 번호 채번 서비스

추적 Q-21, 22, 17, 19, 20 (번호 체계 공통) · 필수 · W0 · SF · APEX, DM · Customization · 선행 ARC-002 · 3 M/D

**목적**: NCR·4M·Claim·8D·Audit 번호를 “공장·연도별 연번”으로 발행한다. 고객 8D·VDA 감사에서 번호가 증빙 식별자로 쓰이므로 중복·결번 없이 발행돼야 한다. 표준 Auto Number는 공장별·연도별 리셋을 못 하므로 서비스로 만든다.

**데이터 모델**

| 객체 / 필드                                 | 타입                              | 필수 | 설명                                                                |
|---------------------------------------------|-----------------------------------|------|---------------------------------------------------------------------|
| CMN_NumberingRule__mdt.ObjectApiName__c | Text(80)                          | Y    | 대상 객체                                                           |
| CMN_NumberingRule__mdt.Pattern__c       | Text(80)                          | Y    | 예: `NCR-{PLANT}-{YYYY}-{SEQ:6}`                                    |
| CMN_NumberingRule__mdt.ScopeField__c    | Text(80)                          | N    | `{PLANT}` 치환 필드(예: Plant__c → CMN_Plant__c.PlantCode__c) |
| CMN_NumberingRule__mdt.ResetPolicy__c   | Picklist (YEARLY, MONTHLY, NEVER) | Y    | 연번 초기화 주기                                                    |
| CMN_NumberCounter__c.Key__c             | Text(120), External ID, Unique    | Y    | `QMS_NCR__c/KR01/2027`                                              |
| CMN_NumberCounter__c.LastValue__c       | Number(18,0)                      | Y    | 마지막 발행 값                                                      |
| (대상 객체).RecordNo__c                   | Text(40), Unique, External ID     | Y    | 발행 번호. 각 업무 객체 WI에서 생성                                 |

**비즈니스 규칙**

- BR-1: 대상 객체 핸들러 beforeInsert에서 `CMN_NumberingService.assign(records)` 호출. 연도·월은 레코드 CreatedDate가 아니라 발행 시점의 사용자 공장 시간대 기준(Plant__c.TimeZone__c).
- BR-2: 카운터는 `FOR UPDATE`로 잠그고 배치 크기만큼 한 번에 증가시킨다. 카운터 레코드가 없으면 생성한다.
- BR-3: RecordNo__c는 insert 후 변경 불가(Validation Rule `ISCHANGED(RecordNo__c)` 차단, 관리자 bypass 없음).
- BR-4: 패턴 토큰: `{PLANT}`, `{YYYY}`, `{YY}`, `{MM}`, `{SEQ:n}`(0 패딩 n자리). 미지원 토큰은 배포 시 단위 테스트에서 실패해야 한다.

**수용 기준**

- AC-1: Given KR01 공장 NCR 200건 일괄 생성, When 저장, Then `NCR-KR01-2027-000001`~`000200`이 중복 없이 순서대로 부여된다.
- AC-2: Given 2027-12-31 23:59(공장 시간) 마지막 번호 000350, When 2028-01-01 00:01에 생성, Then `NCR-KR01-2028-000001`.
- AC-3: Given 발행된 레코드, When 사용자가 RecordNo__c 수정, Then 저장이 차단되고 다국어 오류 메시지가 표시된다.

**에이전트 주의**: 번호를 `Name` 필드에 넣지 않는다. Name은 사용자가 읽는 제목(예: “렌즈 흐림 - 대구 L3”)으로 쓴다.

**오픈 이슈**: SL 현행 번호 체계(공장 코드 자릿수, 고객 8D 번호와 사내 번호 병기 여부).

## 6. CMN-00-MDM 기준정보

기준정보는 디지털 스레드의 열쇠다. PMS 프로젝트와 QMS 부적합·클레임·LELE가 **같은 고객·차종·품번·공장 레코드**를 가리켜야 “개발 액티비티 → 양산 부적합 → 고객 클레임” 추적과 LELE 추천(Q-40)이 가능하다. 원천은 SAP·HR이며 Salesforce는 사본(INT-002, INT-003로 동기화)이다. 다국어 표시 규칙은 I18N-001의 “마스터 데이터 다국어 패턴”(NameEn__c, NameZh__c + `DisplayName__c` 수식)을 모든 마스터에 적용한다.

### CMN-00-MDM-001 조직·사용자 기준정보

추적 Q-42, P-7 · 필수 · W0 · SF · DM · Tailoring · 선행 MDM-002 · 2 M/D

**목적**: 결재선(팀장), 귀책 부서, CFT 구성, 공장별 권한의 근거 데이터.

**데이터 모델**

| 객체 / 필드                       | 타입                              | 필수 | 설명                                               |
|-----------------------------------|-----------------------------------|------|----------------------------------------------------|
| CMN_Department__c.DeptCode__c | Text(20), External ID, Unique     | Y    | HR 부서 ID                                         |
| CMN_Department__c.Parent__c   | Lookup(CMN_Department__c)       | N    | 상위 부서                                          |
| CMN_Department__c.Manager__c  | Lookup(User)                      | N    | 부서장(팀장). 결재 Role 해석에 사용                |
| CMN_Department__c.Plant__c    | Lookup(CMN_Plant__c)            | N    | 소속 공장(본사 부서는 공란)                        |
| CMN_Department__c.FullPath__c | Text(255)                         | N    | “SL \> 품질본부 \> 품질경영팀”. 동기화 배치가 계산 |
| CMN_Department__c.IsActive__c | Checkbox                          | Y    | 폐지 부서는 false(삭제 금지)                       |
| User.EmployeeNo__c              | Text(20), External ID, Unique     | Y    | 사번                                               |
| User.Department__c              | Lookup(CMN_Department__c)       | Y    | 소속 부서                                          |
| User.JobGradeCode__c            | Text(10)                          | N    | HR 직급 코드(임율 계산은 PMS 소관)                 |
| User.PrimaryPlant__c            | Lookup(CMN_Plant__c)            | N    | 기본 공장. 화면 기본 필터·채번 기준                |
| User.HrStatus__c                | Picklist (ACTIVE, LEAVE, RETIRED) | Y    | 휴직(LEAVE) 시 대리결재 자동 제안 대상             |

**비즈니스 규칙**

- BR-1: 부서는 삭제하지 않고 IsActive__c = false로 처리한다(과거 NCR 귀책 부서 이력 보존).
- BR-2: FullPath__c는 Parent 체인을 최대 8단계까지 따라가 생성한다. 순환 참조가 생기면 저장을 차단한다.

**수용 기준**

- AC-1: Given 부서 A의 Parent를 하위 부서 C로 변경, When 저장, Then 순환 참조 오류로 차단.
- AC-2: Given 부서 이동(Parent 변경), When 저장, Then 하위 부서 전체의 FullPath__c가 비동기로 재계산된다.

**에이전트 주의**: User의 표준 `Department`(텍스트) 필드는 쓰지 않는다. 직급별 임율·인사평가 같은 민감 정보는 이 WI에서 만들지 않는다.

### CMN-00-MDM-002 법인·공장·라인·공정 계층

추적 NFR-4.3(멀티 사이트), Q-11, 19, 22 · 필수 · W0 · SF · DM · Tailoring · 선행 ARC-001 · 3 M/D

**목적**: 한국·미국·중국·인도·폴란드·브라질·멕시코 사업장의 데이터 격리 단위(공장)와, 부적합·SPC·4M이 발생하는 위치(라인·공정)를 정의한다.

**데이터 모델**

| 객체 / 필드                           | 타입                                                                                                                                 | 필수 | 설명                                     |
|---------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|------|------------------------------------------|
| CMN_Company__c.CompanyCode__c     | Text(10), External ID                                                                                                                | Y    | SAP 회사 코드                            |
| CMN_Company__c.Country__c         | Picklist(ISO 3166 alpha-2)                                                                                                           | Y    |                                          |
| CMN_Plant__c.PlantCode__c         | Text(10), External ID, Unique                                                                                                        | Y    | SAP Plant. 권한·채번의 키                |
| CMN_Plant__c.Company__c           | Master-Detail(CMN_Company__c)                                                                                                      | Y    |                                          |
| CMN_Plant__c.Region__c            | Picklist (KR, NA, CN, IN, EU, SA)                                                                                                    | Y    | 권역                                     |
| CMN_Plant__c.TimeZone__c          | Picklist (TimeZoneSidKey 값)                                                                                                         | Y    | 일 마감·채번·SLA 계산 기준               |
| CMN_Plant__c.DefaultLanguage__c   | Picklist (ko, en_US, zh_CN, pl, es, pt_BR)                                                                                           | Y    | 현장 사용자 기본 언어                    |
| CMN_Plant__c.MesSiteCode__c       | Text(20)                                                                                                                             | N    | MES 사이트 코드 매핑                     |
| CMN_Line__c.LineCode__c           | Text(20)                                                                                                                             | Y    | 라인 코드                                |
| CMN_Line__c.Plant__c              | Master-Detail(CMN_Plant__c)                                                                                                        | Y    |                                          |
| CMN_Line__c.ExternalKey__c        | Text(40), External ID, Unique                                                                                                        | Y    | `{PlantCode}-{LineCode}` (트리거가 세팅) |
| CMN_Line__c.ProductGroup__c       | Lookup(CMN_ProductGroup__c)                                                                                                        | N    | 주 생산 제품군. MDM-004 배포 시 추가     |
| CMN_Line__c.MesLineCode__c        | Text(20)                                                                                                                             | N    | MES 매핑                                 |
| CMN_Operation__c.OpCode__c        | Text(20)                                                                                                                             | Y    | 공정 코드                                |
| CMN_Operation__c.Line__c          | Master-Detail(CMN_Line__c)                                                                                                         | Y    |                                          |
| CMN_Operation__c.Sequence__c      | Number(4,0)                                                                                                                          | Y    | 공정 순서                                |
| CMN_Operation__c.OperationType__c | Picklist (MOLDING 사출, COATING 하드코팅, METALIZING 증착, ASSEMBLY 조립, LEAK_TEST 기밀검사, AIMING 광축·배광, EOL 최종검사, OTHER) | Y    | 헤드램프 공정 분류                       |

**비즈니스 규칙**

- BR-1: ExternalKey__c는 사용자가 입력하지 않으며 PlantCode와 LineCode로 자동 생성. 같은 공장 내 LineCode 중복 금지.
- BR-2: 공장·라인은 비활성화만 가능하고 삭제 금지(이력 레코드가 참조).

**수용 기준**

- AC-1: Given 공장 KR01에 라인 L03 존재, When KR01에 L03 추가 생성, Then 중복 오류.
- AC-2: Given 미국 공장 TimeZone America/Chicago, When 채번(ARC-003) 연도 판정, Then 해당 시간대 기준으로 판정된다.

**에이전트 주의**: Salesforce 표준 `Location`/Field Service 객체를 쓰지 않는다(라이선스 의존 회피).

### CMN-00-MDM-003 고객·차종

추적 P-4, Q-16, 17, 32, 40 · 필수 · W0 · SF · DM · Tailoring · 선행 MDM-002 · 2 M/D

**목적**: 고객별로 다른 요구(CSR: Customer Specific Requirements)를 데이터로 갖는다. 같은 클레임이라도 BMW와 현대기아의 회신 기한·양식이 다르고, LELE 추천은 고객·차종 일치가 1순위 매칭 키다.

**데이터 모델**

| 객체 / 필드                                      | 타입                                                                 | 필수 | 설명                                      |
|--------------------------------------------------|----------------------------------------------------------------------|------|-------------------------------------------|
| Account (RecordType `CMN_Customer`).OemCode__c | Text(20), External ID                                                | Y    | 고객 코드                                 |
| Account.CustomerGroup__c                       | Picklist (HKMC, BMW, GM, FORD, STELLANTIS, RENAULT, CN_LOCAL, OTHER) | Y    | OEM 그룹                                  |
| Account.SapCustomerNo__c                       | Text(20), External ID                                                | N    | SAP 고객 번호                             |
| Account.ContainmentDueDays__c                  | Number(3,0)                                                          | N    | 클레임 임시조치(D3) 회신 기한(일). 기본 1 |
| Account.EightDDueDays__c                       | Number(3,0)                                                          | N    | 8D 최종 회신 기한(일). 기본 30            |
| Account.PpapDefaultLevel__c                    | Picklist (1, 2, 3, 4, 5)                                             | N    | 기본 PPAP 제출 레벨. 기본 3               |
| Account.AuditStandard__c                       | Multi-Picklist (VDA63, IATF16949, CUSTOMER_SPECIFIC)                 | N    | 고객 감사 기준                            |
| Account.ClaimFormTemplate__c                   | Picklist (STD_8D, BMW_8D, HKMC_6PI, GM_PRR, FORD_GSDB)               | N    | 기본 클레임 회신 양식                     |
| CMN_Vehicle__c.VehicleCode__c                | Text(20)                                                             | Y    | 고객 차종 코드                            |
| CMN_Vehicle__c.Customer__c                   | Lookup(Account, 고객 RT 필터)                                        | Y    |                                           |
| CMN_Vehicle__c.ExternalKey__c                | Text(40), External ID, Unique                                        | Y    | `{OemCode}-{VehicleCode}`                 |
| CMN_Vehicle__c.SopDate__c / EopDate__c     | Date                                                                 | N    | 양산 시작/종료                            |

**비즈니스 규칙**

- BR-1: 고객 RecordType Account는 협력사 RecordType(MDM-005)과 같은 Account 객체를 쓰되 Lookup 필터로 섞이지 않게 한다.
- BR-2: 기한 필드가 비어 있으면 QMS 각 기능은 CMN_Setting의 전사 기본값(D3 1일, 8D 30일)을 사용한다.

**수용 기준**

- AC-1: Given 협력사 Account, When 차종의 Customer__c로 선택 시도, Then 검색 결과에 나타나지 않는다.

**오픈 이슈**: OEM별 클레임 양식·회신 기한 실제 값(CSR 문서) 수령 필요. 양식 목록(BMW_8D 등)은 SL 확인 후 확정.

### CMN-00-MDM-004 제품군·품번(Item)

추적 P-4, Q-4~15 전반 · 필수 · W0 · SF · DM · Tailoring · 선행 MDM-003 · 3 M/D

**목적**: 완제품(헤드램프 ASSY)부터 구매 부품(렌즈·하우징·LED 모듈·리플렉터·커넥터)까지 품번을 한 체계로 관리한다. 부적합·인정시험·Re-PPAP·SPC 특성이 모두 품번에 매달린다.

**데이터 모델**

| 객체 / 필드                                    | 타입                                                                                  | 필수 | 설명                                              |
|------------------------------------------------|---------------------------------------------------------------------------------------|------|---------------------------------------------------|
| CMN_ProductGroup__c.GroupCode__c           | Text(20), External ID                                                                 | Y    | LAMP, LAMP_HL, LAMP_RCL, EV, MIRROR, FEM 등       |
| CMN_ProductGroup__c.Parent__c              | Lookup(self)                                                                          | N    | 2단계 계층                                        |
| CMN_Item__c.ItemNo__c                      | Text(40), External ID, Unique                                                         | Y    | SAP 자재번호                                      |
| CMN_Item__c.ItemType__c                    | Picklist (FG 완제품, SFG 반제품, PART 구매부품, RAW 원재료)                           | Y    |                                                   |
| CMN_Item__c.ProductGroup__c                | Lookup(CMN_ProductGroup__c)                                                         | Y    |                                                   |
| CMN_Item__c.Customer__c                    | Lookup(Account)                                                                       | N    | FG만 필수                                         |
| CMN_Item__c.CustomerPartNo__c              | Text(40)                                                                              | N    | 고객 품번                                         |
| CMN_Item__c.DrawingNo__c / DrawingRev__c | Text(40) / Text(10)                                                                   | N    | PDM 도면 번호·리비전                              |
| CMN_Item__c.PartCategory__c                | Picklist (LENS, HOUSING, LED_MODULE, REFLECTOR, BEZEL, CONNECTOR, PCB, ACTUATOR, ETC) | N    | 부품 분류. LELE·수평전개 유사도 키                |
| CMN_Item__c.SpecialCharCount__c            | Roll-up(COUNT, CMN_Characteristic__c, SpecialClass ≠ NONE)                          | —    | MDM-006 이후 생성                                 |
| CMN_ItemPlant__c                             | Junction(Item, Plant), ExternalKey `{ItemNo}-{PlantCode}`                             | —    | 공장별 사용 여부, Status__c (ACTIVE, PHASE_OUT) |
| CMN_ItemVehicle__c                           | Junction(Item, Vehicle)                                                               | —    | 적용 차종                                         |

**비즈니스 규칙**

- BR-1: ItemType = FG이면 Customer__c 필수(Validation Rule).
- BR-2: BOM(부모-자식 구성)은 Salesforce에 저장하지 않는다. 수평전개·영향 분석에서 BOM이 필요하면 Snowflake `CORE.SAP_BOM`을 조회한다(DWH-002).

**수용 기준**

- AC-1: Given SAP 동기화로 동일 ItemNo 재수신, When upsert, Then 레코드가 1건으로 유지되고 변경 필드만 갱신된다.

### CMN-00-MDM-005 협력사·협력사 품번

추적 Q-6, 18, 20, 21, 31 · 필수 · W0 · SF · DM · Tailoring · 선행 MDM-004 · 2 M/D

**목적**: 수입검사 수준, 부품 PPAP 승인 상태, 협력사 포털 사용자의 데이터 격리 단위를 정의한다.

**데이터 모델**

| 객체 / 필드                                          | 타입                                                              | 필수 | 설명                                |
|------------------------------------------------------|-------------------------------------------------------------------|------|-------------------------------------|
| Account (RecordType `CMN_Supplier`).SapVendorNo__c | Text(20), External ID, Unique                                     | Y    | SAP 공급업체 번호                   |
| Account.SupplierGrade__c                           | Picklist (A, B, C, D)                                             | N    | 협력사 평가 등급(QMS-06-SQM이 갱신) |
| Account.IatfCertified__c / IatfExpiry__c         | Checkbox / Date                                                   | N    | IATF 16949 인증 여부·만료일         |
| Account.PortalEnabled__c                           | Checkbox                                                          | N    | 협력사 포털 사용 여부               |
| CMN_SupplierItem__c.Supplier__c                  | Master-Detail(Account)                                            | Y    |                                     |
| CMN_SupplierItem__c.Item__c                      | Lookup(CMN_Item__c)                                             | Y    |                                     |
| CMN_SupplierItem__c.Plant__c                     | Lookup(CMN_Plant__c)                                            | Y    | 납품 공장                           |
| CMN_SupplierItem__c.ExternalKey__c               | Text(80), External ID, Unique                                     | Y    | `{VendorNo}-{ItemNo}-{PlantCode}`   |
| CMN_SupplierItem__c.PpapStatus__c                | Picklist (NOT_SUBMITTED, INTERIM, APPROVED, REJECTED)             | Y    | 부품 PPAP 승인 상태                 |
| CMN_SupplierItem__c.InspectionLevel__c           | Picklist (NORMAL 정상, TIGHTENED 강화, REDUCED 완화, SKIP 무검사) | Y    | 수입검사 수준. 기본 NORMAL          |

**비즈니스 규칙**

- BR-1: InspectionLevel__c 변경은 이력을 남긴다(Field History). 강화→정상 전환 조건은 QMS-03-IQC에서 정의.
- BR-2: 협력사 Account 하위 Contact만 포털 사용자로 활성화할 수 있다(QMS-03-SPP).

**수용 기준**

- AC-1: Given 동일 협력사·품번·공장 조합, When 두 번째 레코드 생성, Then 중복 오류.

### CMN-00-MDM-006 품질 특성(Characteristic)·특별특성

추적 Q-6, 11, 12, 26, 23 · 필수 · W0 · SF, SNOW · DM · Customization · 선행 MDM-004 · 3 M/D

**목적**: 수입검사·출하검사·SPC·MSA가 공통으로 쓰는 “무엇을, 어떤 규격으로 재는가”의 단일 정의. 관리계획서(Control Plan)의 특성 행에 해당하며, 특별특성(CC/SC)은 고객 감사의 핵심 확인 대상이다.

**데이터 모델**

| 객체 / 필드                                                   | 타입                                                  | 필수                                  | 설명                                         |
|---------------------------------------------------------------|-------------------------------------------------------|---------------------------------------|----------------------------------------------|
| CMN_Characteristic__c.Item__c                             | Master-Detail(CMN_Item__c)                          | Y                                     |                                              |
| CMN_Characteristic__c.CharNo__c                           | Text(20)                                              | Y                                     | 도면 풍선 번호 또는 관리계획서 번호          |
| CMN_Characteristic__c.CharType__c                         | Picklist (VARIABLE 계량, ATTRIBUTE 계수, VISUAL 관능) | Y                                     | VISUAL은 한도견본(QMS-06-LMS) 연결 대상      |
| CMN_Characteristic__c.Nominal__c / USL__c / LSL__c    | Number(18,6)                                          | VARIABLE이면 USL·LSL 중 1개 이상 필수 | 편측 규격 허용                               |
| CMN_Characteristic__c.Unit__c                             | Picklist (mm, um, deg, N, Nm, cd, lx, V, A, %, ETC)   | VARIABLE이면 필수                     |                                              |
| CMN_Characteristic__c.SpecialClass__c                     | Picklist (NONE, CC, SC)                               | Y                                     | CC = 안전·법규, SC = 기능·성능 핵심          |
| CMN_Characteristic__c.CustomerSymbol__c                   | Text(20)                                              | N                                     | OEM 고유 기호 표기                           |
| CMN_Characteristic__c.SpcRequired__c                      | Checkbox                                              | Y                                     | SPC 대상 여부                                |
| CMN_Characteristic__c.TargetCpk__c                        | Number(4,2)                                           | N                                     | 기본 CC 1.67, SC·일반 1.33                   |
| CMN_Characteristic__c.Status__c                           | Picklist (DRAFT, ACTIVE, OBSOLETE)                    | Y                                     |                                              |
| CMN_Characteristic__c.EffectiveFrom__c / EffectiveTo__c | Date                                                  | ACTIVE면 From 필수                    | 4M·ECO 변경 시 구 버전 종료                  |
| CMN_Characteristic__c.ExternalKey__c                      | Text(80), External ID, Unique                         | Y                                     | `{ItemNo}-{CharNo}-{EffectiveFrom yyyymmdd}` |

**비즈니스 규칙**

- BR-1: LSL \< Nominal \< USL (존재하는 값끼리). 위반 시 저장 차단.
- BR-2: TargetCpk__c 미입력 시 SpecialClass = CC이면 1.67, 그 외 1.33을 저장 전에 채운다.
- BR-3: ACTIVE 특성은 규격값을 직접 수정할 수 없다. 새 버전을 만들고 구 버전 EffectiveTo를 닫는다(감사 시 “언제 어떤 규격으로 판정했는가” 재현).
- BR-4: ACTIVE·OBSOLETE 특성은 DWH-002에 따라 Snowflake `CORE.CHARACTERISTIC`으로 매일 + 변경 즉시 동기화한다(SPC 관리 한계 계산의 규격 소스).

**수용 기준**

- AC-1: Given USL 3.1, LSL 2.9, Nominal 3.2, When 저장, Then 차단.
- AC-2: Given ACTIVE 특성의 USL 수정 시도, When 저장, Then 차단되고 “새 버전 생성” 안내.
- AC-3: Given CC 특성 신규, When TargetCpk 공란 저장, Then 1.67.

**오픈 이슈**: 관리계획서·PFMEA 원본이 별도 도구(예: APIS IQ, Excel)에 있는지 — 있다면 특성 마스터의 원천을 그 도구로 할지 결정.

### CMN-00-MDM-007 계층형 공통 코드

추적 Q-21, 22, 17, 36, 39 · 필수 · W0 · SF · DM, LWC · Customization · 선행 ARC-002 · 4 M/D

**목적**: 불량 유형·원인·귀책·처리 방법 같은 품질 분류 체계를 현업이 직접 유지한다. AI Root Cause 추천(Q-36)과 Q&A(Q-39)의 집계 정확도는 이 코드가 일관되게 쓰이는지에 달려 있다.

**선택 기준(에이전트 필수 준수)**: 업무 상태처럼 개발자가 정하고 잘 바뀌지 않는 값 → Picklist(Global Value Set). 현업이 추가·변경하고 계층·다국어·SAP 매핑이 필요한 분류 → CMN_Code__c.

**데이터 모델**

| 객체 / 필드                                     | 타입                              | 필수              | 설명                                |
|-------------------------------------------------|-----------------------------------|-------------------|-------------------------------------|
| CMN_CodeGroup__c.GroupCode__c               | Text(40), External ID, Unique     | Y                 | 예: DEFECT_TYPE                     |
| CMN_CodeGroup__c.MaxLevel__c                | Number(1,0)                       | Y                 | 1~4                                 |
| CMN_Code__c.CodeGroup__c                    | Master-Detail(CMN_CodeGroup__c) | Y                 |                                     |
| CMN_Code__c.Code__c                         | Text(40)                          | Y                 |                                     |
| CMN_Code__c.Parent__c                       | Lookup(self)                      | Level\>1이면 필수 |                                     |
| CMN_Code__c.Level__c                        | Number(1,0)                       | Y                 | Parent.Level + 1 자동               |
| CMN_Code__c.Name / NameEn__c / NameZh__c  | Text(80)                          | Y / N / N         | 다국어 표시명                       |
| CMN_Code__c.SortOrder__c                    | Number(4,0)                       | N                 |                                     |
| CMN_Code__c.IsActive__c                     | Checkbox                          | Y                 |                                     |
| CMN_Code__c.Attribute1__c ~ Attribute3__c | Text(255)                         | N                 | 그룹별 확장 속성(예: SAP 결함 코드) |
| CMN_Code__c.ExternalKey__c                  | Text(90), External ID, Unique     | Y                 | `{GroupCode}/{Code}`                |
| CMN_Code__c.Path__c                         | Text(255)                         | —                 | “외관 \> 이물 \> 렌즈 내부” 자동    |

**초기 코드 그룹**: DEFECT_TYPE(3레벨: 외관/치수/기능/광학/기밀/전기), DEFECT_LOCATION, CAUSE_5M1E(Man, Machine, Material, Method, Measurement, Environment), RESPONSIBILITY(사내 공정, 사내 설계, 협력사, 물류, 고객), DISPOSITION(폐기, 재작업, 선별, 특채, 반품). 값은 SL 현행 코드로 교체.

**화면**: 재사용 LWC `cmnCodePicker` — 속성 `groupCode`, `maxLevel`, `value`(리프 CMN_Code__c Id). 대→중→소 연쇄 선택, 비활성 코드 미표시, 사용자 언어로 표시. 업무 객체는 리프 Lookup 1개 + Path 텍스트 사본을 저장한다.

**비즈니스 규칙**

- BR-1: 업무 레코드에서 참조 중인 코드는 삭제 불가, 비활성화만 가능.
- BR-2: Level은 MaxLevel을 넘을 수 없다.

**수용 기준**

- AC-1: Given 영어 사용자, When cmnCodePicker로 불량 유형 선택, Then NameEn__c로 표시되고 NameEn이 비면 Name으로 대체.
- AC-2: Given NCR이 참조하는 코드, When 삭제, Then 차단.
- AC-3: Given 비활성 중분류, When 피커 표시, Then 그 하위 소분류도 나타나지 않는다.

## 7. CMN-00-SEC 권한·보안

### CMN-00-SEC-001 페르소나·권한 셋 구조

추적 NFR-4.2(RBAC), Q-34, P-55 · 필수 · W0 · SF · CFG · Tailoring · 선행 ARC-001 · 3 M/D

**목적**: 품질팀·개발팀·구매팀·생산팀·협력사·경영진(RFP 4.2)과 PMS의 PM·CFT·PMO를 한 Org에서 분리한다. “데이터는 하나, 화면은 역할별”이 단일 플랫폼 제안의 핵심 메시지다.

**구조 규칙**

- BR-1: Profile은 2개만 쓴다. `SL Internal User`(객체 권한 없음, 로그인·탭 기본만), `SL Supplier Portal User`(Experience Cloud). 객체·필드 권한은 전부 Permission Set으로 준다.
- BR-2: 기능 단위 PS(`{접두어}_PS_{기능}_{Read/Edit/Approve/Admin}`)는 각 기능 WI가 만들고, 페르소나 PSG는 이 WI가 만든다. 새 기능 WI는 아래 매핑표에 따라 해당 PSG에 자기 PS를 추가하는 작업을 포함해야 한다.
- BR-3: 한 사용자가 여러 PSG를 가질 수 있다(예: 품질 엔지니어이면서 내부심사원).
- BR-4: Lightning App은 5개다. 앱 할당은 PSG가 결정한다(2026-11-05 화면 전략, 결정 DS-1).
  - `SL QMS 품질 업무`: 품질 전문가용.
  - 모든 앱은 표준 내비게이션이다(콘솔 미사용, DS-7).
  - `SL QMS`: 참여자·경영진, 모든 사내 사용자.
  - `SL QMS 현장`: 현장 입력, 모바일 우선.
  - `SL Admin`: 품질경영팀·IT.
  - `SL PMS`.
  - 앱-PSG 매핑과 내비게이션 항목은 UX-007 BR-1·BR-2가 정한다.

**페르소나 PSG**

| PSG                                    | 대상                     | 주요 권한                                    |
|----------------------------------------|--------------------------|----------------------------------------------|
| QMS_PSG_QualityEngineer                | 공장 품질 엔지니어       | NCR·4M·Claim·8D 생성/수정, 검사 판정         |
| QMS_PSG_QualityManager                 | 품질팀장                 | QualityEngineer + 결재, 특채·종결 승인       |
| QMS_PSG_Inspector                      | 현장 검사원(모바일 위주) | 검사 결과 입력, NCR 등록, 한도견본 조회      |
| QMS_PSG_SupplierQuality                | 협력사 품질(SQE)         | 수입검사, 부품 NCR, 협력사 4M·Audit          |
| QMS_PSG_Auditor                        | 내부·협력사 심사원       | 심사 계획·결과·지적 사항                     |
| QMS_PSG_Viewer                         | 개발·구매·생산 일반      | 조회 + 귀책 부서 대책 입력                   |
| QMS_PSG_QualityAdmin                   | 품질경영팀               | 코드·체크리스트·양식·LELE 마스터 관리        |
| CMN_PSG_Executive                      | 경영진                   | 대시보드·조회 전용(View All, 비용 필드 포함) |
| CMN_PSG_SystemAdmin                    | IT 운영                  | 설정, 로그, 연계 모니터링                    |
| PMS_PSG_PM / PMS_PSG_CFT / PMS_PSG_PMO | PMS 사용자               | PMS Vol.에서 정의(이름만 예약)               |

**수용 기준**

- AC-1: Given QMS_PSG_Inspector만 가진 사용자, When 앱 런처, Then `SL QMS 현장`만 보이고 Setup 접근 불가.
- AC-2: Given 신규 사용자에게 PSG 미할당, When 로그인, Then 업무 객체 탭이 하나도 보이지 않는다.

**에이전트 주의**: Profile에 객체 권한을 넣지 않는다. “View All Data”·“Modify All Data” 시스템 권한은 CMN_PSG_SystemAdmin 외 금지.

### CMN-00-SEC-002 공장·협력사 데이터 격리(공유 모델)

추적 NFR-4.2(협력사 격리), NFR-4.3(멀티 사이트), P-57 · 필수 · W0 · SF, EXP · APEX, CFG · Customization · 선행 SEC-001, MDM-002, MDM-005 · 6 M/D

**목적**: 해외 공장 사용자는 자기 공장 데이터만, 협력사는 자기 회사 데이터만 본다. RFP가 명시한 “협력사 격리 구조”와 TISAX 대응의 실체다.

**데이터 모델**

| 객체 / 필드                                       | 타입                          | 필수 | 설명                                                                         |
|---------------------------------------------------|-------------------------------|------|------------------------------------------------------------------------------|
| CMN_UserPlantAccess__c.User__c                | Lookup(User)                  | Y    |                                                                              |
| CMN_UserPlantAccess__c.Plant__c               | Lookup(CMN_Plant__c)        | Y    |                                                                              |
| CMN_UserPlantAccess__c.AccessLevel__c         | Picklist (Read, Edit)         | Y    |                                                                              |
| CMN_UserPlantAccess__c.ExternalKey__c         | Text(40), External ID, Unique | Y    | `{EmployeeNo}-{PlantCode}`                                                   |
| CMN_SharingConfig__mdt                          | Custom Metadata               | —    | ObjectApiName__c, PlantField__c, SupplierField__c(선택), IsActive__c |
| Public Group `CMN_GRP_PLANT_{PlantCode}_R` / `_E` | Group                         | —    | 공장별 읽기/편집 그룹. 공장 생성 시 자동 생성                                |
| Apex Sharing Reason `CMN_Plant`, `CMN_Supplier`   | 각 업무 객체                  | —    | 업무 객체 WI가 자기 객체에 생성                                              |

**비즈니스 규칙**

- BR-1: QMS·PMS 업무 객체의 OWD는 Private, 마스터(MDM 전체)는 Public Read Only.
- BR-2: CMN_UserPlantAccess__c 생성/삭제 시 해당 사용자를 공장 그룹 R 또는 E에 추가/제거한다(비동기, Queueable).
- BR-3: 업무 레코드 insert 또는 PlantField 값 변경 시 `CMN_SharingService.recalculate(records)`가 해당 공장 그룹 2개에 __Share 행을 만들고, 이전 공장 공유는 삭제한다. 대상 객체·필드는 CMN_SharingConfig__mdt로만 결정한다(객체별 하드코딩 금지).
- BR-4: SupplierField__c가 설정된 객체는 해당 협력사 Account의 포털 사용자 역할 그룹에 Read 공유를 추가한다. 협력사가 편집해야 하는 객체(NCR 회신 등)는 해당 기능 WI가 Edit 공유를 별도 정의.
- BR-5: 본사 품질경영팀·경영진은 PSG의 객체 View All로 전 공장을 본다(공유 행 생성 대상 아님).
- BR-6: 전체 재계산 배치 `CMN_SharingRecalcBatch(objectApiName)`를 제공한다(공장 그룹 재구성, 데이터 이관 후 사용).

**수용 기준**

- AC-1: Given 사용자 U가 KR01 Read만 보유, When CN01 공장의 NCR 조회(리스트뷰·글로벌 검색·리포트), Then 결과에 없다.
- AC-2: Given NCR의 Plant를 KR01→KR02로 변경, When 저장, Then KR01 그룹 공유는 삭제되고 KR02 그룹 공유가 생긴다.
- AC-3: Given 협력사 A 포털 사용자, When 협력사 B 관련 부품 NCR URL에 직접 접근, Then 권한 없음.
- AC-4: Given 10,000건 NCR, When 재계산 배치 실행, Then 거버너 제한 오류 없이 완료(배치 크기 200).

**오픈 이슈**: 협력사 포털 라이선스(Partner Community vs Customer Community Plus)에 따라 협력사 공유 대상 그룹이 달라진다. QMS-03-SPP 작성 시 확정하고 BR-4를 갱신한다.

### CMN-00-SEC-003 감사 로그·삭제 통제

추적 NFR-4.2(감사 로그), Q-33, P-39 · 필수 · W0 · SF · APEX, CFG · Customization · 선행 ARC-002 · 4 M/D

**목적**: IATF 16949는 품질 기록(부적합, PPAP, 변경 기록 등)을 부품 활성 기간 + 1년 이상 보존하도록 요구한다. 고객 감사에서 “누가 언제 무엇을 바꿨나”를 즉시 보여줄 수 있어야 한다.

**데이터 모델**

| 객체 / 필드                                        | 타입                    | 필수 | 설명                                                                             |
|----------------------------------------------------|-------------------------|------|----------------------------------------------------------------------------------|
| CMN_DeleteLog__c.ObjectApiName__c              | Text(80)                | Y    |                                                                                  |
| CMN_DeleteLog__c.RecordIdText__c               | Text(18)                | Y    |                                                                                  |
| CMN_DeleteLog__c.RecordNo__c                   | Text(40)                | N    | 업무 번호(있으면)                                                                |
| CMN_DeleteLog__c.Snapshot__c                   | Long Text(131072)       | Y    | 삭제 직전 레코드 JSON                                                            |
| CMN_DeleteLog__c.DeletedBy__c / DeletedAt__c | Lookup(User) / DateTime | Y    |                                                                                  |
| CMN_DeleteLog__c.Reason__c                     | Text(255)               | N    | 삭제 사유(UI에서 입력 시)                                                        |
| CMN_DeleteGuard__mdt                             | Custom Metadata         | —    | ObjectApiName__c, StatusField__c, DeletableValues__c(쉼표 구분, 예: DRAFT) |

**비즈니스 규칙**

- BR-1: CMN_DeleteGuard__mdt에 등록된 객체는 StatusField 값이 DeletableValues에 없으면 beforeDelete에서 차단한다. 관리자도 예외 없음(데이터 정정은 상태 되돌림 절차로).
- BR-2: 등록 객체의 삭제는 afterDelete에서 CMN_DeleteLog__c에 스냅숏을 남긴다. CMN_DeleteLog__c 자체는 누구도 수정·삭제할 수 없다(PS 권한 Read만).
- BR-3: 필드 변경 이력은 표준 Field History Tracking을 쓰고, 각 업무 객체 WI가 추적 필드(객체당 최대 20개)를 지정한다. 보존 기간이 18~24개월을 넘어야 하는 이력은 DWH-002가 Snowflake `CORE.SF_FIELD_HISTORY`로 매일 적재해 장기 보존한다.
- BR-4: 업무 레코드는 물리 삭제 대신 종결·취소 상태로 남기는 것이 기본이다. 삭제는 DRAFT 단계 오입력 정정에만 허용한다.

**수용 기준**

- AC-1: Given 상태 APPROVED인 4M 변경, When 관리자 삭제, Then 차단.
- AC-2: Given DRAFT NCR 삭제, When 완료, Then CMN_DeleteLog__c 1건(Snapshot에 전 필드 JSON).
- AC-3: Given 일반 사용자, When CMN_DeleteLog__c 수정 시도, Then 권한 없음.

**오픈 이슈**: Shield Field Audit Trail(최대 10년 보존, 객체당 60필드) 구매 여부. 구매 시 BR-3의 Snowflake 장기 보존은 보조로 전환.

### CMN-00-SEC-004 인증·암호화·플랫폼 보안 설정

추적 NFR-4.2(암호화, SSO), Q-41 · 필수 · W0 · SF, SNOW, MULE · CFG · Tailoring · 선행 SEC-001 · 3 M/D

**목적**: TLS 1.2+·AES-256 저장 암호화·SSO 요구와 TISAX 점검 항목을 설정으로 충족하고 근거 문서를 남긴다.

**설정 항목**

| 영역               | 설정                                        | 값                                                                                     |
|--------------------|---------------------------------------------|----------------------------------------------------------------------------------------|
| Salesforce 로그인  | My Domain, login.salesforce.com 로그인 차단 | SSO 전용. 시스템 관리자 2명만 비상용 ID/PW + MFA                                       |
| Salesforce 세션    | Session Timeout / 고정 IP 잠금              | 2시간 / 해제(해외 이동 사용자)                                                         |
| Salesforce 암호화  | 전송                                        | 플랫폼 기본 TLS 1.2+                                                                   |
| Salesforce 암호화  | 저장                                        | 플랫폼 기본 저장 암호화. Shield Platform Encryption은 오픈 이슈 결정 후 대상 필드 지정 |
| Snowflake 인증     | 사용자 / 서비스 계정                        | SAML SSO / Key-pair 인증(비밀번호 금지)                                                |
| Snowflake 네트워크 | Network Policy                              | Mule·Salesforce 송출 IP·사내망만 허용                                                  |
| Snowflake 데이터   | Masking Policy                              | 임율·원가 컬럼은 `ROLE_FINANCE_READ`만 원문                                            |
| MuleSoft           | 클라이언트 인증                             | Client ID Enforcement + OAuth 2.0 Client Credentials                                   |

**수용 기준**

- AC-1: Given 일반 사용자, When login.salesforce.com에서 ID/PW 로그인, Then 거부.
- AC-2: Given 마스킹 대상 컬럼, When `ROLE_QMS_ANALYST`로 조회, Then 마스킹 값 반환.
- AC-3: 설정 근거 문서 `docs/security/baseline.md`가 저장소에 존재하고 항목별 설정 화면 경로를 기록한다.

**오픈 이슈**: (1) Shield 구매 범위. (2) 중국 공장 데이터 국외 이전(중국 PIPL·데이터 보안법) — 중국 사용자 개인정보 처리 방식. (3) Salesforce·Snowflake·MuleSoft TISAX 레이블 보유 여부 확인.

## 8. CMN-00-I18N / UX 다국어·모바일·화면 공통

### CMN-00-I18N-001 다국어 기반(UI 언어·마스터 데이터·포탈 언어 연동)

추적 Q-1, P-1, NFR-4.3(언어 확장) · 필수 · W0 · SF · CFG, APEX, LWC · Tailoring · 선행 MDM-001 · 5 M/D

**목적**: 한·영·중 기본, 폴란드어·스페인어·포르투갈어 확장. 포탈 로그인 언어를 자동 적용하되 QMS 안에서 개별 변경도 가능해야 한다(RFP 원문 요구 두 가지가 충돌하지 않도록 규칙을 정한다).

**데이터 모델**

| 객체 / 필드                             | 타입          | 필수 | 설명                                                |
|-----------------------------------------|---------------|------|-----------------------------------------------------|
| User.LanguageOverride__c              | Checkbox      | N    | true면 포탈 언어를 무시하고 사용자가 고른 언어 유지 |
| (모든 마스터).NameEn__c / NameZh__c | Text(80)      | N    | 영문·중문 표시명                                    |
| (모든 마스터).DisplayName__c          | Formula(Text) | —    | 아래 BR-3 수식                                      |

**비즈니스 규칙**

- BR-1: Org 기본 언어 ko. Translation Workbench 활성 언어: en_US, zh_CN(완전 지원), pl, es, pt_BR. 화면 문구는 Custom Label·객체/필드/Picklist 번역으로만 제공한다.
- BR-2: SAML SSO 로그인 시 커스텀 `Auth.SamlJitHandler`(`CMN_SamlJitHandler`)가 어설션 속성 `lang`(값 예: ko, en, zh)을 읽어 LanguageLocaleKey를 갱신한다. 단 LanguageOverride__c = true면 갱신하지 않는다. JIT 핸들러는 사용자를 새로 만들지 않는다(사용자 생성은 INT-002 HR 연계만).
- BR-3: DisplayName__c = `CASE(LEFT($User.LanguageLocaleKey,2), "ko", Name, "zh", BLANKVALUE(NameZh__c, BLANKVALUE(NameEn__c, Name)), BLANKVALUE(NameEn__c, Name))`. 즉 pl·es·pt 사용자는 영문으로 대체 표시.
- BR-4: 유틸리티 바 LWC `cmnLanguageSwitcher`: 언어 선택 시 User.LanguageLocaleKey 변경 + LanguageOverride__c = true 저장 후 페이지 새로고침. “포탈 언어 따르기” 옵션 선택 시 LanguageOverride__c = false.
- BR-5: 날짜·숫자 형식은 User.LocaleSidKey, 시각은 User.TimeZoneSidKey. 업무 기한(SLA)은 공장 시간대(MDM-002) 기준으로 계산하고 화면에서는 사용자 시간대로 표시한다.
- BR-6: 모든 WI의 완료 조건 = 해당 WI가 만든 라벨·필드·Picklist의 ko·en_US·zh_CN 번역. pl·es·pt_BR은 언어 확장 시 STF 파일로 일괄 반입한다.

**수용 기준**

- AC-1: Given 포탈 언어 en으로 SSO 로그인, LanguageOverride false, When QMS 진입, Then 영어 UI.
- AC-2: Given 사용자가 스위처로 zh_CN 선택 후 로그아웃, When 포탈 언어 en으로 재로그인, Then zh_CN 유지.
- AC-3: Given 폴란드어 사용자, When 불량 코드 표시, Then NameEn__c 표시.
- AC-4: 저장소 내 LWC·Apex에서 한글 문자열 리터럴을 찾는 CI 검사가 0건(테스트 클래스 제외).

**에이전트 주의**: 사용자가 입력한 본문(부적합 현상, 8D 내용)은 이 WI에서 번역하지 않는다. AI 번역은 CMN-00-AI 범위로 오픈 이슈 처리.

**오픈 이슈**: 포탈이 SAML 어설션에 언어 속성을 줄 수 있는지(속성명·값 형식) SL 포탈 담당 확인. 사용자 입력 콘텐츠의 AI 번역 제공 여부(8D·LELE 다국어 검색에 유효).

### CMN-00-UX-001 모바일·멀티 브라우저 지원

추적 Q-2, P-2, NFR-4.4(모바일) · 권장 · W1 · SF · CFG, LWC · OOTB · 선행 SEC-001 · 3 M/D

**목적**: 현장 검사원이 휴대폰으로 검사 결과 입력·부적합 등록(사진 포함)·한도견본 조회를 하고, 관리자가 이동 중 결재·조회한다.

**비즈니스 규칙**

- BR-1: 지원 채널 = Salesforce 모바일 앱(iOS·Android) + 모바일 웹 브라우저. 지원 브라우저 = Chrome·Edge·Safari 최신 2개 버전.
- BR-2: 모든 LWC는 `formFactors`에 Small을 포함해야 하며, 고정 폭(px) 레이아웃 금지. `lightning-layout-item`은 `size="12" medium-device-size="6"` 패턴.
- BR-3: 모바일 내비게이션은 앱 단위로 정한다(UX-007 BR-2).
  - `SL QMS 현장`(Inspector와 현장 입력이 있는 전문가): 홈(To-Do), 검사 입력, NCR 등록, 한도견본.
  - `SL QMS`(결재자·경영진): 홈(To-Do), 결재 현황, 내 대시보드, 메뉴 허브.
- BR-4: 사진 첨부는 카메라 직접 촬영을 지원하고 업로드 전 장변 1920px로 리사이즈한다(통신·저장 비용).
- BR-5: 바코드·QR 스캔은 `lightning/mobileCapabilities`의 BarcodeScanner를 쓰며 모바일 앱에서만 활성화하고, 웹에서는 수동 입력 필드를 보인다.

**수용 기준**

- AC-1: Given 검사원이 모바일 앱, When NCR 등록에서 사진 3장 촬영 첨부 후 저장, Then 레코드와 파일 3개가 생성되고 각 파일 장변 1920px 이하.
- AC-2: Given 결재자 모바일 웹, When To-Do에서 결재 승인, Then 데스크톱과 같은 결과.

**오픈 이슈**: 현장 Wi-Fi 음영·오프라인 입력 필요 여부(필요 시 별도 WI로 Briefcase/오프라인 설계). 측정기 직접 연결(블루투스 캘리퍼 등) 요구 여부.

### CMN-00-UX-002 화면별 사용 가이드

추적 Q-3, P-3 · 권장 · W2 · SF · DM, LWC · Customization · 선행 I18N-001 · 3 M/D

**목적**: 매뉴얼과 별도로 “지금 보는 화면”의 사용법을 화면 안에서 보여준다. 회사표준 개편(27.01~27.12) 기간에 절차가 바뀌므로 개발 없이 관리자가 내용을 고칠 수 있어야 한다.

**데이터 모델**

| 객체 / 필드                              | 타입                                       | 필수 | 설명                                                           |
|------------------------------------------|--------------------------------------------|------|----------------------------------------------------------------|
| CMN_ScreenGuide__c.PageKey__c        | Text(80)                                   | Y    | 화면 키(예: `QMS_NCR__c.RECORD`, `QMS_NCR__c.LIST`, `cmnHome`) |
| CMN_ScreenGuide__c.Language__c       | Picklist (ko, en_US, zh_CN, pl, es, pt_BR) | Y    |                                                                |
| CMN_ScreenGuide__c.Content__c        | Rich Text(32768)                           | Y    | 본문(이미지 포함 가능)                                         |
| CMN_ScreenGuide__c.VideoUrl__c       | URL                                        | N    | 사내 동영상 링크                                               |
| CMN_ScreenGuide__c.StandardDocUrl__c | URL                                        | N    | 관련 회사표준(프로세스·지침) 링크                              |
| CMN_ScreenGuide__c.IsPublished__c    | Checkbox                                   | Y    |                                                                |
| CMN_ScreenGuide__c.ExternalKey__c    | Text(100), Unique                          | Y    | `{PageKey}-{Language}`                                         |

**비즈니스 규칙**

- BR-1: LWC `cmnScreenGuide`는 유틸리티 바에 두고, 현재 페이지에서 PageKey를 결정한다(레코드 페이지 = `{객체API}.RECORD`, 리스트 = `{객체API}.LIST`, 앱 페이지 = 페이지 API명).
- BR-2: 사용자 언어 가이드 → en_US → ko 순으로 대체 표시.
- BR-3: 공지성 안내(신규 기능 알림)는 표준 In-App Guidance Prompt로 설정하고 이 객체에 넣지 않는다.

**수용 기준**

- AC-1: Given NCR 레코드 페이지, When 가이드 아이콘 클릭, Then `QMS_NCR__c.RECORD` 가이드가 사용자 언어로 열린다.
- AC-2: Given 해당 언어 가이드 없음, When 열기, Then en_US 가이드.

### CMN-00-UX-003 공통 UI 컴포넌트(상태 진행바·코멘트 타임라인)

추적 P-47, Q-29, Q-13 (진행 추적) · 필수 · W0 · SF · DM, LWC, APEX · Customization · 선행 I18N-001, ARC-002 · 5 M/D

**목적**: NCR·4M·8D·Audit·PMS 액티비티가 같은 모양의 진행 표시와 의견 이력을 갖게 해 사용자 학습 비용을 줄이고 에이전트별 UI 편차를 막는다.

**데이터 모델**

| 객체 / 필드                            | 타입             | 필수 | 설명                                                                                                       |
|----------------------------------------|------------------|------|------------------------------------------------------------------------------------------------------------|
| CMN_StatusFlow__mdt                  | Custom Metadata  | —    | ObjectApiName__c, StatusField__c                                                                       |
| CMN_StatusStep__mdt                  | Custom Metadata  | —    | StatusFlow__c, Value__c(Picklist API값), Sequence__c, LabelKey__c(Custom Label명), IsTerminal__c |
| CMN_Comment__c.ParentRecordId__c   | Text(18)         | Y    | 대상 레코드 Id(다형)                                                                                       |
| CMN_Comment__c.ParentObject__c     | Text(80)         | Y    | 대상 객체 API명                                                                                            |
| CMN_Comment__c.Body__c             | Long Text(32768) | Y    | 본문(@멘션 포함)                                                                                           |
| CMN_Comment__c.MentionedUserIds__c | Text(1000)       | N    | 멘션 사용자 Id 목록(쉼표)                                                                                  |
| CMN_Comment__c.IsEdited__c         | Checkbox         | —    |                                                                                                            |

**비즈니스 규칙**

- BR-1: `cmnStatusPath`(속성 recordId, objectApiName)는 메타데이터 순서대로 단계를 그리고 현재 상태를 강조한다. 단계 클릭으로 상태를 바꾸지 않는다(상태 변경은 각 업무 버튼·결재로만).
- BR-2: `cmnCommentTimeline`은 최신순 표시, 작성자 본인만 24시간 내 수정·삭제 가능(이후 수정 불가, 감사 추적). 멘션 대상에게 NTF-001 알림 발송.
- BR-3: CMN_Comment__c 공유는 부모 레코드 접근 권한을 따른다: 조회 Apex가 부모 레코드 접근 가능 여부(`UserRecordAccess`)를 확인한 뒤 반환한다.
- BR-4: 업무 레코드 표준(UX-004)에서 `cmnStatusPath`는 영역 B(하위 헤더)에 둔다. `cmnCommentTimeline`은 결정 지원 레일의 COMMENT 패널이다. 그래서 레일 패널 계약(UX-004 BR-6)을 지킨다: `@api config`, `@api variant`를 받고, `variant="rail"`이면 좁은 폭으로 표시하며, 건수 배지는 `railbadge` 이벤트로 알린다.

**수용 기준**

- AC-1: Given 사용자 A가 KR02 NCR에 접근 권한 없음, When 해당 NCR의 코멘트 조회 API 호출, Then 빈 결과.
- AC-2: Given 25시간 지난 본인 코멘트, When 수정, Then 차단.
- AC-3: Given 코멘트에 @B 멘션, When 저장, Then B에게 알림 1건.

**에이전트 주의**: 표준 Chatter Feed를 쓰지 않는다(포털·다국어·감사 요건 일관성). 표준 Path 컴포넌트는 레코드타입별 설정 부담이 커서 쓰지 않는다.

### CMN-00-UX-004 업무 레코드 작업공간 템플릿·결정 지원 레일

추적 Q-2, Q-29, P-47, NFR-4.4(모바일) · 필수 · W0 · SF · LWC, APEX, CFG · Customization · 선행 UX-003, DSH-001, I18N-001 · 6 M/D

**목적**: NCR·4M·8D·Re-PPAP·인정시험 계획·개선과제·심사 같은 단계형 업무 레코드(화면 유형 T1)가 모두 같은 배치로 열리게 한다. 사용자는 첫 화면에서 스크롤 없이 "지금 단계에서 무엇을 입력하고, 누가 기다리며, AI가 무엇을 권하는가"를 본다. 메뉴마다 레코드 페이지를 따로 설계하면 에이전트별 편차가 생기고, 정기 릴리즈·SLDS 2 전환 때 고칠 곳이 늘어난다.

**범위**
- In:
  - 업무 레코드 배치 표준(영역 A~E)
  - 레코드 페이지 생성기(정의 파일 → FlexiPage 데스크톱·휴대폰, 콤팩트 레이아웃)와 페이지 규칙 검사기
  - 결정 지원 레일 `cmnDecisionRail`과 패널 설정 `CMN_RailPanel__mdt`, 레일 패널 계약
  - 헤더 7개 필드 규칙, 기한 D-day 수식 규칙
  - 문맥 분석 패널(DSH-001 위젯 계약 재사용)
  - LWC 스타일 CI 검사 `scripts/ci/check-lwc-styling.py`
- Out:
  - 상태별 섹션·버튼 노출 규칙: UX-005
  - 그리드: UX-006
  - 현장 입력: UX-008
  - 체크리스트: UX-009
  - 진행 단계 컴포넌트 자체: UX-003
  - 각 업무 객체의 실제 레코드 페이지와 D-day 필드: 각 메뉴 WI가 이 생성기로 만든다
  - 위젯 콘텐츠: QMS-07 등

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| CMN_RailPanel__mdt | Custom Metadata | — | 레일 패널 설정. 1행 = 객체 1개의 패널 1개 |
| CMN_RailPanel__mdt.ObjectApiName__c | Text(80) | Y | 대상 업무 객체 API명. `*` = 모든 T1 객체의 기본 패널 |
| CMN_RailPanel__mdt.PanelKey__c | Text(40) | Y | AI, APPROVAL, TODO, COMMENT, DOCUMENT, CONTEXT_{이름} 등. 같은 키의 객체 행이 `*` 행을 덮어쓴다 |
| CMN_RailPanel__mdt.ComponentName__c | Text(80) | Y | 동적으로 불러올 LWC(`c/cmnAiRecommendationList` 형식) |
| CMN_RailPanel__mdt.TitleLabel__c | Text(80) | Y | 패널 제목 Custom Label 이름 |
| CMN_RailPanel__mdt.Order__c / PhoneOrder__c | Number(3,0) / Number(3,0) | Y / N | 데스크톱 순서 / 휴대폰 순서(비우면 Order) |
| CMN_RailPanel__mdt.DefaultOpen__c | Checkbox | — | 기본 펼침 |
| CMN_RailPanel__mdt.RequiredPermission__c | Text(80) | N | Custom Permission API명. 지정하면 보유자에게만 표시 |
| CMN_RailPanel__mdt.Config__c | Long Text(4000) | N | 패널 설정 JSON(예: DocClass 목록, 위젯 키·바인딩) |
| CMN_RailPanel__mdt.IsActive__c | Checkbox | — | |
| (각 T1 객체).DaysToDue__c | Formula(Number, 0) | — | `DueDate__c - TODAY()`. 규칙은 이 WI, 필드는 각 업무 WI가 만든다 |
| (각 T1 객체) 콤팩트 레이아웃 `{객체}_Header` | Compact Layout | — | 헤더 7개 필드 순서(BR-3). 각 업무 WI가 생성기로 만든다 |

**비즈니스 규칙**

- BR-1: 배치. 데스크톱은 App Builder 표준 템플릿 "헤더, 하위 헤더, 오른쪽 사이드바"를 쓴다(커스텀 Aura 템플릿 금지).
  - A 헤더: 표준 하이라이트 패널 + Dynamic Actions.
  - B 하위 헤더: `cmnStatusPath`(UX-003).
  - C 본문: 표준 탭 컴포넌트.
  - D 사이드바: `cmnDecisionRail` 하나만 둔다.
  - E 유틸리티 바: 앱 설정(UX-007).
  - 사이드바에 다른 컴포넌트를 쌓지 않는다. 패널 추가는 `CMN_RailPanel__mdt` 행으로 한다.
- BR-2: 탭 표준. 탭 이름은 라벨이다. 비활성 탭은 클릭 전에 로드하지 않는다(표준 탭 지연 로딩).
  - 현재 단계(첫 탭, 기본 선택): 현재 상태에서 입력하는 Dynamic Forms 섹션과 단계 전용 LWC(그리드·입력 셸·체크리스트·분석 도구).
  - 상세: 모든 필드를 읽기 전용 섹션으로 보여준다.
  - 관련: Dynamic Related List 최대 3개. 그 외 관련 목록은 "관련 목록 보기" 링크로 연다.
  - 이력: `cmnApprovalHistory`(APV-003)와 표준 필드 이력 관련 목록.
- BR-3: 헤더. 콤팩트 레이아웃 앞 7개 필드는 번호(`RecordNo__c`), 제목, 상태, 고객, 품번, 공장, 기한(D-day) 순서로 고정한다.
  - 해당 필드가 없는 객체(예: 내부심사의 고객)는 그 자리에 객체별 대체 필드를 두고, 정의 파일에 사유를 적는다.
  - 헤더 버튼은 Dynamic Actions로만 둔다. 노출 조건은 UX-005 동기화 스크립트가 넣는다(App Builder에서 손으로 조건을 넣지 않는다).
- BR-4: D-day 표시. 색만으로 구분하지 않고 아이콘과 텍스트를 함께 쓴다. 기준은 공장 시간대와 무관한 일 단위다.
  - `DaysToDue__c` < 0: "기한 경과 n일"(경고 아이콘).
  - 0~3: "n일 남음"(주의 아이콘).
  - 그 외: "n일 남음".
- BR-5: 레일 로드.
  - `cmnDecisionRail`(속성 `recordId`, `objectApiName`은 레코드 페이지가 넣어 준다)은 `CMN_RailPanelController.getPanels(objectApiName)`(cacheable)로 패널 목록을 받는다.
  - 서버는 `*` 행과 객체 행을 PanelKey로 합치고(객체 행 우선), `RequiredPermission__c`를 `FeatureManagement.checkPermission`으로 확인한다. 권한이 없는 패널은 응답에서 뺀다.
  - 각 패널은 `lwc:is` 동적 컴포넌트로 불러와(DSH-001 `cmnWidgetBoard`와 같은 방식, Lightning Web Security) 접기 섹션으로 감싼다. 펼친 패널만 불러오고, 접힌 패널은 열 때 불러온다.
  - 사용자가 접고 편 상태는 브라우저 저장소(객체별 키)에 남긴다. 읽기에 실패하면 `DefaultOpen__c`를 쓴다.
- BR-6: 레일 패널 계약. 모든 패널 LWC가 지킨다.
  - 속성: `@api recordId`, `@api objectApiName`, `@api config`(JSON 객체), `@api variant`.
  - `variant="rail"`이면 사이드바 폭에서 가로 스크롤 없이 표시한다(고정 px 폭 금지).
  - 건수 배지는 `railbadge` 이벤트(`detail: {count, severity}`)로 레일 머리에 알린다.
  - 오류는 패널 안에서만 표시하고 다른 패널에 영향을 주지 않는다.
  - 기본 패널(`*` 행)과 기본 펼침:

    | PanelKey | 컴포넌트 | 근거 WI | 기본 펼침 |
    | --- | --- | --- | --- |
    | AI | `cmnAiRecommendationList` | AI-004 | 펼침 |
    | APPROVAL | `cmnApprovalLine` 요약 | APV-003 | 펼침 |
    | TODO | 이 레코드에 걸린 열린 To-Do | TDO-001 | 접힘 |
    | COMMENT | `cmnCommentTimeline` | UX-003 | 접힘 |
    | DOCUMENT | `cmnDocumentPanel` | DOC-001 | 접힘 |

    AI 패널은 AI-004가 배포되기 전에는 `IsActive__c = false`로 둔다.
- BR-7: 문맥 분석 패널(CONTEXT_*).
  - `ComponentName__c`는 DSH-001 위젯 계약(`@api config`, `@api size`)을 따르는 위젯 LWC다.
  - `Config__c` 형식: `{"widgetKey": "…", "bind": {"characteristicId": "Characteristic__c", "itemId": "Item__c", "plantId": "Plant__c"}}`.
  - 레일은 `CMN_RailPanelController.resolveBindings(recordId, fieldNames)`(USER_MODE 조회)로 레코드 값을 읽어 위젯 config에 넣는다. 레코드나 필드에 접근 권한이 없으면 해당 값은 비운다.
  - 위젯은 `CMN_KpiValue__c`나 DWH-004 등록 쿼리로만 데이터를 읽는다(Snowflake 직접 호출 금지, DSH-001 BR-5). size는 S로 준다.
  - 예: NCR은 해당 특성의 최근 관리도와 같은 불량의 3개월 발생 건수, 4M은 해당 품번의 최근 Cpk를 보여준다.
- BR-8: 휴대폰. 폼 팩터 Small에는 별도 페이지를 할당한다.
  - 순서: 헤더(번호·상태·품번·기한 4개) → 진행 단계(현재 단계 이름) → 현재 단계 섹션 → 레일 패널(PhoneOrder 순, AI·결재만 펼침) → 상세(접힘).
  - 관련·이력은 링크로 연다.
- BR-9: 생성기와 검사기.
  - 레코드 페이지는 정의 파일 `meta-src/record-pages/{객체}.json`에서 `scripts/dev/metagen.py`의 `recordPage` 생성기로 처음 만든다. 출력은 데스크톱·휴대폰 FlexiPage, 콤팩트 레이아웃, 객체 기본 보기 할당이다.
  - 정의 파일의 내용: 헤더 7개 필드, 현재 단계 섹션 목록, 상세 섹션, 관련 목록 3개, 단계 전용 LWC와 속성.
  - 첫 생성 뒤에는 FlexiPage XML이 원천이다. 현업이 App Builder에서 바꾼 것은 retrieve로 소스에 반영한다.
  - `scripts/ci/check-record-pages.py`는 T1 페이지에서 다음을 오류로 낸다.
    - 첫 탭 표시 컴포넌트 11개 이상
    - 관련 목록 4개 이상
    - 사이드바에 `cmnDecisionRail` 외 컴포넌트
    - Dynamic Actions 밖의 버튼
    - 휴대폰 페이지 누락
  - T1 객체 목록은 `CMN_StatusFlow__mdt`(UX-003)에 등록된 객체다.
- BR-10: 스타일 검사. `scripts/ci/check-lwc-styling.py`는 `force-app-*/main/default/lwc/**/*.css`를 검사한다.
  - 다음을 오류로 낸다: 색 리터럴(`#rgb`, `#rrggbb`, `rgb(`, `rgba(`, `hsl(`), 컴포넌트 스타일링 훅 `--slds-c-*`, 구 토큰 `--lwc-*`.
  - 허용: SLDS 전역 스타일링 훅 `--slds-g-*`. `var()`의 대체값에도 색 리터럴을 쓰지 않는다.
  - 기존 `check-lwc-mobile.py`와 함께 CI에서 돈다.
- BR-11: 성능.
  - 레코드 페이지 첫 화면은 3초 이내(EPT, 해외 공장 포함 UAT)다.
  - 첫 탭 표시 컴포넌트는 10개 이하, 관련 목록은 3개 이하다.
  - 레일은 첫 표시 때 서버 호출이 패널 목록 1회와 펼친 패널 각자의 호출뿐이다.

**화면/UX**: 화면 유형 T1 표준 자체다. 배치 그림은 `screen-strategy.md` 5절에 있다.
- 데스크톱: 하위 헤더에 진행 단계, 본문 약 2/3, 레일 약 1/3.
- 레일 머리: 패널 제목과 배지만 표시한다. 펼친 패널은 레일 안에서 스크롤한다.

**권한**
- 이 WI가 `CMN_PS_UiFramework_User`를 만든다. 이 권한 세트는 Apex 클래스 `CMN_RailPanelController`를 담는다. 뒤 UX WI의 컨트롤러도 여기에 더한다.
- 사내 PSG 전부에 넣는다(SEC-001 BR-2).
- 패널 데이터 권한은 각 패널 컴포넌트의 원래 WI가 확인한다.

**수용 기준**

- AC-1: Given 테스트 객체(`CMN_TestRecord__c`) 정의 파일, When 생성기 실행 후 배포, Then 데스크톱 페이지에 영역 A~D가 있고 첫 탭이 "현재 단계"이며 휴대폰 페이지가 할당된다.
- AC-2: Given `*` 행 AI(1)·APPROVAL(2)·COMMENT(3)와 객체 행 COMMENT(Order 0), When 레일 표시, Then COMMENT가 맨 위, AI·APPROVAL이 펼쳐진 상태로 표시된다.
- AC-3: Given RequiredPermission이 지정된 패널, When 권한 없는 사용자가 `getPanels` 호출, Then 응답과 화면에 그 패널이 없다.
- AC-4: Given 패널 하나가 예외를 낸다, When 레일 표시, Then 그 패널에만 오류 표시, 나머지는 정상 표시.
- AC-5: Given DueDate가 어제, When 헤더 표시, Then "기한 경과 1일" 텍스트와 경고 아이콘.
- AC-6: Given CONTEXT 패널 bind `characteristicId = Characteristic__c`, When 레일 표시, Then 위젯 config에 레코드의 특성 Id가 들어간다. 그 필드에 FLS가 없는 사용자는 빈 값이다.
- AC-7: Given 사이드바에 다른 컴포넌트를 넣은 T1 FlexiPage, When `check-record-pages.py`, Then 오류 1건 이상, 종료 코드 1.
- AC-8: Given CSS에 `#ff0000`이나 `--slds-c-button-color-background`가 있는 LWC, When `check-lwc-styling.py`, Then 파일·줄을 출력하고 종료 코드 1.
- AC-9: Given 접힌 패널 3개, When 레일 첫 표시, Then 접힌 패널의 서버 호출이 0건이다(Jest).

**에이전트 주의**
- 커스텀 Aura 레코드 템플릿을 만들지 않는다.
- 레코드 페이지 전체를 덮는 LWC를 두지 않는다.
- 레일 안에서 패널끼리 데이터를 주고받지 않는다. 필요하면 레코드 변경 알림(`notifyRecordUpdateAvailable`)이나 메시지 채널을 쓴다.
- 템플릿 API명은 Org에서 App Builder로 새 페이지를 만들어 확인한 값을 쓴다.
- 표준 Path 컴포넌트는 쓰지 않는다(UX-003).

**오픈 이슈**
- 역할(PSG)별로 기본 펼침 패널을 달리할지 정해야 한다.

### CMN-00-UX-005 상태·권한 화면 제어 매트릭스

추적 NFR-4.2(RBAC), Q-29, P-47 · 필수 · W0 · SF · DM, APEX, CFG · Customization · 선행 UX-003, UX-004, SEC-001 · 5 M/D

**목적**: 상태가 있는 객체마다 "어느 상태에서 누가 어떤 섹션을 고치고 어떤 버튼을 누를 수 있는가"를 표 하나로 정의한다. 같은 표에서 화면 노출(Dynamic Forms·Dynamic Actions 가시성)과 서버 검증을 함께 만들어 화면과 서버가 어긋나지 않게 한다. Flow·검증 규칙·Apex·App Builder에 흩어 쓰면 상태 하나를 추가할 때 빠뜨리는 곳이 생긴다.

**범위**
- In:
  - 규칙 메타데이터 `CMN_UiRule__mdt`·`CMN_UiSection__mdt`, 규칙 정의 파일 형식
  - FlexiPage 가시성 동기화 스크립트(생성·검사·문서 출력)
  - 서버 검증 `CMN_UiRuleService`(버튼 허용 `canExecute`·`assertCanExecute`, 필드 잠금 `lockedFieldViolations`, 서비스 우회)
  - Custom Permission 명명 규칙, 거부 메시지 라벨
- Out:
  - 각 객체의 규칙 행과 Custom Permission: 각 업무 WI
  - 상태 전이 자체: 업무 서비스
  - 결재 중 레코드 잠금: APV-001

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| CMN_UiRule__mdt | Custom Metadata | — | 규칙 1행 = 객체·대상 1개의 허용 조건 묶음 1개. 같은 대상의 행이 여러 개면 하나라도 맞으면 허용 |
| CMN_UiRule__mdt.ObjectApiName__c | Text(80) | Y | |
| CMN_UiRule__mdt.TargetType__c | Picklist (SECTION, ACTION, COMPONENT) | Y | SECTION = Dynamic Forms 필드 섹션, ACTION = Dynamic Actions 버튼(빠른 작업·LWC 액션), COMPONENT = 페이지 LWC(그리드·입력 셸 편집 가능 여부) |
| CMN_UiRule__mdt.TargetKey__c | Text(80) | Y | 섹션 키 / 액션 API명 / 컴포넌트 키 |
| CMN_UiRule__mdt.Mode__c | Picklist (EDIT, SHOW) | Y | SECTION은 EDIT(편집 허용), ACTION·COMPONENT는 SHOW(노출·실행 허용) |
| CMN_UiRule__mdt.StatusField__c | Text(80) | Y | 기본 `Status__c` |
| CMN_UiRule__mdt.StatusValues__c | Text(255) | Y | 쉼표 구분 API값. `*` = 모든 상태 |
| CMN_UiRule__mdt.CustomPermission__c | Text(80) | N | 필요한 Custom Permission. 비우면 객체 편집 권한만 본다 |
| CMN_UiRule__mdt.RecordTypes__c | Text(255) | N | 쉼표 구분 RecordType DeveloperName. 비우면 전체 |
| CMN_UiRule__mdt.FormFactor__c | Picklist (ALL, LARGE, SMALL) | Y | 기본 ALL. 서버 검증에는 쓰지 않는다 |
| CMN_UiRule__mdt.ExtraCondition__c | Text(255) | N | 추가 필드 조건 하나(`Field__c=VALUE` 또는 `Field__c!=VALUE`) |
| CMN_UiRule__mdt.IsActive__c | Checkbox | — | |
| CMN_UiSection__mdt | Custom Metadata | — | 섹션 키 → 필드 목록(서버 필드 잠금용) |
| CMN_UiSection__mdt.ObjectApiName__c / SectionKey__c | Text(80) / Text(80) | Y | |
| CMN_UiSection__mdt.Fields__c | Long Text(4000) | Y | 쉼표 구분 필드 API명 |
| CMN_UiSection__mdt.LabelKey__c | Text(80) | Y | 섹션 제목 Custom Label |

**비즈니스 규칙**

- BR-1: 해석. 대상(객체, TargetKey)의 활성 규칙 행 중 하나라도 아래 조건을 모두 만족하면 허용한다.
  - 상태가 StatusValues에 있다.
  - CustomPermission이 비었거나 사용자가 보유했다.
  - 레코드 타입이 일치한다.
  - ExtraCondition이 일치한다.
  - 규칙 행이 없으면 SECTION은 읽기 전용, ACTION·COMPONENT는 숨김·거부다(기본 거부).
- BR-2: 화면 생성. Dynamic Forms에는 조건부 읽기 전용이 없다. 그래서 SECTION 하나를 FlexiPage에서 섹션 쌍으로 만든다.
  - 편집 섹션: BR-1 허용 조건일 때 보인다.
  - 읽기 섹션: 같은 필드를 UI 동작 "읽기 전용"으로 두고, 편집 섹션이 안 보일 때 보인다.
  - ACTION은 Dynamic Actions 가시성 필터, COMPONENT는 컴포넌트 가시성 필터로 넣는다.
  - 필터에는 레코드 필드(상태·레코드 타입·ExtraCondition), 사용자 권한(Custom Permission), 폼 팩터만 쓴다.
- BR-3: 동기화 스크립트 `scripts/dev/ui-rule-sync.py`. 원천은 `meta-src/ui-rules/{객체}.json`(섹션 정의 + 규칙 표)이다. 모드는 셋이다.
  - (a) 생성: `CMN_UiRule__mdt`·`CMN_UiSection__mdt` 레코드를 metagen 원천에 쓰고, 해당 FlexiPage의 섹션 쌍과 가시성 필터를 갱신한다.
  - (b) `--check`(CI): FlexiPage와 규칙의 불일치, 규칙 없는 액션, 상태 Picklist에 없는 상태값, 존재하지 않는 Custom Permission을 오류로 낸다.
  - (c) `--doc`: 상태 × 섹션·버튼 × 권한 매트릭스를 md로 출력한다. 출력은 WI 완료 보고서에 붙인다.
  - 가시성 필터 수가 플랫폼 한도를 넘으면 생성을 멈추고 규칙 단순화를 요구한다.
- BR-4: 서버 버튼 검증.
  - `CMN_UiRuleService.canExecute(Id recordId, String actionKey)`는 Boolean을 반환한다. 레코드는 USER_MODE로 조회하고 권한은 `FeatureManagement.checkPermission`으로 확인한다. 레코드 접근 권한이 없으면 false다.
  - 업무 액션 Apex(상신, 판정, 재시험 생성 등)는 첫 줄에서 `CMN_UiRuleService.assertCanExecute(recordId, actionKey)`를 호출한다. 실패하면 `CMN_ValidationException`(라벨 `CMN_UiRule_ActionNotAllowed`)을 던진다.
  - 버튼을 숨기는 것만으로 권한 통제로 보지 않는다.
- BR-5: 서버 필드 잠금.
  - `CMN_UiRuleService.lockedFieldViolations(List<SObject> newRecords, Map<Id, SObject> oldMap)`는 레코드별 바뀐 잠긴 필드 목록을 반환한다. 잠긴 필드 = 이전 상태 기준으로 EDIT가 허용되지 않은 섹션의 필드다.
  - 업무 객체 트리거 핸들러는 before update에서 이 결과에 행 오류(`addError`, 라벨 `CMN_UiRule_FieldLocked`)를 붙인다.
  - 상태 전이처럼 서비스가 잠긴 필드를 바꿔야 할 때는 `CMN_UiRuleService.runAsService(Callable)` 안에서 바꾼다. 우회는 그 트랜잭션의 해당 호출 안에서만 유효하다. 직접 플래그를 켜고 끄는 공개 메서드는 두지 않는다.
- BR-6: 성능. 규칙은 객체별로 한 번 읽어 정적 캐시에 둔다(트랜잭션당 메타데이터 조회 객체별 1회). 200건 일괄 수정에서 `lockedFieldViolations`의 추가 SOQL은 0회다.
- BR-7: Custom Permission 이름은 `{접두어}_{객체약어}_{동작}`이다(예: `QMS_NCR_Disposition`). 각 기능 WI가 만들고 자기 Permission Set에 넣는다.

**화면/UX**: 화면 유형 T1(규칙 엔진, 사용자 화면 없음).
- 거부 메시지 라벨 2개: `CMN_UiRule_ActionNotAllowed`, `CMN_UiRule_FieldLocked`.
- 3개 언어로 번역한다.

**권한**
- 규칙은 배포로만 바꾼다. 운영 중 편집 화면은 없다.
- `CMN_UiRuleService`는 다른 Apex가 호출하므로 PS에 클래스 접근을 넣지 않는다.

**수용 기준**

- AC-1: Given 테스트 객체 규칙(DRAFT: 기본정보 섹션 EDIT, 상신 버튼 SHOW / SUBMITTED: 둘 다 없음), When 동기화 후 DRAFT 레코드 열기, Then 기본정보 섹션 편집 가능·상신 버튼 보임. SUBMITTED 레코드는 읽기 섹션만 보이고 상신 버튼이 없다.
- AC-2: Given SUBMITTED 레코드, When 상신 Apex를 직접 호출, Then `CMN_ValidationException`.
- AC-3: Given SUBMITTED 레코드, When API로 기본정보 섹션 필드 수정, Then 행 오류. `runAsService` 안에서 같은 수정은 성공한다.
- AC-4: Given 규칙이 없는 버튼이 FlexiPage에 있다, When `ui-rule-sync.py --check`, Then 오류 1건, 종료 코드 1.
- AC-5: Given CustomPermission 필요 규칙, When 권한 없는 사용자, Then 화면에서 버튼이 숨겨지고 `canExecute`가 false다.
- AC-6: Given 레코드 200건 일괄 수정, When 트리거 실행, Then `lockedFieldViolations`가 추가 SOQL 0회로 끝난다.
- AC-7: Given 규칙 정의, When `--doc`, Then 상태별 섹션·버튼·권한 표 md가 나온다.

**에이전트 주의**
- 같은 상태 규칙을 Validation Rule·Flow로 다시 만들지 않는다.
- 레코드 타입별 페이지 레이아웃으로 상태를 제어하지 않는다.
- 서비스 우회는 `runAsService`로만 한다. 정적 Boolean을 공개하지 않는다.
- FlexiPage를 App Builder에서 고쳐 규칙과 어긋나게 만들지 않는다(CI가 잡는다).

**오픈 이슈**
- 결재 진행 중 잠금을 표준 레코드 잠금(APV-001 구현)과 이 규칙 중 어느 쪽으로 일원화할지 정해야 한다. APV-001 구현을 확인한 뒤 정리한다.

### CMN-00-UX-006 공통 편집 그리드

추적 Q-4, Q-5, Q-24, Q-25, Q-30 · 필수 · W1 · SF · DM, LWC, APEX · Customization · 선행 UX-004, UX-005, I18N-001, MDM-007 · 7 M/D

**목적**: DVP&R 라인, 연간 심사 계획, 교육 계획, 교정 계획, 수평전개 대상, 8D 팀·조치처럼 "행이 많고 셀 단위로 입력하는" 화면(T2)을 메뉴마다 따로 만들지 않고 설정 하나로 만든다. 품질 엔지니어가 엑셀로 하던 일을 옮겨 오는 화면이라 붙여넣기, 일괄 저장, 행 단위 오류 표시가 핵심이다.

**범위**
- In:
  - `cmnEditableGrid` LWC, 그리드 정의 메타데이터 2종, 메시지 채널 `CMN_GridRefresh__c`
  - 컨트롤러 `CMN_GridController`, 업무 확장 인터페이스 `CMN_GridProvider`와 기본 구현 `CMN_GridProviderBase`
  - 붙여넣기 대화상자, 일정 막대 보기, 휴대폰 카드 보기
  - 브라우저 임시 저장 모듈 `cmnDraftStore`(UX-008·009도 쓴다)
- Out:
  - 각 그리드의 열 정의와 업무 검증: 각 업무 WI
  - 엑셀 파일 내려받기: SheetJS, QMS-02-DVQ-009
  - 수천 행 가져오기: 데이터 로더 영역
  - 행 500개 넘는 화면

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| CMN_GridDefinition__mdt | Custom Metadata | — | 그리드 1개. DeveloperName = GridKey |
| CMN_GridDefinition__mdt.ObjectApiName__c | Text(80) | Y | 행 객체 |
| CMN_GridDefinition__mdt.ParentField__c | Text(80) | Y | 부모 레코드 필드(Master-Detail 또는 Lookup) |
| CMN_GridDefinition__mdt.OrderField__c | Text(80) | N | 정렬·행 순서 저장 필드 |
| CMN_GridDefinition__mdt.Filter__c | Text(255) | N | 고정 필터(`Field__c=VALUE`, 쉼표로 AND) |
| CMN_GridDefinition__mdt.MaxRows__c | Number(4,0) | Y | 기본 200, 상한 500 |
| CMN_GridDefinition__mdt.AllowAdd__c / AllowDelete__c / AllowPaste__c | Checkbox | — | |
| CMN_GridDefinition__mdt.ScheduleStartField__c / ScheduleEndField__c | Text(80) | N | 둘 다 있으면 일정 막대 보기 활성 |
| CMN_GridDefinition__mdt.ProviderClass__c | Text(80) | N | `CMN_GridProvider` 구현 클래스 |
| CMN_GridDefinition__mdt.EditRuleKey__c | Text(80) | N | UX-005 COMPONENT 대상 키. 편집 가능 여부 판정 |
| CMN_GridColumn__mdt | Custom Metadata | — | 열 1개 |
| CMN_GridColumn__mdt.Grid__c | Metadata Relationship(CMN_GridDefinition__mdt) | Y | |
| CMN_GridColumn__mdt.FieldApiName__c | Text(80) | Y | |
| CMN_GridColumn__mdt.LabelKey__c | Text(80) | N | 비우면 필드 라벨(번역 포함) |
| CMN_GridColumn__mdt.Order__c | Number(3,0) | Y | |
| CMN_GridColumn__mdt.Editable__c / Required__c / Frozen__c | Checkbox | — | Required는 화면 검증(서버는 Provider·필드 필수로 다시 검증). Frozen = 가로 스크롤 시 고정 |
| CMN_GridColumn__mdt.WidthWeight__c | Number(2,0) | N | 상대 폭 1~10(px 금지) |
| CMN_GridColumn__mdt.InputType__c | Picklist (AUTO, TEXT, NUMBER, DATE, PICKLIST, LOOKUP, CHECKBOX, CODE) | Y | AUTO = 필드 타입. CODE = `cmnCodePicker`(MDM-007) |
| CMN_GridColumn__mdt.CodeGroup__c | Text(40) | CODE면 Y | |
| CMN_GridColumn__mdt.LookupFilter__c | Text(255) | N | Lookup 후보 고정 필터(`Field__c=VALUE`) |
| CMN_GridColumn__mdt.ShowOnPhone__c | Checkbox | — | 휴대폰 카드 표시 필드(최대 4개) |

**서비스 API**

    public interface CMN_GridProvider {
        Map<String, Object> defaults(Id parentId);                                   // 새 행 기본값
        Map<Id, CMN_GridRowMeta> rowMeta(Id parentId, List<SObject> rows);           // 행별 삭제 가능·잠긴 열·경고
        CMN_GridValidation validate(Id parentId, List<SObject> rows, List<Id> deletedIds); // 행·그리드 오류
        void afterSave(Id parentId, List<SObject> savedRows, List<Id> deletedIds);   // 후처리(재계산 등)
    }
    // CMN_GridRowMeta: deletable(Boolean), deleteBlockedLabel(String), lockedFields(Set<String>), warningLabel(String)
    // 추상 클래스 CMN_GridProviderBase가 4개 메서드의 기본 구현(제약 없음)을 준다. 업무 Provider는 필요한 것만 재정의한다.
    CMN_GridController.load(String gridKey, Id parentId)                 // cacheable 아님(편집 화면)
    CMN_GridController.save(String gridKey, Id parentId, String rowsJson, List<Id> deletedIds, String clientVersion)

**비즈니스 규칙**

- BR-1: 로드. `load`는 USER_MODE SOQL로 행을 읽는다.
  - 읽기 권한이 없는 필드의 열은 응답에서 뺀다. 편집 권한이 없는 필드는 읽기 전용으로 내린다.
  - 응답: 열 정의, 행, 편집 가능 여부, `clientVersion`(행들의 최대 LastModifiedDate와 행 수).
  - 편집 가능 = 부모 레코드 편집 권한 AND (EditRuleKey가 없거나 UX-005 `canExecute(parentId, EditRuleKey)`).
  - MaxRows를 넘으면 앞 MaxRows 행만 주고 잘림 표시를 한다.
- BR-2: 편집.
  - 셀 편집은 브라우저 초안으로만 쌓는다. 바뀐 셀을 표시한다.
  - 행 추가: Provider `defaults` 값을 넣는다.
  - 행 삭제: 표시만 하고 저장할 때 반영한다.
  - "변경 취소"는 초안 전체를 되돌린다.
  - 초안은 `cmnDraftStore`에 자동 저장한다(키 = 사용자 Id + GridKey + 부모 Id). 다시 열 때 초안이 있으면 복원 여부를 묻는다.
- BR-3: 붙여넣기. "붙여넣기" 버튼을 누르면 대화상자가 열린다. 순서는 다음과 같다.
  1. 텍스트 영역에 엑셀 범위(탭 구분)를 붙여넣는다.
  2. 첫 행을 머리글로 쓸지와 시작 열을 고른다.
  3. 미리보기에서 열 매핑과 형식 변환 오류 셀을 확인한다.
  4. 적용 방식을 고른다: 기존 행 아래에 추가하거나, 선택한 행부터 덮어쓴다.

  변환 규칙:
  - 날짜: yyyy-mm-dd, yyyy.mm.dd, 사용자 로캘 형식.
  - 숫자: 천 단위 구분 기호를 뺀다.
  - Picklist: API값이나 사용자 언어 라벨과 일치해야 한다.
  - Lookup·CODE: Name이나 외부 키(`ExternalKey__c`)와 일치해야 한다. 서버 조회는 1회, 서로 다른 값 최대 200개다.
  - 변환 실패 셀은 빈 값으로 두고 오류를 표시한다.
- BR-4: 검증. 순서는 클라이언트 검증(필수·형식·범위) → 서버 `save`의 Provider `validate`다.
  - 결과는 행 단위 오류(`행 키 → 메시지 목록`)와 그리드 전체 오류다.
  - 오류가 하나라도 있으면 아무 행도 저장하지 않는다(Savepoint 롤백).
  - 오류 행은 강조하고, 오류 개수 요약과 "다음 오류로 이동"을 제공한다.
- BR-5: 저장.
  - 삽입·수정은 `Database.upsert` 1회(AccessLevel.USER_MODE), 삭제는 1회다. 이어서 Provider `afterSave`를 호출한다.
  - 저장 전에 `clientVersion`을 다시 계산한다. 다르면(다른 사용자가 저장) 저장을 막고 새로 고침을 안내한다. 덮어쓰지 않는다.
  - 성공하면 초안을 지운다.
- BR-6: 일정 막대 보기.
  - ScheduleStart·End가 있으면 "일정 보기"로 바꿀 수 있다. 주 단위 눈금과 오늘 선을 그린다.
  - 종료일이 지났는데 열린 행(Provider가 행 상태로 판단해 경고 플래그를 준다)은 경고 아이콘과 텍스트로 표시한다.
  - 막대는 CSS로 그린다(외부 라이브러리 없음). 막대를 끌어 날짜를 바꾸지 않고 날짜 셀로 편집한다.
- BR-7: 휴대폰. 읽기 전용 카드 목록(ShowOnPhone 필드 최대 4개)으로 표시한다. 카드를 누르면 그 행의 레코드 페이지로 간다.
- BR-8: 구현과 키보드.
  - `lightning-datatable`(인라인 편집, draft-values, errors)을 기반으로 한다. Picklist·Lookup·CODE 셀은 커스텀 데이터 타입(편집 템플릿)으로 만든다.
  - Tab·화살표·Enter로 셀을 이동하고 편집할 수 있어야 한다. 오류는 텍스트로 알린다(색만으로 구분 금지).
- BR-9: 성능.
  - 60행 × 12열 로드는 2초 이내다.
  - 저장 DML은 2회 이하(upsert 1 + delete 1, Provider 후처리 제외)다.
  - 붙여넣기 미리보기 200행은 1초 이내다.
- BR-10: 외부 새로 고침.
  - 같은 페이지의 다른 컴포넌트가 행을 만들거나 바꾸면(예: 라이브러리에서 라인 추가) Lightning Message Service 채널 `CMN_GridRefresh__c`(gridKey, parentId)를 발행한다. 그리드는 일치하면 다시 읽는다.
  - 저장하지 않은 초안이 있으면 새로 고치기 전에 사용자에게 묻는다.
  - 공개 메서드 `@api refresh()`도 둔다.
- BR-11: 행 메타.
  - 로드와 저장 뒤 Provider `rowMeta`로 행별 정보를 받는다.
    - `deletable=false`: 삭제 버튼을 막고 `deleteBlockedLabel` 안내를 보인다.
    - `lockedFields`: 그 행의 해당 셀을 읽기 전용으로 둔다.
    - `warningLabel`: 경고 아이콘과 텍스트를 보인다.
  - 서버 `save`는 같은 rowMeta로 삭제 불가 행 삭제와 잠긴 셀 변경을 다시 거부한다.

**화면/UX**: 화면 유형 T2.
- T1 레코드 페이지의 "현재 단계" 탭이나 관련 영역에 둔다. 속성은 `gridKey`이고 `recordId`는 부모로 자동 주입된다.
- 툴바: 행 추가, 삭제, 붙여넣기, 일정 보기, 변경 취소, 저장, 오류 개수.

**권한**
- `CMN_PS_UiFramework_User`에 `CMN_GridController`를 더한다.
- 행 데이터 권한은 행 객체의 PS(각 업무 WI)를 따른다.

**수용 기준**

- AC-1: Given 60행 × 12열 그리드, When 로드, Then 2초 이내 표시(UAT 측정, Apex 테스트는 쿼리 1회 확인).
- AC-2: Given 엑셀 5행 × 4열 붙여넣기(날짜 1칸 형식 오류), When 미리보기, Then 오류 셀 1개 표시. 적용 후 그 셀은 빈 값에 오류 표시.
- AC-3: Given 3행 수정·1행 추가·1행 삭제, Provider 검증 통과, When 저장, Then DML 2회, 결과 반영, 초안 삭제.
- AC-4: Given Provider가 2행에 오류, When 저장, Then 아무 행도 저장되지 않고 2행이 강조된다.
- AC-5: Given 다른 사용자가 같은 부모의 행을 먼저 저장, When 저장, Then 차단과 새로 고침 안내.
- AC-6: Given 사용자에게 FLS가 없는 필드의 열, When 로드, Then 그 열이 응답과 화면에 없다.
- AC-7: Given 휴대폰, When 그리드 표시, Then 카드 목록, 편집 버튼 없음.
- AC-8: Given 저장하지 않은 초안이 브라우저에 있다, When 다시 열기, Then 복원 여부를 묻는다.
- AC-9: Given EditRuleKey 규칙상 편집 불가 상태, When 로드, Then 읽기 전용, 저장 API 호출도 거부.

**에이전트 주의**
- 그리드마다 새 LWC를 만들지 않는다. 차이는 열 정의와 Provider로 낸다.
- 셀 하나씩 서버에 저장하지 않는다.
- Provider 없이 업무 검증을 LWC에 넣지 않는다.
- 붙여넣기에서 보이지 않는 열(FLS 없음)에 값을 넣지 않는다.

**오픈 이슈**
- 행 500개를 넘는 화면이 필요한지 확인해야 한다.
- 엑셀 파일(.xlsx)을 직접 올려 행을 만드는 기능이 필요한지 확인해야 한다(필요하면 SheetJS 승인 목록 사용).

### CMN-00-UX-007 앱 구성·메뉴 허브

추적 Q-41, P-63, Q-2, NFR-4.2(RBAC) · 필수 · W1 · SF · CFG, LWC, APEX · Tailoring · 선행 SEC-001, TDO-001, TDO-004, ARC-003 · 4 M/D

**목적**: 품질 전문가·참여자·현장·관리자가 각자 맞는 앱으로 들어오게 한다. 국내 제조사 사용자에게 익숙한 트리 메뉴 대신 "앱당 자주 쓰는 8개 탭 + 메뉴 허브"로 전체 기능을 찾게 한다. 메뉴 허브 골격은 화면 우선 개발 A0에서 이미 만들었다(메뉴별 허브 10개, `docs/wi/A0-prototype-kit.md`). 이 WI는 그것을 표준으로 확정하고 확장한다.

**범위**
- In:
  - Lightning 앱 5개 구성: 새 앱 `SL_QMS_Quality`·`SL_QMS_Field`, 배포된 `SL_QMS`·`SL_Admin`·`SL_PMS` 조정
  - 앱별 내비게이션·유틸리티 바·PSG 할당
  - 메뉴 허브 확장: `cmnAppMenuHub`의 전체 메뉴 모드, 권한 필터, 미결 건수 배지, 화면 검색, 업무 번호 바로가기
  - 메뉴 설정 메타데이터 필드 추가
- Out:
  - 협력사 포털 내비게이션: QMS-03-SPP
  - PMS 메뉴 내용: PMS Vol.
  - 각 기능 타일의 대상 화면: 각 화면 묶음과 메뉴 WI

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| CMN_AppMenu__mdt (배포됨) | Custom Metadata | — | 메뉴 그룹. 기존 필드: TitleLabel, DescLabel, IconName, Order, System, IsActive |
| CMN_AppMenu__mdt.Apps__c | Text(255) | Y | 이 그룹을 보여줄 앱 API명(쉼표). 예: `SL_QMS_Quality,SL_QMS` |
| CMN_AppMenu__mdt.PageTab__c | Text(80) | N | 그룹 전용 허브 탭(배포된 메뉴별 허브 페이지). 그룹 머리글 "메뉴 열기" 대상 |
| CMN_AppMenuItem__mdt (배포됨) | Custom Metadata | — | 기능 타일. 기존 필드: Menu, FeatureCode, TitleLabel, DescLabel, IconName, TargetType(OBJECT, PAGE, NONE), Target, Bundle, Order, IsActive |
| CMN_AppMenuItem__mdt.RequiredPermission__c | Text(80) | N | PAGE·NONE 타일 표시에 필요한 Custom Permission |
| CMN_AppMenuItem__mdt.TodoSourceTypes__c | Text(255) | N | 미결 배지에 셀 To-Do SourceType(쉼표) |
| CMN_AppMenuItem__mdt.KeywordsLabel__c | Text(80) | N | 검색 동의어 Custom Label(쉼표 구분 단어, 3개 언어 번역) |
| CMN_AppMenuItem__mdt.ShowOnPhone__c | Checkbox | — | 휴대폰 허브에 표시 |
| Custom Application `SL_QMS_Quality`, `SL_QMS_Field` | CustomApplication | — | 새 앱 2개 |
| Permission Set `CMN_PS_AppQmsQuality_Read`, `CMN_PS_AppQmsField_Read` | PermissionSet | — | 앱 표시 권한(배포된 `CMN_PS_AppQms_Read`·`CMN_PS_AppAdmin_Read`와 같은 방식) |

**비즈니스 규칙**

- BR-1: 앱-PSG 할당.

  | PSG | 기본 앱 | 함께 할당 |
  | --- | --- | --- |
  | QualityEngineer, QualityManager, ProcessEngineer, TrainingCoordinator | SL QMS 품질 업무 | SL QMS |
  | SupplierQuality, LabTester, Metrology, Auditor | SL QMS 품질 업무 | SL QMS, SL QMS 현장 |
  | Inspector | SL QMS 현장 | — |
  | DevEngineer, Viewer | SL QMS | — |
  | CMN_PSG_Executive | SL QMS | SL PMS |
  | QualityAdmin | SL Admin | SL QMS 품질 업무, SL QMS |
  | CMN_PSG_SystemAdmin | SL Admin | 전체 |
  | SupplierPortal | 협력사 포털 | — |

  - QMS PSG 이름 접두어 `QMS_PSG_`는 표에서 생략했다.
  - 기본 앱은 PSG에 넣는 앱 권한 세트 순서와 사용자 기본 앱 설정으로 정한다.
- BR-2: 내비게이션 항목. 앱당 8개 이내다.
  - SL QMS 품질 업무: 홈, 메뉴 허브, NCR, 클레임·8D, 4M 변경, 검사, 인정시험, 개선과제.
  - SL QMS: 홈, 결재 현황, 내 대시보드, 메뉴 허브.
  - SL QMS 현장: 홈(To-Do), 검사 입력, NCR 등록, 한도견본.
  - SL Admin: 메뉴 허브(기준정보·설정 그룹), 공통 코드, 심사 질문지, 결재 템플릿, 연계 모니터, 로그.
  - 아직 화면이 없는 항목은 해당 화면 묶음이 화면을 만들 때 넣는다. 사용자는 순서·항목을 개인화할 수 있다.
  - 메뉴별 허브 탭(QMS_Menu02~09, CMN_MenuWork, CMN_MenuMaster)은 내비게이션에서 빼고, 탭 자체는 남긴다(BR-3의 "메뉴 열기" 대상).
- BR-3: 전체 메뉴 모드. `cmnAppMenuHub`의 `menuKey`가 비어 있으면 현재 앱이 `Apps__c`에 들어 있는 메뉴 그룹을 모두 Order 순 섹션으로 보여준다.
  - 현재 앱은 서버가 `UserAppInfo`로 판단한다. 실패하면 `SL_QMS`로 간주한다.
  - 상단에 그룹 바로가기를 두고, 그룹 머리글에 "메뉴 열기"(PageTab__c)를 둔다.
  - `menuKey`를 지정한 메뉴별 모드는 지금처럼 유지한다.
- BR-4: 권한 필터.
  - OBJECT 타일: 객체 읽기 권한(배포된 규칙 유지).
  - PAGE·NONE 타일: RequiredPermission이 비었거나 사용자가 보유.
  - 보이는 타일이 없는 그룹은 숨긴다.
- BR-5: 미결 배지.
  - 서버가 현재 사용자의 열린 To-Do를 SourceType별로 센다: `CMN_Todo__c` GROUP BY SourceType__c, USER_MODE, 전체 1회 + 기한 경과 1회.
  - 타일의 `TodoSourceTypes__c` 합계를 배지로 붙인다. 0이면 배지가 없고, 99를 넘으면 "99+"다.
  - 기한 경과가 있으면 경고 아이콘과 "기한 경과 n" 텍스트를 함께 단다.
  - 배지는 허브를 열 때 한 번 계산한다(실시간 갱신 없음, 새로 고침 버튼).
- BR-6: 검색과 번호 바로가기. 상단 검색창 하나로 한다.
  - (a) 화면 검색: 타일 제목·설명·검색 동의어 라벨에서 부분 일치(클라이언트)를 찾는다.
  - (b) 업무 번호: 입력이 `CMN_NumberingRule__mdt` Pattern의 고정 접두어(첫 `{` 앞 문자열)로 시작하면, 그 규칙의 ObjectApiName·NumberField(기본 RecordNo__c)로 USER_MODE 조회를 1회 한다.
  - 1건이면 레코드 페이지로 이동한다. 없거나 권한이 없으면 같은 "찾을 수 없음" 메시지를 보인다(존재 여부를 구분해 알려주지 않는다).
  - 접두어가 여러 규칙과 맞으면 가장 긴 접두어를 쓴다.
- BR-7: 유틸리티 바(영역 E). 세 사내 QMS 앱 공통이다.
  - 언어 전환 `cmnLanguageSwitcher`(I18N-001)
  - 화면 가이드 `cmnScreenGuide`(UX-002, 배포 후)
  - 빠른 NCR 등록(QMS-06-NCR-002 배포 후)
  - Agentforce는 표준 헤더 진입(AI-001)이라 유틸리티 바에 넣지 않는다.
- BR-8: 휴대폰. SL QMS 현장과 SL QMS의 모바일 내비게이션은 BR-2와 같다(UX-001 BR-3). 휴대폰 허브는 `ShowOnPhone__c` 타일만 보인다.
- BR-9: 콘솔 미사용(DS-7 결정, 2026-11-05). 모든 앱의 내비게이션 유형은 표준이다.
  - 여러 건을 오가는 작업은 분할 보기 리스트뷰와 브라우저 새 탭으로 한다.
  - 하위 레코드는 레코드 페이지 안(관련 탭, 모달, 결정 지원 레일)에서 처리한다.
  - Lightning Console 권한 집합 라이선스가 필요한 기능을 쓰지 않는다.

**화면/UX**: 화면 유형 T8.
- 메뉴 허브 화면 순서: 검색창 → 그룹 바로가기 → 그룹 섹션(머리글 = 그룹 이름 + 설명 + "메뉴 열기") → 타일(아이콘, 제목, 설명, 배지, 상태 "사용 가능"/"준비 중", 열기).
- 휴대폰: 검색창 + 타일 목록.

**권한**
- 새 앱 권한 세트 2개를 BR-1에 따라 PSG에 넣는다.
- `CMN_AppMenuController`(배포됨)는 `CMN_PS_AppQms_Read`에 있다. 새 앱 권한 세트에도 넣는다.

**수용 기준**

- AC-1: Given QMS_PSG_Inspector만 가진 사용자, When 앱 런처, Then `SL QMS 현장`만 보인다(SEC-001 AC-1).
- AC-2: Given QualityEngineer가 SL QMS 품질 업무에서 메뉴 허브(전체 모드) 열기, Then Apps__c에 SL_QMS_Quality이 있는 그룹만 보이고, 권한 없는 타일은 없다.
- AC-3: Given 열린 NCR To-Do 3건(1건 기한 경과), When 허브 표시, Then NCR 타일에 배지 3과 "기한 경과 1"이 표시된다.
- AC-4: Given 접근 가능한 레코드 번호 `NCR-KR01-2027-000123`, When 검색창에 입력 후 Enter, Then 그 레코드 페이지로 이동한다. 접근 불가 번호와 없는 번호는 같은 "찾을 수 없음"이다.
- AC-5: Given 그룹의 모든 타일에 권한이 없다, When 허브 표시, Then 그룹이 보이지 않는다.
- AC-6: Given 허브 표시, When 서버 호출, Then 배지 집계 SOQL이 2회 이하다.
- AC-7: Given 배포된 메뉴별 허브(QMS_02 등), When menuKey 지정 모드, Then 기존 동작과 같다(회귀).

**에이전트 주의**
- 배포된 이름(`cmnAppMenuHub`, `CMN_AppMenu__mdt`, `CMN_AppMenuItem__mdt`, `CMN_AppMenuController`)을 바꾸지 않는다. 화면 전략 원안의 `cmnMenuHub`·`CMN_MenuItem__mdt`·`QMS_MenuItem__mdt`는 이 이름으로 대체됐다.
- 트리 메뉴를 커스텀 사이드바로 만들지 않는다.
- 배지를 타일마다 따로 조회하지 않는다.

**오픈 이슈**
- 역할별로 홈 페이지를 따로 둘지, 위젯 템플릿만 달리할지 정해야 한다(TDO-004·DSH-001).

### CMN-00-UX-008 현장 입력 셸

추적 Q-2, Q-6, Q-12, NFR-4.4(모바일) · 필수 · W1 · SF · LWC, APEX · Customization · 선행 UX-001, UX-006, I18N-001 · 7 M/D

**목적**: 수입·출하 검사, 시험 결과, 교정, 초기유동 점검처럼 태블릿으로 시료 값을 넣는 화면(T3)을 셸 하나로 통일한다. 검사원이 화면마다 다른 조작을 배우지 않게 하고, 즉시 합불 표시·바코드·사진·임시 저장을 한 번만 잘 만든다.

**범위**
- In:
  - `cmnFieldEntryShell` LWC(전체 화면, 순차·표 모드)
  - 입력 시트 계약 `CMN_FieldEntryProvider`와 DTO, Provider 등록 메타데이터, 컨트롤러 `CMN_FieldEntryController`
  - 즉시 합불 미리보기(서버 확정)
  - 바코드·사진: UX-001 `cmnBarcodeScanner`·`cmnPhotoCapture` 재사용
  - 브라우저 임시 저장: UX-006 `cmnDraftStore`
  - 진행률·미입력 목록
- Out:
  - 판정 규칙과 값 저장: 각 업무 WI의 Provider
  - 측정기 유효성 검사: QMS-03-IQC-003 `QMS_InspectionHook`
  - 측정기 직접 연결(블루투스): UX-001 오픈 이슈
  - 완전 오프라인: DS-5

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| CMN_FieldEntryProvider__mdt | Custom Metadata | — | 객체 → Provider 등록 |
| CMN_FieldEntryProvider__mdt.ObjectApiName__c / ProviderClass__c / IsActive__c | Text(80) / Text(80) / Checkbox | Y | |
| CMN_FieldEntry.Sheet | Apex DTO | — | header(제목, 번호, 품번, 로트, 공장, 보조 정보 라벨 키·값), items, values, editable, defaultMode(SEQUENTIAL, TABLE) |
| CMN_FieldEntry.Item | Apex DTO | — | key, label(사용자 언어), type(VARIABLE, ATTRIBUTE, VISUAL, REPORT, TEXT), sampleQty, lsl, usl, nominal, unit, decimals, specialClass(CC, SC 기호), method, gaugeRequired, photoRequiredOnNg, referenceDocId(한도견본·작업표준), sequence |
| CMN_FieldEntry.Value | Apex DTO | — | itemKey, sampleNo, numValue, okNg(OK, NG), text, photoIds, gaugeNo |
| CMN_FieldEntry.SaveResult | Apex DTO | — | itemResults(itemKey → PASS, FAIL, INCOMPLETE), overall, errors(itemKey·sampleNo별 메시지), nextActionLabel |

**서비스 API**

    public interface CMN_FieldEntryProvider {
        CMN_FieldEntry.Sheet load(Id recordId);
        CMN_FieldEntry.SaveResult save(Id recordId, List<CMN_FieldEntry.Value> values, Boolean isFinal);
        String validateScan(Id recordId, String scanType, String value);   // LOT, GAUGE. 오류 라벨 키 또는 null
    }

**비즈니스 규칙**

- BR-1: 진입. 셸은 화면 탭(앱 페이지, 상태 매개변수 `c__recordId`) 또는 레코드 페이지의 LWC 화면 액션으로 연다.
  - 컨트롤러는 레코드 객체의 Provider를 `CMN_FieldEntryProvider__mdt`에서 찾아 `Type.forName`으로 만든다. 등록이 없으면 오류 라벨을 보인다.
  - 레코드 접근은 Provider가 USER_MODE로 확인한다.
- BR-2: 순차 모드. 휴대폰·태블릿의 기본이다. 한 화면에 항목 1개 × 시료 1개를 보여준다.
  - 입력: 큰 숫자 입력(`inputmode="decimal"`), OK/NG 큰 버튼, 다음·이전.
  - 즉시 합불:
    - VARIABLE: 값을 `decimals` 자리로 반올림한 뒤 LSL ≤ 값 ≤ USL이면 합격(경계 포함, 한쪽 규격만 있으면 그쪽만 본다).
    - ATTRIBUTE·VISUAL: NG면 불합격.
    - 결과는 텍스트와 아이콘으로 보인다.
  - 다음 시료로 넘어가는 데 서버 호출이 없다(0.3초 이내).
- BR-3: 표 모드. 데스크톱의 기본이다. 행 = 항목, 열 = 시료다.
  - 세로 붙여넣기: 엑셀 값 목록을 선택한 항목의 시료 1~n에 넣는다.
  - 모드 전환은 입력값을 잃지 않는다.
- BR-4: 저장.
  - 입력할 때마다 브라우저에 임시 저장한다(`cmnDraftStore`, 키 = 사용자 + 레코드).
  - 항목 하나를 다 입력하면 서버 중간 저장(`isFinal=false`)을 한다.
  - "판정 확정"은 최종 저장(`isFinal=true`)이다. Provider가 판정과 후속 처리(NCR 게이트웨이 등)를 한다.
  - 서버 판정이 화면 미리보기와 다르면 서버 결과를 보이고 차이 항목을 강조한다.
- BR-5: 통신 끊김.
  - 저장이 실패해도 입력은 계속할 수 있다. 저장 버튼에 "전송 대기 n건"을 표시한다.
  - 연결이 돌아오면 사용자가 다시 저장한다. 자동 재전송은 하지 않는다(중복 판정 방지).
  - 임시 저장은 최종 저장에 성공하면 지우고, 7일이 지나면 지운다.
  - 다른 기기에서 이어서 입력하는 것은 서버 중간 저장분으로만 지원한다.
- BR-6: 바코드. 로트·측정기 번호 칸 옆에 스캔 버튼을 둔다.
  - 모바일 앱에서만 스캔하고, 웹에서는 수동 입력이다.
  - 값은 Provider `validateScan`으로 확인한다. 측정기는 IQC-003 훅이 교정 유효성을 본다.
- BR-7: 사진. VISUAL 항목이나 `photoRequiredOnNg` 항목에서 NG를 고르면 사진이 1장 이상 있어야 최종 저장이 된다.
  - 촬영·축소(장변 1920px)는 UX-001 컴포넌트를 쓴다.
  - 저장 위치(DocClass)는 Provider가 정한다.
- BR-8: 진행률과 미입력. 상단에 진행률(입력 시료/전체)을 보이고 "미입력만 보기"를 제공한다. 최종 저장 전에는 미입력 목록을 보여준다.
- BR-9: 화면.
  - 터치 영역은 SLDS 큰 버튼 변형을 쓴다.
  - 특별특성 기호(CC/SC)를 항목 이름 옆에 표시한다.
  - 기준 문서(한도견본) 열기 링크를 둔다.
  - 라이트·다크 테마 모두에서 대비를 확보한다.

**화면/UX**: 화면 유형 T3.
- 화면 순서: 상단(헤더 정보, 진행률, 모드 전환, 미입력만 보기) → 본문(순차 카드 또는 표) → 하단 고정(이전, 다음, 임시 저장 상태, 판정 확정).
- `formFactors` Small·Large를 모두 지원한다.

**권한**
- `CMN_PS_UiFramework_User`에 `CMN_FieldEntryController`를 더한다.
- 편집 가능 여부(`Sheet.editable`)는 Provider가 정한다(UX-005 COMPONENT 규칙 사용 권장).

**수용 기준**

- AC-1: Given VARIABLE 항목 LSL 1.0·USL 2.0·소수 2자리, When 2.05 입력, Then 즉시 불합격 텍스트와 아이콘. 2.004 입력은 합격(반올림 2.00).
- AC-2: Given 순차 모드, When 다음 시료, Then 서버 호출 없이 전환된다(Jest에서 Apex 호출 0회).
- AC-3: Given 입력 중 페이지 새로 고침, When 다시 열기, Then 입력값 복원 여부를 묻는다.
- AC-4: Given 세로 값 5개 붙여넣기, When 표 모드, Then 시료 1~5에 순서대로 들어간다.
- AC-5: Given NG + 사진 필수 항목에 사진 없음, When 판정 확정, Then 차단과 미충족 목록.
- AC-6: Given 서버 판정이 화면 미리보기와 다르다, When 판정 확정, Then 서버 결과를 보이고 차이 항목을 강조한다.
- AC-7: Given `Sheet.editable = false`, When 열기, Then 읽기 전용(입력·저장 버튼 없음).
- AC-8: Given 저장 실패(네트워크 오류 모의), When 계속 입력, Then 입력이 가능하고 "전송 대기" 표시, 자동 재전송 호출은 0회다.

**에이전트 주의**
- 측정값을 시료마다 레코드로 만들지 않는다. Provider가 항목별 JSON 묶음 등으로 저장한다(Vol.0 3절).
- 셸 안에 업무별 분기(if IQC …)를 넣지 않는다.
- 판정 규칙을 셸에 두지 않는다. 미리보기는 규격 비교만 한다.
- 표 모드를 별도 그리드(UX-006)로 만들지 않는다. 시료 열 구조라 셸 내부 표다.

**오픈 이슈**
- 현장 태블릿 기종·OS·화면 크기와 장갑 사용 여부(터치 영역 크기)를 SL에 확인해야 한다.
- 블루투스 측정기 연결 요구가 있는지 확인해야 한다(UX-001).

### CMN-00-UX-009 체크리스트 수행 화면

추적 Q-30, Q-31, Q-32, Q-2 · 필수 · W1 · SF · LWC, APEX · Customization · 선행 UX-001, UX-004, UX-006, MTG-001 · 6 M/D

**목적**: 내부·협력사·고객 심사, 고객 심사 준비 자체 평가, 레슨런 체크리스트, PMS Gate 점검처럼 "질문 목록에 점수·적합 여부·관찰·증빙을 남기고 결과를 계산하는" 화면(T4)을 공통 부품 하나로 만든다.
- 질문지·점수 규칙 데이터는 그 업무를 가진 메뉴가 갖는다. QMS 심사는 Vol.6c IAU-001(질문지·등급 규칙), IAU-003(점수 서비스), CAU-002(VDA 6.3 계산기)다.
- 이 WI는 수행 화면과 계약만 만든다. 화면 전략 원안의 "체크리스트 평가 엔진"에서 질문지 마스터와 점수 계산을 뺀 범위다(Vol.6c와 중복 방지).

**범위**
- In:
  - `cmnChecklistRunner` LWC, 계약 `CMN_ChecklistProvider`와 DTO, Provider 등록 메타데이터, 컨트롤러 `CMN_ChecklistController`
  - 요소 탐색·진행률·내 분담 필터
  - 답 유형별 입력, NA·사유, 관찰 메모, 사진·파일
  - 점수 미리보기 표시(계산은 Provider)
  - 후속 조치 생성: 기본 구현 = `CMN_ActionItem__c`
  - 태블릿 순차 모드, 브라우저 임시 저장
- Out:
  - 질문지 템플릿·판·버전·등급·강등 규칙: CMN-00-QNR-001. 심사 도메인 규칙·점수 계산: Vol.6c IAU-001, IAU-003, CAU-002. Gate 평가: PMS-09-GAT-002·003
  - 심사 지적 사항 객체: IAU-004
  - 증빙 패널: IAU-005
  - PMS Gate Provider: PMS Vol.

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| CMN_ChecklistProvider__mdt | Custom Metadata | — | 객체 → Provider 등록 |
| CMN_ChecklistProvider__mdt.ObjectApiName__c / ProviderClass__c / IsActive__c | Text(80) / Text(80) / Checkbox | Y | |
| CMN_Checklist.Sheet | Apex DTO | — | header, sections(key, label, 진행률), questions, answers, editable, scoreVisible |
| CMN_Checklist.Question | Apex DTO | — | key, sectionKey, no, text(사용자 언어), guidance, isStar, answerType(SCORE_STEPS, POINTS, COMPLIANCE, YES_NO, DEFECT_CLASS, TEXT), allowedScores, maxPoints, allowNa, noteRequiredAtOrBelow, assignedToId |
| CMN_Checklist.Answer | Apex DTO | — | questionKey, points, compliance, yesNo, sampleQty, defectA, defectB, defectC, text, isNa, naReason, notes, photoIds, followUpId |
| CMN_Checklist.ScorePreview | Apex DTO | — | percent, grade, gradeBeforeDowngrade, downgradeReasons, sectionPercents, unansweredCount |

**서비스 API**

    public interface CMN_ChecklistProvider {
        CMN_Checklist.Sheet load(Id recordId);
        CMN_Checklist.SaveResult saveAnswers(Id recordId, List<CMN_Checklist.Answer> answers, Boolean isFinal);
        CMN_Checklist.ScorePreview preview(Id recordId);
        Id raiseFollowUp(Id recordId, String questionKey, CMN_Checklist.FollowUpInput input);
    }

**비즈니스 규칙**

- BR-1: 화면.
  - 요소 목록과 진행률을 태블릿 가로에서는 왼쪽, 휴대폰에서는 상단 선택 목록으로 둔다.
  - 본문은 질문 카드다. 카드 구성: 번호, 별표 표시, 질문, 안내(접기), 답 입력, NA, 관찰 메모, 사진·파일, "후속 조치" 버튼.
  - 데스크톱에는 질문 행 표 보기를 더한다(같은 데이터).
- BR-2: 답 유형별 입력.
  - SCORE_STEPS: `allowedScores` 값만 버튼으로 둔다(점수 단계는 질문지 데이터가 정한다).
  - POINTS: 0~maxPoints 숫자.
  - COMPLIANCE: 적합/부적합.
  - YES_NO: 예/아니오.
  - DEFECT_CLASS: 시료 수와 결함 A·B·C 수.
  - TEXT: 서술.
- BR-3: 필수 입력 규칙. 판단은 Provider가 하고 셸은 표시만 한다.
  - 점수가 `noteRequiredAtOrBelow` 이하이거나 부적합이면 관찰 메모가 필수다.
  - 그때 후속 조치를 만들지 않으면 사유를 받는다(IAU-003 BR-2와 같은 규칙).
  - Provider가 `saveAnswers` 오류(질문 키별)로 돌려주면 셸이 해당 카드에 보인다.
- BR-4: 점수 미리보기. "점수 보기" 패널에 Provider `preview` 결과를 보인다: 전체·요소별 달성률, 강등 전·후 등급, 강등 사유, 미답 수.
  - 셸은 점수를 계산하지 않는다.
  - 저장하지 않은 답이 있으면 중간 저장을 먼저 한다.
  - `scoreVisible=false`(예: 피심사 측)면 패널을 숨긴다.
- BR-5: 후속 조치. "후속 조치"를 누르면 제목, 내용, 담당, 기한, 심각도를 입력받아 Provider `raiseFollowUp`을 호출한다.
  - 기본 구현 `CMN_ChecklistDefaultProvider.raiseFollowUp`은 MTG-001 조치 항목 서비스(`CMN_ActionItemService`)로 `CMN_ActionItem__c`를 만든다. 원천 레코드 Id와 질문 키를 남긴다.
  - QMS 심사 Provider는 IAU-004 지적 객체를 만든다.
- BR-6: 내 분담. "내 분담만"을 켜면 `assignedToId`가 현재 사용자인 질문만 보인다. 분담이 없는 질문은 모두에게 보인다.
- BR-7: 저장·임시 저장·통신 끊김은 UX-008 BR-4·BR-5와 같은 방식이다(`cmnDraftStore`, 항목 묶음 완료 시 중간 저장, 최종 저장, 자동 재전송 없음).
- BR-8: 질문 문구. 셸은 Provider가 준 문구만 보인다.
  - 라이선스 원문 질문(VDA 6.3 등)은 라이선스 확인 플래그가 있을 때만 Provider가 준다(Vol.6c D6C-2, DS-6). 없으면 SL 자체 문구를 준다.
- BR-9: 다음 질문으로 넘어가는 데 서버 호출이 없다. 사진은 UX-001 축소 업로드를 쓴다.

**화면/UX**: 화면 유형 T4.
- 화면 순서: 상단(심사·대상 정보, 진행률, 내 분담만, 점수 보기) → 요소 목록 → 질문 카드 → 하단 고정(이전, 다음, 임시 저장 상태, 제출).
- 셸은 T1 레코드 페이지의 "현재 단계" 탭이나 전체 화면 탭으로 연다.

**권한**
- `CMN_PS_UiFramework_User`에 `CMN_ChecklistController`를 더한다.
- 답 저장 권한은 Provider가 레코드 권한과 UX-005 규칙으로 판정한다.

**수용 기준**

- AC-1: Given SCORE_STEPS 질문(allowedScores 0, 4, 6, 8, 10 — 테스트 값), When 카드 표시, Then 점수 버튼 5개이고 다른 값은 입력할 수 없다.
- AC-2: Given 테스트 Provider가 4점 이하 관찰 필수, When 4점·관찰 없음으로 최종 저장, Then 해당 질문 카드에 오류가 표시되고 저장되지 않는다.
- AC-3: Given 기본 Provider, When 후속 조치 생성, Then `CMN_ActionItem__c` 1건(원천 레코드 Id·질문 키 포함).
- AC-4: Given 미답 3건, When 점수 보기, Then 미답 3과 Provider 계산 결과가 표시된다(셸 계산 없음).
- AC-5: Given 순차 모드, When 다음 질문, Then Apex 호출 0회(Jest).
- AC-6: Given allowNa = false, When 카드 표시, Then NA 버튼이 없다. allowNa = true에서 NA 선택 + 사유 없음은 저장 차단.
- AC-7: Given 내 분담만 켜기, When 표시, Then 다른 심사원에게 분담된 질문은 보이지 않는다.

**에이전트 주의**
- 질문지 템플릿 객체는 CMN-00-QNR-001 소유다. 이 셸은 질문지를 저장하지 않는다(도메인 Provider가 스냅숏 문항을 준다).
- 점수 계산을 LWC나 이 WI의 Apex에 넣지 않는다.
- VDA 등 라이선스 문구를 테스트·데모 데이터에 넣지 않는다.

**오픈 이슈**
- 계층별 공정 심사(LPA)를 별도 기능으로 둘지 SL에 확인해야 한다(이 셸과 Provider로 수용 가능).
- PMS Gate 점검의 적용 시점과 Provider는 PMS-09-GAT-003에서 정했다(2026-11-06).

### CMN-00-QNR-001 표준 질문지 템플릿(판·버전·문항 대응)

추적 Q-30, Q-31, Q-32, Q-33, P-54 · 필수 · W1 · SF · DM, APEX, LWC · Customization · 선행 MDM-007, I18N-001, DOC-001, UX-009 · 7 M/D

**목적**: VDA 6.3·IATF 16949 심사 질문지, 고객 Gate·APQP 점검표, SL 신제품개발 Gate 평가표처럼 **외부·사내 표준이 판(版) 단위로 개정되는 질문지**를 판째 받아 버전 템플릿으로 등록하고, QMS 심사·자체 평가·LPA와 PMS Gate 평가가 같은 엔진으로 쓴다. 회사표준 개정(신제품개발 26.11~27.04), IATF 16949 2판, VDA 6.3 개정판을 개발 없이 반영하고, 심사·평가 당시 어떤 판의 어떤 문항으로 판정했는지 재현하기 위해서다. 2026-11-06 검토 결과(`pms-architecture.md` 6절)에 따라 Vol.6c IAU-001의 질문지·질문·등급 규칙을 이 WI로 옮겼다(공통 판정 기준 (2) 같은 엔진·콘텐츠만 다름).

**범위** In: 질문지 템플릿·문항·등급 규칙 객체, 점수 계산기 등록 메타데이터, 판 수령(원문 파일·발효일·판 변경 표시), 새 버전·활성화·발효일 전환, 판 간 문항 대응과 비교 보고, CSV 일괄 등록, 편집기·시뮬레이터, 스냅숏 API. Out: 도메인별 계산기 구현(QMS-06-IAU-003 일반, QMS-06-CAU-002 VDA 6.3, PMS-09-GAT-003 Gate RAG), 실행 화면(UX-009 체크리스트 셸 + 도메인 Provider), 도메인별 사용 규칙(QMS-06-IAU-001 심사, PMS-09-GAT-002 Gate).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| CMN_QuestionnaireTemplate__c.TemplateCode__c | Text(40), External ID, Unique | Y | `{Family}-V{Version}` 자동. 예: VDA63-PROC-V2, SL-GDP-G5-V1 |
| CMN_QuestionnaireTemplate__c.Domain__c | Picklist (AUDIT 심사, SELF_ASSESSMENT 자체 평가, LPA 계층별 공정 감사, GATE PMS Gate, LELE 레슨런 점검, OTHER) | Y | 사용 도메인. 편집 권한도 도메인 단위(BR-8) |
| CMN_QuestionnaireTemplate__c.Family__c | Text(40) | Y | 같은 질문지의 버전 묶음 키. 예: VDA63-PROC, IATF-SYS, PROD-HL, SL-GDP-G5, CUST-GATE-BMW-RG3 |
| CMN_QuestionnaireTemplate__c.Version__c | Number(3,0) | Y | 시스템 버전(1부터). 판이 같아도 오탈자·안내 수정이면 1 증가 |
| CMN_QuestionnaireTemplate__c.Name / NameEn__c / NameZh__c | Text(80) | Y / N / N | 다국어 표시명(I18N-001) |
| CMN_QuestionnaireTemplate__c.Scheme__c | Picklist (COMPLIANCE 적합·부적합, POINTS 배점 합, VDA63 VDA 6.3 점수, PRODUCT_AUDIT 제품 심사 결함 가중, GATE_RAG Gate 신호) | Y | 점수 계산기 선택 키 |
| CMN_QuestionnaireTemplate__c.UsageKeys__c | Text(255) | N | 도메인이 정한 사용 범위 키(쉼표). AUDIT = `{심사 레코드타입}/{심사 유형}`(QMS-06-IAU-001), GATE = GateCode(PMS-09-GAT-002). 공란 = 도메인 전체 |
| CMN_QuestionnaireTemplate__c.CustomerGroup__c | Picklist (MDM-003 CustomerGroup 값) | N | 고객 전용 질문지(예: BMW 대비 자체 평가, 고객 Gate) |
| CMN_QuestionnaireTemplate__c.StandardRef__c | Text(80) | Y | 근거 규격(예: VDA 6.3, IATF 16949, SL 신제품개발 프로세스) |
| CMN_QuestionnaireTemplate__c.StandardEdition__c | Text(40) | Y | 받은 판(예: 2023, 2016, Rev02) |
| CMN_QuestionnaireTemplate__c.EditionIssuedDate__c | Date | N | 판 발행일 |
| CMN_QuestionnaireTemplate__c.EditionChange__c | Checkbox | Y | 이전 버전과 판이 다르면 true(BR-4 문항 대응 필수) |
| CMN_QuestionnaireTemplate__c.SourceDocument__c | Lookup(CMN_Document__c) | EditionChange 또는 LICENSED_ORIGINAL이면 Y | 받은 원문·판 파일(DocClass QUESTIONNAIRE_SOURCE, 사내 제한) |
| CMN_QuestionnaireTemplate__c.PreviousVersion__c | Lookup(CMN_QuestionnaireTemplate__c) | 2판부터 Y | 같은 Family의 직전 버전 |
| CMN_QuestionnaireTemplate__c.EffectiveFrom__c / EffectiveTo__c | Date / Date | ACTIVE면 From Y / N | 발효 기간. To는 다음 버전 발효 전날로 자동 |
| CMN_QuestionnaireTemplate__c.AllowedScores__c | Text(40) | VDA63·SCORE_STEPS면 Y | 허용 점수 단계(쉼표). 품질경영팀이 원문 기준으로 입력 |
| CMN_QuestionnaireTemplate__c.DefectWeightA__c / B__c / C__c | Number(5,2) | PRODUCT_AUDIT면 Y | 결함 등급별 가중치(SL 기준값) |
| CMN_QuestionnaireTemplate__c.TextSource__c | Picklist (SL_WORDING SL 자체 문구, LICENSED_ORIGINAL 라이선스 원문) | Y | 문항 문구 출처 선언(D6C-2) |
| CMN_QuestionnaireTemplate__c.LicenseConfirmed__c / LicenseRef__c | Checkbox / Text(255) | N / LicenseConfirmed면 Y | 원문 사용 라이선스 확인과 근거 |
| CMN_QuestionnaireTemplate__c.ResponsibleDept__c | Lookup(CMN_Department__c) | Y | 관리 부서(QMS = 품질경영팀, GATE = PMO) |
| CMN_QuestionnaireTemplate__c.Status__c | Picklist (DRAFT, ACTIVE, OBSOLETE) | Y | 서비스로만 변경 |
| CMN_QuestionnaireItem__c.Template__c | Master-Detail | Y | |
| CMN_QuestionnaireItem__c.ItemNo__c | Text(20) | Y | 예: 6.2.3, SYS-07-02, G5-12. 템플릿 안 Unique |
| CMN_QuestionnaireItem__c.Element__c / SubElement__c | Text(20) / Text(20) | VDA63이면 Element Y / N | 예: P6 / 6.2 |
| CMN_QuestionnaireItem__c.Sequence__c | Number(4,0) | Y | |
| CMN_QuestionnaireItem__c.Text__c / TextEn__c / TextZh__c | Long Text(2000) | Y(서비스 확인) / N / N | TextSource 규칙(BR-3) |
| CMN_QuestionnaireItem__c.Guidance__c | Long Text(4000) | N | 확인 포인트·예시 증빙(SL 작성) |
| CMN_QuestionnaireItem__c.IsStar__c | Checkbox | N | 강등 규칙 대상 문항(별표) |
| CMN_QuestionnaireItem__c.IsMandatory__c | Checkbox | N | 필수 문항(Gate는 미충족 시 RED 강등 대상) |
| CMN_QuestionnaireItem__c.AnswerType__c | Picklist (SCORE_STEPS 단계 점수, COMPLIANCE 적합·부적합·해당 없음, POINTS 0~최대, YES_NO 예·아니오, DEFECT_CLASS 결함 등급 개수, TEXT 서술) | Y | UX-009 답 유형과 같다 |
| CMN_QuestionnaireItem__c.MaxPoints__c | Number(5,2) | SCORE_STEPS·POINTS면 Y | SCORE_STEPS는 AllowedScores 최댓값 자동 |
| CMN_QuestionnaireItem__c.Weight__c | Number(5,2) | Y | 기본 1 |
| CMN_QuestionnaireItem__c.AllowNA__c | Checkbox | Y | 해당 없음 허용 |
| CMN_QuestionnaireItem__c.ScopeKeys__c | Text(255) | N | 문항 필터 키(쉼표). AUDIT = QMS_PROCESS 코드, GATE = DEV_ACTIVITY_TYPE 코드. 공란 = 공통 문항 |
| CMN_QuestionnaireItem__c.EvidenceKeys__c | Text(255) | N | 연결 증빙 규칙 키(QMS-06-IAU-005, PMS-09-GAT-003) |
| CMN_QuestionnaireItem__c.AutoCheckRuleKey__c / AutoCheckParams__c | Text(80) / Text(255) | N | 자동 점검 규칙 키와 매개변수(예: DELIVERABLE_APPROVED / DFMEA). 해석은 도메인 Provider |
| CMN_QuestionnaireItem__c.PreviousItemKey__c | Text(80) | EditionChange이고 MappingType이 NEW가 아니면 Y | 직전 버전 문항의 ExternalKey |
| CMN_QuestionnaireItem__c.MappingType__c | Picklist (SAME 같음, CHANGED 바뀜, NEW 새 문항, SPLIT 나뉨, MERGED 합쳐짐) | 2판부터 Y | 직전 버전 대비 대응 |
| CMN_QuestionnaireItem__c.ExternalKey__c | Text(80), External ID, Unique | Y | `{TemplateCode}-{ItemNo}` |
| CMN_QuestionnaireGradeRule__c.Template__c | Master-Detail | Y | |
| CMN_QuestionnaireGradeRule__c.RuleType__c | Picklist (GRADE_BAND 등급 구간, DOWNGRADE 강등) | Y | |
| CMN_QuestionnaireGradeRule__c.Grade__c | Text(10) | GRADE_BAND면 Y | 예: A, B, C / GREEN, AMBER, RED |
| CMN_QuestionnaireGradeRule__c.MinPercent__c / MaxPercent__c | Number(5,2) | GRADE_BAND면 Y | Min ≤ 달성률 < Max(마지막 구간은 Max 포함) |
| CMN_QuestionnaireGradeRule__c.Condition__c | Picklist (STAR_ITEM_SCORE_LE 별표 문항 점수 이하, ANY_ITEM_SCORE_LE 임의 문항 점수 이하, ELEMENT_PERCENT_LT 요소 달성률 미만, SUBELEMENT_PERCENT_LT 하위 요소 달성률 미만, MAJOR_FINDING_COUNT_GE 중대 지적 수 이상, MANDATORY_NOT_MET_GE 필수 미충족 수 이상) | DOWNGRADE면 Y | |
| CMN_QuestionnaireGradeRule__c.Threshold__c | Number(5,2) | DOWNGRADE면 Y | 조건 기준값 |
| CMN_QuestionnaireGradeRule__c.AppliesToGrades__c / ResultGrade__c | Text(30) / Text(10) | DOWNGRADE면 Y | 적용 대상 등급(쉼표)과 결과 등급 |
| CMN_QuestionnaireGradeRule__c.Sequence__c / Description__c | Number(3,0) / Text(255) | Y | 적용 순서, 보고서 표시 문구 |
| CMN_QuestionnaireScorer__mdt | Custom Metadata | — | Scheme__c, ScorerClass__c(`CMN_QuestionnaireScorer` 구현), IsActive__c |

**서비스 API**

    public with sharing class CMN_QuestionnaireService {
      // 발효 중 템플릿: Domain·Family(필수)·CustomerGroup(있으면 우선)·asOf(EffectiveFrom ≤ asOf, 가장 늦은 것)
      static CMN_QuestionnaireTemplate__c activeTemplate(String domain, String family, String customerGroup, Date asOf)
      // 실행용 스냅숏: 문항 전체(문구 3개 언어, 답 형태, 배점, 별표·필수, 자동 점검 키, ExternalKey) + 등급 규칙
      static CMN_Questionnaire.Snapshot snapshot(Id templateId)
      static Id newVersion(Id templateId, Boolean editionChange)          // DRAFT 복사(문항·규칙, PreviousItemKey = 원 문항 키, MappingType SAME)
      static void activate(Id templateId, Date effectiveFrom)            // BR-1·4·5·6 검사
      static CMN_Questionnaire.EditionCompare compareVersions(Id fromId, Id toId) // SAME·CHANGED·NEW·REMOVED·SPLIT·MERGED 목록·건수
      static CMN_Questionnaire.ImportResult importItems(Id templateId, String csv)
    }
    public interface CMN_QuestionnaireScorer {
      CMN_Questionnaire.ScoreResult score(CMN_Questionnaire.Snapshot snapshot, List<CMN_Questionnaire.Answer> answers)
    }

**비즈니스 규칙**

- BR-1: 버전 보호 — ACTIVE 템플릿과 그 문항·등급 규칙은 고칠 수 없다. "새 버전"은 같은 Family로 Version + 1인 DRAFT를 만들고 문항·규칙을 복사한다(PreviousItemKey = 원 문항 ExternalKey, MappingType = SAME). 이미 시작한 심사·평가는 스냅숏을 갖고 있어 영향받지 않는다.
- BR-2: 판 수령 — 판이 바뀌면 "새 판으로 새 버전"(EditionChange = true)을 고르고 StandardEdition·EditionIssuedDate·SourceDocument(받은 원문 파일, DOC-001 DocClass QUESTIONNAIRE_SOURCE, 관리 부서만 열람)를 입력한다. CSV로 문항을 바꾸면서 PreviousItemKey·MappingType을 함께 넣는다.
- BR-3: 문구 출처 — TextSource = LICENSED_ORIGINAL은 LicenseConfirmed = true이고 LicenseRef와 SourceDocument가 있을 때만 고를 수 있다. SL_WORDING 템플릿은 활성화 화면에서 "외부 규격 원문을 옮겨 적지 않았음" 확인을 받아 이력(UX-003 코멘트)에 남긴다(D6C-2).
- BR-4: 문항 대응(활성화 시) — EditionChange = true면 모든 문항에 MappingType이 있어야 하고, NEW가 아닌 문항은 PreviousItemKey가 직전 버전에 있어야 한다. 직전 버전 문항 중 어느 새 문항에서도 가리키지 않은 것은 REMOVED로 비교 보고에 나온다.
- BR-5: 발효 — activate(effectiveFrom)은 effectiveFrom ≥ 오늘이어야 한다. 같은 Family(·CustomerGroup)의 이전 ACTIVE는 EffectiveTo = 새 effectiveFrom − 1일로 바뀌고, 매일 02:00 배치가 EffectiveTo < 오늘인 ACTIVE를 OBSOLETE로 바꾼다. 그래서 새 판을 발효일 전에 미리 받아 둘 수 있다. activeTemplate은 asOf 기준으로 고른다.
- BR-6: 점수 체계별 검증(활성화 시) — VDA63: 모든 문항 AnswerType = SCORE_STEPS 또는 TEXT, Element 필수, AllowedScores 필수. COMPLIANCE: COMPLIANCE·YES_NO·TEXT. POINTS: MaxPoints > 0. PRODUCT_AUDIT: DefectWeightA~C 필수, DEFECT_CLASS 문항 1개 이상. GATE_RAG: COMPLIANCE·YES_NO·TEXT, GRADE_BAND 등급은 GREEN·AMBER·RED만. 해당 Scheme의 CMN_QuestionnaireScorer__mdt가 활성이어야 한다.
- BR-7: 등급 구간 검증(활성화 시) — GRADE_BAND가 하나라도 있으면 0~100을 겹침·빈틈 없이 덮어야 한다. DOWNGRADE의 AppliesToGrades·ResultGrade는 GRADE_BAND에 있는 등급만 허용. 등급 구간이 없으면 점수만 계산하고 등급은 비운다.
- BR-8: 도메인 권한 — 편집·활성화는 PS `CMN_PS_Questionnaire_Admin` + 도메인 Custom Permission(`CMN_QnrAdmin_Audit`, `CMN_QnrAdmin_Gate`, `CMN_QnrAdmin_Other`)이 있어야 한다. QMS 품질경영팀은 AUDIT·SELF_ASSESSMENT·LPA·LELE, PMS PMO는 GATE를 관리한다.
- BR-9: 규칙 값의 원천 — VDA 6.3 등급 구간·강등 조건·허용 점수, 고객 Gate 기준은 관리 부서가 원문으로 검수해 입력한다(D6C-3). 개발 산출물(코드·초기 데이터 스크립트)에 문항·규칙 숫자를 넣지 않는다. 테스트는 테스트 전용 가상 템플릿으로 한다.
- BR-10: 사용 중 보호 — 심사·평가에서 쓰인 템플릿·문항은 삭제할 수 없다(OBSOLETE만). 사용 여부는 도메인이 등록한 사용 확인 클래스로 묻는다(`CMN_QuestionnaireUsageCheck`, QMS-06-IAU-002·PMS-09-GAT-003 구현).
- BR-11: 편집기 `cmnQuestionnaireEditor` — 왼쪽 트리(요소 → 하위 요소 → 문항, 드래그 순서), 오른쪽 문항 편집(ko·en·zh 탭, 안내, 별표·필수, 답 형태, 배점, 가중치, 범위 키, 증빙 키, 자동 점검 키, 이전 판 문항·대응), 탭 "등급 규칙"(구간·강등 표), 탭 "시뮬레이터"(문항별 가상 답 → 해당 Scheme 계산기로 요소·전체 달성률, 강등 전·후 등급), 탭 "판 비교"(compareVersions 결과와 건수).
- BR-12: 일괄 등록 `cmnQuestionnaireImport` — CSV(ItemNo, Element, SubElement, 문구 ko·en·zh, Guidance, IsStar, IsMandatory, AnswerType, MaxPoints, Weight, AllowNA, ScopeKeys, EvidenceKeys, AutoCheckRuleKey, AutoCheckParams, PreviousItemKey, MappingType)로 DRAFT 템플릿에 문항을 upsert하고 행별 오류를 표시한다.

**화면/UX**: T6 기준정보·설정. 편집기(템플릿 레코드 페이지 첫 탭), 가져오기 앱 페이지, 리스트뷰(Domain·Family·상태·발효일). SL Admin 앱 "질문지" 탭, QMS 메뉴 허브 06 심사 설정, PMS 메뉴 허브 09 Gate 설정에서 도메인 필터로 연다. 실행 화면은 UX-009 셸이다.

**권한**: CMN_PS_Questionnaire_Read(사내 페르소나 조회), CMN_PS_Questionnaire_Admin + 도메인 Custom Permission(편집·활성화, BR-8).

**수용 기준**

- AC-1: Given ACTIVE 템플릿의 문항, When 문구 수정, Then 차단 + "새 버전 만들기" 안내.
- AC-2: Given 문항 58개 ACTIVE V1, When 새 판으로 새 버전, Then V2 DRAFT에 문항 58개·등급 규칙 복사, 모든 문항 MappingType SAME·PreviousItemKey 채움, EditionChange = true, SourceDocument 없으면 활성화 차단.
- AC-3: Given V2에서 문항 3개 삭제·2개 추가(NEW)·5개 문구 변경(CHANGED), When 판 비교, Then SAME 50·CHANGED 5·NEW 2·REMOVED 3.
- AC-4: Given V1 ACTIVE, V2를 다음 달 1일 발효로 활성화, When 오늘 기준 activeTemplate, Then V1. 발효일 기준이면 V2. 발효일 다음 날 배치 후 V1 OBSOLETE.
- AC-5: Given V1으로 시작한 심사(또는 Gate 평가), When V2 활성화, Then 그 심사의 스냅숏 문항은 V1 그대로.
- AC-6: Given 테스트 구간 0~80 C, 90~100 A만 등록, When 활성화, Then 80~90 빈 구간 오류로 차단.
- AC-7: Given LicenseConfirmed = false, When TextSource를 LICENSED_ORIGINAL로 저장, Then 차단.
- AC-8: Given GATE 관리 권한만 있는 사용자, When AUDIT 템플릿 활성화, Then 차단.
- AC-9: Given CSV 60행 중 2행 AnswerType 오류, When 업로드, Then 58행 반영 + 2행 사유 표시.

**에이전트 주의**
- VDA 6.3·IATF·고객 Gate 문구를 기억이나 인터넷에서 옮겨 초기 데이터·테스트에 넣지 않는다(BR-9).
- 템플릿 편집을 표준 관련 목록 편집으로 대신하지 않는다. 버전 보호 검사는 서비스와 트리거에 있어야 한다.
- 도메인별 계산기를 이 WI에 만들지 않는다. 인터페이스와 등록부만 만든다.
- 실행 결과(답)를 이 객체들에 저장하지 않는다. 도메인 객체(심사 결과 라인, Gate 평가 항목)가 스냅숏과 답을 갖는다.

**오픈 이슈**: 고객 Gate·APQP 점검표 원문의 사용 권한(고객 제공 양식), 판 수령 담당(품질경영팀·PMO)과 발효 결재 필요 여부, LPA를 이 엔진으로 할지(UX-009 오픈 이슈와 같음).

## 9. CMN-00-APV 결재

**설계 결정: 표준 Approval Process 대신 공통 결재 엔진을 만든다.** 표준 기능은 객체별로 결재 단계가 고정되고, 사용자가 결재선을 임의 편집하거나(Q-44) CFT Role로 결재자를 동적 결정하거나(Q-43) 기간 지정 대리결재(Q-45)·포탈 To-Do 연동(Q-41)을 하기 어렵다. 엔진 하나로 QMS(4M·NCR 통보서·특채·8D)와 PMS(산출물 결재)를 모두 처리한다. Fit-Gap 표기는 Customization이지만 “공통 엔진 1회 개발, 업무별 설정”으로 설명한다.

### CMN-00-APV-001 결재 데이터 모델·상태 엔진·서비스 API

추적 Q-43, P-65, P-38 · 필수 · W0 · SF · DM, APEX · Customization · 선행 ARC-002, ARC-003, SEC-002 · 8 M/D

**목적**: 어떤 업무 객체든 “결재 요청 → 단계별 처리 → 완료 콜백”을 같은 방식으로 수행한다.

**데이터 모델**

| 객체 / 필드                                                      | 타입                                                               | 필수 | 설명                                                                                                                                                                                |
|------------------------------------------------------------------|--------------------------------------------------------------------|------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| CMN_ApprovalType__mdt                                          | Custom Metadata                                                    | —    | TypeCode(DeveloperName), TargetObject__c, CallbackClass__c, LockOnSubmit__c, KeepLockedAfterApproval__c, RequireDrafterManager__c, ReminderDays__c, EscalationDays__c |
| CMN_ApprovalRequest__c.RecordNo__c                           | Text(40), Unique                                                   | Y    | ARC-003 채번 `APV-{YYYY}-{SEQ:7}`                                                                                                                                                   |
| CMN_ApprovalRequest__c.TypeCode__c                           | Text(80)                                                           | Y    | 예: QMS_4M_APPROVE, QMS_NCR_NOTICE, PMS_DELIVERABLE                                                                                                                                 |
| CMN_ApprovalRequest__c.TargetRecordId__c / TargetObject__c | Text(18) / Text(80)                                                | Y    | 결재 대상(다형)                                                                                                                                                                     |
| CMN_ApprovalRequest__c.TargetRecordNo__c                     | Text(40)                                                           | N    | 대상 업무 번호 사본                                                                                                                                                                 |
| CMN_ApprovalRequest__c.Title__c                              | Text(255)                                                          | Y    |                                                                                                                                                                                     |
| CMN_ApprovalRequest__c.Status__c                             | Picklist (DRAFT, IN_PROGRESS, APPROVED, REJECTED, RECALLED)        | Y    |                                                                                                                                                                                     |
| CMN_ApprovalRequest__c.CurrentStepNo__c                      | Number(3,0)                                                        | N    | 진행 중 단계                                                                                                                                                                        |
| CMN_ApprovalRequest__c.Plant__c                              | Lookup(CMN_Plant__c)                                             | N    | 공유·통계용                                                                                                                                                                         |
| CMN_ApprovalRequest__c.Version__c                            | Number(3,0)                                                        | Y    | 같은 대상의 재상신 차수(1부터)                                                                                                                                                      |
| CMN_ApprovalRequest__c.Summary__c                            | Long Text(32768)                                                   | N    | 상신 시점 핵심 필드 스냅숏(JSON). 결재자 화면·감사 근거                                                                                                                             |
| CMN_ApprovalRequest__c.SubmittedAt__c / CompletedAt__c     | DateTime                                                           | N    |                                                                                                                                                                                     |
| CMN_ApprovalStep__c.Request__c                               | Master-Detail                                                      | Y    |                                                                                                                                                                                     |
| CMN_ApprovalStep__c.StepNo__c                                | Number(3,0)                                                        | Y    | 같은 번호 = 병렬(모두 승인 필요)                                                                                                                                                    |
| CMN_ApprovalStep__c.StepType__c                              | Picklist (REVIEW 검토, AGREE 합의, APPROVE 승인, CC 참조)          | Y    | CC는 처리 없이 통보만                                                                                                                                                               |
| CMN_ApprovalStep__c.Approver__c                              | Lookup(User)                                                       | Y    | 지정 결재자                                                                                                                                                                         |
| CMN_ApprovalStep__c.RoleCode__c                              | Text(40)                                                           | N    | Role로 해석된 경우 원본 Role                                                                                                                                                        |
| CMN_ApprovalStep__c.Status__c                                | Picklist (WAITING, PENDING, APPROVED, REJECTED, SKIPPED, NOTIFIED) | Y    | PENDING = 현재 처리 차례                                                                                                                                                            |
| CMN_ApprovalStep__c.ActedBy__c                               | Lookup(User)                                                       | N    | 실제 처리자(대결 시 대리인)                                                                                                                                                         |
| CMN_ApprovalStep__c.IsDelegated__c                           | Checkbox                                                           | N    | 대결 여부                                                                                                                                                                           |
| CMN_ApprovalStep__c.Comment__c                               | Long Text(4000)                                                    | N    |                                                                                                                                                                                     |
| CMN_ApprovalStep__c.ActedAt__c                               | DateTime                                                           | N    |                                                                                                                                                                                     |
| CMN_ApprovalEvent__e                                           | Platform Event                                                     | —    | RequestId__c, StepId__c, EventType__c (SUBMITTED, STEP_PENDING, STEP_DONE, APPROVED, REJECTED, RECALLED), UserId__c                                                         |

**서비스 API (`CMN_ApprovalService`)**

    Id submit(Id targetId, String typeCode, List<CMN_ApprovalStepSpec> steps, String comment)
    void approve(Id stepId, String comment)
    void reject(Id stepId, String comment)      // comment 필수
    void recall(Id requestId, String comment)
    CMN_ApprovalStatusDTO getStatus(Id targetId) // 최신 Version 기준

**비즈니스 규칙**

- BR-1: submit 검증 — 마지막 단계는 APPROVE, APPROVE 단계 1개 이상, 결재자는 활성 사용자, 기안자 본인을 결재자로 넣을 수 없음, RequireDrafterManager__c면 기안자 부서장(MDM-001 Manager__c) 포함 필수(PMS 산출물 “팀장 필수” 규칙 P-38·P-44).
- BR-2: 진행 — StepNo 오름차순. 같은 StepNo의 단계들이 모두 APPROVED가 되면 다음 StepNo가 PENDING. CC 단계는 해당 순서에 도달하면 NOTIFIED로 표시하고 대기하지 않는다.
- BR-3: 반려 — 어느 단계든 REJECTED면 요청 REJECTED, 이후 단계 SKIPPED, 대상 잠금 해제, 콜백 onRejected. 반려 사유 필수.
- BR-4: 회수 — 기안자만, 첫 결재 단계가 아직 처리되지 않았을 때만 가능.
- BR-5: 잠금 — LockOnSubmit이면 상신 시 `Approval.lock(targetId)`, 완료 시 KeepLockedAfterApproval가 false면 해제. (Setup: “Apex에서 레코드 잠금/해제 허용” 활성 필요.)
- BR-6: 접근 권한 — 상신 시 모든 결재자·참조자(및 APV-004 대리인)에게 대상 레코드 Read 공유를 Apex Sharing Reason `CMN_Approval`로 부여한다(다른 공장 결재자 대응). 대상이 표준 객체면 수동 공유(RowCause Manual)로 부여.
- BR-7: 재상신 — 반려 후 다시 submit하면 Version + 1로 새 요청을 만들고 이전 요청은 그대로 보존한다.
- BR-8: 콜백 — CallbackClass__c는 인터페이스 `CMN_ApprovalCallback`(onSubmitted, onApproved, onRejected, onRecalled)을 구현한다. 업무 객체의 상태 변경은 콜백 안에서만 한다(엔진은 업무 필드를 직접 바꾸지 않는다).
- BR-9: 모든 상태 변화는 CMN_ApprovalEvent__e를 발행한다. To-Do(TDO-001)·알림(NTF-001)은 이 이벤트를 구독한다(엔진이 To-Do·메일을 직접 만들지 않는다).

**수용 기준**

- AC-1: Given 검토(1)-합의 2명 병렬(2)-승인(3), When 1 승인·2의 1명만 승인, Then 3은 WAITING 유지.
- AC-2: Given 2단계 반려, When 처리, Then 요청 REJECTED, 3단계 SKIPPED, 대상 잠금 해제, onRejected 1회 호출.
- AC-3: Given 마지막이 REVIEW인 결재선, When submit, Then 예외(라벨 메시지).
- AC-4: Given 다른 공장 결재자, When 상신, Then 해당 결재자가 대상 레코드를 조회할 수 있다.
- AC-5: Given 1단계 처리 완료, When 기안자 회수, Then 차단.
- AC-6: Given 승인 완료, When 같은 대상 재상신, Then Version 2 요청 생성, Version 1 이력 유지.

**에이전트 주의**: 표준 `ProcessInstance`·Approval Process를 만들지 않는다. 결재 상태를 업무 객체 필드에 중복 저장해야 하면 콜백에서만 갱신한다.

### CMN-00-APV-002 결재선 템플릿·CFT Role 매핑

추적 Q-43, Q-44, P-65, P-66 · 필수 · W0 · SF · DM, APEX · Customization · 선행 APV-001, MDM-007 · 6 M/D

**목적**: “4M 변경 결재선 = 품질팀장 검토 → 생산팀장 합의 → 공장장 승인”처럼 사람 대신 Role로 템플릿을 정의하고, 상신 시점의 공장·부서 기준으로 실제 결재자를 해석한다.

**데이터 모델**

| 객체 / 필드                                                              | 타입                                                               | 필수   | 설명                                                                                                                                                  |
|--------------------------------------------------------------------------|--------------------------------------------------------------------|--------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| CMN_Code__c (Group `APPROVAL_ROLE`)                                    | 코드                                                               | —      | QUALITY_MANAGER 품질팀장, PRODUCTION_MANAGER 생산팀장, PLANT_MANAGER 공장장, PURCHASING_MANAGER 구매팀장, DEV_MANAGER 개발팀장, QM_HEAD 품질본부장 등 |
| CMN_RoleAssignment__c.Role__c                                        | Lookup(CMN_Code__c, APPROVAL_ROLE 필터)                          | Y      |                                                                                                                                                       |
| CMN_RoleAssignment__c.Plant__c                                       | Lookup(CMN_Plant__c)                                             | N      | 공란 = 전사                                                                                                                                           |
| CMN_RoleAssignment__c.Department__c                                  | Lookup(CMN_Department__c)                                        | N      |                                                                                                                                                       |
| CMN_RoleAssignment__c.User__c                                        | Lookup(User)                                                       | Y      |                                                                                                                                                       |
| CMN_RoleAssignment__c.ValidFrom__c / ValidTo__c                    | Date                                                               | Y / N  |                                                                                                                                                       |
| CMN_ApprovalTemplate__c.TypeCode__c                                  | Text(80)                                                           | Y      | APV-001 TypeCode                                                                                                                                      |
| CMN_ApprovalTemplate__c.Plant__c                                     | Lookup(CMN_Plant__c)                                             | N      | 공란 = 전사 기본                                                                                                                                      |
| CMN_ApprovalTemplate__c.Scope__c                                     | Picklist (SYSTEM, PERSONAL)                                        | Y      | PERSONAL = 사용자 저장 결재선                                                                                                                         |
| CMN_ApprovalTemplate__c.AllowUserEdit__c                             | Checkbox                                                           | Y      |                                                                                                                                                       |
| CMN_ApprovalTemplate__c.IsDefault__c / IsActive__c                 | Checkbox                                                           | Y      |                                                                                                                                                       |
| CMN_ApprovalTemplateStep__c.Template__c                              | Master-Detail                                                      | Y      |                                                                                                                                                       |
| CMN_ApprovalTemplateStep__c.StepNo__c / StepType__c                | APV-001과 동일                                                     | Y      |                                                                                                                                                       |
| CMN_ApprovalTemplateStep__c.ResolverType__c                          | Picklist (ROLE, USER, DRAFTER_MANAGER, RECORD_FIELD, PROJECT_ROLE) | Y      | PROJECT_ROLE은 PMS가 구현(예약)                                                                                                                       |
| CMN_ApprovalTemplateStep__c.RoleCode__c / User__c / FieldPath__c | Text(40) / Lookup(User) / Text(255)                                | 유형별 | FieldPath 예: `ResponsibleDept__r.Manager__c`                                                                                                         |
| CMN_ApprovalTemplateStep__c.IsMandatory__c                           | Checkbox                                                           | Y      | 사용자가 삭제 불가                                                                                                                                    |

**비즈니스 규칙**

- BR-1: 템플릿 선택 순서 — (TypeCode, 대상 Plant, SYSTEM, IsDefault) → (TypeCode, Plant 공란, SYSTEM, IsDefault). 없으면 상신 화면에서 사용자가 직접 결재선을 만든다.
- BR-2: ROLE 해석 순서 — Role+대상 Plant+기안자 부서 → Role+대상 Plant → Role+Plant 공란. 오늘 날짜가 ValidFrom~ValidTo 안에 있는 1명. 2명 이상이면 오류(설정 오류로 간주), 0명이면 상신 차단 메시지에 Role명과 공장명 표시.
- BR-3: AllowUserEdit면 사용자는 비필수 단계 삭제·순서 변경, 단계 추가(사용자 직접 지정), CC 추가를 할 수 있다. IsMandatory 단계는 삭제·결재자 변경 불가.
- BR-4: 사용자는 편집한 결재선을 PERSONAL 템플릿으로 저장·재사용할 수 있다(본인만 조회).
- BR-5: `CMN_ApprovalLineResolver.resolve(targetId, typeCode)`는 List\<CMN_ApprovalStepSpec\>를 반환하며 APV-003 UI와 서비스 상신 모두 이 메서드를 쓴다.

**수용 기준**

- AC-1: Given KR01 품질팀장 = 김OO, CN01 품질팀장 = 王OO, When CN01 4M 결재선 해석, Then 王OO.
- AC-2: Given 해당 공장에 PLANT_MANAGER 미등록, When 상신, Then “공장장(CN01) 결재자 미지정” 메시지로 차단.
- AC-3: Given IsMandatory 품질팀장 단계, When 사용자가 삭제, Then UI에서 삭제 버튼 비활성 + 서버 검증 차단.
- AC-4: Given 같은 Role·Plant에 유효 기간 겹치는 2명, When 해석, Then 설정 오류 예외.

### CMN-00-APV-003 결재 상신·처리·이력 UI

추적 Q-44, P-66, P-68 · 필수 · W1 · SF · LWC, APEX · Customization · 선행 APV-002, UX-001 · 6 M/D

**목적**: 기안자·결재자·참조자가 같은 컴포넌트로 결재선을 보고 처리한다. 데스크톱·모바일 동일 동작.

**화면 구성**

| 컴포넌트             | 위치                                    | 기능                                                                                   |
|----------------------|-----------------------------------------|----------------------------------------------------------------------------------------|
| `cmnApprovalLine`    | 업무 레코드 페이지(속성: typeCode)      | 해석된 결재선 표시·편집, 상신 의견 입력, 상신/회수 버튼, PERSONAL 템플릿 불러오기·저장 |
| `cmnApprovalAction`  | 결재 요청 레코드 페이지, To-Do에서 열기 | Summary 스냅숏 표시, 대상 레코드 링크, 승인/반려(반려 의견 필수), 대결 표시            |
| `cmnApprovalHistory` | 업무 레코드 페이지                      | 모든 Version의 단계별 처리자·일시·의견 타임라인                                        |
| `cmnApprovalMonitor` | SL QMS·SL PMS 앱 페이지                 | 내가 상신한 / 내가 처리한 / 진행 중 목록, 유형·공장·기간 필터, 체류일수 표시(P-68)     |

**비즈니스 규칙**

- BR-1: 결재자 추가 검색은 이름·사번·부서명으로 하며 비활성 사용자는 검색 결과에서 제외.
- BR-2: 상신 버튼은 대상 레코드가 업무 WI에서 정의한 상신 가능 상태일 때만 활성(`CMN_ApprovalCallback`의 선택 메서드 `canSubmit(targetId)`가 판정, 미구현 시 항상 true).
- BR-3: 진행 중 체류일수 = 현재 PENDING 단계 시작 이후 경과 일수(공장 시간대·영업일 기준은 오픈 이슈, 기본은 달력일).
- BR-4: 업무 레코드 표준(UX-004)에서 결재는 결정 지원 레일의 APPROVAL 패널이다.
  - `cmnApprovalLine`은 레일 패널 계약(UX-004 BR-6)을 지킨다: `@api config`·`@api variant`를 받고, `variant="rail"`이면 결재선 요약(현재 단계·결재자·체류일수)과 상신·회수 버튼만 보인다. 결재선 편집은 모달로 연다.
  - 대기 건수는 `railbadge` 이벤트로 알린다.
  - `cmnApprovalHistory`는 레코드 페이지의 "이력" 탭에 둔다.

**수용 기준**

- AC-1: Given 모바일 웹 결재자, When 반려 의견 없이 반려, Then 버튼 비활성 + 서버 차단.
- AC-2: Given Version 1 반려·Version 2 승인, When 이력 컴포넌트 표시, Then 두 버전이 구분되어 시간순 표시.
- AC-3: Given 저장한 PERSONAL 결재선, When 다른 4M 건에서 불러오기, Then 같은 결재자 구성으로 채워지고 필수 단계는 템플릿 기준 유지.

### CMN-00-APV-004 대리결재(위임)

추적 Q-45, P-67 · 필수 · W1 · SF · DM, APEX, LWC · Customization · 선행 APV-001, TDO-001 · 4 M/D

**데이터 모델**

| 객체 / 필드                                   | 타입              | 필수 | 설명                                    |
|-----------------------------------------------|-------------------|------|-----------------------------------------|
| CMN_Delegation__c.Delegator__c            | Lookup(User)      | Y    | 위임자(부재자)                          |
| CMN_Delegation__c.Delegate__c             | Lookup(User)      | Y    | 대리인                                  |
| CMN_Delegation__c.StartAt__c / EndAt__c | DateTime          | Y    | 위임 기간                               |
| CMN_Delegation__c.TypeCodes__c            | Text(1000)        | N    | 공란 = 전체, 지정 시 쉼표 구분 TypeCode |
| CMN_Delegation__c.Reason__c               | Text(255)         | Y    | 출장, 휴가 등                           |
| CMN_Delegation__c.IsActiveNow__c          | Formula(Checkbox) | —    | NOW()가 기간 안                         |

**비즈니스 규칙**

- BR-1: 위임자 본인 또는 그 부서장이 등록한다. 대리인은 활성 사용자, 위임자 본인 불가.
- BR-2: 대결은 1단계만 — 대리인의 위임은 다시 전달되지 않는다(A→B 위임 중 B→C 위임이 있어도 A 건은 C에게 가지 않음).
- BR-3: 단계가 PENDING이 될 때 위임자에게 유효한 위임이 있으면 위임자 To-Do와 대리인 To-Do(대결 표시)를 함께 만든다. 둘 중 먼저 처리한 사람이 결과를 확정하고 다른 To-Do는 닫는다.
- BR-4: 대리인 처리 시 ActedBy__c = 대리인, IsDelegated__c = true, 이력에 “OOO(대결: 위임자명)” 표시. 대리인에게 대상 레코드 Read 공유를 부여한다(APV-001 BR-6).
- BR-5: 위임 기간에 이미 PENDING인 단계도 위임 등록 즉시 대리인 To-Do를 생성한다.
- BR-6: HR 상태가 LEAVE로 바뀐 사용자(MDM-001)에게 PENDING 결재가 있으면 부서장에게 “대리인 지정 필요” 알림.

**수용 기준**

- AC-1: Given A→B 위임(전체), When A 차례 결재 도래, Then A·B 모두 To-Do 표시, B 처리 시 A To-Do 자동 종료.
- AC-2: Given 위임 기간 종료, When 이후 도래한 A 결재, Then B에게 To-Do 없음.
- AC-3: Given TypeCodes = QMS_4M_APPROVE만, When NCR 통보서 결재 도래, Then B To-Do 없음.

### CMN-00-APV-005 결재 지연 알림·에스컬레이션

추적 P-68, NFR-4.4(알림) · 권장 · W2 · SF · APEX · Customization · 선행 APV-001, NTF-001 · 2 M/D

**비즈니스 규칙**

- BR-1: 스케줄 잡 `CMN_ApprovalReminderJob`이 매시 정각 실행, 각 공장 현지 09:00에 해당하는 공장의 PENDING 단계만 처리한다.
- BR-2: 체류일수 ≥ ReminderDays면 결재자(대리인 포함)에게 독촉 알림, ≥ EscalationDays면 결재자 부서장에게 에스컬레이션 알림. 하루 1회만.
- BR-3: ReminderDays·EscalationDays가 비면 2일·5일.

**수용 기준**

- AC-1: Given ReminderDays 2, PENDING 2일째, When 공장 09:00 잡 실행, Then 독촉 알림 1건, 같은 날 재실행 시 추가 알림 없음.

**오픈 이슈(APV 공통)**: (1) 특채·고객 통보 등 일부 결재를 SL 그룹웨어 전자결재로 보내야 하는지 — 필요 시 “외부 결재 연계” 단계 유형(EXTERNAL) 추가 WI 생성. (2) 체류일수 영업일 기준 여부와 공장별 휴일 캘린더 원천.

## 10. CMN-00-TDO / NTF To-Do·포탈·알림

RFP는 QMS·PMS 모두 “메인 화면 = To-Do 기준, 포탈에 업무/결재 탭 분리 건수·목록 제공”을 요구한다(Q-41, P-19, P-63). 사용자 입장에서 업무 지시가 들어오는 단일 입구이므로, 모든 업무 WI는 사람에게 일을 시킬 때 반드시 TDO-001 서비스를 호출한다.

### CMN-00-TDO-001 통합 To-Do 모델·서비스

추적 Q-41, P-19, P-63 · 필수 · W0 · SF · DM, APEX · Customization · 선행 ARC-002, I18N-001 · 5 M/D

**설계 결정**: 표준 Task 대신 CMN_Todo__c를 쓴다. 표준 Task는 가시성이 상위 레코드에 종속되고 대결·업무/결재 구분·다국어 제목·포탈 API 응답 형식을 일관되게 다루기 어렵다.

**데이터 모델**

| 객체 / 필드                                           | 타입                                | 필수  | 설명                                                   |
|-------------------------------------------------------|-------------------------------------|-------|--------------------------------------------------------|
| CMN_Todo__c.Assignee__c                           | Lookup(User)                        | Y     | 처리자. 레코드 Owner도 Assignee로 설정                 |
| CMN_Todo__c.Category__c                           | Picklist (TASK 업무, APPROVAL 결재) | Y     | 포탈 탭 구분                                           |
| CMN_Todo__c.System__c                             | Picklist (QMS, PMS, CMN)            | Y     | 포탈 표시 시스템명                                     |
| CMN_Todo__c.SourceType__c                         | Text(80)                            | Y     | 예: APV_STEP, QMS_NCR_COUNTERMEASURE, PMS_ACTIVITY     |
| CMN_Todo__c.SourceRecordId__c / SourceObject__c | Text(18) / Text(80)                 | Y     | To-Do를 만든 레코드(결재면 ApprovalStep)               |
| CMN_Todo__c.TargetRecordId__c                     | Text(18)                            | Y     | 클릭 시 열 업무 레코드                                 |
| CMN_Todo__c.RecordNo__c                           | Text(40)                            | N     | 업무 번호 사본                                         |
| CMN_Todo__c.TitleLabel__c / TitleParams__c      | Text(80) / Text(1000)               | Y / N | Custom Label명 + JSON 치환값 → 받는 사람 언어로 렌더링 |
| CMN_Todo__c.TitleFallback__c                      | Text(255)                           | Y     | 생성 시점 기본 언어 렌더링 결과(검색·리포트용)         |
| CMN_Todo__c.DueDate__c                            | Date                                | N     | 공장 시간대 기준 기한                                  |
| CMN_Todo__c.Status__c                             | Picklist (OPEN, DONE, CANCELLED)    | Y     |                                                        |
| CMN_Todo__c.IsDelegated__c / DelegatedFrom__c   | Checkbox / Lookup(User)             | N     | 대결 To-Do                                             |
| CMN_Todo__c.Plant__c                              | Lookup(CMN_Plant__c)              | N     |                                                        |
| CMN_Todo__c.IsOverdue__c                          | Formula(Checkbox)                   | —     | OPEN이고 DueDate \< TODAY()                            |
| CMN_Todo__c.ExternalKey__c                        | Text(120), External ID, Unique      | Y     | `{SourceType}/{SourceRecordId}/{AssigneeId}`           |
| CMN_Todo__c.CompletedAt__c                        | DateTime                            | N     |                                                        |

**서비스 API (`CMN_TodoService`)**

    void open(List<CMN_TodoSpec> specs)              // ExternalKey 기준 upsert, 이미 OPEN이면 무시
    void close(String sourceType, Set<Id> sourceIds, Id assigneeOrNull)  // null이면 해당 소스 전체
    void cancel(String sourceType, Set<Id> sourceIds)
    String renderTitle(CMN_Todo__c t, String languageLocaleKey)

**비즈니스 규칙**

- BR-1: OWD Private, Owner = Assignee. 본인 To-Do만 보인다. 관리자 PSG는 View All.
- BR-2: CMN_ApprovalEvent__e 구독 트리거가 STEP_PENDING이면 결재자(+유효 대리인) APPROVAL To-Do를 open, STEP_DONE·APPROVED·REJECTED·RECALLED이면 해당 단계 To-Do를 close 또는 cancel.
- BR-3: renderTitle은 `System.Label.get('', TitleLabel__c, language)`로 받는 사람 언어 라벨을 얻어 `{key}` 토큰을 TitleParams로 치환한다. 라벨 번역이 없으면 en_US.
- BR-4: To-Do 변경(open/close/cancel)은 `CMN_TodoChanged__e`(AssigneeEmployeeNo__c, TodoId__c, ChangeType__c)를 발행한다(TDO-003 푸시용).
- BR-5: DONE·CANCELLED 상태 To-Do는 180일 후 Snowflake로 이관 후 삭제한다(DWH-002 아카이브 규칙, 업무 이력은 원본 업무 레코드에 있음).

**수용 기준**

- AC-1: Given 같은 Spec으로 open 2회, When 실행, Then To-Do 1건.
- AC-2: Given 결재 단계 PENDING 이벤트, When 처리, Then 결재자 To-Do(APPROVAL) 생성. 승인 이벤트 후 DONE.
- AC-3: Given 중국어 사용자 Assignee, When renderTitle, Then 중국어 제목(번호 치환 포함).
- AC-4: Given 200건 Spec, When open, Then SOQL 2회·DML 1회 이하.

### CMN-00-TDO-002 포탈 SSO

추적 Q-41, P-63, NFR-4.2(SSO) · 필수 · W0 · SF · CFG, APEX · Tailoring · 선행 SEC-004, I18N-001 · 3 M/D

**비즈니스 규칙**

- BR-1: Salesforce = SAML 2.0 Service Provider, 사내 포탈 = Identity Provider. 사용자 매칭은 User.FederationIdentifier = 사번(EmployeeNo__c와 동일 값, INT-002가 세팅).
- BR-2: IdP-initiated(포탈 “Workplace – QMS” 바로가기)와 SP-initiated(메일 링크·북마크 접근 시 포탈 로그인으로 리다이렉트) 모두 지원. RelayState로 원래 URL 유지.
- BR-3: JIT 핸들러는 사용자를 만들지 않고 언어만 갱신(I18N-001 BR-2). 매칭 사용자가 없거나 비활성이면 안내 페이지(“QMS 사용 권한 없음, 담당: 품질경영팀”)로 보낸다.
- BR-4: Salesforce 모바일 앱도 같은 IdP로 로그인(My Domain 로그인 페이지에 SSO 버튼만 노출).

**수용 기준**

- AC-1: Given 포탈 로그인 상태, When Workplace–QMS 클릭, Then 추가 로그인 없이 SL QMS 홈.
- AC-2: Given 미로그인 상태에서 NCR 레코드 링크 클릭, When 포탈 인증 완료, Then 해당 NCR 레코드로 이동.
- AC-3: Given 퇴사자(비활성 User), When SSO, Then 안내 페이지.

**오픈 이슈**: 포탈 IdP 제품·SAML 지원 여부(OIDC만 지원 시 Auth Provider 방식으로 변경), 어설션 속성 목록.

### CMN-00-TDO-003 포탈 To-Do 연계 API

추적 Q-41, P-19, P-63 · 필수 · W1 · SF, MULE · INT, APEX · Customization · 선행 TDO-001, INT-001 · 5 M/D

**목적**: 포탈 메인에 QMS·PMS 업무 건수와 목록을 업무/결재 탭으로 보여준다.

**인터페이스 명세**

| 구분                | 내용                                                                                                                                                                      |
|---------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 방식 1 (필수, Pull) | 포탈 → `GET /exp-portal-todo-api/v1/users/{employeeNo}/todos?category=TASK,APPROVAL&system=QMS,PMS&lang=ko&limit=50`                                                      |
| 방식 2 (선택, Push) | CMN_TodoChanged__e → Mule `prc-todo-sync-api` → 포탈 업무목록 API 호출(포탈이 수신 API를 제공할 때만)                                                                   |
| Salesforce 구현     | Apex REST `/services/apexrest/cmn/v1/todos` (`CMN_TodoRestResource`), 통합 사용자 실행, 사번으로 사용자 조회                                                              |
| 응답                | `{employeeNo, counts:{task, approval, overdue}, items:[{todoId, category, system, title, recordNo, requestedByName, requestedAt, dueDate, isOverdue, isDelegated, url}]}` |
| url                 | Salesforce 레코드 Lightning URL(포탈에서 열면 TDO-002 SSO 경유)                                                                                                           |
| 성능                | p95 1초 이하(사용자당 OPEN 200건 기준). Mule 캐시 60초                                                                                                                    |
| 보안                | Mule Client ID + OAuth 2.0 Client Credentials. 통합 사용자는 CMN_Todo__c Read(View All)만 보유                                                                          |

**비즈니스 규칙**

- BR-1: title은 lang 파라미터 언어로 렌더링(TDO-001 BR-3). lang 미지정 시 사용자 LanguageLocaleKey.
- BR-2: 정렬 = 기한 경과 우선, 이후 DueDate 오름차순, 이후 생성일 내림차순.
- BR-3: 존재하지 않는 사번은 404가 아니라 빈 목록·건수 0을 반환(포탈 메인 오류 방지).

**수용 기준**

- AC-1: Given 업무 3·결재 2, When category=APPROVAL 호출, Then counts.approval = 2, items 2건.
- AC-2: Given lang=zh, When 호출, Then 중국어 title.
- AC-3: 부하 테스트: 동시 500 사용자 호출 시 p95 1초 이하(UAT).

**오픈 이슈**: 포탈 To-Do 연동 표준(포탈이 호출하는 Pull인지, 서브 시스템이 밀어주는 Push인지)과 포탈 측 인증 방식.

### CMN-00-TDO-004 QMS·PMS 메인 홈

추적 Q-41, P-63 · 필수 · W1 · SF · LWC, CFG · Tailoring · 선행 TDO-001, DSH-001 · 3 M/D

**비즈니스 규칙**

- BR-1: `SL QMS`·`SL PMS` 앱 홈 = Lightning App Page. 상단 `cmnTodoList`(탭: 업무 / 결재, 건수 배지, 기한 경과 빨간 표시, 시스템 필터), 하단 `cmnWidgetBoard`(DSH-001).
- BR-2: `cmnTodoList` 항목 클릭 = TargetRecordId 레코드 페이지(결재는 결재 요청 레코드). 한 화면 20건, 더 보기.
- BR-3: 모바일은 To-Do 목록만 표시하고 위젯은 “대시보드” 탭으로 분리.
- BR-4: 화면 유형 T8. 홈은 사내 QMS 앱 세 개(SL QMS 품질 업무, SL QMS, SL QMS 현장)가 같은 페이지를 쓴다(UX-007). SL QMS 현장에서는 위젯 보드를 휴대폰과 같이 숨긴다.

**수용 기준**

- AC-1: Given QMS 업무 3·PMS 업무 2, When SL QMS 홈, Then 기본 필터 QMS로 3건, 필터 전체 시 5건.
- AC-2: Given 홈 진입, When 첫 화면 렌더링, Then To-Do 영역 3초 이내 표시(위젯은 지연 로딩).

### CMN-00-NTF-001 알림 서비스(메일·벨·모바일 푸시)

추적 NFR-4.4(알림), P-17, P-18, P-22, P-23 · 필수 · W0 · SF · DM, APEX · Customization · 선행 ARC-002, I18N-001 · 4 M/D

**목적**: 부적합 발생, 4M 승인 요청, Audit 일정, 결재 요청 등 알림을 받는 사람의 언어로, 업무 WI마다 따로 만들지 않고 한 서비스로 보낸다.

**데이터 모델**

| 객체 / 필드                                                    | 타입     | 필수 | 설명                                                                                         |
|----------------------------------------------------------------|----------|------|----------------------------------------------------------------------------------------------|
| CMN_NotificationRule__mdt.EventCode (DeveloperName)          | —        | Y    | 예: QMS_NCR_CREATED, APV_STEP_PENDING                                                        |
| CMN_NotificationRule__mdt.Channels__c                      | Text(80) | Y    | EMAIL, BELL (쉼표). BELL은 모바일 푸시 포함                                                  |
| CMN_NotificationRule__mdt.SubjectLabel__c / BodyLabel__c | Text(80) | Y    | Custom Label명. 토큰 `{RecordNo}`, `{Title}`, `{Url}`, `{DueDate}`, `{Actor}` 및 업무별 토큰 |
| CMN_NotificationRule__mdt.IsActive__c                      | Checkbox | Y    |                                                                                              |
| Custom Notification Type `CMN_General`                         | 설정     | —    | 벨·푸시 채널                                                                                 |
| Org-Wide Email Address                                         | 설정     | —    | 발신 주소(SL 확인)                                                                           |

**서비스 API**: `CMN_NotificationService.send(String eventCode, Set<Id> recipientUserIds, Id recordId, Map<String,String> params)` — 내부는 Queueable로 비동기 발송.

**비즈니스 규칙**

- BR-1: 수신자별 언어로 제목·본문 라벨을 가져와 토큰을 치환한다(`System.Label.get`).
- BR-2: 사내 사용자 메일은 `setTargetObjectId(userId)` + `setSaveAsActivity(false)`로 보내 일일 외부 메일 한도를 소모하지 않는다. 협력사 포털 사용자도 User Id로 발송.
- BR-3: EventCode가 비활성·미등록이면 아무것도 보내지 않고 WARN 로그.
- BR-4: 발송 실패는 CMN_Logger ERROR로 남기고 업무 트랜잭션을 실패시키지 않는다.
- BR-5: 본문 링크 `{Url}`은 Lightning 레코드 URL. 협력사 수신자는 포털 URL로 변환한다(QMS-03-SPP가 변환 규칙 제공).

**수용 기준**

- AC-1: Given 수신자 2명(ko, en), When send, Then 각자 언어 메일·벨 알림 1건씩.
- AC-2: Given IsActive=false 규칙, When send, Then 발송 0건, WARN 로그 1건.
- AC-3: Given 수신자 300명, When send, Then 거버너 오류 없이 발송(Queueable 분할).

**에이전트 주의**: Email Template(Classic/Lightning)을 업무별로 만들지 않는다. 문구는 Custom Label로만 관리한다(다국어·버전 관리 일원화).

**오픈 이슈**: 사용자별 알림 수신 설정(메일 끄기) 제공 여부. Teams 메시지 알림 채널 필요 여부.

## 11. CMN-00-DOC / DSH / MTG 문서·대시보드·회의

### CMN-00-DOC-001 문서·첨부·리비전 관리

추적 Q-35(리비전), P-34, P-36, P-39, P-45 · 필수 · W0 · SF · DM, APEX, LWC · Customization · 선행 ARC-003, MDM-007, SEC-002 · 7 M/D

**목적**: 8D 보고서, PSW, 관리계획서, 시험 성적서 등 품질 증빙을 “업무 레코드에 붙은 리비전 관리 문서”로 다룬다. VDA 6.3 감사에서 “이 판정 당시 유효했던 문서 버전”을 즉시 제시하는 근거이며, PMS 산출물 5종(일반·표준양식·링크·결재·시스템링크)을 같은 모델로 처리한다.

**데이터 모델**

| 객체 / 필드                                                   | 타입                                                          | 필수          | 설명                                                                     |
|---------------------------------------------------------------|---------------------------------------------------------------|---------------|--------------------------------------------------------------------------|
| CMN_Document__c.ParentRecordId__c / ParentObject__c     | Text(18) / Text(80)                                           | Y             | 소속 업무 레코드(다형)                                                   |
| CMN_Document__c.DocClass__c                               | Lookup(CMN_Code__c, Group `DOC_CLASS`)                      | Y             | 예: 8D_REPORT, PPAP_PSW, CONTROL_PLAN, PFMEA, TEST_REPORT, CERT_SUPPLIER |
| CMN_Document__c.DeliverableType__c                        | Picklist (ATTACHMENT, STD_FORM, LINK, APPROVAL, SYSTEM_LINK)  | Y             | PMS 산출물 유형과 동일                                                   |
| CMN_Document__c.CurrentRevision__c                        | Lookup(CMN_DocumentRevision__c)                             | N             | 최신 RELEASED 리비전                                                     |
| CMN_Document__c.Plant__c                                  | Lookup(CMN_Plant__c)                                        | N             | 공유 기준(부모에서 복사)                                                 |
| CMN_DocumentRevision__c.Document__c                       | Master-Detail                                                 | Y             |                                                                          |
| CMN_DocumentRevision__c.RevisionNo__c                     | Number(4,0)                                                   | Y             | 1부터 자동 증가                                                          |
| CMN_DocumentRevision__c.Status__c                         | Picklist (DRAFT, IN_APPROVAL, RELEASED, SUPERSEDED, REJECTED) | Y             |                                                                          |
| CMN_DocumentRevision__c.StorageType__c                    | Picklist (SF_FILE, SHAREPOINT, PDM, DMS, URL, SF_RECORD)      | Y             |                                                                          |
| CMN_DocumentRevision__c.ContentDocumentId__c              | Text(18)                                                      | SF_FILE이면 Y | Salesforce Files                                                         |
| CMN_DocumentRevision__c.ExternalUrl__c / ExternalKey__c | URL / Text(255)                                               | 외부면 Y      | 외부 저장소 링크·키(도면 번호 등)                                        |
| CMN_DocumentRevision__c.FileName__c / FileSize__c       | Text(255) / Number(12,0)                                      | N             |                                                                          |
| CMN_DocumentRevision__c.FileHash__c                       | Text(64)                                                      | N             | SHA-256. 동일 파일 재사용(타 건 복사) 탐지용                             |
| CMN_DocumentRevision__c.ChangeNote__c                     | Text(1000)                                                    | N             | 작성자 변경 사유                                                         |
| CMN_DocumentRevision__c.AiChangeSummary__c                | Long Text(32768)                                              | N             | AI-003이 채움                                                            |
| CMN_DocumentRevision__c.IndexStatus__c                    | Picklist (PENDING, INDEXED, FAILED, EXCLUDED)                 | Y             | AI-002 검색 색인 상태                                                    |
| CMN_DocTemplate__c                                          | DocClass, Language, ContentDocumentId, Version, IsActive      | —             | 표준 양식(P-36)                                                          |

**비즈니스 규칙**

- BR-1: 같은 부모·같은 DocClass에 파일을 다시 올리면 새 문서가 아니라 새 리비전(RevisionNo + 1)이 된다(Q-35 “동일 문서 등록 시 리비전 관리”).
- BR-2: RELEASED 리비전은 파일·링크 변경 불가. 새 리비전이 RELEASED가 되면 이전 RELEASED는 SUPERSEDED.
- BR-3: DeliverableType = APPROVAL이면 리비전 업로드 후 APV-001 상신(TypeCode `CMN_DOC_RELEASE` 또는 업무 WI 지정 코드), 승인 콜백에서 RELEASED. 그 외 유형은 업로드 즉시 RELEASED.
- BR-4: 파일 크기 50MB 이하 = SF_FILE, 초과 = 업로드 차단 후 외부 저장소 링크 등록 안내(저장 비용 관리). 도면은 PDM 링크만 허용(DocClass 속성 Attribute1 = `LINK_ONLY`).
- BR-5: 업로드 시 서버에서 SHA-256 해시를 계산해 저장한다. 같은 해시가 다른 부모 레코드에 이미 있으면 리비전에 경고 플래그와 원본 레코드 정보를 남긴다(차단하지 않음, Gate·감사의 “복사 문서” 탐지 근거).
- BR-6: CMN_Document__c 공유는 부모 레코드 접근을 따른다(SEC-002 CMN_SharingConfig에 Plant 기준 등록 + 조회 시 UserRecordAccess 확인).
- BR-7: 양식 다운로드는 사용자 언어 → en_US → ko 순으로 CMN_DocTemplate__c를 찾는다.

**화면**: `cmnDocumentPanel`(속성: allowedDocClasses, required DocClass 목록) — DocClass별 최신 리비전, 리비전 이력, 업로드(드래그·다중), 링크 등록, 양식 다운로드, 비교 버튼(AI-003).
- 업무 레코드 표준(UX-004)에서는 결정 지원 레일의 DOCUMENT 패널이다.
- 레일 패널 계약(UX-004 BR-6)을 지킨다: allowedDocClasses·required는 `@api config`로도 받는다.
- `variant="rail"`이면 DocClass별 최신 리비전 목록과 업로드 버튼만 보이고, 리비전 이력은 모달로 연다.
- 필수 문서 누락 수는 `railbadge`로 알린다.

**수용 기준**

- AC-1: Given NCR에 8D_REPORT Rev1 RELEASED, When 같은 클래스 업로드, Then Rev2 생성, Rev2 RELEASED 시 Rev1 SUPERSEDED.
- AC-2: Given RELEASED 리비전, When 파일 교체 시도, Then 차단.
- AC-3: Given 60MB 파일, When 업로드, Then 차단 + 외부 링크 등록 안내.
- AC-4: Given 다른 프로젝트와 같은 해시 파일, When 업로드, Then 경고 플래그와 원본 정보 저장, 업로드는 성공.

**에이전트 주의**: 표준 Files 관련 목록만으로 구현하지 않는다(리비전·상태·DocClass가 없음). 단, 실제 파일 바이너리는 표준 ContentVersion에 저장한다.

**오픈 이슈**: SharePoint를 대용량·통제 문서 저장소로 쓸지(Microsoft 365 연계), Salesforce 파일 저장 용량 증설 예산.

### CMN-00-DSH-001 위젯 대시보드 프레임워크

추적 Q-34, P-55 · 필수 · W1 · SF · DM, LWC, APEX · Customization · 선행 SEC-001, I18N-001 · 7 M/D

**목적**: “지표는 위젯으로 개발, 사용자가 선택·배치, 경영리더/PM/MDT 등 역할별 추천 템플릿” 요구를 QMS·PMS 공통 엔진으로 구현한다. 위젯 콘텐츠는 QMS-07, PMS 대시보드 WI에서 만든다.

**데이터 모델**

| 객체 / 필드                                | 타입                | 필수 | 설명                                                                                                                                                                                                            |
|--------------------------------------------|---------------------|------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| CMN_Widget__mdt                          | Custom Metadata     | —    | WidgetKey(DeveloperName), ComponentName__c(LWC 이름), System__c(QMS/PMS/CMN), Category__c, TitleLabel__c, DescLabel__c, DefaultSize__c(S/M/L), RequiredPermissionSet__c, DefaultConfig__c(JSON) |
| CMN_DashboardTemplate__mdt               | Custom Metadata     | —    | TemplateKey, System__c, Persona__c(EXECUTIVE, PM, MDT, QUALITY_MANAGER, QUALITY_ENGINEER, INSPECTOR, SUPPLIER_QUALITY), TitleLabel__c                                                                     |
| CMN_DashboardTemplateItem__mdt           | Custom Metadata     | —    | Template__c, Widget__c, Order__c, Size__c, Config__c(JSON)                                                                                                                                            |
| CMN_UserDashboard__c.User__c           | Lookup(User)        | Y    |                                                                                                                                                                                                                 |
| CMN_UserDashboard__c.System__c         | Picklist (QMS, PMS) | Y    |                                                                                                                                                                                                                 |
| CMN_UserDashboard__c.LayoutJson__c     | Long Text(32768)    | Y    | `[{widgetKey, size, order, config}]`                                                                                                                                                                            |
| CMN_UserDashboard__c.SourceTemplate__c | Text(80)            | N    | 시작한 템플릿                                                                                                                                                                                                   |

**비즈니스 규칙**

- BR-1: `cmnWidgetBoard`는 Lightning Web Security의 동적 컴포넌트(`lwc:is`)로 ComponentName__c를 로드한다. 12열 그리드: S = 4열, M = 6열, L = 12열. 모바일은 모두 12열.
- BR-2: 위젯 갤러리는 RequiredPermissionSet을 가진 사용자에게만 해당 위젯을 보여준다. 권한을 잃은 위젯은 보드에서 “권한 없음” 자리표시로 남는다.
- BR-3: 사용자 레이아웃이 없으면 사용자 PSG에 맞는 기본 템플릿을 복사해 만든다. “템플릿으로 초기화”로 언제든 되돌린다.
- BR-4: 위젯 계약 — 모든 위젯 LWC는 `@api config`(JSON 객체), `@api size`를 받고, 데이터는 각자 비동기로 가져오며, 실패 시 위젯 내부에 오류 표시(보드 전체를 멈추지 않음). 화면에 보이는 위젯부터 로드(Intersection Observer).
- BR-5: 위젯 데이터 원칙 — 실시간 업무 건수는 Salesforce 집계 SOQL, 추세·통계 지표는 CMN_KpiValue__c(DWH-003이 Snowflake에서 적재)를 읽는다. 위젯에서 Snowflake를 직접 호출하지 않는다.
- BR-6: 공통 필터(공장, 기간)는 보드 상단에서 설정하면 config보다 우선해 모든 위젯에 전달된다.

**수용 기준**

- AC-1: Given 신규 품질팀장, When QMS 홈 첫 진입, Then QUALITY_MANAGER 템플릿 위젯 구성 표시.
- AC-2: Given 편집 모드, When 위젯 추가·순서 변경·크기 변경 후 저장, Then 재로그인 후 동일 배치.
- AC-3: Given 위젯 1개가 예외, When 보드 표시, Then 나머지 위젯 정상 표시.
- AC-4: Given 테스트용 위젯 8개, When 홈 표시, Then 첫 화면 위젯 3초 이내 렌더링(UAT, 해외 공장 포함 측정).

**에이전트 주의**: CRM Analytics(Tableau CRM)·표준 Dashboard 컴포넌트를 프레임워크로 쓰지 않는다. 표준 리포트 차트 임베드는 개별 위젯 안에서만 허용.

### CMN-00-MTG-001 회의 관리

추적 Q-29, P-40 · 권장 · W2 · SF · DM, LWC, APEX · Customization · 선행 TDO-001, NTF-001, DOC-001 · 5 M/D

**목적**: 품질회의·수평전개 회의·Gate 리뷰 등 회의의 공지 → 회의록 → 후속 조치(Follow-up)를 관리한다. 후속 조치가 To-Do로 흘러가야 “회의 후 흐지부지”를 막는다.

**데이터 모델**

| 객체 / 필드                                                | 타입                                                                                                                       | 필수 | 설명                                          |
|------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|------|-----------------------------------------------|
| CMN_Meeting__c.Category__c                             | Lookup(CMN_Code__c, Group `MEETING_TYPE`)                                                                                | Y    | 품질회의, 수평전개, Gate Review, 고객 대응 등 |
| CMN_Meeting__c.IsRegular__c                            | Checkbox                                                                                                                   | Y    | 정기/비정기                                   |
| CMN_Meeting__c.StartAt__c / EndAt__c                 | DateTime                                                                                                                   | Y    |                                               |
| CMN_Meeting__c.Location__c / OnlineUrl__c            | Text(255) / URL                                                                                                            | N    |                                               |
| CMN_Meeting__c.RelatedRecordId__c / RelatedObject__c | Text(18) / Text(80)                                                                                                        | N    | 연관 업무(프로젝트, NCR, Audit 등)            |
| CMN_Meeting__c.Plant__c                                | Lookup(CMN_Plant__c)                                                                                                     | N    |                                               |
| CMN_Meeting__c.Status__c                               | Picklist (SCHEDULED, HELD, MINUTES_DRAFT, MINUTES_CONFIRMED, CANCELLED)                                                    | Y    |                                               |
| CMN_Meeting__c.Minutes__c                              | Rich Text(131072)                                                                                                          | N    | 회의록                                        |
| CMN_MeetingAttendee__c                                   | Meeting(MD), User(Lookup) 또는 ExternalEmail__c, Role__c(CHAIR, REQUIRED, OPTIONAL), Attendance__c                   | —    |                                               |
| CMN_ActionItem__c                                        | Meeting(Lookup, 선택), Description__c, Owner__c, DueDate__c, Status__c(OPEN, DONE, CANCELLED), SourceRecordId__c | —    | 다른 업무에서도 재사용 가능한 공통 조치 항목  |

**비즈니스 규칙**

- BR-1: SCHEDULED 저장 시 참석자에게 NTF 알림 + 일정 파일(.ics) 첨부 메일.
- BR-2: 회의록 확정(MINUTES_CONFIRMED) 시 참석자 전원에게 회의록 링크 알림. 확정 후 회의록 수정 불가(정정은 코멘트).
- BR-3: CMN_ActionItem__c 생성 시 Owner에게 TASK To-Do(SourceType `CMN_ACTION_ITEM`), DONE 시 To-Do 종료. 기한 하루 전·경과 시 알림.
- BR-4: 정기 회의는 반복 규칙(주간/월간) 입력 시 다음 회차 레코드를 회차 종료 후 자동 생성.

**수용 기준**

- AC-1: Given 조치 항목 3건(담당 3명), When 회의록 확정, Then 3명에게 To-Do 각 1건.
- AC-2: Given 확정된 회의록, When 수정, Then 차단.

**오픈 이슈**: Teams 회의 자동 생성·녹취 기반 AI 회의록 초안 필요 여부(필요 시 Microsoft Graph 연계 WI를 W3로 추가).

## 12. CMN-00-INT / DWH 연계·Snowflake

데이터 흐름은 세 방향뿐이다: (1) 원천 시스템 → Mule → Salesforce(기준정보·업무 트리거), (2) 원천·Salesforce → Mule → Snowflake(원천 데이터·이력), (3) Snowflake → Mule → Salesforce(KPI·알람). **PMS와 QMS가 같은 Salesforce Org면 PMS↔QMS 연계는 인터페이스가 아니라 데이터 모델 참조**다. 다른 플랫폼 PMS와의 연계는 QMS-09에서 별도 정의한다.

### CMN-00-INT-001 연계 아키텍처·인터페이스 표준

추적 Q-42, P-64, NFR-4.3(API 제공) · 필수 · W0 · MULE, SF · INT, DM · Customization · 선행 ARC-002, SEC-004 · 6 M/D

**인터페이스 카탈로그(초안)**

| ID          | 원천 → 대상           | 내용                             | 방식·주기                      | 담당 WI |
|-------------|-----------------------|----------------------------------|--------------------------------|---------|
| IF-HR-001   | HR → SF               | 조직·임직원                      | 배치, 매일 01:00 KST + 수동    | INT-002 |
| IF-SAP-001  | SAP → SF, SNOW        | 회사·공장·자재·고객·공급업체     | 배치, 매일 02:00 KST           | INT-003 |
| IF-SAP-002  | SAP → SF              | 입고(GR) → 수입검사 건 생성      | 이벤트 또는 15분               | QMS-09  |
| IF-SAP-003  | SAP → SNOW            | 생산·출하·재고 실적, BOM         | 배치 일 1회                    | QMS-09  |
| IF-MES-001  | MES → SNOW            | SPC 측정값, 검사 결과, 생산 이력 | 마이크로배치 5분               | QMS-09  |
| IF-FC-001   | 필드클레임 → SNOW, SF | 고객 B2B 불량 실적, 필드 클레임  | 배치 일 1회                    | QMS-09  |
| IF-GAU-001  | 측정기 시스템 ↔ SF    | 측정기·교정 이력                 | 배치 일 1회(이관 후 종료 가능) | QMS-09  |
| IF-PTL-001  | 포탈 ↔ SF             | To-Do 건수·목록                  | 실시간 API                     | TDO-003 |
| IF-SF-001   | SF → SNOW             | 업무·마스터 데이터 복제          | 15분 / 일                      | DWH-002 |
| IF-SNOW-001 | SNOW → SF             | KPI 값, 알람 이벤트              | 1분 폴링 / 일                  | DWH-003 |

**데이터 모델**

| 객체 / 필드                                              | 타입                                | 필수 | 설명                                                                                                                      |
|----------------------------------------------------------|-------------------------------------|------|---------------------------------------------------------------------------------------------------------------------------|
| CMN_Interface__mdt                                     | Custom Metadata                     | —    | InterfaceId, Source__c, Target__c, Pattern__c(BATCH, REALTIME, EVENT), Schedule__c, OwnerTeam__c, IsActive__c |
| CMN_InterfaceLog__c.InterfaceId__c                   | Text(20)                            | Y    |                                                                                                                           |
| CMN_InterfaceLog__c.CorrelationId__c                 | Text(64)                            | Y    | Mule `x-correlation-id`                                                                                                   |
| CMN_InterfaceLog__c.Status__c                        | Picklist (SUCCESS, PARTIAL, FAILED) | Y    |                                                                                                                           |
| CMN_InterfaceLog__c.RecordCount__c / ErrorCount__c | Number(10,0)                        | Y    |                                                                                                                           |
| CMN_InterfaceLog__c.StartedAt__c / EndedAt__c      | DateTime                            | Y    |                                                                                                                           |
| CMN_InterfaceLog__c.ErrorSummary__c                  | Long Text(32768)                    | N    | 실패 레코드 키·사유(최대 100건)                                                                                           |

**비즈니스 규칙**

- BR-1: API 계층 — System API(`sys-*`)는 원천 1개당 1개, Process API(`prc-*`)가 변환·조합, Experience API(`exp-*`)는 외부 소비자(포탈) 전용. Salesforce Apex에서 원천 시스템을 직접 호출하지 않는다.
- BR-2: Salesforce 적재는 전부 External ID upsert(멱등). 200건 이하 = Composite API, 초과 = Bulk API 2.0. 통합 사용자는 Salesforce Integration User 라이선스 + `CMN_PS_Integration`.
- BR-3: 실패 시 지수 백오프 3회 재시도 후 Anypoint MQ 데드레터 큐로 보내고 CMN_InterfaceLog__c를 FAILED로 기록, `CMN_PSG_SystemAdmin`에게 NTF 알림.
- BR-4: 모든 배치는 한 실행당 CMN_InterfaceLog__c 1건을 남긴다(Mule이 Salesforce에 기록). 레코드 단위 오류는 ErrorSummary에 요약.
- BR-5: 연계 장애 중에도 Salesforce 업무는 계속된다(RFP 가용성). 연계로 생성될 업무(예: 수입검사 건)는 재처리 시 중복 생성되지 않도록 원천 키를 External ID로 쓴다.

**수용 기준**

- AC-1: Given 동일 배치 2회 재실행, When 적재, Then 레코드 수 변화 없음.
- AC-2: Given Salesforce 점검 시간, When 배치 실행, Then 재시도 후 DLQ 적재, 복구 후 재처리로 정상 반영, 로그 2건(FAILED, SUCCESS).
- AC-3: 인터페이스 모니터링 리스트뷰에서 최근 24시간 FAILED 건을 공장·인터페이스별로 조회할 수 있다.

### CMN-00-INT-002 HR 조직·임직원 연계

추적 Q-42, P-7, NFR-4.2 · 필수 · W0 · MULE, SF · INT, DM · Tailoring · 선행 INT-001, MDM-001 · 5 M/D

**설계 결정**: 임직원 전원을 Salesforce User로 만들지 않는다(라이선스 약 500개). 전 임직원은 CMN_Employee__c로 동기화하고(조직도·CFT 후보 검색·귀책자 지정용), 라이선스 사용자는 관리자가 활성화한다.

**데이터 모델**

| 객체 / 필드                          | 타입                              | 필수  | 설명                   |
|--------------------------------------|-----------------------------------|-------|------------------------|
| CMN_Employee__c.EmployeeNo__c    | Text(20), External ID, Unique     | Y     | 사번                   |
| CMN_Employee__c.Name / NameEn__c | Text(80)                          | Y / N |                        |
| CMN_Employee__c.Email__c         | Email                             | N     |                        |
| CMN_Employee__c.Department__c    | Lookup(CMN_Department__c)       | Y     |                        |
| CMN_Employee__c.JobGradeCode__c  | Text(10)                          | N     |                        |
| CMN_Employee__c.HrStatus__c      | Picklist (ACTIVE, LEAVE, RETIRED) | Y     |                        |
| CMN_Employee__c.User__c          | Lookup(User)                      | N     | 라이선스 사용자면 연결 |

**비즈니스 규칙**

- BR-1: 처리 순서 = 부서 upsert(상위 → 하위) → 임직원 upsert → 연결된 User 필드 갱신(Department__c, JobGradeCode__c, HrStatus__c, Email, FederationIdentifier = 사번).
- BR-2: HrStatus가 RETIRED로 바뀌면 연결 User를 비활성화하고 해당 User의 OPEN To-Do·PENDING 결재 목록을 부서장에게 알린다(업무 이관 필요).
- BR-3: 부서장 변경 시 CMN_Department__c.Manager__c 갱신. 결재 Role(CMN_RoleAssignment__c)은 자동 변경하지 않는다(Role은 업무 지정이므로 관리자 확인).
- BR-4: 임직원 중 성명·사번·부서·직급 외 개인정보(주민번호, 주소, 연락처)는 받지 않는다.

**수용 기준**

- AC-1: Given 퇴사자 1명, When 동기화, Then User 비활성, 부서장 알림 1건.
- AC-2: Given 부서 이동, When 동기화, Then CMN_Employee__c와 User의 Department 동시 갱신.

**오픈 이슈**: HR 시스템 연계 방식(DB View, API, 파일)과 PMS 임율 데이터 제공 범위(PMS Vol.).

### CMN-00-INT-003 SAP 기준정보 연계

추적 Q-42, P-64 · 필수 · W0 · MULE, SF, SNOW · INT · Tailoring · 선행 INT-001, MDM-002~005 · 6 M/D

**비즈니스 규칙**

- BR-1: 대상 — 회사 코드, 플랜트, 자재(자재 유형: 완제품·반제품·구매부품·원재료 중 SL 확인 유형), 자재-플랜트, 고객, 공급업체, 공급업체-자재(구매정보레코드 기준).
- BR-2: S/4HANA 표준 OData API(예: Product, Business Partner) 우선, 없으면 CDS View 기반 커스텀 API. 증분 기준은 변경일시.
- BR-3: Salesforce에는 업무에 필요한 범위만 적재 — 활성 플랜트에 확장된 대상 자재 유형만. 전량은 Snowflake `RAW.SAP_*`에 적재.
- BR-4: 매핑 — 자재 → CMN_Item__c, 자재-플랜트 → CMN_ItemPlant__c, 공급업체 → Account(CMN_Supplier), 고객 → Account(CMN_Customer), 공급업체-자재-플랜트 → CMN_SupplierItem__c(신규 생성 시 InspectionLevel = NORMAL, PpapStatus = NOT_SUBMITTED).
- BR-5: SAP에서 삭제 표시된 자재는 Salesforce에서 삭제하지 않고 CMN_ItemPlant__c.Status__c = PHASE_OUT.

**수용 기준**

- AC-1: Given 신규 공급업체-자재 정보레코드, When 동기화, Then CMN_SupplierItem__c 1건(NORMAL, NOT_SUBMITTED).
- AC-2: Given 자재 삭제 표시, When 동기화, Then 해당 ItemPlant PHASE_OUT, 품번 레코드 유지.

**오픈 이슈**: 대상 자재 유형 코드, SL 뮬소프트 프로젝트(진행 중)의 기존 SAP System API 재사용 범위.

### CMN-00-DWH-001 Snowflake 품질 DW(QDW) 기반

추적 Q-11, 16, 38, 평가 기준 “R&D DW 관점 연계” · 필수 · W0 · SNOW · SQL, CFG · Customization · 선행 ARC-001, SEC-004 · 4 M/D

**구성**

| 구분       | 이름                                                                                            | 기준                                                                                    |
|------------|-------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| 스키마     | RAW                                                                                             | 원천 그대로(JSON은 VARIANT). 컬럼 `_SOURCE`, `_BATCH_ID`, `_LOADED_AT` 필수             |
| 스키마     | STG                                                                                             | 정제·형변환 뷰                                                                          |
| 스키마     | CORE                                                                                            | 통합 모델(SPC_MEASUREMENT, INSPECTION_RESULT, CHARACTERISTIC, ITEM, SF_\* 복제 테이블) |
| 스키마     | MART                                                                                            | 지표·대시보드용(KPI_DAILY 등), Salesforce로 내보낼 뷰                                   |
| 스키마     | ML                                                                                              | 피처·모델 산출물                                                                        |
| 스키마     | SHARE                                                                                           | Salesforce 송출 대기 이벤트(`OUTBOUND_EVENT`)                                           |
| 웨어하우스 | WH_INGEST(XS), WH_TRANSFORM(S), WH_BI(XS), WH_ML(M)                                             | AUTO_SUSPEND 60초                                                                       |
| 역할       | ROLE_INGEST, ROLE_TRANSFORM, ROLE_QMS_ANALYST, ROLE_SF_READER, ROLE_FINANCE_READ, ROLE_DW_ADMIN | 최소 권한                                                                               |
| 비용       | Resource Monitor 월 크레딧 한도, 80%·100% 알림, 100% 시 WH_ML 중지                              | 오브젝트 태그 `SYSTEM=QMS/PMS`                                                          |

**수용 기준**

- AC-1: schemachange V001~V00n으로 DEV에 구성 생성, 같은 스크립트로 TEST 재현.
- AC-2: ROLE_QMS_ANALYST는 RAW 스키마 조회 불가, MART 조회 가능.

**오픈 이슈**: Snowflake 계정 리전(AWS 서울 vs Azure 한국) — Data Cloud Zero Copy 지원 리전과 SL 클라우드 정책 확인. SL이 별도 R&D DW를 보유·계획 중인지.

### CMN-00-DWH-002 Salesforce → Snowflake 복제

추적 Q-38, 39, 42, NFR-4.2(감사 이력 장기 보존) · 필수 · W1 · MULE, SNOW · INT, SQL · Customization · 선행 DWH-001, INT-001 · 5 M/D

**비즈니스 규칙**

- BR-1: 대상 객체·주기는 `CMN_DwhSyncConfig__mdt`(ObjectApiName__c, Frequency__c(15MIN, DAILY), TargetTable__c, IncludeDeleted__c)로만 정한다. 기본: 업무 객체 15분, 마스터 일 1회, Field History·CMN_DeleteLog__c 일 1회.
- BR-2: Mule이 Bulk API 2.0 `queryAll`로 SystemModstamp 증분 추출 → `RAW.SF_{OBJECT}`(VARIANT) 적재 → Snowflake Task가 `CORE.SF_{OBJECT}`에 MERGE(키 = Salesforce Id, 삭제 = `_IS_DELETED` 표시).
- BR-3: 마지막 성공 SystemModstamp를 워터마크로 저장하고, 추출 시 5분 겹침을 둔다(지연 커밋 대응).
- BR-4: 아카이브 — 보존 정책상 Salesforce에서 지울 수 있는 데이터(DONE To-Do 180일, INFO 로그 등)는 CORE 적재 확인 후에만 삭제 배치가 지운다.

**수용 기준**

- AC-1: Given 업무 레코드 수정, When 15분 주기 경과, Then CORE 테이블에 반영.
- AC-2: Given 레코드 삭제, When 다음 주기, Then CORE에서 `_IS_DELETED = TRUE`.

**오픈 이슈**: Data Cloud를 도입하면 Salesforce 데이터를 Data Cloud → Snowflake Zero Copy 공유로 대체할 수 있다. Data Cloud 라이선스 범위 확정 후 BR-2 방식 재결정.

### CMN-00-DWH-003 Snowflake → Salesforce KPI·알람 전달

추적 Q-11, 16, 18, 34, 38 · 필수 · W1 · SNOW, MULE, SF · INT, SQL, APEX, DM · Customization · 선행 DWH-001, INT-001 · 6 M/D

**목적**: 통계·대량 집계 결과는 Snowflake에서 계산하고 Salesforce에는 “화면에 보일 값”과 “업무를 시작시킬 알람”만 보낸다(예: Cpk 1.33 미만 → 부적합 자동 생성, QMS-04).

**데이터 모델**

| 객체 / 필드                                                                                                | 타입                                                                         | 필수  | 설명                                                                |
|------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|-------|---------------------------------------------------------------------|
| CMN_KpiValue__c.KpiKey__c                                                                              | Text(60)                                                                     | Y     | 예: QMS_PPM_CUSTOMER, QMS_CPK, QMS_SUPPLIER_PPM                     |
| CMN_KpiValue__c.PeriodType__c / PeriodStart__c                                                       | Picklist (DAY, WEEK, MONTH) / Date                                           | Y     |                                                                     |
| CMN_KpiValue__c.Plant__c / Line__c / Item__c / Supplier__c / Customer__c / Characteristic__c | Lookup                                                                       | N     | 차원(해당하는 것만)                                                 |
| CMN_KpiValue__c.Value__c / Target__c                                                                 | Number(18,6)                                                                 | Y / N |                                                                     |
| CMN_KpiValue__c.Unit__c                                                                                | Text(20)                                                                     | N     | ppm, %, 건 등                                                       |
| CMN_KpiValue__c.Rag__c                                                                                 | Picklist (GREEN, AMBER, RED)                                                 | N     | Snowflake에서 판정                                                  |
| CMN_KpiValue__c.ExternalKey__c                                                                         | Text(255), External ID, Unique                                               | Y     | KPI·기간·차원 키 해시                                               |
| CMN_ResultInbound__e                                                                                     | Platform Event                                                               | —     | EventType__c, ExternalEventId__c, PayloadJson__c(최대 131072) |
| CMN_InboundRoute__mdt                                                                                    | Custom Metadata                                                              | —     | EventType, HandlerClass__c(`CMN_InboundHandler` 구현)             |
| CMN_InboundReceipt__c                                                                                    | ExternalEventId__c(Unique), EventType, Status, ProcessedAt, ResultRecordId | —     | 멱등 처리 기록                                                      |

**비즈니스 규칙**

- BR-1: KPI — Snowflake `MART.V_SF_KPI_*` 뷰를 Mule이 일 1회(일부 1시간) 읽어 CMN_KpiValue__c에 upsert. 13개월 초과 값은 Salesforce에서 삭제(Snowflake 보존).
- BR-2: 알람 — Snowflake Alert/Task가 조건 충족 시 `SHARE.OUTBOUND_EVENT`(EVENT_ID, EVENT_TYPE, PAYLOAD, STATUS=‘NEW’)에 기록 → Mule 1분 폴링 → Salesforce Platform Event 발행 → 성공 시 STATUS=‘SENT’.
- BR-3: 이벤트 구독 트리거는 CMN_InboundReceipt__c로 ExternalEventId 중복을 거르고 EventType에 맞는 HandlerClass를 실행한다. 미등록 EventType은 Receipt Status = UNROUTED + WARN 로그.
- BR-4: 핸들러 실패 시 Receipt Status = FAILED, 관리자 재처리 버튼으로 다시 실행.

**수용 기준**

- AC-1: Given 같은 EVENT_ID 2회 수신, When 처리, Then 핸들러 1회 실행.
- AC-2: Given 테스트 이벤트 타입 `CMN_TEST`, When OUTBOUND_EVENT에 기록, Then 2분 이내 Receipt PROCESSED.
- AC-3: Given KPI 뷰 1만 행, When 적재, Then Bulk API로 15분 이내 완료.

### CMN-00-DWH-004 상세 데이터 조회 API(드릴다운)

추적 Q-11, 16, 39 · 필수 · W2 · MULE, SNOW, SF · INT, APEX · Customization · 선행 DWH-001, INT-001 · 4 M/D

**목적**: 관리도 상세 점, 검사 측정 원본처럼 Salesforce에 저장하지 않는 데이터를 화면에서 필요할 때만 조회한다.

**비즈니스 규칙**

- BR-1: Salesforce Apex `CMN_DwQueryService.query(queryKey, Map<String,Object> params)` → Named Credential → Mule `prc-dw-query-api` → Snowflake SQL API. 자유 SQL 금지: `CMN_DwQuery__mdt`(QueryKey, SqlTemplate__c, AllowedParams__c, MaxRows__c)에 등록된 바인드 변수 쿼리만 실행.
- BR-2: 사용자 공장 권한 필터를 Apex가 강제로 파라미터에 추가한다(사용자가 접근 불가한 공장 데이터 반환 금지).
- BR-3: MaxRows 기본 5,000. 초과 시 잘라서 반환하고 `truncated = true`.
- BR-4: 응답 p95 3초 이하(WH_BI, 결과 캐시 활용).

**수용 기준**

- AC-1: Given KR01 권한만 있는 사용자, When CN01 파라미터로 조회, Then 결과 0건.
- AC-2: Given 등록되지 않은 QueryKey, When 호출, Then 예외.

**오픈 이슈**: Data Cloud Zero Copy(Snowflake 데이터 연합 조회)로 대체할지 — Data Cloud 도입 시 BR-1 경로를 Data Cloud Query API로 바꿀 수 있다.

## 13. CMN-00-AI AI 공통

AI 요구는 QMS 6개(Q-35~40), PMS 5개(P-58~62)다. 공통 원칙 세 가지: **(1) AI는 추천·초안만 만들고 확정은 사람**, **(2) 사용자가 볼 권한이 없는 데이터는 AI 답변에도 나오지 않는다**, **(3) 모든 추천은 채택/제외와 실제 확정 결과를 기록해 정확도를 측정한다**(Q-36, P-59 “추천 vs 확정 비교” 요구). 여기서 “학습”은 모델 재학습이 아니라 확정 사례를 검색·순위 근거로 재사용하는 것으로 정의한다(평가 시 과장 방지).

### CMN-00-AI-001 Agentforce·Trust Layer 기반 설정

추적 Q-35~40, P-58~62, NFR-4.2 · 권장 · W1 · AF, DC, SF · CFG, AGENT · Tailoring · 선행 SEC-001, I18N-001 · 4 M/D

**비즈니스 규칙**

- BR-1: Agentforce Employee Agent 2개 — `SL Quality Assistant`(SL QMS 앱), `SL Project Assistant`(SL PMS 앱). 공통 Action은 `CMN_AiAction_*` Invocable Apex로 만들고 두 Agent가 공유한다.
- BR-2: Agent는 실행 사용자 권한으로 동작한다(Action Apex는 `with sharing` + `WITH USER_MODE`). 시스템 권한으로 데이터를 읽는 Action 금지.
- BR-3: Einstein Trust Layer — 외부 LLM 제로 데이터 보존, 프롬프트 PII 마스킹 활성, 감사 로그(Audit Trail) 활성.
- BR-4: 응답 언어 = 사용자 LanguageLocaleKey. 모든 생성 결과에 출처(레코드 번호·문서명·리비전) 표시, 출처 없는 사실 진술 금지(프롬프트 템플릿 공통 지시문).
- BR-5: 기능별 on/off는 CMN_FeatureSwitch(ARC-002)로 제어(키 예: `CMN_AI_DOCSEARCH`, `QMS_AI_RCA`).
- BR-6: AI 사용량(크레딧) 월별 리포트 — 기능별·공장별 호출 수를 CMN_AiRecommendation__c와 Agent 세션 로그로 집계.

**수용 기준**

- AC-1: Given KR01 권한 사용자, When Agent에게 CN01 부적합 질문, Then 데이터 없음 응답.
- AC-2: Given 영어 사용자, When 한국어 데이터 기반 질문, Then 영어 응답 + 출처 표시.

**오픈 이슈**: Agentforce·Data Cloud 라이선스 구조(Flex Credit 단가, Data Cloud 크레딧)와 중국 공장 사용자 대상 LLM 호출 허용 여부.

### CMN-00-AI-002 문서 통합 검색·요약

추적 Q-35, P-58, P-69 · 필수(P-69)/권장(Q-35) · W2 · DC, AF, MULE, SF · AGENT, INT, LWC · Customization · 선행 AI-001, DOC-001 · 8 M/D

**목적**: “작년 BMW 렌즈 흐림 8D에서 쓴 대책”처럼 문서 내용으로 찾고 요약을 받는다. PMS 통합 검색(P-69: 프로젝트 정보 + 산출물 내용)을 같은 엔진으로 충족한다.

**비즈니스 규칙**

- BR-1: 색인 파이프라인 — 리비전이 RELEASED가 되면 IndexStatus = PENDING → Mule이 파일을 색인용 객체 스토리지로 복사하고 메타데이터(DocumentRevisionId, ParentRecordId, ParentObject, Plant, DocClass, Language, RevisionNo)를 함께 저장 → Data Cloud 비정형 데이터(UDLO) + 하이브리드 검색 인덱스 갱신 → INDEXED. SUPERSEDED 리비전은 기본 검색에서 제외(필터 옵션으로 포함).
- BR-2: 권한 필터 — 검색 결과(청크)의 ParentRecordId에 대해 Apex가 `UserRecordAccess`로 접근 가능 여부를 확인한 후에만 사용자·LLM에 전달한다. 인덱스 메타데이터 필터(Plant)는 1차, Apex 확인이 최종.
- BR-3: 화면 `cmnUnifiedSearch` — 입력 1개로 (a) 레코드 검색(SOSL: 번호·제목·품번) (b) 문서 의미 검색을 동시에 수행, 상단에 AI 요약(상위 5개 문서 근거, 출처 링크), 하단에 레코드·문서 결과 목록.
- BR-4: 지원 형식 — PDF(텍스트), DOCX, XLSX, PPTX. 스캔 PDF·이미지는 OCR 여부 오픈 이슈, 미지원 시 EXCLUDED.

**수용 기준**

- AC-1: Given 검증용 문서 30건과 질문 20개 정답셋, When 검색, Then 상위 5건 내 정답 문서 포함률 80% 이상.
- AC-2: Given 사용자 접근 불가 NCR에 속한 문서, When 관련 질문, Then 결과·요약 모두에 미포함.
- AC-3: Given 리비전 RELEASED, When 30분 경과, Then IndexStatus = INDEXED.

**오픈 이슈**: 색인 엔진 대안 — Snowflake Cortex Search(PARSE_DOCUMENT + Cortex Search Service)를 쓰면 Data Cloud 없이 구현 가능. Data Cloud 도입 범위 결정 후 확정. 스캔 문서 OCR 필요 여부.

### CMN-00-AI-003 문서 버전 비교·변경 요약

추적 Q-35, P-39, P-58 · 권장 · W2 · AF, SF · AGENT, APEX, LWC · Customization · 선행 AI-002 · 4 M/D

**비즈니스 규칙**

- BR-1: `cmnDocumentPanel`의 비교 버튼에서 두 리비전을 고르면, 색인 단계에서 추출한 텍스트를 섹션 단위로 정렬해 추가·삭제·변경 목록을 만든 뒤 LLM이 사용자 언어로 3~10줄 요약한다.
- BR-2: 결과는 `AiChangeSummary__c`(신규 리비전)에 저장하고 “AI 생성” 표시. 사용자가 수정·확정하면 ChangeNote__c에 반영.
- BR-3: 표 형식 문서(관리계획서·검사기준서 XLSX)는 셀 단위 비교 결과(행 키 = 특성 번호)를 표로 함께 보여준다.
- BR-4: 추출 텍스트가 없는 리비전(스캔, CAD)은 “비교 불가”를 표시하고 LLM을 호출하지 않는다.

**수용 기준**

- AC-1: Given 관리계획서 Rev1→Rev2에서 특성 3개 규격 변경, When 비교, Then 3개 변경이 표와 요약에 모두 나타난다.
- AC-2: Given 스캔 PDF 리비전, When 비교, Then 비교 불가 메시지, AI 호출 0회.

### CMN-00-AI-004 AI 추천 기록·채택·정확도 측정

추적 Q-36, Q-37, Q-40, P-59 · 권장(Q-40은 필수) · W1 · SF, SNOW · DM, APEX, LWC · Customization · 선행 AI-001, DWH-002 · 5 M/D

**목적**: Root Cause 추천, 8D 대책 추천, LELE 추천, 일정 추천이 같은 구조로 “무엇을 추천했고, 사용자가 무엇을 채택했고, 최종 확정은 무엇이었나”를 남긴다. RFP의 “추천 vs 확정 비교로 정확도 향상” 요구의 측정 근거다.

**데이터 모델**

| 객체 / 필드                                                       | 타입                                                                                                      | 필수         | 설명                                             |
|-------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|--------------|--------------------------------------------------|
| CMN_AiRecommendation__c.UseCase__c                            | Picklist (QMS_RCA, QMS_CAPA, QMS_8D_DRAFT, QMS_LELE, QMS_EW, PMS_SCHEDULE, PMS_DELIVERABLE_DRAFT, PMS_EW) | Y            |                                                  |
| CMN_AiRecommendation__c.SourceRecordId__c / SourceObject__c | Text(18) / Text(80)                                                                                       | Y            | 추천 대상 업무 레코드                            |
| CMN_AiRecommendation__c.Rank__c                               | Number(3,0)                                                                                               | Y            | 추천 순위                                        |
| CMN_AiRecommendation__c.ContentJson__c                        | Long Text(32768)                                                                                          | Y            | 추천 내용(구조화)                                |
| CMN_AiRecommendation__c.Rationale__c                          | Long Text(32768)                                                                                          | N            | 근거 설명                                        |
| CMN_AiRecommendation__c.SourceRefs__c                         | Long Text(32768)                                                                                          | N            | 근거 레코드·문서 Id 목록(JSON)                   |
| CMN_AiRecommendation__c.Score__c                              | Number(5,4)                                                                                               | N            | 유사도·신뢰 점수                                 |
| CMN_AiRecommendation__c.PromptVersion__c / ModelInfo__c     | Text(40) / Text(80)                                                                                       | Y            | 재현성                                           |
| CMN_AiRecommendation__c.Status__c                             | Picklist (PROPOSED, ADOPTED, MODIFIED, EXCLUDED, EXPIRED)                                                 | Y            |                                                  |
| CMN_AiRecommendation__c.ExcludeReason__c                      | Lookup(CMN_Code__c, Group `AI_EXCLUDE_REASON`)                                                          | EXCLUDED면 Y | 관련 없음, 이미 검토됨, 근거 부족 등             |
| CMN_AiRecommendation__c.DecidedBy__c / DecidedAt__c         | Lookup(User) / DateTime                                                                                   | N            |                                                  |
| CMN_AiRecommendation__c.FinalOutcomeJson__c                   | Long Text(32768)                                                                                          | N            | 업무 확정 시 실제 결과(예: 확정 Root Cause 코드) |
| CMN_AiRecommendation__c.IsHit__c                              | Checkbox                                                                                                  | N            | 확정 결과와 일치 여부(업무 WI가 일치 규칙 제공)  |

**비즈니스 규칙**

- BR-1: 서비스 `CMN_AiRecommendationService.record(useCase, sourceId, List<Rec>)`, `decide(recId, status, reasonCode)`, `finalize(sourceId, useCase, outcomeJson, CMN_AiHitRule rule)`. 일치 규칙(`CMN_AiHitRule`)은 업무 WI가 구현(예: RCA는 원인 코드 3레벨 일치).
- BR-2: 같은 대상에 재추천하면 이전 PROPOSED는 EXPIRED.
- BR-3: 공통 LWC `cmnAiRecommendationList` — 순위·근거·출처 링크 표시, 채택/수정 채택/제외(사유 필수) 버튼.
  - 업무 레코드 표준(UX-004)에서는 결정 지원 레일의 AI 패널(기본 펼침)이다.
  - 레일 패널 계약(UX-004 BR-6)을 지킨다: UseCase는 `@api config`로 받는다. `variant="rail"`이면 카드 3개까지 보이고 나머지는 "더 보기"로 연다.
  - 새 추천(PROPOSED) 수는 `railbadge`로 알린다.
  - AI 결과를 본문 필드에 직접 쓰지 않는다. 채택하면 업무 WI의 서비스가 반영한다.
- BR-4: 정확도 KPI — Snowflake에서 UseCase·월·공장별 Top-1·Top-3 적중률, 채택률을 계산해 CMN_KpiValue__c(`AI_HIT_TOP1`, `AI_HIT_TOP3`, `AI_ADOPT_RATE`)로 전달(DWH-003).
- BR-5: 확정(IsHit 평가 완료)된 사례는 해당 UseCase 검색 소스의 “검증된 사례”로 가중치를 높인다(가중치 규칙은 각 UseCase WI가 정의).

**수용 기준**

- AC-1: Given 추천 3건 중 2위 채택, When 업무 확정 결과 = 2위 내용, Then 2위 IsHit = true, Top-1 미적중·Top-3 적중으로 집계.
- AC-2: Given 제외 사유 없이 제외, When 저장, Then 차단.

### CMN-00-AI-005 자연어 데이터 Q&A 프레임워크

추적 Q-39, P-62 · 권장 · W2 · AF, SNOW, MULE, SF · AGENT, SQL, APEX · Customization · 선행 AI-001, DWH-003, DWH-004 · 6 M/D

**목적**: “최근 6개월 주요 불량은?”, “향후 1개월 내 리스크 프로젝트는?” 같은 질문에 숫자로 답한다. 이 WI는 엔진과 규칙만 만들고, QMS 질문 범위(Action·시맨틱 모델)는 QMS-08, PMS 범위는 PMS Vol.에서 채운다.

**비즈니스 규칙**

- BR-1: 두 경로 — (a) 업무 현황(진행 중 건수, 내 담당, 기한 경과)은 Salesforce 미리 정의된 파라미터형 Action(`CMN_AiAction_QueryRecords` 계열)으로 답한다. LLM이 SOQL을 직접 생성하지 않는다. (b) 추세·통계(기간별 불량률, 협력사 PPM)는 Snowflake Cortex Analyst + 시맨틱 모델(YAML, MART 뷰 기준)로 답하며 DWH-004 경로로 호출, 사용자 공장 권한 필터를 강제한다.
- BR-2: 답변 형식 = 결론 1문장 + 핵심 수치 표(최대 10행) + 데이터 기준 시각 + 상세 보기 링크(리스트뷰·리포트).
- BR-3: 범위 밖 질문·권한 밖 데이터는 “답할 수 없음”과 이유를 답한다. 추측 수치 금지.
- BR-4: 평가셋 — 시스템별 골든 질문 50개(질문, 기대 SQL/Action, 기대 값)를 저장소 `docs/ai/eval/`에 두고, 배포 전 자동 평가에서 정답률 85% 미만이면 배포 차단.

**수용 기준**

- AC-1: 골든 질문 평가 정답률 85% 이상.
- AC-2: Given KR01 권한 사용자, When 전사 불량 추세 질문, Then KR01 데이터만으로 답하고 범위 제한을 명시.

**에이전트 주의**: Q&A에서 데이터 변경(레코드 생성·수정) Action을 연결하지 않는다. 조회 전용.

## 14. 검토 요청

Vol.0 공통 메뉴는 **50개 워크아이템, 개발 공수 약 233 M/D**(AI 코딩 보조 기준, 분석·통합테스트 제외)다. W0 28개는 QMS·PMS 어느 메뉴든 착수 전에 끝나야 하는 기반이다. 2026-11-05 화면 전략(`screen-strategy.md`)에 따라 공통 화면 부품 UX-004~009 6개(35 M/D)를 더했다.

| 기능코드            | WI 수 | 공수(M/D) | W0  | W1  | W2  |
|---------------------|-------|-----------|-----|-----|-----|
| ARC 개발 기반       | 3     | 12        | 3   | 0   | 0   |
| MDM 기준정보        | 7     | 19        | 7   | 0   | 0   |
| SEC 권한·보안       | 4     | 16        | 4   | 0   | 0   |
| I18N·UX 다국어·화면 | 10    | 51        | 4   | 5   | 1   |
| QNR 질문지 템플릿    | 1     | 7         | 0   | 1   | 0   |
| APV 결재            | 5     | 26        | 2   | 2   | 1   |
| TDO·NTF To-Do·알림  | 5     | 20        | 3   | 2   | 0   |
| DOC·DSH·MTG         | 3     | 19        | 1   | 1   | 1   |
| INT·DWH 연계·DW     | 7     | 36        | 4   | 2   | 1   |
| AI 공통             | 5     | 27        | 0   | 2   | 3   |
| 합계                | 50    | 233       | 28  | 15  | 7   |

**검토 시 결정이 필요한 항목** (결정 결과에 따라 해당 WI의 BR을 고친 뒤 마스터 파일로 이관한다)

- [ ] D-1 PMS·QMS 단일 Salesforce Org 확정 — 전제가 바뀌면 INT·DWH와 QMS-09 PMS 연계 설계가 달라짐
- [ ] D-2 표준 Approval Process 대신 공통 결재 엔진(APV) 개발 승인 — Fit-Gap에 Customization으로 표기
- [ ] D-3 Multi-Currency 활성화 여부(ARC-001) — 활성 후 되돌릴 수 없음
- [ ] D-4 Data Cloud 도입 범위 — DWH-002(복제 방식), DWH-004(드릴다운), AI-002(검색 엔진)를 함께 결정
- [ ] D-5 협력사 포털 라이선스(Partner vs Customer Community Plus) — SEC-002 BR-4
- [ ] D-6 Shield(Platform Encryption, Field Audit Trail) 구매 범위 — SEC-003, SEC-004
- [ ] D-7 대용량·통제 문서 저장소(SharePoint 연계 여부) — DOC-001
- [ ] D-8 임직원 전원 CMN_Employee__c 동기화 + 라이선스 사용자만 User 생성 방식 — INT-002
- [ ] D-9 공장 데이터 격리 수준: 해외 공장 사용자의 타 공장 조회 전면 차단이 맞는지 — SEC-002
- [ ] D-10 AI “학습”의 정의(재학습이 아닌 확정 사례 재사용)를 제안서 표현으로 수용하는지 — AI-004
- [ ] D-11 표준 질문지(VDA 6.3·IATF 심사, 고객·SL Gate 평가표)를 판째 받아 공통 버전 템플릿(QNR-001)으로 관리하고 QMS 심사·PMS Gate가 같이 쓴다(2026-11-06 검토, 권고: 승인 — Vol.6c IAU-001 질문지 객체를 CMN으로 이관)

**화면 전략 결정**(`screen-strategy.md` 13절. 자율 진행 지시에 따라 권고안으로 반영·개발하고 검토 때 확정)

- [ ] DS-1 사용자 두 계층 앱 구조(품질 업무 / 참여자 / 현장 / 포털 / 관리) — SEC-001 BR-4, UX-007. 권고: 승인(반영함)
- [ ] DS-2 Cosmos(SLDS 2) 기준 개발, 협력사 포털만 SLDS 1 기준 검수 — 3.4절, UX-004 BR-10. 권고: 승인(반영함)
- [ ] DS-3 공통 화면 WI 6개(UX-004~009, 35 M/D) 추가와 Vol.2 공수 조정(DVQ-004 7→4, DVQ-007 7→5) — 권고: 승인(반영함)
- [ ] DS-4 트리 메뉴 대신 메뉴 허브 + 앱당 8개 이내 내비게이션 — UX-007. 권고: 승인(반영함)
- [ ] DS-5 현장 오프라인 입력 범위(브라우저 임시 저장만 / 완전 오프라인) — UX-008 BR-5. 권고: 브라우저 임시 저장만
- [ ] DS-6 VDA 6.3 질문지 원문 라이선스 확보 주체(SL / DKBMC) — Vol.6c D6C-2와 같은 결정. 권고: SL
- [x] DS-7 Lightning Console 권한 집합 라이선스 — UX-007 BR-9. 결정(2026-11-05, 사용자): 사용하지 않는다. 모든 앱 표준 내비게이션
- [ ] DS-8 여러 고객 클레임 병합(대표 클레임 + 8D 1개) 기능 추가 — Vol.5 CLM 변경 요청. 권고: 추가(W2)

**SL 확인이 필요한 사실 정보**: 포탈 IdP·SAML 속성과 To-Do 연동 방식(Pull/Push), HR 연계 방식, SAP 자재 유형 코드, 현행 업무 번호 체계, OEM별 CSR(클레임 기한·양식), 관리계획서 원천 도구, Snowflake 리전.

**검토 방법**: 워크아이템 제목이나 BR·AC 문장에 코멘트를 달거나 직접 수정해 주세요. 승인된 WI는 마스터 워크아이템 파일(xlsx)에 L1 시스템 / L2 메뉴 / L3 기능 / L4 워크아이템과 유형·플랫폼·Wave·Fit-Gap·공수·선행 WI·RFP 추적 열로 정리하고, 이어서 Vol.2 QMS-02 개발 품질(부품·제품 인정시험)을 작성한다.
