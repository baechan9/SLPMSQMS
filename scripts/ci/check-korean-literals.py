#!/usr/bin/env python3
"""LWC·Apex 한글 문자열 리터럴 검사(CMN-00-I18N-001 AC-4). 화면 문구는 Custom Label로만 낸다.

사용: python3 scripts/ci/check-korean-literals.py   (위반이 있으면 exit 1)

- 대상: force-app-*/**/classes/*.cls, triggers/*.trigger, lwc/**/*.js, lwc/**/*.html
- 제외: 테스트 클래스(*_Test.cls, 클래스 선언에 @IsTest), lwc __tests__
- 주석의 한글은 허용한다(sf-dev: 주석은 한국어 가능). 문자열·템플릿 텍스트의 한글만 잡는다.
"""
import glob
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
HANGUL = re.compile(r'[ᄀ-ᇿ㄰-㆏가-힣]')


def strings_in_code(text, quotes):
    """주석을 건너뛰고 문자열 리터럴만 (줄 번호, 값)으로 돌려준다."""
    out, i, line, n = [], 0, 1, len(text)
    while i < n:
        c = text[i]
        if c == '\n':
            line += 1
            i += 1
        elif text.startswith('//', i):
            j = text.find('\n', i)
            i = n if j < 0 else j
        elif text.startswith('/*', i):
            j = text.find('*/', i + 2)
            j = n if j < 0 else j + 2
            line += text.count('\n', i, j)
            i = j
        elif c in quotes:
            start_line, j, buf = line, i + 1, []
            while j < n and text[j] != c:
                if text[j] == '\\' and j + 1 < n:
                    buf.append(text[j:j + 2])
                    j += 2
                    continue
                if text[j] == '\n':
                    line += 1
                buf.append(text[j])
                j += 1
            out.append((start_line, ''.join(buf)))
            i = j + 1
        else:
            i += 1
    return out


def is_test_class(text):
    head = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    return re.search(r'@IsTest\s+(?:\w+\s+)*class\s', head, flags=re.I) is not None


def main():
    problems = []
    for pkg in glob.glob(os.path.join(ROOT, 'force-app-*')):
        files = glob.glob(os.path.join(pkg, '**', 'classes', '*.cls'), recursive=True) + \
            glob.glob(os.path.join(pkg, '**', 'triggers', '*.trigger'), recursive=True) + \
            glob.glob(os.path.join(pkg, '**', 'lwc', '**', '*.js'), recursive=True) + \
            glob.glob(os.path.join(pkg, '**', 'lwc', '**', '*.html'), recursive=True)
        for path in sorted(files):
            rel = os.path.relpath(path, ROOT)
            if '__tests__' in path or path.endswith('_Test.cls'):
                continue
            text = open(path, encoding='utf-8').read()
            if path.endswith('.cls') and is_test_class(text):
                continue
            if path.endswith('.html'):
                body = re.sub(r'<!--.*?-->', lambda m: '\n' * m.group(0).count('\n'), text, flags=re.S)
                for no, row in enumerate(body.split('\n'), 1):
                    if HANGUL.search(row):
                        problems.append(f'{rel}:{no}: {row.strip()[:80]}')
                continue
            quotes = ("'",) if path.endswith(('.cls', '.trigger')) else ("'", '"', '`')
            for no, value in strings_in_code(text, quotes):
                if HANGUL.search(value):
                    problems.append(f'{rel}:{no}: {value[:80]}')
    for p in problems:
        print('한글 리터럴:', p)
    print(f'한글 문자열 리터럴 {len(problems)}건(테스트 제외)')
    sys.exit(1 if problems else 0)


if __name__ == '__main__':
    main()
