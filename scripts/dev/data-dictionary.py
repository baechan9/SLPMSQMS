#!/usr/bin/env python3
"""데이터 사전: 배포 소스(force-app-*)의 객체·필드를 한 문서로 모은다.

생성기 산출물(objects/, objectTranslations/)을 읽으므로 metagen 실행 뒤에 돌린다.
    python3 scripts/dev/data-dictionary.py            # docs/docs/30-dev/data-dictionary.md
"""
import glob
import json
import os
import xml.etree.ElementTree as ET
from datetime import date

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'docs/docs/30-dev/data-dictionary.md')
NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}
STANDARD = {'Account': ('거래처(고객·협력사)', 'Account'), 'User': ('사용자', 'User')}
KINDS = [('__c', '커스텀 객체'), ('std', '표준 객체 확장'), ('__mdt', '커스텀 메타데이터 유형(설정)'),
         ('__e', 'Platform Event')]


def text(el, tag):
    x = el.find('m:' + tag, NS)
    return x.text if x is not None and x.text else ''


def cell(s):
    return (s or '').replace('|', '/').replace('\n', ' ').strip()


def meta_src():
    """객체 라벨·소유 WI(정의 JSON)."""
    out = {}
    for p in glob.glob(os.path.join(ROOT, 'meta-src/*/*.json')):
        with open(p, encoding='utf-8') as f:
            d = json.load(f)
        if 'object' not in d:
            continue
        lab = d.get('label') or {}
        lab = lab if isinstance(lab, dict) else {'ko': lab}
        prev = out.get(d['object'], {})
        wis = sorted(set(prev.get('wi', [])) | {d.get('wi', '')})
        out[d['object']] = {'ko': lab.get('ko') or prev.get('ko', ''), 'en': lab.get('en_US') or prev.get('en', ''),
                            'wi': wis, 'desc': d.get('description') or prev.get('desc', '')}
    return out


def english_labels():
    out = {}
    for p in glob.glob(os.path.join(ROOT, 'force-app-*/main/default/objectTranslations/*-en_US/*.fieldTranslation-meta.xml')):
        obj = os.path.basename(os.path.dirname(p)).rsplit('-en_US', 1)[0]
        r = ET.parse(p).getroot()
        out[(obj, text(r, 'name'))] = text(r, 'label')
    return out


def field_row(r, en):
    typ = text(r, 'type')
    detail = ''
    if r.find('m:formula', NS) is not None:
        typ = f'Formula({typ})'
    elif r.find('m:summaryOperation', NS) is not None:
        typ = 'Roll-Up Summary'
    if text(r, 'referenceTo'):
        detail = '→ ' + text(r, 'referenceTo')
    values = [v.find('m:fullName', NS).text for v in r.findall('.//m:valueSetDefinition/m:value', NS)]
    if values:
        detail = ', '.join(values)
    elif text(r, 'length'):
        detail = text(r, 'length')
    elif text(r, 'precision'):
        detail = f"{text(r, 'precision')},{text(r, 'scale') or 0}"
    flags = []
    if text(r, 'required') == 'true':
        flags.append('필수')
    if text(r, 'externalId') == 'true':
        flags.append('외부 키')
    if text(r, 'unique') == 'true':
        flags.append('유일')
    return (text(r, 'fullName'), text(r, 'label'), en, typ, detail, ' '.join(flags), text(r, 'description'))


def kind_of(obj):
    if obj in STANDARD:
        return 'std'
    for suffix in ('__mdt', '__e', '__c'):
        if obj.endswith(suffix):
            return suffix
    return '__c'


def main():
    src = meta_src()
    en = english_labels()
    objects = {}
    for p in sorted(glob.glob(os.path.join(ROOT, 'force-app-*/main/default/objects/*/fields/*.field-meta.xml'))):
        obj = p.split('/objects/')[1].split('/')[0]
        r = ET.parse(p).getroot()
        objects.setdefault(obj, []).append(field_row(r, en.get((obj, text(r, 'fullName')), '')))
    # 필드가 없는 객체(이름만 쓰는 설정)도 목록에 넣는다
    for p in glob.glob(os.path.join(ROOT, 'force-app-*/main/default/objects/*/*.object-meta.xml')):
        objects.setdefault(os.path.basename(os.path.dirname(p)), [])

    lines = [
        '# 데이터 사전 — 배포된 객체와 커스텀 필드',
        '',
        f'`python3 scripts/dev/data-dictionary.py`가 배포 소스(`force-app-*`)에서 만든다. 손으로 고치지 않는다. 기준일 {date.today().isoformat()}.',
        '',
        '- 라벨(ko)은 Org 기본 라벨, Label(en)은 영어 번역이다. 중국어 번역은 소스의 objectTranslations에 있다.',
        '- 값/길이/참조: 선택 목록 값, 텍스트 길이, 숫자 자릿수(전체,소수), 관계 대상(→).',
        '- 표준 필드(Name, Owner, CreatedDate 등)는 넣지 않는다.',
        '',
        '## 요약',
        '',
        '| 구분 | 객체 수 | 커스텀 필드 수 |',
        '| --- | --- | --- |',
    ]
    groups = {k: sorted(o for o in objects if kind_of(o) == k) for k, _ in KINDS}
    for k, title in KINDS:
        lines.append(f'| {title} | {len(groups[k])} | {sum(len(objects[o]) for o in groups[k])} |')
    lines.append(f'| 합계 | {len(objects)} | {sum(len(v) for v in objects.values())} |')
    for k, title in KINDS:
        lines += ['', f'## {title}', '']
        lines += ['| 객체 | 라벨(ko) | Label(en) | 필드 수 | 소유 WI |', '| --- | --- | --- | --- | --- |']
        for o in groups[k]:
            ko, en_label = STANDARD.get(o, (src.get(o, {}).get('ko', ''), src.get(o, {}).get('en', '')))
            lines.append(f"| [{o}](#{o.lower()}) | {cell(ko)} | {cell(en_label)} | {len(objects[o])} | "
                         f"{cell(', '.join(w for w in src.get(o, {}).get('wi', []) if w))} |")
        for o in groups[k]:
            ko, en_label = STANDARD.get(o, (src.get(o, {}).get('ko', ''), src.get(o, {}).get('en', '')))
            lines += ['', f'### {o}', '', f"{cell(ko)} / {cell(en_label)}. {cell(src.get(o, {}).get('desc', ''))}".strip(), '']
            if not objects[o]:
                lines.append('커스텀 필드 없음.')
                continue
            lines += ['| API | 라벨(ko) | Label(en) | 타입 | 값/길이/참조 | 제약 | 설명 |',
                      '| --- | --- | --- | --- | --- | --- | --- |']
            for row in objects[o]:
                lines.append('| ' + ' | '.join(cell(c) for c in row) + ' |')
    with open(OUT, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print(f'객체 {len(objects)}개, 필드 {sum(len(v) for v in objects.values())}개 → {os.path.relpath(OUT, ROOT)}')


if __name__ == '__main__':
    main()
