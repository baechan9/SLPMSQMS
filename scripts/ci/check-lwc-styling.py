#!/usr/bin/env python3
"""CMN-00-UX-004 BR-10 점검: LWC CSS는 SLDS 전역 스타일링 훅(--slds-g-*)과 SLDS 클래스만 쓴다.
색 리터럴(#rgb, #rrggbb, rgb(), rgba(), hsl(), hsla()), 컴포넌트 스타일링 훅(--slds-c-*), 구 토큰(--lwc-*)은
SLDS 2·Cosmos·다크 모드에서 깨지므로 금지한다. 선언의 값(콜론 뒤)만 본다. 사용: python3 scripts/ci/check-lwc-styling.py [css ...]"""
import glob
import re
import sys

RULES = [
    (re.compile(r'#[0-9a-fA-F]{3,8}\b'), '색 리터럴'),
    (re.compile(r'\b(rgba?|hsla?)\('), '색 함수'),
    (re.compile(r'--slds-c-[\w-]+'), '컴포넌트 스타일링 훅(--slds-c-*)'),
    (re.compile(r'--lwc-[\w-]+'), '구 디자인 토큰(--lwc-*)'),
]
COMMENT = re.compile(r'/\*.*?\*/', re.S)


def check(path):
    bad = 0
    text = COMMENT.sub(lambda m: '\n' * m.group(0).count('\n'), open(path, encoding='utf-8').read())
    for i, line in enumerate(text.split('\n'), 1):
        if ':' not in line:
            continue
        value = line.split(':', 1)[1]
        for pattern, what in RULES:
            if pattern.search(value):
                print(f'{path}:{i}: {what} — SLDS 전역 훅(--slds-g-*)이나 SLDS 클래스를 쓴다: {line.strip()}')
                bad += 1
    return bad


def main():
    files = sys.argv[1:] or sorted(glob.glob('force-app-*/main/default/lwc/*/*.css'))
    bad = sum(check(p) for p in files)
    print(f'LWC 스타일 규칙 위반 {bad}건({len(files)}개 파일)')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
