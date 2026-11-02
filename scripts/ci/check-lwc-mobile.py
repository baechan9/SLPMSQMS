#!/usr/bin/env python3
"""CMN-00-UX-001 BR-2 점검: 화면에 배치되는 LWC(레코드·앱·홈 페이지, 탭)는 Small 폼팩터를 지원하고, CSS에 고정 px 폭을 쓰지 않는다.
유틸리티 바 전용·비공개(isExposed=false) 컴포넌트는 제외. 사용: python3 scripts/ci/check-lwc-mobile.py"""
import glob
import os
import re
import sys

PAGE_TARGETS = ('lightning__RecordPage', 'lightning__AppPage', 'lightning__HomePage', 'lightning__Tab')
FIXED_WIDTH = re.compile(r'(?<![-\w])(width|min-width)\s*:\s*\d{3,}px', re.I)
bad = 0
for meta in sorted(glob.glob('force-app-*/main/default/lwc/*/*.js-meta.xml')):
    bundle = os.path.dirname(meta)
    name = os.path.basename(bundle)
    xml = open(meta, encoding='utf-8').read()
    if '<isExposed>true</isExposed>' not in xml:
        continue
    targets = re.findall(r'<target>([^<]+)</target>', xml)
    if any(t in PAGE_TARGETS for t in targets) and 'type="Small"' not in xml:
        print(f'{meta}: 화면 배치 LWC인데 Small 폼팩터가 없다(BR-2)')
        bad += 1
    for css in glob.glob(os.path.join(bundle, '*.css')):
        for i, line in enumerate(open(css, encoding='utf-8'), 1):
            if FIXED_WIDTH.search(line):
                print(f'{css}:{i}: 고정 px 폭(BR-2) — %·rem·SLDS 그리드를 쓴다')
                bad += 1
print(f'LWC 모바일 규칙 위반 {bad}건')
sys.exit(1 if bad else 0)
