#!/usr/bin/env bash
# Scratch Org를 정의 파일로 만들고 배포·관리자 권한·데모 데이터·테스트까지 한 번에 재현한다(CMN-00-ARC-001, 개발 플랜 5.5절).
# 사용: scripts/org/build-scratch.sh <별칭> [--hub <DevHub>] [--days 30] [--phase N] [--users E1101,...] [--no-data] [--reuse]
#   --phase N  : 데모 데이터를 개발 플랜 페이즈 N까지 적재(scripts/demo/load_salesforce.sh --upto-phase N)
#   --users    : 만들 데모 사용자 사번(기본은 scripts/demo/phase-users.json의 페이즈 목록)
#   --no-data  : 데모 데이터를 적재하지 않음
#   --reuse    : 새로 만들지 않고 이미 있는 Scratch Org에 2단계부터 실행
# 결과 로그: build/org-<별칭>-<시각>.log(커밋하지 않음). Scratch Org가 아니면 중단한다(sf-dev.md 9절).
set -euo pipefail

ALIAS="${1:?Org 별칭이 필요합니다}"
shift
HUB=""
DAYS=30
PHASE=""
USERS=""
NO_DATA=0
REUSE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --hub) HUB="$2"; shift 2 ;;
    --days) DAYS="$2"; shift 2 ;;
    --phase) PHASE="$2"; shift 2 ;;
    --users) USERS="$2"; shift 2 ;;
    --no-data) NO_DATA=1; shift ;;
    --reuse) REUSE=1; shift ;;
    *) echo "알 수 없는 옵션: $1" >&2; exit 2 ;;
  esac
done

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p build
LOG="build/org-${ALIAS}-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

step() { printf '\n== [%s/8] %s\n' "$1" "$2"; }
has_metadata() { find force-app-cmn force-app-qms force-app-pms -type f ! -name '.gitkeep' -print -quit | grep -q .; }
has_apex() { find force-app-cmn force-app-qms force-app-pms -type f \( -name '*.cls' -o -name '*.trigger' \) -print -quit | grep -q .; }

step 1 "Org 생성"
if [ "$REUSE" -eq 1 ]; then
  echo "기존 Org 사용: $ALIAS"
else
  sf org create scratch -f config/project-scratch-def.json -a "$ALIAS" ${HUB:+-v "$HUB"} -y "$DAYS" -w 30
fi
# 대상 검사: Scratch Org만 허용(운영·Sandbox에 이 스크립트를 쓰지 않는다)
sf org list --json | python3 -c '
import json, sys
alias = sys.argv[1]
orgs = json.load(sys.stdin)["result"].get("scratchOrgs", [])
if not any(o.get("alias") == alias or o.get("username") == alias for o in orgs):
    sys.exit(f"중단: {alias}는 Scratch Org가 아닙니다")
' "$ALIAS"

step 2 "배포 확인(dry-run)"
if has_metadata; then
  sf project deploy start --dry-run -o "$ALIAS" --wait 60
else
  echo "배포할 메타데이터 없음 — 건너뜀"
fi

step 3 "배포"
if has_metadata; then
  sf project deploy start -o "$ALIAS" --wait 60
else
  echo "배포할 메타데이터 없음 — 건너뜀"
fi

step 4 "배포 후 설정(SL 프로필 시스템 앱 숨김, 관리자 CMN_PSG_SystemAdmin)"
if has_metadata && [ -f "force-app-cmn/main/default/profiles/SL Internal User.profile-meta.xml" ]; then
  # Metadata API로 끌 수 없는 시스템 앱(Work 등)을 SL 프로필에서 숨긴다(CMN-00-SEC-001 AC-1)
  python3 scripts/dev/profile-lockdown.py "$ALIAS" --hide-system-apps
fi
ADMIN_ID="$(sf org display user -o "$ALIAS" --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["id"])')"
PSG_ID="$(sf data query -o "$ALIAS" -q "SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'CMN_PSG_SystemAdmin'" --json \
  | python3 -c 'import json,sys; r=json.load(sys.stdin)["result"]["records"]; print(r[0]["Id"] if r else "")')"
if [ -z "$PSG_ID" ]; then
  echo "CMN_PSG_SystemAdmin 없음(CMN-00-SEC-001 배포 전) — 건너뜀"
elif sf data query -o "$ALIAS" -q "SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = '$ADMIN_ID' AND PermissionSetGroupId = '$PSG_ID'" --json \
  | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["result"]["records"] else 1)'; then
  echo "이미 할당됨"
else
  sf data create record -o "$ALIAS" -s PermissionSetAssignment -v "AssigneeId=$ADMIN_ID PermissionSetGroupId=$PSG_ID"
fi

step 5 "수동 설정 안내(개발 플랜 5.6절)"
cat <<'EOF'
아래 중 이 Org의 페이즈에 해당하는 것을 확인한다(자동화되지 않은 항목).
- P2 이후: 메일 발송 수준(Setup > Deliverability) — 알림 메일을 확인할 때만
- P2 이후: SSO 테스트 IdP 연결(CMN-00-TDO-002 절차)
- P3 이후: External Credential 인증 값 입력(Mule DEV 주소, 사용자별)
- P4 이후: 협력사 포털 사이트 게시(sf community publish -o <별칭> --name <사이트 이름>)
- P12 이후: Agentforce 에이전트 활성화(sf agent)
EOF

step 6 "데모 데이터"
if [ "$NO_DATA" -eq 1 ] || [ -z "$PHASE" ]; then
  echo "건너뜀(--no-data 또는 --phase 없음)"
else
  scripts/demo/load_salesforce.sh "$ALIAS" --upto-phase "$PHASE" ${USERS:+--users "$USERS"}
  if [ -f force-app-cmn/main/default/classes/CMN_SharingRecalcBatch.cls ]; then
    # 공장 그룹은 공장 생성 후 비동기로 생겨 직후 적재분의 공유가 빠질 수 있다 → 전체 재계산(CMN-00-SEC-002 BR-6)
    sf apex run -o "$ALIAS" -f scripts/org/recalc-sharing.apex > /dev/null && echo "공유 재계산 배치 실행"
  fi
fi

step 7 "Apex 테스트(RunLocalTests) + 커버리지 85%"
if has_apex; then
  sf apex run test -o "$ALIAS" -l RunLocalTests -c -w 30 --json > "build/test-${ALIAS}.json" || true
  python3 -c '
import json, sys
r = json.load(open(sys.argv[1])).get("result") or {}
s = r.get("summary") or {}
print("테스트", s.get("outcome"), "| 실행", s.get("testsRan"), "| 통과", s.get("passing"), "| 실패", s.get("failing"))
for t in r.get("tests", []):
    if t.get("Outcome") != "Pass":
        print("FAIL", t.get("FullName"), (t.get("Message") or "")[:200])
sys.exit(1 if s.get("failing") else 0)
' "build/test-${ALIAS}.json"
  python3 scripts/ci/check-coverage.py "build/test-${ALIAS}.json"
else
  echo "저장소에 Apex 코드 없음 — 건너뜀"
fi

step 8 "결과"
sf org display -o "$ALIAS" --json | python3 -c '
import json, sys
r = json.load(sys.stdin)["result"]
print("별칭", r.get("alias"), "| 사용자", r.get("username"), "| 만료", r.get("expirationDate"), "| API", r.get("apiVersion"))
'
echo "로그: $LOG"
