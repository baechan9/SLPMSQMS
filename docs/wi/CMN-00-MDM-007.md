# CMN-00-MDM-007 완료 보고 — 계층형 공통 코드

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-MDM-007 (vol0-cmn-common.md CMN-00-MDM-007) |
| Wave / 공수(계획 → 실제) | W0 / 4 M/D → 약 1.5 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack MDM-007 변경 요청 9건 반영(ExternalKey 경로, 코드 그룹·값 — 데이터 시드) |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 영어 사용자 → NameEn, 비면 Name | `CMN_CodeService_Test.test_AC01_englishUserSeesNameEnWithFallback`(en_US 사용자 runAs, 경로도 언어별), Jest `cmnCodePicker`가 서버 표시명 사용 | 통과 |
| AC-2 NCR이 참조하는 코드 삭제 → 차단 | `test_AC02_referencedCodeCannotBeDeleted`(업무 객체 대신 테스트 대상 객체 `CMN_TestRecord__c` — CR-11·DEV-3, 하위 코드가 있는 코드도 차단, 참조 없는 리프는 삭제) | 통과 |
| AC-3 비활성 중분류 → 그 하위도 미표시 | `test_AC03_inactiveMiddleHidesItsChildren` | 통과 |
| BR-2 단계 ≤ 최대 단계 | `test_BR2_levelCannotExceedMax` | 통과 |
| 단계·키·경로, 하위 재계산, 그룹·중복·입력 검증, 그룹 삭제 금지 | `test_levelKeyAndPathCalculated`, `test_renameRefreshesDescendantPaths`, `test_negative_parentFromOtherGroupAndDuplicate`, `test_negative_pickerInputValidation`, `test_negative_codeGroupDeleteBlocked` | 통과 |
| 벌크·데모 | `test_bulk200Codes`(SOQL 3회 이하), `test_demoFixturesLoadCodeTree` | 통과 |
| 화면(cmnCodePicker) | Jest 8건: 1단계 표시, 연쇄 선택·리프에서만 값, 하위 없는 코드 즉시 값, maxLevel 축소, 초기 값 체인 표시, 빈 상태, 오류(라벨·role=alert), 로딩 스피너 | 통과 |

데모 데이터 재현(qms-dev-a, `--upto-phase 1`): 코드 그룹 15행, 코드 152+69+33행 실패 0. 경로·단계는 트리거가 계산(예: `외관 > 긁힘 > 렌즈 긁힘`).

## 2. 구현 내역

- 객체·필드: `CMN_CodeGroup__c`(GroupCode·MaxLevel 1~4·Description, 삭제 금지), `CMN_Code__c`(그룹 주종 — 그룹 읽기로 편집, Code·Parent·Level·NameEn/Zh·SortOrder·IsActive·Attribute1~3·ExternalKey(경로 전체, Text 255)·Path, 필드 이력), 검증 규칙 3개, 탭 2개(SL Admin). 테스트 전용 `CMN_TestRecord__c`(코드·공장 Lookup, 탭·권한 없음 — DEV-3, ARC-003이 채번 필드를 더함).
- Apex: `CMN_CodeService`(단계·키·경로 — 같은 저장 묶음의 상위 반영, 하위 일괄 재계산, 참조 중 삭제 차단), `CMN_CodeSelector`, `CMN_CodePickerController`(@AuraEnabled cacheable, 언어별 이름, 비활성 체인 제외, 입력 검증), 핸들러 2개 + 트리거 2개.
- LWC: `cmnCodePicker`(속성 groupCode·label·maxLevel·value·required·disabled, change 이벤트 {value, path, externalKey}, 라벨 5개 ko·en·zh, 로딩·빈·오류 상태).
- 권한: `CMN_PS_Code_Read`(사내 PSG 14개, 피커 컨트롤러), `CMN_PS_Code_Admin`(QualityAdmin·SystemAdmin). 라벨 9개.
- 데이터 시드: 데모 생성기 코드에 검토 반영 값을 더했다 — DOC_CLASS 38개(+ PPAP > SUB_COMPONENT), ALERT_DISMISS_REASON 그룹·값, QMS_PROCESS 그룹, AI_EXCLUDE_REASON NOT_APPLICABLE, CAUSE_5M1E 최대 3단계. 코드 CSV(06·07)는 운영 초기값 시드로도 쓴다.
- 공통 도구 보강: ESLint 설정에 Jest 버전 고정(Code Analyzer ESLint 엔진이 Jest를 못 찾던 문제 — 첫 LWC에서 발견), 점검 스크립트가 배포 후 PSG 재계산을 기다림(재계산 중 PSG 할당 테스트 실패 방지), 분석 결과 출력 보강.
- 핵심 설계 판단:
  1. **외부 키는 경로 전체(검토 반영)**: `{GroupCode}/{Code}`이면 다른 상위 아래 같은 코드가 충돌한다. 키 길이를 Text(255)로 늘렸다.
  2. **참조 검사는 Org의 하위 관계로**: 코드를 Lookup하는 사용자 정의 객체를 describe로 찾아 검사하므로 업무 객체가 늘어도 고칠 필요가 없고, 업무 WI가 Lookup 삭제 제약을 SetNull로 두어도 BR-1이 지켜진다.
  3. **표시명·비활성 판단은 서버에서**: 사용자 언어 선택과 상위 비활성 체인 제외를 컨트롤러가 해서 피커는 표시만 한다(다른 화면이 같은 규칙을 재사용).
  4. **업무 객체는 리프 Lookup + Path 사본**: 피커 change 이벤트가 path·externalKey를 함께 준다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_CodeService 98.2%, CMN_CodePickerController·Selector·핸들러 100% |
| Apex 테스트 | 107건 통과(MDM-007 12건 포함) |
| Jest | 8건 통과 |
| Code Analyzer(심각도 1~2) | 0건(describe 지연 로딩) |
| ESLint / Prettier | 통과 |
| 200건 벌크 한도 | 코드 200건 저장 시 트리거 SOQL 3회 이하 |

## 4. 보안·성능 점검

- [x] 피커 입력(그룹 코드) 서버 재검증(형식·길이), 오류는 라벨, 조회는 USER_MODE
- [x] LWC: 서버 원문 미노출, innerHTML 없음, 콤보박스 라벨, 오류 role=alert
- [x] 참조 검사 동적 SOQL은 describe 이름 + 바인드, SYSTEM_MODE 사유 주석
- [x] 루프 안 SOQL·DML 없음(참조 검사는 참조 객체 수만큼 — 코드 삭제는 드문 관리 작업)
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이(CR 반영) | ExternalKey = 경로 전체, Text(90) → Text(255) | review-pack·데모 보강 |
| 명세 차이 | 코드 그룹 Description__c, 코드 그룹 삭제 금지, 코드 변경 금지, 하위가 있는 코드 삭제 금지 | 기준정보 공통 규칙 |
| 명세 차이 | 테스트 대상 객체 `CMN_TestRecord__c`를 MDM-007에서 생성 | AC-2 검증. DEV-3(ARC-003 소유)를 당겨 만듦 |
| CR 반영(데이터) | DOC_CLASS 값·그룹(ALERT_DISMISS_REASON, QMS_PROCESS)·AI_EXCLUDE_REASON·CAUSE_5M1E 3단계 | 데모 생성기 코드 = 시드. 값 이름(Name)은 코드 문자열 — 현업 명칭은 SL 현행 코드로 교체(명세) |
| 후속(CR) | QMS_PROCESS 값과 Attribute1(책임 부서)·Attribute2(공장) | QMS-06-IAU-001 |
| 후속(CR) | DEFECT_TYPE Attribute1 = SAFETY 규칙, DOC_CLASS Attribute2 = INDEX_SCOPE 규칙, GAUGE_TYPE 속성 | NCR-002, AIQ-006, GAU-001 |
| 후속(CR) | DEV_ACTIVITY_TYPE 관리 주체 PMO 권한 | PMS PSG 생성 시 `CMN_PS_Code_Admin` 또는 그룹별 권한 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-MDM-007] 계층형 공통 코드와 cmnCodePicker`
