# CMN-00-MDM-003 완료 보고 — 고객·차종

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-MDM-003 (vol0-cmn-common.md CMN-00-MDM-003) |
| Wave / 공수(계획 → 실제) | W0 / 2 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack MDM-003 변경 요청 2건(RootCauseDueDays, ChangeNoticeLeadDays·ConcessionCustomerApproval) 반영 |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 협력사 Account를 차종 고객으로 선택 → 검색 결과에 없음 | `CMN_CustomerService_Test.test_AC01_nonCustomerAccountNotSelectable`(협력사 레코드타입 계정 저장 시 조회 필터 오류 FIELD_FILTER_VALIDATION_EXCEPTION. 조회 필터는 검색 결과와 저장 모두에 적용) | 통과 |
| BR-1 고객 레코드타입 분리, 고객 필수 키 | `test_BR1_customerNeedsCodeAndGroup` | 통과 |
| BR-2 기한이 비면 전사 기본값 | `test_BR2_blankDueDaysUseSettingDefaults`(D3 1·8D 설정값·원인 10, 고객 값 우선, PPAP 기본 레벨 3), `CMN_Settings_Test` 2건 | 통과 |
| 차종 외부 키·중복, 날짜·삭제, 벌크 | `test_vehicleKeyAndDuplicate`, `test_negative_eopBeforeSopAndDeleteBlocked`, `test_bulk200Vehicles`(SOQL 2회 이하) | 통과 |
| 데모 픽스처 | `test_demoFixturesLoadCustomersAndVehicles` | 통과 |

데모 데이터 재현(qms-dev-a, `--upto-phase 1`): 고객 6행·차종 9행 실패 0. 협력사(09)는 MDM-005 필드 배포 전이라 건너뜀.

## 2. 구현 내역

- 객체·필드: Account 레코드타입 `CMN_Customer`(PPAP 기본 레벨 3), 고객 CSR 필드 11개(OemCode·CustomerGroup·SapCustomerNo·Containment/EightD/RootCause DueDays·PpapDefaultLevel·AuditStandard·ClaimFormTemplate·ChangeNoticeLeadDays·ConcessionCustomerApproval), 검증 규칙 2개(고객 키 필수, 고객 코드 변경 금지). `CMN_Vehicle__c`(VehicleCode·Customer 조회 필터·ExternalKey·SOP/EOP·IsActive, OWD Public Read Only, 탭·레이아웃, 검증 규칙 2개).
- 전사 설정: `CMN_Setting__mdt`(Value·Note) + 기본값 3건(CMN_CSR_CONTAINMENT_DUE_DAYS 1, CMN_CSR_8D_DUE_DAYS 30, CMN_CSR_ROOT_CAUSE_DUE_DAYS 10), 읽기 클래스 `CMN_Settings`(문자열·정수·숫자·참거짓·쉼표 목록, 잘못된 값은 기본값 + 경고 로그).
- Apex: `CMN_CustomerService`(요구사항 DTO `requirements()` — 클레임·8D·4M·NCR·PPAP가 쓰는 기한·양식, 차종 외부 키·중복), `CMN_CustomerSelector`, `CMN_VehicleTriggerHandler` + 트리거.
- 권한: `CMN_PS_Customer_Read`(사내 PSG 14개), `CMN_PS_Customer_Admin`(Account 편집·고객 레코드타입·차종 Modify All·탭, QualityAdmin·SystemAdmin). SL Admin 앱에 계정·차종 탭. 라벨 1개.
- 공통 도구 보강: 생성기가 표준 객체 정의를 여러 파일로 나눠 둘 수 있게 합침(고객 MDM-003, 협력사 MDM-005), 레코드타입별 선택 목록 기본값, 이관 PS에 모든 레코드타입. 테스트 데이터 공장이 Org에 이미 있는 같은 사번 사용자(데모 사용자)를 그대로 쓰고 PSG 중복 할당을 건너뜀. 로그 테스트의 롤백 예시 레코드를 Account에서 부서로 바꿈(Account는 레코드타입·검증 규칙이 붙음).
- 핵심 설계 판단:
  1. **"CMN 설정" 저장소를 여기서 만든다**: BR-2와 여러 Vol.(IQC·PPAP·NCR·대시보드 등)이 "CMN 설정 키"를 쓰는데 소유 WI가 명세·interfaces.md에 없다. 키·값 Custom Metadata로 만들어 배포로 관리하고(감사 추적), 읽기 실패가 업무를 멈추지 않게 했다.
  2. **조회 필터는 레코드타입 이름(라벨)으로**: 조회 필터는 대상 레코드타입을 라벨 "고객"으로 비교한다. 레코드타입 라벨을 바꾸면 필터도 같이 바꿔야 한다(정의 JSON에 주석).
  3. **협력사 레코드타입을 먼저 생성**: 레코드타입이 하나라도 있는 Account는 마스터 레코드타입으로 저장할 수 없어, AC-1의 "협력사 Account"를 만들려면 협력사 레코드타입이 필요하다. 레코드타입만 MDM-005 정의 파일(`meta-src/cmn/Account-supplier.json`)로 먼저 만들었다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_CustomerService 98.3%, CMN_Settings 96.8%, CMN_CustomerSelector·CMN_VehicleTriggerHandler 100% |
| Apex 테스트 | 66건 통과(MDM-003 9건 포함) |
| Jest | 해당 없음 |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier | 통과 |
| 200건 벌크 한도 | 차종 200건 저장 시 트리거 SOQL 2회 이하 |

## 4. 보안·성능 점검

- [x] 조회는 Selector, 시스템 모드 사유 명시(사내 공개 기준정보). `without sharing` 없음
- [x] 오류 문구는 Custom Label·검증 규칙 번역
- [x] 설정 읽기는 Custom Metadata getInstance(SOQL 한도 미사용)
- [x] 비밀값·하드코딩 Id 없음
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | `CMN_Setting__mdt`·`CMN_Settings` 추가(“CMN 설정” 소유 WI 부재) | interfaces.md에 소유(MDM-003) 등록 요청. 다른 Vol.의 설정 키는 각 기능 WI가 레코드를 더한다 |
| 명세 차이(CR 반영) | Account `RootCauseDueDays__c`(Vol.5), `ChangeNoticeLeadDays__c`·`ConcessionCustomerApproval__c`(Vol.6a) | review-pack 변경 요청 |
| 명세 차이 | `OemCode__c` Unique, 고객 코드·차종 코드 변경 금지, `CMN_Vehicle__c.IsActive__c`·삭제 금지·EOP≥SOP 검증 | 외부 키 일관성과 기준정보 규칙 |
| 명세 차이 | 협력사 레코드타입 `CMN_Supplier`를 MDM-003에서 먼저 생성 | MDM-005가 필드·규칙을 더한다 |
| 이슈 | 레코드타입이 생겨 레코드타입 없이 만든 Account는 사용자 기본 레코드타입(관리자는 고객)이 된다 | 연계·코드는 레코드타입을 명시해 만든다. 사용자별 기본 레코드타입은 SL 프로필 정비(UX 또는 SEC 후속)에서 |
| 오픈 이슈 | ClaimFormTemplate 값·OEM별 실제 기한(CSR 문서) | 명세 오픈 이슈 유지 |
| 후속 | Account 레코드 페이지(고객·협력사 필드 배치) | 레이아웃·레코드 페이지 할당이 프로필 단위라 UX WI에서 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-MDM-003] 고객 CSR·차종과 전사 설정(CMN 설정) 저장소`
