#!/usr/bin/env python3
"""P1 게이트 확인(docs/docs/30-dev/p01-cmn-framework-master.md 7절) — Org에서 확인할 수 있는 항목.

사용: python3 scripts/gate/p1-check.py <별칭> [--reload]
  G1-2: P1 소유 데모 CSV 행 수와 Org 건수 비교(--reload면 한 번 더 적재 후 건수 불변 확인)
  G1-6: Inspector 데모 사용자(E1104)의 프로필·PSG·Setup 권한·앱
  G1-9: 한글 문자열 리터럴 검사
G1-1(RunLocalTests·커버리지)은 build-scratch.sh 7단계, G1-3·4·5·7·8은 Apex 테스트(같은 실행)가 근거다.
"""
import csv
import json
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SF_DIR = os.path.join(ROOT, 'data', 'demo', 'salesforce')
P1_OBJECTS = ['CMN_Company__c', 'CMN_Plant__c', 'CMN_Line__c', 'CMN_Operation__c', 'CMN_ProductGroup__c', 'CMN_CodeGroup__c',
              'CMN_Code__c', 'CMN_Vehicle__c', 'CMN_Item__c', 'CMN_ItemPlant__c', 'CMN_ItemVehicle__c', 'CMN_SupplierItem__c',
              'CMN_Characteristic__c', 'CMN_Department__c']


def count(org, soql):
    p = subprocess.run(['sf', 'data', 'query', '-o', org, '-q', soql, '--json'], capture_output=True, text=True)
    return json.loads(p.stdout)['result']['totalSize']


def query(org, soql):
    p = subprocess.run(['sf', 'data', 'query', '-o', org, '-q', soql, '--json'], capture_output=True, text=True)
    return json.loads(p.stdout)['result']['records']


def expected():
    plan = json.load(open(os.path.join(SF_DIR, 'load-plan.json'), encoding='utf-8'))['files']
    keys = {}
    for f in plan:
        if f['object'] in P1_OBJECTS:
            with open(os.path.join(SF_DIR, f['file']), encoding='utf-8') as fh:
                for r in csv.DictReader(fh):
                    keys.setdefault(f['object'], set()).add(r[f['externalId']])
    acc = {'customer': 0, 'supplier': 0}
    for f in plan:
        if f['object'] == 'Account' and f.get('pass') in acc:
            with open(os.path.join(SF_DIR, f['file']), encoding='utf-8') as fh:
                acc[f['pass']] = sum(1 for _ in csv.DictReader(fh))
    return {k: len(v) for k, v in keys.items()}, acc


def actual(org):
    got = {o: count(org, f'SELECT COUNT() FROM {o}') for o in P1_OBJECTS}
    got['Account(CMN_Customer)'] = count(org, "SELECT COUNT() FROM Account WHERE RecordType.DeveloperName = 'CMN_Customer'")
    got['Account(CMN_Supplier)'] = count(org, "SELECT COUNT() FROM Account WHERE RecordType.DeveloperName = 'CMN_Supplier'")
    return got


def main():
    org = sys.argv[1]
    ok = True
    exp, acc = expected()
    exp['Account(CMN_Customer)'] = acc['customer']
    exp['Account(CMN_Supplier)'] = acc['supplier']
    first = actual(org)
    print('G1-2 데모 건수(CSV 고유 키 → Org)')
    for k in sorted(exp):
        mark = 'OK' if first.get(k) == exp[k] else 'DIFF'
        ok &= mark == 'OK'
        print(f'  {mark:4} {k}: {exp[k]} → {first.get(k)}')
    if '--reload' in sys.argv:
        subprocess.run([os.path.join(ROOT, 'scripts', 'demo', 'load_salesforce.sh'), org, '--upto-phase', '1'],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
        second = actual(org)
        same = second == first
        ok &= same
        print(f"  두 번째 적재 후 건수 {'불변' if same else '변화: ' + str({k: (first[k], second[k]) for k in first if first[k] != second[k]})}")
    print('G1-6 Inspector 데모 사용자 E1104')
    u = query(org, "SELECT Id, Profile.Name FROM User WHERE EmployeeNo__c = 'E1104'")
    if not u:
        print('  없음(라이선스로 생성되지 않음)')
        ok = False
    else:
        uid = u[0]['Id']
        groups = sorted(r['PermissionSetGroup']['DeveloperName'] for r in query(
            org, f"SELECT PermissionSetGroup.DeveloperName FROM PermissionSetAssignment WHERE AssigneeId = '{uid}' AND PermissionSetGroupId != null"))
        setup = count(org, "SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = '%s' AND PermissionSet.PermissionsViewSetup = true" % uid)
        print(f"  프로필 {u[0]['Profile']['Name']}, PSG {groups}, View Setup 권한 셋 {setup}개")
        ok &= groups == ['QMS_PSG_Inspector'] and setup == 0
    print('G1-9 한글 문자열 리터럴')
    r = subprocess.run([sys.executable, os.path.join(ROOT, 'scripts', 'ci', 'check-korean-literals.py')], capture_output=True, text=True)
    print('  ' + r.stdout.strip().splitlines()[-1])
    ok &= r.returncode == 0
    print('결과:', '통과' if ok else '확인 필요')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
