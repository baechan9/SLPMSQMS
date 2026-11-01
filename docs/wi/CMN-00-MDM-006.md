# CMN-00-MDM-006 완료 보고 — 품질 특성(Characteristic)·특별특성

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-MDM-006 (vol0-cmn-common.md CMN-00-MDM-006) |
| Wave / 공수(계획 → 실제) | W0 / 3 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), 데모 보강(Unit lm·cc/min·mA) 반영 |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 USL 3.1·LSL 2.9·기준값 3.2 → 차단 | `CMN_CharacteristicService_Test.test_AC01_specOrderViolationRejected` | 통과 |
| AC-2 ACTIVE 특성 USL 수정 → 차단, "새 버전" 안내 | `test_AC02_activeSpecChangeRejectedWithNewVersionHint`(USL 필드에 검증 규칙 오류, 문구가 새 버전 생성 안내) | 통과 |
| AC-3 CC 신규 목표 Cpk 공란 → 1.67 | `test_AC03_targetCpkDefaults`(CC 1.67, SC 1.33) | 통과 |
| BR-3 새 버전 → 활성화 시 구 버전 종료 | `test_BR3_newVersionActivationClosesOldVersion`(편집 권한자, 구 버전 2025-12-31 종료·OBSOLETE, 새 키, 품번 특별특성 수 1 유지) | 통과 |
| 음수·권한·오류 처리 | `test_negative_versionRules`(초안의 새 버전, 이른 시작일, 시작일 없음, 활성 재활성화, 잘못된 Id), `test_negative_controllerNeedsEditPermission`, `test_negative_unexpectedErrorMaskedAndLogged`(공통 문구 + 오류 로그) | 통과 |
| 삭제·중복·계량형 규칙·벌크·데모 | `test_deleteOnlyDraftAndDuplicateKey`, `test_negative_variableNeedsLimitAndUnit`, `test_bulk200Characteristics`(SOQL 2회 이하), `test_demoFixturesLoadCharacteristics` | 통과 |

데모 데이터 재현(qms-dev-a, `--upto-phase 1`): 특성 25행 실패 0, 품번 특별특성 수가 데모 값으로 계산(예: 63117-BE1L 4).

## 2. 구현 내역

- 객체·필드: `CMN_Characteristic__c`(품번 주종 — 품번 읽기만으로 작성 가능, CharNo·CharType·Nominal/USL/LSL(18,6)·Unit(14값)·SpecialClass·CustomerSymbol·SpcRequired·TargetCpk·Status(서비스 전용)·EffectiveFrom/To·ExternalKey, 필드 이력), 검증 규칙 6개(규격 순서, 계량형 규격·단위, ACTIVE 규격 잠금, ACTIVE 시작일, 기간, 상태 필수). `CMN_Item__c.SpecialCharCount__c`(롤업). 탭(SL Admin·SL QMS), 품번 레이아웃에 특성 관련 목록.
- Apex: `CMN_CharacteristicService`(목표 Cpk 기본값, 외부 키, 초안만 삭제, `newVersion`, `activate`), `CMN_CharacteristicSelector`, `CMN_CharacteristicController`(@AuraEnabled 새 버전·활성화, 입력·권한 재검증, 라벨 오류·로그), 핸들러 + 트리거.
- 권한: `CMN_PS_Characteristic_Read`(사내 PSG 14개), `CMN_PS_Characteristic_Edit`(초안 작성·삭제, 컨트롤러, 탭 — QualityEngineer·QualityManager·DevEngineer·QualityAdmin·SystemAdmin). 라벨 6개.
- 공통 도구 보강: 테스트 데이터 공장이 실행 사용자 FLS(isCreateable)로 필드를 거르던 것을 시스템 속성(수식·자동 번호·주종)으로 바꿈 — 관리자도 PS 없이는 새 필드 FLS가 없어 픽스처 값(상한·단위 등)이 조용히 빠지고 있었다.
- 핵심 설계 판단:
  1. **버전은 새 레코드**: ACTIVE 규격은 검증 규칙으로 잠그고, 새 버전(DRAFT)은 규격을 복사해 만든다. 활성화 때 같은 품번·특성 번호의 ACTIVE를 새 시작일 전날로 닫고 OBSOLETE로 바꾼다. 외부 키에 시작일이 들어가 버전마다 키가 다르다.
  2. **상태는 서비스 전용**: 사용자 FLS 읽기, 서비스가 시스템 모드로 바꾼다. 새 버전 생성은 사용자 모드 저장(사용자가 만들 수 있는 필드만 복사).
  3. **특별특성 수 롤업**: 명세(SpecialClass ≠ NONE)에 ACTIVE 조건을 더했다. 폐기 버전까지 세면 버전이 바뀔 때마다 수가 늘어난다.
  4. **초안만 삭제**: 활성·폐기 특성은 판정 이력의 규격 근거라 지우지 않는다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_CharacteristicService 96.8%, CMN_CharacteristicController 95.2%, Selector·핸들러 100% |
| Apex 테스트 | 95건 통과(MDM-006 12건 포함) |
| Jest | 해당 없음(화면은 후속) |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier | 통과 |
| 200건 벌크 한도 | 특성 200건 저장 시 트리거 SOQL 2회 이하 |

## 4. 보안·성능 점검

- [x] 컨트롤러: Id 형식·객체 권한 재검증, 오류는 Custom Label(`AuraHandledException`), 예상 못 한 오류는 `CMN_Logger.error` 후 공통 문구
- [x] 사용자 입력 저장은 USER_MODE, 상태 변경만 SYSTEM_MODE(서비스 전용 필드)
- [x] 루프 안 SOQL·DML 없음
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이(데모 보강) | Unit 값 lm·cc/min·mA 추가 | 개발 플랜 CR-6 |
| 명세 차이 | Status·EffectiveFrom 필수 조건을 기본값·검증 규칙으로(서비스 전용 필드) | 필수 필드는 FLS 읽기 전용 불가 |
| 명세 차이 | SpecialCharCount__c에 ACTIVE 조건 추가, 초안만 삭제, 시작일 없는 초안 키 `-DRAFT` | 버전 관리와 함께 동작하도록 |
| 명세 차이 | 새 버전·활성화 서비스와 @AuraEnabled 컨트롤러 추가 | BR-3·AC-2의 "새 버전 생성" 경로. 화면(버튼·LWC)은 관리계획서 화면 WI(QMS-04)에서 |
| 후속 | Snowflake CORE.CHARACTERISTIC 동기화(BR-4) | CMN-00-DWH-002 |
| 오픈 이슈 | 관리계획서·PFMEA 원천 도구 | 명세 오픈 이슈 유지 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-MDM-006] 품질 특성·특별특성과 규격 버전 관리`
