# SL QMS 오브젝트 구성 설명·리뷰

기준일 2026-11-02 · 근거: WI 명세 Vol.0~9의 데이터 모델 표(스크립트 추출 — 객체 238개, 필드 행 2,750개), `interfaces.md`, `force-app-cmn` 배포 현황 · 목적: 화면 우선 개발 A단계에서 **데이터 모델 전체를 먼저 배포하기 전에**(결정 SF-7) 구성을 설명하고 고칠 점을 정한다.

> 추출 수치는 명세 표 기준이다. 표 밖 본문에만 나오는 필드나 "3절 상태값"처럼 다른 절을 가리키는 값은 세지 않았으므로 실제 필드 수는 조금 더 많다.

## 1. 한눈에 보기

| 구분 | 수 | 내용 |
| --- | --- | --- |
| 커스텀 객체(`__c`) | 166 | CMN 40 · QMS 126 |
| 커스텀 메타데이터 유형(`__mdt`) | 59 | CMN 14 · QMS 45 — 규칙·설정·등록부 |
| Platform Event(`__e`) | 10 | CMN 3(결재·로그·KPI 수신, 구현 때 To-Do 변경 이벤트 추가), QMS 7(수입검사 판정·출하 판정·NCR·4M·B2B 업로드·위젯 사용·AI 작업) |
| 표준 객체 확장 | 3 | User(사번·부서·공장 코드), Account(고객·협력사 레코드 유형), Contact(포털 사용자) |
| 필드 행 | 2,750 | Text 727, Lookup 476, Picklist 358, Number 335, Long Text 176, Date 170, Checkbox 162, DateTime 96, Master-Detail 55, Roll-up 20, Formula 19, Currency 15 |

### 1.1 메뉴별 소유 객체 수(객체 + mdt + 이벤트)

| 메뉴 | 소유 | 상태 |
| --- | --- | --- |
| CMN-00 공통 | 59 | 53 배포 완료. 미배포 6: `CMN_ScreenGuide__c`, `CMN_KpiValue__c`, `CMN_ResultInbound__e`, `CMN_InboundRoute__mdt`, `CMN_InboundReceipt__c`, `CMN_AiRecommendation__c`(A0에서 배포) |
| QMS-02 개발 품질 | 8 | A1 |
| QMS-03 부품/협력사 품질 | 24 | A1 |
| QMS-04 제품/공정 품질 | 22 | A2 |
| QMS-05 고객 품질 | 21 | A3 |
| QMS-06a 4M·부적합 | 18 | A4 |
| QMS-06b 한도견본·교육·측정기·MSA·분석실 | 25 | A5 |
| QMS-06c 심사·인증·협력사 실적·개선 | 37 | A6 |
| QMS-07 대시보드 | 10 | A7 |
| QMS-08 AI | 10 | A7 |
| QMS-09 연계 | 4 | A7 |

### 1.2 필드가 많은 객체(레코드 화면 설계에 영향)

| 객체 | 필드(표 기준) | 객체 | 필드 |
| --- | --- | --- | --- |
| QMS_NCR__c | 74 | QMS_Claim__c | 52 |
| QMS_EightD__c | 70 | QMS_StabilizationPlan__c | 48 |
| QMS_Audit__c | 60 | QMS_ImprovementProject__c | 43 |
| QMS_FourMChange__c | 53 | QMS_AuditFinding__c | 43 |
| QMS_FinalInspLot__c | 52 | QMS_LessonLearned__c | 42 |

## 2. 구성 방식 설명

### 2.1 3개 층

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ③ QMS 메뉴 업무 객체 (126)                                                   │
│   인정시험 · 수입검사 · PPAP · 초기안정화 · SPC · 출하검사 · 수평전개 · 레슨런 │
│   B2B · 8D · 클레임 · 4M · NCR · 한도견본 · 교육 · 측정기 · MSA · 분석실       │
│   심사 · 인증 · 협력사 실적 · 개선 과제 · 대시보드 운영 · AI · 연계 모니터     │
├─────────────────────────────────────────────────────────────────────────────┤
│ ② 공통 업무 엔진 (CMN, 대부분 구현 완료)                                      │
│   결재(요청·단계·결재선 템플릿·위임) · To-Do · 알림 규칙 · 문서·리비전        │
│   코멘트 · 회의·조치 항목 · 채번 · 공유 설정 · 삭제 통제 · 로그 · 연계 로그   │
│   위젯·대시보드 · KPI 수신 · AI 추천 기록                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│ ① 공통 기준정보 (CMN, 구현 완료)                                             │
│   법인 → 공장 → 라인 → 공정(Master-Detail 3단) · 부서·임직원 · 사용자 공장 권한 │
│   고객·협력사(Account 레코드 유형) · 차종 · 제품군 · 품번 · 협력사 품번        │
│   품질 특성(특별특성) · 계층형 공통 코드                                      │
└─────────────────────────────────────────────────────────────────────────────┘
   업무 원천 대량 데이터(SPC 측정값, MES·EOL 실적, B2B 원본, 통계)는 Snowflake.
   Salesforce에는 업무 흐름·판정·결재와 화면에 필요한 요약만 둔다.
```

### 2.2 반복되는 7가지 설계 패턴

| 패턴 | 어떻게 | 적용 객체 |
| --- | --- | --- |
| **기준서 → 실행 결과(스냅숏)** | 기준서(헤더·라인)를 두고, 실행 레코드를 만들 때 기준 값을 결과 라인에 복사한다. 기준서가 개정돼도 과거 판정 근거가 남는다 | 시험 기준서→인정시험 계획 라인, 수입검사 기준서→검사 로트 결과, 출하검사 기준서→출하 로트 결과, PPAP 요소→PPAP 요소 라인, 심사 체크리스트→심사 결과 항목, 분석 항목→분석 의뢰 항목, OCAP 템플릿→SPC 알람 |
| **헤더 → 상세(Master-Detail)** | 상세는 헤더의 공유·삭제를 따르고, 진척은 롤업(20개)으로 센다 | 계획·로트·PPAP·클레임 비용·4M 검증·NCR 비용·분석 의뢰 항목·심사 지적·교정 이력 등 55개 관계 |
| **협력사 제출(포털)** | 협력사가 포털에서 제출하고 사내가 검토(접수·반려) | 시험 성적 제출, 성적서(CoA), 인증서, PPAP 제출, 8D 제출, NCR 협력사 회신, 초기안정화 보고, 심사 지적 회신, 협력사 4M 신청(9종) |
| **메뉴 간 느슨한 연결** | 다른 메뉴 레코드는 `SourceRecordId__c`(텍스트 Id)·`SourceObject__c`·`SourceRecordNo__c`로 가리키고, 사실은 Platform Event로 알리며, 업무 요청은 게이트웨이로 한다 | 원천 연결 16개 객체, QMS 이벤트 6+종. 직접 Lookup은 "공용 엔진"을 쓰는 경우만: NCR→8D, 출하검사 기준→샘플링 계획(수입검사 소유), 제품 Re-PPAP→PPAP(부품 소유), 정기 시험→시험 기준서 |
| **분류값은 공통 코드, 상태값은 선택 목록** | 불량 유형·원인(5M1E)·불량 위치처럼 업무가 늘리는 분류는 `CMN_Code__c` Lookup + 경로 텍스트(검색·분석용). 시스템이 다루는 상태·구분은 Picklist | NCR·클레임·8D의 DefectType·Cause 등. Picklist 358개 |
| **측정값은 레코드가 아니라 묶음** | 측정값 한 건 = 레코드 한 건으로 만들지 않는다. 검사 항목 하나에 시료 값을 JSON(Long Text 131,072)으로 담고, 통계·추세는 Snowflake | `QMS_IqcResult__c`·`QMS_FinalInspResult__c`의 `SampleValuesJson__c`. SPC는 계획·관리 한계·알람만 Salesforce |
| **규칙은 메타데이터** | 전환 규칙·등급 구간·점수 계산·주기·알림·연계 매핑을 mdt로 두고 배포로 관리 | mdt 59개(심사 영역만 14개) |

### 2.3 공유(누가 무엇을 보나)의 기준 필드

- `Plant__c`(QMS 업무 객체 126개 중 57개): 공장 격리(SEC-002). 공장 그룹 공유가 이 필드를 본다.
- `Supplier__c`: 협력사 포털 사용자에게 자기 회사 레코드만 공유.
- Master-Detail 상세: 헤더를 따른다.
- 기준·마스터(시험 항목, 샘플링 계획, 교육 과정, 자격 유형, 심사 체크리스트 등): 사내 공개 읽기.

### 2.4 번호와 이름

업무 번호는 `RecordNo__c`(QMS 업무 객체 30개)에 채번 서비스가 넣고, `Name`은 사람이 읽는 제목이다(예: NCR "렌즈 흐림 - 대구 L3"). 상태가 있는 업무 객체는 78개이며 상태 진행바(`cmnStatusPath`)로 표시한다.

## 3. 메뉴별 객체 구성

화살표(→)는 헤더 → 상세(대부분 Master-Detail), 괄호는 역할이다.

### QMS-02 개발 품질(인정시험)

| 기능 | 객체 |
| --- | --- |
| 시험 마스터·기준 | `TestItem`(시험 항목, ACTIVE/OBSOLETE) · `TestStandard` → `TestStandardLine`(고객·제품별 시험 기준서, 개정 DRAFT/ACTIVE/OBSOLETE) |
| 인정시험 실행 | `QualPlan`(품번·프로젝트별 계획, 진척 롤업 4종) → `QualPlanLine`(시험 라인: 기준 스냅숏, 수행 주체, 일정, 위험 표시) → `QualSampleResult`(시료별 측정값 — 시료 수가 적은 시험이라 레코드로 둠) |
| 협력사 | `SupplierTestSubmission`(협력사 시험 성적 제출) |
| 설정 | `ReportFormat__mdt`(성적서 양식, Vol.4가 확장) |

### QMS-03 부품/협력사 품질

| 기능 | 객체 |
| --- | --- |
| 협력사 포털 | `PortalNotice`(공지), `SupplierCertificate`(인증서 제출·검증·만료), `PortalRoute__mdt` |
| 수입검사 | `SamplingPlan` → `SamplingPlanRow`(샘플링 표, 출하검사도 사용) · `IqcStandard` → `IqcStandardLine`(검사 기준서) · `IqcLot` → `IqcResult`(입고 로트·항목별 결과, 시료 값 JSON) · `IqcLevelChange`·`IqcLevelHold`(검사 수준 정상·강화·완화·무검사 전환 이력과 보류) · `SupplierCoa`(협력사 성적서) · `IqcSwitchRule__mdt` · `IqcDecision__e`(판정 → SAP·NCR 후속) |
| 부품 보증시험 | `PeriodicTestSchedule`(정기 시험 일정, 시험 기준서 참조) |
| 부품 PPAP | `PpapElement`(요소 마스터) · `PpapLevelRule`(제출 수준) · `Ppap` → `PpapElementLine`(요소별 제출·검토) · `PpapSubmission`(협력사 제출) · `PpapElementOwnerRule__mdt`·`PpapCollector__mdt` |
| 부품 초기안정화 | `StabilizationPlan` → `StabilizationReport`(기간·목표·보고, Vol.4가 제품 초기안정화로 확장) · `StabilizationDefault__mdt` |

### QMS-04 제품/공정 품질

| 기능 | 객체 |
| --- | --- |
| 초기유동 | `MesDefectMap`(MES 불량 코드 매핑), 초기안정화 객체 확장(내부 라인용 레코드 유형) |
| SPC | `SpcPlan`(관리 대상 특성·라인), `SpcLimit`(관리 한계 버전·확정), `SpcAlarm`(이상 알람·확인·OCAP 조치), `OcapTemplate` → `OcapStep`, `SpcRule__mdt`. 측정값은 Snowflake |
| 출하검사 | `FinalInspStandard` → `FinalInspStandardLine` · `FinalInspLot` → `FinalInspResult`(EOL 요약 JSON 포함) · `FinalInspHold`(출하 보류) · `FinalInspDecision__e` |
| 수평전개 | `HorizontalDeploy` → `HorizontalDeployTarget`(대상 공장·라인·품번별 전개·확인) |
| 레슨런 | `LessonLearned`(사례), `LeleCheckpoint`(체크 포인트), `LeleApplication`(신규 프로젝트 적용 검토) |
| 제품 Re-PPAP | 부품 PPAP 객체 확장 + `PpapEvidence`(요소 라인의 증빙), `PpapCustomerSubmission`(고객 제출) |

### QMS-05 고객 품질

| 기능 | 객체 |
| --- | --- |
| 고객 B2B | `B2bUpload`(고객 품질 데이터 업로드·재처리·취소), `CustomerDefectMap`·`CustomerPartMap`(고객 코드 → 사내 코드), `B2bTrendRule`(추세 경보 규칙), `CustomerQualityAlert`(경보), `CustomerQualityTarget`(목표), `CustomerScorecard`(고객 평가), `CustomerQualityOwner`(고객별 담당·대리), `B2bFormat__mdt`, `B2bUploadRequested__e` |
| 8D 엔진(공용) | `EightD` → `EightDStep`(D1~D8)·`EightDTeamMember`·`EightDAction`(봉쇄·영구 대책·재발 방지) · `EightDSubmission`(협력사 8D 제출) · `EightDStageField__mdt`·`EightDFormat__mdt`. 클레임·NCR·심사 지적이 같은 엔진을 쓴다 |
| 고객 클레임 | `Claim` → `ClaimCost`(비용, 롤업)·`ClaimResponse`(고객 회신) · `SupplierChargeback`(협력사 구상) |

### QMS-06a 4M 변경·부적합

| 기능 | 객체 |
| --- | --- |
| 4M 변경 | `ChangeTypeRule`(변경 유형별 필요 검증), `FourMChecklistTemplate` → `FourMChecklistItem` · `FourMChange` → `FourMItem`(영향 품번·고객)·`FourMVerification`(시험·PPAP·첫 로트 등 검증, 롤업) · `SupplierFourMRequest` → `SupplierFourMRequestItem`(협력사 신청) · `FourMApprovalRule__mdt` · `FourMEvent__e` |
| 부적합(NCR) | `NCR`(발견 경로·공장·불량 분류·원인·8D 연결, 레코드 유형 INTERNAL/SUPPLIER) → `NcrContainment`(봉쇄)·`NcrDisposition`(처분·특채 결재)·`NcrCost`(비용, 롤업) · `NcrSupplierResponse`(협력사 회신) · `NcrChargeback`(구상) · `NcrSourceConfig__mdt` · `NcrEvent__e` |

### QMS-06b 한도견본·교육·측정기·MSA·분석실

| 기능 | 객체 |
| --- | --- |
| 한도견본 | `LimitSample` → `LimitSampleCopy`(사본 배포) · `LimitSampleCheck`(정기 점검) · `LimitSampleView`(열람 기록) |
| 교육·자격 | `TrainingCourse`, `TrainingPlan`, `TrainingSession`, `TrainingAttendance` · `QualificationType`, `QualificationRequirement`, `Qualification`(개인 자격·만료) · `QualMinStaff__mdt` |
| 측정기 | `Gauge` → `Calibration`(교정 이력·비용) · `GaugeStatusChange` · `GaugeImpactAnalysis`(교정 불합격 영향 분석) · `GaugeSourceSetting__mdt`·`GaugeStatusMap__mdt` |
| MSA | `MsaSchedule`, `MsaStudy`(GR&R 등 — 계산은 Snowflake 프로시저), `MsaAppraiser` |
| 분석실 | `LabAnalysisItem`(분석 항목 마스터), `LabRequest` → `LabRequestItem`(의뢰·항목 진행, 롤업), `LabSchedule` |

### QMS-06c 심사·인증·협력사 실적·개선 과제

| 기능 | 객체 |
| --- | --- |
| 심사 기준 | `AuditChecklist` → `AuditQuestion` · `AuditGradeRule` · `AuditEvidenceRule`(자동 증빙 수집 규칙) |
| 심사 계획·실행 | `AuditProgram` → `AuditProgramItem`(연간 계획) · `Audit`(내부·협력사·고객 VDA 6.3, 지적 롤업 3종) → `AuditTeamMember`·`AuditResultItem`(질문별 점수)·`AuditFinding`(지적) → `AuditFindingAction`(조치)·`AuditFindingResponse`(협력사 회신) · `AuditEvidenceSnapshot` · `CustomerAuditPrepTask`(고객 심사 준비 과제) |
| 인증 | `Certification`(IATF 등 인증 현황·준비 점검) |
| 협력사 실적 | `SupplierTargetSet` → `SupplierTarget` · `SupplierScorecard`(월간 평가) · `SupplierImprovementPlan` |
| 개선 과제 | `ImprovementProject` → `ImprovementPhase`·`ImprovementMember`·`ImprovementKpiValue` |
| 규칙 mdt 14 | 점수 계산, 자격 매핑, 지적 기한, 증빙 쿼리, 위험 요소, 심사 주기, 협력사 심사 규칙, 고객 심사 준비 템플릿, 인증 준비 점검, 경영 검토 입력, 평가 지표, 등급 구간, 즉시 탈락 조건, 개선 템플릿 |

### QMS-07·08·09

| 메뉴 | 객체 |
| --- | --- |
| 07 대시보드 | 공통 `CMN_Widget__mdt`·`CMN_DashboardTemplate__mdt`·`CMN_UserDashboard__c`·`CMN_KpiValue__c` 위에 `KpiDefinition__mdt`(KPI 레지스트리·RAG 기준), `WidgetQuery`·`WidgetCount`·`WidgetList__mdt`(등록 쿼리), `SuggestedQuestion`·`DashboardPersonaRule`·`OverviewSection__mdt`, 운영 객체 `WidgetUsageDaily`·`KpiFreshness`, `WidgetTelemetry__e` |
| 08 AI | `EarlyWarning`(조기경보 처리), `AiUsageCounter`(사용량), `AiEvalRun`(정확도 평가), 공통 `CMN_AiRecommendation__c` 확장, mdt 6종(공장 정책·사용 한도·원천 어댑터·확정 설정·질의 정의·프롬프트 설정), `AiJobEvent__e` |
| 09 연계 | `SyncResendLog`(재전송 기록), `ExternalCodeMap__mdt`(외부 코드 매핑), `SyncMonitorConfig__mdt`, `SapPostingRule__mdt`. 연계 로그·카탈로그는 공통(`CMN_InterfaceLog__c`, `CMN_Interface__mdt`) |

### 대표 흐름 — 문제 발견에서 대책까지

```
수입검사 IqcLot ─판정 이벤트─┐
출하검사 FinalInspLot ───────┤
SPC SpcAlarm ────────────────┼─(게이트웨이: QMS_NcrGateway)─▶ NCR ──Lookup──▶ EightD ◀──Lookup── Claim
인정시험 QualPlanLine ───────┤                                 │  봉쇄·처분·비용            │  D1~D8·조치
고객 B2B 경보 ───────────────┘                                 │                            ▼
                                                               └─협력사 회신(포털)    EightDSubmission(협력사)
                         후속: 4M 변경(FourMChange) · 수평전개(HorizontalDeploy) · 레슨런(LessonLearned)
                         모든 단계의 결재·To-Do·알림·문서·코멘트는 공통 엔진(CMN)
```

## 4. 리뷰 결과

심각도: **높음** = A단계 데이터 모델 배포 전에 정해야 함, **중간** = 해당 묶음 착수 때 반영, **낮음** = 기록·확인.

| ID | 심각도 | 발견 | 영향 | 권고 | 적용 |
| --- | --- | --- | --- | --- | --- |
| R-1 | 높음 | `CMN_KpiValue__c` 데이터량: Vol.7 가정 "KPI 약 110개 × 차원 조합 × 13개월 = 수십만~수백만 행" | 레코드 1건 약 2KB로 100만 행이면 데이터 저장소 약 2GB. SL Org 저장 용량을 넘을 수 있고 조회 성능 저하 | Salesforce에는 위젯이 쓰는 집계 단위(월·주, 공장·협력사·고객 수준)만 적재하고, 일 단위·세부 차원은 Snowflake 드릴다운(DWH-004)으로. 13개월 보존 삭제 배치. 같은 성격의 증가 객체(`CMN_Log__c`, `CMN_InterfaceLog__c`, `QMS_WidgetUsageDaily__c`, `QMS_AiUsageCounter__c`, `QMS_SyncResendLog__c`)에 보존 기간 표를 둔다 | 결정 O-2, A0(KPI 객체) |
| R-2 | 높음 | 통화 필드 15개, 그리고 `QMS_ClaimCost__c`·`QMS_SupplierChargeback__c`에 `CurrencyIsoCode` 행 | `CurrencyIsoCode`는 다중 통화를 켜야 생기는 표준 필드라 직접 만들 수 없다. 다중 통화(D-3)는 켜면 되돌릴 수 없다 | A단계는 Currency 필드만 만들고 `CurrencyIsoCode` 행은 건너뛴다. D-3을 개발 플랜의 P6보다 앞당겨 **A3(고객 클레임) 착수 전**에 정한다. 단일 통화로 정하면 원화 기준 + 원 통화·환율 텍스트 필드 보강을 변경 요청으로 | 결정 O-3(= D-3) |
| R-3 | 중간 | 필드 40~74개인 대형 객체 10개(NCR, 8D, 심사, 4M, 출하 로트, 클레임, 초기안정화 등) | 표준 페이지 레이아웃 한 장에 다 넣으면 화면이 길고 단계마다 필요한 필드가 묻힌다 | A단계에서 이 객체들은 Lightning 레코드 페이지 + Dynamic Forms(필드 섹션을 단계·상태별 탭으로, 상태에 따른 표시 조건)로 만든다. 표준 레이아웃은 모바일·리스트 보조용 최소 구성 | A단계 화면 설계(자체 결정) |
| R-4 | 중간 | 협력사 제출 객체 9종의 상태 값이 둘로 갈림: 시험 성적·NCR 회신·초기안정화 보고는 `DRAFT/SUBMITTED/ACCEPTED/RETURNED`(또는 CONFIRMED), PPAP·8D 제출은 `DRAFT/SUBMITTED/REVIEWED`(검토 결과는 요소별) | 포털 사용자에게 같은 "제출" 행위가 메뉴마다 다르게 보이고, 제출·검토 화면을 9번 따로 만든다 | 상태 값 의미를 한 표로 맞춘다(제출 단위 판정이면 ACCEPTED/RETURNED, 요소별 판정이면 REVIEWED + 요소 결과 집계). 공용 LWC `cmnSubmissionReview`(제출 이력·검토 의견·반려 사유·재제출)를 A1에서 만들고 9종이 함께 쓴다 | 결정 O-4, A1 |
| R-5 | 중간 | 조치 항목 중복: 공통 `CMN_ActionItem__c`(OPEN/DONE/CANCELLED, To-Do·기한 알림 구현 완료)와 `QMS_AuditFindingAction__c`(8필드, 같은 상태 값), `QMS_CustomerAuditPrepTask__c`(OPEN/DONE/NA) | 같은 일을 하는 객체가 늘어 To-Do·독촉·대시보드 집계가 메뉴마다 따로 | 두 객체를 `CMN_ActionItem__c`(원천 `SourceRecordId__c`, 분류 필드 추가)로 대체. 8D 조치(`QMS_EightDAction__c`, 27필드·검증 단계 포함)는 업무가 달라 유지 | 결정 O-5, A6 |
| R-6 | 중간 | 업무 규칙 mdt 45개 중 품질 관리자가 운영 중 바꿀 값이 섞여 있음(검사 수준 전환, 협력사 등급 구간·즉시 탈락, 평가 지표, 심사 주기, 지적 기한, KPI RAG 기준, AI 사용 한도 등) | mdt는 Setup 권한이나 배포로만 바뀐다. 현업 관리자(QualityAdmin PSG)가 직접 못 고치고, 변경 이력·결재가 남지 않는다 | mdt를 "시스템 설정(배포로 관리)"과 "업무 기준(현업이 관리)"으로 나눈다. 업무 기준은 (가) 커스텀 객체 + 관리 화면 + 변경 결재, 또는 (나) mdt 유지 + 변경 요청 절차(분기 배포) 중 택1. 권고: 협력사 등급·평가 지표·심사 주기·KPI RAG처럼 연 1회 이상 바뀌는 것은 (가) | 결정 O-6, 각 묶음 |
| R-7 | 중간 | 텍스트 Id 연결 필드(원천 연결 16개 객체 + 클레임의 분석 의뢰·NCR Id 텍스트 등) | 표준 레이아웃·리스트 뷰에서 18자리 Id가 그대로 보이고 클릭할 수 없다 | 원천 연결이 있는 객체마다 수식 필드 `SourceLink__c = HYPERLINK("/" & SourceRecordId__c, SourceRecordNo__c)`를 추가(명세에 없는 필드 → 보고서 "명세 차이"). 레코드 페이지에는 원천 카드(번호·상태·열기) | A단계 각 묶음(자체 결정) |
| R-8 | 중간 | 여러 Vol.이 같은 객체에 필드를 더함: PPAP·요소 라인·초기안정화 계획·보고(Vol.3 소유, Vol.4 확장), 보고서 양식 mdt(Vol.2 → Vol.4), `CMN_Widget__mdt`(→ Vol.7, 반영 완료), `CMN_AiRecommendation__c`(→ Vol.8) | 한 객체 정의가 두 곳에 흩어져 생성기 정의·권한·레이아웃이 어긋날 수 있다 | 정의 파일은 객체당 하나(소유 메뉴 묶음에서 만듦). 뒤 묶음은 같은 파일에 필드를 더하고 필드마다 `wi`를 남긴다. A단계는 한 번에 배포하므로 Vol.4 확장 필드도 A1에서 같이 만드는 것을 권고 | A1·A2(자체 결정) |
| R-9 | 낮음 | `QMS_NCR__c`만 대문자 약어(자식은 `QMS_NcrContainment__c` 등 PascalCase) | 명명 규칙(Vol.0 3.2)과 다르다 | 명세·`interfaces.md`·데모 데이터에 100곳 가까이 쓰였고 "WI가 정한 API명은 바꾸지 않는다"(sf-dev 7절)에 따라 **유지**. 명명 규칙 예외로 기록 | 결정 O-1(유지 권고) |
| R-10 | 낮음 | Lookup(User)를 필수로 적은 필드 20여 개(PPAP SQE, SPC 알람 담당, 레슨런 검토자, 고객 품질 담당 등) | User Lookup은 필드 수준 필수 지정이 안 된다 | A단계: 페이지 레이아웃·Dynamic Forms에서 필수 표시. B단계: 검증 규칙·서비스 확인(공통 객체와 같은 방식) | A·B(자체 결정) |
| R-11 | 낮음 | 공유 기준 필드(공장·협력사·Master-Detail)가 없는 업무 객체: `HorizontalDeployTarget`(헤더와 Lookup 관계), `IqcLevelChange`·`IqcLevelHold` | 공장 격리 규칙을 적용할 기준이 없다 | 수평전개 대상은 헤더와 Master-Detail로 바꾸거나 대상 `Plant__c` 기준 공유. 검사 수준 이력은 협력사 품번 → 협력사·공장 기준. 나머지 무기준 객체(시험 항목·샘플링 계획·교육 과정·자격 유형·심사 체크리스트 등)는 기준정보라 사내 공개 읽기 | A1·A2 인벤토리에서 확정 |
| R-12 | 낮음 | 측정 시료 값 JSON(`SampleValuesJson__c`, Long Text 131,072) | SOQL 조건·리포트로 쓸 수 없다 | 설계 의도대로 유지(분석은 Snowflake 복제 DWH-002). 화면 그리드가 JSON을 읽고 쓰는 공용 모듈을 A1에서 만들어 출하검사(A2)가 같이 쓴다 | A1(자체 결정) |
| R-13 | 정보 | 메뉴 간 직접 Lookup 4종(NCR→8D, 출하검사→샘플링 계획, 제품 Re-PPAP→PPAP, 정기 시험→시험 기준서)은 "공용 엔진" 재사용이고 대상 메뉴가 먼저 배포된다 | 없음 | 유지. A단계는 전 객체를 한 번에 배포하므로 배포 순서 문제도 없다. 이 밖의 메뉴 간 연결은 계속 텍스트 Id + 이벤트 + 게이트웨이로 | — |
| R-14 | 정보 | 롤업 20개는 모두 Master-Detail 상세를 센다(확인한 부모: 인정시험 계획·PPAP·클레임·4M·NCR·분석 의뢰·심사·품번). 위험 표시 롤업은 배치가 계산하는 체크박스를 센다 | 없음 | 유지 | — |

## 5. 결정 항목

| ID | 결정 | 권고 | 언제까지 |
| --- | --- | --- | --- |
| O-1 | `QMS_NCR__c` 이름 | 유지(명명 규칙 예외로 기록) | A4 전 |
| O-2 | KPI 값 저장 단위·보존 기간 | 위젯 집계 단위만 Salesforce, 세부는 Snowflake, 13개월 보존 삭제 배치, 증가 객체 보존 기간 표 | A0 |
| O-3 | 다중 통화(D-3) | 운영 Org와 같게 결정(되돌릴 수 없음). 결정 전에는 `CurrencyIsoCode` 없이 Currency 필드만 | A3 전 |
| O-4 | 협력사 제출 상태 값·공용 화면 | 의미별 상태 값 표 + 공용 `cmnSubmissionReview` | A1 |
| O-5 | 심사 조치·고객 심사 준비 과제를 공통 조치 항목으로 | 대체(8D 조치는 유지) | A6 전 |
| O-6 | 업무 기준 mdt의 관리 방식 | 자주 바뀌는 업무 기준은 커스텀 객체 + 관리 화면 + 변경 결재 | 각 묶음 착수 전(A1부터) |
| O-7 | 수평전개 대상의 공유 기준 | 헤더와 Master-Detail로 변경 | A2 전 |

"자체 결정"으로 표시한 항목(R-3, R-7, R-8, R-10, R-11 일부, R-12)은 화면 우선 플랜의 권고안 진행 원칙에 따라 해당 묶음에서 반영하고, 명세와 달라지는 부분은 WI 보고서 "명세 차이"와 R1 검토 팩에 남긴다. O-1~O-7 중 답이 없는 항목은 권고안으로 진행한다(자율 진행 원칙). 다만 O-3(다중 통화)은 되돌릴 수 없는 Org 설정이라 A3 착수 전에 다시 확인을 요청한다.
