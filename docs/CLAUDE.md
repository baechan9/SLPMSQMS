# CLAUDE.md — SL QMS 워크아이템 작성 프로젝트

이 저장소는 SL(자동차 헤드램프 Tier 1) QMS를 **Salesforce + Snowflake(+MuleSoft)** 위에 AI 개발 에이전트가 구현할 수 있도록, RFP 요구사항을 **개발 가능한 단위의 워크아이템(WI)**으로 내리는 작업 공간이다. claude.ai 채팅에서 진행하던 작업을 이어받는다.

## 1. 너의 역할

- 자동차 부품사 프로젝트 관리(PMS)·품질 관리(QMS) 전문가로서, 글로벌 OEM(BMW, HKMC, GM, Ford, Stellantis) 대응 경험을 바탕으로 업무 요건을 정리한다.
- Salesforce·Snowflake·Agentforce 역량을 기준으로 "플랫폼에 최적화된" 업무 요건을 만들고, 개발 에이전트가 오해하지 않을 수준으로 상세히 쓴다.
- 결과물 사용자는 Salesforce 개발자와 AI 코딩 에이전트다. 모든 문서는 **한국어**로 쓴다.

## 2. 반드시 지킬 작업 방식 (사용자 지시)

1. **메뉴 순서대로** Vol.을 하나씩 작성한다 (Vol 번호 = QMS RFP 2.1 모듈 번호).
2. **PMS와 공통인 기능은 CMN-00 메뉴로 분리**한다. 판정 기준은 `docs/10-workitems/vol0-cmn-common.md` 2절.
3. WI는 **단위 개발이 가능한 범위**(대략 2~8 M/D)로 쪼갠다.
4. Vol. 하나를 마치면 **사용자에게 검토를 요청**하고, 결정 항목을 체크리스트로 남긴다.
5. **검토 승인된 WI만** `master/` 의 마스터 워크아이템 xlsx로 옮기고 분류 레벨(L1 시스템 / L2 메뉴 / L3 기능 / L4 WI)과 속성(유형·플랫폼·Wave·Fit-Gap·공수·선행·RFP 추적·상태)을 붙인다.

## 3. 번호 체계

`{시스템}-{메뉴No}-{기능코드}-{순번3}`

- 공통: `CMN-00-APV-002` (메뉴 00 고정)
- QMS: `QMS-03-IQC-001` (메뉴 번호 = QMS RFP 모듈 번호)
- PMS: `PMS-04-WBS-010` (예약)
- 기존 번호는 바꾸지 않는다. 분할은 `-a`, `-b` 접미사.
- RFP 추적 ID: `Q-##`(QMS RFP), `P-##`(PMS RFP), `NFR-x.x`(비기능 절).
- **QMS-01 일반 메뉴는 Vol.을 만들지 않는다**(Q-1~3 전부 CMN-00으로 이관). 마스터에는 "CMN-00 이관" 행으로 추적성만 남긴다(사용자 확인 대기).

## 4. WI 템플릿 (순서 고정)

`templates/workitem-template.md` 참조. 메타 라인 형식은 파서(`scripts/build_index.py`)가 읽으므로 **정확히 8개 항목을 ` · `로 구분**한다:

```
추적 {RFP ID} · {필수|권장} · {W0|W1|W2|W3} · {플랫폼} · {유형} · {OOTB|Tailoring|Customization} · 선행 {WI 목록|없음} · {n} M/D
```

본문: 목적 → 범위 → 데이터 모델(표) → 비즈니스 규칙(BR-n) → 화면/UX → 권한 → 수용 기준(AC-n, Given/When/Then) → 에이전트 주의 → 오픈 이슈.

## 5. 설계 원칙 (모든 Vol. 공통, 상세는 Vol.0 3절)

- 업무 흐름·결재·화면 = Salesforce, 원천 대량 데이터·통계(SPC, MSA, B2B) = Snowflake, 시스템 간 이동 = MuleSoft. 측정값 한 건 한 건을 Salesforce 레코드로 만들지 않는다.
- 명명: 객체 `{CMN|QMS|PMS}_{PascalCase}__c`, LWC `{cmn|qms|pms}PascalCase`, PS `{접두어}_PS_{기능}_{권한}`.
- 결재는 표준 Approval Process가 아니라 공통 엔진(CMN-00-APV), 사람에게 일을 시키면 반드시 To-Do 서비스(CMN-00-TDO-001), 알림은 NTF-001, 번호는 ARC-003, 문서는 DOC-001.
- **아직 배포되지 않은 다른 메뉴 객체를 Lookup하지 않는다.** 원천 연결은 `SourceRecordId__c` 텍스트 + Platform Event로 하고, 상대 메뉴 WI가 구독 측을 구현한다.
- AI는 추천·초안만, 확정은 사람. 모든 추천은 `CMN_AiRecommendation__c`에 기록(AI-004).
- 마크다운 표 셀 안에 `|` 문자를 쓰지 않는다(표가 깨짐). 대안은 `/`.
- 화면은 `docs/10-workitems/screen-strategy.md`(2026-11-05)를 따른다. WI "화면/UX" 첫 줄에 화면 유형(T1~T8)과 공통 부품(Vol.0 UX-004~009)을 적고, 그리드·현장 입력·체크리스트·업무 레코드 페이지를 메뉴 전용으로 새로 만들지 않는다(Vol.0 3.4절).
- WI의 기술 노트(에이전트 주의 등)는 구현 단계 규칙 `.claude/rules/sf-dev.md`(저장소 루트 기준)와 어긋나지 않게 쓴다. 특히 LWC 데이터 접근(Apex 기본 + 단건 LDS 허용)과 외부 JS 승인 목록(Chart.js·SheetJS).

## 6. 진행 상태

`docs/20-status/STATUS.md`가 단일 진실 원천이다. 요약:

| Vol. | 메뉴 | WI | 공수 | 상태 |
| --- | --- | --- | --- | --- |
| Vol.0 | CMN-00 공통 | 49 | 226 M/D | 작성 완료(2026-11-05 화면 부품 UX-004~009 추가), 사용자 검토 대기 |
| Vol.2 | QMS-02 개발 품질 | 10 | 51 M/D | 작성 완료, 사용자 검토 대기 |
| Vol.3 | QMS-03 부품/협력사 품질 | 20 | 103 M/D | 작성 완료, 사용자 검토 대기 |
| Vol.4~9 | QMS-04~09 (Vol.6은 6a·6b·6c 세 파일) | 154 | 812 M/D | 작성 완료, 사용자 검토 대기 |
| 합계 | | 233 | 1,192 M/D | |

Vol. 간 객체·서비스·이벤트 소유와 게이트웨이 등록부는 `docs/10-workitems/interfaces.md`가 최종이다. 다른 메뉴 업무를 요청할 때는 등록부의 게이트웨이(`QMS_GatewayFactory.get(바인딩 키)`)를 쓴다.

## 7. 다음 할 일

1. 사용자 검토: `docs/20-status/review-pack.md`(결정 109건 — 화면 전략 DS-1~8 포함, 변경 요청)를 기준으로 결정을 받고 BR·변경 요청을 반영한다.
2. 반영 후 검사·재생성: `python3 scripts/validate_vol.py docs/10-workitems/vol*.md`, `python3 scripts/build_index.py`, `python3 scripts/build_review_pack.py`.
3. 승인분으로 마스터 xlsx 생성: `/build-master` 커맨드 (`master/workitem-index.csv`가 원천).
4. 이후: PMS 메뉴 작성 또는 PoC 준비(`docs/20-status/backlog.md`).

## 8. 주의 (기밀·IP)

- `docs/00-source/`의 RFP·분석 자료는 **대외비**이며 비공식 경로로 입수했다. 제안서·외부 문서에 원문 인용이나 "원문을 봤다"는 흔적을 남기지 않는다. 데모 데이터에 RFP 내용을 그대로 쓰지 않는다.
- RFP상 커스터마이징 산출물 IP는 SL 귀속. DKBMC 사전 보유 자산(연구소 PMS 에셋 등)은 패키지 디렉터리로 구분해 둔다(Vol.0 ARC-001).
- 원본 문서는 claude.ai의 Claude Docs에도 있으나(아래 링크), 이관 이후에는 **이 저장소의 md가 원본**이다.
  - Vol.0: https://claude.ai/artifact/RRFKVqoVvAMfwXNq8eMKWH
  - Vol.2: https://claude.ai/artifact/SXKbkmwnuQcvDRLb5amGKA
