#!/usr/bin/env bash
# WI 구현 후 로컬 점검·배포·테스트를 한 번에 실행한다(sf-dev.md 9절, /implement-wi 6·7단계).
# 사용: scripts/dev/wi-check.sh <테스트 클래스(쉼표 구분)> [-o <Org 별칭>] [--no-deploy]
# 순서: 생성기 재생성·최신 확인 → 픽스처 동기화 확인 → 메타 파일 → Prettier → ESLint → Jest → Code Analyzer(심각도 2)
#      → dry-run → 배포 → Apex 테스트 → 클래스별 커버리지 85%. 결과는 build/에 남긴다.
set -euo pipefail
TESTS="${1:?테스트 클래스 이름(쉼표 구분)이 필요합니다}"
shift
ORG="$(sf config get target-org --json | python3 -c 'import json,sys; r=json.load(sys.stdin)["result"]; print(r[0].get("value") or "")')"
DEPLOY=1
while [ $# -gt 0 ]; do
  case "$1" in
    -o) ORG="$2"; shift 2 ;;
    --no-deploy) DEPLOY=0; shift ;;
    *) echo "알 수 없는 옵션: $1" >&2; exit 2 ;;
  esac
done
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p build
step() { printf '\n== %s\n' "$1"; }

step "메타데이터 생성기"
python3 scripts/dev/metagen.py
scripts/dev/sync-fixtures.sh --check
scripts/dev/ensure-meta.sh
step "Prettier"
npx prettier --write "force-app-*/**/*.{cls,trigger,js,html,css,xml}" "meta-src/**/*.json" > /dev/null
npm run --silent prettier:verify
step "한글 문자열 리터럴(I18N-001 AC-4)"
python3 scripts/ci/check-korean-literals.py
step "LWC 모바일 규칙(UX-001 BR-2)"
python3 scripts/ci/check-lwc-mobile.py
step "LWC 스타일 규칙(UX-004 BR-10)"
python3 scripts/ci/check-lwc-styling.py
step "업무 레코드 페이지 규칙(UX-004 BR-1·2)"
python3 scripts/ci/check-record-pages.py
step "Apex 이름 가림(경고, 변경 파일)"
CHANGED_CLS=$(git ls-files -m -o --exclude-standard -- 'force-app-*/main/default/classes/*.cls')
[ -n "$CHANGED_CLS" ] && python3 scripts/ci/check-apex-shadowing.py $CHANGED_CLS || true
step "ESLint·Jest"
npm run --silent lint
npm run --silent test:unit -- --coverage > build/jest.log 2>&1 || { tail -40 build/jest.log; exit 1; }
tail -6 build/jest.log
step "Code Analyzer(심각도 1~2 위반 0건)"
sf code-analyzer run --target force-app-cmn --target force-app-qms --target force-app-pms \
  --rule-selector Recommended --severity-threshold 2 --output-file build/code-analyzer.json > /dev/null 2>&1 || {
  python3 -c "
import json
for x in json.load(open('build/code-analyzer.json'))['violations']:
    if x['severity'] <= 2:
        l = x['locations'][0]
        print(x['severity'], x['rule'], (l.get('file') or '-').split('force-app')[-1], l.get('startLine'), x['message'][:300])"
  exit 1
}
echo "위반 0건"
[ "$DEPLOY" -eq 1 ] || exit 0
step "dry-run → 배포($ORG)"
sf project deploy start --dry-run -o "$ORG" --wait 30 --ignore-conflicts --json > build/deploy-dry.json 2>/dev/null || {
  python3 -c "
import json
r = json.load(open('build/deploy-dry.json')).get('result') or {}
f = (r.get('details') or {}).get('componentFailures') or []
for x in (f if isinstance(f, list) else [f]):
    print('FAIL', x.get('componentType'), x.get('fullName'), 'L', x.get('lineNumber'), '|', (x.get('problem') or '')[:250])"
  exit 1
}
# 개발 Org는 로컬 소스가 기준이다. PSG는 배포 후 서버 재계산으로 원격 변경처럼 보여 매번 충돌이 나므로 무시한다
sf project deploy start -o "$ORG" --wait 30 --ignore-conflicts --json > build/deploy.json 2>/dev/null || {
  python3 -c "
import json
d = json.load(open('build/deploy.json')); r = d.get('result') or {}
print('배포 실패:', (d.get('message') or '')[:300])
f = (r.get('details') or {}).get('componentFailures') or []
for x in (f if isinstance(f, list) else [f]):
    print('FAIL', x.get('componentType'), x.get('fullName'), 'L', x.get('lineNumber'), '|', (x.get('problem') or '')[:250])"
  exit 1
}
echo "배포 성공"
# PSG 구성이 바뀌면 서버가 비동기로 재계산한다. 그동안 PSG 할당 테스트가 실패하므로 끝날 때까지 기다린다(최대 3분)
for _ in $(seq 1 36); do
  n=$(sf data query -o "$ORG" -q "SELECT COUNT() FROM PermissionSetGroup WHERE Status != 'Updated'" --json \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["totalSize"])')
  [ "$n" = "0" ] && break
  echo "PSG 재계산 대기(${n}개)"; sleep 5
done
step "Apex 테스트: $TESTS"
sf apex run test -o "$ORG" -n "$TESTS" -c -w 30 --json > build/test-wi.json 2>/dev/null || true
python3 - <<'EOF'
import json
r = json.load(open('build/test-wi.json'))['result']
s = r['summary']
print('결과', s.get('outcome'), '통과', s.get('passing'), '실패', s.get('failing'))
for t in r['tests']:
    if t['Outcome'] != 'Pass':
        print('FAIL', t['FullName'], (t.get('Message') or '')[:300], (t.get('StackTrace') or '')[:200])
EOF
python3 scripts/ci/check-coverage.py build/test-wi.json | grep -v '^참고'
