# CMN-00-ARC-002 완료 보고 — Apex 공통 프레임워크(트리거·로그·예외·기능 스위치)

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-ARC-002 (vol0-cmn-common.md#5 CMN-00-ARC-002) |
| Wave / 공수(계획 → 실제) | W0 / 5 M/D → 약 1.5 M/D(메타데이터 생성기·점검 스크립트 포함) |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의) |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 200건 일괄 → SOQL 1·DML 1 이하 | `CMN_TriggerHandler_Test.test_AC01_bulk200EventsSingleDml`(로그 이벤트 200건 → 구독 트리거가 CMN_TriggerHandler로 로그 200건, 핸들러 DML·SOQL 측정) | 통과 |
| AC-2 롤백 전 `CMN_Logger.error` → 로그 1건 남음 | `CMN_Logger_Test.test_AC02_logSurvivesRollback` | 통과 |
| AC-3 IsActive__c = false → 핸들러 미실행 | `CMN_TriggerHandler_Test.test_AC03_inactiveSettingSkipsHandler` | 통과 |
| AC-4 미등록 스위치 키 → false, 예외 없음 | `CMN_FeatureSwitch_Test.test_AC04_unknownKeyIsOff` | 통과 |
| BR-2 우회 권한·코드 우회 | `test_BR2_bypassPermissionSkipsHandler`, `test_BR2_codeBypassAndClear` | 통과 |
| BR-3 재진입 1회 처리 | `test_BR3_reentrySameContextRunsOnce` | 통과 |
| BR-4 최소 수준 미만 미발행 | `CMN_Logger_Test.test_BR4_belowMinLevelNotPublished`, `test_defaultMinLevelIsInfo` | 통과 |
| BR-5 수준별 보존 기간 삭제·02:00 예약 | `CMN_LogPurgeBatch_Test.test_BR5_deletesByLevelRetention`, `test_scheduleDailyAt0200` | 통과 |
| BR-6 필요 PS(직접·PSG) | `CMN_FeatureSwitch_Test.test_BR6_requiredPermissionSet`, `test_BR6_permissionSetThroughGroup` | 통과 |
| (음수) 트리거 밖 호출, 알 수 없는 수준, 길이 초과 | `test_negative_runOutsideTriggerThrows`, `test_negative_unknownLevelIgnored`, `test_longMessageAndPayloadTruncated` | 통과 |

데모 시나리오 재현: 해당 없음.

## 2. 구현 내역

- 객체·필드: `CMN_Log__c`(로그 번호 자동 번호, 수준·위치·메시지·관련 레코드·Payload·트랜잭션 ID, OWD Private, 탭), `CMN_LogEvent__e`(즉시 발행), `CMN_TriggerSetting__mdt`, `CMN_FeatureSwitch__mdt`, `CMN_LogSetting__c`(계층형).
- Apex: `CMN_TriggerHandler`(virtual), `CMN_Logger`, `CMN_LogEventTriggerHandler` + `CMN_LogEventTrigger`, `CMN_FeatureSwitch`, `CMN_Exception`, `CMN_ValidationException`, `CMN_LogPurgeBatch`(배치 + 예약), `CMN_TestDataFactory`(@IsTest).
- 권한(PS)·라벨·번역: `CMN_PS_Admin_Ops`(로그 View All·탭), `CMN_PS_DataMigration`(Custom Permission `CMN_DataMigration`). 공통 라벨 3개(`CMN_Common_UnexpectedError`, `CMN_Common_NoPermission`, `CMN_Common_InvalidInput`)와 로그 객체·필드·선택 목록 en_US·zh_CN 번역.
- 기타: 정적 리소스 `QMS_DemoFixtures`(데모 픽스처 복사본, `scripts/dev/sync-fixtures.sh`).
- 개발 도구: 메타데이터 생성기 `scripts/dev/metagen.py`(`docs/dev/metadata-generator.md`), 점검 스크립트 `scripts/dev/wi-check.sh`, 메타 파일 `ensure-meta.sh`, DEV-STATUS 갱신 `dev-status.py`. CI에 생성기·픽스처 최신 검사 추가.
- 핵심 설계 판단:
  1. **재진입 판단은 채워진 필드 맵으로**: Platform Event 레코드에는 Id 필드가 없어 `r.Id`를 읽으면 예외가 난다. 이 예외가 이벤트 구독 안에서 조용히 사라져 로그가 저장되지 않는 것을 테스트로 발견했다.
  2. **이관 모드(CR-12)**: Custom Permission `CMN_DataMigration`과 `CMN_TriggerHandler.isMigrationMode()`. 업무 핸들러는 이 값이 true면 기존 RecordNo·상태를 유지하고 To-Do·알림·이벤트를 생략한다. 테스트 데이터 공장은 적재하는 동안 이관 모드로 실행한다.
  3. **테스트 데이터 공장(CR-4)**: 픽스처 단계를 순서대로 적재하고, Org에 없는 객체·필드는 건너뛴다(페이즈가 진행돼도 같은 픽스처를 쓴다). 프로필은 라이선스로 찾는다(ko Org의 표준 프로필 이름이 한국어).
  4. **로그 수준 기본값 INFO**: 명세에 값이 없어 설정이 없으면 INFO로 했다.
  5. **긴 텍스트 필수 여부**: Message__c(명세 필수)는 DB 필수 대신 로거가 항상 채우는 것으로 보장했다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_TriggerHandler 88.9%, CMN_Logger 98.0%, CMN_FeatureSwitch 93.8%, CMN_LogEventTriggerHandler 100%, CMN_LogPurgeBatch 100%, CMN_LogEventTrigger 100% |
| Apex 테스트 | 24건 통과 |
| Jest | 해당 없음 |
| Code Analyzer(심각도 1~2) | 0건(`getDescribe` 지연 로딩으로 2건 해소). 심각도 3 이하: 테스트 메서드 이름 규칙(sf-dev 형식 `test_AC01_…`) 등 |
| ESLint / Prettier | 통과 |
| 200건 벌크 한도 | 로그 이벤트 200건: 핸들러 DML 1회 이하·SOQL 1회 이하 |

## 4. 보안·성능 점검

- [x] 시스템 모드 사용 부분(이벤트 구독 저장, 배치 조회·삭제, 권한 셋 조회)은 `AccessLevel.SYSTEM_MODE`/`WITH SYSTEM_MODE`로 드러냄. `without sharing` 없음
- [x] 로거는 메시지·Payload 길이를 잘라 저장, 개인정보는 호출 측 책임(ApexDoc에 명시)
- [x] 루프 안 SOQL·DML 없음. 기능 스위치의 권한 셋 조회는 트랜잭션당 1회
- [x] 비밀값·하드코딩 Id 없음
- [ ] `/code-review`·`/security-review`: 실행하지 않음(자체 점검으로 대신). 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | `CMN_TestDataFactory`·`QMS_DemoFixtures`와 이관 모드(`CMN_DataMigration`, `CMN_PS_DataMigration`)를 이 WI에 추가 | 개발 플랜 CR-4·CR-12, 권고안 채택. Vol.0 ARC-002 범위 추가 요청 |
| 명세 차이 | CMN_LogEvent__e 필드는 Picklist를 쓸 수 없어 Level__c를 Text(10)로 | 로거가 허용 값만 발행 |
| 명세 차이 | CMN_LogSetting__c.MinLevel__c는 Custom Setting이 Picklist를 지원하지 않아 Text(10) | 로거가 대소문자 무관으로 해석, 잘못된 값은 INFO |
| 이슈 | `CMN_LogPurgeBatch` 예약은 실행 사용자 시간대 기준 | KST 사용자로 예약(ApexDoc) |
| 후속 | DWH-002 BR-4(Snowflake 적재 확인 후 삭제)를 붙이면 정리 조건 변경 | CMN-00-DWH-002 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-ARC-002] Apex 공통 프레임워크·테스트 데이터 공장·메타데이터 생성기`
