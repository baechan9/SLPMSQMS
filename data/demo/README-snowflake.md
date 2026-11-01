# Snowflake 데모 데이터(gen_snowflake.py)

생성: `python3 data/demo/generator/generate_all.py` (Salesforce → Snowflake 순서). Snowflake 부분만: `python3 -c "import sys; sys.path.insert(0,'data/demo/generator'); import common, gen_snowflake; gen_snowflake.generate(common.load_master(), common.Clock())"`

## 시각 규칙

- 모든 TIMESTAMP는 UTC ISO 8601(`2026-11-30T14:55:00Z`)로 저장한다. Snowflake 열 타입은 TIMESTAMP_TZ.
- 생성은 공장 현지 시각으로 하고(공장 시간대 = CMN_Plant__c.TimeZone__c: KR01·KR02 Asia/Seoul, CN01 Asia/Shanghai, US01 America/Chicago, PL01 Europe/Warsaw) UTC로 바꿔 쓴다.
- 날짜 열(PROD_DATE, PERIOD_START, PGI_DATE 등)은 **공장 현지 날짜**다. 화면은 UTC 시각을 사용자 시간대로, 업무 기준일은 공장 시간대로 표시한다(spec-snowflake-display 4.3).
- PERIOD_TYPE DAY·MONTH 공정능력과 KPI의 기간 경계도 공장 현지 날짜 기준이다.

## 키 규칙

- PLAN_ID·STUDY_ID에는 Salesforce Id 대신 데모 번호(RecordNo)가 들어 있다. PLAN_NO·STUDY_NO 열과 같고, Salesforce 적재 후 load_demo.sql 끝의 UPDATE로 Id로 바꾼다.
- MEAS_ID = `{MES 포인트}-{UTC yyyyMMddHHmmss}-{순번}`, SIGNAL_ID = sha1(planNo, rule, chart, subgroupNo) 앞 32자.
- 고객 품질 EVENT_KEY = SHA-256(SOURCE, CUSTOMER_CODE, DATA_TYPE, CUSTOMER_REF_NO, LINE_NO). VIN은 STG에만, CORE는 VIN_HASH.

## 적재

`scripts/demo/load_snowflake.sh <snow 연결> [--with-b2b-core]` — DB가 SL_QDW_DEMO·SL_QDW_DEV가 아니면 중단한다. 테이블은 schemachange로 먼저 만든다.
CORE.CUSTOMER_QUALITY_EVENT는 동적 테이블이므로 기본 적재에서 빠지고, 동적 테이블이 없는 환경만 `--with-b2b-core`로 직접 적재한다.
Salesforce 90번대 CSV(KPI, SPC 계획·한계·알람, MSA 연구·평가자, 고객 결함·품번 매핑)는 `salesforce/load-plan.snowflake.json` 순서로 Salesforce 적재에 합친다.

## 기대값(골든)

| 파일 | 내용 |
| --- | --- |
| expected/spc_S7.json | 계획별(키 KR01-L02-OP10-C10, KR01-L01-OP20-C40, KR01-L01-OP40-C30, CN01-L01-OP60-C20) 1단계 한계·상수·계산 방법, 규칙별 신호 목록, DAY·MONTH·ROLLING_30D·STUDY 공정능력, 드리프트 후 최초 R2·R1 |
| expected/msa_S8.json | S8-MSA1·2(ANOVA 표, 분산 성분, %GRR, ndc, 교호작용 p·풀링, 판정, X̄-R 대조), S8-MSA3(kappa, 유효성, 미검출·오검출, 설계 오류) |
| expected/b2b_S10.json | 고객·품번·월 0km PPM, BMW BE1L PPM, HMC HE1 코호트 MIS 곡선, 데모 경보 규칙 결과 |
| expected/eol_S13.json | CN01 KC1L EOL 월·일 직행률 |
| expected/kpi_S5.csv | 2026-11 MONTH·2026-11-30 DAY KPI 값(대시보드 정답) |
| expected/gauge_S12_dwh.json | (Salesforce 수입검사 CSV가 있을 때) GA-KR01-0456 영향 로트, INSPECTION_RESULT 기준 |
| expected/scenario_keys_snowflake.json | 논리 키 → 레코드 번호(S7-PLAN, S7-ALARM, S8-MSA1~3 등) |

## DWH 응답 목

`mocks/dwh/{QueryKey}/{case}.json`(데모 명세 7절 봉투). ok 케이스 rows는 위 CSV에서 계산한 값과 같다.

- QMS_4M_LOT_TRACE: ok
- QMS_4M_OLD_STOCK: ok
- QMS_B2B_DETAIL: ok
- QMS_B2B_LAST_LOADED: ok
- QMS_B2B_MIS_CURVE: ok
- QMS_B2B_PARETO: ok
- QMS_B2B_TOP_ITEMS: ok
- QMS_B2B_TREND: ok
- QMS_BOM_WHERE_USED: ok
- QMS_CLM_SUSPECT_STOCK: ok
- QMS_DW_FRESHNESS: ok
- QMS_EFC_DEFECT_PARETO: ok
- QMS_FQC_EOL_SUMMARY: ok
- QMS_GAU_IMPACT_RESULTS: ok
- QMS_IQC_LOT_DETAIL: empty, ok
- QMS_MSA_CALC: error-timeout, failed-constant, ok-msa1, ok-msa2, ok-msa3
- QMS_MSA_CHART: ok-components
- QMS_MSA_GAUGE_USAGE: ok
- QMS_NCR_PARETO: ok
- QMS_NCR_TREND: ok
- QMS_SPC_CAPABILITY_SERIES: ok
- QMS_SPC_CAPABILITY_STUDY: empty, ok
- QMS_SPC_HISTOGRAM: ok
- QMS_SPC_LIMITS: ok
- QMS_SPC_LIMIT_PREVIEW: ok
- QMS_SPC_MSA_STATUS: empty, ok
- QMS_SPC_PLAN_SUMMARY: ok
- QMS_SPC_SIGNALS: ok
- QMS_SPC_SPEC: ok
- QMS_SPC_SUBGROUPS: empty, error-timeout, ok, stale, truncated

## 파생 데이터(Salesforce CSV 필요)

`salesforce/*QMS_IqcLot__c*.csv`·`*QMS_IqcResult__c*.csv`·`*QMS_NCR__c*.csv`·`*QMS_FourMChange__c*.csv`가 있으면 CORE.INSPECTION_RESULT·NCR_DEFECT·FOURM_CHANGE, IQC·NCR·4M KPI, 목 QMS_GAU_IMPACT_RESULTS·QMS_IQC_LOT_DETAIL·QMS_MSA_GAUGE_USAGE·QMS_NCR_PARETO·QMS_NCR_TREND를 만든다. 없으면 협력사 로트를 `{VendorNo}-{yyMMdd}-A` 패턴으로 합성한다. Salesforce 생성 후 `generate_all.py`를 다시 실행하면 된다.

## 행 수

| 파일 | 행 |
| --- | --- |
| CORE.CUSTOMER_QUALITY_EVENT | 620 |
| CORE.CUSTOMER_VOLUME | 384 |
| CORE.EOL_TEST_RESULT | 8041 |
| CORE.FOURM_CHANGE | 12 |
| CORE.INSPECTION_RESULT | 100040 |
| CORE.LOT_TRACE | 336 |
| CORE.MES_DEFECT | 5029 |
| CORE.MES_PRODUCTION | 9233 |
| CORE.MSA_MEASUREMENT | 330 |
| CORE.NCR_DEFECT | 70 |
| CORE.SAP_BATCH | 1359 |
| CORE.SAP_BOM | 45 |
| CORE.SAP_FX_RATE | 96 |
| CORE.SAP_MATERIAL_PRICE | 38 |
| CORE.SAP_SHIPMENT | 2507 |
| CORE.SAP_STOCK | 58 |
| CORE.SPC_CAPABILITY | 1075 |
| CORE.SPC_CONSTANTS | 24 |
| CORE.SPC_MEASUREMENT | 49592 |
| CORE.SPC_RULE_DEF | 8 |
| CORE.SPC_SIGNAL | 1878 |
| CORE.SPC_SUBGROUP | 11928 |
| MART.DATA_FRESHNESS | 13 |
| ML.MSA_CONSTANT | 18 |
| ML.MSA_RESULT | 3 |
| STG.CUSTOMER_QUALITY_STD | 620 |
| expected/kpi_S5.csv | 99 |
| salesforce/90_CMN_KpiValue__c | 2162 |
| salesforce/91_QMS_SpcPlan__c | 5 |
| salesforce/92_QMS_SpcLimit__c | 5 |
| salesforce/92u_QMS_SpcPlan__c | 5 |
| salesforce/93_QMS_SpcAlarm__c | 92 |
| salesforce/94_QMS_MsaStudy__c | 3 |
| salesforce/95_QMS_MsaAppraiser__c | 9 |
| salesforce/96_QMS_CustomerDefectMap__c | 17 |
| salesforce/97_QMS_CustomerPartMap__c | 11 |
