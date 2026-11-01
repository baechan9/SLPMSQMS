# SL QMS 데모 데이터

가상 회사 SL(자동차 헤드램프 Tier 1)의 데모·개발·테스트 공용 데이터다. 명세는 `docs/docs/40-demo/demo-data-spec.md`, 기준정보는 `master/demo_master.json`이다. 모든 회사·사람·번호는 가상이며, 협력사 담당자 이메일은 `@example.com`, 직원 이메일은 `@slqms.example.com`만 쓴다.

## 생성

```bash
python3 data/demo/generator/generate_all.py            # Salesforce → Snowflake 순서(Snowflake가 Salesforce CSV를 읽는다)
# Salesforce 부분만
python3 -c "import sys; sys.path.insert(0,'data/demo/generator'); import common, gen_salesforce; gen_salesforce.generate(common.load_master(), common.Clock())"
```

- 기준일 2026-12-01(`common.Clock`), seed는 마스터 `meta.seed`. 같은 입력이면 같은 결과가 나온다(약 2초).
- 생성기가 끝에 관계 열·토큰 참조를 모두 점검하고, 하나라도 대상이 없으면 실패한다.
- 생성 결과 파일은 손으로 고치지 않는다. 바꿀 값은 `generator/gen_salesforce.py`·`generator/sf_corpus.py`(문장 코퍼스)·`master/demo_master.json`에서 고친다.

## Salesforce

### 파일

| 경로 | 내용 |
| --- | --- |
| `salesforce/NN_{객체}.csv` | Bulk API 2.0 upsert CSV. 01~85(Salesforce 데이터 작업), 90번대는 Snowflake 데이터 작업 |
| `salesforce/NNa_…`, `NNb_…` | 같은 번호 묶음의 다음 패스(자기 참조·순환 참조·갱신). 예: 07a·07b = 코드 L2·L3, 45a = NCR→8D 연결, 17a = 사용자 필드 갱신 |
| `salesforce/load-plan.json` | 적재 순서(order), 외부 키, 관계 열, 사용자 Lookup 열, 토큰 열, onMissingUser 규칙 |
| `salesforce/users/{사번}.json` | `sf org create user` 정의. `_demo`(우선순위·PSG·결재 Role)는 로더가 떼고 쓴다 |
| `expected/scenario_keys.json` | 시나리오 논리 키 → 실제 번호(Snowflake 키 합침), LELE 번호, S1·S2·S6 맥락, 종결 8D 원인 목록 |
| `expected/iqc_S9.json` | 수입검사 수준 전환·Hold·불합격·성적서 이상·월별 협력사별 로트 합격률 |
| `expected/gauge_S12.json` | GA-KR01-0456 교정 불합격 영향 로트(판정식 포함) |
| `mocks/apex/{DTO 또는 화면}/{케이스}.json` | 화면 Apex 응답 목(LWC Jest). `_meta.definition`이 "제안 DTO"면 WI에 DTO가 아직 없다 |
| `fixtures/demo_fixtures.json` | Apex 테스트 픽스처(정적 리소스 `QMS_DemoFixtures`, `CMN_TestDataFactory`가 읽음) |
| `wi-change-requests-salesforce.md` | 데이터를 만들며 찾은 WI 누락·불일치(대상 WI, 내용, 데모 임시 값) |

### CSV 규칙

- 열 이름은 WI 데이터 모델의 API명이다. 수식·롤업·서버 계산 필드는 넣지 않는다.
- 관계는 `Field__r.외부키필드`(예: `Plant__r.PlantCode__c`, `Item__r.ItemNo__c`, Contact는 `Account.SapVendorNo__c`) — Bulk API가 Id로 바꾼다.
- `RecordTypeDeveloperName` 열은 로더가 `RecordTypeId`로 바꾼다.
- 텍스트 Id 필드(SourceRecordId__c, TargetRecordId__c, LinkedRecordId__c, To-Do ExternalKey 등)는 `{{ref:객체.외부키필드=값}}`·`{{user:사번}}` 토큰으로 쓴다. 대상이 나중 파일에 있으면 로더가 비워 적재한 뒤 마지막 보정 패스에서 채운다.
- 외부 키가 WI에 없는 객체는 `ExternalKey__c`(Text(80), External ID, Unique)를 쓴다 — 변경 요청 파일에 객체별 키 형식이 있다.
- 코드 키는 계층 경로 전체: `DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG`, `CAUSE_5M1E/MACHINE/DISPENSER_FLOW`.
- 업무 번호는 WI 채번 패턴을 따르고 발생일 순으로 매긴다(예: `NCR-KR01-2026-000028`). ARC-003은 "RecordNo가 있으면 채번하지 않고 카운터를 맞춘다"를 지원해야 한다.
- 날짜는 `YYYY-MM-DD`, 일시는 UTC `YYYY-MM-DDTHH:MM:SSZ`(KST 업무 시각을 변환), 체크박스는 `true`/`false`.

### 적재

```bash
scripts/demo/load_salesforce.sh <orgAlias>               # 전체
scripts/demo/load_salesforce.sh <orgAlias> --dry-run     # Org 없이 변환·순서 확인
scripts/demo/load_salesforce.sh <orgAlias> --from 48     # 48번부터 재시작
```

1. 대상 검사 — `sf org list`의 Scratch Org이거나 `Organization.IsSandbox = true`가 아니면 중단한다.
2. 사용자 — 우선순위 8명(E1101 품질팀장, E1102·E1103 품질 엔지니어, E1104 수입검사원, E1111 SQ 팀장, E1112 SQE, E1202 고객품질, E1151 계측)을 만든다. 실행 사용자는 E1901(관리자)로 표시한다. 만들지 않은 사번의 Lookup은 load-plan의 `onMissingUser`에 따라 행을 건너뛰거나(skip: 사용자 갱신·공장 접근·위임) E1901로 바꾼다(admin: 그 밖, 결재 Role 배정 포함).
3. `load-plan.json` + `load-plan.snowflake.json`을 order 순으로 `sf data upsert bulk`.

전제: 대상 Org에 CMN·QMS 메타데이터(객체·필드·RecordType·PSG, 외부 키 제안 필드 `ExternalKey__c` 포함)가 배포돼 있어야 한다.

### 시나리오 요약(기준일 2026-12-01)

| 시나리오 | 상태 |
| --- | --- |
| S0 | 기준정보, 코드, 결재 Role·템플릿·위임(E1101 → E1102, 12-01~12-05), NCR 70(INTERNAL 45·SUPPLIER 25·종결 62, NCR마다 8D: FULL 18·SHORT 52, 클레임 연계 4건은 LINKED_8D), 클레임 20(종결 18), 종결 8D 원인 분포는 명세 표 그대로, 4M 12(S3 포함, 종결 10, 무단 변경 1), 인정시험 15(S3 포함), PPAP 18(S3·델타코팅 잠정 승인 결재 중 포함), LELE 18, 심사 8, 자격 60, 측정기 60·교정 154, 한도견본 15, 분석 의뢰 25 |
| S1 | `S1-NCR`(BMW 반품 BE1 LH 김서림 3EA) → `S1-8D` FULL_8D, D1~D3 승인, D4 진행 중(E1103) |
| S2 | `S2-CLAIM`(HMC HE1 DRL 점멸 12건, 6PI) → `S2-LAB`(X-ray 보이드 31%) → `S2-NCR`(감마LED) → `S2-8D` D1~D4 승인, D5 협력사 제출 대기 |
| S3 | `S3-4M`(알파광학 레진 등급 변경, STABILIZING) → `S3-QUAL` PASS → `S3-PPAP` 승인 → 적용 결재 11-20 → `S3-IQC-FIRST`(11-25, 전수) → `S3-STB` ACTIVE 2로트 |
| S4 | `S4-AUDIT`(BMW 공정 심사 2027-01-20 준비, 자체 평가 84% B, P6.1.4 4점), 직전 심사 `S4-AUDIT-PREV` 지적 3건(종결 2) |
| S6 | PMS 프로젝트·액티비티는 텍스트 Id(`scenario_keys.json` s6Project) |
| S9 | 로트 1,359(6개월), 베타폴리텍 하우징 불합격 5로트·강화 전환 2건, 엡실론 성적서 값 동일, 감마LED 성적서 OOS_HOLD |
| S12 | GA-KR01-0456 교정 불합격(As-found +0.05mm) → 영향 분석 `S12-IMPACT` OPEN |

## Snowflake

<!-- Snowflake 데이터 작업이 채운다. 현재 내용은 README-snowflake.md 참고. -->
