# 페르소나·권한 구조 운영 규칙(CMN-00-SEC-001)

기능 WI를 구현할 때 권한을 어디에 넣는지 정리한다. 명세는 Vol.0 CMN-00-SEC-001, 기능별 PS ↔ PSG 매핑은 각 Vol. 3절 "권한 셋과 페르소나 매핑" 표가 기준이다.

## 1. 구조

| 층 | 무엇 | 위치 |
| --- | --- | --- |
| 프로필 | `SL Internal User`(Salesforce), `SL Internal Platform User`(Salesforce Platform), `SL Supplier Portal User`(Customer Community Plus). 객체 권한 없음, 시스템 권한은 로그인·Lightning·API·검색·알림만, 기본 앱 SL QMS | `force-app-cmn/main/default/profiles/` — `scripts/dev/profile-lockdown.py`가 만든다 |
| 기능 PS | `{접두어}_PS_{기능}_{Read/Edit/Approve/Admin}` — 객체·필드·탭·클래스·Custom Permission | 각 기능 WI가 `meta-src/**/permissionsets/<이름>.json` |
| 페르소나 PSG | 아래 15개. 기능 PS를 묶는다 | `meta-src/{cmn,qms}/permissionsetgroups/<이름>.json` |
| 앱 | `SL_QMS`, `SL_PMS`, `SL_Admin`. 앱 표시는 앱 PS(`CMN_PS_AppQms_Read` 등)로 PSG가 정한다 | `meta-src/cmn/applications/` |
| Custom Permission | `QMS_ViewCost`, `QMS_AuditFindingAnyEdit`, `QMS_DashboardAllPlants`(검토 반영). 앞의 둘은 정의만 하고 소유 WI의 PS가 담는다 | `force-app-qms/main/default/customPermissions/` |
| 공개 그룹 | `QMS_GRP_CUSTOMER_QUALITY`(고객 품질 담당 전원) | `force-app-qms/main/default/groups/` |

## 2. 기능 WI가 할 일

1. 자기 PS 정의를 만든다(객체·필드 권한은 생성기가 정의에서 만든다).
2. 자기 Vol. 3절 매핑 표에 적힌 PSG 정의 JSON의 `permissionSets`에 PS 이름을 더한다. PSG는 중첩되지 않으므로 "QualityEngineer + 결재"인 QualityManager처럼 상위 페르소나에도 같은 PS를 넣는다.
3. 업무 탭은 PS의 `tabs`와 앱 정의의 `tabs`에 함께 넣는다(관리 화면은 `SL_Admin`, 업무 화면은 `SL_QMS`).
4. `python3 scripts/dev/metagen.py` 후 `CMN_PersonaSecurity_Test`가 계속 통과하는지 본다(View All Data·Modify All Data는 CMN_PSG_SystemAdmin 밖 금지).

## 3. PSG와 현재 구성

| PSG | 페르소나 | 앱 | 이 WI에서 넣은 PS |
| --- | --- | --- | --- |
| QMS_PSG_QualityEngineer | 공장 품질 엔지니어 | SL QMS | CMN_PS_AppQms_Read |
| QMS_PSG_QualityManager | 품질팀장 | SL QMS | CMN_PS_AppQms_Read |
| QMS_PSG_Inspector | 현장 검사원 | SL QMS | CMN_PS_AppQms_Read |
| QMS_PSG_SupplierQuality | 협력사 품질(SQE) | SL QMS | CMN_PS_AppQms_Read |
| QMS_PSG_Auditor | 내부·협력사 심사원 | SL QMS | CMN_PS_AppQms_Read |
| QMS_PSG_Viewer | 개발·구매·생산 일반 | SL QMS | CMN_PS_AppQms_Read |
| QMS_PSG_QualityAdmin | 품질경영팀 | SL QMS, SL Admin | + CMN_PS_AppAdmin_Read, QMS_PS_Dashboard_AllPlants |
| QMS_PSG_DevEngineer | 개발팀(인정시험 계획) | SL QMS | CMN_PS_AppQms_Read |
| QMS_PSG_LabTester | 신뢰성·광학 시험, 분석실 | SL QMS | CMN_PS_AppQms_Read |
| QMS_PSG_ProcessEngineer | 생산기술·공정 | SL QMS | CMN_PS_AppQms_Read |
| QMS_PSG_Metrology | 측정기·교정 | SL QMS | CMN_PS_AppQms_Read |
| QMS_PSG_TrainingCoordinator | 공장 교육 담당 | SL QMS | CMN_PS_AppQms_Read |
| QMS_PSG_SupplierPortal | 협력사 포털 사용자 | 없음(포털) | 없음 — QMS-03-SPP가 채운다 |
| CMN_PSG_Executive | 경영진 | SL QMS, SL PMS | + CMN_PS_AppPms_Read, QMS_PS_Dashboard_AllPlants |
| CMN_PSG_SystemAdmin | IT 운영 | 3개 모두 | CMN_PS_AppQms_Read, CMN_PS_AppPms_Read, CMN_PS_AppAdmin_Read, CMN_PS_Setup_Read, CMN_PS_Admin_Ops |

PMS PSG(`PMS_PSG_PM`, `PMS_PSG_CFT`, `PMS_PSG_PMO`)는 이름만 예약했다. PMS Vol.이 만든다.

## 4. 검토 반영으로 뒤 WI가 넣어야 할 것

| 넣을 것 | PSG | 담당 WI |
| --- | --- | --- |
| QMS_PS_FourM_Request, QMS_PS_Ncr_Create, QMS_PS_Ncr_Respond | QMS_PSG_Viewer(Vol.6a 3절 매핑대로 다른 PSG에도) | 각 PS를 만드는 QMS-06 4MC·NCR WI |
| Custom Permission QMS_ViewCost를 QMS_PS_NcrCost_Read·Edit에 포함(비용 필드 FLS와 함께) | QualityManager, CMN_PSG_Executive(조회) / QualityEngineer, SupplierQuality(입력) | QMS-06-NCR-007 |
| Custom Permission QMS_AuditFindingAnyEdit를 QMS_PS_Audit_Admin에 포함 | QMS_PSG_QualityAdmin | QMS-06-IAU-001(QMS_PS_Audit_Admin 생성) |
| QMS_PS_Dashboard_Base | 모든 QMS PSG | QMS-07-DSH-002 |
| QMS_PS_Lele_Read, QMS_PS_Lele_Edit | PMS PSG(PM·CFT·PMO) | QMS-04-LEL-005(PMS PSG 생성 후) |
| QMS_PS_Ai_User, QMS_PS_Ew_Edit, QMS_PS_Ai_Admin + Agentforce 라이선스 할당 규칙 | Vol.8 3절 매핑 | QMS-08 AIQ WI |
| QMS_GRP_CUSTOMER_QUALITY 구성원 | 고객 품질 담당(품질경영팀이 관리) | 운영. B2B-005·006, CLM-007은 그룹 이름으로 알림 |

## 5. 배포 후 단계

Salesforce 라이선스 프로필에는 Metadata API에 나오지 않는 시스템 앱(Work, SecurityHub, DataGovernanceConsole, CommandCenterApp)이 앱 런처에 붙는다. `scripts/org/build-scratch.sh` 4단계와 CI `deploy-main`이 `profile-lockdown.py <별칭> --hide-system-apps`로 지운다. 새 Org 종류(Sandbox·운영)에 처음 배포할 때는 그 Org로 `profile-lockdown.py <별칭>`을 다시 실행해 프로필 XML의 숨김 목록을 갱신한다(기존 목록과 합친다).
