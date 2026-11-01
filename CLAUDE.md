# CLAUDE.md

이 저장소는 SL PMS·QMS Salesforce DX 프로젝트다. 워크아이템(WI) 명세 작성과 Salesforce 구현을 같은 저장소에서 한다.

## 작업 모드

| 모드 | 지침 | 진입 |
| --- | --- | --- |
| WI 문서 작성·검토(`docs/**`) | `docs/CLAUDE.md`(아래 import) | `/write-vol`, `/build-master` |
| Salesforce 개발(`force-app*/**`, `scripts/apex/**`, `manifest/**`, `config/**`) | `.claude/rules/sf-dev.md` — 해당 경로 파일을 다룰 때 자동 로드, 개발 모드에서만 적용 | `/implement-wi <WI-ID>` |

- 개발 작업의 명세는 Vol 문서의 해당 WI 절, 이름·소유는 `docs/docs/10-workitems/interfaces.md`가 최종이다. 구현 진행은 `docs/docs/20-status/DEV-STATUS.md`, 완료 보고는 `docs/wi/{WI-ID}.md`에 남긴다.
- Salesforce 플러그인 스킬을 설치해 쓰더라도 프로젝트 규칙(WI 명세, Vol.0 3.2·3.3, `sf-dev.md`)이 플러그인 기본값보다 우선한다.
- 검증 명령: `npm run prettier:verify`, `npm run lint`, `npm run test:unit`, `sf code-analyzer run --severity-threshold 2`, `sf project deploy start --dry-run -o <alias>`.

@docs/CLAUDE.md

## 경로 주의 (claude.ai 이관 패키지를 `docs/` 아래에 둠)

- `docs/CLAUDE.md`·`docs/README.md` 안의 경로는 `docs/` 기준이다. 예: `docs/10-workitems/` → 실제 `docs/docs/10-workitems/`, `master/` → `docs/master/`, `templates/` → `docs/templates/`.
- 인덱스 재생성은 `docs/`에서 실행한다: `cd docs && python3 scripts/build_index.py`
- `docs/docs/00-source/`는 대외비라 `.gitignore`에 등록했다. 커밋·외부 공유 금지.
- `00-source`의 .docx·.pptx·.xlsx는 원본 바이너리가 아니라 같은 이름 .md와 내용이 같은 텍스트 사본이다. 원천은 .md를 쓴다.
- `docs/`·`data/`는 `sfdx-project.json` 패키지 경로 밖이라 배포 대상이 아니다(`.forceignore` 수정 불필요).
