#!/usr/bin/env python3
"""프로토 목 응답 묶음(A0 프로토 공용 장치). data/demo/mocks/dwh/{QueryKey}/{case}.json을 정적 리소스 CMN_PrototypeMocks 하나로 묶는다.
CMN_Prototype.mockResponse(queryKey, params)가 읽고, CMN_PROTOTYPE_MODE가 켜진 Scratch Org에서만 응답한다.
응답 형식은 spec-snowflake-display.md 그대로다(데모 목 원본을 고치면 다시 실행).

    python3 scripts/dev/build-prototype-mocks.py           # 정적 리소스 갱신
    python3 scripts/dev/build-prototype-mocks.py --check   # 최신인지(CI·wi-check)
"""
import glob
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SRC = os.path.join(ROOT, 'data', 'demo', 'mocks', 'dwh')
DST = os.path.join(ROOT, 'force-app-cmn', 'main', 'default', 'staticresources', 'CMN_PrototypeMocks.json')
MAX_BYTES = 4 * 1024 * 1024


def build():
    dwh = {}
    for path in sorted(glob.glob(os.path.join(SRC, '*', '*.json'))):
        key = os.path.basename(os.path.dirname(path))
        case = os.path.splitext(os.path.basename(path))[0]
        with open(path, encoding='utf-8') as f:
            dwh.setdefault(key, {})[case] = json.load(f)
    text = json.dumps({'version': 1, 'dwh': dwh}, ensure_ascii=False, sort_keys=True, separators=(',', ':')) + '\n'
    if len(text.encode('utf-8')) > MAX_BYTES:
        sys.exit(f'목 묶음 {len(text)}바이트 — 정적 리소스 상한(4MB) 초과. 큰 목을 줄인다')
    return text, len(dwh), sum(len(v) for v in dwh.values())


def main():
    text, keys, cases = build()
    if '--check' in sys.argv:
        same = os.path.exists(DST) and open(DST, encoding='utf-8').read() == text
        print('CMN_PrototypeMocks 최신' if same else 'CMN_PrototypeMocks가 목 원본과 다름: python3 scripts/dev/build-prototype-mocks.py 실행')
        sys.exit(0 if same else 1)
    with open(DST, 'w', encoding='utf-8') as f:
        f.write(text)
    print(f'CMN_PrototypeMocks 갱신: 조회 키 {keys}개, 응답 {cases}개, {len(text.encode("utf-8")) // 1024}KB')


if __name__ == '__main__':
    main()
