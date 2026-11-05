#!/usr/bin/env python3
"""CMN-00-UX-004 BR-1·2·9 점검: 업무 레코드 표준 페이지(meta-src/*/record-pages 정의의 데스크톱·휴대폰 FlexiPage) 규칙.
- 데스크톱: 헤더에 하이라이트 패널, 하위 헤더에 진행 단계, 본문 탭의 첫 탭은 "현재 단계"이고 기본 선택,
  첫 탭 표시 컴포넌트 10개 이하, 관련 목록(동적 관련 목록) 3개 이하, 사이드바에는 cmnDecisionRail 하나만.
- 휴대폰: 페이지가 있고 결정 지원 레일이 있다.
- 객체 기본 보기가 데스크톱·휴대폰 페이지로 지정돼 있다(metagen 산출물).
사용: python3 scripts/ci/check-record-pages.py            # 정의된 페이지 전부
      python3 scripts/ci/check-record-pages.py <flexipage.xml> ...   # 파일 직접(이름이 _Phone으로 끝나면 휴대폰 규칙)"""
import glob
import json
import os
import sys
import xml.etree.ElementTree as ET

NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}
CURRENT_TAB_LABEL = '{!$Label.CMN_RecordPage_TabCurrent}'
MAX_FIRST_TAB = 10
MAX_RELATED = 3
RAIL = 'cmnDecisionRail'


def regions(root):
    return {r.findtext('m:name', namespaces=NS): r for r in root.findall('m:flexiPageRegions', NS)}


def components(region):
    out = []
    for item in region.findall('m:itemInstances', NS):
        comp = item.find('m:componentInstance', NS)
        if comp is not None:
            props = {p.findtext('m:name', namespaces=NS): p.findtext('m:value', namespaces=NS)
                     for p in comp.findall('m:componentInstanceProperties', NS)}
            out.append((comp.findtext('m:componentName', namespaces=NS), props))
        elif item.find('m:fieldInstance', NS) is not None:
            out.append(('field', {}))
    return out


def check_desktop(path):
    errors = []
    root = ET.parse(path).getroot()
    regs = regions(root)
    names = lambda r: [c for c, _ in components(regs[r])] if r in regs else []
    if 'force:highlightsPanel' not in names('header'):
        errors.append('헤더에 하이라이트 패널이 없다(BR-1 A)')
    if 'cmnStatusPath' not in names('subheader'):
        errors.append('하위 헤더에 cmnStatusPath가 없다(BR-1 B)')
    if names('sidebar') != [RAIL]:
        errors.append(f'사이드바에는 {RAIL} 하나만 둔다(BR-1 D): {names("sidebar")}')
    tabsets = [p for c, p in components(regs.get('main', ET.Element('x'))) if c == 'flexipage:tabset']
    if not tabsets:
        errors.append('본문에 탭이 없다(BR-2)')
    else:
        tabs = components(regs.get(tabsets[0].get('tabs'), ET.Element('x')))
        first = tabs[0][1] if tabs else {}
        if first.get('title') != CURRENT_TAB_LABEL or first.get('active') != 'true':
            errors.append('첫 탭은 "현재 단계"이고 기본 선택이어야 한다(BR-2)')
        body = components(regs.get(first.get('body'), ET.Element('x')))
        if len(body) > MAX_FIRST_TAB:
            errors.append(f'첫 탭 표시 컴포넌트 {len(body)}개 — 최대 {MAX_FIRST_TAB}개(BR-11)')
    related = sum(1 for r in regs.values() for c, _ in components(r) if c == 'lst:dynamicRelatedList')
    if related > MAX_RELATED:
        errors.append(f'관련 목록 {related}개 — 최대 {MAX_RELATED}개(BR-2)')
    return errors


def check_phone(path):
    root = ET.parse(path).getroot()
    regs = regions(root)
    found = any(c == RAIL for r in regs.values() for c, _ in components(r))
    return [] if found else [f'휴대폰 페이지에 {RAIL}가 없다(BR-8)']


def check_overrides(spec):
    obj = spec['object']
    path = f"{spec['package']}/main/default/objects/{obj}/{obj}.object-meta.xml"
    if not os.path.exists(path):
        return [f'{path}: 객체 메타데이터가 없다']
    root = ET.parse(path).getroot()
    got = {o.findtext('m:formFactor', namespaces=NS): o.findtext('m:content', namespaces=NS)
           for o in root.findall('m:actionOverrides', NS) if o.findtext('m:actionName', namespaces=NS) == 'View'}
    want = {'Large': spec['name'], 'Small': spec['phoneName']}
    return [] if got == want else [f'{obj}: 기본 보기 지정 {got} — 기대값 {want}(metagen.py 재실행)']


def main():
    bad = 0
    targets = []
    if len(sys.argv) > 1:
        targets = [(p, p.endswith('_Phone.flexipage-meta.xml'), None) for p in sys.argv[1:]]
    else:
        for sp in sorted(glob.glob('meta-src/*/record-pages/*.json')):
            spec = json.load(open(sp, encoding='utf-8'))['recordPage']
            base = f"{spec['package']}/main/default/flexipages"
            targets += [(f"{base}/{spec['name']}.flexipage-meta.xml", False, spec),
                        (f"{base}/{spec['phoneName']}.flexipage-meta.xml", True, None)]
    for path, is_phone, spec in targets:
        if not os.path.exists(path):
            print(f'{path}: 페이지가 없다 — scripts/dev/record-page.py로 만든다')
            bad += 1
            continue
        errors = (check_phone if is_phone else check_desktop)(path)
        if spec:
            errors += check_overrides(spec)
        for e in errors:
            print(f'{path}: {e}')
        bad += len(errors)
    print(f'업무 레코드 페이지 규칙 위반 {bad}건({len(targets)}개 페이지)')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
