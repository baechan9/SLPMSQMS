# CMN-00-DSH-001 완료 보고 — 위젯 대시보드 프레임워크

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-DSH-001 (vol0-cmn-common.md CMN-00-DSH-001) |
| Wave / 공수(계획 → 실제) | W1 / 7 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료(화면 우선 플랜 A0 첫 항목 — 결정 SF-8에 따라 상세 기능까지 완료) |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack Vol.7 변경 요청(ConfigSchema·AvailableSystems·MobileSupported, 설정 검증 인터페이스, 템플릿 해석기·등록 메타, Persona 추가, 복사 시 건너뛰기) 반영 |

## 1. AC 결과

| AC | 확인 | 결과 |
| --- | --- | --- |
| AC-1 신규 품질팀장, QMS 홈 첫 진입 → QUALITY_MANAGER 템플릿 | `CMN_DashboardService_Test.test_AC01_qualityManagerGetsTemplateOnFirstOpen`: 실제 PSG `QMS_PSG_QualityManager`(테스트에서 재계산) 사용자 → 품질팀장 템플릿 구성, 비활성·PMS 전용·권한 없음·미배포 위젯은 건너뜀, 보드 1건 저장(다시 열어도 1건). PSG가 맞지 않는 사용자는 시스템 기본. 화면: `cmnWidgetBoard` Jest(템플릿 배치를 12열 그리드로) | 통과 |
| AC-2 위젯 추가·순서·크기 변경 후 저장 → 재로그인 후 동일 | `test_AC02_savedLayoutReloadsSame`(저장 후 다시 읽기: 순서·크기·설정 동일, 순서 번호는 목록 순서로 다시 매김). 화면: Jest(갤러리에서 추가, 아래로 이동, 크기 L, 저장 JSON 확인) | 통과 |
| AC-3 위젯 1개 예외 → 나머지 정상 | `cmnWidgetFrame`: 위젯 칸마다 `errorCallback`·로드 실패를 그 칸의 오류(다시 시도)로 한정. Jest(로드 실패 위젯은 오류, 이름이 잘못된 컴포넌트는 로드 안 함). 위젯 Jest에서 실제로 "서버가 빈 응답이면 To-Do 위젯 렌더링 예외"를 찾아 고쳤고, 그때도 프레임이 칸 안에서 격리한 것을 확인 | 통과 |
| AC-4 위젯 8개, 첫 화면 3초 | 화면에 보일 때 로드(Intersection Observer), 위젯별 비동기 조회. 측정은 UAT(해외 공장 포함) | 구조 반영, 측정은 UAT |
| BR-1 12열·모바일 12열 | S 4열·M 6열·L 12열(`slds-medium-size_*`), 모바일은 `slds-size_1-of-1` | 통과(Jest) |
| BR-2 갤러리 권한, 권한 잃은 위젯 자리표시 | `test_BR2_lostAccessStaysAsPlaceholderButCannotBeAdded`(권한 없음·사용 불가 자리표시, 컴포넌트 이름 미전달, 기존 위젯은 유지 저장 가능, 새로 추가는 거부), `test_BR3_resetAndGallery`(갤러리 = 시스템·권한·활성 기준) | 통과 |
| BR-3 템플릿으로 초기화 | `test_BR3_resetAndGallery`, Jest(확인 대화상자 후 초기화) | 통과 |
| BR-4 위젯 계약 | `@api config`·`@api size`, 위젯 내부 오류·다시 시도(기본 위젯 2종 Jest) | 통과 |
| BR-5 위젯 데이터 원칙 | 기본 위젯은 집계 SOQL(사용자 모드): `CMN_CoreWidgetController_Test`(To-Do 시스템·공장·기한 경과, 결재 대기 오래된 순·대기 일수) | 통과 |
| BR-6 공통 필터 우선 | 프레임이 공장·기간을 config보다 우선 병합(Jest), 위젯 서버가 공장 필터 적용(Apex) | 통과 |

## 2. 구현 내역

- 메타데이터
  - `CMN_Widget__mdt`(ComponentName·System·AvailableSystems·Category·Title/DescLabel·DefaultSize·RequiredPermissionSet·DefaultConfig·ConfigSchema·MobileSupported·IsActive), 기본 위젯 2건(`CMN_W_TODO_SUMMARY`, `CMN_W_APPROVAL_PENDING`).
  - `CMN_DashboardTemplate__mdt`(System·Persona 10종·TitleLabel·PermissionSetGroups·Priority·IsDefault), `CMN_DashboardTemplateItem__mdt`(Template·Widget 메타데이터 관계, Order·Size·Config), 템플릿 3건(QMS 기본, QMS 품질팀장, PMS 기본).
  - `CMN_DashboardResolver__mdt`(Kind TEMPLATE_RESOLVER·CONFIG_VALIDATOR, ClassName·System·Order·IsActive) — 콘텐츠 WI가 등록.
  - `CMN_UserDashboard__c`(User·System·LayoutJson·SourceTemplate·UniqueKey `{UserId}:{System}`, OWD Private).
  - PS `CMN_PS_Dashboard_User`(보드 객체 편집, 컨트롤러 2개) → 사내 PSG 14개. 라벨 47개(ko·en_US·zh_CN).
- Apex
  - 인터페이스 `CMN_DashboardTemplateResolver`(템플릿 선택·config 토큰 치환), `CMN_WidgetConfigValidator`(저장 시 설정 검증).
  - `CMN_DashboardService`: 보드 조회(없으면 템플릿 복사), 저장 검증(등록·활성·권한·크기·설정 크기 8,000자·최대 24개·검증기), 초기화, 갤러리, 위젯 상태(OK·NO_ACCESS·UNAVAILABLE), 라벨 해석. 템플릿 선택 = 해석기 → PSG 일치(우선순위) → 시스템 기본.
  - `CMN_DashboardSelector`(메타데이터 긴 텍스트는 getAll()이 255자로 자르므로 SOQL, 권한 셋·PSG 구성 조회), `CMN_DashboardController`(getBoard·saveBoard·resetBoard·getGallery), `CMN_CoreWidgetController`(todoSummary·approvalSummary, 사용자 모드 동적 SOQL).
- LWC
  - `cmnWidgetBoard`(홈·앱 페이지, 속성 systemCode): 공통 필터(공장 레코드 선택·기간), 편집 모드(갤러리 추가·제거·앞뒤 이동·크기·설정 JSON), 저장·취소, 템플릿 초기화.
  - `cmnWidgetFrame`(`lightning__dynamicComponent`): `lwc:is` 동적 로드(컴포넌트 이름 형식 검증), Intersection Observer 지연 로드, 오류 격리, 자리표시(권한 없음·사용 불가·모바일 미지원).
  - 기본 위젯 `cmnWidgetTodoSummary`(할 일·결재·기한 경과), `cmnWidgetApprovalPending`(오래 기다린 결재, 요청 열기).

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지 | CMN_CoreWidgetController 97%, CMN_DashboardSelector 95%, CMN_DashboardController 92%, CMN_DashboardService 91% |
| Apex 테스트 | 11건 통과(DSH-001 신규) |
| LWC Jest | 전체 71건 통과(DSH-001 11건) |
| Code Analyzer / LWC 모바일 규칙 / 한글 리터럴 / 이름 가림 | 0건 / 0건 / 0건 / 0건 |

## 4. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 결정 | 템플릿과 사용자 PSG 연결은 템플릿 메타의 `PermissionSetGroups__c`(쉼표 목록)·`Priority__c`·`IsDefault__c`로 정했다(명세는 "PSG에 맞는 기본 템플릿"만 규정). 해석기가 등록되면 먼저 묻는다 | 보고 |
| 결정 | 확장 등록 메타 하나(`CMN_DashboardResolver__mdt`, Kind로 구분)에 템플릿 해석기와 설정 검증기를 함께 둔다(Vol.7 변경 요청의 두 인터페이스) | 보고 |
| 결정 | 저장 제한: 위젯 24개, 위젯 설정 8,000자, 배치 32,768자. 새로 넣는 위젯만 권한·활성 확인(이미 있던 위젯은 권한을 잃어도 자리표시로 유지 — BR-2) | 보고 |
| 결정 | `cmnWidgetConfigForm`(QMS-07-DSH-004)이 생기기 전까지 편집 모드 설정은 JSON 입력(ConfigSchema가 있는 위젯만 설정 버튼) | DSH-004에서 교체 |
| 결정 | 기본 위젯 2종(To-Do 요약·결재 대기)을 공통 위젯으로 추가 — 홈(TDO-004)과 프레임워크 확인용 | 보고 |
| 미검증 | AC-4 성능(UAT), 실제 홈 배치 화면 | TDO-004(A0 다음 항목)·UAT |
| 후속 | 품질 위젯·역할별 템플릿 항목 | QMS-07(A7) |

## 5. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-DSH-001] 위젯 대시보드 엔진·보드·프레임·기본 위젯 2종`
