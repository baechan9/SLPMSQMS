# CMN-00-APV-002 완료 보고 — 결재선 템플릿·CFT Role 매핑

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-APV-002 (vol0-cmn-common.md CMN-00-APV-002) |
| Wave / 공수(계획 → 실제) | W0 / 6 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack APV-002 변경 요청 8건 반영(결재선 기여 인터페이스, Role 해석 공개 메서드, APPROVAL_ROLE 값 — 코드 시드), 데모 보강(ExternalKey 3종) |

## 1. AC 결과

검증 대상은 4M 대신 테스트 대상 객체(유형 `CMN_TEST_APPROVE`, 템플릿: 품질팀장 검토(필수) → 생산팀장 합의 → 공장장 승인(필수))다(CR-11·DEV-3).

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 KR01 품질팀장 김OO, CN01 품질팀장 王OO → CN01 해석 王OO | `CMN_ApprovalLineResolver_Test.test_AC01_qualityManagerResolvedPerPlant`(KR01 결재선 전체 해석 — 공장 Role·전사 Role·필수 표시) | 통과 |
| AC-2 공장에 공장장 미등록 → "공장장(CN01) 결재자 미지정"으로 상신 차단 | `test_AC02_missingPlantManagerBlocksSubmit`(submit에서 차단) | 통과 |
| AC-3 필수 품질팀장 단계 삭제 → 서버 검증 차단 | `test_AC03_mandatoryStepCannotBeRemovedOrReassigned`(삭제·결재자 변경 차단, 비필수 삭제는 허용). UI 비활성은 APV-003 | 통과(서버) |
| AC-4 같은 Role·공장 유효 기간 겹치는 2명 → 설정 오류 | `test_AC04_overlappingAssignmentsAreConfigError` | 통과 |
| BR-1 공장 템플릿 우선, BR-2 부서 배정 우선·만료 무시, 해석 유형(사용자·기안자 부서장·레코드 필드), 편집 불가 템플릿 | `test_BR1_plantTemplateBeatsCompanyDefaultAndResolverTypes`, `test_BR2_departmentAssignmentWinsAndExpiredIgnored` | 통과 |
| BR-4 개인 템플릿 본인만 | `test_BR4_personalTemplateOnlyForOwner` | 통과 |
| 결재선 기여·템플릿 없음, Role 배정 규칙, PROJECT_ROLE 예약, 갱신 | `test_contributorAndNoTemplate`, `test_negative_roleAssignmentRules`, `test_updatesKeepKeys` | 통과 |

데모 데이터 재현(qms-dev-a, `--upto-phase 2`): Role 배정 26행, 템플릿 10행, 템플릿 단계 16행 실패 0(만들지 않은 사용자의 배정은 관리자 E1901로 대체).

## 2. 구현 내역

- 객체·메타데이터: `CMN_RoleAssignment__c`(Role(APPROVAL_ROLE)·Plant·Department·User·ValidFrom/To·ExternalKey, Public Read Only, 이력, 탭), `CMN_ApprovalTemplate__c`(TypeCode·Plant·Scope·AllowUserEdit·IsDefault·IsActive·ExternalKey, Private + 조건 공유 규칙 "SYSTEM은 사내 전체 읽기", 탭), `CMN_ApprovalTemplateStep__c`(주종, StepNo·StepType·ResolverType·RoleCode·User·FieldPath·IsMandatory·ExternalKey). `CMN_ApprovalType__mdt.LineContributorClass__c`. 라벨 9개.
- Apex: `CMN_RoleResolver.resolveUser(roleCode, plantId, deptId)`(공개, 검토 반영 Vol.4), `CMN_ApprovalLineResolver`(resolve·enforceTemplate·savePersonal·loadPersonal), `CMN_ApprovalLineContributor`(검토 반영 Vol.2), `CMN_ApprovalLineSelector`(시스템 템플릿 읽기만 without sharing — 사유 주석), `CMN_ApprovalLineService`(Role 배정 규칙·외부 키, 템플릿·단계 키), 핸들러 3개 + 트리거 3개. `CMN_ApprovalStepSpec.isMandatory`. `CMN_ApprovalService.submit`이 템플릿 규칙을 서버에서 확인.
- 권한: `CMN_PS_ApprovalLine_Admin`(QualityAdmin·SystemAdmin), `CMN_PS_Approval_User`에 템플릿 조회·개인 템플릿 작성·Role 배정 조회 추가. SL Admin 앱에 Role 배정·템플릿 탭.
- 핵심 설계 판단:
  1. **템플릿 규칙은 상신에서 검증**: UI(APV-003)가 막더라도 서버에서 필수 단계·편집 불가 규칙과 Role 미지정을 다시 확인한다(AC-2·AC-3이 상신 시점).
  2. **Role 해석 3단계**: 공장+부서 → 공장(부서 공란) → 전사. 단계마다 1명이면 결정, 2명 이상이면 설정 오류, 끝까지 없으면 Role 표시명(사용자 언어)·공장 코드로 미지정 오류.
  3. **시스템 템플릿 읽기**: 개인 템플릿 보호를 위해 OWD Private + 시스템 템플릿 조건 공유 규칙. 해석은 공유 계산과 무관하게 같은 결과여야 해서 SYSTEM 범위만 공유를 우회해 읽는다(읽기 전용).
  4. **필수 단계 일치 기준**: 같은 단계 유형·같은 결재자가 결재선에 있으면 유지로 본다(순서 변경은 허용).

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_ApprovalLineResolver 92%, CMN_RoleResolver 97%, CMN_ApprovalLineService 96%, Selector·핸들러 100% |
| Apex 테스트 | 161건 통과(APV-002 11건 포함) |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier / 한글 리터럴 | 통과 / 통과 / 0건 |

## 4. 보안·성능 점검

- [x] `without sharing`은 시스템 템플릿 읽기(TemplateReader)만, 사유 주석, 읽기 전용
- [x] 개인 템플릿 저장·조회는 USER_MODE(본인만)
- [x] 레코드 필드 경로 동적 SOQL은 describe로 필드 존재 확인 후 이름만 사용, 값은 바인드
- [x] 오류는 Custom Label
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| CR 반영 | `CMN_ApprovalLineContributor`, `CMN_RoleResolver.resolveUser`, APPROVAL_ROLE 값 11개(LAB_RECEIVER·SUPPLIER_QUALITY·SQ_MANAGER·IQC_LEAD·LELE_OWNER·CQ_MANAGER·PE_MANAGER·METROLOGY_LEAD·LAB_MANAGER·TRAINING_COORDINATOR·QMS_MANAGER — 데모 코드 시드에 이미 있음) | review-pack |
| 명세 차이 | Role 배정 Role__c의 APPROVAL_ROLE 필터를 조회 필터 대신 트리거로, User__c는 트리거 필수 확인 | 관계 너머 조회 필터·User 필수 제약 |
| 명세 차이 | 템플릿 OWD Private + 시스템 템플릿 조건 공유 규칙 | BR-4(개인 템플릿 본인만) |
| 명세 차이(데모 보강) | ExternalKey: RA-{Role}-{Plant 또는 ALL}-{사번}[-{부서}], TPL-{TypeCode}[-{Plant}], {템플릿 키}-{StepNo}[-n] | 개발 플랜 CR-6 |
| 후속 | PROJECT_ROLE 해석 | PMS |
| 후속 | 결재선 편집 UI(필수 단계 삭제 버튼 비활성) | CMN-00-APV-003(P3) |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-APV-002] 결재선 템플릿·Role 해석과 상신 시 템플릿 규칙 검증`
