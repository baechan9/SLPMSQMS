"""각 Vol. 문서의 검토 요청 절에서 결정 항목과 앞 Vol. 변경 요청 표를 모아 docs/20-status/review-pack.md 를 만든다.
사용: python3 scripts/build_review_pack.py   (docs/에서 실행, Vol. 문서는 고치지 않는다)"""
import re, glob, os, collections

OUT = 'docs/20-status/review-pack.md'
DECISION = re.compile(r'^- \[([ x])\] (D[0-9A-Z]*-\d+)\s*(.*)$')
SECTIONS = {
    'vol0': re.compile(r'^\*\*Vol\.0에 반영이 필요한 변경'),
    'prev': re.compile(r'^\*\*(Vol\.2[^*]*|이전 Vol\.)에 반영이 필요한 변경'),
}


def vol_label(path):
    m = re.match(r'vol(\d+[a-z]?)-', os.path.basename(path))
    return 'Vol.' + m.group(1)


def table_after(lines, start):
    """start 줄 다음에 나오는 첫 표의 데이터 행(머리·구분 행 제외)을 셀 목록으로 돌려준다."""
    i = start + 1
    while i < len(lines) and not lines[i].startswith('|'):
        if lines[i].startswith('**') and i > start + 1:
            return []
        i += 1
    rows = []
    while i < len(lines) and lines[i].startswith('|'):
        rows.append([c.strip() for c in lines[i].strip().strip('|').split('|')])
        i += 1
    return rows[2:]


def collect():
    decisions = collections.OrderedDict()
    changes = {'vol0': [], 'prev': []}
    files = sorted(glob.glob('docs/10-workitems/vol*.md'),
                   key=lambda p: [int(t) if t.isdigit() else t for t in re.split(r'(\d+)', os.path.basename(p))])
    for path in files:
        label = vol_label(path)
        lines = open(path, encoding='utf-8').read().split('\n')
        for idx, line in enumerate(lines):
            m = DECISION.match(line)
            if m:
                decisions.setdefault(label, []).append((m.group(1), m.group(2), m.group(3)))
            for key, pat in SECTIONS.items():
                if pat.match(line):
                    for cells in table_after(lines, idx):
                        target = cells[0]
                        body = cells[1] if len(cells) > 1 else ''
                        basis = cells[2] if len(cells) > 2 else ''
                        changes[key].append((target, label, body, basis))
    return decisions, changes


def render(decisions, changes):
    out = ['# 검토 패키지', '',
           '`scripts/build_review_pack.py`가 각 Vol. 검토 요청 절에서 자동으로 모은 문서다. 직접 고치지 말고 Vol. 문서를 고친 뒤 다시 생성한다.', '']
    total = sum(len(v) for v in decisions.values())
    out += [f'## 1. 결정 항목 ({total}건)', '']
    for label, items in decisions.items():
        out += [f'### {label} ({len(items)}건)', '']
        out += [f'- [{mark}] {did} {text}' for mark, did, text in items]
        out.append('')
    titles = {'vol0': '2. Vol.0 변경 요청', 'prev': '3. Vol.2·3 및 이전 Vol. 변경 요청'}
    for key in ('vol0', 'prev'):
        rows = sorted(changes[key], key=lambda r: (r[0], r[1]))
        out += [f'## {titles[key]} ({len(rows)}건, 대상순)', '',
                '| 대상 | 요청 Vol. | 변경 내용 | 근거 |', '| --- | --- | --- | --- |']
        out += [f'| {t} | {v} | {b} | {g} |' for t, v, b, g in rows]
        out.append('')
    return '\n'.join(out)


if __name__ == '__main__':
    d, c = collect()
    open(OUT, 'w', encoding='utf-8').write(render(d, c))
    print(f'결정 {sum(len(v) for v in d.values())}건, Vol.0 변경 {len(c["vol0"])}건, 이전 Vol. 변경 {len(c["prev"])}건 → {OUT}')
