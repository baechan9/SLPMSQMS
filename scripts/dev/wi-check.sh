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
        print(x['severity'], x['rule'], l['file'].split('force-app')[-1], l.get('startLine'), x['message'][:160])"
  exit 1
}
echo "위반 0건"
[ "$DEPLOY" -eq 1 ] || exit 0
step "dry-run → 배포($ORG)"
sf project deploy start --dry-run -o "$ORG" --wait 30 --json > build/deploy-dry.json 2>/dev/null || {
  python3 -c "
import json
r = json.load(open('build/deploy-dry.json')).get('result') or {}
f = (r.get('details') or {}).get('componentFailures') or []
for x in (f if isinstance(f, list) else [f]):
    print('FAIL', x.get('componentType'), x.get('fullName'), 'L', x.get('lineNumber'), '|', (x.get('problem') or '')[:250])"
  exit 1
}
sf project deploy start -o "$ORG" --wait 30 --json > build/deploy.json 2>/dev/null
echo "배포 성공"
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
