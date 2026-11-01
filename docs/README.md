# SL QMS 워크아이템 — Claude Code 이관 패키지

VS Code에서 이 폴더를 열고 Claude Code를 실행하면 `CLAUDE.md`가 자동으로 컨텍스트로 로드된다.

## 구성

```
sl-qms-handoff/
├─ CLAUDE.md                     # Claude Code 작업 지침(역할·규칙·상태·다음 할 일)
├─ README.md
├─ .claude/commands/
│  ├─ write-vol.md               # /write-vol <메뉴번호> : 다음 Vol. 작성
│  └─ build-master.md            # /build-master : 승인분 마스터 xlsx 생성
├─ docs/
│  ├─ 00-source/                 # RFP·Fit-Gap·회사표준 RFP 원본 + md 변환본, 분석 노트 (대외비)
│  ├─ 10-workitems/
│  │  ├─ vol0-cmn-common.md      # Vol.0 공통 43 WI
│  │  ├─ vol2-qms02-dev-quality.md ~ vol9-qms09-integration.md  # Vol.2~9 (Vol.6은 6a·6b·6c), 합계 227 WI
│  │  ├─ interfaces.md           # Vol. 간 계약(객체·서비스·이벤트 소유, 게이트웨이 등록부)
│  │  └─ assets/vol2-qms02-flow.png
│  └─ 20-status/
│     ├─ STATUS.md               # 진행 상태·우선 결정·검토 방법
│     ├─ review-pack.md          # 결정·변경 요청 모음(자동 생성)
│     └─ backlog.md              # 남은 작업·PoC 시나리오 연결 WI
├─ master/workitem-index.csv     # 전체 WI 인덱스(분류 레벨 L1~L4, 상태 = 검토 대기)
├─ scripts/build_index.py        # md → 인덱스 CSV 재생성
├─ scripts/validate_vol.py       # Vol. md 형식 검사(메타 라인·표)
├─ scripts/build_review_pack.py  # 검토 패키지 재생성
└─ templates/workitem-template.md
```

## 시작 방법

1. 폴더를 Git 저장소로 초기화: `git init && git add . && git commit -m "handoff from claude.ai"`
2. Claude Code에서 첫 요청 예: "STATUS.md 기준으로 현재 상태를 요약하고, 결정 대기 항목을 물어봐줘" 또는 `/write-vol 3`
3. 인덱스 재생성: `python scripts/build_index.py` (Python 3.9+)

## 주의

`docs/00-source/`는 대외비다. 공개 저장소(GitHub public 등)에 올리지 않는다.
