#!/usr/bin/env python3
"""상태·권한 화면 제어 동기화(CMN-00-UX-005 BR-2·3).

원천은 meta-src/*/ui-rules/{객체}.json이다. 같은 정의로
- metagen.py가 CMN_UiRule__mdt·CMN_UiSection__mdt 레코드(서버 검증 CMN_UiRuleService)를 만들고,
- 이 스크립트가 FlexiPage(업무 레코드 표준 페이지)의 가시성 규칙을 고친다.

    python3 scripts/dev/ui-rule-sync.py           # FlexiPage 갱신
    python3 scripts/dev/ui-rule-sync.py --check   # 규칙과 FlexiPage가 어긋나면 종료 코드 1(CI)
    python3 scripts/dev/ui-rule-sync.py --doc     # 상태 × 섹션·버튼·컴포넌트 매트릭스(md)

FlexiPage에 하는 일
- SECTION: Dynamic Forms에는 조건부 읽기 전용이 없어서 섹션 쌍을 둔다.
  편집 섹션 `{Key}EditSection`(record-page.py가 만듦)은 허용 조건일 때 보이고,
  읽기 섹션 `{Key}ReadOnlySection`(없으면 만듦, 같은 필드 읽기 전용)은 그 부정일 때 보인다.
- ACTION: 하이라이트 패널을 Dynamic Actions로 바꾸고 규칙이 있는 버튼만 조건과 함께 넣는다(규칙 없는 버튼은 숨김).
- COMPONENT: 식별자가 키인 컴포넌트에 가시성 규칙을 단다.
  mode EDIT인 COMPONENT 규칙은 화면 가시성이 아니라 편집 가능 여부 판정 전용이라(UX-006 그리드 EditRuleKey) 페이지에 손대지 않는다.
허용 조건 = 규칙 행들의 OR. 행 하나 = 상태 ∈ 값 AND 권한 AND 레코드 타입 AND 폼 팩터 AND 추가 조건.
"""
import argparse
import copy
import glob
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
NS = 'http://soap.sforce.com/2006/04/metadata'
Q = '{%s}' % NS
MAX_CRITERIA = 10
ET.register_namespace('', NS)


def specs():
    out = []
    for p in sorted(glob.glob(os.path.join(ROOT, 'meta-src', '*', 'ui-rules', '*.json'))):
        out.append(json.load(open(p, encoding='utf-8'))['uiRules'])
    return out


# ---------------------------------------------------------------- 조건식
def row_terms(rule, spec):
    """규칙 행 하나 → [(criteria 묶음, 'OR'|'AND')] 목록. 빈 목록이면 항상 참."""
    status_field = rule.get('statusField', spec.get('statusField', 'Status__c'))
    terms = []
    if rule.get('status'):
        terms.append(([(f'{{!Record.{status_field}}}', 'EQUAL', v) for v in rule['status']], 'OR'))
    if rule.get('permission'):
        terms.append(([(f"{{!$Permission.CustomPermission.{rule['permission']}}}", 'EQUAL', 'true')], 'AND'))
    if rule.get('recordTypes'):
        terms.append(([('{!Record.RecordType.DeveloperName}', 'EQUAL', rt) for rt in rule['recordTypes']], 'OR'))
    ff = rule.get('formFactor', 'ALL')
    if ff == 'SMALL':
        terms.append(([('{!$Client.FormFactor}', 'EQUAL', 'Small')], 'AND'))
    elif ff == 'LARGE':
        terms.append(([('{!$Client.FormFactor}', 'NE', 'Small')], 'AND'))
    if rule.get('extra'):
        m = re.match(r'^(\w+)(!=|=)(.*)$', rule['extra'])
        if not m:
            sys.exit(f"{spec['object']} {rule['key']}: 추가 조건 형식 오류 {rule['extra']} (Field__c=VALUE 또는 Field__c!=VALUE)")
        terms.append(([(f'{{!Record.{m.group(1)}}}', 'NE' if m.group(2) == '!=' else 'EQUAL', m.group(3))], 'AND'))
    return terms


def expression(rows, spec, key):
    """규칙 행들 → (criteria, booleanFilter). 항상 참이면 None. 행이 없으면 오류(기본 거부는 화면에 두지 않는다)."""
    if not rows:
        sys.exit(f"{spec['object']} {key}: 규칙이 없다 — 읽기 전용 섹션은 현재 단계에서 빼고 상세 탭에 둔다")
    criteria, ors = [], []
    for rule in rows:
        terms = row_terms(rule, spec)
        if not terms:
            return None  # 한 행이라도 조건이 없으면 항상 허용
        ands = []
        for items, join in terms:
            idx = []
            for c in items:
                criteria.append(c)
                idx.append(str(len(criteria)))
            ands.append(idx[0] if len(idx) == 1 else '(' + f' {join} '.join(idx) + ')')
        ors.append(ands[0] if len(ands) == 1 else '(' + ' AND '.join(ands) + ')')
    if len(criteria) > MAX_CRITERIA:
        sys.exit(f"{spec['object']} {key}: 조건 {len(criteria)}개 — 가시성 필터 한도 {MAX_CRITERIA}개를 넘는다. 규칙을 줄인다")
    expr = ors[0] if len(ors) == 1 else ' OR '.join(ors)
    return criteria, expr


FLIP = {'EQUAL': 'NE', 'NE': 'EQUAL'}


def visibility(expr_pair, negate=False):
    """조건이 하나면 부울 필터를 쓸 수 없어(플랫폼 규칙) 부정은 연산자를 뒤집는다."""
    criteria, expr = expr_pair
    rule = ET.Element(Q + 'visibilityRule')
    if len(criteria) == 1 and negate:
        left, op, right = criteria[0]
        criteria = [(left, FLIP[op], right)]
    elif len(criteria) > 1:
        ET.SubElement(rule, Q + 'booleanFilter').text = f'NOT({expr})' if negate else expr
    for left, op, right in criteria:
        c = ET.SubElement(rule, Q + 'criteria')
        ET.SubElement(c, Q + 'leftValue').text = left
        ET.SubElement(c, Q + 'operator').text = op
        ET.SubElement(c, Q + 'rightValue').text = right
    return rule


def canon(el):
    return '' if el is None else ET.tostring(el, encoding='unicode').replace(' ', '').replace('\n', '')


# ---------------------------------------------------------------- FlexiPage
class Page:
    def __init__(self, path):
        self.path = path
        self.tree = ET.parse(path)
        self.root = self.tree.getroot()

    def comps(self):
        for region in self.root.findall(Q + 'flexiPageRegions'):
            for item in region.findall(Q + 'itemInstances'):
                comp = item.find(Q + 'componentInstance')
                if comp is not None:
                    yield region, item, comp

    def find(self, ident):
        for region, item, comp in self.comps():
            if comp.findtext(Q + 'identifier') == ident:
                return region, item, comp
        return None

    def by_name(self, name):
        return [c for _, _, c in self.comps() if c.findtext(Q + 'componentName') == name]

    def region(self, name):
        for r in self.root.findall(Q + 'flexiPageRegions'):
            if r.findtext(Q + 'name') == name:
                return r
        return None

    def add_region(self, name, items):
        region = ET.Element(Q + 'flexiPageRegions')
        for it in items:
            region.append(it)
        ET.SubElement(region, Q + 'name').text = name
        ET.SubElement(region, Q + 'type').text = 'Facet'
        last = max(i for i, el in enumerate(list(self.root)) if el.tag == Q + 'flexiPageRegions')
        self.root.insert(last + 1, region)

    def save(self):
        ET.indent(self.tree, space='    ')
        self.tree.write(self.path, encoding='UTF-8', xml_declaration=True)


def set_visibility(comp, rule_el):
    old = comp.find(Q + 'visibilityRule')
    if old is not None:
        comp.remove(old)
    if rule_el is not None:
        comp.append(rule_el)


def comp_item(name, ident, props):
    item = ET.Element(Q + 'itemInstances')
    comp = ET.SubElement(item, Q + 'componentInstance')
    for k, v in props:
        p = ET.SubElement(comp, Q + 'componentInstanceProperties')
        ET.SubElement(p, Q + 'name').text = k
        ET.SubElement(p, Q + 'value').text = v
    ET.SubElement(comp, Q + 'componentName').text = name
    ET.SubElement(comp, Q + 'identifier').text = ident
    return item, comp


def field_item(field, ident):
    item = ET.Element(Q + 'itemInstances')
    fi = ET.SubElement(item, Q + 'fieldInstance')
    p = ET.SubElement(fi, Q + 'fieldInstanceProperties')
    ET.SubElement(p, Q + 'name').text = 'uiBehavior'
    ET.SubElement(p, Q + 'value').text = 'readonly'
    ET.SubElement(fi, Q + 'fieldItem').text = f'Record.{field}'
    ET.SubElement(fi, Q + 'identifier').text = ident
    return item


def ensure_read_section(page, section, edit_item, edit_region):
    """편집 섹션 바로 뒤에 같은 필드의 읽기 전용 섹션을 만든다(있으면 그대로)."""
    ident = f"{section['key']}ReadOnlySection"
    found = page.find(ident)
    if found:
        return found[2]
    key = section['key'] + 'ReadOnly'
    cols = [[], []]
    for i, f in enumerate(section['fields']):
        cols[i % 2].append(field_item(f, f"Record{f.replace('__c', '')}{key}Field"))
    col_names = []
    for n, items in enumerate(cols, 1):
        name = f'Facet-{key}Col{n}'
        page.add_region(name, items)
        col_names.append(name)
    column_items = [comp_item('flexipage:column', f'{key}Column{n}', [('body', c)])[0] for n, c in enumerate(col_names, 1)]
    page.add_region(f'Facet-{key}Columns', column_items)
    item, comp = comp_item('flexipage:fieldSection', ident, [
        ('columns', f'Facet-{key}Columns'), ('horizontalAlignment', 'false'),
        ('label', '{!$Label.%s}' % section['label'])])
    children = list(edit_region)
    edit_region.insert(children.index(edit_item) + 1, item)
    return comp


def action_list(spec, rules, phone):
    """하이라이트 패널 Dynamic Actions 속성(actionNames 등)."""
    props = []
    names = ET.Element(Q + 'componentInstanceProperties')
    ET.SubElement(names, Q + 'name').text = 'actionNames'
    vl = ET.SubElement(names, Q + 'valueList')
    keys = []
    for r in rules:
        if r['target'] == 'ACTION' and r['key'] not in keys:
            keys.append(r['key'])
    for key in keys:
        item = ET.SubElement(vl, Q + 'valueListItems')
        ET.SubElement(item, Q + 'value').text = key
        expr = expression([r for r in rules if r['target'] == 'ACTION' and r['key'] == key], spec, key)
        if expr:
            item.append(visibility(expr))
    props.append(names)
    for k, v in (('collapsed', 'false'), ('enableActionsConfiguration', 'true'),
                 ('enableActionsInNative', 'true' if phone else 'false'), ('hideChatterActions', 'false'),
                 ('numVisibleActions', '3')):
        p = ET.Element(Q + 'componentInstanceProperties')
        ET.SubElement(p, Q + 'name').text = k
        ET.SubElement(p, Q + 'value').text = v
        props.append(p)
    return props


def apply(spec, page, phone, problems):
    rules = spec['rules']
    changed = False
    for section in spec['sections']:
        rows = [r for r in rules if r['target'] == 'SECTION' and r['key'] == section['key']]
        found = page.find(f"{section['key']}EditSection")
        if not found:
            problems.append(f"{page.path}: 편집 섹션 {section['key']}EditSection이 없다(record-page.py 정의와 키를 맞춘다)")
            continue
        region, item, edit = found
        expr = expression(rows, spec, section['key'])
        want_edit = visibility(expr) if expr else None
        read = page.find(f"{section['key']}ReadOnlySection")
        if canon(edit.find(Q + 'visibilityRule')) != canon(want_edit):
            problems.append(f"{os.path.basename(page.path)}: {section['key']} 편집 섹션 가시성 불일치")
            set_visibility(edit, want_edit)
            changed = True
        if expr is None:
            continue  # 항상 편집 가능 → 읽기 섹션 불필요
        want_read = visibility(expr, negate=True)
        if read is None:
            problems.append(f"{os.path.basename(page.path)}: {section['key']} 읽기 섹션 없음")
            read_comp = ensure_read_section(page, section, item, region)
            set_visibility(read_comp, want_read)
            changed = True
        elif canon(read[2].find(Q + 'visibilityRule')) != canon(want_read):
            problems.append(f"{os.path.basename(page.path)}: {section['key']} 읽기 섹션 가시성 불일치")
            set_visibility(read[2], want_read)
            changed = True
    if any(r['target'] == 'ACTION' for r in rules):
        for hp in page.by_name('force:highlightsPanel'):
            want = action_list(spec, rules, phone)
            have = [p for p in hp.findall(Q + 'componentInstanceProperties')]
            if [canon(p) for p in have] != [canon(p) for p in want]:
                problems.append(f"{os.path.basename(page.path)}: 버튼(Dynamic Actions) 규칙 불일치")
                for p in have:
                    hp.remove(p)
                for n, p in enumerate(want):
                    hp.insert(n, p)
                changed = True
    shown = [r for r in rules if r['target'] == 'COMPONENT' and r.get('mode', 'SHOW') != 'EDIT']
    for key in dict.fromkeys(r['key'] for r in shown):
        found = page.find(key)
        if not found:
            problems.append(f"{os.path.basename(page.path)}: 컴포넌트 {key}가 없다")
            continue
        expr = expression([r for r in shown if r['key'] == key], spec, key)
        want = visibility(expr) if expr else None
        if canon(found[2].find(Q + 'visibilityRule')) != canon(want):
            problems.append(f"{os.path.basename(page.path)}: 컴포넌트 {key} 가시성 불일치")
            set_visibility(found[2], want)
            changed = True
    return changed


def validate(spec, problems):
    for r in spec['rules']:
        perm = r.get('permission')
        if perm and not glob.glob(os.path.join(ROOT, 'force-app-*', 'main', 'default', 'customPermissions', f'{perm}.customPermission-meta.xml')):
            problems.append(f"{spec['object']} {r['key']}: Custom Permission {perm}이 없다")
        unknown = set(r.get('status', [])) - set(spec.get('statuses', r.get('status', [])))
        if unknown:
            problems.append(f"{spec['object']} {r['key']}: 정의에 없는 상태값 {sorted(unknown)}")
    for r in spec['rules']:
        if r.get('mode', 'SHOW') not in ('SHOW', 'EDIT') or (r.get('mode') == 'EDIT' and r['target'] != 'COMPONENT'):
            problems.append(f"{spec['object']} {r['key']}: mode는 COMPONENT 규칙에만 EDIT로 쓴다")
    keys = {s['key'] for s in spec['sections']}
    for r in spec['rules']:
        if r['target'] == 'SECTION' and r['key'] not in keys:
            problems.append(f"{spec['object']}: 섹션 규칙 {r['key']}의 섹션 정의가 없다")


def doc(spec):
    statuses = spec.get('statuses') or sorted({v for r in spec['rules'] for v in r.get('status', [])})
    lines = [f"### {spec['object']}", '', '| 대상 | 종류 | ' + ' | '.join(statuses) + ' | 조건 |',
             '| --- | --- | ' + ' | '.join('---' for _ in statuses) + ' | --- |']
    for kind in ('SECTION', 'ACTION', 'COMPONENT'):
        for key in dict.fromkeys(r['key'] for r in spec['rules'] if r['target'] == kind):
            rows = [r for r in spec['rules'] if r['target'] == kind and r['key'] == key]
            editing = kind == 'SECTION' or rows[0].get('mode') == 'EDIT'
            mark = '편집' if editing else '표시'
            deny = '읽기' if editing else '숨김'
            cells = []
            for st in statuses:
                ok = [r for r in rows if not r.get('status') or st in r['status']]
                cells.append((mark + ('*' if all(r.get('permission') or r.get('recordTypes') or r.get('extra') for r in ok) else '')) if ok else deny)
            cond = '; '.join(filter(None, [', '.join(filter(None, [
                f"권한 {r['permission']}" if r.get('permission') else '',
                f"레코드 타입 {'/'.join(r['recordTypes'])}" if r.get('recordTypes') else '',
                f"화면 {r['formFactor']}" if r.get('formFactor', 'ALL') != 'ALL' else '',
                f"추가 {r['extra']}" if r.get('extra') else ''])) for r in rows]))
            lines.append(f'| {key} | {kind} | ' + ' | '.join(cells) + f' | {cond or "-"} |')
    lines += ['', '`*` = 조건(권한·레코드 타입·추가 조건)을 만족할 때만.', '']
    return '\n'.join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--doc', action='store_true')
    a = ap.parse_args()
    all_specs = specs()
    if a.doc:
        print('\n'.join(doc(s) for s in all_specs))
        return
    problems, changed_files = [], []
    for spec in all_specs:
        validate(spec, problems)
        for name in spec.get('pages', []):
            path = os.path.join(ROOT, spec['package'], 'main', 'default', 'flexipages', f'{name}.flexipage-meta.xml')
            if not os.path.exists(path):
                problems.append(f'{path}: 페이지가 없다')
                continue
            page = Page(path)
            if apply(spec, page, name in spec.get('phonePages', []), problems):
                changed_files.append(page)
    if a.check:
        for p in problems:
            print(p)
        print(f'화면 제어 규칙 불일치 {len(problems)}건')
        sys.exit(1 if problems else 0)
    for page in changed_files:
        page.save()
        print('갱신:', os.path.relpath(page.path, ROOT))
    blocking = [p for p in problems if '없다' in p and '읽기 섹션 없음' not in p]
    for p in blocking:
        print(p)
    print(f'FlexiPage {len(changed_files)}개 갱신')
    sys.exit(1 if blocking else 0)


if __name__ == '__main__':
    main()
