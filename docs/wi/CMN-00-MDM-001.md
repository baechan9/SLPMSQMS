# CMN-00-MDM-001 완료 보고 — 조직·사용자 기준정보

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-MDM-001 (vol0-cmn-common.md CMN-00-MDM-001) |
| Wave / 공수(계획 → 실제) | W0 / 2 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의) |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 부서 A의 상위를 하위 C로 → 순환 참조 오류 | `CMN_DepartmentService_Test.test_AC01_parentUnderOwnChildRejected`(상위 부서 필드, 라벨 문구), `test_AC01_selfParentRejected` | 통과 |
| AC-2 부서 이동 → 하위 전체 FullPath 비동기 재계산 | `test_AC02_moveRecalculatesDescendantsAsync`(저장 직후 자기 경로만, Queueable 후 하위 전체) | 통과 |
| BR-1 삭제 금지·비활성화 | `test_BR1_deleteBlockedDeactivateAllowed` | 통과 |
| BR-2 경로 8단계, 이름 변경 반영 | `test_BR2_deepChainKeepsNearestEightLevels`, `test_BR2_renameRefreshesDescendants` | 통과 |
| 사용자 부서·기본 공장 | `test_userDepartmentAndPlantResolved`, `test_negative_unknownDepartmentCodeRejected`, `test_negative_unknownPlantCodeOnUpdateRejected` | 통과 |
| 벌크 200건 | `test_bulk200Departments`(트리 조회 1회) | 통과 |
| 데모 픽스처 | `test_demoFixturesLoadDepartments` | 통과 |

데모 데이터 재현(qms-dev-a, `--upto-phase 1`): 부서 21행 2단계 적재 실패 0, 데모 사용자 4명(E1101 Salesforce, E1102·E1103·E1104 Platform)이 SL 프로필로 생성되고 PSG·부서 코드·기본 공장 코드가 들어갔다. E1112는 라이선스 조회상 Platform 1석이 남았는데도 Org가 "라이선스 없음"으로 거부했다(개발 Org 한정 여부를 P1 게이트의 새 qms-int에서 확인).

## 2. 구현 내역

- 객체·필드: `CMN_Department__c`(DeptCode·Parent·Manager·Plant·FullPath·IsActive, OWD Public Read Only, 필드 이력, 탭·레이아웃·하위 부서 관련 목록), User 필드 `EmployeeNo__c`(External ID·Unique), `DepartmentCode__c`, `JobGradeCode__c`, `PrimaryPlantCode__c`, `HrStatus__c`(기본 ACTIVE).
- Apex: `CMN_DepartmentService`(순환 검사·경로 계산·하위 재계산), `CMN_DepartmentPathJob`(Queueable), `CMN_DepartmentSelector`, `CMN_DepartmentTriggerHandler` + 트리거, `CMN_UserOrgService`(사용자 → 부서·기본 공장 해석, 코드 검사), `CMN_UserTriggerHandler` + `CMN_UserTrigger`, 공통 `CMN_MasterDataGuard`(기준정보 삭제 금지, MDM-002 핸들러도 이것으로 바꿈).
- 권한: `CMN_PS_Org_Read`(사내 PSG 14개), `CMN_PS_Org_Admin`(SystemAdmin). 라벨 2개 + 공통 라벨 `CMN_Master_DeleteNotAllowed`(MDM-002 라벨 이름 변경).
- 공통 도구 보강: 생성기가 표준 객체 필드에 이력 요소를 넣지 않음, 정의에서 사라진 생성 파일을 지우고 `--check`에서 실패, PS의 표준 객체 필드 전용 모드(fields-read·fields-edit). 점검 스크립트 배포에 `--ignore-conflicts`(PSG 재계산이 매번 원격 변경으로 잡힘). 데모 생성기의 User CSV를 코드 열로 바꿈(재생성 결과 바뀐 파일은 User CSV·적재 계획뿐).
- 핵심 설계 판단:
  1. **User의 부서·기본 공장은 코드**: User는 사용자 정의 객체를 Lookup할 수 없다(배포 오류 "유효하지 않은 데이터 유형"으로 확인). `DepartmentCode__c`·`PrimaryPlantCode__c` 텍스트에 코드를 두고, 저장 때 트리거가 존재를 검사해 Lookup의 참조 무결성을 대신하며, 레코드가 필요한 곳은 `CMN_UserOrgService`로 푼다. 코드는 Sandbox·운영 사이에서도 같아 HR 동기화에도 맞다.
  2. **트리 전체를 한 번에 읽는다**: 순환 검사와 경로 계산이 체인 전체를 봐야 해서 부서 전체(수천 건 규모)를 한 번 조회하고 저장 중인 값을 겹쳐 판단한다. 저장 건수와 무관하게 SOQL 1회.
  3. **자기 경로는 동기, 하위는 비동기**: 저장한 부서의 경로는 바로 보이고, 이름·상위가 바뀌면 하위 경로는 Queueable이 바뀐 것만 갱신한다. 이 갱신은 이름·상위를 바꾸지 않아 작업이 다시 들어가지 않는다.
  4. **8단계 초과**: 가까운 8단계만 남기고 앞을 `…`로 표시한다(저장은 막지 않음 — HR 동기화를 깨지 않게).

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_DepartmentService 100%, CMN_DepartmentPathJob 100%, CMN_DepartmentSelector 100%, CMN_UserOrgService 97%, CMN_UserTriggerHandler 100%, CMN_MasterDataGuard 100% |
| Apex 테스트 | 56건 통과(MDM-001 12건 포함) |
| Jest | 해당 없음 |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier | 통과 |
| 200건 벌크 한도 | 부서 200건 저장 시 트리거 SOQL 1회 |

## 4. 보안·성능 점검

- [x] 조회는 Selector에 모으고 시스템 모드 사유(사내 공개 기준정보) 명시. `without sharing` 없음
- [x] 오류 문구는 Custom Label
- [x] 루프 안 SOQL·DML 없음. 하위 경로 갱신은 Queueable 1회
- [x] 직급별 임율·인사평가 같은 민감 정보 없음(에이전트 주의)
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | `User.Department__c`·`User.PrimaryPlant__c`(Lookup) → `User.DepartmentCode__c`·`User.PrimaryPlantCode__c`(코드) | 플랫폼 제약. Vol.0 MDM-001 데이터 모델 갱신 요청. 이 필드를 쓰는 Vol.6c IAU-002 BR-5(심사 독립성), Vol.7 DSH-002 BR-1·BR-6(`:userDeptId`)은 `CMN_UserOrgService`로 부서·공장 Id를 얻도록 갱신 요청 |
| 명세 차이 | User 필드 필수(Y)를 DB 필수로 두지 않음 | 시스템·통합·포털·테스트 사용자 생성을 막지 않게. HR 동기화(INT-002)와 사용자 생성 절차가 보장, `HrStatus__c`는 기본값 ACTIVE |
| 명세 차이 | 8단계 초과 시 저장 차단 대신 앞 생략 | BR-2 "최대 8단계까지 따라가 생성"의 해석 |
| 명세 보강(CR-6) | 데모 사용자 수가 라이선스에 묶여 없는 사용자 Lookup은 로더 `onMissingUser` 규칙(skip·admin)으로 처리 | 데모 적재 규칙(load-plan.json)에 이미 반영. Vol.0 MDM-001에 규칙 문장 추가 요청 |
| 이슈 | qms-dev-a에서 Platform 라이선스 1석이 남았는데 5번째 사용자 생성 거부 | P1 게이트 새 Org에서 재확인 |
| 후속 | 임직원(CMN_Employee__c)·HR 동기화 | CMN-00-INT-002(P2) |
| 후속 | 부서장으로 결재 Role 해석 | CMN-00-APV |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-MDM-001] 부서 계층·사용자 HR 필드와 부서 경로 비동기 재계산`
