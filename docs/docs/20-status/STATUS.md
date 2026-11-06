# 진행 상태 (기준일 2026-11-06)

## Vol. 현황

QMS 전 메뉴와 PMS 전 메뉴(Vol.P1~P6, 2026-11-06) 작성 완료, 전부 사용자 검토 대기다. PMS 메뉴 간 계약(번호·객체·이벤트·PSG·QMS 접점·설계 결정 D-P1~P9)은 `docs/10-workitems/pms-architecture.md`가 최종이다.

화면 구성 기준은 `docs/10-workitems/screen-strategy.md`(2026-11-05)다. WI별 화면 유형(T1~T8)은 `docs/30-dev/screen-map.csv`의 `화면유형` 열에 있다.

| Vol. | 메뉴 | 파일 | WI | 공수(M/D) | Wave | 결정 |
| --- | --- | --- | --- | --- | --- | --- |
| Vol.0 | CMN-00 공통 | docs/10-workitems/vol0-cmn-common.md | 50 | 233 | W0 28 · W1 15 · W2 7 | D-1~11, DS-1~8 |
| Vol.1 | QMS-01 일반 | — (CMN-00으로 이관) | 0 | 0 | — | 번호 처리 방식 확인 |
| Vol.2 | QMS-02 개발 품질 | docs/10-workitems/vol2-qms02-dev-quality.md | 10 | 51 | W1 8 · W2 2 | D2-1~5 |
| Vol.3 | QMS-03 부품/협력사 품질 | docs/10-workitems/vol3-qms03-part-supplier-quality.md | 20 | 103 | W1 10 · W2 9 · W3 1 | D3-1~9 |
| Vol.4 | QMS-04 제품/공정 품질 | docs/10-workitems/vol4-qms04-product-process-quality.md | 26 | 143 | W1 13 · W2 13 | D4-1~10 |
| Vol.5 | QMS-05 고객 품질(8D 공용 엔진 포함) | docs/10-workitems/vol5-qms05-customer-quality.md | 18 | 102 | W1 13 · W2 5 | D5-1~10 |
| Vol.6a | QMS-06 4M 변경·부적합 | docs/10-workitems/vol6a-qms06-change-ncr.md | 16 | 87 | W1 12 · W2 4 | D6A-1~10 |
| Vol.6b | QMS-06 한도견본·교육·측정기·MSA·분석실 | docs/10-workitems/vol6b-qms06-measurement-lab.md | 21 | 104 | W2 21 | D6B-1~9 |
| Vol.6c | QMS-06 협력사 실적·개선·심사·인증 | docs/10-workitems/vol6c-qms06-supplier-improvement-audit.md | 20 | 104 | W1 8 · W2 12 | D6C-1~11 |
| Vol.7 | QMS-07 Dashboard | docs/10-workitems/vol7-qms07-dashboard.md | 16 | 72 | W1 11 · W2 5 | D7-1~8 |
| Vol.8 | QMS-08 AI | docs/10-workitems/vol8-qms08-ai.md | 16 | 91 | W1 10 · W2 4 · W3 2 | D8-1~11 |
| Vol.9 | QMS-09 연계 | docs/10-workitems/vol9-qms09-integration.md | 21 | 106 | W1 13 · W2 5 · W3 3 | D9-1~8 |
| Vol.P1 | PMS-02 프로젝트 정보, PMS-03 자원 | docs/10-workitems/volp1-pms02-03-project-resource.md | 11 | 57 | W1 9 · W2 2 | DP1-1~16 |
| Vol.P2 | PMS-04 일정, PMS-07 Task·Activity | docs/10-workitems/volp2-pms04-07-schedule-activity.md | 15 | 84 | W1 14 · W2 1 | DP2-1~13 |
| Vol.P3 | PMS-05 비용, PMS-06 산출물 | docs/10-workitems/volp3-pms05-06-cost-deliverable.md | 9 | 50 | W1 6 · W2 3 | DP3-1~15 |
| Vol.P4 | PMS-08 리스크·문제점, PMS-09 Gate | docs/10-workitems/volp4-pms08-09-risk-gate.md | 11 | 55 | W1 8 · W2 3 | DP4-1~11 |
| Vol.P5 | PMS-10 대시보드·보고, PMS-11 AI | docs/10-workitems/volp5-pms10-11-dashboard-ai.md | 9 | 56 | W1 4 · W2 5 | DP5-1~16 |
| Vol.P6 | PMS-12 연계·결재, PMS-13 성과·변경 | docs/10-workitems/volp6-pms12-13-integration-performance.md | 10 | 51 | W1 2 · W2 7 · W3 1 | DP6-1~15 |
| PMS-01 | PMS 일반 | — (CMN-00으로 이관: I18N-001, UX-001·002) | 0 | 0 | — | — |
| 소계 QMS·공통 | | | 234 | 1,196 | | 110건 |
| 소계 PMS | | | 65 | 353 | W1 43(225) · W2 21(124) · W3 1(4) | 86건 + D-P1~9 |
| 합계 | | | 299 | 1,549 | W0 28(122) · W1 156(855) · W2 108(542) · W3 7(30) | 196건 + D-P1~9 |

공수는 AI 코딩 보조를 전제로 한 개발자 1인 기준이며 분석·통합테스트·원천 시스템 측 개발(SL 범위)은 제외다.

## 검토 방법

- **검토 패키지**: 결정 196건(화면 전략 DS-1~8, PMS DP1~DP6 86건 포함 — PMS 공통 설계 결정 D-P1~P9는 `pms-architecture.md` 11절), Vol.0 변경 요청 135건, Vol.2·3 및 이전 Vol. 변경 요청 64건, PMS → QMS Vol. 변경 요청 43건, PMS 계약·PMS Vol. 사이 변경 요청 146건을 `docs/20-status/review-pack.md`에 모았다(자동 생성). Vol. 문서를 고친 뒤 `cd docs && python3 scripts/build_review_pack.py`로 다시 만든다.
- **Vol. 간 계약**: 객체·서비스·이벤트 소유와 게이트웨이 등록부는 `docs/10-workitems/interfaces.md`가 최종이다.
- **형식 검사**: `cd docs && python3 scripts/validate_vol.py docs/10-workitems/vol*.md`. 현재 ERROR는 Vol.0 CMN-00-AI-002·AI-004의 우선순위 값에 주석이 붙은 2건뿐이다(템플릿은 필수/권장만 허용, Vol.0 검토 시 정리).

**먼저 결정하면 영향이 큰 항목**(여러 Vol.의 BR이 이 가정에 기대고 있음)

| 결정 | 영향 |
| --- | --- |
| D-1 PMS·QMS 단일 Org | Vol.9 INT-021(다른 Org PMS 디지털 스레드) 착수 여부, LELE 연계 방식 |
| D-4 Data Cloud 범위 | Vol.8 사례 검색 엔진(D8-1 Cortex Search), AI-002 문서 검색 |
| D-5 / D3-1 협력사 포털 라이선스 | SPP 전체, 협력사 제출 화면(Vol.2·3·5·6a·6c) |
| D-9 공장 데이터 격리 | 지식 객체 전사 조회(Vol.4 D4-5, Vol.5 D5-4) |
| D2-4 CONDITIONAL 판정 | 4M 적용 허용(Vol.6a D6A-3) |
| D3-2 / D9-2 SAP 회신 방식 | 수입검사·출하검사·NCR 처분의 SAP 반영(Vol.9 INT-005·006·007) |
| D4-1 SPC 계산 위치 | MES SPC 보유 시 Vol.4 SPC 범위 축소 |
| D5-1 8D 공용 엔진 | NCR·클레임·심사 지적 대책 구조(Vol.5·6a·6c) |
| D6C-2 VDA 6.3 질문지 저작권 | 고객 심사 대응(CAU) 데이터 범위 |
| D8-8 중국 공장 AI 사용 | Vol.8 전 기능의 공장 범위 |
| D-P1 신제품개발 단계·Gate 모델 | PMS 표준 WBS·Gate 정의·평가표(회사표준 개정 26.11~27.04 결과를 데이터로) |
| D-P2 간트 자산 | PMS 일정 Viewer(연구소 자산 vs 외부 JS 없는 경량 간트) |
| DEV-5 팀 구성 | QMS 4명이면 QMS 1차 오픈 범위가 2027-12 종료(4분기 오픈에 SIT 여유 없음). 권고 QMS 5명·PMS 3명(`docs/30-dev/dev-plan.md` 9.1절) |
| CR-18 결재 엔진 보완 | Master-Detail 하위 대상 상신 예외·DRAFTER_MANAGER·PROJECT_ROLE 해석 — PMS 결재 전부(Vol.P1·P3·P6가 같이 발견) |

## 검토 후 처리 순서

1. 결정 반영: 각 Vol.의 해당 BR을 고치고, review-pack 2·3절의 변경 요청을 Vol.0·2·3 및 해당 Vol. 본문에 반영한다.
2. 반영 후 `validate_vol.py`·`build_index.py`·`build_review_pack.py`를 다시 돌린다.
3. 승인 WI의 상태를 `승인`으로 바꾸고 `/build-master`로 마스터 xlsx를 만든다.

## SL 확인 필요 사실 정보

각 Vol. 검토 요청 절의 "SL 확인이 필요한 사실 정보"에 있다. 여러 Vol.에 걸친 핵심은 SAP(QM 사용 여부, Event Mesh, 이동 유형), MES(SPC 기능, 측정·생산·EOL·로트 데이터 구조), 필드클레임 시스템, 신뢰성 시스템, 부품개발시스템(PPAP·협력사 일정), 측정기 관리 시스템, 포탈 IdP·To-Do 연동, HR 연계, 회사표준 개정 일정(신제품개발 26.11~27.04, 양산품질 27년), OEM별 CSR(클레임·PPAP·4M 통보·감사 기준), Snowflake 리전과 Cortex 기능, Agentforce·Data Cloud 라이선스다.

## 이력

- 2026-11-01 Vol.0, Vol.2 작성(claude.ai), Claude Code로 이관.
- 2026-11-01 Vol.3 QMS-03 부품/협력사 품질 작성(20 WI, 103 M/D).
- 2026-11-01 Vol.4~9 작성. Vol. 간 계약(interfaces.md)을 먼저 정하고 메뉴별로 병렬 작성한 뒤 두 차례 정합(게이트웨이 등록부 통일, 이벤트·KPI·쿼리 열 계약 맞춤). 검사·검토 패키지 스크립트 추가. 전체 227 WI, 1,162 M/D.
- 2026-11-05 화면 전략(`screen-strategy.md`) 반영. 공통 화면 부품 Vol.0 UX-004~009 6개(35 M/D) 추가, Vol.2 DVQ-004·007을 공통 그리드·입력 셸로 바꿔 5 M/D 감소, 결정 DS-1~8 추가. 전체 233 WI, 1,192 M/D.
- 2026-11-05 DS-7 결정(사용자): Lightning Console 라이선스를 쓰지 않는다. 모든 앱은 표준 내비게이션, 전문가 앱 이름은 `SL QMS 품질 업무`(`SL_QMS_Quality`).
- 2026-11-06 표준 질문지 공통 템플릿 CMN-00-QNR-001 추가(Vol.0 50 WI, 233 M/D, 결정 D-11), Vol.6c IAU-001이 이를 쓰도록 축소(104 M/D). PMS 공통 설계 `pms-architecture.md`(D-P1~P9, D-P8 Enterprise Scratch 적용).
- 2026-11-06 PMS Vol.P1~P6 작성(65 WI, 353 M/D, 결정 DP1~DP6 86건). 전체 299 WI, 1,549 M/D. 개발 일정에 PMS 트랙(P14~P20, P3 뒤 QMS와 병렬)을 넣고 연관성 분석(트랙 간 선행 30건, PMS 1차 오픈 범위가 끌고 오는 QMS WI 14건), 대시보드 공용 라이브러리(QMS-07-DSH-001~004)를 P7에서 기반 P3로 당김, 명세 변경 요청 CR-13~18(`docs/30-dev/dev-plan.md` 4·9·10절).
