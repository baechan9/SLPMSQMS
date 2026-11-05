# P4 인정시험·협력사 포털·수입검사·PPAP

첫 QMS 업무 페이즈다. Vol.2 인정시험(DVQ-001~008), Vol.3 협력사 포털 기반·수입검사·부품 PPAP, SAP 입고·판정 연계의 Salesforce 쪽을 만든다. QMS 게이트웨이 프레임워크가 여기서 생기고, 이후 모든 메뉴가 그것으로 서로를 호출한다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | 인정시험 계획 → 결재 → 의뢰 → 결과 → 종합 판정, 협력사 포털 로그인과 문서 업로드, 입고 → 수입검사 → 판정 → 수준 전환, PPAP 생성 → 협력사 제출 → PSW 승인이 Scratch Org에서 동작 |
| 기간(4명 기준) | 누적 89영업일(P3 이후 약 38일) |
| 마일스톤 | S9 수입검사(성적서 제외), S3 앞부분(인정시험 PASS, PPAP 승인) |
| 착수 조건 | W0 전부 `개발 완료`, 해당 P3 선행(DWH-004, APV-003 등) |
| 다음 페이즈로 당겨 착수 가능 | P5 중 NCR-001(선행 CMN뿐), CLM-001(DVQ-007 뒤), B2B-001(DWH 계열 뒤), LEL-001 |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 22건 · 119 M/D · W1 21 · W2 1 · SF 트랙 21건 · 외부 트랙 1건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | QMS-02-DVQ-001 | 시험 항목 라이브러리 | W1 | 4 | SF | — | — |
| A2 | QMS-02-DVQ-002 | 시험 기준 템플릿(필수 시험 매트릭스) | W1 | 5 | SF | DVQ-001 | — |
| A3 | QMS-02-DVQ-003 | 인정시험 계획 데이터 모델·상태 규칙 | W1 | 6 | SF | DVQ-001 | — |
| A4 | QMS-02-DVQ-004 | 계획 생성 마법사·라인 편집 그리드 | W1 | 4 | SF | DVQ-002, DVQ-003 | — |
| A5 | QMS-02-DVQ-005 | 계획 결재와 트리거 연계 서비스 | W1 | 5 | SF | DVQ-003 | — |
| A6 | QMS-02-DVQ-006 | 시험 의뢰·접수·진행 관리 | W1 | 6 | SF | DVQ-005 | — |
| A7 | QMS-02-DVQ-007 | 시험 결과 입력·항목 판정·불합격 처리 | W1 | 5 | SF | DVQ-006 | 게이트웨이 프레임워크를 먼저 별도 PR로(CR-3) |
| A8 | QMS-02-DVQ-008 | 종합 판정·양산 적용 결정 | W1 | 5 | SF | DVQ-007 | — |
| B1 | QMS-03-PPA-001 | PPAP 요소 마스터·제출 레벨 규칙 | W1 | 4 | SF | — | — |
| B2 | QMS-03-SPP-001 | 협력사 포털 사이트·사용자·수신자 해석 | W1 | 6 | SF + 포털 | — | 포털 라이선스 D-5·D3-1 확정 필요 |
| B3 | QMS-03-PPA-002 | PPAP 건 데이터 모델·트리거·요소 체크리스트 생성 | W1 | 6 | SF | PPA-001 | — |
| B4 | QMS-03-SPP-002 | 포털 홈·To-Do·문서 업로드 공통 컴포넌트 | W1 | 5 | SF + 포털 | SPP-001 | — |
| B5 | QMS-03-PPA-003 | 협력사 PPAP 제출·요소별 검토 | W1 | 7 | SF + 포털 | PPA-002, SPP-002 | — |
| B6 | QMS-03-PPA-004 | PSW 승인 결재·승인 상태 반영·잠정 승인 관리 | W1 | 5 | SF | PPA-003 | — |
| C1 | QMS-03-IQC-001 | 샘플링 계획·수입검사 기준서 | W1 | 6 | SF | — | — |
| C2 | QMS-03-IQC-002 | 검사 로트 데이터 모델·입고 수신·로트 초기화 | W1 | 6 | SF | IQC-001 | — |
| C3 | QMS-03-IQC-003 | 검사 결과 입력·항목 판정·로트 판정(모바일) | W1 | 7 | SF | IQC-002 | — |
| C4 | QMS-03-IQC-004 | 판정 후속 처리·SAP 회신·NCR 연계·협력사 통보 | W1 | 5 | SF + 포털 | SPP-001, IQC-003, QMS-02-DVQ-007 | 선행 보정: QMS_NcrGateway 사용(CR-2) |
| C5 | QMS-03-IQC-005 | 검사 수준 자동 전환(정상·강화·완화·무검사) | W2 | 5 | SF | IQC-004 | 앞당김: QMS-06-NCR-002·QMS-06-NCR-006의 선행 |
| D1 | QMS-09-INT-004 | SAP 입고 → 수입검사 로트 생성(IF-SAP-002) | W1 | 6 | SF + 연계 시뮬 | QMS-03-IQC-002 | — |
| D2 | QMS-09-INT-005 | 수입검사 판정 → SAP 사용결정·재고 이동(IF-SAP-004) | W1 | 5 | SF + 연계 시뮬 | INT-004, QMS-03-IQC-004 | — |
| X1 | QMS-09-INT-008 | SAP → Snowflake 공용 데이터(재고·출하·환율·표준가·BOM·배치, IF-SAP-003) | W1 | 6 | 외부 트랙 | — | — |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

### 레인 A — 인정시험(DVQ-001 → … → 008)

임계 경로(DVQ-005 → 006 → 007 → 레인 C IQC-004 → 005 → P5 NCR-002 …)다. 레인 A를 가장 먼저 착수한다. DVQ-007은 P9 심사 엔진(IAU-002)의 선행이기도 하다.

1. **DVQ-001~002**: 시험 항목 라이브러리(Revision, CSV 일괄 등록), 시험 기준 템플릿(조건 키 점수로 세트 선택, 4M 유형 합집합). 데모 보강: `QMS_TestStandard__c`·`Line__c` ExternalKey, `ChangeTypes__c` 값 형식(CHANGE_TYPE 경로 키, 쉼표 구분). review-pack 3절 변경 요청(TriggerType PERIODIC, Phase REQUAL)을 먼저 반영.
2. **DVQ-003~004**: 계획·라인 데이터 모델과 상태 규칙(라이브러리 스냅숏, Status는 서비스로만), 생성 마법사·라인 편집 그리드(60라인 2초). 데모 보강: `QMS_QualPlanLine__c.ExternalKey__c`.
3. **DVQ-005**: 계획 결재(시험 부서장 병렬 합의 — `CMN_ApprovalLineContributor`), `QMS_QualPlanService.createFromSource`·`getStatusBySource`(멱등, TargetDate 포함 — review-pack), `QMS_QualPlanEvent__e`.
4. **DVQ-006**: 의뢰·접수·진행(`QMS_QualLineRequested__e` 발행, 신뢰성 시스템 라인 편집 불가).
5. **DVQ-007**: 결과 입력·항목 판정·불합격 처리. **CR-3**: 착수하자마자 게이트웨이 프레임워크(`QMS_GatewayFactory`, `QMS_GatewayBinding__mdt`, 인터페이스 8종과 DTO 6종, 바인딩 없을 때의 기본 구현 = 담당자 To-Do)를 별도 PR로 먼저 머지한다. 레인 C의 IQC-004가 이것을 기다린다. FAIL 시 NCR 게이트웨이 호출(AC-3: NCR 미배포 상태에서 To-Do). review-pack 변경 요청 7건.
6. **DVQ-008**: 종합 판정·양산 적용 결정(CONDITIONAL이면 품질본부장 단계), JUDGED 이벤트, 보고서 생성 큐(보고서 자체는 P6 DVQ-009).

### 레인 B — 협력사 포털·PPAP(SPP-001 → SPP-002, PPA-001 → 002 → 003 → 004)

1. **SPP-001**: Experience Cloud LWR 사이트, Customer Community Plus 라이선스·프로필·외부 OWD Private, 포털 사용자 활성화(Contact 역할 QUALITY·PPAP·SHIPPING·MANAGEMENT, PortalPlants), `QMS_SupplierContactResolver.resolve`, 알림 링크를 포털 URL로 변환, `QMS_PortalRoute__mdt`. 데모 보강: Contact `ExternalKey__c`. P2 SEC-002 AC-3(협력사 간 격리)을 여기서 확인한다.
2. **SPP-002**: 포털 홈(To-Do 기한 경과 우선), 품번 목록, 공지, `qmsPortalDocUpload`(제출 후 업로드 차단, 공개 문서만, 60MB 차단). 포털 홈 Apex DTO가 명세에 없다(데모 목 `mocks/apex/qmsPortalHome/V10003.json`이 제안 DTO) — 착수 전 명세 보강.
3. **PPA-001**: 요소 마스터·레벨별 요구(S·R·C), 레벨 결정 규칙(점수). 데모 보강: 레벨별 S/R 값 확정(품질경영팀 검수 전 데모 가정), `QMS_PpapLevelRule__c.ExternalKey__c`.
4. **PPA-002**: PPAP 건·요소 라인, `QMS_PpapService.createFromSource`, 시스템 링크 요소 자동 채움(인정시험 계획 등), `QMS_PpapEvent__e`, InternalNote 비공개. 데모 보강: ElementLine·Submission ExternalKey.
5. **PPA-003**: 협력사 제출 객체·포털 제출 화면·자동 점검(CC 특성 공정능력 누락, Ppk remark), 치수 CSV 판정, 해시 경고, 보완 차수.
6. **PPA-004**: PSW 판정·결재·콜백, 승인 상태 반영(`CMN_SupplierItem__c.PpapStatus`), 잠정 승인 만료 관리.

### 레인 C — 수입검사(IQC-001 → 002 → 003 → 004 → 005)

IQC-004·005는 임계 경로 위에 있다. IQC-001~003을 DVQ-007 머지 전에 끝내 두고, 게이트웨이 프레임워크가 머지되는 날 IQC-004를 착수한다.

1. **IQC-001**: 샘플링 계획(`QMS_SamplingService.determine`)·기준서·검사 항목, 엑셀 일괄 등록, 특성 새 버전 시 SQE To-Do. 데모 보강: SamplingPlanRow·IqcStandard·Line ExternalKey(데모 샘플링 표는 가정 값 c=0, SL 현행 표로 교체 예정).
2. **IQC-002**: `QMS_IqcLot__c`·`QMS_IqcResult__c`, 입고 수신 계약(외부 키 멱등), 로트 초기화(SKIP 자동 합격, 빈도 SKIPPED_FREQ, 기준서 없음 To-Do, 장기 미입고), 200건 10초. 데모 보강: `QMS_IqcResult__c.ExternalKey__c`, `QMS_IqcLot__c.Coa__c`(IQC-006 BR-3이 쓰는데 정의 누락).
3. **IQC-003**: 검사 대기열(300건 중 50건 2초, 대기열 DTO가 명세에 없음 — `mocks/apex/qmsIqcQueue/KR01.json`), 입력·판정(모바일, 바코드 `lightning/mobileCapabilities`, 세로 붙여넣기), `QMS_InspectionHook`·`QMS_InspectionHook__mdt`(측정기·검사원 훅 — 구현은 P10, 지금은 테스트 훅), PPAP 거절 로트 예외 승인.
4. **IQC-004**(DVQ-007의 게이트웨이 프레임워크 머지 후): `QMS_IqcDecision__e`, SAP 회신 상태, REJECT → NCR 게이트웨이(기본 구현 To-Do), 협력사 통보, 포털 결과 조회(측정값·내부 코멘트 제외), 재개·정정(CORRECTED), 공장별 09:00 기한 알림.
5. **IQC-005**(W2지만 P5 NCR-002·006의 선행이라 여기): 수준 전환 규칙(정상 ↔ 강화 자동, 완화는 SQE 확인, 무검사는 결재), `QMS_IqcLevelService` Hold API(멱등). 데모 보강: LevelChange·LevelHold ExternalKey.

### 레인 D — SAP 연계 Salesforce 쪽(INT-004, INT-005)

1. **INT-004**: 입고 → 로트 upsert 계약 확인(IQC-002 수신 계약과 같은 키), 입고 취소 반영, 마스터 누락 시 기준정보 즉시 동기화 요청. Mule 흐름은 외부 트랙. Scratch Org에서는 계약 CSV를 두 번 적재해 멱등과 초기화 결과를 확인한다.
2. **INT-005**: `QMS_SapPostingRule__mdt`(공용 SAP 반영 규칙), SapSyncStatus 회신 필드 갱신 계약, 정정 보정. 회신은 CSV upsert로 흉내 낸다.

### 레인 X — 외부 트랙(INT-008)

SAP → Snowflake 공용 CORE 테이블(재고·출하·환율·표준가·BOM·배치). P6 4M 구 재고 조회, P5 클레임 의심 재고 쿼리 키의 원천이다.

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| Experience Cloud LWR 사이트 | SPP-001 메타데이터, `sf community publish` | P0 S-3 결과 |
| 포털 사용자 | 데모 Contact(18) 중 시나리오 협력사 담당자 → 포털 사용자(라이선스 수만큼) | 알파광학(S3), 감마LED(S2·S9), 베타폴리텍(S9) 우선 |
| 모바일 바코드 | 모바일 앱으로 IQC-003 화면 | 입고 라벨 바코드 샘플 출력 |
| 게이트웨이 바인딩 | 이 페이즈에는 기본 구현만(NCR·8D 바인딩은 P5) | |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| NCR(P5) | 게이트웨이 기본 구현 To-Do — DVQ-007 AC-3, IQC-004 AC-1이 바로 이 상태를 검증 |
| 측정기·검사원 자격 훅(P10) | 테스트 훅(IQC-003 AC-5), 운영 모드는 WARN(D6B-1) |
| SAP 입고·회신(Mule) | 계약 CSV upsert |
| 신뢰성 시스템(P10 INT-018) | RELIABILITY_SYS 라인은 편집 불가만 확인(DVQ-006 AC-3) |
| 인정시험·PPAP 원천 4M(P6) | `createFromSource`를 익명 Apex로 호출(가짜 원천 Id) |

## 6. 데모 데이터

```bash
scripts/demo/load_salesforce.sh qms-int --upto-phase 4
```

| 파일 | 객체 | 적재 | 비고 |
| --- | --- | --- | --- |
| 18 | Contact | 전부 | 16명 |
| 24~26 | 시험 항목·기준·기준 라인 | 전부 | 12 + 5 + 30 |
| 27~30 | 샘플링 계획·행, 수입검사 기준서·라인 | 전부 | 2 + 18 + 21 + 77 |
| 31, 32 | PPAP 요소·레벨 규칙 | 전부 | 18 + 5 |
| 48, 49 | 수입검사 로트·결과 | 로트 일부(NCR 연결 열은 P5) | 1,359 + 4,859 |
| 51, 52 | 수준 변경·Hold | 52 일부(NCR·안정화 원천은 P5·P6) | 5 + 6 |
| 55, 56, 63a | 인정시험 계획·라인 | 55 일부(4M 원천은 P6) | 15 + 98 |
| 57~59 | PPAP·요소 라인·제출 | 57 일부(4M 원천은 P6) | 18 + 324 + 18 |
| 63 | CMN_Document__c | 전부(P2에서 비웠던 부모 채움) | 98 |
| 83, 85 | 결재 요청·To-Do | 다시 실행해 PPAP·수준 변경·인정시험 대상 채움 | |

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G4-1 | 새 Org 배포·테스트·P4까지 적재 | 6.4절 | 실패 0 |
| G4-2 | BMW 헤드램프 품번으로 계획 마법사 | DVQ-002 AC-1, DVQ-004 AC-1~3 | BMW 세트 1순위, 필수 라인 면제 사유, 기한 위험 표시 |
| G4-3 | 같은 원천으로 `createFromSource` 2회, 결재선 | DVQ-005 AC-1·2 | 계획 1건, 두 팀장 병렬 합의 |
| G4-4 | 시험 FAIL DONE(NCR 미배포) | DVQ-007 AC-3 | 알림 2명, "불합격 부적합 등록" To-Do 1건 |
| G4-5 | 재시험 PASS 포함 종합 판정, CONDITIONAL | DVQ-008 AC-2·3 | PASS 제안, 품질본부장 단계 |
| G4-6 | 협력사 A 사용자 활성화, B 사용자의 A 로트 URL 접근 | SPP-001 AC-1·2, SEC-002 AC-3 | 포털 User·초대 메일, 권한 없음 |
| G4-7 | 포털 홈·문서 업로드 | SPP-002 AC-1·3·4 | 기한 경과 맨 위, 제출 후 업로드 차단, 공개 문서만 |
| G4-8 | 입고 계약 CSV 2회(SKIP 품번 포함, 기준서 없는 품번 포함) | IQC-002 AC-1·2·4, INT-004 | 로트 1건, 자동 합격, WAITING + To-Do |
| G4-9 | 모바일 바코드 → 검사 입력 → REJECT | IQC-003 AC-1·8, IQC-004 AC-1 | 화면 바로 열림, REJECT 제안, NCR 등록 To-Do |
| G4-10 | 최근 5로트 중 2로트 REJECT → 강화, 연속 5 ACCEPT → 정상 | IQC-005 AC-1·2 | LevelChange 기록 |
| G4-11 | S9 기대값 비교(성적서 항목 제외) | `expected/iqc_S9.json` | 수준 전환·Hold·불합격 로트, 월별 협력사별 합격률 일치 |
| G4-12 | PPAP 레벨 결정·체크리스트·협력사 제출·PSW 승인 | PPA-001 AC-1·3, PPA-003 AC-2·3, PPA-004 | 레벨 3, 요소 수, 제출 차단 규칙, 승인 후 PpapStatus |
| G4-13 | S3 데이터 확인 | 데모 S3 | `S3-QUAL` PASS, `S3-PPAP` 승인 상태 표시 |
| G4-14 | 회귀: P1~P3 게이트 시나리오 요약 | 6.4절 | 통과 |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D-5·D3-1 협력사 포털 라이선스(Customer Community Plus 가정) |
| 결정 | D2-1~D2-5(시험 실행 위치, 시험 원천, 결재 규칙, CONDITIONAL 후속, 협력사 제출 방식) |
| 결정 | D3-2(수입검사 판정 주체·SAP 회신), D3-3(대기열 예외 To-Do), D3-4(결과 라인 보존), D3-5(수준 전환), D3-6(PPAP 엔진 공용·요소 세트), D3-9(PPAP 거절 부품) |
| 결정 | D9-1·D9-2(SAP 이벤트 수신·반영 방식) |
| 결정 | CR-3 게이트웨이 프레임워크 분리 여부(분리하면 P3로) |
| 명세 | CR-2 IQC-004 선행에 DVQ-007 추가, CR-3 게이트웨이 프레임워크를 DVQ-007 본문에 |
| 명세 | review-pack 3절 이 페이즈 대상 약 24건(DVQ-002·003·005·006·007, IQC-001·002·003·005, PPA-001·002·003, SPP-002) |
| 명세 | 데모 보강(CR-6): DVQ-002·003, IQC-001·002·003·005, PPA-001·002, SPP-001·002 항목(3절 각 WI에 적음) |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| 게이트웨이 프레임워크가 늦어 레인 C가 IQC-004에서 멈춤 | DVQ-007 첫 PR로 프레임워크만 머지, 또는 CR-3 분리로 P3에서 미리 |
| 포털 라이선스 부족·LWR 제약 | 시나리오 협력사만, 포털 LWC는 `lightningCommunity__Page` 순수 LWC(SPP-001 에이전트 주의) |
| 수입검사 대량 데이터(로트 1,359·결과 4,859) 적재·화면 성능 | 대기열 50건 2초 기준을 이 데이터로 측정 |
| SAP 반영 방식 미정(D3-2·D9-2) | `QMS_SapPostingRule__mdt`로 공장별 규칙을 데이터로 두어 결정 뒤 값만 바꿈 |

## 10. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| | | | |
