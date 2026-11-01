# 검토 패키지

`scripts/build_review_pack.py`가 각 Vol. 검토 요청 절에서 자동으로 모은 문서다. 직접 고치지 말고 Vol. 문서를 고친 뒤 다시 생성한다.

## 1. 결정 항목 (101건)

### Vol.0 (10건)

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

## 2. Vol.0 변경 요청 (70건, 대상순)

| 대상 | 요청 Vol. | 변경 내용 | 근거 |
| --- | --- | --- | --- |
| 3.3 DoD | Vol.7 | 새 KPI를 만드는 WI는 QMS_KpiDefinition__mdt 레코드와 라벨 3개 언어를 같은 WI에서 추가 | DSH-001 BR-1 |
| CMN-00-AI-001 | Vol.8 | SL Quality Assistant 토픽 목록은 Vol.8 AIQ-001이 정의, 기능 스위치 키 QMS_AI_RCA·QMS_AI_8D·QMS_AI_LELE·QMS_AI_QA·QMS_AI_EW·QMS_AI_4M_TEST·QMS_AI_AUDIT_PREP 등록 | AIQ-001 |
| CMN-00-AI-002 | Vol.8 | DocClass INDEX_SCOPE가 NONE이면 색인 제외(EXCLUDED) | AIQ-013 |
| CMN-00-AI-004 | Vol.3 | UseCase 값 QMS_COA_ANOMALY 추가 | IQC-008 |
| CMN-00-AI-004 | Vol.6a | UseCase 값 QMS_4M_TEST(4M 필요 시험 추천) 추가 — QMS-08에서 확정 | 4MC-003 화면 자리 |
| CMN-00-AI-004 | Vol.7 | Vol.8이 정한 UseCase별 키 규칙(AI_HIT_TOP1·TOP3·ADOPT_RATE_{UseCase}, AI_HIT_TOP5_QMS_LELE) 반영 — Vol.8 변경 요청과 같음, 이 Vol.은 레지스트리 등록만 | DSH-012 |
| CMN-00-AI-004 | Vol.8 | UseCase 값 QMS_AUDIT_PREP 추가(QMS_4M_TEST·QMS_COA_ANOMALY 요청과 함께 확정), CMN_AiRecommendation__c.FinalizedAt__c(DateTime) 추가, 정확도 KPI 키 규칙 `AI_HIT_TOP1_{UseCase}`·`AI_HIT_TOP3_{UseCase}`·`AI_ADOPT_RATE_{UseCase}` 명시(QMS_LELE는 TOP5 추가) | AIQ-006, AIQ-015 |
| CMN-00-AI-005 | Vol.8 | BR-1(b) 공장 권한 강제 방식을 세션 공장 범위 표 + 행 접근 정책으로 구체화, 품질 골든 평가셋 위치 `docs/ai/eval/qms/` | AIQ-010 |
| CMN-00-APV-002 | Vol.2 | 유형별 결재선 기여 인터페이스(CMN_ApprovalLineContributor) 추가 — DVQ-005 BR-4, DVQ-008 BR-5 |  |
| CMN-00-APV-002 | Vol.2 | APPROVAL_ROLE 값 추가: LAB_RECEIVER(시험 접수자), SUPPLIER_QUALITY(협력사 품질 담당) |  |
| CMN-00-APV-002 | Vol.3 | APPROVAL_ROLE 값: SQ_MANAGER(협력사 품질팀장), IQC_LEAD(수입검사 반장). SUPPLIER_QUALITY는 Vol.2 요청과 같음 | IQC-004·005, PPA-004, PIS-003 |
| CMN-00-APV-002 | Vol.4 | APPROVAL_ROLE 값 LELE_OWNER(품질경영팀 레슨런 관리자). Role 해석을 공개 메서드(예: CMN_RoleResolver.resolveUser(roleCode, plantId, deptId))로 제공 | LEL-001, RPP-001 BR-4 |
| CMN-00-APV-002 | Vol.5 | APPROVAL_ROLE 값 CQ_MANAGER(고객품질팀장) | CLM-004·007·009·010·011 |
| CMN-00-APV-002 | Vol.6a | APPROVAL_ROLE 값 PE_MANAGER(생산기술팀장) 추가 | 4MC-005 BR-2 |
| CMN-00-APV-002 | Vol.6b | APPROVAL_ROLE 값 METROLOGY_LEAD(측정기 관리 책임), LAB_MANAGER(분석실 책임자), TRAINING_COORDINATOR(공장 교육 담당). LAB_RECEIVER는 Vol.2 요청 값을 분석실 접수에도 사용 | GAU-002~004, LAB-002·003, TRN-001~003 |
| CMN-00-APV-002 | Vol.6c | APPROVAL_ROLE 값 QMS_MANAGER(품질경영팀장: 심사 프로그램·보고서 승인, 자격·독립성 예외) | IAU-002·003·006, CER-001, IMP-001 |
| CMN-00-ARC-001 | Vol.5 | Multi-Currency 활성화 전제(D-3) | CLM-010 |
| CMN-00-ARC-003 | Vol.4 | 공장 토큰 없는 전사 연번 패턴(LL-, LA-) 지원 확인(ScopeField 공란) | LEL-001·005 |
| CMN-00-DOC-001 | Vol.3 | CMN_Document__c에 Supplier__c·SupplierVisible__c 추가, SharingConfig SupplierField 등록, 협력사 공개 파일 ContentDocumentLink Visibility = AllUsers | SPP-002 BR-3·4, PPA-004 BR-4 |
| CMN-00-DSH-001 | Vol.7 | CMN_Widget__mdt에 ConfigSchema__c·AvailableSystems__c·MobileSupported__c 추가. 보드 편집 모드에서 `cmnWidgetConfigForm` 호출, 설정 검증 인터페이스 CMN_WidgetConfigValidator. Persona 값 QM_HEAD·VIEWER·SYSTEM_ADMIN 추가. 템플릿 해석기 인터페이스 CMN_DashboardTemplateResolver + 등록 메타 CMN_DashboardResolver__mdt(템플릿 선택·config 토큰 치환). 템플릿 복사 시 미배포·비활성·권한 없는 위젯 건너뛰기. QMS 보드 고객 필터(선택) | DSH-004, DSH-013 |
| CMN-00-DWH-001 | Vol.4 | CORE 테이블 추가: SPC_SUBGROUP, SPC_SIGNAL, SPC_CAPABILITY, SPC_CONSTANTS, SPC_RULE_DEF, MES_PRODUCTION, MES_DEFECT, EOL_TEST_RESULT(SPC_MEASUREMENT는 기존 이름 유지, 컬럼 확정) | SPC-002·003, EFC-002, FQC-004 |
| CMN-00-DWH-001 | Vol.8 | ML 스키마 객체(코퍼스·검색 서비스·위험 테이블), 역할 ROLE_AI_SERVICE, SNOWFLAKE.CORTEX_USER 권한, Resource Monitor 대상에 Cortex 사용량 포함 | AIQ-002, AIQ-011 |
| CMN-00-DWH-001 | Vol.9 | RAW 표준 열에 `_SOURCE_KEY` 추가, 공용 SAP·MES·로트 계보 RAW·CORE 테이블 목록과 소유(QMS-09) 기재 | INT-001 BR-6, INT-008·012 |
| CMN-00-DWH-003 | Vol.4 | KPI 예시 키 QMS_CPK → QMS_SPC_CPK로 변경(이름 통일) | SPC-003 |
| CMN-00-DWH-003 | Vol.5 | CMN_KpiValue__c에 Vehicle__c(Lookup CMN_Vehicle__c) 차원 추가 | B2B-003 BR-5 |
| CMN-00-DWH-003 | Vol.6b | CMN_KpiValue__c에 차원 Department__c(Lookup CMN_Department__c) 추가, ExternalKey 해시에 포함. 6b의 QMS_TRN_PLAN_RATE Department 차원이 이 변경을 기다리는 상태(반영 전에는 Plant 단위만 적재) | TRN-003 BR-9, 3절 KPI 표 주석 |
| CMN-00-DWH-003 | Vol.6c | CMN_KpiValue__c.PeriodType__c에 QUARTER 추가(Vol.7 요청과 같음). 추가 전에는 QMS_AUDIT_REPEAT_RATE, QMS_SUPPLIER_GRADE_COUNT_A~D 적재 보류 | 3절, IAU-007 BR-4, SQM-002 BR-5 |
| CMN-00-DWH-003 | Vol.7 | CMN_KpiValue__c.PeriodType__c에 QUARTER 추가, 차원 Department__c·Vehicle__c·ProductGroup__c 추가(Vol.5·Vol.8 요청과 같음), (KpiKey, PeriodType, PeriodStart) 조회 인덱스 요청, 내부 OWD Public Read Only·외부 Private 명시. 공통 RAG UDF MART.F_KPI_RAG와 MART.KPI_RAG_RULE을 DWH 공통 자산으로. 적재 완료 이벤트 CMN_KpiLoaded__e. 예시 키 QMS_CPK → QMS_SPC_CPK | DSH-001, DSH-002, DSH-005 BR-4, DSH-010 BR-3 |
| CMN-00-DWH-003 | Vol.8 | CMN_KpiValue__c에 ProductGroup__c 차원 추가(제품군 위험 점수, Vol.5 Vehicle__c 요청과 함께) | AIQ-011 |
| CMN-00-DWH-003 | Vol.9 | CMN_ResultInbound__e를 Snowflake 외 원천(Mule 발행)에도 사용, EventType 명명·ExternalEventId·schemaVersion 규약 명시 | INT-002 BR-5 |
| CMN-00-DWH-004 | Vol.6a | Wave W2 → W1(4M 영향 범위 BOM 조회·적용 시점 로트 추적·NCR 봉쇄 후보가 W1 PoC 시나리오 1·3에 필요) | 4MC-003, 4MC-007, NCR-003 |
| CMN-00-DWH-004 | Vol.6b | CMN_DwQuery__mdt에 Mode__c(QUERY, PROCEDURE) 추가, `CMN_DwQueryService.callProcedure(queryKey, params)` — Mule이 ROLE_TRANSFORM 연결로 등록 프로시저만 실행, 타임아웃 60초, 응답 VARIANT 최대 1MB | MSA-003 BR-1 |
| CMN-00-DWH-004 | Vol.7 | 포털 사용자 호출 시 공장 필터 대신 협력사 필터 강제 모드(파라미터명은 QMS_WidgetQuery__mdt.SupplierParam) | DSH-002 BR-4 |
| CMN-00-DWH-004 | Vol.8 | Mule API에 SEARCH(Cortex Search)·ANALYST(Cortex Analyst) 연산 추가(prc-ai-snowflake-api), PROCEDURE 모드(Vol.6b 요청과 동일)로 QMS_RCA_RANK 호출 | AIQ-002, AIQ-003, AIQ-010 |
| CMN-00-DWH-004 | Vol.9 | Mode__c 값 QUERY·PROCEDURE·SEARCH·ANALYST(Vol.6b·8 요청), callProcedure, Warehouse__c, 모드·키별 동시 실행 한도, 공통 오류 응답 형식 | INT-020 BR-1·3·4 |
| CMN-00-INT-001 | Vol.7 | 인터페이스 IF-SF-002(Salesforce KPI 정의 → Snowflake MART.KPI_RAG_RULE, 일 1회) 카탈로그 추가 | DSH-001 BR-3 |
| CMN-00-INT-001 | Vol.9 | 카탈로그에 3절 인터페이스 28건 등록, 통합 사용자를 도메인별 3개(SAP·MES/DW·외부 시스템)로 분리, 이벤트형 인터페이스 로그를 1분 묶음으로 남기는 규칙 추가 | INT-001 BR-5·8 |
| CMN-00-INT-003 | Vol.9 | 자재·공급업체·구매정보레코드 단건 즉시 동기화 API(Mule prc) 제공 | INT-004 BR-4 |
| CMN-00-MDM-003 | Vol.5 | Account.RootCauseDueDays__c(원인 회신 기한, 기본 10일) 추가. ClaimFormTemplate 값 확정 | CLM-007 BR-3 |
| CMN-00-MDM-003 | Vol.6a | Account(고객)에 ChangeNoticeLeadDays__c(4M 사전 통보·승인 기한 일수), ConcessionCustomerApproval__c(특채 시 고객 승인 필요) 추가 — CSR 필드 | 4MC-001 BR, 4MC-005 BR-6, NCR-003 BR-5 |
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
| CMN-00-MTG-001 | Vol.6c | 회의 유형 값 MANAGEMENT_REVIEW 추가, 회의를 부모로 한 문서 등록(DOC-001) 확인 | CER-001 BR-5, CER-002 BR-5 |
| CMN-00-NTF-001 | Vol.3 | BR-5 링크 변환을 인터페이스 CMN_RecipientUrlResolver + Custom Metadata 등록 방식으로 명시(CMN이 QMS 클래스를 직접 참조하지 않게) | SPP-001 BR-6 |
| CMN-00-SEC-001 | Vol.2 | 페르소나 추가: QMS_PSG_DevEngineer(개발팀, 제품 인정시험 계획 작성), QMS_PSG_LabTester(신뢰성·광학 시험 담당) |  |
| CMN-00-SEC-001 | Vol.3 | PSG 추가: QMS_PSG_SupplierPortal(협력사 포털 사용자) | SPP-001 |
| CMN-00-SEC-001 | Vol.4 | PSG 추가 QMS_PSG_ProcessEngineer(생산기술·공정 담당: SPC 알람·OCAP, 수평전개 실행). PMS PSG(PM·CFT·PMO)에 QMS_PS_Lele_Read·QMS_PS_Lele_Edit 포함 | SPC-005, LEL-005 |
| CMN-00-SEC-001 | Vol.5 | Public Group QMS_GRP_CUSTOMER_QUALITY(고객 품질 담당 전원) 운영 규칙 | B2B-005·006, CLM-007 |
| CMN-00-SEC-001 | Vol.6a | Viewer PSG에 QMS_PS_FourM_Request·QMS_PS_Ncr_Create·QMS_PS_Ncr_Respond 추가, Custom Permission QMS_ViewCost를 비용 PS에 포함 | 3절 PS 매핑, NCR-007 BR-3 |
| CMN-00-SEC-001 | Vol.6b | PSG 추가: QMS_PSG_Metrology(측정기·교정 담당), QMS_PSG_TrainingCoordinator(공장 교육 담당). Vol.2 요청 QMS_PSG_LabTester의 범위에 분석실 분석자 포함 | 3절 매핑 |
| CMN-00-SEC-001 | Vol.6c | Custom Permission QMS_AuditFindingAnyEdit 정의(QualityAdmin PSG) | IAU-004 BR-12 |
| CMN-00-SEC-001 | Vol.7 | Custom Permission QMS_DashboardAllPlants(CMN_PSG_Executive, QMS_PSG_QualityAdmin 포함, 품질본부장은 PS QMS_PS_Dashboard_AllPlants 개별 부여), 모든 QMS PSG에 QMS_PS_Dashboard_Base | DSH-002 BR-1 |
| CMN-00-SEC-001 | Vol.8 | QMS_PS_Ai_User·QMS_PS_Ew_Edit·QMS_PS_Ai_Admin을 PSG에 추가, Agentforce 사용 권한 셋 라이선스 할당 규칙 | 3절 |
| CMN-00-SEC-002 | Vol.3 | BR-4 협력사 공유 대상 = 협력사 Account 포털 Manager 역할 및 하위 그룹. BR 추가: 외부 OWD는 업무·CMN_Item__c Private, CMN_Plant__c·CMN_CodeGroup__c·CMN_Code__c만 Public Read Only, CMN_Item__c는 CMN_SupplierItem__c 기준으로 협력사 그룹에 Read 공유 | SPP-001 BR-4·5 |
| CMN-00-SEC-002 | Vol.4 | 지식 객체(QMS_LessonLearned__c, QMS_LeleCheckpoint__c, QMS_LeleApplication__c, QMS_HorizontalDeploy__c, QMS_HorizontalDeployTarget__c)는 SharingConfig 대상에서 빼고 내부 OWD Public Read Only(D-9 권고 확정 시) | HZD-001 BR-3, LEL-001 BR-5 |
| CMN-00-SEC-002 | Vol.5 | 지식 공유 규칙: CLOSED 8D를 "모든 내부 사용자"에 Read(Sharing Reason QMS_Knowledge) — D-9 결정과 함께 | CLM-001 BR-9 |
| CMN-00-SEC-004 | Vol.6a | Snowflake 역할 ROLE_QMS_COST 추가, NCR 비용 컬럼 Masking Policy | NCR-008 BR-4 |
| CMN-00-SEC-004 | Vol.9 | Mule 통합 사용자 3개와 권한 범위, Snowflake ROLE_INGEST의 RAW 개인정보(VIN) 접근 제한 재확인 | INT-001 BR-8, INT-014 BR-5 |
| CMN-00-TDO-001 | Vol.3 | 포털 사용자 Assignee 허용, 포털 사용자 To-Do는 TDO-003 포탈 API·TDO-004 사내 홈에서 제외 | SPP-002 BR-2 |
| CMN-00-UX-001 | Vol.6b | 사원증 바코드(사번) 스캔을 BarcodeScanner 공통 유틸리티에 포함(교육 출석·MSA 평가자 등록) | TRN-002, MSA-002 |

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
