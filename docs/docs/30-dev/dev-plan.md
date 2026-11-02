# SL QMS 개발 플랜 — Scratch Org 기반 WI 구현

기준일 2026-11-01 · 대상 WI 227건(1,162 M/D) · 상태: 초안(사용자 검토 대기)

> **개발 전략 변경(2026-11-02)**: [개발 중단점 p1](checkpoint-p1.md) 이후에는 [화면 우선 개발 플랜](screen-first-plan.md)을 따른다. 남은 WI는 A단계(전 메뉴 1차 화면 — Salesforce 표준 화면과 커스텀 화면) → R1(화면 검토·승인, 개발 중단) → B단계(상세 기능) 순서로 개발한다. 이 문서의 환경·브랜치·검증·목 전략은 그대로 쓰고, 페이즈(P3 잔여~P13)와 페이즈 문서는 B단계의 순서·게이트로 쓴다.

## 1. 목적과 읽는 법

이 문서는 Vol.0~9 워크아이템을 **어떤 순서로, 어떤 환경에서, 무엇으로 검증하며** Scratch Org에 개발할지 정한다. WI 1건을 구현하는 절차는 `/implement-wi`, 코드 규칙은 `.claude/rules/sf-dev.md`, 진행 기록은 `docs/docs/20-status/DEV-STATUS.md`가 맡는다. 이 플랜은 순서·환경·검증만 정하며, WI 명세와 다르면 명세가 이긴다(우선순위: WI 명세 → `interfaces.md` → Vol.0 3.2·3.3 → `sf-dev.md` → 이 플랜).

| 파일 | 내용 | 누가 고치나 |
| --- | --- | --- |
| `dev-plan.md`(이 문서) | 원칙, 환경, 페이즈 개요, 일정, 명세 이슈, 위험 | 사람. 표시된 구간은 스크립트 |
| `phase-map.csv` | WI → 페이즈·레인 배정, 선행 보정(추가·제외), 비고 | 사람 |
| `p00-setup.md` ~ `p13-advanced-stabilization.md` | 페이즈별 목표, WI 착수 순서, Scratch Org 준비, 목, 데모 데이터, 게이트, 결정 | 사람. WI 표는 스크립트 |
| `docs/scripts/build_dev_plan.py` | 배정표 검사(누락·순환·선행 위반)와 표 재생성 | — |

배정을 바꾸면 `phase-map.csv`만 고치고 `cd docs && python3 scripts/build_dev_plan.py`를 실행한다. 선행을 어기는 배정이 있으면 스크립트가 문서를 고치지 않고 실패한다. 각 문서의 `<!-- BEGIN:… -->` ~ `<!-- END:… -->` 구간은 손으로 고치지 않는다.

## 2. 현재 상태 진단(2026-11-01)

| 항목 | 현재 | 플랜의 조치 |
| --- | --- | --- |
| 명세 검토 | 227건 전부 `검토 대기`(승인 0). `/implement-wi`는 승인되지 않은 WI마다 계속할지 묻는다 | 페이즈 착수 전 해당 페이즈 WI 승인(3.6절) |
| 명세 정합 | 선행 순환 1건, Wave 역전 41건, 소유 WI가 없는 공통 요소 2건, 선행 누락 1건, 공통 WI AC가 아직 없는 QMS 객체를 예로 든 것 10여 건 | 10절 변경 요청 CR-1~CR-12 |
| 소스 | `force-app/main`만 있고 비어 있음. `sfdx-project.json` 패키지 디렉터리 1개 | P0에서 ARC-001 구조(`force-app-cmn`·`force-app-qms`·`force-app-pms`)로 바꿈 |
| 도구 | sf CLI 2.136.8(2.156.8 업데이트 가능), Node 24, npm 의존성 미설치(`node_modules` 없음, husky 훅 비활성), Code Analyzer 플러그인 미설치, `code-analyzer.yml`·CI 없음 | P0 |
| Dev Hub | `LSPMSQMS`(기본), `myDevHub` 2개. 둘 다 활성 Scratch Org 최대 3개, 하루 생성 6개 | 5.2절 배분 |
| Scratch Org | `scratchOrg`(Developer, 2026-11-01 생성, **2026-12-01 만료**, API 68.0). 기본 대상 Org | P0 스파이크·개발에 쓰고 만료 전 `qms-int`로 교체 |
| 정의 파일 | `features`가 `EnableSetPasswordInApi`뿐. Translation Workbench·Experience Cloud·Agentforce 미설정 | 5.3절 제안안을 P0에서 검증 |
| API 버전 | `sourceApiVersion` 66.0, Scratch Org 68.0 | P0 결정(운영 Org 릴리즈 기준) |
| 데모 데이터 | 생성 완료(기준일 2026-12-01 고정). 로더는 전체 메타데이터 배포를 전제로 하며, 아직 없는 객체를 가리키는 토큰을 만나면 조회 오류로 멈춘다. 출하검사·수평전개·스코어카드 등 일부 업무와 AI 기대값 5종은 데이터가 없다 | P0에서 단계 적재·기준일 지정 보강, 공백은 데이터 작업에 요청(8절) |
| Git | `main`에 커밋 2개, 원격(`baechan9/SLPMSQMS`, 공개) 미push | 6절 브랜치·CI. 공개 저장소의 시크릿 주의 |

## 3. 개발 원칙

### 3.1 순서는 선행 관계가 정한다

Wave는 업무 우선순위이고 개발 순서가 아니다. W1 WI 41건이 W2 WI를 선행으로 요구하므로(부록 B), Wave 순서대로 착수하면 막힌다. 이 플랜은 모든 WI를 선행 관계로 정렬한 뒤 업무 묶음과 PoC 시나리오 기준으로 14개 페이즈에 나눴다. 배정 결과 선행이 뒤 페이즈에 있는 WI는 0건이다(스크립트 검사). DEV-STATUS의 "Wave 순서로 착수" 원칙은 P0에서 이 플랜을 가리키도록 고친다.

### 3.2 페이즈는 착수 장벽이 아니라 검증 단위다

- 페이즈 N+1의 WI는 **선행 WI가 모두 `개발 완료`이면** 페이즈 N 게이트 전에도 착수할 수 있다. 다만 한 페이즈 앞까지만 당겨 착수한다(N+2는 기다린다).
- 예외: W0 공통 기반(P1·P2)이 끝나기 전에는 QMS WI를 착수하지 않는다(DEV-STATUS 기존 원칙 유지).
- 근거: 페이즈를 엄격한 장벽으로 두면 4명 이상부터 병렬 효과가 거의 사라진다(4명 기준 376영업일 대 한 페이즈 앞 착수 296영업일, 9절).
- 페이즈 게이트(6.4절)는 새 Scratch Org에서 처음부터 재현해 그 페이즈의 시나리오를 확인하는 마일스톤이다.

### 3.3 Scratch Org는 일회용이다

Scratch Org는 최대 30일 뒤 사라진다. 기능·설정은 전부 메타데이터와 스크립트로 저장소에 두고, 자동화할 수 없는 설정은 수동 설정 목록(5.6절)에 단계와 함께 남긴다. Org에서 손으로 바꾼 설정을 원본으로 삼지 않는다.

### 3.4 플랫폼 트랙을 나눈다

- **SF 트랙**(215건): 플랫폼에 SF·EXP·AF·DC가 하나라도 있는 WI. Scratch Org에서 메타데이터·Apex·LWC를 개발한다. Snowflake·Mule 부분은 목과 시뮬레이션으로 대체한다(7절).
- **외부 트랙**(12건, 62 M/D): 플랫폼이 SNOW·MULE뿐인 WI. Scratch Org 산출물이 없다. Snowflake `SL_QDW_DEV`와 Mule DEV에서 별도 인력이 개발하고, SF 트랙은 그 WI의 계약(테이블·쿼리 키·이벤트·KPI 키)만 보고 진행한다.

### 3.5 다른 메뉴는 계약으로만 만난다

아직 배포되지 않은 메뉴의 객체는 Lookup하지 않고, 업무 요청은 게이트웨이(`QMS_GatewayFactory.get(바인딩 키)`), 사실 통지는 Platform Event, 원천 연결은 `SourceRecordId__c`로 한다(`interfaces.md` 1절). 그래서 소유 메뉴가 없는 페이즈에서도 호출 측은 기본 구현(담당자 To-Do)으로 동작을 확인할 수 있다. 소유 메뉴 페이즈에서 바인딩을 등록하면 실제 구현으로 바뀐다.

### 3.6 승인된 명세만 착수한다

- 페이즈 착수 전에 그 페이즈 WI의 검토를 끝내고 `workitem-index.csv` 상태를 `승인`으로 바꾼다. 검토는 페이즈 순서(Vol.0 → Vol.2·3 → …)로 하면 착수와 겹치지 않는다.
- 승인 전에 착수해야 하면 사용자 확인을 받고, 완료 보고서에 "검토 전 명세"라고 적는다.
- 각 페이즈 문서의 "선결 결정"(review-pack의 결정 항목)과 "명세 보강"(데모 데이터 변경 요청 등)을 착수 전에 처리한다. 처리하지 않은 채 착수하면 데모 적재가 실패하거나 다시 만들어야 한다.

### 3.7 WI 1건 = 브랜치 1개 = PR 1개

WI 범위 밖 파일을 고치지 않는다(`sf-dev.md` 2절). 범위 밖 수정이 필요하면 해당 WI의 변경 요청으로 올리고, 이 플랜의 CR 목록이나 페이즈 문서의 "명세 보강"에 추가한다.

## 4. 페이즈 개요

<!-- BEGIN:PHASE-SUMMARY -->
| 페이즈 | 이름 | WI | M/D | Wave 구성 | SF 트랙 | 외부 트랙 | 마일스톤 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P0 | [착수 준비](p00-setup.md) | 1 | 4 | W0 1 | 1 | 0 | 정의 파일·재현 스크립트·CI 동작 |
| P1 | [공통 프레임워크·기준정보](p01-cmn-framework-master.md) | 12 | 39 | W0 12 | 12 | 0 | 기준정보 데모 적재, 다국어 표시 |
| P2 | [보안·공통 업무 서비스·연계 기반](p02-cmn-security-services.md) | 13 | 68 | W0 13 | 12 | 1 | 공장 격리, 결재·To-Do·알림·문서 서비스 |
| P3 | [공통 확장·QMS 연계 공통](p03-cmn-extension.md) | 16 | 74 | W1 13 · W2 3 | 15 | 1 | 결재 UI·위임, KPI 수신, 위젯 보드 |
| P4 | [인정시험·협력사 포털·수입검사·PPAP](p04-dvq-supplier-iqc-ppap.md) | 22 | 124 | W1 21 · W2 1 | 21 | 1 | S9 수입검사, S3 앞부분(시험·PPAP) |
| P5 | [8D 엔진·부적합·고객 클레임](p05-8d-ncr-claim.md) | 19 | 110 | W1 19 | 19 | 0 | S1 NCR(AI 제외), S2 핵심 |
| P6 | [4M 변경·초기안정화·부품 확장](p06-4m-stabilization.md) | 24 | 124 | W1 8 · W2 16 | 22 | 2 | S3 4M 완성(Salesforce 부분) |
| P7 | [SPC·레슨런·대시보드 공용 라이브러리](p07-spc-lele-dashboard-lib.md) | 16 | 87 | W1 14 · W2 2 | 15 | 1 | S7 SPC, S6 규칙 매칭 |
| P8 | [출하검사·초기유동·수평전개·고객 B2B](p08-fqc-efc-hzd-b2b.md) | 23 | 122 | W1 8 · W2 15 | 20 | 3 | S10 B2B, S13 EOL·출하 |
| P9 | [심사·인증·협력사 실적·개선 과제](p09-audit-supplier-improvement.md) | 21 | 112 | W1 8 · W2 13 | 21 | 0 | S4 VDA 6.3 |
| P10 | [측정기·MSA·교육·분석실·한도견본](p10-gauge-msa-training-lab.md) | 23 | 115 | W2 23 | 23 | 0 | S8 MSA, S12 교정 불합격, S2 분석 |
| P11 | [품질 위젯·대시보드](p11-dashboard-widgets.md) | 12 | 50 | W1 7 · W2 5 | 12 | 0 | S5 대시보드(질문은 대체 경로) |
| P12 | [품질 AI](p12-quality-ai.md) | 18 | 104 | W1 10 · W2 8 | 15 | 3 | S1·S2·S5·S6 AI 완성 |
| P13 | [고도화·통합 안정화](p13-advanced-stabilization.md) | 7 | 29 | W2 1 · W3 6 | 7 | 0 | 전 시나리오 회귀, SIT 이관 준비 |
| 합계 | | 227 | 1162 | | | | |
<!-- END:PHASE-SUMMARY -->

**단계 묶음**: 기반(P0~P3) → 핵심 업무(P4~P8) → 운영 지원(P9~P10) → 분석·AI(P11~P12) → 고도화(P13).

**레인**: 각 페이즈의 WI는 레인(A~D)으로 나눴다. 레인은 병렬로 진행할 수 있는 작업 흐름이며, 개발자(또는 에이전트) 1명이 레인 1개를 맡는 것을 기준으로 했다. 레인 X는 외부 트랙(Snowflake·Mule) WI다. 레인이 달라도 "이 페이즈 안 선행"에 적힌 WI는 기다려야 한다.

**임계 경로**: 공수 합이 가장 긴 선행 사슬이다. 이 사슬의 WI는 각 페이즈에서 가장 먼저 착수한다.

<!-- BEGIN:CRITICAL-PATH -->
공수 합 108 M/D, 21건. 인원을 늘려도 이 사슬보다 짧아지지 않는다.

| 순서 | WI | 제목 | 페이즈 | M/D |
| --- | --- | --- | --- | --- |
| 1 | CMN-00-ARC-001 | 개발 환경·저장소·CI/CD 표준 | P0 | 4 |
| 2 | CMN-00-MDM-002 | 법인·공장·라인·공정 계층 | P1 | 3 |
| 3 | CMN-00-MDM-003 | 고객·차종 | P1 | 2 |
| 4 | CMN-00-MDM-004 | 제품군·품번(Item) | P1 | 3 |
| 5 | CMN-00-MDM-005 | 협력사·협력사 품번 | P1 | 2 |
| 6 | CMN-00-SEC-002 | 공장·협력사 데이터 격리(공유 모델) | P2 | 6 |
| 7 | CMN-00-APV-001 | 결재 데이터 모델·상태 엔진·서비스 API | P2 | 8 |
| 8 | CMN-00-APV-002 | 결재선 템플릿·CFT Role 매핑 | P2 | 6 |
| 9 | QMS-02-DVQ-005 | 계획 결재와 트리거 연계 서비스 | P4 | 5 |
| 10 | QMS-02-DVQ-006 | 시험 의뢰·접수·진행 관리 | P4 | 6 |
| 11 | QMS-02-DVQ-007 | 시험 결과 입력·항목 판정·불합격 처리 | P4 | 7 |
| 12 | QMS-03-IQC-004 | 판정 후속 처리·SAP 회신·NCR 연계·협력사 통보 | P4 | 5 |
| 13 | QMS-03-IQC-005 | 검사 수준 자동 전환(정상·강화·완화·무검사) | P4 | 5 |
| 14 | QMS-06-NCR-002 | 부적합 등록(모바일)·원천 자동 생성 게이트웨이 | P5 | 6 |
| 15 | QMS-06-NCR-003 | 봉쇄·처분·특채·재고 처리 이벤트 | P5 | 7 |
| 16 | QMS-06-NCR-008 | 부적합 실적 Snowflake 집계·KPI | P6 | 4 |
| 17 | QMS-08-AIQ-002 | 품질 사례·레슨런 코퍼스와 의미 검색 서비스 | P12 | 7 |
| 18 | QMS-08-AIQ-003 | 원인 후보 순위 엔진(원인 분포·유사 사례·맥락 신호) | P12 | 6 |
| 19 | QMS-08-AIQ-004 | 원인 추천 서비스·원천 어댑터·화면 연결 | P12 | 6 |
| 20 | QMS-08-AIQ-006 | 추천 확정·적중 평가 자동화와 확정 사례 반영 | P12 | 5 |
| 21 | QMS-08-AIQ-014 | 4M 변경 기반 필요 시험 추천 | P13 | 5 |
<!-- END:CRITICAL-PATH -->

## 5. Scratch Org 환경

### 5.1 Org 구성

| 별칭 | Dev Hub | 기간 | 용도 | 배포 원천 |
| --- | --- | --- | --- | --- |
| `qms-int` | LSPMSQMS | 30일(25일째 재생성) | 통합 확인, 페이즈 게이트, 데모. 데모 데이터 적재 | `main` |
| `qms-dev-{레인}` | LSPMSQMS·myDevHub | 14~21일 | 레인별 개발. WI 브랜치 배포 | WI 브랜치 |
| `qms-ci` | myDevHub | 30일 | CI 검증 전용. `main` 병합 때마다 배포해 `main`과 같게 유지 | `main` |
| `qms-spike` | myDevHub | 1~3일 | 기능·라이선스 확인(Agentforce, Experience Cloud, 테스트 IdP 등) | 없음 |

- `qms-dev-*`에는 데모 데이터를 필요한 파일만 넣는다. 화면 확인은 `qms-int`에서 한다.
- 기존 `scratchOrg`(2026-12-01 만료)는 P0 스파이크·P1 개발에 쓰고, 만료 전에 `qms-int`로 바꾼다. 기본 대상 Org 설정(`target-org`)은 각자 개발 Org로 둔다.

### 5.2 Dev Hub 용량

| Dev Hub | 활성 한도 | 일 생성 한도 | 배분 |
| --- | --- | --- | --- |
| LSPMSQMS | 3(현재 1 사용) | 6 | `qms-int` 1 + `qms-dev-a`·`qms-dev-b` 2 |
| myDevHub | 3 | 6 | `qms-ci` 1 + `qms-dev-c` 1 + `qms-spike`·`qms-dev-d` 공용 1 |

- 동시에 쓸 수 있는 개발 Org는 4개다. 개발자(에이전트) 4명까지는 이 용량으로 충분하고, 5명 이상이면 한도가 큰 Dev Hub(회사 운영 Org나 파트너 Org)를 연결해야 한다.
- CI가 PR마다 Scratch Org를 새로 만들면 하루 6개 한도를 바로 넘는다. CI는 상시 Org `qms-ci`에 dry-run 검증만 한다(6.3절).

### 5.3 정의 파일(P0 스파이크로 검증한 안)

`config/project-scratch-def.json` 한 파일에서 기능 플래그를 관리한다(ARC-001 BR-2). 아래는 2026-11-01 스파이크(`qms-spike`, myDevHub)에서 생성·설정을 확인한 안에 스파이크 결과로 추가가 필요한 항목(`ForceComPlatform`, `enableEndUserLanguages`, `enableEinsteinGptGlobalLangSupport`)을 넣은 것이다. 결과 상세는 P0 문서 3.4절.

```json
{
  "orgName": "SL QMS Dev",
  "edition": "Developer",
  "language": "ko",
  "country": "KR",
  "features": ["EnableSetPasswordInApi", "Communities", "Einstein1AIPlatform", "ForceComPlatform"],
  "settings": {
    "lightningExperienceSettings": { "enableS1DesktopEnabled": true },
    "mobileSettings": { "enableS1EncryptedStoragePref2": false },
    "languageSettings": { "enableTranslationWorkbench": true, "enableEndUserLanguages": true },
    "communitiesSettings": { "enableNetworksEnabled": true },
    "einsteinGptSettings": { "enableEinsteinGptPlatform": true, "enableEinsteinGptGlobalLangSupport": true },
    "agentPlatformSettings": { "enableAgentPlatform": true }
  }
}
```

| 기능·설정 | 필요한 WI | 첫 페이즈 | 스파이크 결과 |
| --- | --- | --- | --- |
| Org 기본 언어 ko, Translation Workbench | I18N-001(BR-1: en_US·zh_CN·pl·es·pt_BR 활성) | P1 | 켜짐(ko, ko_KR, Asia/Seoul). 5개 언어 Custom Label 번역이 메타데이터 배포로 저장됨(수동 설정 불필요). 폴란드어 UI에는 `enableEndUserLanguages`가 필요(기본 false) |
| Communities + `enableNetworksEnabled` | QMS-03-SPP-001 이후 포털 WI | P4 | 켜짐. Customer Community Plus 5·Plus Login 5·Partner Community 5. LWR 사이트를 `sf community create`·`publish`로 생성·게시 |
| Einstein1AIPlatform + Einstein·Agent 설정 | CMN-00-AI-001, QMS-08 | P3 | 켜짐. Agentforce(Default) 3, Einstein Prompt Templates 3,000, Einstein Agent 사용자 201, `sf agent` 명령 사용 가능. 한·중 응답에 `enableEinsteinGptGlobalLangSupport`가 필요(기본 false) |
| MultiCurrency | PMS 비용, QMS 비용(CLM-010, NCR-007) | P6 | 시험 안 함. **D-3 결정 전에는 넣지 않는다**(켜면 되돌릴 수 없음, 운영과 같아야 함) |
| Platform Encryption | SEC-003·004 | — | 시험 안 함. **D-6 결정 전에는 넣지 않는다** |
| Platform Cache 용량 | QMS-07-DSH-001·002, QMS-06-LMS-003, TRN-004 | P7 | Org 캐시 1MB 파티션 배포 성공(용량 있음) |
| 사용자 라이선스 | 데모 사용자, 통합 사용자(INT-001 BR-2) | P1 | Salesforce 2(관리자 1 사용)·Salesforce Platform 3. `ForceComPlatform`로 Platform +1(수량 표기 `:n`은 거부됨) → **새 내부 사용자 최대 5명**. Salesforce Integration 1. Enterprise 에디션은 Salesforce 5이지만 Platform·포털 라이선스가 없어 쓰지 않음 |
| 세션 2시간 | SEC-004 | P2 | 기본값이 이미 TwoHours |

Data Cloud(Data 360)는 Salesforce 문서가 Sandbox를 권장하므로 Scratch Org에 넣지 않는다(7.6절).

**ko Org 주의**: Org 기본 언어가 ko이면 표준 프로필 이름이 한국어로 바뀐다(`Standard User` → `표준 사용자`, `Standard Platform User` → `표준 플랫폼 사용자`). 이름으로 프로필을 찾는 코드·스크립트(데모 사용자 생성, `CMN_TestDataFactory`의 테스트 사용자)는 영어 이름으로 찾으면 실패한다. 테스트 코드는 프로필을 `UserLicense.Name`으로 찾는다(sf-dev 5절 "프로필명 하드코딩 금지"와 같은 이유).

### 5.4 수명 관리

- 생성: `sf org create scratch -f config/project-scratch-def.json -a <별칭> -v <DevHub> -y <일수>`
- 만료 확인: `sf org list`의 만료일. `qms-int`는 25일째, 개발 Org는 만료 3일 전에 새로 만든다.
- 재생성은 아래 재현 스크립트 한 번으로 끝나야 한다. 재현에 1시간 넘게 걸리거나 수동 단계가 5개를 넘으면 자동화 작업을 다음 페이즈 레인에 추가한다.

### 5.5 재현 스크립트 `scripts/org/build-scratch.sh`(P0 산출물)

```bash
scripts/org/build-scratch.sh <별칭> [--hub LSPMSQMS] [--days 30] [--phase N] [--no-data]
```

| 단계 | 동작 | 명령 |
| --- | --- | --- |
| 1 | Org 생성 | `sf org create scratch -f config/project-scratch-def.json -a <별칭> -v <hub> -y <days> -w 30` |
| 2 | 배포 확인 | `sf project deploy start --dry-run -o <별칭>` |
| 3 | 배포 | `sf project deploy start -o <별칭>` |
| 4 | 관리자 권한 | 관리자 사용자에 `CMN_PSG_SystemAdmin` 등 할당(`sf org assign permset` 또는 PSG 할당 스크립트) |
| 5 | 수동 설정 안내 | 5.6절 목록 중 이 Org에 아직 안 된 항목을 출력하고 확인을 기다림 |
| 6 | 데모 데이터 | `scripts/demo/load_salesforce.sh <별칭> --upto-phase N`(8절) |
| 7 | 테스트 | `sf apex run test -o <별칭> -l RunLocalTests -c -r human -w 30` |
| 8 | 결과 | 배포·테스트·적재 결과를 `.sfdx` 밖 `build/org-<별칭>-<날짜>.log`에 저장(커밋하지 않음) |

`--phase N`은 배정표에서 페이즈 N까지의 결과만 적재·확인한다. dry-run 없이 배포하지 않고, Scratch Org·Sandbox가 아니면 중단한다(`sf-dev.md` 9절).

### 5.6 수동 설정 목록(후보)

P0 스파이크에서 메타데이터·CLI로 자동화할 수 있는지 확인했다. 남은 것은 처음 나오는 페이즈 담당자가 절차를 확정한다.

| 항목 | 첫 페이즈 | 자동화 |
| --- | --- | --- |
| 번역 언어(en_US, zh_CN, pl, es, pt_BR) | P1 | **확인됨**: Translation 메타데이터 배포로 저장. 수동 단계 없음 |
| Platform Cache 파티션 | P7 | **확인됨**: PlatformCachePartition 메타데이터 배포 |
| Experience Cloud 사이트 생성·게시 | P4 | **확인됨**: `sf community create`(비동기 — `BackgroundOperation`으로 완료 확인), `sf community publish`. 같은 이름으로 두 번 요청하면 두 번째가 오류 |
| 메일 발송 수준(Deliverability) | P2 | 메타데이터(EmailAdministrationSettings)에 항목이 없어 Setup에서 확인·변경(수동) |
| SSO 테스트 IdP 연결(다른 Org를 IdP로) | P2 | 불가(2026-11-02 확인): IdP 인증서·활성화·메타데이터는 되지만 신규 Org는 연결된 앱(SAML) 생성이 막혀 SP 등록 불가. SP 설정 배포까지만 확인(`scripts/org/sso-sp-config.py`), AC는 SIT에서 포털 IdP로(docs/dev/sso-setup.md) |
| External Credential 주체·인증 값 입력(Mule DEV 주소) | P3 | 비밀값이라 저장소에 두지 않음. 사용자별 입력 절차만 기록 |
| Agentforce 에이전트 활성화 | P12 | `sf agent` 명령 사용 가능 확인, 활성화 절차는 P12에서 |

### 5.7 패키지 디렉터리·API 버전

- `sfdx-project.json` 패키지 디렉터리를 `force-app-cmn`(기본), `force-app-qms`, `force-app-pms`로 바꾼다(ARC-001). CMN 접두어 메타데이터는 반드시 `force-app-cmn`에 둔다. 명세의 `force-app/main/default/...` 경로 표기는 이 구조로 읽는다(CR-7).
- 여러 WI가 같은 파일(Custom Label, 번역 파일, PSG)을 동시에 고쳐 충돌이 잦을 것이다. P0에서 `sfdx-project.json`의 `sourceBehaviorOptions`(Custom Label·Permission Set 분해 옵션. 정확한 옵션 이름은 설치한 CLI 버전 문서로 확인)를 적용할지 정한다.
- `sourceApiVersion`은 SL 운영 Org가 받을 릴리즈와 같게 둔다. Scratch Org는 항상 최신 릴리즈이므로 낮은 버전 소스를 배포해도 된다. 운영 릴리즈가 정해지기 전에는 66.0을 유지한다.

## 6. 브랜치·검증·배포 흐름

### 6.1 브랜치

- `main`은 보호한다(직접 커밋 금지, ARC-001 BR-1). 이미 있는 커밋 2개는 기준선이다.
- WI마다 `wi/{WI-ID}` 브랜치를 만들고 PR 1건으로 병합한다. 커밋 메시지는 `[WI-ID] 요약`이다.
- 페이즈 게이트를 통과하면 `main`에 `phase-NN` 태그를 단다.
- 커밋·push·PR은 사용자가 요청할 때만 에이전트가 한다(`sf-dev.md` 10절).

### 6.2 로컬 점검(WI마다)

```bash
npm run prettier:verify
npm run lint
npm run test:unit -- --coverage
sf code-analyzer run --target <변경 경로> --rule-selector Recommended --severity-threshold 2
sf project deploy start --dry-run -o qms-dev-<레인> --test-level RunLocalTests
sf project deploy start -o qms-dev-<레인>
sf apex run test -o qms-dev-<레인> -n <이번 WI 테스트 클래스> -c -r human -w 10
```

### 6.3 CI(ARC-001 BR-1, P0 산출물)

| 작업 | 시점 | 내용 | 통과 조건 |
| --- | --- | --- | --- |
| 정적 검사 | PR | `npm ci`, prettier·eslint·Jest, Code Analyzer(변경 경로) | 실패 0, 심각도 1~2 위반 0 |
| 배포 검증 | PR | `qms-ci`에 `--dry-run --test-level RunLocalTests` | 배포 성공, 테스트 전부 통과, 클래스별 커버리지 85% 이상(`scripts/ci/check-coverage.py`가 미달 클래스명 출력) |
| 기준 Org 갱신 | `main` 병합 | `qms-ci`에 실제 배포 | 성공 |
| 재생성 | 주 1회·만료 전 | `qms-ci`를 재현 스크립트로 새로 만듦 | 성공 |

- 저장소가 공개이므로 Dev Hub·Org 인증 값(SFDX 인증 URL 등)은 GitHub Secrets에만 두고, 외부 포크 PR에서 시크릿이 쓰이는 트리거(`pull_request_target`)를 쓰지 않는다. 공개 여부는 다시 검토할 것을 권한다(11절).

### 6.4 페이즈 게이트

1. 페이즈 WI가 모두 DEV-STATUS `개발 완료`이고 완료 보고서(`docs/wi/{WI-ID}.md`)가 있다.
2. `scripts/org/build-scratch.sh qms-int --phase N`으로 **새** Org를 만들어 처음부터 재현한다(ARC-001 AC-1을 페이즈마다 확인하는 것과 같다).
3. `RunLocalTests` 전부 통과, 클래스별 커버리지 85% 이상, 전체 경로 Code Analyzer 심각도 1~2 위반 0건.
4. 페이즈 문서 "게이트 시나리오"를 데모 데이터로 재현하고, `data/demo/expected/*.json`과 맞춘다(통계 상대 오차 1e-6, 건수 정확히 일치).
5. 이전 페이즈 게이트 시나리오를 빠르게 다시 확인한다(회귀).
6. 페이즈 문서 "게이트 기록"에 날짜·Org·결과·남은 문제를 적고, `phase-NN` 태그를 단다.

## 7. 플랫폼 트랙과 목 전략

### 7.1 "Scratch Org 범위" 표기

| 표기 | 뜻 | Scratch Org에서 하는 일 |
| --- | --- | --- |
| SF | Salesforce Platform | 전부 구현·배포·테스트 |
| 포털 | Experience Cloud | Scratch Org 안 LWR 사이트와 포털 사용자로 확인(7.4절) |
| DW 목 | Snowflake 의존 | Salesforce 호출부·표시·수신 핸들러만 구현. 응답은 목(7.2절) |
| 연계 시뮬 | Mule 의존 | Salesforce 수신 계약(외부 키 upsert, 이벤트 구독·발행)만 구현. 원천 동작은 CSV 적재·이벤트 발행으로 흉내(7.3절) |
| Agentforce | Agentforce | 스파이크 결과에 따라 Scratch Org 또는 대안 Org(7.5절) |
| Data Cloud(Sandbox) | Data Cloud | Scratch Org에서 하지 않음(7.6절) |
| 외부 트랙 | SNOW·MULE뿐 | Scratch Org 산출물 없음. 계약 문서만 확인 |

### 7.2 Snowflake 의존 부분 — 세 수준으로 검증

| 수준 | 언제 | 방법 |
| --- | --- | --- |
| L1 단위 | 항상(WI 완료 조건) | Apex: `HttpCalloutMock` + 정적 리소스로 `data/demo/mocks/dwh/{QueryKey}/{case}.json`(ok·empty·stale·truncated·error-timeout). LWC: Jest + `data/demo/mocks/apex/*` |
| L2 Scratch 화면 | 페이즈 게이트 | KPI는 `90_CMN_KpiValue__c.csv` 적재로 위젯·화면 확인. 알람은 익명 Apex로 `CMN_ResultInbound__e` 발행(P3에서 `scripts/apex/publish-inbound.apex` 작성). 드릴다운 화면은 "연계 오류·지연" 상태 표시까지만 확인 |
| L3 연계 화면 | 외부 트랙 준비 후 | Mule DEV(`prc-dw-query-api`, `mock-source-systems`)와 `SL_QDW_DEV`가 준비되면 Scratch Org External Credential을 DEV 주소로 연결해 실제 응답으로 확인 |

**결정 필요(DEV-1)**: L3 전에 드릴다운 화면을 실제 값으로 보여야 하면(PoC 일정 등) Scratch Org 전용 "개발 목 응답 모드"를 `CMN_DwQueryService`에 추가해야 한다. QMS-09-INT-003은 "목을 업무 코드와 섞지 않는다"고 하므로 명세 변경이 필요하다. 권고는 L3 연결을 앞당기는 것이다(P3까지 Mule DEV `prc-dw-query-api` 목 배포).

### 7.3 Mule 의존 부분

- 원천 → Salesforce 적재: WI가 정한 외부 키로 `sf data upsert bulk`를 실행해 Mule upsert와 같은 결과를 만든다(멱등 확인 = 같은 CSV 두 번 적재 후 건수 불변).
- 원천 요청 이벤트: QMS-09-INT-002의 외부 요청 이벤트 규약대로 익명 Apex로 이벤트를 발행해 수신 핸들러를 확인한다.
- Salesforce → 원천 이벤트: 발행만 확인한다(구독은 Mule, 외부 트랙).
- 계약 스키마(`integration/contracts/*.schema.json`, QMS-09-INT-003)가 생기면 수신 핸들러 테스트 데이터를 그 스키마로 검증한다.

### 7.4 Experience Cloud(포털)

- P4(SPP-001)에서 LWR 사이트를 메타데이터(사이트·네트워크·DigitalExperience 번들)로 만들고, 협력사 Contact(`18_Contact.csv`)로 포털 사용자를 만든다.
- 라이선스가 Customer Community Plus(D3-1 가정)가 아니면 공유 방식(SEC-002 BR-4)이 달라지므로 D-5·D3-1을 P4 착수 전에 확정한다.
- Developer Scratch Org의 포털 라이선스 수는 P0 스파이크에서 확인한다. 부족하면 포털 사용자 수를 시나리오 협력사(알파광학, 감마LED, 베타폴리텍 등) 담당자로 줄인다.

### 7.5 Agentforce

- P0 스파이크에서 정의 파일로 Agentforce가 켜진 Org가 만들어지는지 확인한다.
- 안 되면 대안: (1) Agentforce가 켜진 Developer Edition Org를 AI 검증 전용으로 두고 P12 산출물만 배포, (2) Sandbox 확보. Dev Hub Org(`LSPMSQMS`, `myDevHub`)에는 개발 메타데이터를 배포하지 않는다.
- 생성형 AI 호출량에 한도가 있으므로 평가셋 전체 실행(AIQ-016)은 Sandbox에서 한다.

### 7.6 Data Cloud

Scratch Org에서는 하지 않는다. D-4(Data Cloud 범위)·D8-1(Cortex Search) 결정에 따라 문서 검색(AI-002, AIQ-013)의 Data Cloud 부분이 Sandbox로 가거나 Cortex Search로 통일되어 없어진다. Scratch Org에서는 Apex·LWC 부분만 개발한다.

### 7.7 외부 트랙 WI

| WI | 페이즈 | Salesforce 쪽에서 기다리는 것 |
| --- | --- | --- |
| CMN-00-DWH-001 | P2 | `SL_QDW_DEV` 스키마·역할(L3 전제) |
| CMN-00-DWH-002 | P3 | Salesforce → Snowflake 복제. AI-004의 정확도 KPI 원천 |
| QMS-09-INT-008 | P4 | SAP 공용 CORE 테이블(재고·BOM 쿼리 키의 원천) |
| QMS-03-IQC-007 | P6 | 수입검사 KPI(위젯·협력사 평가의 원천) |
| QMS-06-NCR-008 | P6 | NCR KPI·`MART.V_NCR_SUPPLIER_DEFECT` |
| QMS-09-INT-010 | P7 | MES SPC 측정값(SPC 실데이터) |
| QMS-09-INT-011·012·014 | P8 | MES 실적·EOL·로트 계보, 필드클레임 원천 |
| QMS-08-AIQ-003·011 | P12 | 원인 순위 엔진, 위험 점수 |
| QMS-09-INT-020 | P12 | 프로시저 호출 모드(MSA 계산의 실제 경로) |

외부 트랙은 각 페이즈 SF 트랙과 같은 기간에 진행하되 게이트는 L3 연결 확인으로 따로 기록한다.

## 8. 데모 데이터 단계 적재

- 현재 로더(`scripts/demo/sf_demo_loader.py`)는 토큰 대상 객체를 조회하다가 그 객체가 배포되지 않았으면 오류로 멈춘다. 페이즈마다 일부만 적재하려면 P0에서 아래를 보강한다(개발 도구 작업, WI 아님).
  - `--upto-phase N`: `phase-map.csv`와 객체 소유 WI로 적재할 파일을 고른다.
  - 배포되지 않은 객체를 가리키는 토큰은 조회하지 않고 빈 값으로 적재한 뒤 보정 목록에 남긴다. 다음 페이즈에서 같은 명령을 다시 실행하면 채워진다(upsert라 건수는 늘지 않음).
- 페이즈별 적재 범위는 각 페이즈 문서 "데모 데이터" 절에 있다. 요약:

| 페이즈 | 새로 전부 적재되는 파일(load-plan 번호) | 일부 행·열만 적재(나머지는 해당 페이즈에서 채움) |
| --- | --- | --- |
| P1 | 01~16, 17a, 17b | — |
| P2 | 17, 17c, 19~22, 64, 64a, 84 | 63(→P4), 83(→P6), 85(→P10) |
| P3 | 23, 90 | — |
| P4 | 18, 24~32, 49, 51, 56, 58, 59, 63, 63a | 48(→P5), 52·55·57(→P6) |
| P5 | 40~44, 45a, 45b, 46, 47, 48, 53, 96, 97 | 45(→P10) |
| P6 | 33, 50, 52, 55, 57, 60~62, 65, 66, 68, 81, 83 | — |
| P7 | 54, 91, 92, 92u, 93 | — |
| P8 | — (출하검사·초기유동·수평전개 CSV 없음, 8.1) | — |
| P9 | 37~39, 69, 69a, 70~72, 80 | — |
| P10 | 34~36, 45, 67, 73~79, 82, 85, 94, 95 | — |

### 8.1 데모 데이터 공백

- 출하검사(FQC)·초기유동(EFC)·수평전개(HZD) 레코드, 협력사 목표·스코어카드·개선 과제·심사 프로그램은 데모 CSV가 없다. S13(EOL·출하)·S10(B2B)은 Snowflake 기대값만 있다. 해당 페이즈 게이트 시나리오는 화면에서 직접 만들거나 데모 데이터 작업에 추가를 요청한다(P8·P9 문서).
- 데모 명세 2절의 AI 기대값 5종(`ai_rca_S1.json`, `ai_rca_S2.json`, `lele_S6.json`, `ew_S11.json`, `qa_S5.json`)이 아직 없다. P7(LELE 규칙)·P12(AI) 게이트 전에 생성을 요청한다.
- 등록 쿼리 목 중 `QMS_NCR_STOCK_CHECK`, `QMS_NCR_LOT_TRACE`, 표준가·환율, AI 검색·순위 응답은 `data/demo/mocks/dwh`에 없다. 해당 WI가 같은 폴더 규칙으로 L1 목을 만든다.
- 데모 데이터를 만들며 찾은 WI 보강 요청 40건(`data/demo/wi-change-requests-salesforce.md`)은 대상 WI 착수 전에 명세에 반영해야 적재가 성공한다. 각 페이즈 문서 "명세 보강"에 나눠 적었다.

### 8.2 데모 기준일과 실제 날짜

데모 데이터는 기준일 2026-12-01로 만들어졌고(`common.Clock`), Scratch Org의 오늘은 실제 날짜다. 위임 기간, 기한 경과, 에스컬레이션, 독촉, 만료처럼 오늘과 비교하는 규칙은 게이트 날짜에 따라 결과가 달라지고 기대값과 어긋난다.

생성기는 이미 기준일 이동을 지원한다(`python3 data/demo/generator/generate_all.py --today YYYY-MM-DD` — 명세의 날짜를 같은 간격만큼 옮김). P0에서 확인한 내용:

- 날짜를 옮기면 참조 점검에서 실패하던 상수 키 1건(무검사 결재 대상 수준 변경 키)을 고쳤다. 13주 이동 생성에서 시나리오 기준 날짜(위임 기간, S3 4M 일정, S12 교정일, 8D 기한, SPC 목 기준 시각)가 오늘 기준으로 같은 간격을 유지한다.
- 생성기를 빈 상태에서 한 번만 돌리면 `scenario_keys.json`에 Snowflake 시나리오 키가 빠지던 문제를 고쳤다(`generate_all.py`가 마지막에 Salesforce 생성을 한 번 더 실행).
- 업무 번호의 연도(`NCR-KR01-2027-…`)와 "최근 24개월" 같은 기간 창도 함께 바뀌므로, 옮긴 데이터는 저장소에 커밋하지 않고 게이트 Org 적재용으로만 쓴다. 저장소의 기준 데이터는 2026-12-01로 유지한다.

게이트 날짜 기준으로 다시 만든 CSV와 기대값을 같은 묶음으로 쓴다(기대값만 기준일 그대로 두면 어긋난다).

### 8.3 진행 중 상태의 데이터 적재(이관 모드)

데모 데이터에는 이미 결재 중·진행 중·종결된 업무 레코드가 많다(8D 584단계, 종결 NCR 62건 등). 그런데 명세는 상태를 서비스로만 바꾸고(API 직접 변경 차단), 트리거가 채번·To-Do·이벤트를 만든다. 그대로 적재하면 검증 규칙에 막히거나 이벤트·To-Do가 중복으로 생긴다. 운영 이관도 같은 문제를 겪는다(CR-12).

- 권고: ARC-002에 "데이터 이관 모드"(예: Custom Permission `CMN_DataMigration`)를 두고, 이 권한을 가진 사용자의 적재에서는 트리거 핸들러가 부수 효과(이벤트·To-Do·알림)를 건너뛰고, 상태 직접 변경 차단 검증 규칙과 상태 서비스 검사가 적재를 허용한다. 채번은 ARC-003 보강(RecordNo가 있으면 카운터만 맞춤)으로 처리한다.
- 권한은 Scratch Org·Sandbox의 로더 실행 사용자와 운영 이관 사용자에게만 준다. 데모 로더는 적재 전후로 권한을 붙였다 뗀다.

### 8.4 데모 사용자

P0 스파이크 결과 Developer Scratch Org의 라이선스는 Salesforce 1 + Platform 4(`ForceComPlatform` 포함)로 보이지만, P1 게이트(2026-11-02)에서 **실제로 만들 수 있는 새 내부 사용자는 4명**(Salesforce 1 + Platform 3)임을 새 Org에서 재현해 확인했다. 5번째 Platform 사용자는 남은 라이선스가 있다고 조회돼도 생성이 거부된다. 데모 로더는 남은 라이선스를 보고 우선순위 순으로 Salesforce(표준 사용자) → Platform(표준 플랫폼 사용자)을 배정한다. 데모 사용자 정의의 우선순위대로면 E1101 품질팀장, E1102·E1103 품질 엔지니어, E1104 수입검사원, E1111 SQ 팀장까지 만들어지고, E1112 SQE·E1202 고객품질·E1151 계측은 빠져 해당 Lookup이 관리자 E1901로 대체된다(`onMissingUser`).

- 영향: 협력사 품질(S3·S9의 SQE 단계), 고객 클레임(S2), 측정기(S12)의 담당자 화면을 그 페르소나로 볼 수 없다. E1111은 SupplierQuality·QualityManager PSG를 함께 갖고 있어 SQE 단계 상당수는 E1111로 확인할 수 있다.
- **DEV-4 결정(2026-11-02)**: 페이즈별로 그 페이즈 시나리오의 페르소나를 고른다(앞 4명이 실제 생성, 5번째는 여유분 — P1 게이트에서 순서 조정). 목록은 `scripts/demo/phase-users.json`이고, 데모 로더가 `--upto-phase N`에 맞춰 그 순서로 만든다(`--users`로 덮어쓸 수 있음, 생성기 데이터는 그대로). 데모 데이터에서 가장 많이 등장하는 SQE E1112는 모든 페이즈에 넣었다.

| 페이즈 | 데모 사용자 | 이유 |
| --- | --- | --- |
| P1~P3, P7, P13 | E1101 품질팀장, E1102·E1103 품질 엔지니어, E1104 검사원, E1112 SQE | 기본 |
| P4 | E1101, E1104, E1111 SQ 팀장, E1112, E1102 | 수입검사·PPAP(SQ 팀장 결재) |
| P5 | E1101, E1103, E1104, E1112, E1202 고객품질 | S1 8D D4(E1103), 모바일 NCR(E1104), S2 클레임(E1202) |
| P6 | E1101, E1111, E1112, E1202, E1104 | S3 4M(SQ 결재, HMC 통보, 첫 로트 검사) |
| P8 | E1101, E1103, E1104, E1112, E1202 | 출하검사·초기유동·B2B |
| P9 | E1101, E1102, E1103, E1112, E1151 계측 | S4 준비 과제 담당 |
| P10 | E1101, E1104, E1151, E1161 분석실장, E1112 | S12 교정, S2 분석 의뢰 |
| P11 | E1101, E1102, E1104, E1112, E1001 품질본부장 | 경영진·역할별 대시보드 |
| P12 | E1101, E1102, E1103, E1112, E1202 | S1·S2·S5·S6 AI |

목록에 없는 페르소나(공장장 결재 등)는 관리자 E1901이 대신한다. 페르소나 전체가 필요한 확인은 SIT Sandbox에서 한다.
- Platform 라이선스 사용자에게 줄 권한 셋은 Salesforce 라이선스 전용 기능을 요구하지 않아야 한다(SEC-001이 PS를 만들 때 라이선스를 지정하지 않음).

## 9. 일정 추정

### 9.1 인원별 기간

모든 WI를 문서 공수(M/D)대로, 1건을 1명이 맡고, 선행이 끝나면 바로 착수하며, 다음 페이즈는 한 페이즈 앞까지만 당겨 착수한다고 가정해 시뮬레이션했다. 검토 대기·재작업·게이트 검증(페이즈당 1~2일)·외부 트랙 인력은 포함하지 않았다.

| 개발 인원(SF 트랙) | 영업일 | 개월(21영업일 기준) | 참고: 페이즈를 엄격한 장벽으로 둘 때 |
| --- | --- | --- | --- |
| 3명 | 392 | 약 18.7 | 429 |
| 4명 | 296 | 약 14.1 | 376 |
| 5명 | 253 | 약 12.0 | 363 |
| 6명 | 231 | 약 11.0 | 360 |

6명을 넘기면 줄어드는 폭이 작다(8명 223영업일). 임계 경로(4절)와 페이즈 안 선행 사슬이 막기 때문이다.

### 9.2 4명 기준 페이즈 종료 시점(누적 영업일)

| P0 | P1 | P2 | P3 | P4 | P5 | P6 | P7 | P8 | P9 | P10 | P11 | P12 | P13 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 4 | 17 | 34 | 51 | 89 | 112 | 144 | 167 | 193 | 240 | 251 | 264 | 290 | 296 |

### 9.3 PoC 시나리오와의 관계

QMS-09-INT-003은 PoC를 10~12월로 적고 있다. PoC 시나리오(backlog.md)를 완성하는 데 필요한 WI를 선행까지 모두 모으면 아래와 같다.

| 시나리오 | 연결 WI | 선행 포함 WI | 선행 포함 M/D | 완성 페이즈 | AI 없이 완성 |
| --- | --- | --- | --- | --- | --- |
| S1 NCR Full Cycle | 16 | 87 | 454 | P12 | P5 |
| S2 Claim 8D | 12 | 88 | 466 | P12 | P6(분석실 연계는 P10) |
| S3 4M | 15 | 67 | 339 | P8 | P6(INT-012 실연계 제외) |
| S4 VDA 6.3 | 8 | 41 | 197 | P9 | P9 |
| S5 Dashboard·Q&A | 16 | 151 | 787 | P12 | P11(질문은 대체 경로) |
| S6 LELE 추천 | 7 | 60 | 307 | P12 | P7(규칙 매칭) |
| 합계(중복 제외) | | 172 | 905 | | |

PoC 6개 시나리오를 모두 실제 구현으로 보이려면 전체의 76%(905 M/D)가 필요하다. 이 플랜 일정 안에서 PoC를 하면 S4·S3가 가장 빠르다. PoC 일정이 이 플랜보다 앞선다면 시나리오를 골라 그 선행 집합만 먼저 하는 별도 PoC 경로가 필요하다(**결정 필요 DEV-2**).

## 10. 착수 전 정리할 명세 이슈(변경 요청)

| ID | 내용 | 영향 | 이 플랜의 처리 | 필요한 조치 |
| --- | --- | --- | --- | --- |
| CR-1 | 선행 순환: QMS-07-DSH-012 → QMS-08-AIQ-016 → AIQ-010 → DSH-012 | 배정 불가 | DSH-012 선행에서 AIQ-011·012·016을 뺐다(`phase-map.csv` 제외선행). DSH-012 BR-3이 "Vol.8 컴포넌트 배포 전에는 IsActive = false"로 이미 대비하고 있다. P11에서 구현, P12에서 Vol.8 위젯 활성화 | DSH-012 메타 라인 선행 수정 또는 `-a`(채널·질문·정확도 위젯)·`-b`(Vol.8 위젯 활성화) 분할 |
| CR-2 | QMS-03-IQC-004가 `QMS_NcrGateway`(DVQ-007 소유)를 쓰는데 선행에 DVQ-007이 없음 | 컴파일 실패 | 추가선행으로 보정(P4 안에서 DVQ-007 뒤) | IQC-004 선행에 QMS-02-DVQ-007 추가 |
| CR-3 | 게이트웨이 프레임워크(`QMS_GatewayFactory`, `QMS_GatewayBinding__mdt`, 인터페이스 8종, DTO 6종, 기본 구현)가 "Vol.2 DVQ-007 변경 요청"으로만 있고 DVQ-007 본문에 없음 | P4~P12 호출 측 전부 | DVQ-007 착수 시 프레임워크를 먼저 별도 PR로 머지 | DVQ-007 본문에 반영하거나 `QMS-02-DVQ-007a`로 분리(선행 ARC-002·TDO-001이면 P3에 배치 가능) |
| CR-4 | `CMN_TestDataFactory`·정적 리소스 `QMS_DemoFixtures`(sf-dev 8절)를 만드는 WI가 없음 | 모든 Apex 테스트 | ARC-002에 포함하자고 제안(P1) | ARC-002 범위에 추가. 각 WI가 자기 객체 생성 메서드를 어디에 두는지 규칙도 정함(권고: CMN은 코어만, QMS WI는 `QMS_{도메인}TestData`에) |
| CR-5 | ARC-001 BR-2 "Translation Workbench, Communities, Platform Encryption **비활성** 상태로 시작" | I18N-001(P1), SPP-001(P4)이 켜진 상태를 요구 | 5.3절 안: TW·Communities 활성, Platform Encryption은 D-6 전 비활성 | BR-2 문구 확정 |
| CR-6 | 데모 데이터 보강 요청 40건(`ExternalKey__c` 추가, DTO 정의, 누락 필드 등) | 데모 적재 실패 | 페이즈 문서 "명세 보강"에 대상 WI별로 배치 | 해당 WI 착수 전 명세 반영 |
| CR-7 | 저장소 경로 표기 불일치: Vol.7은 `force-app/main/default/...`(cmnChartJs, QMS_AskQualityChannel), Vol.9는 `integration/...`, ARC-001은 `force-app-{cmn,qms,pms}`·`mule/` | 파일 위치 혼선 | ARC-001 구조를 따름(cmnChartJs → `force-app-cmn`, QMS 채널 → `force-app-qms`) | 명세 경로 표기 정리, Mule 디렉터리 이름 하나로 |
| CR-8 | 라이브러리 미정: QR 라벨(GAU-001, LMS-002, LAB-002의 Visualforce PDF), 엑셀 양식 채우기(CLM-006). 승인 목록은 Chart.js·SheetJS뿐 | 구현 방식 미정 | 해당 페이즈 결정 항목 | SheetJS 사용 범위 확대 여부, QR 생성 방식(서버 측 생성 등) 결정 |
| CR-9 | `CMN_DwQueryService.callProcedure`(프로시저 호출 모드)가 QMS-09-INT-020의 "Vol.0 DWH-004 변경"으로만 있음. MSA-003(P10)이 먼저 필요 | MSA 계산 | DWH-004(P3) 구현 때 함께 반영 권고 | DWH-004 명세에 callProcedure 추가 |
| CR-10 | DEV-STATUS의 "Wave 순서로 착수" 원칙 | 이 플랜과 충돌 | P0에서 DEV-STATUS 문구를 이 플랜(선행 순서·롤링 착수)으로 바꿈 | — |
| CR-11 | 공통 WI AC가 아직 없는 QMS 객체를 예로 듦: ARC-003 AC-1, MDM-007 AC-2, SEC-002 AC-1~4, SEC-003 AC-1·2, UX-003 AC-1, DOC-001 AC-1, APV-002 AC-1, UX-001 AC-1, UX-002 AC-1 | P1~P3에서 그대로 검증 불가 | 테스트 대상 객체로 검증하고(DEV-3), 실제 객체 AC는 P5·P6 게이트에서 회귀 AC로 다시 확인 | 공통 WI AC에 "검증 대상" 문구 추가, DEV-3 결정 |
| CR-12 | 진행 중·종결 상태 레코드를 적재하는 경로(데모·운영 이관)가 명세에 없음 | 데모 적재 실패, 이벤트·To-Do 중복 | 8.3절 이관 모드 권고 | ARC-002에 이관 모드 추가, 상태 규칙이 있는 업무 WI의 검증 규칙이 이를 따르게 |

Wave 역전 41건은 이 플랜이 선행 WI를 앞으로 당겨 해소했다(부록 B). WI 메타의 Wave 값을 바꿀지는 검토 때 정한다(마스터 xlsx의 Wave 열에 영향).

## 11. 위험과 대응

| 위험 | 영향 | 대응 |
| --- | --- | --- |
| 명세 미승인 상태로 착수 | 재작업 | 페이즈 순서로 검토(3.6절). P1 착수 전 Vol.0 W0 26건 승인이 최우선 |
| Scratch Org 만료(30일) | 작업 손실 | 설정을 전부 메타데이터·스크립트로(3.3절), 재현 스크립트, 만료 전 재생성(5.4절) |
| Dev Hub 한도(활성 3·일 6) | 병렬 개발·CI 막힘 | 5.2절 배분, CI는 상시 Org dry-run, 5명 이상이면 큰 Dev Hub |
| Scratch Org 라이선스(내부 사용자 실제 4명) | 일부 페르소나(SQE·고객품질·계측)를 데모 사용자로 확인 못 함 | DEV-4 결정(8.4절). 포털 라이선스(Customer Community Plus 5 + Login 5)는 충분 |
| Agentforce·Data Cloud를 Scratch Org에서 못 씀 | P3·P12 지연 | P0 스파이크, 7.5·7.6절 대안 Org 미리 확보 |
| 외부 트랙(Snowflake·Mule) 지연 | 화면 L3 검증 지연, PoC 데이터 흐름. 특히 QMS-06-NCR-008은 임계 경로 위(P12 AI 선행) | L1·L2로 SF 트랙 완료 처리, L3는 별도 게이트(7.2절). 외부 트랙 인력·환경을 P2까지 확보하고 NCR-008을 외부 트랙 최우선으로 |
| 공용 파일 병합 충돌(Custom Label, 번역, PSG) | PR 대기 | 분해 옵션(5.7절), 작은 PR, 병합 전 `main` 재반영 |
| 공개 저장소 | CI 시크릿·명세 노출 | 시크릿은 GitHub Secrets만, `pull_request_target` 금지. WI 명세가 RFP 기반 대외비라면 비공개 전환 권고 |
| PoC 일정이 이 플랜보다 앞섬 | 시연 범위 부족 | DEV-2 결정(9.3절) |
| 데모 기준일(2026-12-01)과 게이트 날짜 차이 | 기한·만료 시나리오가 기대값과 어긋남 | 생성기 `--today`(8.2절) |
| 진행 중 상태 데이터 적재 | 데모·이관 적재 실패 | 이관 모드(8.3절, CR-12) |
| 결정 지연(D-1, D-3, D-4, D-5, D-6 등) | 해당 WI 착수 불가 | 페이즈 문서의 "선결 결정"을 그 페이즈 착수 2주 전까지 받는다 |

## 12. 진행 관리

- **WI 단위**: `/implement-wi`가 DEV-STATUS 행(상태·시작일·완료일·보고서)을 갱신한다. P0에서 DEV-STATUS 진행 표에 "페이즈"·"레인" 열을 추가한다.
- **페이즈 단위**: 게이트 결과를 각 페이즈 문서 "게이트 기록"에 남긴다.
- **플랜 변경**: `phase-map.csv`를 고치고 `python3 scripts/build_dev_plan.py`로 검사·재생성한다. 명세가 바뀌어 `workitem-index.csv`를 다시 만들었을 때도 실행한다(선행이 바뀌면 배정 위반이 드러난다).
- **결정**: DEV-1(개발 목 응답 모드, 7.2절), DEV-2(PoC 경로, 9.3절), DEV-3(공통 기능 테스트 대상 객체, P1 문서 10절)은 대기, DEV-4(데모 사용자 5명 한도 대응, 8.4절)는 2026-11-02 페이즈별 선택으로 정했다. 이 넷은 이 플랜에서 새로 생긴 결정이고, 나머지는 review-pack의 결정 번호를 쓴다.
- **CI 검증 Org 갱신**: `qms-ci`는 30일마다 다시 만들고 GitHub 시크릿 `SF_AUTH_URL_CI`를 갱신한다(`scripts/org/build-scratch.sh qms-ci --hub myDevHub --no-data` → `sf org display -o qms-ci --verbose --json`의 `sfdxAuthUrl`). 갱신하지 않으면 CI의 배포 검증 단계가 실패한다.

## 부록 A. 페이즈별 선결 결정(review-pack)

| 페이즈 | 착수 전 필요한 결정 |
| --- | --- |
| P0 | D-1 단일 Org, D-3 Multi-Currency, D-6 Shield, API 버전, 저장소 공개 여부, DEV-2 PoC 경로 |
| P1 | D-8 임직원 동기화 방식(MDM-001·INT-002 전제), DEV-3 테스트 대상 객체, CR-12 이관 모드(ARC-002), I18N-001 오픈 이슈(SAML 언어 속성) |
| P2 | D-2 공통 결재 엔진, D-7 문서 저장소, D-9 공장 격리 수준 |
| P3 | D-4 Data Cloud 범위(DWH-002·004, AI-002), DEV-1 개발 목 응답 모드 |
| P4 | D-5·D3-1 포털 라이선스, D2-1~D2-5, D3-2~D3-6, D3-9, D9-1·D9-2(SAP 수신·반영 방식) |
| P5 | D5-1, D5-4, D5-5, D5-8, D5-10, D6A-5~D6A-7, D6A-10, D4-5, D4-6 |
| P6 | D-3(비용 WI 전), D2-4, D3-7, D3-8, D4-9, D5-7, D6A-1~D6A-4, D6A-8, D6A-9 |
| P7 | D4-1~D4-3, D4-7, D4-8, D7-1~D7-3 |
| P8 | D4-4, D4-10, D5-2, D5-3, D5-9, D9-3, D9-5 |
| P9 | D6C-1~D6C-11 |
| P10 | D6B-1~D6B-9 |
| P11 | D7-4~D7-8 |
| P12 | D-4, D-10, D8-1~D8-11 |
| P13 | D-1·D9-6(INT-021), D9-7(선택 연계), D9-4 |

## 부록 B. Wave 역전 목록

<!-- BEGIN:WAVE-INVERSIONS -->
41건. 왼쪽 WI의 Wave가 선행 WI보다 이르다. 이 플랜은 선행 WI를 앞 페이즈로 당겨 해소했다.

| WI | Wave | 선행 WI | 선행 Wave | 선행 배정 |
| --- | --- | --- | --- | --- |
| QMS-05-B2B-001 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-08-AIQ-009 | W1 | CMN-00-AI-005 | W2 | P12 |
| QMS-06-4MC-003 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-05-B2B-006 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-04-SPC-003 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-07-DSH-001 | W1 | QMS-03-IQC-007 | W2 | P6 |
| QMS-07-DSH-002 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-05-CLM-003 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-06-IAU-005 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-04-RPP-002 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-04-RPP-002 | W1 | QMS-02-DVQ-009 | W2 | P6 |
| QMS-06-NCR-002 | W1 | QMS-03-IQC-005 | W2 | P4 |
| QMS-04-SPC-006 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-07-DSH-012 | W1 | QMS-08-AIQ-011 | W2 | P12 |
| QMS-07-DSH-012 | W1 | QMS-08-AIQ-012 | W2 | P12 |
| QMS-07-DSH-012 | W1 | QMS-08-AIQ-016 | W2 | P12 |
| QMS-06-4MC-007 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-06-4MC-007 | W1 | QMS-03-IQC-006 | W2 | P6 |
| QMS-06-4MC-007 | W1 | QMS-03-PIS-001 | W2 | P6 |
| QMS-06-NCR-003 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-05-CLM-008 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-07-DSH-006 | W1 | QMS-04-EFC-002 | W2 | P8 |
| QMS-07-DSH-006 | W1 | QMS-04-FQC-004 | W2 | P8 |
| QMS-09-INT-011 | W1 | QMS-04-EFC-002 | W2 | P8 |
| QMS-09-INT-011 | W1 | QMS-04-FQC-004 | W2 | P8 |
| QMS-08-AIQ-002 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-08-AIQ-002 | W1 | QMS-06-NCR-008 | W2 | P6 |
| QMS-06-NCR-006 | W1 | QMS-03-IQC-005 | W2 | P4 |
| QMS-09-INT-007 | W1 | QMS-06-NCR-007 | W2 | P6 |
| QMS-07-DSH-007 | W1 | QMS-06-4MC-008 | W2 | P6 |
| QMS-07-DSH-007 | W1 | QMS-06-NCR-008 | W2 | P6 |
| QMS-08-AIQ-003 | W1 | CMN-00-DWH-004 | W2 | P3 |
| QMS-08-AIQ-003 | W1 | QMS-03-IQC-007 | W2 | P6 |
| QMS-08-AIQ-003 | W1 | QMS-06-4MC-008 | W2 | P6 |
| QMS-08-AIQ-003 | W1 | QMS-06-NCR-008 | W2 | P6 |
| QMS-07-DSH-005 | W1 | QMS-03-IQC-007 | W2 | P6 |
| QMS-07-DSH-005 | W1 | QMS-06-SQM-002 | W2 | P9 |
| QMS-08-AIQ-010 | W1 | CMN-00-AI-005 | W2 | P12 |
| QMS-08-AIQ-010 | W1 | QMS-03-IQC-007 | W2 | P6 |
| QMS-08-AIQ-010 | W1 | QMS-06-NCR-008 | W2 | P6 |
| QMS-08-AIQ-010 | W1 | QMS-06-SQM-002 | W2 | P9 |
<!-- END:WAVE-INVERSIONS -->
