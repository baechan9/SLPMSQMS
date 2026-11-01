# CMN-00-ARC-001 완료 보고 — 개발 환경·저장소·CI/CD 표준

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-ARC-001 (vol0-cmn-common.md#5 CMN-00-ARC 개발 기반) |
| Wave / 공수(계획 → 실제) | W0 / 4 M/D → 약 2 M/D(에이전트 작업, P0 스파이크·도구 준비 포함) |
| 완료일 | — (일부 완료) |
| 구현 | Claude Code(에이전트) |
| 상태 | 일부 완료 — AC-1은 P1 게이트(2026-11-02)에서 확인, AC-2는 GitHub CI 실제 실행, AC-3은 외부 트랙(Snowflake)에서 마저 확인 |
| 명세 상태 | 검토 전 명세(2026-11-02 사용자가 검토 전 착수에 동의) |

## 1. AC 결과

| AC | 확인 방법 | 결과 |
| --- | --- | --- |
| AC-1 새 Scratch Org 생성 → 소스 배포 → CMN 테스트 전부 통과 | `scripts/org/build-scratch.sh qms-int --hub LSPMSQMS --no-data`로 확정 정의 파일에서 Org 생성(5분 44초), 8단계 끝까지 수행. 정의 파일 설정이 모두 켜짐(번역 언어·Experience Cloud·Einstein·Agent·Platform 라이선스 4) | 통과 — P1 게이트(2026-11-02): `qms-int`에 전체 배포 후 RunLocalTests 138건 통과, 저장소 클래스 전부 85% 이상(P1 문서 11절) |
| AC-2 커버리지 80% 클래스 PR → 병합 차단 + 미달 클래스명 표시 | 실제 dry-run 배포 결과(`qms-spike`, RunLocalTests)와 `sf apex run test` 결과로 `scripts/ci/check-coverage.py` 확인: 62.5% 클래스 `TmpPartial` → 종료 코드 1, "커버리지 85% 미만 클래스 1개: TmpPartial" 출력. 100% 클래스는 통과 | 일부 — 검사기는 확인. GitHub Actions에서의 실제 차단은 원격 push·시크릿 등록 후(T0-7) |
| AC-3 schemachange V002 → DEV 적용 → `SCHEMACHANGE_HISTORY` 기록 | `snowflake/schemachange-config.yml`, `V001__init.sql` 작성 | 미확인 — Snowflake DEV 계정 준비 후 외부 트랙에서(T0-8) |

데모 시나리오 재현: 해당 없음(S0 기준정보는 P1).

추가로 확인한 비즈니스 규칙:

| BR | 확인 |
| --- | --- |
| BR-1 PR 병합 조건 | `.github/workflows/ci.yml`: 정적 검사(prettier·eslint·Jest·Code Analyzer 심각도 2), qms-ci dry-run + RunLocalTests + 저장소 클래스별 커버리지 85%. 브랜치 보호(필수 체크)는 사용자가 GitHub에서 설정 |
| BR-2 정의 파일 한 곳 | `config/project-scratch-def.json` 하나. 재현 스크립트·CI가 이 파일만 씀 |
| BR-3 비밀값 없음 | 저장소에 자격 증명 없음. CI는 GitHub Secrets(`SF_AUTH_URL_CI`), Snowflake는 환경 변수·Key-pair, Mule은 Secure Properties로 안내 |
| BR-4 schemachange만 | `snowflake/README.md`에 수동 DDL 금지와 실행 방법 |

## 2. 구현 내역

| 파일 | 내용 |
| --- | --- |
| `sfdx-project.json` | 패키지 디렉터리 `force-app-cmn`(기본)·`force-app-qms`·`force-app-pms`. `sourceBehaviorOptions: ["decomposeCustomLabelsBeta2"]`. API 66.0 유지 |
| `force-app-{cmn,qms,pms}/main/default/.gitkeep` | 빈 디렉터리 유지(`.forceignore`에 `**/.gitkeep`). 템플릿의 빈 `force-app/` 제거 |
| `config/project-scratch-def.json` | Developer, ko·KR, Communities·Einstein1AIPlatform·ForceComPlatform, Translation Workbench·End User Languages, Experience Cloud, Einstein·Global Lang Support·Agent 플랫폼 |
| `code-analyzer.yml` | 문서·데이터·스크립트·외부 트랙 폴더 제외, ESLint는 저장소 `eslint.config.js` 사용 |
| `.github/workflows/ci.yml` | `static`(PR·push), `validate`(qms-ci dry-run RunLocalTests + 커버리지), `deploy-main`(main push 때 qms-ci 갱신). 시크릿·메타데이터가 없으면 건너뛰고 알림만 |
| `scripts/ci/check-coverage.py` | 배포 결과·테스트 실행 결과 JSON 모두 읽음. 저장소 패키지 디렉터리의 클래스·트리거만 판정 |
| `scripts/org/build-scratch.sh` | 개발 플랜 5.5절 8단계(생성 → dry-run → 배포 → 관리자 PSG → 수동 설정 안내 → 데모 → 테스트·커버리지 → 결과). Scratch Org가 아니면 중단. 로그는 `build/`(커밋 안 함) |
| `jest.config.js` | 데모 목 별칭 `@demo/*` → `data/demo/*`(예: `import mock from "@demo/mocks/apex/qmsIqcQueue/KR01.json"`) |
| `snowflake/` | README, `schemachange-config.yml`(접속 정보는 환경 변수), `migrations/V001__init.sql` |
| `mule/README.md`, `integration/README.md` | Mule 애플리케이션은 `mule/{api-name}/`, 계약·목·PoC·카탈로그는 `integration/`(QMS-09 경로) |
| `.gitignore` | `build/`, `test-results/` |
| P0 도구(2026-11-01 커밋) | lint `--no-error-on-unmatched-pattern`, Jest `--passWithNoTests`, `.prettierignore`에 `docs/`·`data/`·`**/*.md` |

핵심 설계 판단(명세가 정하지 않은 부분):

1. **CI 검증 Org는 상시 Scratch Org `qms-ci` 하나**: Dev Hub 하루 생성 한도(6)로는 PR마다 새 Org를 만들 수 없다. `main` 병합 때마다 실제 배포해 `main`과 같게 두고, PR은 그 위에 dry-run으로 검증한다. 30일마다 다시 만들고 시크릿을 갱신해야 한다(5절).
2. **커버리지는 저장소 클래스만 판정**: RunLocalTests는 Org 기본 클래스도 돌리는데, Experience Cloud를 켜면 생기는 `CommunitiesSelfRegController`(76%)·`MicrobatchSelfRegController`(80%)·`SiteRegisterController`(81%) 등이 85%에 못 미친다. 그대로면 모든 PR이 막히므로 저장소 밖 클래스는 "참고"로만 표시한다(`--all`로 전체 판정 가능).
3. **Custom Label만 분해 형식**: 여러 WI가 동시에 라벨을 추가해 생기는 병합 충돌을 줄이려고 `decomposeCustomLabelsBeta2`만 켰다. Permission Set은 WI마다 따로 만들어 충돌이 적어 분해하지 않았다. 번역 파일(`*.translation-meta.xml`)은 분해 옵션이 없어 작은 PR·병합 전 `main` 재반영으로 대응한다.
4. **ko Org의 표준 프로필 이름이 한국어**(`표준 사용자`, `표준 플랫폼 사용자`): 이름으로 프로필을 찾는 스크립트·테스트는 실패한다. 데모 로더는 수정했고, `CMN_TestDataFactory`(ARC-002)는 `UserLicense.Name`으로 프로필을 찾아야 한다.
5. **Developer 에디션 유지**: Enterprise 에디션 Scratch Org는 Salesforce 라이선스 5개지만 Platform·포털 라이선스가 없어 협력사 포털을 만들 수 없다. Developer + `ForceComPlatform`로 새 내부 사용자 5명(DEV-4는 페이즈별 사용자 선택 `scripts/demo/phase-users.json`으로 대응).

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지 | 해당 없음(Apex 코드 없음). 검사기는 임시 클래스로 확인 후 임시 파일 삭제 |
| Jest | `@demo` 별칭을 쓰는 임시 LWC 테스트 1건 통과 후 삭제. 빈 저장소에서 `npm run test:unit` 통과 |
| Code Analyzer(심각도 1~2) | 빈 패키지 디렉터리 0건. 루프 안 SOQL 임시 클래스로 종료 코드 2(차단) 확인 후 삭제 |
| ESLint / Prettier | 통과(`npm run lint`, `npm run prettier:verify`) |
| 재현 스크립트 | `bash -n` 통과, `qms-int`·`qms-ci` 생성 실행 |
| 데모 로더 | 빈 `qms-int`에서 실제 실행: 소유 WI 미배포 파일 104개를 사유와 함께 건너뜀(레코드타입이 없는 Account 파일 포함) |

## 4. 보안·성능 점검

- [x] 비밀값·하드코딩 Id 없음: 저장소에 인증 값 없음. CI는 `SF_AUTH_URL_CI` 시크릿을 임시 파일로 쓰고 바로 지움
- [x] 공개 저장소 대응: `pull_request_target` 미사용(포크 PR에 시크릿이 넘어가지 않음), 시크릿이 없으면 검증을 건너뛰고 알림
- [x] 재현 스크립트·로더는 Scratch Org(로더는 Sandbox 포함)가 아니면 중단
- [ ] `/code-review`·`/security-review`: 실행하지 않음(Apex·LWC 코드 없음, 스크립트·설정만). P1 첫 코드 WI부터 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | BR-2 "Translation Workbench, Communities, Platform Encryption 비활성 상태로 시작" → TW·Communities는 켜고 Platform Encryption만 뺌(I18N-001·SPP-001이 켜진 상태를 요구) | CR-5, 사용자가 권고안 채택(2026-11-02). Vol.0 BR-2 문구 수정 요청 |
| 명세 차이 | 구성 기준 DEV 환경 "Scratch Org + Developer Sandbox 2개" → 현재 Sandbox 없음, Scratch Org(Dev Hub 2개, 각 활성 3)만 | Sandbox는 SIT 전 확보(개발 플랜 P13) |
| 명세 차이 | 저장소 구조 예시의 루트 `sl-platform/` → 실제 저장소 `SLPMSQMS`. `mule/`과 QMS-09의 `integration/`을 둘 다 둠(역할 분리) | CR-7 해석. Vol.0·Vol.9 경로 표기 정리 요청 |
| 명세 차이 | 정의 파일에 명세에 없는 `ForceComPlatform`, End User Languages, Einstein Global Lang Support 추가 | P0 스파이크 결과(개발 플랜 P0 3.4절) |
| 명세 차이 | 커버리지 판정을 저장소 클래스로 한정 | 2절 판단 2. Vol.0 3.3 DoD에 문구 추가 요청 |
| 이슈 | `qms-ci`는 30일마다 다시 만들고 GitHub 시크릿을 갱신해야 함(자동화 안 됨) | 절차: `scripts/org/build-scratch.sh qms-ci --hub myDevHub --no-data` → `sf org display -o qms-ci --verbose --json`의 `sfdxAuthUrl`을 `SF_AUTH_URL_CI`에 등록 |
| 이슈 | 오픈 이슈 (1) Multi-Currency(D-3, review-pack Vol.5 요청 포함) (2) Unlocked Package 전환 시점 (3) DKBMC 사전 보유 자산 디렉터리 | 결정 대기. D-3은 P6 비용 WI 전, (3)은 필요 시 `force-app-dkbmc` 추가 |
| 후속 WI | CMN-00-ARC-002: `CMN_TestDataFactory`(CR-4), 이관 모드(CR-12), 테스트 대상 객체(DEV-3), 프로필 조회는 `UserLicense.Name` | P1 |
| 후속 | AC-2 실제 CI 차단 확인: push·브랜치 보호·시크릿 등록 후 커버리지 미달 임시 PR로 확인하고 폐기 | T0-7 이후 |

## 6. 배포 정보

- 대상 Org: `qms-int`(Scratch, Dev Hub LSPMSQMS, 2026-12-01 만료) — 통합·게이트용. `qms-ci`(Scratch, Dev Hub myDevHub) — CI 검증용. `qms-spike`(Scratch, myDevHub, 2026-11-04 만료) — 스파이크용, 검사기 확인용 임시 클래스 3개가 배포돼 있음(만료와 함께 사라짐)
- dry-run → 배포 결과: 배포할 메타데이터 없음(빈 패키지 디렉터리)
- 커밋: 제안 `[CMN-00-ARC-001] 패키지 디렉터리·정의 파일·CI·재현 스크립트` (사용자 요청 시)
