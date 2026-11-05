#!/usr/bin/env python3
"""업무 레코드 표준 페이지 생성기(CMN-00-UX-004 BR-1·2·8·9).

meta-src/*/record-pages/{객체}.json 정의로 FlexiPage 두 개(데스크톱·휴대폰)를 처음 한 번 만든다.
만든 뒤에는 FlexiPage XML이 원천이다(App Builder에서 고친 것은 retrieve로 소스에 반영). 그래서 이미 있으면 건너뛰고,
--force일 때만 덮어쓴다. 헤더 콤팩트 레이아웃과 폼 팩터별 기본 보기 지정은 metagen.py가 같은 정의로 만든다.

    python3 scripts/dev/record-page.py                 # 없는 페이지만 생성
    python3 scripts/dev/record-page.py CMN_TestRecord__c --force

배치(데스크톱, 템플릿 "헤더, 하위 헤더, 오른쪽 사이드바"):
  A header    = 하이라이트 패널(콤팩트 레이아웃 7개 필드)
  B subheader = cmnStatusPath + cmnDueIndicator
  C main      = 탭(현재 단계 / 상세 / 관련 / 이력), 첫 탭 기본 선택
  D sidebar   = cmnDecisionRail 하나
휴대폰: header = 하이라이트 패널, main = 진행 단계·기한·탭(현재 단계 / 상세), sidebar = 결정 지원 레일(본문 아래 표시)
"""
import argparse
import glob
import json
import os
import re
import sys
from xml.sax.saxutils import escape

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
DESKTOP_TEMPLATE = 'flexipage:recordHomeWithSubheaderTemplateDesktop'
PHONE_TEMPLATE = 'flexipage:recordHomeTemplateDesktop'
LABEL = '{{!$Label.{}}}'


class Page:
    """FlexiPage XML 조립기. Facet 이름과 식별자를 페이지 안에서 겹치지 않게 만든다."""

    def __init__(self):
        self.regions = []
        self.ids = set()

    def ident(self, base):
        base = re.sub(r'[^A-Za-z0-9]', '', base) or 'item'
        name, n = base, 2
        while name in self.ids:
            name, n = f'{base}{n}', n + 1
        self.ids.add(name)
        return name

    @staticmethod
    def props(props):
        out = ''
        for k, v in props:
            out += ('                <componentInstanceProperties>\n'
                    f'                    <name>{k}</name>\n'
                    f'                    <value>{escape(str(v))}</value>\n'
                    '                </componentInstanceProperties>\n')
        return out

    def comp(self, name, ident=None, props=()):
        ident = self.ident(ident or name.replace(':', '_'))
        return ('        <itemInstances>\n            <componentInstance>\n'
                f'{self.props(sorted(props))}'
                f'                <componentName>{name}</componentName>\n'
                f'                <identifier>{ident}</identifier>\n'
                '            </componentInstance>\n        </itemInstances>\n')

    def field(self, field, behavior):
        ident = self.ident(f'Record{field.replace("__c", "")}Field')
        return ('        <itemInstances>\n            <fieldInstance>\n'
                '                <fieldInstanceProperties>\n'
                '                    <name>uiBehavior</name>\n'
                f'                    <value>{behavior}</value>\n'
                '                </fieldInstanceProperties>\n'
                f'                <fieldItem>Record.{field}</fieldItem>\n'
                f'                <identifier>{ident}</identifier>\n'
                '            </fieldInstance>\n        </itemInstances>\n')

    def region(self, name, items, kind='Region'):
        self.regions.append('    <flexiPageRegions>\n' + ''.join(items) +
                            f'        <name>{name}</name>\n        <type>{kind}</type>\n    </flexiPageRegions>\n')
        return name

    def facet(self, base, items):
        return self.region(f'Facet-{self.ident(base)}', items, 'Facet')

    def xml(self, label, sobject, template):
        return ('<?xml version="1.0" encoding="UTF-8" ?>\n'
                '<FlexiPage xmlns="http://soap.sforce.com/2006/04/metadata">\n' + ''.join(self.regions) +
                f'    <masterLabel>{escape(label)}</masterLabel>\n'
                f'    <sobjectType>{sobject}</sobjectType>\n'
                f'    <template>\n        <name>{template}</name>\n    </template>\n'
                '    <type>RecordPage</type>\n</FlexiPage>\n')


def field_section(page, section, readonly, all_readonly):
    """Dynamic Forms 필드 섹션(2열). 읽기 전용 필드·상세 탭은 uiBehavior readonly."""
    cols = [[], []]
    for i, f in enumerate(section['fields']):
        behavior = 'readonly' if all_readonly or f in readonly else 'none'
        cols[i % 2].append(page.field(f, behavior))
    key = section['key'] + ('Read' if all_readonly else 'Edit')
    col_facets = [page.facet(f'{key}Col{n + 1}', items) for n, items in enumerate(cols)]
    columns = page.facet(f'{key}Columns', [page.comp('flexipage:column', f'{key}Column{n + 1}', [('body', c)])
                                           for n, c in enumerate(col_facets)])
    return page.comp('flexipage:fieldSection', f'{key}Section', [
        ('columns', columns), ('horizontalAlignment', 'false'), ('label', LABEL.format(section['label']))])


def tab(page, key, label_name, body_items, active=False):
    body = page.facet(f'{key}TabBody', body_items)
    props = [('body', body), ('title', LABEL.format(label_name))]
    if active:
        props.append(('active', 'true'))
    return page.comp('flexipage:tab', f'{key}Tab', props)


def current_items(page, spec, readonly):
    cur = spec.get('currentStep', {})
    items = [field_section(page, s, readonly, False) for s in cur.get('sections', [])]
    for c in cur.get('components', []):
        items.append(page.comp(c['name'], c.get('identifier'), sorted(c.get('properties', {}).items())))
    return items


def detail_items(page, spec, readonly):
    return [field_section(page, s, readonly, True) for s in spec.get('detailSections', [])]


def related_items(page, spec):
    lists = spec.get('relatedLists', [])
    if len(lists) > 3:
        sys.exit(f"{spec['object']}: 관련 목록 {len(lists)}개 — 최대 3개(UX-004 BR-2)")
    if not lists:
        return [page.comp('force:relatedListContainer')]
    return [page.comp('lst:dynamicRelatedList', f"related{rl['relatedListApiName']}", [
        ('parentFieldApiName', f"{spec['object']}.Id"), ('relatedListApiName', rl['relatedListApiName']),
        ('relatedListComponentOverride', 'NONE'), ('rowsToDisplay', str(rl.get('rows', 5))),
        ('showActionBar', 'true')]) for rl in lists]


def subheader_items(page, spec):
    return [page.comp('cmnStatusPath'),
            page.comp('cmnDueIndicator', props=[('daysField', spec.get('daysField', 'DaysToDue__c'))])]


def desktop(spec):
    readonly = set(spec.get('readOnlyFields', []))
    p = Page()
    tabs = p.facet('MainTabs', [
        tab(p, 'Current', 'CMN_RecordPage_TabCurrent', current_items(p, spec, readonly), active=True),
        tab(p, 'Detail', 'CMN_RecordPage_TabDetail', detail_items(p, spec, readonly)),
        tab(p, 'Related', 'CMN_RecordPage_TabRelated', related_items(p, spec)),
        tab(p, 'History', 'CMN_RecordPage_TabHistory', [p.comp('cmnApprovalHistory')]),
    ])
    p.region('header', [p.comp('force:highlightsPanel')])
    p.region('subheader', subheader_items(p, spec))
    p.region('main', [p.comp('flexipage:tabset', 'mainTabset', [('tabs', tabs)])])
    p.region('sidebar', [p.comp('cmnDecisionRail')])
    return p.xml(spec['label'], spec['object'], DESKTOP_TEMPLATE)


def phone(spec):
    readonly = set(spec.get('readOnlyFields', []))
    p = Page()
    tabs = p.facet('PhoneTabs', [
        tab(p, 'Current', 'CMN_RecordPage_TabCurrent', current_items(p, spec, readonly), active=True),
        tab(p, 'Detail', 'CMN_RecordPage_TabDetail', detail_items(p, spec, readonly)),
    ])
    p.region('header', [p.comp('force:highlightsPanel')])
    p.region('main', subheader_items(p, spec) + [p.comp('flexipage:tabset', 'phoneTabset', [('tabs', tabs)])])
    p.region('sidebar', [p.comp('cmnDecisionRail')])
    return p.xml(spec['label'] + ' Phone', spec['object'], PHONE_TEMPLATE)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('objects', nargs='*', help='객체 API명(비우면 정의 전부)')
    ap.add_argument('--force', action='store_true', help='이미 있는 FlexiPage도 덮어쓴다')
    a = ap.parse_args()
    made = 0
    for path in sorted(glob.glob(os.path.join(ROOT, 'meta-src', '*', 'record-pages', '*.json'))):
        spec = json.load(open(path, encoding='utf-8'))['recordPage']
        if a.objects and spec['object'] not in a.objects:
            continue
        base = os.path.join(ROOT, spec['package'], 'main', 'default', 'flexipages')
        os.makedirs(base, exist_ok=True)
        for name, build in ((spec['name'], desktop), (spec['phoneName'], phone)):
            target = os.path.join(base, f'{name}.flexipage-meta.xml')
            if os.path.exists(target) and not a.force:
                print('건너뜀(이미 있음):', os.path.relpath(target, ROOT))
                continue
            with open(target, 'w', encoding='utf-8') as f:
                f.write(build(spec))
            made += 1
            print('생성:', os.path.relpath(target, ROOT))
    print(f'FlexiPage {made}개 생성')


if __name__ == '__main__':
    main()
