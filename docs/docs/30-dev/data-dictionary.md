# 데이터 사전 — 배포된 객체와 커스텀 필드

`python3 scripts/dev/data-dictionary.py`가 배포 소스(`force-app-*`)에서 만든다. 손으로 고치지 않는다. 기준일 2026-11-06.

- 라벨(ko)은 Org 기본 라벨, Label(en)은 영어 번역이다. 중국어 번역은 소스의 objectTranslations에 있다.
- 값/길이/참조: 선택 목록 값, 텍스트 길이, 숫자 자릿수(전체,소수), 관계 대상(→).
- 표준 필드(Name, Owner, CreatedDate 등)는 넣지 않는다.

## 요약

| 구분 | 객체 수 | 커스텀 필드 수 |
| --- | --- | --- |
| 커스텀 객체 | 41 | 373 |
| 표준 객체 확장 | 2 | 22 |
| 커스텀 메타데이터 유형(설정) | 25 | 156 |
| Platform Event | 5 | 23 |
| 합계 | 73 | 574 |

## 커스텀 객체

| 객체 | 라벨(ko) | Label(en) | 필드 수 | 소유 WI |
| --- | --- | --- | --- | --- |
| [CMN_ActionItem__c](#cmn_actionitem__c) | 조치 항목 | Action Item | 10 | CMN-00-MTG-001 |
| [CMN_AiRecommendation__c](#cmn_airecommendation__c) | AI 추천 | AI Recommendation | 19 | CMN-00-AI-004 |
| [CMN_ApprovalRequest__c](#cmn_approvalrequest__c) | 결재 요청 | Approval Request | 14 | CMN-00-APV-001 |
| [CMN_ApprovalStep__c](#cmn_approvalstep__c) | 결재 단계 | Approval Step | 14 | CMN-00-APV-001 |
| [CMN_ApprovalTemplateStep__c](#cmn_approvaltemplatestep__c) | 템플릿 단계 | Template Step | 9 | CMN-00-APV-002 |
| [CMN_ApprovalTemplate__c](#cmn_approvaltemplate__c) | 결재선 템플릿 | Approval Template | 7 | CMN-00-APV-002 |
| [CMN_Characteristic__c](#cmn_characteristic__c) | 품질 특성 | Characteristic | 18 | CMN-00-MDM-006 |
| [CMN_CodeGroup__c](#cmn_codegroup__c) | 코드 그룹 | Code Group | 6 | CMN-00-MDM-007 |
| [CMN_Code__c](#cmn_code__c) | 공통 코드 | Code | 14 | CMN-00-MDM-007 |
| [CMN_Comment__c](#cmn_comment__c) | 코멘트 | Comment | 5 | CMN-00-UX-003 |
| [CMN_Company__c](#cmn_company__c) | 법인 | Company | 6 | CMN-00-MDM-002 |
| [CMN_Delegation__c](#cmn_delegation__c) | 결재 위임 | Approval Delegation | 8 | CMN-00-APV-004 |
| [CMN_DeleteLog__c](#cmn_deletelog__c) | 삭제 기록 | Delete Log | 7 | CMN-00-SEC-003 |
| [CMN_Department__c](#cmn_department__c) | 부서 | Department | 9 | CMN-00-MDM-001 |
| [CMN_DocTemplate__c](#cmn_doctemplate__c) | 문서 양식 | Document Template | 5 | CMN-00-DOC-001 |
| [CMN_DocumentRevision__c](#cmn_documentrevision__c) | 문서 리비전 | Document Revision | 17 | CMN-00-DOC-001 |
| [CMN_Document__c](#cmn_document__c) | 문서 | Document | 9 | CMN-00-DOC-001 |
| [CMN_Employee__c](#cmn_employee__c) | 임직원 | Employee | 7 | CMN-00-INT-002 |
| [CMN_InboundReceipt__c](#cmn_inboundreceipt__c) | 수신 영수 | Inbound Receipt | 8 | CMN-00-DWH-003 |
| [CMN_InterfaceLog__c](#cmn_interfacelog__c) | 연계 로그 | Interface Log | 11 | CMN-00-INT-001 |
| [CMN_ItemPlant__c](#cmn_itemplant__c) | 공장별 품번 | Item Plant | 4 | CMN-00-MDM-004 |
| [CMN_ItemVehicle__c](#cmn_itemvehicle__c) | 적용 차종 | Item Vehicle | 4 | CMN-00-MDM-004 |
| [CMN_Item__c](#cmn_item__c) | 품번 | Item | 13 | CMN-00-MDM-004 |
| [CMN_KpiValue__c](#cmn_kpivalue__c) | KPI 값 | KPI Value | 17 | CMN-00-DWH-003 |
| [CMN_Line__c](#cmn_line__c) | 라인 | Line | 9 | CMN-00-MDM-002 |
| [CMN_LogSetting__c](#cmn_logsetting__c) | 로그 설정 |  | 1 | CMN-00-ARC-002 |
| [CMN_Log__c](#cmn_log__c) | 로그 | Log | 6 | CMN-00-ARC-002 |
| [CMN_MeetingAttendee__c](#cmn_meetingattendee__c) | 참석자 | Attendee | 5 | CMN-00-MTG-001 |
| [CMN_Meeting__c](#cmn_meeting__c) | 회의 | Meeting | 14 | CMN-00-MTG-001 |
| [CMN_NumberCounter__c](#cmn_numbercounter__c) | 채번 카운터 | Number Counter | 2 | CMN-00-ARC-003 |
| [CMN_Operation__c](#cmn_operation__c) | 공정 | Operation | 9 | CMN-00-MDM-002 |
| [CMN_Plant__c](#cmn_plant__c) | 공장 | Plant | 10 | CMN-00-MDM-002 |
| [CMN_ProductGroup__c](#cmn_productgroup__c) | 제품군 | Product Group | 6 | CMN-00-MDM-004 |
| [CMN_RoleAssignment__c](#cmn_roleassignment__c) | 결재 Role 배정 | Role Assignment | 7 | CMN-00-APV-002 |
| [CMN_SupplierItem__c](#cmn_supplieritem__c) | 협력사 품번 | Supplier Item | 6 | CMN-00-MDM-005 |
| [CMN_TestRecordLine__c](#cmn_testrecordline__c) | 테스트 라인 | Test Line | 10 | CMN-00-UX-006 |
| [CMN_TestRecord__c](#cmn_testrecord__c) | 테스트 레코드 | Test Record | 10 | CMN-00-ARC-003 |
| [CMN_Todo__c](#cmn_todo__c) | To-Do | To-Do | 19 | CMN-00-TDO-001 |
| [CMN_UserDashboard__c](#cmn_userdashboard__c) | 사용자 대시보드 | User Dashboard | 5 | CMN-00-DSH-001 |
| [CMN_UserPlantAccess__c](#cmn_userplantaccess__c) | 공장 접근 | Plant Access | 4 | CMN-00-SEC-002 |
| [CMN_Vehicle__c](#cmn_vehicle__c) | 차종 | Vehicle | 9 | CMN-00-MDM-003 |

### CMN_ActionItem__c

조치 항목 / Action Item. 공통 조치 항목(MTG-001). 회의 외 업무에서도 재사용. 담당자(Owner__c) To-Do(SourceType CMN_ACTION_ITEM), 완료 시 To-Do 종료

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| CompletedAt__c | 완료 일시 | Completed At | DateTime |  |  |  |
| Description__c | 내용 | Description | LongTextArea | 32768 |  |  |
| DueDate__c | 기한 | Due Date | Date |  | 필수 |  |
| LastDueAlertOn__c | 마지막 기한 알림일 | Last Due Alert | Date |  |  | BR-3 하루 1회 |
| Meeting__c | 회의 | Meeting | Lookup | → CMN_Meeting__c |  |  |
| Owner__c | 담당자 | Owner | Lookup | → User |  | 필수는 트리거 확인(User Lookup 필수 불가) |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  |  |
| SourceKey__c | 원천 세부 키 | Source Key | Text | 80 |  | 원천 레코드 안의 세부 위치(체크리스트 질문 키 등, UX-009 BR-5). SourceRecordId__c와 함께 쓴다 |
| SourceRecordId__c | 원천 업무 | Source Record | Text | 18 |  |  |
| Status__c | 상태 | Status | Picklist | OPEN, DONE, CANCELLED | 필수 |  |

### CMN_AiRecommendation__c

AI 추천 / AI Recommendation. AI 추천 기록(AI-004). 무엇을 추천했고 사용자가 무엇을 채택했고 최종 확정이 무엇이었는지 남긴다(정확도 측정 근거). 기록·결정·확정은 CMN_AiRecommendationService만 한다(사람 확정 원칙: 추천은 업무 필드에 직접 쓰지 않는다). 공장은 원천 레코드에서 가져와 공장 공유(SEC-002)를 따른다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| ContentJson__c | 추천 내용 | Content JSON | LongTextArea | 32768 |  | 구조화 내용. 기본 표시 키: title, text, items[{label,value}]. UseCase 렌더러가 확장 |
| DecidedAt__c | 결정 시각 | Decided At | DateTime |  |  |  |
| DecidedBy__c | 결정자 | Decided By | Lookup | → User |  |  |
| ExcludeReason__c | 제외 사유 | Exclude Reason | Lookup | → CMN_Code__c |  | 공통 코드 그룹 AI_EXCLUDE_REASON. 제외면 필수(AC-2) |
| FinalOutcomeJson__c | 확정 결과 | Final Outcome | LongTextArea | 32768 |  | 업무 확정 시 실제 결과(예: 확정 원인 코드) |
| FinalizedAt__c | 확정 평가 시각 | Finalized At | DateTime |  |  | Vol.8 변경 요청: 적중 평가 시각 |
| IsHit__c | 적중 | Hit | Checkbox |  |  | 확정 결과와 일치(업무 WI의 CMN_AiHitRule) |
| ModelInfo__c | 모델 | Model | Text | 80 | 필수 |  |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  | 원천 레코드의 Plant__c(있을 때). 공장 공유 기준(명세 보충) |
| PromptVersion__c | 프롬프트 버전 | Prompt Version | Text | 40 | 필수 |  |
| Rank__c | 순위 | Rank | Number | 3,0 | 필수 |  |
| Rationale__c | 근거 설명 | Rationale | LongTextArea | 32768 |  |  |
| Score__c | 신뢰 점수 | Score | Number | 5,4 |  | 유사도·신뢰 점수 0~1 |
| SourceLink__c | 대상 레코드 | Source Record | Formula(Text) |  |  | 대상 레코드 바로 가기(명세 보충) |
| SourceObject__c | 대상 객체 | Source Object | Text | 80 | 필수 |  |
| SourceRecordId__c | 대상 레코드 Id | Source Record Id | Text | 18 | 필수 외부 키 | 추천 대상 업무 레코드(다른 메뉴 객체라 Lookup이 아닌 Id 텍스트). 외부 ID = 조회 인덱스 |
| SourceRefs__c | 근거 출처 | Source References | LongTextArea | 32768 |  | 근거 레코드·문서 목록 JSON [{id, label}] |
| Status__c | 결정 상태 | Status | Picklist | PROPOSED, ADOPTED, MODIFIED, EXCLUDED, EXPIRED | 필수 |  |
| UseCase__c | 추천 유형 | Use Case | Picklist | QMS_RCA, QMS_CAPA, QMS_8D_DRAFT, QMS_LELE, QMS_EW, QMS_COA_ANOMALY, QMS_4M_TEST, QMS_AUDIT_PREP, PMS_SCHEDULE, PMS_DELIVERABLE_DRAFT, PMS_EW | 필수 | QMS_COA_ANOMALY(Vol.3)·QMS_4M_TEST(Vol.6a)·QMS_AUDIT_PREP(Vol.8)은 review-pack 변경 요청 |

### CMN_ApprovalRequest__c

결재 요청 / Approval Request. 결재 요청(APV-001). 대상은 다형(TargetRecordId·TargetObject). 상태는 CMN_ApprovalService만 바꾼다. 번호 APV-{YYYY}-{SEQ:7}(ARC-003)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| CompletedAt__c | 완료 일시 | Completed At | DateTime |  |  |  |
| CurrentStepNo__c | 진행 단계 | Current Step | Number | 3,0 |  |  |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  | 공유·통계용(대상의 공장) |
| RecordNo__c | 결재 번호 | Approval No. | Text | 40 | 외부 키 유일 | 채번 APV-{YYYY}-{SEQ:7} |
| Status__c | 상태 | Status | Picklist | DRAFT, IN_PROGRESS, APPROVED, REJECTED, RECALLED |  |  |
| SubmitComment__c | 상신 의견 | Submit Comment | LongTextArea | 4000 |  | submit()의 comment(명세 API 인자 — 저장 위치 추가) |
| SubmittedAt__c | 상신 일시 | Submitted At | DateTime |  |  |  |
| Summary__c | 상신 스냅숏 | Submission Snapshot | LongTextArea | 32768 |  | 상신 시점 대상 필드 JSON |
| TargetObject__c | 대상 객체 | Target Object | Text | 80 | 필수 |  |
| TargetRecordId__c | 대상 레코드 | Target Record | Text | 18 | 필수 |  |
| TargetRecordNo__c | 대상 번호 | Target No. | Text | 40 |  | 대상 업무 번호 사본 |
| Title__c | 제목 | Title | Text | 255 | 필수 |  |
| TypeCode__c | 결재 유형 | Approval Type | Text | 80 | 필수 | CMN_ApprovalType__mdt DeveloperName |
| Version__c | 차수 | Version | Number | 3,0 | 필수 | 같은 대상 재상신 차수(BR-7) |

### CMN_ApprovalStep__c

결재 단계 / Approval Step. 결재 단계. 같은 StepNo = 병렬(모두 승인 필요), CC는 통보만. 상태는 CMN_ApprovalService만 바꾼다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| ActedAt__c | 처리 일시 | Acted At | DateTime |  |  |  |
| ActedBy__c | 처리자 | Acted By | Lookup | → User |  | 실제 처리자(대결 시 대리인) |
| Approver__c | 결재자 | Approver | Lookup | → User |  | 명세 필수: User 조회는 필수로 만들 수 없어 서비스가 확인 |
| Comment__c | 의견 | Comment | LongTextArea | 4000 |  |  |
| ExternalKey__c | 외부 키 | External Key | Text | 60 | 외부 키 유일 | {결재 번호}-S{StepNo}(병렬 둘째부터 -{순번}). 데모 보강 CR-6 |
| IsDelegated__c | 대결 | Delegated | Checkbox |  |  |  |
| LastEscalationOn__c | 마지막 에스컬레이션일 | Last Escalation | Date |  |  | 공장 현지 날짜. 하루 1회(APV-005 BR-2) |
| LastReminderOn__c | 마지막 독촉일 | Last Reminder | Date |  |  | 공장 현지 날짜. 하루 1회(APV-005 BR-2) |
| PendingAt__c | 대기 시작 | Pending Since | DateTime |  |  | PENDING이 된 시각(APV-005 체류일수 기준) |
| Request__c | 결재 요청 | Approval Request | MasterDetail | → CMN_ApprovalRequest__c |  |  |
| RoleCode__c | 결재 Role | Approval Role | Text | 40 |  | Role로 해석된 경우 원본 Role |
| Status__c | 상태 | Status | Picklist | WAITING, PENDING, APPROVED, REJECTED, SKIPPED, NOTIFIED |  |  |
| StepNo__c | 단계 순서 | Step Order | Number | 3,0 | 필수 |  |
| StepType__c | 단계 유형 | Step Type | Picklist | REVIEW, AGREE, APPROVE, CC | 필수 |  |

### CMN_ApprovalTemplateStep__c

템플릿 단계 / Template Step. 결재선 템플릿 단계. 해석 유형: ROLE, USER, DRAFTER_MANAGER, RECORD_FIELD(FieldPath), PROJECT_ROLE(PMS 예약)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| ExternalKey__c | 외부 키 | External Key | Text | 140 | 외부 키 유일 | {템플릿 외부 키}-{StepNo}. 데모 보강 CR-6 |
| FieldPath__c | 필드 경로 | Field Path | Text | 255 |  | RECORD_FIELD: 대상 레코드의 사용자 Id 경로(예: ResponsibleDept__r.Manager__c) |
| IsMandatory__c | 필수 | Mandatory | Checkbox |  |  | 사용자가 삭제·결재자 변경 불가(BR-3) |
| ResolverType__c | 결재자 해석 | Resolver Type | Picklist | ROLE, USER, DRAFTER_MANAGER, RECORD_FIELD, PROJECT_ROLE | 필수 |  |
| RoleCode__c | Role 코드 | Role Code | Text | 40 |  | ROLE: APPROVAL_ROLE 코드 |
| StepNo__c | 단계 순서 | Step Order | Number | 3,0 | 필수 |  |
| StepType__c | 단계 유형 | Step Type | Picklist | REVIEW, AGREE, APPROVE, CC | 필수 |  |
| Template__c | 템플릿 | Template | MasterDetail | → CMN_ApprovalTemplate__c |  |  |
| User__c | 사용자 | User | Lookup | → User |  | USER |

### CMN_ApprovalTemplate__c

결재선 템플릿 / Approval Template. 결재선 템플릿(APV-002). SYSTEM은 전 사용자 조회(조건 공유 규칙), PERSONAL은 본인만. TypeCode × 공장(공란 = 전사 기본)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| AllowUserEdit__c | 사용자 편집 허용 | Allow User Edit | Checkbox |  |  |  |
| ExternalKey__c | 외부 키 | External Key | Text | 120 | 외부 키 유일 | 시스템 기본 템플릿: TPL-{TypeCode}(공장이면 -{PlantCode}). 데모 보강 CR-6 |
| IsActive__c | 사용 | Active | Checkbox |  |  |  |
| IsDefault__c | 기본 | Default | Checkbox |  |  |  |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  | 공란 = 전사 기본 |
| Scope__c | 구분 | Scope | Picklist | SYSTEM, PERSONAL | 필수 |  |
| TypeCode__c | 결재 유형 | Approval Type | Text | 80 | 필수 |  |

### CMN_Characteristic__c

품질 특성 / Characteristic. 품질 특성(관리계획서 특성 행). 수입·출하검사·SPC·MSA가 공통으로 쓰는 규격 정의. 버전: ACTIVE 규격은 수정 금지, 새 버전을 만들어 활성화하면 구 버전이 닫힌다(BR-3). Snowflake CORE.CHARACTERISTIC 동기화는 DWH-002

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| CharNo__c | 특성 번호 | Char. No. | Text | 20 | 필수 | 도면 풍선 번호 또는 관리계획서 번호 |
| CharType__c | 특성 유형 | Char. Type | Picklist | VARIABLE, ATTRIBUTE, VISUAL | 필수 | VISUAL은 한도견본(QMS-06-LMS) 연결 대상 |
| CustomerSymbol__c | 고객 기호 | Customer Symbol | Text | 20 |  | OEM 고유 기호 표기 |
| DisplayName__c | 표시명 | Display Name | Formula(Text) |  |  | 사용자 언어 표시명(ko → Name, zh → 중문·영문·이름, 그 외 → 영문·이름, CMN-00-I18N-001 BR-3) |
| EffectiveFrom__c | 적용 시작일 | Effective From | Date |  |  | ACTIVE면 필수 |
| EffectiveTo__c | 적용 종료일 | Effective To | Date |  |  | 새 버전 활성화 시 서비스가 닫는다 |
| ExternalKey__c | 외부 키 | External Key | Text | 80 | 외부 키 유일 | {ItemNo}-{CharNo}-{EffectiveFrom yyyymmdd}(시작일이 없으면 -DRAFT). 트리거가 설정 |
| Item__c | 품번 | Item | MasterDetail | → CMN_Item__c |  | 품번 읽기 권한만으로 특성 작성 가능(품번은 사내 공개 읽기 전용) |
| LSL__c | 하한 규격 | LSL | Number | 18,6 |  | 계량형이면 USL·LSL 중 1개 이상(편측 허용) |
| NameEn__c | 영문명 | English Name | Text | 80 |  | 영문 표시명(CMN-00-I18N-001) |
| NameZh__c | 중문명 | Chinese Name | Text | 80 |  | 중문 표시명(CMN-00-I18N-001) |
| Nominal__c | 기준값 | Nominal | Number | 18,6 |  |  |
| SpcRequired__c | SPC 대상 | SPC Required | Checkbox |  |  |  |
| SpecialClass__c | 특별특성 | Special Class | Picklist | NONE, CC, SC | 필수 | CC = 안전·법규, SC = 기능·성능 핵심 |
| Status__c | 상태 | Status | Picklist | DRAFT, ACTIVE, OBSOLETE |  | DRAFT → ACTIVE(활성화) → OBSOLETE(새 버전 활성화 시). CMN_CharacteristicService만 변경. 명세 필수는 기본값 + 검증 규칙 |
| TargetCpk__c | 목표 Cpk | Target Cpk | Number | 4,2 |  | 비면 저장 전에 CC 1.67, 그 외 1.33(BR-2) |
| USL__c | 상한 규격 | USL | Number | 18,6 |  | 계량형이면 USL·LSL 중 1개 이상(편측 허용) |
| Unit__c | 단위 | Unit | Picklist | mm, um, deg, N, Nm, cd, lx, lm, V, A, mA, %, cc/min, ETC |  | 계량형이면 필수. lm·cc/min·mA는 데모 보강(CR-6) |

### CMN_CodeGroup__c

코드 그룹 / Code Group. 코드 그룹(DEFECT_TYPE, CAUSE_5M1E, DOC_CLASS …). 현업이 추가·변경하고 계층·다국어·SAP 매핑이 필요한 분류. 개발자가 정하는 상태값은 Picklist(Global Value Set)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Description__c | 설명 | Description | Text | 255 |  | 용도·관리 주체(예: DEV_ACTIVITY_TYPE은 품질경영팀 + PMO) |
| DisplayName__c | 표시명 | Display Name | Formula(Text) |  |  | 사용자 언어 표시명(ko → Name, zh → 중문·영문·이름, 그 외 → 영문·이름, CMN-00-I18N-001 BR-3) |
| GroupCode__c | 그룹 코드 | Group Code | Text | 40 | 필수 외부 키 유일 |  |
| MaxLevel__c | 최대 단계 | Max Level | Number | 1,0 | 필수 | 1~4(BR-2) |
| NameEn__c | 영문명 | English Name | Text | 80 |  | 영문 표시명(CMN-00-I18N-001) |
| NameZh__c | 중문명 | Chinese Name | Text | 80 |  | 중문 표시명(CMN-00-I18N-001) |

### CMN_Code__c

공통 코드 / Code. 계층형 공통 코드. Level·ExternalKey(그룹/코드 경로 전체)·Path(이름 경로)는 트리거가 만든다. 업무 레코드는 리프 Lookup 1개 + Path 사본을 저장. 참조 중 코드는 삭제 금지(BR-1)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Attribute1__c | 속성 1 | Attribute 1 | Text | 255 |  | 그룹별 확장 속성(예: SAP 결함 코드, DEFECT_TYPE = SAFETY, GAUGE_TYPE 교정 주기) |
| Attribute2__c | 속성 2 | Attribute 2 | Text | 255 |  | 그룹별 확장 속성(예: DOC_CLASS INDEX_SCOPE) |
| Attribute3__c | 속성 3 | Attribute 3 | Text | 255 |  |  |
| CodeGroup__c | 코드 그룹 | Code Group | MasterDetail | → CMN_CodeGroup__c |  |  |
| Code__c | 코드 | Code | Text | 40 | 필수 |  |
| DisplayName__c | 표시명 | Display Name | Formula(Text) |  |  | 사용자 언어 표시명(ko → Name, zh → 중문·영문·이름, 그 외 → 영문·이름, CMN-00-I18N-001 BR-3) |
| ExternalKey__c | 외부 키 | External Key | Text | 255 | 외부 키 유일 | {GroupCode}/{상위 코드…}/{Code} 경로 전체(데모 보강 CR — 명세 {GroupCode}/{Code}는 단계가 다른 같은 코드가 충돌). 트리거가 설정 |
| IsActive__c | 사용 | Active | Checkbox |  |  | 비활성 코드와 그 하위는 피커에 나오지 않는다(AC-3) |
| Level__c | 단계 | Level | Number | 1,0 |  | Parent.Level + 1(트리거). 그룹 최대 단계 이하(BR-2) |
| NameEn__c | 영문명 | English Name | Text | 80 |  | 영어 사용자 표시명. 비면 Name(AC-1) |
| NameZh__c | 중문명 | Chinese Name | Text | 80 |  | 중국어 사용자 표시명. 비면 Name |
| Parent__c | 상위 코드 | Parent Code | Lookup | → CMN_Code__c |  | 같은 그룹. 2단계 이상이면 필수(상위 없으면 1단계) |
| Path__c | 경로 | Path | Text | 255 |  | "외관 > 이물 > 렌즈 내부" 자동 |
| SortOrder__c | 정렬 순서 | Sort Order | Number | 4,0 |  |  |

### CMN_Comment__c

코멘트 / Comment. 코멘트(UX-003). 부모 레코드 접근을 따른다(조회 Apex가 UserRecordAccess 확인). OWD Private, Owner = 작성자. 작성자 본인만 24시간 내 수정·삭제

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Body__c | 본문 | Body | LongTextArea | 32768 |  | 일반 텍스트(@멘션 표기 포함). Long Text Area는 DB 필수 지정 불가라 트리거가 필수 확인 |
| IsEdited__c | 수정됨 | Edited | Checkbox |  |  |  |
| MentionedUserIds__c | 멘션 사용자 | Mentioned Users | LongTextArea | 1000 |  | 사용자 Id(쉼표). 명세 Text(1000)은 Text 최대 255라 Long Text Area(1000) |
| ParentObject__c | 대상 객체 | Parent Object | Text | 80 | 필수 | 트리거가 ParentRecordId에서 채운다 |
| ParentRecordId__c | 대상 레코드 | Parent Record | Text | 18 | 필수 |  |

### CMN_Company__c

법인 / Company. 법인(SAP 회사 코드). 공장의 주종 상위. 마스터 OWD Public Read Only(SEC-002 BR-1). 삭제 금지(BR-2)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| CompanyCode__c | 법인 코드 | Company Code | Text | 10 | 필수 외부 키 유일 | SAP 회사 코드 |
| Country__c | 국가 | Country | Picklist | KR, US, CN, IN, PL, BR, MX, DE, JP, VN, CZ, SK, HU, FR, IT, ES, GB, CA, TR, SE | 필수 | ISO 3166 alpha-2. 사업장·고객 국가 위주로 두고 필요 시 값 추가 |
| DisplayName__c | 표시명 | Display Name | Formula(Text) |  |  | 사용자 언어 표시명(ko → Name, zh → 중문·영문·이름, 그 외 → 영문·이름, CMN-00-I18N-001 BR-3) |
| IsActive__c | 사용 | Active | Checkbox |  |  | BR-2: 삭제 대신 비활성화(이력 레코드가 참조) |
| NameEn__c | 영문명 | English Name | Text | 80 |  | 영문 표시명(CMN-00-I18N-001) |
| NameZh__c | 중문명 | Chinese Name | Text | 80 |  | 중문 표시명(CMN-00-I18N-001) |

### CMN_Delegation__c

결재 위임 / Approval Delegation. 대리결재 위임(APV-004). 위임자 본인 또는 부서장이 등록. 대결은 1단계만(대리인의 위임은 전달되지 않음)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Delegate__c | 대리인 | Delegate | Lookup | → User |  |  |
| Delegator__c | 위임자 | Delegator | Lookup | → User |  | 부재자. 필수는 트리거 확인(User Lookup은 필수 지정 불가) |
| EndAt__c | 종료 | End | DateTime |  | 필수 |  |
| ExternalKey__c | 외부 키 | External Key | Text | 80 | 외부 키 유일 | DLG-{위임자 사번}-{시작일 yyyyMMdd}(데모·이관, 개발 플랜 CR-6). 비우면 트리거가 채운다 |
| IsActiveNow__c | 현재 유효 | Active Now | Formula(Checkbox) |  |  |  |
| Reason__c | 사유 | Reason | Text | 255 | 필수 |  |
| StartAt__c | 시작 | Start | DateTime |  | 필수 |  |
| TypeCodes__c | 결재 유형 | Approval Types | LongTextArea | 1000 |  | 공란 = 전체, 지정 시 쉼표 구분 TypeCode. 명세 Text(1000)은 Text 최대 255라 Long Text Area(1000) |

### CMN_DeleteLog__c

삭제 기록 / Delete Log. 삭제 기록(SEC-003 BR-2). 삭제 직전 레코드 JSON 스냅숏. 삭제 통제 서비스만 만들고 누구도 수정·삭제할 수 없다(트리거가 막음, 권한은 읽기만)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| DeletedAt__c | 삭제 일시 | Deleted At | DateTime |  | 필수 |  |
| DeletedBy__c | 삭제자 | Deleted By | Lookup | → User |  | 명세 필수: User 조회는 Restrict를 쓸 수 없고 필수 조회는 SetNull이 안 돼 DB 필수 대신 서비스가 항상 채움(사용자는 삭제되지 않음) |
| ObjectApiName__c | 객체 | Object | Text | 80 | 필수 |  |
| Reason__c | 삭제 사유 | Reason | Text | 255 |  | UI에서 입력한 경우(CMN_DeleteGuardService.setReason) |
| RecordIdText__c | 레코드 Id | Record Id | Text | 18 | 필수 |  |
| RecordNo__c | 업무 번호 | Record No. | Text | 40 |  | 업무 번호(있으면) |
| Snapshot__c | 스냅숏 | Snapshot | LongTextArea | 131072 |  | 삭제 직전 레코드 JSON(전 필드). 명세 필수: 긴 텍스트는 DB 필수 대신 서비스가 항상 채움 |

### CMN_Department__c

부서 / Department. 부서(HR 부서 ID). 결재선(팀장)·귀책 부서·CFT·공장 권한의 근거. FullPath는 저장 시 자신, 하위는 비동기(CMN_DepartmentPathJob)로 계산. 삭제 금지(BR-1)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| DeptCode__c | 부서 코드 | Department Code | Text | 20 | 필수 외부 키 유일 | HR 부서 ID |
| DisplayName__c | 표시명 | Display Name | Formula(Text) |  |  | 사용자 언어 표시명(ko → Name, zh → 중문·영문·이름, 그 외 → 영문·이름, CMN-00-I18N-001 BR-3) |
| FullPath__c | 전체 경로 | Full Path | Text | 255 |  | "SL > 품질본부 > 품질경영팀". 상위 체인 최대 8단계(넘으면 앞을 …로 줄임). 트리거·CMN_DepartmentPathJob이 계산 |
| IsActive__c | 사용 | Active | Checkbox |  |  | 폐지 부서는 false(삭제 금지, BR-1) |
| Manager__c | 부서장 | Manager | Lookup | → User |  | 부서장(팀장). 결재 Role 해석에 사용 |
| NameEn__c | 영문명 | English Name | Text | 80 |  | 영문 표시명(CMN-00-I18N-001) |
| NameZh__c | 중문명 | Chinese Name | Text | 80 |  | 중문 표시명(CMN-00-I18N-001) |
| Parent__c | 상위 부서 | Parent Department | Lookup | → CMN_Department__c |  | 순환 참조 금지(BR-2). 자기 참조 조회는 Restrict를 쓸 수 없다(부서는 삭제 금지라 영향 없음) |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  | 소속 공장(본사 부서는 공란) |

### CMN_DocTemplate__c

문서 양식 / Document Template. 표준 양식(DOC-001 BR-7, P-36). 사용자 언어 → en_US → ko 순으로 찾는다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| ContentDocumentId__c | 파일 Id | File Id | Text | 18 | 필수 |  |
| DocClass__c | 문서 분류 | Document Class | Lookup | → CMN_Code__c | 필수 |  |
| IsActive__c | 사용 | Active | Checkbox |  |  |  |
| Language__c | 언어 | Language | Picklist | ko, en_US, zh_CN, pl, es, pt_BR | 필수 |  |
| Version__c | 버전 | Version | Number | 4,0 |  |  |

### CMN_DocumentRevision__c

문서 리비전 / Document Revision. 문서 리비전(DOC-001). RELEASED는 파일·링크 변경 불가, 새 RELEASED가 나오면 이전 RELEASED는 SUPERSEDED(BR-2). 상태는 CMN_DocumentService만 바꾼다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| AiChangeSummary__c | AI 변경 요약 | AI Change Summary | LongTextArea | 32768 |  | AI-003이 채움 |
| ChangeNote__c | 변경 사유 | Change Note | LongTextArea | 1000 |  | 명세 Text(1000) → Long Text Area(1000)(Text 최대 255) |
| ContentDocumentId__c | 파일 Id | File Id | Text | 18 |  |  |
| Document__c | 문서 | Document | MasterDetail | → CMN_Document__c |  |  |
| DuplicateOfRevision__c | 원본 리비전 | Original Revision | Lookup | → CMN_DocumentRevision__c |  |  |
| ExternalKey__c | 외부 키 | External Key | Text | 120 | 외부 키 유일 | 데모·이관 업서트 키(CR-6) |
| ExternalRef__c | 외부 문서 번호 | External Ref | Text | 255 |  | 외부 저장소 키(도면 번호 등). 명세 ExternalKey__c를 데모 업서트 키와 구분해 이름 변경(CR-6) |
| ExternalUrl__c | 외부 링크 | External URL | Url |  |  |  |
| FileHash__c | 파일 해시 | File Hash | Text | 64 |  | 플랫폼 체크섬(ContentVersion.Checksum, MD5). 50MB 파일 SHA-256은 Apex 힙 한도로 계산 불가 |
| FileName__c | 파일명 | File Name | Text | 255 |  |  |
| FileSize__c | 파일 크기(바이트) | File Size (bytes) | Number | 12,0 |  |  |
| IndexStatus__c | 색인 상태 | Index Status | Picklist | PENDING, INDEXED, FAILED, EXCLUDED | 필수 |  |
| IsDuplicateFile__c | 중복 파일 | Duplicate File | Checkbox |  |  | BR-5: 같은 해시가 다른 부모 레코드에 있음(차단하지 않음) |
| ReleasedAt__c | 공개 일시 | Released At | DateTime |  |  | RELEASED 된 시각(Vol.6c 공개일 기준) |
| RevisionNo__c | 리비전 번호 | Revision No. | Number | 4,0 | 필수 |  |
| Status__c | 상태 | Status | Picklist | DRAFT, IN_APPROVAL, RELEASED, SUPERSEDED, REJECTED | 필수 |  |
| StorageType__c | 저장소 | Storage | Picklist | SF_FILE, SHAREPOINT, PDM, DMS, URL, SF_RECORD | 필수 |  |

### CMN_Document__c

문서 / Document. 업무 레코드에 붙은 리비전 관리 문서(DOC-001). 같은 부모·같은 DocClass = 한 문서, 다시 올리면 새 리비전(BR-1). 공유는 공장·협력사(SEC-002) + 조회 시 부모 접근 확인(BR-6)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| CurrentRevision__c | 현재 리비전 | Current Revision | Lookup | → CMN_DocumentRevision__c |  | 최신 RELEASED 리비전 |
| DeliverableType__c | 산출물 유형 | Deliverable Type | Picklist | ATTACHMENT, STD_FORM, LINK, APPROVAL, SYSTEM_LINK | 필수 |  |
| DocClass__c | 문서 분류 | Document Class | Lookup | → CMN_Code__c | 필수 | 코드 그룹 DOC_CLASS(트리거 확인) |
| ExternalKey__c | 외부 키 | External Key | Text | 120 | 외부 키 유일 | 데모·이관 업서트 키(개발 플랜 CR-6) |
| ParentObject__c | 소속 객체 | Parent Object | Text | 80 | 필수 |  |
| ParentRecordId__c | 소속 레코드 | Parent Record | Text | 18 | 필수 |  |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  | 공유 기준(부모에서 복사) |
| SupplierVisible__c | 협력사 공개 | Visible to Supplier | Checkbox |  |  | 검토 반영 Vol.3: 파일 링크 Visibility = AllUsers |
| Supplier__c | 협력사 | Supplier | Lookup | → Account |  | 검토 반영 Vol.3: 협력사 공유 기준 |

### CMN_Employee__c

임직원 / Employee. 임직원(INT-002, HR 연계). 전 임직원을 동기화하고 라이선스 사용자는 User__c로 연결(사번 일치 시 자동). 성명·사번·부서·직급·메일 외 개인정보는 받지 않는다(BR-4)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Department__c | 부서 | Department | Lookup | → CMN_Department__c | 필수 |  |
| Email__c | 메일 | Email | Email |  |  |  |
| EmployeeNo__c | 사번 | Employee No. | Text | 20 | 필수 외부 키 유일 |  |
| HrStatus__c | 재직 상태 | HR Status | Picklist | ACTIVE, LEAVE, RETIRED | 필수 |  |
| JobGradeCode__c | 직급 코드 | Job Grade | Text | 10 |  |  |
| NameEn__c | 영문 성명 | English Name | Text | 80 |  |  |
| User__c | 사용자 | User | Lookup | → User |  | 라이선스 사용자. 비우면 같은 사번의 사용자를 트리거가 연결 |

### CMN_InboundReceipt__c

수신 영수 / Inbound Receipt. 결과 수신 영수(DWH-003 BR-3·BR-4). 이벤트 1건 = 1건, 외부 이벤트 Id 유일로 중복 수신을 거른다(멱등). 미등록 유형은 UNROUTED, 핸들러 실패는 FAILED + 관리자 재처리(재처리에 쓰려고 원문 Payload를 보관한다). 상태는 수신 서비스만 바꾼다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| AttemptCount__c | 처리 횟수 | Attempts | Number | 3,0 |  | 첫 처리 1, 관리자 재처리마다 1씩 더한다(명세 보충) |
| ErrorMessage__c | 오류 내용 | Error Message | LongTextArea | 32768 |  | FAILED·UNROUTED 사유(명세 보충). 개인정보·비용 원문은 남기지 않는다 |
| EventType__c | 이벤트 유형 | Event Type | Text | 80 | 필수 |  |
| ExternalEventId__c | 외부 이벤트 Id | External Event Id | Text | 255 | 필수 외부 키 유일 | 원천의 결정적 Id. 같은 Id가 다시 오면 핸들러를 실행하지 않는다(AC-1) |
| PayloadJson__c | 수신 원문 | Payload JSON | LongTextArea | 131072 |  | 재처리용 원문(BR-4, 명세 보충). 운영 데이터 보존 기간 표(결정 O-2)에 따라 정리 |
| ProcessedAt__c | 처리 시각 | Processed At | DateTime |  |  |  |
| ResultRecordId__c | 결과 레코드 Id | Result Record Id | Text | 18 |  | 핸들러가 만들거나 고친 대표 레코드 |
| Status__c | 처리 상태 | Status | Picklist | RECEIVED, PROCESSED, UNROUTED, FAILED | 필수 | RECEIVED는 처리 중(같은 트랜잭션에서 결과 상태로 바뀐다) |

### CMN_InterfaceLog__c

연계 로그 / Interface Log. 연계 실행 로그(INT-001 BR-4). 배치 1회 = 1건(Mule이 기록). 외부 키 = {InterfaceId}:{CorrelationId}로 같은 실행은 갱신. FAILED면 시스템 관리자에게 알림(BR-3)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| CorrelationId__c | 상관 ID | Correlation Id | Text | 64 | 필수 | Mule x-correlation-id |
| EndedAt__c | 종료 | Ended At | DateTime |  | 필수 |  |
| ErrorCount__c | 오류 건수 | Errors | Number | 10,0 | 필수 |  |
| ErrorSummary__c | 오류 요약 | Error Summary | LongTextArea | 32768 |  | 실패 레코드 키·사유(최대 100건) |
| ExternalKey__c | 외부 키 | External Key | Text | 90 | 외부 키 유일 | {InterfaceId}:{CorrelationId}. 비우면 트리거가 채운다(같은 실행 재전송 시 갱신 = 멱등) |
| InterfaceId__c | 인터페이스 | Interface | Text | 20 | 필수 |  |
| IsRecent__c | 최근 24시간 | Last 24 Hours | Formula(Checkbox) |  |  |  |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  | AC-3 공장별 조회(공장 단위 인터페이스만) |
| RecordCount__c | 처리 건수 | Records | Number | 10,0 | 필수 |  |
| StartedAt__c | 시작 | Started At | DateTime |  | 필수 |  |
| Status__c | 결과 | Status | Picklist | SUCCESS, PARTIAL, FAILED | 필수 |  |

### CMN_ItemPlant__c

공장별 품번 / Item Plant. 품번 × 공장(공장별 사용 여부). ExternalKey = {ItemNo}-{PlantCode}(트리거). 삭제 대신 Status PHASE_OUT

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| ExternalKey__c | 외부 키 | External Key | Text | 60 | 외부 키 유일 | {ItemNo}-{PlantCode}. 트리거가 설정 |
| Item__c | 품번 | Item | MasterDetail | → CMN_Item__c |  |  |
| Plant__c | 공장 | Plant | MasterDetail | → CMN_Plant__c |  |  |
| Status__c | 상태 | Status | Picklist | ACTIVE, PHASE_OUT | 필수 |  |

### CMN_ItemVehicle__c

적용 차종 / Item Vehicle. 품번 × 차종(적용 차종). ExternalKey = {ItemNo}-{차종 외부 키}(트리거). 차량당 사용 수량은 Vol.5 B2B-003 요청

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| ExternalKey__c | 외부 키 | External Key | Text | 100 | 외부 키 유일 | {ItemNo}-{OemCode}-{VehicleCode}. 트리거가 설정(데모 보강) |
| Item__c | 품번 | Item | MasterDetail | → CMN_Item__c |  |  |
| UsagePerVehicle__c | 차량당 사용 수량 | Usage per Vehicle | Number | 4,0 |  | 차량당 사용 수량, 기본 1(Vol.5 B2B-003 BR-1 요청) |
| Vehicle__c | 차종 | Vehicle | MasterDetail | → CMN_Vehicle__c |  |  |

### CMN_Item__c

품번 / Item. 품번(SAP 자재번호). 완제품~구매부품 한 체계. 부적합·인정시험·Re-PPAP·SPC 특성이 매달린다. BOM은 저장하지 않음(Snowflake CORE.SAP_BOM, BR-2)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| CustomerPartNo__c | 고객 품번 | Customer Part No. | Text | 40 |  |  |
| Customer__c | 고객 | Customer | Lookup | → Account |  | FG만 필수(BR-1). 고객 레코드타입만(조회 필터 — 레코드타입 라벨 "고객"으로 비교) |
| DisplayName__c | 표시명 | Display Name | Formula(Text) |  |  | 사용자 언어 표시명(ko → Name, zh → 중문·영문·이름, 그 외 → 영문·이름, CMN-00-I18N-001 BR-3) |
| DrawingNo__c | 도면 번호 | Drawing No. | Text | 40 |  | PDM 도면 번호 |
| DrawingRev__c | 도면 리비전 | Drawing Rev. | Text | 10 |  | PDM 도면 리비전 |
| IsActive__c | 사용 | Active | Checkbox |  |  | 삭제 대신 비활성화(기준정보) |
| ItemNo__c | 품번 | Item No. | Text | 40 | 필수 외부 키 유일 | SAP 자재번호. SAP 동기화 upsert 키(AC-1) |
| ItemType__c | 품목 유형 | Item Type | Picklist | FG, SFG, PART, RAW | 필수 |  |
| NameEn__c | 영문명 | English Name | Text | 80 |  | 영문 표시명(CMN-00-I18N-001) |
| NameZh__c | 중문명 | Chinese Name | Text | 80 |  | 중문 표시명(CMN-00-I18N-001) |
| PartCategory__c | 부품 분류 | Part Category | Picklist | LENS, HOUSING, LED_MODULE, REFLECTOR, BEZEL, CONNECTOR, PCB, ACTUATOR, ETC |  | LELE·수평전개 유사도 키 |
| ProductGroup__c | 제품군 | Product Group | Lookup | → CMN_ProductGroup__c | 필수 |  |
| SpecialCharCount__c | 특별특성 수 | Special Characteristics | Roll-Up Summary |  |  | ACTIVE이면서 SpecialClass ≠ NONE인 특성 수(CMN-00-MDM-006에서 추가. 폐기 버전 중복을 막으려고 ACTIVE 조건 추가) |

### CMN_KpiValue__c

KPI 값 / KPI Value. Snowflake가 계산한 KPI 값(DWH-003 BR-1). Mule이 MART.V_SF_KPI_* 뷰를 읽어 외부 키로 upsert한다. 위젯 집계 단위만 적재하고 세부는 드릴다운(DWH-004), 13개월 초과 값은 삭제(Snowflake 보존, 결정 O-2). 사내 공개 읽기 전용·외부 비공개(Vol.7 요청) — 공장 필터는 위젯 데이터 서비스가 강제한다. Name은 트리거가 채운다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Characteristic__c | 특성 | Characteristic | Lookup | → CMN_Characteristic__c |  | 차원(SPC Cpk·Ppk) |
| Customer__c | 고객 | Customer | Lookup | → Account |  | 차원(고객 PPM·필드 클레임) |
| Department__c | 부서 | Department | Lookup | → CMN_Department__c |  | 차원(Vol.6b TRN-003 요청: 부서별 교육 계획 이행률). 외부 키 해시에 포함 |
| ExternalKey__c | 외부 키 | External Key | Text | 255 | 필수 외부 키 유일 | KPI·기간·차원 키 해시(Snowflake가 만든다, 재적재 멱등) |
| Item__c | 품번 | Item | Lookup | → CMN_Item__c |  | 차원 |
| KpiKey__c | KPI 키 | KPI Key | Text | 60 | 필수 | KPI 레지스트리 키. 예: QMS_PPM_CUSTOMER, QMS_SPC_CPK, QMS_SUPPLIER_PPM(interfaces.md KPI 이름 통일) |
| Line__c | 라인 | Line | Lookup | → CMN_Line__c |  | 차원 |
| PeriodStart__c | 기간 시작 | Period Start | Date |  | 필수 | 일 = 그날, 주 = 월요일, 월 = 1일, 분기 = 분기 첫날 |
| PeriodType__c | 기간 단위 | Period Type | Picklist | DAY, WEEK, MONTH, QUARTER | 필수 | QUARTER는 Vol.6c·Vol.7 요청(감사 반복률, 협력사 등급 수) |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  | 차원(해당하는 것만 채운다) |
| ProductGroup__c | 제품군 | Product Group | Lookup | → CMN_ProductGroup__c |  | 차원(Vol.7·Vol.8 요청: 제품군 위험 점수) |
| Rag__c | 신호 | RAG | Picklist | GREEN, AMBER, RED |  | Snowflake 공통 RAG 판정(MART.F_KPI_RAG). 판정 기준이 없는 KPI는 비운다 |
| Supplier__c | 협력사 | Supplier | Lookup | → Account |  | 차원(협력사 PPM·수입검사 합격률) |
| Target__c | 목표 | Target | Number | 18,6 |  |  |
| Unit__c | 단위 | Unit | Text | 20 |  | KPI 레지스트리 단위 코드: RATIO, CNT, PCT, PPM, R1000 |
| Value__c | 값 | Value | Number | 18,6 | 필수 |  |
| Vehicle__c | 차종 | Vehicle | Lookup | → CMN_Vehicle__c |  | 차원(Vol.5 B2B-003 요청: 차종별 필드 클레임 R/1000) |

### CMN_Line__c

라인 / Line. 생산 라인. ExternalKey = {PlantCode}-{LineCode}(트리거가 설정, BR-1). 제품군 Lookup은 MDM-004가 추가

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| DisplayName__c | 표시명 | Display Name | Formula(Text) |  |  | 사용자 언어 표시명(ko → Name, zh → 중문·영문·이름, 그 외 → 영문·이름, CMN-00-I18N-001 BR-3) |
| ExternalKey__c | 외부 키 | External Key | Text | 40 | 외부 키 유일 | {PlantCode}-{LineCode}. 사용자가 입력하지 않음(트리거가 설정). 명세 필수: DB 필수 대신 트리거로 보장 |
| IsActive__c | 사용 | Active | Checkbox |  |  | BR-2: 삭제 대신 비활성화(이력 레코드가 참조) |
| LineCode__c | 라인 코드 | Line Code | Text | 20 | 필수 | 같은 공장 안에서 유일(BR-1) |
| MesLineCode__c | MES 라인 코드 | MES Line Code | Text | 20 |  |  |
| NameEn__c | 영문명 | English Name | Text | 80 |  | 영문 표시명(CMN-00-I18N-001) |
| NameZh__c | 중문명 | Chinese Name | Text | 80 |  | 중문 표시명(CMN-00-I18N-001) |
| Plant__c | 공장 | Plant | MasterDetail | → CMN_Plant__c |  |  |
| ProductGroup__c | 주 생산 제품군 | Main Product Group | Lookup | → CMN_ProductGroup__c |  | 주 생산 제품군(CMN-00-MDM-004에서 추가) |

### CMN_LogSetting__c

로그 설정 / . 사용자·프로필별 최소 로그 수준(ARC-002). 값이 없으면 INFO.

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| MinLevel__c | Minimum Level |  | Text | 10 |  | ERROR, WARN, INFO, DEBUG 중 하나 |

### CMN_Log__c

로그 / Log. Apex 오류·경고 로그(CMN-00-ARC-002). CMN_LogEvent__e 구독 트리거가 생성한다. 조회는 CMN_PS_Admin_Ops만.

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Level__c | 수준 | Level | Picklist | ERROR, WARN, INFO, DEBUG | 필수 |  |
| Message__c | 메시지 | Message | LongTextArea | 32768 |  | 필수(로거가 항상 채움). 긴 텍스트는 DB 필수 지정 대신 코드에서 보장 |
| Payload__c | 상세(요청·응답·스택) | Payload | LongTextArea | 131072 |  |  |
| RecordId__c | 관련 레코드 | Related Record | Text | 18 |  |  |
| Source__c | 발생 위치 | Source | Text | 255 | 필수 | 클래스.메서드 |
| TransactionId__c | 트랜잭션 ID | Transaction ID | Text | 36 | 필수 | Request.getCurrent().getRequestId() |

### CMN_MeetingAttendee__c

참석자 / Attendee. 회의 참석자(MTG-001). 사내 사용자 또는 외부 메일 중 하나

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Attendance__c | 참석 여부 | Attendance | Picklist | UNKNOWN, ATTENDED, ABSENT |  |  |
| ExternalEmail__c | 외부 메일 | External Email | Email |  |  |  |
| Meeting__c | 회의 | Meeting | MasterDetail | → CMN_Meeting__c |  |  |
| Role__c | 역할 | Role | Picklist | CHAIR, REQUIRED, OPTIONAL | 필수 |  |
| User__c | 사용자 | User | Lookup | → User |  |  |

### CMN_Meeting__c

회의 / Meeting. 회의(MTG-001). 공지 → 회의록 → 후속 조치. 회의록 확정 후 수정 불가(정정은 코멘트). 공유: 공장 + 참석자

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Category__c | 회의 유형 | Meeting Type | Lookup | → CMN_Code__c | 필수 | 코드 그룹 MEETING_TYPE(트리거 확인) |
| EndAt__c | 종료 | End | DateTime |  | 필수 |  |
| IsRegular__c | 정기 회의 | Regular | Checkbox |  |  |  |
| Location__c | 장소 | Location | Text | 255 |  |  |
| MinutesConfirmedAt__c | 회의록 확정 일시 | Minutes Confirmed At | DateTime |  |  |  |
| Minutes__c | 회의록 | Minutes | Html | 131072 |  |  |
| NextMeeting__c | 다음 회차 | Next Meeting | Lookup | → CMN_Meeting__c |  | BR-4 자동 생성한 다음 회차(중복 생성 방지) |
| OnlineUrl__c | 온라인 회의 주소 | Online URL | Url |  |  |  |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  |  |
| Recurrence__c | 반복 | Recurrence | Picklist | NONE, WEEKLY, MONTHLY |  | BR-4 정기 회의 반복 규칙 |
| RelatedObject__c | 연관 객체 | Related Object | Text | 80 |  |  |
| RelatedRecordId__c | 연관 업무 | Related Record | Text | 18 |  |  |
| StartAt__c | 시작 | Start | DateTime |  | 필수 |  |
| Status__c | 상태 | Status | Picklist | SCHEDULED, HELD, MINUTES_DRAFT, MINUTES_CONFIRMED, CANCELLED | 필수 | MINUTES_CONFIRMED는 회의록 확정 서비스만(트리거가 직접 변경 차단) |

### CMN_NumberCounter__c

채번 카운터 / Number Counter. 채번 카운터. Key = {객체}/{범위}/{기간}. 채번 서비스가 FOR UPDATE로 잠그고 묶음 단위로 증가한다. 사용자 접근 없음(운영 조회만)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Key__c | 키 | Key | Text | 120 | 필수 외부 키 유일 | 예: QMS_Ncr__c/KR01/2027, 전사 연번은 범위 * |
| LastValue__c | 마지막 값 | Last Value | Number | 18,0 | 필수 |  |

### CMN_Operation__c

공정 / Operation. 공정. ExternalKey = {PlantCode}-{LineCode}-{OpCode}(트리거가 설정, 데모 보강 CR-6)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| DisplayName__c | 표시명 | Display Name | Formula(Text) |  |  | 사용자 언어 표시명(ko → Name, zh → 중문·영문·이름, 그 외 → 영문·이름, CMN-00-I18N-001 BR-3) |
| ExternalKey__c | 외부 키 | External Key | Text | 60 | 외부 키 유일 | {PlantCode}-{LineCode}-{OpCode}. 트리거가 설정(데모 보강 CR-6) |
| IsActive__c | 사용 | Active | Checkbox |  |  | BR-2: 삭제 대신 비활성화(이력 레코드가 참조) |
| Line__c | 라인 | Line | MasterDetail | → CMN_Line__c |  |  |
| NameEn__c | 영문명 | English Name | Text | 80 |  | 영문 표시명(CMN-00-I18N-001) |
| NameZh__c | 중문명 | Chinese Name | Text | 80 |  | 중문 표시명(CMN-00-I18N-001) |
| OpCode__c | 공정 코드 | Operation Code | Text | 20 | 필수 | 같은 라인 안에서 유일 |
| OperationType__c | 공정 유형 | Operation Type | Picklist | MOLDING, COATING, METALIZING, ASSEMBLY, LEAK_TEST, AIMING, EOL, OTHER | 필수 | 헤드램프 공정 분류 |
| Sequence__c | 공정 순서 | Sequence | Number | 4,0 | 필수 |  |

### CMN_Plant__c

공장 / Plant. 공장(SAP Plant). 데이터 격리·채번·권한의 단위. 시간대가 일 마감·채번 연도·SLA 기준(CMN_PlantService)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Company__c | 법인 | Company | MasterDetail | → CMN_Company__c |  |  |
| DefaultLanguage__c | 기본 언어 | Default Language | Picklist | ko, en_US, zh_CN, pl, es, pt_BR | 필수 | 현장 사용자 기본 언어 |
| DisplayName__c | 표시명 | Display Name | Formula(Text) |  |  | 사용자 언어 표시명(ko → Name, zh → 중문·영문·이름, 그 외 → 영문·이름, CMN-00-I18N-001 BR-3) |
| IsActive__c | 사용 | Active | Checkbox |  |  | BR-2: 삭제 대신 비활성화(이력 레코드가 참조) |
| MesSiteCode__c | MES 사이트 코드 | MES Site Code | Text | 20 |  |  |
| NameEn__c | 영문명 | English Name | Text | 80 |  | 영문 표시명(CMN-00-I18N-001) |
| NameZh__c | 중문명 | Chinese Name | Text | 80 |  | 중문 표시명(CMN-00-I18N-001) |
| PlantCode__c | 공장 코드 | Plant Code | Text | 10 | 필수 외부 키 유일 | SAP Plant. 권한(공장 그룹)·채번의 키 |
| Region__c | 권역 | Region | Picklist | KR, NA, CN, IN, EU, SA | 필수 |  |
| TimeZone__c | 시간대 | Time Zone | Picklist | Asia/Seoul, Asia/Shanghai, Asia/Kolkata, Asia/Ho_Chi_Minh, Asia/Tokyo, America/Chicago, America/New_York, America/Detroit, America/Los_Angeles, America/Mexico_City, America/Monterrey, America/Sao_Paulo, Europe/Warsaw, Europe/Berlin, Europe/Prague, Europe/Bratislava, Europe/Budapest, Europe/London, Europe/Paris, Europe/Istanbul | 필수 | TimeZoneSidKey 값. 일 마감·채번 연도·SLA 계산 기준 |

### CMN_ProductGroup__c

제품군 / Product Group. 제품군(LAMP, LAMP_HL, LAMP_RCL, EV, MIRROR, FEM 등). 2단계 계층. 삭제 금지

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| DisplayName__c | 표시명 | Display Name | Formula(Text) |  |  | 사용자 언어 표시명(ko → Name, zh → 중문·영문·이름, 그 외 → 영문·이름, CMN-00-I18N-001 BR-3) |
| GroupCode__c | 제품군 코드 | Group Code | Text | 20 | 필수 외부 키 유일 |  |
| IsActive__c | 사용 | Active | Checkbox |  |  | 삭제 대신 비활성화(기준정보) |
| NameEn__c | 영문명 | English Name | Text | 80 |  | 영문 표시명(CMN-00-I18N-001) |
| NameZh__c | 중문명 | Chinese Name | Text | 80 |  | 중문 표시명(CMN-00-I18N-001) |
| Parent__c | 상위 제품군 | Parent Group | Lookup | → CMN_ProductGroup__c |  | 2단계 계층(상위의 상위 금지) |

### CMN_RoleAssignment__c

결재 Role 배정 / Role Assignment. 결재 Role 배정(APV-002). Role(APPROVAL_ROLE 코드) × 공장(공란 = 전사) × 부서 × 사용자, 유효 기간. 결재선 Role 해석의 근거

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Department__c | 부서 | Department | Lookup | → CMN_Department__c |  |  |
| ExternalKey__c | 외부 키 | External Key | Text | 120 | 외부 키 유일 | RA-{Role}-{Plant 또는 ALL}-{사번}(부서가 있으면 -{부서 코드}). 데모 보강 CR-6 |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  | 공란 = 전사 |
| Role__c | 결재 Role | Approval Role | Lookup | → CMN_Code__c | 필수 | APPROVAL_ROLE 그룹 코드만(트리거 검증) |
| User__c | 사용자 | User | Lookup | → User |  | 명세 필수: User 조회는 필수로 만들 수 없어 트리거가 확인 |
| ValidFrom__c | 유효 시작 | Valid From | Date |  | 필수 |  |
| ValidTo__c | 유효 종료 | Valid To | Date |  |  |  |

### CMN_SupplierItem__c

협력사 품번 / Supplier Item. 협력사 × 품번 × 납품 공장. 수입검사 수준·부품 PPAP 승인 상태의 단위. ExternalKey = {VendorNo}-{ItemNo}-{PlantCode}(트리거). 상태 필드는 QMS-03 서비스만 변경

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| ExternalKey__c | 외부 키 | External Key | Text | 80 | 외부 키 유일 | {VendorNo}-{ItemNo}-{PlantCode}. 트리거가 설정(AC-1 중복 차단) |
| InspectionLevel__c | 수입검사 수준 | Inspection Level | Picklist | NORMAL, TIGHTENED, REDUCED, SKIP |  | 수입검사 수준. 기본 NORMAL. 변경 이력(BR-1). QMS-03-IQC 서비스만 변경(사용자 FLS 읽기) |
| Item__c | 품번 | Item | Lookup | → CMN_Item__c | 필수 |  |
| Plant__c | 납품 공장 | Delivery Plant | Lookup | → CMN_Plant__c | 필수 |  |
| PpapStatus__c | PPAP 상태 | PPAP Status | Picklist | NOT_SUBMITTED, INTERIM, APPROVED, REJECTED |  | 부품 PPAP 승인 상태. QMS-03 서비스만 변경(사용자 FLS 읽기, Vol.3 요청), 필드 이력. 명세 필수는 기본값 + 검증 규칙으로 보장(필수 필드는 FLS 읽기 전용이 될 수 없음) |
| Supplier__c | 협력사 | Supplier | MasterDetail | → Account |  | 협력사 레코드타입만(조회 필터 — 레코드타입 라벨 "협력사"로 비교). 포털 데이터 격리 단위 |

### CMN_TestRecordLine__c

테스트 라인 / Test Line. 테스트 전용 하위 객체(개발 플랜 DEV-3). 공통 편집 그리드(UX-006)의 행 객체 샘플. 탭·권한 없음(관리자·테스트만)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Category__c | 구분 | Category | Picklist | PLAN, CHECK, ACTION |  | PICKLIST 열 샘플 |
| Code__c | 코드 | Code | Lookup | → CMN_Code__c |  | CODE 열 샘플(MDM-007) |
| EndDate__c | 종료일 | End Date | Date |  |  | 일정 막대 종료 |
| IsDone__c | 완료 | Done | Checkbox |  |  | CHECKBOX 열 샘플. 완료 행은 삭제·일정 변경 불가(샘플 Provider) |
| LineNo__c | 순서 | Line No. | Number | 4,0 |  | 그리드 OrderField |
| Note__c | 비고 | Note | Text | 255 |  | TEXT 열 샘플. FLS 테스트(AC-6) |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  | LOOKUP 열 샘플 |
| Quantity__c | 수량 | Quantity | Number | 10,2 |  | NUMBER 열 샘플 |
| StartDate__c | 시작일 | Start Date | Date |  |  | 일정 막대 시작 |
| TestRecord__c | 테스트 레코드 | Test Record | MasterDetail | → CMN_TestRecord__c |  | 부모(그리드 ParentField) |

### CMN_TestRecord__c

테스트 레코드 / Test Record. 테스트 전용 객체(개발 플랜 DEV-3). 공통 기능(코드 참조 삭제 차단, 채번, 공유, 결재 …)의 AC를 업무 객체 없이 검증한다. 탭·권한 없음(관리자·테스트만). 필드는 공통 WI가 필요할 때 더한다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| ChecklistJson__c | 체크리스트 답 | Checklist Answers | LongTextArea | 131072 |  | 체크리스트 수행 화면(UX-009) 샘플 Provider가 질문별 답을 JSON 묶음으로 저장 |
| Code__c | 코드 | Code | Lookup | → CMN_Code__c |  | MDM-007 AC-2(참조 중 코드 삭제 차단). 업무 객체처럼 리프 코드 Lookup |
| DaysToDue__c | 남은 일수 | Days to Due | Formula(Number) | 6,0 |  | D-day(UX-004 BR-4): 기한 - 오늘. 음수면 기한 경과 |
| DueDate__c | 기한 | Due Date | Date |  |  | 업무 레코드 표준(UX-004) 샘플: 기한 |
| EntryJson__c | 현장 입력 값 | Field Entry Values | LongTextArea | 131072 |  | 현장 입력 셸(UX-008) 샘플 Provider가 항목·시료 값을 JSON 묶음으로 저장(시료마다 레코드를 만들지 않는다) |
| EntryResult__c | 현장 입력 판정 | Field Entry Result | Text | 20 |  | 현장 입력 최종 판정(PASS·FAIL·INCOMPLETE, UX-008 샘플) |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  | 채번·공장 공유 검증(ARC-003, SEC-002) |
| RecordNo__c | 번호 | Record No. | Text | 40 | 외부 키 유일 | 채번 서비스가 발행(ARC-003). 업무 객체의 RecordNo__c와 같은 규칙 |
| Status__c | 상태 | Status | Text | 40 |  | 삭제 통제 검증(SEC-003, DRAFT만 삭제) |
| Supplier__c | 협력사 | Supplier | Lookup | → Account |  | 협력사 공유 검증(SEC-002 BR-4) |

### CMN_Todo__c

To-Do / To-Do. 통합 To-Do(TDO-001). Owner = Assignee, OWD Private(본인만). 사람에게 일을 시키는 모든 기능은 CMN_TodoService로 만든다. ExternalKey = {SourceType}/{SourceRecordId}/{AssigneeId}

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Assignee__c | 처리자 | Assignee | Lookup | → User |  | Owner도 처리자. 포털 사용자 허용(검토 반영 Vol.3). 명세 필수는 서비스가 보장 |
| Category__c | 구분 | Category | Picklist | TASK, APPROVAL | 필수 |  |
| CompletedAt__c | 완료 일시 | Completed At | DateTime |  |  |  |
| DelegatedFrom__c | 위임자 | Delegated From | Lookup | → User |  |  |
| DueDate__c | 기한 | Due Date | Date |  |  | 공장 시간대 기준 |
| ExternalKey__c | 외부 키 | External Key | Text | 120 | 외부 키 유일 | {SourceType}/{SourceRecordId}/{AssigneeId}(데모·이관은 토큰 치환) |
| IsDelegated__c | 대결 | Delegated | Checkbox |  |  |  |
| IsOverdue__c | 기한 초과 | Overdue | Formula(Checkbox) |  |  |  |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c |  |  |
| RecordNo__c | 업무 번호 | Record No. | Text | 40 |  |  |
| SourceObject__c | 원천 객체 | Source Object | Text | 80 | 필수 |  |
| SourceRecordId__c | 원천 레코드 | Source Record | Text | 18 | 필수 |  |
| SourceType__c | 원천 유형 | Source Type | Text | 80 | 필수 | 예: CMN_APPROVAL, QMS_NCR_COUNTERMEASURE |
| Status__c | 상태 | Status | Picklist | OPEN, DONE, CANCELLED |  |  |
| System__c | 시스템 | System | Picklist | QMS, PMS, CMN | 필수 |  |
| TargetRecordId__c | 업무 레코드 | Target Record | Text | 18 | 필수 | 클릭 시 열 업무 레코드 |
| TitleFallback__c | 기본 제목 | Title Fallback | Text | 255 | 필수 | 생성 시점 기본 언어 렌더링(검색·리포트) |
| TitleLabel__c | 제목 라벨 | Title Label | Text | 80 | 필수 | Custom Label 이름 |
| TitleParams__c | 제목 치환값 | Title Params | LongTextArea | 1000 |  | JSON 배열({0}…) 또는 객체({key}). 명세 Text(1000)은 Text 최대 255라 Long Text Area(1000) |

### CMN_UserDashboard__c

사용자 대시보드 / User Dashboard. 사용자별 대시보드 배치(DSH-001). 사용자·시스템당 1건(UniqueKey = 사용자Id:시스템). OWD Private, Owner = 사용자. 저장은 CMN_DashboardService(사용자 모드)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| LayoutJson__c | 배치 | Layout | LongTextArea | 32768 |  | [{widgetKey, size, order, config}] |
| SourceTemplate__c | 시작 템플릿 | Source Template | Text | 80 |  |  |
| System__c | 시스템 | System | Picklist | QMS, PMS | 필수 |  |
| UniqueKey__c | 고유 키 | Unique Key | Text | 40 | 외부 키 유일 | {UserId}:{System}. 서비스가 채운다(사용자 모드 저장이라 편집 FLS 필요) |
| User__c | 사용자 | User | Lookup | → User |  | 필수는 서비스 확인(User Lookup은 필수 지정 불가) |

### CMN_UserPlantAccess__c

공장 접근 / Plant Access. 사용자별 공장 접근(SEC-002). 생성·삭제·수준 변경 시 공장 그룹(CMN_GRP_PLANT_{코드}_R/_E) 구성원을 비동기로 맞춘다(BR-2). ExternalKey = {EmployeeNo}-{PlantCode}

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| AccessLevel__c | 접근 수준 | Access Level | Picklist | Read, Edit | 필수 |  |
| ExternalKey__c | 외부 키 | External Key | Text | 40 | 외부 키 유일 | {EmployeeNo}-{PlantCode}(사번이 없으면 사용자 Id). 트리거가 설정 |
| Plant__c | 공장 | Plant | Lookup | → CMN_Plant__c | 필수 |  |
| User__c | 사용자 | User | Lookup | → User |  | 명세 필수: User 조회는 필수(삭제 제한)로 만들 수 없어 트리거가 확인 |

### CMN_Vehicle__c

차종 / Vehicle. 고객 차종. ExternalKey = {OemCode}-{VehicleCode}(트리거가 설정). LELE 추천 1순위 매칭 키. 삭제 금지(기준정보)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Customer__c | 고객 | Customer | Lookup | → Account | 필수 | 고객 RecordType만(조회 필터, BR-1·AC-1) |
| DisplayName__c | 표시명 | Display Name | Formula(Text) |  |  | 사용자 언어 표시명(ko → Name, zh → 중문·영문·이름, 그 외 → 영문·이름, CMN-00-I18N-001 BR-3) |
| EopDate__c | 양산 종료 | EOP | Date |  |  |  |
| ExternalKey__c | 외부 키 | External Key | Text | 40 | 외부 키 유일 | {OemCode}-{VehicleCode}. 트리거가 설정(명세 필수: DB 필수 대신 트리거로 보장) |
| IsActive__c | 사용 | Active | Checkbox |  |  | 삭제 대신 비활성화(기준정보) |
| NameEn__c | 영문명 | English Name | Text | 80 |  | 영문 표시명(CMN-00-I18N-001) |
| NameZh__c | 중문명 | Chinese Name | Text | 80 |  | 중문 표시명(CMN-00-I18N-001) |
| SopDate__c | 양산 시작 | SOP | Date |  |  |  |
| VehicleCode__c | 차종 코드 | Vehicle Code | Text | 20 | 필수 | 고객 차종 코드. 같은 고객 안에서 유일 |

## 표준 객체 확장

| 객체 | 라벨(ko) | Label(en) | 필드 수 | 소유 WI |
| --- | --- | --- | --- | --- |
| [Account](#account) | 거래처(고객·협력사) | Account | 16 | CMN-00-MDM-003, CMN-00-MDM-005 |
| [User](#user) | 사용자 | User | 6 | CMN-00-MDM-001 |

### Account

거래처(고객·협력사) / Account. 고객(RecordType CMN_Customer)과 CSR 필드. 협력사 RecordType·필드는 MDM-005

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| AuditStandard__c | 고객 감사 기준 | Audit Standard | MultiselectPicklist | VDA63, IATF16949, CUSTOMER_SPECIFIC |  |  |
| ChangeNoticeLeadDays__c | 4M 사전 통보 기한(일) | Change Notice Lead Days | Number | 3,0 |  | 4M 변경 사전 통보·승인 기한 일수(Vol.6a 4MC-001·005 요청). CSR |
| ClaimFormTemplate__c | 클레임 회신 양식 | Claim Form Template | Picklist | STD_8D, BMW_8D, HKMC_6PI, GM_PRR, FORD_GSDB |  | 기본 클레임 회신 양식(값은 SL 확인 후 확정 — 오픈 이슈) |
| ConcessionCustomerApproval__c | 특채 고객 승인 필요 | Concession Needs Customer Approval | Checkbox |  |  | 특채 시 고객 승인 필요(Vol.6a NCR-003 BR-5 요청). CSR |
| ContainmentDueDays__c | 임시조치 회신 기한(일) | Containment Due Days | Number | 3,0 |  | 클레임 임시조치(D3) 회신 기한. 비면 CMN 설정 CMN_CSR_CONTAINMENT_DUE_DAYS(1일) |
| CustomerGroup__c | OEM 그룹 | OEM Group | Picklist | HKMC, BMW, GM, FORD, STELLANTIS, RENAULT, CN_LOCAL, OTHER |  | 고객 RecordType에서 필수(검증 규칙) |
| EightDDueDays__c | 8D 회신 기한(일) | 8D Due Days | Number | 3,0 |  | 8D 최종 회신 기한. 비면 CMN 설정 CMN_CSR_8D_DUE_DAYS(30일) |
| IatfCertified__c | IATF 16949 인증 | IATF 16949 Certified | Checkbox |  |  |  |
| IatfExpiry__c | IATF 인증 만료일 | IATF Expiry | Date |  |  |  |
| OemCode__c | 고객 코드 | OEM Code | Text | 20 | 외부 키 유일 | 고객 코드. 고객 RecordType에서 필수(검증 규칙), 차종 외부 키의 앞부분이라 만든 뒤 바꾸지 않는다 |
| PortalEnabled__c | 협력사 포털 사용 | Portal Enabled | Checkbox |  |  | 협력사 포털 사용 여부. 협력사 하위 Contact만 포털 사용자로 활성화(BR-2, QMS-03-SPP) |
| PpapDefaultLevel__c | 기본 PPAP 레벨 | Default PPAP Level | Picklist | 1, 2, 3, 4, 5 |  | 기본 PPAP 제출 레벨. 고객 RecordType 기본값 3 |
| RootCauseDueDays__c | 원인 회신 기한(일) | Root Cause Due Days | Number | 3,0 |  | 원인 회신 기한(Vol.5 CLM-007 요청). 비면 CMN 설정 CMN_CSR_ROOT_CAUSE_DUE_DAYS(10일) |
| SapCustomerNo__c | SAP 고객 번호 | SAP Customer No. | Text | 20 | 외부 키 |  |
| SapVendorNo__c | SAP 공급업체 번호 | SAP Vendor No. | Text | 20 | 외부 키 유일 | 협력사 RecordType에서 필수(검증 규칙). 협력사 품번 외부 키의 앞부분이라 바꾸지 않는다 |
| SupplierGrade__c | 협력사 등급 | Supplier Grade | Picklist | A, B, C, D |  | 협력사 평가 등급. QMS-06-SQM-003 서비스만 변경(사용자 FLS 읽기, Vol.6c 요청), 필드 이력 |

### User

사용자 / User. 사용자 HR 필드(CMN-00-MDM-001). 표준 Department(텍스트)는 쓰지 않는다. 부서·기본 공장은 코드(플랫폼 제약)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| DepartmentCode__c | 소속 부서 코드 | Department Code | Text | 20 |  | 소속 부서 CMN_Department__c.DeptCode__c. 명세는 Lookup이나 User는 사용자 정의 객체를 Lookup할 수 없어 코드로 둔다. 레코드는 CMN_UserOrgService.departmentsOf. 명세 필수(Y)는 HR 동기화가 보장 |
| EmployeeNo__c | 사번 | Employee No. | Text | 20 | 외부 키 유일 | 사번. 명세 필수(Y)는 HR 동기화(INT-002)와 사용자 생성 절차가 보장(시스템·통합·포털 사용자 때문에 DB 필수 아님) |
| HrStatus__c | 재직 상태 | HR Status | Picklist | ACTIVE, LEAVE, RETIRED |  | 휴직(LEAVE) 시 대리결재 자동 제안 대상. 기본 ACTIVE(명세 필수를 기본값으로 보장) |
| JobGradeCode__c | 직급 코드 | Job Grade Code | Text | 10 |  | HR 직급 코드(임율 계산은 PMS 소관) |
| LanguageOverride__c | 언어 직접 지정 | Language Override | Checkbox |  |  | true면 포털(SSO) 언어를 무시하고 사용자가 고른 언어 유지(CMN-00-I18N-001 BR-2·BR-4). cmnLanguageSwitcher가 바꾼다 |
| PrimaryPlantCode__c | 기본 공장 코드 | Primary Plant Code | Text | 10 |  | 기본 공장 CMN_Plant__c.PlantCode__c(화면 기본 필터·채번 기준). Lookup 불가로 코드. 레코드는 CMN_UserOrgService.primaryPlantsOf |

## 커스텀 메타데이터 유형(설정)

| 객체 | 라벨(ko) | Label(en) | 필드 수 | 소유 WI |
| --- | --- | --- | --- | --- |
| [CMN_AppMenuItem__mdt](#cmn_appmenuitem__mdt) | 앱 메뉴 항목 |  | 14 | CMN-00-UX-007 |
| [CMN_AppMenu__mdt](#cmn_appmenu__mdt) | 앱 메뉴 |  | 8 | CMN-00-UX-007 |
| [CMN_ApprovalType__mdt](#cmn_approvaltype__mdt) | 결재 유형 |  | 8 | CMN-00-APV-001 |
| [CMN_ChecklistProvider__mdt](#cmn_checklistprovider__mdt) | 체크리스트 Provider |  | 3 | CMN-00-UX-009 |
| [CMN_DashboardResolver__mdt](#cmn_dashboardresolver__mdt) | 대시보드 확장 |  | 5 | CMN-00-DSH-001 |
| [CMN_DashboardTemplateItem__mdt](#cmn_dashboardtemplateitem__mdt) | 대시보드 템플릿 항목 |  | 5 | CMN-00-DSH-001 |
| [CMN_DashboardTemplate__mdt](#cmn_dashboardtemplate__mdt) | 대시보드 템플릿 |  | 6 | CMN-00-DSH-001 |
| [CMN_DeleteGuard__mdt](#cmn_deleteguard__mdt) | 삭제 통제 |  | 3 | CMN-00-SEC-003 |
| [CMN_FeatureSwitch__mdt](#cmn_featureswitch__mdt) | 기능 스위치 |  | 2 | CMN-00-ARC-002 |
| [CMN_FieldEntryProvider__mdt](#cmn_fieldentryprovider__mdt) | 현장 입력 Provider |  | 3 | CMN-00-UX-008 |
| [CMN_GridColumn__mdt](#cmn_gridcolumn__mdt) | 편집 그리드 열 |  | 12 | CMN-00-UX-006 |
| [CMN_GridDefinition__mdt](#cmn_griddefinition__mdt) | 편집 그리드 정의 |  | 12 | CMN-00-UX-006 |
| [CMN_InboundRoute__mdt](#cmn_inboundroute__mdt) | 수신 경로 |  | 4 | CMN-00-DWH-003 |
| [CMN_Interface__mdt](#cmn_interface__mdt) | 인터페이스 |  | 9 | CMN-00-INT-001 |
| [CMN_NotificationRule__mdt](#cmn_notificationrule__mdt) | 알림 규칙 |  | 4 | CMN-00-NTF-001 |
| [CMN_NumberingRule__mdt](#cmn_numberingrule__mdt) | 채번 규칙 |  | 5 | CMN-00-ARC-003 |
| [CMN_RailPanel__mdt](#cmn_railpanel__mdt) | 결정 지원 레일 패널 |  | 10 | CMN-00-UX-004 |
| [CMN_Setting__mdt](#cmn_setting__mdt) | CMN 설정 |  | 2 | CMN-00-MDM-003 |
| [CMN_SharingConfig__mdt](#cmn_sharingconfig__mdt) | 공유 설정 |  | 4 | CMN-00-SEC-002 |
| [CMN_StatusFlow__mdt](#cmn_statusflow__mdt) | 상태 흐름 |  | 2 | CMN-00-UX-003 |
| [CMN_StatusStep__mdt](#cmn_statusstep__mdt) | 상태 단계 |  | 5 | CMN-00-UX-003 |
| [CMN_TriggerSetting__mdt](#cmn_triggersetting__mdt) | 트리거 설정 |  | 3 | CMN-00-ARC-002 |
| [CMN_UiRule__mdt](#cmn_uirule__mdt) | 화면 제어 규칙 |  | 11 | CMN-00-UX-005 |
| [CMN_UiSection__mdt](#cmn_uisection__mdt) | 화면 섹션 |  | 4 | CMN-00-UX-005 |
| [CMN_Widget__mdt](#cmn_widget__mdt) | 대시보드 위젯 |  | 12 | CMN-00-DSH-001 |

### CMN_AppMenuItem__mdt

앱 메뉴 항목 / . 앱 메뉴 허브의 기능 타일(A0 앱 내비게이션 골격). 화면이 아직 없으면 TargetType NONE + Bundle(1차 화면 묶음)로 '준비 중'을 보이고, 각 묶음이 화면을 만들면 Target을 채운다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Bundle__c | Bundle |  | Text | 10 |  | 준비 중 기능의 1차 화면 묶음(A0~A7, screen-first-plan 5절) |
| DescLabel__c | Description Label |  | Text | 80 |  | 설명 Custom Label 이름(선택) |
| FeatureCode__c | Feature Code |  | Text | 20 |  | WI 기능 코드(IQC, NCR 등). 타일에 표시 |
| IconName__c | Icon Name |  | Text | 80 |  |  |
| IsActive__c | Active |  | Checkbox |  |  |  |
| KeywordsLabel__c | Keywords Label |  | Text | 80 |  | 화면 검색 동의어 Custom Label(쉼표 구분 단어, 3개 언어) |
| Menu__c | Menu |  | MetadataRelationship | → CMN_AppMenu__mdt |  |  |
| Order__c | Order |  | Number | 3,0 |  |  |
| RequiredPermission__c | Required Permission |  | Text | 80 |  | PAGE·NONE 타일 표시에 필요한 Custom Permission API명(UX-007 BR-4). 비우면 모두에게 보인다 |
| ShowOnPhone__c | Show On Phone |  | Checkbox |  |  | 휴대폰 전체 메뉴 허브에 표시(UX-007 BR-8) |
| TargetType__c | Target Type |  | Picklist | OBJECT, PAGE, NONE |  | OBJECT = 객체 목록(Target = 객체 API명, 읽기 권한 없으면 숨김), PAGE = 앱 페이지 탭(Target = 탭 API명), NONE = 준비 중 |
| Target__c | Target |  | Text | 80 |  |  |
| TitleLabel__c | Title Label |  | Text | 80 |  | 제목 Custom Label 이름. 비우면 OBJECT 대상 객체의 복수 라벨 |
| TodoSourceTypes__c | To-Do Source Types |  | Text | 255 |  | 미결 배지에 셀 To-Do SourceType(쉼표). * = 내 열린 To-Do 전체(UX-007 BR-5) |

### CMN_AppMenu__mdt

앱 메뉴 / . 앱 메뉴 그룹(CMN-00-UX-007, A0 골격에서 시작). DeveloperName = 메뉴 키(QMS_02 등). 메뉴 허브(cmnAppMenuHub)가 전체 메뉴 모드에서 현재 앱(Apps__c)으로, 메뉴별 모드에서 menuKey로 읽는다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Apps__c | Apps |  | Text | 255 |  | 이 그룹을 보여줄 앱 API명(쉼표). 전체 메뉴 모드는 현재 앱이 들어 있는 그룹만 보인다(UX-007 BR-3) |
| DescLabel__c | Description Label |  | Text | 80 |  | 설명 Custom Label 이름 |
| IconName__c | Icon Name |  | Text | 80 |  | SLDS 아이콘(예: standard:product) |
| IsActive__c | Active |  | Checkbox |  |  |  |
| Order__c | Order |  | Number | 3,0 |  | 메뉴 순서(QMS 메뉴는 RFP 모듈 번호) |
| PageTab__c | Page Tab |  | Text | 80 |  | 그룹 전용 허브 탭(메뉴별 허브 앱 페이지). 그룹 머리글 "메뉴 열기" 대상 |
| System__c | System |  | Picklist | QMS, PMS, CMN |  | 소유 시스템. CMN 메뉴(공통 업무·기준정보)는 QMS·PMS 앱 모두에 둔다 |
| TitleLabel__c | Title Label |  | Text | 80 |  | 제목 Custom Label 이름(ko·en_US·zh_CN) |

### CMN_ApprovalType__mdt

결재 유형 / . 결재 유형(APV-001). DeveloperName = TypeCode. 각 업무 WI가 레코드를 더한다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| CallbackClass__c | Callback Class |  | Text | 120 |  | CMN_ApprovalCallback 구현 클래스 |
| EscalationDays__c | Escalation Days |  | Number | 3,0 |  |  |
| KeepLockedAfterApproval__c | Keep Locked After Approval |  | Checkbox |  |  |  |
| LineContributorClass__c | Line Contributor Class |  | Text | 120 |  | CMN_ApprovalLineContributor 구현(유형별 결재선 보정, APV-002 검토 반영 Vol.2) |
| LockOnSubmit__c | Lock On Submit |  | Checkbox |  |  |  |
| ReminderDays__c | Reminder Days |  | Number | 3,0 |  |  |
| RequireDrafterManager__c | Require Drafter Manager |  | Checkbox |  |  |  |
| TargetObject__c | Target Object |  | Text | 80 |  |  |

### CMN_ChecklistProvider__mdt

체크리스트 Provider / . 체크리스트 수행 화면(UX-009) Provider 등록. 1행 = 업무 객체 1개 → CMN_ChecklistProvider 구현 클래스

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| IsActive__c | Active |  | Checkbox |  |  | 사용 여부 |
| ObjectApiName__c | Object API Name |  | Text | 80 |  | 업무 객체 |
| ProviderClass__c | Provider Class |  | Text | 80 |  | CMN_ChecklistProvider 구현 클래스(공개 기본 생성자) |

### CMN_DashboardResolver__mdt

대시보드 확장 / . 대시보드 확장 등록(DSH-001 변경 요청 Vol.7): TEMPLATE_RESOLVER = CMN_DashboardTemplateResolver(템플릿 선택·config 토큰 치환), CONFIG_VALIDATOR = CMN_WidgetConfigValidator(저장 시 위젯 설정 검증). Order 작은 것부터

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| ClassName__c | Class Name |  | Text | 120 |  |  |
| IsActive__c | Active |  | Checkbox |  |  |  |
| Kind__c | Kind |  | Picklist | TEMPLATE_RESOLVER, CONFIG_VALIDATOR |  |  |
| Order__c | Order |  | Number | 3,0 |  |  |
| System__c | System |  | Picklist | QMS, PMS, CMN |  |  |

### CMN_DashboardTemplateItem__mdt

대시보드 템플릿 항목 / . 템플릿 위젯 구성(DSH-001). 콘텐츠 WI(QMS-07-DSH-013 등)가 품질 위젯 항목을 더한다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Config__c | Config |  | LongTextArea | 32768 |  | 위젯 설정 JSON(비우면 위젯 DefaultConfig). {userPlantId} 등 토큰은 해석기가 치환 |
| Order__c | Order |  | Number | 3,0 |  |  |
| Size__c | Size |  | Picklist | S, M, L |  |  |
| Template__c | Template |  | MetadataRelationship | → CMN_DashboardTemplate__mdt |  |  |
| Widget__c | Widget |  | MetadataRelationship | → CMN_Widget__mdt |  |  |

### CMN_DashboardTemplate__mdt

대시보드 템플릿 / . 역할별 추천 대시보드 템플릿(DSH-001 BR-3). DeveloperName = TemplateKey. 사용자 PSG가 PermissionSetGroups__c에 있으면 그 템플릿(Priority 낮은 것 먼저), 없으면 시스템 기본(IsDefault). 해석기(CMN_DashboardResolver__mdt)가 있으면 먼저 묻는다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| IsDefault__c | Default |  | Checkbox |  |  | 시스템 기본(맞는 PSG가 없을 때) |
| PermissionSetGroups__c | Permission Set Groups |  | Text | 255 |  | 이 템플릿을 받을 PSG DeveloperName 쉼표 목록 |
| Persona__c | Persona |  | Picklist | EXECUTIVE, QM_HEAD, PM, MDT, QUALITY_MANAGER, QUALITY_ENGINEER, INSPECTOR, SUPPLIER_QUALITY, VIEWER, SYSTEM_ADMIN |  |  |
| Priority__c | Priority |  | Number | 3,0 |  | 여러 템플릿이 맞으면 작은 값 우선 |
| System__c | System |  | Picklist | QMS, PMS |  |  |
| TitleLabel__c | Title Label |  | Text | 80 |  |  |

### CMN_DeleteGuard__mdt

삭제 통제 / . 삭제 통제 대상 객체(SEC-003 BR-1). 상태가 DeletableValues에 없으면 삭제 차단(관리자 예외 없음), 삭제되면 CMN_DeleteLog__c 스냅숏. 각 업무 객체 WI가 레코드를 더한다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| DeletableValues__c | Deletable Values |  | Text | 255 |  | 삭제 가능한 상태 값(쉼표 구분, 예: DRAFT) |
| ObjectApiName__c | Object API Name |  | Text | 80 |  |  |
| StatusField__c | Status Field |  | Text | 80 |  | 상태 필드 API 이름(예: Status__c) |

### CMN_FeatureSwitch__mdt

기능 스위치 / . 기능 스위치(ARC-002 BR-6). DeveloperName이 키. 미등록 키는 꺼짐.

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| IsOn__c | On |  | Checkbox |  |  |  |
| RequiredPermissionSet__c | Required Permission Set |  | Text | 80 |  | 비우면 모든 사용자. 값이 있으면 그 Permission Set(이름) 보유자만 |

### CMN_FieldEntryProvider__mdt

현장 입력 Provider / . 현장 입력 셸(UX-008) Provider 등록. 1행 = 업무 객체 1개 → CMN_FieldEntryProvider 구현 클래스

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| IsActive__c | Active |  | Checkbox |  |  | 사용 여부 |
| ObjectApiName__c | Object API Name |  | Text | 80 |  | 업무 객체 |
| ProviderClass__c | Provider Class |  | Text | 80 |  | CMN_FieldEntryProvider 구현 클래스(공개 기본 생성자) |

### CMN_GridColumn__mdt

편집 그리드 열 / . 공통 편집 그리드의 열 1개(UX-006). 레코드는 meta-src/*/grids 정의로 metagen이 만든다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| CodeGroup__c | Code Group |  | Text | 40 |  | CODE 열의 코드 그룹 |
| Editable__c | Editable |  | Checkbox |  |  | 편집 열(필드 편집 권한이 있을 때만) |
| FieldApiName__c | Field API Name |  | Text | 80 |  | 행 객체 필드 |
| Frozen__c | Frozen |  | Checkbox |  |  | 가로 스크롤 시 고정(앞쪽 배치) |
| Grid__c | Grid |  | MetadataRelationship | → CMN_GridDefinition__mdt |  | 그리드 정의 |
| InputType__c | Input Type |  | Picklist | AUTO, TEXT, NUMBER, DATE, PICKLIST, LOOKUP, CHECKBOX, CODE |  | AUTO = 필드 타입. CODE = 계층형 공통 코드(MDM-007) |
| LabelKey__c | Label Key |  | Text | 80 |  | 열 머리글 Custom Label(비우면 필드 라벨) |
| LookupFilter__c | Lookup Filter |  | Text | 255 |  | Lookup 후보 고정 필터(Field__c=VALUE, 쉼표로 AND) |
| Order__c | Order |  | Number | 3,0 |  | 열 순서 |
| Required__c | Required |  | Checkbox |  |  | 화면 필수 검증(서버는 Provider·필드 필수로 다시 검증) |
| ShowOnPhone__c | Show On Phone |  | Checkbox |  |  | 휴대폰 카드 표시(최대 4개) |
| WidthWeight__c | Width Weight |  | Number | 2,0 |  | 상대 폭 1~10(px 금지) |

### CMN_GridDefinition__mdt

편집 그리드 정의 / . 공통 편집 그리드 1개(UX-006). DeveloperName = GridKey. 레코드는 meta-src/*/grids 정의로 metagen이 만든다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| AllowAdd__c | Allow Add |  | Checkbox |  |  | 행 추가 |
| AllowDelete__c | Allow Delete |  | Checkbox |  |  | 행 삭제 |
| AllowPaste__c | Allow Paste |  | Checkbox |  |  | 엑셀 붙여넣기 |
| EditRuleKey__c | Edit Rule Key |  | Text | 80 |  | UX-005 COMPONENT 규칙 키(Mode EDIT). 편집 가능 여부 판정 |
| Filter__c | Filter |  | Text | 255 |  | 고정 필터(Field__c=VALUE, 쉼표로 AND) |
| MaxRows__c | Max Rows |  | Number | 4,0 |  | 기본 200, 상한 500 |
| ObjectApiName__c | Object API Name |  | Text | 80 |  | 행 객체 |
| OrderField__c | Order Field |  | Text | 80 |  | 정렬·행 순서 저장 필드(숫자). 새 행은 마지막 순서 + 1 |
| ParentField__c | Parent Field |  | Text | 80 |  | 부모 레코드 필드(Master-Detail 또는 Lookup) |
| ProviderClass__c | Provider Class |  | Text | 80 |  | CMN_GridProvider 구현 클래스(비우면 제약 없음) |
| ScheduleEndField__c | Schedule End Field |  | Text | 80 |  | 일정 막대 종료일 |
| ScheduleStartField__c | Schedule Start Field |  | Text | 80 |  | 일정 막대 시작일(종료일과 함께 있으면 일정 보기) |

### CMN_InboundRoute__mdt

수신 경로 / . 결과 수신 라우팅(DWH-003 BR-3). 1행 = 이벤트 유형 1개 → CMN_InboundHandler 구현 클래스. 핸들러는 이벤트 유형을 소유한 Vol. WI가 만들고 여기에 등록한다. 미등록 유형은 수신 영수 UNROUTED

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| EventType__c | Event Type |  | Text | 80 |  | CMN_ResultInbound__e.EventType__c 값(QMS_{영역}_{사건}) |
| HandlerClass__c | Handler Class |  | Text | 80 |  | CMN_InboundHandler 구현 클래스(공개 기본 생성자) |
| IsActive__c | Active |  | Checkbox |  |  | 사용 여부(끄면 UNROUTED로 남는다) |
| OwnerWi__c | Owner WI |  | Text | 30 |  | 핸들러를 소유한 WI(예: QMS-04-SPC-002) |

### CMN_Interface__mdt

인터페이스 / . 인터페이스 카탈로그(INT-001). DeveloperName = InterfaceId의 - 를 _ 로. 새 인터페이스는 담당 WI가 레코드를 더한다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Description__c | Description |  | Text | 255 |  |  |
| InterfaceId__c | Interface Id |  | Text | 20 |  | 예: IF-SAP-002 |
| IsActive__c | Is Active |  | Checkbox |  |  |  |
| OwnerTeam__c | Owner Team |  | Text | 40 |  | 담당 메뉴(예: QMS-09, CMN-00) |
| OwnerWi__c | Owner WI |  | Text | 40 |  |  |
| Pattern__c | Pattern |  | Text | 20 |  | BATCH, REALTIME, EVENT |
| Schedule__c | Schedule |  | Text | 120 |  |  |
| Source__c | Source |  | Text | 40 |  |  |
| Target__c | Target |  | Text | 40 |  |  |

### CMN_NotificationRule__mdt

알림 규칙 / . 알림 규칙(NTF-001). DeveloperName = EventCode. 각 업무 WI가 레코드와 제목·본문 라벨을 더한다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| BodyLabel__c | Body Label |  | Text | 80 |  | Custom Label 이름(본문, 일반 텍스트) |
| Channels__c | Channels |  | Text | 80 |  | EMAIL, BELL(쉼표). BELL은 모바일 푸시 포함 |
| IsActive__c | Is Active |  | Checkbox |  |  |  |
| SubjectLabel__c | Subject Label |  | Text | 80 |  | Custom Label 이름. 토큰 {RecordNo} {Title} {Url} {DueDate} {Actor} 및 업무별 토큰 |

### CMN_NumberingRule__mdt

채번 규칙 / . 업무 문서 번호 규칙(ARC-003). 객체마다 1개. 각 업무 객체 WI가 자기 규칙 레코드를 더한다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| NumberField__c | Number Field |  | Text | 80 |  | 번호를 넣을 필드. 비우면 RecordNo__c |
| ObjectApiName__c | Object API Name |  | Text | 80 |  | 대상 객체(예: QMS_Ncr__c) |
| Pattern__c | Pattern |  | Text | 80 |  | 토큰 {PLANT} {YYYY} {YY} {MM} {SEQ:n}. 예: NCR-{PLANT}-{YYYY}-{SEQ:6} |
| ResetPolicy__c | Reset Policy |  | Picklist | YEARLY, MONTHLY, NEVER |  |  |
| ScopeField__c | Scope Field |  | Text | 80 |  | {PLANT} 치환 필드(공장 Lookup이면 공장 코드). 비우면 전사 연번(예: LL-, LA-) |

### CMN_RailPanel__mdt

결정 지원 레일 패널 / . 결정 지원 레일 패널(UX-004 BR-5·6). 1행 = 객체 1개의 패널 1개. ObjectApiName * = 모든 업무 레코드 기본 패널, 같은 PanelKey의 객체 행이 덮어쓴다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| ComponentName__c | Component Name |  | Text | 80 |  | 동적으로 불러올 LWC(c/cmnXxx) |
| Config__c | Config |  | LongTextArea | 4000 |  | 패널 설정 JSON(문맥 분석 bind 등) |
| DefaultOpen__c | Default Open |  | Checkbox |  |  | 기본 펼침 |
| IsActive__c | Active |  | Checkbox |  |  | 사용 여부 |
| ObjectApiName__c | Object API Name |  | Text | 80 |  | 대상 업무 객체. * = 기본 |
| Order__c | Order |  | Number | 3,0 |  | 데스크톱 순서 |
| PanelKey__c | Panel Key |  | Text | 40 |  | AI, APPROVAL, TODO, COMMENT, DOCUMENT, CONTEXT_{이름} |
| PhoneOrder__c | Phone Order |  | Number | 3,0 |  | 휴대폰 순서(비우면 Order) |
| RequiredPermission__c | Required Permission |  | Text | 80 |  | Custom Permission API명. 지정하면 보유자에게만 |
| TitleLabel__c | Title Label |  | Text | 80 |  | 패널 제목 Custom Label 이름 |

### CMN_Setting__mdt

CMN 설정 / . 전사 설정 키·값(“CMN 설정”). DeveloperName이 키. 여러 Vol.이 기본값·대상 목록을 여기 둔다(CMN_Settings로 읽음). 소유 WI가 명세에 없어 MDM-003 BR-2와 함께 추가

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Note__c | Note |  | Text | 255 |  | 용도와 근거 WI |
| Value__c | Value |  | Text | 255 |  | 값(문자열). 숫자·참거짓·쉼표 목록은 CMN_Settings가 변환 |

### CMN_SharingConfig__mdt

공유 설정 / . 공장·협력사 공유 대상 객체(SEC-002 BR-3). 등록된 객체는 저장 때 공장 그룹(읽기·편집)과 협력사 포털 그룹에 Apex 공유(사유 CMN_Plant·CMN_Supplier)를 받는다. 각 업무 객체 WI가 레코드와 공유 사유를 더한다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| IsActive__c | Active |  | Checkbox |  |  |  |
| ObjectApiName__c | Object API Name |  | Text | 80 |  |  |
| PlantField__c | Plant Field |  | Text | 80 |  | 공장 Lookup 필드 |
| SupplierField__c | Supplier Field |  | Text | 80 |  | 협력사 Account Lookup(선택). 협력사 포털 Manager 역할·하위 그룹에 읽기 공유 |

### CMN_StatusFlow__mdt

상태 흐름 / . 상태 흐름(UX-003). DeveloperName = 객체 이름(접미사 제외). 각 업무 객체 WI가 레코드와 단계를 더한다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| ObjectApiName__c | Object API Name |  | Text | 80 |  |  |
| StatusField__c | Status Field |  | Text | 80 |  | 상태 필드 API명(예: Status__c, CurrentStep__c) |

### CMN_StatusStep__mdt

상태 단계 / . 상태 흐름 단계(UX-003). 표시 순서 = Sequence. 종료 단계 중 순서가 가장 앞선 것이 정상 완료, 나머지 종료는 오류 표시

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| IsTerminal__c | Is Terminal |  | Checkbox |  |  |  |
| LabelKey__c | Label Key |  | Text | 80 |  | Custom Label 이름. 비우면 선택 목록 라벨(사용자 언어), 그것도 없으면 값 |
| Sequence__c | Sequence |  | Number | 4,0 |  |  |
| StatusFlow__c | Status Flow |  | MetadataRelationship | → CMN_StatusFlow__mdt |  |  |
| Value__c | Value |  | Text | 80 |  | 상태 값(선택 목록 API 값) |

### CMN_TriggerSetting__mdt

트리거 설정 / . 객체별 트리거 핸들러 활성·우회 권한(ARC-002 BR-2). 레코드가 없으면 활성.

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| BypassPermission__c | Bypass Custom Permission |  | Text | 80 |  | 이 Custom Permission을 가진 사용자는 핸들러를 건너뛴다 |
| IsActive__c | Active |  | Checkbox |  |  |  |
| ObjectApiName__c | Object API Name |  | Text | 80 |  |  |

### CMN_UiRule__mdt

화면 제어 규칙 / . 상태·권한 화면 제어 규칙(UX-005). 1행 = 객체·대상 1개의 허용 조건 묶음. 같은 대상의 행 중 하나라도 맞으면 허용. 레코드는 meta-src/*/ui-rules 정의로 metagen이 만든다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| CustomPermission__c | Custom Permission |  | Text | 80 |  | 필요한 Custom Permission |
| ExtraCondition__c | Extra Condition |  | Text | 255 |  | Field__c=VALUE 또는 Field__c!=VALUE 하나 |
| FormFactor__c | Form Factor |  | Picklist | ALL, LARGE, SMALL |  | 화면 크기(서버 검증에는 쓰지 않음) |
| IsActive__c | Active |  | Checkbox |  |  | 사용 여부 |
| Mode__c | Mode |  | Picklist | EDIT, SHOW |  | SECTION은 EDIT, ACTION·COMPONENT는 SHOW |
| ObjectApiName__c | Object API Name |  | Text | 80 |  | 업무 객체 |
| RecordTypes__c | Record Types |  | Text | 255 |  | 쉼표 구분 DeveloperName. 비우면 전체 |
| StatusField__c | Status Field |  | Text | 80 |  | 상태 필드(기본 Status__c) |
| StatusValues__c | Status Values |  | Text | 255 |  | 쉼표 구분 API값, * = 모든 상태 |
| TargetKey__c | Target Key |  | Text | 80 |  | 섹션 키 / 액션 이름 / 컴포넌트 식별자 |
| TargetType__c | Target Type |  | Picklist | SECTION, ACTION, COMPONENT |  | SECTION 필드 섹션, ACTION 버튼, COMPONENT 페이지 LWC |

### CMN_UiSection__mdt

화면 섹션 / . 화면 섹션 → 필드(UX-005 BR-5 서버 필드 잠금). 필드 목록은 Text(255)라 조회가 SOQL 한도에 세어지지 않는다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Fields__c | Fields |  | Text | 255 |  | 쉼표 구분 필드 API명(255자 이내, 넘으면 섹션을 나눈다) |
| LabelKey__c | Label Key |  | Text | 80 |  | 섹션 제목 Custom Label |
| ObjectApiName__c | Object API Name |  | Text | 80 |  | 업무 객체 |
| SectionKey__c | Section Key |  | Text | 80 |  | 섹션 키(FlexiPage 식별자 {Key}EditSection) |

### CMN_Widget__mdt

대시보드 위젯 / . 대시보드 위젯 등록(DSH-001). DeveloperName = WidgetKey. 위젯 콘텐츠 WI(QMS-07, PMS 대시보드)가 레코드를 더한다. 등록 체크리스트는 QMS-07-DSH-004 BR-4

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| AvailableSystems__c | Available Systems |  | Text | 40 |  | 쉼표 목록(QMS,PMS). 비우면 System 기준(CMN = 둘 다) |
| Category__c | Category |  | Text | 40 |  |  |
| ComponentName__c | Component Name |  | Text | 80 |  | 위젯 LWC 이름(c 네임스페이스, 예: cmnWidgetTodoSummary). 계약: @api config, @api size |
| ConfigSchema__c | Config Schema |  | LongTextArea | 32768 |  | 설정 스키마 JSON(QMS-07-DSH-004 규약). 없으면 편집 모드 설정 버튼 숨김 |
| DefaultConfig__c | Default Config |  | LongTextArea | 32768 |  | 기본 설정 JSON 객체 |
| DefaultSize__c | Default Size |  | Picklist | S, M, L |  |  |
| DescLabel__c | Description Label |  | Text | 80 |  |  |
| IsActive__c | Active |  | Checkbox |  |  | 비활성 위젯은 갤러리·템플릿 복사에서 제외, 보드에는 '사용 불가' 자리표시 |
| MobileSupported__c | Mobile Supported |  | Checkbox |  |  |  |
| RequiredPermissionSet__c | Required Permission Set |  | Text | 80 |  | 이 PS(PSG 포함)를 가진 사용자에게만 갤러리 노출(BR-2). 비우면 전원 |
| System__c | System |  | Picklist | QMS, PMS, CMN |  | 소유 시스템. CMN은 QMS·PMS 보드 모두에 노출 |
| TitleLabel__c | Title Label |  | Text | 80 |  | 제목 Custom Label 이름(ko·en_US·zh_CN) |

## Platform Event

| 객체 | 라벨(ko) | Label(en) | 필드 수 | 소유 WI |
| --- | --- | --- | --- | --- |
| [CMN_ApprovalEvent__e](#cmn_approvalevent__e) | 결재 이벤트 |  | 6 | CMN-00-APV-001 |
| [CMN_KpiLoaded__e](#cmn_kpiloaded__e) | KPI 적재 완료 이벤트 |  | 4 | CMN-00-DWH-003 |
| [CMN_LogEvent__e](#cmn_logevent__e) | 로그 이벤트 |  | 6 | CMN-00-ARC-002 |
| [CMN_ResultInbound__e](#cmn_resultinbound__e) | 결과 수신 이벤트 |  | 3 | CMN-00-DWH-003 |
| [CMN_TodoChanged__e](#cmn_todochanged__e) | To-Do 변경 이벤트 |  | 4 | CMN-00-TDO-001 |

### CMN_ApprovalEvent__e

결재 이벤트 / . 결재 상태 변화(BR-9). To-Do(TDO-001)·알림(NTF-001)이 구독한다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| EventType__c | Event Type |  | Text | 20 |  | SUBMITTED, STEP_PENDING, STEP_DONE, APPROVED, REJECTED, RECALLED |
| RequestId__c | Request Id |  | Text | 18 |  |  |
| StepId__c | Step Id |  | Text | 18 |  |  |
| TargetRecordId__c | Target Record Id |  | Text | 18 |  |  |
| TypeCode__c | Type Code |  | Text | 80 |  |  |
| UserId__c | User Id |  | Text | 18 |  | 처리 차례 결재자(STEP_PENDING) 또는 처리자 |

### CMN_KpiLoaded__e

KPI 적재 완료 이벤트 / . KPI 적재 완료(Vol.7 변경 요청). Mule이 KPI 적재 배치 1회가 끝나면 발행하고, 위젯 데이터 서비스(Vol.7 DSH-002)가 kpi: 캐시를 비운다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| KpiKeys__c | KPI Keys |  | LongTextArea | 32768 |  | 이번 적재에 포함된 KPI 키(쉼표 구분) |
| LoadId__c | Load Id |  | Text | 64 |  | 적재 배치 상관 ID(연계 로그 CorrelationId와 같다) |
| LoadedAt__c | Loaded At |  | DateTime |  |  |  |
| RowCount__c | Row Count |  | Number | 10,0 |  |  |

### CMN_LogEvent__e

로그 이벤트 / . 로그 이벤트. 트랜잭션이 롤백돼도 로그가 남도록 즉시 발행한다(ARC-002 BR-4).

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| Level__c | Level |  | Text | 10 |  |  |
| Message__c | Message |  | LongTextArea | 32768 |  |  |
| Payload__c | Payload |  | LongTextArea | 131072 |  |  |
| RecordId__c | Record Id |  | Text | 18 |  |  |
| Source__c | Source |  | Text | 255 |  |  |
| TransactionId__c | Transaction Id |  | Text | 36 |  |  |

### CMN_ResultInbound__e

결과 수신 이벤트 / . 외부 결과 수신(DWH-003 BR-2·BR-3). Snowflake SHARE.OUTBOUND_EVENT를 Mule이 1분 폴링해 발행하고, 다른 원천의 업무 요청도 같은 규약으로 쓴다(Vol.9 INT-002 BR-5). 구독 트리거가 수신 영수로 중복을 거르고 CMN_InboundRoute__mdt의 핸들러를 실행한다

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| EventType__c | Event Type |  | Text | 80 |  | QMS_{영역}_{사건}(예: QMS_SPC_ALARM). 테스트 = CMN_TEST |
| ExternalEventId__c | External Event Id |  | Text | 255 |  | 원천의 결정적 Id(Snowflake EVENT_ID 또는 {IF-ID}:{원천 키}:{원천 버전}) |
| PayloadJson__c | Payload JSON |  | LongTextArea | 131072 |  | 최상위 schemaVersion(정수) 필수, 120,000자 이하(초과 시 200건 단위 part 분할) |

### CMN_TodoChanged__e

To-Do 변경 이벤트 / . To-Do 변경 알림(BR-4, TDO-003 푸시)

| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |
| --- | --- | --- | --- | --- | --- | --- |
| AssigneeEmployeeNo__c | Assignee Employee No |  | Text | 20 |  |  |
| AssigneeId__c | Assignee Id |  | Text | 18 |  | 포털 사용자는 사번이 없다 |
| ChangeType__c | Change Type |  | Text | 20 |  | OPEN, DONE, CANCELLED |
| TodoId__c | Todo Id |  | Text | 18 |  |  |
