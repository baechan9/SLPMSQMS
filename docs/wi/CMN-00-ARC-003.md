# CMN-00-ARC-003 완료 보고 — 업무 문서 번호 채번 서비스

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-ARC-003 (vol0-cmn-common.md CMN-00-ARC-003) |
| Wave / 공수(계획 → 실제) | W0 / 3 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack ARC-003 변경 요청 1건(공장 토큰 없는 전사 연번)과 데모 보강(RecordNo 선적재) 반영 |

## 1. AC 결과

검증 대상은 업무 객체(NCR) 대신 테스트 대상 객체 `CMN_TestRecord__c`(규칙 `TST-{PLANT}-{YYYY}-{SEQ:6}`)다(개발 플랜 CR-11·DEV-3).

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 KR01 200건 일괄 → 000001~000200 순서대로, 중복 없이 | `CMN_NumberingService_Test.test_AC01_bulk200InOrderWithoutGaps`(카운터 200, SOQL 4회 이하) | 통과 |
| AC-2 공장 시간 2027-12-31 23:59 → 000351, 2028-01-01 00:01 → 2028-000001 | `test_AC02_yearResetsAtPlantMidnight`, `test_AC02_usPlantUsesChicagoTime`(같은 순간 US01은 2027, KR01은 2028) | 통과 |
| AC-3 발행 번호 수정 → 차단, 다국어 문구 | `test_AC03_issuedNumberCannotChange`(검증 규칙, ko·en_US·zh_CN 번역) | 통과 |
| BR-4 미지원 토큰은 단위 테스트에서 실패 | `test_BR4_deployedPatternsAreValidAndBadTokensFail`(배포된 모든 규칙 검사 + 잘못된 패턴 5종) | 통과 |
| 검토 반영: 전사 연번(LL-·LA-) | `test_CR_companyWideSequenceWithoutPlant` | 통과 |
| 월 초기화·{YY}{MM}, 이관 모드 선적재, 공장·규칙 없음 | `test_monthlyResetAndShortYear`, `test_migrationKeepsNumberAndAdvancesCounter`, `test_negative_missingPlantOrRule` | 통과 |

데모 시나리오 G1-7(미국 공장 시간대 연도 경계 채번)은 위 AC-2 테스트로 재현한다.

## 2. 구현 내역

- 객체·메타데이터: `CMN_NumberingRule__mdt`(ObjectApiName·Pattern·ScopeField·ResetPolicy·NumberField) + 테스트 대상 규칙 1건, `CMN_NumberCounter__c`(Key 유일·대소문자 구분, LastValue, OWD Private, `CMN_PS_Admin_Ops` 조회), `CMN_TestRecord__c.RecordNo__c`(유일·외부 키·서비스 전용) + 변경 금지 검증 규칙(관리자 예외 없음).
- Apex: `CMN_NumberingService`(`assign`, `validatePattern`), `CMN_TestRecordTriggerHandler` + 트리거, `CMN_PlantService.plantCodeOf`. 라벨 3개.
- 업무 객체 WI가 할 일: 자기 객체에 `RecordNo__c`(Text 40, 유일·외부 키, 서비스 전용)와 같은 변경 금지 검증 규칙, `CMN_NumberingRule__mdt` 레코드 1건, 핸들러 beforeInsert에서 `CMN_NumberingService.assign(newRecords)`.
- 핵심 설계 판단:
  1. **카운터 키 = 객체/범위/기간**: 범위는 공장 코드(규칙 ScopeField가 공장 Lookup), 비우면 `*`(전사 연번). 기간은 YEARLY=YYYY, MONTHLY=YYYYMM, NEVER=`*`.
  2. **기간은 공장 시간대**: 공장 범위면 공장 TimeZone, 아니면 사용자 시간대로 연·월을 판정한다(CreatedDate 아님).
  3. **잠금과 동시 생성**: `FOR UPDATE`로 카운터를 잠그고 묶음 크기만큼 한 번에 올린다. 카운터가 없으면 만들되, 다른 트랜잭션이 먼저 만들어 유일 제약으로 실패하면 다시 잠가 읽는다.
  4. **이관 선적재**: 이관 모드에서 번호가 이미 있으면 유지하고, 같은 범위·기간 패턴이면 카운터를 그 번호까지 올려 이후 번호가 겹치지 않게 한다.
  5. **설정 오류는 예외**: 규칙이 없거나 패턴이 잘못되면 `CMN_Exception`(라벨 문구)으로 저장을 막는다. 공장이 빈 레코드는 그 레코드에만 오류를 단다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_NumberingService 96.8%, 핸들러·트리거 100% |
| Apex 테스트 | 117건 통과(ARC-003 10건 포함) |
| Jest | 해당 없음 |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier | 통과 |
| 200건 벌크 한도 | 200건 저장 시 SOQL 4회 이하, 카운터 DML 2회 이하 |

## 4. 보안·성능 점검

- [x] 카운터는 사용자 접근 없음(시스템 모드 갱신, 운영 조회만), 번호 필드는 서비스 전용
- [x] 번호 변경 금지는 관리자 예외 없음(명세 BR-3)
- [x] 루프 안 SOQL·DML 없음, 규칙은 Custom Metadata getAll(SOQL 미사용)
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이(CR 반영) | ScopeField 공란 = 전사 연번(키 범위 `*`) | review-pack Vol.4 LEL-001·005 |
| 명세 차이(데모 보강) | 이관 모드에서 기존 번호 유지 + 카운터 동기화 | 개발 플랜 CR-6·CR-12 |
| 명세 차이 | `NumberField__c`(기본 RecordNo__c) 추가, 패턴의 SEQ는 정확히 1개·자리수 1~99 | 번호 필드가 다른 객체 대비, 패턴 검사 규칙 명확화 |
| 명세 차이 | 테스트 대상 객체 `CMN_TestRecord__c`의 번호 필드·규칙 | DEV-3 |
| 오픈 이슈 | SL 현행 번호 체계(공장 코드 자릿수, 고객 8D 번호 병기) | 명세 오픈 이슈 유지 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-ARC-003] 공장·기간별 업무 문서 번호 채번 서비스`
