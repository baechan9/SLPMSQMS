# CMN-00-APV-001 완료 보고 — 결재 데이터 모델·상태 엔진·서비스 API

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-APV-001 (vol0-cmn-common.md CMN-00-APV-001) |
| Wave / 공수(계획 → 실제) | W0 / 8 M/D → 약 1.5 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), 결정 D-2는 권고안(표준 Approval Process 대신 공통 엔진), 데모 보강(단계 ExternalKey) 반영 |

## 1. AC 결과

검증 대상은 업무 객체 대신 테스트 대상 객체(결재 유형 `CMN_TEST_APPROVE`)와 기록 콜백이다(CR-11·DEV-3). 결재 화면은 APV-003(P3).

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 검토(1)-합의 2명 병렬(2)-승인(3), 1 승인·2의 1명만 승인 → 3 WAITING | `CMN_ApprovalService_Test.test_AC01_parallelAgreeWaitsForAll`(이어서 나머지 합의 → 3 PENDING → 승인 → 요청 APPROVED·잠금 해제·onApproved 1회·번호 APV-) | 통과 |
| AC-2 2단계 반려 → 요청 REJECTED, 3단계 SKIPPED, 잠금 해제, onRejected 1회 | `test_AC02_rejectSkipsRestAndUnlocks` | 통과 |
| AC-3 마지막이 REVIEW → 예외(라벨) | `test_AC03_lastStepMustBeApprove` | 통과 |
| AC-4 다른 공장 결재자 → 대상 조회 가능 | `test_AC04_otherPlantApproverCanReadTarget`(상신 전 0건 → 상신 후 대상·요청 조회) | 통과 |
| AC-5 1단계 처리 후 기안자 회수 → 차단 | `test_AC05_recallBlockedAfterFirstStep`, `test_BR4_recallBeforeAnyActionAndOnlyDrafter` | 통과 |
| AC-6 승인 완료 후 재상신 → Version 2, Version 1 유지 | `test_AC06_resubmitCreatesVersion2`(getStatus는 최신 차수) | 통과 |
| BR-1 검증(빈 결재선·기안자 본인·비활성·유형 없음·콜백 거부·진행 중·사유 없는 반려·결재자 아님·부서장 필수) | `test_BR1_validationsAndInProgressGuard`, `test_BR1_requireDrafterManager` | 통과 |
| BR-2 CC 통보·BR-9 이벤트 | `test_BR2_ccIsNotifiedWithoutWaitingAndEvents` | 통과 |
| 화면 결재선 역직렬화 | `test_stepSpecDeserializesFromScreen` | 통과 |

## 2. 구현 내역

- 메타데이터: `CMN_ApprovalType__mdt`(+ 테스트 유형), `CMN_ApprovalRequest__c`(RecordNo·TypeCode·Target 다형·Title·Status·CurrentStepNo·Plant·Version·Summary·SubmitComment·일시, Private, 공유 사유 CMN_Plant·CMN_Approval, 번호 변경 금지, 탭), `CMN_ApprovalStep__c`(주종, StepNo·StepType·Approver·RoleCode·Status·ActedBy·IsDelegated·Comment·ActedAt·ExternalKey), `CMN_ApprovalEvent__e`(커밋 후 발행). 채번 규칙 `APV-{YYYY}-{SEQ:7}`, 삭제 통제(DRAFT만), 공유 설정(Plant__c), 테스트 대상 객체 공유 사유 CMN_Approval. Org 설정 `ApexSettings.enableApexApprovalLockUnlock`(저장소 설정 메타데이터 + Scratch 정의 파일).
- Apex: `CMN_ApprovalService`(submit·approve·reject·recall·getStatus), `CMN_ApprovalCallback`(canSubmit·onSubmitted·onApproved·onRejected·onRecalled), `CMN_ApprovalStepSpec`, `CMN_ApprovalStatusDTO`, `CMN_ApprovalSelector`, `CMN_ApprovalWriter`(상태 쓰기·잠금 — without sharing, 사유 주석), `CMN_ApprovalRequestTriggerHandler` + 트리거.
- 권한·라벨: `CMN_PS_Approval_User`(사내 PSG 14개, 읽기 + 탭), `CMN_PS_Approval_Admin`(QualityAdmin·Auditor·SystemAdmin 전체 보기). 라벨 13개. SL QMS·SL PMS 앱에 결재 탭.
- 업무 WI가 할 일: `CMN_ApprovalType__mdt` 레코드(대상 객체·콜백·잠금 옵션), 콜백 클래스(업무 상태는 콜백에서만), 대상 객체에 공유 사유 `CMN_Approval`(없으면 수동 공유로 대체).
- 핵심 설계 판단:
  1. **상태 쓰기는 without sharing 작성기**: 결재자는 읽기 공유만 받는데, 처리하면 엔진이 요청·단계를 갱신하고 대상 잠금을 풀어야 한다. `AccessLevel.SYSTEM_MODE`는 권한만 무시하고 공유는 클래스 설정을 따라 주종 하위 갱신이 거부됐다(테스트로 확인). 검증은 서비스, 저장·잠금만 작성기.
  2. **다음 순서 열기**: 처리한 순서의 단계가 모두 승인(또는 통보)이면 다음 StepNo 묶음을 연다. CC만 있는 묶음은 통보 표시 후 바로 다음으로.
  3. **재상신 차수**: 진행 중 요청이 있으면 상신을 막고, 아니면 최신 차수 + 1(반려·회수·승인 후 모두).
  4. **상신 스냅숏**: 대상의 전 필드(주소·위치 제외)를 JSON으로 Summary__c에 남긴다(감사 근거).
  5. **이벤트 = 연계 지점**: SUBMITTED·STEP_PENDING·STEP_DONE·APPROVED·REJECTED·RECALLED. To-Do·알림은 직접 만들지 않는다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_ApprovalService 96%, Selector·Writer·StepSpec·DTO·핸들러 100% |
| Apex 테스트 | 150건 통과(APV-001 12건 포함) |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier / 한글 리터럴 | 통과 / 통과 / 0건 |

## 4. 보안·성능 점검

- [x] `without sharing`은 `CMN_ApprovalWriter`(저장·잠금만)와 기존 `CMN_ShareWriter`, 사유 주석
- [x] 처리 권한 검증: 처리 차례(PENDING)·결재자 본인·기안자(회수), 요청은 `FOR UPDATE`로 잠가 동시 처리 방지
- [x] 오류는 Custom Label(`CMN_ValidationException`)
- [x] 루프 안 SOQL·DML 없음
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | `SubmitComment__c` 추가(submit의 comment 저장 위치), 이벤트에 TargetRecordId·TypeCode 추가 | 구독 측(To-Do·알림)이 대상·유형을 다시 조회하지 않게 |
| 명세 차이 | Approver__c를 DB 필수 대신 서비스 검증 | User 조회는 필수로 만들 수 없음 |
| 명세 차이 | 콜백에 `canSubmit` 포함 | interfaces.md 기재 사항 반영 |
| 명세 차이(데모 보강) | `CMN_ApprovalStep__c.ExternalKey__c` = `{결재 번호}-S{StepNo}`(병렬 둘째부터 `-{순번}`) | 개발 플랜 CR-6 |
| 이슈 | 표준 객체 대상은 결재자 공유를 하지 않고 경고 로그(명세는 수동 공유) | 업무 대상은 모두 사용자 정의 객체. 표준 객체 대상이 생기면 그 WI에서 |
| 이슈 | Org 설정 `enableApexApprovalLockUnlock`이 꺼져 있으면 상신 실패 | 저장소 설정 메타데이터로 배포, 새 Scratch는 정의 파일 |
| 후속 | 대결(IsDelegated, APV-004), 결재선 템플릿·Role 해석(APV-002), 결재 화면(APV-003), To-Do(TDO-001)·알림(NTF-001) 구독 | 각 WI |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-APV-001] 공통 결재 엔진(상신·병렬·반려·회수·재상신)과 결재 이벤트`
