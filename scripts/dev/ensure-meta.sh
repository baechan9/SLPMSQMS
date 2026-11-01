#!/usr/bin/env bash
# 메타 파일이 없는 Apex 클래스·트리거에 -meta.xml을 만든다(API 버전은 sfdx-project.json의 sourceApiVersion).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
V="$(python3 -c "import json;print(json.load(open('$ROOT/sfdx-project.json'))['sourceApiVersion'])")"
for f in $(find "$ROOT"/force-app-* \( -name '*.cls' -o -name '*.trigger' \)); do
  [ -f "$f-meta.xml" ] && continue
  case "$f" in
    *.cls) T=ApexClass ;;
    *.trigger) T=ApexTrigger ;;
  esac
  printf '<?xml version="1.0" encoding="UTF-8"?>\n<%s xmlns="http://soap.sforce.com/2006/04/metadata">\n    <apiVersion>%s</apiVersion>\n    <status>Active</status>\n</%s>\n' "$T" "$V" "$T" > "$f-meta.xml"
  echo "생성: ${f#$ROOT/}-meta.xml"
done
