# 남은 작업

QMS Vol.0~9 워크아이템은 모두 작성했다(STATUS.md). 작성 순서 = 메뉴 순서였고, 개발 순서는 각 WI의 선행 WI·Wave로 정한다.

| 순서 | 작업 | 메모 |
| --- | --- | --- |
| 1 | 사용자 검토·결정 | `review-pack.md`의 결정 101건. STATUS.md "먼저 결정하면 영향이 큰 항목"부터 |
| 2 | 변경 요청 반영 | review-pack 2·3절(Vol.0 70건, 이전 Vol. 64건). Vol.0·2·3은 검토 결과와 함께 반영 |
| 3 | 마스터 xlsx | 승인 WI만 `/build-master` |
| 4 | PMS 메뉴 | PMS RFP(P-1~71) 중 CMN-00에 없는 메뉴를 PMS-{모듈}-{기능}-{순번}으로 작성. QMS가 남긴 PMS 접점: P-21 액티비티 완료 조건(인정시험·체크포인트 hasOpenMandatory), P-28 협력사 부품개발 일정, P-49 문제점 ↔ 클레임 이벤트, LELE 반영(QMS_LeleApplicationService), SOP 시 초기유동 생성, PROJECT_ROLE 결재선 |
| 5 | PoC 준비 | 시나리오 1~6과 연결 WI(아래) 중 W1 범위로 데모 데이터·목(QMS-09-INT-003) 구성 |

## 참고: QMS PoC 시나리오(RFP 5.3)와 연결 WI

| 시나리오 | 연결 WI |
| --- | --- |
| 1 NCR Full Cycle | QMS-06-NCR-001~006, QMS-05-CLM-001~004(8D 엔진), QMS-08-AIQ-003~006(원인 추천), QMS-04-LEL-001·002 |
| 2 Claim 8D | QMS-05-CLM-001~011, QMS-08-AIQ-005(8D 초안) |
| 3 4M | QMS-06-4MC-001~007, QMS-02-DVQ-005·008, QMS-03-PPA-002~004, QMS-04-RPP-001·004, QMS-09-INT-012 |
| 4 VDA 6.3 | QMS-06-IAU-001~005, QMS-06-CAU-001~003 |
| 5 Dashboard·Q&A | QMS-07-DSH-001~014, QMS-08-AIQ-009·010 |
| 6 PMS LELE 추천 | QMS-04-LEL-001~005, QMS-08-AIQ-007·008 |
