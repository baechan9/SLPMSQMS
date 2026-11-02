#!/usr/bin/env python3
"""Apex는 식별자 대소문자를 구분하지 않는다. 클래스 상수(static final)와 대소문자만 다른 지역 변수·매개변수가 있으면
상수를 가려 "Comparison arguments must be compatible types" 같은 컴파일 오류가 난다. 배포 전에 잡는다.
사용: python3 scripts/ci/check-apex-shadowing.py [파일 ...] (없으면 force-app-*/**/classes/*.cls)"""
import glob
import re
import sys

files = sys.argv[1:] or glob.glob('force-app-*/main/default/classes/*.cls')
DECL = re.compile(r'\b(?:List|Set|Map|String|Integer|Boolean|Id|Date|Datetime|Decimal|Long|Object|[A-Z]\w*)(?:<[^;=()]*?>)?\s+([a-z]\w*)\s*(?:[=;:,)])')
bad = 0
for p in files:
    src = open(p, encoding='utf-8').read()
    consts = {c.lower(): c for c in re.findall(r'static\s+final\s+[\w<>,\s]+?\s([A-Z][A-Z0-9_]+)\s*=', src)}
    consts.update({'label': 'Label', 'type': 'Type', 'schema': 'Schema', 'test': 'Test'})
    for m in DECL.finditer(src):
        name = m.group(1)
        if name.lower() in consts and name != consts[name.lower()]:
            line = src.count('\n', 0, m.start()) + 1
            print(f'{p}:{line}: 지역 이름 {name}이(가) {consts[name.lower()]}을(를) 가린다')
            bad += 1
print(f'Apex 이름 가림 {bad}건')
sys.exit(1 if bad else 0)
