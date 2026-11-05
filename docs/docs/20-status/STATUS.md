# 진행 상태 (기준일 2026-11-05)

## Vol. 현황

전 메뉴 작성 완료, 전부 사용자 검토 대기다.

화면 구성 기준은 `docs/10-workitems/screen-strategy.md`(2026-11-05)다. WI별 화면 유형(T1~T8)은 `docs/30-dev/screen-map.csv`의 `화면유형` 열에 있다.

| Vol. | 메뉴 | 파일 | WI | 공수(M/D) | Wave | 결정 |
| --- | --- | --- | --- | --- | --- | --- |
| Vol.0 | CMN-00 공통 | docs/10-workitems/vol0-cmn-common.md | 49 | 226 | W0 28 · W1 14 · W2 7 | D-1~10, DS-1~8 |
| Vol.1 | QMS-01 일반 | — (CMN-00으로 이관) | 0 | 0 | — | 번호 처리 방식 확인 |
| Vol.2 | QMS-02 개발 품질 | docs/10-workitems/vol2-qms02-dev-quality.md | 10 | 51 | W1 8 · W2 2 | D2-1~5 |
| Vol.3 | QMS-03 부품/협력사 품질 | docs/10-workitems/vol3-qms03-part-supplier-quality.md | 20 | 103 | W1 10 · W2 9 · W3 1 | D3-1~9 |
| Vol.4 | QMS-04 제품/공정 품질 | docs/10-workitems/vol4-qms04-product-process-quality.md | 26 | 143 | W1 13 · W2 13 | D4-1~10 |
| Vol.5 | QMS-05 고객 품질(8D 공용 엔진 포함) | docs/10-workitems/vol5-qms05-customer-quality.md | 18 | 102 | W1 13 · W2 5 | D5-1~10 |
| Vol.6a | QMS-06 4M 변경·부적합 | docs/10-workitems/vol6a-qms06-change-ncr.md | 16 | 87 | W1 12 · W2 4 | D6A-1~10 |
| Vol.6b | QMS-06 한도견본·교육·측정기·MSA·분석실 | docs/10-workitems/vol6b-qms06-measurement-lab.md | 21 | 104 | W2 21 | D6B-1~9 |
| Vol.6c | QMS-06 협력사 실적·개선·심사·인증 | docs/10-workitems/vol6c-qms06-supplier-improvement-audit.md | 20 | 107 | W1 8 · W2 12 | D6C-1~11 |
| Vol.7 | QMS-07 Dashboard | docs/10-workitems/vol7-qms07-dashboard.md | 16 | 72 | W1 11 · W2 5 | D7-1~8 |
| Vol.8 | QMS-08 AI | docs/10-workitems/vol8-qms08-ai.md | 16 | 91 | W1 10 · W2 4 · W3 2 | D8-1~11 |
| Vol.9 | QMS-09 연계 | docs/10-workitems/vol9-qms09-integration.md | 21 | 106 | W1 13 · W2 5 · W3 3 | D9-1~8 |
| 합계 | | | 233 | 1,192 | W0 28(122) · W1 112(618) · W2 87(426) · W3 6(26) | 109건 |

공수는 AI 코딩 보조를 전제로 한 개발자 1인 기준이며 분석·통합테스트·원천 시스템 측 개발(SL 범위)은 제외다.

## 검토 방법

- **검토 패키지**: 결정 109건(화면 전략 DS-1~8 포함), Vol.0 변경 요청 70건, Vol.2·3 및 이전 Vol. 변경 요청 64건을 `docs/20-status/review-pack.md`에 모았다(자동 생성). Vol. 문서를 고친 뒤 `cd docs && python3 scripts/build_review_pack.py`로 다시 만든다.
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
