# 데모 데이터 명세 (SL QMS PoC·개발 공용)

이 문서는 PoC 시연과 기능 개발·테스트가 같은 가상 데이터를 쓰도록 정한 계약이다. 기준정보의 정확한 값은 `data/demo/master/demo_master.json`이 원천이고, 이 문서는 시나리오·파일 구조·키 규칙·WI 연결 방법을 정한다. 이름과 값이 두 곳에서 다르면 JSON이 우선이다.

## 1. 원칙

- **전부 가상이다.** 회사·공장·협력사·인물·차종·품번은 실존 대상과 무관하다. 고객 OEM은 그룹 식별용 이름만 쓰고 CSR 값(기한·레벨)은 데모 가정이다. RFP 문장, 담당자, 실제 공장명, 실제 조직명은 쓰지 않는다.
- **운영 Org·운영 Snowflake에 적재하지 않는다.** 적재 스크립트는 대상 Org가 Scratch 또는 Sandbox인지, Snowflake DB 이름이 `SL_QDW_DEMO` 또는 `SL_QDW_DEV`인지 검사하고 아니면 중단한다.
- **재현 가능해야 한다.** 생성기는 Python 3.9+ 표준 라이브러리만 쓰고 seed(`meta.seed`)를 고정한다. 같은 명령이면 같은 파일이 나온다. `--today YYYY-MM-DD`로 기준일을 옮기면 모든 날짜가 같은 간격으로 이동한다.
- **기대값(골든)을 함께 만든다.** 통계(SPC·MSA)·집계(KPI)·AI 추천의 정답을 생성기가 계산해 `data/demo/expected/`에 둔다. 기능 WI의 AC는 이 파일과 비교하는 테스트로 검증한다.

## 2. 기준일과 기간

| 항목 | 값 |
| --- | --- |
| 기준일(demoToday) | 2026-12-01 |
| 이력 시작 | 2024-12-01 (24개월) |
| 수입검사·SPC·MES 상세 | 최근 6개월(2026-06-01 ~ 2026-11-30) |
| 고객 B2B·NCR·8D·클레임·LELE | 24개월 |

## 3. 파일 구조와 소유

| 경로 | 내용 | 작성 주체 |
| --- | --- | --- |
| data/demo/master/demo_master.json | 기준정보·코드·시나리오 목록 | 조정자(이 문서와 함께) |
| data/demo/generator/common.py | 마스터 로드, seed RNG, 날짜 이동, CSV·JSON 쓰기 공통 함수 | 조정자 |
| data/demo/generator/gen_salesforce.py | Salesforce 레코드 CSV(기준정보·업무·시나리오 S0~S6, S9, S12) | Salesforce 데이터 작업 |
| data/demo/generator/gen_snowflake.py | Snowflake 원천·CORE 테이블 CSV, SPC·MSA·KPI·조기경보 기대값, DWH-004 응답 목 | Snowflake 데이터 작업 |
| data/demo/generator/generate_all.py | 두 생성기 순서 실행 | 조정자 |
| data/demo/salesforce/NN_{객체}.csv, load-plan.json | Bulk upsert용 CSV(외부 키 관계 열 `Field__r.ExternalKey__c`)와 적재 순서 | Salesforce 데이터 작업. 단 90번대(KPI 값, SPC 계획·한계·알람, MSA 연구)는 Snowflake 데이터 작업 |
| data/demo/salesforce/users/*.json | `sf org create user` 정의(라이선스 페르소나) | Salesforce 데이터 작업 |
| data/demo/snowflake/{SCHEMA}.{TABLE}.csv, load_demo.sql | Snowflake 적재 파일·스크립트 | Snowflake 데이터 작업 |
| data/demo/expected/*.json, *.csv | 골든 기대값, 시나리오 논리 키 → 실제 번호 매핑(scenario_keys.json) | 각 데이터 작업(파일별) |
| data/demo/mocks/dwh/{QueryKey}/{case}.json | DWH-004 등록 쿼리 응답 목(LWC Jest·Apex 콜아웃 목·계약 테스트 공용) | Snowflake 데이터 작업 |
| data/demo/mocks/apex/*.json | 화면 Apex 응답 목(LWC Jest) | Salesforce 데이터 작업 |
| data/demo/fixtures/demo_fixtures.json | Apex 테스트용 소형 고정 데이터(정적 리소스 QMS_DemoFixtures로 배포) | Salesforce 데이터 작업 |
| scripts/demo/load_salesforce.sh, load_snowflake.sh | 적재 실행(대상 검사 포함) | 각 데이터 작업 |
| docs/ai/eval/*.jsonl | AI 평가셋(골든 질문·추천 정답) | AI 시나리오 작업 |
| data/demo/expected/ai_rca_S1.json, ai_rca_S2.json, lele_S6.json, ew_S11.json, qa_S5.json | AI 기대값(원인 추천·LELE 추천·조기경보·Q&A 정답) — 생성된 데이터와 Vol.4·8 규칙으로 계산 | AI 시나리오 작업 |

## 4. 키 규칙

- **기준정보**: demo_master.json의 키를 그대로 쓴다. PlantCode, `{PlantCode}-{LineCode}`, ItemNo, SapVendorNo, `{VendorNo}-{ItemNo}-{PlantCode}`, `{ItemNo}-{CharNo}-{EffectiveFrom yyyymmdd}`, GaugeNo, 사번, DeptCode, `{GroupCode}/{Code}`(코드는 계층 경로를 `/`로 이어 리프 키로 쓴다, 예: `DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG`).
- **업무 레코드 번호**: 각 WI의 채번 패턴(예: NCR-{PLANT}-{YYYY}-{SEQ:6})을 따르고 데모 CSV에 값을 넣어 적재한다. ARC-003은 "RecordNo가 이미 있으면 채번하지 않고 카운터를 그 값 이상으로 맞춘다"를 지원해야 한다(데이터 이관과 같은 요구, Vol.0 보강 대상).
- **시나리오 논리 키**: 문서·평가셋·AC는 실제 번호 대신 논리 키(예: `S1-NCR`, `S2-CLAIM`, `S3-4M`)를 쓰고, 실제 번호는 `expected/scenario_keys.json`에서 찾는다.
- **사용자**: 데모 Org 사용자 Username = `{사번 소문자}.{orgAlias}@slqms.demo`, FederationIdentifier = 사번.
- **외부 키가 없는 객체**: WI에 External ID가 없는 객체(CMN_Operation__c, CMN_ItemVehicle__c, Contact, CMN_RoleAssignment__c, 결재선 템플릿·단계, CMN_Delegation__c, CMN_Document__c, 시험 기준·라인, 샘플링 행, 수입검사 기준서·라인, 8D 팀원·액션·제출, QMS_SpcLimit__c, QMS_MsaAppraiser__c, 분석 의뢰 항목 등)는 `ExternalKey__c`(Text(80), External ID, Unique)를 두는 것으로 제안하고 데모 CSV는 그 열로 upsert한다. 데이터 이관에도 같은 키가 필요하므로 각 WI 변경 요청으로 올린다(8절).
- **코드 키**: CMN_Code__c.ExternalKey__c는 계층 경로 전체(`{Group}/{L1}/{L2}/{L3}`)로 통일한다. 같은 그룹 안에서 하위 코드 이름이 겹칠 수 있기 때문이다(예: CHANGE_TYPE의 METHOD/CONDITION과 ENVIRONMENT/CONDITION). Vol.0 MDM-007의 `{GroupCode}/{Code}` 정의를 바꾸는 변경 요청이다.
- **Snowflake 계획 키**: SPC·MSA 테이블의 PLAN_ID·STUDY_ID(Salesforce Id) 옆에 PLAN_NO·STUDY_NO(RecordNo)를 둔다. 데모·테스트 재현과 조인은 번호로 한다(Vol.4 SPC-002, Vol.6b MSA-002 변경 요청).
- **단위 코드**: CMN_KpiValue__c.Unit__c는 Vol.7 KPI 레지스트리 단위 코드(PPM, PCT, CNT, DAYS, MIN 등, 정확한 목록은 Vol.7 KPI 카탈로그)를 쓴다(Vol.0 DWH-003 예시 값 변경 요청).
- **MSA 풀링 기준**: ANOVA 교호작용 풀링 기준 p > 0.25(AIAG)를 데모 기본값으로 쓴다(Vol.6b 설정 기본값 확인 요청).

## 5. 시나리오

### S0 기준정보·이력(AI 사례 코퍼스)

- 기준정보 전체, 공통 코드, 결재 Role 배정(employees.roles), 결재선 템플릿(4M·NCR 통보·특채·8D 종결·PPAP·인정시험), 위임 1건(E1101 → E1102, 2026-12-01~12-05).
- 24개월 이력: NCR 70건(INTERNAL 45, SUPPLIER 25, 종결 62). NCR 대책은 모두 8D 엔진을 쓰므로(Vol.6a NCR-005) NCR마다 8D 1건(SHORT_CAPA 52, FULL_8D 18 — 특별특성·반복·고객 영향 건), 클레임 8D는 FULL_8D. 종결 8D의 확정 원인이 아래 분포를 따른다. 고객 클레임 20건, 4M 12건(종결 10), 인정시험 계획 15건, PPAP 18건, LELE 18건(PUBLISHED), 내부·협력사·고객 심사 8건, 교육 과정 12개·이수 기록, 자격 60건, 측정기 60대·교정 이력, 한도견본 15건, 분석 의뢰 25건.
- **원인 분포(AI 원인 추천 골든의 근거)** — 종결된 NCR·8D의 확정 원인 코드(CAUSE_5M1E 리프)를 아래 분포로 만든다.

| 불량 유형(리프) | 확정 원인 분포 |
| --- | --- |
| SEALING/CONDENSATION/INNER_FOG | MACHINE/DISPENSER_FLOW 4, MATERIAL/VENT_MEMBRANE 3, MATERIAL/HSG_WARP 1, METHOD/CURING_TIME 1 |
| FUNCTION/LIGHTING/DRL_FLICKER | MATERIAL/LED_SOLDER 4, MATERIAL/PIN_DEFORM 2, METHOD/ESD_CONTROL 1 |
| APPEARANCE/HAZE/LENS_HAZE | MATERIAL/RESIN_MOISTURE 3, METHOD/COATING_CURE 2 |
| APPEARANCE/HAZE/COATING_CRACK | METHOD/COATING_CURE 2, ENVIRONMENT/HUMIDITY 1 |
| OPTICAL/AIMING/AIM_OUT | MACHINE/ACT_GEAR 2, MEASUREMENT/GAUGE_DRIFT 2, MATERIAL/HSG_WARP 1 |
| DIMENSION/POSITION/FLATNESS | MATERIAL/HSG_WARP 4 |
| ELECTRICAL/CONNECTOR/PIN_BENT | MATERIAL/PIN_DEFORM 3 |
| APPEARANCE/SCRATCH/LENS_SCRATCH | MAN/STD_NOT_FOLLOWED 3, ENVIRONMENT/DUST 2 |

- **LELE 18건**(제목 요지와 태그, 본문은 생성기가 현상·원인·대책·학습 포인트로 작성):

| 키 | 요지 | 액티비티 유형 | 단계 | 부품군·고객 | 불량 유형 |
| --- | --- | --- | --- | --- | --- |
| LL-001 | 벤트 캡을 물 고임 부위 밖에 배치 | MECH_DESIGN | P1 | HOUSING | INNER_FOG |
| LL-002 | 렌즈 웰드라인을 광학 유효면 밖으로 | MOLD_DESIGN | P2 | LENS | LENS_HAZE |
| LL-003 | 실링 디스펜서 토출량 실시간 감시·비드 폭 SPC | CONTROL_PLAN | P4 | HOUSING·BMW | INNER_FOG |
| LL-004 | 렌즈 레진 건조 수분 0.02% 이하 관리 | CONTROL_PLAN | P4 | LENS | LENS_HAZE |
| LL-005 | 하드코팅 경화로 온도 균일도 검증 | PV_TEST | P4 | LENS | COATING_CRACK |
| LL-006 | LED 모듈 솔더 보이드 X-ray 전수(협력사 요구) | SUPPLIER_PPAP | P4 | LED_MODULE·HKMC | DRL_FLICKER |
| LL-007 | 커넥터 핀 변형 방지 포장 사양 | SUPPLIER_PPAP | P4 | CONNECTOR | PIN_BENT |
| LL-008 | PCB 조립 ESD 관리 구역 | PFMEA | P3 | PCB | LED_OFF |
| LL-009 | 레벨링 액추에이터 기어 내구 DV 조건 강화 | DV_TEST | P3 | ACTUATOR | LEVELING_FAIL |
| LL-010 | 조준 브래킷 강성 해석 | MECH_DESIGN | P1 | HOUSING | AIM_OUT |
| LL-011 | 하우징 실링면 평면도를 SC로 지정 | MECH_DESIGN | P1 | HOUSING | FLATNESS |
| LL-012 | 배광 해석에 렌즈 두께 편차 반영(BMW) | OPT_DESIGN | P1 | LENS·BMW | HV_LOW |
| LL-013 | 열충격 후 코팅 크랙 DV 판정 기준 | DV_TEST | P3 | LENS | COATING_CRACK |
| LL-014 | 금형 이관 초품 전수 검사 | SUPPLIER_PPAP | P4 | 전체 | — |
| LL-015 | EOL 조준 측정기 MSA 반기 실시 | CONTROL_PLAN | P4 | 전체 | AIM_OUT |
| LL-016 | 고습 계절 조립 라인 습도 관리 | CONTROL_PLAN | P5 | 전체 | INNER_FOG |
| LL-017 | 매트릭스 LED 방열판 접촉 설계(BMW) | ELEC_DESIGN | P1 | LED_MODULE·BMW | LED_OFF |
| LL-018 | 과거차 문제 검토 회의 운영 방식 | PAST_ISSUE_REVIEW | P1 | 전체 | — |

### S1 부적합 Full Cycle (PoC 1)

- 2026-11-10부터 KR01 L01 OP20 실링 비드 폭(63117-BE1L C40)이 4.0 → 3.7mm로 서서히 감소(디스펜서 토출량 저하, S7과 같은 SPC 데이터 세트에 포함).
- 2026-11-24 BMW 라인에서 BE1 헤드램프 LH 내부 김서림 3EA 반품 → `S1-NCR`(INTERNAL, SourceType CUSTOMER_RETURN, 63117-BE1L, DEFECT_TYPE SEALING/CONDENSATION/INNER_FOG, 수량 3, 봉쇄: 사내 재고 120EA 선별, 운송 중 40EA).
- 8D `S1-8D`(NCR_INTERNAL, FULL_8D, D3 완료, D4 진행 중) — 기준일 현재 D4 화면에서 AI 원인 추천을 실행하는 상태.
- **AI 원인 추천 기대값**(`expected/ai_rca_S1.json`): 상위 3 = MACHINE/DISPENSER_FLOW(과거 4건 + 맥락 신호: 같은 공정 비드 폭 SPC 하향 신호), MATERIAL/VENT_MEMBRANE(과거 3건), MATERIAL/HSG_WARP(과거 1건 + 맥락 신호: 베타폴리텍 하우징 평면도 수입검사 불합격 S9). 확정 원인 = DISPENSER_FLOW → Top-1 적중.
- 대책(시연 후속): 디스펜서 노즐 교체, 토출량 인터록, 비드 폭 SPC 계획 추가 → 효과 검증(2주 재발 0) → LELE 등록 `S1-LELE`(LL-003 개정판).

### S2 고객 클레임 8D (PoC 2)

- HMC HE1 필드 DRL 점멸 12건(MIS 3 이내) → `S2-CLAIM`(필드, 2026-11-12 접수, HKMC_6PI, D3 1일·8D 14일).
- 반품 분석 `S2-LAB`(분석실: X-ray 솔더 보이드 31%) → 귀책 협력사 감마LED → `S2-NCR`(SUPPLIER) → 협력사 8D `S2-8D`(NCR_SUPPLIER, 포털 제출 D4까지 승인, D5 제출 대기).
- AI 원인 추천 기대값: Top-1 MATERIAL/LED_SOLDER. 8D 초안 기대 요소: D2에 MIS·수량·VIN 해시 수 포함, D5 후보에 LL-006(X-ray 전수) 인용.
- 고객 회신 보고서(6pi 양식) 생성 대상.

### S3 협력사 4M (PoC 3)

- 2026-09-10 알파광학(V10001)이 P-LENS-HE1 원재료를 R-PC-A01 → R-PC-B01(세타소재)로 바꾸는 4M 신청 → `S3-4M`(SUPPLIER, CHANGE_TYPE MATERIAL/RESIN/RESIN_GRADE, 리스크 HIGH, HMC 통보 필요).
- 인정시험 `S3-QUAL`(내광성·열충격·헤이즈 3항목 PASS, 2026-10-30) → PPAP `S3-PPAP`(레벨 3, APPROVED 2026-11-15) → 적용 승인 2026-11-20 → 첫 적용 로트 `S3-IQC-FIRST`(2026-11-25, 성적서 4M 표시, TIGHTENED·전수) → 초기안정화 `S3-STB`(ACTIVE, 최소 90일·10로트, 기준일 현재 2로트).

### S4 VDA 6.3 BMW 공정 심사 대비 (PoC 4)

- BMW 공정 심사 예정 2027-01-20(KR01, BE1 라인) → `S4-AUDIT`(CUSTOMER, 준비 중). 자체 평가 2026-11-25: 요소 P2~P7 질문 부분 집합(질문 번호와 SL 자체 문구만, 원문 질문 저장 안 함), 달성률 84%(B), 변경 관리 질문 1개 4점(4M 적용 시점 증빙 부족).
- 증빙 규칙 실행 결과: 4M 이력(S3 포함), 렌즈 두께 공정능력(S7), 교육·자격, 측정기 교정(S12 영향 포함).
- 직전 BMW 심사(2025-05) 지적 3건(종결 2, 진행 1).

### S5 품질 종합 Dashboard·Q&A (PoC 5)

- 최근 6개월 KPI 값(`salesforce/90_CMN_KpiValue__c.csv`)과 Snowflake MART가 같은 값을 갖는다.
- Q&A 골든 질문과 정답은 AI 시나리오 작업이 `docs/ai/eval/qa_golden.jsonl`로 만든다(예: 최근 6개월 주요 불량 상위 3 = INNER_FOG, DRL_FLICKER, FLATNESS).

### S6 PMS 연계 LELE 추천 (PoC 6)

- PMS 프로젝트(가상) `S6-PRJ` = "BE3 헤드램프 신규 개발", 고객 BMW, 차종 BMW-BE3, 제품군 LAMP_HL. WBS 액티비티 7개(Id는 텍스트): OPT_DESIGN(P1), MECH_DESIGN(P1), ELEC_DESIGN(P1), MOLD_DESIGN(P2), DV_TEST(P3), SUPPLIER_PPAP(P4), PAST_ISSUE_REVIEW(P1).
- 기대값 `expected/lele_S6.json`: Vol.4 LEL-004 규칙 점수로 계산한 액티비티별 추천 목록과 점수(예: OPT_DESIGN → LL-012 최상위, MECH_DESIGN → LL-001·LL-011·LL-010).

### S7 SPC (렌즈 두께)

- 계획: KR01 L02 OP10, S-LENS-BE1 C10, 관리도 X̄-S(부분군 5, 매시 1부분군), 규칙 R1·R2·R3·R5 활성. 1단계 한계 산출 기간 2026-06-01 ~ 2026-07-31(고정, 승인).
- 데이터: 기본 평균 3.000mm, 공정 σ 0.0206mm(Cpk 약 1.62). 2026-11-21부터 평균이 선형 상승해 2026-11-30에 3.040mm(σ 유지). 최근 10일 Cpk 약 1.29(목표 1.33 미달 → 공정능력 미달 알람), 11-30 하루 Cpk 약 0.97. 정확한 값은 생성기가 계산해 기대값 파일에 둔다(명세 수치는 목표 범위).
- 기대 신호: R2(9점 연속 중심선 위) 최초 발생일, R1(UCL 초과) 발생 부분군 목록, 일별·월별 Cp·Cpk·Pp·Ppk → `expected/spc_S7.json`.
- 같은 세트에 S1 실링 비드 폭(KR01 L01 OP20, 63117-BE1L C40, X̄-S n=5)과 S13 조준각(CN01 L01 OP60, 92101-KC1L C20, I-MR)을 포함한다.
- 상수: X̄-S 상수는 c4 닫힌 식(감마 함수)으로, X̄-R 상수 d2·d3는 정규 범위 분포 수치 적분으로 계산해 기대값에 계산 방법과 함께 적는다(표 값을 기억으로 넣지 않는다). 운영 전 Minitab 결과와 대조한다.

### S8 MSA

| 연구 | 측정기 × 특성 | 설계 | 기대 판정 |
| --- | --- | --- | --- |
| S8-MSA1 | GA-KR01-0123 × S-LENS-BE1 C10 | 부품 10 × 평가자 3(E1102, E1103, E1105) × 반복 3, ANOVA | %GRR(연구 변동 대비) 약 12% → 조건부, ndc ≥ 5 |
| S8-MSA2 | GA-KR01-0201 × 63117-BE1L C20 | 부품 10 × 평가자 3 × 반복 2, ANOVA | %GRR 약 6% → 합격 |
| S8-MSA3 | 외관 긁힘(S-LENS-BE1 C40) 계수형 | 부품 30 × 평가자 3 × 반복 2, 기준값 있음 | 평가자 대 기준 kappa 약 0.82 → 합격 |

- ANOVA 교호작용 p > 0.25이면 풀링(AIAG 방식). F 분포 p값은 정규화 불완전 베타 함수로 계산한다. 결과 → `expected/msa_S8.json`.

### S9 수입검사

- 최근 6개월 로트: 공급 품번별 주기적 입고(로트 약 1,500건), 기준서·샘플링(c=0 데모 표)과 성적서.
- 베타폴리텍 P-HSG-BE1(KR01): 2026-10-05·10-19 평면도 0.34mm로 불합격 → 10-19에 강화 전환(최근 5로트 중 2로트).
- 엡실론커넥터 P-CON-01(KR01): 2026-11-03·11-17 성적서 값 배열 동일 → 성적서 이상 R1.
- 감마LED P-LED-HE1: 2026-11-05 성적서 솔더 보이드 27% → OOS_HOLD.
- 알파광학 P-LENS-HE1: S3 첫 적용 로트.
- 기대값 `expected/iqc_S9.json`: 수준 전환 이력, 로트 합격률(QMS_IQC_LAR) 월별·협력사별.

### S10 고객 B2B

- OEM·차종·품번별 월간 0km 불량, 필드 클레임(MIS), 반품 24개월. BMW BE1 0km PPM이 2026-09 ~ 11 상승(INNER_FOG 반품) → 추세 경보. HMC HE1 DRL 점멸이 MIS 3에 몰림(S2).
- 기대값 `expected/b2b_S10.json`: QMS_PPM_CUSTOMER 월별, 경보 규칙 결과.

### S11 조기경보

- 위험 점수 상위: 협력사 베타폴리텍(수입검사 불합격·NCR·등급 C), 라인 KR01 L02(SPC 드리프트), 공정 KR01 L01 OP20(비드 폭 하락 + S1 NCR).
- 기대값 `expected/ew_S11.json`: Vol.8 AIQ-011 가중치로 계산한 상위 10과 주요 요인 코드.

### S12 측정기 교정 불합격

- GA-KR01-0456 2026-11-20 교정 As-found +0.05mm 공차 초과 → 마지막 합격 교정(2025-11-20) 이후 이 측정기로 판정한 수입검사 로트(P-HSG-BE1 홀 위치) 목록 → `expected/gauge_S12.json`.

### S13 EOL·출하

- CN01 KC1 조준 EOL 직행률 2026-11 98.5% → 95.2% 하락, 출하검사 강화 Hold 1건, 조준각 I-MR 신호.

## 6. 기능 개발 사전 적용 규칙

1. **WI 표기**: 각 WI의 수용 기준 바로 앞에 한 줄을 둔다.
   `**데모 데이터**: S7(렌즈 두께 드리프트) — 대표 레코드 S7-PLAN, 기대값 data/demo/expected/spc_S7.json#KR01-L02-OP10-C10`
   해당 시나리오가 없으면 `**데모 데이터**: S0(기준정보만)`으로 쓴다.
2. **AC**: 데모 값을 쓴 AC는 끝에 `(데모 S7)`처럼 표시하고, 숫자 기대값은 기대값 파일 키로 적는다(값을 본문에 다시 쓰지 않아 생성기 변경 시 어긋나지 않게).
3. **Apex 테스트**: Org 데이터에 의존하지 않는다(SeeAllData 금지). `CMN_TestDataFactory`가 정적 리소스 QMS_DemoFixtures(`data/demo/fixtures/demo_fixtures.json`)를 읽어 같은 키·값으로 레코드를 만든다.
4. **LWC Jest**: `data/demo/mocks/apex`, `data/demo/mocks/dwh`의 JSON을 그대로 import해 wire·imperative 호출을 목으로 만든다.
5. **Snowflake·Mule**: `data/demo/snowflake`를 개발 DB에 적재한 뒤, 등록 쿼리 결과가 `mocks/dwh` 응답과 같은지 계약 테스트로 확인한다.
6. **완료 조건 추가**: 기능 WI는 데모 Org·데모 Snowflake에서 해당 시나리오 단계가 재현돼야 완료다(시연 스크립트 단계 번호는 AI 시나리오 가이드와 각 Vol. 데모 표 참조).

## 7. DWH 조회 응답 형식(목·계약 테스트 공용)

DWH-004 `CMN_DwQueryService`(모드 QUERY·PROCEDURE·SEARCH·ANALYST)가 Salesforce 화면에 돌려주는 표준 형식이다. Vol.7 위젯 DTO 공통 필드(asOf, stale, truncated, scopeNote, errorCode)와 같은 이름을 쓴다. 목 파일 `data/demo/mocks/dwh/{QueryKey}/{case}.json`은 이 형식을 그대로 쓴다.

    {
      "queryKey": "QMS_SPC_SUBGROUPS",
      "mode": "QUERY",
      "version": 1,
      "params": {"planId": "...", "from": "2026-11-01T00:00:00Z", "to": "2026-11-30T23:59:59Z"},
      "columns": [{"name": "subgroupTs", "type": "DATETIME", "unit": null}, {"name": "xbar", "type": "NUMBER", "unit": "mm"}],
      "rows": [["2026-11-01T00:00:00Z", 3.0012]],
      "rowCount": 1,
      "truncated": false,
      "asOf": "2026-11-30T23:55:00Z",
      "stale": false,
      "scopeNote": "KR01",
      "generatedAt": "2026-12-01T00:00:03Z",
      "durationMs": 840,
      "calcVersion": null,
      "warnings": [],
      "errorCode": null,
      "errorMessage": null
    }

- rows는 columns 순서의 배열(차트 데이터 크기를 줄이기 위해). type은 STRING, NUMBER, INTEGER, DATE, DATETIME, BOOLEAN, JSON.
- asOf = 원천 데이터 최신 적재 시각(Snowflake 기준), generatedAt = 응답 생성 시각. 날짜·시각은 UTC ISO 8601이고 화면이 사용자·공장 시간대로 바꾼다.
- calcVersion은 PROCEDURE 모드 계산 엔진 버전(예: MSA "msa-anova-1.0").
- errorCode 값: NOT_REGISTERED, PARAM_INVALID, FORBIDDEN_SCOPE, TIMEOUT, CONCURRENCY_LIMIT, SNOWFLAKE_ERROR, UNAVAILABLE. 오류 시 rows는 빈 배열.
- 목 케이스 이름: `ok`(정상), `empty`(0행), `truncated`, `stale`, `error-timeout`, `error-forbidden`.

## 8. 데모 적재에서 나온 WI 변경 요청

데이터를 만들면서 발견한 명세 누락·불일치는 생성기가 `data/demo/wi-change-requests-salesforce.md`, `data/demo/wi-change-requests-snowflake.md`에 표(대상 WI, 내용, 데모에서 쓴 임시 값)로 다시 만든다. 2단계 WI 보강 작업이 이 표를 반영한다.

## 9. 적재 절차

1. `python3 data/demo/generator/generate_all.py [--today 2026-12-01]`
2. Snowflake: `scripts/demo/load_snowflake.sh <connection>` — 스키마는 DWH-001·각 WI의 schemachange 스크립트로 먼저 만든다. 데모 적재는 RAW·CORE·MART에 직접 넣고 Task는 정지 상태로 둔다(재계산 시 기대값과 달라질 수 있음).
3. Salesforce: `scripts/demo/load_salesforce.sh <orgAlias>` — Scratch/Sandbox 검사 → 사용자 생성(users/*.json) → load-plan.json 순서대로 `sf data upsert bulk`.
4. 검증: `python3 data/demo/generator/verify_load.py <orgAlias>`(선택) — 건수·핵심 키 확인.
