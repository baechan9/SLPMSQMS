# CMN-00-INT-002 완료 보고 — HR 조직·임직원 연계

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-INT-002 (vol0-cmn-common.md CMN-00-INT-002) |
| Wave / 공수(계획 → 실제) | W0 / 5 M/D → 약 0.5 M/D(Salesforce 측) |
| 완료일 | 2026-11-02(Salesforce 수신 계약) |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 중(Salesforce 측 완료, Mule HR 추출·스케줄은 외부 트랙) |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), 결정 D-8(임직원 전원 동기화 + 라이선스 사용자만 User) 권고안대로 구현 |

## 1. AC 결과

| AC | 확인 | 결과 |
| --- | --- | --- |
| AC-1 퇴사자 1명 동기화 → User 비활성, 부서장 알림 1건 | `CMN_EmployeeService_Test.test_AC01_retiredEmployeeDeactivatesUserAndNotifiesManager`(사용자 비활성·재직 상태 RETIRED, 부서장에게 `CMN_EMPLOYEE_RETIRED` 1건, 진행 중 To-Do 1건·결재 대기 0건 치환) | 통과 |
| AC-2 부서 이동 → 임직원과 User 부서 동시 갱신 | `test_AC02_departmentMoveUpdatesEmployeeAndUser`(사번 자동 연결, 부서 코드·직급·메일 갱신, FederationIdentifier = 사번, 활성 유지) | 통과 |
| BR-2 부서장 없음 | `test_BR2_noManagerFallsBackToAdmins`(시스템 관리자 PSG 사용자에게) | 통과 |
| 이관 모드·실패·벌크 | `test_BR2_migrationModeSkipsUserSyncAndAlerts`(연결만, 사용자 갱신·알림 없음), `test_syncFailureIsLoggedNotThrown`(자기 자신 비활성화 실패 → ERROR 로그), `test_bulk200EmployeesWithoutUsers`(SOQL 2회 이하, 사용자 없으면 작업 없음) | 통과 |

데모 데이터(qms-dev-a, `--upto-phase 2`): `17_CMN_Employee__c` 38행 실패 0, `17c` 사용자 연결 5행(Scratch Org 사용자 한도로 만든 사용자 5명만, 나머지 30행 제외) 실패 0. 이관 모드라 사용자 갱신·알림 없음.

## 2. 구현 내역

- 객체: `CMN_Employee__c`(EmployeeNo 외부 키·Unique, NameEn, Email, Department(필수, Restrict), JobGradeCode, HrStatus, User), 공개 읽기(조직도·CFT 후보 검색), 이력, 탭(SL Admin).
- PS: `CMN_PS_Employee_Read`(사내 페르소나 PSG 전체), `CMN_PS_Employee_Admin`(SystemAdmin), `CMN_PS_Integration_Hr`(HR 통합 사용자: 부서·임직원 upsert, CMN_PS_Integration과 함께).
- NTF 규칙 `CMN_EMPLOYEE_RETIRED` + 라벨 2개.
- Apex: `CMN_EmployeeService`(linkUsers, afterSave: 사용자 동기화 작업 등록·퇴직 알림), `CMN_EmployeeSelector`(사용자·부서·남의 To-Do/결재 건수, without sharing 사유 주석), `CMN_EmployeeUserSyncJob`(Queueable, 사용자 갱신·비활성화), `CMN_EmployeeTriggerHandler` + 트리거.
- 핵심 설계 판단
  1. **사용자 갱신은 Queueable**: 사용자(설정 객체)와 임직원(일반 객체)을 한 트랜잭션에서 함께 저장할 수 없다(Mixed DML). 임직원 저장 트랜잭션은 작업 등록만 하고, 사용자 갱신은 다음 트랜잭션에서 한다(AC-2의 "동시"는 같은 동기화 실행 안에서 몇 초 차이).
  2. **사용자 연결은 사번 자동**: HR 데이터에 사용자 Id가 없으므로 User__c가 비면 같은 사번의 사용자를 연결한다(관리자가 라이선스 사용자를 활성화하면 다음 동기화에서 연결).
  3. **User 필드**: User는 사용자 지정 객체를 조회할 수 없어 부서는 `DepartmentCode__c`(코드)로 맞춘다(MDM-001 설계). FederationIdentifier = 사번은 사용자 트리거(TDO-002)가 맞춘다.
  4. **퇴직 알림 대상**: 부서장(`CMN_Department__c.Manager__c`), 부서장이 없거나 본인이면 시스템 관리자 PSG 사용자. 남은 업무는 건수만 알린다(목록은 To-Do·결재 화면에서).
  5. **이관 모드**: 데모·이관 적재 때는 사용자 갱신·알림을 하지 않는다(연결만).

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_EmployeeUserSyncJob 100%, CMN_EmployeeService 97%, CMN_EmployeeSelector 92%, 핸들러·트리거 100% |
| Apex 테스트 | INT-002 6건 통과 |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier / 한글 리터럴 | 통과 / 통과 / 0건 |

## 4. 보안·성능 점검

- [x] BR-4: 성명·사번·부서·직급·메일만(주민번호·주소·연락처 필드 없음)
- [x] `without sharing`은 Selector의 건수 집계·사용자 조회만, 사유 주석
- [x] 사용자 갱신 실패는 로그로 남기고 나머지는 저장(allOrNone false)
- [x] 200건 일괄 SOQL 2회 이하, Queueable은 동기화 대상이 있을 때 1개
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | User의 Department__c → `DepartmentCode__c`(User는 사용자 지정 객체 조회 불가, MDM-001과 동일) | 명세 문구 정정 요청 |
| 명세 차이 | 사용자 갱신이 같은 트랜잭션이 아니라 직후 Queueable(Mixed DML) | AC-2 "동시" 해석 확인 |
| 명세 차이 | FederationIdentifier 설정 주체: 사용자 트리거(TDO-002) | — |
| Mule 측 | 부서 upsert(상위 → 하위) → 임직원 upsert 순서, 실행 로그(INT-001 규약), 매일 01:00 KST + 수동 | 외부 트랙 |
| 후속 | 연계 모니터 "지금 실행"(검토 반영 Vol.9 INT-017 BR-3) | QMS-09 연계 모니터 WI |
| 오픈 이슈 | HR 연계 방식(DB View·API·파일), PMS 임율 제공 범위 | 사용자 확인 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-INT-002] 임직원 동기화·사용자 연결·퇴직 처리`
