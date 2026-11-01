# CMN-00-MDM-002 완료 보고 — 법인·공장·라인·공정 계층

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-MDM-002 (vol0-cmn-common.md CMN-00-MDM-002) |
| Wave / 공수(계획 → 실제) | W0 / 3 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), 데모 보강 CR-6(공정 ExternalKey) 반영 |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 KR01에 L03이 있을 때 L03 추가 → 중복 오류 | `CMN_PlantService_Test.test_AC01_duplicateLineCodeInPlantRejected`(대소문자만 다른 l03, 라인 코드 필드에 라벨 문구), `test_AC01_duplicateWithinOneSaveRejected`(같은 저장 묶음) | 통과 |
| AC-2 미국 공장(America/Chicago) 채번 연도 → 공장 시간대 기준 | `test_AC02_plantTimeZoneDecidesLocalYear`(2027-01-01 03:00 UTC → US01 2026-12-31, KR01 2027-01-01). 채번 서비스 연결은 ARC-003 AC-2에서 다시 확인 | 통과 |
| BR-1 외부 키 자동 생성(사용자 입력 무시), 다른 공장 같은 코드 허용 | `test_BR1_externalKeysAssignedFromCodes`, `test_BR1_sameLineCodeInOtherPlantAllowed`, `test_BR1_migrationLineCodeFixRefreshesOperationKeys` | 통과 |
| BR-2 삭제 금지·비활성화 허용 | `test_BR2_deleteBlockedDeactivateAllowed`(법인·공장·라인·공정 4개 모두) | 통과 |
| (음수) 코드 변경 차단, 없는 공장 | `test_negative_codeCannotChangeAfterCreate`, `test_negative_unknownPlantThrows` | 통과 |
| 벌크 200건 | `test_bulk200LinesAndOperations`(라인 200·공정 200, 트리거 SOQL 각 2회 이하) | 통과 |
| 데모 픽스처 | `test_demoFixturesLoadIntoHierarchy`(@TestSetup과 겹치는 키는 갱신) | 통과 |

데모 데이터 재현: `load_salesforce.sh qms-dev-a --upto-phase 1` — 법인 4, 공장 5, 라인 9, 공정 28행 실패 0. 라인의 `ProductGroup__r.GroupCode__c` 열만 MDM-004 배포 전이라 빠졌다.

## 2. 구현 내역

- 객체·필드: `CMN_Company__c`(CompanyCode·Country·IsActive, OWD Public Read Only), `CMN_Plant__c`(PlantCode·Company 주종·Region·TimeZone·DefaultLanguage·MesSiteCode·IsActive, 필드 이력), `CMN_Line__c`(LineCode·Plant 주종·ExternalKey·MesLineCode·IsActive, 필드 이력), `CMN_Operation__c`(OpCode·Line 주종·Sequence·OperationType·ExternalKey·IsActive). 탭 4개(SL Admin 앱), 레이아웃 4개(하위 관련 목록 포함), 코드 변경 금지 검증 규칙 4개.
- Apex: `CMN_PlantService`(공장 시간대·현지 날짜, 외부 키·중복 검사, 삭제 금지, 공정 키 재계산), `CMN_PlantSelector`, 트리거 핸들러 4개 + 트리거 4개.
- 권한: `CMN_PS_Site_Read`(사내 페르소나 PSG 14개), `CMN_PS_Site_Admin`(Modify All + 탭, QualityAdmin·SystemAdmin). 라벨 4개(ko·en_US·zh_CN), 객체·필드·선택 목록 번역.
- 공통 도구 보강:
  - 생성기: 기본 레이아웃 생성(`{라벨} 레이아웃` 덮어쓰기), `trackHistory`는 이력 켠 객체만, `allObjectFields`(이관 PS가 정의된 모든 객체·필드를 자동으로 편집).
  - `CMN_PS_DataMigration`: 모든 객체·필드 편집(서비스 전용 포함)으로 확장. 데모 로더가 적재하는 동안만 관리자에게 할당하고 끝나면 해제한다(새 필드 FLS가 없어 외부 키·MES 코드 열이 빠지던 문제 해결).
  - `CMN_TestDataFactory`: 이미 있는 레코드(@TestSetup)는 외부 키로 찾아 갱신, 주종 필드는 갱신하지 않음.
- 핵심 설계 판단:
  1. **코드는 만든 뒤 바꾸지 않는다**: 공장 코드는 공장 그룹(SEC-002)·채번 키, 라인·공정 코드는 외부 키의 일부라 바꾸면 외부 참조가 끊긴다. 검증 규칙으로 막고 이관 모드만 허용하며, 그때 라인 키가 바뀌면 공정 키를 다시 만든다.
  2. **삭제 금지는 4단계 모두**: 주종 관계라 법인을 지우면 공장·라인·공정이 연쇄 삭제되고 하위 트리거가 돌지 않으므로 상위까지 막는다.
  3. **외부 키 필수는 트리거로 보장**: 명세는 필수(Y)지만 사용자가 입력하지 않는 값이라 DB 필수 대신 트리거가 채우고 FLS는 읽기 전용(서비스 전용)으로 했다.
  4. **공장 조회는 시스템 모드 + 트랜잭션 캐시**: 기준정보는 사내 전체 공개라 노출 범위가 같고, 채번처럼 어느 사용자 문맥에서도 호출된다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_PlantService 95.6%, CMN_PlantSelector 100%, 핸들러·트리거 100%. 기존 클래스 유지(CMN_TriggerHandler 93.3%) |
| Apex 테스트 | 44건 통과(MDM-002 12건 포함) |
| Jest | 해당 없음 |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier | 통과 |
| 200건 벌크 한도 | 라인 200·공정 200 저장 시 트리거 SOQL 각 2회 이하 |

## 4. 보안·성능 점검

- [x] 조회는 Selector에 모으고 시스템 모드 사유를 ApexDoc에 남김. `without sharing` 없음
- [x] 오류 문구는 Custom Label(라인·공정 중복, 삭제 금지, 없는 공장)
- [x] 루프 안 SOQL·DML 없음(공장 조회 트랜잭션 1회, 중복 검사 1회)
- [x] 비밀값·하드코딩 Id 없음
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | `IsActive__c`(4개 객체)와 코드 변경 금지 검증 규칙 추가 | BR-2 "비활성화만 가능"을 위한 필드. Vol.0 MDM-002 데이터 모델 갱신 요청 |
| 명세 차이 | `CMN_Operation__c.ExternalKey__c`(Text(60), `{PlantCode}-{LineCode}-{OpCode}`) 추가 | 데모 보강 CR-6 |
| 명세 차이 | `CMN_Company__c.CompanyCode__c`에 Unique 추가 | 외부 키 upsert가 한 건으로 정해지도록 |
| 명세 차이 | Country는 ISO 3166 전체 대신 사업장·고객 국가 20개, TimeZone은 사업장 후보 20개 | 값 추가는 정의 JSON에 넣고 다시 생성 |
| 명세 차이 | `CMN_Line__c.ProductGroup__c` 미생성 | 명세대로 MDM-004가 추가 |
| 후속 | 공장 생성 시 공장 그룹 자동 생성 | SEC-002가 `CMN_PlantTriggerHandler`에 추가 |
| 후속 | 채번 연도의 공장 시간대 적용 | ARC-003이 `CMN_PlantService.localDate` 사용 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS), 관리자에게 `CMN_PSG_SystemAdmin` 할당(build-scratch 4단계와 같음)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-MDM-002] 법인·공장·라인·공정 계층과 공장 시간대 서비스`
