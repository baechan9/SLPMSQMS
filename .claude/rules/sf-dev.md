---
paths:
  - "force-app*/**"
  - "scripts/apex/**"
  - "scripts/soql/**"
  - "manifest/**"
  - "config/**"
  - "sfdx-project.json"
---

# Salesforce 개발 지침 (SL QMS·PMS)

Salesforce 메타데이터·Apex·LWC·테스트·배포 작업에만 적용한다(위 paths의 파일을 다룰 때 자동으로 로드된다). WI 문서 작성에는 `docs/CLAUDE.md`를 따른다. 코드 예시와 전체 한도 표는 필요할 때 `docs/dev/reference-apex.md`, `reference-lwc.md`, `reference-testing.md`를 읽는다.

## 1. 우선순위

규칙이 충돌하면 아래 순서로 따른다. 위에 있는 문서가 이긴다.

1. 구현 대상 WI 명세(`docs/docs/10-workitems/vol*.md`의 해당 WI 절): 객체·필드 API명, BR, AC
2. `docs/docs/10-workitems/interfaces.md`: 다른 메뉴 객체·서비스·이벤트·게이트웨이의 이름과 소유
3. Vol.0 3.2 명명 규칙, 3.3 완료 기준, CMN-00-ARC-001~003
4. 이 지침
5. 일반 Salesforce 관행, 설치된 Salesforce 플러그인 스킬의 기본값(프로젝트 규칙이 이긴다)

명세가 모호하거나 서로 모순되면 추측해서 구현하지 않는다. 멈추고 WI ID와 모순 내용을 보고한다.

## 2. 작업 흐름

WI 하나를 `/implement-wi <WI-ID>`로 구현한다. 순서는 아래와 같다.

1. 명세를 읽고 선행 WI가 구현돼 있는지 확인한다.
2. 계획을 세우고 AC별 테스트를 먼저 작성한다.
3. 구현한다.
4. 린트·테스트·정적 분석을 통과시킨다.
5. Scratch Org에 dry-run 후 배포한다.
6. 자체 리뷰를 거친다.
7. 완료 보고서를 쓰고 개발 현황(DEV-STATUS)을 갱신한다.

변경은 WI 범위 안에서만 한다. 범위 밖 수정이 필요하면 따로 보고하고, 다른 WI의 객체를 함께 고치지 않는다.

## 3. 보안

- **SOQL·DML 권한**
  - 정적 SOQL은 `WITH USER_MODE`를 쓴다. `WITH SECURITY_ENFORCED`는 새 코드에 쓰지 않는다.
  - 동적 SOQL은 `Database.queryWithBinds(query, binds, AccessLevel.USER_MODE)`를 쓴다. 문자열을 이어 붙여 WHERE 값을 넣지 않는다.
  - 정렬 필드처럼 바인드할 수 없는 값은 허용 목록으로 검증한다.
  - 사용자 입력에서 비롯된 DML은 `insert as user` / `update as user` 또는 `Database.insert(records, AccessLevel.USER_MODE)`를 쓴다.
- **공유**
  - 모든 클래스는 `with sharing`이 기본이다.
  - `without sharing`은 WI 명세가 허용한 경우만 쓰고, 클래스 머리에 사유 주석(`// SHARING-EXCEPTION: {WI-ID} {사유}`)을 단다. 범위는 읽기 전용 최소 메서드로 한정하고 리뷰에서 확인한다.
  - 시스템 모드(트리거 핸들러, 이벤트 구독, 배치)는 SOQL에 `WITH SYSTEM_MODE`를 명시해 의도를 드러낸다.
- **비밀값**: 자격 증명·토큰·키를 코드, 메타데이터, 저장소에 두지 않는다. 외부 호출은 Named Credential + External Credential만 쓴다(ARC-001 BR-3).
- **오류 메시지**
  - 화면에 보내는 오류는 Custom Label 문구로 만든 `AuraHandledException`이다. `e.getMessage()`나 스택 트레이스를 사용자에게 보내지 않는다.
  - 원문은 `CMN_Logger.error(source, message, recordId, ex)`로 기록한다.
- **입력 검증**: `@AuraEnabled` 메서드는 모든 입력(Id 형식, 필수값, 허용값, 길이)을 서버에서 다시 검증한다. 화면에서 버튼을 숨기는 것은 보안이 아니다.
- **XSS**
  - LWC에서 `innerHTML`과 `lwc:dom="manual"`로 사용자 데이터를 넣지 않는다.
  - Rich Text는 `lightning-formatted-rich-text`로만 표시한다.
- **로그 금지 값**: 개인정보(사번 외 연락처 등), 비용·임율 원문, 토큰을 로그에 남기지 않는다.

## 4. 거버너·성능

- **벌크화**
  - 루프 안에서 SOQL·DML·콜아웃·이벤트 발행을 하지 않는다. 집합(Set·Map) 단위로 한 번에 조회하고 저장한다.
  - 모든 트리거·서비스는 200건 일괄 처리를 전제로 하고, 테스트로 증명한다.
- **비동기 선택**

| 상황 | 사용 |
| --- | --- |
| 콜아웃·체인 작업, 수천 건 이하 | Queueable(필요 시 Transaction Finalizer로 실패 후처리) |
| 5만 건 이상 또는 주기 작업 | Batch Apex + Schedulable |
| 화면에서 5초 넘게 걸릴 수 있는 외부 조회 | Continuation(동시 장기 실행 요청 한도 회피) |
| 다른 메뉴·외부에 사실 통지 | Platform Event(발행 측은 구독을 구현하지 않음) |

- 반복 조회되는 설정·조회 결과는 Platform Cache를 쓴다. 키와 TTL은 WI 명세 또는 `spec-snowflake-display.md` 기준을 따른다.
- 화면 Apex 응답은 화면에 필요한 필드만 담은 DTO로 반환한다. 레코드 전체나 대용량 JSON을 그대로 보내지 않는다.

거버너 한도 수치는 `docs/dev/reference-apex.md` 5절을 본다. 릴리즈마다 바뀔 수 있으니 설계 판단에 쓰기 전에 Salesforce 문서로 다시 확인한다.

## 5. Apex

- **트리거**
  - 객체당 트리거는 1개다. 본문은 `new QMS_NcrTriggerHandler().run();` 한 줄만 둔다.
  - 핸들러는 `CMN_TriggerHandler`(ARC-002)를 상속한다.
  - 같은 객체·같은 시점에 Flow와 Apex를 섞지 않는다.
- **계층**

| 계층 | 이름 | 하는 일 |
| --- | --- | --- |
| 화면 진입점 | `*Controller` | 입력 검증, DTO 변환 |
| 업무 규칙 | `*Service` | 상태 전이, 서비스 API |
| 조회 | `*Selector` | SOQL을 한곳에 모음 |
| 트리거 | `*TriggerHandler` | 트리거 로직 |

  화면 컨트롤러에서 바로 DML을 하지 않는다.
- **하드코딩 금지**
  - Id, 프로필명, 레코드타입 Id, 사용자명을 코드에 넣지 않는다. 레코드타입은 DeveloperName으로 조회한다.
  - 기준값은 Custom Metadata, CMN 설정, 기능 스위치(`CMN_FeatureSwitch.isOn`)로 둔다.
- **공통 서비스 재사용**: 아래 기능을 직접 만들지 않는다. 공통 서비스를 호출한다.

| 기능 | 공통 서비스 |
| --- | --- |
| 결재 | `CMN_ApprovalService` |
| To-Do | `CMN_TodoService` |
| 알림 | `CMN_NotificationService` |
| 채번 | `CMN_NumberingService`(번호는 RecordNo__c, Name은 사람이 읽는 제목) |
| 문서 | `CMN_DocumentService` |
| 공유 | `CMN_SharingService` |
| 로그 | `CMN_Logger` |

  다른 메뉴에 업무를 요청할 때는 `QMS_GatewayFactory.get(바인딩 키)` 게이트웨이를 쓴다(interfaces.md 5절).
- **상태 변경**: 상태 필드는 서비스 메서드로만 바꾼다(FLS Read + 검증). 화면이나 Flow에서 직접 바꾸지 않는다.
- **최신 문법**
  - null 안전 연산자 `?.`와 `??`, `Assert` 클래스(`Assert.areEqual`)를 쓴다.
  - `System.assert*`, `Database.query` 문자열 결합은 새 코드에 쓰지 않는다.
- **ApexDoc**
  - 공개 클래스와 메서드에 `@description`, `@param`, `@return`, `@throws`를 단다.
  - `@group`에는 WI ID를 적는다.
  - 주석은 "왜"를 쓰고, 한국어로 써도 된다. 식별자는 영어로 쓴다.

## 6. LWC

- **데이터 접근**
  - 기본은 Apex 컨트롤러(`@AuraEnabled(cacheable=true)` 조회와 명령형 호출)다.
  - 단일 레코드 하나를 조회하거나 편집하고 서버 업무 규칙이 없는 경우에 한해 Lightning Data Service(`lightning/uiRecordApi`, `lightning-record-form`, `lightning-record-edit-form`)를 쓸 수 있다.
  - LDS를 쓸 때만 `@salesforce/schema` 필드 import를 허용한다.
  - 상태 전이, 다건 조회, 집계, 다른 객체 조합은 Apex로 한다.
- **템플릿**
  - `lwc:if`·`lwc:elseif`·`lwc:else`를 쓰고, `if:true`·`if:false`는 쓰지 않는다.
  - 반복에는 `key`가 필수다. DOM 참조는 `lwc:ref`로 한다.
- **Lightning Web Security**: 전역 객체 조작이나 다른 네임스페이스 DOM 접근을 하지 않는다.
- **외부 라이브러리**: 아래 승인 목록만 정적 리소스 + `lightning/platformResourceLoader`의 `loadScript`로 쓴다. 목록에 없는 라이브러리, CDN 로딩, npm 번들 포함은 금지다. 새로 추가하려면 WI 명세 변경과 사용자 승인이 필요하다.

| 정적 리소스 | 라이브러리 | 용도 | 근거 WI |
| --- | --- | --- | --- |
| cmnChartJs | Chart.js(버전 고정) | SPC 관리도, 대시보드 차트 | QMS-07-DSH-003, QMS-04-SPC-006 |
| (WI 지정 이름) | SheetJS(버전 고정) | DVP&R 등 Excel 내려받기 | QMS-02-DVQ-009 |

- **스타일**
  - SLDS 클래스와 SLDS 전역 스타일링 훅(`--slds-g-*`)만 쓴다. 색·글꼴·간격을 하드코딩하지 않는다.
  - 색 리터럴(`#…`, `rgb()`, `rgba()`, `hsl()`), 컴포넌트 스타일링 훅(`--slds-c-*`), 구 토큰(`--lwc-*`)은 쓰지 않는다. SLDS 2·Cosmos·다크 모드에서 깨지기 때문이다. CI 검사는 `scripts/ci/check-lwc-styling.py`(Vol.0 UX-004)다.
  - 고정 px 폭 레이아웃을 쓰지 않는다(Vol.0 UX-001).
- **화면 표준**(Vol.0 3.4절, `docs/docs/10-workitems/screen-strategy.md`)
  - 상태가 있는 업무 객체의 레코드 페이지는 UX-004 생성기로 만든다: 헤더 7개 필드, "현재 단계" 첫 탭, 사이드바에는 `cmnDecisionRail` 하나.
  - 섹션·버튼 노출은 UX-005 규칙에서 생성한다. 업무 액션 Apex는 첫 줄에서 `CMN_UiRuleService.assertCanExecute`를 호출한다.
  - 공통 부품을 쓴다: 행 편집은 `cmnEditableGrid`(UX-006), 시료·측정 입력은 `cmnFieldEntryShell`(UX-008), 질문지 평가는 `cmnChecklistRunner`(UX-009). 업무 규칙은 각 Provider 구현에 둔다. 같은 일을 하는 메뉴 전용 LWC를 새로 만들지 않는다. 부품이 아직 없으면 해당 UX WI를 먼저 구현한다.
  - 결정 지원 레일 패널 LWC는 `@api recordId`·`@api objectApiName`·`@api config`·`@api variant`를 받고 건수를 `railbadge` 이벤트로 알린다.
  - 콘솔 앱을 쓰지 않는다(DS-7). 콘솔 기능(하위 탭, 고정 영역)을 전제로 화면을 만들지 않는다.
  - 화면 문구는 "동사 + 대상"으로 쓰고, 오류 메시지는 원인과 고치는 법을 한 문장에 담는다.
- **문구**: 화면의 모든 문구는 `@salesforce/label`로 가져온다. 한국어 리터럴을 쓰지 않는다. 번역은 ko·en_US·zh_CN 3종이다.
- **모바일**: 대상 컴포넌트는 `formFactors`에 Small을 포함한다. 바코드는 `lightning/mobileCapabilities`를 쓴다.
- **화면 상태**
  - 로딩·빈 결과·오류·지연·잘림 상태를 모두 화면에 표시한다.
  - Snowflake 연계 화면은 `docs/docs/10-workitems/spec-snowflake-display.md`의 상태 표준과 응답 형식을 따른다.
- **오류 표시**: 오류는 `ShowToastEvent` 또는 화면 안 오류 영역으로 표시한다. 서버 메시지를 그대로 붙이지 않고 라벨로 바꾼다.
- **접근성**
  - 입력에는 label을 붙이고, 아이콘 버튼에는 `alternative-text`를 붙인다.
  - 색만으로 상태를 구분하지 않는다. 합격/불합격에는 텍스트나 아이콘을 함께 둔다.

## 7. 명명

Vol.0 3.2가 기준이다. 아래는 그 요약과, 첨부 표준 중 프로젝트와 충돌하지 않아 추가한 규칙이다. WI가 이미 정의한 API명은 바꾸지 않는다.

| 대상 | 규칙 | 예 |
| --- | --- | --- |
| 객체 | `{CMN/QMS/PMS}_{PascalCase}__c` | `QMS_IqcLot__c` |
| 필드 | 접두어 없는 PascalCase, 관계 필드는 대상명 | `Plant__c`, `DueAt__c` |
| 신규 Boolean 필드 | `Is` 접두 권장(WI에 없는 새 필드만) | `IsOverdue__c` |
| Apex | `{접두어}_{도메인}{역할}` | `QMS_IqcLotService` |
| 테스트 클래스 / 메서드 | `{클래스}_Test` / `test_AC{nn}_{설명}` | `QMS_IqcLotService_Test.test_AC03_skipLevelAutoAccepts` |
| LWC | `{cmn/qms/pms}{PascalCase}` | `qmsIqcInspection` |
| Flow | `{접두어}_{객체}_{시점}_{동작}` | `QMS_NCR_AfterSave_NotifyOwner` |
| Permission Set / Group | `{접두어}_PS_{기능}_{권한}` / `{접두어}_PSG_{페르소나}` | `QMS_PS_Iqc_Inspect` |
| Custom Label | 이름 `{접두어}_{화면}_{키}`, Category = 접두어 | `QMS_IqcInspection_BtnDecide` |
| Validation Rule | `{객체}_{검증 대상}` | `QMS_IqcLot_DecisionRequiresReason` |
| Custom Metadata / Platform Event | `{접두어}_{이름}__mdt` / `__e` | `QMS_IqcSwitchRule__mdt` |

Name 필드는 사람이 읽는 제목이다. 업무 번호는 Auto Number가 아니라 `RecordNo__c` + 채번 서비스(ARC-003)로 만든다.

## 8. 테스트

- **커버리지와 AC**
  - 클래스별 커버리지는 85% 이상이다(ARC-001 BR-1).
  - AC마다 테스트 메서드를 1개 이상 둔다. 메서드 이름에 AC 번호를 넣고, 본문은 Given/When/Then 주석으로 나눈다.
- **필수 테스트 종류**
  - 벌크: 200건으로 실행하고 `Limits.getQueries()` 등으로 한도를 확인한다.
  - 음수: 잘못된 입력, 권한 없음, 상태 위반을 넣는다.
  - 권한: `System.runAs`로 PSG를 가진 사용자와 가지지 않은 사용자를 비교한다.
- **테스트 데이터**
  - Org 데이터에 의존하지 않는다(`SeeAllData` 금지).
  - `CMN_TestDataFactory`가 정적 리소스 `QMS_DemoFixtures`(`data/demo/fixtures/demo_fixtures.json`)로 데모와 같은 키·값을 만든다.
- **목**
  - 콜아웃은 `HttpCalloutMock`으로 막고, 응답 본문은 `data/demo/mocks/dwh/{QueryKey}/{case}.json`을 정적 리소스로 읽는다.
  - 의존 서비스 대체는 `Test.createStub`(StubProvider) 또는 게이트웨이 바인딩 교체로 한다.
- **골든 비교**: 통계·집계 결과는 `data/demo/expected/*.json`과 비교한다. 허용 오차는 통계 상대 1e-6, 건수는 정확히 일치다.
- **LWC Jest**
  - `sfdx-lwc-jest`로 돌리고, Apex·LDS 호출은 목으로 막는다.
  - 상태별(로딩·빈 결과·오류) 렌더링과 사용자 동작을 테스트한다.

## 9. 메타데이터·배포

- **CLI와 소스 형식**
  - CLI는 `sf`만 쓴다(`sfdx` 명령 금지).
  - 메타데이터는 소스 형식으로 `sfdx-project.json` 패키지 디렉터리에 둔다. 패키지 분리 기준은 ARC-001이다: 접두어별 디렉터리를 쓰고, CMN 객체는 CMN 디렉터리에 둔다.
- **같은 WI 안에서 함께 반영할 것**
  - WI가 만든 모든 객체·필드는 같은 WI에서 Permission Set에 반영한다.
  - Custom Label과 번역(ko·en_US·zh_CN)도 같은 WI에서 반영한다.
  - 페이지 레이아웃·Lightning 페이지 배치는 WI 화면 절을 따른다.
- **정적 분석**: `sf code-analyzer run --target <변경 경로> --rule-selector Recommended --severity-threshold 2`. 심각도 1~2 위반은 0건이어야 한다. 설정 파일은 저장소 루트 `code-analyzer.yml`이다.
- **배포 순서**
  1. Scratch Org에 `sf project deploy start --dry-run -o <alias>`로 확인한다.
  2. `sf project deploy start -o <alias>`로 배포한다.
  3. `sf apex run test -o <alias> -n <테스트 클래스> -c -r human -w 10`을 실행한다.
  4. Sandbox 검증은 `sf project deploy start --dry-run -o <alias> --test-level RunLocalTests`로 한다. `sf project deploy validate`(검증 후 quick deploy)는 운영 릴리즈 파이프라인 전용이며 에이전트가 실행하지 않는다.
- 같은 오류로 dry-run이나 validate가 두 번 연속 실패하면 멈추고 원인과 시도 내용을 보고한다.
- **에이전트가 하지 않는 것**
  - 운영 Org 배포, destructive 변경(삭제 매니페스트), 데이터 삭제를 사용자 승인 없이 하지 않는다.
  - Scratch Org나 Sandbox가 아닌 Org에 데모 데이터를 넣지 않는다.

## 10. 커밋·보고

- **커밋 메시지**: `[WI-ID] 요약` 형식이다. 예: `[QMS-03-IQC-002] 검사 로트 초기화 서비스`
  - 커밋은 사용자가 요청할 때만 한다.
  - `main`에 직접 커밋하지 않는다.
- **완료 보고**: WI 완료 시 `docs/wi/{WI-ID}.md`(ARC-001 구현 노트 위치)를 `docs/dev/wi-report-template.md` 형식으로 작성한다.
- **현황 갱신**
  - `docs/docs/20-status/DEV-STATUS.md`의 해당 WI 행(상태·시작일·완료일·보고서 링크)을 갱신한다.
  - `docs/master/workitem-index.csv`의 상태 열은 검토 상태(`승인` 등, `/build-master`가 사용) 전용이라 개발 상태로 바꾸지 않는다.
- **명세 불일치 처리**: 구현 중 명세와 다르게 해야 했던 점은 보고서 "명세 차이" 절에 남긴다. WI 문서를 직접 고치지 않고, 변경 요청으로 사용자에게 알린다.

## 11. 금지 목록

- **SOQL·DML**
  - 루프 안 SOQL·DML·콜아웃
  - 문자열 결합 동적 SOQL
  - `WITH SECURITY_ENFORCED` 신규 사용
  - 사유 주석 없는 `without sharing`
- **하드코딩**
  - Id·레코드타입 Id·프로필명
  - 한국어 리터럴(문구는 Custom Label로)
  - 비밀값
- **구조**
  - 트리거 본문 로직
  - 같은 시점에 Flow와 Apex 혼용
  - 공통 서비스 재구현
  - 다른 메뉴 객체를 선행 없이 Lookup
- **LWC**
  - 승인 목록 밖 외부 JS
  - `if:true`
  - `innerHTML`로 사용자 데이터 삽입
  - 서버 메시지 원문 노출
- **테스트**
  - `SeeAllData`
  - AC 번호 없는 테스트만 있는 상태
  - 커버리지 85% 미만 병합
- **배포·명령**
  - `sfdx` 명령
  - 승인 없는 운영 배포·삭제
  - dry-run 없이 배포
