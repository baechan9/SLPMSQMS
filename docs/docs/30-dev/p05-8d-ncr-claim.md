# P5 8D 엔진·부적합·고객 클레임

8D·CAPA 공용 엔진(Vol.5 CLM-001~004·006), 부적합 NCR(Vol.6a NCR-001~006), 고객 클레임 접수·초기 대응·귀책·회신(CLM-007~009·011), 고객 품질 매핑(B2B-001), 레슨런 기본(LEL-001·002)을 만든다. 게이트웨이 바인딩 NCR·EIGHT_D·LESSON_LEARNED가 실제 구현으로 바뀌는 페이즈다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | NCR 등록 → 봉쇄·처분 → 협력사 통보 → 8D → 효과 확인 → 종결, 클레임 접수 → 봉쇄 → 귀책 → 회신 → 종결이 AI 없이 끝까지 동작 |
| 기간(4명 기준) | 누적 112영업일(P4 이후 약 23일) |
| 마일스톤 | S1 NCR Full Cycle(AI 제외), S2 핵심(분석실·협력사 8D 포털 제외) |
| 착수 조건 | DVQ-007(게이트웨이 프레임워크), IQC-004·005, SPP-001·002 `개발 완료` |
| 다음 페이즈로 당겨 착수 가능 | P6 중 4MC-001·002, IQC-006, RPP-001, PIS-001(IQC-005·PPA-004 뒤) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 19건 · 110 M/D · W1 19 · SF 트랙 19건 · 외부 트랙 0건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | QMS-05-CLM-001 | 8D 엔진 데이터 모델·단계 규칙·생성 서비스 | W1 | 8 | SF | — | — |
| A2 | QMS-05-CLM-002 | 8D 작성 화면·단계 게이팅 | W1 | 7 | SF | CLM-001 | — |
| A3 | QMS-05-CLM-003 | 8D 액션(CAPA) 추적·효과 검증 | W1 | 6 | SF + DW 목 | CLM-001 | — |
| A4 | QMS-05-CLM-004 | D7 재발 방지 연계·D8 종결 결재 | W1 | 5 | SF | CLM-002, CLM-003 | — |
| A5 | QMS-05-CLM-006 | 고객 양식 8D·6pi 보고서 생성 | W1 | 6 | SF | CLM-002 | 엑셀 양식 채우기 라이브러리 확인(CR-8) |
| B1 | QMS-06-NCR-001 | 부적합 데이터 모델·상태 규칙·공통 기반 | W1 | 6 | SF | — | — |
| B2 | QMS-06-NCR-002 | 부적합 등록(모바일)·원천 자동 생성 게이트웨이 | W1 | 6 | SF | NCR-001 | — |
| B3 | QMS-06-NCR-003 | 봉쇄·처분·특채·재고 처리 이벤트 | W1 | 7 | SF | NCR-002 | — |
| B4 | QMS-06-NCR-004 | 부적합 통보서·귀책 확정·이의 제기(포털) | W1 | 6 | SF + 포털 | QMS-05-CLM-001, NCR-002 | — |
| B5 | QMS-06-NCR-005 | 원인·대책(8D 엔진 연계)·무단 4M 판정 | W1 | 4 | SF | QMS-05-CLM-001, QMS-05-CLM-002, NCR-004 | — |
| B6 | QMS-06-NCR-006 | 효과 확인 연동·종결·후속 조치 요청 | W1 | 4 | SF | QMS-05-CLM-003, QMS-05-CLM-004, NCR-005 | — |
| C1 | QMS-05-B2B-001 | 고객 품질 통합 데이터 모델·결함 코드·품번 매핑 | W1 | 6 | SF + DW 목 | — | — |
| C2 | QMS-05-CLM-007 | 고객 클레임 접수·기한 관리 | W1 | 7 | SF | B2B-001, CLM-001 | — |
| C3 | QMS-05-CLM-009 | 반품 분석·귀책 판정·부적합 연계 | W1 | 5 | SF | CLM-007 | — |
| C4 | QMS-09-INT-015 | 고객 클레임 통보 → QMS_Claim__c(IF-FC-002) | W1 | 4 | SF + 연계 시뮬 | QMS-05-CLM-007 | — |
| C5 | QMS-05-CLM-008 | 초기 대응: 의심 범위 산정·봉쇄·초기 회신 | W1 | 5 | SF + DW 목 | CLM-003, CLM-007, CLM-006 | — |
| C6 | QMS-05-CLM-011 | 고객 회신·수용 이력·종결·에스컬레이션 | W1 | 6 | SF + DW 목 | CLM-006, CLM-009, CLM-008 | — |
| D1 | QMS-04-LEL-001 | 레슨런 데이터 모델·태그·게시 절차 | W1 | 6 | SF | — | — |
| D2 | QMS-04-LEL-002 | 레슨런 등록 화면·원천 연계 서비스·라이브러리 | W1 | 6 | SF | LEL-001 | — |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

레인 B(NCR)의 NCR-004·005·006은 레인 A(8D)의 CLM-001·002·003·004를 기다린다. 레인 A를 하루라도 먼저 시작한다. 레인 B의 NCR-002 → 003은 임계 경로(→ P6 NCR-008 → P12 AIQ-002) 위에 있으므로 IQC-005가 끝나는 날 착수한다.

### 레인 A — 8D 엔진(CLM-001 → 002 → 003 → 004, 006)

1. **CLM-001**: `QMS_EightD__c`·Step·TeamMember·Action, 레코드타입 4개(CUSTOMER_CLAIM, NCR_SUPPLIER, NCR_INTERNAL, AUDIT_FINDING), 모드 FULL_8D·SHORT_CAPA, 단계 상태 기계·기한 계산·승인 잠금·재개, `QMS_EightDService.createFromSource`(멱등, 200건), `QMS_EightDEvent__e`, 종결 8D 전사 조회(D5-4), 바인딩 EIGHT_D 등록(`QMS_EightDGatewayImpl`). 데모 보강: TeamMember·Action ExternalKey, 8D 화면 초기 로드 DTO(`mocks/apex/qmsEightDScreen/S1-8D.json`), 클레임 MIS·VIN 해시 수 필드 결정.
2. **CLM-002**: 8D 작업 화면, 단계별 필수 검증(5W2H, Why 사슬, 유출 원인 대책), 팀·액션 그리드, Is/Is Not·Why-why 편집기, AI 영역 자리(`EIGHT_D_ASSIST` 기본 구현 = 버튼 숨김, AC-4), 모바일 봉쇄 입력. review-pack 3절 변경 요청 1건.
3. **CLM-003**: 액션 생애주기·To-Do·기한 변경, 08:00 지연 에스컬레이션, 증빙·검증(본인 검증 금지), 효과 확인(KPI·재발·수동) 배치, NOT_EFFECTIVE 재개, 내 액션 화면, 8D KPI.
4. **CLM-004**: D7 체크 항목·문서 연결, 수평전개·레슨런 게이트웨이 호출(HORIZONTAL_DEPLOY는 P8까지 기본 구현 To-Do — AC-2가 이 상태), D8 결재(귀책 부서장 합의 → 공장 품질팀장), `QMS_EightDRcaHitRule`·`QMS_EightDCapaHitRule`, 원천 취소 시 8D 취소.
5. **CLM-006**: 고객 양식 메타데이터·필드 매핑, Visualforce `QMS_EightDReport`(renderAs pdf) → `getContentAsPDF()`(Queueable) → CMN 문서 리비전, DRAFT 워터마크, 엑셀 양식 채우기(**CR-8**: 승인 라이브러리 SheetJS를 이 용도에 쓸지 결정 필요).

### 레인 B — 부적합(NCR-001 → 002 → 003 → 004 → 005 → 006)

1. **NCR-001**: `QMS_NCR__c`(RecordType INTERNAL·SUPPLIER), 상태 전이 서비스, 재발 판정(180일), CC 특성 → Severity A, 통보서 승인 전 협력사 비공개(`SupplierShareTo__c`), `QMS_NcrEvent__e`, `QMS_NcrQueryService`, 공통 기반 등록(채번 `NCR-{PLANT}-{YYYY}-{SEQ:6}`, 공유, 삭제 통제).
2. **NCR-002**: 모바일 빠른 등록(라벨 스캔·사진), 중복 후보, 게이트웨이 구현체·바인딩 NCR(`requestFromQualification`, `requestFromIncoming`, `requestNcr`), 원천 NCR 번호 회신(`QMS_NcrSourceConfig__mdt`), **기본 구현 To-Do 전환 배치**(P4에서 쌓인 SourceType QMS_NCR_REQUEST To-Do → NCR, AC-6), Severity A면 수입검사 Hold.
3. **NCR-003**: 봉쇄(기한·후보 위치, 로트 추적), 처분·특채 결재·고객 승인, 확정 불량 수량, 재고 이동 이벤트(SAP 전기는 P8 INT-007). 데모 보강: `QMS_NcrContainment__c.ExternalKey__c`.
4. **NCR-004**(CLM-001 뒤): 통보서 결재·PDF·발행, 협력사 공유 시작, 회신(접수·이의), 무응답 1일 수용 간주, 귀책 재판정, 포털 NCR 화면.
5. **NCR-005**(CLM-002 뒤): 대책 모드 판정(FULL_8D 기준, D6A-5), EIGHT_D 게이트웨이 생성, 클레임 8D 연결(LINKED_8D), 무단 4M 판정, NCR 화면 8D 요약. NCR 화면에 AI 영역을 두지 않는다(D8-11).
6. **NCR-006**(CLM-003·004 뒤): 종결 조건·결재, Hold 해제, 후속 조치(HORIZONTAL_DEPLOY·LESSON_LEARNED 게이트웨이), 재개.

### 레인 C — 고객 클레임(B2B-001 → CLM-007 → 008, 009 → 011, INT-015)

1. **B2B-001**(Salesforce 쪽): `QMS_CustomerDefectMap__c`·`QMS_CustomerPartMap__c`와 관리 화면(미매핑 탭), `QMS_CustomerQualityOwnerResolver`. Snowflake RAW·STG·CORE·Dynamic Table은 외부 트랙에서(WI 플랫폼 SNOW·SF).
2. **CLM-007**: `QMS_Claim__c`, 접수 경로 3개(수동, 연계, 경보), 연계 수신 계약(고객 클레임 번호 멱등), 기한 계산(고객 CSR 필드), 재발 판단, 8D 단계 이벤트로 클레임 상태 동기화, 첨부 수신 REST, `QMS_ClaimEvent__e`, 목록 화면.
3. **CLM-008**: 의심 범위 조회(Snowflake 등록 쿼리 `QMS_CLM_SUSPECT_STOCK`), 봉쇄 계획·액션 일괄 생성, Clean Point, CONTAINMENT_STARTED 이벤트(1회), 05:00·09:00 초기 회신 감시.
4. **CLM-009**: 반품 수령·분석 의뢰(LAB_REQUEST는 P10까지 기본 구현 To-Do — AC-1), 귀책 판정·결재(NTF·고객 귀책, D5-5), 협력사 귀책 → `requestNcr`(CUSTOMER_CLAIM), 협력사 원인 가져오기, 사내 귀책 부서 참여.
5. **CLM-011**: 회신 객체·기대 회신 3건 자동 생성, 발송 조건(승인된 단계·RELEASED 보고서), 고객 판정·추가 회신, 기한 감시·에스컬레이션, 종결 조건(8D 효과 확인 후, D5-10), 클레임 KPI.
6. **INT-015**(Salesforce 쪽): 클레임 통보 → `QMS_Claim__c` upsert 계약 확인, 첨부 전달 방식(변경 요청). Mule 쪽은 외부 트랙.

### 레인 D — 레슨런 기본(LEL-001 → LEL-002)

1. **LEL-001**: `QMS_LessonLearned__c`(태그, 상태·버전, 게시 결재, 전사 조회·협력사 비공개), 이벤트, KPI. 코드 그룹 DEV_PHASE·DEV_ACTIVITY_TYPE(P1 MDM-007 보강분)을 쓴다.
2. **LEL-002**: `QMS_LessonLearnedService.createFromSource`, 바인딩 LESSON_LEARNED 구현, 등록·편집 화면, 다중 코드 선택 컴포넌트, 라이브러리 검색(영문 카드).

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| 게이트웨이 바인딩 | `QMS_GatewayBinding__mdt` NCR·EIGHT_D·LESSON_LEARNED 레코드 | 나머지(HORIZONTAL_DEPLOY, LAB_REQUEST, IMPROVEMENT, EIGHT_D_ASSIST)는 기본 구현 유지 |
| PDF | Visualforce 페이지(`QMS_EightDReport`, NCR 통보서) | Queueable `getContentAsPDF()` |
| 포털 화면 | NCR 회신·이의(NCR-004) | P4 포털 사용자로 |
| 스케줄 잡 | CLM-003 08:00, CLM-008 05:00·09:00, CLM-011 08:00, NCR-003 봉쇄 기한 | 게이트 Org에서 등록 스크립트로 |
| 첨부 수신 REST | CLM-007 | `curl`로 호출 |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| 분석실(P10), 수평전개(P8), 개선 과제(P9), AI 초안(P12) | 게이트웨이 기본 구현. CLM-009 AC-1, CLM-004 AC-2, CLM-002 AC-4가 이 상태를 검증 |
| 의심 재고(Snowflake `QMS_CLM_SUSPECT_STOCK`) | `data/demo/mocks/dwh/QMS_CLM_SUSPECT_STOCK/ok.json` |
| NCR 재고·로트 추적 쿼리(`QMS_NCR_STOCK_CHECK`, `QMS_NCR_LOT_TRACE`) | **데모 목 파일이 없다.** NCR-003이 같은 폴더 규칙으로 L1 목(ok·empty·error-timeout)을 만든다 |
| 필드클레임 연계(INT-015 Mule) | 계약 CSV upsert 2회 |
| 고객 품질 Snowflake 모델(B2B-001) | 매핑 객체만 Salesforce에서 확인. 매핑 상태(MAPPED·AMBIGUOUS) 계산은 외부 트랙 |

## 6. 데모 데이터

```bash
scripts/demo/load_salesforce.sh qms-int --upto-phase 5
```

| 파일 | 객체 | 적재 | 비고 |
| --- | --- | --- | --- |
| 40, 45a | QMS_NCR__c | 전부 | 70건(INTERNAL 45·SUPPLIER 25, 종결 62), 45a는 8D 연결 |
| 41~44 | 8D·단계·팀·액션 | 전부 | 86 + 584 + 102 + 287 |
| 45, 45b | QMS_Claim__c | 45는 일부(분석 의뢰 연결은 P10) | 20건(종결 18) |
| 46, 47 | 봉쇄·처분 | 전부 | 72 + 69 |
| 48 | QMS_IqcLot__c | 다시 실행해 NCR 연결 채움 | |
| 53 | QMS_LessonLearned__c | 전부 | 18 |
| 96, 97 | 고객 결함·품번 매핑 | 전부 | Snowflake 데이터 작업 소유 |
| 83, 85 | 결재 요청·To-Do | 다시 실행해 NCR·8D 대상 채움 | |

데모 기준일(2026-12-01)과 게이트 날짜가 다르면 기한 경과·에스컬레이션 결과가 달라진다(dev-plan 11절, 생성기 `--today`).

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G5-1 | 새 Org 배포·테스트·P5까지 적재 | 6.4절 | 실패 0 |
| G5-2 | P4 게이트에서 생긴 "부적합 등록" To-Do 전환 배치 | NCR-002 AC-6 | To-Do 수만큼 NCR, To-Do 종료 |
| G5-3 | 모바일 NCR 등록(라벨 스캔·사진 3장) | NCR-002 AC-1, UX-001 AC-1 | OPEN NCR, 파일 3개(장변 1920) |
| G5-4 | IQC 불합격 로트 → `requestFromIncoming` 2회 | NCR-002 AC-3·4 | SUPPLIER NCR 1건, 같은 Id |
| G5-5 | Severity A 봉쇄 기한·알림, SORT 처분 확정 수량 | NCR-003 AC-1·4 | 4시간 기한, 확정 불량 50 |
| G5-6 | 통보서 승인 전후 협력사 포털 조회, 무응답 1일 | NCR-001 AC-5, NCR-004 | 승인 전 권한 없음, 승인 후 조회, 수용 간주 |
| G5-7 | FULL_8D 기준 NCR → 8D 생성 → D1~D8 → 효과 확인 → NCR 종결 | NCR-005·006, CLM-001~004 | 단계 게이팅, D8 결재, EFFECTIVE 후 종결 |
| G5-8 | S1: `S1-NCR` → `S1-8D` D4 진행(수동 원인 입력) → 종결 | 데모 S1 | D1~D3 승인 상태 유지, D4부터 진행 가능 |
| G5-9 | 클레임 접수(고객 CSR 기한), 연계 수신 2회, 재발 | CLM-007 AC-1·3·4 | 기한, 1건 유지, IsRecurrence |
| G5-10 | 의심 범위 조회(목) → 봉쇄 액션 2건 | CLM-008 AC-1~3 | 액션 2·To-Do 2·이벤트 1회 |
| G5-11 | S2: `S2-CLAIM` 귀책 협력사 확정 → `S2-NCR`, 8D D4 승인 상태 | 데모 S2, CLM-009 AC-3 | `requestNcr` 1회, 원천 번호 회신 |
| G5-12 | FINAL 회신 거절 → 추가 회신, 8D 효과 미확정 종결 상신 | CLM-011 AC-3·5 | 추가 회신 + To-Do, 종결 차단 |
| G5-13 | 8D PDF FINAL 2회, INTERIM | CLM-006 AC-1~3 | Rev 2 RELEASED·Rev 1 SUPERSEDED, DRAFT 워터마크 |
| G5-14 | 레슨런 게시·개정, CN01 사용자 조회, 포털 사용자 | LEL-001 AC-2~5 | 버전 전환, 전사 조회, 포털 차단 |
| G5-15 | **회귀 AC(실제 객체)**: NCR 200건 채번, 공장 격리, DRAFT NCR 삭제 로그, NCR 코멘트 권한, NCR 8D_REPORT 리비전, NCR 참조 코드 삭제 차단 | ARC-003 AC-1, SEC-002 AC-1~4, SEC-003 AC-2, UX-003 AC-1, DOC-001 AC-1, MDM-007 AC-2 | P1·P2에서 테스트 대상 객체로 확인한 결과와 같음 |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D5-1(8D 공용 엔진), D5-4(종결 8D 전사 조회), D5-5(NTF·고객 귀책 결재), D5-8(양식 매핑), D5-10(클레임 종결 조건) |
| 결정 | D6A-5(FULL_8D 기준), D6A-6(NCR 1건 = 품번 1·현상 1), D6A-7(협력사 비공개·무응답 수용), D6A-10(효과 확인은 8D 결과) |
| 결정 | D4-5(레슨런 전사 조회), D4-6(레슨런 게시 결재), D-9(공장 격리와 지식 객체 예외) |
| 결정 | CR-8 엑셀 양식 채우기 라이브러리(CLM-006) |
| 명세 | 데모 보강(CR-6): CLM-001(TeamMember·Action ExternalKey, 클레임 MIS·VIN 필드, 8D 화면 DTO), NCR-003(Containment ExternalKey) |
| 명세 | review-pack 3절: CLM-002 1, CLM-007 1, B2B-001 1, Vol.5·6a 쿼리 키 1, LEL 코드 1 |
| 명세 | NCR 쿼리 키 목(`QMS_NCR_STOCK_CHECK`, `QMS_NCR_LOT_TRACE`) 응답 열 계약 확인(Vol.6a ↔ Vol.9 INT-008·012) |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| 8D 엔진(CLM-001, 8 M/D)이 늦어 NCR 후반이 멈춤 | 레인 A 선착수, CLM-001 데이터 모델·생성 서비스를 먼저 머지하고 화면(CLM-002)은 뒤에 |
| 바인딩 교체 시 P4 호출 측 회귀 | 게이트웨이 계약 테스트(기본 구현·실제 구현 둘 다)를 공통 테스트로 유지 |
| 데모 8D 584단계·287액션 적재 시 검증 규칙 충돌 | 상태가 이미 진행된 레코드 적재는 트리거 bypass(`CMN_TriggerHandler.bypass` 또는 bypass 권한)를 로더 실행 사용자에게만. 우회 범위를 보고서에 적음 |
| 기한 계산이 데모 기준일과 어긋남 | 생성기 `--today` 또는 날짜를 바꾼 테스트 레코드 |

## 10. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| | | | |
