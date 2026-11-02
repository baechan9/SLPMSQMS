# CMN-00-TDO-004 완료 보고 — QMS·PMS 메인 홈

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-TDO-004 (vol0-cmn-common.md CMN-00-TDO-004) |
| Wave / 공수(계획 → 실제) | W1 / 3 M/D → 약 0.5 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료(화면 우선 플랜 A0 — 업무 규칙이 화면 규칙뿐이라 상세 기능까지 완료) |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의) |

## 1. AC 결과

| AC | 확인 | 결과 |
| --- | --- | --- |
| AC-1 QMS 업무 3·PMS 업무 2, SL QMS 홈 → 기본 필터 QMS 3건, 전체 5건 | `CMN_TodoListController_Test.test_AC01_qmsFilterThenAll`(QMS 3, 전체 5, PMS 2). 화면: `cmnTodoList` Jest(앱 기본 시스템으로 조회, 필터 전체로 바꾸면 다시 조회). 개발 Org 확인: 관리자 데모 To-Do로 QMS 4건(QMS 3 + 공통 1), 전체 6건 | 통과 |
| AC-2 첫 화면 To-Do 3초 이내(위젯은 지연 로딩) | To-Do는 1회 조회(목록 20건 + 건수 집계 1회), 위젯 보드는 프레임이 화면에 보일 때 로드(DSH-001). 측정은 UAT | 구조 반영, 측정은 UAT |
| BR-1 앱 홈 = 앱 페이지, 상단 To-Do(업무/결재 탭·건수·기한 경과·시스템 필터), 하단 위젯 보드 | 앱 페이지 `CMN_QMS_Home`·`CMN_PMS_Home`(탭 "홈", 앱 내비게이션 첫 항목), `cmnTodoList` + `cmnWidgetBoard`. 기한 경과는 빨간 글씨 + "기한 경과" 배지(색만으로 구분하지 않음) | 통과 |
| BR-2 항목 클릭 = 업무 레코드(결재는 결재 요청), 20건 + 더 보기 | `test_BR2_pagesOf20OrderedByDueDate`(20건 + 더 보기, 기한 빠른 순·기한 없음 뒤), `test_BR2_approvalOpensApprovalRequest`(결재 To-Do → 결재 요청). Jest(더 보기, 항목 열기) | 통과 |
| BR-3 모바일은 To-Do만, 위젯은 "대시보드" 탭 | 홈의 위젯 보드에 `hideOnPhone=true`(휴대폰에서 그리지도 읽지도 않음, Jest), 별도 앱 페이지 탭 "내 대시보드"(`CMN_QMS_Dashboard`·`CMN_PMS_Dashboard`) | 통과(실기기 확인은 R1·SIT) |

## 2. 구현 내역

- Apex `CMN_TodoListController.getTodos(category, systemFilter, offsetRows)`: 사용자 모드 조회, 입력 검증(TASK·APPROVAL, QMS·PMS·ALL, 0~2000), 제목은 `CMN_TodoService.renderTitle`(사용자 언어), 결재 To-Do는 원천 결재 단계 → 결재 요청 Id(단계를 읽을 수 없으면 업무 레코드).
- LWC `cmnTodoList`(앱·홈 페이지, 속성 systemCode QMS·PMS·ALL): 업무·결재 탭(건수), 시스템 필터, 새로 고침, 기한·기한 경과·대결 표시, 더 보기, 로딩·빈·오류(다시 시도).
- `cmnWidgetBoard` 속성 `hideOnPhone` 추가(DSH-001 컴포넌트, BR-3 때문에 이 WI에서 추가).
- 앱 페이지·탭: `CMN_QMS_Home`, `CMN_PMS_Home`, `CMN_QMS_Dashboard`, `CMN_PMS_Dashboard`. SL QMS·SL PMS 앱 첫 탭을 표준 홈에서 이 앱 페이지로 바꿈.
- 권한: `CMN_PS_Todo_User` + 클래스 `CMN_TodoListController`, `CMN_PS_AppQms_Read`·`CMN_PS_AppPms_Read` + 홈·내 대시보드 탭. 라벨 13개(ko·en_US·zh_CN).

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지 | CMN_TodoListController 96% |
| Apex 테스트 | 5건 통과(TDO-004 신규), 회귀 DSH-001·위젯 컨트롤러 함께 통과 |
| LWC Jest | 전체 81건 통과(cmnTodoList 5, cmnWidgetBoard 휴대폰 2 신규) |
| Code Analyzer / LWC 모바일 규칙 / 한글 리터럴 | 0건 / 0건 / 0건 |

## 4. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 결정 | 시스템 필터 QMS·PMS는 그 시스템 + 공통(CMN) To-Do를 보여준다(공통 결재·회의 조치는 어느 홈에서나 보이게). 위젯 To-Do 요약(DSH-001)과 같은 기준. AC-1은 공통 To-Do가 없을 때 그대로 성립 | 보고 |
| 결정 | 앱 홈은 표준 홈 탭 대신 앱 페이지 탭 "홈"을 첫 탭으로 둔다(명세 BR-1 "앱 홈 = Lightning App Page"). 표준 홈은 앱 내비게이션에서 뺐다 | 보고 |
| 결정 | 모바일 대시보드 탭 이름은 "내 대시보드"(QMS-07 메뉴 "품질 대시보드"와 구분) | 보고 |
| 데모 | 개발 Org 관리자에게 화면 확인용 To-Do 6건(QMS 3·PMS 2·공통 1, 원천 유형 `DEMO_HOME`, 제목은 기본 제목) | 검토 Org 적재는 R1 준비 때 |
| 미검증 | AC-2 성능, 휴대폰 실기기 | UAT·R1 |

## 5. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch)
- dry-run → 배포: 성공(`scripts/dev/wi-check.sh`, A0 앱 내비게이션 골격과 함께)
- 커밋: `[CMN-00-TDO-004] 메인 홈(To-Do 목록·위젯 보드)과 QMS 메뉴 허브 내비게이션(A0)`
