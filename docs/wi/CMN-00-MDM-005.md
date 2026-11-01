# CMN-00-MDM-005 완료 보고 — 협력사·협력사 품번

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-MDM-005 (vol0-cmn-common.md CMN-00-MDM-005) |
| Wave / 공수(계획 → 실제) | W0 / 2 M/D → 약 0.7 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack MDM-005 변경 요청 2건(상태 필드 서비스 전용·이력) 반영 |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 같은 협력사·품번·공장 두 번째 생성 → 중복 오류 | `CMN_SupplierService_Test.test_AC01_sameSupplierItemPlantRejected`(라벨 문구, 키 V10001-P-LENS-KR01) | 통과 |
| BR-1 검사 수준 이력, 상태는 서비스만 | `test_BR1_statusFieldsServiceOnlyForUsers`(관리 PS에서도 PpapStatus·InspectionLevel·SupplierGrade 읽기 전용), `test_updateAndDeleteRules` | 통과 |
| BR-2 협력사 하위 Contact만 포털 사용자 | QMS-03-SPP 범위(이 WI는 PortalEnabled__c 필드만) | 해당 없음 |
| 기본값·키, 고객 배제·필수 키, 삭제, 벌크, 데모 | `test_defaultsAndKey`, `test_negative_customerCannotBeSupplierAndKeyRequired`, `test_updateAndDeleteRules`(협력사 품번·협력사 계정 삭제 거부), `test_bulk200SupplierItems`(SOQL 4회 이하), `test_demoFixturesLoadSuppliers` | 통과 |

데모 데이터 재현(qms-dev-a, `--upto-phase 1`): 협력사 8행, 협력사 품번 21행 실패 0(서비스 전용 상태 필드는 이관 PS로 적재).

## 2. 구현 내역

- 객체·필드: Account 협력사 필드(SapVendorNo·SupplierGrade(서비스 전용, 이력)·IatfCertified·IatfExpiry·PortalEnabled), 검증 규칙 2개(번호 필수·번호 변경 금지), Account 필드 이력 사용. `CMN_SupplierItem__c`(협력사 주종·품번·납품 공장·ExternalKey·PpapStatus(기본 NOT_SUBMITTED)·InspectionLevel(기본 NORMAL), 두 상태 서비스 전용·이력, 상태 필수 검증 규칙, 탭).
- Apex: `CMN_SupplierService`(외부 키·중복), `CMN_SupplierSelector`, `CMN_SupplierItemTriggerHandler` + 트리거, `CMN_AccountTriggerHandler` + `CMN_AccountTrigger`(고객·협력사 계정 삭제 금지).
- 권한: `CMN_PS_Supplier_Read`(사내 PSG 14개), `CMN_PS_Supplier_Admin`(Account Modify All·협력사 레코드타입·협력사 품번 Modify All·탭, QualityAdmin·SystemAdmin). `CMN_PS_Customer_Admin`도 Account Modify All로 맞춤. 라벨 1개.
- 공통 도구 보강: 생성기가 표준 객체 설정(`objectSettings`, 예: Account 이력 사용)을 쓰고, 이관 PS에 표준 객체 권한(User 제외)을 넣음(하위 객체 권한이 Account에 종속).
- 핵심 설계 판단:
  1. **서비스 전용 상태는 DB 필수가 아니다**: 필수 필드는 FLS 읽기 전용이 될 수 없어(항상 편집 가능), PpapStatus·InspectionLevel은 기본값 + "비어 있으면 안 됨" 검증 규칙으로 명세 필수(Y)를 지키고 FLS는 읽기 전용으로 했다. QMS-03 서비스는 시스템 모드로 바꾼다.
  2. **고객·협력사 Account 삭제 금지**: 협력사 품번이 협력사의 주종 하위라 계정을 지우면 트리거 없이 연쇄 삭제된다. Account Modify All을 준 관리자도 지울 수 없게 트리거로 막는다(다른 레코드타입은 표준 동작).
  3. **Account Modify All**: 지금 Account 공유 모델은 Public Read/Write이지만 SEC-002가 기준정보를 Public Read Only로 바꾸면 하위(협력사 품번) 편집에 Account 편집 권한이 필요해 관리 PS에 Modify All을 줬다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_SupplierService·CMN_SupplierSelector·CMN_SupplierItemTriggerHandler·CMN_AccountTriggerHandler 100% |
| Apex 테스트 | 83건 통과(MDM-005 7건 포함) |
| Jest | 해당 없음 |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier | 통과 |
| 200건 벌크 한도 | 협력사 품번 200건 저장 시 트리거 SOQL 4회 이하 |

## 4. 보안·성능 점검

- [x] 상태 필드는 모든 PS에서 읽기 전용(테스트로 고정), 이관 PS만 편집
- [x] 조회는 Selector, 시스템 모드 사유 명시. `without sharing` 없음
- [x] 오류 문구는 Custom Label·검증 규칙 번역
- [x] 루프 안 SOQL·DML 없음
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이(CR 반영) | PpapStatus·InspectionLevel·SupplierGrade 서비스 전용(FLS 읽기)·필드 이력 | review-pack 변경 요청(Vol.3·Vol.6c) |
| 명세 차이 | PpapStatus·InspectionLevel 필수를 기본값 + 검증 규칙으로 | 필수 필드는 읽기 전용 FLS 불가 |
| 명세 차이 | SapVendorNo 변경 금지, 고객·협력사 Account 삭제 금지, Account 필드 이력 사용 | 외부 키·주종 하위 보호 |
| 후속(CR) | 운영 시작 시 현행 승인 부품 APPROVED 이관 | 데이터 이관 계획(이관 PS가 서비스 전용 필드 편집 가능) |
| 후속 | 포털 사용자 활성화(협력사 하위 Contact만), 포털 PSG 권한 | QMS-03-SPP |
| 후속 | 협력사 공유(포털 격리) | CMN-00-SEC-002 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-MDM-005] 협력사 필드·협력사 품번과 기준정보 계정 삭제 금지`
