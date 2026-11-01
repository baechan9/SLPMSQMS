"""SPC·MSA 통계 함수(표준 라이브러리만). 데모 골든 기대값 계산용.

원칙: 관리도 상수·분포 값을 기억한 표로 넣지 않고 정의식에서 직접 계산한다.
- c4: 감마 함수 닫힌 식
- d2, d3: 표준 정규 표본 범위 분포의 수치 적분
- d2*(m, g): Patnaik 근사 sqrt(d2^2 + d3^2 / g) (AIAG MSA 평균범위법 K1·K2·K3의 근거)
- F·t 분포 p값: 정규화 불완전 베타 함수(연분수 전개)
운영 계산(Snowflake)은 SL이 검수한 상수 표와 scipy·statsmodels를 쓰며, 이 모듈은 그 결과를 대조할 독립 구현이다.
`python3 qstats.py`로 자체 검증을 실행한다."""
import math

# ---------------------------------------------------------------- 정규 분포


def norm_pdf(x):
    return math.exp(-0.5 * x * x) / math.sqrt(2.0 * math.pi)


def norm_cdf(x):
    return 0.5 * (1.0 + math.erf(x / math.sqrt(2.0)))


# ---------------------------------------------------------------- 관리도 상수


def c4(n):
    """E[s]/σ (표본 크기 n, 정규). c4 = sqrt(2/(n-1)) · Γ(n/2) / Γ((n-1)/2)."""
    return math.sqrt(2.0 / (n - 1)) * math.exp(math.lgamma(n / 2.0) - math.lgamma((n - 1) / 2.0))


_GRID_L, _GRID_N = 8.0, 1600
_cache = {}


def _grid():
    if 'grid' not in _cache:
        h = 2 * _GRID_L / _GRID_N
        xs = [-_GRID_L + i * h for i in range(_GRID_N + 1)]
        _cache['grid'] = (h, xs, [norm_cdf(x) for x in xs])
    return _cache['grid']


def d2(n):
    """E[W]/σ, W = 표본 범위. d2 = ∫ [1 − Φ(x)^n − (1 − Φ(x))^n] dx (심프슨 적분, 구간 ±8σ)."""
    key = ('d2', n)
    if key not in _cache:
        h, xs, ps = _grid()
        f = [1.0 - p ** n - (1.0 - p) ** n for p in ps]
        s = f[0] + f[-1] + sum((4 if i % 2 else 2) * f[i] for i in range(1, len(f) - 1))
        _cache[key] = s * h / 3.0
    return _cache[key]


def d3(n):
    """sd[W]/σ. E[W²] = 2 ∫∫_{x<y} [1 − Φ(y)^n − (1 − Φ(x))^n + (Φ(y) − Φ(x))^n] dx dy, d3 = sqrt(E[W²] − d2²).
    사다리꼴 2차원 적분(격자 0.04σ). 대각선은 가중치 1/2."""
    key = ('d3', n)
    if key not in _cache:
        step = 4  # 격자 0.01σ × 4 = 0.04σ (속도와 소수 3자리 정확도 균형)
        h0, xs, ps = _grid()
        ps = ps[::step]
        h = h0 * step
        m = len(ps)
        pn = [p ** n for p in ps]
        qn = [(1.0 - p) ** n for p in ps]
        total = 0.0
        for j in range(m):              # y 인덱스
            pj, pnj = ps[j], pn[j]
            row = 0.0
            for i in range(j):          # x < y
                row += 1.0 - pnj - qn[i] + (pj - ps[i]) ** n
            row += 0.5 * (1.0 - pnj - qn[j])  # 대각선(x = y)
            total += row
        ew2 = 2.0 * total * h * h
        _cache[key] = math.sqrt(max(ew2 - d2(n) ** 2, 0.0))
    return _cache[key]


def d2_star(m, g):
    """AIAG 평균범위법의 d2*(m: 범위를 구한 표본 크기, g: 범위 개수). Patnaik 근사 sqrt(d2² + d3²/g)."""
    return math.sqrt(d2(m) ** 2 + d3(m) ** 2 / g)


def spc_constants(n):
    """부분군 크기 n의 관리도 상수. A2·D3·D4는 d2·d3에서, A3·B3·B4는 c4에서 유도한다(정의식)."""
    _d2, _d3, _c4 = d2(n), d3(n), c4(n)
    return {
        'N': n, 'D2': _d2, 'D3_CONST': _d3, 'C4': _c4,
        'A2': 3.0 / (_d2 * math.sqrt(n)),
        'D3': max(0.0, 1.0 - 3.0 * _d3 / _d2), 'D4': 1.0 + 3.0 * _d3 / _d2,
        'A3': 3.0 / (_c4 * math.sqrt(n)),
        'B3': max(0.0, 1.0 - 3.0 * math.sqrt(1.0 - _c4 ** 2) / _c4),
        'B4': 1.0 + 3.0 * math.sqrt(1.0 - _c4 ** 2) / _c4,
        'E2': 3.0 / _d2,
    }


# ---------------------------------------------------------------- 기초 통계


def mean(xs):
    return sum(xs) / len(xs)


def stdev(xs):
    """표본 표준편차(n−1)."""
    m = mean(xs)
    return math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))


# ---------------------------------------------------------------- 관리 한계


def xbar_s_limits(subgroups):
    """X̄-S 관리도. CL = X̿, UCL/LCL = X̿ ± A3·S̄, S 관리도 B3·S̄ ~ B4·S̄, σw = S̄/c4."""
    n = len(subgroups[0])
    k = spc_constants(n)
    xbb = mean([mean(s) for s in subgroups])
    sbar = mean([stdev(s) for s in subgroups])
    return {'chart': 'XBAR_S', 'n': n, 'cl': xbb, 'ucl': xbb + k['A3'] * sbar, 'lcl': xbb - k['A3'] * sbar,
            'disp_cl': sbar, 'disp_ucl': k['B4'] * sbar, 'disp_lcl': (k['B3'] * sbar) if k['B3'] > 0 else None,
            'sigma_within': sbar / k['C4'], 'subgroups': len(subgroups)}


def xbar_r_limits(subgroups):
    """X̄-R 관리도. UCL/LCL = X̿ ± A2·R̄, R 관리도 D3·R̄ ~ D4·R̄, σw = R̄/d2."""
    n = len(subgroups[0])
    k = spc_constants(n)
    xbb = mean([mean(s) for s in subgroups])
    rbar = mean([max(s) - min(s) for s in subgroups])
    return {'chart': 'XBAR_R', 'n': n, 'cl': xbb, 'ucl': xbb + k['A2'] * rbar, 'lcl': xbb - k['A2'] * rbar,
            'disp_cl': rbar, 'disp_ucl': k['D4'] * rbar, 'disp_lcl': (k['D3'] * rbar) if k['D3'] > 0 else None,
            'sigma_within': rbar / k['D2'], 'subgroups': len(subgroups)}


def imr_limits(values):
    """I-MR 관리도. σw = MR̄/d2(2), UCL/LCL = X̄ ± 3σw(= E2·MR̄), MR 관리도 UCL = D4(2)·MR̄."""
    k = spc_constants(2)
    mrs = [abs(values[i] - values[i - 1]) for i in range(1, len(values))]
    mrbar = mean(mrs)
    xb = mean(values)
    sw = mrbar / k['D2']
    return {'chart': 'I_MR', 'n': 1, 'cl': xb, 'ucl': xb + 3 * sw, 'lcl': xb - 3 * sw,
            'disp_cl': mrbar, 'disp_ucl': k['D4'] * mrbar, 'disp_lcl': None,
            'sigma_within': sw, 'subgroups': len(values)}


# ---------------------------------------------------------------- 공정능력


def capability(values, lsl, usl, sigma_within):
    """SPC-003 BR-1. Cp = (USL−LSL)/6σw, CPU = (USL−μ)/3σw, CPL = (μ−LSL)/3σw, Cpk = min.
    Pp·Ppk는 σo(전체 표본 표준편차). 편측이면 Cp·Pp = None, ONE_SIDED."""
    mu = mean(values)
    so = stdev(values)
    out = {'n': len(values), 'mean': mu, 'sigma_within': sigma_within, 'sigma_overall': so,
           'cp': None, 'pp': None, 'cpu': None, 'cpl': None, 'cpk': None, 'ppk': None, 'flags': []}
    ppu = ppl = None
    if usl is not None:
        out['cpu'] = (usl - mu) / (3 * sigma_within)
        ppu = (usl - mu) / (3 * so)
    if lsl is not None:
        out['cpl'] = (mu - lsl) / (3 * sigma_within)
        ppl = (mu - lsl) / (3 * so)
    if usl is not None and lsl is not None:
        out['cp'] = (usl - lsl) / (6 * sigma_within)
        out['pp'] = (usl - lsl) / (6 * so)
    else:
        out['flags'].append('ONE_SIDED')
    out['cpk'] = min(v for v in (out['cpu'], out['cpl']) if v is not None)
    out['ppk'] = min(v for v in (ppu, ppl) if v is not None)
    if len(values) < 100:
        out['flags'].append('LOW_SAMPLE')
    return out


def anderson_darling_p(values):
    """정규성 Anderson-Darling(평균·분산 추정, D'Agostino & Stephens 1986 Case 3) p값."""
    xs = sorted(values)
    n = len(xs)
    m, s = mean(xs), stdev(xs)
    a2 = 0.0
    for i, x in enumerate(xs, start=1):
        fi = min(max(norm_cdf((x - m) / s), 1e-15), 1 - 1e-15)
        fn = min(max(norm_cdf((xs[n - i] - m) / s), 1e-15), 1 - 1e-15)
        a2 += (2 * i - 1) * (math.log(fi) + math.log(1 - fn))
    a2 = -n - a2 / n
    a = a2 * (1 + 0.75 / n + 2.25 / n ** 2)
    if a >= 0.6:
        p = math.exp(1.2937 - 5.709 * a + 0.0186 * a * a)
    elif a >= 0.34:
        p = math.exp(0.9177 - 4.279 * a - 1.38 * a * a)
    elif a >= 0.2:
        p = 1 - math.exp(-8.318 + 42.796 * a - 59.938 * a * a)
    else:
        p = 1 - math.exp(-13.436 + 101.14 * a - 223.73 * a * a)
    return max(0.0, min(1.0, p))


# ---------------------------------------------------------------- 이상 판정 규칙(Vol.4 SPC-001 표)

RULE_DEF = [
    # code, window_n, hit_m, zone_sigma, pattern
    ('R1', 1, 1, 3, 'BEYOND'),
    ('R2', 9, 9, 0, 'SAME_SIDE'),
    ('R3', 6, 6, 0, 'TREND'),
    ('R4', 14, 14, 0, 'ALTERNATE'),
    ('R5', 3, 2, 2, 'BEYOND'),
    ('R6', 5, 4, 1, 'BEYOND'),
    ('R7', 15, 15, 1, 'WITHIN'),
    ('R8', 8, 8, 1, 'OUTSIDE_BOTH'),
]


def evaluate_rules(points, cl, ucl, lcl, rules):
    """points: 판정 대상 값 목록(시간순). 규칙이 완성되는 점(창의 마지막 점)마다 (index, rule) 기록.
    σ 구역 = (UCL − CL)/3. R5·R6은 '같은 쪽' 조건, R8은 양쪽 섞여도 1σ 밖이면 충족."""
    sig = (ucl - cl) / 3.0
    hits = []
    for i in range(len(points)):
        for code, w, m, z, pat in RULE_DEF:
            if code not in rules or i + 1 < w:
                continue
            win = points[i - w + 1:i + 1]
            ok = False
            if code == 'R1':
                ok = win[0] > ucl or (lcl is not None and win[0] < lcl)
            elif pat == 'SAME_SIDE':
                ok = all(p > cl for p in win) or all(p < cl for p in win)
            elif pat == 'TREND':
                ok = all(win[j] > win[j - 1] for j in range(1, w)) or all(win[j] < win[j - 1] for j in range(1, w))
            elif pat == 'ALTERNATE':
                d = [win[j] - win[j - 1] for j in range(1, w)]
                ok = all(d[j] * d[j - 1] < 0 for j in range(1, len(d)))
            elif pat == 'BEYOND':
                up = sum(1 for p in win if p > cl + z * sig)
                dn = sum(1 for p in win if p < cl - z * sig)
                ok = (up >= m and win[-1] > cl + z * sig) or (dn >= m and win[-1] < cl - z * sig)
            elif pat == 'WITHIN':
                ok = all(abs(p - cl) < sig for p in win)
            elif pat == 'OUTSIDE_BOTH':
                ok = all(abs(p - cl) > sig for p in win)
            if ok:
                hits.append((i, code))
    return hits


# ---------------------------------------------------------------- 분포 함수(불완전 베타)


def _betacf(a, b, x):
    """정규화 불완전 베타 함수의 연분수(Lentz 방법)."""
    maxit, eps, fpmin = 300, 3e-14, 1e-300
    qab, qap, qam = a + b, a + 1.0, a - 1.0
    c, d = 1.0, 1.0 - qab * x / qap
    d = 1.0 / (d if abs(d) > fpmin else fpmin)
    h = d
    for m in range(1, maxit + 1):
        m2 = 2 * m
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = 1.0 + aa * d
        d = 1.0 / (d if abs(d) > fpmin else fpmin)
        c = 1.0 + aa / c
        c = c if abs(c) > fpmin else fpmin
        h *= d * c
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
        d = 1.0 + aa * d
        d = 1.0 / (d if abs(d) > fpmin else fpmin)
        c = 1.0 + aa / c
        c = c if abs(c) > fpmin else fpmin
        de = d * c
        h *= de
        if abs(de - 1.0) < eps:
            break
    return h


def betai(a, b, x):
    """I_x(a, b) 정규화 불완전 베타."""
    if x <= 0.0:
        return 0.0
    if x >= 1.0:
        return 1.0
    lbt = math.lgamma(a + b) - math.lgamma(a) - math.lgamma(b) + a * math.log(x) + b * math.log(1.0 - x)
    if x < (a + 1.0) / (a + b + 2.0):
        return math.exp(lbt) * _betacf(a, b, x) / a
    return 1.0 - math.exp(lbt) * _betacf(b, a, 1.0 - x) / b


def f_sf(f, d1, d2_):
    """F 분포 상측 확률 P(F > f)."""
    if f <= 0:
        return 1.0
    return betai(d2_ / 2.0, d1 / 2.0, d2_ / (d2_ + d1 * f))


def t_sf2(t, df):
    """t 분포 양측 p값 P(|T| > |t|)."""
    return betai(df / 2.0, 0.5, df / (df + t * t))


def t_ppf2(p_two_sided, df):
    """양측 유의수준 p에 대한 t 임계값(이분법)."""
    lo, hi = 0.0, 1000.0
    for _ in range(200):
        mid = (lo + hi) / 2
        if t_sf2(mid, df) > p_two_sided:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


# ---------------------------------------------------------------- Gage R&R


def grr_anova(data, tolerance=None, alpha=0.25, study_mult=6.0, process_sigma=None):
    """2요인 교차 ANOVA Gage R&R(Vol.6b MSA-003 BR-2·4).
    data: {(part, appraiser, trial): value}. 교호작용 p > alpha면 오차에 합쳐(풀링) 다시 계산한다.
    분산 성분: 반복성 = MS_E, 교호 = (MS_PO − MS_E)/r, 평가자 = (MS_O − MS_PO)/(p·r), 부품 = (MS_P − MS_PO)/(o·r).
    풀링 시 MS_PO 자리에 MS_pooled. 음수 성분은 0."""
    parts = sorted({k[0] for k in data})
    apprs = sorted({k[1] for k in data})
    trials = sorted({k[2] for k in data})
    p, o, r = len(parts), len(apprs), len(trials)
    vals = list(data.values())
    gm = mean(vals)
    mp = {i: mean([data[(i, j, t)] for j in apprs for t in trials]) for i in parts}
    mo = {j: mean([data[(i, j, t)] for i in parts for t in trials]) for j in apprs}
    mpo = {(i, j): mean([data[(i, j, t)] for t in trials]) for i in parts for j in apprs}
    ss_p = o * r * sum((mp[i] - gm) ** 2 for i in parts)
    ss_o = p * r * sum((mo[j] - gm) ** 2 for j in apprs)
    ss_po = r * sum((mpo[(i, j)] - mp[i] - mo[j] + gm) ** 2 for i in parts for j in apprs)
    ss_e = sum((data[(i, j, t)] - mpo[(i, j)]) ** 2 for i in parts for j in apprs for t in trials)
    ss_t = sum((v - gm) ** 2 for v in vals)
    df_p, df_o, df_po, df_e = p - 1, o - 1, (p - 1) * (o - 1), p * o * (r - 1)
    ms_p, ms_o, ms_po, ms_e = ss_p / df_p, ss_o / df_o, ss_po / df_po, ss_e / df_e
    f_po = ms_po / ms_e
    p_po = f_sf(f_po, df_po, df_e)
    anova_full = [
        {'source': 'PART', 'df': df_p, 'ss': ss_p, 'ms': ms_p, 'f': ms_p / ms_po, 'p': f_sf(ms_p / ms_po, df_p, df_po)},
        {'source': 'APPRAISER', 'df': df_o, 'ss': ss_o, 'ms': ms_o, 'f': ms_o / ms_po, 'p': f_sf(ms_o / ms_po, df_o, df_po)},
        {'source': 'PART_X_APPRAISER', 'df': df_po, 'ss': ss_po, 'ms': ms_po, 'f': f_po, 'p': p_po},
        {'source': 'REPEATABILITY', 'df': df_e, 'ss': ss_e, 'ms': ms_e, 'f': None, 'p': None},
        {'source': 'TOTAL', 'df': p * o * r - 1, 'ss': ss_t, 'ms': None, 'f': None, 'p': None},
    ]
    pooled = p_po > alpha
    if pooled:
        df_pl = df_po + df_e
        ms_pl = (ss_po + ss_e) / df_pl
        anova_used = [
            {'source': 'PART', 'df': df_p, 'ss': ss_p, 'ms': ms_p, 'f': ms_p / ms_pl, 'p': f_sf(ms_p / ms_pl, df_p, df_pl)},
            {'source': 'APPRAISER', 'df': df_o, 'ss': ss_o, 'ms': ms_o, 'f': ms_o / ms_pl, 'p': f_sf(ms_o / ms_pl, df_o, df_pl)},
            {'source': 'REPEATABILITY', 'df': df_pl, 'ss': ss_po + ss_e, 'ms': ms_pl, 'f': None, 'p': None},
            {'source': 'TOTAL', 'df': p * o * r - 1, 'ss': ss_t, 'ms': None, 'f': None, 'p': None},
        ]
        var_rep = ms_pl
        var_int = 0.0
        var_app = max((ms_o - ms_pl) / (p * r), 0.0)
        var_part = max((ms_p - ms_pl) / (o * r), 0.0)
    else:
        anova_used = anova_full
        var_rep = ms_e
        var_int = max((ms_po - ms_e) / r, 0.0)
        var_app = max((ms_o - ms_po) / (p * r), 0.0)
        var_part = max((ms_p - ms_po) / (o * r), 0.0)
    ev = math.sqrt(var_rep)
    av = math.sqrt(var_app + var_int)
    grr = math.sqrt(ev ** 2 + av ** 2)
    pv = math.sqrt(var_part)
    tv = math.sqrt(grr ** 2 + pv ** 2)
    comps = {'REPEATABILITY': var_rep, 'REPRODUCIBILITY': var_app + var_int, 'APPRAISER': var_app,
             'PART_X_APPRAISER': var_int, 'TOTAL_GRR': grr ** 2, 'PART_TO_PART': var_part, 'TOTAL': tv ** 2}
    table = []
    for name, var in comps.items():
        sd = math.sqrt(var)
        table.append({'source': name, 'variance': var, 'pctContribution': 100 * var / tv ** 2, 'sd': sd,
                      'studyVar': study_mult * sd, 'pctStudyVar': 100 * sd / tv,
                      'pctTolerance': (100 * study_mult * sd / tolerance) if tolerance else None})
    out = {'method': 'ANOVA', 'parts': p, 'appraisers': o, 'trials': r, 'alphaInteraction': alpha,
           'interactionPValue': p_po, 'interactionPooled': pooled, 'anovaFull': anova_full, 'anovaUsed': anova_used,
           'components': table, 'EV': ev, 'AV': av, 'GRR': grr, 'PV': pv, 'TV': tv,
           'pctGrrStudyVar': 100 * grr / tv,
           'pctGrrTolerance': (100 * study_mult * grr / tolerance) if tolerance else None,
           'pctGrrProcess': (100 * grr / process_sigma) if process_sigma else None,
           'ndc': math.floor(1.41 * pv / grr) if grr > 0 else None, 'ssCheck': abs(ss_p + ss_o + ss_po + ss_e - ss_t)}
    return out


def grr_xbar_r(data, tolerance=None, study_mult=6.0):
    """평균범위법(Vol.6b MSA-003 BR-3). K1 = 1/d2(trials), K2 = 1/d2*(appraisers, 1), K3 = 1/d2*(parts, 1).
    이 K 값은 AIAG MSA 표와 같은 정의식이며 운영은 검수된 ML.MSA_CONSTANT를 쓴다."""
    parts = sorted({k[0] for k in data})
    apprs = sorted({k[1] for k in data})
    trials = sorted({k[2] for k in data})
    n, o, r = len(parts), len(apprs), len(trials)
    k1, k2, k3 = 1.0 / d2(r), 1.0 / d2_star(o, 1), 1.0 / d2_star(n, 1)
    rbar_app = [mean([max(data[(i, j, t)] for t in trials) - min(data[(i, j, t)] for t in trials) for i in parts])
                for j in apprs]
    rbarbar = mean(rbar_app)
    xbar_app = [mean([data[(i, j, t)] for i in parts for t in trials]) for j in apprs]
    xdiff = max(xbar_app) - min(xbar_app)
    part_means = [mean([data[(i, j, t)] for j in apprs for t in trials]) for i in parts]
    rp = max(part_means) - min(part_means)
    ev = rbarbar * k1
    av = math.sqrt(max((xdiff * k2) ** 2 - ev ** 2 / (n * r), 0.0))
    grr = math.sqrt(ev ** 2 + av ** 2)
    pv = rp * k3
    tv = math.sqrt(grr ** 2 + pv ** 2)
    return {'method': 'XBAR_R', 'K1': k1, 'K2': k2, 'K3': k3, 'EV': ev, 'AV': av, 'GRR': grr, 'PV': pv, 'TV': tv,
            'pctGrrStudyVar': 100 * grr / tv,
            'pctGrrTolerance': (100 * study_mult * grr / tolerance) if tolerance else None,
            'ndc': math.floor(1.41 * pv / grr) if grr > 0 else None}


def msa_verdict(pct_tol, pct_sv, ndc, basis='WORST', ok_max=10.0, cond_max=30.0, ndc_min=5):
    """Vol.6b MSA-003 BR-5 판정."""
    if basis == 'TOLERANCE':
        g = pct_tol
    elif basis == 'STUDY_VAR':
        g = pct_sv
    else:
        g = max(v for v in (pct_tol, pct_sv) if v is not None)
    if ndc is not None and ndc < ndc_min:
        return 'UNACCEPTABLE', g, f'ndc < {ndc_min}'
    if g < ok_max:
        return 'ACCEPTABLE', g, f'%GRR({basis}) {g:.2f} < {ok_max}'
    if g <= cond_max:
        return 'CONDITIONAL', g, f'{ok_max} ≤ %GRR({basis}) {g:.2f} ≤ {cond_max}'
    return 'UNACCEPTABLE', g, f'%GRR({basis}) {g:.2f} > {cond_max}'


def bias_study(values, reference, tolerance=None, conf=0.95):
    """편의(Vol.6b MSA-004 BR-1): Bias = 평균 − 기준값, t = Bias/(s/√n), 양측 p, 신뢰구간."""
    n = len(values)
    b = mean(values) - reference
    s = stdev(values)
    se = s / math.sqrt(n)
    t = b / se if se > 0 else float('inf')
    tc = t_ppf2(1 - conf, n - 1)
    return {'bias': b, 's': s, 't': t, 'p': t_sf2(t, n - 1), 'ciLow': b - tc * se, 'ciHigh': b + tc * se,
            'pctTolerance': (100 * abs(b) / tolerance) if tolerance else None}


def linearity_study(pairs):
    """직선성(Vol.6b MSA-004 BR-2): 편의 = 측정 − 기준을 기준값에 최소제곱 회귀. pairs: [(reference, measured)]."""
    xs = [p[0] for p in pairs]
    ys = [p[1] - p[0] for p in pairs]
    n = len(xs)
    mx, my = mean(xs), mean(ys)
    sxx = sum((x - mx) ** 2 for x in xs)
    sxy = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    slope = sxy / sxx
    intercept = my - slope * mx
    resid = [y - (intercept + slope * x) for x, y in zip(xs, ys)]
    s2 = sum(e * e for e in resid) / (n - 2)
    se_slope = math.sqrt(s2 / sxx)
    se_int = math.sqrt(s2 * (1.0 / n + mx * mx / sxx))
    ss_tot = sum((y - my) ** 2 for y in ys)
    return {'slope': slope, 'intercept': intercept, 'r2': 1 - sum(e * e for e in resid) / ss_tot if ss_tot else None,
            'slopeP': t_sf2(slope / se_slope, n - 2), 'interceptP': t_sf2(intercept / se_int, n - 2)}


# ---------------------------------------------------------------- 계수형 일치성


def cohen_kappa(a, b):
    """두 판정 목록의 Cohen kappa = (po − pe)/(1 − pe)."""
    cats = sorted(set(a) | set(b))
    n = len(a)
    po = sum(1 for x, y in zip(a, b) if x == y) / n
    pe = sum((a.count(c) / n) * (b.count(c) / n) for c in cats)
    return (po - pe) / (1 - pe) if pe < 1 else 1.0


def fleiss_kappa(ratings):
    """ratings: 항목별 판정 목록([[OK, NG, OK], ...]). 항목마다 평가 수가 같아야 한다."""
    cats = sorted({c for row in ratings for c in row})
    n = len(ratings[0])
    N = len(ratings)
    pj = {c: sum(row.count(c) for row in ratings) / (N * n) for c in cats}
    pi = [(sum(row.count(c) ** 2 for c in cats) - n) / (n * (n - 1)) for row in ratings]
    pbar = mean(pi)
    pe = sum(v * v for v in pj.values())
    return (pbar - pe) / (1 - pe) if pe < 1 else 1.0


# ---------------------------------------------------------------- 자체 검증


def _self_test():
    """알려진 표 값과 정의식 결과를 대조한다(소수 3자리). 표 값은 검증 목적의 대조에만 쓴다."""
    known_d2 = {2: 1.128, 3: 1.693, 4: 2.059, 5: 2.326, 10: 3.078, 25: 3.931}
    known_d3 = {2: 0.853, 3: 0.888, 4: 0.880, 5: 0.864, 10: 0.797, 25: 0.708}
    known_c4 = {2: 0.7979, 5: 0.9400, 10: 0.9727, 25: 0.9896}
    for n, v in known_d2.items():
        assert abs(d2(n) - v) < 0.001, ('d2', n, d2(n))
    for n, v in known_d3.items():
        assert abs(d3(n) - v) < 0.002, ('d3', n, d3(n))
    for n, v in known_c4.items():
        assert abs(c4(n) - v) < 0.0001, ('c4', n, c4(n))
    k5 = spc_constants(5)
    assert abs(k5['A2'] - 0.577) < 0.001 and abs(k5['D4'] - 2.114) < 0.002 and k5['D3'] == 0.0
    assert abs(k5['A3'] - 1.427) < 0.001 and abs(k5['B4'] - 2.089) < 0.001
    assert abs(d2_star(3, 1) - 1.9116) < 0.002 and abs(1 / d2_star(10, 1) - 0.3146) < 0.0005
    assert abs(t_sf2(2.262, 9) - 0.05) < 0.001, t_sf2(2.262, 9)
    assert abs(f_sf(4.10, 2, 10) - 0.05) < 0.001, f_sf(4.10, 2, 10)
    data = {(i, j, t): 10 + i * 0.1 + j * 0.01 + ((i * 7 + j * 3 + t * 5) % 11) * 0.001
            for i in range(10) for j in range(3) for t in range(3)}
    g = grr_anova(data)
    assert g['ssCheck'] < 1e-9
    assert abs(cohen_kappa(['OK', 'NG', 'OK', 'OK'], ['OK', 'NG', 'OK', 'OK']) - 1.0) < 1e-12
    print('qstats 자체 검증 통과: d2(5)=%.4f d3(5)=%.4f c4(5)=%.4f A2(5)=%.4f D4(5)=%.4f' % (
        d2(5), d3(5), c4(5), k5['A2'], k5['D4']))


if __name__ == '__main__':
    _self_test()
