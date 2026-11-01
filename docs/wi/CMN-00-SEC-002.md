# CMN-00-SEC-002 완료 보고 — 공장·협력사 데이터 격리(공유 모델)

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-SEC-002 (vol0-cmn-common.md CMN-00-SEC-002) |
| Wave / 공수(계획 → 실제) | W0 / 6 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료(AC-3은 P4) |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), 결정 D-9는 권고안(업무 객체 공장 격리 — 설정으로 흡수), review-pack SEC-002 변경 요청 3건 중 Vol.3(협력사 그룹·외부 OWD·품번 공유) 반영, Vol.4·5(지식 객체)는 해당 WI에서 |

## 1. AC 결과

검증 대상은 NCR 대신 테스트 대상 객체 `CMN_TestRecord__c`(공유 설정: Plant__c·Supplier__c, 사유 CMN_Plant·CMN_Supplier)다(CR-11·DEV-3).

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 KR01 읽기 사용자 → CN01 레코드 안 보임 | `CMN_SharingService_Test.test_AC01_kr01ReaderCannotSeeCn01Records`(runAs 조회 — 목록·검색·리포트는 같은 공유를 따름) | 통과 |
| AC-2 공장 KR01 → KR02 변경 → 이전 공유 삭제, 새 공유 생성 | `test_AC02_plantChangeMovesShares`(KR01 → CN01, 읽기·편집 그룹) | 통과 |
| AC-3 협력사 A 포털 사용자 → B 관련 레코드 권한 없음 | 포털 사용자가 생기는 P4(QMS-03-SPP)에서 확인. 지금은 포털 역할이 없으면 협력사 공유를 만들지 않는 것만 `test_BR4_supplierWithoutPortalRoleGetsNoShare`로 확인 | P4 |
| AC-4 10,000건 재계산 배치 거버너 오류 없음(배치 200) | `test_BR6_recalcBatchRestoresShares`(200건 지운 공유 400행 복원). 10,000건 실측은 게이트 G2-4 | 통과(규모는 게이트) |
| BR-2 공장 접근 → 그룹 구성원(비동기) | `test_BR2_accessChangesUpdateGroupMembership`(읽기 → 편집 → 삭제) | 통과 |
| 공장 그룹 자동 생성, 벌크, 설정 끔, 입력 검증 | `test_newPlantGetsGroupsAsync`, `test_bulk200AndInactiveConfig`, `test_negative_accessNeedsUserAndNoDuplicates` | 통과 |

개발 Org: 데모 공장 5곳 그룹 10개 생성, `--upto-phase 2` 적재로 공장 접근 4건 → KR01 편집 그룹 구성원 4명.

## 2. 구현 내역

- 객체·메타데이터: `CMN_UserPlantAccess__c`(User·Plant·AccessLevel·ExternalKey, Private, 이력, 탭), `CMN_SharingConfig__mdt`(ObjectApiName·PlantField·SupplierField·IsActive) + 테스트 대상 레코드, 테스트 대상 객체 Supplier__c·공유 사유 2개, `CMN_Item__c` 공유 사유 CMN_Supplier, 외부 공유 모델(품번·차종·제품군·부서 Private — 검토 반영 Vol.3). 생성기에 Apex 공유 사유 지원.
- Apex: `CMN_SharingService`(설정 기반 공유 계산·적용, 품번 협력사 공유), `CMN_ShareWriter`(공유 행 쓰기 — without sharing, 사유 주석), `CMN_PlantGroupService`·`CMN_PlantGroupJob`(공장 그룹 생성·구성원 맞춤), `CMN_SharingRecalcBatch`(BR-6), `CMN_UserPlantAccessTriggerHandler` + 트리거. `CMN_TriggerHandler`가 after insert/update에서 공유를 항상 계산, 공장 트리거가 그룹 생성 작업을, 협력사 품번 트리거가 품번 공유를 부른다. `CMN_PlantService.plantCodes`(채번·공유가 공장 캐시를 함께 씀).
- 권한·도구: `CMN_PS_PlantAccess_Admin`(SystemAdmin), 라벨 2개. `scripts/org/recalc-sharing.apex` + build-scratch 6단계(적재 뒤 재계산).
- 업무 객체 WI가 할 일: OWD Private, 공유 사유 `CMN_Plant`(+ 협력사 공개면 `CMN_Supplier`), `CMN_SharingConfig__mdt` 레코드 1건. 코드는 필요 없다.
- 핵심 설계 판단:
  1. **프레임워크에서 공유**: 업무 객체 핸들러가 공유를 빠뜨리지 않게 기반 클래스가 설정만 보고 공유를 맞춘다(삭제 통제와 같은 방식, 핸들러 비활성·우회와 무관).
  2. **그룹은 비동기**: 그룹·구성원은 설정 객체라 업무 레코드와 같은 트랜잭션에서 쓸 수 없다(Mixed DML). 공장 생성·공장 접근 변경 때 Queueable을 넣고, 놓친 경우는 재계산 배치가 맞춘다.
  3. **공유 행 쓰기만 without sharing**: 일반 사용자가 레코드를 저장할 때 Apex 공유 사유로 공유 행을 만들면 with sharing 문맥에서 "invalid row cause"로 거부된다(이관 사용자 테스트로 발견). 계산·조회는 with sharing 서비스가 하고 행 쓰기만 분리했다.
  4. **편집 수준은 편집 그룹만**: 읽기·편집 그룹을 따로 두고 사용자는 한쪽에만 둔다.
  5. **협력사 그룹**: 협력사 Account 포털 Manager 역할·하위 그룹(검토 반영). 포털 사용자가 있어야 역할이 생기므로 없으면 건너뛴다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_SharingService 86.3%, CMN_PlantGroupService 86.2%, CMN_SharingRecalcBatch 93.9%, 핸들러 95.8%, Job·Writer 100% |
| Apex 테스트 | 138건 통과(SEC-002 8건 포함). 채번·협력사 품번 벌크 테스트의 SOQL 상한을 공유 조회만큼 조정(채번 3 + 공유 2) |
| Jest | 13건 유지 |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier / 한글 리터럴 | 통과 / 통과 / 0건 |

## 4. 보안·성능 점검

- [x] `without sharing`은 `CMN_ShareWriter` 하나, 사유 주석(SHARING-EXCEPTION), 행 삽입·삭제만
- [x] 공유 대상·필드는 설정으로만 결정(객체별 하드코딩 없음)
- [x] 루프 안 SOQL·DML 없음(묶음당 그룹·기존 공유 조회 각 1회)
- [x] 본사·경영진 전 공장 조회는 공유 행이 아니라 PSG View All(BR-5)
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | `CMN_UserPlantAccess__c.User__c`를 DB 필수 대신 트리거로 확인 | User 조회는 필수(삭제 제한)로 만들 수 없다 |
| 명세 차이 | 공유 계산을 트리거 프레임워크에 통합, 공유 행 쓰기 `without sharing` 분리 | 위 설계 판단 1·3 |
| CR 반영(Vol.3) | 협력사 공유 대상 = 포털 Manager 역할·하위 그룹, 외부 OWD(품번 등 Private, 공장·코드 그룹·코드 Public Read Only), 협력사 품번 기준 품번 공유 | 포털 확인은 P4 |
| CR 대기(Vol.4·5) | 지식 객체 OWD Public Read Only·SharingConfig 제외, CLOSED 8D 전사 읽기 | 해당 객체 WI(P5·P7)에서 — 설정으로 처리 |
| 이슈 | 공장 생성 직후 적재된 레코드는 그룹 생성 전이면 공유가 빠질 수 있다 | 재계산 배치(빌드 스크립트 6단계에 포함) |
| 후속 | 10,000건 재계산 실측(AC-4·G2-4) | P2 게이트 |
| 후속 | AC-3 포털 격리 | QMS-03-SPP(P4) |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-SEC-002] 설정 기반 공장·협력사 공유와 공장 그룹`
