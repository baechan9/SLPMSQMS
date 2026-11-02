#!/usr/bin/env bash
# CMN-00-INT-003 연계 시뮬(개발 플랜 7.3): Mule 대신 외부 키 upsert로 SAP 기준정보 수신 계약을 확인한다.
#  1) 데모 기준정보(자재·자재-플랜트·공급업체-자재)를 같은 CSV로 두 번 upsert → 건수 불변(멱등)
#  (AC-1 신규 공급업체-자재 기본값은 데모 데이터를 늘리지 않도록 Apex 테스트 CMN_SapMasterInbound_Test로 확인)
#  2) 자재 삭제 표시 → 자재-플랜트 PHASE_OUT, 품번 유지(AC-2). 확인 후 ACTIVE로 되돌린다(데모 일관성)
# 사용: scripts/sim/int003-sap-sim.sh <org alias>
set -euo pipefail
ORG="${1:?org alias}"
DATA="$(cd "$(dirname "$0")/../../data/demo/salesforce" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
q() { sf data query -o "$ORG" -q "$1" --json | python3 -c 'import json,sys;print(json.load(sys.stdin)["result"]["totalSize"])'; }
up() { sf data upsert bulk -o "$ORG" -s "$1" -i "$2" -f "$3" -w 10 > /dev/null; }

before="$(q "SELECT COUNT() FROM CMN_Item__c")/$(q "SELECT COUNT() FROM CMN_ItemPlant__c")/$(q "SELECT COUNT() FROM CMN_SupplierItem__c")"
for i in 1 2; do
  up CMN_ItemPlant__c ExternalKey__c "$DATA/12_CMN_ItemPlant__c.csv"
done
after="$(q "SELECT COUNT() FROM CMN_Item__c")/$(q "SELECT COUNT() FROM CMN_ItemPlant__c")/$(q "SELECT COUNT() FROM CMN_SupplierItem__c")"
echo "멱등(품번/자재-플랜트/공급업체-자재): $before → $after"

# 2) 삭제 표시 → PHASE_OUT → 되돌림
IP="$(sed -n 2p "$DATA/12_CMN_ItemPlant__c.csv" | cut -d, -f1)"
printf 'ExternalKey__c,Status__c\n%s,PHASE_OUT\n' "$IP" > "$TMP/ip.csv"
up CMN_ItemPlant__c ExternalKey__c "$TMP/ip.csv"
sf data query -o "$ORG" -q "SELECT ExternalKey__c, Status__c, Item__r.ItemNo__c FROM CMN_ItemPlant__c WHERE ExternalKey__c = '$IP'"
printf 'ExternalKey__c,Status__c\n%s,ACTIVE\n' "$IP" > "$TMP/ip.csv"
up CMN_ItemPlant__c ExternalKey__c "$TMP/ip.csv"
