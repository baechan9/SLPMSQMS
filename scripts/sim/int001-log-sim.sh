#!/usr/bin/env bash
# CMN-00-INT-001 연계 시뮬(개발 플랜 7.3): Mule 대신 외부 키 upsert로 연계 로그 수신 계약을 확인한다.
#  1) 같은 실행(FAILED, SUCCESS 2건)을 두 번 upsert → 로그 수 변화 없음(AC-1 멱등)
#  2) 점검 시간 실패 → 재처리 성공: 로그 2건(FAILED, SUCCESS), FAILED는 시스템 관리자 알림(AC-2 Salesforce 측)
# 사용: scripts/sim/int001-log-sim.sh <org alias>
set -euo pipefail
ORG="${1:?org alias}"
RUN="SIM-$(date +%Y%m%d%H%M%S)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
NOW="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
cat > "$TMP/logs.csv" <<CSV
ExternalKey__c,InterfaceId__c,CorrelationId__c,Status__c,RecordCount__c,ErrorCount__c,StartedAt__c,EndedAt__c,ErrorSummary__c
IF-HR-001:$RUN-1,IF-HR-001,$RUN-1,FAILED,0,1,$NOW,$NOW,Salesforce maintenance window - retried 3 times then sent to DLQ
IF-HR-001:$RUN-2,IF-HR-001,$RUN-2,SUCCESS,120,0,$NOW,$NOW,
CSV
count() {
  sf data query -o "$ORG" -q "SELECT COUNT() FROM CMN_InterfaceLog__c WHERE CorrelationId__c LIKE '$RUN-%'" --json |
    python3 -c 'import json,sys;print(json.load(sys.stdin)["result"]["totalSize"])'
}
for i in 1 2; do
  sf data upsert bulk -o "$ORG" -s CMN_InterfaceLog__c -i ExternalKey__c -f "$TMP/logs.csv" -w 10 > /dev/null
  echo "upsert $i: $(count)건"
done
sf data query -o "$ORG" -q "SELECT Name, Status__c, RecordCount__c, ErrorCount__c FROM CMN_InterfaceLog__c WHERE CorrelationId__c LIKE '$RUN-%' ORDER BY CorrelationId__c"
