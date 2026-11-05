#!/usr/bin/env bash
# 데모 픽스처(data/demo/fixtures/demo_fixtures.json)를 정적 리소스 QMS_DemoFixtures로 복사한다(CMN_TestDataFactory가 읽음).
# 프로토 목 응답 묶음(CMN_PrototypeMocks, A0 프로토 공용 장치)도 함께 갱신·확인한다.
# 사용: scripts/dev/sync-fixtures.sh [--check]   (--check: 같은지만 확인, CI용)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/data/demo/fixtures/demo_fixtures.json"
DST="$ROOT/force-app-qms/main/default/staticresources/QMS_DemoFixtures.json"
if [ "${1:-}" = "--check" ]; then
  cmp -s "$SRC" "$DST" && echo "QMS_DemoFixtures 최신" || { echo "QMS_DemoFixtures가 데모 픽스처와 다름: scripts/dev/sync-fixtures.sh 실행"; exit 1; }
else
  cp "$SRC" "$DST"
  echo "QMS_DemoFixtures 갱신"
fi
python3 "$ROOT/scripts/dev/build-prototype-mocks.py" ${1:-}
