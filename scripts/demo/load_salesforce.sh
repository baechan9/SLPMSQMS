#!/usr/bin/env bash
# SL QMS 데모 데이터를 Salesforce Scratch Org·Sandbox에 적재한다(gen_salesforce.py + gen_snowflake.py 90번대 CSV).
# 사용: scripts/demo/load_salesforce.sh <orgAlias> [--upto-phase N] [--max-users 8] [--from 40] [--only 48] [--strict] [--dry-run]
#       --upto-phase N: 개발 플랜 페이즈 N까지 소유 객체만 적재(docs/docs/30-dev/phase-map.csv). 다음 페이즈에서 다시 실행하면 빠진 연결을 채운다.
# 전제: sf CLI(`sfdx` 금지), 대상 Org에 QMS·CMN 메타데이터(객체·필드·RecordType·PSG) 배포 완료,
#       python3 data/demo/generator/generate_all.py 실행 완료.
# 대상 검사: Scratch Org(sf org list의 scratchOrgs) 또는 Sandbox(Organization.IsSandbox)가 아니면 중단한다.
set -euo pipefail
ORG="${1:?Org 별칭이 필요합니다(sf org list)}"
shift
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
command -v sf >/dev/null || { echo "sf CLI가 필요합니다" >&2; exit 2; }
[ -f "$ROOT/data/demo/salesforce/load-plan.json" ] || { echo "먼저 python3 data/demo/generator/generate_all.py 를 실행하세요" >&2; exit 2; }
exec python3 "$ROOT/scripts/demo/sf_demo_loader.py" "$ORG" "$@"
