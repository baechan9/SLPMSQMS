# P2 보안·공통 업무 서비스·연계 기반

공장·협력사 데이터 격리, 공통 결재 엔진, To-Do·알림·문서 서비스, 공통 UI, SSO와 연계 표준을 만든다. W0의 나머지 13건이다. 이 페이즈가 끝나야 QMS WI를 착수할 수 있다(3.2절 예외).

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | 모든 QMS 메뉴가 호출할 공통 서비스(`CMN_ApprovalService`, `CMN_TodoService`, `CMN_NotificationService`, `CMN_DocumentService`, `CMN_SharingService`)와 격리 모델이 테스트 대상 객체로 검증된 상태 |
| 기간(4명 기준) | 누적 34영업일(P1 이후 약 17일) |
| 마일스톤 | 공장 격리, 결재·To-Do·알림·문서 서비스, 테스트 IdP SSO |
| 착수 조건 | P1의 해당 선행 WI `개발 완료`, 8절 결정 |
| 다음 페이즈로 당겨 착수 가능 | P3 중 UX-001(SEC-001), DSH-001(SEC-001·I18N-001), DWH-003·004(DWH-001·INT-001) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 13건 · 68 M/D · W0 13 · SF 트랙 12건 · 외부 트랙 1건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | CMN-00-SEC-002 | 공장·협력사 데이터 격리(공유 모델) | W0 | 6 | SF + 포털 | — | — |
| A2 | CMN-00-APV-001 | 결재 데이터 모델·상태 엔진·서비스 API | W0 | 8 | SF | SEC-002 | — |
| A3 | CMN-00-APV-002 | 결재선 템플릿·CFT Role 매핑 | W0 | 6 | SF | APV-001 | — |
| B1 | CMN-00-NTF-001 | 알림 서비스(메일·벨·모바일 푸시) | W0 | 4 | SF | — | — |
| B2 | CMN-00-TDO-001 | 통합 To-Do 모델·서비스 | W0 | 5 | SF | — | — |
| B3 | CMN-00-UX-003 | 공통 UI 컴포넌트(상태 진행바·코멘트 타임라인) | W0 | 5 | SF | — | — |
| B4 | CMN-00-DOC-001 | 문서·첨부·리비전 관리 | W0 | 7 | SF | SEC-002 | — |
| C1 | CMN-00-SEC-004 | 인증·암호화·플랫폼 보안 설정 | W0 | 3 | SF + DW 목 + 연계 시뮬 | — | SSO 거부(AC-1)는 테스트 IdP 연결 후 확인 |
| C2 | CMN-00-INT-001 | 연계 아키텍처·인터페이스 표준 | W0 | 6 | SF + 연계 시뮬 | SEC-004 | — |
| C3 | CMN-00-TDO-002 | 포탈 SSO | W0 | 3 | SF | SEC-004 | 테스트 IdP(다른 Org)로 검증 |
| C4 | CMN-00-INT-002 | HR 조직·임직원 연계 | W0 | 5 | SF + 연계 시뮬 | INT-001 | — |
| C5 | CMN-00-INT-003 | SAP 기준정보 연계 | W0 | 6 | SF + DW 목 + 연계 시뮬 | INT-001 | — |
| X1 | CMN-00-DWH-001 | Snowflake 품질 DW(QDW) 기반 | W0 | 4 | 외부 트랙 | SEC-004 | — |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

### 레인 A — 격리·결재(SEC-002 → APV-001 → APV-002)

임계 경로다. P1 레인 B(MDM-005)가 끝나는 날 SEC-002를 착수한다.

1. **SEC-002**: `CMN_UserPlantAccess__c`, 공장별 공개 그룹, `CMN_SharingConfig__mdt`(PlantField, SupplierField), `CMN_SharingService`, 재계산 배치(배치 크기 200). 내부 OWD Private 기준. 협력사 포털 공유(AC-3)는 포털이 생기는 P4에서 확인한다. review-pack 변경 요청 3건.
2. **APV-001**: 결재 요청·단계 객체, 상태 엔진(검토·합의 병렬·승인, 반려 시 SKIPPED·잠금 해제, 회수 제한, 재상신 Version), 콜백 인터페이스 `CMN_ApprovalCallback`(onSubmitted·onApproved·onRejected·onRecalled, canSubmit), 다른 공장 결재자 조회 공유(AC-4). 업무 객체가 아직 없으므로 테스트 대상 객체와 `@IsTest` 콜백으로 검증한다(P1 10절). 데모 보강: `CMN_ApprovalStep__c.ExternalKey__c`.
3. **APV-002**: 결재선 템플릿·단계, `CMN_RoleAssignment__c`(Role·Plant·유효 기간), `CMN_ApprovalLineResolver`, 필수 단계 삭제 차단, 결재선 기여 인터페이스 `CMN_ApprovalLineContributor`(Vol.2 변경 요청). review-pack 변경 요청 8건. 데모 보강: RoleAssignment·Template·TemplateStep `ExternalKey__c`.

### 레인 B — 업무 공통 서비스(TDO-001, NTF-001, UX-003 → DOC-001)

1. **TDO-001**: `CMN_Todo__c`(ExternalKey `{SourceType}/{SourceRecordId}/{AssigneeId}`), `CMN_TodoService.open/close/cancel`, 결재 단계 이벤트 → APPROVAL To-Do(AC-2는 APV-001 머지 후), 언어별 제목 렌더링. 이후 모든 "사람에게 시키는 일"이 이 서비스를 쓴다.
2. **NTF-001**: `CMN_NotificationService.send`, `CMN_NotificationRule__mdt`, 메일·벨(Custom Notification Type)·모바일 푸시, Queueable 분할. 문구는 Custom Label.
3. **UX-003**: `CMN_StatusFlow__mdt` + `cmnStatusPath`, `CMN_Comment__c` + `cmnCommentTimeline`(멘션 알림 → NTF-001, 25시간 수정 제한, 접근 권한 없는 레코드 코멘트 숨김).
4. **DOC-001**(SEC-002 머지 후): `CMN_Document__c`·`CMN_DocumentRevision__c`·`CMN_DocTemplate__c`, `cmnDocumentPanel`, 리비전 RELEASED·SUPERSEDED, 크기 제한, 해시 중복 경고. 데모 보강: `CMN_Document__c.ExternalKey__c`(업서트 키), 리비전의 외부 저장소 키는 `ExternalRef__c`로 이름 변경, `Supplier__c`·`SupplierVisible__c`(Vol.3 요청).

### 레인 C — 플랫폼 보안·SSO·연계 표준(SEC-004 → TDO-002, INT-001 → INT-002, INT-003)

1. **SEC-004**: 세션 2시간, My Domain, login.salesforce.com 로그인 차단(설정 메타데이터로 가능한지 P0 확인), `docs/security/baseline.md`(AC-3). Snowflake·Mule 항목은 외부 트랙과 함께 문서화만.
2. **TDO-002**: SAML SP 설정, JIT 핸들러(I18N-001) 연결, RelayState, 권한 없는 사용자 안내 페이지. **테스트 IdP**: 다른 Scratch Org(`qms-spike`)를 Identity Provider로 켜고 Connected App을 SP로 등록해 AC-1~3을 확인한다. 실제 포탈 IdP는 SIT에서 연결한다.
3. **INT-001**: `CMN_Interface__mdt`(카탈로그), `CMN_InterfaceLog__c`, 통합 사용자 PS `CMN_PS_Integration`, 모니터 리스트뷰(AC-3). Mule 공통 규약(재시도·DLQ)은 외부 트랙. review-pack 변경 요청 2건.
4. **INT-002**(Salesforce 쪽): `CMN_Employee__c` upsert 대상, 부서 → 임직원 → User 순서 갱신 규칙, RETIRED → User 비활성 + 부서장 알림. Mule 대신 CSV upsert로 흉내 낸다.
5. **INT-003**(Salesforce 쪽): 신규 협력사 품번 기본값(NORMAL, NOT_SUBMITTED), 자재 삭제 표시 → `CMN_ItemPlant__c.Status__c = PHASE_OUT`. CSV upsert로 흉내 낸다. review-pack 변경 요청 1건.

### 레인 X — 외부 트랙(DWH-001)

Snowflake `SL_QDW_DEV` 스키마(RAW·STG·CORE·MART·ML·SHARE)·웨어하우스·역할·Resource Monitor를 schemachange로 만든다. Scratch Org 작업 없음. P3의 L3 연결과 P4 이후 외부 트랙 WI의 전제다.

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| 내부 OWD Private, 공장 공개 그룹 | SEC-002 메타데이터 | 데모 공장 5개(KR01 등) |
| Custom Notification Type | NTF-001 메타데이터 | 벨 알림 |
| 메일 발송 | Deliverability 설정(P0 S-7 결과) | 메일 확인이 필요한 날만 켬 |
| 테스트 IdP | `qms-spike`에서 IdP 활성, 인증서, Connected App | 수동 설정 목록에 절차 기록 |
| 통합 사용자 | P0 S-5 결과대로 Integration 라이선스 또는 일반 사용자 + `CMN_PS_Integration` | |
| 테스트 대상 객체 | DEV-3 결정안(P1 10절) | APV·SEC·DOC·UX-003 테스트에 사용 |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| HR 연계(INT-002), SAP 기준정보(INT-003) | 계약 CSV를 `sf data upsert bulk`로 두 번 적재해 멱등·후처리 확인 |
| 포탈 IdP(TDO-002) | 다른 Scratch Org를 IdP로 |
| 수신자 300명(NTF-001 AC-3) | Scratch Org에서 사용자 300명을 만들 수 없으므로 수신자 해석을 Stub으로 바꿔 분할 로직만 테스트. 실제 규모는 SIT Sandbox |
| 60MB 파일(DOC-001 AC-3) | 크기 판정 로직 단위 테스트 + 화면에서 큰 파일로 1회 확인(테스트 힙 한도 때문에 Apex 테스트로 만들 수 없음) |
| Snowflake(DWH-001) | 외부 트랙. Scratch Org 영향 없음 |

## 6. 데모 데이터

```bash
scripts/demo/load_salesforce.sh qms-int --upto-phase 2
```

| 파일 | 객체 | 적재 | 비고 |
| --- | --- | --- | --- |
| 17, 17c | CMN_Employee__c | 전부 | 38명 + 사용자 연결 35명 |
| 19 | CMN_UserPlantAccess__c | 전부 | 만들지 않은 사용자 행은 건너뜀 |
| 20 | CMN_RoleAssignment__c | 전부 | 없는 사용자는 E1901로 |
| 21, 22 | CMN_ApprovalTemplate__c·Step__c | 전부 | 10 + 16 |
| 64, 64a | CMN_DocumentRevision__c, CMN_Document__c 갱신 | 전부 | |
| 84 | CMN_ApprovalStep__c | 전부 | 83 다음 |
| 63 | CMN_Document__c | 일부 | 부모(인정시험 라인)는 P4에서 채움 |
| 83 | CMN_ApprovalRequest__c | 일부 | 대상(PPAP·NCR·4M 등)은 P4~P6에서 채움 |
| 85 | CMN_Todo__c | 일부 | 원천 레코드는 P4~P10에서 채움 |

83·85는 대상 레코드 없이 넣으면 검증 규칙에 걸릴 수 있다. 실패한 행은 대상 페이즈에서 같은 명령을 다시 실행해 채운다.

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G2-1 | 새 Org 배포·RunLocalTests | 6.4절 | 실패 0, 커버리지 85% |
| G2-2 | KR01만 가진 사용자로 CN01 테스트 대상 레코드 조회(리스트뷰·검색) | SEC-002 AC-1 | 보이지 않음 |
| G2-3 | 테스트 대상 레코드 공장 변경 | SEC-002 AC-2 | 이전 공장 그룹 공유 삭제, 새 공장 공유 생성 |
| G2-4 | 10,000건 재계산 배치 | SEC-002 AC-4 | 거버너 오류 없이 완료 |
| G2-5 | 검토 → 합의 2명 병렬 → 승인, 1명만 합의 | APV-001 AC-1 | 승인 단계 WAITING 유지 |
| G2-6 | 2단계 반려, 재상신 | APV-001 AC-2·6 | REJECTED, 3단계 SKIPPED, 잠금 해제, Version 2 생성·Version 1 이력 유지 |
| G2-7 | 데모 Role로 KR01·CN01 결재선 해석, Role 미등록 공장 | APV-002 AC-1·2 | 공장별 결재자, 미지정 메시지로 차단 |
| G2-8 | 결재 단계 도래 → To-Do, 승인 → DONE, 같은 Spec 2회 | TDO-001 AC-1·2 | To-Do 1건, 상태 전환 |
| G2-9 | ko·en 수신자 알림 | NTF-001 AC-1 | 각자 언어로 메일·벨 1건 |
| G2-10 | 리비전 2 RELEASED, RELEASED 파일 교체 | DOC-001 AC-1·2 | Rev1 SUPERSEDED, 교체 차단 |
| G2-11 | 코멘트 멘션, 25시간 지난 코멘트 수정 | UX-003 AC-2·3 | 알림 1건, 수정 차단 |
| G2-12 | 테스트 IdP로 SSO, 레코드 링크 RelayState, 비활성 사용자 | TDO-002 AC-1~3 | 추가 로그인 없음, 원래 레코드로 이동, 안내 페이지 |
| G2-13 | 임시 사용자 RETIRED 동기화 | INT-002 AC-1 | User 비활성, 부서장 알림 1건 |
| G2-14 | 신규 협력사 품번·자재 삭제 표시 CSV 적재 2회 | INT-003 AC-1·2, INT-001 AC-1 | 기본값·PHASE_OUT, 건수 불변 |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D-2 표준 Approval Process 대신 공통 결재 엔진 |
| 결정 | D-7 대용량·통제 문서 저장소(SharePoint 연계 여부) — DOC-001 |
| 결정 | D-9 공장 데이터 격리 수준 — SEC-002(뒤집히면 P5 이후 지식 객체 조회 규칙도 바뀜) |
| 결정 | D-1 단일 Org — INT-001 카탈로그·PMS 연계 전제 |
| 결정 | TDO-002 오픈 이슈: 포탈 IdP 제품의 SAML 지원(OIDC만이면 Auth Provider 방식으로 바뀜) |
| 명세 | review-pack 2절 Vol.0 변경 요청 22건: APV-002 8, SEC-002 3, DWH-001 3, INT-001 2, SEC-004 2, DOC-001 1, INT-003 1, NTF-001 1, TDO-001 1 |
| 명세 | 데모 보강(CR-6): APV-001 ApprovalStep ExternalKey, APV-002 RoleAssignment·Template·TemplateStep ExternalKey, DOC-001 ExternalKey·ExternalRef 이름 변경·Supplier 필드, TDO-001 ExternalKey의 Id 치환 규칙 |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| 결재 엔진(APV-001, 8 M/D)이 임계 경로에서 길어짐 | AC별 테스트 먼저, 병렬 합의·회수·재상신을 단계적으로 머지. 결재 UI(APV-003)는 P3이므로 여기서는 서비스·테스트만 |
| 공유 재계산 성능 | AC-4를 10,000건으로 실제 측정, 배치 크기 200 고정 |
| D-9가 바뀜(해외 공장 조회 허용 등) | `CMN_SharingConfig__mdt` 설정으로 흡수되게 설계 |
| SSO를 실제 IdP로 확인 못 함 | 테스트 IdP로 흐름 검증, 실제 IdP는 SIT 게이트 항목으로 넘김 |

## 10. 게이트 기록

| 날짜 | Org | 결과 | 남은 문제 |
| --- | --- | --- | --- |
| | | | |
