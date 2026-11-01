# Snowflake 결과 연계 표시 설계 기준

이 문서는 Snowflake에서 계산·보관하는 결과(SPC 관리도, 공정능력, MSA, 수입검사·출하검사 실적, 고객 B2B, 협력사 스코어카드, 조기경보, AI 검색·분석)를 Salesforce 화면에 보여주는 모든 WI가 따르는 공통 설계다. 각 WI 본문이 이 문서와 다르면 이 문서를 기준으로 WI를 고친다(12절 보강 지시). 이름·소유는 `interfaces.md`, 응답 형식은 `docs/40-demo/demo-data-spec.md` 7절이 원천이다.

## 0. 적용 범위와 용어

| 용어 | 뜻 |
| --- | --- |
| 등록 쿼리 | CMN_DwQuery__mdt 1행. 화면은 QueryKey와 파라미터만 보내고 SQL은 메타데이터에만 있다 |
| 응답 봉투 | demo-data-spec 7절의 JSON 형식. Apex DTO 이름은 CMN_DwQueryResult |
| 대화형 호출 | 사용자가 화면에서 기다리는 호출(LWC → Apex → Mule → Snowflake) |
| 결과 반영 | Snowflake가 계산한 결과를 Salesforce 레코드로 만드는 것(DWH-003 인바운드 이벤트) |
| 신선도(asOf) | 응답에 쓰인 원천 데이터의 최신 적재 시각 |
| 골든 | data/demo/expected의 기대값 파일. 같은 알고리즘의 데모 재현 기준 |

## 1. 데이터 경로 패턴과 선택 기준

| 패턴 | 경로 | 지연(데이터 → 화면) | 신선도 표시 | Snowflake 비용 | 권한 강제 위치 | 적합한 화면 |
| --- | --- | --- | --- | --- | --- | --- |
| P1 KPI 적재 | Snowflake MART 뷰 → Mule(일 1~24회) → CMN_KpiValue__c(DWH-003) → SOQL | 1시간~1일 | asOf = KpiValue 적재 시각, 레지스트리 FreshnessHours | 적재 시 1회 | Apex(QMS_WidgetDataService 공장 필터) | 대시보드 타일·추세, 목록의 실적 배지, 포털 요약 |
| P2 등록 쿼리 | LWC → Apex CMN_DwQueryService.query → Named Credential → Mule prc-dw-query-api → Snowflake SQL API | 원천 적재 지연 + 1~3초 | asOf = MART.DATA_FRESHNESS | 호출마다(캐시로 절감) | Apex 파라미터 주입 + SqlTemplate 필수 조건 + (W2) 행 접근 정책 | 관리도·히스토그램·파레토·건별 상세·드릴다운 |
| P3 프로시저 계산 | Apex Queueable → Mule /procedures → CALL 프로시저 → 결과 Apex 저장 → 플랫폼 이벤트로 화면 갱신 | 5~60초(비동기) | calcVersion·계산 시각 | 호출마다(WH_ML) | Apex 파라미터 + 프로시저 인자 검증 | MSA 계산, 한계 미리보기처럼 무거운 계산, 차트 이미지 생성 |
| P4 결과 반영 | Snowflake Task → SHARE.OUTBOUND_EVENT → Mule 1분 폴링 → CMN_ResultInbound__e → 핸들러 → Salesforce 레코드 | 1~10분 | 레코드 생성 시각·이벤트 ExternalEventId | 판정 시 1회 | 레코드 공유 모델(SharingConfig) | 알람·경보(업무를 시작시키는 결과), 계획 실적 필드, 스코어카드·한계 산출 |
| P5 AI 검색·분석 | Apex → Mule prc-ai-snowflake-api(SEARCH·ANALYST) → Cortex Search·Analyst | 1~30초 | 검색 색인 시각·시맨틱 모델 버전 | 호출마다(Cortex) | Apex 파라미터 + 세션 범위 테이블·행 접근 정책(AIQ-010) | 유사 사례 검색, 자연어 Q&A |

**선택 규칙**

1. 숫자 하나·추세를 여러 사람이 매일 보는 화면 → P1. 같은 값을 P2로 매번 조회하지 않는다.
2. 사용자가 고른 기간·대상의 상세(점·행)가 필요한 화면 → P2. 결과를 Salesforce에 저장하지 않는다.
3. 계산이 5초를 넘거나 계산 결과를 기록으로 남겨야 하면 → P3. 결과는 업무 레코드 필드와 Snowflake 이력 테이블 두 곳에 남긴다.
4. 결과가 사람에게 일을 시키면(알람·경보·To-Do) → P4. 화면이 Snowflake를 다시 조회해 판정하지 않는다.
5. 자연어·의미 검색 → P5. 등록 쿼리로 흉내 내지 않는다.

**금지**: 측정값·시료값을 Salesforce 레코드로 복사(P1~P5 어디서도), LWC·Apex에서 통계 재계산, 화면에서 자유 SQL·임의 테이블명 전달, Snowflake 직접 접속(JDBC·Snowflake 커넥터)을 Salesforce에서 사용, 위젯별 개별 Apex 콜아웃 클래스.

## 2. DWH-004 표준

### 2.1 CMN_DwQuery__mdt 필드 표준

현재 DWH-004 정의(QueryKey, SqlTemplate, AllowedParams, MaxRows)에 아래 필드를 더한다(Vol.0 변경).

| 필드 | 타입 | 필수 | 규칙 |
| --- | --- | --- | --- |
| DeveloperName(QueryKey) | — | Y | `{접두어}_{영역}_{대상}` 대문자, 40자 이하. 예: QMS_SPC_SUBGROUPS |
| Mode__c | Picklist (QUERY, PROCEDURE, SEARCH, ANALYST) | Y | INT-020 모드 표와 같다 |
| SqlTemplate__c | Long Text(32768) | Y | 2.2 작성 규칙. PROCEDURE는 `CALL ML.SP_x(:p1, :p2)` 한 문장 |
| AllowedParams__c | Long Text(4000) | Y | JSON 배열 `[{"name":"planId","type":"ID","required":true},{"name":"from","type":"DATETIME","required":true},{"name":"limit","type":"INTEGER","max":1000}]`. type = STRING, INTEGER, NUMBER, DATE, DATETIME, BOOLEAN, ID, STRING_LIST, ID_LIST. 목록 타입은 최대 200개 |
| PlantParam__c | Text(40) | N | Apex가 사용자 공장 범위(공장 코드 목록)를 강제로 넣을 파라미터명. 값이 있으면 SqlTemplate에 그 파라미터를 쓰는 조건이 반드시 있어야 한다(배포 테스트) |
| SupplierParam__c | Text(40) | N | 포털 호출 시 협력사 코드(SapVendorNo)를 강제로 넣을 파라미터명 |
| PortalAllowed__c | Checkbox | Y | 포털 사용자 호출 허용 |
| RequiredPermission__c | Text(80) | N | Custom Permission API명(예: QMS_ViewCost). 없으면 FORBIDDEN_SCOPE |
| MaxRows__c | Number(6,0) | Y | 기본 5,000. 2.4의 응답 크기 1MB 안에 들어가야 한다(MaxRows × 행 예상 바이트 ≤ 900KB) |
| OrderByRequired__c | Checkbox | Y | 기본 true. SqlTemplate에 ORDER BY가 없으면 배포 테스트 실패 |
| LatencyClass__c | Picklist (FAST, SLOW, ASYNC) | Y | FAST: p95 3초 이하, 일반 콜아웃. SLOW: p95 20초 이하, Continuation. ASYNC: Queueable + 결과 이벤트(PROCEDURE 기본) |
| CacheSeconds__c | Number(5,0) | Y | 0 = 캐시 안 함. 기본 QUERY 600, PROCEDURE·ANALYST 0, SEARCH 300 |
| Warehouse__c | Text(40) | N | 공란이면 모드 기본(QUERY WH_BI, PROCEDURE WH_ML) |
| FreshnessKey__c | Text(80) | N | MART.DATA_FRESHNESS의 SOURCE_KEY(쉼표로 여러 개면 가장 오래된 값을 asOf로) |
| StaleAfterMinutes__c | Number(6,0) | N | asOf가 이 분보다 오래되면 stale = true. 공란이면 원천 예상 주기 × 2 |
| ResultColumns__c | Long Text(8000) | Y(QUERY) | 결과 열 계약 JSON `[{"name":"subgroupNo","type":"INTEGER","nullable":false,"unit":null}]`. 이름·순서·타입은 SqlTemplate의 SELECT 별칭과 같아야 한다(계약 테스트) |
| Version__c | Number(3,0) | Y | 결과 열 계약을 바꾸면 +1. 응답 version에 실린다. 열 삭제·이름 변경은 소비 WI(Vol.7 위젯 등)를 같은 배포에서 함께 고친다 |
| OwnerWi__c | Text(40) | Y | 정의 소유 WI ID(예: QMS-04-SPC-006). 변경 영향 추적용 |
| MockCases__c | Text(255) | N | 목 파일 케이스 목록(예: ok,empty,truncated,error-timeout). data/demo/mocks/dwh/{QueryKey}/{case}.json이 있어야 한다 |

### 2.2 SqlTemplate 작성 규칙

1. 파라미터는 `:이름` 바인드 토큰으로만 쓴다. Mule이 Snowflake SQL API bindings로 넘기며 문자열 결합을 하지 않는다. 목록 파라미터는 `IN (SELECT VALUE::STRING FROM TABLE(FLATTEN(INPUT => PARSE_JSON(:plantCodes))))` 형태로 쓴다.
2. PlantParam이 있으면 공장 조건을 SqlTemplate 본문에 직접 쓴다(Apex가 값을 강제로 채움). 공장 컬럼이 NULL일 수 있는 데이터는 NULL 행 처리 규칙을 WI에 명시한다(예: B2B-006 BR-5).
3. 결과는 MART 뷰나 CORE 보안 뷰(SECURE VIEW)만 읽는다. RAW·STG를 읽지 않는다. 역할 ROLE_SF_READER는 이 둘에만 SELECT 권한을 갖는다.
4. ORDER BY와 `LIMIT :__limit`을 반드시 쓴다. `__limit`은 Mule이 MaxRows + 1로 채워 잘림(truncated)을 판단한다(사용자가 줄 수 없음).
5. SELECT 열 별칭은 ResultColumns의 name과 같은 camelCase로 쓴다(따옴표로 대소문자 보존). 시각 열은 `CONVERT_TIMEZONE('UTC', 열)`로 UTC로 낸다. 날짜(생산일 등 공장 현지 날짜)는 DATE 그대로 낸다.
6. 숫자는 계산 정밀도를 유지하고 반올림은 화면에서 한다. 통계 값은 NUMBER(18,6) 이상.
7. 템플릿 안에서 CURRENT_DATE·CURRENT_TIMESTAMP를 쓰지 않는다(재현성). 기준일이 필요하면 `:asOfDate` 파라미터를 받는다.

예: QMS_SPC_SUBGROUPS

    SELECT g.SUBGROUP_NO                         AS "subgroupNo",
           CONVERT_TIMEZONE('UTC', g.SUBGROUP_TS) AS "subgroupTs",
           g.N                                   AS "n",
           g.MEAN                                AS "mean",
           g.RANGE_VAL                           AS "rangeVal",
           g.STDDEV_VAL                          AS "stddevVal",
           g.MR_VAL                              AS "mrVal",
           g.LIMIT_VERSION                       AS "limitVersion",
           g.EXCLUDED                            AS "excluded",
           g.HAS_OOS                             AS "hasOos"
      FROM CORE.V_SPC_SUBGROUP_SECURE g
     WHERE g.PLAN_ID = :planId
       AND g.PLANT_CODE IN (SELECT VALUE::STRING FROM TABLE(FLATTEN(INPUT => PARSE_JSON(:plantCodes))))
       AND g.SUBGROUP_TS >= :fromTs AND g.SUBGROUP_TS < :toTs
     ORDER BY g.SUBGROUP_NO DESC
     LIMIT :__limit

### 2.3 Apex API

    public with sharing class CMN_DwQueryService {
        // 대화형 FAST: 일반 콜아웃(타임아웃 10초). 캐시 적중이면 콜아웃 없음
        public static CMN_DwQueryResult query(String queryKey, Map<String, Object> params);
        // 대화형 SLOW: Continuation. LWC는 @AuraEnabled(continuation=true cacheable=false) 메서드에서 호출
        public static Object startQuery(String queryKey, Map<String, Object> params, String callbackMethod);
        public static CMN_DwQueryResult finishQuery(Object state);   // Continuation 콜백에서 호출
        // ASYNC(PROCEDURE): Queueable에서만 호출. 화면 갱신은 업무 WI의 결과 이벤트로
        public static CMN_DwQueryResult callProcedure(String queryKey, Map<String, Object> params);
        // SEARCH·ANALYST: Vol.8 AIQ-002·010이 같은 봉투로 감싼다
        public static CMN_DwQueryResult search(String aliasKey, Map<String, Object> params);
        public static CMN_DwQueryResult analyst(String aliasKey, Map<String, Object> params);
        // 등록 확인(LWC 진입 시 권한 없는 영역을 숨기는 용도)
        public static Boolean canRun(String queryKey);
    }

    public class CMN_DwQueryResult {
        @AuraEnabled public String queryKey;  @AuraEnabled public String mode;
        @AuraEnabled public Integer version;  @AuraEnabled public Map<String, Object> params;
        @AuraEnabled public List<CMN_DwColumn> columns;   // name, type, unit, nullable
        @AuraEnabled public List<List<Object>> rows;
        @AuraEnabled public Integer rowCount; @AuraEnabled public Boolean truncated;
        @AuraEnabled public Datetime asOf;    @AuraEnabled public Boolean stale;
        @AuraEnabled public String scopeNote; @AuraEnabled public Datetime generatedAt;
        @AuraEnabled public Integer durationMs; @AuraEnabled public String calcVersion;
        @AuraEnabled public List<String> warnings;
        @AuraEnabled public String errorCode; @AuraEnabled public String errorMessage;
        // 추가 필드(봉투 확장, 이름 변경 없음)
        @AuraEnabled public Object result;     // PROCEDURE·ANALYST 원본 JSON(행 형태가 아닌 결과)
        @AuraEnabled public Boolean cacheHit;  // 캐시 적중 여부
        @AuraEnabled public String requestId;  // Mule x-correlation-id(로그 대조)
        public List<Map<String, Object>> toMaps(); // 서버 측 소비자 편의(행 → 열 이름 맵)
    }

처리 순서(query·startQuery 공통):

1. 메타데이터 조회(없으면 errorCode NOT_REGISTERED, 예외 아님 — 화면이 오류 상태를 그림). Mode가 맞지 않으면 NOT_REGISTERED.
2. RequiredPermission 검사(FeatureManagement.checkPermission), 포털 사용자면 PortalAllowed 검사 → FORBIDDEN_SCOPE.
3. AllowedParams 검사: 이름·타입·필수·목록 크기·INTEGER max. 위반이면 PARAM_INVALID(외부 호출 없음).
4. 범위 주입: PlantParam이 있으면 `CMN_DwScope.plantCodes()`(CMN_UserPlantAccess__c + PrimaryPlant, View All 권한자는 전 공장) ∩ 사용자가 준 값. 교집합이 비면 콜아웃 없이 0행 + scopeNote "권한 없는 공장 제외". SupplierParam이 있고 포털 사용자면 자기 협력사 코드로 덮어쓴다.
5. 캐시 조회(3.3). 적중이면 cacheHit = true로 반환.
6. 콜아웃: Named Credential `CMN_Mule_DW`, 헤더 `x-correlation-id`(UUID), `x-timeout-ms`(FAST 8000, SLOW 15000, ASYNC 55000), `x-requested-by`(사번). Apex 타임아웃은 FAST 10초, SLOW 20초(Continuation 최대 120초 안), ASYNC 60초.
7. 응답 파싱 → asOf·stale 계산(StaleAfterMinutes) → 캐시 저장(오류·stale 응답은 저장하지 않음) → 반환.
8. 로그: CMN_Logger DEBUG(queryKey, durationMs, rowCount, cacheHit, requestId). 파라미터 값은 남기지 않는다(5절).

LWC 쪽 호출 규칙: FAST 쿼리는 `@AuraEnabled(cacheable=true)` 래퍼 메서드로 wire 또는 imperative 호출, SLOW는 `@AuraEnabled(continuation=true)` 래퍼로 imperative 호출, ASYNC는 계산 요청 메서드만 호출하고 결과는 lightning/empApi 구독(구독 실패 시 5초 간격 폴링, 최대 90초).

### 2.4 Mule 계약(prc-dw-query-api, INT-020 확장)

    POST /prc-dw-query-api/v1/queries/{queryKey}
    헤더: x-correlation-id, x-timeout-ms, x-requested-by, x-plant-scope(Apex가 넣은 공장 목록, 행 접근 정책용)
    요청: {"params": {"planId": "a1B...", "plantCodes": ["KR01"], "fromTs": "...", "toTs": "..."}}
    응답 200: demo-data-spec 7절 봉투(errorCode null)
    응답 4xx·5xx: {"status": "ERROR", "errorCode": "TIMEOUT", "message": "...", "requestId": "..."}

| 항목 | 규칙 |
| --- | --- |
| 실행 | Snowflake SQL API v2, Key-pair 인증, 역할·웨어하우스는 INT-020 표. QUERY_TAG = `{queryKey}:{requestId}`(비용 추적) |
| 열 메타데이터 | resultSetMetaData.rowType로 columns를 만든다. 타입 변환: FIXED scale 0 → INTEGER, FIXED scale > 0·REAL → NUMBER, TEXT → STRING, DATE → DATE, TIMESTAMP_* → DATETIME(UTC ISO 8601, 밀리초), BOOLEAN → BOOLEAN, VARIANT·OBJECT·ARRAY → JSON. unit은 ResultColumns 계약에서 채운다 |
| 숫자 | SQL API가 문자열로 주는 숫자는 JSON 숫자로 바꾼다. 유효 숫자 15자리를 넘는 값은 문자열로 두고 warnings에 NUMBER_PRECISION을 넣는다 |
| 파티션 | 결과가 여러 파티션이면 MaxRows + 1행에 도달할 때까지 이어 받는다. MaxRows 초과면 MaxRows까지 자르고 truncated = true |
| 크기 | 응답 본문 1MB 초과면 502가 아니라 200 + truncated = true + warnings RESPONSE_SIZE로 자른다(행 단위로 자름) |
| 신선도 | FreshnessKey가 있으면 같은 세션에서 `SELECT MIN(LAST_LOADED_AT) FROM MART.DATA_FRESHNESS WHERE SOURCE_KEY IN (...)`(60초 캐시)로 asOf를 채운다. 없으면 asOf = generatedAt |
| HTTP → errorCode | 404 NOT_REGISTERED, 400 PARAM_INVALID, 403 FORBIDDEN_SCOPE, 429 CONCURRENCY_LIMIT, 504 TIMEOUT, 502 SNOWFLAKE_ERROR, 연결 실패·5xx 기타 UNAVAILABLE(Apex가 판단) |
| PROCEDURE | INT-020 응답 `{status, durationMs, result}`를 같은 봉투로 바꾼다: columns·rows = [], result = 프로시저 VARIANT, calcVersion = result.engineVersion |

### 2.5 데이터 신선도

`MART.DATA_FRESHNESS`(SOURCE_KEY, LAST_LOADED_AT TIMESTAMP_TZ, EXPECTED_INTERVAL_MIN, UPDATED_BY_TASK)를 DWH-001에 둔다. 모든 적재 Task(INT-008·010·011·014, DWH-002 복제, 각 WI의 MERGE Task)는 끝날 때 자기 SOURCE_KEY 행을 MERGE한다. 키 예: MES_SPC(CORE.SPC_MEASUREMENT), SPC_SUBGROUP, SPC_CAPABILITY, MES_PRODUCTION, EOL, IQC_RESULT, CUSTOMER_QUALITY, SF_REPLICA_15MIN, SF_REPLICA_DAILY, MSA_RESULT, RISK_SCORE.

화면은 asOf를 그대로 보여주고(4절 상태 표준의 "기준 시각"), stale이면 노란 배지 "데이터 지연"과 툴팁(예상 주기, 마지막 적재 시각)을 붙인다. stale 판단 기본값: StaleAfterMinutes 공란이면 EXPECTED_INTERVAL_MIN × 2.

### 2.6 오류 코드별 처리

| errorCode | 원인 | Apex 처리 | 화면(Custom Label) | 재시도 | 로그 |
| --- | --- | --- | --- | --- | --- |
| NOT_REGISTERED | 키 없음·모드 불일치 | 콜아웃 없음 | CMN_Dw_Err_NotRegistered "이 화면 설정이 등록되지 않았습니다(관리자 문의)" | 없음 | ERROR(배포 오류) |
| PARAM_INVALID | 파라미터 타입·필수·크기 위반 | 콜아웃 없음 | CMN_Dw_Err_Param "조회 조건을 확인하세요" | 조건 변경 후 | WARN |
| FORBIDDEN_SCOPE | 권한·포털 비허용 | 콜아웃 없음 | CMN_Dw_Err_Forbidden "조회 권한이 없습니다" | 없음 | INFO |
| TIMEOUT | Snowflake·Mule 시간 초과 | 캐시 저장 안 함 | CMN_Dw_Err_Timeout "조회 시간이 길어 중단했습니다. 기간을 줄이세요" | 수동 1회 | WARN |
| CONCURRENCY_LIMIT | Mule 세마포어 초과 | 캐시 저장 안 함 | CMN_Dw_Err_Busy "요청이 많습니다. 잠시 후 다시 시도하세요" | 5초 후 자동 1회 | INFO |
| SNOWFLAKE_ERROR | SQL 오류·권한 오류 | 캐시 저장 안 함 | CMN_Dw_Err_Source "데이터 원천 오류(요청 번호 {requestId})" | 수동 | ERROR |
| UNAVAILABLE | Mule·네트워크 장애 | 캐시 저장 안 함 | CMN_Dw_Err_Unavailable "분석 데이터 서비스에 연결할 수 없습니다" | 수동 | ERROR |

화면의 다른 영역(Salesforce 레코드 데이터)은 오류와 관계없이 정상 표시한다. 한 화면에 쿼리가 여러 개면 영역마다 따로 오류를 그린다(B2B-006 AC-6과 같은 원칙).

## 3. 성능·거버너

### 3.1 응답 시간 예산(p95, 캐시 미스)

| 구간 | FAST | SLOW | 비고 |
| --- | --- | --- | --- |
| Snowflake 실행 | 1.5초 | 12초 | WH_BI 웜 상태 기준. 콜드 스타트는 AUTO_RESUME 2초 추가(업무 시간 WH_BI 최소 클러스터 유지 검토) |
| Mule 처리·전송 | 0.5초 | 1.5초 | 파티션 병합·변환 포함 |
| Apex 처리 | 0.3초 | 0.5초 | 파싱·캐시 |
| LWC 렌더링 | 0.7초 | 1초 | Chart.js 1,000점 기준 |
| 합계 | 3초 | 15초 | NFR-4.1 3초는 FAST 화면에 적용. SLOW 화면은 진행 표시를 반드시 보여준다 |

### 3.2 동기·Continuation·비동기 선택

- Salesforce는 5초 넘게 걸리는 동기 요청이 Org 전체에서 동시에 10개를 넘으면 이후 요청을 거부한다(동시 장기 실행 요청 한도). 그래서 p95가 3초를 넘을 수 있는 대화형 쿼리는 LatencyClass SLOW로 두고 Continuation으로 호출한다. Continuation 대기 시간은 이 한도에 세지 않는다.
- PROCEDURE(MSA 계산 등)는 Continuation을 쓰지 않고 ASYNC(Queueable + 결과 이벤트)로 한다. 계산 결과를 레코드에 저장해야 하고 60초까지 걸릴 수 있기 때문이다.
- Continuation 1회에 콜아웃은 1개만 묶는다(쿼리별 오류를 분리하기 위해). 한 화면이 쿼리 4개를 SLOW로 부르면 LWC가 4번 호출한다.
- Apex 트리거·배치에서 DWH 쿼리를 부르지 않는다(Queueable 또는 Schedulable에서만, 콜아웃 한도 100회/트랜잭션).

### 3.3 Platform Cache

- 파티션 `CMNDw`(Org 캐시, 최소 2MB, DSH-002의 QMSDashboard와 별도).
- 키 = `dw` + SHA-1(queryKey + Version + 정렬된 파라미터 JSON + 범위 공장 목록 정렬 문자열 + 포털 협력사 코드). 사용자 Id는 넣지 않는다(같은 범위 사용자끼리 공유).
- TTL = CacheSeconds(최대 3,600). 값 크기 100KB 초과 결과는 캐시하지 않는다(Org 캐시 항목 상한 대비).
- 무효화: DWH-003 KPI 적재 완료 이벤트 CMN_KpiLoaded__e를 받으면 `kpi:` 캐시만 비운다(DSH-002). 등록 쿼리 캐시는 TTL로만 만료한다. 데이터가 바뀌는 즉시 보여야 하는 쿼리(예: 알람 화면의 신호)는 CacheSeconds 0 또는 60 이하로 둔다.
- 캐시 계층은 하나다: 등록 쿼리 캐시는 CMN_DwQueryService만 갖는다. QMS_WidgetDataService.runQuery는 결과를 다시 캐시하지 않는다(QMS_WidgetQuery__mdt.CacheSeconds는 0으로 고정하거나 필드를 없앤다 — Vol.7 보강).

### 3.4 크기 한도

| 한도 | 값 | 설계 규칙 |
| --- | --- | --- |
| Mule QUERY·PROCEDURE 응답 | 1MB(INT-020 BR-2) | MaxRows × 행 바이트 ≤ 900KB로 MaxRows를 정한다. SPC 부분군 1행 약 160바이트 → 1,000행 160KB |
| Apex 콜아웃 응답·힙 | 동기 6MB, 비동기 12MB | 1MB 응답 기준 여유 충분. PROCEDURE 결과에 이미지(base64)를 넣지 않는다(8절 MSA 차트) |
| 플랫폼 이벤트 PayloadJson__c | 131,072자 | P4 이벤트는 대상 200개 단위로 쪼갠다(7절) |
| LWC 차트 점 | 일반 위젯 500점(DSH-003 BR-5 균등 추출), SPC 관리도 1,000점(추출 금지) | 3.5 |

### 3.5 차트 점 수·다운샘플링

- 일반 추세 차트(위젯): 500점 초과면 DSH-003 BR-5대로 균등 추출해 그린다(툴팁에 "표시 점 n/N").
- **SPC 관리도는 추출하지 않는다.** 추출하면 신호 점이 사라질 수 있기 때문이다. 기본 보기는 최근 125부분군이고, ◀ ▶로 125개씩 이전·다음 구간을 조회한다(쿼리 파라미터 beforeSubgroupNo, limit 125). 기간 보기(7·30·90일)는 최대 1,000부분군까지 한 번에 그리고, 넘으면 최근 1,000개 + "기간을 줄이세요" 안내.
- 히스토그램은 Snowflake에서 구간 도수로 받아 그린다(원값을 받지 않음).
- 건별 목록은 최대 MaxRows까지 받고 화면은 50행 페이지로 나눈다(서버 재조회 없음).

### 3.6 동시 실행

- Mule 세마포어: QUERY 키별 20, PROCEDURE 키별 5(INT-020). 같은 화면이 같은 쿼리를 동시에 여러 번 부르지 않도록 LWC는 진행 중 요청이 있으면 새 요청을 디바운스(300ms)하고 이전 응답을 버린다(요청 순번 비교).
- Snowflake: WH_BI MAX_CONCURRENCY_LEVEL 기본(8), 멀티 클러스터(최대 2)는 운영 데이터로 결정(결정 SNOW-4).

## 4. 화면 상태 표준

### 4.1 공통 LWC 유틸 `cmnDwDataState`(Vol.0 DWH-004가 소유하는 LWC 모듈)

    // 상태 계산
    export function stateOf(result, { loading }) → 'LOADING' | 'ERROR' | 'EMPTY' | 'READY'
    // 표시 메타
    export function badgesOf(result) → [{type:'STALE'|'TRUNCATED'|'SCOPE'|'CACHE', labelKey, tooltip}]
    // 열 접근
    export function toObjects(result) → Array<Object>   // columns 이름으로 행을 객체로
    // 시각 표시
    export function formatTs(isoUtc, { mode: 'PLANT'|'USER', plantTimeZone, locale }) → string
    // 오류 메시지
    export function errorLabel(errorCode) → Custom Label 값

컴포넌트 `cmnDwStateFrame`(슬롯 래퍼): 자식 차트·표를 감싸 상태별 화면을 그린다. 모든 P2·P3·P5 화면 영역은 이 프레임을 쓴다.

| 상태 | 표시 |
| --- | --- |
| LOADING | 영역 크기를 유지한 스켈레톤(lightning-spinner 대신), SLOW 쿼리는 1초 뒤부터 "조회 중… (평균 n초)" 문구 |
| EMPTY | "조건에 맞는 데이터가 없습니다" + 현재 조건 요약 + 조건 변경 버튼 |
| ERROR | 2.6 라벨 메시지 + 재시도 버튼(TIMEOUT·SNOWFLAKE_ERROR·UNAVAILABLE) + 요청 번호(requestId) 복사 링크 |
| READY | 데이터 + 하단 정보 줄: 기준 시각(asOf), 범위(scopeNote), 잘림 안내, 캐시 표시(관리자만) |

### 4.2 배지 규칙

- STALE: stale = true면 노란 배지 "데이터 지연", 툴팁 "마지막 적재 {asOf}, 예상 주기 {n}분".
- TRUNCATED: truncated = true면 회색 배지 "최근 {rowCount}건만 표시" + 조건 축소 안내.
- SCOPE: scopeNote가 있으면 회색 배지(예: "KR01 기준", "권한 없는 공장 제외").

### 4.3 시간대

- 응답 시각은 UTC다. 생산·측정 시각(부분군, MES 실적, EOL, 수입검사 판정)은 **공장 시간대**로 표시하고 공장 코드를 함께 쓴다(예: "11-28 14:00 (KR01)"). 툴팁에 사용자 시간대 시각을 덧붙인다.
- 사람의 업무 시각(알람 확인, 결재, 계산 요청)은 사용자 시간대(Salesforce 기본)로 표시한다.
- 생산일·판매월처럼 DATE인 값은 변환하지 않는다.
- 공장 시간대는 CMN_Plant__c.TimeZone__c를 Apex가 응답과 함께 내려준다(`QMS_*Controller`가 plantTimeZone 필드를 DTO에 포함).

## 5. 보안

| 항목 | 규칙 |
| --- | --- |
| 공장 범위 1차 | Apex가 PlantParam에 범위 공장을 강제로 넣고 SqlTemplate이 그 조건을 반드시 쓴다(2.2). 배포 테스트가 PlantParam을 가진 키의 SqlTemplate에 `:{PlantParam}` 토큰이 있는지 검사 |
| 공장 범위 2차(W2) | Mule이 요청마다 세션 범위 테이블(SEC.SESSION_SCOPE: SESSION_ID, PLANT_CODE)에 x-plant-scope를 넣고, CORE·MART 보안 뷰에 행 접근 정책(EXISTS 세션 범위)을 건다. Vol.8 AIQ-010 ANALYST 방식과 같다. 1차가 빠져도 다른 공장 행이 나오지 않게 하는 방어선(결정 SNOW-2) |
| 비용 | 비용 열은 RequiredPermission QMS_ViewCost 키에서만 SELECT하고, Snowflake Masking Policy(ROLE_FINANCE_READ 외 마스킹)를 함께 둔다. 비용 값을 CMN_KpiValue__c에 넣지 않는다(Vol.7 D7-4) |
| 포털 | PortalAllowed 키만 포털 Apex(`QMS_PortalWidgetDataService` 등)에서 부를 수 있고, SupplierParam은 Apex가 자기 협력사 코드로 덮어쓴다. 포털 사용자는 측정 원값·SL 내부 코멘트·다른 협력사 순위를 받지 않는다 |
| 로그 | 파라미터 값·결과 행·ANALYST 생성 SQL 원문은 남기지 않는다. queryKey, rowCount, durationMs, errorCode, requestId, 사번만 남긴다 |
| 자격 증명 | Named Credential·External Credential만 사용, Apex 코드에 키·URL을 넣지 않는다. Mule ↔ Snowflake는 Key-pair, 키 회전 90일 |
| 감사 | 비용·포털 키 호출은 CMN_Logger INFO로 1건씩 남긴다(누가 언제 어떤 키를 조회했는지) |

## 6. 테스트·목

### 6.1 목 파일

- 위치: `data/demo/mocks/dwh/{QueryKey}/{case}.json`. 형식은 응답 봉투 그대로. 케이스: ok, empty, truncated, stale, error-timeout, error-forbidden(필요한 것만, CMN_DwQuery__mdt.MockCases__c에 나열).
- ok 케이스 값은 데모 데이터(S7~S13)를 실제 등록 쿼리로 계산한 결과와 같아야 한다(6.4 계약 테스트). 생성은 Snowflake 데이터 생성기(gen_snowflake.py)가 한다.
- 배포: 저장소의 목 디렉터리를 묶은 정적 리소스 `CMN_DwMocks`(zip, Cache Control Private)를 테스트 전용으로 배포한다. 운영 배포 매니페스트에서는 뺀다.

### 6.2 Apex 테스트

    @IsTest public class CMN_DwMockService implements HttpCalloutMock {
        public CMN_DwMockService(String caseName);                    // 기본 'ok'
        public CMN_DwMockService withCase(String queryKey, String caseName);
        public HTTPResponse respond(HTTPRequest req);
        // 경로에서 queryKey를 읽어 CMN_DwMocks/{queryKey}/{case}.json을 돌려준다.
        // error-* 케이스는 Mule 오류 본문과 HTTP 코드(504, 403 등)로 돌려준다.
        public static List<HTTPRequest> captured();                   // 보낸 요청 검사용
    }

- 모든 P2·P3 화면 컨트롤러 테스트는 이 목을 쓴다(SeeAllData 금지). Continuation 테스트는 `Test.setContinuationResponse` + `Test.invokeContinuationMethod`로 같은 JSON을 넣는다.
- 필수 테스트: (a) 범위 주입 — KR01 사용자가 plantCodes [CN01] 요청 → 콜아웃 없음, 0행, scopeNote, (b) 오류 코드 7종 매핑, (c) 캐시 적중 시 콜아웃 0회, (d) captured()로 파라미터에 강제 공장이 들어갔는지, 파라미터 값이 로그에 없는지.
- 메타데이터 테스트 `CMN_DwQueryRegistryTest`(배포 파이프라인 필수): 모든 CMN_DwQuery__mdt에 대해 SqlTemplate 토큰 ⊆ AllowedParams ∪ {__limit}, PlantParam 토큰 존재, ORDER BY·LIMIT 존재, ResultColumns JSON 파싱, MockCases의 목 파일 존재(정적 리소스 안).

### 6.3 LWC Jest

- `import okMock from '../../../../../data/demo/mocks/dwh/QMS_SPC_SUBGROUPS/ok.json'`처럼 목을 직접 가져와 Apex 래퍼를 `jest.mock`으로 대체한다(경로는 jest.config의 moduleNameMapper 별칭 `@demo/mocks`로 고정 — DWH-004 보강).
- 컴포넌트마다 상태 4종(LOADING, EMPTY, ERROR, READY)과 배지 3종(STALE, TRUNCATED, SCOPE) 스냅숏 테스트를 둔다.

### 6.4 계약 테스트(Snowflake 실제 결과 ↔ 목)

- 스크립트 `scripts/dw/contract_test.py`(Vol.9 INT-020 보강): 개발 Snowflake(SL_QDW_DEV, 데모 데이터 적재)에서 등록 쿼리를 목의 params로 실행해 (a) columns 이름·타입·순서가 ResultColumns·목과 같고, (b) 행 값이 목과 같은지(아래 허용 오차) 검사한다. 배포 파이프라인에서 쿼리를 바꾼 PR이면 필수.
- 허용 오차: 통계 값(평균, σ, 한계, Cp·Cpk, %GRR, 분산 성분, kappa)은 상대 1e-6(같은 알고리즘의 데모 골든 비교), 건수·코드·날짜는 정확 일치. Minitab 대조는 별도 기준(SPC-003 BR-7 절대 0.01, MSA-003 BR-7 분산 성분 상대 0.5%)을 쓴다.

### 6.5 성능 테스트

- 데모 데이터 기준 측정은 기능 확인용이고, 성능 판정은 SPC-002 BR-10 규모(계획 3,000개, 측정 연 3억 건)로 합성한 부하 데이터(SL_QDW_PERF)에서 p95를 잰다. 측정 결과를 DWH-004 성능 보고서(docs/perf/dw-query.md)에 남긴다.

## 7. P4 결과 반영 표준(Snowflake → Salesforce 레코드)

DWH-003 BR-2~4 경로를 쓰는 모든 이벤트 유형(QMS_SPC_LIMIT_READY, QMS_SPC_ALARM, QMS_SPC_CAPABILITY_LOW, QMS_SPC_DATA_GAP, QMS_STAB_DAILY, QMS_SQM_SCORECARD, QMS_EW_ALERT, QMS_EOL_FPY_DROP, QMS_COA_ANOMALY, QMS_B2B_ALERT 등)에 공통 적용한다.

| 항목 | 규칙 |
| --- | --- |
| 이벤트 크기 | PAYLOAD는 120,000자 이하. 대상이 많은 이벤트(QMS_STAB_DAILY, QMS_SQM_SCORECARD, QMS_EW_ALERT 묶음)는 200건 단위로 나누고 payload에 `{batchId, part, partCount}`를 넣는다. 핸들러는 part 단위로 독립 처리한다(모든 part를 기다리지 않음) |
| EVENT_ID | 결정적 해시(같은 결과를 다시 계산해도 같은 Id). 예: QMS_STAB_DAILY = hash(asOfDate, part), QMS_SPC_ALARM = (planId, 첫 signalId) |
| 멱등 | CMN_InboundReceipt__c(ExternalEventId Unique)로 중복을 거른다. 결과 레코드는 ExternalKey upsert(스코어카드, 실적 필드)로 만든다 |
| 순서 | 같은 대상의 이벤트가 순서 없이 와도 결과가 같게 한다: 실적 필드 갱신은 payload의 asOfDate가 레코드의 마지막 asOfDate보다 새로울 때만(필드 LastResultAsOf__c를 각 대상 객체에 둠) |
| 핸들러 거버너 | CMN_ResultInbound__e 트리거는 PlatformEventSubscriberConfig로 배치 크기 50, 실행 사용자 = 통합 사용자. 핸들러 1건당 SOQL 10회·DML 5회 이하, 대상 200건 처리 시 벌크 패턴 |
| 실패 | 핸들러 예외는 Receipt FAILED + 재처리 버튼(DWH-003 BR-4). Snowflake 쪽 STATUS는 SENT로 남고, 재전송은 관리자 화면에서 Receipt 재처리로만 한다(중복 생성 방지) |
| 지연 감시 | SHARE.OUTBOUND_EVENT에서 STATUS NEW가 10분 넘게 남은 행 수를 MART.V_OUTBOUND_BACKLOG로 내고 Vol.9 INT-002 모니터가 5건 이상이면 관리자 알림 |
| 신선도 | 핸들러가 갱신한 레코드에는 원천 계산 시각(asOfDate 또는 calculatedAt)을 필드로 남겨 화면이 "기준 시각"을 보여준다(예: QMS_StabilizationPlan__c.LastResultAsOf__c, QMS_SupplierScorecard__c.CalculatedAt__c) |

## 8. SPC 종단 설계 점검

### 8.1 흐름과 지연 예산

    MES → (Mule 5분 마이크로배치, INT-010) RAW.MES_SPC
        → (Task 5분) CORE.SPC_MEASUREMENT
        → (Dynamic Table·Task 5분) CORE.SPC_SUBGROUP
        → (Task 5분, 한계 복제본으로 규칙 평가) CORE.SPC_SIGNAL
        → SHARE.OUTBOUND_EVENT(QMS_SPC_ALARM)
        → (Mule 1분 폴링) CMN_ResultInbound__e → QMS_SpcAlarmInboundHandler → QMS_SpcAlarm__c

| 구간 | 예산(p95) |
| --- | --- |
| 측정 → RAW | 5분 |
| RAW → 부분군·신호 | 5분 |
| 신호 → 알람 레코드 | 2분 |
| 합계(측정 → 알람) | 12분. SPC-002 AC-2의 "10분 이내"는 RAW 적재 이후 기준으로 해석을 명시한다(보강) |

### 8.2 관리 한계의 단일 원천(결정)

- **승인된 관리 한계의 원천은 Salesforce QMS_SpcLimit__c다.** 확정·결재·감사 이력(누가, 언제, 어떤 근거로)이 Salesforce에 있기 때문이다. Snowflake는 DWH-002 복제본 `CORE.SF_QMS_SPCLIMIT`(15분)로 판정한다. TRIAL 한계 값은 Snowflake가 계산해 P4(QMS_SPC_LIMIT_READY)로 보내고, Salesforce가 레코드를 만든다. Snowflake는 승인 전 한계로 판정하지 않는다.
- **적용 시각 규칙**: 한계 확정·승인 시 `EffectiveFrom = 확정 시각 + QMS_SPC_LIMIT_EFFECTIVE_DELAY_MIN(CMN 설정, 기본 30분)`. 복제 주기(15분)보다 길게 두어 Snowflake가 새 버전을 받기 전에 그 버전이 적용돼야 하는 부분군이 생기지 않게 한다. 화면은 "적용 예정 {시각}"을 보여준다.
- **복제 지연 보호**: Snowflake 규칙 평가 Task는 `MART.DATA_FRESHNESS`의 SF_REPLICA_15MIN이 25분보다 오래됐으면 OOC 규칙 평가를 보류하고(OOS는 계속 판정), 보류 구간 부분군을 복제가 회복된 뒤 평가한다. 보류가 30분을 넘으면 EVENT_TYPE 'QMS_SPC_EVAL_PAUSED'로 관리자에게 알린다.
- **선택(W2) 즉시 반영**: 한계 ACTIVE 시 Salesforce가 `QMS_SpcLimitChanged__e`를 발행하고 Mule이 CORE.SPC_LIMIT_OVERRIDE에 즉시 MERGE하면 지연을 30분에서 2분으로 줄일 수 있다. 기본은 지연 규칙만 쓴다(결정 SNOW-1).

### 8.3 쿼리 열 계약(SPC-006 소유, 모두 LatencyClass FAST, PlantParam plantCodes)

| QueryKey | 파라미터 | 결과 열(이름 타입) | MaxRows | Cache |
| --- | --- | --- | --- | --- |
| QMS_SPC_SUBGROUPS | planId ID, fromTs DATETIME, toTs DATETIME, beforeSubgroupNo INTEGER(선택), limit INTEGER(최대 1000, 기본 125) | subgroupNo INTEGER, subgroupTs DATETIME, n INTEGER, mean NUMBER, rangeVal NUMBER, stddevVal NUMBER, mrVal NUMBER, pVal NUMBER, uVal NUMBER, sampleN INTEGER, ucl NUMBER(P·U만 부분군별 한계, 그 외 NULL), lcl NUMBER(같음), limitVersion INTEGER, excluded BOOLEAN, hasOos BOOLEAN | 1000 | 60 |
| QMS_SPC_LIMITS | planId ID | version INTEGER, status STRING, effectiveFrom DATETIME, cl NUMBER, ucl NUMBER, lcl NUMBER, dispCl NUMBER, dispUcl NUMBER, dispLcl NUMBER, sigmaWithin NUMBER, source STRING | 50 | 300 |
| QMS_SPC_SIGNALS | planId ID, fromTs, toTs | signalId STRING, signalType STRING, ruleCode STRING, chart STRING, subgroupNo INTEGER, subgroupTs DATETIME, value NUMBER, limitVersion INTEGER | 2000 | 60 |
| QMS_SPC_SPEC | planId ID, fromTs, toTs | effectiveFrom DATETIME, effectiveTo DATETIME, lsl NUMBER, usl NUMBER, nominal NUMBER, unit STRING | 20 | 600 |
| QMS_SPC_HISTOGRAM | planId ID, fromTs, toTs, bins INTEGER(5~50, 기본 20) | binLow NUMBER, binHigh NUMBER, count INTEGER, mean NUMBER, sigmaOverall NUMBER, n INTEGER | 50 | 300 |
| QMS_SPC_CAPABILITY_SERIES | planId ID, periodType STRING(DAY, MONTH, ROLLING_30D), fromDate DATE, toDate DATE | periodStart DATE, periodEnd DATE, n INTEGER, mean NUMBER, sigmaWithin NUMBER, sigmaOverall NUMBER, cp NUMBER, cpk NUMBER, pp NUMBER, ppk NUMBER, isStable BOOLEAN, flags STRING | 400 | 600 |
| QMS_SPC_CAPABILITY_STUDY | itemId ID, characteristicId ID(선택), fromDate, toDate | SPC-003 BR-6 DTO 열과 같은 camelCase(planId, planNo, characteristicId, charNo, specialClass, lineCode, n, mean, sigmaWithin, sigmaOverall, cp, cpk, pp, ppk, isStable, flags) | 200 | 300(LatencyClass SLOW) |
| QMS_SPC_LIMIT_PREVIEW | planId ID, fromTs, toTs, excludedSubgroups STRING(JSON 배열) | cl, ucl, lcl, dispCl, dispUcl, dispLcl, sigmaWithin, subgroupCount INTEGER, currentCl, currentUcl, currentLcl, widthChangePct NUMBER, cpkNew NUMBER | 1 | 0(LatencyClass SLOW) |
| QMS_SPC_PLAN_SUMMARY | plantCode STRING, lineCode STRING(선택) | SPC-006 BR-10 계약 그대로 | 500 | 300 |
| QMS_SPC_MSA_STATUS | characteristicId ID, plantCode | studyNo STRING, studyType STRING, gaugeNo STRING, verdict STRING, pctGrrStudyVar NUMBER, pctGrrTolerance NUMBER, ndc INTEGER, approvedDate DATE | 5 | 600 |

규격선은 QMS_SPC_SPEC으로 따로 받는다(특성 버전이 기간 중 바뀌면 구간별 규격선). FreshnessKey: SUBGROUPS·SIGNALS·HISTOGRAM = SPC_SUBGROUP, CAPABILITY_* = SPC_CAPABILITY, LIMITS = SF_REPLICA_15MIN.

### 8.4 관리도 컴포넌트(qmsSpcChart) 구성 사양

| 요소 | 사양 |
| --- | --- |
| 배치 | 위: 주 관리도(X̄·X·p·np·c·u), 아래: 산포 관리도(R·S·MR, 계량형만). 두 차트 x축 공유(같은 subgroupNo 범위) |
| x축 | 기본 subgroupNo(정수 눈금), 토글로 subgroupTs(공장 시간대, 4.3) |
| 데이터 선 | 부분군 값 선 + 점(반지름 2), 제외 부분군(excluded) 회색 점·선 끊김 없음 |
| 한계선 | CL 실선, UCL·LCL 점선. limitVersion 구간별로 계단선(버전 경계에 세로 점선 + "v{n}" 라벨). P·U는 QMS_SPC_SUBGROUPS의 부분군별 ucl·lcl 열로 계단선을 그린다(화면에서 n으로 한계를 계산하지 않음) |
| 규격선 | LSL·USL 토글(기본 끔, 주 관리도만, 개별값 관리도에서만 의미 있다는 안내 툴팁) |
| 신호 | 신호 부분군 점을 빨강 큰 점(반지름 5)으로, 같은 점의 여러 규칙은 툴팁에 모두("R1, R5"). OOS는 빨강 마름모 |
| 기본 범위 | 최근 125부분군, ◀ ▶ 125개 이동, 기간 버튼(7·30·90일, 최대 1,000) |
| 성능 | Chart.js(cmnChartJs) animation false, parsing false(미리 {x,y} 변환), decimation 끔(추출 금지) |
| 접근성 | 차트 아래 "최근 신호" 표(최대 10행)로 같은 정보 제공 |
| 내보내기 | SPC-006 BR-4 CSV(표시 구간 부분군 통계) |

### 8.5 MSA 배지

SPC-006 BR-8 그대로(복제 데이터 조회, 없으면 숨김). 추가: 배지 데이터는 QMS_SPC_MSA_STATUS(Cache 600)로 받고, UNACCEPTABLE이면 공정능력 카드의 Cp·Cpk 옆에 경고 아이콘. 배지 클릭 시 연구 레코드로 이동(studyNo로 Salesforce 검색 → Id, 같은 Org).

### 8.6 데모·골든

- 데모 S7: 계획 KR01 L02 OP10 S-LENS-BE1 C10(X̄-S n=5), S1 비드 폭(KR01 L01 OP20 63117-BE1L C40), S13 조준각(CN01 L01 OP60 92101-KC1L C20, I-MR).
- 목: `data/demo/mocks/dwh/QMS_SPC_SUBGROUPS/ok.json`(S7 최근 125부분군), `.../QMS_SPC_SIGNALS/ok.json`, `.../QMS_SPC_LIMITS/ok.json`, `.../QMS_SPC_CAPABILITY_SERIES/ok.json`, `.../QMS_SPC_HISTOGRAM/ok.json`, `.../QMS_SPC_PLAN_SUMMARY/ok.json`, 케이스 empty·truncated·stale·error-timeout.
- 골든: `data/demo/expected/spc_S7.json` 키 `KR01-L02-OP10-C10`(한계, 일·월 Cp·Cpk·Pp·Ppk, R1·R2 신호 부분군 목록), `KR01-L01-OP20-C40`, `CN01-L01-OP60-C20`.

## 9. MSA 종단 설계 점검

### 9.1 결정

| 항목 | 결정 | 이유 |
| --- | --- | --- |
| 측정값 저장 | Salesforce QMS_MsaStudy__c.MeasurementJson__c(입력 원장, 131,072자) | 입력·수정·감사 이력이 Salesforce에 있음. 레코드 분할 금지 |
| 계산 시 데이터 전달 | **프로시저 호출 파라미터로 직접 전달**(measurementJson, designJson, toleranceJson, criteriaJson) | DWH-002 15분 복제를 기다리면 대화형 계산이 안 됨. RAW 즉시 적재 경로를 따로 만들 필요 없음(1MB 안에 들어감: GRR 10×3×3 = 90값 약 5KB, ATTRIBUTE 50×3×3 약 20KB) |
| CORE.MSA_MEASUREMENT 기록 | 프로시저만 MERGE(키 STUDY_ID, CALC_SEQ, PART, APPRAISER, TRIAL) | 단일 기록자. DWH-002 복제는 QMS_MsaStudy__c 필드를 복제하되 MeasurementJson을 펼치는 Task는 만들지 않는다(MSA-002 BR-8 보강) |
| 호출 방식 | ASYNC: Queueable 콜아웃 → 결과 필드 저장 → QMS_MsaCalcDone__e → 화면 empApi(실패 시 5초 폴링, 최대 90초) | 60초까지 걸릴 수 있고 결과를 레코드로 남겨야 함. Continuation 쓰지 않음 |
| 결과 반영 | Apex가 프로시저 결과(result)를 연구 필드(MSA-003·004 필드)와 ResultJson__c에 저장. ML.MSA_RESULT에는 프로시저가 이력 INSERT | 화면·보고서는 Salesforce 필드, 재현·분석은 Snowflake 이력 |
| 차트 이미지 | 계산 응답에 넣지 않는다. 보고서 생성(MSA-005) 때 Queueable 체인이 차트별로 `QMS_MSA_CHART`(PROCEDURE, chartType param: COMPONENTS, R_CHART, XBAR_CHART, INTERACTION) 1회씩 호출해 PNG(base64 ≤ 500KB)를 받는다 | INT-020 응답 1MB 한도. 4개를 한 응답에 넣으면 초과 가능 |
| 화면 차트 | qmsMsaResult는 ResultJson__c의 차트 데이터(숫자)로 Chart.js를 그린다(PNG 아님) | 대화형 표시 |
| 버전 | 결과 JSON의 engineVersion → CalcEngineVersion__c, 응답 calcVersion. 엔진 버전이 바뀌면 기존 결과는 그대로 두고 재계산은 사용자가 요청할 때만 | 승인된 결과의 재현성 |

### 9.2 계산 결과 JSON 계약(PROCEDURE QMS_MSA_CALC result)

    {
      "engineVersion": "msa-1.0.0",
      "studyId": "a1B...", "studyType": "GRR_ANOVA", "calcSeq": 3,
      "status": "OK",                       // OK 또는 FAILED
      "errorCode": null,                    // CONSTANT_NOT_VERIFIED, DESIGN_INCOMPLETE, ZERO_VARIATION 등
      "metrics": {"ev": 0.0021, "av": 0.0012, "interaction": 0.0, "grr": 0.0024, "pv": 0.0189, "tv": 0.0191,
                  "pctGrrStudyVar": 12.6, "pctGrrTolerance": 7.3, "pctGrrProcess": null, "ndc": 11,
                  "interactionPValue": 0.41, "interactionPooled": true, "rangeOutOfControlCount": 0},
      "verdict": {"value": "CONDITIONAL", "basis": "WORST", "reason": "%GRR(연구 변동) 12.6% — 10~30%"},
      "anovaTable": [{"source": "PART", "df": 9, "ss": 0.0, "ms": 0.0, "f": 0.0, "p": 0.0}],
      "varianceComponents": [{"source": "REPEATABILITY", "variance": 0.0, "pctContribution": 0.0, "stdDev": 0.0, "studyVar": 0.0, "pctStudyVar": 0.0, "pctTolerance": 0.0}],
      "chartData": {"components": [...], "rByAppraiser": [...], "xbarByAppraiser": [...], "interaction": [...]},
      "warnings": ["RESOLUTION_LOW"]
    }

Apex는 status FAILED면 CalcStatus FAILED + CalcError = errorCode와 메시지, 연구 Status는 MEASURING 유지.

### 9.3 실패 처리

| 상황 | 처리 |
| --- | --- |
| Mule TIMEOUT(60초) | CalcStatus FAILED("계산 시간 초과"), 재계산 버튼, Snowflake 쪽 쿼리는 Mule이 취소(SQL API cancel) |
| CONCURRENCY_LIMIT | Queueable이 `System.enqueueJob(job, 1)`로 1분 뒤 1회 재시도, 그래도 실패면 FAILED("대기 중 — 잠시 후 다시") |
| 프로시저 FAILED(CONSTANT_NOT_VERIFIED 등) | 메시지를 그대로 보여주고 재계산 버튼 숨김(설정 문제) + QualityAdmin 알림 |
| 계산 중 측정값 수정 | 계산 요청 시 MeasurementJson 해시를 CalcInputHash__c에 남기고, 결과 저장 시 현재 해시와 다르면 결과를 버리고 CalcStatus FAILED("입력 변경됨, 다시 계산") |
| 이벤트 유실 | 화면 폴링(5초, 90초)으로 회복. 90초 후에도 REQUESTED면 "계산이 오래 걸립니다 — 나중에 새로고침" |

### 9.4 데모·골든

- 데모 S8: S8-MSA1(마이크로미터 × 렌즈 두께, 조건부), S8-MSA2(에이밍 테스터 × 조준각, 합격), S8-MSA3(외관 긁힘 계수형).
- 목: `data/demo/mocks/dwh/QMS_MSA_CALC/ok-msa1.json`, `ok-msa2.json`, `ok-msa3.json`, `error-timeout.json`, `failed-constant.json`(result.status FAILED), `QMS_MSA_CHART/ok-components.json`.
- 골든: `data/demo/expected/msa_S8.json` 키 S8-MSA1·S8-MSA2·S8-MSA3(분산 성분, %GRR, ndc, 교호작용 p값·풀링 여부, kappa). 데모 비교는 상대 1e-6, Minitab 대조는 MSA-003 BR-7 허용 오차.

## 10. 기타 영역 점검

| 영역 | WI | 현재 경로 | 점검 결과 | 조치 |
| --- | --- | --- | --- | --- |
| 수입검사 실적 | QMS-03-IQC-007 | P1(KPI 5종) | 응답 봉투·신선도 키 없음, GAUGE_NO 열 없음(측정기 영향 분석 원천) | DATA_FRESHNESS 키 IQC_RESULT 등록, INSPECTION_RESULT에 GAUGE_NO, SQM·대시보드 드릴다운 쿼리(QMS_IQC_LOT_DETAIL) 정의 |
| 초기안정화 일 집계 | QMS-03-PIS-002, QMS-04-EFC-002 | P4(QMS_STAB_DAILY) + P2(파레토) | 이벤트 크기 분할 규칙·순서 처리·기준 시각 필드 없음, 모니터 차트 쿼리 키 미정의 | 7절 규칙 적용, LastResultAsOf__c, 쿼리 QMS_STAB_DAILY_SERIES·QMS_STAB_LOT_LIST 정의 |
| 보증시험 준수율 | QMS-03-PWT-002 | P1 | 신선도 표시만 부족 | KPI 레지스트리 FreshnessHours, 보드에 asOf |
| B2B 차트 | QMS-05-B2B-003·006 | P1 + P2(6쿼리) | 쿼리 6개의 결과 열 타입·목 케이스 미정, 건별 쿼리 5,000행이 1MB를 넘을 수 있음 | ResultColumns 확정, 건별 쿼리 MaxRows 3,000(행 300바이트 가정)으로 조정 또는 열 축소, LatencyClass(건별 SLOW) |
| 협력사 스코어카드 | QMS-06-SQM-002 | P4(스코어카드) + P2(드릴다운 2) | 드릴다운 열 계약 없음 | QMS_SQM_NCR_DETAIL·QMS_SQM_IQC_DETAIL ResultColumns, PortalAllowed false |
| 심사 분석 | QMS-06-IAU-007 | P1 + P2 | 대체로 충족(열 계약 있음) | 목 케이스와 FreshnessKey만 추가 |
| 조기경보 | QMS-08-AIQ-011·012 | P4(경보) + P1(점수) + P2(상위 위험) | QMS_EW_ALERT 묶음 분할, OPERATION 점수 드릴다운 열 계약 | 7절 분할 규칙, QMS_EW_TOP_RISKS·QMS_EW_FACTORS FreshnessKey RISK_SCORE |
| Q&A Analyst | QMS-08-AIQ-010 | P5 | 봉투 매핑 미정(생성 SQL·해석 문장 위치) | rows = 결과 표, result = {interpretation, sqlHash, semanticModelVersion}, LatencyClass SLOW, CacheSeconds 0 |
| 사례 검색 | QMS-08-AIQ-002 | P5 | 봉투 매핑 미정 | rows = 검색 결과(caseId, caseType, score, title, snippet, plantCode), CacheSeconds 300 |
| 출하검사·EOL | QMS-04-FQC-004 | P1 + P2(EOL 요약) | EOL 요약은 시리얼 원천을 읽어 느릴 수 있음 | LatencyClass SLOW, MART.EOL_DAILY_AGG Dynamic Table 사용, 결과 열 계약 |
| 측정기 영향 분석 | QMS-06-GAU-004 | P2 | 12개월 INSPECTION_RESULT 조회로 느릴 수 있음, 결과를 Salesforce에 저장하는지 불명확 | LatencyClass SLOW, 요약(로트 수·고위험 로트)은 분석 레코드 필드에 저장(P2 결과의 사용자 확정 시점 스냅숏), 상세는 재조회 |
| 분석실 정기 추세 | QMS-06-LAB-004 | P2 | 원천이 복제 테이블(15분), 결과 열 미정 | ResultColumns, FreshnessKey SF_REPLICA_15MIN |
| MSA 후보 | QMS-06-MSA-001 | P2(QMS_MSA_GAUGE_USAGE) | 결과 열 미정 | ResultColumns(charId, charNo, gaugeNo, measureCount, lastMeasuredAt) |
| 대시보드 위젯 | QMS-07-DSH-002·003·012·016 | P1 + P2 | 캐시 이중화(위젯 + DWH), runQuery DTO와 봉투 관계, SPC 차트 추출 예외, 신선도 화면 원천 | 3.3 단일 캐시, QMS_QueryResultDTO = CMN_DwQueryResult, SPC 추출 금지 명시, DSH-016이 MART.DATA_FRESHNESS를 쿼리 QMS_DW_FRESHNESS로 표시 |

## 11. 결정이 필요한 항목

- [ ] SNOW-1 SPC 관리 한계 적용 시각 = 확정 시각 + 30분(복제 지연 흡수) 기본, 즉시 반영 이벤트(QMS_SpcLimitChanged__e → Mule MERGE)는 W2 선택
- [ ] SNOW-2 Snowflake 2차 공장 범위(세션 범위 테이블 + 행 접근 정책) 도입 시점 — PoC에서 동작 검증 후 W2 적용
- [ ] SNOW-3 SPC 측정 → 알람 지연 예산 12분(RAW 적재 후 10분) 수용
- [ ] SNOW-4 WH_BI 업무 시간 상시 1클러스터 유지(콜드 스타트 2초 제거, 비용 증가) 여부
- [ ] SNOW-5 SPC 관리도 기본 보기 최근 125부분군 + 다운샘플링 금지(기간 보기 최대 1,000)
- [ ] SNOW-6 MSA 보고서 차트 이미지를 차트별 프로시저 호출로 받기(보고서 생성 시간 증가 수용)
- [ ] SNOW-7 DWH-004 공수 4 → 8 M/D(DWH-004a 서비스·메타·캐시·오류 5, DWH-004b 화면 상태 LWC·목·레지스트리 테스트 3)와 INT-020 4 → 6 M/D

## 12. WI별 보강 지시

2단계 작업자는 아래 행을 해당 WI 본문(BR·AC·데이터 모델·화면·권한)에 반영한다. "목"은 data/demo/mocks/dwh, "골든"은 data/demo/expected 기준 경로다.

### 12.1 Vol.0

| WI ID | 현재 상태 요약 | 추가할 내용 |
| --- | --- | --- |
| CMN-00-DWH-001 | 스키마·웨어하우스·역할·비용 모니터만 정의 | BR 추가: MART.DATA_FRESHNESS(SOURCE_KEY, LAST_LOADED_AT, EXPECTED_INTERVAL_MIN, UPDATED_BY_TASK)와 모든 적재 Task의 갱신 책임(2.5), ROLE_SF_READER는 MART와 CORE SECURE VIEW만 SELECT, SHARE.OUTBOUND_EVENT 열(EVENT_ID, EVENT_TYPE, PAYLOAD, STATUS, PART, PART_COUNT, CREATED_AT, SENT_AT)과 MART.V_OUTBOUND_BACKLOG, QUERY_TAG 비용 뷰 MART.V_DW_QUERY_COST, (W2) SEC.SESSION_SCOPE와 행 접근 정책. AC: ROLE_SF_READER로 RAW 조회 실패, 적재 Task 실행 후 DATA_FRESHNESS 갱신 |
| CMN-00-DWH-002 | 15분·일 복제, 워터마크 | BR 추가: 복제 완료 시 DATA_FRESHNESS SF_REPLICA_15MIN·SF_REPLICA_DAILY 갱신, 복제 지연 25분 초과 감시(SPC 판정 보호, 8.2), Long Text JSON 필드는 복제만 하고 펼치기는 소유 WI가 정함(MSA MeasurementJson은 펼치지 않음, 9.1). AC: 복제 중단 30분 시 관리자 알림 |
| CMN-00-DWH-003 | KPI 적재·인바운드 이벤트·멱등 Receipt | 데이터 모델: CMN_KpiValue__c OWD Public Read Only(공장 필터는 QMS_WidgetDataService가 강제, 비용 KPI 금지), 차원 Vehicle__c·Department__c·ProductGroup__c, PeriodType QUARTER, 이벤트 CMN_KpiLoaded__e. BR: 7절 P4 표준 전체(payload 120,000자·200건 분할·part, 결정적 EVENT_ID, PlatformEventSubscriberConfig 배치 50, LastResultAsOf 순서 규칙, Receipt 재처리만 재전송), 예시 KPI 키 QMS_CPK → QMS_SPC_CPK. AC: part 3개 이벤트가 순서 없이 도착해도 결과 동일, 더 오래된 asOfDate 이벤트 무시 |
| CMN-00-DWH-004 | query(키, 파라미터)·공장 필터·MaxRows 5,000·p95 3초만 정의 | 2절 전체 반영: CMN_DwQuery__mdt 필드 표준(2.1), SqlTemplate 규칙(2.2), CMN_DwQueryService 시그니처·처리 순서·LatencyClass별 호출(일반·Continuation·Queueable)·CMN_DwQueryResult(2.3), Mule 계약 참조(2.4), 오류 코드 7종과 라벨(2.6), Platform Cache 파티션 CMNDw(3.3), 크기 한도(3.4), LWC 모듈 cmnDwDataState·컴포넌트 cmnDwStateFrame(4절), CMN_DwMockService·정적 리소스 CMN_DwMocks·CMN_DwQueryRegistryTest·jest moduleNameMapper @demo/mocks(6절). 공수 4 → 8(DWH-004a 5, DWH-004b 3로 분할 권고). AC: KR01 사용자 CN01 요청 시 콜아웃 0·0행·scopeNote, 오류 코드 7종 매핑, 캐시 적중 시 콜아웃 0, SLOW 키는 Continuation 경로, 미등록 키 NOT_REGISTERED(예외 아님), 레지스트리 테스트가 PlantParam 토큰 누락 키를 실패시킴 |
| CMN-00-DSH-001 | 위젯 계약 @api config·size, 지연 로딩 | BR 추가: P2·P3 데이터를 쓰는 위젯은 cmnDwStateFrame으로 상태 4종을 그리고 asOf·stale·truncated·scopeNote를 하단 정보 줄에 표시, 보드 공통 필터의 기간은 공장 시간대 기준(4.3). AC: 쿼리 오류 위젯만 오류, 다른 위젯 정상 |
| CMN-00-SEC-004 | 암호화·SSO·마스킹 설정 | 설정 추가: 비용 열 Masking Policy(ROLE_FINANCE_READ 외 마스킹), Mule ↔ Snowflake Key-pair 90일 회전, ROLE_SF_READER 권한 범위, (W2) 세션 범위 행 접근 정책 근거를 docs/security/baseline.md에 기록 |

### 12.2 Vol.3

| WI ID | 현재 상태 요약 | 추가할 내용 |
| --- | --- | --- |
| QMS-03-IQC-007 | KPI 5종·INSPECTION_RESULT 펼침 | INSPECTION_RESULT에 GAUGE_NO 열(Vol.6b 요청과 같음), DATA_FRESHNESS IQC_RESULT 갱신, 등록 쿼리 QMS_IQC_LOT_DETAIL(plantCodes STRING_LIST, vendorNo, itemNo, fromDate, toDate → lotNo STRING, grDate DATE, decision STRING, inspectionLevel STRING, coaStatus STRING, ngCount INTEGER, rejectQty NUMBER; MaxRows 2000, FAST, Cache 600, PlantParam plantCodes) — SQM·대시보드 드릴다운용, KPI 레지스트리 FreshnessHours 30. 데모 S9, 골든 iqc_S9.json, 목 QMS_IQC_LOT_DETAIL/ok·empty |
| QMS-03-PIS-002 | QMS_STAB_DAILY 이벤트로 계획 필드 갱신, 차트 쿼리 미정 | 7절 적용(200계획 분할, EVENT_ID = hash(asOfDate, recordType, part), 계획 필드 LastResultAsOf__c, 더 오래된 asOfDate 무시). 등록 쿼리 QMS_STAB_DAILY_SERIES(planId → date DATE, lots INTEGER, rejectLots INTEGER, receivedQty NUMBER, defectQty NUMBER, ppm NUMBER, specialDefects INTEGER; MaxRows 400, FAST, Freshness IQC_RESULT)와 QMS_STAB_LOT_LIST(planId, fromDate, toDate → lotNo, grDate, decision, defectType, ngCount; MaxRows 500). 모니터는 cmnDwStateFrame, 날짜는 공장 기준. 데모 S3(S3-STB). AC: 같은 asOfDate 재수신 시 변화 없음, 전날 asOfDate 이벤트가 늦게 와도 필드 유지 |
| QMS-03-PWT-002 | 준수율 KPI | 보드에 asOf 표시, KPI QMS_PERIODIC_TEST_COMPLIANCE 레지스트리 FreshnessHours 30, 데모 S0 |

### 12.3 Vol.4

| WI ID | 현재 상태 요약 | 추가할 내용 |
| --- | --- | --- |
| QMS-04-SPC-001 | 한계 버전 객체, 확정 시 EffectiveFrom = 확정 시각 | 8.2 결정 반영: 승인 한계의 원천은 Salesforce, EffectiveFrom = 확정 시각 + CMN 설정 QMS_SPC_LIMIT_EFFECTIVE_DELAY_MIN(기본 30), 한계 화면 "적용 예정 {시각}". AC-4 수정(EffectiveFrom = 확정 + 30분). 데모 S7(S7-PLAN, 한계 v1) |
| QMS-04-SPC-002 | 측정·부분군·한계 산출·규칙 평가·신호 송출 | BR 추가: 복제 지연 보호(SF_REPLICA_15MIN 25분 초과 시 OOC 평가 보류·회복 후 재평가, 30분 초과 시 QMS_SPC_EVAL_PAUSED), DATA_FRESHNESS MES_SPC·SPC_SUBGROUP 갱신, P·U 부분군별 한계 열(CORE.SPC_SUBGROUP.UCL_I·LCL_I), 신호 이벤트가 500신호를 넘으면 part 분할, 8.1 지연 예산과 AC-2 해석(RAW 적재 후 10분), SPC_CONSTANTS 시드 검증 테스트(c4 닫힌 식·d2·d3 수치 적분으로 표 값 재계산 대조). AC 추가: 데모 S7 R2 최초 신호 부분군이 spc_S7.json#KR01-L02-OP10-C10.signals.R2[0]과 같음, 복제 지연 30분이면 OOC 신호 없음·OOS 신호 있음 |
| QMS-04-SPC-003 | 공정능력 계산·KPI·getCapability | QMS_SPC_CAPABILITY_STUDY를 LatencyClass SLOW(Continuation)로, 결과 열 8.3 표, getCapability가 CMN_DwQueryResult를 DTO로 바꾸는 규칙, FreshnessKey SPC_CAPABILITY, CAPABILITY_LOW 이벤트 7절. AC 추가: S7 일별 Cpk가 골든과 상대 1e-6, 목 ok·empty로 Apex 테스트 |
| QMS-04-SPC-004 | 재계산 미리보기·결재 | QMS_SPC_LIMIT_PREVIEW를 LatencyClass SLOW, CacheSeconds 0, 결과 열 8.3 표, 미리보기 오류면 상신 불가. AC-4 수정(승인 10:00 → EffectiveFrom 10:30, 10:35 부분군 새 버전) |
| QMS-04-SPC-005 | 알람 수신·OCAP | 7절 인바운드 규칙(핸들러 배치 50, part 독립 처리), 알람 화면 관리도는 qmsSpcChart(신호 강조, QMS_SPC_SIGNALS CacheSeconds 60). 데모 S7 알람 1건(R2 → R1 묶음). AC: 같은 신호 묶음 part 2개가 순서 없이 와도 알람 1건 |
| QMS-04-SPC-006 | 등록 쿼리 7종(열 일부), 기간 최대 1,000 | 등록 쿼리 표를 8.3 열 계약으로 바꾸고 QMS_SPC_SPEC 추가, SUBGROUPS에 beforeSubgroupNo·limit 파라미터와 ucl·lcl 열. BR-2 수정: 기본 보기 최근 125부분군 페이지(◀ ▶), 기간 보기 최대 1,000, 다운샘플링 금지(Vol.7 DSH-003 BR-5 예외). 8.4 차트 사양, cmnDwStateFrame, 시각은 공장 시간대. 목 8.6 경로·케이스. AC-1 수정(기본 보기 125점, 30일 기간 보기 720점), AC 추가: stale 응답이면 지연 배지, SUBGROUPS error-timeout이면 관리도 영역만 오류이고 공정능력 카드 정상 |
| QMS-04-EFC-002 | MES 일 집계·QMS_STAB_DAILY PRODUCT·파레토 쿼리 | 7절 분할·순서(PRODUCT 포함), QMS_EFC_DEFECT_PARETO 결과 열(defectTypeCode STRING, defectTypeName STRING, qty NUMBER, pct NUMBER, cumulativePct NUMBER; MaxRows 20, FAST, Freshness MES_PRODUCTION), QMS_STAB_DAILY_SERIES PRODUCT 열(date, inputQty, firstPassQty, defectQty, ppm, fpy). 데모 S0 |
| QMS-04-FQC-004 | EOL 요약 쿼리·KPI·FPY 급락 | QMS_FQC_EOL_SUMMARY를 LatencyClass SLOW, MART.EOL_DAILY_AGG Dynamic Table 사용, 결과 열(plantCode, itemNo, mesLotNo, testCode, produced, tested, firstPass, finalPass, finalFail, scrapped, untested), DATA_FRESHNESS EOL, QMS_EOL_FPY_DROP 7절. 데모 S13, 골든 S13 키 |

### 12.4 Vol.5

| WI ID | 현재 상태 요약 | 추가할 내용 |
| --- | --- | --- |
| QMS-05-B2B-003 | KPI 계산·비용 쿼리 전용 | DATA_FRESHNESS CUSTOMER_QUALITY, KPI 레지스트리 FreshnessHours, 비용 쿼리 RequiredPermission QMS_ViewCost(CMN_DwQuery__mdt 필드). 데모 S10, 골든 b2b_S10.json |
| QMS-05-B2B-004 | 추세 경보 규칙 | QMS_B2B_ALERT 이벤트 7절(분할, 결정적 EVENT_ID = hash(ruleCode, scopeKey, period)) |
| QMS-05-B2B-006 | 분석 화면 등록 쿼리 6개 | 6개 ResultColumns(타입 포함) 확정, 건별 쿼리는 1MB 한도로 MaxRows 재산정(행 바이트 × MaxRows ≤ 900KB, 예: 3,000) 또는 열 축소, LatencyClass(추세·파레토·상위 품번 FAST, 건별·MIS 곡선 SLOW), CacheSeconds 600, FreshnessKey CUSTOMER_QUALITY, 영역별 cmnDwStateFrame. AC-4 수정(재산정한 MaxRows). 목 S10 |

### 12.5 Vol.6b

| WI ID | 현재 상태 요약 | 추가할 내용 |
| --- | --- | --- |
| QMS-06-MSA-001 | 후보 산출 쿼리 QMS_MSA_GAUGE_USAGE | ResultColumns(charId ID, charNo STRING, gaugeNo STRING, measureCount INTEGER, lastMeasuredAt DATETIME), Freshness IQC_RESULT, 목 |
| QMS-06-MSA-002 | MeasurementJson 저장, DWH 복제 후 Task가 CORE.MSA_MEASUREMENT로 펼침 | BR-8 수정: 복제는 하되 펼치기 Task 없음, CORE.MSA_MEASUREMENT는 프로시저만 기록(9.1). 필드 CalcInputHash__c(9.3) |
| QMS-06-MSA-003 | Queueable 콜아웃 → 프로시저 → 결과 저장 → 이벤트 | 9.2 결과 JSON 계약(engineVersion, calcSeq, status, errorCode, metrics, verdict, anovaTable, varianceComponents, chartData, warnings), 9.3 실패 처리(입력 변경 감지, CONCURRENCY_LIMIT 1분 뒤 재시도, TIMEOUT 시 SQL 취소), Continuation 미사용 명시, QMS_MSA_CALC LatencyClass ASYNC·CacheSeconds 0. 데모 S8, 골든 msa_S8.json(상대 1e-6), 목 9.4. AC 추가: 계산 중 측정값 수정 시 FAILED "입력 변경됨" |
| QMS-06-MSA-004 | 편의·직선성·안정성·계수형 계산 | 같은 결과 JSON 계약(유형별 metrics 키 목록 명시), 데모 S8-MSA3 골든 |
| QMS-06-MSA-005 | 보고서 PDF에 프로시저 PNG 4개(각 500KB) | BR-4 수정: 계산 응답에서 PNG를 받지 않고 보고서 생성 Queueable 체인이 QMS_MSA_CHART(PROCEDURE, chartType 4종)를 차트별 1회 호출(응답 1MB 한도). QMS_MSA_CHART 등록 행 추가. AC: 차트 1개 실패 시 나머지 차트로 보고서 생성 + 재생성 To-Do |
| QMS-06-GAU-004 | 영향 조회 QMS_GAU_IMPACT_RESULTS | LatencyClass SLOW, ResultColumns(source, lotId, lotNo, itemNo, charNo, inspectedAt, sampleCount, minMargin, riskLevel), 분석 완료 시 요약(로트 수·고위험 로트 수·조회 시각)을 분석 레코드에 스냅숏 저장, Freshness IQC_RESULT. 데모 S12, 골든 gauge_S12.json, 목 |
| QMS-06-LAB-004 | 정기 추세 쿼리 | QMS_LAB_PERIODIC_TREND ResultColumns, FreshnessKey SF_REPLICA_15MIN |

### 12.6 Vol.6c

| WI ID | 현재 상태 요약 | 추가할 내용 |
| --- | --- | --- |
| QMS-06-SQM-002 | 스코어카드 이벤트·드릴다운 2개 | QMS_SQM_SCORECARD 7절(200협력사 분할), 드릴다운 ResultColumns — QMS_SQM_NCR_DETAIL(ncrNo, openedDate, itemNo, defectType, confirmedQty, status), QMS_SQM_IQC_DETAIL(lotNo, grDate, itemNo, decision, rejectQty, ngCount), PortalAllowed false, 화면 기준 시각 = CalculatedAt__c. 데모 S9 |
| QMS-06-IAU-007 | KPI·분석 쿼리(열 계약 있음) | MockCases·FreshnessKey SF_REPLICA_DAILY 추가 |

### 12.7 Vol.7

| WI ID | 현재 상태 요약 | 추가할 내용 |
| --- | --- | --- |
| QMS-07-DSH-002 | runQuery·위젯 캐시·허용 목록 메타 | QMS_QueryResultDTO = CMN_DwQueryResult(같은 필드), QMS_WidgetQuery__mdt.CacheSeconds 제거(캐시는 DWH-004 단일 계층, 3.3), PlantParam·SupplierParam·PortalAllowed·RequiredPermission은 CMN_DwQuery__mdt로 옮기고 QMS_WidgetQuery__mdt는 위젯 노출 허용 목록만, SLOW 쿼리는 Continuation 래퍼 |
| QMS-07-DSH-003 | qmsWidgetBase 상태 3종, 500점 추출 | qmsWidgetBase를 cmnDwDataState 위에 구현, 4.2 배지 규칙, BR-5에 SPC 관리도 추출 금지 예외 명시 |
| QMS-07-DSH-006 | SPC·EFC·FQC 위젯 | SPC 위젯은 qmsSpcChart 기본 보기 125부분군, QMS_SPC_PLAN_SUMMARY 목 사용 |
| QMS-07-DSH-012 | 조기경보·AI 정확도 위젯 | QMS_EW_TOP_RISKS FreshnessKey RISK_SCORE, 목 ok·stale |
| QMS-07-DSH-016 | KPI 신선도·연계 상태 위젯 | 등록 쿼리 QMS_DW_FRESHNESS(sourceKey, lastLoadedAt, expectedIntervalMin, stale; FAST, Cache 60)와 QMS_DW_OUTBOUND_BACKLOG(eventType, newCount, oldestCreatedAt)로 Snowflake 신선도·송출 적체 표시 |

### 12.8 Vol.8

| WI ID | 현재 상태 요약 | 추가할 내용 |
| --- | --- | --- |
| QMS-08-AIQ-002 | 사례 검색 SEARCH | 봉투 매핑(rows 열: caseId, caseType, recordNo, title, snippet, score, plantCode, causeCode, closedDate), CacheSeconds 300, 오류 코드 2.6 |
| QMS-08-AIQ-010 | Cortex Analyst Q&A | 봉투 매핑(rows = 결과 표, columns = Analyst 결과 열, result = {interpretation, sqlHash, semanticModelVersion, suggestions}), LatencyClass SLOW, CacheSeconds 0, 생성 SQL 원문 로그 금지 |
| QMS-08-AIQ-011 | 위험 점수·경보·상위 위험 쿼리 | QMS_EW_ALERT 7절(분할, EVENT_ID = hash(entityType, entityKey, asOfDate)), DATA_FRESHNESS RISK_SCORE, QMS_EW_TOP_RISKS·QMS_EW_FACTORS·QMS_EW_SCORE_TREND FreshnessKey. 데모 S11, 골든 ew_S11.json |

### 12.9 Vol.9

| WI ID | 현재 상태 요약 | 추가할 내용 |
| --- | --- | --- |
| QMS-09-INT-020 | PROCEDURE 구현·4모드 규약 | 2.4 QUERY 응답 봉투 생성(타입 매핑, 숫자 정밀도, 파티션, 1MB 자르기 = truncated, 신선도 조회, x-timeout-ms, QUERY_TAG, x-plant-scope와 세션 범위 테이블(W2)), HTTP → errorCode 표, 계약 테스트 scripts/dw/contract_test.py(6.4), 성능 데이터 SL_QDW_PERF(6.5). 공수 4 → 6 |
| QMS-09-INT-008 | SAP → Snowflake 공용 테이블 | 적재 완료 시 DATA_FRESHNESS SAP_STOCK·SAP_SHIPMENT·SAP_BOM 갱신 |
| QMS-09-INT-010 | MES SPC 측정 수집 | DATA_FRESHNESS MES_SPC 갱신, 5분 예산 감시(8.1) |
| QMS-09-INT-011 | MES 생산·불량·EOL 수집 | DATA_FRESHNESS MES_PRODUCTION·EOL 갱신 |
| QMS-09-INT-014 | 필드클레임 → Snowflake | DATA_FRESHNESS CUSTOMER_QUALITY 갱신 |
