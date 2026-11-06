"""docs/30-dev/phase-map.csv(WI → 페이즈·레인)와 master/workitem-index.csv(선행·Wave·공수)로 개발 플랜 표를 다시 만들고 선행 순서를 검사한다.
사용: python3 scripts/build_dev_plan.py   (docs/에서 실행)
- 검사: 배정 누락·중복, 선행 순환, 선행이 뒤 페이즈에 있는 배정. 하나라도 있으면 파일을 고치지 않고 종료 코드 1.
- 갱신: docs/30-dev/dev-plan.md 와 p*.md 의 <!-- BEGIN:키 --> ~ <!-- END:키 --> 구간만 바꾼다(나머지 본문은 사람이 쓴다).
- DEV-STATUS: docs/20-status/DEV-STATUS.md 진행 표의 제목·페이즈·레인·Wave 열을 배정표로 다시 쓰고,
  상태·시작일·완료일·보고서·비고 열(/implement-wi가 쓰는 값)은 그대로 둔다. 요약 표도 다시 계산한다.
- 트랙: 기반(P0~P3) 뒤에 QMS 트랙(P4~P13)과 PMS 트랙(P14~P20)이 병렬로 간다. 페이즈 번호는 식별용이고,
  PMS 트랙 첫 페이즈는 P13이 아니라 P3 뒤에 착수한다. 같은 트랙과 기반 WI만 앞 페이즈 선행으로 검사하고,
  PMS → QMS 선행(트랙 간 선행)은 허용하되 TRACK-LINKS 표로 따로 보인다. QMS·기반 → PMS 선행은 오류다.
- 일정: 트랙별 인원으로 선행·페이즈 당김(한 페이즈 앞까지)을 지켜 시뮬레이션해 SCHEDULE·PHASE-END 표를 만든다."""
import csv, glob, os, re, sys
from collections import defaultdict

INDEX = 'master/workitem-index.csv'
MAP = 'docs/30-dev/phase-map.csv'
PLAN = 'docs/30-dev/dev-plan.md'
STATUS = 'docs/20-status/DEV-STATUS.md'
STATUS_COLS = ['WI', '제목', '페이즈', '레인', 'Wave', '상태', '시작일', '완료일', '보고서', '비고']
PHASES = [  # 번호, 이름, 문서, 마일스톤, 트랙
    (0, '착수 준비', 'p00-setup.md', '정의 파일·재현 스크립트·CI 동작', '기반'),
    (1, '공통 프레임워크·기준정보', 'p01-cmn-framework-master.md', '기준정보 데모 적재, 다국어 표시', '기반'),
    (2, '보안·공통 업무 서비스·연계 기반', 'p02-cmn-security-services.md', '공장 격리, 결재·To-Do·알림·문서 서비스', '기반'),
    (3, '공통 확장·연계 공통·대시보드 공용', 'p03-cmn-extension.md', '결재 UI·위임, KPI 수신, 위젯 보드·공용 라이브러리, 질문지 템플릿', '기반'),
    (4, '인정시험·협력사 포털·수입검사·PPAP', 'p04-dvq-supplier-iqc-ppap.md', 'S9 수입검사, S3 앞부분(시험·PPAP)', 'QMS'),
    (5, '8D 엔진·부적합·고객 클레임', 'p05-8d-ncr-claim.md', 'S1 NCR(AI 제외), S2 핵심', 'QMS'),
    (6, '4M 변경·초기안정화·부품 확장', 'p06-4m-stabilization.md', 'S3 4M 완성(Salesforce 부분)', 'QMS'),
    (7, 'SPC·레슨런·고객 PPAP 증빙', 'p07-spc-lele-dashboard-lib.md', 'S7 SPC, S6 규칙 매칭', 'QMS'),
    (8, '출하검사·초기유동·수평전개·고객 B2B', 'p08-fqc-efc-hzd-b2b.md', 'S10 B2B, S13 EOL·출하', 'QMS'),
    (9, '심사·인증·협력사 실적·개선 과제', 'p09-audit-supplier-improvement.md', 'S4 VDA 6.3', 'QMS'),
    (10, '측정기·MSA·교육·분석실·한도견본', 'p10-gauge-msa-training-lab.md', 'S8 MSA, S12 교정 불합격, S2 분석', 'QMS'),
    (11, '품질 위젯·대시보드', 'p11-dashboard-widgets.md', 'S5 대시보드(질문은 대체 경로)', 'QMS'),
    (12, '품질 AI', 'p12-quality-ai.md', 'S1·S2·S5·S6 AI 완성', 'QMS'),
    (13, '고도화·통합 안정화', 'p13-advanced-stabilization.md', '전 시나리오 회귀, SIT 이관 준비', 'QMS'),
    (14, 'PMS 기준·프로젝트 착수·CFT', 'p14-pms-project-cft.md', '표준 WBS → 프로젝트 생성 → CFT 승인·보안서약 → SOR', 'PMS'),
    (15, 'PMS 실행 WBS·일정 엔진·액티비티', 'p15-pms-wbs-schedule.md', '실행 WBS·CPM → 일정 확정·To-Do, Gantt', 'PMS'),
    (16, 'PMS 수행·산출물·투입·비용', 'p16-pms-execution-cost.md', '산출물 결재·완료 조건, 주간 투입, 비용 실적', 'PMS'),
    (17, 'PMS Gate·리스크·문제점·QMS 접점', 'p17-pms-gate-risk-qms.md', 'Gate 평가·결재, SOP 이관 → QMS 초기유동', 'PMS'),
    (18, 'PMS 대시보드·보고·분석', 'p18-pms-dashboard-report.md', 'PMS 1차 오픈 범위 완성(PMO 보드·주간 보고)', 'PMS'),
    (19, 'PMS AI', 'p19-pms-ai.md', '일정 추천·조기경보·산출물 초안·SOR 분해', 'PMS'),
    (20, 'PMS 외부 연계·성과·변경', 'p20-pms-integration-performance.md', 'BPA·HR·DMS·PDM·ALM 연계, SOP+2개월 성과', 'PMS'),
]
BASE = '기반'
OPEN_TARGET = {'PMS': '2027-10(27.3Q)', 'QMS': '2027-4Q'}  # 분석 노트 일정(착수 2027-01)
KICKOFF = (2027, 1, 4)  # 일정 시뮬레이션 달력 환산 시작일(본 계약 착수 가정, 영업일 = 월~금, 공휴일 미반영)
TEAMS = [(3, 2), (4, 2), (4, 3), (5, 3), (6, 3)]  # (QMS 트랙 인원, PMS 트랙 인원). 기반 WI는 두 팀이 같이 한다
DEFAULT_TEAM = (4, 3)
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
    for part in re.split(r',\s*(?![^()]*\))', text):  # 괄호 안 쉼표(설명)는 나누지 않는다
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


TRACK = {p: t for p, _n, _f, _ms, t in PHASES}


def phase_prev():
    """같은 업무 트랙의 바로 앞 페이즈. 업무 트랙(QMS·PMS)의 첫 페이즈는 기반 마지막 페이즈(P3)를 잇는다."""
    base_last = max(p for p, *_r, t in PHASES if t == BASE)
    prev, last = {}, {}
    for p, *_r, t in PHASES:
        prev[p] = (p - 1 if p > 0 else None) if t == BASE else last.get(t, base_last)
        last[t] = p
    return prev


def biz_date(day):
    """시뮬레이션 영업일(0부터) → 달력 날짜(월~금, 공휴일 미반영)."""
    import datetime
    d = datetime.date(*KICKOFF)
    n = max(int(-(-day // 1)) - 1, 0)
    while n:
        d += datetime.timedelta(days=1)
        if d.weekday() < 5:
            n -= 1
    return d.strftime('%Y-%m')


def closure(seeds, deps):
    seen, stack = set(), list(seeds)
    while stack:
        w = stack.pop()
        if w not in seen:
            seen.add(w)
            stack += deps[w]
    return seen


def simulate(idx, deps, phase, md, ext, team, finished=frozenset()):
    """트랙별 인원 team=(QMS, PMS)으로 착수 순서를 흉내 낸다.
    - WI 1건은 1명이 문서 공수(M/D)만큼 맡는다. 기반 WI는 두 팀 누구나, 업무 트랙 WI는 그 트랙 팀만 한다.
    - 외부 트랙(Snowflake·Mule) WI는 SF 인원을 쓰지 않는다(외부 인력, 수 제한 없음).
    - 착수 조건: 선행 완료 + 같은 트랙 두 단계 앞 페이즈 완료(= 한 페이즈 앞까지만 당겨 착수).
    - 우선순위: 페이즈 → 남은 선행 사슬 길이. finished(개발 완료)는 공수 0으로 본다."""
    prev = phase_prev()
    gate = {p: (prev[prev[p]] if prev[p] is not None else None) for p in prev}
    members = {p: [] for p in prev}
    for w in idx:
        members[phase[w]].append(w)
    succ = defaultdict(list)
    for w, ds in deps.items():
        for d in ds:
            succ[d].append(w)
    dur = {w: (0.0 if w in finished else md[w]) for w in idx}
    tail = {}
    for w in reversed(topo(idx, deps)):
        tail[w] = dur[w] + max([tail[x] for x in succ[w]], default=0)
    cap = {'QMS': team[0], 'PMS': team[1]}
    done, start, pending, running = {}, {}, set(idx), []
    phase_end = {}
    t = 0.0
    while pending or running:
        for p, ws in members.items():
            if p not in phase_end and all(w in done for w in ws):
                phase_end[p] = max([done[w] for w in ws], default=0.0)
        ready = []
        for w in pending:
            g = gate[phase[w]]
            if g is not None and (g not in phase_end or phase_end[g] > t):
                continue
            if all(d in done and done[d] <= t for d in deps[w]):
                ready.append(w)
        ready.sort(key=lambda w: (phase[w], -tail[w], w))
        busy = defaultdict(int)
        for _e, w, pool in running:
            busy[pool] += 1
        for w in ready:
            if w in ext or dur[w] == 0:
                pool = 'EXT'
            elif TRACK[phase[w]] == BASE:
                pool = max(cap, key=lambda k: cap[k] - busy[k])
                if busy[pool] >= cap[pool]:
                    continue
            else:
                pool = TRACK[phase[w]]
                if busy[pool] >= cap[pool]:
                    continue
            busy[pool] += 1
            start[w] = t
            running.append((t + dur[w], w, pool))
            pending.discard(w)
        if not running:
            raise RuntimeError('일정 시뮬레이션 정지: ' + ', '.join(sorted(pending)[:5]))
        running.sort()
        t = running[0][0]
        for e, w, _p in [x for x in running if x[0] <= t]:
            done[w] = e
        running = [x for x in running if x[0] > t]
    for p, ws in members.items():
        phase_end.setdefault(p, max([done[w] for w in ws], default=0.0))
    return done, start, phase_end


def topo(idx, deps):
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
    return order


def status_states():
    text = open(STATUS, encoding='utf-8').read()
    m = re.search(r'<!-- BEGIN:DEV-TABLE -->\n(.*?)<!-- END:DEV-TABLE -->', text, re.S)
    out = {}
    for line in (m.group(1).splitlines() if m else []):
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if line.startswith('|') and len(cells) == len(STATUS_COLS):
            out[cells[0]] = cells[5]
    return out


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
        elif int(r['페이즈']) not in TRACK:
            errors.append(f"없는 페이즈: {r['WI_ID']} P{r['페이즈']}")
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
    trk = {wi: TRACK[phase[wi]] for wi in idx}
    order = topo(idx, deps)
    if len(order) < len(idx):
        done_ = set(order)
        sys.exit('선행 순환: ' + ', '.join(sorted(w for w in idx if w not in done_)))
    late, links = [], []
    for w in idx:
        for d in deps[w]:
            if trk[d] in (trk[w], BASE):
                if phase[d] > phase[w]:
                    late.append(f'{w}(P{phase[w]})의 선행 {d}가 뒤 페이즈 P{phase[d]}에 있음')
            elif trk[w] == 'PMS' and trk[d] == 'QMS':
                links.append((w, d))
            else:
                late.append(f'{w}({trk[w]} 트랙 P{phase[w]})가 {trk[d]} 트랙 {d}(P{phase[d]})를 선행으로 둠 — 허용 안 함')
    if late:
        sys.exit('\n'.join(late))
    pos = {w: i for i, w in enumerate(order)}
    # 페이즈 안 선행 깊이. 표는 (레인, 깊이, WI 번호) 순이라 선행이 항상 위에 온다
    depth = {}
    for w in order:
        depth[w] = max([depth[d] + 1 for d in deps[w] if phase[d] == phase[w]], default=0)
    md = {w: float(idx[w]['공수MD']) for w in idx}
    ext = {w for w in idx if scope(idx[w]['플랫폼']) == '외부 트랙'}
    # 앞당김 표시: 더 이른 Wave의 WI가 선행으로 요구하는 경우(원래 선행 기준)
    pulled = defaultdict(list)
    for w, ds in raw.items():
        for d in ds:
            if WAVE[idx[d]['Wave']] > WAVE[idx[w]['Wave']]:
                pulled[d].append(w)
    summary = ['| 페이즈 | 업무 트랙 | 이름 | WI | M/D | Wave 구성 | SF 트랙 | 외부 트랙 | 마일스톤 |', '| --- | --- | --- | --- | --- | --- | --- | --- | --- |']
    for p, name, fname, ms, tname in PHASES:
        ws = sorted([w for w in idx if phase[w] == p], key=lambda w: (pm[w]['레인'], depth[w], w))
        waves = defaultdict(int)
        for w in ws:
            waves[idx[w]['Wave']] += 1
        ext_ws = [w for w in ws if w in ext]
        wave_txt = ' · '.join(f'{k} {waves[k]}' for k in sorted(waves))
        total = sum(md[w] for w in ws)
        summary.append(f"| P{p} | {tname} | [{name}]({fname}) | {len(ws)} | {total:g} | {wave_txt} | {len(ws) - len(ext_ws)} | {len(ext_ws)} | {ms} |")
        lines = [f'WI {len(ws)}건 · {total:g} M/D · {wave_txt} · SF 트랙 {len(ws) - len(ext_ws)}건 · 외부 트랙 {len(ext_ws)}건', '',
                 '| 순서 | WI | 제목 | Wave | M/D | Scratch Org 범위 | 이 페이즈 안 선행 | 비고 |', '| --- | --- | --- | --- | --- | --- | --- | --- |']
        seq = defaultdict(int)
        for w in ws:
            lane = pm[w]['레인']
            seq[lane] += 1
            inside = [short(d, w) for d in sorted(deps[w], key=lambda x: pos[x]) if phase[d] == p]
            note = [pm[w].get('비고', '').strip()] if pm[w].get('비고', '').strip() else []
            cross = [d for d in deps[w] if trk[d] != trk[w] and trk[d] != BASE]
            if cross:
                note.append('QMS 선행: ' + '·'.join(f'{d}(P{phase[d]})' for d in sorted(cross, key=lambda x: pos[x])))
            if pulled.get(w):
                note.append('앞당김: ' + '·'.join(short(x, w) for x in sorted(pulled[w])[:3]) + (' 외' if len(pulled[w]) > 3 else '') + '의 선행')
            lines.append(f"| {lane}{seq[lane]} | {w} | {idx[w]['L4_워크아이템']} | {idx[w]['Wave']} | {md[w]:g} | {scope(idx[w]['플랫폼'])} | {', '.join(inside) or '—'} | {' / '.join(note) or '—'} |")
        path = os.path.join('docs/30-dev', fname)
        if os.path.exists(path):
            replace_block(path, 'WI-TABLE', '\n'.join(lines))
        else:
            print(f'WARN 페이즈 문서 없음: {path}')
    for tname in (BASE, 'QMS', 'PMS'):
        ws = [w for w in idx if trk[w] == tname]
        summary.append(f"| 소계 | {tname} | | {len(ws)} | {sum(md[w] for w in ws):g} | | | | |")
    total = sum(md.values())
    summary.append(f'| 합계 | | | {len(idx)} | {total:g} | | | | |')
    replace_block(PLAN, 'PHASE-SUMMARY', '\n'.join(summary))
    # 임계 경로(공수 합이 가장 긴 선행 사슬) — 전체, 그리고 PMS 트랙에서 끝나는 사슬
    best, prev = {}, {}
    for w in order:
        b = max(deps[w], key=lambda d: best[d], default=None)
        best[w] = md[w] + (best[b] if b else 0)
        prev[w] = b

    def chain_to(end):
        out = []
        while end:
            out.append(end)
            end = prev[end]
        return out[::-1]
    cp = []
    chains = (('전체(QMS 트랙에서 끝남)', [w for w in idx if trk[w] != 'PMS']),
              ('PMS 1차 오픈 범위(W0·W1)', [w for w in idx if trk[w] == 'PMS' and idx[w]['Wave'] in ('W0', 'W1')]),
              ('PMS 트랙 전체', [w for w in idx if trk[w] == 'PMS']))
    for label, pool in chains:
        if not pool:
            continue
        chain = chain_to(max(pool, key=best.get))
        cp += [f'**{label}**: 공수 합 {best[chain[-1]]:g} M/D, {len(chain)}건. 인원을 늘려도 이 사슬보다 짧아지지 않는다.', '',
               '| 순서 | WI | 제목 | 페이즈 | M/D |', '| --- | --- | --- | --- | --- |']
        cp += [f"| {i} | {w} | {idx[w]['L4_워크아이템']} | P{phase[w]} | {md[w]:g} |" for i, w in enumerate(chain, 1)]
        cp.append('')
    replace_block(PLAN, 'CRITICAL-PATH', '\n'.join(cp).rstrip())
    inv = sorted(((w, d) for w, ds in raw.items() for d in ds if WAVE[idx[d]['Wave']] > WAVE[idx[w]['Wave']]), key=lambda x: (pos[x[0]], x[1]))
    tb = [f'{len(inv)}건. 왼쪽 WI의 Wave가 선행 WI보다 이르다. 이 플랜은 선행 WI를 앞 페이즈로 당겨 해소했다.', '',
          '| WI | Wave | 선행 WI | 선행 Wave | 선행 배정 |', '| --- | --- | --- | --- | --- |']
    tb += [f"| {w} | {idx[w]['Wave']} | {d} | {idx[d]['Wave']} | P{phase[d]} |" for w, d in inv]
    replace_block(PLAN, 'WAVE-INVERSIONS', '\n'.join(tb))
    sched = schedule_blocks(idx, deps, phase, trk, md, ext, links, pos)
    sync_dev_status(idx, pm, phase, depth)
    print(f'{len(idx)} WI, {total:g} M/D, 페이즈 {len(PHASES)}개 — 선행 순서 위반 0, 순환 0, 트랙 간 선행 {len(links)}건, '
          f'Wave 역전 {len(inv)}건, 임계 경로 {best[chain_to(max(best, key=best.get))[-1]]:g} M/D' + sched)


def schedule_blocks(idx, deps, phase, trk, md, ext, links, pos):
    """SCHEDULE·PHASE-END·TRACK-LINKS·OPEN-SCOPE 구간을 만든다. 처음부터(기준선)와 남은 작업(DEV-STATUS 개발 완료 제외) 두 가지."""
    finished = frozenset(w for w, st in status_states().items() if st.startswith('개발 완료') and w in idx)
    open_scope = {}
    for tname in ('PMS', 'QMS'):
        seeds = [w for w in idx if trk[w] == tname and idx[w]['Wave'] in ('W0', 'W1')]
        open_scope[tname] = closure(seeds, deps)
    runs = {}
    for team in sorted(set(TEAMS) | {DEFAULT_TEAM}):
        runs[team, 'all'] = simulate(idx, deps, phase, md, ext, team)
        runs[team, 'rest'] = simulate(idx, deps, phase, md, ext, team, finished)

    def end_of(done, ws):
        return max((done[w] for w in ws), default=0.0)
    base_ws = [w for w in idx if trk[w] == BASE]
    lines = ['| QMS 인원 | PMS 인원 | 기반 종료 | PMS 1차 오픈 범위(W0·W1) 종료 | PMS 전체 종료 | QMS 1차 오픈 범위(W0·W1) 종료 | 전체 종료 | 남은 작업: PMS 1차 오픈 범위 | 남은 작업: QMS 1차 오픈 범위 | 남은 작업: 전체 |',
             '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |']
    for team in TEAMS:
        d_all = runs[team, 'all'][0]
        d_rest = runs[team, 'rest'][0]
        cells = [end_of(d_all, base_ws), end_of(d_all, open_scope['PMS']), end_of(d_all, [w for w in idx if trk[w] == 'PMS']),
                 end_of(d_all, open_scope['QMS']), end_of(d_all, idx)]
        rest = [end_of(d_rest, open_scope['PMS']), end_of(d_rest, open_scope['QMS']), end_of(d_rest, idx)]
        mark = ' **(기본)**' if team == DEFAULT_TEAM else ''
        lines.append(f'| {team[0]}{mark} | {team[1]} | ' + ' | '.join(f'{c:.0f}' for c in cells) + ' | '
                     + ' | '.join(f'{c:.0f}일 → {biz_date(c)}' for c in rest) + ' |')
    replace_block(PLAN, 'SCHEDULE', '\n'.join(lines))
    _d, _s, pe = runs[DEFAULT_TEAM, 'all']
    rows = []
    for tname in (BASE, 'QMS', 'PMS'):
        ps = [p for p, *_r, t in PHASES if t == tname]
        rows += [f'**{tname}**', '', '| ' + ' | '.join(f'P{p}' for p in ps) + ' |', '|' + ' --- |' * len(ps),
                 '| ' + ' | '.join(f'{pe[p]:.0f}' for p in ps) + ' |', '']
    replace_block(PLAN, 'PHASE-END', '\n'.join(rows).rstrip())
    # 트랙 간 선행(PMS → QMS)
    d_all, s_all, _pe = runs[DEFAULT_TEAM, 'all']
    tl = [f'{len(links)}건(PMS WI {len({w for w, _d in links})}건이 QMS WI {len({d for _w, d in links})}건을 선행으로 둠). '
          f'시뮬레이션 값은 기본 인원(QMS {DEFAULT_TEAM[0]}명·PMS {DEFAULT_TEAM[1]}명), 처음부터 기준 영업일이다. "대기"는 QMS 선행 때문에 늦어진 날수(다른 선행이 더 늦으면 0).', '',
          '| PMS WI | 페이즈 | Wave | QMS 선행 WI | 선행 페이즈 | 선행 Wave | 선행 완료 | PMS 착수 | 대기 |', '| --- | --- | --- | --- | --- | --- | --- | --- | --- |']
    for w, d in sorted(links, key=lambda x: (phase[x[0]], pos[x[0]], x[1])):
        other = max([d_all[x] for x in deps[w] if x != d], default=0.0)
        wait = max(0.0, d_all[d] - other)
        tl.append(f"| {w} | P{phase[w]} | {idx[w]['Wave']} | {d} | P{phase[d]} | {idx[d]['Wave']} | {d_all[d]:.0f} | {s_all[w]:.0f} | {wait:.0f} |")
    replace_block(PLAN, 'TRACK-LINKS', '\n'.join(tl))
    # 1차 오픈 범위
    os_lines = ['| 범위 | 대상 WI(W0·W1) | 선행 포함 WI | 그중 기반 | 그중 QMS | 그중 PMS | 선행 포함 M/D | 기본 인원 종료(처음부터) |', '| --- | --- | --- | --- | --- | --- | --- | --- |']
    for tname in ('PMS', 'QMS'):
        sc = open_scope[tname]
        seeds = [w for w in idx if trk[w] == tname and idx[w]['Wave'] in ('W0', 'W1')]
        cnt = {t: len([w for w in sc if trk[w] == t]) for t in (BASE, 'QMS', 'PMS')}
        os_lines.append(f"| {tname} 1차 오픈 | {len(seeds)} | {len(sc)} | {cnt[BASE]} | {cnt['QMS']} | {cnt['PMS']} | {sum(md[w] for w in sc):g} | {end_of(d_all, sc):.0f} |")
    pulled_qms = sorted((w for w in open_scope['PMS'] if trk[w] == 'QMS'), key=lambda w: (phase[w], pos[w]))
    os_lines += ['', f"PMS 1차 오픈 범위에 들어오는 QMS WI {len(pulled_qms)}건: " + (', '.join(f'{w}(P{phase[w]}·{idx[w]["Wave"]})' for w in pulled_qms) or '없음')]
    replace_block(PLAN, 'OPEN-SCOPE', '\n'.join(os_lines))
    d4 = runs[DEFAULT_TEAM, 'rest'][0]
    return f', 기본 인원 남은 작업 PMS 1차 오픈 {end_of(d4, open_scope["PMS"]):.0f}일·전체 {end_of(d4, idx):.0f}일'


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
    s += [f'| P{p} | ' + count([w for w in idx if phase[w] == p]) + ' |' for p, *_r in PHASES]
    s += ['', '| Wave | 전체 WI | 개발 완료 | 개발 중 | 보류 |', '| --- | --- | --- | --- | --- |']
    s += [f'| {wv} | ' + count([w for w in idx if idx[w]['Wave'] == wv]) + ' |' for wv in sorted(WAVE, key=WAVE.get)]
    s += [f'| 합계 | ' + count(list(idx)) + ' |']
    replace_block(STATUS, 'DEV-SUMMARY', '\n'.join(s))


if __name__ == '__main__':
    main()
