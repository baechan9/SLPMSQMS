# 검토 패키지

`scripts/build_review_pack.py`가 각 Vol. 검토 요청 절에서 자동으로 모은 문서다. 직접 고치지 말고 Vol. 문서를 고친 뒤 다시 생성한다.

## 1. 결정 항목 (196건)

### Vol.0 (19건)

- [ ] D-1 PMS·QMS 단일 Salesforce Org 확정 — 전제가 바뀌면 INT·DWH와 QMS-09 PMS 연계 설계가 달라짐
- [ ] D-2 표준 Approval Process 대신 공통 결재 엔진(APV) 개발 승인 — Fit-Gap에 Customization으로 표기
- [ ] D-3 Multi-Currency 활성화 여부(ARC-001) — 활성 후 되돌릴 수 없음
- [ ] D-4 Data Cloud 도입 범위 — DWH-002(복제 방식), DWH-004(드릴다운), AI-002(검색 엔진)를 함께 결정
- [ ] D-5 협력사 포털 라이선스(Partner vs Customer Community Plus) — SEC-002 BR-4
- [ ] D-6 Shield(Platform Encryption, Field Audit Trail) 구매 범위 — SEC-003, SEC-004
- [ ] D-7 대용량·통제 문서 저장소(SharePoint 연계 여부) — DOC-001
- [ ] D-8 임직원 전원 CMN_Employee__c 동기화 + 라이선스 사용자만 User 생성 방식 — INT-002
- [ ] D-9 공장 데이터 격리 수준: 해외 공장 사용자의 타 공장 조회 전면 차단이 맞는지 — SEC-002
- [ ] D-10 AI “학습”의 정의(재학습이 아닌 확정 사례 재사용)를 제안서 표현으로 수용하는지 — AI-004
- [ ] D-11 표준 질문지(VDA 6.3·IATF 심사, 고객·SL Gate 평가표)를 판째 받아 공통 버전 템플릿(QNR-001)으로 관리하고 QMS 심사·PMS Gate가 같이 쓴다(2026-11-06 검토, 권고: 승인 — Vol.6c IAU-001 질문지 객체를 CMN으로 이관)
- [ ] DS-1 사용자 두 계층 앱 구조(품질 업무 / 참여자 / 현장 / 포털 / 관리) — SEC-001 BR-4, UX-007. 권고: 승인(반영함)
- [ ] DS-2 Cosmos(SLDS 2) 기준 개발, 협력사 포털만 SLDS 1 기준 검수 — 3.4절, UX-004 BR-10. 권고: 승인(반영함)
- [ ] DS-3 공통 화면 WI 6개(UX-004~009, 35 M/D) 추가와 Vol.2 공수 조정(DVQ-004 7→4, DVQ-007 7→5) — 권고: 승인(반영함)
- [ ] DS-4 트리 메뉴 대신 메뉴 허브 + 앱당 8개 이내 내비게이션 — UX-007. 권고: 승인(반영함)
- [ ] DS-5 현장 오프라인 입력 범위(브라우저 임시 저장만 / 완전 오프라인) — UX-008 BR-5. 권고: 브라우저 임시 저장만
- [ ] DS-6 VDA 6.3 질문지 원문 라이선스 확보 주체(SL / DKBMC) — Vol.6c D6C-2와 같은 결정. 권고: SL
- [x] DS-7 Lightning Console 권한 집합 라이선스 — UX-007 BR-9. 결정(2026-11-05, 사용자): 사용하지 않는다. 모든 앱 표준 내비게이션
- [ ] DS-8 여러 고객 클레임 병합(대표 클레임 + 8D 1개) 기능 추가 — Vol.5 CLM 변경 요청. 권고: 추가(W2)

### Vol.2 (5건)

- [ ] D2-1 시험 실행 관리 위치 — QMS에서 접수·결과까지 관리할지, 기존 신뢰성 시스템이 실행하고 QMS는 계획·판정만 할지(ExecutionSystem 기본값과 QMS-09 범위가 바뀜)
- [ ] D2-2 시험 항목·기준의 원천 — QMS 라이브러리를 마스터로 할지, 신뢰성 시스템 마스터를 동기화할지(DVQ-001 오픈 이슈)
- [ ] D2-3 계획 결재에 시험 부서장 자동 합의, 조건부 판정에 품질본부장 승인 추가 — 결재 규칙 승인
- [ ] D2-4 판정 결과와 후속 업무 연결 규칙 — CONDITIONAL 판정도 4M 적용·PMS 액티비티 완료를 허용할지(QMS-06, PMS Vol.에 반영)
- [ ] D2-5 협력사 제출을 별도 제출 객체 + SQE 승인 방식으로 하는 설계 승인

### Vol.3 (9건)

- [ ] D3-1 협력사 포털 라이선스 = Customer Community Plus(Member·Login 혼용) — Vol.0 D-5를 이 항목으로 종결하고 SEC-002 BR-4 갱신
- [ ] D3-2 수입검사 판정 주체 = QMS, SAP에는 사용결정(재고 상태)만 회신 — SAP QM 사용 여부에 따라 QMS-09 범위가 달라짐
- [ ] D3-3 수입검사 일상 업무는 로트별 To-Do 대신 공장 검사 대기열 화면으로 처리하고 예외만 To-Do — Vol.0 "사람에게 일을 시키면 To-Do" 원칙의 예외 승인
- [ ] D3-4 시료 측정값은 결과 라인 JSON + Snowflake, 판정 후 24개월 지난 결과 라인은 Salesforce에서 삭제(Snowflake 보존, 로트 헤더 유지) — IATF 기록 보존 정책과 맞는지
- [ ] D3-5 검사 수준 전환 기본 규칙(정상↔강화 자동, 완화는 SQE 확인, 무검사는 결재) 승인
- [ ] D3-6 PPAP 엔진을 부품·제품 공용으로 만들고 요소 세트 AIAG PPAP 4판 / VDA 2를 선택 가능하게 — 신규 부품 PPAP(NEW_PART)를 QMS에서 다룰지는 부품개발시스템 범위 확인 후 결정(기본 꺼짐)
- [ ] D3-7 초기안정화 엔진을 부품(PIS)·제품(QMS-04-EFC) 공용으로, PPAP 승인 시 자동 생성 + 즉시 강화 검사
- [ ] D3-8 부품 보증시험은 인정시험 엔진(Vol.2) 재사용(TriggerType PERIODIC)
- [ ] D3-9 PPAP 거절(잠정 승인 만료 포함) 부품은 수입검사에서 합격 처리 불가, 협력사 품질팀장 예외 승인만 허용

### Vol.4 (10건)

- [ ] D4-1 SPC 계산 위치 = Snowflake 자체 계산(권고). SL MES에 SPC가 있으면 MES 판정 결과 수신으로 바꾸고 SPC-002를 "신호 수신·매핑"으로 축소
- [ ] D4-2 SPC 대상 = SpcRequired 특성(특별특성 중심) 측정값, 설비 센서 시계열은 범위 밖
- [ ] D4-3 공정능력 미달 → NCR 자동 생성은 PoC 데모 설정으로만 켜고, 운영 기본은 개선 검토 To-Do
- [ ] D4-4 출하검사 로트는 기준서가 있는 품번만, 기본 단위 = 품번·공장·생산일(기준서별 변경 가능), EOL 전수 항목은 사람이 다시 보지 않고 EOL 결과로 판정
- [ ] D4-5 수평전개·레슨런·반영 이력은 전사 조회(Vol.0 D-9 권고와 같은 가정), 협력사는 자기 수평전개 대상만
- [ ] D4-6 레슨런 게시 결재(검토자 → 품질경영팀 LELE_OWNER), 게시 시 영문 제목·요약 필수
- [ ] D4-7 LELE ↔ PMS 매칭 키 = 공통 코드 DEV_PHASE·DEV_ACTIVITY_TYPE, PMS 표준 WBS 액티비티가 이 코드를 속성으로 가짐(PMS Vol. 설계 전제)
- [ ] D4-8 필수 체크포인트 미적용은 결재(QMS_LELE_WAIVE), 미결정 필수 반영 건이 있으면 PMS 액티비티 완료 불가(hasOpenMandatory)
- [ ] D4-9 고객 PPAP는 Vol.3 PPAP 엔진의 CUSTOMER 레코드타입, BMW는 VDA 2 요소 세트, 고객 통보·승인 필요 판단은 4M(QMS-06)에서
- [ ] D4-10 제품 초기유동은 생성 즉시 출하검사 강화(안전 측), 해제 결재에 생산팀장 합의 포함

### Vol.5 (10건)

- [ ] D5-1 8D·CAPA 엔진을 고객 클레임·협력사 부적합·사내 부적합·고객 요구 심사 지적 공용으로(레코드타입 4개, 모드 FULL_8D / SHORT_CAPA) — 다른 메뉴는 바인딩 EIGHT_D로 사용
- [ ] D5-2 고객 B2B 원천 데이터는 Snowflake에만 저장하고 Salesforce에는 KPI·경보만(분석 화면은 Snowflake 실시간 조회)
- [ ] D5-3 연계 없는 고객 데이터는 파일 업로드 → Mule → Snowflake 검증 방식(Salesforce에서 행을 파싱·저장하지 않음)
- [ ] D5-4 종결(CLOSED)된 8D는 전 공장 내부 사용자 조회 허용 — Vol.0 D-9 권고와 함께 결정
- [ ] D5-5 무귀책(NTF)·고객 귀책 판정은 고객품질팀장 결재(심각 클레임은 품질본부장 추가)
- [ ] D5-6 의심 재고 SAP 보류는 1차 수동 + 봉쇄 시작 이벤트만 발행(자동 보류는 QMS-09 선택 범위)
- [ ] D5-7 협력사 구상은 포털 합의·정산 번호 기록까지, SAP 전표는 수동
- [ ] D5-8 고객별 8D·6pi 양식은 하나의 8D 데이터 + 양식 매핑(메타데이터)으로 PDF·엑셀·포털 입력 도우미를 만든다
- [ ] D5-9 VIN 등 개인 식별 가능 값은 Snowflake STG에서 해시하고 원문은 RAW에만(접근 ROLE_INGEST)
- [ ] D5-10 클레임 종결은 8D 효과 확인(EFFECTIVE) 후에만 허용(고객 수용 후에도 내부 효과 확인까지 열린 상태 유지)

### Vol.6a (10건)

- [ ] D6A-1 4M 결재 2회 구조 — 계획 결재(QMS_4M_PLAN: 변경 추진·검증 계획) + 적용 결재(QMS_4M_APPROVE: 검증 결과 확인 후 양산 적용 허가)
- [ ] D6A-2 협력사 4M은 협력사 소유 신청 객체 → SQE 접수 시 4M 생성(QMS-02-DVQ-010·QMS-03-PPA-003과 같은 원칙). W1 기간은 SQE 대리 등록
- [ ] D6A-3 검증 결과 CONDITIONAL(인정시험 조건부, PPAP 잠정 승인, 고객 조건부 승인)도 적용 결재를 허용하고 조건 이행을 To-Do로 추적, 미이행 시 4M 종료 차단(Vol.2 D2-4 권고와 같은 원칙)
- [ ] D6A-4 첫 적용 로트 기준 — 협력사 4M은 성적서에 4M 번호가 표시된 첫 수입검사 로트, 사내 4M은 MES 생산 로트(MES에 4M 번호가 없으면 수동 등록)
- [ ] D6A-5 NCR 대책은 모두 QMS-05 8D 엔진으로 — FULL_8D 기준(심각도 A, 특별특성, 고객 영향, 재발 180일, 협력사 불량 100개 이상, 시험 불합격, 협력사 귀책 클레임), 그 외 SHORT_CAPA, 사내 귀책 고객 반품·클레임은 클레임 8D 연결(LINKED_8D)
- [ ] D6A-6 NCR 1건 = 품번 1개 + 불량 현상 1개(다품번·다현상은 건을 나눔)
- [ ] D6A-7 NCR은 통보서 승인 전까지 협력사에게 보이지 않음(SupplierShareTo 방식), 통보 후 무응답 1일 경과 시 귀책 수용 간주(이의 제기는 종결 전까지 가능)
- [ ] D6A-8 처분 결과 SAP 재고 이동·구상 차변 메모는 이벤트로 QMS-09가 처리(Salesforce에서 SAP 직접 호출 없음)
- [ ] D6A-9 COPQ 단가는 SAP 표준가·공장 시간 단가를 Snowflake에서 조회하고 비용은 별도 권한(QMS_PS_NcrCost, QMS_ViewCost)으로 분리, KPI 테이블에는 금액을 적재하지 않음
- [ ] D6A-10 NCR 효과 확인은 8D 엔진 결과(QMS-05-CLM-003)를 그대로 쓰고 NCR은 다시 판정하지 않음. 수평전개·레슨런은 FULL_8D는 8D D7, SHORT_CAPA는 NCR 종결 시 게이트웨이로 요청

### Vol.6b (9건)

- [ ] D6B-1 검사원 자격·측정기 교정 검사 훅을 WARN 모드로 시작하고, 자격·측정기 이관이 끝난 공장부터 BLOCK으로 전환 — 전환 기준과 시점
- [ ] D6B-2 측정기 마스터 원천: 공장별로 QMS 일원화(기존 측정기 시스템 이관 후 종료) 또는 기존 시스템 유지·동기화를 고르는 방식 승인 — 기본 가정은 이관 후 QMS 일원화
- [ ] D6B-3 MSA 계산은 Snowflake Snowpark 단일 엔진, Salesforce는 DWH-004 프로시저 모드로 준동기 호출 — Vol.0 DWH-004 확장 승인, Minitab 대조 허용 오차(분산 성분 0.5%, %GRR 0.1%p)
- [ ] D6B-4 MSA 판정 기준 초기값(%GRR 10%·30%, ndc 5, 기준 = 공차·연구 변동 중 큰 값, 연구 변동 배수 6, ANOVA 교호작용 α, 편의·계수형 기준) — SL 품질경영팀 확정 필요
- [ ] D6B-5 분석실 장비를 별도 객체 없이 측정기(QMS_Gauge__c, Category LAB_INSTRUMENT)로 관리해 교정 통제를 공통 적용
- [ ] D6B-6 교육·자격 대상은 CMN_Employee__c(라이선스 없는 현장 인원 포함), 출석은 사원증 스캔·명단 체크
- [ ] D6B-7 한도견본 사진은 참고, 판정 기준은 실물. 실물 유효기간·점검 주기 기본값 12개월·90일
- [ ] D6B-8 협력사에 자기 부품 한도견본 공개, 협력사 보관 사본은 포털에서 협력사가 점검 입력
- [ ] D6B-9 교정 불합격 영향 분석은 Snowflake 검사 결과(측정기 번호 기록분)만 자동 조회, 인정시험 등 나머지 소스는 수동 확인

### Vol.6c (11건)

- [ ] D6C-1 내부·협력사·고객·인증 기관 심사를 공용 심사 엔진(QMS_Audit__c 4개 RecordType) 하나로 만드는 설계 승인
- [ ] D6C-2 VDA 6.3 등 외부 질문지 원문은 SL 라이선스 확인 시에만 저장, 그 전에는 질문 번호 + SL 자체 문구(TextSource·LicenseConfirmed 관리)
- [ ] D6C-3 VDA 6.3 등급 구간·강등 조건·허용 점수·집계 방식(TotalMethod, StepAggregation)은 품질경영팀이 원문으로 검수해 설정 데이터로 입력, 코드에는 규칙 숫자 없음 + 골든 케이스 검증
- [ ] D6C-4 심사 지적 시정은 지적 자체 CAPA(원인·조치 항목·유효성 검증)가 기본이고, 고객이 8D 양식을 요구한 지적만 Vol.5 8D 엔진의 RecordType AUDIT_FINDING을 바인딩 EIGHT_D(QMS_EightDGateway)로 생성
- [ ] D6C-5 "증빙 즉시 제시"는 등록 쿼리·제공자 클래스만 사용(자유 SOQL 금지), 고객 심사 시작 시 증빙 스냅숏을 남겨 "보여준 것"을 보관
- [ ] D6C-6 협력사 스코어카드 초기 지표·가중치(확정 PPM 30, 로트 합격률 15, 클레임 20, 회신 적시율 10, 심사 15, 무단 4M 10)와 등급 구간(A ≥ 90, B ≥ 80, C ≥ 70, D < 70), 월간 점수 → 분기 등급 → SQE 확정 방식
- [ ] D6C-7 협력사 심사 주기 초기값(A 36, B 24, C 12, D 6, 미평가 12개월)과 C 등급·MAJOR 지적 시 6개월 내 후속 심사
- [ ] D6C-8 협력사 등급 C·D는 개선 계획 의무, D는 심사 요청 + 구매 알림까지만(발주 차단은 하지 않음)
- [ ] D6C-9 지적 기한 초기값(사내·협력사 MAJOR 회신 14일·종결 60일, MINOR 30일·90일), 고객·인증 기관 지적은 외부 통지 기한 입력 필수
- [ ] D6C-10 개선 과제 등급(A 전사·B 공장·C 팀)별 게이트 승인과 DMAIC 기본 + 사용자 정의 마일스톤 허용
- [ ] D6C-11 Vol.6b 심사원 자격 서비스 배포 전에는 자격 확인을 경고만 하고 저장 허용(W1 심사 엔진이 먼저 운영될 수 있음)

### Vol.7 (8건)

- [ ] D7-1 RAG 판정 기준 단일화 — QMS_KpiDefinition__mdt를 원천으로 Snowflake MART.KPI_RAG_RULE과 공통 UDF가 모든 KPI의 RAG를 판정하고, 각 Vol.의 개별 RAG 규칙(예: Vol.6c IAU-007)은 이 방식으로 통합
- [ ] D7-2 KPI 위젯 공장 권한 — CMN_KpiValue__c는 내부 전사 Read이지만 위젯 서비스가 사용자 공장으로 필터하고, 전 공장 조회는 Custom Permission QMS_DashboardAllPlants(경영진·품질경영팀·품질본부장)만 허용
- [ ] D7-3 3절 KPI 카탈로그의 RAG 초기 기준값(초록·노랑) 확정 — 품질경영팀 검토
- [ ] D7-4 비용 정보(COPQ·클레임 비용·워런티 비용)는 KPI 레코드에 두지 않고 QMS_ViewCost 보유자만 쿼리로 조회하는 Vol.6a 방식으로 통일(Vol.5 비용 KPI 변경 필요)
- [ ] D7-5 품질 종합 Dashboard는 품질경영팀이 정한 고정 구성(필터만 변경), 개인 홈 보드는 자유 편집
- [ ] D7-6 역할별 기본 템플릿 9종 구성과 페르소나 우선순위(경영진 > IT 관리자 > 품질본부장 > 품질팀장 > SQE > 엔지니어 > 검사원 > 조회자)
- [ ] D7-7 협력사 포털 공개 KPI 6종(수입검사 합격률·보류 PPM·확정 불량 PPM·성적서 제출률·스코어·보증시험 준수율), 완료 월만 공개, 타사 순위 비공개
- [ ] D7-8 PoC 데모 데이터는 합성 데이터만 쓰고 PoC Org에 한정(DEMO- 키 운영 배포 차단)

### Vol.8 (11건)

- [ ] D8-1 유사 사례·레슨런 의미 검색 엔진 = Snowflake Cortex Search(품질 데이터가 SAP·MES 데이터와 함께 Snowflake에 있어 결합 분석이 쉬움). 문서 파일 검색(AI-002)은 Vol.0 D-4 결과를 따르고, Data Cloud를 쓰지 않으면 문서도 Cortex Search로 통일
- [ ] D8-2 LLM 생성은 Salesforce Prompt Builder(Trust Layer)로만 하고 Snowflake Cortex COMPLETE는 쓰지 않음(마스킹·감사·비용 관리 단일화). Cortex는 검색·Analyst·ML 함수만
- [ ] D8-3 원인 코드·위험 점수·추천 순위는 결정적 로직이 정하고 LLM은 근거 문장만 작성. 후보 밖 코드·입력에 없는 숫자는 자동 폐기
- [ ] D8-4 "학습" = 확정 사례 재사용(주간 원인 분포 재계산, 효과 확인 사례 1.5배 가중, 제외 피드백 180일 억제). 모델 재학습 없음(Vol.0 D-10과 같은 정의)
- [ ] D8-5 자연어 통계 질의의 공장 권한 = Snowflake 세션 공장 범위 표 + 행 접근 정책(생성 SQL에도 강제), 보안 뷰 8개만 질의 허용
- [ ] D8-6 조기경보 1차 = 설명 가능한 가중 점수(로버스트 z) + Cortex 이상 탐지 보정. 경보 기준 HIGH 70점 이상이고 7일 평균 대비 +15점 또는 신규 HIGH, 같은 대상 14일 중복 방지
- [ ] D8-7 LELE 추천 결합 = 규칙 0.6 + 의미 0.4, 필수 체크포인트는 순위와 무관하게 항상 포함, 의미 검색만으로 찾은 추가 후보는 유사도 0.75 이상 최대 5건
- [ ] D8-8 중국 공장 사용자 AI 기능은 법무 확인 전까지 비활성(공장 정책 메타데이터로 공장 단위 활성화)
- [ ] D8-9 AI 사용 한도 초기값 — 유스케이스별 공장 일 300회, 사용자 일 30회, 입력 24,000자, 출력 2,000토큰
- [ ] D8-10 PoC 시나리오 6은 PMS 없이 문맥 입력 화면 + 가상 데모 데이터로 시연하고, 실제 PMS 연동은 본 계약 이후 검증
- [ ] D8-11 원인 추천 대상 = 8D D4(클레임·NCR·심사 지적 8D, 자동 초안), 심사 지적·SPC 알람(사용자 요청). NCR 화면에는 AI 영역을 두지 않음(QMS-06-NCR-005와 일치)

### Vol.9 (8건)

- [ ] D9-1 SAP 이벤트 수신 방식 — S/4HANA 비즈니스 이벤트(Event Mesh) 우선, 없으면 15분 폴링(입고·납품 지연 목표가 2분 또는 15분으로 달라짐)
- [ ] D9-2 SAP 반영 방식 — SAP QM 사용결정 또는 재고 이동, 출하 차단은 납품 차단·배치 제한·보류 재고 중 무엇으로 할지(공장별 규칙 메타데이터로 둘 다 지원, 기본값 결정 필요, Vol.3 D3-2와 연동)
- [ ] D9-3 MES 수집 방식 — MES DB 읽기 전용 뷰 폴링(기본) 또는 MES 푸시 API, 공장군별 sys API 분리 승인
- [ ] D9-4 Mule 런타임 위치 — CloudHub 2.0 + 공장 VPN 또는 공장 내 하이브리드 런타임(해외 공장 MES·측정기 시스템 접근, 중국 공장 데이터 국외 이전 이슈와 함께 결정)
- [ ] D9-5 Snowflake 적재 방식 — Mule stage + COPY(기본, 5분 지연) 승인. SPC 지연을 1분 이하로 요구하면 Snowpipe Streaming으로 전환
- [ ] D9-6 PMS 별도 Org 연계(INT-021)는 Vol.0 D-1 결과에 따라 착수 여부 결정(단일 Org면 폐기)
- [ ] D9-7 선택 연계(클레임 봉쇄 재고 SAP 보류 INT-009, 4M MES 통보 INT-013, 협력사 등급 전달 IF-PDS-003)는 W3 권장으로 두고 SL 요청 시 착수
- [ ] D9-8 공용 SAP·로트 계보 CORE 테이블(CORE.SAP_*, CORE.LOT_TRACE)의 정의 소유를 QMS-09로 확정(업무 Vol.은 쿼리 키만 소유)

### Vol.P1 (16건)

- [ ] DP1-1 프로젝트 공유 모델 — 생산처 공장 그룹(읽기·편집 그룹 모두)에는 Read만 주고(PMS 공유 사유 PMS_Plant, CMN_SharingConfig에 등록하지 않음), 편집은 ACTIVE CFT 구성원 Apex 공유(PM·EDIT = Edit, VIEWER = Read)로만 준다. PMO·경영진은 View All. 품번별 추가 생산처 공장은 공유하지 않고 그 공장 담당을 CFT로 넣는다. 권고: 승인
- [ ] DP1-2 CFT 활성 조건 — 팀장 승인과 보안서약 서명을 모두 마쳐야 ACTIVE가 되고 그때 프로젝트 공유를 받는다. PM 본인은 프로젝트 소유자라 서명 전에도 접근하며 "PM 서명 대기"로 표시한다. 권고: 승인
- [ ] DP1-3 보안서약 객체 관계 — 계약의 Master-Detail(Project) 대신 Lookup + 소유자 = 서명자. Master-Detail이면 서약 레코드 접근이 프로젝트 공유를 따라가 서명 전 사람이 자기 서약을 열 수 없다. 권고: Lookup(계약 변경)
- [ ] DP1-4 보안서약 단위·방식 — 프로젝트별 서약. 양식 종류는 고객 그룹별 설정 목록(기본 SL 표준 전자 동의 1종). 고객 지정 서면 양식은 스캔 업로드 + PM 확인. 양식 개정 시 재서명은 설정(기본 하지 않음). 권고: 승인
- [ ] DP1-5 CFT 할당 결재 — 구성원 1명당 결재 PMS_CFT_ASSIGN 1건, 결재자 = 요청 부서의 부서장(RECORD_FIELD). 팀장은 CFT 요청함에서 하위 부서 인원을 지정한 뒤 승인한다. 부서장이 PM 본인이면 자동 승인, VIEWER·PMO 역할은 결재 없음, 팀장이 제안한 교체는 PM 수락만으로 승인. 권고: 승인
- [ ] DP1-6 투입 실적 승인 방식 — APV 결재 대신 PM 일괄 승인 화면(프로젝트·승인자당 To-Do 1건). 사람 500명 × 주 52회 결재 건수를 피한다. PM 본인 실적은 부PM(PM 수준 구성원)이 승인하고, 부PM이 없으면 제출 즉시 자동 확정(PMO 리스트뷰로 감사). 같은 프로젝트 구성원끼리 실적 시간이 보이는 것을 허용한다. 권고: 승인(계약 7절 표기 변경)
- [ ] DP1-7 투입 계획 단위·원천 — 계획도 사람 × 프로젝트 × 주 1행(D-P4 확장), 액티비티별 내역은 행의 JSON. 원천은 액티비티 주/보조 투입율(기본 50%/20%)과 구성원 기본 투입률이고, PM은 주별 예외만 수동 조정한다. 권고: 승인
- [ ] DP1-8 근무 시간 상한 — 실적은 일 8시간(사람 전 프로젝트 합계)·주 52시간 차단, 주 40시간 초과 경고. 계획은 수동 조정만 주 52시간 차단하고 일정에서 파생된 계획은 경고·알림만 한다(일정 변경을 부하 때문에 막지 않기 위해). 공장별 정책 메타데이터로 해외 법정 시간을 다르게 둔다. 일 8시간을 차단할지 경고로 할지는 정책 값(DailyCapIsHard)으로 바꿀 수 있다. 권고: 승인
- [ ] DP1-9 SOR 버전·기준선 — 요구 1건의 버전마다 1행을 두고, 기준선 결재(PMS_SOR_BASELINE: QE·PE 역할 합의 → PM 소속 팀장 승인)로 ACTIVE가 된다. 기준선 객체(PMS_RequirementBaseline__c)를 새로 둔다. 권고: 승인
- [ ] DP1-10 요구사항 충족 판정 — 검증 연결이 1개 이상이고 모든 연결이 VERIFIED면 충족. 자동 상태는 대상 유형별 해석기가 정하고, 수동 확인은 증빙 필수, 강제 완료 액티비티는 검증으로 인정하지 않는다. 충족률 분모에서 참고(INFO)·해당 없음·승인된 이탈을 뺀다. 권고: 승인
- [ ] DP1-11 SOP 단일 원천·보존 — SOP 고객 마일스톤 계획일이 원천이고 프로젝트 SopDate는 사본이다. SOP 실적은 양산 이관 Gate(confirmSop)만 기록한다. 보존 기한 = EOP + 15년(설정, 고객 CSR 확인 후 조정). 권고: 승인
- [ ] DP1-12 개발처 — 개발처를 사업장(CMN_Plant__c)으로 관리하고 연구소·테크센터도 사업장 레코드로 등록한다. 권고: 승인(SL 사업장 목록 확인 필요)
- [ ] DP1-13 업무 번호 범위 — 문서로 쓰이는 객체(프로젝트 PRJ-, SOR 기준선 SRB-, 보안서약 SPL-)만 RecordNo를 두고, CFT 구성원·마일스톤·투입 행 같은 하위 명세 행은 ExternalKey만 둔다. 권고: 승인(계약 5절 머리말 해석)
- [ ] DP1-14 소프트웨어 요구사항 — ALM(Codebeamer)이 원본이다. PMS에는 참조 행(AlmRef)과 충족 상태만 둔다. 권고: 승인
- [ ] DP1-15 프로젝트 레코드 페이지 탭 — 프로젝트는 허브 객체라 UX-004 표준 4탭(현재 단계·상세·관련·이력) 사이에 업무 영역 탭(구성, 요구사항, CFT·투입, Vol.P2~P4의 일정·산출물·비용·리스크·Gate)을 둔다. 첫 탭 컴포넌트 10개 이하·관련 목록 3개 이하 규칙은 지킨다. 권고: 승인(Vol.0 UX-004 예외)
- [ ] DP1-16 CFT 상태 DRAFT 추가 — 요청 작성과 승인 요청 발송을 구분한다(여러 명을 골라 한 번에 보내기 위해). 권고: 승인(계약 상태값 추가)

### Vol.P2 (13건)

- [ ] DP2-1 일정 엔진 = Apex CPM(순수 계산 엔진 + 실행 대기열 Queueable + 바뀐 행만 저장 + 야간 재계산), 프로젝트당 2,000 액티비티 상한, 크리티컬 = 총 여유 0 이하, 경고 = 1일 이하(P-17) — 권고: 승인(D-P3 구체화)
- [ ] DP2-2 근무 달력 = CMN 공통 달력 객체(Vol.0 신규: 공장별 주말·휴일·특근) + 프로젝트당 달력 1개(개발처 공장 기본). Salesforce BusinessHours·Holiday는 테스트에서 만들 수 없고 휴일 연결을 조회할 수 없어 쓰지 않는다. 액티비티별 달력은 W3 후보 — 권고: 승인
- [ ] DP2-3 간트 렌더러 = 연구소 자산 재사용(D-P2)은 자산이 LWC이고 그 안의 라이브러리가 승인 목록 안이거나 사용자가 승인할 때만. 그 전에는 외부 라이브러리 없는 읽기 전용 경량 간트(pmsGanttLite)를 W1 기본으로. 간트에서 끌어 수정은 W1 범위 밖 — 권고: 승인
- [ ] DP2-4 확정 후 일정 변경 = 일정에 영향을 주는 편집은 모두 변경 요청 경유. PM 본인·영향 없음 = 즉시 적용, CFT 요청 = PM 승인, 크리티컬·Gate·고객 마일스톤 지연·재기준선 = PMO 승인 추가(P-26 구현) — 권고: 승인
- [ ] DP2-5 일정 확정 결재선 = PM 기안 → PM 소속 팀장 승인, PMO 참조 — 권고: 승인
- [ ] DP2-6 액티비티 완료 = 완료 조건 충족 시 시스템 승인(무결재)이 기본, 템플릿에서 PM·역할 승인을 지정한 액티비티만 결재, Gate 마일스톤은 Gate 결재로만 완료 — 권고: 승인(PM 결재 600건 부담 방지)
- [ ] DP2-7 강제 완료·재시작 권한 = PM(자기 프로젝트)·PMO. 필수 액티비티 강제 완료는 PMO 승인(PM이 하면 결재) — 권고: 승인
- [ ] DP2-8 인정시험 조건부(CONDITIONAL) 판정을 QMS_QUAL_PASS 충족으로 볼지(Vol.2 D2-4와 같이 결정) — 권고: 충족 + 경고, 조건 문구를 완료 의견에 기록, 설정으로 끌 수 있음
- [ ] DP2-9 필수 데이터 속성(P-21) = 템플릿 데이터 항목(설정형, 배포 없이 추가) + 연결 레코드 필드 검사(FIELD_NOT_BLANK). 대안: 항목마다 액티비티 필드 배포 — 권고: 설정형
- [ ] DP2-10 레슨런 반영 = 템플릿 속성 LeleReviewMode(기본 액티비티별), 호출 시점 = 일정 확정 + 액티비티 착수(프로젝트·WBS 생성 시점은 담당 미정이라 제외) — 권고: 승인(Vol.8 AIQ-008 오픈 이슈 해소)
- [ ] DP2-11 과제 종료 = 정상 종료는 PM 팀장 승인, 임의 종료는 PMO 합의 추가 + 미완료 액티비티 일괄 강제 완료 — 권고: 승인
- [ ] DP2-12 진척 산식 기본값 = 산출물이 있는 표준 액티비티는 산출물 완료율(P-44), 없는 액티비티는 주간 수기 입력(P-20), 마일스톤 0/100. RAG 임계값 지연 5작업일·진척 차 20%p·요약 10%/20%·SPI 0.9/0.8 — 권고: 승인(값은 SL 조정)
- [ ] DP2-13 표준 WBS 개정(26.11~27.04) 대응 = 진행 중 프로젝트는 생성 당시 판을 유지하고, 새 판의 필수 액티비티는 PM이 "표준에서 추가"(확정 후는 변경 요청)로 골라 반영, 판 비교 보고서로 대상 안내 — 권고: 승인

### Vol.P3 (15건)

- [ ] DP3-1 비용 권한 범위 — PM·PMO·재무·경영진은 금액 조회, PM·재무는 편집, CFT·팀장은 비용 객체 권한 없음, 전체 포트폴리오는 PMO·재무·경영진만. 원가 역할(PROJECT_ROLE CST) CFT에게는 개인별로 PMS_PS_Cost_Read를 준다. 권고: 승인
- [ ] DP3-2 ED&D 공개 세분도 — 액티비티별(계획)·월별(실적) 금액과 시간을 Cost_Read 보유자에게 보이므로 혼자 맡은 액티비티에서 직급 임율을 역산할 수 있다. 임율 원문·직급별 분해는 재무만, Snowflake에는 임율을 복제하지 않는다. 권고: 역산 가능성 수용(직급 평균값이라 개인 급여가 아님)
- [ ] DP3-3 ED&D 실적 산정 기준 — 승인(APPROVED) 투입 실적만, 요일별 날짜로 월 귀속, 익월 5일 마감·동결, 지연 승인분은 열린 달 조정 행, 그 해 임율이 없으면 전년 임율 임시 적용. 권고: 승인
- [ ] DP3-4 미래 연도 임율 상승률 기본값(`PMS_LABOR_RATE_ESCALATION_PCT`) — 권고: 0%(재무 확인 후 설정)
- [ ] DP3-5 비용 범주 규칙 — Piece Price는 단가로 관리(합계 제외), Tooling에 투자 주체(자사·고객 지급·단가 상각) 표시, 예비비에는 실적을 붙이지 않고 "예비비 사용"으로 이전. 권고: 승인
- [ ] DP3-6 CostRag 산식·공개 — EAC 차이 5%(AMBER)·10%(RED), 진행 속도 15%(AMBER), 같은 환율로 기준선·EAC 환산, RAG는 프로젝트 조회자 전원에게 공개(금액 비공개). 권고: 승인
- [ ] DP3-7 산출물 결재 팀장 정의 — 기안자 소속 부서장(기안자가 부서장이면 상위 부서장), 기안자는 액티비티 주·보조 담당만. 권고: 승인
- [ ] DP3-8 필수 산출물 해당 없음(N/A) — PM이 사유만 입력(결재 없음), Gate 점검에서 N/A 건수를 따로 보인다. 권고: 승인
- [ ] DP3-9 승인본 품번 문서 게시 — FMEA·관리계획서·공정 흐름도·설계 기록 승인본을 프로젝트 품번 문서로 게시해 QMS Re-PPAP 증빙 수집기가 읽게 한다. 권고: 승인(전 품번)
- [ ] DP3-10 산출물 이벤트 `PMS_DeliverableEvent__e` 신설(계약 9절 변경) — 대안은 PMS_ActivityEvent__e에 DELIVERABLE_* 값 추가. 권고: 신설(Enterprise Scratch 교체 D-P8 전제)
- [ ] DP3-11 개정 중 완료 인정 — 새 판이 승인될 때까지 이전 승인본을 유효로 보고 액티비티를 자동 재시작하지 않는다. Gate 점검은 "개정 중" 표시만. 권고: 승인
- [ ] DP3-12 영향 항목 객체 `PMS_ImpactItem__c` 추가(계약의 AffectedJson은 분석 스냅숏으로 유지), 기본 분석 깊이 3. 권고: 승인
- [ ] DP3-13 요구사항 연결의 원본은 SOR-002 `PMS_RequirementLink__c`이고 DLV-003은 저장하지 않고 합쳐 보인다. 권고: 승인
- [ ] DP3-14 DeliverableType 값 `STANDARD_FORM`을 이미 배포된 CMN 값 `STD_FORM`으로 통일(계약 5절 변경). 승인 전까지는 DLV-001 BR-3의 값 대응으로 동작. 권고: 통일
- [ ] DP3-15 출장비 실적 원천 — W1은 수동 입력, SAP 경비·출장 시스템 연계는 SL 확인 후 PMS-12 신규 WI. 권고: 승인

### Vol.P4 (11건)

- [ ] DP4-1 Gate 평가표 적용 시점 — 평가 시작(IN_REVIEW 진입) 날짜 기준으로 발효 중인 판을 스냅숏하고 끝까지 쓴다. PMS Gate 점검은 W1부터 UX-009 체크리스트 셸을 쓴다(UX-009 오픈 이슈 해소). 권고: 승인
- [ ] DP4-2 고객 Gate 점검표 처리 — SL 표준 평가표 뒤에 고객 점검표를 별도 섹션으로 붙여 같은 Gate에서 함께 평가하고, 최종 RAG는 둘 중 나쁜 값(GAT-002 BR-3). 대안: 고객 Gate를 별도 Gate(고객 마일스톤)로 따로 평가. 권고: 합성 평가
- [ ] DP4-3 Gate RAG 규칙 — 달성률 구간(GRADE_BAND) + 필수 문항 미충족 1개 이상 RED 강등(MANDATORY_NOT_MET_GE), 숫자는 PMO가 템플릿에 입력(코드 없음). 제안 결정 GREEN = 통과, AMBER = 조건부, RED = 실패. 권고: 승인
- [ ] DP4-4 완화 결정 — 제안보다 완화된 결정(RED → 조건부, AMBER → 통과)을 근거 200자 + 사업부장 승인으로 허용, RED → 통과는 금지(GAT-004 BR-2). 권고: 승인
- [ ] DP4-5 리스크 등급 기준 — P×I(1~5) 점수 15 이상 또는 영향도 5·가능성 2 이상 HIGH, 8 이상 MEDIUM, FMEA AP H 리스크 하한 MEDIUM, HIGH 주간·그 외 월간 검토(모두 CMN 설정). SL 현행 행렬이 있으면 그 값으로 교체. 권고: 설정값으로 시작
- [ ] DP4-6 High 리스크 에스컬레이션 — 1단계 자동(PMO·팀장 알림·대책 To-Do), 2단계 수동(경영 보고, 사업부장), 14일 미개선 시 2단계 검토 알림만(자동 2단계 없음). 권고: 승인
- [ ] DP4-7 QMS 이벤트로 문제점 자동 생성 범위 — 활성 프로젝트(SOP + 90일까지) 품번의 고객 클레임 전부, NCR은 심각도 A·B만. 같은 품번을 쓰는 프로젝트가 여러 개면 모두 생성. 권고: 승인(대표 프로젝트 1개만으로 바꿀지 SL 확인)
- [ ] DP4-8 대책서 단일화 — QMS 클레임·NCR과 연결된 문제점은 QMS 8D(HKMC 6pi)를 대책서로 쓰고 PMS에 원인·대책을 복사하지 않음. 승인 요청은 8D D6 이후, 종결은 8D 종결 후. 권고: 승인
- [ ] DP4-9 SOP Gate 초기유동 대상 — 프로젝트 품번 중 완제품·반제품(FG·SFG) 전체 × 생산 공장마다 생성(리드 품번만 아님). 권고: 전체
- [ ] DP4-10 산출물 이상 징후 범위 — 규칙 신호 6종(W2)을 기본으로 하고 AI 내용 신호 3종은 기능 스위치(기본 꺼짐), "검토 필요" 표시만 하고 산출물·Gate를 자동 반려하지 않음. 권고: 승인
- [ ] DP4-11 Gate 결재선 — PM 기안 → QE 합의 → PMO 팀장 검토 → 사업부장 승인. GREEN 통과는 PMO 팀장 승인으로 끝내고 사업부장 참조(SOP Gate·완화 결정은 사업부장 승인 필수). 권고: 승인

### Vol.P5 (16건)

- [ ] DP5-1 대시보드 공용 기반 재사용 — PMS 위젯은 Vol.7 KPI 레지스트리(QMS_KpiDefinition__mdt)·위젯 데이터 서비스(QMS_WidgetDataService)·공용 컴포넌트(qmsKpiTile 등)·설정 폼(cmnWidgetConfigForm)·cmnChartJs·RAG UDF를 이름 그대로 쓰고 PMS 키·영역·전 공장 권한·관계 경로 공장 필드만 확장한다. 함께, Vol.7 DSH-001~004의 형식·서비스는 QMS 업무 메뉴 선행 없이 먼저 배포할 수 있게 초기 데이터와 분리한다. 대안(PMS 전용 복제, CMN 이름으로 승격)은 중복 개발 또는 Vol.7 전면 수정이 필요하다. 권고: 채택
- [ ] DP5-2 AI 운영 자산 재사용 — QMS_AiGuard·정책·한도·사용량 카운터·작업 이벤트(AIQ-001), 확정 배치·설정(AIQ-006), 질의 정의·서비스(AIQ-009), analyst 연산·세션 공장 범위·RAP(AIQ-010), 검색 프리셋(AIQ-013), 프롬프트 버전·평가·JSON 검증(AIQ-016)을 같은 Org에서 PMS가 함께 쓴다. QMS 접두어 이름은 바꾸지 않는다. 권고: 채택
- [ ] DP5-3 비용 정보 분리 — 비용 값은 CMN_KpiValue__c·보고 PDF·알림 본문·AI 답변·Snowflake 등록 쿼리 결과에 넣지 않고, Salesforce 비용 객체·비용 필드의 FLS(PMS_PS_Cost_Read)와 Custom Permission PMS_ViewCost로만 보인다. 프로젝트 CostRag도 비용 정보로 보고 FLS로 감춘다. 권고: 채택(비용 PS를 받는 PSG는 CST-003에서 확정)
- [ ] DP5-4 프로젝트 품질(Q) 상태 — Gate 결과·조건부 후속 기한·고객 클레임/NCR 연결 문제점·SOR 검증 실패·산출물 반려·이상 징후·LELE 필수 미결로 RED·AMBER·GREEN을 매일과 이벤트 때 판정하고 PMS_Project__c에 필드 3개를 추가한다. OverallRag에 Q를 넣을지는 OverallRag 소유 WI가 정한다. 권고: 채택, 기준은 PMO·품질경영팀 확정
- [ ] DP5-5 보고 방식 — 공장·고객별 양식 메타데이터 + 자동 스냅숏 + 수기 섹션, 발행 후 불변·정정 발행, 결재 엔진 대신 검토·발행 절차, PDF는 비용 제외(비용 포함본은 권한자 즉시 내려받기), 일간 보고는 자동 생성·자동 발행·180일 보존. 권고: 채택, SL 현행 양식 수령 후 양식 행 추가
- [ ] DP5-6 의사결정사항을 W2 → W1로 당김(PoC 시나리오 4), 후속 조치는 CMN_ActionItem__c 재사용 + MTG-001 변경(SourceObject 필드, 상태 훅). 권고: 채택
- [ ] DP5-7 AI 일정 추천 방식 — 과거 완료 액티비티 실제 기간의 단계적 그룹 P50(표본 5 이상)을 추천하고 고객 마일스톤 가능성은 일정 엔진 시뮬레이션으로 보인다. 기준선 전 채택은 기간 직접 반영, 기준선 후는 일정 변경 요청 초안. 지연 회복안은 P20 압축·과거 겹침 기반 병행 3안. 정확도 = 추천 대비 실적(IsHit), 추천 대비 확정은 비교 화면·채택률. "학습"은 주간 실적 재집계(D-10). 권고: 채택
- [ ] DP5-8 조기경보 방식 — 1차는 절대 기준 선형 변환의 규칙 가중 점수 + 28일 여유 소진 추세로 30일 뒤 지연 투영. 대상은 프로젝트·부서이고, 인원 과부하는 EFF-003의 주간 알림(PMS_RES_OVERLOAD)에 맡겨 중복 경보를 만들지 않는다. 경보는 업무 레코드를 자동 생성하지 않는다. 권고: 채택
- [ ] DP5-9 SOR 분해 방식 — 엑셀은 열 매핑(결정적) + 미매핑 값만 AI 분류, PDF·Word는 텍스트 구간 AI 추출 + 원문 대조 검증, 후보는 검토용 작업 객체(PMS_SorCandidate__c)에 두고 확정 시 SOR-001 서비스로 등록. 권고: 채택
- [ ] DP5-10 계약 추가 — 신규 객체 3개(PMS_WeeklyReportLine__c, PMS_EarlyWarning__c, PMS_SorCandidate__c), Custom Metadata 6개, PMS_Project__c 필드 3개, UseCase 2개(PMS_SCHEDULE_ADJUST, PMS_SOR_EXTRACT)를 `pms-architecture.md` 5·7절과 `interfaces.md` 6절에 반영. 권고: 채택
- [ ] DP5-11 MDT 역할 가정 — MDT를 "차종 단위로 여러 프로젝트를 총괄하는 개발 책임자"로 가정하고 결재 Role MDT_LEADER로 판단해 차종 단위 템플릿을 준다. SL 정의를 받으면 규칙 메타데이터만 고친다. 권고: 가정으로 진행
- [ ] DP5-12 PMS KPI RAG 초기 기준값(3절 표) — PMO 확정. 권고: 초기 제안값으로 개발
- [ ] DP5-13 공장 없는 합계 KPI 행(전사·고객 합계)을 PMS 대시보드 사용자 전원에게 보임 — 프로젝트 단위 정보가 아니므로 공개해도 공장 권한 원칙(P-57)에 어긋나지 않는다고 본다. 권고: 공개
- [ ] DP5-14 공수 조정 45 → 56 M/D, DSH-004 Wave 조정(위 표). 권고: 승인
- [ ] DP5-15 에이전트·Q&A 답변 범위 — 비용·임율·수평평가는 비용 권한 보유자에게도 답하지 않고 화면 안내, 개인별 투입은 답하지 않고 자원 부하 화면(EFF-003)을 안내, 부서 단위 투입률은 공개. 권고: 채택
- [ ] DP5-16 산출물 초안 예시는 같은 고객(Account) 프로젝트 승인본만 — 다른 OEM 정보가 초안에 섞이는 것을 막는다(TISAX). 권고: 채택

### Vol.P6 (15건)

- [ ] DP6-1 PMS 연계 공통 기반(연결 대장 PMS_SystemLink__c, 핸들러 등록부, 코드 매핑 PMS_ExternalCodeMap__mdt)을 W1인 INT-005에 두고 INT-001~004·ACT-004·ISS-002·PRF-001·DLV-003·004가 재사용한다. 권고: 승인(외부 시스템·QMS 연결을 한 대장에서 보는 것이 디지털 스레드 화면·감사·DW 적재에 유리)
- [ ] DP6-2 PMS → QMS 호출은 게이트웨이(신규 바인딩 LELE_PROJECT·QUALIFICATION·STABILIZATION)로만 하고 QMS 클래스를 직접 참조하지 않는다. 대안은 직접 호출 + 배포 순서 고정(QMS LEL·DVQ·EFC가 PMS보다 먼저). 권고: 게이트웨이(interfaces.md 1절 규칙과 같고, 메뉴별 배포 순서가 바뀌어도 PMS가 컴파일됨). 이 경우 QMS 공통 패키지에 인터페이스·DTO 추가가 필요하다(QMS 변경 요청 표)
- [ ] DP6-3 PMS_PeerEvaluation__c의 관계를 계약의 Master-Detail(Performance)에서 Lookup + OWD Private로 바꾼다. MD는 부모(프로젝트 → 성과) 공유를 따르므로 CFT 전원이 평가 내용을 보게 된다. 권고: 승인(계약 변경)
- [ ] DP6-4 HR 전송 단위와 공개 범위 — (권고) 피평가자 × 방향 집계(평균·등급·평가자 수, 평가자 익명, 의견 미전송, 피평가자 비공개). 대안: 개별 평가 행 전송(평가자 사번 포함), 의견 전송, 피평가자 본인 결과 공개
- [ ] DP6-5 수평평가 범위 — (권고) PM ↔ CFT(PM_AND_CFT), 투입 40시간 이상 구성원. 대안: CFT 상호(같은 액티비티 담당 공유자) 포함(FULL)
- [ ] DP6-6 HR 임율 수신 규칙 — 표본 3명 미만 직급 거부(HR이 밴드로 묶어 보냄), 마감된 비용 기간의 임율 변경은 자동 반영하지 않고 Finance 확인. 권고: 승인
- [ ] DP6-7 DMS 비용 실적 인식 기준 — (권고) 발주 확정(ORDERED) 이후 금액을 발주 월에 인식. 대안: 지급(PAID) 기준, 또는 두 기준 모두 적재(PMS_CostActual__c에 기준 필드 추가)
- [ ] DP6-8 부품개발 비용 집행 금액의 원본 — (권고) DMS(PAID 행으로 단계 자동 집행, PMS 실적 중복 생성 없음). 대안: PMS에서 구매 담당 확인 입력(DMS에 협력사 개발비가 없을 때)
- [ ] DP6-9 프로젝트 변경 대장 방식 — 일정·자원·산출물 변경은 각 기능(WBS-006·CFT-002·ACT-005·DLV-004)에서 결재하고 결과만 대장에 RECORD로 기록, 비용·범위 변경만 CHG-001에서 요청·결재. 권고: 승인(같은 변경을 두 곳에서 결재하지 않음)
- [ ] DP6-10 PROJECT_ROLE 결재선 해석 규칙 — 같은 역할 복수 구성원은 병렬(액티비티 담당이 있으면 그 사람으로 좁힘), 기안자 본인으로 해석되면 기안자 부서장으로 대체, 산출물별 결재선은 템플릿 VariantKey(표준 산출물의 ApprovalVariantKey). 권고: 승인
- [ ] DP6-11 양산 초기 NCR·클레임 수 산정 — (권고) 프로젝트 품번과 같은 품번·같은 생산 공장의 NCR·클레임만(연결 대장 기준, 대장이 기간을 덮지 못하면 Snowflake 등록 쿼리). 대안: SAP BOM 하위 부품의 협력사 NCR까지 포함(Snowflake CORE.SAP_BOM 전개, 공수 +2)
- [ ] DP6-12 SAP 비용 실적·원가시스템(CIS)·MES·신뢰성 시스템과 PMS 직접 연계 — (권고) 만들지 않는다. SAP·MES 데이터는 Vol.9가 Snowflake에 적재한 것을 PMS 대시보드가 쓰고, 신뢰성 시험 결과는 QMS 인정시험 판정으로 받는다. 원가시스템은 SL 확인 후 별도 WI
- [ ] DP6-13 BPA 변경 반영 — ACTIVE 표준 WBS는 자동으로 바꾸지 않고 PMO To-Do로 새 버전·차이 유지를 결정. 표준 WBS 활성화 시 BPA 폐기(OBSOLETE)·미존재(NOT_FOUND) 액티비티는 경고만(권고) 또는 차단
- [ ] DP6-14 ALM(Codebeamer) 연계 범위 — PMS는 읽기만(릴리스 일정·상태, SOR 연결 요구사항 상태), PMS 일정 자동 변경 없음, Codebeamer 전체 항목은 Snowflake에만 적재(IF-ALM-004 권장). 권고: 승인
- [ ] DP6-15 PMS 통합 사용자 2개(pms-int-ext: BPA·부품개발·PDM·ALM, pms-int-fin: HR·DMS 비용) — Vol.9 QMS 통합 사용자 3개와 합쳐 Integration User 라이선스 5개. 권고: 승인

## 2. Vol.0 변경 요청 (135건, 대상순)

| 대상 | 요청 Vol. | 변경 내용 | 근거 |
| --- | --- | --- | --- |
| 3.3 DoD | Vol.7 | 새 KPI를 만드는 WI는 QMS_KpiDefinition__mdt 레코드와 라벨 3개 언어를 같은 WI에서 추가 | DSH-001 BR-1 |
| 3.3 DoD | Vol.P5 | PMS KPI를 만드는 WI도 QMS_KpiDefinition__mdt 레코드와 라벨 3개 언어를 같은 WI에서 추가 | DSH-001 BR-5 |
| CMN-00-AI-001 | Vol.8 | SL Quality Assistant 토픽 목록은 Vol.8 AIQ-001이 정의, 기능 스위치 키 QMS_AI_RCA·QMS_AI_8D·QMS_AI_LELE·QMS_AI_QA·QMS_AI_EW·QMS_AI_4M_TEST·QMS_AI_AUDIT_PREP 등록 | AIQ-001 |
| CMN-00-AI-001 | Vol.P5 | SL Project Assistant 토픽 목록은 AIP-004가 정의. 기능 스위치 키 PMS_AI_SCHEDULE, PMS_AI_SCHEDULE_ADJUST, PMS_AI_DLV_DRAFT, PMS_AI_EW, PMS_AI_QA, PMS_AI_SOR | AIP-004 |
| CMN-00-AI-002 | Vol.8 | DocClass INDEX_SCOPE가 NONE이면 색인 제외(EXCLUDED) | AIQ-013 |
| CMN-00-AI-002 | Vol.P5 | `CMN_DocTextService.getChunks(Id revisionId, Integer maxChars)` — 색인 단계에서 추출한 텍스트를 쪽·제목 경로가 붙은 청크로 Apex에 제공(USER_MODE 접근 확인 포함). AI-003 비교도 같은 서비스 사용. PMS DocClass의 INDEX_SCOPE 값(비용 증빙 NONE) | AIP-002, AIP-005, AIP-004 BR-9 |
| CMN-00-AI-004 | Vol.3 | UseCase 값 QMS_COA_ANOMALY 추가 | IQC-008 |
| CMN-00-AI-004 | Vol.6a | UseCase 값 QMS_4M_TEST(4M 필요 시험 추천) 추가 — QMS-08에서 확정 | 4MC-003 화면 자리 |
| CMN-00-AI-004 | Vol.7 | Vol.8이 정한 UseCase별 키 규칙(AI_HIT_TOP1·TOP3·ADOPT_RATE_{UseCase}, AI_HIT_TOP5_QMS_LELE) 반영 — Vol.8 변경 요청과 같음, 이 Vol.은 레지스트리 등록만 | DSH-012 |
| CMN-00-AI-004 | Vol.8 | UseCase 값 QMS_AUDIT_PREP 추가(QMS_4M_TEST·QMS_COA_ANOMALY 요청과 함께 확정), CMN_AiRecommendation__c.FinalizedAt__c(DateTime) 추가, 정확도 KPI 키 규칙 `AI_HIT_TOP1_{UseCase}`·`AI_HIT_TOP3_{UseCase}`·`AI_ADOPT_RATE_{UseCase}` 명시(QMS_LELE는 TOP5 추가) | AIQ-006, AIQ-015 |
| CMN-00-AI-004 | Vol.P1 | UseCase PMS_SOR_EXTRACT(계약에 이미 변경 요청 있음). 이 Vol.은 createDrafts API만 제공 | SOR-001 BR-9 |
| CMN-00-AI-004 | Vol.P4 | UseCase 값 PMS_DOC_ANOMALY 추가(계약 7절에 이미 명시) | GAT-005 BR-3 |
| CMN-00-AI-004 | Vol.P5 | UseCase 값 PMS_SCHEDULE_ADJUST·PMS_SOR_EXTRACT 추가(PMS_DOC_ANOMALY는 Vol.P4 요청). CMN_AiRecommendation__c.ContextRecordId__c(Text 18, 인덱스)·RunKey__c(Text 40) 추가 — 실행 묶음과 프로젝트 단위 조회. Vol.8이 요청한 FinalizedAt__c 사용 | 3절, AIP-001·003·005 |
| CMN-00-AI-005 | Vol.8 | BR-1(b) 공장 권한 강제 방식을 세션 공장 범위 표 + 행 접근 정책으로 구체화, 품질 골든 평가셋 위치 `docs/ai/eval/qms/` | AIQ-010 |
| CMN-00-AI-005 | Vol.P5 | PMS 골든 평가셋 위치 `docs/ai/eval/pms/` | AIP-004 BR-12 |
| CMN-00-APV-001 | Vol.P1 | (필수) __Share 객체가 없는 대상(Master-Detail 하위)에서 submit이 실패하지 않게 한다. 현재 구현은 `Schema.{객체}__Share` 타입이 없어 예외가 난다. CMN_ApprovalType__mdt.TargetShareMode__c(TARGET 기본, TOP_MASTER = 최상위 마스터에 결재자 Read 공유, NONE = 업무 WI가 접근 책임) 추가 | CFT-002(NONE), SOR-001(TOP_MASTER), Vol.P3·P4의 결재 대상 대부분 |
| CMN-00-APV-002 | Vol.2 | 유형별 결재선 기여 인터페이스(CMN_ApprovalLineContributor) 추가 — DVQ-005 BR-4, DVQ-008 BR-5 |  |
| CMN-00-APV-002 | Vol.2 | APPROVAL_ROLE 값 추가: LAB_RECEIVER(시험 접수자), SUPPLIER_QUALITY(협력사 품질 담당) |  |
| CMN-00-APV-002 | Vol.3 | APPROVAL_ROLE 값: SQ_MANAGER(협력사 품질팀장), IQC_LEAD(수입검사 반장). SUPPLIER_QUALITY는 Vol.2 요청과 같음 | IQC-004·005, PPA-004, PIS-003 |
| CMN-00-APV-002 | Vol.4 | APPROVAL_ROLE 값 LELE_OWNER(품질경영팀 레슨런 관리자). Role 해석을 공개 메서드(예: CMN_RoleResolver.resolveUser(roleCode, plantId, deptId))로 제공 | LEL-001, RPP-001 BR-4 |
| CMN-00-APV-002 | Vol.5 | APPROVAL_ROLE 값 CQ_MANAGER(고객품질팀장) | CLM-004·007·009·010·011 |
| CMN-00-APV-002 | Vol.6a | APPROVAL_ROLE 값 PE_MANAGER(생산기술팀장) 추가 | 4MC-005 BR-2 |
| CMN-00-APV-002 | Vol.6b | APPROVAL_ROLE 값 METROLOGY_LEAD(측정기 관리 책임), LAB_MANAGER(분석실 책임자), TRAINING_COORDINATOR(공장 교육 담당). LAB_RECEIVER는 Vol.2 요청 값을 분석실 접수에도 사용 | GAU-002~004, LAB-002·003, TRN-001~003 |
| CMN-00-APV-002 | Vol.6c | APPROVAL_ROLE 값 QMS_MANAGER(품질경영팀장: 심사 프로그램·보고서 승인, 자격·독립성 예외) | IAU-002·003·006, CER-001, IMP-001 |
| CMN-00-APV-002 | Vol.P1 | ResolverType RECORD_FIELD가 Master-Detail 하위 대상(PMS_CftMember__c)의 경로 `Department__r.Manager__c`를 상신자 권한으로 해석하는지 확인 | CFT-002 |
| CMN-00-APV-002 | Vol.P2 | APPROVAL_ROLE 값 PMO_MANAGER(PMO 책임자). 결재선 기여 인터페이스 CMN_ApprovalLineContributor(Vol.2 요청과 같음)를 PMS 결재 4종이 사용 | WBS-005·006·009, ACT-004 |
| CMN-00-APV-002 | Vol.P4 | APPROVAL_ROLE 값 PMO_MANAGER(PMO 팀장)·BU_HEAD(사업부장·연구소장) 추가. 결재선 기여 인터페이스 CMN_ApprovalLineContributor(Vol.2 요청과 같음)를 PMS도 사용 | RSK-001 BR-8, ISS-001 BR-4, GAT-004 BR-4 |
| CMN-00-APV-002 | Vol.P6 | ResolverType PROJECT_ROLE 플러그인: 인터페이스 `CMN_ApprovalStepResolver`(resolve, isValidRoleCode)와 등록 메타데이터 `CMN_ApprovalResolverPlugin__mdt`(제안). 현재 `CMN_ApprovalLineResolver`는 PROJECT_ROLE에서 ResolverNotSupported 예외를 던지므로 플러그인 호출로 바꾸고, 결과 여러 명이면 같은 StepNo 병렬 단계로 펼친다. 템플릿 단계 저장 시 플러그인 isValidRoleCode 검증 | PMS-12-APV-001 BR-1·2 |
| CMN-00-APV-002 | Vol.P6 | 템플릿 VariantKey: `CMN_ApprovalTemplate__c.VariantKey__c`, `CMN_ApprovalType__mdt.VariantFieldPath__c`, 선택 순서 (유형, 키, 공장) → (유형, 키, 공란) → (유형, 공란, 공장) → (유형, 공란, 공란) | APV-001 BR-6 |
| CMN-00-APV-002 | Vol.P6 | 공장 경로: `CMN_ApprovalType__mdt.PlantFieldPath__c`(기본 Plant__c). 현재 해석기는 대상의 Plant__c만 읽어 PMS 객체(ProdPlant 경로)에서 공장별 템플릿이 선택되지 않음 | APV-001 데이터 모델 |
| CMN-00-APV-002 | Vol.P6 | APPROVAL_ROLE 값 추가: PMS_COST_ADMIN(원가·예산 관리), PMS_PMO_LEAD(PMO 리더), PMS_DIRECTOR(연구소장·개발본부장, SOP 영향 변경 승인) | INT-002 BR-4, INT-003 BR-7, PRF-001 BR-2, CHG-001 BR-6 |
| CMN-00-APV-003 | Vol.P1 | (선택) CMN_ApprovalType__mdt.ActionPanel__c — 결재 처리 화면에 유형별 입력 LWC를 끼우는 자리. 있으면 CFT 담당 지정을 결재 화면에서 바로 한다. 없으면 CFT 요청함으로 처리(현재 본문) | CFT-002 BR-3 |
| CMN-00-ARC-001 | Vol.5 | Multi-Currency 활성화 전제(D-3) | CLM-010 |
| CMN-00-ARC-001 | Vol.P2 | DKBMC 사전 보유 자산(연구소 간트) 패키지 디렉터리 추가(가칭 force-app-dkbmc, 오픈 이슈 3 결정) | WBS-008, DP2-3 |
| CMN-00-ARC-002 | Vol.P6 | "객체당 트리거 1개"를 플랫폼 이벤트에는 "구독 패키지당 트리거 1개"로 명시(QMS 이벤트를 QMS·PMS가 각자 구독) | INT-005 BR-16 |
| CMN-00-ARC-003 | Vol.4 | 공장 토큰 없는 전사 연번 패턴(LL-, LA-) 지원 확인(ScopeField 공란) | LEL-001·005 |
| CMN-00-ARC-003 | Vol.P2 | 공장 토큰 없는 전사 연번(ACT-, SCH-, ASG-) 지원 확인(Vol.4 요청과 같음) | ACT-001, WBS-006, ACT-005 |
| CMN-00-DOC-001 | Vol.3 | CMN_Document__c에 Supplier__c·SupplierVisible__c 추가, SharingConfig SupplierField 등록, 협력사 공개 파일 ContentDocumentLink Visibility = AllUsers | SPP-002 BR-3·4, PPA-004 BR-4 |
| CMN-00-DOC-001 | Vol.P1 | 서약 양식 파일(CMN_DocTemplate__c, DocClass SECURITY_PLEDGE)이 모든 사내 사용자에게 미리보기·내려받기 가능한지 확인(파일 공유 방식) | CFT-003 |
| CMN-00-DOC-001 | Vol.P4 | 데이터 모델 표에 구현된 CMN_DocumentRevision__c.IsDuplicateFile__c·DuplicateOfRevision__c를 BR-5 경고 플래그 필드로 명시 | GAT-005 BR-2 |
| CMN-00-DSH-001 | Vol.7 | CMN_Widget__mdt에 ConfigSchema__c·AvailableSystems__c·MobileSupported__c 추가. 보드 편집 모드에서 `cmnWidgetConfigForm` 호출, 설정 검증 인터페이스 CMN_WidgetConfigValidator. Persona 값 QM_HEAD·VIEWER·SYSTEM_ADMIN 추가. 템플릿 해석기 인터페이스 CMN_DashboardTemplateResolver + 등록 메타 CMN_DashboardResolver__mdt(템플릿 선택·config 토큰 치환). 템플릿 복사 시 미배포·비활성·권한 없는 위젯 건너뛰기. QMS 보드 고객 필터(선택) | DSH-004, DSH-013 |
| CMN-00-DSH-001 | Vol.P5 | CMN_DashboardTemplate__mdt.Persona__c 값 PMO, CFT, TEAM_LEAD 추가(EXECUTIVE·PM·MDT는 있음). Vol.7이 요청한 해석기 인터페이스 CMN_DashboardTemplateResolver·등록 메타 CMN_DashboardResolver__mdt에 System PMS 행 허용. 보드 공통 필터를 System별로(PMS: 공장·기간·고객·차종). 템플릿 복사 때 미배포·비활성·권한 없는 위젯 건너뛰기(Vol.7 요청과 같음) | DSH-001 BR-12·13 |
| CMN-00-DWH-001 | Vol.4 | CORE 테이블 추가: SPC_SUBGROUP, SPC_SIGNAL, SPC_CAPABILITY, SPC_CONSTANTS, SPC_RULE_DEF, MES_PRODUCTION, MES_DEFECT, EOL_TEST_RESULT(SPC_MEASUREMENT는 기존 이름 유지, 컬럼 확정) | SPC-002·003, EFC-002, FQC-004 |
| CMN-00-DWH-001 | Vol.8 | ML 스키마 객체(코퍼스·검색 서비스·위험 테이블), 역할 ROLE_AI_SERVICE, SNOWFLAKE.CORTEX_USER 권한, Resource Monitor 대상에 Cortex 사용량 포함 | AIQ-002, AIQ-011 |
| CMN-00-DWH-001 | Vol.9 | RAW 표준 열에 `_SOURCE_KEY` 추가, 공용 SAP·MES·로트 계보 RAW·CORE 테이블 목록과 소유(QMS-09) 기재 | INT-001 BR-6, INT-008·012 |
| CMN-00-DWH-001 | Vol.P5 | MART.DATA_FRESHNESS SOURCE_KEY PMS_PROJECT_SNAPSHOT, PMS_RISK_SCORE, PMS_DURATION_STATS | DSH-001, AIP-001, AIP-003 |
| CMN-00-DWH-001·002 | Vol.P6 | RAW.DMS_DEV_COST·DMS_TOOL_MODIFICATION·ALM_ITEM, CORE.DMS_DEV_COST·ALM_ITEM 등록. CMN_DwhSyncConfig__mdt에 PMS_SystemLink__c·PMS_ProjectChange__c·PMS_ProjectPerformance__c·PMS_SupplierCostStage__c(15분), PMS_ProcessDefinition__c(일), 금액 열 제외 기능(ExcludedFields__c, 제안) | 3절 공통 기반, PRF-001 BR-10 |
| CMN-00-DWH-002 | Vol.P5 | PMS 업무 객체 복제 대상(DSH-001 BR-2 목록), CMN_ActionItem__c 복제(15MIN), 민감 객체(PMS_LaborRate__c, PMS_PeerEvaluation__c)·비용 필드 복제 제외 원칙 | DSH-001 BR-2, DSH-004 BR-9 |
| CMN-00-DWH-003 | Vol.4 | KPI 예시 키 QMS_CPK → QMS_SPC_CPK로 변경(이름 통일) | SPC-003 |
| CMN-00-DWH-003 | Vol.5 | CMN_KpiValue__c에 Vehicle__c(Lookup CMN_Vehicle__c) 차원 추가 | B2B-003 BR-5 |
| CMN-00-DWH-003 | Vol.6b | CMN_KpiValue__c에 차원 Department__c(Lookup CMN_Department__c) 추가, ExternalKey 해시에 포함. 6b의 QMS_TRN_PLAN_RATE Department 차원이 이 변경을 기다리는 상태(반영 전에는 Plant 단위만 적재) | TRN-003 BR-9, 3절 KPI 표 주석 |
| CMN-00-DWH-003 | Vol.6c | CMN_KpiValue__c.PeriodType__c에 QUARTER 추가(Vol.7 요청과 같음). 추가 전에는 QMS_AUDIT_REPEAT_RATE, QMS_SUPPLIER_GRADE_COUNT_A~D 적재 보류 | 3절, IAU-007 BR-4, SQM-002 BR-5 |
| CMN-00-DWH-003 | Vol.7 | CMN_KpiValue__c.PeriodType__c에 QUARTER 추가, 차원 Department__c·Vehicle__c·ProductGroup__c 추가(Vol.5·Vol.8 요청과 같음), (KpiKey, PeriodType, PeriodStart) 조회 인덱스 요청, 내부 OWD Public Read Only·외부 Private 명시. 공통 RAG UDF MART.F_KPI_RAG와 MART.KPI_RAG_RULE을 DWH 공통 자산으로. 적재 완료 이벤트 CMN_KpiLoaded__e. 예시 키 QMS_CPK → QMS_SPC_CPK | DSH-001, DSH-002, DSH-005 BR-4, DSH-010 BR-3 |
| CMN-00-DWH-003 | Vol.8 | CMN_KpiValue__c에 ProductGroup__c 차원 추가(제품군 위험 점수, Vol.5 Vehicle__c 요청과 함께) | AIQ-011 |
| CMN-00-DWH-003 | Vol.9 | CMN_ResultInbound__e를 Snowflake 외 원천(Mule 발행)에도 사용, EventType 명명·ExternalEventId·schemaVersion 규약 명시 | INT-002 BR-5 |
| CMN-00-DWH-003 | Vol.P1 | CMN_KpiValue__c.Department__c(Lookup CMN_Department__c) 차원 추가 | EFF-003 |
| CMN-00-DWH-003 | Vol.P5 | CMN_KpiValue__c 차원 Department__c·Vehicle__c·ProductGroup__c(Vol.5·7·8 요청과 같음). PMS KPI 뷰 MART.V_SF_KPI_PMS·MART.V_SF_KPI_PMS_EW 적재 등록. 비용 KPI 금지 원칙을 PMS에도 명시 | DSH-001 BR-4, DP5-3 |
| CMN-00-DWH-003 | Vol.P6 | EVENT_TYPE PMS_DMS_UNMAPPED, PMS_DMS_RECON_GAP 라우팅(핸들러 PMS 소유), KPI 키 PMS_PRF_*·PMS_CHG_COUNT·PMS_INT_FAILED | INT-003 BR-7·8, 3절 KPI |
| CMN-00-DWH-004 | Vol.6a | Wave W2 → W1(4M 영향 범위 BOM 조회·적용 시점 로트 추적·NCR 봉쇄 후보가 W1 PoC 시나리오 1·3에 필요) | 4MC-003, 4MC-007, NCR-003 |
| CMN-00-DWH-004 | Vol.6b | CMN_DwQuery__mdt에 Mode__c(QUERY, PROCEDURE) 추가, `CMN_DwQueryService.callProcedure(queryKey, params)` — Mule이 ROLE_TRANSFORM 연결로 등록 프로시저만 실행, 타임아웃 60초, 응답 VARIANT 최대 1MB | MSA-003 BR-1 |
| CMN-00-DWH-004 | Vol.7 | 포털 사용자 호출 시 공장 필터 대신 협력사 필터 강제 모드(파라미터명은 QMS_WidgetQuery__mdt.SupplierParam) | DSH-002 BR-4 |
| CMN-00-DWH-004 | Vol.8 | Mule API에 SEARCH(Cortex Search)·ANALYST(Cortex Analyst) 연산 추가(prc-ai-snowflake-api), PROCEDURE 모드(Vol.6b 요청과 동일)로 QMS_RCA_RANK 호출 | AIQ-002, AIQ-003, AIQ-010 |
| CMN-00-DWH-004 | Vol.9 | Mode__c 값 QUERY·PROCEDURE·SEARCH·ANALYST(Vol.6b·8 요청), callProcedure, Warehouse__c, 모드·키별 동시 실행 한도, 공통 오류 응답 형식 | INT-020 BR-1·3·4 |
| CMN-00-DWH-004 | Vol.P6 | 쿼리 키 PMS_DMS_COST_DETAIL, PMS_PRF_EARLY_QUALITY, PMS_PRF_COST_TOTAL과 쿼리별 실행 역할(원가 쿼리는 ROLE_FINANCE_READ) | INT-003 BR-11, PRF-001 BR-5 |
| CMN-00-INT-001 | Vol.7 | 인터페이스 IF-SF-002(Salesforce KPI 정의 → Snowflake MART.KPI_RAG_RULE, 일 1회) 카탈로그 추가 | DSH-001 BR-3 |
| CMN-00-INT-001 | Vol.9 | 카탈로그에 3절 인터페이스 28건 등록, 통합 사용자를 도메인별 3개(SAP·MES/DW·외부 시스템)로 분리, 이벤트형 인터페이스 로그를 1분 묶음으로 남기는 규칙 추가 | INT-001 BR-5·8 |
| CMN-00-INT-001 | Vol.P6 | 카탈로그에 IF-BPA-001, IF-HR-002·003, IF-DMS-001·002, IF-PDS-004·005, IF-PDM-001·002, IF-ALM-001~004 등록. PMS 통합 사용자 2개(pms-int-ext, pms-int-fin)와 PS. Named Credential PMS_Mule_Bpa·Hr·Pdm·Alm | 4절 |
| CMN-00-INT-002 | Vol.P6 | 오픈 이슈 "PMS 임율 데이터 제공 범위"를 PMS-12-INT-002로 해소(법인 × 직급 평균, 표본 3명 이상, 개인 급여 미수신). sys-hr-api에 임율·평가 엔드포인트 추가 | INT-002 BR-1·2 |
| CMN-00-INT-003 | Vol.9 | 자재·공급업체·구매정보레코드 단건 즉시 동기화 API(Mule prc) 제공 | INT-004 BR-4 |
| CMN-00-MDM-001, INT-002 | Vol.P1 | (선택) CMN_Employee__c.JobFunctionCode__c(HR 직무 코드) — CFT 후보를 역할에 맞는 직무로 정렬 | CFT-001 BR-8 |
| CMN-00-MDM-002(또는 신규 CMN-00-MDM-008 제안, 2 M/D) | Vol.P2 | 공장 근무 달력: CMN_WorkCalendar__c(Code, Plant, WeekendDays, IsPlantDefault, IsActive), CMN_WorkCalendarDay__c(Calendar MD, Date, DayType HOLIDAY·WORKDAY, 사유), CMN_WorkCalendarService(getWorkingDays, isWorkingDay, addWorkingDays, countWorkingDays, Platform Cache 1시간), 연도별 CSV 가져오기. APV-003·005 체류일 영업일 기준(오픈 이슈)과 Vol.6b LAB 영업일에도 쓴다 | WBS-004 BR-2, DP2-2 |
| CMN-00-MDM-003 | Vol.5 | Account.RootCauseDueDays__c(원인 회신 기한, 기본 10일) 추가. ClaimFormTemplate 값 확정 | CLM-007 BR-3 |
| CMN-00-MDM-003 | Vol.6a | Account(고객)에 ChangeNoticeLeadDays__c(4M 사전 통보·승인 기한 일수), ConcessionCustomerApproval__c(특채 시 고객 승인 필요) 추가 — CSR 필드 | 4MC-001 BR, 4MC-005 BR-6, NCR-003 BR-5 |
| CMN-00-MDM-003 | Vol.P1 | CMN_Vehicle__c.PredecessorVehicle__c(Lookup self, 차종 계보) 추가 — Vol.4 LEL 후속 모델 매칭(오픈 이슈 해소) | PRJ-001 BaseProject와 함께 |
| CMN-00-MDM-004 | Vol.5 | CMN_ItemVehicle__c.UsagePerVehicle__c(차량당 사용 수량, 기본 1) 추가 | B2B-003 BR-1 |
| CMN-00-MDM-005 | Vol.3 | PpapStatus·InspectionLevel은 QMS-03 서비스만 변경(사용자 FLS Read), PpapStatus 필드 이력 추가, 운영 시작 시 현행 승인 부품 APPROVED 이관 | IQC-005 BR-7, PPA-004 BR-5 |
| CMN-00-MDM-005 | Vol.6c | Account.SupplierGrade__c는 SQM-003 서비스만 변경(사용자 FLS Read), 필드 이력 추적 | SQM-003 BR-2 |
| CMN-00-MDM-007 | Vol.2 | 코드 그룹 추가: CHANGE_TYPE(4M 변경 유형), DOC_CLASS 값 TEST_REPORT·TEST_PHOTO·DVPR |  |
| CMN-00-MDM-007 | Vol.3 | DOC_CLASS 값: SUPPLIER_COA, IQC_PHOTO, PPAP 하위 요소 코드(PPAP > DESIGN_RECORD 등), PPAP_APPROVAL_NOTICE. 코드 그룹: IQC_COMMON_CHECK | IQC-001·003·006, PPA-001·004 |
| CMN-00-MDM-007 | Vol.4 | 코드 그룹 DEV_PHASE(개발 단계), DEV_ACTIVITY_TYPE(표준 WBS 액티비티 유형, 2레벨, 초기값에 PAST_ISSUE_REVIEW 포함 — 9절 머리말) 추가, 관리 주체 품질경영팀 + PMO. DOC_CLASS 값 OCAP_EVIDENCE, CUSTOMER_COA, HZD_EVIDENCE, LELE_EVIDENCE, LELE_APPLY_EVIDENCE, PPAP_PACKAGE, PPAP_CUSTOMER_APPROVAL, PPAP > SUB_COMPONENT | LEL-001·003, SPC-005, FQC-005, HZD-003, RPP-002·004 |
| CMN-00-MDM-007 | Vol.5 | DOC_CLASS 값: EIGHTD_REPORT, EIGHTD_EVIDENCE, EIGHTD_TEMPLATE, CLAIM_CUSTOMER_DOC, CLAIM_COST_EVIDENCE, B2B_SOURCE_FILE, CUSTOMER_SCORECARD, WORK_INSTRUCTION, COMPANY_STANDARD, DESIGN_GUIDE. 코드 그룹 ALERT_DISMISS_REASON. CAUSE_5M1E를 계층(최대 3레벨) 코드로 운영(AI 적중 판정 단위) | B2B-005, CLM-001·004·006·010 |
| CMN-00-MDM-007 | Vol.6a | CHANGE_TYPE 3레벨 초기 값(4MC-001 BR-1), DISPOSITION 코드 값 SCRAP·REWORK·SORT·CONCESSION·RETURN·USE_AS_IS_OK, DOC_CLASS 값 FOURM_REQUEST·FOURM_EVIDENCE·NCR_PHOTO·NCR_NOTICE·NCR_EVIDENCE, DEFECT_TYPE Attribute1 = SAFETY 규칙 | 4MC-001, NCR-002·003·004 |
| CMN-00-MDM-007 | Vol.6b | 코드 그룹 GAUGE_TYPE(계층, Attribute1 기본 교정 주기 월, Attribute2 교정 구분, Attribute3 MSA 대상 Y/N). DOC_CLASS 값 LIMIT_SAMPLE_PHOTO, LIMIT_SAMPLE_CUSTOMER_APPROVAL, LIMIT_SAMPLE_CHECK_PHOTO, TRAINING_MATERIAL, TRAINING_CERT, QUALIFICATION_CERT, CALIBRATION_CERT, GAUGE_DISPOSAL_CONSENT, MSA_REPORT, MSA_CHART, LAB_RAW_DATA, LAB_IMAGE, LAB_EXTERNAL_REPORT, LAB_REPORT | GAU-001, LMS-001·002, TRN-001~003, GAU-002·003, MSA-005, LAB-001·003 |
| CMN-00-MDM-007 | Vol.6c | 코드 그룹 QMS_PROCESS(회사표준 프로세스 목록, Attribute1 = 책임 부서 코드, Attribute2 = 적용 공장 코드) | IAU-001·002·006 |
| CMN-00-MDM-007 | Vol.6c | DOC_CLASS 값: AUDIT_REPORT, AUDIT_EVIDENCE, AUDIT_EVIDENCE_PACKAGE, AUDIT_PREP_DOC, FINDING_EVIDENCE, CUSTOMER_AUDIT_REPORT, CUSTOMER_AUDIT_RESPONSE, CERT_SL, CB_REPORT, CB_RESPONSE, MGMT_REVIEW_INPUT, IMP_DELIVERABLE | IAU-003~005, SAU-002, CAU-003, CER-001·002, IMP-001 |
| CMN-00-MDM-007 | Vol.8 | DOC_CLASS Attribute2 = INDEX_SCOPE(QMS_KNOWLEDGE, NONE) 규칙, AI_EXCLUDE_REASON 값 "적용 대상 아님"·"기타" 추가 | AIQ-006, AIQ-013 |
| CMN-00-MDM-007 | Vol.P1 | 코드 그룹 추가: CUSTOMER_MILESTONE(Attribute1 고객 그룹, Attribute2 유형 BUILD·SUBMISSION·APPROVAL·SOP·EOP·OTHER, Attribute3 SOP 기준 기본 오프셋 주), PROJECT_ROLE(값 11개, Attribute1 기본 권한, Attribute2 팀장 승인 필요, Attribute3 HR 직무 코드), SOR_CATEGORY(2레벨, Attribute1 기본 검증 방법, Attribute2 기본 책임 역할). DOC_CLASS 값 추가: NOMINATION_LETTER, CUSTOMER_SCHEDULE, SOR_DOCUMENT, COMPLIANCE_MATRIX, SECURITY_PLEDGE(Attribute1 서명 방식), SECURITY_PLEDGE_SIGNED. 코드 관리 권한을 PMS_PSG_PMO에도 할당 | PRJ-001·003, SOR-001, CFT-001·003 |
| CMN-00-MDM-007 | Vol.P2 | 코드 그룹 SUPPLIER_MILESTONE(초기값 DESIGN_FREEZE, TOOL_KICKOFF, T0, T1, T2, ISIR, PPAP_SUBMIT, PPAP_APPROVED, MASS_READY). DOC_CLASS 값 PMS_SCHEDULE_EVIDENCE. DEV_PHASE·DEV_ACTIVITY_TYPE(Vol.4 요청) 관리 주체에 PMO 포함 | WBS-010, WBS-006 |
| CMN-00-MDM-007 | Vol.P4 | 코드 그룹 RISK_CATEGORY(2레벨)·ISSUE_TYPE(2레벨) 추가, DOC_CLASS 값 ISSUE_COUNTERMEASURE·GATE_MINUTES·RUN_AT_RATE·LAUNCH_READINESS, MEETING_TYPE 값 GATE_REVIEW 확정 | 3절 공통 코드 |
| CMN-00-MDM-007 | Vol.P5 | DOC_CLASS 값 PMS_REPORT, PMS_DECISION. AI_EXCLUDE_REASON 값 "고객 일정 고정", "자원 제약", "기간 과소", "기간 과다", "다른 안 채택", "이미 등록됨", "추출 오류". APPROVAL_ROLE 값 PLANT_PMO(공장 PMO — 보고 작성·검토), MDT_LEADER(차종 개발 총괄, DP5-11) | DSH-003, DSH-001, AIP-001·005 |
| CMN-00-MDM-007 | Vol.P6 | 코드 그룹 PMS_CHANGE_REASON, PMS_CHANGE_RESPONSIBILITY. DOC_CLASS 값 CUSTOMER_CHANGE_REQUEST | CHG-001, CHG-002 |
| CMN-00-MTG-001 | Vol.6c | 회의 유형 값 MANAGEMENT_REVIEW 추가, 회의를 부모로 한 문서 등록(DOC-001) 확인 | CER-001 BR-5, CER-002 BR-5 |
| CMN-00-MTG-001 | Vol.P5 | CMN_ActionItem__c.SourceObject__c(Text 80)·SourceRecordNo__c(Text 40) 추가. 조치 항목 상태 변경 훅 `CMN_ActionItemHook__mdt`(SourceObject → 핸들러 클래스, 인터페이스 CMN_ActionItemHook.onStatusChanged). 회의 레코드 페이지에 PMS 결정 그리드 조건부 배치 | DSH-004 BR-3·4·6 |
| CMN-00-NTF-001 | Vol.3 | BR-5 링크 변환을 인터페이스 CMN_RecipientUrlResolver + Custom Metadata 등록 방식으로 명시(CMN이 QMS 클래스를 직접 참조하지 않게) | SPP-001 BR-6 |
| CMN-00-QNR-001 | Vol.P4 | (1) 활성화 시 도메인 검증 훅(예: 인터페이스 `CMN_QuestionnaireDomainValidator`, 도메인별 등록)으로 GATE 템플릿의 자동 점검 규칙 키를 검사, (2) Snapshot에 AutoCheckRuleKey·AutoCheckParams·ScopeKeys·EvidenceKeys·PreviousItemKey·MappingType·IsMandatory·Weight가 모두 포함됨을 명시 | GAT-002 BR-4, GAT-003 BR-1 |
| CMN-00-SEC-001 | Vol.2 | 페르소나 추가: QMS_PSG_DevEngineer(개발팀, 제품 인정시험 계획 작성), QMS_PSG_LabTester(신뢰성·광학 시험 담당) |  |
| CMN-00-SEC-001 | Vol.3 | PSG 추가: QMS_PSG_SupplierPortal(협력사 포털 사용자) | SPP-001 |
| CMN-00-SEC-001 | Vol.4 | PSG 추가 QMS_PSG_ProcessEngineer(생산기술·공정 담당: SPC 알람·OCAP, 수평전개 실행). PMS PSG(PM·CFT·PMO)에 QMS_PS_Lele_Read·QMS_PS_Lele_Edit 포함 | SPC-005, LEL-005 |
| CMN-00-SEC-001 | Vol.5 | Public Group QMS_GRP_CUSTOMER_QUALITY(고객 품질 담당 전원) 운영 규칙 | B2B-005·006, CLM-007 |
| CMN-00-SEC-001 | Vol.6a | Viewer PSG에 QMS_PS_FourM_Request·QMS_PS_Ncr_Create·QMS_PS_Ncr_Respond 추가, Custom Permission QMS_ViewCost를 비용 PS에 포함 | 3절 PS 매핑, NCR-007 BR-3 |
| CMN-00-SEC-001 | Vol.6b | PSG 추가: QMS_PSG_Metrology(측정기·교정 담당), QMS_PSG_TrainingCoordinator(공장 교육 담당). Vol.2 요청 QMS_PSG_LabTester의 범위에 분석실 분석자 포함 | 3절 매핑 |
| CMN-00-SEC-001 | Vol.6c | Custom Permission QMS_AuditFindingAnyEdit 정의(QualityAdmin PSG) | IAU-004 BR-12 |
| CMN-00-SEC-001 | Vol.7 | Custom Permission QMS_DashboardAllPlants(CMN_PSG_Executive, QMS_PSG_QualityAdmin 포함, 품질본부장은 PS QMS_PS_Dashboard_AllPlants 개별 부여), 모든 QMS PSG에 QMS_PS_Dashboard_Base | DSH-002 BR-1 |
| CMN-00-SEC-001 | Vol.8 | QMS_PS_Ai_User·QMS_PS_Ew_Edit·QMS_PS_Ai_Admin을 PSG에 추가, Agentforce 사용 권한 셋 라이선스 할당 규칙 | 3절 |
| CMN-00-SEC-001 | Vol.P2 | PMS PSG에 3절 PS 매핑 반영 | 3절 |
| CMN-00-SEC-001 | Vol.P4 | PMS PSG(PM·CFT·TeamLead·PMO)에 CMN_PS_Questionnaire_Read 포함, PMS_PSG_PMO에 CMN_PS_Questionnaire_Admin + CMN_QnrAdmin_Gate | GAT-002 권한 |
| CMN-00-SEC-001 | Vol.P5 | PMS PSG에 이 Vol. PS 추가(3절 표), 모든 PMS PSG에 QMS_PS_Dashboard_Base 포함 | 3절 |
| CMN-00-SEC-001 | Vol.P6 | PSG 추가 PMS_PSG_HrEval(제안, HR 담당 수평평가 확정·전송). CMN_PSG_Executive의 View All에서 PMS_PeerEvaluation__c·PMS_LaborRate__c 제외 | PRF-002 BR-8 |
| CMN-00-SEC-001, UX-007 | Vol.P1 | PMS PSG 5개 내용(이 Vol. 3절)과 SL PMS 앱 할당을 UX-007 BR-1 표에 추가. SL PMS 내비게이션(8개 이내): 홈, 프로젝트, 내 주간 실적, 실적 승인, CFT 요청함, 자원 부하, 메뉴 허브. 메뉴 허브 그룹 PMS_02·PMS_03 | PRJ-001, CFT-002, EFF-002·003 |
| CMN-00-SEC-002 | Vol.3 | BR-4 협력사 공유 대상 = 협력사 Account 포털 Manager 역할 및 하위 그룹. BR 추가: 외부 OWD는 업무·CMN_Item__c Private, CMN_Plant__c·CMN_CodeGroup__c·CMN_Code__c만 Public Read Only, CMN_Item__c는 CMN_SupplierItem__c 기준으로 협력사 그룹에 Read 공유 | SPP-001 BR-4·5 |
| CMN-00-SEC-002 | Vol.4 | 지식 객체(QMS_LessonLearned__c, QMS_LeleCheckpoint__c, QMS_LeleApplication__c, QMS_HorizontalDeploy__c, QMS_HorizontalDeployTarget__c)는 SharingConfig 대상에서 빼고 내부 OWD Public Read Only(D-9 권고 확정 시) | HZD-001 BR-3, LEL-001 BR-5 |
| CMN-00-SEC-002 | Vol.5 | 지식 공유 규칙: CLOSED 8D를 "모든 내부 사용자"에 Read(Sharing Reason QMS_Knowledge) — D-9 결정과 함께 | CLM-001 BR-9 |
| CMN-00-SEC-004 | Vol.6a | Snowflake 역할 ROLE_QMS_COST 추가, NCR 비용 컬럼 Masking Policy | NCR-008 BR-4 |
| CMN-00-SEC-004 | Vol.9 | Mule 통합 사용자 3개와 권한 범위, Snowflake ROLE_INGEST의 RAW 개인정보(VIN) 접근 제한 재확인 | INT-001 BR-8, INT-014 BR-5 |
| CMN-00-SEC-004 | Vol.P6 | Snowflake 마스킹 대상에 DMS 금액(CORE.DMS_DEV_COST.AMOUNT)·PMS 복제 객체 금액 열 추가. Mule 로그 마스킹 목록(hourlyRate, avgScore, criteria, amount) | INT-002 BR-5, INT-003 BR-12 |
| CMN-00-TDO-001 | Vol.3 | 포털 사용자 Assignee 허용, 포털 사용자 To-Do는 TDO-003 포탈 API·TDO-004 사내 홈에서 제외 | SPP-002 BR-2 |
| CMN-00-TDO-001 | Vol.P2 | 열린 To-Do의 기한·제목 갱신 메서드 `refresh(List<CMN_TodoSpec>)`(지금 open은 OPEN이면 무시) | WBS-005 BR-7 |
| CMN-00-TDO-001, NTF-001 | Vol.P6 | 3절 SourceType 11개·EventCode 12개 등록(문구는 Custom Label) | 3절 |
| CMN-00-TDO-004 | Vol.P5 | SL PMS 홈의 보드 system = PMS, To-Do 기본 필터 PMS 설정은 PMS-10-DSH-001이 한다고 명시 | DSH-001 BR-14 |
| CMN-00-UX-001 | Vol.6b | 사원증 바코드(사번) 스캔을 BarcodeScanner 공통 유틸리티에 포함(교육 출석·MSA 평가자 등록) | TRN-002, MSA-002 |
| CMN-00-UX-004 | Vol.P1 | 허브 객체(PMS_Project__c)의 업무 영역 탭 허용과 check-record-pages.py 규칙 확인 | DP1-15 |
| CMN-00-UX-006 | Vol.P1 | (선택) 실행 시 필터 `@api filter`(허용 필드만, 고정 필터와 AND) — SOR 유효 요구사항이 500건을 넘는 프로젝트의 범주별 편집 | SOR-001 BR-2 |
| CMN-00-UX-006 | Vol.P4 | ParentField에 Text(18) 원천 Id 필드 허용(CMN_ActionItem__c.SourceRecordId__c처럼 다형 연결) | GAT-004 후속 조치 그리드 |
| CMN-00-UX-007 | Vol.P5 | SL PMS 메뉴 허브 그룹 "PMS 대시보드·보고"와 타일, 내비게이션 후보(홈, 메뉴 허브, 프로젝트, PMO 보드, 보고, 의사결정, 조기경보) — SL PMS 앱 소유 WI가 8개 이내로 확정 | DSH-001 BR-14 |
| CMN-00-UX-009 | Vol.P4 | CMN_Checklist.Question DTO에 autoResultLabel(String)·autoResultSeverity(String)·evidenceLinks(List: label, recordId)·anomalyCount(Integer) 추가, 카드에 자동 결과 배지·증빙 링크·이상 징후 확인 체크 표시. 반영 전에는 Provider가 guidance로 대체 | GAT-003 BR-8 |
| V0-1 | Vol.P3 | CMN-00-DOC-001 | 문서 부모 리스너: 인터페이스 `CMN_DocumentListener`(deliverableTypeFor(parentId, docClassId) — 문서 생성 시 유형 결정, afterRevisionChange(revisions) — 리비전 생성·상태 변경 후 같은 트랜잭션), 메타데이터 `CMN_DocumentListener__mdt`(ParentObject, ListenerClass, ApprovalHandledByParent — 패널 문서 단위 상신 숨김·서버 거부, LinkFilesToParent — 파일을 부모 업무 레코드에도 ShareType I로 연결). 문서 리비전 조회(부모 Id 집합) 공개 메서드 |
| V0-10 | Vol.P3 | CMN-00-SEC-004, DWH-001·002 | Masking Policy `MP_PMS_COST`(PMS 비용 금액 열과 그 필드 이력 값: ROLE_FINANCE_READ·ROLE_SF_READER만 원문), PMS_LaborRate__c와 그 이력은 복제 제외 |
| V0-2 | Vol.P3 | CMN-00-DOC-001 | 다중 부모 등록 `registerFilesToParents(parentIds ≤ 20, docClassId, contentDocumentIds, changeNote)`: SOQL 수가 부모 수와 무관, 같은 호출 안 부모끼리 중복 경고 없음 |
| V0-3 | Vol.P3 | CMN-00-DOC-001 | 승인본 게시 `publishCopy(sourceRevisionId, targetParentId)`: RELEASED 리비전만, 대상 객체는 CMN 설정 `CMN_DOC_PUBLISH_TARGETS`(CMN_Item__c) 허용 목록, 즉시 RELEASED. 신규 필드 CMN_DocumentRevision__c.PublishedFromRevision__c(Lookup self) — 설정되면 해시 중복 경고 제외 |
| V0-4 | Vol.P3 | CMN-00-APV-001 | 일괄 결재 상태 `CMN_ApprovalService.getStatuses(Set<Id> targetIds)`(최대 200, SOQL 2회) |
| V0-5 | Vol.P3 | CMN-00-APV-001 | BR-6 공유: Share 테이블이 없는 대상(Master-Detail 하위)은 `CMN_ApprovalType__mdt.ShareTargetPath__c`(예: `Activity__r.Project__c`)가 가리키는 레코드에 Read 공유. 경로가 없으면 WARN 로그 후 건너뜀(현재 구현은 하위 객체에서 예외) |
| V0-6 | Vol.P3 | CMN-00-APV-002 | DRAFTER_MANAGER 해석과 RequireDrafterManager 검사: 기안자가 부서장이면 상위 부서장으로 |
| V0-7 | Vol.P3 | CMN-00-MDM-007 | DOC_CLASS 값 `PMS_DLV` 하위(SOR_REVIEW, DESIGN_SPEC, DESIGN_REVIEW, DR_REPORT, FEASIBILITY, DRAWING_LINK(LINK_ONLY), BOM_LINK(LINK_ONLY), TEST_RESULT, IMDS, TOOLING_ORDER, PACKAGING_SPEC, TIMING_PLAN, CUSTOMER_APPROVAL, KICKOFF_APPROVAL, SYSTEM_RECORD, OTHER)와 `PMS_COST_TEMPLATE`. FMEA·관리계획서·공정 흐름도·설계 기록은 기존 PPAP 하위 코드를 같이 쓴다. 코드 그룹 PMS_COST_SUBCATEGORY(2레벨), PMS_DLV_REVISION_REASON. APPROVAL_ROLE 값 COST_CONTROLLER |
| V0-8 | Vol.P3 | CMN-00-SEC-001 | CMN_PSG_Executive에 PMS_PS_Cost_Read·PMS_PS_Cost_Portfolio·PMS_PS_Deliverable_Read 추가, 페르소나 표의 PMS PSG에 PMS_PSG_TeamLead·PMS_PSG_Finance 추가 |
| V0-9 | Vol.P3 | Vol.0 3.3·sf-dev.md 6절 | SheetJS 정적 리소스 이름을 `cmnSheetJs`(force-app-cmn, cmnChartJs와 같은 규칙)로 고정. 먼저 구현하는 WI가 만든다 |

## 3. Vol.2·3 및 이전 Vol. 변경 요청 (64건, 대상순)

| 대상 | 요청 Vol. | 변경 내용 | 근거 |
| --- | --- | --- | --- |
| QMS-02-DVQ-002, DVQ-003 | Vol.3 | TriggerType 값 PERIODIC, Phase 값 REQUAL 추가 | PWT-001 |
| QMS-02-DVQ-005 | Vol.3 | BR-2 멱등 키에 TargetDate 추가(같은 원천에서 주기마다 계획 생성) | PWT-001 BR-2 |
| QMS-02-DVQ-005 | Vol.6a | getStatusBySource DTO에 FinalResult·ResultCondition 포함 확인(4M 조건부 처리에 사용) | 4MC-006 BR-1 |
| QMS-02-DVQ-006 | Vol.9 | QMS_QualLineRequested__e 필드 정의(INT-018 표), EventType REQUESTED·CANCELLED·RESCHEDULED. QMS_QualPlanLine__c에 ExternalSyncStatus__c(PENDING, SENT, ACCEPTED, FAILED)·ExternalSyncMessage__c, 통합 PS QMS_PS_Qual_Integration | INT-018 BR-1 |
| QMS-02-DVQ-006·007 | Vol.6b | (선택) 시험 라인에 사용 장비 번호(EquipmentNo__c)를 남기고 착수 시 `QMS_GaugeService.getUsability` 확인 — 신뢰성 시험 장비도 교정 통제·영향 분석 대상이 됨 | GAU-003 BR-8, GAU-004 BR-6 |
| QMS-02-DVQ-007 | Vol.3 | QMS_NcrGateway에 requestFromIncoming(lotId) 추가 | IQC-004 BR-2 |
| QMS-02-DVQ-007 | Vol.5 | 게이트웨이 프레임워크(QMS_GatewayBinding__mdt, QMS_GatewayFactory, QMS_FollowUpRequest, QMS_FollowUpStatusDTO)와 interfaces.md 5절 인터페이스·기본 구현을 QMS 공통에 둔다. Vol.5는 사용자. 추가로 (a) QMS_NcrGateway.requestNcr(QMS_NcrRequest), (b) QMS_EightDGateway와 그 DTO(QMS_EightDRequest, QMS_EightDActionDraft, QMS_EightDStatusDTO — 필드는 Vol.5 CLM-001 정의)의 클래스 배치, (c) 바인딩 키 EIGHT_D_ASSIST(QMS_EightDAssist, 기본 구현 isAvailable = false) 추가 | CLM-001 BR-12, CLM-002 BR-3, CLM-004, CLM-009, B2B-005 |
| QMS-02-DVQ-007 | Vol.6a | QMS_NcrGateway 인터페이스에 requestNcr(QMS_NcrRequest)와 DTO QMS_NcrRequest 추가(필드는 NCR-002 서비스 API, sourceType 등록부 값), 게이트웨이 프레임워크 QMS_GatewayBinding__mdt(DeveloperName = 바인딩 키)·QMS_GatewayFactory.get(bindingKey)·공용 DTO QMS_FollowUpRequest·QMS_FollowUpStatusDTO 정의, 기본 구현 To-Do SourceType = QMS_NCR_REQUEST로 고정, NcrRecordId 회신은 NCR이 QMS_NcrSourceConfig__mdt로 수행(원천 WI는 등록만) | NCR-002 BR-4~7 |
| QMS-02-DVQ-007 | Vol.6b | VISUAL·PASS_FAIL 입력 화면의 한도견본 링크는 `qmsLimitSampleLink`(itemId만 넘기는 품번 단위 모드) 사용 | LMS-003 BR-1(c) |
| QMS-02-DVQ-007 | Vol.6b | 게이트웨이 프레임워크(QMS_GatewayBinding__mdt, QMS_GatewayFactory, QMS_FollowUpRequest·QMS_FollowUpStatusDTO — interfaces.md 5절). 6b는 바인딩 NCR을 사용하고 AUDITOR_QUALIFICATION·LAB_REQUEST 구현을 등록 | TRN-004 BR-8, LAB-002 BR-8, GAU-004 BR-4 |
| QMS-02-DVQ-007 | Vol.6c | 게이트웨이 프레임워크(QMS_GatewayBinding__mdt, QMS_GatewayFactory, QMS_FollowUpRequest·QMS_FollowUpStatusDTO, interfaces.md 5절)를 QMS 공통으로 소유. 이 Vol.은 바인딩 키 AUDITOR_QUALIFICATION, EIGHT_D, HORIZONTAL_DEPLOY, LESSON_LEARNED를 호출하고 IMPROVEMENT 구현체를 등록 | IAU-002·004, CAU-003, IMP-001·002, SQM-003 |
| QMS-02-DVQ-007 | Vol.9 | 외부 결과 반영 서비스 `QMS_QualLineExternalService.applyUpdate(dto)` — 화면 입력과 같은 상태 전이·시료 결과·DONE 조건·불합격 처리, 앞선 상태만 반영 | INT-018 BR-4·5 |
| QMS-02-DVQ-009 | Vol.4 | QMS_ReportFormat__mdt에 ReportType__c(DVPR, FQC_COA, PSW), ShowSampleValues__c, FileNamePattern__c 추가 | FQC-005, RPP-003 |
| QMS-02-DVQ-010 | Vol.3 | BR-1 협력사 수신자를 QMS_SupplierContactResolver(QUALITY)로 결정, 선행에 QMS-03-SPP-002 추가(포털 문서 업로드 컴포넌트) | SPP-001 BR-3, SPP-002 |
| QMS-03-IQC-001·003 | Vol.4 | 기준서 편집기·검사 입력·대기열을 공용 컴포넌트 qmsInspStandardEditor·qmsInspectionEntry·qmsInspectionWorkbench(mode IQC·FQC)로 일반화 | FQC-001·002 |
| QMS-03-IQC-002 | Vol.9 | 수신 필드 GrPostedAt__c(DateTime, 입고 전기 시각) 추가 — DueAt 계산 근거, QMS_PS_Iqc_Integration 편집 대상 포함 | INT-004 매핑 |
| QMS-03-IQC-002·003 | Vol.6a | QMS_IqcLot__c에 RejectDefectType__c(Lookup CMN_Code DEFECT_TYPE), RejectNgSampleQty__c, RejectReason__c 추가(IQC-003 BR-5 입력값 저장 위치), 기본 구현 To-Do SourceType = QMS_NCR_REQUEST | NCR-002 BR-5(b) |
| QMS-03-IQC-003 | Vol.6b | VARIABLE 결과 저장 시 측정기 번호 입력 필수 옵션(CMN 설정 QMS_IQC_GAUGE_REQUIRED, 기본 false → GAU 이관 후 true) | GAU-003 BR-2, GAU-004 |
| QMS-03-IQC-003 | Vol.6b | (참고) 검사 훅 validateInspector에 컨텍스트 인자가 없어 6b는 컨텍스트별 구현 클래스를 등록한다. 인자 추가를 원하면 IQC-003 시그니처 변경 필요 | TRN-004 BR-2 |
| QMS-03-IQC-005 | Vol.6c | QMS_SupplierGradeEvent__e 구독: 협력사 등급이 A에서 내려가면 그 협력사 SKIP 품번의 기본 수준을 NORMAL로(Reason SKIP_REVOKED). 무검사 조건의 등급은 SQM-003 확정 등급(Account.SupplierGrade__c) | SQM-003 BR-3 |
| QMS-03-IQC-006 | Vol.6a | 성적서 4M 번호 입력 시 QMS_FourMService.isApplicable(recordNo, supplierItemId)로 검증, 선행에 QMS-06-4MC-007 추가 | 4MC-007 BR-3 |
| QMS-03-IQC-007 | Vol.4 | CORE.INSPECTION_RESULT에 SOURCE 'FQC' 행 허용(키·컬럼 동일) | FQC-004 |
| QMS-03-IQC-007 | Vol.6b | BR-2 CORE.INSPECTION_RESULT에 GAUGE_NO 열 추가(IQC 결과 라인 GaugeNo__c), 키는 그대로 | GAU-004 BR-2, MSA-001 BR-1 |
| QMS-03-IQC-007, QMS-03-PWT-002 | Vol.7 | KPI 뷰의 Rag를 공통 UDF MART.F_KPI_RAG로 계산 | DSH-001 BR-4 |
| QMS-03-PIS-001 | Vol.4 | Trigger 값 NEW_PRODUCT, CUSTOMER_ECO, LINE_TRANSFER 추가(PRODUCT). QMS_StabilizationRequest에 itemId, plantId, lineId, customerId, sopDate. QMS_StabilizationDefault__mdt에 RecordType__c, ProductGroupCode__c와 PRODUCT 목표 필드. 서비스·Hold 분기를 레코드타입으로 | EFC-001 |
| QMS-03-PIS-001 | Vol.6a | BR-1 QMS_PIS_AUTO_TRIGGERS 기본값을 NEW_PART만으로(CHANGE_4M 안정화는 4MC-007이 적용 승인 시 생성 — PPAP 승인 시점에 Hold가 걸려 변경 전 부품까지 강화 검사되는 것을 방지) | 4MC-007 BR-2 |
| QMS-03-PIS-002 | Vol.4 | QMS_STAB_DAILY 핸들러 PRODUCT 매핑, QMS_StabilizationReport__c 레코드타입 SUPPLIER·INTERNAL과 Line__c·ProdDate__c·Shift__c, Supplier__c 필수를 SUPPLIER만으로, 모니터 PRODUCT 모드 | EFC-002 |
| QMS-03-PIS-002, IQC-007 | Vol.6a | 확정 불량 수량 원천 = MART.V_NCR_SUPPLIER_DEFECT(CORE.NCR_DEFECT) | NCR-008 BR-6 |
| QMS-03-PIS-003 | Vol.4 | 해제 조건·결재 유형·Hold 해제 대상을 레코드타입별로 분기(PRODUCT: QMS_EFC_RELEASE·QMS_EFC_EXTEND, 출하검사 Hold) | EFC-003 |
| QMS-03-PIS-003 | Vol.6a | BR-1 협력사 귀책 OPEN NCR 확인은 QMS_NcrQueryService.openNcrCount 사용, 선행에 QMS-06-NCR-001 추가 | NCR-001 BR-9 |
| QMS-03-PPA-001 | Vol.4 | CUSTOMER 범위 레벨 기본값 = Account.PpapDefaultLevel(없으면 CMN 설정) | RPP-001 BR-3 |
| QMS-03-PPA-002 | Vol.4 | Status 값 IN_PREPARATION·CUSTOMER_REVIEW(CUSTOMER 전용), Sqe__c 필수는 SUPPLIER만, CUSTOMER 필드(Customer, Vehicle, CustomerPartNo, CustomerChangeNo, CustomerApprovalRequired, PswJson, PswSignedAt·By, CurrentSubmissionRound), 요청 DTO에 itemId·plantId·customerId·customerChangeNo·customerApprovalRequired, 요소 라인 Responsible__c·ElementDueDate__c, QMS_PpapEvent__e에 Scope__c와 EventType CUSTOMER_SUBMITTED | RPP-001·004 |
| QMS-03-PPA-002 | Vol.9 | (선택) QMS_Ppap__c.PdsSyncStatus__c·PdsSyncMessage__c, SourceObject 'PDS'(원천 Id 없음 → Receipt Id 사용) 허용 명시 | INT-019 BR-2·3 |
| QMS-03-PPA-002·003 | Vol.6b | 부품 PPAP의 MSA 요소도 Vol.4 RPP-002 증빙 수집 구조(QMS_PpapEvidenceCollector, QMS_PpapCollector__mdt)로 6b MSA 수집기를 실행해 "SL 보유 증빙"으로 표시 | MSA-005 BR-9 |
| QMS-03-PPA-003 | Vol.4 | 검토 화면 qmsPpapReview에 CUSTOMER 모드(제출 객체 대신 채택 증빙·업로드 문서) | RPP-003 BR-1 |
| QMS-03-SPP-002 | Vol.7 | 포털 홈 `qmsPortalHome`에 품질 요약 슬롯(qmsPortalQualitySummary) 추가 | DSH-015 BR-6 |
| QMS-04 KPI 뷰 전체 | Vol.7 | Rag 계산을 공통 UDF로. QMS_SPC_PLAN_SUMMARY 결과 열 이름(charName, lineCode, cpk, ppk, rag, openAlarms, lastMeasuredAt) 확정 | DSH-001, DSH-006 |
| QMS-04-EFC-002 | Vol.9 | CORE.MES_PRODUCTION에 LOT_STATUS, LOT_CLOSED_TS, FOURM_RECORD_NO, SPEC_VERSION, DELETED 컬럼 추가(RAW 표준 형식에 있음) | INT-011, INT-012 BR-4 |
| QMS-04-FQC-002 | Vol.9 | DELIVERY 로트 수신 계약에 Customer 참조로 Account.SapCustomerNo__c 허용, 납품 삭제 시 취소 필드(CancelFlag__c) 추가 | INT-006 매핑·BR-3 |
| QMS-04-LEL(코드) | Vol.8 | DEV_ACTIVITY_TYPE 값에 PAST_ISSUE_REVIEW(과거차 반영 검토) 포함 | AIQ-008 반영 방식 B |
| QMS-04-LEL-004·005 | Vol.8 | QMS_LeleMatch DTO에 aiRecommendationId·draftText 추가(propose가 Origin AI_RECOMMEND 레코드에 AiRecommendationId__c를 채움). QMS_LeleApplicationEvent__e 필드 목록에 AiRecommendationId__c 명시(LEL-005 BR-9와 필드 표 불일치) | AIQ-007 BR-8, AIQ-006 BR-3 |
| QMS-04-LEL-005 | Vol.9 | PMS 별도 Org일 때만: 필수 체크포인트 미결 확인 REST 리소스(hasOpenMandatory) 추가 | INT-021 API |
| QMS-04-SPC-005 | Vol.8 | 알람 레코드 페이지에 cmnAiRecommendationList(UseCase QMS_RCA)와 qmsAiRecommendLauncher 배치 위치 명시(BR-11 "QMS-08이 같은 영역에 추가"의 구체화) | AIQ-004 BR-6 |
| QMS-04-SPC-006 | Vol.7 | 정적 리소스 이름 `chartjs` → `cmnChartJs`(Vol.5와 통일). qmsSpcChart ConfigSchema(planId, days) 제공 | DSH-003 BR-5, DSH-006 BR-2 |
| QMS-05 B2B 화면 컴포넌트 | Vol.7 | qmsB2bMisCurve·qmsB2bTrendChart에 ConfigSchema 제공 | DSH-008 BR-3 |
| QMS-05-B2B-001 | Vol.9 | RAW.FC_CUSTOMER_QUALITY에 `_SOURCE_KEY` 열 추가 | INT-014 |
| QMS-05-B2B-002 | Vol.9 | 통합 PS QMS_PS_B2b_Integration(QMS_B2bUpload__c Status·ErrorSummary 편집, ContentVersion·QMS_B2bFormat__mdt 읽기) | INT-016 BR-3 |
| QMS-05-B2B-003, CLM-010 | Vol.7 | 비용 KPI(QMS_WARRANTY_COST, QMS_CLAIM_COST, QMS_CLAIM_RECOVERED)를 CMN_KpiValue__c에서 빼고 QMS_ViewCost 검사 쿼리로 전환(Vol.6a NCR-008 방식) | D7-4 |
| QMS-05-CLM-002 | Vol.8 | 변경 없음. 확인: 적용 규칙이 읽는 ContentJson 키(causeCodeExternalKey, text, actionText)를 AIQ-005가 그대로 제공, NCR_SUPPLIER는 isAvailable false | AIQ-005 |
| QMS-05-CLM-007 | Vol.9 | (선택) 원천 첨부 파일 수신 계약(DOC-001 문서 생성 수신 API 또는 첨부 URL 필드) | INT-015 BR-4 |
| QMS-05·06a 쿼리 키 | Vol.9 | CORE.SAP_STOCK·SAP_SHIPMENT·SAP_BATCH·LOT_TRACE 컬럼은 INT-008·012 정의를 따르고, 계보 재귀는 CORE.F_LOT_DESCENDANTS·F_LOT_ANCESTORS 사용 | INT-008, INT-012 BR-3 |
| QMS-06-4MC-003 | Vol.8 | 기존 cmnAiRecommendationList(QMS_4M_TEST) 자리 옆에 qmsAiRecommendLauncher 배치 | AIQ-014 BR-1 |
| QMS-06-4MC-007 | Vol.9 | 사양 버전 방식 감지를 쓰려면 4M 객체에 "적용 사양 버전" 필드 추가. 첫 생산 로트 감지 Task는 QMS-09-INT-012가 구현(QMS_4M_FIRST_LOT 계약 유지) | INT-012 BR-4·5 |
| QMS-06-CAU-001 | Vol.8 | 고객 심사 콕핏에 qmsAiRecommendLauncher·cmnAiRecommendationList(QMS_AUDIT_PREP) 자리, 준비 과제 생성 공개 메서드 이름 제공(AIQ-015 동적 호출) | AIQ-015 |
| QMS-06-GAU-005 | Vol.9 | 성적서 URL 수신 필드 이름 확정, 수동 즉시 동기화를 INT-002 모니터 "지금 실행"으로 제공 | INT-017 BR-3 |
| QMS-06-IAU-007 | Vol.7 | 자체 RAG 기본값 대신 공통 UDF 사용, MART.KPI_RAG_RULE 소유를 공통(DSH-001 동기화)으로 이전. QMS_AUDIT_ELEMENT_TREND를 긴 형식(month, element, achievementPct)으로 | DSH-001 BR-4, DSH-009 |
| QMS-06-NCR-008 | Vol.7 | QMS_NCR_PARETO·QMS_NCR_TREND·QMS_COPQ_TREND 결과 열 이름 확정(위젯 config 기준: defectTypeL2, ncrCount, month, opened, closed, openEnd, scrap, rework, sorting, other) | DSH-007 |
| QMS-06-SQM-002·003 | Vol.7 | QMS_SUPPLIER_GRADE_COUNT_*의 QUARTER 주기는 DWH-003 변경 후 적재. 포털 공개 KPI 목록(D7-7)과 스코어카드 공개 규칙 일치 | DSH-005 BR-4, DSH-015 |
| QMS-06-TRN-003 | Vol.7 | QMS_TRN_PLAN_RATE의 Department 차원은 DWH-003 차원 추가 후 적재, 그 전에는 Plant만 | DSH-010 BR-3 |
| QMS-08(Vol.8) | Vol.7 | QMS_EW_TOP_RISKS에 제품군 단위(riskDomain PRODUCT_GROUP) 지원 추가 — 경영 화면에서 제품군 위험 목록이 필요할 때(현재 이 Vol.은 SUPPLIER·LINE·PROCESS만 사용). qmsRiskTopWidget의 config 키(entityType, plantCode, topN) 고정과 ConfigSchema 제공, 위험 보드 조회 PS 이름 확정. QMS_EW_RISK_SCORE의 ProductGroup 차원은 DWH-003 변경 후 적재. Q&A 골든 질문과 이 Vol. 추천 질문(DSH-012 BR-2)을 맞춤 질문 채널: Vol.7이 정의·발행하는 QMS_AskQualityChannel(BR-1a 필드)을 유틸리티 바 qmsQualityAssistant가 구독하고 같은 requestId로 1.5초 안에 ACK(AIQ-010 BR-9·AC-8, Vol.7 DSH-012 AC-2·DSH-014 AC-5와 짝). 컨트롤러 입력은 채널의 customerIds·periodMonths를 쓰고 customerCode·periodFrom·periodTo는 표시용으로 둔다 | DSH-012, DSH-014 |
| QMS-09(Vol.9) | Vol.7 | QMS_INT_FAILED·QMS_INT_PENDING_AGED·QMS_INT_LATENCY_MIN의 인터페이스·원천 차원을 키 접미사(`_{IF ID, - → _}`)로 적재하고 전체 값은 기본 키로 적재(FAILED·PENDING_AGED = 합계, LATENCY_MIN = 원천별 최대). QMS_INT_LATENCY_MIN 목표(원천별 기준)는 KpiValue.Target__c에 적재 | 3절 카탈로그, DSH-016 BR-7 |
| Vol.3 | Vol.5 | 변경 없음. 포털 경로 `/8d/{id}`, `/chargeback/{id}`는 이 Vol. WI가 QMS_PortalRoute__mdt에 등록 | CLM-005, CLM-010 |
| interfaces.md | Vol.9 | 3.1 표의 CORE.LOT_TRACE·CORE.SAP_STOCK 소유를 Vol.9(INT-008·012)로 정정. Vol.9 추가 이름 등록: QMS_SapPostingRule__mdt, QMS_ExternalCodeMap__mdt, QMS_SyncMonitorConfig__mdt, QMS_SyncResender, QMS_InboundHandlerBase, 핸들러 8종(QMS_IntStaleHandler, QMS_FqcShippedOnHoldHandler, QMS_ClaimSapHoldResultHandler, QMS_FourMMesNoticeResultHandler, QMS_FcClaimUnmappedHandler, QMS_ReliabilityLineUpdateHandler, QMS_PdsPpapRequestHandler, QMS_PmsRiskEventHandler), CORE.F_LOT_DESCENDANTS·F_LOT_ANCESTORS, Mule exp-pms-lele-api·prc-lele-sync-api·prc-pms-thread-api(INT-021), 인터페이스 ID IF-AI-001~004 | 3절 |
| 각 메뉴 | Vol.7 | 업무 화면 이름(교정 계획, MSA 계획, 자격 매트릭스, 분석 대기열, 반영 검토 목록, 고객 PPAP 목록, 출하검사 대기열 qmsFqcWorkbench, 협력사 스코어카드 목록 qmsSupplierScorecardList)을 레지스트리 DrillTarget에 넣을 수 있게 확정 | DSH-005~011 |

## 4. PMS Vol. → QMS Vol. 변경 요청 (43건, 대상순)

| 대상 | 요청 Vol. | 변경 내용 | 근거 |
| --- | --- | --- | --- |
| QMS-02 D2-4 | Vol.P4 | CONDITIONAL 인정시험 판정을 QMS_QUAL_PASS 충족으로 볼지 결정 — Gate 자동 점검은 ACT-004 완료 조건 판정을 그대로 따름 | GAT-003 BR-4 |
| QMS-02-DVQ-005 | Vol.P1 | 조회 API 추가: `List<QMS_QualLineStatusDTO> getLineStatuses(Set<Id> lineIds)`, `List<QMS_QualLineStatusDTO> getLinesByPlan(Id planId)`(lineId, testCode, testName, lineStatus, result, actualEnd). SOR 검증 연결의 시험 라인 단위 해석(PMS-12-INT-005 해석기)에 쓴다 | SOR-002 |
| QMS-02-DVQ-005 | Vol.P6 | QUALIFICATION 바인딩 구현체 `QMS_QualPlanGatewayImpl`(request → createFromSource, payloadJson 키 scope·triggerType·phase·ownerId·sourceNo, getStatus → getStatusBySource) | INT-005 BR-7 |
| QMS-02-DVQ-007 | Vol.P6 | 게이트웨이 프레임워크(공통 패키지)에 위 4개 인터페이스와 DTO 배치 | DP6-2 |
| QMS-04 LEL(SEC 변경 요청 재확인) | Vol.P6 | PMS PSG(PM·CFT·PMO)에 QMS_PS_Lele_Read·Edit 포함 — 액티비티 레일 레슨런 패널 사용 | INT-005 화면 |
| QMS-04-EFC-001 | Vol.P4 | PMS 호출 값 확정: sourceId = PMS_GateReview__c Id, sourceObject 'PMS_GateReview__c', 품번·공장 조합마다 1회 호출, ownerId = 프로젝트 QE(없으면 QMS 기본값) | GAT-006 BR-3 |
| QMS-04-EFC-001 | Vol.P6 | STABILIZATION 바인딩 구현체(request → createFromSource PRODUCT·NEW_PRODUCT, sourceObject PMS_GateReview__c). QMS_StabilizationEvent__e에 SourceObject__c 추가 권장(현재 SourceRecordId만) | INT-005 BR-12 |
| QMS-04-HZD-002 | Vol.P6 | 대상 선정 화면의 PMS 프로젝트 후보 탐색을 PMS_PROJECT 게이트웨이 searchProjects로 구현(PMS 미배포면 수동 입력만) | INT-005 BR-15 |
| QMS-04-LEL-002 BR-7 | Vol.P4 | payloadJson 키 pmsSourceType·projectNo·devPhaseCode를 레슨런 원천 설명에 반영(선택), SourceRecordNo = PMS 문제점·리스크 번호 | ISS-002 BR-8 |
| QMS-04-LEL-004 | Vol.P1 | 오픈 이슈 해소 확인: PMS가 고객 그룹·제품군·부품 분류·차종을 PMS_ProjectContextService.getContext로 제공한다. 후속 모델(차종 계보)은 CMN_Vehicle__c.PredecessorVehicle__c(Vol.0 MDM-003 변경 요청)와 PMS_Project__c.BaseProject__c로 찾는다 | PRJ-001·002 |
| QMS-04-LEL-005 | Vol.P4 | (선택) 반영 검토 화면에 PMS 리스크 연결 표시 — PMS_RiskQualityService.getRisksByQmsTarget 호출 | RSK-002 BR-7 |
| QMS-04-LEL-005 | Vol.P6 | LELE_PROJECT 바인딩 구현체(recommend → QMS_LeleMatchService + propose(RULE_MATCH), hasOpenMandatory, getByProject). QMS_PmsActivityContextDTO → QMS_LeleContext·QMS_LeleProjectRef 변환 | INT-005 BR-5·8 |
| QMS-06-NCR-002 | Vol.P4 | QMS_NcrSourceConfig__mdt에 PMS 패키지가 PMS_Issue 레코드를 등록함을 명시(SourceObject PMS_Issue__c, NcrRecordId__c·NcrRecordNo__c), requestNcr sourceType OTHER·sourceObject PMS_Issue__c에서 라인·공정 없이 DRAFT 허용 확인 | ISS-002 BR-6 |
| QMS-08-AIQ-007 | Vol.P6 | LELE_PROJECT 바인딩을 AI 추천 구현으로 교체(recommend → QMS_LeleRecommendService). `qmsLeleAiRecommend`가 레일 패널 계약(@api recordId·objectApiName·config·variant, railbadge)을 지원하고 PMS_Activity__c 문맥은 PMS_PROJECT getActivityContext로 얻음. 에이전트 액션 QMS_AiAction_RecommendLessonsForActivity의 "PMS 조회 Action"도 같은 게이트웨이 | INT-005 화면, BR-15 |
| QMS-08-AIQ-007·008 | Vol.P1 | 확인(변경 없음): QMS_LeleProjectRef.qualityOwnerId = PROJECT_ROLE QE 역할 대표(getRoleHolders) | CFT-001 |
| QMS-08-AIQ-008 | Vol.P6 | 같은 Org 호출 경로를 "PMS Apex가 직접 호출" → "PMS-12-INT-005가 LELE_PROJECT 게이트웨이로 호출"로 정정, 일정 확정 시점 = PMS_ProjectEvent__e SCHEDULE_CONFIRMED | DP6-2 |
| QMS-09-INT-019 | Vol.P6 | sys-pds-api를 PMS(IF-PDS-004·005)와 공용으로 쓰고 IF-PDS 번호 004부터 PMS가 사용함을 카탈로그에 기재 | 4절 |
| QMS-09-INT-021 | Vol.P6 | 다른 Org일 때 PMS 수신 계약 = PMS_SystemLink__c ExternalKey upsert(Mule이 같은 매핑 표로 변환). BR-5의 예시 PMS_QmsThreadEvent__e는 만들지 않음 | INT-005 에이전트 주의 |
| QMS-09-INT-021 BR-6 | Vol.P4 | 리스크·문제점 레슨런 후보의 sourceObject를 'PMS_RISK' 대신 같은 Org 경로와 같은 'OTHER' + payloadJson.sourceType DEV_ISSUE, pmsSourceType RISK·ISSUE로 맞춤(LEL-002 BR-7 매핑 목록 밖 값 예외 방지) | ISS-002 BR-8 |
| Vol.2 D2-4 | Vol.P2 | 조건부 판정의 PMS 완료 허용을 PMS 설정 PMS_QUAL_PASS_ALLOW_CONDITIONAL로 둠(DP2-8과 함께 결정) | ACT-004 BR-6 |
| Vol.2 DVQ-005 | Vol.P3 | 변경 없음. SYSTEM_LINK QMS_QUAL_PLAN 충족 규칙(Status CLOSED + FinalResult PASS, CONDITIONAL 포함 여부는 D2-4 결과)을 INT-005가 등록 |  |
| Vol.2 DVQ-009 | Vol.P5 | SheetJS 정적 리소스 이름 확정(PMS도 같은 리소스 사용, 없으면 cmnSheetJs) | DSH-002 BR-10 |
| Vol.2 QMS-02-DVQ-005 | Vol.P2 | `getStatusBySource`가 원천 1건당 여러 계획을 돌려주는 목록형 + 벌크 `getStatusBySources(Set<Id>)` | ACT-004 BR-6 |
| Vol.4 LEL-005 | Vol.P5 | QMS_LeleApplicationService.getByProject 반환 형식(액티비티별 필수 체크포인트 미결 여부) 확정 | DSH-002 BR-3 |
| Vol.4 QMS-04-LEL-005 | Vol.P2 | `hasOpenMandatory` 벌크 메서드 `hasOpenMandatoryBulk(Set<String> activityIds)` → Map<String, Boolean>(자동 종료 200건 벌크 검사) | ACT-004 BR-9 |
| Vol.4 QMS-04-LEL-005 | Vol.P2 | 반영 검토 문맥 갱신 API `updateReviewContext(activityId, reviewerId, dueDate)`(PMS 담당 변경·일정 변경 시 INT-005가 호출) | ACT-005 BR-5, WBS-004 BR-11 |
| Vol.4 RPP-002 | Vol.P3 | 변경 없음(확인 요청). QMS_DocumentCollector의 가정 "관리계획서·FMEA·공정 흐름도는 품번 레코드에 DocClass로 등록"을 DLV-002 품번 게시가 채운다. DocClass는 PPAP 하위 코드를 같이 쓴다 |  |
| Vol.7 DSH-001 | Vol.P5 | KpiKey 이름 규칙에 `PMS_` 허용, Area 값 PRJ·SCH·GAT·DLV·RSK·RES·RPT·DEC·PEW·PAI 추가, 레지스트리 형식·서비스와 QMS 초기 데이터를 분리해 QMS 업무 WI(IQC-007 등) 없이 먼저 배포 가능하게 | DP5-1 |
| Vol.7 DSH-002 | Vol.P5 | 전 공장 권한을 키 접두어별로(PMS_ 키 → Custom Permission PMS_DashboardAllPlants), 등록 집계·목록 PlantField에 1단계 관계 경로(`Project__r.ProdPlant__c`) 허용, getKpiBreakdown·qmsCompareBar의 breakdownDim에 Department 허용 | DSH-001 BR-6·11·15 |
| Vol.7 DSH-003·004 | Vol.P5 | 위젯 등록 검사(QMS_WidgetRegistryTest, `scripts/ci/check-widgets.js`) 대상에 `PMS_W_` 포함, ConfigSchema lookup 대상에 PMS_Project__c·CMN_Vehicle__c 허용 | DSH-001 AC-10 |
| Vol.7 DSH-012·013 | Vol.P5 | PMS 템플릿 권고 위젯(QMS_W_LELE_MY_REVIEW, QMS_W_LELE_RATES, QMS_W_PPAP_CUST_OPEN, QMS_W_CUST_PPM_BY_CUSTOMER, QMS_W_LELE_RECENT)의 AvailableSystems에 PMS 추가. qmsAiAccuracyWidget useCase 선택지를 QMS_ 접두 제한 없이 레지스트리에서 채움 | DSH-001 BR-13, AIP-001 BR-11 |
| Vol.8 AIQ-001 | Vol.P5 | QMS_AiGuard·QMS_AiPlantPolicy__mdt·QMS_AiUsageLimit__mdt·QMS_AiUsageCounter__c·QMS_AiJobEvent__e를 PMS 유스케이스가 함께 씀을 명시(UseCase 값 목록에 PMS_* 추가), QMS_AiJobEvent__e 읽기를 PMS_PS_Ai_User에 | DP5-2 |
| Vol.8 AIQ-006 | Vol.P5 | QMS_AiFinalizeBatch가 PMS 설정 행(SourceObject PMS_*)을 처리. PMS 적중 규칙 5종(PMS_ScheduleHitRule, PMS_ScheduleAdjustHitRule, PMS_DeliverableDraftHitRule, PMS_EwHitRule, PMS_SorExtractHitRule)은 PMS 소유 | AIP-001·002·003·005 |
| Vol.8 AIQ-007 | Vol.P5 | QMS_AiAction_SearchLessons·QMS_AiAction_RecommendLessonsForActivity를 SL Project Assistant 레슨런 토픽에도 등록, Apex 접근을 PMS_PS_Ai_User에 | AIP-004 BR-1 |
| Vol.8 AIQ-009 | Vol.P5 | QMS_AiQueryDef__mdt에 System__c(QMS, PMS) 추가(에이전트별 질의 정의 분리), PlantField 1단계 관계 경로 허용 | AIP-004 |
| Vol.8 AIQ-010 | Vol.P5 | Mule analyst SQL 검증의 허용 뷰를 시맨틱 모델별 목록으로(pms_portfolio → MART.SV_QA_PMS_* 6개), RAP_QMS_PLANT를 PMS 보안 뷰에 부착, ROLE_AI_SERVICE에 PMS 보안 뷰 SELECT | AIP-004 BR-7 |
| Vol.8 AIQ-011 | Vol.P5 | (참고) 품질 위험 PRODUCT_GROUP 피처에 PMS 프로젝트 위험을 넣을 때 ML.PMS_RISK_SCORE_DAILY를 원천으로 쓸 수 있다(AIQ-011 오픈 이슈 해소 경로) | AIP-003 |
| Vol.8 AIQ-013 | Vol.P5 | QMS_AiSearchPreset__mdt에 System__c 추가, cmnUnifiedSearch SL PMS 인스턴스의 프리셋 칩 | AIP-004 BR-9 |
| Vol.8 AIQ-016 | Vol.P5 | 출시 기준표에 PMS 유스케이스 행(AIP 각 WI BR), 평가 실행기 PMS 지원, MART.V_SF_KPI_AI에 PMS_AI_CALLS_{UseCase}, ML.PMS_RISK_RULE 활성 버전도 배포 검사 대상 | AIP-001~005 |
| Vol.8 QMS-08-AIQ-007 | Vol.P2 | qmsLeleAiRecommend가 레일 패널 계약(@api recordId·objectApiName·config·variant, railbadge)을 지켜 PMS 액티비티 레일(PanelKey PMS_LELE)에 동적으로 실린다 | ACT-001 BR-12 |
| Vol.8 QMS-08-AIQ-008 | Vol.P2 | 반영 방식 = PMS_WbsTemplate__c.LeleReviewMode__c, 호출 시점 = SCHEDULE_CONFIRMED·STARTED 이벤트(프로젝트 생성 시점 제외) | WBS-003 BR-11, DP2-10 |
| Vol.9 | Vol.P3 | CORE.SAP_FX_RATE 소비자에 CST-004 추가(정의 변경 없음) |  |
| interfaces.md 5절 | Vol.P4 | PMS가 LESSON_LEARNED·NCR·EIGHT_D 게이트웨이를 쓰므로 게이트웨이 프레임워크(QMS 공통 패키지)를 PMS 패키지보다 먼저 배포하는 순서 명시 | ISS-002 |

## 5. PMS 계약·다른 PMS Vol. 변경 요청 (146건, 대상순)

| 대상 | 요청 Vol. | 변경 내용 | 근거 |
| --- | --- | --- | --- |
| 1 | Vol.P1 | 5절 신규 객체 | PMS_RequirementBaseline__c(SOR-001): SOR 기준선, MD Project, RecordNo SRB-{YYYY}-{SEQ:5}, Status DRAFT·IN_APPROVAL·APPROVED·REJECTED·SUPERSEDED. 결재 유형 PMS_SOR_BASELINE의 대상 |
| 10 | Vol.P1 | 5절 PMS_ProjectPart__c | PartRole(FG, COMPONENT)·ParentPart·Supplier·PartCategory·TempPartNo·CustomerPartNo·Status 추가. GAT-006·WBS-010은 PartRole로 완제품·부품을 구분 |
| 10 | Vol.P3 | PS 추가: PMS_PS_Cost_Edit, PMS_PS_Cost_Portfolio, PMS_PS_LaborRate_Admin, PMS_PS_Cost_Integration, PMS_PS_Deliverable_Read·Edit·Manage. Custom Permission PMS_ViewCost 외 9개 | 3절 권한 셋 표 |
| 11 | Vol.P1 | 5절 신규 설정 | PMS_WorkHourPolicy__mdt(CFT-001), PMS_TraceTargetType__mdt(SOR-002) |
| 12 | Vol.P1 | 5절 머리말 | "모든 업무 객체는 RecordNo"를 문서로 쓰이는 객체로 한정 |
| 13 | Vol.P1 | 5절 Vol.P2 객체 | PMS_Activity__c.OwnerContributionPct__c, PMS_ActivityAssignee__c.ContributionPct__c(EFF-001이 생성) |
| 14 | Vol.P1 | 10절 PSG | PMS PSG 5개는 PRJ-001이 만들고 PS 매핑은 이 Vol. 3절 표를 따른다 |
| 2 | Vol.P1 | 5절 신규 객체 | PMS_EffortSheet__c(EFF-002): 사람 × 주 실적 시트, 소유자 = 본인, 실적 행의 그리드 부모(UX-006은 부모 레코드가 필요) |
| 3 | Vol.P1 | 5절 PMS_SecurityPledge__c | Project 관계 MD → Lookup(소유자 = 서명자), RecordNo SPL-{YYYY}-{SEQ:6}, Status REQUESTED·SUBMITTED·SIGNED·CANCELLED·SUPERSEDED |
| 4 | Vol.P1 | 5절 PMS_CftMember__c.Status | DRAFT 추가 |
| 4 | Vol.P3 | 공수 CST-003 3→4, CST-004 5→7, DLV-001 5→6, DLV-003 6→7(Vol.P3 44→50 M/D) | 6절 머리말 |
| 5 | Vol.P1 | 9절 PMS_ProjectEvent__e | EventType MILESTONE_CHANGED 추가(PayloadJson = 변경 목록). WBS-004가 구독해 CPM 재계산 |
| 5 | Vol.P3 | PMS_WbsTemplateDeliverable__c·PMS_Deliverable__c의 DeliverableType 값 STANDARD_FORM → STD_FORM | DP3-14 |
| 5 | Vol.P3 | PMS_Deliverable__c에 RecordNo `DLV-{YYYY}-{SEQ:6}`, IsSatisfied, IsAdHoc, 사본 필드(LatestFileName 등), DLV-002·004 필드 | DLV-001·002·004 데이터 모델 |
| 5 | Vol.P3 | PMS_ImpactAssessment__c에 RecordNo `IA-{YYYY}-{SEQ:5}`, Status 값(ANALYZED, IN_REVIEW, CONFIRMED, CLOSED, CANCELLED) | DLV-004 |
| 5 | Vol.P3 | 신규 객체 PMS_ImpactItem__c(MD ImpactAssessment) | DP3-12 |
| 5 | Vol.P3 | PMS_DeliverableTrace__c 필드 추가(From·ToSystemLinkType, Label, RevisionNo, IsStale, Source, UniqueKey), FromType·ToType 값(DELIVERABLE, ACTIVITY, SYSTEM) | DLV-003 |
| 5 | Vol.P3 | PMS_CostBudget__c·PMS_CostActual__c 필드 추가(SubCategory, Activity, ProjectPart, 기준선, 마감, ExternalKey 등), PMS_LaborRate__c에 Company·CurrencyIsoCode·ExternalKey 추가 | CST-001~003 |
| 5 | Vol.P3 | 다른 WI 객체에 이 Vol.이 더하는 필드: PMS_Activity__c 롤업 6개(DLV-001), PMS_Project__c.CostRagAsOf__c(CST-004) | DLV-001, CST-004 |
| 6 | Vol.P1 | 5절 PMS_CustomerMilestone__c.Activity | 소유 WI는 PRJ-003으로 두되 Lookup 필드 생성·설정은 PMS_Activity__c를 만드는 WBS-003이 한다. 개발 순서 PRJ-003 → WBS-003(서로 선행이 되는 순환을 끊기 위해) |
| 7 | Vol.P1 | 11절 D-P4, 5절 PMS_EffortPlan__c | 계획도 사람 × 프로젝트 × 주 1행. Activity = 대표 액티비티(참고), 액티비티별 내역은 BreakdownJson. DerivedHours·ManualHours·BaselineHours 필드 추가 |
| 7 | Vol.P3 | 커스텀 메타데이터 PMS_SystemLinkType__mdt, PMS_DeliverableApprovalRule__mdt, PMS_DeliverablePublishRule__mdt | DLV-001·002 |
| 8 | Vol.P1 | 7절 결재 사용처 | "투입 실적 승인(PM)"을 APV 사용처에서 빼고 EFF-002 일괄 승인으로 |
| 9 | Vol.P1 | 5절 PMS_Project__c | BaseProject(기반 프로젝트), PledgeRequired, PmUserIds·IsCurrentUserPm, RetentionUntil, EffortPlanDirtyAt 추가. 공장 필드 이름은 ProdPlant__c를 유지(DOC-001이 부모의 Plant__c를 문서에 복사하므로 Plant__c로 바꾸면 프로젝트 문서가 공장 전원에게 공유된다) |
| 9 | Vol.P3 | 이벤트 PMS_DeliverableEvent__e(SUBMITTED, NOT_APPLICABLE, SYSTEM_STATUS_CHANGED, APPROVAL_SUBMITTED, APPROVED, REJECTED, REVISION_STARTED, REVISED) | DP3-10 |
| PMS-02-PRJ-001 | Vol.P4 | PMS_GateEvent__e PASSED·CONDITIONAL 구독으로 CurrentPhase를 다음 단계로 전진, SOP Gate(IsSopGate) 결정 시 PMS_ProjectEvent__e SOP_CONFIRMED 발행. 프로젝트에 고객 그룹 수식 필드(Customer__r.CustomerGroup__c) | GAT-001 BR-1, GAT-006 BR-8 |
| PMS-02-PRJ-001 | Vol.P6 | PMS_ProjectEvent__e SOP_CONFIRMED에 SOP일 필드 포함 | PRF-001 BR-1 |
| PMS-02-SOR-002 | Vol.P6 | ALM_REQUIREMENT 연결 대장 행의 DONE을 SW 요구사항 검증 근거로 사용 | INT-004 BR-6 |
| PMS-03-CFT-001 | Vol.P6 | CFT 화면에 결재 역할 공백 경고(`PMS_ApprovalRoleCoverageService`) | APV-001 BR-8 |
| PMS-04-WBS-001 | Vol.P1 | 표준 WBS 템플릿에 CustomerGroup·ProductGroup·ProjectType·Version(추천 키)과 AnchorMilestoneCode(CUSTOMER_MILESTONE 코드 값)를 둔다 |  |
| PMS-04-WBS-001 | Vol.P6 | PMS_WbsTemplateActivity__c에 ProcessNo__c·Description__c·OwnerDept__c(없으면), INT-001이 추가하는 BpaSyncStatus__c·BpaCheckedAt__c·BpaWaiveReason__c 수용, 그리드에 "BPA 동기화" 열, 활성화 시 `PMS_BpaSyncService.validateTemplate` 경고. PMS_WbsTemplate__c.LeleReviewMode__c(제안) | INT-001 BR-5~7, INT-005 BR-5 |
| PMS-04-WBS-001·003 | Vol.P4 | 마일스톤 액티비티 GateCode 값은 PMS_GateDefinition__c.GateCode와 같은 값 목록을 쓴다. PMS_ActivityEvent__e에 ProjectId__c·IsMilestone__c·GateCode__c 필드 포함 | GAT-001 BR-2·3 |
| PMS-04-WBS-002 | Vol.P6 | PMS_WbsTemplateDeliverable__c.ApprovalVariantKey__c(제안). PMS_CompletionRule__mdt에 INT-004의 ALM_MILESTONE_DONE·PDS_MILESTONE_DONE 행 수용(PMS_CompletionChecker 계약 공개) | APV-001 BR-6, INT-004 BR-7 |
| PMS-04-WBS-003 | Vol.P1 | PMS_CustomerMilestone__c.Activity__c Lookup 생성, 실행 WBS 생성 시 AnchorMilestoneCode로 연결, 기준일은 PMS_CustomerMilestoneService.getMilestones, ResponsibleRole → PMS_CftService.getRoleHolders로 주담당 기본 지정(2명 이상이면 공란 + 경고), 실행 액티비티가 생기면 StandardWbs를 잠그는 검사를 PRJ-001 착수 서비스·편집 규칙에 더함 |  |
| PMS-04-WBS-004 | Vol.P1 | PMS_ProjectEvent__e MILESTONE_CHANGED 구독 → CPM 재계산. PMS_ActivityEvent__e DATES_CHANGED 발행(EFF-001이 구독) |  |
| PMS-04-WBS-005 | Vol.P1 | 기준선 승인 콜백에서 PMS_ProjectService.transitionByService(PLANNING → IN_PROGRESS, callerKey WBS_BASELINE), PMS_CustomerMilestoneService.captureBaseline, PMS_EffortPlanService.captureBaseline 호출 |  |
| PMS-04-WBS-005 | Vol.P6 | 기준선 승인 시 PMS_ProjectEvent__e SCHEDULE_CONFIRMED 발행, 일정 확정 전 `PMS_ApprovalRoleCoverageService.check` 경고 | INT-005 BR-5, APV-001 BR-8 |
| PMS-04-WBS-006, PMS-03-CFT-002, PMS-07-ACT-005, PMS-06-DLV-004 | Vol.P6 | 승인(결재 완료) 콜백에서 `PMS_ProjectChangeService.record` 호출, 취소 시 cancelRecord | CHG-001 BR-1 |
| PMS-04-WBS-009 | Vol.P1 | 종료 상신·승인·반려에서 transitionByService(WBS_CLOSE_SUBMIT·APPROVE·REJECT) |  |
| PMS-04-WBS-009 | Vol.P4 | 과제 종료 승인 시 SopDisposition CARRY_TO_CLOSURE 문제점·리스크 미결 여부 확인 | GAT-006 BR-5 |
| PMS-04-WBS-010 | Vol.P6 | PMS_SupplierPartSchedule__c에 PdsPartId__c·VendorNo__c·ItemNo__c·PdsStatus__c(제안), 원천 필드는 통합 사용자만 편집 | INT-004 BR-2 |
| PMS-05-CST-001 | Vol.P6 | `PMS_CostBudgetService.applyChange(changeId, lines)` 제공(예산 개정 이력) | CHG-001 BR-7 |
| PMS-05-CST-001·002 | Vol.P1 | 계획 = PMS_EffortPlan__c.PlannedHours(액티비티별은 BreakdownJson, 기준선은 BaselineHours), 실적 = PMS_EffortActual__c APPROVED(요일 칸으로 월 분할). 월 마감 뒤 실적 재개 금지 검사를 EFF-002 재개 서비스에 더함 |  |
| PMS-05-CST-002 | Vol.P6 | PMS_CostActual__c.SubCategory__c·ExternalKey__c(제안), Source DMS 행은 통합 사용자만 편집 | INT-003 |
| PMS-05-CST-003 | Vol.P6 | PMS_LaborRate__c에 CompanyCode__c·CurrencyCode__c·EffectiveFrom__c·EffectiveTo__c·Source__c·ExternalKey__c·PendingChange__c(제안). ED&D 적용 임율은 법인·직급·적용 기간으로 찾음 | INT-002 |
| PMS-06-DLV-001 | Vol.P4 | PMS_Deliverable__c.AnomalyStatus__c·AnomalyCheckedAt__c·AnomalyCheckedRevision__c는 GAT-005가 만든다(계약 표기와 같음). 산출물 레일에 CONTEXT_ANOMALY 패널 행 허용 | GAT-005 |
| PMS-06-DLV-001 | Vol.P6 | SYSTEM_LINK 산출물 등록에서 `pmsSystemLinkPicker` 사용(PDM 도면) | INT-004 BR-3 |
| PMS-06-DLV-002·003 | Vol.P1 | 산출물 결재 완료 시 PMS_RequirementTraceService.applyTargetResult('PMS_DELIVERABLE', ids) 호출(선택, 야간 갱신으로도 반영). 디지털 스레드 화면에 getTrace 결과 표시 |  |
| PMS-06-DLV-004 | Vol.P6 | 연결 대장 핸들러(LinkType PDM_DRAWING) 등록으로 도면 개정 시 영향도 분석 생성 | INT-004 BR-4 |
| PMS-07-ACT-001 | Vol.P1 | 주/보조 담당은 PMS_CftService.isAssignable로 검증. 담당 섹션에 투입율 필드(EFF-001 생성) 배치. 담당·투입율 변경 시 PMS_EffortPlanService.requestRegenerate 호출. 주담당 필드 API명(계약 Owner)을 CFT-002 해제 검사가 쓴다 |  |
| PMS-07-ACT-003 | Vol.P1 | 복사한 CFT 구성원은 DRAFT로 만들고 CFT-002 승인과 CFT-003 서약을 다시 거친다 |  |
| PMS-07-ACT-004 | Vol.P4 | Gate 마일스톤 액티비티 완료 조건 규칙 키 GATE_DECIDED(`PMS_GateQueryService.isDecided(activityId)`) 추가 또는 PMS_GateEvent__e 구독 자동 완료. PMS_CompletionChecker는 액티비티 단건·다건 판정을 공개 메서드로 제공(Gate 자동 점검 위임) | GAT-003 BR-4, GAT-001 서비스 |
| PMS-07-ACT-004 | Vol.P6 | QMS_LELE_NO_OPEN_MANDATORY는 `PMS_QmsThreadService.hasOpenMandatoryLessons`, QMS_QUAL_PASS는 `qualificationStatus` 사용. 연결 대장 핸들러(QUALIFICATION, LELE_APPLICATION, ALM_MILESTONE, PDS_PART) 등록으로 자동 종료 재평가 | INT-005 BR-8, INT-004 BR-8 |
| PMS-07-ACT-005 | Vol.P1 | 교체 이관 To-Do(PMS_CFT_HANDOVER)에서 여는 일괄 변경 화면이 URL 매개변수 c__fromUserId·c__toUserId를 받는다. 변경 후 requestRegenerate 호출 |  |
| PMS-08-ISS-002 | Vol.P6 | 연결 대장 핸들러(CLAIM, NCR) 등록으로 문제점 후보·연결, 레슨런 후보 종결 시 `requestLessonLearned` 사용 | INT-005 BR-4·13 |
| PMS-09-GAT-003·006 | Vol.P1 | 자동 점검 규칙 키 SOR_FULFILLMENT(getFulfillment), PLEDGE_COMPLETE(getCompliance), CFT_ROLES(missingRoles). 양산 이관 Gate 승인 시 confirmSop 호출, 초기유동 생성은 getContext.fgParts(품번·생산처) 기준 |  |
| PMS-09-GAT-006 | Vol.P6 | SOP Gate 통과 시 `requestEarlyProductionContainment` 호출 | INT-005 BR-12 |
| PMS-10-DSH(Vol.P5) | Vol.P6 | KPI PMS_PRF_*·PMS_CHG_COUNT 위젯, DMS 상세 위젯 `pmsDmsCostDetail`을 비용 대시보드에 배치 | 3절, INT-003 BR-11 |
| PMS-10-DSH, PMS-11-AIP | Vol.P1 | 위젯 pmsSorFulfillmentWidget·pmsResourceLoadWidget을 역할 템플릿에 배치. AIP-005는 채택한 초안을 createDrafts(origin AI_DRAFT)로 저장. AIP-003은 MART.V_PMS_RESOURCE_WEEKLY 사용 |  |
| PMS-10-DSH-002 | Vol.P4 | PMO 보드의 Gate·리스크·문제점 영역은 PMS_GateQueryService.getGateSummary와 RSK-003 위젯 2개 사용 | RSK-003, GAT-001 BR-9 |
| PMS-11-AIP-003 | Vol.P4 | 조기경보 결과를 리스크로 만들 때 PMS_RiskService.createFromSource(Source EARLY_WARNING) 사용 | RSK-001 BR-10 |
| PMS-12-APV-001 | Vol.P1 | PROJECT_ROLE 해석 = getRoleHolders(1명이어야 함, 2명 이상이면 "역할 대표 지정 필요"로 상신 차단) |  |
| PMS-12-INT-004·005 | Vol.P1 | PMS_TraceTargetResolver 구현(PDM_DRAWING, ALM_ITEM / QMS_QUAL_PLAN, QMS_QUAL_PLAN_LINE)과 PMS_TraceTargetType__mdt.ResolverClass 설정, 외부 결과 수신 시 applyTargetResult 호출. LELE 문맥 = getContext + 품질 담당(QE 역할 대표) |  |
| PMS-12-INT-005 | Vol.P4 | QMS_ClaimEvent__e·QMS_NcrEvent__e·QMS_EightDEvent__e 구독 트리거에서 PMS_IssueQmsService.handle*Events를 호출(구독 트리거는 INT-005 한 곳), QMS_LeleApplicationEvent__e 수신 시 PMS_RiskQualityService.refreshStatus 호출 | ISS-002, RSK-002 BR-4 |
| PMS-13-PRF-001 | Vol.P4 | Gate 1회 통과율 = SOP까지 결정된 Gate 중 Round 1 PASSED 비율(PMS_GateReview__c 기준, KPI PMS_GATE_FIRST_PASS_RATE와 같은 정의) | 3절 KPI |
| PMS-13-PRF-002 | Vol.P1 | 수평평가 대상 = 프로젝트 실적 시간이 있는 구성원(ACTIVE·RELEASED) |  |
| PMS_ActivityDependency__c / PMS_ActivityAssignee__c / PMS_ActivityProgress__c 필드 | Vol.P2 | TemplateDependency·ExternalKey·IsDriving / ExternalKey·AssignedBy / ExternalKey·PlannedPct·EnteredBy | WBS-004, ACT-001, WBS-007 |
| PMS_ActivityEvent__e 값·필드 | Vol.P2 | EventType OWNER_CHANGED 추가, 필드 정의(ACT-001 데이터 모델 표) | ACT-001, ACT-005 |
| PMS_ActivityEvent__e 정의 소유 | Vol.P2 | ACT-001 | ACT-001 |
| PMS_Activity__c 필드 | Vol.P2 | 3절 분담표의 계약 외 필드 전부(구조·담당·BPA·완료 설정·제약·엔진·진척·완료 결과) | ACT-001, WBS-003·004·005·007, ACT-004 |
| PMS_CompletionRule__mdt 필드 | Vol.P2 | Scope, IsBlocking, ParamSchema, LabelKey, IsActive | WBS-002 |
| PMS_ProjectEvent__e 값·필드 | Vol.P2 | EventType WBS_GENERATED, SCHEDULE_CONFIRMED, BASELINE_CHANGED 추가, Detail__c(Long Text, JSON: sourceType TEMPLATE·TEMPLATE_ADD·COPY, templateId, sourceProjectId, activityIds) | WBS-003·005, ACT-002·003 |
| PMS_Project__c 필드(PRJ-001 소유) | Vol.P2 | ScheduleStatus, WorkCalendar, CurrentBaselineNo, ScheduleConfirmedAt, IsCurrentUserPm(수식), PmUserIds(CFT-001 유지), SchedulePlannedPct, ScheduleActualPct, ScheduleSpi, ForecastFinishDate, BaselineFinishDate, ScheduleSlipDays, CriticalOpenCount, FloatWarningCount, RedActivityCount, LastScheduleRunAt, CloseType, CloseComment, CloseRequestedAt, ScheduleClosedAt, SopOverdueNotifiedAt | WBS-003·005·007·009 |
| PMS_ScheduleBaseline__c 필드 | Vol.P2 | Name, SnapshotFileId, Reason, ScheduleChange, ApprovalRequestId, ActivityCount, ForecastFinishDate, IsCurrent | WBS-005·006 |
| PMS_ScheduleChange__c 필드·값 | Vol.P2 | RecordNo, Name, RequestedBy, Origin, AiRecommendationId, Rebaseline, RequiresApproval, ApprovalReason, SimulatedAt·RunId, SlipDays, CriticalChanged, GateSlip, CustomerSlip, ApprovalRequestId, AppliedAt·By, BaselineNo. ChangeType 값 CUSTOMER_MILESTONE, INTERNAL_DELAY, SCOPE, RECOVERY, OTHER | WBS-006 |
| PMS_SupplierPartSchedule__c 필드 | Vol.P2 | Supplier, Item, ForecastDate, Status, EffectiveDate, DelayDays, LinkedActivity, DrivesSchedule, Source, LastSyncedAt, Remark, WarnedAt·Date | WBS-010 |
| PMS_WbsTemplateActivity__c 필드 | Vol.P2 | ExternalKey, NameEn·Zh, SortOrder, PhaseRoot, IsSummary, SupportRoles, OwnerDept, ProcessNo, ProcessPortalUrl, Description, ProgressMethod, CompletionApprover·Role, AutoCloseSource, QualTrigger, CompletionRuleKeys | WBS-001·002 |
| PMS_WbsTemplateDependency__c / PMS_WbsTemplateDeliverable__c 필드 | Vol.P2 | ExternalKey / NameEn·Zh, Sequence, CompletionRuleParams, ExternalKey | WBS-001·002 |
| PMS_WbsTemplate__c 필드 | Vol.P2 | ExternalKey, StandardEdition, ChangeNote, PreviousVersion, LeleReviewMode, ActivatedAt·By, ActivityCount, MandatoryCount, SimulatedDurationDays·At, ValidationStatus·Json, ImportStatus·Message | WBS-001·004 |
| PS(10절 PSG에 매핑) | Vol.P2 | PMS_PS_WbsTemplate_Read·Admin, PMS_PS_Schedule_Read·Plan·Admin·Integration, PMS_PS_Activity_Execute, PMS_PS_SupplierSchedule_Edit | 3절 |
| Vol.P1 CFT-001 | Vol.P2 | PmUserIds__c 유지(AccessLevel PM 구성원), 활성 CFT 구성원의 부서장(팀장)에게 프로젝트 Read 공유, PMS_SupplierPartSchedule__c를 프로젝트 공유 대상에 등록 |  |
| Vol.P1 CFT-001 | Vol.P3 | CftMember에 Employee 연결 필수(ED&D 직급·법인), 프로젝트 공유는 결재자 프로젝트 Read(APV V0-5)와 공존 |  |
| Vol.P1 CFT-002 | Vol.P2 | REQUESTED insert(프로젝트 복사)에도 팀장 승인 To-Do를 여는 경로, 구성원 해제 전 `countOpenAssignments` 확인 |  |
| Vol.P1 EFF-001·002 | Vol.P3 | PMS_EffortPlan__c·PMS_EffortActual__c DWH-002 복제 등록(시간만), 실적 Status APPROVED 의미 고정 |  |
| Vol.P1 EFF-001·003 | Vol.P2 | 액티비티 일정은 ForecastStart/End 사용, OWNER_CHANGED 구독으로 투입 계획 담당 정리 |  |
| Vol.P1 EFF-003 | Vol.P5 | 확인: 이 Vol.은 MART.V_PMS_RESOURCE_WEEKLY·MART.V_PMS_RESOURCE_PROJECT_WEEKLY(열 이름 그대로)와 KPI PMS_RES_UTIL_PLAN·PMS_RES_OVERLOAD_PERSONS·PMS_EFF_SUBMIT_RATE를 소비만 한다(레지스트리 등록·RAG 기준은 EFF-003). pmsResourceLoadWidget·pmsSorFulfillmentWidget(SOR-002)의 CMN_Widget__mdt 등록(PMS_W_RES_LOAD, PMS_W_SOR_FULFILLMENT)은 DSH-001이 한다. 인원 과부하 알림(PMS_RES_OVERLOAD)은 EFF-003, 프로젝트·부서 조기경보는 AIP-003으로 나눈다 | DSH-001, AIP-003, AIP-004 |
| Vol.P1 PRJ-001 | Vol.P2 | 위 PMS_Project__c 필드 추가, IsCurrentUserPm__c 수식, 상태 전이 서비스 공개 메서드(종료·재개, CLOSED 이벤트 발행), PMS_ProjectEvent__e 값·Detail 추가, 프로젝트 레코드 페이지에 "일정"·"WBS 편집"·"내 주간 진척"·"협력사 부품 일정" 탭과 Dynamic Action 자리(실행 WBS 생성, 다른 프로젝트에서 복사, 일정 확정 상신, 일정 다시 계산, 일정 변경 요청, 담당자 일괄 변경, 과제 종료, 프로젝트 재개), 프로젝트 생성 화면 표준 WBS 기본값은 PMS_WbsTemplateSelector |  |
| Vol.P1 PRJ-001 | Vol.P3 | PMS_Project__c.CostRag__c 쓰기 주체는 CST-004 핸들러, CostRagAsOf__c 추가 수용, 레코드 페이지 정의에 "비용"(UX-005 PMS_CostTab)·"산출물"·"디지털 스레드" 탭 자리, PMS PSG 생성 시 3절 PS 구성 |  |
| Vol.P1 PRJ-001 | Vol.P5 | PMS_Project__c에 QualityRag__c·QualityRagReason__c·QualityRagAsOf__c 추가 허용(필드는 DSH-001, 값은 DSH-002). OverallRag 산식 소유와 Q 반영 여부. 진행 중 상태 값 목록, PM__c 필드 이름. 프로젝트 레코드 페이지에 액션(AI 기간 추천, 지연 회복안 추천, 보고 만들기)·탭(AI 일정 비교, SOR 분해)·레일 패널(CONTEXT_PMS_WP, CONTEXT_PMS_RISK) 추가. SL PMS 앱 내비게이션 소유 | DSH-001·002·003, AIP-001·003·005 |
| Vol.P1 PRJ-002 | Vol.P3 | PMS_ProjectPart__c.IsLeadPart·Item 필드(DLV-002 품번 게시 대상) |  |
| Vol.P1 PRJ-003 | Vol.P2 | Activity__c Lookup의 선행을 ACT-001로, 일정 확정 후 PlannedDate 직접 수정 잠금(WBS-006 경유), 확정 전 날짜 변경 시 `PMS_ScheduleService.onCustomerMilestoneDatesChanged`, 수동 매핑 변경 시 `syncAnchors` 호출, 앵커 액티비티 COMPLETED 이벤트 구독으로 ActualDate 기록 |  |
| Vol.P1 SOR-001 | Vol.P5 | 확인: AIP-005는 채택 후보를 `PMS_RequirementService.createDrafts(projectId, List<PMS_RequirementDraft>, 'AI_DRAFT')`로 넘기고(CHANGED 행은 revise 경로) 기준선 결재는 SOR-001 절차를 따른다. 요청: SOR 문서 DocClass 값, Category·VerificationMethod 값 집합(Global Value Set으로 AIP-005 후보와 공유), SOR 문서 패널에 분해 버튼 배치. SOR-001 To-Do PMS_SOR_REVIEW와 구분해 AIP-005 To-Do는 PMS_SOR_AI_REVIEW를 쓴다 | AIP-005 |
| Vol.P1 SOR-002 | Vol.P3 | PMS_RequirementLink__c.TargetType 값에 DELIVERABLE·ACTIVITY·SYSTEM(+SystemLinkType) 포함, 관계 값(VERIFIES·DERIVED_FROM)을 두면 DLV-003이 그대로 쓴다 |  |
| Vol.P1 SOR-002 | Vol.P5 | 요구사항 충족 연결 생성 서비스(TargetType ACTIVITY, Status PLANNED) | AIP-005 BR-6, DSH-002 BR-3 |
| Vol.P2 ACT-001 | Vol.P3 | 액티비티 레코드 현재 단계 탭에 `pmsDeliverablePanel`, 롤업 필드 6개 수용 |  |
| Vol.P2 ACT-004 | Vol.P3 | 완료 조건 RuleKey `PMS_DLV_MANDATORY_DONE`(PMS_DeliverableCompletionChecker) 등록, 롤업 변화 시 자동 종료 판단 |  |
| Vol.P2 WBS-002 | Vol.P3 | DeliverableType STD_FORM, TemplateDocument → Lookup(CMN_DocTemplate__c), SystemLinkType = PMS_SystemLinkType__mdt 키, InputDeliverableCodes__c(Text 255) 추가, 유형별 ApprovalRequired 규칙(APPROVAL ⇒ true, LINK·SYSTEM_LINK ⇒ false) |  |
| Vol.P2 WBS-003, ACT-002, ACT-003 | Vol.P3 | 액티비티 생성·추가·복사 마지막 단계에서 `PMS_DeliverableService.syncFromTemplate` 호출 |  |
| Vol.P2 WBS-003·ACT-001 | Vol.P5 | 확인: PMS_Activity__c.ActivityCode__c(Vol.P2 제안 필드)를 AIP-001 기간 통계의 키로 쓴다. 액티비티 담당 필드 이름(OwnerId 또는 Owner__c) 확정 | AIP-001 BR-3, DSH-001 BR-6 |
| Vol.P2 WBS-004 | Vol.P5 | 확인: `PMS_ScheduleService.simulate(projectId, List<PMS_ScheduleChangeSpec>)`(DML 0, anchoredMilestones·gateMilestones)를 AIP-001이 기간 추천 가능성·회복안 검증에 쓴다(2,000 액티비티 응답 시간 확인 — Vol.P2 기준 600 액티비티 5초). 요청: 공장 근무일 달력의 Snowflake 복제 `CORE.PMS_WORK_CALENDAR`, DATES_CHANGED 이벤트는 CPM 재계산 뒤 발행 | AIP-001 |
| Vol.P2 WBS-005 | Vol.P5 | 기준선 판의 액티비티 일자 조회 메서드(스냅숏 JSON 해석) | AIP-001 BR-10, AIP-004 BR-4 |
| Vol.P2 WBS-006 | Vol.P5 | 확인: `createFromAi(projectId, aiRecommendationId, specs, reason)`에 대표 추천 Id 1개와 reason의 RunKey로 여러 추천을 묶는다. REJECTED·CANCELLED 결과는 AIP-001 동기화 배치가 읽는다 | AIP-001 BR-7·8 |
| Vol.P2 WBS-007 | Vol.P3 | P-44 산출물 완료율 = PMS_Activity__c.DlvCompletionPct__c |  |
| Vol.P2 WBS-007 | Vol.P5 | 확인: PMS_Project__c.SchedulePlannedPct__c·ScheduleActualPct__c(Vol.P2 제안) 이름 확정, 요약 액티비티 Progress·Rag 롤업 보장 | DSH-001 BR-3·9 |
| Vol.P3 CST | Vol.P2 | 액티비티별 ED&D 비용 조회 서비스(일정 변경 화면 현황 열, PMS_PS_Cost_Read 보유자만) |  |
| Vol.P3 CST-003 | Vol.P5 | 확인: PMS_ViewCost는 PMS_PS_Cost_Read(PM·PMO·Finance·Executive)에 이미 포함. 요청: PMS_Project__c.CostRag__c와 이 Vol. 비용 필드(보고 라인 비용 4개·CostRag, CostSnapshotJson__c, PMS_Decision__c.CostDetail__c) FLS를 PMS_PS_Cost_Read에만, 비용 PS를 받는 PSG 확정 | DP5-3 |
| Vol.P3 CST-004 | Vol.P5 | 비용 위젯을 PMS_W_CST_* 키로 등록(PMO·경영 템플릿 추가용), 비용 증빙 DocClass INDEX_SCOPE NONE | DSH-001 BR-13, AIP-004 BR-9 |
| Vol.P3 DLV-001 | Vol.P2 | WBS_GENERATED 구독으로 실행 산출물 행 생성(TEMPLATE·TEMPLATE_ADD = 템플릿 산출물 기준, COPY = 원본 프로젝트 정의 복사, 멱등), PMS_SystemLinkType 전역 값 집합 사용, 산출물 패널을 액티비티 레코드 정의 파일에 추가, NOT_APPLICABLE은 승인된 미적용만, Status 값 계약 유지(WBS-007 Roll-up 필터) |  |
| Vol.P3 DLV-001·003·005 | Vol.P5 | 산출물 레코드 페이지에 AI 초안 액션·레일 패널 배치, PMS_DeliverableTrace__c INPUT_OF 방향(To = 산출물 또는 액티비티) 확정, 표준 양식 내려받기 링크 | AIP-002 |
| Vol.P4 GAT-001·004 | Vol.P2 | Gate 일정 = GateCode 마일스톤 액티비티(DATES_CHANGED 구독), Gate PASSED·CONDITIONAL 시 `autoComplete(source GATE)`, Gate 재심사로 마일스톤을 다시 열 때는 PMO 재시작 |  |
| Vol.P4 GAT-003 | Vol.P3 | 산출물 자동 점검은 `PMS_DeliverableQueryService.byCodes`, EvidenceDeliverableIds 형식은 쉼표 구분 Id(DLV-004가 검색) |  |
| Vol.P4 GAT-003·005 | Vol.P5 | 산출물 자동 점검 규칙과 AIP-004 BR-6 판정 코드 정합(같은 판정은 GAT-003 서비스 호출), AnomalyStatus__c 이상 값은 REVIEW_REQUIRED·CONFIRMED_ISSUE로 쓴다(Vol.P4 정의 값) | AIP-004, DSH-002 |
| Vol.P4 GAT-005 | Vol.P3 | AnomalyStatus__c 값 쓰기, LatestRevisionDuplicate__c 사용, PublishedFromRevision이 있는 리비전은 복사 문서로 보지 않음 |  |
| Vol.P4 RSK-001·ISS-001 | Vol.P5 | 확인: `PMS_RiskService.createFromSource(PMS_RiskRequest)`(Vol.P4 정의, ExternalKey 멱등)를 AIP-003이 쓴다. 요청: PMS_RiskRequest에 probability·impact 제안값을 넣을 수 있는지, RISK_CATEGORY 일정 코드 값. ISS-001 IsAged30__c 수식 필드 | AIP-003 BR-5, DSH-001 BR-6 |
| Vol.P5 AIP-002 | Vol.P3 | 산출물 레코드 레일 AI 패널(UseCase PMS_DELIVERABLE_DRAFT) 활성화 |  |
| Vol.P5 DSH-002·003, AIP-004 | Vol.P3 | 비용 표시 전 `PMS_CostAccess` 확인, 포트폴리오는 `PMS_CST_PORTFOLIO`, 산출물 KPI 3종 뷰 구현·위젯 |  |
| Vol.P5 DSH·AIP | Vol.P2 | 3절 KPI 키, `simulate` API(AIP-001·003), `createFromAi`(AIP-001 채택 → 변경 요청), `getMyActivities` 위젯 |  |
| Vol.P6 APV-001 | Vol.P2 | PROJECT_ROLE 결재선 해석(ACT-004 ROLE 완료 승인) |  |
| Vol.P6 APV-001 | Vol.P3 | PROJECT_ROLE 해석 메서드 공개(DLV-002 기여자가 호출) |  |
| Vol.P6 CHG-001 | Vol.P2 | 프로젝트 변경의 SCHEDULE 유형은 PMS_ScheduleChange__c를 참조하고 일정 변경을 따로 만들지 않음 |  |
| Vol.P6 CHG-001 | Vol.P3 | 비용 변경 승인 시 `PMS_CostPlanService.confirmBaseline` 호출(재확정) |  |
| Vol.P6 INT-001 | Vol.P2 | BPA 속성 동기화 대상 = PMS_WbsTemplateActivity__c(ProcessPortalActivityId 키) |  |
| Vol.P6 INT-002 | Vol.P3 | PMS_LaborRate__c upsert(ExternalKey `{CompanyCode}-{JobGradeCode}-{Year}`, Source HR) |  |
| Vol.P6 INT-003 | Vol.P3 | DMS → PMS_CostActual__c 수신 계약(CST-002 BR-6), 산출물 이벤트 구독(금형 관련 DocClass) |  |
| Vol.P6 INT-003·004 | Vol.P2 | 외부 완료 사건 → `autoComplete`(source DMS·PDM·PART_DEV·ALM), 부품개발 일정 → `upsertFromSource` |  |
| Vol.P6 INT-004 | Vol.P3 | PDM_DRAWING·PDM_BOM 리졸버 구현·유형 교체, MART.V_PMS_TRACE_EDGE와 같은 키 규칙 |  |
| Vol.P6 INT-005 | Vol.P2 | WBS-003 BR-11·12 호출 시점·문맥 구현, QMS 검사기 2종(PMS_QmsLeleCompletionChecker, PMS_QmsQualCompletionChecker)과 PMS_CompletionRule__mdt 행 배포, JUDGED 이벤트 → `autoComplete(source QMS_QUAL)`, OWNER_CHANGED·DATES_CHANGED → QMS 반영 검토 갱신 |  |
| Vol.P6 INT-005 | Vol.P3 | QMS_QUAL_PLAN·QMS_PPAP 등 SYSTEM_LINK 유형·리졸버 등록, QMS 이벤트 수신 시 `applySystemStatus` 호출, 산출물 이벤트 구독 |  |
| Vol.P6 PRF-001 | Vol.P5 | (선택) 성과 지표 계산에 MART.PMS_PROJECT_SNAPSHOT_DAILY·MART.PMS_MILESTONE_STATUS 사용 가능 | — |
| WI 공수 | Vol.P2 | WBS-006 7, ACT-002 6, ACT-004 8 | 위 공수 조정 |
| interfaces.md 5절 | Vol.P6 | 바인딩 키 추가(제안): QUALIFICATION(QMS_QualPlanGateway, 구현 Vol.2 DVQ-005, 기본 To-Do), LELE_PROJECT(QMS_LeleProjectGateway, 구현 Vol.4 LEL-005 → Vol.8 AIQ-007, 기본 no-op), STABILIZATION(QMS_StabilizationGateway, 구현 Vol.4 EFC-001, 기본 To-Do), PMS_PROJECT(QMS_PmsProjectGateway: searchProjects, getActivityContext, 구현 PMS-12-INT-005, 기본 빈 결과). DTO QMS_PmsActivityContextDTO·QMS_PmsProjectDTO를 공통 패키지에 | INT-005 호출 경로, BR-15 |
| interfaces.md 6절 | Vol.P6 | PMS-12-INT-005 행에 연결 대장·게이트웨이 4종·구독 이벤트 6종(LeleApplication, QualPlan, Stabilization, Claim, Ncr, FourM) 반영 | INT-005 |
| pms-architecture.md 4절 | Vol.P6 | 공수: INT-004 6→7, INT-005 5→7, APV-001 3→4, PRF-002 4→5, CHG-001 5→6 | 10절 표 |
| pms-architecture.md 5절 | Vol.P6 | 객체 추가(제안): PMS_SystemLink__c(INT-005), PMS_ProcessDefinition__c(INT-001), PMS_ProjectChangeLine__c(CHG-001), PMS_SupplierCostStage__c(CHG-002). 메타데이터: PMS_SystemLinkHandler__mdt, PMS_ExternalCodeMap__mdt, PMS_QmsTriggerRule__mdt, PMS_ApprovalTargetMap__mdt, PMS_PeerEvalCriterion__mdt, PMS_CostStageRule__mdt | 3절 |
| pms-architecture.md 5절 | Vol.P6 | PMS_PeerEvaluation__c "MD Performance" → "Lookup Performance, OWD Private" | DP6-3 |
| pms-architecture.md 5절 | Vol.P6 | PMS_ProjectChange__c 요약에 Mode(REQUEST, RECORD), Origin, 원천 텍스트 Id, ExternalKey 추가 | CHG-001 |
| pms-architecture.md 8절 | Vol.P6 | "성과 지표" 행: QMS 쪽 계약을 CMN_KpiValue__c(공장·라인 차원이라 프로젝트 품번을 가를 수 없음)에서 연결 대장(NCR·CLAIM) + Snowflake 등록 쿼리 대체로 정정. "인정시험 의뢰" 행의 게이트웨이 QUALIFICATION을 5절 등록부에 올림 | INT-005 BR-7·14 |
| pms-architecture.md 9절 | Vol.P6 | PMS_ProjectEvent__e EventType에 SCHEDULE_CONFIRMED(제안, 기준선 승인, BaselineNo 포함) 추가 — WBS-005 발행 | INT-005 BR-5 |
| pms-architecture.md·interfaces.md 6절 | Vol.P4 | 새 이름 등록: PMS_GateCheckRule__mdt, PMS_DeliverableAnomaly__c, PMS_AnomalyRule__mdt, PMS_GateAutoChecker·PMS_GateAutoCheckExtension·PMS_GateDecisionExtension, PMS_GateRagScorer, PMS_GateQueryService, PMS_LessonCandidateService, PMS_RiskQualityService, PMS_GateQuestionnaireUsageCheck, PMS_AnomalyDetectionService, PMS_SopHandoverService, MART.V_SF_KPI_PMS_RISK_GATE, KPI 키 6개, 코드 그룹 RISK_CATEGORY·ISSUE_TYPE | 3절 |
| 객체 추가 | Vol.P2 | PMS_WbsTemplateDataItem__c(표준 필수 데이터 항목), PMS_ActivityDataValue__c(데이터 값) | WBS-002, ACT-001 |
| 객체 추가 | Vol.P2 | PMS_ScheduleRun__c(계산 대기열·실행 기록), PMS_ScheduleRunStep__mdt(후처리 단계 등록) | WBS-004 |
| 객체 추가 | Vol.P2 | PMS_ScheduleChangeItem__c(일정 변경 항목) | WBS-006 |
| 객체 추가 | Vol.P2 | PMS_AssigneeChange__c(담당자 변경 요청·일괄 이력) | ACT-005 |
| 결재 유형 | Vol.P2 | PMS_SCHEDULE_CONFIRM, PMS_SCHEDULE_CHANGE, PMS_ACTIVITY_COMPLETE, PMS_ACTIVITY_FORCE, PMS_PROJECT_CLOSE, PMS_ASSIGNEE_CHANGE | 3절 |
| 소유 분담 | Vol.P2 | PMS_Activity__c 객체 메타데이터 생성은 개발 순서상 먼저인 ACT-001, WBS-003은 생성 필드·서비스 | ACT-001, WBS-003 |
| 전역 값 집합 | Vol.P2 | PMS_SystemLinkType(QMS_QUAL_PLAN, QMS_PPAP, QMS_LELE, QMS_FOURM, CMN_MEETING, PDM_DOCUMENT, DMS_TOOL, ALM_ITEM, PART_DEV, OTHER), DLV-001과 공유 | WBS-002 |
