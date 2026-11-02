# CMN-00-INT-003 완료 보고 — SAP 기준정보 연계

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-INT-003 (vol0-cmn-common.md CMN-00-INT-003) |
| Wave / 공수(계획 → 실제) | W0 / 6 M/D → 약 0.3 M/D(Salesforce 측) |
| 완료일 | 2026-11-02(Salesforce 수신 계약) |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 중(Salesforce 측 완료, Mule SAP OData 추출·Snowflake RAW 적재는 외부 트랙) |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack 변경 요청 1건(Vol.9 단건 즉시 동기화 API — Mule prc, 외부 트랙) |

## 1. AC 결과

| AC | 확인 | 결과 |
| --- | --- | --- |
| AC-1 신규 공급업체-자재 정보레코드 → CMN_SupplierItem__c 1건(NORMAL, NOT_SUBMITTED) | `CMN_SapMasterInbound_Test.test_AC01_newInfoRecordCreatesSupplierItemWithDefaults`(SAP 통합 사용자 권한, 외부 키 참조(공급업체 SapVendorNo·자재 ItemNo·공장 PlantCode)로 upsert 2회 → 1건, 기본값) | 통과 |
| AC-2 자재 삭제 표시 → ItemPlant PHASE_OUT, 품번 유지 | `test_AC02_deletionFlagPhasesOutItemPlantAndKeepsItem`(PHASE_OUT upsert, 통합 사용자는 품번 삭제 불가, 품번 유지). 연계 시뮬 `scripts/sim/int003-sap-sim.sh`에서 데모 자재-플랜트 PHASE_OUT 후 되돌림 | 통과 |
| BR-1 멱등 | `test_BR1_masterUpsertIsIdempotent`(자재·공급업체 2회 upsert 건수 불변). 시뮬: 데모 자재-플랜트 CSV 2회 upsert 건수 불변 | 통과 |

시뮬 결과(qms-dev-a): 자재-플랜트 CSV 2회 upsert → 품번 25 / 자재-플랜트 38 / 공급업체-자재 21 그대로, `92101-HE1L-KR01` PHASE_OUT(품번 유지) 확인 후 ACTIVE로 되돌림.

## 2. 구현 내역

- PS `CMN_PS_Integration_Sap`(SAP 통합 사용자: 회사·공장·자재·자재-플랜트·공급업체-자재·Account 생성·수정, 고객·협력사 레코드타입, 자재-플랜트·공급업체-자재 외부 키 쓰기, 삭제 권한 없음). `CMN_PS_Integration`과 함께 준다.
- 생성기: PS `editableFields`(서비스 전용 필드 중 이 권한 셋에만 쓰기를 여는 필드) — 통합 사용자의 외부 키 upsert용.
- 수신 계약 테스트 `CMN_SapMasterInbound_Test`, 연계 시뮬 `scripts/sim/int003-sap-sim.sh <org>`.
- 매핑 대상(BR-4)은 MDM-002~005가 이미 만든 객체·외부 키를 그대로 쓴다.

| SAP | Salesforce | 외부 키 | 비고 |
| --- | --- | --- | --- |
| 회사 코드 | CMN_Company__c | CompanyCode__c | MDM-001 |
| 플랜트 | CMN_Plant__c | PlantCode__c | MDM-001 |
| 자재 | CMN_Item__c | ItemNo__c | MDM-003, 대상 자재 유형만(BR-3) |
| 자재-플랜트 | CMN_ItemPlant__c | ExternalKey__c(`{자재}-{공장}`) | 삭제 표시 → Status__c = PHASE_OUT(BR-5) |
| 고객 | Account(CMN_Customer) | SapCustomerNo__c | MDM-004 |
| 공급업체 | Account(CMN_Supplier) | SapVendorNo__c | MDM-005 |
| 구매정보레코드(공급업체-자재-플랜트) | CMN_SupplierItem__c | ExternalKey__c(`{공급업체}-{자재}-{공장}`) | 신규 = NORMAL·NOT_SUBMITTED(필드 기본값, 검사 수준·PPAP 상태는 서비스 전용이라 연계가 덮어쓰지 않음) |

- 핵심 설계 판단
  1. **새 Apex 없이 수신 계약 확인**: 매핑 객체·외부 키·기본값·삭제 방지가 MDM WI에 있으므로, 이 WI는 통합 사용자 권한(최소 권한)과 연계 경로(외부 키 참조 upsert, 멱등)를 테스트로 고정한다.
  2. **소유권**: 플랜트는 회사의, 자재-플랜트는 자재·플랜트의 주종 하위라 통합 사용자가 상위 레코드에 편집 권한이 있어야 한다. 운영에서는 SAP 통합 사용자가 회사·플랜트·자재를 적재해 소유한다. **이관(DATA WI) 때 기준정보 소유자를 SAP 통합 사용자로 지정**해야 이후 증분 동기화가 실패하지 않는다.
  3. **연계가 덮어쓰면 안 되는 필드**: 검사 수준·PPAP 상태는 사용자 FLS 읽기(서비스 전용)라 통합 사용자 USER_MODE upsert가 바꿀 수 없다 — SAP 재동기화가 품질 상태를 되돌리지 않는다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 테스트 | CMN_SapMasterInbound_Test 3건 통과 |
| Code Analyzer(심각도 1~2) | 0건 |

## 4. 보안 점검

- [x] 통합 사용자 최소 권한(삭제 없음, 품질 상태 필드 쓰기 없음)
- [x] 테스트·시뮬은 USER_MODE(통합 사용자 권한 그대로)

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 이관 주의 | 회사·플랜트·자재·자재-플랜트 소유자 = SAP 통합 사용자(주종 하위 편집 권한) | 데이터 이관 WI에 반영 요청 |
| Mule 측 | S/4HANA OData(Product, Business Partner) 우선·CDS View 보완, 변경일시 증분, 활성 플랜트·대상 자재 유형만 Salesforce, 전량은 Snowflake `RAW.SAP_*`, 실행 로그(INT-001 규약) | 외부 트랙 |
| CR(외부) | 자재·공급업체·정보레코드 단건 즉시 동기화 API(Mule prc, 검토 반영 Vol.9 INT-004 BR-4) | 외부 트랙 |
| 오픈 이슈 | 대상 자재 유형 코드, 기존 SAP System API 재사용 범위 | 사용자 확인 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-INT-003] SAP 기준정보 통합 사용자 권한·수신 계약 테스트·연계 시뮬`
