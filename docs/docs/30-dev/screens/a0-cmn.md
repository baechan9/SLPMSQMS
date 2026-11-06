# A0 공통 화면 인벤토리

화면 우선 플랜 5.1절 A0 6항 산출물이다. A0에서 새로 만든 화면과, 그 전에 구현을 마쳐 R1 확인만 하면 되는 공통 화면의 확인 경로를 함께 적는다. 화면 유형과 공통 부품은 [화면 전략](../../10-workitems/screen-strategy.md)을 따른다.

- 묶음 브랜치: `ui/a0-cmn`
- 검토 Org 준비: `scripts/org/build-scratch.sh qms-int --reuse --bundle A0 --review`
- 샘플 추가(검토 Org): `sf apex run -o qms-int -f scripts/apex/seed-ai-recommendations.apex`, `sf apex run -o qms-int -f scripts/apex/seed-screen-guides.apex`
- 진행 상태: `screen-map.csv`의 `화면상태`. A0 행 49개 중 화면 대상은 35개이고, 35개 모두 "화면 완료"(3) 또는 "구현 완료(검토 대기)"(32)다. 나머지 14개는 화면이 없거나 B단계·외부 트랙이다.
- 앱 약칭:
  - SL QMS 품질 업무 = 품질 업무
  - SL QMS 현장 = 현장
  - SL Admin = 관리
  - 메뉴 허브의 공통 업무 = 허브 › 공통 업무
  - 메뉴 허브의 기준정보 = 허브 › 기준정보
- 화면 키 예: 샘플 레코드 `TST-KR01-2026-000001`(테스트 객체, 공통 부품 시연용).

## 1. 화면 목록

### 1.1 A0에서 만든 화면(공통 화면 부품·공통 잔여)

| 화면 ID | 화면 | 유형 | 객체·컴포넌트 | 진입 경로 | 페르소나 | 모바일 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| UX-007-S01 | 메뉴 허브(메뉴 번호·기능 타일·검색) | T8 | `cmnAppMenuHub`, `CMN_AppMenu(Item)__mdt` | 품질 업무 → 메뉴 허브 | E1102 | 1열 타일 | 구현 완료 |
| TDO-004-S01 | SL QMS 홈(할 일 + 위젯 보드) | T8 | `cmnTodoList`, `cmnWidgetBoard` | SL QMS → 홈 | E1101, E1102 | 할 일 우선 | 구현 완료 |
| TDO-004-S02 | 현장 홈 | T8 | `CMN_QMS_FieldHome` | 현장 → 홈 | E1104 | 휴대폰 기본 | 구현 완료 |
| DSH-001-S01 | 내 대시보드(위젯 추가·순서·크기) | T5 | `cmnWidgetBoard`·`cmnWidgetFrame`, 샘플 위젯 2개 | SL QMS → 대시보드 | E1101 | 1열 | 구현 완료 |
| UX-004-S01 | 업무 레코드 표준(헤더 7필드·현재 단계 탭·결정 지원 레일) | T1 | 생성기 FlexiPage, `cmnDecisionRail`·`cmnRailPanel` | 샘플 레코드 열기 | E1102 | 레일 → 본문 아래 | 구현 완료 |
| UX-005-S01 | 상태·권한별 섹션·버튼 노출 | T1 | `CMN_UiRule__mdt`·`CMN_UiSection__mdt` | 샘플 레코드 상태를 DRAFT → IN_PROGRESS → DONE으로 바꿔 보기 | E1102 | 같음 | 구현 완료 |
| UX-006-S01 | 공통 편집 그리드(붙여넣기·초안 복원·일정 막대) | T2 | `cmnEditableGrid` gridKey `CMN_TestRecordLines` | 샘플 레코드 → 현재 단계 탭 | E1102 | 카드 목록 | 구현 완료 |
| UX-008-S01 | 현장 입력 셸(순차·표, 즉시 합불, 스캔·사진) | T3 | `cmnFieldEntryShell`, Provider `CMN_TestFieldEntryProvider` | `/lightning/n/CMN_FieldEntry?c__recordId=<샘플 Id>` | E1104 | 순차 모드 | 구현 완료 |
| UX-009-S01 | 체크리스트 수행(답 유형 6종·후속 조치·점수) | T4 | `cmnChecklistRunner`, Provider `CMN_TestChecklistProvider` | `/lightning/n/CMN_Checklist?c__recordId=<샘플 Id>` | E1112 | 요소 선택 목록 | 구현 완료 |
| AI-004-S01 | 레일 AI 추천 패널(채택·수정 채택·제외) | T1 레일 | `cmnAiRecommendationList`, `cmnAiExcludeDialog` | 샘플 레코드 → 오른쪽 레일 "AI 추천"(seed 스크립트 후) | E1102 | 본문 아래 | 구현 완료 |
| AI-004-S02 | AI 추천 기록 목록·레코드 | T6 | `CMN_AiRecommendation__c` 목록 "제안 중"·"제외됨"·"확정 평가됨" | 허브 08 AI → AI 추천 기록 | E1101 | 표준 | 구현 완료 |
| AI-002-S01 | 통합 검색·요약 | T8 | `cmnUnifiedSearch`, `CMN_SearchScope__mdt` | 허브 08 AI → 품질 문서 검색(`CMN_UnifiedSearch?c__q=`) | E1102 | 1열 | 화면 완료 |
| AI-003-S01 | 문서 버전 비교·변경 요약 | T1 대화상자 | `cmnDocumentCompare` | 문서 패널 → 리비전 2개 이상 문서 → 버전 비교 | E1102 | 대화상자 | 화면 완료 |
| UX-002-S01 | 화면 가이드(유틸리티 바) | T6 | `cmnScreenGuide` | 모든 SL 앱 아래 유틸리티 바 "Guide"(seed 스크립트 후) | 전원 | 유틸리티 | 구현 완료 |
| UX-002-S02 | 화면 가이드 관리 | T6 | `CMN_ScreenGuide__c` 목록 "전체"·"미게시" | 관리 → 화면 가이드 | E1901 | 표준 | 구현 완료 |
| DWH-003-S01 | KPI 값(월간 값·위험 신호) | T5 | `CMN_KpiValue__c` | 허브 07 대시보드 → KPI 값, 관리 → KPI 값 | E1101 | 표준 | 화면 완료 |
| DWH-003-S02 | 수신 영수(실패·경로 없음) | T6 | `CMN_InboundReceipt__c` | 허브 09 연계 → 수신 영수, 관리 → 수신 영수 | E1901 | 표준 | 화면 완료(데이터는 B단계) |

### 1.2 구현 완료 공통 화면(R1 확인만)

| 화면 ID | 화면 | 유형 | 객체·컴포넌트 | 진입 경로 | 확인할 것 |
| --- | --- | --- | --- | --- | --- |
| MDM-002-S01 | 법인·공장·라인·공정 | T6 | 표준 레코드 페이지 | 허브 › 기준정보 → 법인/공장/라인/공정 | 공장 시간대·언어, 라인-공정 관련 목록 |
| MDM-001-S01 | 부서·임직원 | T6 | `CMN_Department__c`, `CMN_Employee__c` | 허브 › 기준정보 → 부서/임직원 | 상위 부서, 부서장, HR 상태 |
| MDM-003-S01 | 고객·협력사·차종 | T6 | Account(고객·협력사 레코드타입), `CMN_Vehicle__c` | 허브 › 기준정보 → 고객·협력사/차종 | OEM 코드, 공급업체 번호, 차종-고객 필터 |
| MDM-004-S01 | 제품군·품번 | T6 | `CMN_ProductGroup__c`, `CMN_Item__c`, `CMN_ItemPlant__c` | 허브 › 기준정보 → 제품군/품번 | 자재-플랜트, 차종 연결 |
| MDM-005-S01 | 협력사 품번 | T6 | `CMN_SupplierItem__c` | 허브 › 기준정보 → 협력사 품번 | 검사 수준, PPAP 상태 기본값 |
| MDM-006-S01 | 품질 특성 | T6 | `CMN_Characteristic__c` | 허브 › 기준정보 → 품질 특성 | 규격·특별 특성 표시 |
| MDM-007-S01 | 코드 그룹·공통 코드·코드 선택 | T6 | `CMN_CodeGroup__c`, `CMN_Code__c`, `cmnCodePicker` | 허브 › 기준정보 → 코드 그룹/공통 코드, 관리 → 공통 코드 | 3레벨 코드, 언어별 이름 |
| SEC-002-S01 | 공장 접근 | T6 | `CMN_UserPlantAccess__c` | 허브 › 기준정보 → 공장 접근 | 읽기·편집 수준 |
| APV-002-S01 | 결재선 템플릿·결재 Role 배정 | T6 | `CMN_ApprovalTemplate__c`, `CMN_RoleAssignment__c` | 관리 → 결재선 템플릿, 허브 › 기준정보 → 결재 Role 배정 | 단계·Role, 공장별 Role |
| APV-001·003-S01 | 결재선·상신·처리·이력 | T1 레일 | `cmnApprovalLine`·`cmnApprovalAction`·`cmnApprovalHistory` | 샘플 레코드 → 레일 "결재" | 결재선 편집, 상신(결재 유형 CMN_TEST_APPROVE), 승인·반려 |
| APV-003-S02 | 결재 현황 | T8 | `cmnApprovalMonitor` | SL QMS → 결재 현황 | 내 상신·내 결재, 지연 |
| APV-004-S01 | 결재 위임 | T1 | `CMN_Delegation__c` | 허브 › 공통 업무 → 결재 위임 | 기간·대리인 |
| TDO-001-S01 | To-Do 목록·레일 할 일 | T8 | `CMN_Todo__c`, `cmnTodoList`, `cmnRailTodoList` | 허브 › 공통 업무 → To-Do, 샘플 레코드 → 레일 "할 일" | 기한 경과 표시 |
| NTF-001-S01 | 알림 규칙 | T6 | `CMN_NotificationRule__mdt` | 설정 → 사용자 정의 메타데이터 | 이벤트별 채널(관리자 확인) |
| UX-003-S01 | 상태 진행바·코멘트 타임라인 | T1 | `cmnStatusPath`, `cmnCommentTimeline` | 샘플 레코드 상단·레일 "코멘트" | @멘션, 첨부 |
| DOC-001-S01 | 문서 패널·문서·양식 | T1 레일 | `cmnDocumentPanel`, `CMN_Document__c`, `CMN_DocTemplate__c` | 샘플 레코드 → 레일 "문서", 허브 › 공통 업무 → 문서/문서 양식 | 분류별 리비전, 필수 누락, 링크 등록 |
| MTG-001-S01 | 회의·조치 항목 | T1 | `CMN_Meeting__c`, `CMN_ActionItem__c`, `cmnMeetingPanel` | 허브 › 공통 업무 → 회의/조치 항목 | 참석자, 회의록 확정, 조치 To-Do |
| I18N-001-S01 | 언어 전환 | T6 | `cmnLanguageSwitcher` | 유틸리티 바 "Language" | ko·en_US·zh_CN 문구 표본 |
| UX-001-S01 | 모바일 사진·바코드 | T3 | `cmnPhotoCapture`, `cmnBarcodeScanner` | 현장 앱(휴대폰) → 현장 입력 셸 | 촬영·압축·스캔 |
| ARC-002·003-S01 | 로그·채번 | T6 | `CMN_Log__c`, `CMN_NumberingRule__mdt` | 관리 → 로그 | 오류 로그, 번호 형식 |
| SEC-003-S01 | 삭제 기록 | T6 | `CMN_DeleteLog__c` | 관리 → 삭제 기록 | 삭제 사유·스냅샷 |
| INT-001·002-S01 | 연계 로그·임직원 동기화 결과 | T5 | `CMN_InterfaceLog__c` 목록 "최근 24시간 실패" | 허브 09 연계 → 연계 로그, 관리 → 연계 로그 | 공장·인터페이스별 실패 |

## 2. 업무 동작 자리 구현(A단계)

| 화면 ID | 버튼·동작 | 서비스 메서드 | A단계 동작 |
| --- | --- | --- | --- |
| AI-003-S01 | 변경 내용에 반영 | `CMN_DocumentCompareController.applySummary` → B단계 저장(AiChangeSummary·ChangeNote) | `CMN_Prototype.notYetAvailable()` 안내 |
| AI-002-S01 | 문서 의미 검색·AI 요약 | 색인 엔진 호출(P12, D-4·D8-1) | 프로토 모드면 목 응답, 아니면 "준비 중" |
| AI-003-S01 | 비교(추출·정렬·요약) | 색인 추출 텍스트 + LLM(P12) | 프로토 모드면 목 응답, 아니면 "준비 중"(비교 불가 판정은 실제 동작) |

B단계 완료 조건: `python3 scripts/ci/check-prototype-stubs.py --menu CMN-00` 참조 0건(현재 8건, 테스트 포함).

## 3. Snowflake·AI 목 응답

| 화면 ID | 조회 키·AI 응답 | 목 원본 | 예시 데이터 표시 |
| --- | --- | --- | --- |
| AI-002-S01 | CMN_DOC_SEARCH(ok·empty) | `data/demo/mocks/dwh/CMN_DOC_SEARCH/*.json` | `cmnPrototypeBadge`(AI 요약 머리) |
| AI-003-S01 | CMN_DOC_COMPARE(ok·no-text) | `data/demo/mocks/dwh/CMN_DOC_COMPARE/*.json` | `cmnPrototypeBadge`(변경 요약 머리) |

## 4. 데모 데이터

| 객체 | 원본 | 건수 | 비고 |
| --- | --- | --- | --- |
| 기준정보(법인~협력사 품번·특성·코드) | `data/demo/salesforce/01~16_*.csv` | 묶음 A0 적재 | `--upto-bundle A0` |
| 부서·임직원·사용자·공장 접근·결재 Role | `16~20_*.csv`, `users/` | 페르소나 5명(라이선스 한도) | 검토 페르소나 E1101·E1102·E1104·E1112 |
| 결재 템플릿·위임·결재 요청·To-Do | `21~23_*.csv`, `83~85_*.csv` | | |
| 문서·리비전 | `63~64a_*.csv` | | 버전 비교는 리비전 2개 이상 문서 |
| KPI 값 | `90_CMN_KpiValue__c.csv` | 2,162 | KPI 23종, 일·월 |
| AI 추천 | `scripts/apex/seed-ai-recommendations.apex` | 3 | 예시 문구 |
| 화면 가이드 | `scripts/apex/seed-screen-guides.apex` | 5 | 예시 문구 |
| 샘플 업무 레코드·행 | 테스트 객체(UX-006 그리드 데모) | 1 + 6행 | 공통 부품 시연용 |

## 5. 프로토 한계

| 화면 ID | 한계 | B단계에서 바뀌는 것 |
| --- | --- | --- |
| AI-002-S01 | 문서 결과·AI 요약은 예시 데이터, 문서 링크 없음. 레코드 결과는 실제 | 색인·의미 검색·상위 레코드 접근 확인 |
| AI-003-S01 | 비교 결과·요약은 예시 데이터(실제 파일과 무관), 반영 버튼은 안내만 | 추출·정렬·LLM 요약·요약 저장 |
| AI-004-S01 | 추천은 seed 스크립트가 넣은 예시. AI 실행(추천 생성) 버튼은 메뉴별 AI WI(Vol.8)가 붙인다 | 업무 화면별 런처·렌더러·적중 규칙 |
| DWH-003-S01·S02 | KPI는 데모 CSV, 수신 영수는 빈 목록 | Mule 적재·알람 이벤트·재처리·13개월 삭제 |
| UX-008·009 | Provider는 테스트 객체 샘플 | 메뉴별 Provider(IQC·FQC·심사 등) |
| 공통 | 테스트 객체 화면은 공통 부품 시연용이며 운영 메뉴가 아니다 | 메뉴 화면이 부품을 쓰면 시연 범위 축소 |

## 6. 화면 확인 기록

| 날짜 | 페르소나 | 화면 ID | 결과 | 메모 |
| --- | --- | --- | --- | --- |
| 2026-11-06 | (에이전트) | AI-002-S01 | 확인 필요 | `qms-dev-a` 검색 색인이 재배포 뒤 응답하지 않아(표준 Account도 SOSL 0건) 레코드 결과를 브라우저에서 다시 본다 |
