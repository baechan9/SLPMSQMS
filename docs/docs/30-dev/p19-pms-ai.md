# P19 PMS AI

PMS 에이전트 기반과 자연어 Q&A, 마일스톤 기반 일정 추천, 일정·리소스 조기경보, 산출물 초안, SOR 문서 분해, 산출물 이상 징후 탐지, 산출물 개정 영향도 분석을 만든다. 전부 W2이며 공통 AI(AI-002·003·005)와 QMS AI 운영 자산(Vol.8 AIQ — QMS 트랙 P12)을 재사용하므로, 착수 시점은 QMS 트랙 P12 진행에 묶인다([개발 플랜](dev-plan.md) 4.3절). 명세는 [Vol.P5](../10-workitems/volp5-pms10-11-dashboard-ai.md)·[Vol.P4](../10-workitems/volp4-pms08-09-risk-gate.md)·[Vol.P3](../10-workitems/volp3-pms05-06-cost-deliverable.md)이다.

## 1. 개요

| 항목 | 내용 |
| --- | --- |
| 목표 | `SL Project Assistant` PMS 토픽·정책, Q&A(Action + Cortex Analyst), 일정 기간 추천·조정안(채택 이력·정확도), 조기경보(프로젝트·부서 점수), 산출물 초안(같은 고객 예시만), SOR 분해 후보, 이상 징후 "검토 필요" 표시, 개정 영향 분석 |
| 기간(기본 인원) | PMS 트랙 마지막(처음부터 약 280영업일 — QMS AI P12 이후) |
| 마일스톤 | PMS AI 5종(RFP 가점 항목) 완성 |
| 착수 조건 | CMN-00-AI-001·004(기반), AI-002·003·005(QMS 트랙 P12), QMS-08-AIQ-001·006·009·010·013·016(P12 — 평가·출시 기준·프롬프트 버전·사용량 운영), P18 DSH-001 |
| 다음 페이즈로 당겨 착수 가능 | 없음(P20은 AI와 무관하게 P17 뒤 착수 가능 — 트랙 안 순서상 P18 종료 후) |

## 2. WI 착수 순서

<!-- BEGIN:WI-TABLE -->
WI 7건 · 43 M/D · W2 7 · SF 트랙 7건 · 외부 트랙 0건

| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | PMS-11-AIP-004 | PMS 자연어 Q&A 범위 | W2 | 6 | SF + DW 목 + 연계 시뮬 + Agentforce | — | PMS 에이전트 기반(다른 AIP의 선행) / QMS 선행: QMS-08-AIQ-001(P12)·CMN-00-AI-005(P12)·QMS-08-AIQ-009(P12)·CMN-00-AI-002(P12)·QMS-08-AIQ-013(P12)·QMS-08-AIQ-010(P12)·QMS-08-AIQ-016(P12) |
| A2 | PMS-11-AIP-001 | 마일스톤 기반 일정 자동 생성·조정 추천 | W2 | 8 | SF + DW 목 + 연계 시뮬 + Agentforce | AIP-004 | QMS 선행: QMS-08-AIQ-006(P12)·QMS-08-AIQ-016(P12) |
| A3 | PMS-11-AIP-003 | 일정·리소스 조기경보 | W2 | 8 | SF + DW 목 + 연계 시뮬 + Agentforce | AIP-004 | QMS 선행: QMS-08-AIQ-006(P12) |
| B1 | PMS-06-DLV-004 | 산출물 개정·영향도 분석 | W2 | 6 | SF | — | QMS 선행: CMN-00-AI-003(P12) |
| B2 | PMS-09-GAT-005 | 산출물 이상 징후 탐지(데이터 대조·AI) | W2 | 5 | SF + Agentforce | — | QMS 선행: CMN-00-AI-002(P12)·QMS-02-DVQ-005(P4) |
| B3 | PMS-11-AIP-002 | 산출물 초안 작성 | W2 | 5 | SF + Agentforce | AIP-004 | QMS 선행: CMN-00-AI-002(P12)·QMS-08-AIQ-016(P12) |
| B4 | PMS-11-AIP-005 | SOR 문서 분해 초안 | W2 | 5 | SF + Agentforce | AIP-004 | QMS 선행: CMN-00-AI-002(P12)·QMS-08-AIQ-016(P12) |
<!-- END:WI-TABLE -->

## 3. 레인별 작업

### 레인 A — 에이전트·일정 AI(AIP-004 → AIP-001, AIP-003)

1. **AIP-004**: PMS 토픽·공통 지시·권한 셋·정책 행(DP5-15 답변 범위 — 비용 금지 DP5-3), 업무 현황은 파라미터형 Action, 추세·비율은 Cortex Analyst(AI-005 BR-1). 다른 AIP의 기반.
2. **AIP-001**: 완료 프로젝트 실제 소요로 기간 추천, 고객 마일스톤 달성 가능성, 지연 시 압축·병행 조정안(`simulate` — WBS-006 영향 시뮬레이션 재사용), 추천 vs 기준선 vs 실적 비교(DP5-7). 기록은 `CMN_AiRecommendation__c`(AI-004, `ContextRecordId__c`·`RunKey__c` 추가 — Vol.0 변경 요청).
3. **AIP-003**: 조기경보(주경로 여유 감소 속도·기한 경과·Gate 준비 부족·과부하 신호 → 매일 점수, "급히 나빠진" 프로젝트·부서만 — DP5-8), `PMS_EarlyWarning__c`.

### 레인 B — 문서 AI(AIP-002, AIP-005, GAT-005, DLV-004)

1. **AIP-002**: 산출물 초안(표준 양식 구조 + Input 산출물 + SOR + 같은 고객 유사 승인본 — DP5-16), 산출물 레일 AI 패널(UseCase PMS_DELIVERABLE_DRAFT).
2. **AIP-005**: SOR 문서 분해 후보 `PMS_SorCandidate__c`(DP5-9) → 사람이 SOR-001 요구사항으로 확정. UseCase PMS_SOR_EXTRACT(Vol.0 변경 요청).
3. **GAT-005**: 이상 징후 — 규칙 대조(같은 해시·빈 양식·다른 시스템 기록 없음) + AI 내용 불일치 보조, 자동 불합격 금지(DP4-10), `PMS_DeliverableAnomaly__c`·`PMS_AnomalyRule__mdt`. UseCase PMS_DOC_ANOMALY.
4. **DLV-004**: 산출물 개정·영향도(하류 산출물·후행 액티비티·연계 시스템·통과 Gate), `PMS_ImpactItem__c`(DP3-12), 개정 중 이전 승인본 유효(DP3-11). AI-003 버전 비교 재사용.

## 4. Scratch Org 준비

| 항목 | 방법 | 비고 |
| --- | --- | --- |
| Agentforce | Scratch 기능 정의(dev-plan 5.3절), 에이전트 활성화는 `sf agent` | P12와 같은 준비 |
| Data Cloud | D-4 결정 범위(AI-002) — Sandbox | |
| AI 목 | `CMN_PrototypeMocks` AI 응답 | 화면 검토용 |

## 5. 목·대체

| 의존 | 대체 |
| --- | --- |
| 과거 완료 프로젝트 실적(기간 추천 학습) | DD-P1 종료 프로젝트 1건 + 생성 데이터(Sandbox) |
| Cortex Analyst 시맨틱 모델 | QMS AIQ-010 방식 재사용, Scratch는 목 응답 |
| 문서 텍스트 추출 | `CMN_DocTextService`(Vol.P5 신설 제안) |

## 6. 데모 데이터

AI 기대값(질문 10개·정답 목록)을 DD-P1에 더한다. 산출물 초안 예시는 같은 고객 데모 프로젝트의 승인본만 쓴다. 실제 고객 문서·회사표준 원문은 넣지 않는다.

## 7. 게이트 시나리오

| 번호 | 확인 | 근거 | 통과 기준 |
| --- | --- | --- | --- |
| G19-1 | 새 Org 배포·테스트·P19까지 적재 | 6.4절 | 실패 0 |
| G19-2 | "향후 1개월 안에 위험한 프로젝트는?" 등 질문 10개 | AIP-004 AC | 기대값 일치, 비용 미포함 |
| G19-3 | 기간 추천 → 채택·제외 → 기준선·실적 비교 | AIP-001 AC | AI 추천 기록 |
| G19-4 | 조기경보 점수·경보 대상(프로젝트·부서) | AIP-003 AC | |
| G19-5 | 산출물 초안·SOR 분해 후보 → 사람 확정 | AIP-002·005 AC | 확정 전 업무 데이터 미변경 |
| G19-6 | 같은 해시 산출물 → "검토 필요", 개정 → 영향 항목 | GAT-005, DLV-004 AC | 자동 불합격 없음 |
| G19-7 | 회귀: P14~P18 요약 | 6.4절 | 통과 |

## 8. 선결 결정·명세 보강

| 구분 | 항목 |
| --- | --- |
| 결정 | D-4(Data Cloud), D-10(AI 공통), DP5-7~10·15·16, DP4-10, DP3-11·12 |
| Vol.0 변경 | AI-004 `ContextRecordId__c`·`RunKey__c`, UseCase PMS_SCHEDULE_ADJUST·PMS_SOR_EXTRACT·PMS_DOC_ANOMALY, `CMN_DocTextService` |

## 9. 위험

| 위험 | 대응 |
| --- | --- |
| QMS AI(P12) 지연으로 PMS AI 전체가 밀림 | PMS 1차 오픈 범위 밖(W2)이라 오픈에 영향 없음. RFP 가점 시연은 PoC 경로(dev-plan 9.3절)로 별도 |
| 추천 정확도 근거 부족(과거 데이터 적음) | 표준 기간 대비 비교만 먼저, 실적 축적 후 재평가 |

## 10. 게이트 기록

| 일자 | Org | 결과 | 비고 |
| --- | --- | --- | --- |
