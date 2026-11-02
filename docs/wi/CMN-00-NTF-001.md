# CMN-00-NTF-001 완료 보고 — 알림 서비스(메일·벨·모바일 푸시)

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-NTF-001 (vol0-cmn-common.md CMN-00-NTF-001) |
| Wave / 공수(계획 → 실제) | W0 / 4 M/D → 약 0.5 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack Vol.3 변경 요청(BR-5 링크 변환 = `CMN_RecipientUrlResolver` + Custom Metadata 등록) 반영 |

## 1. AC 결과

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 수신자 2명(ko, en) → 각자 언어 메일·벨 1건씩 | `CMN_NotificationService_Test.test_AC01_eachRecipientGetsOwnLanguageMailAndBell`(제목 `[결재 요청] …`/`[Approval Request] …`, 본문 보낸 사람·Lightning 링크, 언어별 벨 1건) | 통과 |
| AC-2 IsActive=false 규칙 → 발송 0건, WARN 로그 1건 | `test_AC02_inactiveRuleSendsNothingAndLogsWarn`(큐 등록 0, `CMN_Log__c` WARN 1건, 미등록 코드도 미발송) | 통과 |
| AC-3 수신자 300명 → 거버너 오류 없이 발송(Queueable 분할) | `test_AC03_300RecipientsAreSentInChunks`: Queueable 1개 등록, 100명씩 3회 실행(이어 붙이기). Scratch Org에서 300명을 만들 수 없어 실제 사용자 2명 + 사용자 Id 298개로 분할만 검증(개발 플랜 P2 위험 항목) | 통과 |
| BR-1 언어 → en_US 대체 | `test_BR1_renderUsesLanguageThenEnglish`(zh_CN, 번역 없는 ja → en_US, 없는 라벨 → null) | 통과 |
| BR-4 라벨 없음·발송 실패는 업무 트랜잭션 밖에서 로그 | `test_BR4_missingLabelAndInactiveRecipientAreSkipped` | 통과 |
| BR-5 포털 수신자 링크 변환 | `test_BR5_portalRecipientsUseRegisteredResolver`(등록 클래스 URL, 클래스 없음 → 사내 링크 + WARN) | 통과 |
| 결재 이벤트 알림 | `test_BR_approvalEventsQueueNotifications`(STEP_PENDING → 결재자, 반려 → 기안자(보낸 사람 = 반려자), 승인 → 기안자) | 통과 |

실 Org 스모크(qms-dev-a): E1101·E1103에게 `APV_STEP_PENDING` 발송 → `CMN_NotificationJob` Completed, 오류 0, ERROR 로그 0.

## 2. 구현 내역

- 메타데이터
  - `CMN_NotificationRule__mdt`(Channels·SubjectLabel·BodyLabel·IsActive, DeveloperName = EventCode). 레코드: `APV_STEP_PENDING`(EMAIL·BELL), `APV_APPROVED`(BELL), `APV_REJECTED`(EMAIL·BELL), `CMN_TEST_INACTIVE`(AC-2 검증용 비활성).
  - Custom Notification Type `CMN_General`(데스크톱·모바일).
  - 라벨 6개(결재 요청·승인·반려 제목/본문, ko·en_US·zh_CN). CMN 설정 `CMN_NTF_CHUNK_SIZE`(100), `CMN_NTF_FROM_ADDRESS`(공란), `CMN_NTF_PORTAL_URL_RESOLVER`(공란).
- Apex
  - `CMN_NotificationService.send(eventCode, recipientUserIds, recordId, params)`(명세 API), `send(List<Message>)`(여러 알림을 Queueable 하나로 — 트리거·이벤트 구독 일괄용), `ruleOf`, `render`.
  - `CMN_NotificationJob`(Queueable): 수신자 묶음 단위 발송·이어 붙이기, 메일(`setTargetObjectId` + `setSaveAsActivity(false)`, Org-Wide 주소 설정 시 사용), 벨(언어별 1회), 토큰 채우기, 링크 변환.
  - `CMN_RecipientUrlResolver`(인터페이스, 검토 반영 Vol.3).
  - `CMN_ApprovalEventTriggerHandler`에 결재 알림 추가(TDO-001 구독과 같은 트리거, 서로의 실패에 영향 없음). `CMN_TodoSelector.approvalSteps`에 기안자 추가.
- 핵심 설계 판단
  1. **큐 등록만 업무 트랜잭션에서**: 규칙 확인·수신자 정리 후 Queueable 1개만 등록한다. 발송 오류·라벨 누락은 Queueable 안에서 로그로 남겨 업무를 되돌리지 않는다(BR-4). Queueable 한도에 걸리면 ERROR 로그를 남기고 건너뛴다.
  2. **토큰**: `{RecordNo}`·`{Title}`은 레코드의 `RecordNo__c`·`Name`(객체별 SOQL 1회), `{Actor}`는 보낸 사람 이름, `{Url}`은 수신자별 링크, `{DueDate}`는 params. params가 같은 이름이면 우선한다.
  3. **벨 본문**: 링크가 필요 없고(알림을 누르면 레코드로 이동) 언어별로 묶어 보낸다. 제목 250자·본문 750자로 자른다.
  4. **포털 판정**: `UserType != 'Standard'`. 변환 클래스가 등록되지 않았거나 일부 수신자 URL을 주지 않으면 사내 링크.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_NotificationJob 89%, CMN_NotificationService 91%, CMN_ApprovalEventTriggerHandler 89% |
| Apex 테스트 | 186건 통과(RunLocalTests, NTF-001 7건 포함) |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier / 한글 리터럴 | 통과 / 통과 / 0건 |

## 4. 보안·성능 점검

- [x] 모든 클래스 with sharing. 사용자·레코드 토큰 조회는 `WITH SYSTEM_MODE`/`AccessLevel.SYSTEM_MODE`(Queueable 시스템 처리), 결과는 메일·벨 문구로만 쓴다
- [x] 동적 SOQL은 객체 이름을 Id에서 얻고(사용자 입력 아님) 이스케이프, 값은 바인드
- [x] 메일은 User 대상(`setTargetObjectId`)이라 외부 일일 한도 미사용, 활동 기록 없음
- [x] 문구는 Custom Label만(Email Template 미사용)
- [x] 로그에 본문·개인정보를 남기지 않는다(이벤트 코드·오류 메시지만)
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| CR 반영 | `CMN_RecipientUrlResolver` + CMN 설정 `CMN_NTF_PORTAL_URL_RESOLVER`(클래스 이름) 등록 | QMS-03-SPP-001이 `QMS_PortalUrlResolver`를 만들고 설정 값을 채운다 |
| 명세 차이 | 명세 API 외에 `send(List<Message>)` 추가: 이벤트 구독·트리거가 여러 알림을 Queueable 1개로 보내기 위함(Queueable 한도) | interfaces.md 알림 절에 추가 요청 |
| 명세 차이 | 결재 알림 규칙 코드 `APV_STEP_PENDING`·`APV_APPROVED`·`APV_REJECTED`를 NTF-001이 등록(APV-001 BR-9 구독 측). 승인 알림은 벨만 | 운영 중 규칙 레코드로 조정 |
| 신규 설정 | `CMN_NTF_CHUNK_SIZE`, `CMN_NTF_FROM_ADDRESS`(SL 발신 주소 확인 후 Org-Wide Email Address 등록과 함께 입력), `CMN_NTF_PORTAL_URL_RESOLVER` | 오픈 이슈: 발신 주소 |
| 미검증 | 300명 실제 발송(AC-3)은 Scratch 사용자 한도로 분할 로직만 검증 | SIT Sandbox에서 실제 규모 확인 |
| 오픈 이슈 | 사용자별 수신 설정(메일 끄기), Teams 채널 | 명세 오픈 이슈 유지 |
| 후속 | 멘션 알림(UX-003), 결재 지연·에스컬레이션 알림(APV-005), 각 업무 WI의 규칙·라벨 | 각 WI |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-NTF-001] 공통 알림 서비스(메일·벨)와 결재 알림`
