#!/usr/bin/env bash
# P2 게이트 G2-4(CMN-00-SEC-002 AC-4): 테스트 대상 레코드 N건(기본 10,000)을 공장별로 만들고 공유 재계산 배치를 돌려
# 거버너 오류 없이 끝나는지 잰다. 레코드는 외부 키(RecordNo__c = G24-nnnnn)로 upsert하므로 다시 실행해도 늘지 않는다.
# 적재 동안만 관리자에게 이관 모드 PS를 준다(테스트 대상 객체는 관리자에게 FLS가 없다).
# 사용: scripts/gate/p2-recalc-10k.sh <scratch alias> [건수]
set -euo pipefail
ORG="${1:?scratch alias}"
N="${2:-10000}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
j() { python3 -c "import json,sys;d=json.load(sys.stdin);print($1)"; }

PLANTS=$(tail -n +2 "$ROOT/data/demo/salesforce/03_CMN_Plant__c.csv" | cut -d, -f1 | tr '\n' ' ')
python3 - "$N" $PLANTS > "$TMP/records.csv" <<'PY'
import sys
n, plants = int(sys.argv[1]), sys.argv[2:]
print('RecordNo__c,Name,Plant__r.PlantCode__c,Status__c')
for i in range(1, n + 1):
    print(f'G24-{i:05d},G2-4 load {i},{plants[i % len(plants)]},DRAFT')
PY

USER=$(sf org display -o "$ORG" --json | j 'd["result"]["username"]')
PS=$(sf data query -o "$ORG" -q "SELECT Id FROM PermissionSet WHERE Name = 'CMN_PS_DataMigration'" --json | j 'd["result"]["records"][0]["Id"]')
UID=$(sf data query -o "$ORG" -q "SELECT Id FROM User WHERE Username = '$USER'" --json | j 'd["result"]["records"][0]["Id"]')
PSA=$(sf data query -o "$ORG" -q "SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = '$UID' AND PermissionSetId = '$PS'" --json | j 'd["result"]["records"][0]["Id"] if d["result"]["records"] else ""')
if [ -z "$PSA" ]; then
  PSA=$(sf data create record -o "$ORG" -s PermissionSetAssignment -v "AssigneeId=$UID PermissionSetId=$PS" --json | j 'd["result"]["id"]')
  REVOKE=1
fi
echo "적재: $N건 → CMN_TestRecord__c"
sf data upsert bulk -o "$ORG" -s CMN_TestRecord__c -i RecordNo__c -f "$TMP/records.csv" -w 30 > "$TMP/upsert.log" 2>&1 || { tail -5 "$TMP/upsert.log"; }
[ "${REVOKE:-0}" = 1 ] && sf data delete record -o "$ORG" -s PermissionSetAssignment -i "$PSA" > /dev/null
echo "적재 결과: $(sf data query -o "$ORG" -q "SELECT COUNT() FROM CMN_TestRecord__c WHERE RecordNo__c LIKE 'G24-%'" --json | j 'd["result"]["totalSize"]')건"

echo "Id j = Database.executeBatch(new CMN_SharingRecalcBatch('CMN_TestRecord__c'), CMN_SharingRecalcBatch.BATCH_SIZE); System.debug('JOB=' + j);" > "$TMP/run.apex"
JOB=$(sf apex run -o "$ORG" -f "$TMP/run.apex" | grep -o 'JOB=[0-9A-Za-z]*' | head -1 | cut -d= -f2)
echo "배치: $JOB"
START=$(date +%s)
while true; do
  R=$(sf data query -o "$ORG" -q "SELECT Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, ExtendedStatus FROM AsyncApexJob WHERE Id = '$JOB'" --json)
  S=$(echo "$R" | j 'd["result"]["records"][0]["Status"]')
  case "$S" in Completed|Failed|Aborted) break ;; esac
  sleep 15
done
echo "$R" | j '" / ".join(f"{k}={v}" for k, v in d["result"]["records"][0].items() if k != "attributes")'
echo "소요: $(( $(date +%s) - START ))초"
echo "공장 공유 행: $(sf data query -o "$ORG" -q "SELECT COUNT() FROM CMN_TestRecord__Share WHERE RowCause = 'CMN_Plant__c'" --json | j 'd["result"]["totalSize"]')"
