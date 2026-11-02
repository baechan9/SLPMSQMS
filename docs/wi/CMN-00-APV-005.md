# CMN-00-APV-005 완료 보고 — 결재 지연 알림·에스컬레이션

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-APV-005 (vol0-cmn-common.md CMN-00-APV-005) |
| Wave / 공수(계획 → 실제) | W2 / 2 M/D → 약 0.3 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의) |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 ReminderDays 2, PENDING 2일째, 공장 09:00 잡 → 독촉 1건, 같은 날 재실행 시 추가 없음 | `CMN_ApprovalReminderJob_Test.test_AC01_reminderOncePerDay`(KR01 현지 09:00 = 00:00 GMT, 결재자 1명, Days 2, LastReminderOn 기록, 30분 뒤 재실행 0건) | 통과 |
| BR-2 에스컬레이션 | `test_BR2_escalationToManagerAndNotBeforeDays`(5일째 → 결재자 독촉 + 부서장 에스컬레이션) | 통과 |
| BR-1 현지 시각·일수 | `test_BR1_onlyAtLocalReminderHourAndAfterDays`(1일째 미발송, 현지 10시 미처리, 스케줄 진입점) | 통과 |

## 2. 구현 내역

- `CMN_ApprovalStep__c`에 `PendingAt__c`(PENDING이 된 시각, 엔진 openNextGroup이 기록), `LastReminderOn__c`·`LastEscalationOn__c`(공장 현지 날짜, 하루 1회) 추가.
- `CMN_ApprovalReminderJob`(Schedulable, 매시 정각): 공장 현지 시각이 `CMN_APV_REMINDER_HOUR`(9)인 공장만, 체류일수 = 대기 시작 현지 날짜 → 오늘. ReminderDays(기본 2) 이상 → 결재자 + 유효 대리인(APV-004)에게 `APV_REMINDER`, EscalationDays(기본 5) 이상 → 결재자 부서장에게 `APV_ESCALATION`. `CMN_ApprovalReminderSelector`(without sharing, 사유 주석).
- NTF 규칙 2개 + 라벨 4개, CMN 설정 `CMN_APV_REMINDER_HOUR`(9)·`CMN_DEFAULT_TIMEZONE`(Asia/Seoul, 공장 없는 결재).
- 예약 스크립트 `scripts/apex/schedule-jobs.apex`(이미 예약된 이름은 건너뜀), `build-scratch.sh` 6단계에서 실행. qms-dev-a 예약 완료.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지 | CMN_ApprovalReminderJob 97%, Selector 100% |
| Apex 테스트 | APV-005 3건 + 결재·위임 회귀 22건 통과 |
| Code Analyzer(심각도 1~2) | 0건 |

## 4. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | 단계 필드 3개 추가(PendingAt·LastReminderOn·LastEscalationOn) — 체류일수·하루 1회 판정 근거 | 명세 데이터 모델 보완 요청 |
| 명세 차이 | 체류일수는 달력 일수(공장 현지 날짜) | 오픈 이슈(영업일·공장 휴일 캘린더) 결정 후 변경 |
| 신규 설정 | `CMN_APV_REMINDER_HOUR`, `CMN_DEFAULT_TIMEZONE` | — |
| 오픈 이슈 | 그룹웨어 전자결재 연계(EXTERNAL 단계), 영업일 기준 | 명세 오픈 이슈 유지 |

## 5. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS), 잡 예약 완료
- dry-run → 배포: 성공
- 커밋: `[CMN-00-APV-005] 결재 지연 독촉·에스컬레이션 스케줄 잡`
