# P2 보안·정확성 리뷰 결과(2026-11-02)

P2 공통 서비스(TDO-001, NTF-001, UX-003, DOC-001, INT-001~003, TDO-002) Apex·LWC를 독립 리뷰(서브 에이전트, 코드만 읽음)로 점검했다. 각 WI 보고서의 "`/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행" 항목을 이 문서로 대신한다.

| # | 등급 | 지적 | 판단 | 조치 | 회귀 테스트 |
| --- | --- | --- | --- | --- | --- |
| 1 | 높음 | 문서 결재 상신에 접근 확인이 없어 남의 문서 Id로 상신 가능(요청 Summary에 대상 전체 필드 복사, 결재자 공유) | 맞음 | `CMN_DocumentService.submitForApproval`이 부모 편집 권한 확인. 결재 엔진 `CMN_ApprovalService.submit`도 대상 읽기 권한이 없으면 거절(`CMN_Approval_NoTargetAccess`, 모든 유형 공통 방어) | `CMN_DocumentService_Test.test_review_submitRequiresAccess` |
| 2 | 높음 | 결재형 문서에 작성 중 리비전이 둘이면 함께 결재 중이 되고 승인 시 같은 문서 Id 중복으로 실패 | 맞음 | 새 리비전 등록 시 이전 작성 중 리비전 SUPERSEDED, 같은 요청의 낮은 번호도 SUPERSEDED, 같은 요청 안 번호 이어 매기기, `release`는 문서별 최고 번호만 공개 | `test_review_newDraftSupersedesOlderDraftAndApprovesOnce` |
| 3 | 중간 | 리비전 파일·링크 필드를 사용자가 바꿀 수 있고 `javascript:` 링크가 그대로 렌더링 | 공개·대체 리비전은 이미 유효성 규칙이 막았으나 작성 중·결재 중은 열려 있었음, XSS는 맞음 | 유효성 규칙을 상태와 무관하게 "등록 후 변경 불가"로, 파일·링크 필드 사용자 FLS 읽기 전용, 서버·화면 모두 https 링크만 | 같은 테스트(작성 중 변경 거절), Jest "https가 아닌 링크는 링크로 그리지 않는다" |
| 4 | 중간 | MULTI_FILE 분류 링크 등록이 첫 번째 기존 문서에 붙음 | 맞음 | 파일명 키로 해당 문서 선택 | `test_review_linkGoesToItsOwnMultiFileDocument` |
| 5 | 중간 | 크기 초과 파일 삭제가 예외로 롤백되어 남음 | 맞음 | `rejectOversized`가 삭제 후 문구를 값으로 반환, 화면 컨트롤러 응답 `Registration{results, error}`, LWC는 error를 토스트 | `test_AC03_fileOver50MbIsBlockedAndRemoved`, Jest "크기 초과 응답" |
| 6 | 중간 | 문서 패널이 포털 사용자에게 비공개 문서·다른 레코드 중복 원본을 보여 줌 | 맞음(포털 미구성이라 잠재) | 포털(UserType ≠ Standard)은 협력사 공개 문서만, 중복 원본 부모는 사용자가 읽을 수 있을 때만 | 포털 사용자 테스트는 P4(SPP-001)에서 |
| 6-2 | 중간 | 등록 분류를 컴포넌트 허용 목록으로만 제한 | 맞음 | **미조치**: 서버 강제에는 업무 객체별 허용 분류 설정이 필요(업무 WI가 정의). 부모 편집 권한은 서버에서 확인 중 | 후속: 업무 WI 공통 기반 등록 항목에 "문서 분류 허용 목록" 추가 요청 |
| 7 | 중간 | 비활성 결재자 한 명 때문에 이벤트 묶음의 To-Do 열기·닫기·취소 전체 실패 | 맞음 | 비활성 결재자는 To-Do를 만들지 않음, 열기·닫기·취소·알림 각각 별도 try | `CMN_TodoService_Test.test_review_inactiveApproverDoesNotBlockOtherTodos` |
| 8 | 중간 | 반복문 안 로그 발행(행마다 이벤트), DML 오류 원문(메일 주소) 로그 | 맞음 | 연계 로그·알림 서비스·알림 Job·사용자 동기화 Job 모두 묶음당 1회, 메일 오류는 상태 코드·사용자 Id만 | 기존 테스트(WARN 1건 등) 통과 |
| 9 | 낮음 | 포털 링크 변환 클래스를 알림마다 호출 | 맞음 | 인터페이스를 묶음 단위(`Map<Id, Set<Id>>` → `Map<Id, Map<Id, String>>`)로 변경, Job당 1회 호출 | `test_BR5_portalRecipientsUseRegisteredResolver` |
| 10 | 낮음 | 부모 접근 없는 사용자(포털 포함) 멘션 시 알림에 레코드 번호·제목·코멘트 일부 노출 | 포털은 맞음, 사내 사용자는 작성자가 의도한 공유로 판단 | 포털 사용자는 멘션 알림 대상에서 제외 | 기존 AC-3 테스트 통과 |
| 11 | 낮음 | 임직원 동기화 Queueable 등록에 한도 확인 없음 | 맞음 | 한도에 걸리면 등록하지 않고 ERROR 로그(임직원 저장은 유지, 다음 동기화에서 맞춤) | — |

## 함께 고친 것

- `scripts/org/build-scratch.sh`·`scripts/dev/wi-check.sh`: 저장소가 기준인 스크래치 배포에 `--ignore-conflicts`(PSG 재계산 흔적이 충돌로 잡혀 게이트 빌드가 멈춤).
- 결재 이벤트 핸들러 catch 블록을 한 줄 도우미로 줄여 커버리지 유지(81% → 85% 이상).
