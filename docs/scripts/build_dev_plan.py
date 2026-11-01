"""docs/30-dev/phase-map.csv(WI → 페이즈·레인)와 master/workitem-index.csv(선행·Wave·공수)로 개발 플랜 표를 다시 만들고 선행 순서를 검사한다.
사용: python3 scripts/build_dev_plan.py   (docs/에서 실행)
- 검사: 배정 누락·중복, 선행 순환, 선행이 뒤 페이즈에 있는 배정. 하나라도 있으면 파일을 고치지 않고 종료 코드 1.
- 갱신: docs/30-dev/dev-plan.md 와 p*.md 의 <!-- BEGIN:키 --> ~ <!-- END:키 --> 구간만 바꾼다(나머지 본문은 사람이 쓴다).
- DEV-STATUS: docs/20-status/DEV-STATUS.md 진행 표의 제목·페이즈·레인·Wave 열을 배정표로 다시 쓰고,
  상태·시작일·완료일·보고서·비고 열(/implement-wi가 쓰는 값)은 그대로 둔다. 요약 표도 다시 계산한다."""
import csv, glob, os, re, sys
from collections import defaultdict

INDEX = 'master/workitem-index.csv'
MAP = 'docs/30-dev/phase-map.csv'
PLAN = 'docs/30-dev/dev-plan.md'
STATUS = 'docs/20-status/DEV-STATUS.md'
STATUS_COLS = ['WI', '제목', '페이즈', '레인', 'Wave', '상태', '시작일', '완료일', '보고서', '비고']
PHASES = [  # 번호, 이름, 문서, 마일스톤
    (0, '착수 준비', 'p00-setup.md', '정의 파일·재현 스크립트·CI 동작'),
    (1, '공통 프레임워크·기준정보', 'p01-cmn-framework-master.md', '기준정보 데모 적재, 다국어 표시'),
    (2, '보안·공통 업무 서비스·연계 기반', 'p02-cmn-security-services.md', '공장 격리, 결재·To-Do·알림·문서 서비스'),
    (3, '공통 확장·QMS 연계 공통', 'p03-cmn-extension.md', '결재 UI·위임, KPI 수신, 위젯 보드'),
    (4, '인정시험·협력사 포털·수입검사·PPAP', 'p04-dvq-supplier-iqc-ppap.md', 'S9 수입검사, S3 앞부분(시험·PPAP)'),
    (5, '8D 엔진·부적합·고객 클레임', 'p05-8d-ncr-claim.md', 'S1 NCR(AI 제외), S2 핵심'),
    (6, '4M 변경·초기안정화·부품 확장', 'p06-4m-stabilization.md', 'S3 4M 완성(Salesforce 부분)'),
    (7, 'SPC·레슨런·대시보드 공용 라이브러리', 'p07-spc-lele-dashboard-lib.md', 'S7 SPC, S6 규칙 매칭'),
    (8, '출하검사·초기유동·수평전개·고객 B2B', 'p08-fqc-efc-hzd-b2b.md', 'S10 B2B, S13 EOL·출하'),
    (9, '심사·인증·협력사 실적·개선 과제', 'p09-audit-supplier-improvement.md', 'S4 VDA 6.3'),
    (10, '측정기·MSA·교육·분석실·한도견본', 'p10-gauge-msa-training-lab.md', 'S8 MSA, S12 교정 불합격, S2 분석'),
    (11, '품질 위젯·대시보드', 'p11-dashboard-widgets.md', 'S5 대시보드(질문은 대체 경로)'),
    (12, '품질 AI', 'p12-quality-ai.md', 'S1·S2·S5·S6 AI 완성'),
    (13, '고도화·통합 안정화', 'p13-advanced-stabilization.md', '전 시나리오 회귀, SIT 이관 준비'),
]
WAVE = {'W0': 0, 'W1': 1, 'W2': 2, 'W3': 3}
SCOPE = [('SF', 'SF'), ('EXP', '포털'), ('SNOW', 'DW 목'), ('MULE', '연계 시뮬'), ('AF', 'Agentforce'), ('DC', 'Data Cloud(Sandbox)')]


def menu(wi):
    return '-'.join(wi.split('-')[:2])


def resolve(owner, tok, ids):
    """선행 표기(전체 ID, 같은 메뉴 약칭, CMN 약칭)를 전체 ID로 바꾼다. 약칭은 같은 메뉴 → CMN 순으로 찾는다."""
    if tok in ids:
        return [tok]
    cands = [i for i in ids if i.endswith('-' + tok)]
    own = [c for c in cands if menu(c) == menu(owner)]
    return own or [c for c in cands if c.startswith('CMN-00')] or cands


def parse_deps(owner, text, ids):
    out, bad = [], []
    if text.strip() == '없음':
        return out, bad
    for part in re.split(r',\s*', text):
        part = re.sub(r'\(.*?\)', '', part).strip()
        if not part:
            continue
        m = re.fullmatch(r'((?:[A-Z]{3}-\d{2}-)?[A-Z0-9]+-)(\d{3})~(\d{3})', part)
        toks = [f'{m.group(1)}{n:03d}' for n in range(int(m.group(2)), int(m.group(3)) + 1)] if m else [part]
        for t in toks:
            r = resolve(owner, t, ids)
            if len(r) == 1:
                out.append(r[0])
            else:
                bad.append(t)
    return out, bad


def split_ids(cell):
    return [x.strip() for x in re.split(r'[;,]', cell or '') if x.strip()]


def scope(platform):
    p = {x.strip() for x in platform.split(',')}
    if not p & {'SF', 'EXP', 'AF', 'DC'}:
        return '외부 트랙'
    return ' + '.join(label for key, label in SCOPE if key in p)


def short(wi, base):
    if wi.startswith('CMN-00-'):
        return wi[len('CMN-00-'):]
    return wi[len(menu(wi)) + 1:] if menu(wi) == menu(base) else wi


def replace_block(path, key, body):
    text = open(path, encoding='utf-8').read()
    pat = re.compile(rf'(<!-- BEGIN:{key} -->\n).*?(<!-- END:{key} -->)', re.S)
    if not pat.search(text):
        print(f'WARN {path}: {key} 구간 없음')
        return
    open(path, 'w', encoding='utf-8').write(pat.sub(lambda m: m.group(1) + body + '\n' + m.group(2), text))


def main():
    idx = {r['WI_ID']: r for r in csv.DictReader(open(INDEX, encoding='utf-8-sig'))}
    rows = list(csv.DictReader(open(MAP, encoding='utf-8-sig')))
    ids = set(idx)
    errors = []
    pm = {}
    for r in rows:
        if r['WI_ID'] not in ids:
            errors.append(f"배정표에 없는 WI: {r['WI_ID']}")
        elif r['WI_ID'] in pm:
            errors.append(f"중복 배정: {r['WI_ID']}")
        pm[r['WI_ID']] = r
    errors += [f'미배정 WI: {i}' for i in sorted(ids - set(pm))]
    deps, raw = {}, {}
    for wi in idx:
        d, bad = parse_deps(wi, idx[wi]['선행WI'], ids)
        errors += [f'{wi} 선행 해석 실패: {b}' for b in bad]
        raw[wi] = d
        m = pm.get(wi, {})
        excl = set(split_ids(m.get('제외선행')))
        deps[wi] = [x for x in d if x not in excl] + [x for x in split_ids(m.get('추가선행')) if x not in d]
    if errors:
        sys.exit('\n'.join(errors))
    phase = {wi: int(pm[wi]['페이즈']) for wi in idx}
    # 위상 정렬(Kahn). 남는 WI가 있으면 순환
    indeg = {w: len(deps[w]) for w in idx}
    succ = defaultdict(list)
    for w, ds in deps.items():
        for d in ds:
            succ[d].append(w)
    order = [w for w in idx if indeg[w] == 0]
    for w in order:
        for s in succ[w]:
            indeg[s] -= 1
            if indeg[s] == 0:
                order.append(s)
    if len(order) < len(idx):
        sys.exit('선행 순환: ' + ', '.join(sorted(w for w in idx if indeg[w] > 0)))
    late = [(w, d) for w in idx for d in deps[w] if phase[d] > phase[w]]
    if late:
        sys.exit('\n'.join(f'{w}(P{phase[w]})의 선행 {d}가 뒤 페이즈 P{phase[d]}에 있음' for w, d in late))
    pos = {w: i for i, w in enumerate(order)}
    # 페이즈 안 선행 깊이. 표는 (레인, 깊이, WI 번호) 순이라 선행이 항상 위에 온다
    depth = {}
    for w in order:
        depth[w] = max([depth[d] + 1 for d in deps[w] if phase[d] == phase[w]], default=0)
    md = {w: float(idx[w]['공수MD']) for w in idx}
    # 앞당김 표시: 더 이른 Wave의 WI가 선행으로 요구하는 경우(원래 선행 기준)
    pulled = defaultdict(list)
    for w, ds in raw.items():
        for d in ds:
            if WAVE[idx[d]['Wave']] > WAVE[idx[w]['Wave']]:
                pulled[d].append(w)
    names = {p: (n, f, ms) for p, n, f, ms in PHASES}
    summary = ['| 페이즈 | 이름 | WI | M/D | Wave 구성 | SF 트랙 | 외부 트랙 | 마일스톤 |', '| --- | --- | --- | --- | --- | --- | --- | --- |']
    for p, (name, fname, ms) in names.items():
        ws = sorted([w for w in idx if phase[w] == p], key=lambda w: (pm[w]['레인'], depth[w], w))
        waves = defaultdict(int)
        for w in ws:
            waves[idx[w]['Wave']] += 1
        ext = [w for w in ws if scope(idx[w]['플랫폼']) == '외부 트랙']
        wave_txt = ' · '.join(f'{k} {waves[k]}' for k in sorted(waves))
        total = sum(md[w] for w in ws)
        summary.append(f"| P{p} | [{name}]({fname}) | {len(ws)} | {total:g} | {wave_txt} | {len(ws) - len(ext)} | {len(ext)} | {ms} |")
        lines = [f'WI {len(ws)}건 · {total:g} M/D · {wave_txt} · SF 트랙 {len(ws) - len(ext)}건 · 외부 트랙 {len(ext)}건', '',
                 '| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |', '| --- | --- | --- | --- | --- | --- | --- | --- |']
        seq = defaultdict(int)
        for w in ws:
            lane = pm[w]['레인']
            seq[lane] += 1
            inside = [short(d, w) for d in sorted(deps[w], key=lambda x: pos[x]) if phase[d] == p]
            note = [pm[w].get('비고', '').strip()] if pm[w].get('비고', '').strip() else []
            if pulled.get(w):
                note.append('앞당김: ' + '·'.join(short(x, w) for x in sorted(pulled[w])[:3]) + (' 외' if len(pulled[w]) > 3 else '') + '의 선행')
            lines.append(f"| {lane}{seq[lane]} | {w} | {idx[w]['L4_워크아이템']} | {idx[w]['Wave']} | {md[w]:g} | {scope(idx[w]['플랫폼'])} | {', '.join(inside) or '—'} | {' / '.join(note) or '—'} |")
        path = os.path.join('docs/30-dev', fname)
        if os.path.exists(path):
            replace_block(path, 'WI-TABLE', '\n'.join(lines))
        else:
            print(f'WARN 페이즈 문서 없음: {path}')
    total = sum(md.values())
    summary.append(f'| 합계 | | {len(idx)} | {total:g} | | | | |')
    replace_block(PLAN, 'PHASE-SUMMARY', '\n'.join(summary))
    # 임계 경로(공수 합이 가장 긴 선행 사슬)
    best, prev = {}, {}
    for w in order:
        b = max(deps[w], key=lambda d: best[d], default=None)
        best[w] = md[w] + (best[b] if b else 0)
        prev[w] = b
    end = max(best, key=best.get)
    chain = []
    while end:
        chain.append(end)
        end = prev[end]
    chain.reverse()
    cp = [f'공수 합 {best[chain[-1]]:g} M/D, {len(chain)}건. 인원을 늘려도 이 사슬보다 짧아지지 않는다.', '',
          '| 순서 | WI | 제목 | 페이즈 | M/D |', '| --- | --- | --- | --- | --- |']
    cp += [f"| {i} | {w} | {idx[w]['L4_워크아이템']} | P{phase[w]} | {md[w]:g} |" for i, w in enumerate(chain, 1)]
    replace_block(PLAN, 'CRITICAL-PATH', '\n'.join(cp))
    inv = sorted(((w, d) for w, ds in raw.items() for d in ds if WAVE[idx[d]['Wave']] > WAVE[idx[w]['Wave']]), key=lambda x: (pos[x[0]], x[1]))
    tb = [f'{len(inv)}건. 왼쪽 WI의 Wave가 선행 WI보다 이르다. 이 플랜은 선행 WI를 앞 페이즈로 당겨 해소했다.', '',
          '| WI | Wave | 선행 WI | 선행 Wave | 선행 배정 |', '| --- | --- | --- | --- | --- |']
    tb += [f"| {w} | {idx[w]['Wave']} | {d} | {idx[d]['Wave']} | P{phase[d]} |" for w, d in inv]
    replace_block(PLAN, 'WAVE-INVERSIONS', '\n'.join(tb))
    sync_dev_status(idx, pm, phase, depth)
    print(f'{len(idx)} WI, {total:g} M/D, 페이즈 {len(PHASES)}개 — 선행 순서 위반 0, 순환 0, Wave 역전 {len(inv)}건, 임계 경로 {best[chain[-1]]:g} M/D')


def sync_dev_status(idx, pm, phase, depth):
    """DEV-STATUS 진행 표를 배정표 순서로 다시 쓰되, 진행 값(상태~비고)은 보존한다."""
    text = open(STATUS, encoding='utf-8').read()
    m = re.search(r'<!-- BEGIN:DEV-TABLE -->\n(.*?)<!-- END:DEV-TABLE -->', text, re.S)
    if not m:
        print(f'WARN {STATUS}: DEV-TABLE 구간 없음')
        return
    keep = {}
    for line in m.group(1).splitlines():
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if line.startswith('|') and len(cells) == len(STATUS_COLS) and cells[0] in idx:
            keep[cells[0]] = cells[5:]
    order = sorted(idx, key=lambda w: (phase[w], pm[w]['레인'], depth[w], w))
    lines = ['| ' + ' | '.join(STATUS_COLS) + ' |', '|' + ' --- |' * len(STATUS_COLS)]
    state = {}
    for w in order:
        prog = keep.get(w, ['대기', '', '', '', ''])
        state[w] = prog[0]
        lines.append(f"| {w} | {idx[w]['L4_워크아이템']} | P{phase[w]} | {pm[w]['레인']} | {idx[w]['Wave']} | " + ' | '.join(prog) + ' |')
    replace_block(STATUS, 'DEV-TABLE', '\n'.join(lines))

    def count(keys):
        done = sum(1 for w in keys if state[w].startswith('개발 완료'))
        doing = sum(1 for w in keys if state[w].startswith('개발 중'))
        held = sum(1 for w in keys if state[w].startswith('보류'))
        return f'{len(keys)} | {done} | {doing} | {held}'
    s = ['| 페이즈 | 전체 WI | 개발 완료 | 개발 중 | 보류 |', '| --- | --- | --- | --- | --- |']
    s += [f'| P{p} | ' + count([w for w in idx if phase[w] == p]) + ' |' for p, *_ in PHASES]
    s += ['', '| Wave | 전체 WI | 개발 완료 | 개발 중 | 보류 |', '| --- | --- | --- | --- | --- |']
    s += [f'| {wv} | ' + count([w for w in idx if idx[w]['Wave'] == wv]) + ' |' for wv in sorted(WAVE, key=WAVE.get)]
    s += [f'| 합계 | ' + count(list(idx)) + ' |']
    replace_block(STATUS, 'DEV-SUMMARY', '\n'.join(s))


if __name__ == '__main__':
    main()
