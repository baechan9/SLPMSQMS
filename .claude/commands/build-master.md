---
description: 검토 승인된 WI로 마스터 워크아이템 xlsx를 만든다
---

1. `cd docs && python3 scripts/build_index.py`로 `docs/master/workitem-index.csv`를 최신화한다(상태 열은 기존 값 유지).
2. CSV에서 상태가 `승인`인 행만 골라 `docs/master/SL_QMS_WorkItem_Master.xlsx`를 만든다.
   - 시트 `WorkItems`: CSV 열 순서 그대로(L1 시스템 / L2 메뉴 / L3 기능 / L4 WI + RFP 추적·우선순위·Wave·플랫폼·유형·Fit-Gap·선행 WI·공수·출처·상태). 머리 행 고정, 자동 필터, 열 너비 조정.
   - 시트 `Summary`: L2 메뉴 × Wave별 WI 수·공수 합계, L3 기능별 합계.
   - 시트 `Traceability`: RFP ID(Q-##, P-##, NFR) 기준으로 WI를 펼친 표. QMS-01은 "CMN-00 이관" 행으로 남긴다.
3. 승인되지 않은 WI가 있으면 목록과 사유(결정 대기 항목)를 사용자에게 보고한다.
4. `STATUS.md` 이력에 생성 일자와 포함 WI 수·공수를 남긴다.
