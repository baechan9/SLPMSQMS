# CMN-00-DWH-003 A단계 보고 — Snowflake → Salesforce KPI·알람 전달(데이터 모델·화면)

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-DWH-003 (docs/docs/10-workitems/vol0-cmn-common.md#12절) |
| Wave / 공수(계획 → 실제) | W1 / 6 M/D(화면 추정 1.8) → A단계 약 0.5 M/D |
| 작업일 | 2026-11-06 |
| 구현 | Claude Code(에이전트) |
| 상태 | 화면 완료(화면 우선 플랜 A0 4항, R1 검토 대기). DEV-STATUS는 B단계에서 바꾼다 |

## 1. 범위

화면 우선 플랜 5.1절 4항에 따라 A0에서는 **데이터 모델·레이아웃·권한·KPI 데모 적재**까지 했다. 대시보드 위젯(A7)이 데모 KPI를 읽고, R1에서 데이터 모델을 검토할 수 있게 하는 것이 목적이다.

| 구분 | A0(이번) | B단계(P3 레인 C) |
| --- | --- | --- |
| KPI 값 | 객체·차원·탭·목록·권한, 이름 채움 트리거, 데모 2,162행 | 13개월 초과 삭제 배치, 적재 완료 이벤트 발행 확인 |
| 결과 수신 | 이벤트·경로 메타데이터·영수 객체·탭·목록·권한 | 구독 트리거(PlatformEventSubscriberConfig 배치 50), `CMN_InboundHandler`, 멱등·UNROUTED·FAILED, 재처리 버튼, `scripts/apex/publish-inbound.apex`, AC-1·AC-2 |
| 연계 | 통합 사용자 권한 셋 | Mule 폴링·Bulk 적재(AC-3, 외부 트랙) |

## 2. 구현 내역

- **객체·이벤트·메타데이터**(`meta-src/cmn/`):
  - `CMN_KpiValue__c`: KpiKey, PeriodType(DAY·WEEK·MONTH·QUARTER), PeriodStart, 차원 9개(공장·라인·품번·특성·협력사·고객·차종·부서·제품군), Value·Target(18,6), Unit, Rag(GREEN·AMBER·RED), ExternalKey(255, 유일·대소문자 구분).
    - 공유: 사내 공개 읽기 전용, 외부 비공개.
    - 화면: 읽기 전용 레이아웃, 콤팩트 레이아웃, 목록 "월간 값"·"위험 신호"·"전체".
  - `CMN_ResultInbound__e`: EventType(80), ExternalEventId(255), PayloadJson(131072). 커밋 후 발행.
  - `CMN_KpiLoaded__e`(Vol.7 변경 요청): LoadId, KpiKeys, RowCount, LoadedAt.
  - `CMN_InboundRoute__mdt`: EventType, HandlerClass, OwnerWi, IsActive. 등록 레코드는 없다(핸들러를 만드는 WI가 등록).
  - `CMN_InboundReceipt__c`:
    - 필드: ExternalEventId(255, 유일), EventType, Status(RECEIVED·PROCESSED·UNROUTED·FAILED, 서비스 전용), ProcessedAt, ResultRecordId, AttemptCount, PayloadJson, ErrorMessage.
    - 공유는 비공개다. 목록은 "실패"·"경로 없음"·"전체".
- **Apex:**
  - `CMN_KpiValueService.prepare`: Name을 `{KPI 키} {기간 단위} {기간 시작 yyyy-MM-dd}`로 채운다. SOQL은 없다.
  - `CMN_KpiValueTriggerHandler`, `CMN_KpiValueTrigger`: 객체당 트리거 1개다.
- **권한 셋:**
  - `CMN_PS_KpiValue_Read`: KPI 값 읽기. `CMN_PS_Dashboard_User`가 있는 사내 PSG 14개 전부에 넣었다.
  - `CMN_PS_Inbound_Admin`: 수신 영수 모두 보기와 KPI 값·수신 영수 탭. `CMN_PSG_SystemAdmin`에 넣었다.
  - `CMN_PS_Integration_Dwh`(Snowflake 통합 사용자):
    - KPI 값 쓰기, 차원 객체 읽기(공장 읽기 때문에 회사 읽기도 준다).
    - 두 이벤트 발행.
    - 수신 영수 쓰기. 구독 실행 사용자가 이 사용자이고, 서비스 전용 필드도 이 PS에서만 쓸 수 있다.
  - 검토용 열람 PS `QMS_PS_Prototype_Review`에는 두 객체가 자동으로 들어갔다.
- **화면 진입:**
  - SL Admin 앱 탭(수신 영수, KPI 값).
  - 메뉴 허브 항목 `QMS_07_DSH_KPIVALUE`(대시보드 메뉴)와 `QMS_09_INT_INBOUND`(연계 메뉴). 라벨 2개(ko·en_US·zh_CN)를 더했다.
- **생성기:** `metagen.py`는 플랫폼 이벤트의 필드 권한을 만들지 않는다. 이벤트 필드에는 필드 수준 보안이 없어 객체 권한(읽기·만들기)만 준다.
- **데모 데이터:**
  - `90_CMN_KpiValue__c.csv` 2,162행(KPI 23종, 일 1,359·월 803)을 `qms-dev-a`에 적재했다. 실패는 0건이다.
  - 차종 차원 95행이 연결됐다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 테스트 | CMN_KpiValueService_Test 4건 통과 |
| └ 통합 사용자 적재 | 200행을 외부 키로 2회 upsert해도 200건(멱등). 공장 코드 참조, 트리거 SOQL 0회 |
| └ 이름 채움 | 분기 KPI 이름, 기간이 바뀌면 다시 만든다 |
| └ 조회 전용 페르소나 | KPI는 읽지만 고칠 수 없다. 수신 영수는 볼 수 없다 |
| └ 시스템 관리 페르소나 | 다른 사람이 기록한 영수를 모두 본다 |
| └ 영수 중복 | 외부 이벤트 Id 중복은 DUPLICATE_VALUE로 거부된다(AC-1의 기반) |
| Apex 커버리지 | CMN_KpiValueService·핸들러·트리거 100% |
| 회귀 | CMN_AppMenuController_Test·CMN_PersonaSecurity_Test·CMN_Prototype_Test 27건 통과 |
| Code Analyzer(심각도 1~2) | 0건 |
| 생성기 최신·Prettier·한글 리터럴·레코드 페이지·화면 제어 규칙·이름 가림·ESLint | 통과 |

## 4. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 변경 요청 반영 | review-pack 2절 DWH-003 데이터 모델 요청을 A0에서 반영했다. 반영 항목: PeriodType QUARTER(Vol.6c·7), 차원 Vehicle·Department·ProductGroup(Vol.5·6b·7·8), 사내 공개 읽기 전용·외부 비공개(Vol.7), `CMN_KpiLoaded__e`(Vol.7). 예시 키 `QMS_SPC_CPK`는 데모 데이터가 이미 따른다 | 명세 반영 대기(사용자 승인) |
| 명세 보충 1 | 재처리(BR-4)에 원문이 필요해 수신 영수에 PayloadJson·ErrorMessage·AttemptCount를 더했다. 처리 전 상태 RECEIVED도 더했다 | 변경 요청: DWH-003 데이터 모델 |
| 명세 보충 2 | 크기 미정 필드를 정했다: ExternalEventId 255(Vol.9 INT-002 BR-5 형식 `{IF-ID}:{원천 키}:{원천 버전}`), EventType 80. 경로 메타데이터에 OwnerWi를 더했다 | 변경 요청 |
| 명세 보충 3 | `CMN_KpiLoaded__e` 필드(LoadId, KpiKeys, RowCount, LoadedAt)를 정했다. Vol.7은 이벤트 이름만 요청했다 | 변경 요청(Vol.7 DSH-002와 맞춤) |
| 명세 보충 4 | Snowflake 통합 사용자 PS `CMN_PS_Integration_Dwh`를 만들었다. INT-001의 통합 사용자 3개 중 DWH 도메인이다 | 보고 |
| 보류 | (KpiKey, PeriodType, PeriodStart) 조회 인덱스 요청(Vol.7)은 메타데이터로 만들 수 없다. Salesforce 지원 요청 대상이며 운영 데이터량을 본 뒤 판단한다 | B단계·운영 |
| 위험 | 공장 1곳에 KPI 행이 1만 건을 넘으면 Lookup 쏠림(잠금 경합)이 생길 수 있다(R-1). 적재는 Bulk API 직렬 모드나 공장별 분할로 한다 | B단계 Mule 적재 설계 |
| 결정 대기 | O-2(위젯 단위만 적재)가 확정되면 데모의 일 단위 1,359행을 줄일지 정한다. 지금은 위젯 시연을 위해 그대로 둔다 | 사용자 결정 O-2 |
| 후속 | 수신 구독·핸들러 라우팅·재처리·13개월 삭제·`publish-inbound.apex`·AC-1~3 | B단계 P3 레인 C |

**화면 확인 방법:**
- **KPI 값:** SL Admin 앱 → "KPI 값" 탭(또는 SL QMS 메뉴 허브 07 대시보드 → "KPI 값") → 목록 "위험 신호"에서 RED 값을 본다.
- **수신 영수:** SL Admin 앱 → "수신 영수" 탭. 목록 구성만 확인한다. 데이터는 B단계의 이벤트 발행 뒤에 생긴다.

## 5. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch).
- dry-run 후 배포했다(2,128개 구성요소). 첫 dry-run은 통합 PS의 회사 읽기 종속 권한 누락으로 실패해 고쳤다.
- 커밋: `[CMN-00-DWH-003] 화면: …`
