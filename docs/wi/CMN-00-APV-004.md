# CMN-00-APV-004 완료 보고 — 대리결재(위임)

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-APV-004 (vol0-cmn-common.md CMN-00-APV-004) |
| Wave / 공수(계획 → 실제) | W1 / 4 M/D → 약 0.5 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), 데모 보강 CR-6(ExternalKey `DLG-{위임자 사번}-{시작일}`) |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 A→B 위임(전체), A 차례 도래 → A·B To-Do, B 처리 시 A To-Do 자동 종료 | `CMN_DelegationService_Test.test_AC01_delegateGetsTodoAndClosesBoth`(B To-Do 대결 표시·위임자, B 승인 → ActedBy = B·IsDelegated, A·B To-Do DONE) | 통과 |
| AC-2 위임 기간 종료 후 도래 → B To-Do 없음 | `test_AC02_expiredDelegationGivesNoTodo` | 통과 |
| AC-3 TypeCodes = QMS_4M_APPROVE만, 다른 유형 도래 → B To-Do 없음 | `test_AC03_typeScopedDelegationIgnoresOtherTypes`(B는 처리도 불가) | 통과 |
| BR-1 등록 규칙 | `test_BR1_registrationRules`(타인 거절, 부서장 허용·외부 키, 본인 위임·기간 역전 거절) | 통과 |
| BR-2 1단계만 | `test_BR2_delegationIsOneLevelOnly`(A→B, B→C에서 A 건은 B만) | 통과 |
| BR-5 등록·연장 즉시 | `test_BR5_delegationOpensTodoForAlreadyPendingStep`, `test_BR5_extendingDelegationOpensTodo` | 통과 |
| BR-6 휴직 알림 | `test_BR6_leaveWithPendingApprovalNotifiesManager`(HR 상태 LEAVE + 결재 대기 1건 → 부서장 `CMN_DELEGATION_NEEDED`) | 통과 |

## 2. 구현 내역

- 객체 `CMN_Delegation__c`(Delegator·Delegate·StartAt·EndAt·TypeCodes·Reason·IsActiveNow 수식·ExternalKey, 공개 읽기, 이력, 탭, 편집 레이아웃). Custom Permission `CMN_DelegationAdmin`.
- PS: `CMN_PS_Delegation_User`(사내 페르소나 PSG 전체), `CMN_PS_Delegation_Admin`(QualityAdmin·SystemAdmin, 다른 사용자 위임 대리 등록). NTF 규칙 `CMN_DELEGATION_NEEDED` + 라벨 5개.
- Apex: `CMN_DelegationService`(prepare: 등록 규칙·외부 키·이름, activeFor·delegatesFor·isDelegate, openForPendingSteps, delegateSpecs, notifyLeave), `CMN_DelegationSelector`(without sharing: 위임자 PENDING 단계 찾기만, 사유 주석), `CMN_DelegationTriggerHandler` + 트리거.
- 결재 엔진 변경(APV-001 클래스): `CMN_ApprovalService.act`가 결재자 본인 또는 그 시점 유효한 대리인을 허용하고 `IsDelegated__c` 기록, `grantRead(targetId, requestId, users)` 공개(대리인 읽기 공유). 결재 이벤트 구독(TDO-001): PENDING 단계 결재자의 유효 대리인에게 To-Do(대결)·읽기 공유·결재 요청 알림. 사용자 트리거(MDM-001): after update에서 휴직 알림.
- 핵심 설계 판단
  1. **To-Do 원천 = 결재 단계**: 위임자·대리인 To-Do가 같은 원천이라 어느 쪽이 처리해도 STEP_DONE에서 단계 To-Do가 모두 닫힌다(BR-3 "다른 To-Do는 닫는다").
  2. **처리 권한은 처리 시점 기준**: 대리인 여부를 승인·반려하는 순간의 유효 위임으로 판단한다(기간이 끝나면 대리인 To-Do가 남아 있어도 처리 불가).
  3. **1단계 위임**: 결재자의 위임만 조회하고 대리인의 위임은 따라가지 않는다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지 | CMN_DelegationService 95%, Selector·핸들러·트리거 100%, CMN_ApprovalEventTriggerHandler 89% |
| Apex 테스트 | APV-004 8건 + 결재·To-Do·알림·임직원 회귀 44건 통과 |
| Code Analyzer(심각도 1~2) | 0건 |

## 4. 보안·성능 점검

- [x] 대리인 처리 허용은 유효 위임(기간·유형·활성 대리인)이 있을 때만, 1단계
- [x] 등록 권한 서버 확인(위임자 본인·부서장·관리자 권한)
- [x] `without sharing`은 Selector 조회만, 사유 주석
- [x] 위임 검색 SOQL은 이벤트 묶음당 1회

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | `TypeCodes__c` Text(1000) → Long Text Area(1000)(Text 최대 255). `Delegator__c`·`Delegate__c` 필수는 트리거 확인(User Lookup 필수 불가), 위임자를 비우면 등록자 | 플랫폼 제약 |
| 명세 차이 | 관리자 대리 등록용 Custom Permission `CMN_DelegationAdmin`(명세는 본인·부서장만) | 운영 필요로 추가, 사용자 확인 |
| 후속 | 이력 표시 "OOO(대결: 위임자명)" 화면 | CMN-00-APV-003 |
| 후속 | 위임 등록 전용 화면(현재 표준 레코드 화면·탭) | APV-003 결재 화면에서 바로가기 |
| 데모 | `23_CMN_Delegation__c` 1행(E1101 → E1102, 2026-12-01~05) | P3 데모 적재 때 확인 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-APV-004] 대리결재 위임과 대리인 To-Do·처리 권한`
