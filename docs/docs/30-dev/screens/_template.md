# A{n} {메뉴} 화면 인벤토리

화면 우선 플랜 4.1 1단계 산출물. 묶음 WI의 "화면/UX"·"데이터 모델"·"권한" 절을 읽고 화면을 빠짐없이 적는다. 화면 유형과 공통 부품은 [화면 전략](../../10-workitems/screen-strategy.md)을 따른다.

- 묶음 브랜치: `ui/a{n}-{메뉴}`
- 검토 Org 준비: `scripts/org/build-scratch.sh qms-int --reuse --bundle A{n} --review`
- 진행 상태: `screen-map.csv`의 `화면상태`(대기 → 화면 개발 중 → 화면 완료 → 검토 중 → 승인 / 재작업)

## 1. 화면 목록

| 화면 ID | 화면 | 유형(T1~T8) | 객체 | 컴포넌트·공통 부품 | 진입 경로 | 페르소나 | 모바일 | 상태 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| {WI-ID}-S01 | {화면 이름} | T1 업무 레코드 | {객체 API명} | 표준 레코드 페이지(UX-004 생성기), ui-rules(UX-005) | SL QMS 품질 업무 → 메뉴 허브 → {타일} | E1102 품질 엔지니어 | 카드(컴팩트 레이아웃) | 화면 완료 |
| {WI-ID}-S02 | {화면 이름} | T2 그리드 | {행 객체} | `cmnEditableGrid` gridKey={GridKey}, Provider {클래스} | {부모 레코드} → 현재 단계 탭 | | 읽기 전용 카드 | |
| {WI-ID}-S03 | {화면 이름} | T3 현장 입력 | {객체} | `cmnFieldEntryShell`, Provider {클래스} | 현장 입력 탭 `c__recordId` / 화면 액션 | E1104 수입검사원 | 순차 모드 | |
| {WI-ID}-S04 | {화면 이름} | T4 체크리스트 | {객체} | `cmnChecklistRunner`, Provider {클래스} | 체크리스트 탭 `c__recordId` | | 요소 선택 목록 | |

유형: T1 업무 레코드, T2 그리드, T3 현장 입력, T4 체크리스트, T5 대시보드·위젯, T6 기준정보·설정, T7 포털, T8 메뉴 허브·앱 페이지.

## 2. 업무 동작 자리 구현(A단계)

| 화면 ID | 버튼·동작 | 서비스 메서드(명세 시그니처) | A단계 동작 |
| --- | --- | --- | --- |
| {WI-ID}-S01 | {판정·처분·발행…} | `QMS_{도메인}Service.{메서드}` | `CMN_Prototype.notYetAvailable()` 안내 |

B단계 완료 조건: `python3 scripts/ci/check-prototype-stubs.py --menu QMS-{nn}` 참조 0건.

## 3. Snowflake·AI 목 응답

| 화면 ID | 조회 키·AI 응답 | 목 원본 | 예시 데이터 표시 |
| --- | --- | --- | --- |
| {WI-ID}-S05 | {QueryKey} | `data/demo/mocks/dwh/{QueryKey}/ok.json` | `cmnPrototypeBadge` |

## 4. 데모 데이터

| 객체 | 원본 | 건수 | 비고 |
| --- | --- | --- | --- |
| {객체} | `data/demo/salesforce/{NN}_{객체}.csv` 또는 `data/demo/proto/{객체}.csv` | | RFP 원문 문구 금지 |

## 5. 프로토 한계

| 화면 ID | 한계 | B단계에서 바뀌는 것 |
| --- | --- | --- |
| {WI-ID}-S01 | 검증 규칙·채번·공유 없음 | 트리거·검증 규칙·공장 격리 |

## 6. 화면 확인 기록

| 날짜 | 페르소나 | 화면 ID | 결과 | 메모 |
| --- | --- | --- | --- | --- |
