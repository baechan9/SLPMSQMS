"""WI별 상세도 지표를 계산해 보강 후보를 찾는다(파일을 고치지 않는다).
지표: 본문 길이, BR 수, AC 수, 데이터 모델 표 행 수, 범위·권한·화면·에이전트 주의·오픈 이슈 유무, 서비스 시그니처 유무.
사용: python3 scripts/wi_metrics.py [--csv 출력경로]   (docs/에서 실행)"""
import re, glob, os, sys, csv

HEADER = re.compile(r'^### ((CMN|QMS|PMS)-\d\d-[A-Z0-9]+-\d{3}[a-z]?) (.+)$')


def split_wis(path):
    lines = open(path, encoding='utf-8').read().split('\n')
    cur, buf, out = None, [], []
    for line in lines:
        m = HEADER.match(line)
        if m or line.startswith('## '):
            if cur:
                out.append((cur, buf))
            cur, buf = (m.group(1), m.group(3)) if m else None, []
            continue
        if cur:
            buf.append(line)
    if cur:
        out.append((cur, buf))
    return out


def metrics(body):
    text = '\n'.join(body)
    meta = next((l for l in body if l.strip()), '')
    md = re.search(r'· (\d+(?:\.\d+)?) M/D', meta)
    table_rows = sum(1 for l in body if l.startswith('|') and not l.startswith('| ---'))
    return {
        'chars': len(text),
        'md': float(md.group(1)) if md else 0,
        'br': len(re.findall(r'^- BR-\d+', text, re.M)),
        'ac': len(re.findall(r'^- AC-\d+', text, re.M)),
        'rows': table_rows,
        'scope': '**범위**' in text,
        'perm': '**권한**' in text,
        'ui': '**화면' in text,
        'agent': '**에이전트 주의**' in text,
        'issue': '**오픈 이슈**' in text,
        'api': bool(re.search(r'^    \S', text, re.M)),
    }


def flags(m):
    f = []
    if m['br'] < 4: f.append(f"BR{m['br']}")
    if m['ac'] < 4: f.append(f"AC{m['ac']}")
    if not m['scope']: f.append('범위X')
    if not m['perm']: f.append('권한X')
    if not m['agent']: f.append('주의X')
    if m['chars'] / max(m['md'], 1) < 700: f.append('밀도↓')
    return f


if __name__ == '__main__':
    rows = []
    for path in sorted(glob.glob('docs/10-workitems/vol*.md')):
        for (wid, title), body in split_wis(path):
            m = metrics(body)
            rows.append({'file': os.path.basename(path).split('-')[0], 'wi': wid, 'title': title, **m,
                         'flags': ' '.join(flags(m))})
    if '--csv' in sys.argv:
        out = sys.argv[sys.argv.index('--csv') + 1]
        with open(out, 'w', newline='', encoding='utf-8-sig') as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
    by = {}
    for r in rows:
        b = by.setdefault(r['file'], [0, 0, 0, 0])
        b[0] += 1; b[1] += r['br']; b[2] += r['ac']; b[3] += 1 if r['flags'] else 0
    for k, (n, br, ac, weak) in by.items():
        print(f'{k:6} WI {n:3}  평균 BR {br / n:4.1f}  평균 AC {ac / n:4.1f}  보강 후보 {weak}')
    print('보강 후보 합계', sum(1 for r in rows if r['flags']))
