#!/usr/bin/env python3
"""SL QMS 데모 데이터를 Scratch Org·Sandbox에 적재한다(표준 라이브러리 + sf CLI).

사용: scripts/demo/load_salesforce.sh <orgAlias> [--max-users 8] [--from 40] [--only 48] [--dry-run]

순서
1. 대상 검사: `sf org list`의 scratchOrgs에 있거나 Organization.IsSandbox = true여야 한다. 아니면 중단(운영 Org 보호).
2. 사용자: data/demo/salesforce/users/*.json을 _demo.priority 순으로 --max-users명 만든다(`sf org create user`).
   실행 사용자에게 EmployeeNo__c = E1901(관리자 페르소나)을 넣고, PSG를 할당한다.
3. load-plan.json + load-plan.snowflake.json(있으면)을 order 순으로 `sf data upsert bulk` 한다.
   - RecordTypeDeveloperName 열 → RecordTypeId
   - 사용자 Lookup 열(userLookups): 없는 사번이면 onMissingUser에 따라 행 건너뜀(skip) 또는 E1901로 대체(admin)
   - {{ref:객체.외부키=값}}·{{user:사번}} 토큰 → Id. 대상이 아직 없으면 비워 적재하고 마지막 보정 패스에서 채운다.
"""
import argparse
import csv
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SF_DIR = os.path.join(ROOT, 'data', 'demo', 'salesforce')
REF_RE = re.compile(r'\{\{ref:([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)=([^}]*)\}\}')
USER_RE = re.compile(r'\{\{user:([A-Z0-9]+)\}\}')
ADMIN_EMP = 'E1901'
csv.field_size_limit(10 ** 9)


def sf(args, org=None, check=True):
    cmd = ['sf'] + args + (['--target-org', org] if org else []) + ['--json']
    p = subprocess.run(cmd, capture_output=True, text=True)
    try:
        out = json.loads(p.stdout or '{}')
    except json.JSONDecodeError:
        out = {'status': 1, 'message': p.stdout + p.stderr}
    if check and out.get('status', 1) != 0:
        raise RuntimeError(f"sf {' '.join(args[:3])} 실패: {out.get('message') or p.stderr[:500]}")
    return out


def soql(org, q):
    return sf(['data', 'query', '--query', q], org)['result'].get('records', [])


def quote_in(values):
    return ','.join("'" + v.replace("\\", "\\\\").replace("'", "\\'") + "'" for v in values)


class Loader:
    def __init__(self, args):
        self.a = args
        self.org = args.org
        self.dry = args.dry_run
        self.users = {}       # 사번 → User Id
        self.rt = {}          # (SObject, DeveloperName) → Id
        self.cache = {}       # (obj, field, value) → Id
        self.deferred = []    # (plan entry, ext value, column, 원래 셀)
        self.tmp = tempfile.mkdtemp(prefix='slqms-demo-')

    # ---------------------------------------------------------------- 1. 대상 검사
    def check_org(self):
        if self.dry:
            print('[dry-run] 대상 검사 생략')
            return
        disp = sf(['org', 'display'], self.org)['result']
        username = disp.get('username')
        lst = sf(['org', 'list'])['result']
        scratch = any(o.get('username') == username or o.get('alias') == self.org for o in lst.get('scratchOrgs', []))
        org = soql(self.org, 'SELECT Id, Name, IsSandbox, OrganizationType FROM Organization')[0]
        if not (scratch or org.get('IsSandbox')):
            sys.exit(f"중단: {self.org}({org.get('Name')}, {org.get('OrganizationType')})는 Scratch Org·Sandbox가 아닙니다. 데모 데이터는 넣지 않습니다.")
        self.admin_username = username
        print(f"대상 확인: {self.org} — {'Scratch Org' if scratch else 'Sandbox'} ({org.get('Name')})")

    # ---------------------------------------------------------------- 2. 사용자
    def create_users(self):
        defs = []
        for path in glob.glob(os.path.join(SF_DIR, 'users', '*.json')):
            with open(path, encoding='utf-8') as f:
                defs.append(json.load(f))
        defs.sort(key=lambda d: d['_demo']['priority'])
        if self.dry:
            for d in defs[:self.a.max_users]:
                self.users[d['EmployeeNo__c']] = '005DRYRUN' + d['EmployeeNo__c']
            self.users[ADMIN_EMP] = '005DRYRUNADMIN'
            print(f"[dry-run] 사용자 {len(self.users)}명 가정: {', '.join(sorted(self.users))}")
            return
        sf(['data', 'update', 'record', '--sobject', 'User', '--where', f"Username='{self.admin_username}'",
            '--values', f'EmployeeNo__c={ADMIN_EMP}'], self.org)
        existing = {r['EmployeeNo__c']: r['Id'] for r in soql(self.org, 'SELECT Id, EmployeeNo__c FROM User WHERE EmployeeNo__c != null')}
        made = 0
        for d in defs:
            emp = d['EmployeeNo__c']
            if emp == ADMIN_EMP or emp in existing or made >= self.a.max_users:
                continue
            body = {k: (v.replace('{orgAlias}', re.sub(r'[^a-z0-9]', '', self.org.lower())) if isinstance(v, str) else v)
                    for k, v in d.items() if not k.startswith('_') and v is not None}
            path = os.path.join(self.tmp, f'user-{emp}.json')
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(body, f, ensure_ascii=False)
            res = sf(['org', 'create', 'user', '--definition-file', path, '--set-unique-username'], self.org, check=False)
            if res.get('status') != 0:
                print(f"  사용자 {emp} 생성 실패(라이선스 부족 가능): {res.get('message')}")
                break
            made += 1
            print(f"  사용자 {emp} 생성")
        self.users = {r['EmployeeNo__c']: r['Id'] for r in soql(self.org, 'SELECT Id, EmployeeNo__c FROM User WHERE EmployeeNo__c != null')}
        self.assign_psg(defs)
        print(f"사용자 {len(self.users)}명(관리자 {ADMIN_EMP} 포함). 없는 사번 Lookup은 onMissingUser 규칙을 따른다.")

    def assign_psg(self, defs):
        names = sorted({p for d in defs for p in d['_demo']['permissionSetGroups']})
        groups = {r['DeveloperName']: r['Id'] for r in soql(self.org, f'SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN ({quote_in(names)})')}
        missing = [n for n in names if n not in groups]
        if missing:
            print(f"  경고: 배포되지 않은 PSG {missing} — 메타데이터 배포 후 다시 실행하면 할당한다")
        have = {(r['AssigneeId'], r['PermissionSetGroupId']) for r in
                soql(self.org, 'SELECT AssigneeId, PermissionSetGroupId FROM PermissionSetAssignment WHERE PermissionSetGroupId != null')}
        for d in defs:
            uid = self.users.get(d['EmployeeNo__c'])
            for p in d['_demo']['permissionSetGroups']:
                if uid and p in groups and (uid, groups[p]) not in have:
                    sf(['data', 'create', 'record', '--sobject', 'PermissionSetAssignment',
                        '--values', f'AssigneeId={uid} PermissionSetGroupId={groups[p]}'], self.org, check=False)

    # ---------------------------------------------------------------- 3. 적재
    def load_meta(self):
        if self.dry:
            return
        self.rt = {(r['SobjectType'], r['DeveloperName']): r['Id'] for r in soql(self.org, 'SELECT Id, SobjectType, DeveloperName FROM RecordType')}

    def resolve_ref(self, obj, field, value):
        key = (obj, field, value)
        if key in self.cache:
            return self.cache[key]
        if self.dry:
            self.cache[key] = f'DRY:{obj}:{value}'
            return self.cache[key]
        return None

    def prefetch(self, rows, cols):
        """파일 안 토큰 대상 Id를 객체별로 한 번에 조회한다."""
        if self.dry:
            return
        want = {}
        for r in rows:
            for c in cols:
                for m in REF_RE.finditer(r.get(c) or ''):
                    if m.group(0) and (m.group(1), m.group(2), m.group(3)) not in self.cache:
                        want.setdefault((m.group(1), m.group(2)), set()).add(m.group(3))
        for (obj, field), values in want.items():
            vals = sorted(values)
            for i in range(0, len(vals), 200):
                for rec in soql(self.org, f'SELECT Id, {field} FROM {obj} WHERE {field} IN ({quote_in(vals[i:i + 200])})'):
                    self.cache[(obj, field, rec[field])] = rec['Id']

    def sub_tokens(self, text):
        ok = True

        def ref(m):
            nonlocal ok
            rid = self.resolve_ref(m.group(1), m.group(2), m.group(3))
            if rid is None:
                ok = False
                return ''
            return rid

        def usr(m):
            return self.users.get(m.group(1)) or self.users.get(ADMIN_EMP, '')
        out = USER_RE.sub(usr, REF_RE.sub(ref, text))
        return out, ok

    def transform(self, p, rows):
        cols = list(rows[0].keys()) if rows else []
        tok_cols = p.get('tokenColumns') or [c for c in cols if any('{{' in (r.get(c) or '') for r in rows)]
        user_cols = p.get('userLookups') or []
        self.prefetch(rows, tok_cols)
        out, skipped = [], 0
        ext = p['externalId']
        for r in rows:
            r = dict(r)
            drop = p['object'] == 'User' and r.get(ext) not in self.users   # 로더가 만든 사용자만 갱신
            for c in user_cols:
                v = r.get(c)
                if v and v not in self.users:
                    if p.get('onMissingUser') == 'skip':
                        drop = True
                        break
                    r[c] = ADMIN_EMP
            if drop:
                skipped += 1
                continue
            for c in tok_cols:
                v = r.get(c) or ''
                if '{{' not in v:
                    continue
                new, ok = self.sub_tokens(v)
                if not ok:
                    if c == ext:
                        drop = True
                        break
                    self.deferred.append((p, r[ext], c, v))
                r[c] = new
            if drop:
                self.deferred.append((p, None, '*', r))
                continue
            if 'RecordTypeDeveloperName' in r:
                dn = r.pop('RecordTypeDeveloperName')
                if dn:
                    rid = self.rt.get((p['object'], dn)) if not self.dry else f'012DRY{dn}'
                    if not rid:
                        raise RuntimeError(f"{p['file']}: RecordType {p['object']}.{dn} 없음 — 메타데이터 배포 확인")
                    r['RecordTypeId'] = rid
            out.append(r)
        return out, skipped

    def upsert(self, p, rows, label):
        if not rows:
            print(f"  {label}: 0행(건너뜀)")
            return
        path = os.path.join(self.tmp, label.replace(' ', '_'))
        cols = []
        for r in rows:
            for k in r:
                if k not in cols:
                    cols.append(k)
        with open(path, 'w', newline='', encoding='utf-8') as f:
            w = csv.DictWriter(f, fieldnames=cols, lineterminator='\n')
            w.writeheader()
            w.writerows(rows)
        if self.dry:
            print(f"  [dry-run] {label}: {len(rows)}행 → sf data upsert bulk -s {p['object']} -i {p['externalId']}")
            return
        res = sf(['data', 'upsert', 'bulk', '--sobject', p['object'], '--file', path, '--external-id', p['externalId'],
                  '--wait', '30', '--line-ending', 'LF'], self.org, check=False)
        r = res.get('result') or {}
        info = r.get('jobInfo') or r
        failed = info.get('numberRecordsFailed') or (len(r.get('records', {}).get('failedResults', [])) if isinstance(r.get('records'), dict) else 0)
        print(f"  {label}: {len(rows)}행, 실패 {failed or 0}" + ('' if res.get('status') == 0 else f" — {res.get('message', '')[:300]}"))
        if (failed or res.get('status') != 0) and self.a.strict:
            sys.exit(f"중단(--strict): {p['file']}")

    def run(self):
        self.check_org()
        self.create_users()
        self.load_meta()
        plans = []
        for name in ('load-plan.json', 'load-plan.snowflake.json'):
            path = os.path.join(SF_DIR, name)
            if os.path.exists(path):
                with open(path, encoding='utf-8') as f:
                    plans += json.load(f)['files']
        plans.sort(key=lambda p: p['order'])
        for p in plans:
            if self.a.only is not None and int(p['order']) != self.a.only:
                continue
            if p['order'] < self.a.from_order:
                continue
            with open(os.path.join(SF_DIR, p['file']), encoding='utf-8') as f:
                rows = list(csv.DictReader(f))
            out, skipped = self.transform(p, rows)
            label = p['file'] + (f' (사용자 없음 {skipped}행 제외)' if skipped else '')
            self.upsert(p, out, label)
        self.fix_deferred()
        print('적재 완료' + (' (dry-run)' if self.dry else ''))

    def fix_deferred(self):
        if not self.deferred:
            return
        print(f'보정 패스: 미해결 토큰 {len(self.deferred)}건')
        self.cache = {k: v for k, v in self.cache.items() if v}
        by_file = {}
        for p, extv, col, v in self.deferred:
            if col == '*':
                rows, _ = self.transform(dict(p, onMissingUser='admin'), [v])
                by_file.setdefault(p['file'], (p, []))[1].extend(rows)
                continue
            self.prefetch([{col: v}], [col])
            new, ok = self.sub_tokens(v)
            if ok:
                by_file.setdefault(p['file'], (p, []))[1].append({p['externalId']: extv, col: new})
            else:
                print(f"  해결 불가: {p['file']} {extv} {col}={v[:80]}")
        self.deferred = []
        for name, (p, rows) in by_file.items():
            merged = {}
            for r in rows:
                merged.setdefault(r[p['externalId']], {}).update(r)
            self.upsert(p, list(merged.values()), f'{name} 보정')


def main():
    ap = argparse.ArgumentParser(description='SL QMS 데모 데이터 Salesforce 적재(Scratch Org·Sandbox 전용)')
    ap.add_argument('org', help='sf 별칭 또는 사용자 이름')
    ap.add_argument('--max-users', type=int, default=8, help='만들 데모 사용자 수(우선순위 순, 기본 8 — Scratch Org 라이선스 한도)')
    ap.add_argument('--from', dest='from_order', type=float, default=0, help='이 order부터 적재(재시작)')
    ap.add_argument('--only', type=int, default=None, help='이 번호(NN) 파일만 적재')
    ap.add_argument('--strict', action='store_true', help='실패 행이 있으면 중단')
    ap.add_argument('--dry-run', action='store_true', help='Org 없이 변환·순서만 확인')
    Loader(ap.parse_args()).run()


if __name__ == '__main__':
    main()
