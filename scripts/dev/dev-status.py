#!/usr/bin/env python3
"""DEV-STATUS 진행 표의 WI 행(상태·시작일·완료일·보고서·비고)을 고치고 요약을 다시 계산한다.
사용: python3 scripts/dev/dev-status.py <WI-ID> <상태> [--start YYYY-MM-DD] [--done YYYY-MM-DD] [--note 비고]
상태: 대기 / 개발 중 / 개발 완료 / 보류(사유). 보고서 링크는 docs/wi/<WI-ID>.md가 있으면 자동으로 넣는다."""
import argparse
import datetime as dt
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
STATUS = os.path.join(ROOT, 'docs', 'docs', '20-status', 'DEV-STATUS.md')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('wi')
    ap.add_argument('state')
    ap.add_argument('--start')
    ap.add_argument('--done')
    ap.add_argument('--note')
    a = ap.parse_args()
    today = dt.date.today().isoformat()
    lines = open(STATUS, encoding='utf-8').read().split('\n')
    hit = False
    for i, line in enumerate(lines):
        if line.startswith(f'| {a.wi} |'):
            c = [x.strip() for x in line.strip().strip('|').split('|')]
            c[5] = a.state
            if a.start or (a.state != '대기' and not c[6]):
                c[6] = a.start or today
            if a.done or a.state.startswith('개발 완료'):
                c[7] = a.done or c[7] or today
            if os.path.exists(os.path.join(ROOT, 'docs', 'wi', f'{a.wi}.md')):
                c[8] = f'[보고서](../../wi/{a.wi}.md)'
            if a.note is not None:
                c[9] = a.note.replace('|', '/')
            lines[i] = '| ' + ' | '.join(c) + ' |'
            hit = True
    if not hit:
        sys.exit(f'DEV-STATUS에 {a.wi} 행이 없음')
    open(STATUS, 'w', encoding='utf-8').write('\n'.join(lines))
    # 요약 표 재계산(진행 값은 보존된다)
    subprocess.run([sys.executable, 'scripts/build_dev_plan.py'], cwd=os.path.join(ROOT, 'docs'), check=True,
                   stdout=subprocess.DEVNULL)
    print(f'{a.wi}: {a.state}')


if __name__ == '__main__':
    main()
