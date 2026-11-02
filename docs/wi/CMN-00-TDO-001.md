# CMN-00-TDO-001 완료 보고 — 통합 To-Do 모델·서비스

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-TDO-001 (vol0-cmn-common.md CMN-00-TDO-001) |
| Wave / 공수(계획 → 실제) | W0 / 5 M/D → 약 0.5 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack Vol.3 변경 요청(포털 사용자 처리자 허용) 반영 |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 같은 Spec으로 open 2회 → To-Do 1건 | `CMN_TodoService_Test.test_AC01_openTwiceKeepsOneTodo`(Owner = Assignee, 기본 제목 렌더링, 이벤트 1건, 완료 후 재오픈은 같은 레코드) | 통과 |
| AC-2 결재 단계 PENDING 이벤트 → 결재자 APPROVAL To-Do, 승인 이벤트 후 DONE | `test_AC02_approvalPendingOpensAndApprovalClosesTodo`(2단계 결재: 1단계 To-Do → 승인 → 1단계 DONE·2단계 OPEN → 최종 승인 DONE) | 통과 |
| AC-3 중국어 사용자 renderTitle → 중국어 제목(번호 치환) | `test_AC03_chineseAssigneeGetsChineseTitle`(`[审批] PPA-KR01-2026-00006`, 번역 없는 언어 → en_US, `{key}` 치환, 라벨 없음 → 기본 제목, 깨진 JSON) | 통과 |
| AC-4 200건 Spec open → SOQL 2회·DML 1회 이하 | `test_AC04_bulk200SpecsUseTwoQueriesOneDml`: SOQL 1회, 레코드 DML 1회 + 이벤트 발행 1회(아래 명세 차이). 취소 200건도 SOQL 1회·DML 1회 + 발행 1회 | 통과(차이 기록) |
| BR-1 본인 To-Do만, 관리자 View All, 상태는 서비스만 | `test_BR1_assigneeSeesOnlyOwnAndAdminSeesAll`(처리자 아닌 업무 담당자도 닫을 수 있음) | 통과 |
| BR-2 반려·회수 | `test_BR2_rejectCancelsParallelAndRecallCancels`(반려한 단계 DONE, 병렬 단계 CANCELLED, 회수 시 남은 To-Do 모두 CANCELLED) | 통과 |
| 음수 | `test_negative_invalidSpecs`(처리자 없음·비활성, 라벨 없음, 치환값 1000자 초과, 빈 입력) | 통과 |

데모 데이터 재현(qms-dev-a, `--upto-phase 2`): `85_CMN_Todo__c.csv` 31행은 모두 아직 배포되지 않은 QMS 업무 레코드(8D·IQC·PPAP 등)와 그 결재 단계를 참조해 로더가 건너뛰었다(실패 0). 해당 메뉴 페이즈에서 재현한다.

실 Org 스모크(qms-dev-a): 테스트 대상 레코드 상신(결재자 E1101) → 이벤트 구독(자동 프로세스 사용자)이 `[결재] TST-SMOKE-TDO TDO smoke` APPROVAL To-Do 생성, Owner = E1101 → 회수 후 CANCELLED·완료 일시 기록. 구독 오류 로그 0건.

## 2. 구현 내역

- 객체·메타데이터
  - `CMN_Todo__c`: 명세 필드 전부(Assignee·Category·System·SourceType·SourceRecordId·SourceObject·TargetRecordId·RecordNo·TitleLabel·TitleParams·TitleFallback·DueDate·Status·IsDelegated·DelegatedFrom·Plant·IsOverdue 수식·ExternalKey(Unique, 대소문자 구분)·CompletedAt). OWD Private, 탭, 읽기 전용 레이아웃, 번역 3종.
  - `CMN_TodoChanged__e`(PublishAfterCommit): AssigneeEmployeeNo·AssigneeId·TodoId·ChangeType.
  - 라벨 2개(`CMN_Todo_CMN_APPROVAL` = `[결재] {0}` / `[Approval] {0}` / `[审批] {0}`, `CMN_Todo_AssigneeRequired`). CMN 설정 `CMN_DEFAULT_LANGUAGE`(ko).
- Apex
  - `CMN_TodoSpec`: 생성 명세(필수 5개는 생성자, 나머지는 공개 필드), `externalKey()`.
  - `CMN_TodoService`: `open(List<CMN_TodoSpec>)`, `close(sourceType, sourceIds, assigneeOrNull)`, `cancel(sourceType, sourceIds)`, `renderTitle(CMN_Todo__c, languageLocaleKey)`. 상수 `OPEN/DONE/CANCELLED`, `SOURCE_APPROVAL = 'CMN_APPROVAL'`.
  - `CMN_TodoSelector`·`CMN_TodoWriter`: 남의 Private To-Do를 읽고 쓰는 부분만 without sharing(사유 주석). 화면에 결과를 돌려주지 않는다.
  - `CMN_ApprovalEventTrigger` + `CMN_ApprovalEventTriggerHandler`: 결재 이벤트 구독(BR-2).
- 권한: `CMN_PS_Todo_User`(읽기·탭, 사내 페르소나 PSG 전체), `CMN_PS_Todo_Admin`(View All, QualityAdmin·SystemAdmin). SL QMS·SL PMS 앱 두 번째 탭에 To-Do.
- 데모 생성기: To-Do 제목 라벨을 `{접두어}_Todo_{SourceType}`로 생성(`CMN_APPROVAL` → `CMN_Todo_CMN_APPROVAL`, QMS 원천은 그대로 `QMS_Todo_…`).
- 핵심 설계 판단
  1. **중복 판정 SOQL 1회**: 처리자(User) 조회에 같은 키 To-Do를 하위 조회로 붙여 사번(BR-4 이벤트)과 기존 상태를 한 번에 읽는다. 이미 OPEN이면 건너뛰고, DONE·CANCELLED면 같은 레코드를 다시 연다(재작업·재요청).
  2. **결재 To-Do 원천 = 결재 단계**: STEP_PENDING은 구독 시점에도 단계가 PENDING일 때만 연다(재전달된 이벤트가 끝난 To-Do를 다시 열지 않게). STEP_DONE은 그 단계, APPROVED는 요청의 남은 단계를 close, REJECTED·RECALLED는 cancel. 한 묶음 안에서 open → close → cancel 순으로 처리해 요청 안 이벤트 순서를 지킨다.
  3. **제목 언어**: `Label.translationExists`로 받는 사람 언어 번역을 확인하고, 없으면 en_US, 라벨 자체가 없으면(다른 메뉴 WI 미배포) TitleFallback. 치환값은 JSON 배열(`{0}`)과 객체(`{key}`) 모두 지원. String.format은 작은따옴표를 이스케이프로 처리하므로 쓰지 않는다.
  4. **구독 실패 격리**: 구독 오류는 `CMN_Logger.error`로 남기고 결재 처리 자체에 영향을 주지 않는다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_TodoService 98.7%, CMN_ApprovalEventTriggerHandler 89.4%, Selector·Writer·Spec·트리거 100% |
| Apex 테스트 | 178건 통과(TDO-001 7건 포함, RunLocalTests) |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier / 한글 리터럴 | 통과 / 통과 / 0건 |

## 4. 보안·성능 점검

- [x] `without sharing`은 Selector(키·상태·사번 조회)와 Writer(저장)만, 사유 주석. 서비스·핸들러는 with sharing
- [x] 상태·처리자·외부 키 필드는 사용자 FLS 읽기 전용(서비스만 변경), 사용자 PS는 To-Do 생성·편집 불가
- [x] 동적 SOQL은 바인드만(처리자 조건 유무만 분기)
- [x] 오류는 Custom Label(`CMN_Todo_AssigneeRequired`, `CMN_Common_InvalidInput`)
- [x] 200건 일괄: SOQL 1회, 레코드 DML 1회, 발행 1회
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | `TitleParams__c` Text(1000) → Long Text Area(1000). Text 최대 길이가 255 | 플랫폼 제약 |
| 명세 차이 | AC-4 "DML 1회 이하": 레코드 DML 1회 + `CMN_TodoChanged__e` 발행 1회. PublishAfterCommit 발행은 DML 한도에 1회로 잡힌다. 롤백된 To-Do가 푸시되지 않도록 PublishAfterCommit을 유지 | AC-4 문구를 "레코드 DML 1회 + 이벤트 발행 1회"로 변경 요청 |
| 명세 차이 | 결재 To-Do SourceType `CMN_APPROVAL`(명세 예시 `APV_STEP`) — 데모 데이터·외부 키와 일치 | 명세 예시 변경 요청 |
| 명세 차이 | 제목 라벨 규칙 `{접두어}_Todo_{SourceType}`(예: `CMN_Todo_CMN_APPROVAL`, `QMS_Todo_QMS_8D_STEP`). 각 메뉴 WI가 자기 원천 유형 라벨을 만든다 | interfaces.md To-Do 절에 규칙 추가 요청 |
| 명세 차이 | `Assignee__c`는 DB 필수가 아니라 서비스 필수(User Lookup은 필수 지정 불가) | 플랫폼 제약 |
| 명세 차이 | `CMN_TodoChanged__e.AssigneeId__c` 추가: 포털 사용자는 사번이 없다(검토 반영 Vol.3 포털 처리자) | TDO-003 푸시가 사번 없을 때 사용 |
| 명세 차이 | Owner = Assignee는 사내(Standard)·Partner/Customer Community Plus 사용자만. 레코드를 소유할 수 없는 대량 포털·게스트 사용자는 Owner를 바꾸지 않고(만든 사용자), 포털 조회는 TDO-002 API가 Assignee 기준으로 한다 | TDO-002 착수 때 확인 |
| 신규 설정 | CMN 설정 `CMN_DEFAULT_LANGUAGE`(ko): TitleFallback 렌더링 언어 | Org 기본 언어와 같게 운영 |
| 후속 | BR-2 "+유효 대리인" To-Do | CMN-00-APV-004(P3, `CMN_Delegation__c`). 닫기는 단계 전체 기준이라 대리인 To-Do도 함께 닫힌다 |
| 후속 | 결재 To-Do 기한(DueDate) | CMN-00-APV-005(지연 알림·에스컬레이션, `ReminderDays__c`) |
| 후속 | BR-5 DONE·CANCELLED 180일 후 아카이브 | CMN-00-DWH-002 |
| 후속 | `CMN_TodoChanged__e` 구독(푸시), 포털 To-Do API | CMN-00-TDO-003·TDO-002 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-TDO-001] 통합 To-Do 서비스와 결재 이벤트 구독`
