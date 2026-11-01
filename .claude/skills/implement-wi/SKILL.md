---
name: implement-wi
description: SL QMS·PMS 워크아이템(WI) 하나를 명세 기반으로 Salesforce에 구현한다. 명세 확인 → AC 테스트 먼저 → 구현 → 린트·테스트·정적 분석 → Scratch Org 배포 → 자체 리뷰 → 완료 보고 순서로 진행한다.
argument-hint: <WI-ID 예: QMS-03-IQC-002>
disable-model-invocation: true
---

WI `$ARGUMENTS`를 구현한다. 각 단계의 결과를 짧게 보고하고, 멈춤 조건에 걸리면 그 자리에서 멈추고 사용자에게 알린다.

## 0. 사전 점검

1. `.claude/rules/sf-dev.md`를 읽는다. force-app 파일을 아직 열지 않았으면 자동 로드되지 않았을 수 있다. 이 지침이 이후 모든 단계의 기준이다.
2. 아래 두 가지를 확인한다. 하나라도 없으면 무엇이 필요한지 알리고 멈춘다.
   - Git 저장소인지(`git rev-parse --is-inside-work-tree`). 자체 리뷰와 커밋에 필요하다.
   - 기본 대상 Org가 Scratch 또는 Sandbox인지(`sf config get target-org`, `sf org display --json`). 운영 Org면 즉시 멈춘다.

## 1. 명세 읽기

1. `docs/master/workitem-index.csv`에서 WI 행(출처 Vol·선행 WI·Wave·상태)을 찾는다. 상태가 `승인`이 아니면 "검토 전 명세"임을 알리고 계속할지 묻는다.
2. 해당 Vol 문서(`docs/docs/10-workitems/{출처}*.md`)에서 `### $ARGUMENTS` 절만 읽는다. 읽는 순서는 메타 라인 → 데이터 모델 → 서비스 API → BR → 화면 → 권한 → 데모 데이터 → AC → 에이전트 주의 → 오픈 이슈다.
3. 함께 확인할 문서:
   - `docs/docs/10-workitems/interfaces.md`: 이 WI가 쓰는 다른 메뉴 이름, 소유, 게이트웨이 바인딩
   - Vol 문서 3절(데이터 모델 개요): 상태값, PS·PSG 매핑, 공통 기반 등록
   - Snowflake 연계 화면이면 `docs/docs/10-workitems/spec-snowflake-display.md`의 해당 절
   - 데모 데이터 줄이 가리키는 `data/demo/expected`·`mocks` 파일
4. **멈춤 조건:** 오픈 이슈나 명세 모순이 구현을 막는 경우다. 해당 항목과 선택지를 정리해 묻는다.

## 2. 선행 확인

- 메타 라인 `선행`의 각 WI가 `docs/docs/20-status/DEV-STATUS.md`에서 `개발 완료`인지 확인한다.
- 그 WI가 만든 객체·클래스가 force-app에 실제로 있는지 확인한다.
- **멈춤 조건:** 미완료 선행이 있으면 목록을 보고하고 멈춘다. 선행 객체를 임시로 만들지 않는다.

## 3. 계획(사용자 승인 후 진행)

다음을 표로 정리해 제시하고 승인을 받는다.

- **만들 메타데이터:** 객체·필드(API명·타입), Custom Metadata 레코드, Platform Event, PS, Custom Label 키, 번역 파일
- **Apex·LWC:** 클래스와 컴포넌트 목록, 각 책임, 호출하는 공통 서비스·게이트웨이
- **AC → 테스트 메서드 매핑 표:** 형식은 `docs/dev/reference-testing.md` 1절을 따르고, 벌크·음수·권한 테스트를 포함한다.
- **명세에서 정하지 않아 내가 결정해야 하는 부분:** 이유를 함께 적는다.

## 4. 테스트 먼저

- AC 매핑 표대로 Apex 테스트 클래스와 Jest 테스트를 먼저 작성한다.
- 테스트 데이터는 `CMN_TestDataFactory`와 데모 픽스처·목을 쓴다. `SeeAllData`는 쓰지 않는다.
- 아직 구현이 없어서 실패하는지 확인한다(Jest는 로컬 실행, Apex는 다음 단계 배포 후 확인).

## 5. 구현

순서: 객체·필드 → Custom Metadata·이벤트 → Apex(셀렉터 → 서비스 → 핸들러·컨트롤러) → LWC → PS·라벨·번역(ko·en_US·zh_CN) → 페이지 배치.

- 공통 서비스(결재·To-Do·알림·채번·문서·공유·로그)와 게이트웨이는 다시 만들지 않고 호출한다.
- 범위 밖 파일을 고쳐야 하면 멈추고 묻는다.

## 6. 로컬 점검

```bash
npm run prettier:verify
npm run lint
npm run test:unit -- --coverage
sf code-analyzer run --target <변경 경로> --rule-selector Recommended --severity-threshold 2
```

- **멈춤 조건:** 실패가 있으면 고친다. 같은 실패를 두 번 고쳐도 남으면 멈추고 보고한다.

## 7. Scratch Org 배포·테스트

```bash
sf project deploy start --dry-run -o <alias> --test-level RunLocalTests
sf project deploy start -o <alias>
sf apex run test -o <alias> -n <이번 WI 테스트 클래스들> -c -r human -w 10
```

- 클래스별 커버리지가 85% 이상이고 모든 AC 테스트가 통과해야 한다.
- **멈춤 조건:** dry-run이 같은 원인으로 두 번 실패하면 멈추고 보고한다.

## 8. 자체 리뷰

- 변경분에 `/code-review`와 `/security-review`를 실행하고, 지적 사항을 고친 뒤 테스트를 다시 돌린다.
- 리뷰 결과 요약(고친 것·남긴 것과 이유)을 보고서에 넣는다.

## 9. 데모 시나리오 확인(해당 시)

명세의 데모 데이터 줄이 가리키는 시나리오 단계를 데모 데이터가 적재된 Scratch Org에서 재현한다. 기대값 파일과 화면·레코드 결과가 일치하는지 확인한다.

## 10. 완료 보고·현황

1. `docs/wi/$ARGUMENTS.md`를 `docs/dev/wi-report-template.md` 형식으로 작성한다.
2. `docs/docs/20-status/DEV-STATUS.md`의 해당 행(상태·완료일·보고서 링크)을 갱신한다. 인덱스 CSV 상태 열은 바꾸지 않는다.
3. 명세와 다르게 구현한 점은 보고서 "명세 차이"에 적고, 사용자에게 변경 요청으로 알린다. WI 문서는 직접 고치지 않는다.
4. 커밋 메시지 `[$ARGUMENTS] {요약}`를 제안한다. 커밋은 사용자가 요청할 때만 한다.
