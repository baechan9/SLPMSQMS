# A0 프로토 공용 장치 보고 (화면 우선 플랜 5.1 2항)

WI가 아닌 개발 도구·화면 골격이다. 항목별로 끝나는 대로 이 문서에 적는다.

| 항목 | 상태 | 비고 |
| --- | --- | --- |
| SL QMS 앱 내비게이션 골격(메뉴 순서, QMS-02~09 메뉴 자리) | 완료 2026-11-02 → CMN-00-UX-007로 흡수(2026-11-05) | 아래 1절. 화면 전략으로 앱 5개·전체 메뉴 모드·미결 배지·번호 바로가기를 UX-007이 확장 |
| `CMN_Prototype`(`notYetAvailable`·`mockResponse`), 기능 스위치 `CMN_PROTOTYPE_MODE`, 정적 리소스 `CMN_PrototypeMocks`, 라벨 | 대기 | A1 착수 전 |
| 검토용 PS `QMS_PS_Prototype_Review` | 대기 | A1 착수 전 |
| `scripts/ci/check-prototype-stubs.py` | 대기 | |
| 데모 로더 `--upto-bundle`, 화면 인벤토리 템플릿 | 대기 | |

## 1. 앱 내비게이션 골격(2026-11-02)

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
