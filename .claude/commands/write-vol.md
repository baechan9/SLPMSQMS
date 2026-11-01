---
description: 다음 QMS 메뉴 Vol. 워크아이템 문서를 작성한다
argument-hint: <메뉴번호 3~9>
---

QMS-0$ARGUMENTS 메뉴의 Vol.$ARGUMENTS 워크아이템 문서를 작성한다.

1. 상태 확인: `docs/docs/20-status/STATUS.md`, `docs/docs/20-status/backlog.md`에서 이 Vol.의 RFP 범위·기능코드·핵심 포인트와 미결 결정 항목을 확인한다.
2. 원천 읽기(`docs/docs/00-source/`, .md만): QMS RFP의 해당 Q 번호, Fit-Gap 분석서, 회사표준 개선 RFP 2종, 분석 노트. PMS RFP에서 대응 P 번호도 확인한다.
3. 재사용 확인: Vol.0(`vol0-cmn-common.md`) 공통 WI를 선행으로 참조하고 같은 기능을 다시 만들지 않는다. 이미 작성된 Vol.의 경계표·이벤트·인터페이스(예: NcrGateway, QualPlanEvent)와 맞춘다.
4. 작성: `docs/docs/10-workitems/vol{n}-qms0{n}-{영문 슬러그}.md`. 구성은 Vol.2와 같다 — 개요(도메인 정의, 선행 공통 WI, 다른 메뉴와의 경계표) → 업무 흐름 → 데이터 모델 개요(객체·상태값) → 기능별 WI → 검토 요청(WI 요약표, 결정 항목 D{n}-x 체크리스트, Vol.0 변경 요청 표, SL 확인 사실).
5. WI 형식: `docs/templates/workitem-template.md`. 메타 라인은 정확히 8항목을 ` · `로 구분, 공수 2~8 M/D, 표 셀 안 `|` 금지.
6. 검증: `cd docs && python3 scripts/build_index.py` 실행해 WARN이 없고 새 WI가 인덱스에 들어갔는지 확인한다.
7. `STATUS.md`의 Vol. 현황·결정 대기·Vol.0 변경 요청·SL 확인 사실을 갱신한다.
8. 사용자에게 요약(WI 수·공수·Wave 분포)과 결정 항목을 제시하고 검토를 요청한다.
