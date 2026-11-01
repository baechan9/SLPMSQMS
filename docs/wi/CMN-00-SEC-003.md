# CMN-00-SEC-003 완료 보고 — 감사 로그·삭제 통제

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-SEC-003 (vol0-cmn-common.md CMN-00-SEC-003) |
| Wave / 공수(계획 → 실제) | W0 / 4 M/D → 약 0.7 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의). Shield Field Audit Trail은 결정 D-6 전이라 범위 밖 |

## 1. AC 결과

검증 대상은 4M·NCR 대신 테스트 대상 객체 `CMN_TestRecord__c`(삭제 통제 규칙: Status__c, DRAFT만 삭제)다(CR-11·DEV-3). P5·P6 게이트에서 실제 객체로 다시 확인한다.

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 APPROVED 레코드 관리자 삭제 → 차단 | `CMN_DeleteGuardService_Test.test_AC01_approvedRecordCannotBeDeletedEvenByAdmin`(관리자 실행 + 핸들러 코드 우회 상태에서도 차단, 상태가 든 라벨 문구) | 통과 |
| AC-2 DRAFT 삭제 → 삭제 기록 1건(전 필드 JSON) | `test_AC02_draftDeleteLeavesSnapshot`(번호·삭제자·일시·사유, 스냅숏에 시스템 필드 포함) | 통과 |
| AC-3 일반 사용자 삭제 기록 수정 → 권한 없음 | `test_AC03_deleteLogCannotBeChangedByAnyone`(일반 사용자 접근 거부, 관리자 수정·삭제·직접 생성도 트리거가 차단) | 통과 |
| 벌크·미등록 규칙 | `test_bulk200DraftDeletes`(기록 200건, DML 2회), `test_unregisteredObjectNotGuarded` | 통과 |

## 2. 구현 내역

- 메타데이터: `CMN_DeleteGuard__mdt`(ObjectApiName·StatusField·DeletableValues) + 테스트 대상 규칙 1건, `CMN_DeleteLog__c`(자동 번호, Object·RecordIdText·RecordNo·Snapshot(131072)·DeletedBy·DeletedAt·Reason, OWD Private, 읽기 전용 레이아웃, 탭), `CMN_TestRecord__c.Status__c`. 라벨 2개.
- Apex: `CMN_DeleteGuardService`(`guard`, `log`, `setReason`), `CMN_DeleteLogTriggerHandler` + 트리거(프레임워크를 쓰지 않아 우회·비활성으로 풀리지 않음). `CMN_TriggerHandler.run()`이 before/after delete에서 삭제 통제를 항상 부른다(핸들러 비활성·우회·재진입과 무관).
- 권한: `CMN_PS_DeleteLog_Read`(전체 보기·읽기 전용·탭 — QualityAdmin·Auditor·SystemAdmin).
- 생성기: 객체당 이력 추적 필드 20개 초과면 생성 실패(BR-3의 표준 Field History 한도).
- 업무 객체 WI가 할 일: `CMN_DeleteGuard__mdt` 레코드 1건(상태 필드·삭제 가능 값), 트리거에 before delete·after delete 이벤트 포함(모든 CMN 트리거 템플릿이 이미 포함), 추적 필드 지정(객체당 20개 이하).
- 핵심 설계 판단:
  1. **프레임워크에 넣는다**: 업무 객체마다 핸들러에 코드를 넣으면 빠뜨리기 쉽다. 기반 클래스가 규칙 레코드만 보고 차단·기록하므로 업무 WI는 메타데이터만 더한다. 관리자 예외가 없어야 해서 핸들러 비활성 설정·코드 우회보다 먼저 실행한다.
  2. **삭제 기록 보호**: 관리자(Modify All Data)도 고칠 수 있으므로 권한(읽기만)에 더해 트리거로 수정·삭제·직접 생성을 막는다. 서비스만 쓰기 표시를 켜고 시스템 모드로 만든다.
  3. **스냅숏 = 채워진 전 필드 JSON**: after delete의 Trigger.old에는 전 필드가 있어 그대로 직렬화한다(131072자 초과분은 자름).

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_DeleteGuardService·CMN_DeleteLogTriggerHandler 100%, CMN_TriggerHandler 94% |
| Apex 테스트 | 123건 통과(SEC-003 5건 포함) |
| Jest | 해당 없음(기존 8건 유지) |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier | 통과 |
| 200건 벌크 한도 | 200건 삭제 시 기록 DML 1회 |

## 4. 보안·성능 점검

- [x] 삭제 기록: 읽기 전용 PS + 트리거 보호(관리자 포함), 생성은 서비스만
- [x] 스냅숏에 비용·개인정보 필드가 있으면 그대로 남는다 — 조회 권한을 품질경영·심사원·IT 운영으로 한정
- [x] 규칙은 Custom Metadata getAll(SOQL 미사용), 루프 안 DML 없음
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | DeletedBy__c·Snapshot__c를 DB 필수 대신 서비스가 항상 채움 | User 조회는 Restrict 불가·필수 조회는 SetNull 불가, 긴 텍스트 필수 제약 |
| 명세 차이 | 삭제 기록 조회 PS `CMN_PS_DeleteLog_Read`(QualityAdmin·Auditor·SystemAdmin) | 명세는 "PS 권한 Read만" — 대상 페르소나를 정함 |
| 명세 차이 | 테스트 대상 객체 `Status__c` | DEV-3 |
| 후속 | 장기 보존(Snowflake CORE.SF_FIELD_HISTORY) | CMN-00-DWH-002 |
| 오픈 이슈 | Shield Field Audit Trail 구매(D-6) | 결정 후 BR-3 보조 전환 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-SEC-003] 상태 기반 삭제 통제와 삭제 기록`
