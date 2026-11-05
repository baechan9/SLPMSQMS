#!/usr/bin/env python3
"""SL QMS 데모 데이터를 Scratch Org·Sandbox에 적재한다(표준 라이브러리 + sf CLI).

사용: scripts/demo/load_salesforce.sh <orgAlias> [--upto-phase N] [--upto-bundle A{n}] [--max-users 8] [--from 40] [--only 48] [--dry-run]

순서
1. 대상 검사: `sf org list`의 scratchOrgs에 있거나 Organization.IsSandbox = true여야 한다. 아니면 중단(운영 Org 보호).
2. 적재 범위: Org에 배포된 객체만 적재한다. --upto-phase N이면 개발 플랜 배정표(docs/docs/30-dev/phase-map.csv)와
   object-owner.json으로 페이즈 N까지 소유 객체만 적재한다. --upto-bundle A{n}이면 화면 우선 플랜의 화면 묶음
   (docs/docs/30-dev/screen-map.csv)으로 A{n}까지 소유 객체만 적재한다(A단계 묶음 검토용, 둘 다 주면 둘 다 만족).
   객체에 아직 없는 열은 빼고 적재한 뒤 요약에 남긴다.
3. 사용자: data/demo/salesforce/users/*.json을 _demo.priority 순으로 --max-users명 만든다(`sf org create user`).
   남은 라이선스에 맞춰 Salesforce(표준 사용자) → Salesforce Platform(표준 플랫폼 사용자) 순으로 배정하고,
   Org 언어에 따라 바뀐 표준 프로필 이름을 찾아 쓴다. 실행 사용자에게 EmployeeNo__c = E1901(관리자 페르소나)을 넣고, PSG를 할당한다.
4. load-plan.json + load-plan.snowflake.json(있으면)을 order 순으로 `sf data upsert bulk` 한다.
   - RecordTypeDeveloperName 열 → RecordTypeId
   - 사용자 Lookup 열(userLookups): 없는 사번이면 onMissingUser에 따라 행 건너뜀(skip) 또는 E1901로 대체(admin)
   - {{ref:객체.외부키=값}}·{{user:사번}} 토큰 → Id. 대상이 아직 없거나 적재 범위 밖이면 비워 적재하고 마지막 보정 패스에서 채운다.
     다음 페이즈에서 같은 명령을 다시 실행하면 채워진다(upsert라 건수는 늘지 않는다).
"""
import argparse
import collections
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
PHASE_MAP = os.path.join(ROOT, 'docs', 'docs', '30-dev', 'phase-map.csv')
SCREEN_MAP = os.path.join(ROOT, 'docs', 'docs', '30-dev', 'screen-map.csv')
BUNDLE_RE = re.compile(r'^A(\d)$')
OWNER_MAP = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'object-owner.json')
PHASE_USERS = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'phase-users.json')
REF_RE = re.compile(r'\{\{ref:([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)=([^}]*)\}\}')
USER_RE = re.compile(r'\{\{user:([A-Z0-9]+)\}\}')
ADMIN_EMP = 'E1901'
# 라이선스별 프로필 우선순위: SL 프로필(CMN-00-SEC-001) → 표준 프로필.
# 표준 프로필 이름은 Org 기본 언어로 바뀐다(ko Org에서 'Standard User' → '표준 사용자')
PROFILE_NAMES = {
    'Salesforce': ('SL Internal User', 'Standard User', '표준 사용자', '标准用户'),
    'Salesforce Platform': ('SL Internal Platform User', 'Standard Platform User', '표준 플랫폼 사용자', '标准平台用户'),
}
csv.field_size_limit(10 ** 9)


class SkipFile(Exception):
    """이 파일은 지금 적재할 수 없다(소유 WI 메타데이터 미배포). 요약에 사유를 남기고 다음 파일로 넘어간다."""


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
        self.deployed = None  # 적재 가능한 객체(None = 제한 없음)
        self.obj_phase = {}   # 객체 → 소유 WI의 페이즈
        self.obj_bundle = {}  # 객체 → 소유 WI의 화면 묶음 번호(A{n}의 n)
        self.fields = {}      # 객체 → (필드 이름, 관계 이름)
        self.dropped = collections.defaultdict(set)    # 파일 → 객체에 없어 뺀 열
        self.skipped_files = []                        # (파일, 사유)
        self.unresolved = collections.Counter()        # (파일, 토큰 대상 객체) → 미해결 건수

    # ---------------------------------------------------------------- 적재 범위
    def load_scope(self):
        with open(OWNER_MAP, encoding='utf-8') as f:
            owners = {k: v for k, v in json.load(f).items() if not k.startswith('_')}
        with open(PHASE_MAP, encoding='utf-8-sig') as f:
            wi_phase = {r['WI_ID']: int(r['페이즈']) for r in csv.DictReader(f)}
        self.obj_phase = {o: wi_phase[w] for o, w in owners.items() if w in wi_phase}
        if self.bundle_limit is not None:
            with open(SCREEN_MAP, encoding='utf-8-sig') as f:
                wi_bundle = {r['WI_ID']: int(m.group(1)) for r in csv.DictReader(f)
                             if (m := BUNDLE_RE.match((r.get('화면묶음') or '').strip()))}
            self.obj_bundle = {o: wi_bundle[w] for o, w in owners.items() if w in wi_bundle}
            print(f'적재 범위: 화면 묶음 A{self.bundle_limit}까지 소유 객체')
        if self.dry:
            if self.a.upto_phase is not None or self.bundle_limit is not None:
                self.deployed = {o for o in set(self.obj_phase) | set(self.obj_bundle) if self.in_scope(o)}
            return
        self.deployed = set(sf(['sobject', 'list', '--sobject', 'all'], self.org)['result'])
        if self.a.upto_phase is not None:
            print(f'적재 범위: 페이즈 {self.a.upto_phase}까지 소유 객체 중 Org에 배포된 것')

    @property
    def bundle_limit(self):
        b = getattr(self.a, 'upto_bundle', None)
        m = BUNDLE_RE.match(b.strip().upper()) if b else None
        if b and not m:
            sys.exit(f'--upto-bundle 형식 오류: {b} (예: A1)')
        return int(m.group(1)) if m else None

    def in_scope(self, obj):
        phase_ok = self.a.upto_phase is None or self.obj_phase.get(obj, 99) <= self.a.upto_phase
        bundle_ok = self.bundle_limit is None or self.obj_bundle.get(obj, 99) <= self.bundle_limit
        return phase_ok and bundle_ok

    def available(self, obj):
        if self.deployed is not None and obj not in self.deployed:
            return False
        return self.in_scope(obj)

    def object_fields(self, obj):
        if obj not in self.fields:
            d = sf(['sobject', 'describe', '--sobject', obj], self.org)['result']
            self.fields[obj] = ({f['name'] for f in d['fields']},
                                {f['relationshipName'] for f in d['fields'] if f.get('relationshipName')})
        return self.fields[obj]

    def keep_column(self, obj, col):
        if self.dry:
            return True
        names, rels = self.object_fields(obj)
        return col.split('.', 1)[0] in rels if '.' in col else col in names

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
        limit = self.a.max_users
        pick = self.pick_users()
        if pick:
            by_emp = {d['EmployeeNo__c']: d for d in defs}
            unknown = [e for e in pick if e not in by_emp]
            if unknown:
                sys.exit(f'사용자 목록에 없는 사번: {unknown}')
            defs = [by_emp[e] for e in pick] + [d for d in defs if d['EmployeeNo__c'] not in pick]
            limit = min(limit, len(pick))
            print(f"데모 사용자 선택: {', '.join(pick)}")
        if self.dry:
            for d in defs[:limit]:
                self.users[d['EmployeeNo__c']] = '005DRYRUN' + d['EmployeeNo__c']
            self.users[ADMIN_EMP] = '005DRYRUNADMIN'
            print(f"[dry-run] 사용자 {len(self.users)}명 가정: {', '.join(sorted(self.users))}")
            return
        if 'EmployeeNo__c' not in self.object_fields('User')[0]:
            print('사용자: User.EmployeeNo__c가 아직 없어 데모 사용자를 만들지 않는다(CMN-00-MDM-001 배포 후 다시 실행)')
            return
        sf(['data', 'update', 'record', '--sobject', 'User', '--where', f"Username='{self.admin_username}'",
            '--values', f'EmployeeNo__c={ADMIN_EMP}'], self.org)
        existing = {r['EmployeeNo__c']: r['Id'] for r in soql(self.org, 'SELECT Id, EmployeeNo__c FROM User WHERE EmployeeNo__c != null')}
        slots = self.license_slots()
        made = 0
        for d in defs:
            emp = d['EmployeeNo__c']
            if emp == ADMIN_EMP or emp in existing or made >= limit:
                continue
            if not slots:
                print(f"  남은 사용자 라이선스 없음 — {emp}부터는 만들지 않는다(onMissingUser 규칙 적용)")
                break
            license_name, profile = slots.pop(0)
            body = {k: (v.replace('{orgAlias}', re.sub(r'[^a-z0-9]', '', self.org.lower())) if isinstance(v, str) else v)
                    for k, v in d.items() if not k.startswith('_') and v is not None}
            body['profileName'] = profile
            path = os.path.join(self.tmp, f'user-{emp}.json')
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(body, f, ensure_ascii=False)
            res = sf(['org', 'create', 'user', '--definition-file', path, '--set-unique-username'], self.org, check=False)
            if res.get('status') != 0:
                print(f"  사용자 {emp} 생성 실패: {res.get('message')}")
                break
            made += 1
            print(f"  사용자 {emp} 생성({license_name})")
        self.users = {r['EmployeeNo__c']: r['Id'] for r in soql(self.org, 'SELECT Id, EmployeeNo__c FROM User WHERE EmployeeNo__c != null')}
        self.assign_psg(defs)
        print(f"사용자 {len(self.users)}명(관리자 {ADMIN_EMP} 포함). 없는 사번 Lookup은 onMissingUser 규칙을 따른다.")

    def pick_users(self):
        """만들 데모 사용자: --users > phase-users.json의 페이즈 목록(--upto-phase) > 우선순위(없음)."""
        if self.a.users:
            return [u.strip() for u in self.a.users.split(',') if u.strip()]
        if self.a.upto_phase is None:
            return None
        with open(PHASE_USERS, encoding='utf-8') as f:
            sets = json.load(f)
        return sets.get(str(self.a.upto_phase)) or sets.get('default')

    def license_slots(self):
        """남은 라이선스를 (라이선스, 표준 프로필 이름) 목록으로. Salesforce를 먼저 쓰고 Platform으로 채운다."""
        lic = {r['Name']: r['TotalLicenses'] - r['UsedLicenses'] for r in soql(
            self.org, f"SELECT Name, TotalLicenses, UsedLicenses FROM UserLicense WHERE Name IN ({quote_in(list(PROFILE_NAMES))})")}
        names = [n for ns in PROFILE_NAMES.values() for n in ns]
        found = {r['Name'] for r in soql(self.org, f"SELECT Name FROM Profile WHERE Name IN ({quote_in(names)})")}
        prof = {lic: next((n for n in ns if n in found), None) for lic, ns in PROFILE_NAMES.items()}
        prof = {lic: n for lic, n in prof.items() if n}
        slots = [(name, prof[name]) for name in PROFILE_NAMES if name in prof for _ in range(max(lic.get(name, 0), 0))]
        print(f"  사용자 라이선스 여유: {', '.join(f'{n} {max(lic.get(n, 0), 0)}' for n in PROFILE_NAMES)}")
        return slots

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
        if self.dry and self.available(obj):
            self.cache[key] = f'DRY:{obj}:{value}'
            return self.cache[key]
        return None

    def prefetch(self, rows, cols):
        """파일 안 토큰 대상 Id를 객체별로 한 번에 조회한다. 적재 범위 밖 객체는 조회하지 않는다(보정 패스로 미룸)."""
        if self.dry:
            return
        want = {}
        for r in rows:
            for c in cols:
                for m in REF_RE.finditer(r.get(c) or ''):
                    if m.group(0) and (m.group(1), m.group(2), m.group(3)) not in self.cache:
                        want.setdefault((m.group(1), m.group(2)), set()).add(m.group(3))
        for (obj, field), values in want.items():
            if not self.available(obj):
                continue
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
                        raise SkipFile(f"RecordType {p['object']}.{dn} 없음(소유 WI 미배포)")
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
        missing = [c for c in cols if not self.keep_column(p['object'], c)]
        if p['externalId'] in missing:
            self.skipped_files.append((p['file'], f"외부 키 {p['externalId']} 필드 없음"))
            print(f"  {label}: 외부 키 {p['externalId']}가 {p['object']}에 없어 건너뜀")
            return
        if missing:
            self.dropped[p['file']].update(missing)
            cols = [c for c in cols if c not in missing]
        with open(path, 'w', newline='', encoding='utf-8') as f:
            w = csv.DictWriter(f, fieldnames=cols, lineterminator='\n', extrasaction='ignore')
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
        granted = self.grant_migration()
        try:
            self.load()
        finally:
            if granted:
                sf(['data', 'delete', 'record', '--sobject', 'PermissionSetAssignment', '--record-id', granted], self.org, check=False)
                print('이관 모드 PS(CMN_PS_DataMigration) 할당 해제')

    def grant_migration(self):
        """적재하는 동안만 관리자에게 이관 모드 PS를 붙인다(CR-12). 새 필드 FLS(서비스 전용 포함)와 이관 모드를 함께 준다.
        이미 할당돼 있으면 건드리지 않는다. 돌려준 Id의 할당만 끝에 지운다."""
        if self.dry:
            return None
        ps = soql(self.org, "SELECT Id FROM PermissionSet WHERE Name = 'CMN_PS_DataMigration'")
        if not ps:
            return None
        uid = soql(self.org, f"SELECT Id FROM User WHERE Username = '{self.admin_username}'")[0]['Id']
        if soql(self.org, f"SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = '{uid}' AND PermissionSetId = '{ps[0]['Id']}'"):
            return None
        res = sf(['data', 'create', 'record', '--sobject', 'PermissionSetAssignment',
                  '--values', f"AssigneeId={uid} PermissionSetId={ps[0]['Id']}"], self.org)
        print('이관 모드 PS(CMN_PS_DataMigration)를 적재 동안 관리자에게 할당')
        return res['result']['id']

    def load(self):
        self.load_scope()
        if self.available('User'):
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
            if not self.available(p['object']):
                phase = self.obj_phase.get(p['object'])
                bundle = self.obj_bundle.get(p['object'])
                if phase is None:
                    reason = '소유 WI 미등록(object-owner.json)'
                elif self.a.upto_phase is not None and phase > self.a.upto_phase:
                    reason = f'P{phase} 소유'
                elif self.bundle_limit is not None and (bundle is None or bundle > self.bundle_limit):
                    reason = f'A{bundle} 묶음 소유' if bundle is not None else '화면 묶음 미배정(screen-map.csv)'
                else:
                    reason = 'Org에 미배포'
                self.skipped_files.append((p['file'], reason))
                continue
            with open(os.path.join(SF_DIR, p['file']), encoding='utf-8') as f:
                rows = list(csv.DictReader(f))
            mark = len(self.deferred)
            try:
                out, skipped = self.transform(p, rows)
            except SkipFile as e:
                # 표준 객체(Account 등)는 항상 배포돼 있어 레코드타입·필드로 소유 WI 배포 여부를 판단한다
                del self.deferred[mark:]
                self.skipped_files.append((p['file'], str(e)))
                continue
            label = p['file'] + (f' (사용자 없음 {skipped}행 제외)' if skipped else '')
            self.upsert(p, out, label)
        self.fix_deferred()
        self.summary()
        print('적재 완료' + (' (dry-run)' if self.dry else ''))

    def summary(self):
        if self.skipped_files:
            print(f'건너뛴 파일 {len(self.skipped_files)}개:')
            by_reason = collections.defaultdict(list)
            for f, why in self.skipped_files:
                by_reason[why].append(f.split('_')[0])
            for why, files in sorted(by_reason.items()):
                print(f"  {why}: {', '.join(files)}")
        if self.dropped:
            print('객체에 없어 뺀 열(배포된 WI 범위 밖 필드이거나 명세 불일치 — 해당 WI 배포 후 다시 실행):')
            for f, cols in self.dropped.items():
                print(f"  {f}: {', '.join(sorted(cols))}")
        if self.unresolved:
            print('미해결 토큰(대상 객체가 적재 범위 밖이거나 아직 없음 — 대상 페이즈에서 다시 실행하면 채워진다):')
            for (f, obj), n in sorted(self.unresolved.items()):
                print(f'  {f} → {obj}: {n}건')

    def fix_deferred(self):
        if not self.deferred:
            return
        print(f'보정 패스: 미해결 토큰 {len(self.deferred)}건')
        self.cache = {k: v for k, v in self.cache.items() if v}
        by_file = {}
        # 사본을 한 번만 돈다. 여기서도 풀리지 않아 transform이 다시 미룬 행은 미해결로만 센다(무한 반복 방지)
        pending, self.deferred = self.deferred, []
        for p, extv, col, v in pending:
            if col == '*':
                rows, _ = self.transform(dict(p, onMissingUser='admin'), [v])
                by_file.setdefault(p['file'], (p, []))[1].extend(rows)
                continue
            self.prefetch([{col: v}], [col])
            new, ok = self.sub_tokens(v)
            if ok:
                by_file.setdefault(p['file'], (p, []))[1].append({p['externalId']: extv, col: new})
            else:
                for m in REF_RE.finditer(v):
                    if self.resolve_ref(m.group(1), m.group(2), m.group(3)) is None:
                        self.unresolved[(p['file'], m.group(1))] += 1
        for p, _, _, r in self.deferred:   # 외부 키 토큰이 여전히 안 풀린 행
            for c in r.values():
                for m in REF_RE.finditer(c or ''):
                    if self.resolve_ref(m.group(1), m.group(2), m.group(3)) is None:
                        self.unresolved[(p['file'], m.group(1))] += 1
        self.deferred = []
        for name, (p, rows) in by_file.items():
            merged = {}
            for r in rows:
                merged.setdefault(r[p['externalId']], {}).update(r)
            self.upsert(p, list(merged.values()), f'{name} 보정')


def main():
    ap = argparse.ArgumentParser(description='SL QMS 데모 데이터 Salesforce 적재(Scratch Org·Sandbox 전용)')
    ap.add_argument('org', help='sf 별칭 또는 사용자 이름')
    ap.add_argument('--upto-phase', type=int, default=None,
                    help='개발 플랜 페이즈 N까지 소유 객체만 적재(docs/docs/30-dev/phase-map.csv). 다음 페이즈에서 다시 실행하면 빠진 연결을 채운다')
    ap.add_argument('--upto-bundle', default=None,
                    help='화면 우선 플랜 묶음 A{n}까지 소유 객체만 적재(docs/docs/30-dev/screen-map.csv 화면묶음). A단계 묶음 검토용')
    ap.add_argument('--users', default=None,
                    help='만들 데모 사용자 사번(쉼표 구분, 이 순서로). 없으면 --upto-phase의 phase-users.json 목록, 그것도 없으면 우선순위 순')
    ap.add_argument('--max-users', type=int, default=8, help='만들 데모 사용자 수 상한(기본 8). 실제 수는 남은 라이선스로 제한된다')
    ap.add_argument('--from', dest='from_order', type=float, default=0, help='이 order부터 적재(재시작)')
    ap.add_argument('--only', type=int, default=None, help='이 번호(NN) 파일만 적재')
    ap.add_argument('--strict', action='store_true', help='실패 행이 있으면 중단')
    ap.add_argument('--dry-run', action='store_true', help='Org 없이 변환·순서만 확인')
    Loader(ap.parse_args()).run()


if __name__ == '__main__':
    main()
