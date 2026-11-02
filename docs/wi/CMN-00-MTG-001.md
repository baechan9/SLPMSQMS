# CMN-00-MTG-001 완료 보고 — 회의 관리

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-MTG-001 (vol0-cmn-common.md CMN-00-MTG-001) |
| Wave / 공수(계획 → 실제) | W2 / 5 M/D → 약 1 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack Vol.6c 변경 요청(회의 유형 MANAGEMENT_REVIEW, 회의를 부모로 문서 등록) 반영 |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 조치 항목 3건(담당 3명), 회의록 확정 → 3명 To-Do 각 1건 | `CMN_MeetingService_Test.test_AC01_confirmOpensTodoPerActionOwner`(확정 전 To-Do 없음, 확정 후 담당자별 1건, 참석자 회의록 알림) | 통과 |
| AC-2 확정된 회의록 수정 → 차단 | `test_AC02_confirmedMinutesCannotChange` | 통과 |
| BR-1 공지 | `test_BR1_scheduledMeetingInvitesAttendees`(벨 알림, .ics 메일 4건(사내 3 + 외부 1), 참석자 읽기 공유 3건, ICS UID·DTSTART) | 통과 |
| BR-2 확정 경로 | `test_BR2_confirmOnlyByServiceAndOnlyFromHeld`(직접 확정 저장 거절, 예정 회의 확정 거절, 시간 역전) | 통과 |
| BR-3 조치 To-Do·기한 알림 | `test_BR3_actionItemTodoLifecycleAndDueAlerts`(회의 밖 조치 즉시 To-Do·담당자 공유, 담당자 변경 → 이전 취소·새 To-Do, 내일 기한 DUE·같은 날 재실행 없음·경과 OVERDUE, 담당자 필수) | 통과 |
| BR-4 정기 회의 | `test_BR4_regularMeetingCreatesNextOnce`(개최 → +7일 다음 회차·참석자 복사·연결, 1회만) | 통과 |
| 화면 | `test_controller_panelAddAndComplete`, `cmnMeetingPanel` Jest 5건 | 통과 |

## 2. 구현 내역

- 객체: `CMN_Meeting__c`(Category(MEETING_TYPE)·IsRegular·Recurrence·Start/End·Location·OnlineUrl·Related·Plant·Status·Minutes(Rich Text)·MinutesConfirmedAt·NextMeeting, Private + 공장·참석자 공유 사유, 이력, 탭), `CMN_MeetingAttendee__c`(주종, User 또는 ExternalEmail(유효성 규칙)·Role·Attendance), `CMN_ActionItem__c`(Meeting(선택)·Description·Owner·DueDate·Status·SourceRecordId·Plant·CompletedAt·LastDueAlertOn, Private + 공장·담당자 공유, 이력, 탭).
- 공유 설정(SEC-002) CMN_Meeting·CMN_ActionItem(Plant__c), NTF 규칙 4개(CMN_MEETING_SCHEDULED(벨)·CMN_MEETING_MINUTES·CMN_ACTION_DUE·CMN_ACTION_OVERDUE), 라벨 27개, PS `CMN_PS_Meeting_User`(사내 페르소나 PSG 전체).
- 데모 코드 시드: `MEETING_TYPE`(품질회의·수평전개·게이트 리뷰·고객 대응·경영검토) — 생성기 반영.
- Apex: `CMN_MeetingService`(검증·회의록 잠금·확정·공지·다음 회차·참석자 공유), `CMN_ActionItemService`(검증·To-Do 수명·담당자 공유), `CMN_MeetingInviteJob`(.ics 메일), `CMN_ActionItemReminderJob`(매일 기한 알림), `CMN_MeetingController`, `CMN_MeetingSelector`·`CMN_MeetingWriter`(without sharing, 사유 주석), 트리거 3개.
- LWC `cmnMeetingPanel`(회의 레코드 페이지: 확정 버튼, 조치 목록·추가·완료, 데스크톱·모바일).
- 스케줄: `schedule-jobs.apex`에 `CMN_ActionItemReminderJob`(매일 09:00) 추가, qms-dev-a 예약.
- 점검 도구: `scripts/ci/check-apex-shadowing.py`(상수와 대소문자만 다른 지역 이름 경고), wi-check에 변경 파일 대상 경고 단계.
- 핵심 설계 판단
  1. **조치 To-Do 시점**: 회의 조치는 회의록 확정 때(AC-1), 회의 밖 조치·확정 뒤 추가 조치는 저장 때(BR-3). 둘 다 같은 원천 키라 중복이 없다.
  2. **공지 채널**: 벨은 알림 서비스, 메일은 .ics 첨부가 필요해 별도 Queueable(같은 UID, 수정 시 SEQUENCE 증가 → 달력 앱이 갱신).
  3. **확정 경로 하나**: 확정 상태는 `confirmMinutes`로만(이관 모드 예외). 확정 후 회의록·상태 변경 불가, 정정은 코멘트(UX-003).
  4. **공유**: 회의는 공장 + 참석자 읽기, 조치 항목은 공장 + 담당자 편집.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지 | Service 95%, ActionItemService 96%, InviteJob 91%, Controller 86%, Selector·Writer·핸들러 100% |
| Apex 테스트 | MTG-001 7건 + To-Do 회귀 통과 |
| LWC Jest | 40건 통과(MTG-001 5건 포함) |
| Code Analyzer(심각도 1~2) | 0건 |

## 4. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | 추가 필드: Recurrence(반복 규칙), MinutesConfirmedAt, NextMeeting(중복 생성 방지), ActionItem Plant·CompletedAt·LastDueAlertOn | 명세 데이터 모델 보완 요청 |
| 명세 차이 | 조치 To-Do 시점(회의 조치는 확정 때) — AC-1과 BR-3 문구를 함께 만족하도록 해석 | 사용자 확인 |
| 명세 차이 | 기한 알림은 예약 사용자 시간대 09:00 하루 1회(공장별 시간대 아님) | 운영 시 공장별로 바꿀지 결정 |
| CR 반영 | MANAGEMENT_REVIEW 회의 유형, 회의를 부모로 문서 등록(DOC-001 패널을 회의 레코드 페이지에 배치 가능, 부모 편집 권한 기준) | P9 CER-002에서 사용 |
| 후속 | 회의 레코드 페이지 배치(cmnMeetingPanel·cmnCommentTimeline·cmnDocumentPanel) | 화면 확인 항목 |
| 오픈 이슈 | Teams 회의 자동 생성·AI 회의록 초안 | 명세 오픈 이슈 유지 |

## 5. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS), 기한 알림 잡 예약
- dry-run → 배포: 성공
- 커밋: `[CMN-00-MTG-001] 회의·참석자·조치 항목과 회의록 확정·공지·정기 회차`
