# CMN-00-MDM-004 완료 보고 — 제품군·품번(Item)

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-MDM-004 (vol0-cmn-common.md CMN-00-MDM-004) |
| Wave / 공수(계획 → 실제) | W0 / 3 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack MDM-004 변경 요청 1건(UsagePerVehicle)과 데모 보강(ItemVehicle ExternalKey) 반영 |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 같은 ItemNo 재수신 upsert → 1건 유지, 바뀐 필드만 갱신 | `CMN_ItemService_Test.test_AC01_resyncSameItemNoKeepsOneRecord`(isCreated false, 도면 리비전·품명 갱신, 보내지 않은 고객 품번 유지) | 통과 |
| BR-1 FG면 고객 필수 | `test_BR1_finishedGoodNeedsCustomer`(FG 거부, PART 허용) | 통과 |
| BR-2 BOM은 Salesforce에 두지 않음 | 해당 객체 없음(설계 확인) | 해당 없음 |
| 공장별 품번·적용 차종 키·기본값·중복 | `test_itemPlantAndVehicleKeys`, `test_linkUpdatesKeepKeys` | 통과 |
| 제품군 2단계 | `test_productGroupTwoLevels`(3단계 생성·하위 있는 제품군 이동 거부) | 통과 |
| 삭제 규칙, 벌크, 데모 | `test_negative_deleteBlockedExceptItemVehicle`, `test_bulk200ItemsAndPlantLinks`(SOQL 3회 이하), `test_demoFixturesLoadItems` | 통과 |

데모 데이터 재현(qms-dev-a, `--upto-phase 1`): 제품군 3+2행, 품번 25행, 공장별 품번 38행, 적용 차종 21행 실패 0. 라인의 `ProductGroup__r.GroupCode__c` 열도 이제 들어간다.

## 2. 구현 내역

- 객체·필드: `CMN_ProductGroup__c`(GroupCode·Parent·IsActive), `CMN_Item__c`(ItemNo·ItemType·ProductGroup·Customer 조회 필터·CustomerPartNo·DrawingNo/Rev·PartCategory·IsActive, 필드 이력), `CMN_ItemPlant__c`(품번·공장 주종 연결, ExternalKey·Status), `CMN_ItemVehicle__c`(품번·차종 주종 연결, ExternalKey·UsagePerVehicle 기본 1), `CMN_Line__c.ProductGroup__c`(MDM-002 명세의 "MDM-004 배포 시 추가"). 검증 규칙 4개, 탭 2개(SL Admin), 레이아웃(연결 관련 목록 포함), 라벨 3개.
- Apex: `CMN_ItemService`(연결 외부 키·중복, 제품군 2단계), `CMN_ItemSelector`, 핸들러 4개 + 트리거 4개, 공통 `CMN_KeyGuard`(외부 키 중복 검사 — MDM-002 라인·공정, MDM-003 차종도 이것으로 정리).
- 권한: `CMN_PS_Item_Read`(사내 PSG 14개), `CMN_PS_Item_Admin`(QualityAdmin·SystemAdmin). 연결 객체가 공장·차종의 주종 하위라 두 PS에 법인·공장·차종 읽기를 함께 넣었다(권한 종속 배포 오류로 확인).
- 핵심 설계 판단:
  1. **연결 객체는 주종 2개(Junction)**: 공유는 품번·공장·차종(모두 사내 공개)을 따르고, 이름은 자동 번호(IP-/IV-), 업무 키는 트리거가 만드는 ExternalKey.
  2. **삭제 규칙**: 품번·제품군·공장별 품번은 삭제 금지(단종은 Status PHASE_OUT). 적용 차종은 잘못 연결하면 지울 수 있다(업무 레코드는 품번·차종을 직접 참조).
  3. **제품군 2단계는 검증 규칙 + 트리거**: 상위의 상위는 검증 규칙이, 하위가 있는 제품군에 상위를 다는 경우는 트리거가 막는다. 검증 규칙은 상위가 있을 때만 판정한다(상위·Id가 둘 다 빈 루트를 자기 참조로 오인하던 문제를 개발 Org에서 확인해 고침).
  4. **SpecialCharCount__c(롤업)**: 특성 객체가 생기는 MDM-006에서 만든다(명세대로).

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_ItemService·CMN_ItemSelector·핸들러 100%, CMN_KeyGuard 91% |
| Apex 테스트 | 75건 통과(MDM-004 9건 포함) |
| Jest | 해당 없음 |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier | 통과 |
| 200건 벌크 한도 | 공장별 품번 200건 저장 시 트리거 SOQL 3회 이하 |

## 4. 보안·성능 점검

- [x] 조회는 Selector, 키 검사 동적 SOQL은 describe 이름만 쓰고 값은 바인드(`queryWithBinds`, SYSTEM_MODE 사유 주석)
- [x] 오류 문구는 Custom Label·검증 규칙 번역
- [x] 루프 안 SOQL·DML 없음
- [x] BOM 미저장(BR-2)
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이(CR 반영) | `CMN_ItemVehicle__c.UsagePerVehicle__c`(Vol.5 B2B-003) | review-pack 변경 요청 |
| 명세 차이(데모 보강) | `CMN_ItemVehicle__c.ExternalKey__c`(`{ItemNo}-{OemCode}-{VehicleCode}`) | 개발 플랜 CR-6 |
| 명세 차이 | 제품군·품번 `IsActive__c`, 코드 변경 금지, 품번·제품군·공장별 품번 삭제 금지, 품번 고객 조회 필터(고객 레코드타입) | 기준정보 공통 규칙 |
| 명세 차이 | `CMN_ProductGroup__c.GroupCode__c` Unique | 외부 키 upsert 일관성 |
| 후속 | `CMN_Item__c.SpecialCharCount__c` 롤업 | CMN-00-MDM-006 |
| 후속 | BOM 조회(수평전개·영향 분석) | CMN-00-DWH-002 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-MDM-004] 제품군·품번과 공장·차종 연결, 외부 키 공통 검사`
