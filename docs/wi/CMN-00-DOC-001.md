# CMN-00-DOC-001 완료 보고 — 문서·첨부·리비전 관리

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-DOC-001 (vol0-cmn-common.md CMN-00-DOC-001) |
| Wave / 공수(계획 → 실제) | W0 / 7 M/D → 약 1.5 M/D |
| 완료일 | 2026-11-02 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 완료 |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack Vol.3 변경 요청(Supplier·SupplierVisible·협력사 공유·AllUsers 링크) 반영, 데모 보강(CR-6: ExternalKey·ExternalRef) |

## 1. AC 결과

부모 레코드는 테스트 대상 객체(`CMN_TestRecord__c`)다(CR-11·DEV-3). 분류는 테스트에서 만든 DOC_CLASS 코드(8D_REPORT, NCR_PHOTO = MULTI_FILE, DRAWING = LINK_ONLY, PPAP_PSW = APPROVAL).

| AC | 테스트 | 결과 |
| --- | --- | --- |
| AC-1 8D_REPORT Rev1 RELEASED에 같은 분류 업로드 → Rev2, Rev2 RELEASED 시 Rev1 SUPERSEDED | `CMN_DocumentService_Test.test_AC01_sameClassUploadCreatesNextRevisionAndSupersedes`(같은 문서, 현재 리비전 = Rev2, 공개 일시, 부모 공장 복사, 파일 2개 연결) | 통과 |
| AC-2 RELEASED 리비전 파일 교체 → 차단 | `test_AC02_releasedRevisionFileCannotBeReplaced`(리비전 파일·링크 변경, Files 새 버전 업로드, 파일 삭제, 문서 삭제 모두 차단) | 통과 |
| AC-3 60MB 파일 업로드 → 차단 + 외부 링크 안내 | `test_AC03_fileOver50MbIsBlockedAndRemoved`: 크기 판정(60MB > 50MB, 50MB 허용) + 크기만 60MB인 버전으로 차단 문구·올린 파일 삭제 확인. 실제 60MB 파일은 테스트 힙 한도로 Apex 테스트 불가(개발 플랜 P2 위험 항목) — 화면 1회 확인 항목 | 통과(판정·차단 경로) |
| AC-4 다른 레코드와 같은 해시 파일 → 경고 플래그·원본 정보, 업로드 성공 | `test_AC04_sameHashOnOtherParentIsFlaggedNotBlocked`(RELEASED, IsDuplicateFile, DuplicateOfRevision = 원본, 처음 파일은 경고 없음) | 통과 |
| BR-1 MULTI_FILE 분류·단일 분류 | `test_BR1_multiFileClassKeepsDocumentPerFile`(사진 파일별 문서, 같은 이름 → Rev2, 협력사 공개 = AllUsers, 단일 분류 다중 파일 거절) | 통과 |
| BR-2 부모 불변·삭제 통제 | `test_BR2_documentParentFixedAndDraftDocumentDeletable` | 통과 |
| BR-3 결재형 공개 | `test_BR3_approvalTypeReleasesOnApproval`(DRAFT → 상신 IN_APPROVAL → 결재 중 업로드 차단 → 승인 RELEASED, 다음 리비전 반려 REJECTED·이전 RELEASED 유지), `test_BR3_recallReturnsToDraft` | 통과 |
| BR-4 링크 전용·링크 | `test_BR4_linkOnlyClassAndLinks`(도면 파일 차단, PDM 외부 번호 등록·즉시 공개, http·저장소 오류) | 통과 |
| BR-6 부모 접근 | `test_BR6_panelFollowsParentAccess`(패널: 분류·필수 누락·en_US 양식·현재 리비전, 부모를 못 보는 사용자 빈 패널·등록 차단) | 통과 |
| BR-7 양식 언어·입력 검증 | `test_negative_inputAndTemplates`(ko 우선 → en_US, 분류·파일·코드 목록·Id 형식 오류, 결재선 템플릿 없음) | 통과 |
| 화면 | `cmnDocumentPanel` Jest 7건(분류별 표시·중복 경고·필수 누락·양식 링크, 업로드 → 등록 → 다시 불러오기, 오류 토스트, 링크 등록, 이력·미리보기·상신, 접근 없음·읽기 전용, 조회 오류) | 통과 |

데모 데이터(`63_CMN_Document__c`·`64_CMN_DocumentRevision__c`·`64a`, 98행)는 부모가 모두 `QMS_QualPlanLine__c`(P4)라 이번 페이즈에서 적재하지 않는다(로더·테스트 픽스처 모두 건너뜀).

## 2. 구현 내역

- 객체·메타데이터
  - `CMN_Document__c`(Parent·DocClass·DeliverableType·CurrentRevision·Plant·Supplier·SupplierVisible·ExternalKey, Private + 공장·협력사·결재자 공유 사유, 이력, 탭), `CMN_DocumentRevision__c`(주종, 명세 필드 + IsDuplicateFile·DuplicateOfRevision·ReleasedAt·ExternalRef·ExternalKey, 공개 리비전 잠금 유효성 규칙), `CMN_DocTemplate__c`(DocClass·Language·ContentDocumentId·Version·IsActive, 공개 읽기, 탭).
  - 공유 설정 `CMN_SharingConfig` CMN_Document(Plant__c·Supplier__c), 삭제 통제 `CMN_DeleteGuard` 리비전(DRAFT·REJECTED만), 결재 유형 `CMN_DOC_RELEASE`(대상 문서, 콜백), CMN 설정 `CMN_DOC_MAX_FILE_MB`(50).
  - PS `CMN_PS_Document_User`(사내 페르소나 PSG 전체), `CMN_PS_Document_Admin`(View All·양식 관리, QualityAdmin·SystemAdmin). 라벨 35개.
- Apex: `CMN_DocumentService`(registerFiles·registerLink·submitForApproval·release·moveRevisions·templateFor·templatesFor·tooLarge), `CMN_DocumentSelector`·`CMN_DocumentWriter`(without sharing, 사유 주석), `CMN_DocumentApprovalCallback`, `CMN_DocumentController`(getPanel·registerFiles·registerLink·submitDocument), 트리거: 문서(핸들러), 리비전(프레임워크: 삭제 통제), ContentVersion(공개 파일 새 버전 차단), ContentDocument(공개 파일 삭제 차단).
- LWC: `cmnDocumentPanel`(속성 allowedDocClasses·requiredDocClasses, 데스크톱·모바일).
- 테스트 기반: `CMN_TestDataFactory`가 풀 수 없는 참조(아직 배포되지 않은 다른 메뉴 레코드)를 가진 픽스처 행과 그 후속 단계 행을 건너뛴다(문서 픽스처의 부모가 QMS 레코드라 필요).
- 핵심 설계 판단
  1. **결재 대상 = 문서**: 리비전은 주종 하위라 공유 객체가 없어 결재자 공유(APV-001 BR-6)를 줄 수 없다. 문서를 결재하고 콜백이 결재 중 리비전의 상태를 바꾼다.
  2. **파일은 먼저 개인 파일로**: `lightning-file-upload`에 record-id를 주지 않아 사용자 개인 파일로 올리고, 서버가 분류·크기·결재 중 여부를 확인한 뒤 문서에 연결한다(ShareType I = 문서 접근을 따름). 크기를 넘으면 그 파일을 지운다.
  3. **공개 잠금은 유효성 규칙 + 파일 트리거**: 리비전 필드 잠금은 트리거 재진입 판정과 무관하게 항상 적용되도록 유효성 규칙으로, Files의 새 버전 업로드·삭제는 ContentVersion·ContentDocument 트리거로 막는다.
  4. **분류 속성으로 업무 설정**: DocClass `Attribute1__c = LINK_ONLY`(도면), `Attribute2__c = MULTI_FILE`(사진: 파일명 단위 문서), `Attribute3__c` = 산출물 유형(비우면 ATTACHMENT, APPROVAL이면 결재형). 업무 WI는 코드 속성만 채운다.
  5. **등록 권한 = 부모 편집 권한**: 조회는 부모 읽기(BR-6), 등록은 `UserRecordAccess.HasEditAccess`. 다른 사용자가 만든 문서에도 리비전을 더할 수 있도록 검증 후 저장은 Writer가 한다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 커버리지(클래스별) | CMN_DocumentService 98%, CMN_DocumentSelector 98%, CMN_DocumentApprovalCallback 97%, CMN_DocumentTriggerHandler 88%, CMN_DocumentController 86%, Writer·파일 트리거 핸들러 100% |
| Apex 테스트 | DOC-001 11건 통과. 전체 회귀 25개 클래스 184건 통과(동기 실행: 스크래치 Org 일일 비동기 테스트 한도 도달) |
| LWC Jest | 33건 통과(DOC-001 7건 포함) |
| Code Analyzer(심각도 1~2) | 0건 |
| ESLint / Prettier / 한글 리터럴 | 통과 / 통과 / 0건 |

## 4. 보안·성능 점검

- [x] `without sharing`은 Selector(문서 단위 판정·중복 탐지·부모 확인 후 패널 조회, 읽기만)와 Writer(검증 후 저장만), 사유 주석
- [x] 상태·번호·해시·현재 리비전은 사용자 FLS 읽기, 서비스만 변경
- [x] 링크는 https만, 외부 링크는 `rel="noopener"`로 새 창
- [x] 동적 SOQL은 Id에서 얻은 객체 이름만(이스케이프), 값은 바인드
- [x] 패널은 부모 읽기 권한이 없으면 빈 응답, 서버 메시지는 라벨 문구만
- [ ] `/code-review`·`/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | `FileHash__c` = 플랫폼 체크섬(`ContentVersion.Checksum`, MD5). 50MB 파일의 SHA-256은 Apex 힙 한도(동기 6MB·비동기 12MB)로 서버에서 계산할 수 없다 | BR-5 문구를 "플랫폼 체크섬"으로 변경 요청 |
| 명세 차이 | 결재 대상은 리비전이 아니라 문서(주종 하위는 공유 객체가 없어 결재자 공유 불가) | BR-3 보완 요청 |
| 명세 차이 | `ChangeNote__c` Text(1000) → Long Text Area(1000)(Text 최대 255) | 플랫폼 제약 |
| 명세 차이 | 추가 필드: `IsDuplicateFile__c`·`DuplicateOfRevision__c`(BR-5 경고·원본), `ReleasedAt__c`(Vol.6c 공개일), `ExternalKey__c`(데모 업서트 키), 리비전 외부 저장소 키는 `ExternalRef__c`(CR-6 이름 변경) | 개발 플랜 CR-6 |
| 명세 차이 | 분류 속성 규칙: Attribute1 LINK_ONLY, Attribute2 MULTI_FILE, Attribute3 산출물 유형 | DOC_CLASS 코드 시드에 반영 필요(도면 분류 LINK_ONLY, 사진 분류 MULTI_FILE, 결재형 분류 APPROVAL) |
| 명세 차이 | 등록은 부모 편집 권한 필요(명세 미기재) | 사용자 확인 |
| CR 반영 | 검토 반영 Vol.3: Supplier·SupplierVisible, 공유 설정 SupplierField, 협력사 공개 파일 Visibility AllUsers | — |
| 신규 설정 | `CMN_DOC_MAX_FILE_MB`(50) | — |
| 미검증 | 실제 60MB 파일 업로드(화면), `lightning-file-upload` record-id 없이 업로드 | 사용자 UI 확인 항목 |
| 후속 | 비교 버튼·AI 변경 요약(AI-003), 색인(AI-002), 포털 문서 화면(QMS-03-SPP), PMS 산출물 5종 | 각 WI |
| 오픈 이슈 | D-7 대용량·통제 문서 저장소(SharePoint) | review-pack 결정 대기 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-DOC-001] 문서·리비전 관리 서비스와 문서 패널`
