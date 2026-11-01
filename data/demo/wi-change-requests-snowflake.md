# Snowflake 데모 데이터 작업에서 나온 WI 변경 요청

데모 데이터(gen_snowflake.py)를 만들면서 찾은 명세 누락·불일치다. 조정자가 data/demo/wi-change-requests.md에 합친다.

| 대상 WI | 내용 | 데모에서 쓴 임시 값 |
| --- | --- | --- |
| QMS-04-SPC-002, QMS-06-MSA-002·003 | CORE.SPC_SUBGROUP·SPC_SIGNAL·SPC_CAPABILITY에 PLAN_NO, CORE.MSA_MEASUREMENT·ML.MSA_RESULT에 STUDY_NO(RecordNo) 열 추가. 데모·테스트 재현과 조인 키 | PLAN_ID·STUDY_ID에 RecordNo를 넣고 Salesforce 적재 후 UPDATE로 Id 치환(load_demo.sql) |
| QMS-04-SPC-001 | QMS_SpcLimit__c.ExternalKey__c(Text(80), External ID, Unique) 추가 | `{PlanNo}-V{Version}` 예: SPC-KR01-00001-V1 |
| QMS-06-MSA-002 | QMS_MsaAppraiser__c.ExternalKey__c 추가 | `{StudyNo}-{Label}` 예: MSA-KR01-2026-00007-A |
| CMN-00-MDM-002 | CMN_Operation__c.ExternalKey__c 추가 | `{PlantCode}-{LineCode}-{OpCode}` 예: KR01-L02-OP10 |
| CMN-00-MDM-007 | CMN_Code__c.ExternalKey__c를 계층 경로 전체로 | `{Group}/{L1}/{L2}/{L3}` 예: DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG, CAUSE_5M1E/MACHINE/DISPENSER_FLOW |
| CMN-00-DWH-003 | CMN_KpiValue__c.Unit__c 예시를 Vol.7 레지스트리 단위 코드로, Vehicle__c 차원 추가(QMS_FIELD_R1000) | Unit = RATIO·CNT·PCT·PPM·R1000, Vehicle__r.ExternalKey__c 열 사용(필드 추가 전에는 적재 시 열 제거) |
| QMS-06-MSA-002·003 | CORE.MSA_MEASUREMENT 열 정의(제안) | STUDY_ID, STUDY_NO, CALC_SEQ, STUDY_TYPE, PLANT_CODE, GAUGE_NO, ITEM_NO, CHAR_NO, PART, APPRAISER, APPRAISER_EMP_NO, TRIAL, VALUE, RESULT, REFERENCE, MEASURED_AT, _LOADED_AT. 키 (STUDY_ID, CALC_SEQ, PART, APPRAISER, TRIAL) |
| QMS-06-MSA-003 | ML.MSA_RESULT 열 정의(제안), ML.MSA_CONSTANT 초기 값 출처 | MSA_RESULT: STUDY_ID, STUDY_NO, CALC_SEQ, CALC_AT, ENGINE_VERSION, RESULT(VARIANT). MSA_CONSTANT K1·K2·K3는 정의식 계산값, VERIFIED_BY 공란(검수 전 XBAR_R 계산 실패가 정상) |
| QMS-06-MSA-004 | 계수형 판정 기준 기본값 | 데모 임시: kappa ≥ 0.75, 유효성 ≥ 80%, 미검출 ≤ 5%, 오검출 ≤ 12.5%(QMS_MsaCriteria__mdt). AIAG 권장 표(유효성 90·미검출 2·오검출 5)를 쓰면 S8-MSA3은 CONDITIONAL |
| QMS-05-B2B-001, QMS-09-INT-014 | STG.CUSTOMER_QUALITY_STD 열 정의(제안) | EVENT_KEY, SOURCE, UPLOAD_ID, CUSTOMER_CODE, DATA_TYPE, CUSTOMER_REF_NO, LINE_NO, EVENT_DATE, VEHICLE_CODE, VIN, CUSTOMER_PART_NO, CUSTOMER_DEFECT_CODE, CUSTOMER_DEFECT_TEXT, QTY, PRODUCTION_MONTH, SALES_MONTH, FAILURE_MONTH, MILEAGE_KM, COST_AMOUNT, COST_CURRENCY, COUNTRY, CUSTOMER_JUDGMENT, _IS_DELETED, LOADED_AT |
| QMS-05-B2B-001 | 출하 공장이 2곳 이상인 품번(BE1L: KR01·PL01)은 BR-3으로 PLANT_CODE가 NULL → 공장별 고객 PPM 불가. SAP 출하 이력(납품처·VIN·로트)으로 공장 추정 규칙 필요 | 데모는 PLANT_CODE NULL, KPI는 고객·품번 단위 |
| QMS-05-B2B-006 | 등록 쿼리 결과 열(제안) | TREND: periodStart, dataType, customerCode, eventCount, qty, denominator, ppm, r1000, target / PARETO: defectTypeCode, defectTypeName, eventCount, qty, pct, cumulativePct / MIS_CURVE: cohortMonth, mis, cumulativeClaims, soldVehicles, cumR1000 |
| QMS-05-CLM-008 | QMS_CLM_SUSPECT_STOCK 결과 열(제안) | locationType(PLANT_STOCK, SERVICE, IN_TRANSIT), plantCode, storageLocation, oemCode, itemNo, batch, stockType, batchProdDate, qty, pgiDate, snapshotTs |
| QMS-04-SPC-003 | S7 데모에서 최근 10일 Cpk 1.30 < 1.33이지만 BR-5는 ROLLING_30D 기준이라 11-30까지 QMS_SPC_CAPABILITY_LOW가 발생하지 않음(11-30 ROLLING_30D Cpk 1.51, expected/spc_S7.json). 데모 시연에 공정능력 미달 알람이 필요하면 판정 창 설정값(예: QMS_SPC_CAPABILITY_WINDOW_DAYS) 추가 | STUDY(11-21~11-30) 행을 SPC_CAPABILITY에 넣어 화면 시연, 알람은 R1·R2 신호 알람으로 시연 |
| QMS-04-SPC-002 | SPC_CONSTANTS에 SOURCE_REF·VERIFIED_BY·VERIFIED_AT 열(검수 추적), D3_CONST(d3) 열 추가 제안 | 데모 값은 정의식 계산값, VERIFIED_BY 공란 |
| QMS-04-EFC-002, QMS-09-INT-011 | CORE.MES_DEFECT.DEFECT_TYPE_CODE 형식 명시(CMN_Code ExternalKey 전체 경로) | DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG 형식, MES_DEFECT_CODE는 MF-* 데모 코드 |
| QMS-03-IQC-007 | CORE.INSPECTION_RESULT에 GAUGE_NO, LOT_NO 열(데모 조인용) | LOT_ID에 RecordNo, LOT_NO 동일 값 |
| QMS-04-SPC-006 | QMS_SPC_PLAN_SUMMARY의 cpk·rag 기준 기간이 ROLLING_30D라 S7(최근 10일 Cpk 1.30)이 GREEN으로 보임. 드리프트 초기 경고가 필요하면 rag 기준 기간 설정 또는 최근 STUDY 값 병기 | 목은 ROLLING_30D 기준(S7 GREEN, 1.51), STUDY 값은 QMS_SPC_CAPABILITY_STUDY 목 |
| QMS-04-SPC-005 | 지속 이동(드리프트·평균 이동) 중 한 알람에 신호가 수백 건 붙으면 SignalsJson__c(Long Text 131072)를 넘음. 상한(예: 최근 500건 + 총 건수) 규칙 필요 | S13 CN01 알람 798건 → 120,000자 이내 앞부분만 저장, SignalCount__c는 전체 건수 |
| QMS-04-EFC-002 | CORE.MES_DEFECT 키 "MES 불량 기록 Id"의 열 이름 미정 | MES_DEFECT_ID = {PLANT}-{MES_LOT_NO}-{MES_DEFECT_CODE} |
| QMS-04-FQC-004 | EOL_TEST_RESULT.TEST_ITEMS 배열 원소 키 이름 미정 | [{code, value, result}], code = AIM_V·LEAK·DRL_I(데모) |
| QMS-05-B2B-006 | TOP_ITEMS·DETAIL·LAST_LOADED 결과 열(제안) | TOP_ITEMS: itemNo, itemName, currentQty, previousQty, changePct / DETAIL: eventDate, customerRefNo, vehicleCode, itemNo, defectTypeCode, customerDefectText, mis, mileageKm, country, costKrw(includeCost=false면 NULL), customerJudgment, claimNo / LAST_LOADED: customerCode, dataType, lastLoadedAt, lastEventDate, rowCount |
| QMS-06-MSA-005 | QMS_MSA_CHART PROCEDURE result 형식(제안) | {engineVersion, studyId, calcSeq, chartType, status, mimeType image/png, width, height, imageBase64, series, categories} |
| QMS-04-EFC-002 | QMS_EFC_DEFECT_PARETO 파라미터(공장·기간)와 이름 열 원천 | plantCodes, fromDate, toDate. defectTypeName = CMN_Code L3 이름(ko) |
| QMS-06-GAU-004 | QMS_GAU_IMPACT_RESULTS 위험 판정식(minMargin 단위·기준) 미정 | minMargin = (측정값 − As-found 오차)에서 규격 한계까지 최소 거리(특성 단위), 음수면 HIGH(Salesforce 데모 gauge_S12.json과 같은 식) |
| 데모 명세 3절·5절 S12 | expected/gauge_S12.json을 Salesforce 생성기와 Snowflake 생성기가 둘 다 산출 대상으로 가짐(소유 중복) | Snowflake 쪽 계산은 expected/gauge_S12_dwh.json(같은 로트 목록을 INSPECTION_RESULT 기준으로 계산), gauge_S12.json은 Salesforce 작업 소유로 둠 |
| 데모 명세 7절 | 응답 형식 예시의 queryKey QMS_SPC_CHART와 열(xbar)이 등록 쿼리(QMS_SPC_SUBGROUPS, mean)와 다름 | 목은 QMS_SPC_SUBGROUPS 사용 |
| QMS-08-AIQ-011 | OPERATION 엔터티 키가 PLANT+LINE+OPERATION_TYPE이라 데모 명세 S11의 "KR01 L01 OP20"은 OP10~OP30(ASSEMBLY)을 묶은 KR01-L01-ASSEMBLY로 집계됨. CORE.SPC_SIGNAL에는 공정 열이 없어 SPC 계획(Operation) 조인 필요. CN01 L01(S13)도 최근 7일 OOC 213건으로 상위 후보 | 원천: 최근 7일 OOC KR01 L02 343, KR01 L01 OP20 280(OOS 1 포함), CN01 L01 OP60 213 |
| CMN-00-DWH-003 | Vol.7 카탈로그 일수 단위는 DAYS(QMS_4M_CYCLE_DAYS 등)인데 데모 명세 4절 예시는 DAY | 데모 KPI에 일수 KPI 없음(해당 없음), 카탈로그 DAYS를 따를 것 |
