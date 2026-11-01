# CMN-00-SEC-001 완료 보고 — 페르소나·권한 셋 구조

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-SEC-001 (vol0-cmn-common.md CMN-00-SEC-001) |
| Wave / 공수(계획 → 실제) | W0 / 3 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack SEC-001 변경 요청 9건 반영 |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 Inspector만 가진 사용자 → 앱 런처에 SL QMS만, Setup 불가 | `CMN_PersonaSecurity_Test.test_AC01_inspectorSeesOnlySlQmsWithoutSetup`(사내 프로필 2종, runAs 사용자 기준 AppMenuItem + 권한 셋 합의 View Setup) | 통과 |
| AC-2 PSG 미할당 → 업무 객체 탭 없음 | `test_AC02_noPsgShowsNoBusinessTabs`(객체 읽기 권한 0, 사용자 정의 탭 설정 0, runAs describeTabs 사용자 정의 탭 0) | 통과 |
| BR-1 프로필에 객체 권한 없음, 라이선스 | `test_BR1_profilesCarryNoObjectPermissions`(3개 프로필 객체 권한 0, View/Modify All Data·View Setup 0) | 통과 |
| BR-2 페르소나 PSG 15개 배포(이름 고정) | `test_BR2_personaGroupsDeployed` | 통과 |
| BR-3 여러 PSG 동시 보유 | `test_BR3_userCanHoldSeveralPersonaGroups` | 통과 |
| BR-4 앱은 PSG가 정함 | `test_BR4_appsFollowPersonaGroups`(경영진 SL QMS·PMS, IT 운영 3개 + Setup, 품질경영 SL QMS·Admin), `test_BR4_customPermissionsFollowPersonaGroups` | 통과 |
| 에이전트 주의: View/Modify All Data는 SystemAdmin PSG만 | `test_negative_allDataOnlyInSystemAdminGroup` | 통과 |

데모 시나리오 재현: G1-6(E1104 Inspector)은 P1 게이트에서 qms-int에 데모 사용자를 만든 뒤 확인한다. 현재 qms-dev-a에는 사번 필드(User.EmployeeNo__c)가 아직 없어 데모 사용자가 없다.

## 2. 구현 내역

- 프로필 3개: `SL Internal User`(Salesforce), `SL Internal Platform User`(Salesforce Platform), `SL Supplier Portal User`(Customer Community Plus). 객체 권한 없음, 시스템 권한은 API·Lightning·Chatter·도움말·알림·검색만, 표준 앱 숨김, 사내 프로필 기본 앱 SL QMS.
- Lightning 앱 3개: `SL_QMS`, `SL_PMS`, `SL_Admin`(SL Admin에 로그 탭).
- 앱 PS: `CMN_PS_AppQms_Read`, `CMN_PS_AppPms_Read`, `CMN_PS_AppAdmin_Read`, `CMN_PS_Setup_Read`(View Setup + 종속 View Roles).
- 페르소나 PSG 15개: QMS 13개(QualityEngineer, QualityManager, Inspector, SupplierQuality, Auditor, Viewer, QualityAdmin, DevEngineer, LabTester, ProcessEngineer, Metrology, TrainingCoordinator, SupplierPortal) + `CMN_PSG_Executive`, `CMN_PSG_SystemAdmin`(`CMN_PS_Admin_Ops` 포함). PMS PSG 3개는 이름만 예약.
- 검토 반영: Custom Permission `QMS_ViewCost`, `QMS_AuditFindingAnyEdit`, `QMS_DashboardAllPlants`, PS `QMS_PS_Dashboard_AllPlants`(경영진·품질경영 PSG), 공개 그룹 `QMS_GRP_CUSTOMER_QUALITY`, PSG 추가 6개(DevEngineer, LabTester, SupplierPortal, ProcessEngineer, Metrology, TrainingCoordinator).
- 도구: 생성기에 PSG·앱 정의 추가, `scripts/dev/profile-lockdown.py`(프로필 잠금 XML 생성 + 배포 후 시스템 앱 숨김), `build-scratch.sh` 4단계와 CI `deploy-main`에 배포 후 단계 추가, 데모 로더·테스트 데이터 공장이 SL 프로필을 우선 사용.
- 운영 규칙 문서: `docs/dev/persona-psg.md`(기능 WI가 PS를 PSG에 넣는 방법, 뒤 WI가 넣을 검토 반영 항목).
- 핵심 설계 판단:
  1. **새 프로필은 라이선스 기본값을 받는다**: Metadata API로 만든 프로필에도 표준 앱 20여 개, 표준 객체 권한(Platform 29·포털 35개), Platform 라이선스는 View Setup·보고서 등 40여 개 시스템 권한이 켜진다. 대상 Org의 현재 값을 읽어 허용 목록 밖을 모두 끄는 XML을 만들고, 이미 잠긴 Org에서 다시 실행해도 목록이 줄지 않게 기존 XML과 합친다.
  2. **기본 앱 SL QMS**: 프로필은 기본 앱이 하나 있어야 해서(배포 오류로 확인) 사내 프로필의 기본 앱을 SL QMS로 했다. SL PMS·SL Admin은 PSG가 배정하고, QMS PSG도 SL QMS 앱 PS를 따로 가져 기본 앱이 바뀌어도 유지된다.
  3. **Metadata API로 숨길 수 없는 시스템 앱**: Salesforce 라이선스 프로필에 Work, SecurityHub, DataGovernanceConsole, CommandCenterApp가 앱 런처에 붙는다(runAs 테스트로 발견). 이 앱은 Metadata API 목록에 없어 프로필 XML로 끌 수 없으므로, 배포 후 SL 프로필의 앱 접근(SetupEntityAccess) 중 Metadata API가 모르는 행을 지운다. AC-1 테스트는 이 단계 전 Org(CI 첫 검증)에서도 흔들리지 않게 이 4개만 제외하고 판정한다.
  4. **비용·심사 지적 권한은 정의만**: 명세 매핑상 `QMS_ViewCost`는 NCR-007의 `QMS_PS_NcrCost_*`, `QMS_AuditFindingAnyEdit`는 IAU의 `QMS_PS_Audit_Admin`이 담는다. 중복 PS를 만들지 않고 Custom Permission만 정의했다.
  5. **권한 판정 방식**: 앱 런처는 runAs 사용자 기준 AppMenuItem, 시스템·Custom Permission은 사용자 권한 셋(프로필 소유 PS, 직접 PS, PSG 구성 PS) 합으로 판정한다. `FeatureManagement.checkPermission`은 배포 직후 PSG 재계산(비동기) 중에 실패한 적이 있어 쓰지 않았다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | 새 운영 클래스 없음(테스트 클래스만). 기존 클래스 유지: CMN_TriggerHandler 88.9%, CMN_Logger 98.0%, CMN_FeatureSwitch 93.8%, 나머지 100% |
| Apex 테스트 | 32건 통과(SEC-001 8건 + ARC-002 24건) |
| Jest | 해당 없음 |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier | 통과(프로필·PSG·앱은 생성 파일이라 Prettier 제외) |
| 200건 벌크 한도 | 해당 없음(구성 WI) |

## 4. 보안·성능 점검

- [x] 프로필에 객체 권한 없음, View All Data·Modify All Data·View Setup 없음(테스트로 고정)
- [x] View Setup은 `CMN_PSG_SystemAdmin`만(`CMN_PS_Setup_Read`)
- [x] 프로필 이름은 테스트·도구에서만 사용(운영 코드 하드코딩 없음)
- [x] 비밀값·하드코딩 Id 없음(배포 후 단계는 실행 시 Id를 조회)
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | BR-1 프로필 2개 → 3개. `SL Internal Platform User`(Salesforce Platform) 추가 | Scratch Org 사내 라이선스가 Salesforce 1·Platform 4이고, 운영에서도 조회·현장 사용자는 Platform 라이선스를 쓸 수 있어 같은 규칙의 프로필을 하나 더 둠. Vol.0 SEC-001 BR-1 갱신 요청 |
| 명세 차이 | BR-4 "앱 할당은 PSG가 결정" — 사내 프로필 기본 앱 SL QMS는 프로필이 준다 | 플랫폼 제약(프로필 기본 앱 필수). PSG 미할당 사용자는 SL QMS 앱에 홈 탭만 보인다(AC-2 충족) |
| 명세 차이 | 앱 표시용 PS 3개·View Setup PS 추가(`CMN_PS_App*_Read`, `CMN_PS_Setup_Read`) | PSG는 PS만 묶을 수 있어 앱·시스템 권한을 담을 PS가 필요 |
| 명세 차이 | 검토 반영 Custom Permission 중 `QMS_ViewCost`·`QMS_AuditFindingAnyEdit`는 정의만 | NCR-007, IAU-001이 자기 PS에 포함(`docs/dev/persona-psg.md` 4절) |
| 이슈 | Salesforce 라이선스 프로필의 시스템 앱 4개는 배포 후 단계가 있어야 숨겨진다 | build-scratch.sh 4단계, CI deploy-main에 포함. Sandbox·운영 배포 파이프라인에도 같은 단계 필요(RLS WI) |
| 이슈 | 프로필 XML의 숨김 목록은 Org 기능 구성에 따라 다르다 | 새 Org 종류에 처음 배포하기 전 `profile-lockdown.py <별칭>` 재실행 |
| 후속 | 협력사 포털 PSG 구성, 포털 프로필 세부 권한 | QMS-03-SPP |
| 후속 | 모든 QMS PSG에 `QMS_PS_Dashboard_Base` | QMS-07-DSH-002 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS). 배포 후 단계 실행(`profile-lockdown.py qms-dev-a --hide-system-apps`, 앱 접근 32건 해제)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-SEC-001] 페르소나 프로필·PSG·앱 구조와 프로필 잠금 도구`
