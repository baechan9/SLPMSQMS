# Vol. 간 계약 — 객체·서비스·이벤트 소유권

이 파일은 메뉴(Vol.)를 나눠 쓰거나 개발 에이전트가 메뉴 순서와 다르게 착수해도 이름과 책임이 어긋나지 않게 하는 등록부다. 상세 정의(필드·BR·AC)는 소유 Vol. 본문이 최종이며, 이름이나 소유를 바꿀 때는 이 파일과 해당 Vol.을 함께 고친다.

## 1. 공통 규칙

- **Lookup**: 다른 메뉴 객체는 그 객체를 정의한 WI를 메타 라인 `선행`에 적었을 때만 Lookup한다. 그 외 원천 연결은 `SourceRecordId__c`(Text 18) / `SourceObject__c`(Text 80) / `SourceRecordNo__c`(Text 40) + Platform Event로 한다.
- **생성 서비스**: 다른 메뉴가 내 업무 레코드를 만들게 할 때 `{접두어}_{도메인}Service.createFromSource(요청 DTO)`를 제공한다. 원천 Id 기준 멱등, 조회용 `getStatusBySource(Id sourceId)` DTO를 함께 둔다.
- **이벤트**: `{접두어}_{도메인}Event__e`(대상 Id, SourceRecordId__c, SourceObject__c, EventType__c, 결과 필드). 발행 WI는 구독 측을 구현하지 않는다.
- **게이트웨이**: 다른 메뉴에 업무 생성을 요청하거나 다른 메뉴 서비스를 호출할 때는 그 메뉴가 아직 배포되지 않았을 수 있으므로 5절 게이트웨이 등록부의 인터페이스를 `QMS_GatewayFactory.get(바인딩 키)`로 얻어 호출한다. 구현 교체는 `QMS_GatewayBinding__mdt`, 기본 구현은 담당자 To-Do(또는 경고)다. 소유 메뉴는 자기 `createFromSource`에 위임하는 구현체를 등록한다. 이벤트는 "이미 일어난 일"을 알리는 데만 쓰고, 다른 메뉴에 일을 요청하는 플래그로 쓰지 않는다.
- **KPI**: `CMN_KpiValue__c.KpiKey__c` = `QMS_{영역}_{지표}`. 각 Vol.은 데이터 모델 개요에 KPI 키 표(키, 정의, 주기, 차원, 계산 위치)를 둔다. Vol.7 위젯이 이 표를 소비한다.
- **Snowflake**: CORE 테이블은 대문자 스네이크, KPI 뷰는 `MART.V_SF_KPI_{영역}`, Salesforce로 보내는 알람은 `SHARE.OUTBOUND_EVENT`의 EVENT_TYPE `QMS_{영역}_{사건}`(DWH-003 라우팅, 핸들러는 소유 Vol.).
- **코드 이름**: 결재 유형 `QMS_{영역}_{동작}`, 알림 EventCode `QMS_{영역}_{사건}`, To-Do SourceType `QMS_{영역}_{업무}`, 채번 `{약어}-{PLANT}-{YYYY}-{SEQ:n}`.
- **협력사**: 수신자는 `QMS_SupplierContactResolver`, 포털 화면은 SPP 규칙(`QMS_PortalRoute__mdt`, `qmsPortalDocUpload`, 외부 OWD Private, 협력사 소유 제출 객체 + SQE 확인).
- **검사 강도**: 수입검사 수준은 `QMS_IqcLevelService` Hold API로만 바꾼다. 출하검사 강도도 같은 방식(Vol.4 FQC 정의).
- **지식 객체의 공장 간 조회**: LELE, 수평전개, 8D 요약은 Vol.0 D-9 권고(결정 대기)에 따라 전사 Read로 가정한다. 업무 원장(NCR, Claim, 4M 등)은 공장 격리.
- **AI**: 모든 추천·탐지는 `CMN_AiRecommendationService`(AI-004)에 기록하고 확정은 사람이 한다.

## 2. 이미 정의된 계약 (Vol.0·2·3)

| 이름 | 종류 | 소유 WI | 요지 |
| --- | --- | --- | --- |
| CMN_Plant__c, CMN_Line__c, CMN_Operation__c, CMN_Department__c, CMN_Employee__c | 마스터 | CMN-00-MDM-001·002, INT-002 | 공장·라인·공정(OperationType), 부서(Manager__c), 임직원 |
| Account(CMN_Customer, CMN_Supplier), CMN_Vehicle__c | 마스터 | MDM-003·005 | 고객 CSR 필드(ContainmentDueDays, EightDDueDays, PpapDefaultLevel, AuditStandard, ClaimFormTemplate), 협력사(SupplierGrade, Iatf*) |
| CMN_ProductGroup__c, CMN_Item__c, CMN_ItemPlant__c, CMN_ItemVehicle__c, CMN_SupplierItem__c | 마스터 | MDM-004·005 | 품번(ItemType, PartCategory), 협력사 품번(PpapStatus, InspectionLevel) |
| CMN_Characteristic__c | 마스터 | MDM-006 | 특성(CharType, LSL/USL, SpecialClass CC/SC, SpcRequired, TargetCpk, 버전) |
| CMN_CodeGroup__c / CMN_Code__c, cmnCodePicker | 마스터·LWC | MDM-007 | 그룹 DEFECT_TYPE, DEFECT_LOCATION, CAUSE_5M1E, RESPONSIBILITY, DISPOSITION, APPROVAL_ROLE, DOC_CLASS, CHANGE_TYPE, AI_EXCLUDE_REASON, IQC_COMMON_CHECK |
| CMN_ApprovalService, CMN_ApprovalLineResolver, CMN_ApprovalCallback, CMN_ApprovalType__mdt, cmnApprovalLine | 결재 | APV-001~003 | 콜백 onSubmitted/onApproved/onRejected/onRecalled, canSubmit. 결재선 기여 인터페이스 CMN_ApprovalLineContributor(Vol.2 변경 요청) |
| CMN_RoleAssignment__c, APPROVAL_ROLE | 결재 Role | APV-002 | QUALITY_MANAGER, PRODUCTION_MANAGER, PLANT_MANAGER, PURCHASING_MANAGER, DEV_MANAGER, QM_HEAD, LAB_RECEIVER, SUPPLIER_QUALITY, SQ_MANAGER, IQC_LEAD |
| CMN_TodoService.open/close/cancel, CMN_Todo__c | To-Do | TDO-001 | ExternalKey `{SourceType}/{SourceRecordId}/{AssigneeId}` |
| CMN_NotificationService.send, CMN_NotificationRule__mdt | 알림 | NTF-001 | 문구는 Custom Label |
| CMN_NumberingService, CMN_NumberingRule__mdt | 채번 | ARC-003 | RecordNo__c |
| CMN_SharingConfig__mdt, CMN_SharingService | 공유 | SEC-002 | PlantField, SupplierField |
| CMN_DeleteGuard__mdt, CMN_DeleteLog__c | 감사 | SEC-003 | |
| CMN_StatusFlow__mdt, cmnStatusPath, CMN_Comment__c, cmnCommentTimeline | UI | UX-003 | |
| CMN_Document__c, CMN_DocumentRevision__c, cmnDocumentPanel, CMN_DocTemplate__c | 문서 | DOC-001 | DocClass, 리비전, 해시 경고 |
| CMN_Widget__mdt, cmnWidgetBoard | 대시보드 | DSH-001 | 위젯 계약 `@api config`, `@api size` |
| CMN_Meeting(회의) | 회의 | MTG-001 | Q-29 |
| CMN_KpiValue__c, CMN_ResultInbound__e, CMN_InboundRoute__mdt, CMN_InboundHandler, CMN_InboundReceipt__c | Snowflake → SF | DWH-003 | KPI·알람 |
| CMN_DwhSyncConfig__mdt | SF → Snowflake | DWH-002 | 복제 대상 등록 |
| CMN_DwQueryService, CMN_DwQuery__mdt | 드릴다운 | DWH-004 | 등록 쿼리만 |
| CMN_AiRecommendationService, CMN_AiHitRule, cmnAiRecommendationList | AI | AI-004 | UseCase QMS_RCA, QMS_CAPA, QMS_8D_DRAFT, QMS_LELE, QMS_EW, QMS_COA_ANOMALY |
| AI-001(Agentforce 기반), AI-002(문서 검색), AI-003(버전 비교), AI-005(자연어 Q&A 프레임워크) | AI | AI-001~005 | |
| QMS_QualPlanService.createFromSource / getStatusBySource, QMS_QualPlanEvent__e | 인정시험 | QMS-02-DVQ-005 | TriggerType NEW_DEV, SPEC_CHANGE, CHANGE_4M, PERIODIC |
| QMS_QualLineRequested__e | 신뢰성 시스템 의뢰 | QMS-02-DVQ-006 | QMS-09 구독 |
| QMS_NcrGateway | 게이트웨이 | QMS-02-DVQ-007 | requestFromQualification(lineId), requestFromIncoming(lotId) |
| QMS_SupplierContactResolver.resolve | 협력사 | QMS-03-SPP-001 | 역할 QUALITY, PPAP, SHIPPING, MANAGEMENT |
| qmsPortalDocUpload, QMS_PortalRoute__mdt | 포털 | QMS-03-SPP-001·002 | |
| QMS_SamplingService.determine | 샘플링 | QMS-03-IQC-001 | |
| QMS_InspectionHook, QMS_InspectionHook__mdt | 검사 훅 | QMS-03-IQC-003 | validateGauge, validateInspector, Context IQC·FQC |
| QMS_IqcLot__c, QMS_IqcResult__c, QMS_IqcDecision__e | 수입검사 | QMS-03-IQC-002·004 | |
| QMS_IqcLevelService.effectiveLevel / addHold / releaseHold | 검사 수준 | QMS-03-IQC-005 | HoldType STABILIZATION, NCR, PERIODIC_TEST_FAIL, MANUAL |
| CORE.INSPECTION_RESULT | Snowflake | QMS-03-IQC-007 | SOURCE 'IQC', 'COA' (Vol.4 FQC가 'FQC' 추가) |
| QMS_PpapService.createFromSource / getStatusBySource, QMS_PpapEvent__e, QMS_Ppap__c | PPAP | QMS-03-PPA-002 | RecordType SUPPLIER, CUSTOMER(Vol.4) |
| QMS_StabilizationService.createFromSource / getStatusBySource, QMS_StabilizationEvent__e, QMS_StabilizationPlan__c | 안정화 | QMS-03-PIS-001·003 | RecordType PART, PRODUCT(Vol.4) |

## 3. Vol.4~9 계약 (소유 Vol.이 상세 정의)

| 이름 | 종류 | 소유 | 사용처 | 요지 |
| --- | --- | --- | --- | --- |
| QMS_StabilizationPlan__c RecordType PRODUCT | 초기유동 | Vol.4 EFC | QMS-06-4MC(사내 4M), PMS(SOP) | MES 실적 기반, Vol.3 엔진 재사용 |
| CORE.SPC_MEASUREMENT, QMS_SpcPlan__c, QMS_SpcAlarm__c(OCAP 기록), EVENT_TYPE QMS_SPC_ALARM | SPC | Vol.4 SPC | NCR(게이트웨이), RPP(Ppk), Vol.7·8 | 계산은 Snowflake, 조치는 Salesforce |
| QMS_FinalInspLot__c, QMS_FinalInspResult__c, CORE.INSPECTION_RESULT SOURCE 'FQC' | 출하검사 | Vol.4 FQC | NCR, QMS-09(MES·SAP 출하) | 샘플링·검사 훅 재사용 |
| QMS_HorizontalDeployService.createFromSource, QMS_HorizontalDeploy__c, QMS_HorizontalDeployTarget__c, QMS_HorizontalDeployEvent__e | 수평전개 | Vol.4 HZD | 8D D7(Vol.5), NCR(6a), Audit(6c), LEL | 대상(품번·공정·공장·협력사)별 실행 점검 |
| QMS_LessonLearned__c, QMS_LeleCheckpoint__c, QMS_LeleApplication__c, QMS_LessonLearnedService.createFromSource, QMS_LeleMatchService.match | 레슨런 | Vol.4 LEL | 8D D7, NCR, Audit, Vol.8(AI 추천), PMS | 태그 일치 규칙 추천은 Vol.4, AI 순위·PMS 자동 매핑은 Vol.8 |
| 코드 그룹 DEV_PHASE, DEV_ACTIVITY_TYPE | 공통 코드 | Vol.4 LEL(Vol.0 변경 요청) | PMS WBS, Vol.8 | LELE↔PMS 매칭 키 |
| QMS_Ppap__c RecordType CUSTOMER | 제품 Re-PPAP | Vol.4 RPP | QMS-06-4MC | 고객 제출·승인 추적 |
| CORE.CUSTOMER_QUALITY, QMS_CustomerQualityAlert__c, EVENT_TYPE QMS_B2B_ALERT | 고객 B2B | Vol.5 B2B | Vol.7·8, IMP | 원천 수집은 Vol.9 |
| QMS_Claim__c, QMS_ClaimEvent__e | 고객 클레임 | Vol.5 CLM | Vol.7·8, PMS(P-49) | 6pi·8D 고객 회신 |
| QMS_EightD__c, QMS_EightDAction__c, QMS_EightDService.createFromSource / getStatusBySource, QMS_EightDEvent__e | 8D·CAPA 엔진(공용) | Vol.5 CLM | NCR(6a), Audit 지적(6c 선택), Vol.8(RCA·초안) | RecordType CUSTOMER_CLAIM, NCR_SUPPLIER, NCR_INTERNAL. 협력사 8D 포털 입력 포함 |
| QMS_FourMChange__c, QMS_FourMEvent__e, QMS_FourMService | 4M 변경 | Vol.6a 4MC | Vol.8(필요 시험 추천), Vol.9(적용 시점 재고·로트) | RecordType INTERNAL, SUPPLIER. DVQ·PPAP·안정화 생성 서비스 호출 |
| QMS_NCR__c, QMS_NcrEvent__e, QMS_NcrGateway 구현체 | 부적합 | Vol.6a NCR | IQC·FQC·SPC·DVQ·CLM·Vol.8 | RecordType INTERNAL, SUPPLIER. 대책은 8D 엔진(선행 Vol.5) |
| QMS_NcrGateway.requestNcr(QMS_NcrRequest) | 게이트웨이 확장 | Vol.6a NCR | Vol.4 FQC·SPC, Vol.5 CLM | 범용 메서드. 기존 두 메서드는 래퍼 |
| QMS_LimitSample__c, qmsLimitSampleLink | 한도견본 | Vol.6b LMS | IQC-003, DVQ-007, FQC | 특성(VISUAL)·품번 기준 |
| QMS_Qualification__c, QMS_QualificationService.isQualified | 교육·자격 | Vol.6b TRN | InspectionHook 구현, IAU·SAU·CAU 심사원 배정 | |
| QMS_Gauge__c, QMS_Calibration__c | 측정기 | Vol.6b GAU | InspectionHook 구현, MSA, Vol.9 | 교정 불합격 영향 분석(INSPECTION_RESULT GAUGE_NO) |
| QMS_MsaStudy__c, CORE.MSA_MEASUREMENT | MSA | Vol.6b MSA | RPP·PPA(MSA 요소), GAU | Gage R&R는 Snowpark |
| QMS_LabRequest__c | 분석실 | Vol.6b LAB | CLM(반품 분석), NCR | |
| KPI 목표·등급(Account.SupplierGrade__c 갱신) | 협력사 실적 | Vol.6c SQM | IQC-005(무검사 조건), Vol.7 | |
| QMS_ImprovementProject__c, QMS_ImprovementService.createFromSource | 개선 과제 | Vol.6c IMP | B2B, SQM, Audit, Vol.8 EW | |
| QMS_Audit__c, QMS_AuditChecklist__c, QMS_AuditQuestion__c, QMS_AuditResultItem__c, QMS_AuditFinding__c | 심사 엔진(공용) | Vol.6c IAU | SAU, CAU, CER, Vol.8(지적 RCA) | RecordType INTERNAL, SUPPLIER, CUSTOMER, CERTIFICATION |
| QMS_Certification__c | 인증 | Vol.6c CER | Vol.7 | ISO 9001, IATF 16949 등 SL 사업장 인증 |
| qms*Widget, 역할별 템플릿 | 대시보드 콘텐츠 | Vol.7 DSH | — | DSH-001 위젯 계약 준수 |
| Agentforce 토픽·액션, QMS_LeleRecommendService, 조기경보 모델 | 품질 AI | Vol.8 AIQ | NCR·CLM·Audit·PMS | |
| Mule API 구현(IF-SAP-002·003, IF-MES-001, IF-FC-001, IF-GAU-001, 신뢰성, 부품개발, PMS) | 연계 | Vol.9 INT | 전 Vol. | Salesforce 측 수신 계약은 각 소유 Vol. |

### 3.1 Vol.4~6 작성 중 추가된 이름(소유 Vol. 본문이 상세 정의)

| 소유 | 추가된 객체·서비스·이벤트 |
| --- | --- |
| Vol.4 | QMS_FinalInspLevelService·QMS_FinalInspHold__c(출하검사 강도), QMS_FinalInspDecision__e, QMS_SpcLimit__c, QMS_OcapTemplate__c·Step, QMS_MesDefectMap__c, QMS_LessonLearnedEvent__e, QMS_LeleApplicationService(propose, decide, verify, getByProject, hasOpenMandatory, REST), QMS_LeleApplicationEvent__e, QMS_HorizontalDeployEvent__e, QMS_PpapEvidence__c, QMS_PpapCustomerSubmission__c, QMS_PpapEvidenceCollector·QMS_PpapCollector__mdt, qmsSpcChart |
| Vol.5 | QMS_ClaimService, QMS_ClaimEvent__e, QMS_CustomerQualityOwnerResolver, QMS_B2bUploadRequested__e, QMS_EightDAssist(isAvailable, requestDraft — Vol.8 구현), QMS_EightDRcaHitRule, QMS_EightDCapaHitRule. 8D 모드 FULL_8D·SHORT_CAPA, RecordType에 AUDIT_FINDING 추가(Vol.6c 요구). NCR 대책은 간이 대책 없이 8D 엔진(SHORT_CAPA 포함)만 쓰므로 NCR의 RCA 적중 판정도 QMS_EightDRcaHitRule이 맡는다 |
| Vol.6a | QMS_NcrQueryService, QMS_FourMHistoryService, QMS_ChangeTypeRuleService, QMS_NcrSourceConfig__mdt(원천 객체별 NCR 번호 회신 규칙), QMS_NcrDisposition__c, CORE.NCR_DEFECT, CORE.FOURM_CHANGE, MART.V_NCR_SUPPLIER_DEFECT(협력사 확정 불량 수량의 단일 원천). NCR 협력사 공유 필드는 SupplierShareTo__c(통보서 승인 후 채움) |
| Vol.6b | QMS_LimitSampleService, QMS_GaugeService, QMS_GaugeEvent__e, QMS_MsaService, QMS_MsaEvent__e, QMS_LabRequestService, QMS_LabRequestEvent__e, QMS_TrainingNeedsService. 분석 장비도 QMS_Gauge__c로 관리 |
| Vol.6c | QMS_AuditEvent__e, QMS_AuditFindingEvent__e, QMS_SupplierGradeEvent__e, QMS_AuditFindingAction__c, QMS_AuditFindingResponse__c, QMS_AuditEvidenceRule__c·Snapshot(증빙 제공자 등록 구조), QMS_AuditProgram__c, QMS_SupplierTargetSet__c·Target, QMS_SupplierScorecard__c, QMS_SupplierImprovementPlan__c, QMS_AuditFindingHitRule |
| Vol.9 | 공용 원천 테이블 정의 소유: CORE.SAP_STOCK, CORE.SAP_SHIPMENT, CORE.SAP_FX_RATE, CORE.SAP_MATERIAL_PRICE, CORE.SAP_BOM, CORE.LOT_TRACE(계보 UDTF 포함), MES·EOL·SPC RAW 적재. 원천 업무 요청 수신 핸들러 8종(CMN_ResultInbound__e 경유, 업무 서비스·게이트웨이로 위임만), 4M 첫 생산 로트 감지 Task(INT-012). KPI QMS_INT_FAILED, QMS_INT_PENDING_AGED, QMS_INT_LATENCY_MIN |

### 3.2 Vol.7·8에서 추가된 이름

| 소유 | 추가된 객체·서비스·이벤트 |
| --- | --- |
| Vol.7 | QMS_KpiDefinition__mdt(KPI 정의 레지스트리, 새 KPI는 반드시 등록), QMS_WidgetQuery__mdt·QMS_WidgetCount__mdt·QMS_WidgetList__mdt, QMS_DashboardPersonaRule__mdt, QMS_SuggestedQuestion__mdt, QMS_OverviewSection__mdt, Lightning Message Channel QMS_AskQualityChannel·QMS_DashboardFilterChannel, QMS_WidgetTelemetry__e, QMS_WidgetUsageDaily__c, Snowflake MART.KPI_RAG_RULE·MART.F_KPI_RAG(RAG 판정 공통 자산), 정적 리소스 cmnChartJs(전 메뉴 차트 공용), cmnWidgetConfigForm, Custom Permission QMS_DashboardAllPlants |
| Vol.8 | QMS_AiGuard, QMS_SimilarCaseService, QMS_RcaRecommendService(rankAndExplain), QMS_EightDAssistImpl(바인딩 EIGHT_D_ASSIST), QMS_LeleRecommendService·REST /qms/v1/lele/recommend, QMS_EarlyWarningService, QMS_EarlyWarning__c, QMS_AiJobEvent__e, qmsAiRecommendLauncher, qmsRiskTopWidget, EVENT_TYPE QMS_EW_ALERT·QMS_EW_FOLLOWUP, Mule prc-ai-snowflake-api. RCA 결과 JSON 표준(causeCodeId + causeCodeExternalKey). 원인 추천 대상은 8D D4·심사 지적·SPC 알람(NCR 화면에는 두지 않음) |

**KPI 이름 통일**: Cpk는 `QMS_SPC_CPK`(Vol.4)로 하고 Vol.0 DWH-003 예시의 `QMS_CPK`는 바꾼다. NCR 건수는 `QMS_NCR_OPENED`(Vol.6a, Plant·Line 차원), 협력사 PPM은 `QMS_SUPPLIER_PPM`(Vol.6c, 원천 MART.V_NCR_SUPPLIER_DEFECT).

## 4. 파일·번호

| Vol. | 파일 | 기능코드 | 결정 번호 |
| --- | --- | --- | --- |
| Vol.4 | vol4-qms04-product-process-quality.md | EFC, SPC, FQC, HZD, LEL, RPP | D4-n |
| Vol.5 | vol5-qms05-customer-quality.md | B2B, CLM | D5-n |
| Vol.6a | vol6a-qms06-change-ncr.md | 4MC, NCR | D6A-n |
| Vol.6b | vol6b-qms06-measurement-lab.md | LMS, TRN, GAU, MSA, LAB | D6B-n |
| Vol.6c | vol6c-qms06-supplier-improvement-audit.md | SQM, IMP, IAU, SAU, CAU, CER | D6C-n |
| Vol.7 | vol7-qms07-dashboard.md | DSH | D7-n |
| Vol.8 | vol8-qms08-ai.md | AIQ | D8-n |
| Vol.9 | vol9-qms09-integration.md | INT | D9-n |

## 5. 게이트웨이 등록부

프레임워크(`QMS_GatewayBinding__mdt`: DeveloperName = 바인딩 키, Interface__c, ImplClass__c, IsActive__c / `QMS_GatewayFactory.get(String bindingKey)` / 공용 DTO `QMS_FollowUpRequest`·`QMS_FollowUpStatusDTO`)는 Vol.2 DVQ-007 변경 요청으로 QMS 공통에 둔다. 바인딩이 없거나 비활성이면 팩토리가 기본 구현을 돌려준다.

| 바인딩 키 | 인터페이스 | 메서드 | 구현 소유 | 기본 구현 |
| --- | --- | --- | --- | --- |
| NCR | QMS_NcrGateway | requestFromQualification(Id lineId), requestFromIncoming(Id lotId), Id requestNcr(QMS_NcrRequest req) | Vol.6a NCR | To-Do(SourceType QMS_NCR_REQUEST) |
| EIGHT_D | QMS_EightDGateway | Id create(QMS_EightDRequest req), QMS_EightDStatusDTO getStatus(Id sourceId), void cancel(Id sourceId, String reason), void reopen(Id sourceId, String fromStepNo, String reason) | Vol.5 CLM-001 | To-Do |
| EIGHT_D_ASSIST | QMS_EightDAssist(정의 Vol.5 CLM-002) | Boolean isAvailable(String recordTypeName), void requestDraft(Id eightDId, Set<String> stepNos) — 비동기, 결과는 CMN_AiRecommendation__c | Vol.8 AIQ | isAvailable = false(AI 버튼 숨김) |
| HORIZONTAL_DEPLOY | QMS_HorizontalDeployGateway | Id request(QMS_FollowUpRequest req), QMS_FollowUpStatusDTO getStatus(Id sourceId) | Vol.4 HZD | To-Do |
| LESSON_LEARNED | QMS_LessonLearnedGateway | 위와 같음 | Vol.4 LEL | To-Do |
| IMPROVEMENT | QMS_ImprovementGateway | 위와 같음 | Vol.6c IMP | To-Do |
| LAB_REQUEST | QMS_LabGateway | 위와 같음 | Vol.6b LAB | To-Do |
| AUDITOR_QUALIFICATION | QMS_QualificationGateway | Boolean isQualified(Id personId, String qualificationType, Map<String,Object> scope), List<Id> findQualified(String qualificationType, Map<String,Object> scope) | Vol.6b TRN | 항상 true + WARN 로그 |

게이트웨이 인터페이스와 그 DTO(`QMS_NcrRequest`, `QMS_EightDRequest`, `QMS_EightDActionDraft`, `QMS_EightDStatusDTO`, `QMS_FollowUpRequest`, `QMS_FollowUpStatusDTO`)는 모두 프레임워크와 같은 공통 패키지에 둔다. 소유 메뉴가 배포되기 전에도 호출 측이 컴파일되게 하기 위해서다.

`QMS_FollowUpRequest` 필드: sourceId, sourceObject, sourceNo, title, description, plantId, itemId, supplierId, customerId, requestedById, dueDate, payloadJson(메뉴별 추가 값). `QMS_NcrRequest`의 sourceType 값: QUAL_TEST, IQC, FQC, SPC_ALARM, PROCESS, CUSTOMER_CLAIM, CUSTOMER_RETURN, GAUGE_IMPACT, AUDIT, OTHER.
