#!/usr/bin/env python3
"""화면 우선 개발 자리 구현 참조 수(A0 프로토 공용 장치, 화면 우선 플랜 4.3-4).

A단계 업무 동작은 CMN_Prototype.notYetAvailable()(Apex)·CMN_Prototype_NotYetAvailable(라벨)·CMN_Prototype.mockResponse()로 막아 둔다.
B단계에서 서비스 본문을 채우면 참조가 사라져야 한다. 이 스크립트는 메뉴·WI·파일별 참조 수를 보이고,
--menu로 준 메뉴(예: QMS-03)에 참조가 남아 있으면 종료 코드 1을 돌려준다(그 메뉴 B단계 완료 조건).

    python3 scripts/ci/check-prototype-stubs.py                 # 전체 표
    python3 scripts/ci/check-prototype-stubs.py --menu QMS-03   # QMS-03 참조 0건이어야 통과
    python3 scripts/ci/check-prototype-stubs.py --json

WI는 파일 머리 주석의 WI ID(@group 또는 첫 번째 "{시스템}-{메뉴}-{기능}-{순번}")로 정하고, 없으면 파일 접두어로 메뉴만 정한다.
"""
import argparse
import collections
import glob
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
PATTERNS = [re.compile(r'\bCMN_Prototype\.(notYetAvailable|mockResponse|isActive)\b'),
            re.compile(r'\bCMN_Prototype_NotYetAvailable\b')]
WI_RE = re.compile(r'\b((?:CMN|QMS|PMS)-\d{2}-[A-Z0-9]+-\d{3}[a-z]?)\b')
# 장치 자체와 그 테스트·배지는 세지 않는다
OWN = {'CMN_Prototype.cls', 'CMN_Prototype_Test.cls', 'cmnPrototypeBadge.js', 'A0-prototype-kit.json'}


def files():
    out = []
    for pkg in glob.glob(os.path.join(ROOT, 'force-app-*', 'main', 'default')):
        out += glob.glob(os.path.join(pkg, 'classes', '*.cls'))
        out += glob.glob(os.path.join(pkg, 'triggers', '*.trigger'))
        out += [p for p in glob.glob(os.path.join(pkg, 'lwc', '*', '*.*')) if p.endswith(('.js', '.html'))]
    return sorted(p for p in out if os.path.basename(p) not in OWN and '__tests__' not in p)


def owner(path, text):
    m = WI_RE.search(text[:2000])
    if m:
        wi = m.group(1)
        return wi[:6], wi
    name = os.path.basename(path)
    prefix = name[:3].upper()
    return (prefix if prefix in ('CMN', 'QMS', 'PMS') else 'ETC'), '-'


def scan():
    rows = []
    for path in files():
        text = open(path, encoding='utf-8').read()
        count = sum(len(p.findall(text)) for p in PATTERNS)
        if count:
            menu, wi = owner(path, text)
            rows.append({'menu': menu, 'wi': wi, 'file': os.path.relpath(path, ROOT), 'count': count})
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--menu', help='이 메뉴(예: QMS-03)에 참조가 있으면 실패')
    ap.add_argument('--json', action='store_true')
    a = ap.parse_args()
    rows = scan()
    if a.json:
        print(json.dumps(rows, ensure_ascii=False, indent=2))
    else:
        by_menu = collections.Counter()
        for r in rows:
            by_menu[r['menu']] += r['count']
        print('| 메뉴 | WI | 파일 | 참조 |\n| --- | --- | --- | --- |')
        for r in sorted(rows, key=lambda r: (r['menu'], r['wi'], r['file'])):
            print(f"| {r['menu']} | {r['wi']} | {r['file']} | {r['count']} |")
        print('\n메뉴별 합계: ' + (', '.join(f'{m} {c}' for m, c in sorted(by_menu.items())) or '없음'))
    if a.menu:
        left = [r for r in rows if r['menu'] == a.menu or r['wi'].startswith(a.menu)]
        if left:
            print(f'{a.menu}: 자리 구현 참조 {sum(r["count"] for r in left)}건 — B단계 미완료')
            sys.exit(1)
        print(f'{a.menu}: 자리 구현 참조 0건')


if __name__ == '__main__':
    main()
