# P1 공통 프레임워크·기준정보

모든 WI가 기대는 Apex 프레임워크(트리거·로그·기능 스위치·채번·삭제 통제), 기준정보(조직·공장·고객·품번·협력사·특성·공통 코드), 권한 구조와 다국어 기반을 만든다. W0 26건 중 12건이다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | 새 Scratch Org에 CMN 프레임워크와 기준정보 객체가 배포되고, 데모 기준정보가 적재되어 한·영·중 표시와 권한 구조가 동작 |
| 기간(4명 기준) | 누적 17영업일(P0 이후 약 13일) |
| 마일스톤 | 기준정보 데모 적재, 다국어 표시. ARC-001 AC-1(새 Org에서 CMN 테스트 전부 통과) 첫 확인 |
| 착수 조건 | P0 게이트, Vol.0 W0 WI 승인, 8절 결정 |
| 다음 페이즈로 당겨 착수 가능 | P2 WI 중 선행이 끝난 것(예: SEC-004는 SEC-001만, INT-001은 ARC-002·SEC-004) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 12건 · 39 M/D · W0 12 · SF 트랙 12건 · 외부 트랙 0건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | CMN-00-ARC-002 | Apex 공통 프레임워크 (트리거·로그·예외·기능 스위치) | W0 | 5 | SF | — | CMN_TestDataFactory 포함 제안(CR-4) |
| A2 | CMN-00-ARC-003 | 업무 문서 번호 채번 서비스 | W0 | 3 | SF | ARC-002 | AC의 NCR은 P1에 없어 대체 대상으로 검증 |
| A3 | CMN-00-SEC-003 | 감사 로그·삭제 통제 | W0 | 4 | SF | ARC-002 | — |
| B1 | CMN-00-MDM-002 | 법인·공장·라인·공정 계층 | W0 | 3 | SF | — | — |
| B2 | CMN-00-MDM-003 | 고객·차종 | W0 | 2 | SF | MDM-002 | — |
| B3 | CMN-00-MDM-004 | 제품군·품번(Item) | W0 | 3 | SF | MDM-003 | — |
| B4 | CMN-00-MDM-005 | 협력사·협력사 품번 | W0 | 2 | SF | MDM-004 | — |
| B5 | CMN-00-MDM-006 | 품질 특성(Characteristic)·특별특성 | W0 | 3 | SF + DW 목 | MDM-004 | — |
| C1 | CMN-00-SEC-001 | 페르소나·권한 셋 구조 | W0 | 3 | SF | — | — |
| C2 | CMN-00-MDM-001 | 조직·사용자 기준정보 | W0 | 2 | SF | MDM-002 | — |
| C3 | CMN-00-MDM-007 | 계층형 공통 코드 | W0 | 4 | SF | ARC-002 | — |
| C4 | CMN-00-I18N-001 | 다국어 기반(UI 언어·마스터 데이터·포탈 언어 연동) | W0 | 5 | SF | MDM-001 | — |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

### 레인 A — Apex 프레임워크(ARC-002 → ARC-003, SEC-003)

1. **ARC-002**: `CMN_TriggerHandler`(virtual, 7개 시점, 재진입 방지, 객체·권한·코드 bypass), `CMN_Logger` + `CMN_LogEvent__e`(Publish Immediately) + `CMN_Log__c`, 예외 클래스, `CMN_FeatureSwitch`, `CMN_LogPurgeBatch`(02:00 KST), `CMN_PS_Admin_Ops`.
   - 제안(CR-4): `CMN_TestDataFactory` 코어와 정적 리소스 `QMS_DemoFixtures`(`data/demo/fixtures/demo_fixtures.json`)를 이 WI에 넣는다. 첫 픽스처는 `MASTER_CORE`(레인 B 객체가 생긴 뒤 채움).
   - 제안(DEV-3): 공통 기능 테스트용 대상 객체(10절) 방식을 이 WI에서 확정한다.
   - 제안(CR-12): 데이터 이관 모드(Custom Permission, dev-plan 8.3절)를 이 WI의 bypass 규칙에 넣는다. 이후 상태 규칙을 가진 업무 WI가 이 권한을 확인한다.
   - 이 레인의 결과를 다른 레인이 바로 쓰므로 **첫날 착수**한다. 트리거 베이스가 머지되기 전에는 레인 B·C가 트리거를 만들지 않는다(필드·화면 먼저).
2. **ARC-003**: `CMN_NumberingRule__mdt`, `CMN_NumberCounter__c`(FOR UPDATE), `CMN_NumberingService.assign`, `RecordNo__c` 변경 금지 Validation Rule. 공장 시간대(MDM-002 `TimeZone__c`) 기준 연도 판정.
   - 데모 보강: RecordNo가 이미 있으면 채번하지 않고 카운터를 그 값 이상으로 맞춘다(데모·이관 적재).
   - AC-1(NCR 200건)은 NCR이 P5에 생기므로 테스트 대상 객체로 검증하고, P5 게이트에서 NCR로 다시 확인한다(보고서 "명세 차이").
3. **SEC-003**: `CMN_DeleteGuard__mdt`, `CMN_DeleteLog__c`(전 필드 JSON 스냅숏), 필드 이력 추적 규칙. AC-1(4M)·AC-2(NCR)는 테스트 대상 객체로 검증하고 P5·P6 게이트에서 실제 객체로 다시 확인한다. Shield Field Audit Trail은 D-6 결정 전 범위 밖.

### 레인 B — 조직·제품 기준정보(MDM-002 → 003 → 004 → 005, 006)

임계 경로(MDM-002 → 003 → 004 → 005 → P2 SEC-002 → APV-001 …)다. 가장 먼저, 가장 빠른 사람이 맡는다.

1. **MDM-002**: `CMN_Company__c`, `CMN_Plant__c`(PlantCode, TimeZone), `CMN_Line__c`, `CMN_Operation__c`(OperationType). 데모 보강: `CMN_Operation__c.ExternalKey__c`(`{PlantCode}-{LineCode}-{OpCode}`).
2. **MDM-003**: Account 레코드타입 `CMN_Customer`·`CMN_Supplier`, 고객 CSR 필드(ContainmentDueDays, EightDDueDays, PpapDefaultLevel, AuditStandard, ClaimFormTemplate), `CMN_Vehicle__c`. 보강: `Account.RootCauseDueDays__c`(Vol.5 요청).
3. **MDM-004**: `CMN_ProductGroup__c`, `CMN_Item__c`(ItemType, PartCategory), `CMN_ItemPlant__c`, `CMN_ItemVehicle__c`. 보강: `CMN_ItemVehicle__c.ExternalKey__c`, `UsagePerVehicle__c`(Vol.5 요청).
4. **MDM-005**: 협력사 필드(SupplierGrade, Iatf*), `CMN_SupplierItem__c`(PpapStatus, InspectionLevel, 협력사·품번·공장 유일).
5. **MDM-006**: `CMN_Characteristic__c`(CharType, LSL/USL, SpecialClass CC/SC, SpcRequired, TargetCpk 기본값, 버전·ACTIVE 잠금). 보강: Unit 값 lm, cc/min, mA.
6. 레인 B가 끝나면 `CMN_TestDataFactory`에 `MASTER_CORE` 픽스처를 채운다(레인 A와 협의).

### 레인 C — 사용자·권한·코드·다국어(SEC-001, MDM-007, MDM-001 → I18N-001)

1. **SEC-001**(첫날 착수 가능, 선행 ARC-001뿐): 페르소나별 PSG 구조와 이름. 데모 사용자가 쓰는 PSG 14개(`CMN_PSG_SystemAdmin`, `CMN_PSG_Executive`, `QMS_PSG_QualityManager`, `QMS_PSG_QualityEngineer`, `QMS_PSG_Inspector`, `QMS_PSG_SupplierQuality`, `QMS_PSG_Metrology`, `QMS_PSG_LabTester`, `QMS_PSG_Auditor`, `QMS_PSG_DevEngineer`, `QMS_PSG_ProcessEngineer`, `QMS_PSG_QualityAdmin`, `QMS_PSG_TrainingCoordinator`, `QMS_PSG_Viewer`)를 이 WI에서 빈 그룹이라도 만들어 둔다. 이후 WI는 자기 PS를 만들어 이 PSG에 넣는다. review-pack Vol.0 변경 요청 9건(SEC-001)을 먼저 반영한다.
2. **MDM-007**(ARC-002 뒤): `CMN_CodeGroup__c`·`CMN_Code__c`(3단계), `cmnCodePicker`. 보강: `ExternalKey__c` = 계층 경로 전체(`DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG`), 그룹 초기값(GAUGE_TYPE·IQC_COMMON_CHECK·DEFECT_LOCATION·DOC_CLASS, 분석실 장비 4종), Vol.4 요청 그룹 DEV_PHASE·DEV_ACTIVITY_TYPE. review-pack 변경 요청 9건. AC-2(NCR 참조 코드 삭제 차단)는 P5에서 다시 확인.
3. **MDM-001**(MDM-002 뒤): `CMN_Department__c`(Manager, FullPath 비동기 재계산, 순환 차단), User 필드(`EmployeeNo__c` External ID 등). 보강: 데모 사용자 수가 라이선스에 묶이므로 없는 사용자 Lookup의 대체 규칙(로더 `onMissingUser`)을 명세에 적는다.
4. **I18N-001**(MDM-001 뒤): Org 기본 언어 ko, 번역 언어(en_US·zh_CN 완전 지원, pl·es·pt_BR), `User.LanguageOverride__c`, 마스터 `NameEn__c`·`NameZh__c`·`DisplayName__c` 수식, `cmnLanguageSwitcher`, `CMN_SamlJitHandler`(사용자를 만들지 않고 언어만 갱신). 한국어 리터럴 검사(AC-4)를 CI 정적 검사에 추가한다.

## 4. Scratch Org 준비

| 항목 | 방법 |
| --- | --- |
| 기본 언어 ko, Translation Workbench, 번역 언어 5종 | 정의 파일(`enableEndUserLanguages` 포함). 번역은 Translation 메타데이터 배포로 저장됨(P0 S-2, 수동 설정 없음) |
| 데모 사용자 최대 5명 + 관리자 E1901 | 데모 로더가 남은 라이선스로 생성(User 필드 배포 후, P0 S-5). PSG는 SEC-001 배포 후 할당. 누구를 만들지는 DEV-4 결정 |
| 프로필 조회 | ko Org는 표준 프로필 이름이 한국어. `CMN_TestDataFactory`와 테스트 사용자는 프로필을 `UserLicense.Name`으로 찾음(P0 3.4절) |
| Account 레코드타입 | MDM-003 메타데이터 |
| 앱 `SL QMS` | SEC-001(AC-1: Inspector는 SL QMS 앱만) |

SAML JIT 핸들러는 IdP 없이 단위 테스트로만 확인하고, 실제 SSO는 P2(TDO-002)에서 테스트 IdP로 확인한다.

## 5. 목·대체

해당 없음(외부 의존 없음). 다만 P1 AC 중 아직 없는 업무 객체(NCR·4M)를 예로 든 것은 테스트 대상 객체로 대신한다(10절, CR-11).

## 6. 데모 데이터

```bash
scripts/demo/load_salesforce.sh qms-int --upto-phase 1
```

| 파일 | 객체 | 행 |
| --- | --- | --- |
| 01 | CMN_Company__c | 4 |
| 02, 02a | CMN_ProductGroup__c | 3 + 2 |
| 03 | CMN_Plant__c | 5 |
| 04 | CMN_Line__c | 9 |
| 05 | CMN_Operation__c | 28 |
| 06 | CMN_CodeGroup__c | 13 |
| 07, 07a, 07b | CMN_Code__c(L1·L2·L3) | 109 + 68 + 33 |
| 08, 09 | Account(고객, 협력사) | 6 + 8 |
| 10 | CMN_Vehicle__c | 9 |
| 11 | CMN_Item__c | 25 |
| 12 | CMN_ItemPlant__c | 38 |
| 13 | CMN_ItemVehicle__c | 21 |
| 14 | CMN_SupplierItem__c | 21 |
| 15 | CMN_Characteristic__c | 25 |
| 16, 17b | CMN_Department__c | 21(17b는 Manager 갱신) |
| 17a | User(데모 사용자 필드 갱신) | 생성된 사용자만 |

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G1-1 | 새 `qms-int`에 전체 배포, RunLocalTests | ARC-001 AC-1 | 실패 0, 클래스별 커버리지 85% 이상 |
| G1-2 | 기준정보 적재 두 번 | INT-001 원칙(멱등) | 6절 행 수와 Org 건수 일치, 두 번째 실행 후 건수 불변 |
| G1-3 | en_US 사용자로 불량 유형 피커 | MDM-007 AC-1 | NameEn 표시, 비면 Name |
| G1-4 | pl 사용자로 코드 표시 | I18N-001 AC-3 | NameEn 표시 |
| G1-5 | 스위처로 zh_CN 선택 | I18N-001 BR-4 | LanguageOverride true, 중국어 UI |
| G1-6 | Inspector PSG만 가진 데모 사용자(E1104) | SEC-001 AC-1·2 | SL QMS 앱만, Setup 불가 |
| G1-7 | 미국 공장 시간대 연도 경계 채번 | MDM-002 AC-2, ARC-003 AC-2 | 공장 시간 기준 연도 |
| G1-8 | 특성 규격 역전·ACTIVE 수정 | MDM-006 AC-1·2 | 차단, "새 버전" 안내 |
| G1-9 | 한국어 리터럴 검사 | I18N-001 AC-4 | 0건(테스트 클래스 제외) |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D-8 임직원 동기화 방식(MDM-001의 User·Employee 역할 분담) |
| 결정 | DEV-3 공통 기능 테스트 대상 객체 방식(10절) |
| 결정 | I18N-001 오픈 이슈: 포탈 SAML 어설션의 언어 속성명·값 형식(구현은 속성명을 Custom Metadata로 두고 진행 가능) |
| 명세 | review-pack 2절 Vol.0 변경 요청 24건: ARC-003 1, MDM-003 2, MDM-004 1, MDM-005 2, MDM-007 9, SEC-001 9. 그리고 3.3 DoD 1건(새 KPI는 정의 메타데이터·라벨 3개 언어를 같은 WI에서) |
| 명세 | 데모 보강(CR-6): ARC-003 RecordNo 선적재, MDM-001 대체 사용자 규칙, MDM-002 Operation ExternalKey, MDM-003 RootCauseDueDays, MDM-004 ItemVehicle ExternalKey·UsagePerVehicle, MDM-006 Unit 값, MDM-007 ExternalKey 경로·코드 그룹 초기값 |
| 명세 | CR-4 `CMN_TestDataFactory` 소유(ARC-002), CR-11 공통 WI AC의 업무 객체 예시, CR-12 이관 모드(ARC-002) |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| 프레임워크(ARC-002) 지연이 모든 레인을 막음 | 첫날 착수, 트리거 베이스·로거를 먼저 작게 머지 |
| PSG 이름이 나중에 바뀌어 데모 사용자 할당 실패 | SEC-001에서 14개 이름을 확정하고 데모 사용자 JSON과 맞춘다 |
| Custom Label·번역 파일 병합 충돌(세 레인 동시) | P0 분해 옵션, 라벨 키 접두어를 WI 화면별로 |
| 코드 그룹 초기값이 여러 Vol.에서 계속 늘어남 | MDM-007은 그룹 구조·초기값 로더만, 각 Vol. 그룹 값은 소유 WI가 데이터로 추가하는 규칙을 보고서에 명시 |

## 10. 공통 기능의 테스트 대상(CR-11, DEV-3)

P1~P3 공통 WI의 AC는 NCR·4M 같은 QMS 객체를 예로 든다(ARC-003 AC-1, MDM-007 AC-2, SEC-002 AC-1~4, SEC-003 AC-1·2, UX-003 AC-1, DOC-001 AC-1, APV-002 AC-1, UX-001 AC-1, UX-002 AC-1). 그 객체는 P5·P6에 생기므로 공통 WI 단계에서는 다른 대상으로 검증해야 한다.

| 안 | 내용 | 장점 | 단점 |
| --- | --- | --- | --- |
| 1(권고) | 테스트 전용 객체 `CMN_TestRecord__c`(Plant__c, Status__c, RecordNo__c 등)를 별도 패키지 디렉터리 `force-app-cmn-test`에 두고 운영 배포에서 제외 | 공통 기능을 실제 업무 객체처럼 검증. 각 QMS 객체에 묶이지 않음 | 패키지 디렉터리 1개 추가(ARC-001 변경) |
| 2 | CMN 마스터 객체(예: `CMN_Item__c`)로 대체 | 추가 객체 없음 | 마스터에는 상태·공장 격리가 맞지 않아 일부 AC를 흉내 내기 어려움 |

어느 안이든 실제 QMS 객체 AC는 객체 소유 페이즈 게이트에서 "회귀 AC"로 다시 확인한다(P5: NCR, P6: 4M).

## 11. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| 2026-11-02 | `qms-int`(P0 이후 빈 Org, `build-scratch.sh qms-int --reuse --phase 1`) | **통과**. G1-1 전체 배포 + RunLocalTests 138건 통과(저장소 Apex 129건 + Experience Cloud 기본 9건), 저장소 클래스 전부 85% 이상(전체 97%). G1-2 P1 데모 16개 대상 건수가 CSV 고유 키와 같고 두 번째 적재 후 불변(`scripts/gate/p1-check.py --reload`). G1-6 E1104는 `SL Internal Platform User` + `QMS_PSG_Inspector`만, View Setup 없음. G1-9 한글 리터럴 0건. G1-3·4·5·7·8은 같은 실행의 Apex 테스트(MDM-007 AC-1, I18N-001 AC-3·AC-2·BR-4, ARC-003 AC-2·MDM-002 AC-2, MDM-006 AC-1·2)와 Jest 13건 | ① 새 내부 사용자는 실제 4명(5번째 Platform 생성 거부 — 새 Org에서 재현) → `phase-users.json` 순서 조정, dev-plan 8.4절 정정. ② 첫 실행에서 빌드 스크립트가 `set -o pipefail` + `find \| grep -q`로 메타데이터를 "없음"으로 판정해 배포 없이 성공 처리 → `find -print -quit`로 고침(CI 워크플로 같은 패턴도). ③ 화면 확인(앱 런처·언어 스위처·코드 피커 실제 렌더링)은 UI 세션이 필요해 사용자 확인으로 남김. ④ CI 실제 실행(ARC-001 AC-2)은 GitHub push·시크릿 등록 후 |
