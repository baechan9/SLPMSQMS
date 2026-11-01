#!/usr/bin/env python3
"""SL 프로필 3개를 '로그인·기본 기능만' 상태로 잠그는 프로필 메타데이터를 만든다(CMN-00-SEC-001 BR-1).

사용: python3 scripts/dev/profile-lockdown.py <org 별칭>                     프로필 XML 생성
      python3 scripts/dev/profile-lockdown.py <org 별칭> --hide-system-apps  배포 후 단계(build-scratch.sh 4단계)

새 프로필은 라이선스 기본값으로 표준 앱·표준 객체 권한·일부 시스템 권한(Platform 라이선스는 Setup 조회까지)을 받는다.
이 스크립트는 대상 Org에 배포된 SL 프로필의 현재 값을 읽어 허용 목록 밖의 것을 모두 끄는 XML을 쓴다.
표준 앱·객체 목록이 Org 기능 구성(에디션·라이선스)에 따라 달라서, Scratch 정의 파일과 다른 Org(Sandbox·운영)에
배포하기 전에는 그 Org를 대상으로 다시 실행한다. 프로필이 아직 없으면 허용 목록만 담은 최소 XML로 먼저 배포한다.

--hide-system-apps: Salesforce 라이선스 프로필에는 Metadata API에 나오지 않는 시스템 앱(Work, SecurityHub,
DataGovernanceConsole, CommandCenterApp 등)이 앱 런처에 보인다. 프로필 XML로는 끌 수 없어서, 배포 후 SL 프로필의
앱 접근(SetupEntityAccess, TabSet) 가운데 Metadata API가 모르는 앱의 행을 지운다(설정 화면에서 앱 할당을 끄는 것과 같다).
"""
import json
import os
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'force-app-cmn', 'main', 'default', 'profiles')

# 프로필은 기본 앱이 하나 있어야 한다('You can't remove the only default app'). 사내 프로필은 SL QMS를 기본 앱으로 두고,
# SL PMS·SL Admin은 PSG가 배정한다(BR-4). QMS PSG도 SL QMS 앱 PS를 따로 가져 프로필 기본 앱이 바뀌어도 유지된다.
DEFAULT_APP = 'SL_QMS'

# 라이선스가 강제해 끌 수 없는 권한(배포 오류 '…권한을 해제하지 못할 수 있습니다'로 확인). 켠 채로 둔다.
FORCED = {'ActivitiesAccess', 'AllowViewKnowledge', 'LightningConsoleAllowedForUser'}

PROFILES = {
    'SL Internal User': {
        'license': 'Salesforce',
        'defaultApp': DEFAULT_APP,
        'description': '사내 사용자 기본 프로필(Salesforce 라이선스). 로그인·Lightning·모바일·검색·알림만. 객체·필드·앱 권한은 PSG로 준다(CMN-00-SEC-001 BR-1)',
        'allow': ['ApiEnabled', 'ChatterInternalUser', 'LightningExperienceUser', 'ViewHelpLink', 'EnableNotifications', 'AllowUniversalSearch'],
    },
    'SL Internal Platform User': {
        'license': 'Salesforce Platform',
        'defaultApp': DEFAULT_APP,
        'description': '사내 사용자 기본 프로필(Salesforce Platform 라이선스). SL Internal User와 같은 규칙(CMN-00-SEC-001 BR-1, 라이선스 차이로 추가)',
        'allow': ['ApiEnabled', 'ChatterInternalUser', 'LightningExperienceUser', 'ViewHelpLink', 'EnableNotifications', 'AllowUniversalSearch'],
    },
    'SL Supplier Portal User': {
        'license': 'Customer Community Plus',
        'description': '협력사 포털 사용자 프로필(Customer Community Plus). 객체 권한은 QMS_PSG_SupplierPortal로 준다(CMN-00-SEC-001 BR-1)',
        'allow': ['EnableNotifications'],
    },
}


def query(org, soql):
    p = subprocess.run(['sf', 'data', 'query', '-o', org, '-q', soql, '--json'], capture_output=True, text=True)
    d = json.loads(p.stdout or '{}')
    if d.get('status') != 0:
        sys.exit(f'조회 실패: {d.get("message")}')
    return d['result']['records']


def perm_fields(org):
    p = subprocess.run(['sf', 'sobject', 'describe', '-s', 'PermissionSet', '-o', org, '--json'], capture_output=True, text=True)
    return [f['name'] for f in json.loads(p.stdout)['result']['fields']
            if f['name'].startswith('Permissions') and f['type'] == 'boolean']


def metadata_apps(org):
    """Metadata API가 아는 앱 Id → 전체 이름(standard__Sales, SL_QMS). 프로필 XML로 다룰 수 있는 앱은 이것뿐이다."""
    p = subprocess.run(['sf', 'org', 'list', 'metadata', '-m', 'CustomApplication', '-o', org, '--json'], capture_output=True, text=True)
    return {r['id'][:15]: r['fullName'] for r in json.loads(p.stdout)['result']}


def hide_system_apps(org):
    known = metadata_apps(org)
    names = ', '.join(f"'{n}'" for n in PROFILES)
    rows = query(org, f"SELECT Id, Parent.Profile.Name, SetupEntityId FROM SetupEntityAccess "
                      f"WHERE Parent.Profile.Name IN ({names}) AND SetupEntityType = 'TabSet'")
    gone = [r for r in rows if r['SetupEntityId'][:15] not in known]
    for r in gone:
        p = subprocess.run(['sf', 'data', 'delete', 'record', '-s', 'SetupEntityAccess', '-i', r['Id'], '-o', org, '--json'],
                           capture_output=True, text=True)
        if json.loads(p.stdout or '{}').get('status') != 0:
            sys.exit(f"앱 접근 삭제 실패: {r['Parent']['Profile']['Name']} {r['SetupEntityId']}")
    print(f'SL 프로필 시스템 앱 접근 {len(gone)}건 해제')


def existing(path):
    """이미 쓴 XML의 숨김 앱·해제 객체·시스템 권한 이름. 잠금이 적용된 Org에서는 기본값이 더 보이지 않으므로 합쳐서 유지한다."""
    if not os.path.exists(path):
        return set(), set(), set()
    ns = {'m': 'http://soap.sforce.com/2006/04/metadata'}
    root = ET.parse(path).getroot()
    apps = {e.findtext('m:application', namespaces=ns) for e in root.findall('m:applicationVisibilities', ns)
            if e.findtext('m:visible', namespaces=ns) == 'false'}
    objs = {e.findtext('m:object', namespaces=ns) for e in root.findall('m:objectPermissions', ns)}
    perms = {e.findtext('m:name', namespaces=ns) for e in root.findall('m:userPermissions', ns)}
    return apps, objs, perms


def block(tag, items):
    return ''.join(f'    <{tag}>\n' + ''.join(f'        <{k}>{v}</{k}>\n' for k, v in it) + f'    </{tag}>\n' for it in items)


def main():
    args = sys.argv[1:]
    if len(args) not in (1, 2) or (len(args) == 2 and args[1] != '--hide-system-apps'):
        sys.exit(__doc__)
    org = args[0]
    if len(args) == 2:
        hide_system_apps(org)
        return
    fields = perm_fields(org)
    apps = metadata_apps(org)
    for name, spec in PROFILES.items():
        path = os.path.join(OUT, f'{name}.profile-meta.xml')
        old_apps, old_objs, old_perms = existing(path)
        on = set()
        for i in range(0, len(fields), 150):
            rec = query(org, f"SELECT {', '.join(fields[i:i + 150])} FROM PermissionSet WHERE Profile.Name = '{name}'")
            if not rec:
                sys.exit(f'{name} 프로필이 {org}에 없음 — 최소 XML로 먼저 배포한 뒤 다시 실행')
            on |= {k[len('Permissions'):] for k, v in rec[0].items() if v is True}
        objs = sorted(old_objs | {r['SobjectType'] for r in query(org, f"SELECT SobjectType FROM ObjectPermissions WHERE Parent.Profile.Name = '{name}'")})
        visible = sorted({apps[r['SetupEntityId'][:15]] for r in query(
            org, f"SELECT SetupEntityId FROM SetupEntityAccess WHERE Parent.Profile.Name = '{name}' AND SetupEntityType = 'TabSet'")
            if r['SetupEntityId'][:15] in apps})
        visible = sorted(old_apps | {a for a in visible if not a.startswith('SL_')})
        perms = sorted(on | old_perms | set(spec['allow']))
        xml = ['<?xml version="1.0" encoding="UTF-8"?>\n<Profile xmlns="http://soap.sforce.com/2006/04/metadata">\n',
               block('applicationVisibilities', sorted(
                   [[('application', a), ('default', 'false'), ('visible', 'false')] for a in visible]
                   + ([[('application', spec['defaultApp']), ('default', 'true'), ('visible', 'true')]] if spec.get('defaultApp') else []))),
               '    <custom>true</custom>\n',
               f"    <description>{spec['description']}</description>\n",
               block('objectPermissions', [[('allowCreate', 'false'), ('allowDelete', 'false'), ('allowEdit', 'false'),
                                            ('allowRead', 'false'), ('modifyAllRecords', 'false'), ('object', o),
                                            ('viewAllRecords', 'false')] for o in objs]),
               f"    <userLicense>{spec['license']}</userLicense>\n",
               block('userPermissions', [[('enabled', 'true' if p in spec['allow'] or p in FORCED else 'false'), ('name', p)] for p in perms]),
               '</Profile>\n']
        with open(path, 'w', encoding='utf-8') as f:
            f.write(''.join(xml))
        print(f'{name}: 앱 {len(visible)}개 숨김, 객체 {len(objs)}개 권한 해제, 시스템 권한 {len(on - set(spec["allow"]) - FORCED)}개 끔')


if __name__ == '__main__':
    main()
