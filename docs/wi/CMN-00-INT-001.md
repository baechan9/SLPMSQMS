# CMN-00-INT-001 완료 보고 — 연계 아키텍처·인터페이스 표준

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-INT-001 (vol0-cmn-common.md CMN-00-INT-001) |
| Wave / 공수(계획 → 실제) | W0 / 6 M/D → 약 0.5 M/D(Salesforce 측) |
| 완료일 | 2026-11-02(Salesforce 수신 계약). Mule API 계층·재시도·DLQ는 외부 트랙 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 중(Salesforce 측 완료, Mule 재시도·DLQ 실연계는 외부 트랙) |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack 변경 요청 2건 반영(Vol.7 IF-SF-002 카탈로그, Vol.9 인터페이스 28건 등록·통합 사용자 3개·이벤트형 로그 1분 묶음 규칙 — 마지막 항목은 Mule 측 규칙으로 기록) |

## 1. AC 결과

| AC | 확인 | 결과 |
| --- | --- | --- |
| AC-1 같은 배치 2회 재실행 → 레코드 수 변화 없음 | `CMN_InterfaceLogService_Test.test_AC01_sameRunUpsertedTwiceKeepsOneLog`(통합 사용자 권한으로 외부 키 upsert 2회 → 1건). 연계 시뮬 `scripts/sim/int001-log-sim.sh qms-dev-a`: `sf data upsert bulk` 2회 → 2건 → 2건 | 통과 |
| AC-2 점검 시간 실패 → 재시도·DLQ → 복구 후 재처리, 로그 2건(FAILED, SUCCESS) | Salesforce 측: `test_AC02_failedThenRecoveredLeavesTwoLogsAndAlertsAdmins`(로그 2건, FAILED만 시스템 관리자 알림, 같은 실행 재전송은 알림 반복 없음, SUCCESS → FAILED 전환은 알림). 시뮬에서 FAILED마다 알림 Queueable 완료(오류 0). 재시도 3회·Anypoint MQ DLQ는 Mule(외부 트랙) | Salesforce 측 통과, Mule 측 대기 |
| AC-3 모니터링 리스트뷰에서 최근 24시간 FAILED를 공장·인터페이스별 조회 | `test_AC03_monitoringListViewShowsRecentFailures`(리스트뷰 조건으로 최근 실패만, 공장 포함, 리스트뷰 배포 확인). 리스트뷰 `CMN_FailedLast24h`(인터페이스·공장·결과·건수·시각·상관 ID 열), `CMN_Last24h` | 통과 |
| 카탈로그·검증·벌크 | `test_BR4_catalogAndValidation`(34건 이상, 패턴 값, 종료 < 시작 거절, 미등록 인터페이스 저장 + WARN), `test_bulk200LogsAndNoAdmin`(200건 SOQL 2회 이하, 관리자 없으면 경고만) | 통과 |

## 2. 구현 내역

- 메타데이터
  - `CMN_Interface__mdt`(InterfaceId·Source·Target·Pattern·Schedule·OwnerTeam·OwnerWi·Description·IsActive) + 카탈로그 34건: Vol.0 기본 10건, Vol.7 요청 IF-SF-002, Vol.9 3절 28건(겹치는 SAP-002·SAP-003·MES-001·FC-001·GAU-001은 하나로). DeveloperName = InterfaceId의 `-`를 `_`로.
  - `CMN_InterfaceLog__c`(명세 필드 + Plant(AC-3 공장별), ExternalKey(`{InterfaceId}:{CorrelationId}`), IsRecent 수식(최근 24시간)), OWD Private, 리스트뷰 2개, 탭(SL Admin 앱).
  - PS `CMN_PS_Integration`(통합 사용자 공통: 연계 로그 생성·수정, 회사·공장 읽기), `CMN_PS_InterfaceLog_Read`(모든 로그 조회·탭, CMN_PSG_SystemAdmin).
  - NTF 규칙 `CMN_INTERFACE_FAILED`(메일·벨) + 라벨 2개.
- Apex: `CMN_InterfaceLogService`(prepare: 이름·외부 키·요약 길이·시간 순서·카탈로그 확인, alertFailures: 새로 FAILED가 된 로그를 관리자 PSG 사용자에게 Queueable 1개로 알림), `CMN_InterfaceLogTriggerHandler` + 트리거.
- 연계 시뮬: `scripts/sim/int001-log-sim.sh <org>`(개발 플랜 7.3).
- 생성기: 객체 `listViews` 지원(docs/dev/metadata-generator.md 반영).
- 핵심 설계 판단
  1. **로그 1건 = 실행 1회, 외부 키로 멱등**: Mule이 같은 실행을 재전송하면 갱신된다. 상관 ID가 다르면(재처리 실행) 새 로그 → AC-2의 FAILED·SUCCESS 2건.
  2. **카탈로그 밖 인터페이스도 저장**: 로그를 거절하면 장애 흔적이 사라지므로 저장하고 WARN을 남긴다(카탈로그 등록은 담당 WI 책임).
  3. **알림은 상태 전환 시 1회**: 같은 실행의 FAILED 재전송은 다시 알리지 않는다(알림 폭주 방지).
  4. **"최근 24시간"은 수식 필드**: 리스트뷰 날짜 조건은 일 단위라 `StartedAt__c >= NOW() - 1` 수식(IsRecent)으로 거른다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_InterfaceLogService 94%, 핸들러·트리거 100% |
| Apex 테스트 | INT-001 5건 통과(동기 실행: 일일 비동기 테스트 한도) |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier / 한글 리터럴 | 통과 / 통과 / 0건 |

## 4. 보안·성능 점검

- [x] 모든 클래스 with sharing, 관리자 PSG 조회는 SYSTEM_MODE(알림 대상 계산만)
- [x] 통합 사용자는 USER_MODE로 쓰는 최소 권한(로그 생성·수정, 회사·공장 읽기)
- [x] 로그 요약은 32,768자에서 자름, 알림 본문에는 인터페이스·건수·상관 ID만(레코드 원문 없음)
- [x] 200건 일괄 SOQL 2회 이하, 알림 Queueable 1개
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | 추가 필드 `Plant__c`(AC-3 공장별 조회), `ExternalKey__c`(재전송 멱등), `IsRecent__c`(리스트뷰 24시간 조건). 카탈로그 추가 필드 `OwnerWi__c`·`Description__c` | 명세 보완 요청 |
| CR 반영 | Vol.7 IF-SF-002, Vol.9 28건, 통합 사용자 3개(근거 문서 S-10, `CMN_PS_Integration` 공통) | — |
| Mule 측 규칙 | API 계층(sys·prc·exp), 200건 이하 Composite·초과 Bulk 2.0, 지수 백오프 3회 → Anypoint MQ DLQ, 이벤트형 인터페이스는 1분 묶음으로 로그 1건 | 외부 트랙(Mule) 구현 시 확인. 연계 로그 수신 계약: 외부 키 `{InterfaceId}:{CorrelationId}`로 upsert |
| 미확인 | AC-2 실연계(Mule 재시도·DLQ·재처리) | 외부 트랙 준비 후 qms-int에서 확인 |
| 후속 | 통합 사용자 3개 생성(Salesforce Integration User 라이선스) | INT-002·INT-003·Vol.9 착수 시 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공(소스 추적 초기화 후 dry-run 변경 없음)
- 커밋: `[CMN-00-INT-001] 인터페이스 카탈로그·연계 로그·실패 알림`
