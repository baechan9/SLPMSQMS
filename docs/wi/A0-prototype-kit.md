# A0 프로토 공용 장치 보고 (화면 우선 플랜 5.1 2항)

WI가 아닌 개발 도구·화면 골격이다. 항목별로 끝나는 대로 이 문서에 적는다.

| 항목 | 상태 | 비고 |
| --- | --- | --- |
| SL QMS 앱 내비게이션 골격(메뉴 순서, QMS-02~09 메뉴 자리) | 완료 2026-11-02 → CMN-00-UX-007로 흡수(2026-11-05) | 아래 1절. 화면 전략으로 앱 5개·전체 메뉴 모드·미결 배지·번호 바로가기를 UX-007이 확장 |
| `CMN_Prototype`(`notYetAvailable`·`mockResponse`), 기능 스위치 `CMN_PROTOTYPE_MODE`, 정적 리소스 `CMN_PrototypeMocks`, 라벨 | 완료 2026-11-06 | 아래 2절 |
| 검토용 PS `QMS_PS_Prototype_Review` | 완료 2026-11-06 | 아래 3절 |
| `scripts/ci/check-prototype-stubs.py` | 완료 2026-11-06 | 아래 4절 |
| 데모 로더 `--upto-bundle`, 화면 인벤토리 템플릿 | 완료 2026-11-06 | 아래 5절 |

## 1. 앱 내비게이션 골격(2026-11-02)

> 2026-11-05 CMN-00-UX-007로 개편했다(앱 5개, SL QMS 탭 13개 → 4개, 전체 메뉴 허브). 현재 구성은 `docs/wi/CMN-00-UX-007.md` 2절이 기준이고, 아래는 골격 당시 기록이다.

### 1.1 구성

SL QMS 앱 탭(순서):

| 순서 | 탭 | 내용 |
| --- | --- | --- |
| 1 | 홈 `CMN_QMS_Home` | 내 할 일(To-Do 목록) + 위젯 대시보드(CMN-00-TDO-004) |
| 2 | 결재 현황 `CMN_ApprovalMonitor` | APV-003 |
| 3~10 | 개발 품질 `QMS_Menu02` ~ 연계 `QMS_Menu09` | QMS-02~09 메뉴 허브(메뉴 번호 순서) |
| 11 | 공통 업무 `CMN_MenuWork` | To-Do·결재·대리결재·회의·조치 항목·문서·표준 양식 |
| 12 | 기준정보 `CMN_MenuMaster` | 법인·공장·라인·공정·부서·임직원·고객/협력사·차종·제품군·품번·협력사 품번·품질 특성·공통 코드·공장 권한·CFT 역할 |
| 13 | 내 대시보드 `CMN_QMS_Dashboard` | 위젯 보드(모바일에서 홈과 분리, TDO-004 BR-3) |

SL PMS 앱: 홈 `CMN_PMS_Home`, 결재 현황, 공통 업무, 기준정보, 내 대시보드 `CMN_PMS_Dashboard`(PMS 메뉴는 PMS Vol. 작성 후).

### 1.2 메뉴 허브

- 메뉴마다 앱 페이지 1개(`flexipage:defaultAppHomeTemplate`) + LWC `cmnAppMenuHub`(속성 `menuKey`).
- 설정은 메타데이터: `CMN_AppMenu__mdt`(메뉴 10건: QMS_02~09, CMN_WORK, CMN_MASTER — 제목·설명 라벨, 아이콘), `CMN_AppMenuItem__mdt`(기능 타일 68건 — 기능 코드, 제목·설명 라벨, 대상 유형 OBJECT·PAGE·NONE, 대상, 1차 화면 묶음).
- 타일 상태: 대상이 있으면 "사용 가능 + 열기"(OBJECT = 객체 목록, PAGE = 앱 페이지 탭), 없으면 "준비 중 · 1차 화면 A{n} 묶음". OBJECT 대상은 읽기 권한이 없거나 배포되지 않았으면 숨긴다(서버 `CMN_AppMenuController`). 제목 라벨이 없는 OBJECT 타일은 객체 복수 라벨(번역됨)을 쓴다.
- QMS 기능 타일은 WI 기능 코드 단위(DVQ, IQC, NCR …). QMS-07·08·09는 기능 코드가 하나라 화면 묶음 단위(종합 대시보드, 위젯, 원인 추천, 동기화 모니터 …)로 나눴다.
- **각 묶음(A1~A7)이 화면을 만들면 해당 타일의 `TargetType__c`·`Target__c`를 채운다**(필요하면 기능 하나를 화면별 타일 여러 개로 나눈다). 객체 탭을 앱 내비게이션에 직접 늘어놓지 않고 메뉴 허브에서 연다(탭 수십 개가 내비게이션을 덮는 것 방지). 자주 쓰는 작업 화면(수입검사 대기열 등)만 명세가 앱 페이지로 정한 경우 내비게이션에 더한다.

### 1.3 권한

- `QMS_PS_Menu_Read`(force-app-qms, QMS 메뉴 허브 탭 8개) → SL QMS 앱을 쓰는 PSG 14개(QMS 사내 12 + CMN 경영진·시스템 관리자).
- `CMN_PS_AppQms_Read`·`CMN_PS_AppPms_Read` + 공통 메뉴 허브 탭·홈·내 대시보드 탭, 클래스 `CMN_AppMenuController`.

### 1.4 결정

| 결정 | 내용 |
| --- | --- |
| 메뉴 허브 메타데이터 신설 | 명세에 없는 설정 객체 2개(`CMN_AppMenu__mdt`·`CMN_AppMenuItem__mdt`)를 프로토 공용 장치로 만들었다. 메뉴 구성을 배포 없이 고치려는 것이 아니라, 화면이 생길 때마다 타일 상태를 데이터로 바꾸고 문구를 라벨(3개 언어)로 관리하려는 것이다. R1 이후에도 메뉴 첫 화면으로 유지할지는 R1에서 확인. 2026-11-05 화면 전략에서 메뉴 허브를 표준으로 확정했다(UX-007, 결정 DS-4). 이름은 그대로 쓴다 |
| 타일 권한 | OBJECT 타일만 서버에서 읽기 권한으로 거른다. PAGE 타일은 탭 표시 권한을 Salesforce가 열 때 확인한다 |
| 표준 홈 제외 | SL QMS·SL PMS 앱 내비게이션에서 표준 홈 탭을 빼고 앱 페이지 "홈"을 첫 탭으로 둠(TDO-004 BR-1) |

### 1.5 검증

- Apex `CMN_AppMenuController_Test` 4건(타일 상태·순서·객체 라벨, 권한 없는 객체 숨김, 메뉴 키 검증, 배포된 메뉴 설정 무결성) 통과. 커버리지 CMN_AppMenuController 89%, CMN_AppMenuSelector 100%.
- Jest `cmnAppMenuHub` 3건(타일·준비 중 묶음·열기 버튼, 객체/페이지 이동, 빈·오류). 전체 Jest 81건 통과.
- 개발 Org(관리자): 10개 메뉴 모두 열림. QMS-02~06 타일은 전부 준비 중, QMS-07 "내 대시보드"·QMS-09 "연계 로그" 사용 가능, 공통 업무 11개 중 9개, 기준정보 16개 모두 사용 가능.

## 2. 자리 구현과 목 응답(2026-11-06)

- `CMN_Prototype`:
  - `notYetAvailable()`: A단계 업무 동작 서비스 메서드(명세 시그니처 그대로)의 본문이다. 라벨 `CMN_Prototype_NotYetAvailable` 문구로 `CMN_ValidationException`을 던진다. 화면 컨트롤러가 검증 예외를 라벨 문구 그대로 보내므로 화면에는 "상세 기능 개발 단계에서 동작합니다"가 보인다.
  - `mockResponse(queryKey, params)`: 정적 리소스 `CMN_PrototypeMocks`에서 Snowflake 조회 예시 응답을 돌려준다. 형식은 spec-snowflake-display.md 그대로이고, `params.case`로 ok·empty·stale·truncated·error-timeout을 고른다. 응답에 `isMock = true`를 더한다.
  - `isActive()`: 세 조건을 모두 만족할 때만 true다. (1) 기능 스위치 `CMN_PROTOTYPE_MODE`(IsOn, 필요 PS = 검토용 PS) (2) 사용자에게 `QMS_PS_Prototype_Review` (3) Scratch Org(Organization.IsSandbox이면서 TrialExpirationDate가 있음). 그래서 운영·SIT에서는 목이 응답하지 않는다(결정 SF-2, DEV-1 해소안).
- **목 묶음:** `scripts/dev/build-prototype-mocks.py`가 `data/demo/mocks/dwh/{QueryKey}/{case}.json`(30개 조회 키, 응답 41개, 221KB)을 하나로 묶는다. `scripts/dev/sync-fixtures.sh --check`(CI·wi-check)가 최신인지 확인한다.
- **화면 표시:** `cmnPrototypeBadge`(라벨 `CMN_Prototype_MockBadge` "예시 데이터")를 목 응답을 그리는 화면 구석에 둔다(`show={isMock}`).
- **검증:**
  - Apex `CMN_Prototype_Test` 3건(안내 문구, 세 조건 조합, 배포된 리소스와 실제 Org 판정). 커버리지 95%.
  - Jest 1건.
  - 개발 Org 관리자로 `QMS_B2B_PARETO` 응답(3행, isMock)을 확인했다.

## 3. 검토용 열람 PS(2026-11-06)

- `QMS_PS_Prototype_Review`(force-app-qms)는 정의 파일의 `viewAllObjects`(metagen 새 옵션)로 만든다.
  - `CMN_`·`QMS_` 사용자 정의 객체는 모두 읽기 + 모두 보기다. 주종 하위 객체는 읽기만이다.
  - 의존하는 표준 객체 Account는 읽기다.
  - 제외: 테스트 객체 2개, 로그, 채번 카운터.
  - 새 메뉴 객체는 정의만 더하면 자동으로 들어온다. 현재 33개 객체다.
- PSG에 넣지 않는다. `scripts/org/build-scratch.sh`가 관리자에게 항상 할당하고, `--review`면 검토 페르소나(E1101·E1102·E1104·E1112)에게도 할당한다.
- B단계에서 메뉴별 공유가 들어오면 그 메뉴 객체를 `exclude`에 더한다. 전 메뉴 B단계 후 삭제한다(사용자 승인).
- 개발 Org(`qms-dev-a`) 관리자에게 할당했다.

## 4. 자리 구현 참조 수(2026-11-06)

- `scripts/ci/check-prototype-stubs.py`는 `CMN_Prototype.notYetAvailable·mockResponse·isActive`와 라벨 `CMN_Prototype_NotYetAvailable` 참조를 메뉴·WI·파일별로 센다.
  - WI는 파일 머리의 WI ID(@group 등)로 정한다.
  - `--menu QMS-03`처럼 메뉴를 주면, 참조가 남아 있을 때 종료 코드 1이다(그 메뉴 B단계 완료 조건).
- CI와 wi-check에서는 보고만 한다. 지금은 0건이다. 샘플 클래스로 메뉴·WI 판정과 `--menu` 실패를 확인했다.

## 5. 데모 로더 묶음 범위·화면 인벤토리 템플릿(2026-11-06)

- **로더:** `scripts/demo/load_salesforce.sh <org> --upto-bundle A{n}`은 screen-map.csv의 화면 묶음으로 객체 소유 WI를 걸러 A{n}까지 적재한다.
  - `--upto-phase`와 함께 주면 둘 다 만족해야 적재한다.
  - 건너뛴 파일은 "A{n} 묶음 소유"로 요약한다.
  - dry-run(A0)으로 A1~A6 소유 파일 70개가 빠지는 것을 확인했다.
- **Scratch 생성:** `scripts/org/build-scratch.sh <별칭> --bundle A{n} --review`가 묶음 검토 Org를 준비한다(데모 적재 + 검토 PS).
- **화면 인벤토리 템플릿:** `docs/docs/30-dev/screens/_template.md`. 화면 목록(화면 ID·유형 T1~T8·공통 부품·진입 경로·페르소나·모바일), 업무 동작 자리 구현, 목 응답, 데모 데이터, 프로토 한계, 확인 기록으로 이루어진다.

