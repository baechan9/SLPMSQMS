#!/usr/bin/env bash
# SL QMS 데모 데이터를 Snowflake 개발·데모 DB에 적재한다(gen_snowflake.py 생성).
# 사용: scripts/demo/load_snowflake.sh <snow-connection-name> [--with-b2b-core]
# 전제: Snowflake CLI(snow) 설치, 연결의 database가 SL_QDW_DEMO 또는 SL_QDW_DEV, 테이블은 schemachange로 생성 완료.
set -euo pipefail
CONN="${1:?연결 이름이 필요합니다(snow connection list)}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DIR="$ROOT/data/demo/snowflake"
DB="$(snow sql -c "$CONN" -q "SELECT CURRENT_DATABASE()" --format json | python3 -c 'import json,sys; print(list(json.load(sys.stdin)[0].values())[0])')"
case "$DB" in
  SL_QDW_DEMO|SL_QDW_DEV) ;;
  *) echo "중단: 데모 데이터는 SL_QDW_DEMO·SL_QDW_DEV에만 적재합니다(현재 $DB)" >&2; exit 2 ;;
esac
snow sql -c "$CONN" -f "$DIR/load_demo.sql" -D "demo_dir=$DIR"
if [ "${2:-}" = "--with-b2b-core" ]; then
  # CORE.CUSTOMER_QUALITY_EVENT 동적 테이블이 없는 환경만
  snow sql -c "$CONN" -f "$DIR/load_demo_b2b_core.sql" -D "demo_dir=$DIR"
fi
echo "적재 완료: $DB"
