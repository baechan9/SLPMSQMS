# CMN-00-APV-003 완료 보고 — 결재 상신·처리·이력 UI

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-APV-003 (vol0-cmn-common.md CMN-00-APV-003) |
| Wave / 공수(계획 → 실제) | W1 / 6 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료(화면 배치·모바일 실기기 확인은 사용자 확인 항목) |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의) |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 모바일 웹 결재자, 의견 없이 반려 → 버튼 비활성 + 서버 차단 | 화면: `cmnApprovalAction` Jest(의견 입력 전 반려 버튼 disabled, 입력 후 활성·호출). 서버: `CMN_ApprovalController_Test.test_AC01_rejectWithoutCommentBlockedOnServer`(공백 의견 반려 → `CMN_Approval_CommentRequired` 라벨 오류, 단계 PENDING 유지, 의견 있으면 반려). 컴포넌트는 Small 폼팩터 포함 | 통과(실기기는 사용자 확인) |
| AC-2 Version 1 반려·Version 2 승인 → 두 버전 구분, 시간순 | `test_AC02_historyShowsVersionsInOrder`(버전 1 REJECTED·의견·SKIPPED 단계, 버전 2 APPROVED, 결재 요청 Id로 열어도 대상 전체 이력). 화면: `cmnApprovalHistory` Jest(버전 순 구분, 대결 표시) | 통과 |
| AC-3 저장한 PERSONAL 결재선을 다른 건에서 불러오기 → 같은 결재자 구성, 필수 단계 유지 | `test_AC03_personalLineKeepsMandatorySteps`(개인: 합의 A·승인 공장장 → 불러오면 필수 검토 품질팀장(1)·합의 A(1)·필수 승인 공장장(3), 중복 제거, 불러온 그대로 상신 성공) | 통과 |
| BR-1 이름·사번·부서명 검색, 비활성 제외 | `test_BR1_searchByNameEmployeeNoDepartmentActiveOnly`(사번·부서명·이름, 비활성 제외, 2자 미만 거부) | 통과 |
| BR-2 상신 버튼은 상신 가능 상태에서만 | `test_BR2_submitButtonStateAndRecall`(상신 전 가능, 진행 중이면 불가·기안자 회수 가능, 콜백 `canSubmit` 거절 사유 표시) | 통과 |
| BR-3 체류일수 | `test_BR3_monitorViewsFiltersAndPendingDays`(현재 PENDING 시작 3일 전 → 3일, 내가 상신·진행 중·내가 처리 보기, 유형·공장·기간 필터, 잘못된 보기 거부). 화면: `cmnApprovalMonitor` Jest | 통과 |
| (APV-004 연계) 대결 처리 | `test_delegateSeesTurnAndHistoryShowsOnBehalf`(대리인 처리 화면에 위임자 표시, 승인 후 이력 "처리자(대결: 위임자)") | 통과 |

## 2. 구현 내역

- LWC(모두 Large·Small)
  - `cmnApprovalLine`(업무 레코드 페이지, 속성 typeCode): 해석된 결재선 표시·편집(단계 추가·삭제·유형 변경, 필수 단계 잠금, 템플릿이 편집 금지면 읽기 전용), 결재자 검색, 상신 의견·상신, 회수(첫 처리 전·기안자), 개인 결재선 저장·불러오기, 진행 중이면 현재 상태 표시.
  - `cmnApprovalAction`(결재 요청 레코드 페이지, To-Do에서 열림): 상신 시점 스냅숏(보는 사람의 필드 권한만큼), 대상 레코드 열기, 승인·반려(반려는 의견 필수), 대결 안내, 처리 차례가 아니면 안내.
  - `cmnApprovalHistory`(업무 레코드 페이지 또는 결재 요청 페이지): 모든 버전의 단계별 처리자·일시·의견, 대결 표시.
  - `cmnApprovalMonitor`(앱 페이지 `CMN_ApprovalMonitor`, 탭 "결재 현황"): 내가 상신 / 내가 처리 / 진행 중 탭, 유형(결재 유형 메타데이터)·공장(레코드 선택)·상신 기간 필터, 체류일수, 결재 번호로 요청 열기. 최근 200건.
- Apex
  - `CMN_ApprovalController`: getLine, searchApprovers, submit, recall, savePersonal, loadPersonal, getAction, approve, reject, getHistory, getTypes, getMonitor. 모든 입력(Id 유형, 유형 코드 형식, 결재선 JSON 엄격 역직렬화·30단계 이하, 검색어 2~40자, 보기 값) 서버 검증. 오류는 라벨 문구, 원문은 `CMN_Logger`.
  - `CMN_ApprovalUiSelector`(with sharing): 이력·요청(공유로 볼 수 있는 것만), 모니터 동적 SOQL(`queryWithBinds` + USER_MODE), 결재자 검색, 부서명, 개인 템플릿.
  - 재사용을 위해 공개: `CMN_ApprovalService.submitRefusal`(상신 가능 판정 = submit과 같은 규칙, 콜백 교체 가능), `CMN_ApprovalLineResolver.templateFor`(공장 템플릿 우선 규칙).
- 메타데이터
  - 레코드 페이지 `CMN_ApprovalRequest_Record`(처리 + 상세 + 이력)를 결재 요청 기본 보기(데스크톱·모바일)로 지정. 생성기에 객체 `recordPage` 키 추가(`docs/dev/metadata-generator.md`).
  - 앱 페이지·탭 `CMN_ApprovalMonitor`, SL QMS·SL PMS 앱 탭, `CMN_PS_Approval_User`에 탭·클래스 접근.
  - 라벨 50개(ko·en_US·zh_CN, `meta-src/cmn/labels/CMN-00-APV-003.json`).
- 개발 환경: Scratch 정의에 `deploymentSettings.doesSkipAsyncApexValidation`(예약 잡이 걸린 클래스 재배포 허용). 기존 Org는 `build-scratch.sh --reuse`가 `scripts/org/mdapi/deployment-settings`로 적용. 패키지 소스에는 넣지 않았다(운영 배포 설정은 릴리즈 절차가 정한다).

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지 | CMN_ApprovalController 97%, CMN_ApprovalUiSelector 100%, CMN_ApprovalService 95%, CMN_ApprovalLineResolver 93% |
| Apex 테스트 | APV-003 8건 + 결재·결재선·위임·독촉 회귀 통과(45건) |
| LWC Jest | 60건 통과(APV-003 12건) |
| Code Analyzer / LWC 모바일 규칙 / 한글 리터럴 | 0건 / 0건 / 0건 |
| Apex 이름 가림(경고) | 1건: 화면 선택지 DTO 필드 `label`(LWC 콤보박스 형식 {label, value}). 내부 클래스 필드라 `Label.*` 참조와 겹치지 않음 — 유지 |

## 4. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 결정 | 개인 결재선 불러오기 병합: 템플릿 필수 단계를 먼저 두고 개인 단계를 더한 뒤 단계 순으로 정렬(같은 순서는 필수 단계 먼저), 같은 유형·결재자는 중복 제거 | 보고(AC-3 해석) |
| 결정 | 스냅숏 표시는 보는 사람의 필드 읽기 권한만큼(대상 객체 FLS가 없는 결재자에게는 빈 목록). 상신 시점 값이라 대상 레코드를 열어 현재 값을 볼 수 있게 링크 제공 | 보고 |
| 결정 | 이력 컴포넌트를 결재 요청 페이지에 두면 그 요청의 대상 이력을 보인다(요청 페이지에서도 버전 비교 가능) | 보고 |
| 결정 | 모니터 "진행 중"은 공유로 볼 수 있는 진행 중 결재(관리자는 전체). 결재 유형 필터 선택지는 `CMN_ApprovalType__mdt` | 보고 |
| 오픈 이슈 | BR-3 체류일수의 공장 시간대·영업일 기준(현재 사용자 시간대 달력일) | 명세 오픈 이슈 유지 |
| 배치 | `cmnApprovalLine`·`cmnApprovalHistory`의 업무 레코드 페이지 배치는 각 업무 WI가 typeCode와 함께 한다(4M·PPAP·문서 등) | 업무 WI |
| 미검증 | 모바일 앱·모바일 웹 실기기 결재 처리(UX-001 AC-2), 앱 탭·레코드 페이지 실제 표시 | 사용자 UI 확인 항목 |
| 후속 | UX-001 AC-2(모바일 웹 결재)는 이 WI의 `cmnApprovalAction`(Small)으로 충족 | UX-001 보고서 갱신 |

## 5. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS). 배포 전 DeploymentSettings 적용(예약 잡 `CMN_ApprovalReminderJob` 때문에 `CMN_ApprovalService` 재배포가 막혔던 문제).
- dry-run → 배포: 성공
- 커밋: `[CMN-00-APV-003] 결재선 편집·상신, 처리, 이력, 결재 현황 화면`
