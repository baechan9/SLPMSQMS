#!/usr/bin/env python3
"""객체 정의 JSON(meta-src/**/*.json)으로 Salesforce 소스 메타데이터를 만든다.

사용: python3 scripts/dev/metagen.py           (meta-src 전체를 생성 — 번역 파일이 모든 라벨을 모으므로 항상 전체)
      python3 scripts/dev/metagen.py --check   (생성 결과가 저장소와 같은지만 확인, CI용)

만드는 것(객체 정의 1개당)
- objects/<Obj>/<Obj>.object-meta.xml(표준 객체는 만들지 않음), fields/, recordTypes/, validationRules/
- tabs/<Obj>.tab-meta.xml("tab"이 있을 때)
- objectTranslations/<Obj>-en_US/, <Obj>-zh_CN/: 객체·필드·선택 목록 값·레코드타입·검증 규칙 번역
권한 셋 정의(meta-src/**/permissionsets/*.json)는 permissionsets/<Name>.permissionset-meta.xml로 만든다.

Org 기본 언어가 ko라서 정의의 "ko" 값이 메타데이터 기본 라벨이 되고 en_US·zh_CN은 번역 파일로 간다.
생성 파일은 손으로 고치지 않는다. 바꿀 때는 정의 JSON을 고치고 다시 실행한다(CMN-00-ARC-001 개발 규칙).
"""
import argparse
import glob
import json
import os
import sys
from xml.sax.saxutils import escape

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SRC = os.path.join(ROOT, 'meta-src')
NS = 'http://soap.sforce.com/2006/04/metadata'
LANGS = ('en_US', 'zh_CN')

written = {}  # 경로 → 내용


def x(v):
    if isinstance(v, bool):
        return 'true' if v else 'false'
    return escape(str(v))


def node(tag, value, indent):
    pad = '    ' * indent
    if isinstance(value, list):
        return ''.join(node(tag, v, indent) for v in value)
    if isinstance(value, dict):
        inner = ''.join(node(k, v, indent + 1) for k, v in value.items() if v is not None)
        return f'{pad}<{tag}>\n{inner}{pad}</{tag}>\n'
    return f'{pad}<{tag}>{x(value)}</{tag}>\n'


def doc(root, body):
    """body: [(tag, value)] 순서 그대로."""
    inner = ''.join(node(t, v, 1) for t, v in body if v is not None)
    return f'<?xml version="1.0" encoding="UTF-8" ?>\n<{root} xmlns="{NS}">\n{inner}</{root}>\n'


def emit(path, content):
    written[os.path.join(ROOT, path)] = content


def lbl(v, lang='ko'):
    """{"ko":..,"en_US":..,"zh_CN":..} 또는 문자열."""
    if v is None:
        return None
    if isinstance(v, str):
        return v
    return v.get(lang) or (v.get('ko') if lang == 'ko' else None)


# ---------------------------------------------------------------- 필드
def field_xml(f, obj):
    t = f['type']
    body = [('fullName', f['name'])]
    opt = []
    if f.get('description'):
        opt.append(('description', f['description']))
    if f.get('help'):
        opt.append(('inlineHelpText', lbl(f['help'])))
    opt.append(('label', lbl(f['label'])))
    if t in ('Text', 'Email', 'Phone', 'Url') and t == 'Text':
        opt.append(('length', f.get('length', 255)))
    if t in ('LongTextArea', 'Html'):
        opt.append(('length', f.get('length', 32768)))
        opt.append(('visibleLines', f.get('visibleLines', 5)))
    if t == 'TextArea':
        pass
    if t in ('Number', 'Currency', 'Percent'):
        opt.append(('precision', f.get('precision', 18)))
        opt.append(('scale', f.get('scale', 0)))
    if t == 'Checkbox':
        opt.append(('defaultValue', 'true' if f.get('default') else 'false'))
    elif f.get('default') is not None and t not in ('Picklist', 'MultiselectPicklist'):
        opt.append(('defaultValue', f['default']))
    if t in ('Lookup', 'MasterDetail'):
        opt.append(('referenceTo', f['referenceTo']))
        opt.append(('relationshipLabel', lbl(f.get('relationshipLabel') or obj['plural'])))
        opt.append(('relationshipName', f['relationshipName']))
        if t == 'Lookup':
            opt.append(('deleteConstraint', f.get('deleteConstraint', 'SetNull')))
        else:
            opt.append(('relationshipOrder', f.get('relationshipOrder', 0)))
            opt.append(('reparentableMasterDetail', f.get('reparentable', False)))
            opt.append(('writeRequiresMasterRead', f.get('writeRequiresMasterRead', False)))
        if f.get('lookupFilter'):
            lf = f['lookupFilter']
            opt.append(('lookupFilter', {
                'active': True,
                'errorMessage': lf.get('errorMessage'),
                'filterItems': [{'field': i['field'], 'operation': i['operation'], 'value': i.get('value'),
                                 'valueField': i.get('valueField')} for i in lf['items']],
                'isOptional': lf.get('isOptional', False),
            }))
    if t == 'Formula':
        opt.append(('formula', f['formula']))
        opt.append(('formulaTreatBlanksAs', f.get('treatBlanksAs', 'BlankAsZero')))
        rt = f['returnType']
        if rt in ('Number', 'Currency', 'Percent'):
            opt.append(('precision', f.get('precision', 18)))
            opt.append(('scale', f.get('scale', 0)))
    if t == 'Summary':
        opt.append(('summaryForeignKey', f['summaryForeignKey']))
        opt.append(('summaryOperation', f['summaryOperation']))
        if f.get('summarizedField'):
            opt.append(('summarizedField', f['summarizedField']))
        if f.get('summaryFilterItems'):
            opt.append(('summaryFilterItems', [{'field': i['field'], 'operation': i['operation'], 'value': i.get('value')}
                                               for i in f['summaryFilterItems']]))
    if t in ('Picklist', 'MultiselectPicklist'):
        if f.get('valueSetName'):
            opt.append(('valueSet', {'restricted': True, 'valueSetName': f['valueSetName']}))
        else:
            vals = [{'fullName': v['api'], 'default': v['api'] == f.get('default'), 'label': lbl(v.get('label')) or v['api']}
                    for v in f['values']]
            opt.append(('valueSet', {'restricted': f.get('restricted', True),
                                     'valueSetDefinition': {'sorted': False, 'value': vals}}))
        if t == 'MultiselectPicklist':
            opt.append(('visibleLines', f.get('visibleLines', 4)))
    if t in ('Text', 'Number', 'Email') and f.get('externalId'):
        opt.append(('externalId', True))
    if f.get('unique'):
        opt.append(('unique', True))
        if t == 'Text':
            opt.append(('caseSensitive', f.get('caseSensitive', False)))
    if t not in ('MasterDetail', 'Formula', 'Summary', 'Checkbox', 'MultiselectPicklist'):
        opt.append(('required', f.get('required', False)))
    if t not in ('Formula', 'Summary'):
        opt.append(('trackHistory', f.get('trackHistory', False)))
        opt.append(('trackTrending', False))
    opt.append(('type', f['returnType'] if t == 'Formula' else t))
    return doc('CustomField', body + sorted(opt, key=lambda kv: kv[0]))


def field_translation(f, lang):
    body = []
    if f.get('help') and lbl(f['help'], lang):
        body.append(('help', lbl(f['help'], lang)))
    body.append(('label', lbl(f['label'], lang) or lbl(f['label'])))
    if f.get('lookupFilter', {}).get('errorMessage') and lbl(f['lookupFilter'].get('errorMessageI18n'), lang):
        body.append(('lookupFilter', {'errorMessage': lbl(f['lookupFilter']['errorMessageI18n'], lang)}))
    body.append(('name', f['name']))
    if f['type'] in ('Picklist', 'MultiselectPicklist') and not f.get('valueSetName'):
        pv = [{'masterLabel': lbl(v.get('label')) or v['api'], 'translation': lbl(v.get('label'), lang) or v['api']}
              for v in f['values']]
        body.append(('picklistValues', pv))
    if f['type'] in ('Lookup', 'MasterDetail') and f.get('relationshipLabel'):
        body.append(('relationshipLabel', lbl(f['relationshipLabel'], lang)))
    return doc('CustomFieldTranslation', body)


# ---------------------------------------------------------------- 객체
def build_special(spec, base):
    """Custom Metadata 유형(mdt), Platform Event(event), 계층형 Custom Setting(setting)."""
    obj, kind = spec['object'], spec['kind']
    if kind == 'mdt':
        body = [('description', spec.get('description')), ('label', lbl(spec['label'])),
                ('pluralLabel', lbl(spec['plural'])), ('visibility', 'Public')]
    elif kind == 'event':
        body = [('deploymentStatus', 'Deployed'), ('description', spec.get('description')),
                ('eventType', 'HighVolume'), ('label', lbl(spec['label'])), ('pluralLabel', lbl(spec['plural'])),
                ('publishBehavior', spec.get('publishBehavior', 'PublishAfterCommit'))]
    else:
        body = [('customSettingsType', 'Hierarchy'), ('description', spec.get('description')),
                ('enableFeeds', False), ('label', lbl(spec['label'])), ('visibility', 'Public')]
    emit(f'{base}/objects/{obj}/{obj}.object-meta.xml', doc('CustomObject', body))
    for f in spec.get('fields', []):
        xml = field_xml(f, spec)
        if kind == 'mdt':
            xml = xml.replace('    <label>', '    <fieldManageability>DeveloperControlled</fieldManageability>\n    <label>', 1)
        if kind != 'object':
            xml = xml.replace('    <trackHistory>false</trackHistory>\n', '').replace('    <trackTrending>false</trackTrending>\n', '')
        emit(f'{base}/objects/{obj}/fields/{f["name"]}.field-meta.xml', xml)
    for r in spec.get('records', []):
        mdt = obj[:-len('__mdt')]
        vals = ''
        for k, v in r.get('values', {}).items():
            if v is None:
                vals += f'    <values>\n        <field>{k}</field>\n        <value xsi:nil="true"/>\n    </values>\n'
                continue
            t = 'xsd:boolean' if isinstance(v, bool) else ('xsd:double' if isinstance(v, (int, float)) else 'xsd:string')
            vals += f'    <values>\n        <field>{k}</field>\n        <value xsi:type="{t}">{x(v)}</value>\n    </values>\n'
        emit(f'{base}/customMetadata/{mdt}.{r["name"]}.md-meta.xml',
             '<?xml version="1.0" encoding="UTF-8" ?>\n'
             f'<CustomMetadata xmlns="{NS}" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
             'xmlns:xsd="http://www.w3.org/2001/XMLSchema">\n'
             f'    <label>{x(r.get("label", r["name"]))}</label>\n    <protected>false</protected>\n{vals}</CustomMetadata>\n')


label_trans = {lang: [] for lang in LANGS}


def build_labels(spec):
    base = f'{spec["package"]}/main/default'
    for l in spec['labels']:
        emit(f'{base}/labels/{l["name"]}.label-meta.xml', doc('CustomLabel', [
            ('fullName', l['name']), ('categories', l.get('category', l['name'].split('_')[0])), ('language', 'ko'),
            ('protected', False), ('shortDescription', l.get('description', l['name'])[:80]), ('value', lbl(l['value']))]))
        for lang in LANGS:
            label_trans[lang].append({'label': lbl(l['value'], lang) or lbl(l['value']), 'name': l['name']})


def build_translations():
    """조직 전체 Translations(언어별 1개)는 force-app-cmn에 모은다. 같은 언어 파일이 패키지마다 있으면 배포가 충돌한다."""
    for lang in LANGS:
        items = sorted(label_trans[lang], key=lambda d: d['name'])
        if items:
            emit(f'force-app-cmn/main/default/translations/{lang}.translation-meta.xml',
                 doc('Translations', [('customLabels', items)]))


def build_object(spec):
    obj, pkg = spec['object'], spec['package']
    base = f'{pkg}/main/default'
    std = spec.get('standard', False)
    if spec.get('kind', 'object') != 'object':
        build_special(spec, base)
        return
    if not std:
        body = [
            ('allowInChatterGroups', False),
            ('deploymentStatus', 'Deployed'),
            ('description', spec.get('description')),
            ('enableActivities', spec.get('enableActivities', False)),
            ('enableBulkApi', True),
            ('enableFeeds', False),
            ('enableHistory', spec.get('enableHistory', False)),
            ('enableLicensing', False),
            ('enableReports', spec.get('enableReports', True)),
            ('enableSearch', spec.get('enableSearch', True)),
            ('enableSharing', True),
            ('enableStreamingApi', True),
            ('externalSharingModel', spec.get('externalSharingModel', spec.get('sharingModel', 'Private'))),
            ('label', lbl(spec['label'])),
        ]
        nf = spec['nameField']
        nfx = {'label': lbl(nf['label']), 'trackHistory': False, 'type': nf.get('type', 'Text')}
        if nf.get('type') == 'AutoNumber':
            nfx = {'displayFormat': nf['format'], 'label': lbl(nf['label']), 'trackHistory': False, 'type': 'AutoNumber'}
        body += [('nameField', nfx), ('pluralLabel', lbl(spec['plural'])),
                 ('sharingModel', spec.get('sharingModel', 'Private')), ('visibility', 'Public')]
        emit(f'{base}/objects/{obj}/{obj}.object-meta.xml', doc('CustomObject', body))
    for f in spec.get('fields', []):
        emit(f'{base}/objects/{obj}/fields/{f["name"]}.field-meta.xml', field_xml(f, spec))
    picks = [f for f in spec.get('fields', []) if f['type'] in ('Picklist', 'MultiselectPicklist') and not f.get('valueSetName')]
    for rt in spec.get('recordTypes', []):
        pv = []
        for f in picks:
            allowed = rt.get('picklists', {}).get(f['name']) or [v['api'] for v in f['values']]
            pv.append({'picklist': f['name'], 'values': [{'fullName': a, 'default': a == f.get('default')} for a in allowed]})
        emit(f'{base}/objects/{obj}/recordTypes/{rt["name"]}.recordType-meta.xml', doc('RecordType', [
            ('fullName', rt['name']), ('active', True), ('description', rt.get('description')),
            ('label', lbl(rt['label'])), ('picklistValues', pv or None)]))
    for vr in spec.get('validationRules', []):
        emit(f'{base}/objects/{obj}/validationRules/{vr["name"]}.validationRule-meta.xml', doc('ValidationRule', [
            ('fullName', vr['name']), ('active', vr.get('active', True)), ('description', vr.get('description')),
            ('errorConditionFormula', vr['formula']), ('errorDisplayField', vr.get('field')),
            ('errorMessage', lbl(vr['message']))]))
    if spec.get('tab') and not std:
        emit(f'{base}/tabs/{obj}.tab-meta.xml', doc('CustomTab', [
            ('customObject', True), ('motif', spec['tab'].get('motif', 'Custom57: Building'))]))
    for lang in LANGS:
        tdir = f'{base}/objectTranslations/{obj}-{lang}'
        body = []
        if not std:
            if lang == 'en_US':
                body.append(('caseValues', [{'plural': False, 'value': lbl(spec['label'], lang)},
                                            {'plural': True, 'value': lbl(spec['plural'], lang)}]))
            else:
                body.append(('caseValues', {'plural': False, 'value': lbl(spec['label'], lang)}))
            body.append(('nameFieldLabel', lbl(spec['nameField']['label'], lang)))
        rts = [{'label': lbl(rt['label'], lang), 'name': rt['name']} for rt in spec.get('recordTypes', [])]
        if rts:
            body.append(('recordTypes', rts))
        if not std and lang == 'en_US':
            # 영어 객체 번역은 관사 선택용 startsWith가 필수다
            first = (lbl(spec['label'], lang) or 'x')[0].lower()
            body.append(('startsWith', 'Vowel' if first in 'aeiou' else 'Consonant'))
        vrs = [{'errorMessage': lbl(vr['message'], lang), 'name': vr['name']} for vr in spec.get('validationRules', [])]
        if vrs:
            body.append(('validationRules', vrs))
        emit(f'{tdir}/{obj}-{lang}.objectTranslation-meta.xml', doc('CustomObjectTranslation', body))
        for f in spec.get('fields', []):
            emit(f'{tdir}/{f["name"]}.fieldTranslation-meta.xml', field_translation(f, lang))


# ---------------------------------------------------------------- 권한 셋
def field_names(spec_index, obj):
    s = spec_index.get(obj)
    return [] if not s else s.get('fields', [])


def build_permset(ps, spec_index):
    pkg = ps['package']
    objs, fields = [], []
    access = {
        'read': dict(allowCreate=False, allowDelete=False, allowEdit=False, allowRead=True, modifyAllRecords=False, viewAllRecords=False),
        'edit': dict(allowCreate=True, allowDelete=False, allowEdit=True, allowRead=True, modifyAllRecords=False, viewAllRecords=False),
        'edit-delete': dict(allowCreate=True, allowDelete=True, allowEdit=True, allowRead=True, modifyAllRecords=False, viewAllRecords=False),
        'viewall': dict(allowCreate=False, allowDelete=False, allowEdit=False, allowRead=True, modifyAllRecords=False, viewAllRecords=True),
        'admin': dict(allowCreate=True, allowDelete=True, allowEdit=True, allowRead=True, modifyAllRecords=True, viewAllRecords=True),
    }
    for obj, mode in ps.get('objects', {}).items():
        a = access[mode] if isinstance(mode, str) else mode
        objs.append(dict(a, object=obj))
        writable = a['allowEdit'] or a['allowCreate']
        readonly = set(ps.get('readOnlyFields', {}).get(obj, []))
        for f in field_names(spec_index, obj):
            if f['type'] == 'MasterDetail' or f.get('required'):
                continue  # 필수·주종 필드는 권한 셋에 넣을 수 없다(항상 접근)
            calc = f['type'] in ('Formula', 'Summary')
            edit = writable and not calc and f['name'] not in readonly and not f.get('serviceOnly')
            fields.append({'editable': edit, 'field': f'{obj}.{f["name"]}', 'readable': True})
    body = [('applicationVisibilities', [{'application': a, 'visible': True} for a in ps.get('apps', [])] or None),
            ('classAccesses', [{'apexClass': c, 'enabled': True} for c in sorted(ps.get('classes', []))] or None),
            ('customPermissions', [{'enabled': True, 'name': c} for c in sorted(ps.get('customPermissions', []))] or None),
            ('description', ps.get('description')),
            ('fieldPermissions', sorted(fields, key=lambda d: d['field']) or None),
            ('hasActivationRequired', False),
            ('label', ps['label']),
            ('license', ps.get('license')),
            ('objectPermissions', sorted(objs, key=lambda d: d['object']) or None),
            ('recordTypeVisibilities', [{'recordType': r, 'visible': True} for r in ps.get('recordTypes', [])] or None),
            ('tabSettings', [{'tab': t, 'visibility': 'Visible'} for t in ps.get('tabs', [])] or None),
            ('userPermissions', [{'enabled': True, 'name': u} for u in sorted(ps.get('userPermissions', []))] or None)]
    emit(f'{pkg}/main/default/permissionsets/{ps["name"]}.permissionset-meta.xml', doc('PermissionSet', body))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('files', nargs='*')
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    all_specs = sorted(glob.glob(os.path.join(SRC, '**', '*.json'), recursive=True))
    objects = {}
    for p in all_specs:
        with open(p, encoding='utf-8') as f:
            d = json.load(f)
        if 'object' in d:
            objects[d['object']] = d
    # 번역 파일은 모든 라벨을 모아야 하므로 항상 전체를 처리하고, 쓰기만 대상 파일로 한정하지 않는다
    targets = all_specs
    for p in targets:
        with open(p, encoding='utf-8') as f:
            d = json.load(f)
        if 'object' in d:
            build_object(d)
        elif 'permissionSet' in d:
            build_permset(d['permissionSet'], objects)
        elif 'labels' in d:
            build_labels(d)
    build_translations()
    if a.check:
        diff = [p for p, c in written.items() if not os.path.exists(p) or open(p, encoding='utf-8').read() != c]
        for p in diff:
            print('최신 아님:', os.path.relpath(p, ROOT))
        print(f'정의 {len(targets)}개, 파일 {len(written)}개, 다른 파일 {len(diff)}개')
        sys.exit(1 if diff else 0)
    for p, c in written.items():
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w', encoding='utf-8') as f:
            f.write(c)
    print(f'정의 {len(targets)}개 → 파일 {len(written)}개')


if __name__ == '__main__':
    main()
