"""Snowflake 데모 데이터·골든 기대값·DWH 응답 목 생성기(표준 라이브러리만).

입력: demo_master.json, 데모 명세(docs/docs/40-demo/demo-data-spec.md)의 S1·S5·S7·S8·S10·S12·S13 수치.
출력(data/demo 아래):
  snowflake/{SCHEMA}.{TABLE}.csv, snowflake/load_demo.sql
  expected/spc_S7.json, msa_S8.json, b2b_S10.json, eol_S13.json, kpi_S5.csv, gauge_S12.json(원천 있을 때)
  salesforce/90_CMN_KpiValue__c.csv, 91~97(SPC 계획·한계·알람, MSA 연구·평가자, 고객 결함·품번 매핑)
  mocks/dwh/{QueryKey}/{case}.json
  wi-change-requests-snowflake.md, README-snowflake.md
시각은 모두 UTC(ISO 8601 'Z')로 저장한다. 공장 시간대 변환은 README-snowflake.md 참조.
Salesforce 데이터 작업 CSV(수입검사·NCR·4M)가 있으면 INSPECTION_RESULT·NCR_DEFECT·FOURM_CHANGE를 파생한다."""
import base64
import csv
import datetime as dt
import glob
import hashlib
import json
import math
import os
import struct
import zlib
from zoneinfo import ZoneInfo

import qstats
from common import ROOT, rng, write_csv, write_json, out_path

UTC = dt.timezone.utc
ENGINE_VERSION = 'msa-1.0.0-demo'
GENERATED_AT = '2026-12-01T00:00:03Z'
LOADED_AT = [None]  # eol_row 등 ctx 없는 함수용
SPC_ENGINE = 'spc-1.0.0-demo'


# ============================================================== 공통

def sha1(*parts):
    return hashlib.sha1('|'.join(str(p) for p in parts).encode('utf-8')).hexdigest()


def sha256(*parts):
    return hashlib.sha256('|'.join(str(p) for p in parts).encode('utf-8')).hexdigest()


def iso(ts):
    return ts.astimezone(UTC).strftime('%Y-%m-%dT%H:%M:%SZ')


def rnd(x, nd=6):
    return None if x is None else round(x, nd)


def daterange(d0, d1):
    d = d0
    while d <= d1:
        yield d
        d += dt.timedelta(days=1)


def month_start(d):
    return d.replace(day=1)


def add_months(d, n):
    y, m = divmod(d.month - 1 + n, 12)
    return dt.date(d.year + y, m + 1, 1)


def months_between(a, b):
    return (b.year - a.year) * 12 + (b.month - a.month)


def poisson(r, lam):
    """Knuth(작은 λ) / 정규 근사(큰 λ)."""
    if lam <= 0:
        return 0
    if lam > 50:
        return max(0, int(round(r.gauss(lam, math.sqrt(lam)))))
    lim, k, p = math.exp(-lam), 0, 1.0
    while True:
        k += 1
        p *= r.random()
        if p <= lim:
            return k - 1


class Ctx:
    def __init__(self, master, clock):
        self.m = master
        self.clock = clock
        self.seed = master['meta']['seed']
        self.plants = {p['code']: p for p in master['plants']}
        self.tz = {c: ZoneInfo(p['timeZone']) for c, p in self.plants.items()}
        self.items = {i['itemNo']: i for i in master['items']}
        self.chars = {(c['item'], c['charNo']): c for c in master['characteristics']}
        self.suppliers = {s['vendorNo']: s for s in master['suppliers']}
        self.customers = {c['oemCode']: c for c in master['customers']}
        self.vehicles = {v['key']: v for v in master['vehicles']}
        self.today = clock.today
        self.counts = {}
        self.change_requests = []
        self.notes = []
        self.kpis = []
        self.keys = {}
        self.msa_verdicts = []
        self.loaded_at = iso(self.local(self.d('2026-11-30'), 23, 55, 'KR01'))

    def d(self, iso_date):
        return self.clock.d(iso_date)

    def local(self, date, hour, minute, plant, second=0):
        return dt.datetime(date.year, date.month, date.day, hour, minute, second, tzinfo=self.tz[plant])

    def char_key(self, item, char_no):
        c = self.chars[(item, char_no)]
        return f"{item}-{char_no}-{c['from'].replace('-', '')}"

    def snow(self, schema_table, rows, fields=None):
        write_csv(f'snowflake/{schema_table}.csv', rows, fields)
        self.counts[schema_table] = len(rows)

    def sf(self, name, rows, fields=None):
        rows = [{k: (str(v).lower() if isinstance(v, bool) else v) for k, v in r.items()} for r in rows]
        write_csv(f'salesforce/{name}.csv', rows, fields)
        self.counts['salesforce/' + name] = len(rows)

    def cr(self, target, content, temp):
        self.change_requests.append((target, content, temp))


def envelope(query_key, params, columns, rows, mode='QUERY', as_of=None, stale=False, truncated=False,
             scope='KR01', warnings=None, error=None, result=None, calc_version=None, http=None):
    """데모 명세 7절 응답 봉투 + DWH-004 확장 필드(result, cacheHit, requestId)."""
    env = {
        'queryKey': query_key, 'mode': mode, 'version': 1, 'params': params,
        'columns': [{'name': n, 'type': t, 'unit': u} for n, t, u in columns],
        'rows': rows if not error else [], 'rowCount': 0 if error else len(rows),
        'truncated': truncated, 'asOf': as_of, 'stale': stale, 'scopeNote': scope,
        'generatedAt': GENERATED_AT, 'durationMs': 840 if not error else 8000,
        'calcVersion': calc_version, 'warnings': warnings or [],
        'errorCode': error[0] if error else None, 'errorMessage': error[1] if error else None,
        'result': result, 'cacheHit': False, 'requestId': 'demo-' + sha1(query_key, json.dumps(params, sort_keys=True))[:12],
    }
    if http:
        env['mockHttpStatus'] = http
    return env


def write_mock(ctx, key, case, env):
    write_json(f'mocks/dwh/{key}/{case}.json', env)
    ctx.counts.setdefault('mocks', []).append(f'{key}/{case}')


# ============================================================== SPC

SPC_PLANS = [
    {'key': 'KR01-L02-OP10-C10', 'no': 'SPC-KR01-00001', 'logical': 'S7-PLAN', 'plant': 'KR01', 'line': 'L02',
     'op': 'OP10', 'item': 'S-LENS-BE1', 'char': 'C10', 'point': 'KR01-M2-OP10-THK', 'chart': 'XBAR_S', 'n': 5,
     'rules': ['R1', 'R2', 'R3', 'R5'], 'owner': 'E1103', 'schedule': (0, 23, 7), 'gauge': 'GA-KR01-0123',
     'res': 0.001, 'name': 'BE1 렌즈 두께 L02 사출', 'confirmer': 'E1103'},
    {'key': 'KR01-L01-OP20-C40', 'no': 'SPC-KR01-00002', 'logical': 'S1-SPC-BEAD', 'plant': 'KR01', 'line': 'L01',
     'op': 'OP20', 'item': '63117-BE1L', 'char': 'C40', 'point': 'KR01-A1-OP20-BEAD', 'chart': 'XBAR_S', 'n': 5,
     'rules': ['R1', 'R2', 'R3', 'R5'], 'owner': 'E1103', 'schedule': (6, 21, 6), 'gauge': 'GA-KR01-0610',
     'res': 0.01, 'name': 'BE1 실링 비드 폭 L01 OP20', 'confirmer': 'E1103'},
    {'key': 'KR01-L01-OP40-C30', 'no': 'SPC-KR01-00003', 'logical': 'S7-PLAN-LEAK', 'plant': 'KR01', 'line': 'L01',
     'op': 'OP40', 'item': '63117-BE1L', 'char': 'C30', 'point': 'KR01-A1-OP40-LEAK', 'chart': 'XBAR_S', 'n': 5,
     'rules': ['R1', 'R2'], 'owner': 'E1103', 'schedule': (6, 21, 6), 'gauge': 'GA-KR01-0310',
     'res': 0.01, 'name': 'BE1 기밀 누설량 L01 OP40(편측)', 'confirmer': 'E1103'},
    {'key': 'CN01-L01-OP60-C20', 'no': 'SPC-CN01-00001', 'logical': 'S13-PLAN', 'plant': 'CN01', 'line': 'L01',
     'op': 'OP60', 'item': '92101-KC1L', 'char': 'C20', 'point': 'CN01-A1-OP60-AIMV', 'chart': 'I_MR', 'n': 1,
     'rules': ['R1', 'R2', 'R3', 'R5'], 'owner': 'E2102', 'schedule': (7, 22, 6), 'gauge': 'GA-CN01-0102',
     'res': 0.01, 'name': 'KC1 조준 수직각 EOL', 'confirmer': 'E2101'},
    {'key': 'KR01-L05-OP50-C20', 'no': 'SPC-KR01-00004', 'logical': 'S7-PLAN-NODATA', 'plant': 'KR01', 'line': 'L05',
     'op': 'OP50', 'item': '92101-HE1L', 'char': 'C20', 'point': 'KR01-A5-OP50-AIMV', 'chart': 'I_MR', 'n': 1,
     'rules': ['R1', 'R2'], 'owner': 'E1103', 'schedule': None, 'gauge': 'GA-KR01-0201',
     'res': 0.01, 'name': 'HE1 조준 수직각 L05(측정 미연결)', 'confirmer': 'E1103'},
]


def frac(t, t0, t1):
    if t <= t0:
        return 0.0
    if t >= t1:
        return 1.0
    return (t - t0).total_seconds() / (t1 - t0).total_seconds()


def process_model(ctx, plan):
    """계획별 (평균, σ) 함수. 명세 S7·S1·S13 수치."""
    p = plan['plant']
    if plan['key'] == 'KR01-L02-OP10-C10':
        # 11-21 00:00부터 11-30 12:00까지 선형 상승 후 3.040 유지(최근 10일 Cpk 약 1.29, 11-30 일 Cpk 약 0.97)
        t0, t1 = ctx.local(ctx.d('2026-11-21'), 0, 0, p), ctx.local(ctx.d('2026-11-30'), 12, 0, p)
        return lambda t: (3.000 + 0.040 * frac(t, t0, t1), 0.0206)
    if plan['key'] == 'KR01-L01-OP20-C40':
        t0, t1 = ctx.local(ctx.d('2026-11-10'), 0, 0, p), ctx.local(ctx.d('2026-11-30'), 21, 59, p)
        return lambda t: (4.00 - 0.30 * frac(t, t0, t1), 0.09)
    if plan['key'] == 'KR01-L01-OP40-C30':
        return lambda t: (1.20, 0.25)
    if plan['key'] == 'CN01-L01-OP60-C20':
        t0 = ctx.local(ctx.d('2026-11-03'), 0, 0, p)
        return lambda t: ((0.108, 0.05) if t >= t0 else (0.0, 0.04))
    return None


def quantize(v, res):
    return round(round(v / res) * res, 6)


def sample_groups(ctx, plan, d0, d1, r_hist, r_drift=None, drift_from=None):
    """계획 일정대로 부분군을 뽑는다. r_drift가 있으면 drift_from 이후 값만 그 난수열로 뽑는다(이력은 고정)."""
    model = process_model(ctx, plan)
    h0, h1, last_wd = plan['schedule']
    p, n = plan['plant'], plan['n']
    groups, no = [], 0
    for day in daterange(d0, d1):
        if last_wd < 7 and day.weekday() >= last_wd:
            continue
        for h in range(h0, h1 + 1):
            no += 1
            vals, tss = [], []
            for k in range(n):
                t = ctx.local(day, h, 5 + k, p)
                mu, sg = model(t)
                r = r_drift if (r_drift and t >= drift_from) else r_hist
                v = r.gauss(mu, sg)
                if plan['key'] == 'KR01-L01-OP40-C30':
                    v = max(v, 0.05)
                vals.append(quantize(v, plan['res']))
                tss.append(t)
            groups.append((no, tss[-1], vals, tss))
    return groups


S7_TARGET = {'study': (1.28, 1.30), 'lastDay': (0.95, 0.99)}


def pick_s7_groups(ctx, plan, d0, d1, lsl, usl):
    """S7: 이력(06-01~11-20)은 고정 난수열, 드리프트 구간(11-21~)은 하위열 0..N 중
    최근 10일 Cpk와 11-30 일 Cpk가 목표 범위(S7_TARGET)에 드는 첫 하위열을 쓴다(결정적)."""
    drift_from = ctx.local(ctx.d('2026-11-21'), 0, 0, plan['plant'])
    last = ctx.d('2026-11-30')
    for k in range(300):
        gs = sample_groups(ctx, plan, d0, d1, rng('spc-' + plan['key'], ctx.seed), rng(f"spc-{plan['key']}-drift-{k}", ctx.seed), drift_from)
        study = [g for g in gs if g[1] >= drift_from]
        day = [g for g in study if g[1].date() == last]

        def cpk(sel):
            sw = qstats.mean([qstats.stdev(g[2]) for g in sel]) / qstats.c4(plan['n'])
            return qstats.capability([v for g in sel for v in g[2]], lsl, usl, sw)['cpk']
        c_study, c_day = cpk(study), cpk(day)
        if S7_TARGET['study'][0] <= c_study <= S7_TARGET['study'][1] and S7_TARGET['lastDay'][0] <= c_day <= S7_TARGET['lastDay'][1]:
            ctx.s7_substream = k
            return gs
    raise RuntimeError('S7 목표 범위 데이터 생성 실패')


def gen_spc(ctx):
    meas, subs, sigs, caps = [], [], [], []
    plan_rows, limit_rows, plan_upd, alarms = [], [], [], []
    expected = {'method': {
        'XBAR_S': 'CL = X̿, UCL/LCL = X̿ ± A3·S̄, S관리도 B3·S̄~B4·S̄, σw = S̄/c4(n). c4 = √(2/(n−1))·Γ(n/2)/Γ((n−1)/2)',
        'XBAR_R': 'σw = R̄/d2. d2 = ∫[1−Φ^n−(1−Φ)^n]dx, d3 = √(2∬_{x<y}[1−Φ(y)^n−(1−Φ(x))^n+(Φ(y)−Φ(x))^n]dxdy − d2²) 수치 적분',
        'I_MR': 'σw = MR̄/d2(2), UCL/LCL = X̄ ± 3σw, MR UCL = D4(2)·MR̄',
        'capability': 'SPC-003 BR-1. Cp=(USL−LSL)/6σw, Cpk=min(CPU,CPL), Pp·Ppk는 기간 전체 표본 표준편차 σo. N_VALUES ≥ 30만 계산, <100 LOW_SAMPLE',
        'rules': 'Vol.4 SPC-001 R1~R8. 한계 ACTIVE(EffectiveFrom) 이후 부분군만, 창은 ACTIVE 구간 안에서. 산포 관리도는 R1만. OOS는 개별 측정값이 규격 밖이면 상태와 관계없이 SPEC',
        'effectiveFrom': '확정 시각 + 30분(spec-snowflake-display 8.2)',
        'engine': SPC_ENGINE}, 'plans': {}}
    d0, d1 = ctx.d('2026-06-01'), ctx.d('2026-11-30')
    basis_to = ctx.d('2026-07-31')
    for plan in SPC_PLANS:
        p, n = plan['plant'], plan['n']
        char = ctx.chars[(plan['item'], plan['char'])]
        lsl, usl = char.get('lsl'), char.get('usl')
        groups = []  # (no, ts_last(local), [values], [meas_ts])
        if plan['schedule']:
            if plan['key'] == 'KR01-L02-OP10-C10':
                groups = pick_s7_groups(ctx, plan, d0, d1, lsl, usl)
            else:
                groups = sample_groups(ctx, plan, d0, d1, rng('spc-' + plan['key'], ctx.seed))
        # 한계(1단계)
        basis = [g for g in groups if g[1].date() <= basis_to]
        if plan['chart'] == 'XBAR_S':
            lim = qstats.xbar_s_limits([g[2] for g in basis]) if basis else None
        else:
            lim = qstats.imr_limits([g[2][0] for g in basis]) if basis else None
        conf_t = ctx.local(ctx.d('2026-08-01'), 8, 30, p)
        eff_t = conf_t + dt.timedelta(minutes=30)
        lim_key = f"{plan['no']}-V1"
        # 신호
        active = [g for g in groups if lim and g[1] >= eff_t]
        main_vals = [(sum(g[2]) / n) for g in active]
        sig_list = []
        if lim:
            for idx, code in qstats.evaluate_rules(main_vals, lim['cl'], lim['ucl'], lim['lcl'], plan['rules']):
                g = active[idx]
                sig_list.append(('OOC', code, 'MAIN', g, main_vals[idx]))
            for i, g in enumerate(active):
                if plan['chart'] == 'XBAR_S':
                    s = qstats.stdev(g[2])
                    if s > lim['disp_ucl'] or (lim['disp_lcl'] is not None and s < lim['disp_lcl']):
                        sig_list.append(('OOC', 'R1', 'DISP', g, s))
                elif i > 0:
                    mr = abs(g[2][0] - active[i - 1][2][0])
                    if mr > lim['disp_ucl']:
                        sig_list.append(('OOC', 'R1', 'DISP', g, mr))
        for g in groups:
            oos = [v for v in g[2] if (usl is not None and v > usl) or (lsl is not None and v < lsl)]
            if oos:
                worst = max(oos, key=lambda v: max((v - usl) if usl is not None else -1e9, (lsl - v) if lsl is not None else -1e9))
                sig_list.append(('OOS', 'SPEC', 'MAIN', g, worst))
        sig_list.sort(key=lambda s: (s[3][0], s[1]))
        # 행 기록
        prev = None
        for g in groups:
            no, ts, vals, tss = g
            for k, (v, t) in enumerate(zip(vals, tss)):
                meas.append({'MEAS_ID': f"{plan['point']}-{t.astimezone(UTC).strftime('%Y%m%d%H%M%S')}-{k + 1}",
                             'PLANT_CODE': p, 'LINE_CODE': plan['line'], 'OP_CODE': plan['op'],
                             'MES_POINT_CODE': plan['point'], 'ITEM_NO': plan['item'], 'MEAS_TS': iso(t), 'VALUE': v,
                             'SAMPLE_N': None, 'DEFECT_COUNT': None, 'MES_SUBGROUP_ID': f"{plan['point']}-{no}",
                             'MES_LOT_NO': f"{p}{plan['line']}{t.strftime('%y%m%d')}{'D' if 6 <= t.hour < 18 else 'N'}",
                             'OPERATOR_ID': None, 'GAUGE_NO': plan['gauge'], '_SOURCE': 'DEMO', '_BATCH_ID': 'DEMO-2026-12-01',
                             '_LOADED_AT': ctx.loaded_at})
            has_oos = any((usl is not None and v > usl) or (lsl is not None and v < lsl) for v in vals)
            subs.append({'PLAN_ID': plan['no'], 'PLAN_NO': plan['no'], 'SUBGROUP_NO': no, 'SUBGROUP_TS': iso(ts), 'N': n,
                         'MEAN': rnd(sum(vals) / n, 8), 'RANGE_VAL': rnd(max(vals) - min(vals), 8) if n > 1 else None,
                         'STDDEV_VAL': rnd(qstats.stdev(vals), 8) if n > 1 else None,
                         'MR_VAL': rnd(abs(vals[0] - prev[2][0]), 8) if (n == 1 and prev) else None,
                         'DEFECTS': None, 'SAMPLE_N': None, 'P_VAL': None, 'U_VAL': None,
                         'UCL_I': None, 'LCL_I': None, 'HAS_OOS': has_oos,
                         'LIMIT_VERSION': 1 if (lim and ts >= eff_t) else None, 'EXCLUDED': False})
            prev = g
        sig_out = []
        for st, code, chart, g, val in sig_list:
            sid = sha1(plan['no'], code, chart, g[0])[:32]
            row = {'SIGNAL_ID': sid, 'PLAN_ID': plan['no'], 'PLAN_NO': plan['no'], 'SIGNAL_TYPE': st, 'RULE_CODE': code,
                   'CHART': chart, 'SUBGROUP_NO': g[0], 'SUBGROUP_TS': iso(g[1]), 'VALUE': rnd(val, 8),
                   'LIMIT_VERSION': 1 if (lim and g[1] >= eff_t) else None,
                   'DETECTED_AT': iso(g[1] + dt.timedelta(minutes=6)), 'SENT_AT': iso(g[1] + dt.timedelta(minutes=8))}
            sigs.append(row)
            sig_out.append(row)
        # 공정능력
        cap_rows = []
        if groups:
            cap_rows = spc_capability(ctx, plan, groups, lim, eff_t, sig_out, lsl, usl, char)
            caps.extend(cap_rows)
        # Salesforce 계획·한계
        plan_rows.append({
            'RecordNo__c': plan['no'], 'Name': plan['name'],
            'Characteristic__r.ExternalKey__c': ctx.char_key(plan['item'], plan['char']),
            'Item__r.ItemNo__c': plan['item'], 'Plant__r.PlantCode__c': p,
            'Line__r.ExternalKey__c': f"{p}-{plan['line']}", 'Operation__r.ExternalKey__c': f"{p}-{plan['line']}-{plan['op']}",
            'MesMeasurePointCode__c': plan['point'], 'DataType__c': 'VARIABLE', 'ChartType__c': plan['chart'],
            'SubgroupSize__c': n, 'SubgroupingMethod__c': 'CONSECUTIVE', 'SamplingIntervalMin__c': 60,
            'RuleCodes__c': ','.join(plan['rules']), 'InitialSubgroups__c': 25, 'LimitReviewRequired__c': False,
            'AlarmOwner__r.EmployeeNo__c': plan['owner'], 'Status__c': 'ACTIVE',
            'ActivatedAt__c': iso(ctx.local(d0, 0, 0, p))})
        if not lim:
            # 측정 미연결 계획: 유사 공정 값을 수동 한계로(SPC-001 BR-5)
            limit_rows.append({
                'ExternalKey__c': lim_key, 'SpcPlan__r.RecordNo__c': plan['no'], 'Version__c': 1, 'Status__c': 'ACTIVE',
                'Source__c': 'MANUAL', 'CenterLine__c': 0.0, 'Ucl__c': 0.12, 'Lcl__c': -0.12, 'DispCenterLine__c': 0.0451,
                'DispUcl__c': 0.1474, 'DispLcl__c': None, 'SigmaWithin__c': 0.04, 'BasisFrom__c': None, 'BasisTo__c': None,
                'SubgroupCount__c': None, 'EffectiveFrom__c': iso(eff_t), 'Reason__c': '유사 공정(CN01 L01 OP60 조준각) 값 적용, MES 측정 연결 전',
                'ConfirmedBy__r.EmployeeNo__c': plan['confirmer'], 'ConfirmedAt__c': iso(conf_t)})
            plan_upd.append({'RecordNo__c': plan['no'], 'CurrentLimit__r.ExternalKey__c': lim_key})
        if lim:
            limit_rows.append({
                'ExternalKey__c': lim_key, 'SpcPlan__r.RecordNo__c': plan['no'], 'Version__c': 1, 'Status__c': 'ACTIVE',
                'Source__c': 'CALCULATED', 'CenterLine__c': rnd(lim['cl']), 'Ucl__c': rnd(lim['ucl']),
                'Lcl__c': rnd(lim['lcl']), 'DispCenterLine__c': rnd(lim['disp_cl']), 'DispUcl__c': rnd(lim['disp_ucl']),
                'DispLcl__c': rnd(lim['disp_lcl']), 'SigmaWithin__c': rnd(lim['sigma_within'], 8),
                'BasisFrom__c': iso(basis[0][3][0]), 'BasisTo__c': iso(basis[-1][1]), 'SubgroupCount__c': len(basis),
                'EffectiveFrom__c': iso(eff_t), 'Reason__c': None, 'ConfirmedBy__r.EmployeeNo__c': plan['confirmer'],
                'ConfirmedAt__c': iso(conf_t)})
            plan_upd.append({'RecordNo__c': plan['no'], 'CurrentLimit__r.ExternalKey__c': lim_key})
        alarms.extend(spc_alarms(ctx, plan, sig_out, char))
        # 기대값
        ex = {'planNo': plan['no'], 'logicalKey': plan['logical'], 'plant': p, 'line': plan['line'], 'op': plan['op'],
              'item': plan['item'], 'charNo': plan['char'], 'specialClass': char.get('special'), 'lsl': lsl, 'usl': usl,
              'chartType': plan['chart'], 'subgroupSize': n, 'subgroups': len(groups), 'measurements': len(groups) * n}
        if lim:
            k = qstats.spc_constants(max(n, 2))
            ex['limit'] = {'version': 1, 'effectiveFrom': iso(eff_t), 'basisFrom': iso(basis[0][3][0]),
                           'basisTo': iso(basis[-1][1]), 'subgroupCount': len(basis),
                           'cl': lim['cl'], 'ucl': lim['ucl'], 'lcl': lim['lcl'], 'dispCl': lim['disp_cl'],
                           'dispUcl': lim['disp_ucl'], 'dispLcl': lim['disp_lcl'], 'sigmaWithin': lim['sigma_within'],
                           'constants': {kk: k[kk] for kk in ('C4', 'D2', 'D3_CONST', 'A2', 'A3', 'B3', 'B4', 'D3', 'D4', 'E2')}}
            if plan['chart'] == 'XBAR_S' and basis:
                ex['limitXbarRCrossCheck'] = {kk: v for kk, v in qstats.xbar_r_limits([g[2] for g in basis]).items()
                                              if kk in ('cl', 'ucl', 'lcl', 'disp_cl', 'disp_ucl', 'sigma_within')}
        by_rule = {}
        for s in sig_out:
            by_rule.setdefault(s['RULE_CODE'] + ('' if s['CHART'] == 'MAIN' else '_DISP'), []).append(
                {'subgroupNo': s['SUBGROUP_NO'], 'subgroupTs': s['SUBGROUP_TS'], 'value': s['VALUE']})
        ex['signals'] = by_rule
        ex['signalCounts'] = {kk: len(v) for kk, v in by_rule.items()}
        ex['capability'] = {
            'DAY': {c['PERIOD_START']: {kk: c[kk] for kk in ('N_VALUES', 'MEAN', 'SIGMA_WITHIN', 'SIGMA_OVERALL', 'CP', 'CPK', 'PP', 'PPK', 'FLAGS')}
                    for c in cap_rows if c['PERIOD_TYPE'] == 'DAY'},
            'MONTH': {c['PERIOD_START']: {kk: c[kk] for kk in ('N_VALUES', 'MEAN', 'SIGMA_WITHIN', 'SIGMA_OVERALL', 'CP', 'CPK', 'PP', 'PPK', 'IS_STABLE', 'FLAGS')}
                      for c in cap_rows if c['PERIOD_TYPE'] == 'MONTH'},
            'ROLLING_30D_LAST': next(({kk: c[kk] for kk in ('PERIOD_START', 'PERIOD_END', 'CPK', 'PPK')}
                                      for c in reversed(cap_rows) if c['PERIOD_TYPE'] == 'ROLLING_30D'), None),
            'STUDY': [{kk: c[kk] for kk in ('PERIOD_START', 'PERIOD_END', 'N_VALUES', 'MEAN', 'SIGMA_WITHIN', 'CP', 'CPK', 'PP', 'PPK', 'FLAGS')}
                      for c in cap_rows if c['PERIOD_TYPE'] == 'STUDY']}
        expected['plans'][plan['key']] = ex
        ctx.keys[plan['logical']] = plan['no']
        plan['_groups'], plan['_lim'], plan['_eff'], plan['_sig'], plan['_caps'] = groups, lim, eff_t, sig_out, cap_rows
    # 상수·규칙 정의
    consts = []
    for nn in range(2, 26):
        k = qstats.spc_constants(nn)
        consts.append({'N': nn, 'A2': rnd(k['A2'], 6), 'A3': rnd(k['A3'], 6), 'D3': rnd(k['D3'], 6), 'D4': rnd(k['D4'], 6),
                       'B3': rnd(k['B3'], 6), 'B4': rnd(k['B4'], 6), 'D2': rnd(k['D2'], 6), 'D3_CONST': rnd(k['D3_CONST'], 6),
                       'C4': rnd(k['C4'], 6), 'E2': rnd(k['E2'], 6),
                       'SOURCE_REF': 'computed: c4 감마 닫힌 식, d2·d3 정규 범위 분포 수치 적분(qstats.py)',
                       'VERIFIED_BY': None, 'VERIFIED_AT': None})
    rules = [{'RULE_CODE': c, 'WINDOW_N': w, 'HIT_M': m, 'ZONE_SIGMA': z, 'PATTERN': pat,
              'APPLIES_TO': 'BOTH' if c in ('R1', 'R2', 'R3', 'R4') else 'VARIABLE'} for c, w, m, z, pat in qstats.RULE_DEF]
    ctx.snow('CORE.SPC_MEASUREMENT', meas)
    ctx.snow('CORE.SPC_SUBGROUP', subs)
    ctx.snow('CORE.SPC_SIGNAL', sigs)
    ctx.snow('CORE.SPC_CAPABILITY', caps)
    ctx.snow('CORE.SPC_CONSTANTS', consts)
    ctx.snow('CORE.SPC_RULE_DEF', rules)
    ctx.sf('91_QMS_SpcPlan__c', plan_rows)
    ctx.sf('92_QMS_SpcLimit__c', limit_rows)
    ctx.sf('92u_QMS_SpcPlan__c', plan_upd)
    ctx.sf('93_QMS_SpcAlarm__c', alarms)
    # 첫 신호 요약(보고용)
    s7 = expected['plans']['KR01-L02-OP10-C10']
    drift_t = iso(ctx.local(ctx.d('2026-11-21'), 0, 0, 'KR01'))
    expected['method']['S7_driftSubstream'] = getattr(ctx, 's7_substream', None)
    expected['method']['S7_model'] = 'μ 3.000, σ 0.0206. 11-21 00:00~11-30 12:00(KST) 선형 상승 → 3.040 유지. 드리프트 구간은 목표 범위에 드는 첫 난수 하위열'
    expected['summary'] = {
        'S7_firstR2AfterDrift': next((s for s in s7['signals'].get('R2', []) if s['subgroupTs'] >= drift_t), None),
        'S7_firstR1AfterDrift': next((s for s in s7['signals'].get('R1', []) if s['subgroupTs'] >= drift_t), None),
        'S7_firstR2': (s7['signals'].get('R2') or [None])[0],
        'S7_firstR1': (s7['signals'].get('R1') or [None])[0]}
    write_json('expected/spc_S7.json', expected)
    ctx.spc_expected = expected
    spc_mocks(ctx)
    return expected


def spc_capability(ctx, plan, groups, lim, eff_t, sigs, lsl, usl, char):
    p = plan['plant']
    out = []
    ooc_ts = [s['SUBGROUP_TS'] for s in sigs if s['SIGNAL_TYPE'] == 'OOC']

    def sigma_w(gs):
        if plan['chart'] == 'XBAR_S':
            return qstats.mean([qstats.stdev(g[2]) for g in gs]) / qstats.c4(plan['n'])
        vals = [g[2][0] for g in gs]
        if len(vals) < 2:
            return None
        return qstats.mean([abs(vals[i] - vals[i - 1]) for i in range(1, len(vals))]) / qstats.d2(2)

    def row(ptype, start, end, gs):
        vals = [v for g in gs for v in g[2]]
        if len(vals) < 30:
            return None
        sw = sigma_w(gs)
        c = qstats.capability(vals, lsl, usl, sw)
        t0, t1 = iso(ctx.local(start, 0, 0, p)), iso(ctx.local(end, 23, 59, p) + dt.timedelta(seconds=59))
        stable = None
        if lim and gs[-1][1] >= eff_t:
            stable = not any(t0 <= ts <= t1 for ts in ooc_ts)
        np_ = qstats.anderson_darling_p(vals) if len(vals) >= 8 else None
        flags = list(c['flags'])
        if np_ is not None and np_ < 0.05:
            flags.append('NON_NORMAL')
        return {'PLAN_ID': plan['no'], 'PLAN_NO': plan['no'], 'PERIOD_TYPE': ptype, 'PERIOD_START': start.isoformat(),
                'PERIOD_END': end.isoformat(), 'N_SUBGROUPS': len(gs), 'N_VALUES': len(vals), 'MEAN': rnd(c['mean'], 8),
                'SIGMA_WITHIN': rnd(sw, 8), 'SIGMA_OVERALL': rnd(c['sigma_overall'], 8), 'CP': rnd(c['cp'], 6),
                'CPK': rnd(c['cpk'], 6), 'PP': rnd(c['pp'], 6), 'PPK': rnd(c['ppk'], 6), 'CPU': rnd(c['cpu'], 6),
                'CPL': rnd(c['cpl'], 6), 'LSL': lsl, 'USL': usl, 'TARGET_CPK': char.get('targetCpk'),
                'IS_STABLE': stable, 'NORMALITY_P': rnd(np_, 6), 'FLAGS': ','.join(flags) or None,
                'CALCULATED_AT': ctx.loaded_at}

    by_day = {}
    for g in groups:
        by_day.setdefault(g[1].date(), []).append(g)
    days = sorted(by_day)
    for d in days:
        r = row('DAY', d, d, by_day[d])
        if r:
            out.append(r)
    for i, d in enumerate(days):
        win = [x for x in days if d - dt.timedelta(days=29) <= x <= d]
        if (d - days[0]).days < 29:
            continue
        r = row('ROLLING_30D', d - dt.timedelta(days=29), d, [g for x in win for g in by_day[x]])
        if r:
            out.append(r)
    months = sorted({month_start(d) for d in days})
    for m in months:
        end = add_months(m, 1) - dt.timedelta(days=1)
        gs = [g for d in days if m <= d <= end for g in by_day[d]]
        r = row('MONTH', m, end, gs)
        if r:
            out.append(r)
    # STUDY: 최근 10일(명세 S7 "최근 10일 Cpk")
    s0, s1 = ctx.d('2026-11-21'), ctx.d('2026-11-30')
    gs = [g for d in days if s0 <= d <= s1 for g in by_day[d]]
    r = row('STUDY', s0, s1, gs)
    if r:
        out.append(r)
    return out


SEV_RANK = {'CRITICAL': 4, 'HIGH': 3, 'MEDIUM': 2, 'LOW': 1}


def ack_delay(r, sev):
    """확인까지 걸린 분. 약 7%는 기한 초과(OCAP 기한 준수율 KPI가 100%로 고정되지 않게)."""
    due = {'CRITICAL': 30, 'HIGH': 60, 'MEDIUM': 240, 'LOW': 1440}[sev]
    return int(due * (r.uniform(1.1, 1.8) if r.random() < 0.07 else r.uniform(0.15, 0.85)))
ACK_MIN = {'CRITICAL': 30, 'HIGH': 60, 'MEDIUM': 240, 'LOW': 1440}
ACT_H = {'CRITICAL': 8, 'HIGH': 24, 'MEDIUM': 72, 'LOW': 168}
OPEN_FROM = {'KR01-L02-OP10-C10': '2026-11-21', 'KR01-L01-OP20-C40': '2026-11-10', 'CN01-L01-OP60-C20': '2026-11-03'}


def severity(sig, special):
    if sig['SIGNAL_TYPE'] == 'OOS':
        return 'CRITICAL' if special in ('CC', 'SC') else 'HIGH'
    if sig['RULE_CODE'] == 'R1':
        return 'HIGH' if special in ('CC', 'SC') else 'MEDIUM'
    return 'LOW'


def spc_alarms(ctx, plan, sigs, char):
    """SPC-005 BR-1 묶음 규칙: 열린 알람에 신호를 붙이고, 조치 완료(ACTION_DONE) 이후 신호는 새 알람.
    과거 알람은 심각도별 시간 안에 원인 미발견(NO_CAUSE_FOUND)·측정 오류(FALSE_SIGNAL)로 종결.
    명세 시나리오 구간(S7 11-21, S1 11-10, S13 11-03 이후)의 첫 알람은 열린 채로 남겨 이후 신호를 모두 묶는다."""
    if not sigs:
        return []
    r = rng('alarm-' + plan['key'], ctx.seed)
    p = plan['plant']
    special = char.get('special')
    open_from = OPEN_FROM.get(plan['key'])
    open_from_ts = iso(ctx.local(ctx.d(open_from), 0, 0, p)) if open_from else None
    groups = []
    cur = None
    for s in sigs:
        ts = dt.datetime.strptime(s['SUBGROUP_TS'], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=UTC)
        if cur and (cur['keepOpen'] or ts <= cur['doneAt']):
            cur['signals'].append(s)
            continue
        keep = bool(open_from_ts and s['SUBGROUP_TS'] >= open_from_ts)
        sev = severity(s, special)
        cur = {'signals': [s], 'first': ts, 'keepOpen': keep,
               'doneAt': ts + dt.timedelta(hours={'CRITICAL': 4, 'HIGH': 6, 'MEDIUM': 12, 'LOW': 24}[sev])}
        groups.append(cur)
    rows, seq = [], {}
    for g in groups:
        sev = max((severity(s, special) for s in g['signals']), key=lambda x: SEV_RANK[x])
        first, last = g['first'], max(dt.datetime.strptime(s['SUBGROUP_TS'], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=UTC)
                                      for s in g['signals'])
        year = first.astimezone(ctx.tz[p]).year
        seq[year] = seq.get(year, 0) + 1
        sj = [{'signalId': s['SIGNAL_ID'], 'signalType': s['SIGNAL_TYPE'], 'ruleCode': s['RULE_CODE'], 'chart': s['CHART'],
               'subgroupNo': s['SUBGROUP_NO'], 'subgroupTs': s['SUBGROUP_TS'], 'value': s['VALUE'], 'limitVersion': s['LIMIT_VERSION']}
              for s in g['signals']]
        sj_text = json.dumps(sj, ensure_ascii=False, separators=(',', ':'))
        if len(sj_text) > 120000:
            ctx.notes.append(f"{plan['no']} 알람 SignalsJson {len(sj)}건이 120,000자를 넘어 앞부분만 저장")
            while len(sj_text) > 120000:
                sj = sj[:int(len(sj) * 0.9)]
                sj_text = json.dumps(sj, ensure_ascii=False, separators=(',', ':'))
        row = {'RecordNo__c': f"ALM-{p}-{year}-{seq[year]:06d}", 'SpcPlan__r.RecordNo__c': plan['no'],
               'Plant__r.PlantCode__c': p, 'Line__r.ExternalKey__c': f"{p}-{plan['line']}",
               'Operation__r.ExternalKey__c': f"{p}-{plan['line']}-{plan['op']}", 'Item__r.ItemNo__c': plan['item'],
               'Characteristic__r.ExternalKey__c': ctx.char_key(plan['item'], plan['char']), 'AlarmType__c': 'SIGNAL',
               'SignalTypes__c': ','.join(sorted({s['SIGNAL_TYPE'] for s in g['signals']})),
               'RuleCodes__c': ','.join(sorted({s['RULE_CODE'] for s in g['signals']})),
               'SignalsJson__c': sj_text, 'SignalCount__c': len(g['signals']),
               'FirstSignalAt__c': iso(first), 'LastSignalAt__c': iso(last), 'Severity__c': sev,
               'AckDueAt__c': iso(first + dt.timedelta(minutes=ACK_MIN[sev])),
               'ActionDueAt__c': iso(first + dt.timedelta(hours=ACT_H[sev])),
               'AckBy__r.EmployeeNo__c': plan['owner'], 'AckAt__c': iso(first + dt.timedelta(minutes=ack_delay(r, sev))),
               'Status__c': None, 'Outcome__c': None, 'ActionDescription__c': None, 'ProductImpact__c': None,
               'CauseCode__r.ExternalKey__c': None, 'VerifiedBy__r.EmployeeNo__c': None, 'VerifiedAt__c': None,
               'ExcludeFromLimit__c': False}
        if g['keepOpen']:
            row['Status__c'] = 'IN_PROGRESS'
            lk = {'KR01-L02-OP10-C10': 'S7-ALARM', 'KR01-L01-OP20-C40': 'S1-SPC-ALARM', 'CN01-L01-OP60-C20': 'S13-SPC-ALARM'}.get(plan['key'])
            if lk:
                ctx.keys[lk] = row['RecordNo__c']
        else:
            false_sig = r.random() < 0.1
            row['Status__c'] = 'CLOSED'
            row['Outcome__c'] = 'FALSE_SIGNAL' if false_sig else 'NO_CAUSE_FOUND'
            row['ActionDescription__c'] = ('측정기 영점 재확인, 측정 오류로 판정' if false_sig
                                           else 'OCAP 점검(금형 온도·사출 압력·측정기) 결과 이상 원인 없음, 관찰 지속')
            row['ProductImpact__c'] = 'NONE'
            if SEV_RANK[sev] >= 3:
                row['VerifiedBy__r.EmployeeNo__c'] = 'E1102' if p == 'KR01' else 'E2101'
                row['VerifiedAt__c'] = iso(g['doneAt'] + dt.timedelta(hours=1))
        rows.append(row)
    return rows


def spc_mocks(ctx):
    plan = SPC_PLANS[0]
    groups, lim, eff_t, sigs = plan['_groups'], plan['_lim'], plan['_eff'], plan['_sig']
    cols = [('subgroupNo', 'INTEGER', None), ('subgroupTs', 'DATETIME', None), ('n', 'INTEGER', None),
            ('mean', 'NUMBER', 'mm'), ('rangeVal', 'NUMBER', 'mm'), ('stddevVal', 'NUMBER', 'mm'),
            ('mrVal', 'NUMBER', 'mm'), ('pVal', 'NUMBER', None), ('uVal', 'NUMBER', None),
            ('sampleN', 'INTEGER', None), ('ucl', 'NUMBER', 'mm'), ('lcl', 'NUMBER', 'mm'),
            ('limitVersion', 'INTEGER', None), ('excluded', 'BOOLEAN', None), ('hasOos', 'BOOLEAN', None)]
    char = ctx.chars[(plan['item'], plan['char'])]

    def sg_row(g):
        vals = g[2]
        return [g[0], iso(g[1]), 5, rnd(sum(vals) / 5, 8), rnd(max(vals) - min(vals), 8), rnd(qstats.stdev(vals), 8),
                None, None, None, None, None, None, 1 if g[1] >= eff_t else None, False,
                any((char.get('usl') is not None and v > char['usl']) or (char.get('lsl') is not None and v < char['lsl']) for v in vals)]

    last = groups[-125:]
    to_ts = ctx.local(ctx.d('2026-11-30'), 23, 59, 'KR01')
    from_ts = last[0][1] - dt.timedelta(minutes=10)
    params = {'planId': 'S7-PLAN', 'planNo': plan['no'], 'fromTs': iso(from_ts), 'toTs': iso(to_ts), 'limit': 125,
              'plantCodes': ['KR01']}
    as_of = iso(groups[-1][1] + dt.timedelta(minutes=7))
    write_mock(ctx, 'QMS_SPC_SUBGROUPS', 'ok', envelope('QMS_SPC_SUBGROUPS', params, cols, [sg_row(g) for g in last], as_of=as_of))
    write_mock(ctx, 'QMS_SPC_SUBGROUPS', 'empty', envelope('QMS_SPC_SUBGROUPS', dict(params, fromTs='2025-01-01T00:00:00Z', toTs='2025-01-31T23:59:59Z'), cols, [], as_of=as_of))
    big = groups[-1000:]
    write_mock(ctx, 'QMS_SPC_SUBGROUPS', 'truncated', envelope('QMS_SPC_SUBGROUPS', dict(params, fromTs=iso(groups[0][1]), limit=1000), cols,
                                                                 [sg_row(g) for g in big], as_of=as_of, truncated=True,
                                                                 warnings=['MAX_ROWS_REACHED']))
    stale_rows = [sg_row(g) for g in groups[-145:-20]]
    write_mock(ctx, 'QMS_SPC_SUBGROUPS', 'stale', envelope('QMS_SPC_SUBGROUPS', params, cols, stale_rows,
                                                             as_of=iso(groups[-21][1] + dt.timedelta(minutes=7)), stale=True))
    write_mock(ctx, 'QMS_SPC_SUBGROUPS', 'error-timeout', envelope('QMS_SPC_SUBGROUPS', params, cols, [], as_of=None,
                                                                     error=('TIMEOUT', 'Snowflake query exceeded 8000 ms'), http=504))
    # 신호
    sig_cols = [('signalId', 'STRING', None), ('signalType', 'STRING', None), ('ruleCode', 'STRING', None),
                ('chart', 'STRING', None), ('subgroupNo', 'INTEGER', None), ('subgroupTs', 'DATETIME', None),
                ('value', 'NUMBER', 'mm'), ('limitVersion', 'INTEGER', None)]
    srows = [[s['SIGNAL_ID'], s['SIGNAL_TYPE'], s['RULE_CODE'], s['CHART'], s['SUBGROUP_NO'], s['SUBGROUP_TS'], s['VALUE'], s['LIMIT_VERSION']]
             for s in sigs if s['SUBGROUP_TS'] >= iso(from_ts)]
    write_mock(ctx, 'QMS_SPC_SIGNALS', 'ok', envelope('QMS_SPC_SIGNALS', params, sig_cols, srows, as_of=as_of))
    lim_cols = [('version', 'INTEGER', None), ('status', 'STRING', None), ('effectiveFrom', 'DATETIME', None),
                ('cl', 'NUMBER', 'mm'), ('ucl', 'NUMBER', 'mm'), ('lcl', 'NUMBER', 'mm'), ('dispCl', 'NUMBER', 'mm'),
                ('dispUcl', 'NUMBER', 'mm'), ('dispLcl', 'NUMBER', 'mm'), ('sigmaWithin', 'NUMBER', 'mm'), ('source', 'STRING', None)]
    write_mock(ctx, 'QMS_SPC_LIMITS', 'ok', envelope('QMS_SPC_LIMITS', {'planId': 'S7-PLAN', 'planNo': plan['no'], 'plantCodes': ['KR01']}, lim_cols,
                                                     [[1, 'ACTIVE', iso(eff_t), rnd(lim['cl']), rnd(lim['ucl']), rnd(lim['lcl']), rnd(lim['disp_cl']),
                                                       rnd(lim['disp_ucl']), rnd(lim['disp_lcl']), rnd(lim['sigma_within'], 8), 'CALCULATED']], as_of=as_of))
    spec_cols = [('effectiveFrom', 'DATETIME', None), ('effectiveTo', 'DATETIME', None), ('lsl', 'NUMBER', 'mm'),
                 ('usl', 'NUMBER', 'mm'), ('nominal', 'NUMBER', 'mm'), ('unit', 'STRING', None)]
    write_mock(ctx, 'QMS_SPC_SPEC', 'ok', envelope('QMS_SPC_SPEC', params, spec_cols,
                                                   [[char['from'] + 'T00:00:00Z', None, char['lsl'], char['usl'], char['nominal'], char['unit']]], as_of=as_of))
    # 히스토그램(최근 30일)
    h_from = ctx.d('2026-11-01')
    vals = [v for g in groups if g[1].date() >= h_from for v in g[2]]
    lo, hi, bins = min(vals), max(vals), 20
    w = (hi - lo) / bins
    counts = [0] * bins
    for v in vals:
        counts[min(int((v - lo) / w), bins - 1)] += 1
    mu, so = qstats.mean(vals), qstats.stdev(vals)
    hrows = [[rnd(lo + i * w, 6), rnd(lo + (i + 1) * w, 6), counts[i], rnd(mu, 8), rnd(so, 8), len(vals)] for i in range(bins)]
    write_mock(ctx, 'QMS_SPC_HISTOGRAM', 'ok', envelope('QMS_SPC_HISTOGRAM', dict(params, fromTs=iso(ctx.local(h_from, 0, 0, 'KR01')), bins=20),
                                                        [('binLow', 'NUMBER', 'mm'), ('binHigh', 'NUMBER', 'mm'), ('count', 'INTEGER', None),
                                                         ('mean', 'NUMBER', 'mm'), ('sigmaOverall', 'NUMBER', 'mm'), ('n', 'INTEGER', None)],
                                                        hrows, as_of=as_of))
    cap_cols = [('periodStart', 'DATE', None), ('periodEnd', 'DATE', None), ('n', 'INTEGER', None), ('mean', 'NUMBER', 'mm'),
                ('sigmaWithin', 'NUMBER', 'mm'), ('sigmaOverall', 'NUMBER', 'mm'), ('cp', 'NUMBER', None), ('cpk', 'NUMBER', None),
                ('pp', 'NUMBER', None), ('ppk', 'NUMBER', None), ('isStable', 'BOOLEAN', None), ('flags', 'STRING', None)]
    crow = [[c['PERIOD_START'], c['PERIOD_END'], c['N_VALUES'], c['MEAN'], c['SIGMA_WITHIN'], c['SIGMA_OVERALL'], c['CP'], c['CPK'],
             c['PP'], c['PPK'], c['IS_STABLE'], c['FLAGS']] for c in plan['_caps'] if c['PERIOD_TYPE'] == 'DAY' and c['PERIOD_START'] >= '2026-11-01']
    write_mock(ctx, 'QMS_SPC_CAPABILITY_SERIES', 'ok', envelope('QMS_SPC_CAPABILITY_SERIES',
                                                                {'planId': 'S7-PLAN', 'planNo': plan['no'], 'periodType': 'DAY', 'fromDate': '2026-11-01',
                                                                 'toDate': '2026-11-30', 'plantCodes': ['KR01']}, cap_cols, crow, as_of=as_of))
    # 공정능력 STUDY(최근 10일)
    study = [c for c in plan['_caps'] if c['PERIOD_TYPE'] == 'STUDY']
    st_cols = [('planId', 'STRING', None), ('planNo', 'STRING', None), ('characteristicId', 'STRING', None), ('charNo', 'STRING', None),
               ('specialClass', 'STRING', None), ('lineCode', 'STRING', None), ('n', 'INTEGER', None), ('mean', 'NUMBER', 'mm'),
               ('sigmaWithin', 'NUMBER', 'mm'), ('sigmaOverall', 'NUMBER', 'mm'), ('cp', 'NUMBER', None), ('cpk', 'NUMBER', None),
               ('pp', 'NUMBER', None), ('ppk', 'NUMBER', None), ('isStable', 'BOOLEAN', None), ('flags', 'STRING', None)]
    write_mock(ctx, 'QMS_SPC_CAPABILITY_STUDY', 'ok', envelope('QMS_SPC_CAPABILITY_STUDY',
                                                               {'itemId': 'S-LENS-BE1', 'fromDate': '2026-11-21', 'toDate': '2026-11-30', 'plantCodes': ['KR01']},
                                                               st_cols, [[plan['no'], plan['no'], ctx.char_key(plan['item'], plan['char']), 'C10', 'SC', 'L02',
                                                                          c['N_VALUES'], c['MEAN'], c['SIGMA_WITHIN'], c['SIGMA_OVERALL'], c['CP'], c['CPK'],
                                                                          c['PP'], c['PPK'], c['IS_STABLE'], c['FLAGS']] for c in study], mode='QUERY', as_of=as_of))
    write_mock(ctx, 'QMS_SPC_CAPABILITY_STUDY', 'empty', envelope('QMS_SPC_CAPABILITY_STUDY',
                                                                  {'itemId': '92101-HE1L', 'fromDate': '2026-11-21', 'toDate': '2026-11-30', 'plantCodes': ['KR01']},
                                                                  st_cols, [], as_of=as_of))
    # 한계 재계산 미리보기(최근 25부분군 제외 없음 — 드리프트 구간으로 미리보면 한계가 넓어짐을 보여줌)
    pv = groups[-120:]
    nl = qstats.xbar_s_limits([g[2] for g in pv])
    width_cur, width_new = lim['ucl'] - lim['lcl'], nl['ucl'] - nl['lcl']
    vals_pv = [v for g in pv for v in g[2]]
    cpk_new = qstats.capability(vals_pv, char['lsl'], char['usl'], nl['sigma_within'])['cpk']
    write_mock(ctx, 'QMS_SPC_LIMIT_PREVIEW', 'ok', envelope('QMS_SPC_LIMIT_PREVIEW',
                                                            {'planId': 'S7-PLAN', 'planNo': plan['no'], 'fromTs': iso(pv[0][3][0]), 'toTs': iso(pv[-1][1]),
                                                             'excludedSubgroups': '[]', 'plantCodes': ['KR01']},
                                                            [('cl', 'NUMBER', 'mm'), ('ucl', 'NUMBER', 'mm'), ('lcl', 'NUMBER', 'mm'), ('dispCl', 'NUMBER', 'mm'),
                                                             ('dispUcl', 'NUMBER', 'mm'), ('dispLcl', 'NUMBER', 'mm'), ('sigmaWithin', 'NUMBER', 'mm'),
                                                             ('subgroupCount', 'INTEGER', None), ('currentCl', 'NUMBER', 'mm'), ('currentUcl', 'NUMBER', 'mm'),
                                                             ('currentLcl', 'NUMBER', 'mm'), ('widthChangePct', 'NUMBER', '%'), ('cpkNew', 'NUMBER', None)],
                                                            [[rnd(nl['cl']), rnd(nl['ucl']), rnd(nl['lcl']), rnd(nl['disp_cl']), rnd(nl['disp_ucl']),
                                                              rnd(nl['disp_lcl']), rnd(nl['sigma_within'], 8), len(pv), rnd(lim['cl']), rnd(lim['ucl']),
                                                              rnd(lim['lcl']), rnd(100 * (width_new - width_cur) / width_cur, 4), rnd(cpk_new, 6)]], as_of=as_of))
    # 계획 요약(KR01) — SPC-006 BR-10 열 15개
    sum_cols = [('planId', 'STRING', None), ('planNo', 'STRING', None), ('itemNo', 'STRING', None), ('charNo', 'STRING', None),
                ('charName', 'STRING', None), ('specialClass', 'STRING', None), ('lineCode', 'STRING', None), ('opCode', 'STRING', None),
                ('chartType', 'STRING', None), ('cpk', 'NUMBER', None), ('ppk', 'NUMBER', None), ('targetCpk', 'NUMBER', None),
                ('rag', 'STRING', None), ('openAlarms', 'INTEGER', None), ('dataGap', 'BOOLEAN', None), ('lastMeasuredAt', 'DATETIME', None)]
    srows = []
    for pl in SPC_PLANS:
        if pl['plant'] != 'KR01':
            continue
        ch = ctx.chars[(pl['item'], pl['char'])]
        roll = next((c for c in reversed(pl.get('_caps') or []) if c['PERIOD_TYPE'] == 'ROLLING_30D'), None)
        cpk = roll['CPK'] if roll else None
        tgt = ch.get('targetCpk') or 1.33
        rag = 'NONE' if cpk is None else ('GREEN' if cpk >= tgt else ('AMBER' if cpk >= 1.0 else 'RED'))
        open_alarms = sum(1 for a in pl.get('_alarms_cache', []) if a)
        srows.append([pl['no'], pl['no'], pl['item'], pl['char'], ch['name'], ch.get('special'), pl['line'], pl['op'], pl['chart'],
                      cpk, roll['PPK'] if roll else None, tgt, rag, None, pl['schedule'] is None,
                      iso(pl['_groups'][-1][3][-1]) if pl.get('_groups') else None])
    order = {'RED': 0, 'AMBER': 1, 'GREEN': 2, 'NONE': 3}
    srows.sort(key=lambda x: (order[x[12]], x[9] if x[9] is not None else 99))
    ctx.spc_summary_rows = srows
    ctx.spc_summary_cols = sum_cols
    ctx.spc_summary_asof = as_of


def spc_summary_mock(ctx, alarms):
    open_by_plan = {}
    for a in alarms:
        if a['Status__c'] in ('NEW', 'IN_PROGRESS'):
            open_by_plan[a['SpcPlan__r.RecordNo__c']] = open_by_plan.get(a['SpcPlan__r.RecordNo__c'], 0) + 1
    rows = [r[:13] + [open_by_plan.get(r[1], 0)] + r[14:] for r in ctx.spc_summary_rows]
    write_mock(ctx, 'QMS_SPC_PLAN_SUMMARY', 'ok', envelope('QMS_SPC_PLAN_SUMMARY', {'plantCode': 'KR01', 'plantCodes': ['KR01']},
                                                           ctx.spc_summary_cols, rows, as_of=ctx.spc_summary_asof))


# ============================================================== MSA

def grr_data(r, true_parts, offsets, sigma_e, trials, res, inter_sd=0.0):
    data = {}
    inter = {(i, j): r.gauss(0, inter_sd) for i in range(len(true_parts)) for j in range(len(offsets))}
    for i, tv in enumerate(true_parts):
        for j, off in enumerate(offsets):
            for t in range(trials):
                data[(i + 1, 'ABC'[j], t + 1)] = quantize(tv + off + inter[(i, j)] + r.gauss(0, sigma_e), res)
    return data


def pick_study(name, seed, builder, target_lo, target_hi, tol, metric='pctGrrStudyVar'):
    """명세 목표 범위에 드는 첫 난수 하위열을 고른다(결정적)."""
    for k in range(200):
        r = rng(f'{name}-{k}', seed)
        data = builder(r)
        g = qstats.grr_anova(data, tolerance=tol, alpha=0.25)
        if target_lo <= g[metric] <= target_hi:
            return data, g, k
    raise RuntimeError(f'{name}: 목표 범위 데이터 생성 실패')


def gen_msa(ctx):
    exp = {'criteria': {'GRR_BASIS': 'WORST', 'GRR_OK_MAX': 10, 'GRR_COND_MAX': 30, 'NDC_MIN': 5, 'STUDY_VAR_MULTIPLIER': 6,
                        'ANOVA_INTERACTION_ALPHA': 0.25,
                        'ATTRIBUTE(데모 임시)': {'KAPPA_OK_MIN': 0.75, 'EFFECTIVENESS_OK_MIN': 80, 'MISS_RATE_MAX': 5, 'FALSE_ALARM_MAX': 12.5}},
           'engineVersion': ENGINE_VERSION, 'studies': {}}
    meas_rows, study_rows, appr_rows, res_rows, mocks = [], [], [], [], {}
    # MSA1: 마이크로미터 × 렌즈 두께
    parts1 = [2.962, 2.971, 2.980, 2.989, 2.996, 3.004, 3.011, 3.019, 3.028, 3.040]
    d1, g1, k1 = pick_study('msa1', ctx.seed, lambda r: grr_data(r, parts1, [-0.0012, 0.0, 0.0015], 0.0026, 3, 0.001),
                            11.5, 12.5, 0.20)
    # MSA2: 에이밍 테스터 × 조준각
    parts2 = [-0.14, -0.11, -0.07, -0.04, -0.01, 0.02, 0.05, 0.08, 0.11, 0.14]
    d2, g2, k2 = pick_study('msa2', ctx.seed, lambda r: grr_data(r, parts2, [-0.003, 0.0, 0.003], 0.004, 2, 0.01),
                            5.5, 6.5, 0.40)
    studies = [
        {'key': 'S8-MSA1', 'no': 'MSA-KR01-2026-00007', 'type': 'GRR_ANOVA', 'gauge': 'GA-KR01-0123', 'item': 'S-LENS-BE1',
         'char': 'C10', 'tol': 0.20, 'parts': 10, 'apprs': ['E1102', 'E1103', 'E1105'], 'trials': 3, 'data': d1, 'g': g1,
         'from': '2026-10-14', 'approved': '2026-10-20', 'unit': 'mm'},
        {'key': 'S8-MSA2', 'no': 'MSA-KR01-2026-00008', 'type': 'GRR_ANOVA', 'gauge': 'GA-KR01-0201', 'item': '63117-BE1L',
         'char': 'C20', 'tol': 0.40, 'parts': 10, 'apprs': ['E1102', 'E1103', 'E1105'], 'trials': 2, 'data': d2, 'g': g2,
         'from': '2026-09-22', 'approved': '2026-09-25', 'unit': 'deg'},
    ]
    for s in studies:
        g = s['g']
        verdict, basis_val, reason = qstats.msa_verdict(g['pctGrrTolerance'], g['pctGrrStudyVar'], g['ndc'])
        xr = qstats.grr_xbar_r(s['data'], tolerance=s['tol'])
        rng_ooc = grr_range_ooc(s['data'])
        chart = grr_chart_data(s['data'], g)
        result = {'engineVersion': ENGINE_VERSION, 'studyId': s['no'], 'studyNo': s['no'], 'studyType': s['type'], 'calcSeq': 1,
                  'status': 'OK', 'errorCode': None,
                  'metrics': {'ev': g['EV'], 'av': g['AV'],
                              'interaction': math.sqrt(next(c['variance'] for c in g['components'] if c['source'] == 'PART_X_APPRAISER')),
                              'grr': g['GRR'], 'pv': g['PV'], 'tv': g['TV'], 'pctGrrStudyVar': g['pctGrrStudyVar'],
                              'pctGrrTolerance': g['pctGrrTolerance'], 'pctGrrProcess': None, 'ndc': g['ndc'],
                              'interactionPValue': g['interactionPValue'], 'interactionPooled': g['interactionPooled'],
                              'rangeOutOfControlCount': rng_ooc},
                  'verdict': {'value': verdict, 'basis': 'WORST', 'reason': reason},
                  'anovaTable': g['anovaUsed'], 'anovaTableFull': g['anovaFull'],
                  'varianceComponents': [{'source': c['source'], 'variance': c['variance'], 'pctContribution': c['pctContribution'],
                                          'stdDev': c['sd'], 'studyVar': c['studyVar'], 'pctStudyVar': c['pctStudyVar'],
                                          'pctTolerance': c['pctTolerance']} for c in g['components']],
                  'chartData': chart, 'warnings': resolution_warnings(s), 'xbarRCrossCheck': xr}
        exp['studies'][s['key']] = {k: result[k] for k in ('studyNo', 'studyType', 'metrics', 'verdict', 'anovaTable', 'anovaTableFull',
                                                           'varianceComponents', 'warnings', 'xbarRCrossCheck')}
        exp['studies'][s['key']]['seedSubstream'] = k1 if s['key'] == 'S8-MSA1' else k2
        ctx.keys[s['key']] = s['no']
        ctx.msa_verdicts.append((ctx.d(s['approved']), verdict))
        mocks[s['key']] = result
        mj = [{'part': p, 'appraiser': a, 'trial': t, 'value': v} for (p, a, t), v in sorted(s['data'].items())]
        study_rows.append(msa_study_row(ctx, s, mj, result, verdict, reason))
        for j, emp in enumerate(s['apprs']):
            appr_rows.append({'ExternalKey__c': f"{s['no']}-{'ABC'[j]}", 'Study__r.RecordNo__c': s['no'],
                              'Employee__r.EmployeeNo__c': emp, 'Label__c': 'ABC'[j], 'QualifiedAtStart__c': True})
        for (p, a, t), v in sorted(s['data'].items()):
            meas_rows.append({'STUDY_ID': s['no'], 'STUDY_NO': s['no'], 'CALC_SEQ': 1, 'STUDY_TYPE': s['type'], 'PLANT_CODE': 'KR01',
                              'GAUGE_NO': s['gauge'], 'ITEM_NO': s['item'], 'CHAR_NO': s['char'], 'PART': p, 'APPRAISER': a,
                              'APPRAISER_EMP_NO': s['apprs']['ABC'.index(a)], 'TRIAL': t, 'VALUE': v, 'RESULT': None,
                              'REFERENCE': None, 'MEASURED_AT': iso(ctx.local(ctx.d(s['from']), 9 + t, 0, 'KR01')),
                              '_LOADED_AT': ctx.loaded_at})
        res_rows.append({'STUDY_ID': s['no'], 'STUDY_NO': s['no'], 'CALC_SEQ': 1,
                         'CALC_AT': iso(ctx.local(ctx.d(s['from']), 16, 0, 'KR01')), 'ENGINE_VERSION': ENGINE_VERSION,
                         'RESULT': json.dumps(result, ensure_ascii=False, separators=(',', ':'))})
    # MSA3: 계수형
    a3 = attribute_study(ctx)
    ctx.keys['S8-MSA3'] = a3['expected']['studyNo']
    ctx.msa_verdicts.append((ctx.d('2026-10-30'), a3['result']['verdict']['value']))
    exp['studies']['S8-MSA3'] = a3['expected']
    mocks['S8-MSA3'] = a3['result']
    study_rows.append(a3['study_row'])
    appr_rows.extend(a3['appr_rows'])
    meas_rows.extend(a3['meas_rows'])
    res_rows.append(a3['res_row'])
    # 상수(평균범위법 K) — 검수 전 상태
    const = []
    for t in (2, 3):
        const.append({'CONSTANT_NAME': 'K1', 'TRIALS': t, 'APPRAISERS': None, 'PARTS': None, 'VALUE': rnd(1 / qstats.d2(t), 6),
                      'SOURCE_REF': 'computed: 1/d2(trials), qstats.py', 'VERIFIED_BY': None, 'VERIFIED_AT': None})
    for o in (2, 3):
        const.append({'CONSTANT_NAME': 'K2', 'TRIALS': None, 'APPRAISERS': o, 'PARTS': None, 'VALUE': rnd(1 / qstats.d2_star(o, 1), 6),
                      'SOURCE_REF': 'computed: 1/d2*(appraisers, g=1), Patnaik √(d2²+d3²/g)', 'VERIFIED_BY': None, 'VERIFIED_AT': None})
    for n in range(2, 16):
        const.append({'CONSTANT_NAME': 'K3', 'TRIALS': None, 'APPRAISERS': None, 'PARTS': n, 'VALUE': rnd(1 / qstats.d2_star(n, 1), 6),
                      'SOURCE_REF': 'computed: 1/d2*(parts, g=1), Patnaik √(d2²+d3²/g)', 'VERIFIED_BY': None, 'VERIFIED_AT': None})
    ctx.snow('CORE.MSA_MEASUREMENT', meas_rows)
    ctx.snow('ML.MSA_RESULT', res_rows)
    ctx.snow('ML.MSA_CONSTANT', const)
    ctx.sf('94_QMS_MsaStudy__c', study_rows)
    ctx.sf('95_QMS_MsaAppraiser__c', appr_rows)
    write_json('expected/msa_S8.json', exp)
    ctx.msa_expected = exp
    # 목
    for key, case in (('S8-MSA1', 'ok-msa1'), ('S8-MSA2', 'ok-msa2'), ('S8-MSA3', 'ok-msa3')):
        res = mocks[key]
        write_mock(ctx, 'QMS_MSA_CALC', case, envelope('QMS_MSA_CALC', {'studyId': key, 'studyNo': res['studyNo'], 'studyType': res['studyType']},
                                                       [], [], mode='PROCEDURE', as_of=None, result=res, calc_version=ENGINE_VERSION, scope=None))
    write_mock(ctx, 'QMS_MSA_CALC', 'error-timeout', envelope('QMS_MSA_CALC', {'studyId': 'S8-MSA1'}, [], [], mode='PROCEDURE',
                                                               error=('TIMEOUT', 'Procedure exceeded 55000 ms'), http=504, scope=None))
    write_mock(ctx, 'QMS_MSA_CALC', 'failed-constant', envelope('QMS_MSA_CALC', {'studyId': 'S8-MSA1', 'studyType': 'GRR_XBAR_R'}, [], [],
                                                                 mode='PROCEDURE', calc_version=ENGINE_VERSION, scope=None,
                                                                 result={'engineVersion': ENGINE_VERSION, 'studyId': 'S8-MSA1', 'studyType': 'GRR_XBAR_R',
                                                                         'calcSeq': 2, 'status': 'FAILED', 'errorCode': 'CONSTANT_NOT_VERIFIED',
                                                                         'metrics': None, 'verdict': None, 'warnings': ['K3(PARTS=10) VERIFIED_BY 공란']}))
    comp = [c for c in mocks['S8-MSA1']['varianceComponents'] if c['source'] in ('TOTAL_GRR', 'REPEATABILITY', 'REPRODUCIBILITY', 'PART_TO_PART')]
    png = bar_chart_png([[c['pctContribution'], c['pctStudyVar'], c['pctTolerance'] or 0] for c in comp])
    write_mock(ctx, 'QMS_MSA_CHART', 'ok-components', envelope(
        'QMS_MSA_CHART', {'studyId': 'S8-MSA1', 'studyNo': 'MSA-KR01-2026-00007', 'calcSeq': 1, 'chartType': 'COMPONENTS'}, [], [], mode='PROCEDURE',
        calc_version=ENGINE_VERSION, scope=None,
        result={'engineVersion': ENGINE_VERSION, 'studyId': 'MSA-KR01-2026-00007', 'calcSeq': 1, 'chartType': 'COMPONENTS', 'status': 'OK',
                'mimeType': 'image/png', 'width': 480, 'height': 240, 'imageBase64': base64.b64encode(png).decode('ascii'),
                'series': ['pctContribution', 'pctStudyVar', 'pctTolerance'], 'categories': [c['source'] for c in comp]}))
    # SPC 화면 MSA 배지
    badge_cols = [('studyNo', 'STRING', None), ('studyType', 'STRING', None), ('gaugeNo', 'STRING', None), ('verdict', 'STRING', None),
                  ('pctGrrStudyVar', 'NUMBER', '%'), ('pctGrrTolerance', 'NUMBER', '%'), ('ndc', 'INTEGER', None), ('approvedDate', 'DATE', None)]
    s1 = studies[0]
    write_mock(ctx, 'QMS_SPC_MSA_STATUS', 'ok', envelope('QMS_SPC_MSA_STATUS', {'characteristicId': ctx.char_key('S-LENS-BE1', 'C10'), 'plantCode': 'KR01', 'plantCodes': ['KR01']},
                                                         badge_cols, [[s1['no'], 'GRR_ANOVA', s1['gauge'], exp['studies']['S8-MSA1']['verdict']['value'],
                                                                       rnd(g1['pctGrrStudyVar'], 4), rnd(g1['pctGrrTolerance'], 4), g1['ndc'],
                                                                       ctx.d(s1['approved']).isoformat()]],
                                                         as_of=ctx.loaded_at))
    write_mock(ctx, 'QMS_SPC_MSA_STATUS', 'empty', envelope('QMS_SPC_MSA_STATUS', {'characteristicId': ctx.char_key('92101-KC1L', 'C20'), 'plantCode': 'CN01', 'plantCodes': ['CN01']},
                                                            badge_cols, [], as_of=ctx.loaded_at, scope='CN01'))
    return exp


def bar_chart_png(groups, width=480, height=240):
    """분산 성분 막대(그룹별 3계열) PNG. 글자 없이 막대만 그리는 목 이미지(표준 라이브러리 zlib)."""
    colors = [(70, 110, 170), (230, 150, 60), (120, 170, 90)]
    px = [[(255, 255, 255)] * width for _ in range(height)]
    base_y, top = height - 20, 15
    for x in range(20, width - 10):
        px[base_y][x] = (90, 90, 90)
    slot = (width - 40) // len(groups)
    bw = slot // 5
    for gi, vals in enumerate(groups):
        for si, v in enumerate(vals):
            h = int(max(0.0, min(v, 100.0)) / 100.0 * (base_y - top))
            x0 = 20 + gi * slot + bw // 2 + si * bw
            for y in range(base_y - h, base_y):
                for x in range(x0, x0 + bw - 2):
                    px[y][x] = colors[si]
    raw = b''.join(b'\x00' + bytes(c for p in row for c in p) for row in px)

    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


def grr_range_ooc(data):
    parts = sorted({k[0] for k in data})
    apprs = sorted({k[1] for k in data})
    trials = sorted({k[2] for k in data})
    ranges = [max(data[(p, a, t)] for t in trials) - min(data[(p, a, t)] for t in trials) for a in apprs for p in parts]
    ucl = qstats.spc_constants(len(trials))['D4'] * qstats.mean(ranges)
    return sum(1 for x in ranges if x > ucl)


def grr_chart_data(data, g):
    parts = sorted({k[0] for k in data})
    apprs = sorted({k[1] for k in data})
    trials = sorted({k[2] for k in data})
    return {
        'components': [{'source': c['source'], 'pctContribution': c['pctContribution'], 'pctStudyVar': c['pctStudyVar'],
                        'pctTolerance': c['pctTolerance']} for c in g['components'] if c['source'] in ('TOTAL_GRR', 'REPEATABILITY', 'REPRODUCIBILITY', 'PART_TO_PART')],
        'rByAppraiser': [{'appraiser': a, 'part': p, 'range': max(data[(p, a, t)] for t in trials) - min(data[(p, a, t)] for t in trials)}
                         for a in apprs for p in parts],
        'xbarByAppraiser': [{'appraiser': a, 'part': p, 'mean': qstats.mean([data[(p, a, t)] for t in trials])} for a in apprs for p in parts],
        'interaction': [{'part': p, 'appraiser': a, 'mean': qstats.mean([data[(p, a, t)] for t in trials])} for p in parts for a in apprs]}


def resolution_warnings(s):
    w = []
    res = {'GA-KR01-0123': 0.001, 'GA-KR01-0201': 0.01}.get(s['gauge'])
    if res and res > s['tol'] / 10:
        w.append('RESOLUTION_LOW')
    data = s['data']
    parts = sorted({k[0] for k in data})
    apprs = sorted({k[1] for k in data})
    trials = sorted({k[2] for k in data})
    same = sum(1 for p in parts for a in apprs if len({data[(p, a, t)] for t in trials}) == 1)
    if same / (len(parts) * len(apprs)) > 0.5:
        w.append('REPEAT_IDENTICAL_OVER_50PCT')
    return w


def msa_study_row(ctx, s, mj, result, verdict, reason):
    m = result['metrics']
    return {'RecordNo__c': s['no'], 'Name': f"{s['item']} {s['char']} {s['gauge']} GRR", 'StudyType__c': s['type'],
            'Trigger__c': 'PERIODIC', 'Plant__r.PlantCode__c': 'KR01', 'Gauge__r.GaugeNo__c': s['gauge'],
            'Characteristic__r.ExternalKey__c': ctx.char_key(s['item'], s['char']), 'Tolerance__c': s['tol'],
            'ProcessSigma__c': None, 'ProcessSigmaSource__c': 'NONE', 'PartCount__c': s['parts'],
            'AppraiserCount__c': len(s['apprs']), 'TrialCount__c': s['trials'], 'ReferenceValuesJson__c': None,
            'MeasurementJson__c': json.dumps(mj, separators=(',', ':')), 'PerformedFrom__c': ctx.d(s['from']).isoformat(),
            'PerformedTo__c': ctx.d(s['from']).isoformat(),
            'Status__c': 'APPROVED', 'CalcStatus__c': 'DONE', 'CalculatedAt__c': iso(ctx.local(ctx.d(s['from']), 16, 0, 'KR01')),
            'CalcEngineVersion__c': ENGINE_VERSION, 'Method__c': 'ANOVA', 'EV__c': rnd(m['ev'], 8), 'AV__c': rnd(m['av'], 8),
            'Interaction__c': rnd(m['interaction'], 8), 'GRR__c': rnd(m['grr'], 8), 'PV__c': rnd(m['pv'], 8), 'TV__c': rnd(m['tv'], 8),
            'PctGrrStudyVar__c': rnd(m['pctGrrStudyVar'], 2), 'PctGrrTolerance__c': rnd(m['pctGrrTolerance'], 2),
            'PctGrrProcess__c': None, 'Ndc__c': m['ndc'], 'InteractionPValue__c': rnd(m['interactionPValue'], 6),
            'InteractionPooled__c': m['interactionPooled'], 'RangeOutOfControlCount__c': m['rangeOutOfControlCount'],
            'Verdict__c': verdict, 'VerdictBasis__c': 'WORST', 'VerdictReason__c': reason,
            'ResultJson__c': json.dumps({k: result[k] for k in ('anovaTable', 'varianceComponents', 'chartData')},
                                        ensure_ascii=False, separators=(',', ':')),
            'KappaWithinMin__c': None, 'KappaBetween__c': None, 'KappaVsStandardMin__c': None, 'EffectivenessPct__c': None,
            'MissRatePct__c': None, 'FalseAlarmPct__c': None, 'AppraiserResultsJson__c': None}


def attribute_study(ctx):
    """S8-MSA3: 30부품(기준 OK 20, NG 10) × 평가자 3 × 반복 2. 평가자별 오류(미검출·오검출)를 정해 kappa 약 0.82."""
    no = 'MSA-KR01-2026-00009'
    ref = ['NG' if p in (3, 7, 11, 14, 18, 21, 24, 26, 28, 30) else 'OK' for p in range(1, 31)]
    border = {5: 'OK', 9: 'OK', 16: 'OK', 22: 'OK', 27: 'OK'}  # 경계 부품(기준 OK, 오검출 위치)
    errors = {'A': [(5, 1, 'NG'), (9, 2, 'NG'), (16, 1, 'NG'), (14, 2, 'OK')],
              'B': [(5, 2, 'NG'), (9, 1, 'NG'), (22, 1, 'NG'), (27, 2, 'NG'), (24, 1, 'OK')],
              'C': [(5, 1, 'NG'), (5, 2, 'NG'), (16, 2, 'NG'), (22, 2, 'NG'), (27, 1, 'NG')]}
    emps = {'A': 'E1104', 'B': 'E1105', 'C': 'E1114'}
    res = {}
    for a in 'ABC':
        for p in range(1, 31):
            for t in (1, 2):
                res[(p, a, t)] = ref[p - 1]
        for p, t, v in errors[a]:
            res[(p, a, t)] = v
    per = {}
    for a in 'ABC':
        mine = [res[(p, a, t)] for p in range(1, 31) for t in (1, 2)]
        refs = [ref[p - 1] for p in range(1, 31) for t in (1, 2)]
        within = [[res[(p, a, 1)], res[(p, a, 2)]] for p in range(1, 31)]
        eff = sum(1 for p in range(1, 31) if res[(p, a, 1)] == res[(p, a, 2)] == ref[p - 1]) / 30 * 100
        miss = sum(1 for p in range(1, 31) for t in (1, 2) if ref[p - 1] == 'NG' and res[(p, a, t)] == 'OK') / 20 * 100
        fa = sum(1 for p in range(1, 31) for t in (1, 2) if ref[p - 1] == 'OK' and res[(p, a, t)] == 'NG') / 40 * 100
        k_std = qstats.cohen_kappa(mine, refs)
        k_within = qstats.fleiss_kappa(within)
        ok = k_std >= 0.75 and eff >= 80 and miss <= 5 and fa <= 12.5
        per[a] = {'appraiser': a, 'employeeNo': emps[a], 'kappaVsStandard': k_std, 'kappaWithin': k_within,
                  'effectivenessPct': eff, 'missRatePct': miss, 'falseAlarmPct': fa, 'verdict': 'ACCEPTABLE' if ok else 'CONDITIONAL'}
    between = qstats.fleiss_kappa([[res[(p, a, 1)] for a in 'ABC'] for p in range(1, 31)])
    # 판정은 평가자별 기준이므로 연구 지표도 평가자별 최악값(유효성 최소, 미검출·오검출 최대). 전원 일치 유효성은 별도 키
    sys_eff = sum(1 for p in range(1, 31) if all(res[(p, a, t)] == ref[p - 1] for a in 'ABC' for t in (1, 2))) / 30 * 100
    eff_all = min(per[a]['effectivenessPct'] for a in 'ABC')
    miss_all = max(per[a]['missRatePct'] for a in 'ABC')
    fa_all = max(per[a]['falseAlarmPct'] for a in 'ABC')
    kmin = min(per[a]['kappaVsStandard'] for a in 'ABC')
    verdict = 'ACCEPTABLE' if all(per[a]['verdict'] == 'ACCEPTABLE' for a in 'ABC') else 'CONDITIONAL'
    metrics = {'kappaWithinMin': min(per[a]['kappaWithin'] for a in 'ABC'), 'kappaBetween': between, 'kappaVsStandardMin': kmin,
               'effectivenessPct': eff_all, 'missRatePct': miss_all, 'falseAlarmPct': fa_all, 'systemEffectivenessPct': sys_eff,
               'metricBasis': 'APPRAISER_WORST'}
    result = {'engineVersion': ENGINE_VERSION, 'studyId': no, 'studyNo': no, 'studyType': 'ATTRIBUTE', 'calcSeq': 1, 'status': 'OK',
              'errorCode': None, 'metrics': metrics,
              'verdict': {'value': verdict, 'basis': 'ATTRIBUTE', 'reason': f'평가자 대 기준 kappa 최소 {kmin:.3f} ≥ 0.75(데모 임시 기준)'},
              'appraiserResults': list(per.values()), 'warnings': []}
    mj = [{'part': p, 'appraiser': a, 'trial': t, 'result': res[(p, a, t)]} for p in range(1, 31) for a in 'ABC' for t in (1, 2)]
    row = {'RecordNo__c': no, 'Name': 'S-LENS-BE1 C40 외관 긁힘 계수형', 'StudyType__c': 'ATTRIBUTE', 'Trigger__c': 'PERIODIC',
           'Plant__r.PlantCode__c': 'KR01', 'Gauge__r.GaugeNo__c': None,
           'Characteristic__r.ExternalKey__c': ctx.char_key('S-LENS-BE1', 'C40'), 'Tolerance__c': None, 'ProcessSigma__c': None,
           'ProcessSigmaSource__c': 'NONE', 'PartCount__c': 30, 'AppraiserCount__c': 3, 'TrialCount__c': 2,
           'ReferenceValuesJson__c': json.dumps([{'part': p, 'reference': ref[p - 1]} for p in range(1, 31)], separators=(',', ':')),
           'MeasurementJson__c': json.dumps(mj, separators=(',', ':')), 'PerformedFrom__c': ctx.d('2026-10-28').isoformat(),
           'PerformedTo__c': ctx.d('2026-10-28').isoformat(),
           'Status__c': 'APPROVED', 'CalcStatus__c': 'DONE', 'CalculatedAt__c': iso(ctx.local(ctx.d('2026-10-28'), 16, 0, 'KR01')),
           'CalcEngineVersion__c': ENGINE_VERSION, 'Method__c': None, 'EV__c': None, 'AV__c': None, 'Interaction__c': None,
           'GRR__c': None, 'PV__c': None, 'TV__c': None, 'PctGrrStudyVar__c': None, 'PctGrrTolerance__c': None,
           'PctGrrProcess__c': None, 'Ndc__c': None, 'InteractionPValue__c': None, 'InteractionPooled__c': None,
           'RangeOutOfControlCount__c': None, 'Verdict__c': verdict, 'VerdictBasis__c': 'ATTRIBUTE',
           'VerdictReason__c': result['verdict']['reason'], 'ResultJson__c': json.dumps({'appraiserResults': list(per.values())}, ensure_ascii=False),
           'KappaWithinMin__c': rnd(metrics['kappaWithinMin'], 4), 'KappaBetween__c': rnd(between, 4),
           'KappaVsStandardMin__c': rnd(kmin, 4), 'EffectivenessPct__c': rnd(eff_all, 2), 'MissRatePct__c': rnd(miss_all, 2),
           'FalseAlarmPct__c': rnd(fa_all, 2), 'AppraiserResultsJson__c': json.dumps(list(per.values()), ensure_ascii=False)}
    meas = [{'STUDY_ID': no, 'STUDY_NO': no, 'CALC_SEQ': 1, 'STUDY_TYPE': 'ATTRIBUTE', 'PLANT_CODE': 'KR01', 'GAUGE_NO': None,
             'ITEM_NO': 'S-LENS-BE1', 'CHAR_NO': 'C40', 'PART': p, 'APPRAISER': a, 'APPRAISER_EMP_NO': emps[a], 'TRIAL': t,
             'VALUE': None, 'RESULT': res[(p, a, t)], 'REFERENCE': ref[p - 1],
             'MEASURED_AT': iso(ctx.local(ctx.d('2026-10-28'), 9 + t, 0, 'KR01')), '_LOADED_AT': ctx.loaded_at}
            for p in range(1, 31) for a in 'ABC' for t in (1, 2)]
    return {'expected': {'studyNo': no, 'studyType': 'ATTRIBUTE', 'metrics': metrics, 'verdict': result['verdict'],
                         'appraiserResults': list(per.values()), 'designedErrors': errors,
                         'note': 'kappa 기준 0.75 이상은 AIAG 지침 범위, 유효성·미검출·오검출 기준은 데모 임시값(설정 QMS_MsaCriteria__mdt)'},
            'result': result, 'study_row': row,
            'appr_rows': [{'ExternalKey__c': f'{no}-{a}', 'Study__r.RecordNo__c': no, 'Employee__r.EmployeeNo__c': emps[a],
                           'Label__c': a, 'QualifiedAtStart__c': True} for a in 'ABC'],
            'meas_rows': meas,
            'res_row': {'STUDY_ID': no, 'STUDY_NO': no, 'CALC_SEQ': 1, 'CALC_AT': iso(ctx.local(ctx.d('2026-10-28'), 16, 0, 'KR01')),
                        'ENGINE_VERSION': ENGINE_VERSION, 'RESULT': json.dumps(result, ensure_ascii=False, separators=(',', ':'))}}


# ============================================================== MES·EOL

PROD = [  # plant, line, item, 일 투입, 근무 요일 수(6 = 월~토, 7 = 매일)
    ('KR01', 'L01', '63117-BE1L', 420, 6), ('KR01', 'L01', '63117-BE1R', 420, 6),
    ('KR01', 'L05', '92101-HE1L', 380, 6), ('KR01', 'L05', '92102-HE1R', 380, 6),
    ('KR01', 'L05', '92101-HE2L', 260, 6), ('KR01', 'L05', '92101-KE1L', 300, 6),
    ('KR01', 'L02', 'S-LENS-BE1', 900, 7), ('KR02', 'L01', '92401-HE1L', 500, 6),
    ('CN01', 'L01', '92101-KC1L', 150, 6), ('US01', 'L01', '84001-GE1L', 260, 6),
    ('US01', 'L01', '84101-FE1L', 240, 6), ('PL01', 'L01', '63117-BE1L', 200, 6),
    ('PL01', 'L01', '63117-BE1R', 200, 6), ('PL01', 'L01', '98140-SE1L', 280, 6),
]

# 불량 기준율(ppm of input): (MES 코드, DEFECT_TYPE 경로, 공정, 특성 번호)
DEFECTS = {
    'INNER_FOG': ('MF-FOG', 'DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG', 'OP60', 'C50'),
    'DRL_FLICKER': ('MF-DRL', 'DEFECT_TYPE/FUNCTION/LIGHTING/DRL_FLICKER', 'OP60', 'C60'),
    'FLATNESS': ('MF-FLT', 'DEFECT_TYPE/DIMENSION/POSITION/FLATNESS', 'OP10', None),
    'LEAK_RATE': ('MF-LEK', 'DEFECT_TYPE/SEALING/LEAK/LEAK_RATE', 'OP40', 'C30'),
    'LENS_SCRATCH': ('MF-SCR', 'DEFECT_TYPE/APPEARANCE/SCRATCH/LENS_SCRATCH', 'OP60', None),
    'AIM_OUT': ('MF-AIM', 'DEFECT_TYPE/OPTICAL/AIMING/AIM_OUT', 'OP60', 'C20'),
    'INNER_FOREIGN': ('MF-FOR', 'DEFECT_TYPE/APPEARANCE/FOREIGN/INNER_FOREIGN', 'OP60', None),
    'LENS_HAZE': ('MF-HAZ', 'DEFECT_TYPE/APPEARANCE/HAZE/LENS_HAZE', 'OP10', None),
    'LED_OFF': ('MF-LED', 'DEFECT_TYPE/FUNCTION/LIGHTING/LED_OFF', 'OP60', None),
    'PIN_BENT': ('MF-PIN', 'DEFECT_TYPE/ELECTRICAL/CONNECTOR/PIN_BENT', 'OP60', None),
    'LENS_THICKNESS': ('MF-THK', 'DEFECT_TYPE/DIMENSION/THICKNESS/LENS_THICKNESS', 'OP10', 'C10'),
}


MES_RATE_SCALE = 8  # 아래 상대 비율 × 8 = 공정 불량 ppm(조립 라인 합계 약 0.4%)


def defect_rates(ctx, plant, line, item, day):
    """일별 공정 불량률(ppm). 시나리오: S1 결로(KR01 L01 BE1 11-10~), S2 DRL(KR01 L05 HE1 7~10월), S9 평면도(KR01 L01 BE1 10~11월),
    S13 조준(CN01 11-03~, EOL 1차 불합격률과 같은 3.3%), S7 두께(KR01 L02 11-21~)."""
    rates = {k: v * MES_RATE_SCALE for k, v in _relative_rates(ctx, plant, line, item, day).items()}
    if plant == 'CN01' and day >= ctx.d('2026-11-03'):
        rates['AIM_OUT'] = 33000
    return rates


def _relative_rates(ctx, plant, line, item, day):
    rates = {}
    if line == 'L02':
        rates = {'LENS_HAZE': 90, 'LENS_SCRATCH': 50, 'LENS_THICKNESS': 15}
        if day >= ctx.d('2026-11-21'):
            rates['LENS_THICKNESS'] = 15 + 25 * (day - ctx.d('2026-11-21')).days
        return rates
    rates = {'INNER_FOG': 190, 'LEAK_RATE': 40, 'LENS_SCRATCH': 30, 'AIM_OUT': 30, 'INNER_FOREIGN': 35, 'LED_OFF': 25,
             'PIN_BENT': 12, 'FLATNESS': 30}
    if item in ('92101-HE1L', '92102-HE1R', '92101-HE2L', '92101-KE1L', '92101-KC1L'):
        rates['DRL_FLICKER'] = 140
    if plant == 'KR01' and item.startswith('63117-BE1'):
        if day >= ctx.d('2026-11-10'):
            rates['INNER_FOG'] = 190 + 120 * (day - ctx.d('2026-11-10')).days
        if ctx.d('2026-10-01') <= day:
            rates['FLATNESS'] = 900
    if plant == 'KR01' and item in ('92101-HE1L', '92102-HE1R') and ctx.d('2026-07-01') <= day <= ctx.d('2026-10-31'):
        rates['DRL_FLICKER'] = 900
    return rates


def gen_mes(ctx):
    prod_rows, def_rows = [], []
    daily = {}   # (plant, item, date) -> dict(input, good, fp)
    mes_from = ctx.d('2025-12-01')
    d0, d1 = ctx.d('2024-12-01'), ctx.d('2026-11-30')
    r = rng('mes', ctx.seed)
    for day in daterange(d0, d1):
        for plant, line, item, qty, wd in PROD:
            if wd == 6 and day.weekday() == 6:
                continue
            itm = ctx.items[item]
            if itm.get('vehicles'):
                sop = min(ctx.d(ctx.vehicles[v]['sop']) for v in itm['vehicles'] if v in ctx.vehicles)
                if day < sop:
                    continue
            total_in = poisson(r, qty) if qty < 60 else int(round(r.gauss(qty, qty * 0.04)))
            rates = defect_rates(ctx, plant, line, item, day)
            shifts = ['D', 'N'] if line != 'L02' else ['A', 'B', 'C']
            day_good = day_fp = 0
            for si, sh in enumerate(shifts):
                inp = total_in // len(shifts) + (1 if si < total_in % len(shifts) else 0)
                dsum = 0
                lot = f"{plant}{line}{day.strftime('%y%m%d')}{sh}{item.split('-')[-1]}"
                for code, ppm in rates.items():
                    q = poisson(r, inp * ppm / 1e6)
                    if q <= 0:
                        continue
                    dsum += q
                    if day >= mes_from:
                        mc, path, op, ch = DEFECTS[code]
                        ch_ok = ch and (item, ch) in ctx.chars
                        hour = {'D': 10, 'N': 22, 'A': 3, 'B': 11, 'C': 19}[sh]
                        def_rows.append({'MES_DEFECT_ID': f"{plant}-{lot}-{mc}", 'PLANT_CODE': plant, 'LINE_CODE': line,
                                         'OP_CODE': op if line != 'L02' else 'OP10', 'ITEM_NO': item, 'PROD_DATE': day.isoformat(),
                                         'SHIFT': sh, 'MES_LOT_NO': lot, 'MES_DEFECT_CODE': mc, 'DEFECT_TYPE_CODE': path, 'QTY': q,
                                         'IS_SPECIAL_CHAR': bool(ch_ok and ctx.chars[(item, ch)].get('special') in ('CC', 'SC')),
                                         'CHAR_NO': ch if ch_ok else None,
                                         'DETECTED_TS': iso(ctx.local(day, hour, 30, plant)),
                                         'CHANGED_TS': iso(ctx.local(day, hour, 31, plant)), 'DELETED': False})
                scrap = int(round(dsum * 0.4))
                rework = dsum - scrap
                good = inp - scrap
                fp = inp - dsum
                day_good += good
                day_fp += fp
                if day >= mes_from:
                    closed = day < ctx.d('2026-11-30') or sh in ('D', 'A', 'B')
                    fourm = 'FM-KR01-2026-00041' if (item == '92101-HE1L' and day >= ctx.d('2026-11-26')) else None
                    prod_rows.append({'PLANT_CODE': plant, 'LINE_CODE': line, 'ITEM_NO': item, 'PROD_DATE': day.isoformat(),
                                      'SHIFT': sh, 'MES_LOT_NO': lot, 'INPUT_QTY': inp, 'GOOD_QTY': good, 'FIRST_PASS_QTY': fp,
                                      'REWORK_QTY': rework, 'SCRAP_QTY': scrap, 'LOT_STATUS': 'CLOSED' if closed else 'OPEN',
                                      'LOT_CLOSED_TS': iso(ctx.local(day, 23, 50, plant)) if closed else None,
                                      'FOURM_RECORD_NO': fourm, 'SPEC_VERSION': None,
                                      'CHANGED_TS': iso(ctx.local(day, 23, 51, plant)), 'DELETED': False,
                                      '_SOURCE': 'DEMO', '_BATCH_ID': 'DEMO-2026-12-01', '_LOADED_AT': ctx.loaded_at})
            daily[(plant, item, day)] = {'input': total_in, 'good': day_good, 'fp': day_fp}
    ctx.snow('CORE.MES_PRODUCTION', prod_rows)
    ctx.snow('CORE.MES_DEFECT', def_rows)
    ctx.mes_daily = daily
    ctx.mes_prod_rows = prod_rows
    ctx.mes_def_rows = def_rows
    # 최근 6개월 상위 불량(S5)
    tot = {}
    for x in def_rows:
        if x['PROD_DATE'] >= ctx.d('2026-06-01').isoformat():
            tot[x['DEFECT_TYPE_CODE']] = tot.get(x['DEFECT_TYPE_CODE'], 0) + x['QTY']
    ctx.mes_top = sorted(tot.items(), key=lambda kv: -kv[1])
    names = {path: path.split('/')[-1] for path in tot}
    for grp_tree in ctx.m['codes']['DEFECT_TYPE']:
        for l2 in grp_tree.get('children', []):
            for l3 in l2.get('children', []):
                names[f"DEFECT_TYPE/{grp_tree['code']}/{l2['code']}/{l3['code']}"] = l3['name']
    all_qty = sum(tot.values()) or 1
    prow, cum = [], 0
    for path, q in ctx.mes_top[:20]:
        cum += q
        prow.append([path, names.get(path), q, round(100 * q / all_qty, 2), round(100 * cum / all_qty, 2)])
    write_mock(ctx, 'QMS_EFC_DEFECT_PARETO', 'ok', envelope('QMS_EFC_DEFECT_PARETO', {'plantCodes': sorted(ctx.plants), 'fromDate': ctx.d('2026-06-01').isoformat(),
                                                                                     'toDate': ctx.d('2026-11-30').isoformat()},
                                                            [('defectTypeCode', 'STRING', None), ('defectTypeName', 'STRING', None), ('qty', 'NUMBER', None),
                                                             ('pct', 'NUMBER', '%'), ('cumulativePct', 'NUMBER', '%')], prow, as_of=ctx.loaded_at, scope='ALL'))
    gen_eol(ctx)


def gen_eol(ctx):
    rows = []
    r = rng('eol', ctx.seed)
    stats = {}
    for day in daterange(ctx.d('2026-10-01'), ctx.d('2026-11-30')):
        if day.weekday() == 6:
            continue
        for k in range(150):
            sh = 'D' if k < 75 else 'N'
            lot = f"CN01L01{day.strftime('%y%m%d')}{sh}KC1L"
            t = ctx.local(day, 7 + (k * 15) // 150, (k * 37) % 60, 'CN01')
            shifted = day >= ctx.d('2026-11-03')
            aim = r.gauss(0.108, 0.05) if shifted else r.gauss(0.0, 0.04)
            leak = max(0.05, r.gauss(1.1, 0.25))
            drl = r.gauss(350, 5)
            other_fail = r.random() < 0.015
            aim_fail = abs(aim) > 0.2
            res1 = 'FAIL' if (aim_fail or other_fail) else 'PASS'
            code = 'AIM_V' if aim_fail else ('DRL_I' if other_fail and r.random() < 0.5 else ('LEAK' if other_fail else None))
            if other_fail and code == 'LEAK':
                leak = r.uniform(3.05, 3.6)
            if other_fail and code == 'DRL_I':
                drl = r.uniform(372, 380)
            serial = f"KC1{day.strftime('%y%m%d')}{k + 1:04d}"
            items = [{'code': 'AIM_V', 'value': round(aim, 3), 'result': 'FAIL' if aim_fail else 'PASS'},
                     {'code': 'LEAK', 'value': round(leak, 2), 'result': 'FAIL' if code == 'LEAK' else 'PASS'},
                     {'code': 'DRL_I', 'value': round(drl, 1), 'result': 'FAIL' if code == 'DRL_I' else 'PASS'}]
            disp = 'SHIPPABLE'
            rows.append(eol_row(serial, lot, t, 1, res1, code, items, None))
            st = stats.setdefault(day, {'tested': 0, 'fp': 0, 'finalFail': 0, 'scrapped': 0})
            st['tested'] += 1
            if res1 == 'PASS':
                st['fp'] += 1
                rows[-1]['DISPOSITION'] = 'SHIPPABLE'
                continue
            ok2 = r.random() < 0.9
            items2 = [dict(i, value=(round(r.gauss(0.0, 0.03), 3) if i['code'] == 'AIM_V' else i['value']),
                           result=('PASS' if ok2 else ('FAIL' if i['code'] == code else 'PASS'))) for i in items]
            rows[-1]['DISPOSITION'] = 'REWORK'
            rows.append(eol_row(serial, lot, t + dt.timedelta(minutes=25), 2, 'PASS' if ok2 else 'FAIL', None if ok2 else code,
                                items2, 'SHIPPABLE' if ok2 else 'SCRAPPED'))
            if not ok2:
                st['finalFail'] += 1
                st['scrapped'] += 1
    ctx.snow('CORE.EOL_TEST_RESULT', rows)
    by_month = {}
    for d, s in stats.items():
        m = month_start(d).isoformat()
        b = by_month.setdefault(m, {'tested': 0, 'fp': 0, 'finalFail': 0})
        for k in b:
            b[k] += s[k]
    exp = {'plant': 'CN01', 'line': 'L01', 'item': '92101-KC1L', 'note': 'S13. FPY = 1차 PASS 시리얼 / 시험 시리얼',
           'monthly': {m: dict(b, fpyPct=round(100 * b['fp'] / b['tested'], 3)) for m, b in sorted(by_month.items())},
           'daily': {d.isoformat(): dict(s, fpyPct=round(100 * s['fp'] / s['tested'], 3)) for d, s in sorted(stats.items())}}
    write_json('expected/eol_S13.json', exp)
    ctx.eol_stats = stats
    ctx.eol_expected = exp
    # FQC EOL 요약 목(11-25 주간 로트)
    day = ctx.d('2026-11-25')
    lot = f"CN01L01{day.strftime('%y%m%d')}DKC1L"
    sel = [x for x in rows if x['MES_LOT_NO'] == lot]
    serials = {x['SERIAL_NO'] for x in sel}
    fp = {x['SERIAL_NO'] for x in sel if x['TEST_SEQ'] == 1 and x['RESULT'] == 'PASS'}
    final = {}
    for x in sorted(sel, key=lambda z: z['TEST_SEQ']):
        final[x['SERIAL_NO']] = x
    fpass = sum(1 for x in final.values() if x['RESULT'] == 'PASS')
    ffail = sum(1 for x in final.values() if x['RESULT'] == 'FAIL')
    scr = sum(1 for x in final.values() if x['DISPOSITION'] == 'SCRAPPED')
    produced = next((p['INPUT_QTY'] for p in ctx.mes_prod_rows if p['MES_LOT_NO'] == lot), len(serials))
    cols = [('plantCode', 'STRING', None), ('itemNo', 'STRING', None), ('mesLotNo', 'STRING', None), ('testCode', 'STRING', None),
            ('produced', 'INTEGER', None), ('tested', 'INTEGER', None), ('firstPass', 'INTEGER', None), ('finalPass', 'INTEGER', None),
            ('finalFail', 'INTEGER', None), ('scrapped', 'INTEGER', None), ('untested', 'INTEGER', None)]
    write_mock(ctx, 'QMS_FQC_EOL_SUMMARY', 'ok', envelope('QMS_FQC_EOL_SUMMARY', {'plantCode': 'CN01', 'itemNo': '92101-KC1L', 'mesLotNos': [lot], 'plantCodes': ['CN01']},
                                                          cols, [['CN01', '92101-KC1L', lot, 'ALL', produced, len(serials), len(fp), fpass, ffail, scr,
                                                                  max(produced - len(serials), 0)]], as_of=ctx.loaded_at, scope='CN01'))


def eol_row(serial, lot, t, seq, result, code, items, disp):
    return {'SERIAL_NO': serial, 'PLANT_CODE': 'CN01', 'LINE_CODE': 'L01', 'ITEM_NO': '92101-KC1L', 'MES_LOT_NO': lot,
            'TEST_STATION': 'CN01-EOL-1', 'TEST_TS': iso(t), 'TEST_SEQ': seq, 'RESULT': result, 'FAIL_CODE': code,
            'TEST_ITEMS': json.dumps(items, separators=(',', ':')), 'DISPOSITION': disp,
            '_SOURCE': 'DEMO', '_BATCH_ID': 'DEMO-2026-12-01', '_LOADED_AT': LOADED_AT[0]}


# ============================================================== SAP

FG_CUSTOMER_PLANT = {}  # item -> [(plant, oem)]
PRICES = {'63117-BE1L': 520000, '63117-BE1R': 520000, '92101-HE1L': 310000, '92102-HE1R': 310000, '92101-HE2L': 360000,  # KRW
          '92101-KE1L': 330000, '92101-KC1L': 313500, '84001-GE1L': 331200, '84101-FE1L': 317400, '98140-SE1L': 269100,
          '92401-HE1L': 120000, 'S-LENS-BE1': 21000, 'P-LENS-HE1': 18000, 'P-HSG-HE1': 22000, 'P-HSG-BE1': 26000,
          'P-BZL-HE1': 7000, 'P-LED-HE1': 45000, 'P-LED-BE1': 68000, 'P-REF-BE1': 9000, 'P-CON-01': 1200, 'P-PCB-HE1': 15000,
          'P-ACT-01': 13000, 'P-VENT-01': 600, 'R-PC-A01': 4500, 'R-PC-B01': 5200}
CCY = {'KR01': 'KRW', 'KR02': 'KRW', 'CN01': 'CNY', 'US01': 'USD', 'PL01': 'PLN'}


def gen_sap(ctx):
    r = rng('sap', ctx.seed)
    ships = []
    seq = {}
    fg = [(p, it) for p, l, it, q, w in PROD if ctx.items[it]['type'] == 'FG']
    six = ctx.d('2026-06-01')
    for plant, item in fg:
        oem = ctx.items[item]['customer']
        cust = ctx.customers[oem]
        pending = 0
        pend_lots = []
        for day in daterange(ctx.d('2024-12-01'), ctx.d('2026-11-30')):
            dd = ctx.mes_daily.get((plant, item, day))
            if dd:
                pending += dd['good']
                pend_lots.append(day)
            ship_today = (day >= six and day.weekday() < 5) or (day < six and day.weekday() == 4)
            if ship_today and pending > 0:
                seq[plant] = seq.get(plant, 0) + 1
                dn = f"8{list(ctx.plants).index(plant) + 1}{seq[plant]:07d}"
                bday = pend_lots[-1]
                lot = f"{plant}L01{bday.strftime('%y%m%d')}D{item.split('-')[-1]}"
                if plant == 'KR01' and item.startswith('921'):
                    lot = f"{plant}L05{bday.strftime('%y%m%d')}D{item.split('-')[-1]}"
                ships.append({'DELIVERY_NO': dn, 'DELIVERY_ITEM': 10, 'PLANT_CODE': plant, 'ITEM_NO': item,
                              'CUSTOMER_NO': cust['sapNo'], 'OEM_CODE': oem, 'SHIP_TO': f"{oem}-{plant}",
                              'PGI_DATE': day.isoformat(), 'PGI_TS': iso(ctx.local(day, 17, 0, plant)), 'QTY': pending, 'UOM': 'EA',
                              'BATCH': f"{item[-4:]}{bday.strftime('%y%m%d')}", 'BATCH_PROD_DATE': bday.isoformat(), 'MES_LOT_NO': lot})
                pending = 0
                pend_lots = []
    ctx.snow('CORE.SAP_SHIPMENT', ships)
    ctx.ships = ships
    # 환율(월)
    fx = []
    base = {'USD': 1380.0, 'EUR': 1495.0, 'CNY': 190.0, 'PLN': 345.0}
    m = ctx.d('2024-12-01')
    while m <= ctx.d('2026-11-01'):
        for c, b in base.items():
            fx.append({'RATE_TYPE': 'M', 'FROM_CCY': c, 'TO_CCY': 'KRW', 'VALID_FROM': m.isoformat(),
                       'RATE': round(b * (1 + 0.015 * math.sin(months_between(ctx.d('2024-12-01'), m) / 3.0)), 4)})
        m = add_months(m, 1)
    ctx.snow('CORE.SAP_FX_RATE', fx)
    # 표준가
    price = []
    for it in ctx.items.values():
        for p in it.get('plants', []):
            c = CCY[p]
            unit = 100 if it['itemNo'] in ('P-CON-01', 'P-VENT-01') else 1
            v = PRICES.get(it['itemNo'], 1000) * unit
            if c != 'KRW':
                v = round(v / base[c], 2)
            price.append({'PLANT_CODE': p, 'ITEM_NO': it['itemNo'], 'PRICE_CONTROL': 'S', 'PRICE': v, 'PRICE_UNIT': unit,
                          'CURRENCY': c, 'VALID_FROM': ctx.d('2025-01-01').isoformat()})
    ctx.snow('CORE.SAP_MATERIAL_PRICE', price)
    # BOM(1단계)
    bom = []
    mirror = {'63117-BE1R': '63117-BE1L', '92102-HE1R': '92101-HE1L'}
    for b in ctx.m['bom']:
        parents = [b['parent']] + [k for k, v in mirror.items() if v == b['parent']]
        for par in parents:
            for p in ctx.items[par].get('plants', []):
                bom.append({'PLANT_CODE': p, 'PARENT_ITEM_NO': par, 'COMPONENT_ITEM_NO': b['child'], 'COMPONENT_QTY': b['qty'],
                            'UOM': 'KG' if b['child'].startswith('R-') else 'EA', 'BOM_USAGE': '1', 'ALT_BOM': '01',
                            'VALID_FROM': '2024-01-01', 'VALID_TO': '9999-12-31'})
    ctx.snow('CORE.SAP_BOM', bom)
    gen_lots_stock(ctx, r)


def supplier_lots_from_sf(ctx):
    """Salesforce 데이터 작업의 수입검사 로트 CSV가 있으면 협력사 로트를 그대로 쓴다."""
    rows = read_sf_merged('QMS_IqcLot__c', 'ExternalKey__c')
    if not rows:
        return None
    out = []
    for row in rows:
        g = lambda k: row.get(k) or None
        out.append({'plant': g('Plant__r.PlantCode__c'), 'item': g('Item__r.ItemNo__c'), 'vendor': g('Supplier__r.SapVendorNo__c'),
                    'lot': g('SupplierLotNo__c'), 'grDate': (g('GrDate__c') or '')[:10], 'qty': float(g('GrQty__c') or 0),
                    'recordNo': g('RecordNo__c'), 'ext': g('ExternalKey__c'), 'decision': g('Decision__c')})
    return [o for o in out if o['lot'] and o['grDate']]


def gen_lots_stock(ctx, r):
    """협력사 로트(SF 수입검사 로트가 있으면 그것, 없으면 주 1회 합성) → SAP 배치·재고·로트 계보."""
    sf_lots = supplier_lots_from_sf(ctx)
    lots = []
    if sf_lots:
        lots = sf_lots
        ctx.notes.append(f'협력사 로트를 Salesforce 수입검사 CSV에서 {len(sf_lots)}건 사용')
    else:
        ctx.notes.append('Salesforce 수입검사 CSV 없음 → 협력사 로트를 패턴 {VendorNo}-{yyMMdd}-{n}으로 합성(SF 로트 번호와 연결되지 않음)')
        for si in ctx.m['supplierItems']:
            if si['inspectionLevel'] == 'SKIP':
                pass
            for day in daterange(ctx.d('2026-09-01'), ctx.d('2026-11-30')):
                if day.weekday() not in (0, 3):
                    continue
                if si['item'] == 'P-LENS-HE1' and si['plant'] == 'KR01' and day >= ctx.d('2026-11-25'):
                    continue
                rej = si['item'] == 'P-HSG-BE1' and si['plant'] == 'KR01' and day == ctx.d('2026-11-26')
                lots.append({'plant': si['plant'], 'item': si['item'], 'vendor': si['vendor'],
                             'lot': f"{si['vendor']}-{day.strftime('%y%m%d')}-A", 'grDate': day.isoformat(),
                             'qty': 1200.0, 'recordNo': None, 'decision': 'REJECT' if rej else 'ACCEPT'})
        d4m = ctx.d('2026-11-25')
        lots.append({'plant': 'KR01', 'item': 'P-LENS-HE1', 'vendor': 'V10001', 'lot': f"V10001-{d4m.strftime('%y%m%d')}-A",
                     'grDate': d4m.isoformat(), 'qty': 600.0, 'recordNo': None, 'decision': 'ACCEPT'})
    batches, stock, trace = [], [], []
    bseq = 0
    lot_batch = {}
    for lt in lots:
        bseq += 1
        b = f"B{bseq:07d}"
        lot_batch[(lt['plant'], lt['item'], lt['lot'])] = b
        batches.append({'PLANT_CODE': lt['plant'], 'ITEM_NO': lt['item'], 'BATCH': b, 'VENDOR_NO': lt['vendor'],
                        'VENDOR_BATCH': lt['lot'], 'PROD_DATE': lt['grDate'], 'SLED': None, 'IS_RESTRICTED': False})
    ctx.snow('CORE.SAP_BATCH', batches)
    snap = iso(ctx.local(ctx.d('2026-11-30'), 23, 0, 'KR01'))
    # 재고 스냅숏: 완제품 2일분, 부품 최근 로트
    for (plant, item, day), dd in ctx.mes_daily.items():
        if day == ctx.d('2026-11-28') and ctx.items[item]['type'] == 'FG':
            stock.append(stock_row(plant, 'FG01', item, f"{item[-4:]}{day.strftime('%y%m%d')}", 'UNRESTRICTED', None, dd['good'] * 2,
                                   day.isoformat(), None, snap))
    stock.append(stock_row('KR01', 'FG01', '63117-BE1L', 'BE1L261124', 'BLOCKED', None, 120, ctx.d('2026-11-24').isoformat(), None, snap))
    stock.append(stock_row('KR01', 'SV01', '92101-HE1L', 'HE1L260815', 'UNRESTRICTED', None, 36, ctx.d('2026-08-15').isoformat(), None, snap))
    last_by = {}
    for lt in lots:
        k = (lt['plant'], lt['item'])
        last_by.setdefault(k, []).append(lt)
    for (plant, item), ls in last_by.items():
        ls.sort(key=lambda x: x['grDate'])
        recent_rej = [lt for lt in ls[:-2] if lt.get('decision') == 'REJECT' and lt['grDate'] >= ctx.d('2026-11-01').isoformat()]
        for lt in recent_rej + ls[-2:]:  # 반품 대기 불합격 로트 + 최근 2로트
            st = 'QUALITY' if lt['grDate'] >= ctx.d('2026-11-29').isoformat() else 'UNRESTRICTED'
            if lt.get('decision') == 'REJECT':
                st = 'BLOCKED'
            if item == 'P-LENS-HE1' and plant == 'KR01' and lt['grDate'] == ctx.d('2026-11-25').isoformat():
                st = 'QUALITY'  # S3 4M 첫 로트(초기유동 Hold)
            stock.append(stock_row(plant, 'RM01', item, lot_batch[(plant, item, lt['lot'])], st, lt['vendor'],
                                   lt['qty'] if item != 'P-LENS-HE1' else (1800 if st == 'UNRESTRICTED' else lt['qty']),
                                   lt['grDate'], lt['lot'], snap))
    ctx.snow('CORE.SAP_STOCK', stock)
    # 로트 계보: 렌즈·LED 협력사 로트 → HE1L MES 로트 → 납품, BE1L MES 로트 → 납품
    mes_lots = {}
    for p in ctx.mes_prod_rows:
        mes_lots.setdefault((p['PLANT_CODE'], p['ITEM_NO']), []).append(p)
    def consumer_edges(part, plant, fg_item, from_d, to_d):
        pls = sorted([l for l in lots if l['item'] == part and l['plant'] == plant], key=lambda x: x['grDate'])
        for pr in mes_lots.get((plant, fg_item), []):
            if not (from_d.isoformat() <= pr['PROD_DATE'] <= to_d.isoformat()):
                continue
            src = [l for l in pls if l['grDate'] < pr['PROD_DATE']]
            if not src:
                continue
            sl = src[-1]
            trace.append({'PLANT_CODE': plant, 'FROM_LOT_TYPE': 'SUPPLIER_LOT', 'FROM_LOT_NO': sl['lot'], 'FROM_ITEM_NO': part,
                          'TO_LOT_TYPE': 'MES_LOT', 'TO_LOT_NO': pr['MES_LOT_NO'], 'TO_ITEM_NO': fg_item, 'QTY': pr['INPUT_QTY'],
                          'LINK_TS': iso(ctx.local(dt.date.fromisoformat(pr['PROD_DATE']), 8, 0, plant)), 'LINK_SOURCE': 'MES_CONSUME',
                          'CUSTOMER_CODE': None, 'SHIP_DATE': None, '_UPDATED_AT': ctx.loaded_at})
    consumer_edges('P-LENS-HE1', 'KR01', '92101-HE1L', ctx.d('2026-11-01'), ctx.d('2026-11-30'))
    consumer_edges('P-LED-HE1', 'KR01', '92101-HE1L', ctx.d('2026-09-01'), ctx.d('2026-11-30'))
    for s in ctx.ships:
        if s['ITEM_NO'] in ('92101-HE1L', '63117-BE1L') and s['PLANT_CODE'] == 'KR01' and s['PGI_DATE'] >= ctx.d('2026-09-01').isoformat():
            trace.append({'PLANT_CODE': 'KR01', 'FROM_LOT_TYPE': 'MES_LOT', 'FROM_LOT_NO': s['MES_LOT_NO'], 'FROM_ITEM_NO': s['ITEM_NO'],
                          'TO_LOT_TYPE': 'DELIVERY', 'TO_LOT_NO': s['DELIVERY_NO'], 'TO_ITEM_NO': s['ITEM_NO'], 'QTY': s['QTY'],
                          'LINK_TS': s['PGI_TS'], 'LINK_SOURCE': 'SAP_DELIVERY', 'CUSTOMER_CODE': s['OEM_CODE'],
                          'SHIP_DATE': s['PGI_DATE'], '_UPDATED_AT': ctx.loaded_at})
    ctx.snow('CORE.LOT_TRACE', trace)
    ctx.lots, ctx.stock, ctx.trace = lots, stock, trace
    sap_mocks(ctx)


def stock_row(plant, sloc, item, batch, stype, vendor, qty, prod, vbatch, snap):
    return {'PLANT_CODE': plant, 'STORAGE_LOCATION': sloc, 'ITEM_NO': item, 'BATCH': batch, 'STOCK_TYPE': stype,
            'SPECIAL_STOCK': None, 'VENDOR_NO': vendor, 'QTY': qty, 'UOM': 'EA', 'BATCH_PROD_DATE': prod,
            'VENDOR_BATCH': vbatch, 'LAST_MOVEMENT_TS': snap, 'SNAPSHOT_TS': snap}


def sap_mocks(ctx):
    snap = iso(ctx.local(ctx.d('2026-11-30'), 23, 0, 'KR01'))
    cols = [('plantCode', 'STRING', None), ('storageLocation', 'STRING', None), ('itemNo', 'STRING', None), ('batch', 'STRING', None),
            ('vendorBatch', 'STRING', None), ('stockType', 'STRING', None), ('specialStock', 'STRING', None), ('vendorNo', 'STRING', None),
            ('qty', 'NUMBER', None), ('uom', 'STRING', None), ('batchProdDate', 'DATE', None), ('snapshotTs', 'DATETIME', None)]
    rows = [[s['PLANT_CODE'], s['STORAGE_LOCATION'], s['ITEM_NO'], s['BATCH'], s['VENDOR_BATCH'], s['STOCK_TYPE'], s['SPECIAL_STOCK'],
             s['VENDOR_NO'], s['QTY'], s['UOM'], s['BATCH_PROD_DATE'], s['SNAPSHOT_TS']]
            for s in ctx.stock if s['ITEM_NO'] == 'P-LENS-HE1' and s['PLANT_CODE'] == 'KR01']
    write_mock(ctx, 'QMS_4M_OLD_STOCK', 'ok', envelope('QMS_4M_OLD_STOCK', {'itemNos': ['P-LENS-HE1'], 'plantCode': 'KR01', 'vendorNo': 'V10001', 'plantCodes': ['KR01']},
                                                       cols, rows, as_of=snap))
    bcols = [('inputItemNo', 'STRING', None), ('itemNo', 'STRING', None), ('level', 'INTEGER', None), ('isTop', 'BOOLEAN', None),
             ('componentQty', 'NUMBER', None), ('plantCode', 'STRING', None)]
    write_mock(ctx, 'QMS_BOM_WHERE_USED', 'ok', envelope('QMS_BOM_WHERE_USED', {'itemNos': ['P-LENS-HE1'], 'plantCode': 'KR01', 'asOfDate': '2026-11-30', 'plantCodes': ['KR01']},
                                                         bcols, [['P-LENS-HE1', '92101-HE1L', 1, True, 1, 'KR01']], as_of=snap))
    tcols = [('seedLotNo', 'STRING', None), ('seedExists', 'BOOLEAN', None), ('depth', 'INTEGER', None), ('fromLotType', 'STRING', None),
             ('fromLotNo', 'STRING', None), ('fromItemNo', 'STRING', None), ('toLotType', 'STRING', None), ('toLotNo', 'STRING', None),
             ('toItemNo', 'STRING', None), ('qty', 'NUMBER', None), ('linkTs', 'DATETIME', None), ('linkSource', 'STRING', None),
             ('customerCode', 'STRING', None), ('shipDate', 'DATE', None)]
    seed = next((l['lot'] for l in ctx.lots if l['item'] == 'P-LENS-HE1' and l['plant'] == 'KR01' and l['grDate'] >= ctx.d('2026-11-25').isoformat()), None)
    rows = []
    if seed:
        lvl1 = [t for t in ctx.trace if t['FROM_LOT_NO'] == seed]
        for t in lvl1:
            rows.append([seed, True, 1, t['FROM_LOT_TYPE'], t['FROM_LOT_NO'], t['FROM_ITEM_NO'], t['TO_LOT_TYPE'], t['TO_LOT_NO'],
                         t['TO_ITEM_NO'], t['QTY'], t['LINK_TS'], t['LINK_SOURCE'], t['CUSTOMER_CODE'], t['SHIP_DATE']])
            for t2 in [x for x in ctx.trace if x['FROM_LOT_NO'] == t['TO_LOT_NO']]:
                rows.append([seed, True, 2, t2['FROM_LOT_TYPE'], t2['FROM_LOT_NO'], t2['FROM_ITEM_NO'], t2['TO_LOT_TYPE'], t2['TO_LOT_NO'],
                             t2['TO_ITEM_NO'], t2['QTY'], t2['LINK_TS'], t2['LINK_SOURCE'], t2['CUSTOMER_CODE'], t2['SHIP_DATE']])
    write_mock(ctx, 'QMS_4M_LOT_TRACE', 'ok', envelope('QMS_4M_LOT_TRACE', {'plantCode': 'KR01', 'lotType': 'SUPPLIER_LOT', 'lotNos': [seed], 'maxDepth': 5, 'plantCodes': ['KR01']},
                                                       tcols, rows, as_of=ctx.loaded_at))
    # 클레임 의심 재고(S2: HE1L 2026-07~09 생산분)
    scols = [('locationType', 'STRING', None), ('plantCode', 'STRING', None), ('storageLocation', 'STRING', None), ('oemCode', 'STRING', None),
             ('itemNo', 'STRING', None), ('batch', 'STRING', None), ('stockType', 'STRING', None), ('batchProdDate', 'DATE', None),
             ('qty', 'NUMBER', None), ('pgiDate', 'DATE', None), ('snapshotTs', 'DATETIME', None)]
    srows = []
    for s in ctx.stock:
        if s['ITEM_NO'] == '92101-HE1L' and ctx.d('2026-07-01').isoformat() <= (s['BATCH_PROD_DATE'] or '') <= ctx.d('2026-09-30').isoformat():
            srows.append(['SERVICE' if s['STORAGE_LOCATION'] == 'SV01' else 'PLANT_STOCK', s['PLANT_CODE'], s['STORAGE_LOCATION'], None,
                          s['ITEM_NO'], s['BATCH'], s['STOCK_TYPE'], s['BATCH_PROD_DATE'], s['QTY'], None, s['SNAPSHOT_TS']])
    for s in ctx.ships:
        if s['ITEM_NO'] == '92101-HE1L' and s['PGI_DATE'] >= ctx.d('2026-11-24').isoformat():
            srows.append(['IN_TRANSIT', s['PLANT_CODE'], None, s['OEM_CODE'], s['ITEM_NO'], s['BATCH'], None, s['BATCH_PROD_DATE'],
                          s['QTY'], s['PGI_DATE'], snap])
    write_mock(ctx, 'QMS_CLM_SUSPECT_STOCK', 'ok', envelope('QMS_CLM_SUSPECT_STOCK', {'itemNo': '92101-HE1L', 'plantCode': 'KR01', 'prodFrom': '2026-07-01',
                                                                                     'prodTo': '2026-09-30', 'transitDays': 7, 'plantCodes': ['KR01']},
                                                            scols, srows, as_of=snap))


# ============================================================== B2B

CUST_DEFECTS = {
    'HKMC': [('HK-L034', '램프 내부 습기', 'DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG'),
             ('HK-L021', 'DRL 점멸', 'DEFECT_TYPE/FUNCTION/LIGHTING/DRL_FLICKER'),
             ('HK-L012', '렌즈 긁힘', 'DEFECT_TYPE/APPEARANCE/SCRATCH/LENS_SCRATCH'),
             ('HK-L050', '광축 불량', 'DEFECT_TYPE/OPTICAL/AIMING/AIM_OUT'),
             ('HK-L061', 'LED 미점등', 'DEFECT_TYPE/FUNCTION/LIGHTING/LED_OFF'),
             ('HK-L099', '기타 램프 불량', None)],
    'BMW': [('BMW-6311-KON', 'Kondenswasser im Scheinwerfer', 'DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG'),
            ('BMW-6311-KRA', 'Kratzer Streuscheibe', 'DEFECT_TYPE/APPEARANCE/SCRATCH/LENS_SCRATCH'),
            ('BMW-6311-LED', 'LED Ausfall', 'DEFECT_TYPE/FUNCTION/LIGHTING/LED_OFF'),
            ('BMW-6311-EIN', 'Einstellung fehlerhaft', 'DEFECT_TYPE/OPTICAL/AIMING/AIM_OUT')],
    'GM': [('GM-HL-104', 'Moisture in lamp', 'DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG'),
           ('GM-HL-220', 'Lamp inoperative', 'DEFECT_TYPE/FUNCTION/LIGHTING/LED_OFF'),
           ('GM-HL-310', 'Lens scratch', 'DEFECT_TYPE/APPEARANCE/SCRATCH/LENS_SCRATCH')],
    'FORD': [('FD-L-07', 'Condensation', 'DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG'),
             ('FD-L-12', 'DRL flicker', 'DEFECT_TYPE/FUNCTION/LIGHTING/DRL_FLICKER'),
             ('FD-L-03', 'Lens scratch', 'DEFECT_TYPE/APPEARANCE/SCRATCH/LENS_SCRATCH')],
    'STELLANTIS': [('ST-HL-15', 'Buée phare', 'DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG'),
                   ('ST-HL-22', 'Rayure glace', 'DEFECT_TYPE/APPEARANCE/SCRATCH/LENS_SCRATCH')],
}
BASE_0KM_PPM = {'HMC': 40, 'KIA': 40, 'BMW': 30, 'GM': 50, 'FORD': 45, 'STLA': 35}
COUNTRY = {'HMC': 'KR', 'KIA': 'KR', 'BMW': 'DE', 'GM': 'US', 'FORD': 'US', 'STLA': 'PL'}
COST_CCY = {'HMC': ('KRW', 180000), 'KIA': ('KRW', 180000), 'BMW': ('EUR', 240), 'GM': ('USD', 210), 'FORD': ('USD', 200), 'STLA': ('EUR', 160)}
PPM_TARGET = {'HMC': 80, 'KIA': 80, 'BMW': 50, 'GM': 100, 'FORD': 100, 'STLA': 100}


def gen_b2b(ctx):
    r = rng('b2b', ctx.seed)
    std, core, vol = [], [], []
    fx = {}
    month_ship = {}
    for s in ctx.ships:
        k = (s['OEM_CODE'], s['ITEM_NO'], month_start(dt.date.fromisoformat(s['PGI_DATE'])))
        month_ship[k] = month_ship.get(k, 0) + s['QTY']
    veh_item = {}
    for it in ctx.items.values():
        if it['type'] == 'FG' and it['itemNo'].endswith('L') and it.get('vehicles'):
            veh_item.setdefault(it['vehicles'][0], it['itemNo'])  # 헤드램프 LH 우선(마스터 순서), RCL 제외
    item_plants = {it['itemNo']: it.get('plants', []) for it in ctx.items.values()}
    months = []
    m = ctx.d('2024-12-01')
    while m <= ctx.d('2026-11-01'):
        months.append(m)
        m = add_months(m, 1)
    # 차량 대수: 생산 = 해당 월 LH 출하, 판매 = 전월 생산 × 0.97
    produced = {}
    for vkey, item in veh_item.items():
        oem = ctx.vehicles[vkey]['customer']
        for m in months:
            q = month_ship.get((oem, item, m), 0)
            produced[(vkey, m)] = q
            vol.append({'CUSTOMER_CODE': oem, 'VEHICLE_CODE': ctx.vehicles[vkey]['code'], 'MONTH': m.isoformat(),
                        'VOLUME_TYPE': 'PRODUCED', 'QTY': q, 'SOURCE': 'FC'})
            sold = int(round(produced.get((vkey, add_months(m, -1)), 0) * 0.97))
            vol.append({'CUSTOMER_CODE': oem, 'VEHICLE_CODE': ctx.vehicles[vkey]['code'], 'MONTH': m.isoformat(),
                        'VOLUME_TYPE': 'SOLD', 'QTY': sold, 'SOURCE': 'FC'})
    sold_by = {(v['CUSTOMER_CODE'], v['VEHICLE_CODE'], v['MONTH']): v['QTY'] for v in vol if v['VOLUME_TYPE'] == 'SOLD'}
    events = []

    def add_event(oem, dtype, ref, line_no, ev_date, vcode, item, defect, qty, prod_m=None, sales_m=None, fail_m=None,
                  mileage=None, vin=None, judgment='SUPPLIER_RESPONSIBLE'):
        grp = ctx.customers[oem]['group']
        code, text, path = defect
        ccy, unit_cost = COST_CCY[oem]
        cost = round(unit_cost * qty * (1.0 if dtype != 'FIELD' else 2.5), 2)
        events.append({'oem': oem, 'grp': grp, 'dtype': dtype, 'ref': ref, 'line': line_no, 'date': ev_date, 'vcode': vcode,
                       'item': item, 'cpn': ctx.items[item]['customerPartNo'], 'code': code, 'text': text, 'path': path,
                       'qty': qty, 'prod': prod_m, 'sales': sales_m, 'fail': fail_m, 'mileage': mileage, 'vin': vin,
                       'ccy': ccy, 'cost': cost, 'judgment': judgment})

    def pick_defect(oem, weights):
        lst = CUST_DEFECTS[ctx.customers[oem]['group']]
        tot = sum(weights.get(c[0], 1) for c in lst)
        x = r.random() * tot
        for c in lst:
            x -= weights.get(c[0], 1)
            if x <= 0:
                return c
        return lst[-1]

    # 0km
    for (oem, item, m), q in sorted(month_ship.items()):
        if m > ctx.d('2026-11-01'):
            continue
        ppm = BASE_0KM_PPM[oem]
        weights = {}
        s10 = {ctx.d('2026-09-01'): 60, ctx.d('2026-10-01'): 110, ctx.d('2026-11-01'): 190}
        if item.startswith('63117-BE1') and m in s10:
            ppm = s10[m]
            weights = {'BMW-6311-KON': 8}
        # 시나리오 품번(BMW BE1)은 기대 건수를 반올림해 월별 PPM 순서가 난수에 흔들리지 않게 한다
        n = int(q * ppm / 1e6 + 0.5) if item.startswith('63117-BE1') else poisson(r, q * ppm / 1e6)
        last_day = (add_months(m, 1) - dt.timedelta(days=1)).day
        for i in range(n):
            day = m.replace(day=1 + int(r.random() * last_day))
            add_event(oem, 'LINE_0KM', f"{oem}-0K-{m.strftime('%y%m')}-{item[-4:]}-{i + 1:04d}", 1, day,
                      ctx.vehicles[ctx.items[item]['vehicles'][0]]['code'], item, pick_defect(oem, weights), 1, prod_m=m,
                      judgment='SUPPLIER_RESPONSIBLE' if r.random() < 0.8 else 'UNDER_ANALYSIS')
    # 필드(판매 코호트 × MIS)
    for vkey, item in veh_item.items():
        oem = ctx.vehicles[vkey]['customer']
        vcode = ctx.vehicles[vkey]['code']
        for cm in months:
            sold = sold_by.get((oem, vcode, cm.isoformat()), 0)
            if not sold:
                continue
            for mis in range(0, 25):
                fm = add_months(cm, mis)
                if fm > ctx.d('2026-11-01'):
                    break
                hz = 0.035 / 1000
                weights = {}
                if vkey == 'HMC-HE1' and ctx.d('2026-07-01') <= cm <= ctx.d('2026-09-01') and 1 <= mis <= 3:
                    hz += 0.55 / 1000
                    weights = {'HK-L021': 12}
                n = poisson(r, sold * hz)
                for i in range(n):
                    day = fm.replace(day=1 + int(r.random() * 27))
                    vin = f"DEMO{vcode}{cm.strftime('%y%m')}{int(r.random() * 1e6):06d}"
                    add_event(oem, 'FIELD', f"{oem}-WC-{fm.strftime('%y%m')}-{vcode}-{len(events) + 1:05d}", 1, day, vcode, item,
                              pick_defect(oem, weights), 1, prod_m=add_months(cm, -1), sales_m=cm, fail_m=fm,
                              mileage=int(max(50, r.gauss(1300 * max(mis, 0.5), 400))), vin=vin)
    # 반품(월 0~2)
    for oem in ctx.customers:
        its = [i for i in veh_item.values() if ctx.items[i]['customer'] == oem]
        for m in months:
            for i in range(poisson(r, 0.6)):
                item = its[int(r.random() * len(its))]
                add_event(oem, 'RETURN', f"{oem}-RT-{m.strftime('%y%m')}-{i + 1:03d}", 1, m.replace(day=10 + i), ctx.items[item]['vehicles'][0].split('-')[1],
                          item, pick_defect(oem, {}), 1 + int(r.random() * 3))
    # 행 기록
    salt = 'DEMO-SALT'
    for e in events:
        key = sha256('FC', e['oem'], e['dtype'], e['ref'], e['line'])
        plants = item_plants.get(e['item'], [])
        plant = plants[0] if len(plants) == 1 else None
        mis = months_between(e['sales'], e['fail']) if (e['sales'] and e['fail']) else None
        base = {'EVENT_KEY': key, 'SOURCE': 'FC', 'UPLOAD_ID': None, 'CUSTOMER_CODE': e['oem'], 'DATA_TYPE': e['dtype'],
                'CUSTOMER_REF_NO': e['ref'], 'LINE_NO': e['line'], 'EVENT_DATE': e['date'].isoformat(), 'VEHICLE_CODE': e['vcode'],
                'CUSTOMER_PART_NO': e['cpn'], 'CUSTOMER_DEFECT_CODE': e['code'], 'CUSTOMER_DEFECT_TEXT': e['text'], 'QTY': e['qty'],
                'PRODUCTION_MONTH': e['prod'].isoformat() if e['prod'] else None,
                'SALES_MONTH': e['sales'].isoformat() if e['sales'] else None,
                'FAILURE_MONTH': e['fail'].isoformat() if e['fail'] else None, 'MILEAGE_KM': e['mileage'],
                'COST_AMOUNT': e['cost'], 'COST_CURRENCY': e['ccy'], 'COUNTRY': COUNTRY[e['oem']],
                'CUSTOMER_JUDGMENT': e['judgment']}
        std.append(dict(base, VIN=e['vin'], _IS_DELETED=False, LOADED_AT=ctx.loaded_at))
        rate = 1.0 if e['ccy'] == 'KRW' else {'EUR': 1495.0, 'USD': 1380.0}[e['ccy']]
        core.append(dict(base, CUSTOMER_GROUP=e['grp'], VIN_HASH=sha256(e['vin'], salt) if e['vin'] else None,
                         ITEM_NO=e['item'], ITEM_MAP_STATUS='MAPPED', PLANT_CODE=plant,
                         DEFECT_TYPE_CODE=e['path'], DEFECT_MAP_STATUS='MAPPED' if e['path'] else 'UNMAPPED', MIS=mis,
                         COST_KRW=round(e['cost'] * rate, 0), _IS_DELETED=False, LOADED_AT=ctx.loaded_at))
    core_fields = ['EVENT_KEY', 'SOURCE', 'UPLOAD_ID', 'CUSTOMER_CODE', 'CUSTOMER_GROUP', 'DATA_TYPE', 'CUSTOMER_REF_NO', 'EVENT_DATE',
                   'VEHICLE_CODE', 'VIN_HASH', 'CUSTOMER_PART_NO', 'ITEM_NO', 'ITEM_MAP_STATUS', 'PLANT_CODE', 'CUSTOMER_DEFECT_CODE',
                   'CUSTOMER_DEFECT_TEXT', 'DEFECT_TYPE_CODE', 'DEFECT_MAP_STATUS', 'QTY', 'PRODUCTION_MONTH', 'SALES_MONTH',
                   'FAILURE_MONTH', 'MIS', 'MILEAGE_KM', 'COST_AMOUNT', 'COST_CURRENCY', 'COST_KRW', 'COUNTRY', 'CUSTOMER_JUDGMENT',
                   '_IS_DELETED', 'LOADED_AT']
    std_fields = ['EVENT_KEY', 'SOURCE', 'UPLOAD_ID', 'CUSTOMER_CODE', 'DATA_TYPE', 'CUSTOMER_REF_NO', 'LINE_NO', 'EVENT_DATE',
                  'VEHICLE_CODE', 'VIN', 'CUSTOMER_PART_NO', 'CUSTOMER_DEFECT_CODE', 'CUSTOMER_DEFECT_TEXT', 'QTY', 'PRODUCTION_MONTH',
                  'SALES_MONTH', 'FAILURE_MONTH', 'MILEAGE_KM', 'COST_AMOUNT', 'COST_CURRENCY', 'COUNTRY', 'CUSTOMER_JUDGMENT',
                  '_IS_DELETED', 'LOADED_AT']
    ctx.snow('STG.CUSTOMER_QUALITY_STD', std, std_fields)
    ctx.snow('CORE.CUSTOMER_QUALITY_EVENT', core, core_fields)
    ctx.snow('CORE.CUSTOMER_VOLUME', vol)
    # 매핑(Salesforce)
    dmap, pmap = [], []
    for grp, lst in CUST_DEFECTS.items():
        for code, text, path in lst:
            if path is None:
                continue
            dmap.append({'ExternalKey__c': f'{grp}-*-{code}', 'CustomerGroup__c': grp, 'Customer__r.OemCode__c': None,
                         'CustomerDefectCode__c': code, 'CustomerDefectName__c': text, 'DefectType__r.ExternalKey__c': path,
                         'DefaultResponsibility__r.ExternalKey__c': 'RESPONSIBILITY/SUPPLIER' if 'LED' in code or 'L021' in code else None,
                         'IsActive__c': True})
    for it in ctx.items.values():
        if it['type'] == 'FG':
            for p in it.get('plants', []):
                pmap.append({'ExternalKey__c': f"{it['customer']}-{it['customerPartNo']}-{it['itemNo']}-20240101-{p}",
                             'Customer__r.OemCode__c': it['customer'], 'Item__r.ItemNo__c': it['itemNo'],
                             'CustomerPartNo__c': it['customerPartNo'], 'Plant__r.PlantCode__c': p if len(it['plants']) == 1 else None,
                             'ValidFrom__c': '2024-01-01', 'ValidTo__c': None})
    # 공장 2곳 품번은 공장 지정 없는 1행만
    seen, pm2 = set(), []
    for x in pmap:
        k = (x['Customer__r.OemCode__c'], x['CustomerPartNo__c'], x['Item__r.ItemNo__c'], x['Plant__r.PlantCode__c'])
        if k in seen:
            continue
        seen.add(k)
        x['ExternalKey__c'] = f"{k[0]}-{k[1]}-{k[2]}-20240101"
        pm2.append(x)
    ctx.sf('96_QMS_CustomerDefectMap__c', dmap)
    ctx.sf('97_QMS_CustomerPartMap__c', pm2)
    ctx.b2b_core, ctx.b2b_vol, ctx.month_ship = core, vol, month_ship
    b2b_expected_and_mocks(ctx)


def b2b_expected_and_mocks(ctx):
    core = ctx.b2b_core
    ppm, r1000, mis_curve = {}, {}, {}
    for (oem, item, m), q in ctx.month_ship.items():
        if m > ctx.d('2026-11-01') or q == 0:
            continue
        defects = sum(e['QTY'] for e in core if e['DATA_TYPE'] == 'LINE_0KM' and e['CUSTOMER_CODE'] == oem and e['ITEM_NO'] == item
                      and e['EVENT_DATE'][:7] == m.isoformat()[:7])
        ppm[(oem, item, m.isoformat())] = {'qty': defects, 'shipped': q, 'ppm': round(defects / q * 1e6, 3)}
    # MIS 곡선: HMC HE1 코호트 2026-05~09
    sold = {(v['CUSTOMER_CODE'], v['VEHICLE_CODE'], v['MONTH']): v['QTY'] for v in ctx.b2b_vol if v['VOLUME_TYPE'] == 'SOLD'}
    for cohort in ('2026-05-01', '2026-06-01', '2026-07-01', '2026-08-01', '2026-09-01'):
        c = ctx.d(cohort).isoformat()
        s = sold.get(('HMC', 'HE1', c), 0)
        pts, cum = [], 0
        for mis in range(0, 25):
            fm = add_months(dt.date.fromisoformat(c), mis)
            if fm > ctx.d('2026-11-01'):
                break
            cum += sum(e['QTY'] for e in core if e['DATA_TYPE'] == 'FIELD' and e['CUSTOMER_CODE'] == 'HMC' and e['VEHICLE_CODE'] == 'HE1'
                       and e['SALES_MONTH'] == c and e['MIS'] == mis)
            pts.append({'mis': mis, 'cumulativeClaims': cum, 'soldVehicles': s, 'cumR1000': round(cum / s * 1000, 4) if s else None})
        mis_curve[c] = pts
    be1 = {k[2]: v for k, v in ppm.items() if k[0] == 'BMW' and k[1] == '63117-BE1L'}
    series = [be1[m] for m in sorted(be1)]
    hits = []
    if len(series) >= 4:
        last4 = [x['ppm'] for x in series[-4:]]
        if all(last4[i] > last4[i - 1] for i in range(1, 4)):
            hits.append({'ruleCode': 'DEMO-0KM-CONSEC3', 'ruleType': 'CONSECUTIVE_INCREASE', 'dataType': 'LINE_0KM', 'metric': 'PPM',
                         'customerCode': 'BMW', 'itemNo': '63117-BE1L', 'periodStart': sorted(be1)[-1], 'value': last4[-1],
                         'baseline': last4[0], 'alertKey': sha256('DEMO-0KM-CONSEC3', 'BMW', 'BE1', '63117-BE1L', '')})
    he1_mis3 = {c: next((p['cumR1000'] for p in pts if p['mis'] == 3), None) for c, pts in mis_curve.items()}
    for c, v in he1_mis3.items():
        if v is not None and v > 0.8:
            hits.append({'ruleCode': 'DEMO-FIELD-MIS3', 'ruleType': 'MIS_LIMIT', 'dataType': 'FIELD', 'metric': 'R1000', 'customerCode': 'HMC',
                         'vehicleCode': 'HE1', 'itemNo': '92101-HE1L', 'cohort': c, 'misPoint': 3, 'value': v, 'threshold': 0.8,
                         'alertKey': sha256('DEMO-FIELD-MIS3', 'HMC', 'HE1', '92101-HE1L', c)})
    exp = {'ppmMonthly': {f'{k[0]}|{k[1]}|{k[2]}': v for k, v in sorted(ppm.items())},
           'BMW_BE1L_ppm': {m: v['ppm'] for m, v in sorted(be1.items())},
           'HMC_HE1_misCurve': mis_curve, 'demoRules': [
               {'ruleCode': 'DEMO-0KM-CONSEC3', 'type': 'CONSECUTIVE_INCREASE', 'dataType': 'LINE_0KM', 'grain': 'CUSTOMER,ITEM', 'consecutiveN': 3},
               {'ruleCode': 'DEMO-FIELD-MIS3', 'type': 'MIS_LIMIT', 'dataType': 'FIELD', 'grain': 'CUSTOMER,VEHICLE,ITEM', 'misPoint': 3, 'misLimitR1000': 0.8}],
           'alerts': hits, 'eventCounts': {t: sum(1 for e in core if e['DATA_TYPE'] == t) for t in ('LINE_0KM', 'FIELD', 'RETURN')},
           'unmappedDefectEvents': sum(1 for e in core if e['DEFECT_MAP_STATUS'] == 'UNMAPPED'),
           'note': 'BE1L은 출하 공장이 2곳(KR01·PL01)이라 PLANT_CODE NULL(B2B-001 BR-3). 규칙 값은 데모 가정(B2B-004 초기 규칙은 비활성 제공).'}
    write_json('expected/b2b_S10.json', exp)
    ctx.b2b_expected = exp
    as_of = ctx.loaded_at
    tcols = [('periodStart', 'DATE', None), ('dataType', 'STRING', None), ('customerCode', 'STRING', None), ('eventCount', 'INTEGER', None),
             ('qty', 'NUMBER', None), ('denominator', 'NUMBER', None), ('ppm', 'NUMBER', 'PPM'), ('r1000', 'NUMBER', 'R1000'), ('target', 'NUMBER', 'PPM')]
    rows = [[m, 'LINE_0KM', 'BMW', v['qty'], v['qty'], v['shipped'], v['ppm'], None, PPM_TARGET['BMW']] for m, v in sorted(be1.items())[-13:]]
    write_mock(ctx, 'QMS_B2B_TREND', 'ok', envelope('QMS_B2B_TREND', {'customerCodes': ['BMW'], 'itemNos': ['63117-BE1L'], 'dataTypes': ['LINE_0KM'],
                                                                     'periodType': 'MONTH', 'from': rows[0][0], 'to': rows[-1][0], 'plantCodes': ['KR01', 'PL01']},
                                                    tcols, rows, as_of=as_of, scope='KR01, PL01'))
    pcols = [('defectTypeCode', 'STRING', None), ('defectTypeName', 'STRING', None), ('eventCount', 'INTEGER', None), ('qty', 'NUMBER', None),
             ('pct', 'NUMBER', '%'), ('cumulativePct', 'NUMBER', '%')]
    agg = {}
    for e in core:
        if e['CUSTOMER_CODE'] == 'BMW' and e['DATA_TYPE'] == 'LINE_0KM' and e['EVENT_DATE'] >= ctx.d('2026-06-01').isoformat():
            k = e['DEFECT_TYPE_CODE'] or 'UNMAPPED'
            a = agg.setdefault(k, [0, 0])
            a[0] += 1
            a[1] += e['QTY']
    tot = sum(v[1] for v in agg.values()) or 1
    prow, cum = [], 0
    for k, v in sorted(agg.items(), key=lambda kv: -kv[1][1]):
        cum += v[1]
        prow.append([k, k.split('/')[-1], v[0], v[1], round(100 * v[1] / tot, 2), round(100 * cum / tot, 2)])
    write_mock(ctx, 'QMS_B2B_PARETO', 'ok', envelope('QMS_B2B_PARETO', {'customerCodes': ['BMW'], 'dataTypes': ['LINE_0KM'], 'from': '2026-06-01', 'to': '2026-11-30', 'plantCodes': ['KR01', 'PL01']},
                                                     pcols, prow, as_of=as_of, scope='KR01, PL01'))
    mcols = [('cohortMonth', 'DATE', None), ('mis', 'INTEGER', None), ('cumulativeClaims', 'INTEGER', None), ('soldVehicles', 'NUMBER', None),
             ('cumR1000', 'NUMBER', 'R1000')]
    mrows = [[c, p['mis'], p['cumulativeClaims'], p['soldVehicles'], p['cumR1000']] for c, pts in sorted(mis_curve.items()) for p in pts]
    write_mock(ctx, 'QMS_B2B_MIS_CURVE', 'ok', envelope('QMS_B2B_MIS_CURVE', {'customerCodes': ['HMC'], 'vehicleCodes': ['HE1'], 'itemNos': ['92101-HE1L'],
                                                                             'cohortFrom': '2026-05', 'cohortTo': '2026-09', 'plantCodes': ['KR01']},
                                                        mcols, mrows, as_of=as_of))
    # 상위 품번(0km, 이번 달 vs 전월)
    cur_m, prev_m = ctx.d('2026-11-01').isoformat()[:7], ctx.d('2026-10-01').isoformat()[:7]
    qty = {}
    for e in core:
        if e['DATA_TYPE'] == 'LINE_0KM' and e['EVENT_DATE'][:7] in (cur_m, prev_m):
            q = qty.setdefault(e['ITEM_NO'], [0, 0])
            q[0 if e['EVENT_DATE'][:7] == cur_m else 1] += e['QTY']
    trows = [[it, ctx.items[it]['name'], c, p, round(100 * (c - p) / p, 2) if p else None]
             for it, (c, p) in sorted(qty.items(), key=lambda kv: (-kv[1][0], kv[0]))][:20]
    write_mock(ctx, 'QMS_B2B_TOP_ITEMS', 'ok', envelope('QMS_B2B_TOP_ITEMS', {'customerCodes': [], 'dataTypes': ['LINE_0KM'], 'periodType': 'MONTH',
                                                                             'periodStart': ctx.d('2026-11-01').isoformat(), 'plantCodes': ['KR01', 'KR02', 'CN01', 'US01', 'PL01']},
                                                        [('itemNo', 'STRING', None), ('itemName', 'STRING', None), ('currentQty', 'NUMBER', None),
                                                         ('previousQty', 'NUMBER', None), ('changePct', 'NUMBER', '%')], trows, as_of=as_of, scope='ALL'))
    # 건별 목록(BMW BE1L 0km 2026-09~11, includeCost=false → 비용 열 NULL)
    dcols = [('eventDate', 'DATE', None), ('customerRefNo', 'STRING', None), ('vehicleCode', 'STRING', None), ('itemNo', 'STRING', None),
             ('defectTypeCode', 'STRING', None), ('customerDefectText', 'STRING', None), ('mis', 'INTEGER', None), ('mileageKm', 'NUMBER', 'km'),
             ('country', 'STRING', None), ('costKrw', 'NUMBER', 'KRW'), ('customerJudgment', 'STRING', None), ('claimNo', 'STRING', None)]
    drows = [[e['EVENT_DATE'], e['CUSTOMER_REF_NO'], e['VEHICLE_CODE'], e['ITEM_NO'], e['DEFECT_TYPE_CODE'], e['CUSTOMER_DEFECT_TEXT'], e['MIS'],
              e['MILEAGE_KM'], e['COUNTRY'], None, e['CUSTOMER_JUDGMENT'], None]
             for e in sorted(core, key=lambda x: (x['EVENT_DATE'], x['CUSTOMER_REF_NO']), reverse=True)
             if e['CUSTOMER_CODE'] == 'BMW' and e['ITEM_NO'] == '63117-BE1L' and e['DATA_TYPE'] == 'LINE_0KM'
             and e['EVENT_DATE'] >= ctx.d('2026-09-01').isoformat()]
    write_mock(ctx, 'QMS_B2B_DETAIL', 'ok', envelope('QMS_B2B_DETAIL', {'customerCodes': ['BMW'], 'itemNos': ['63117-BE1L'], 'dataTypes': ['LINE_0KM'],
                                                                       'from': ctx.d('2026-09-01').isoformat(), 'to': ctx.d('2026-11-30').isoformat(),
                                                                       'includeCost': False, 'plantCodes': ['KR01', 'PL01']},
                                                     dcols, drows, as_of=as_of, scope='KR01, PL01'))
    # 고객·유형별 마지막 적재
    last = {}
    for e in core:
        k = (e['CUSTOMER_CODE'], e['DATA_TYPE'])
        b = last.setdefault(k, [None, 0])
        b[0] = max(b[0] or '', e['EVENT_DATE'])
        b[1] += 1
    write_mock(ctx, 'QMS_B2B_LAST_LOADED', 'ok', envelope('QMS_B2B_LAST_LOADED', {'customerCodes': []},
                                                          [('customerCode', 'STRING', None), ('dataType', 'STRING', None), ('lastLoadedAt', 'DATETIME', None),
                                                           ('lastEventDate', 'DATE', None), ('rowCount', 'INTEGER', None)],
                                                          [[k[0], k[1], ctx.loaded_at, v[0], v[1]] for k, v in sorted(last.items())], as_of=as_of, scope=None))


# ============================================================== 파생(Salesforce CSV 있을 때)

def read_csv(path):
    with open(path, encoding='utf-8') as f:
        return list(csv.DictReader(f))


def read_sf_merged(obj, key):
    """같은 객체의 Salesforce CSV(1차 적재 + 2차 갱신 파일)를 키로 합친다. 뒤 파일의 빈 값은 앞 값을 지우지 않는다."""
    files = sorted(f for f in glob.glob(os.path.join(ROOT, 'salesforce', f'*{obj}*.csv')) if os.path.basename(f).split('_', 1)[1].startswith(obj))
    merged = {}
    for path in files:
        for row in read_csv(path):
            if row.get(key):
                tgt = merged.setdefault(row[key], {})
                tgt.update({k: v for k, v in row.items() if v not in (None, '')})
    return list(merged.values())


def levels(path, n=3):
    """코드 경로 'GROUP/L1/L2/L3' → [L1, L2, L3](없으면 None)."""
    parts = (path or '').split('/')[1:]
    return (parts + [None] * n)[:n]


def local_date(ctx, ts, plant):
    """UTC ISO 시각 → 공장 현지 날짜(YYYY-MM-DD). 날짜만 있으면 그대로."""
    if not ts:
        return None
    if len(ts) <= 10:
        return ts
    t = dt.datetime.strptime(ts[:19], '%Y-%m-%dT%H:%M:%S').replace(tzinfo=UTC)
    return t.astimezone(ctx.tz.get(plant, UTC)).date().isoformat()


def gen_derived(ctx):
    done = []
    lot_rows, res_rows = read_sf_merged('QMS_IqcLot__c', 'ExternalKey__c'), read_sf_merged('QMS_IqcResult__c', 'ExternalKey__c')
    keys_f = os.path.join(ROOT, 'expected', 'scenario_keys.json')
    if lot_rows and res_rows:
        lots = {l['ExternalKey__c']: l for l in lot_rows}
        rows = []
        for rs in res_rows:
            lot = lots.get(rs.get('Lot__r.ExternalKey__c'))
            if not lot:
                continue
            try:
                samples = json.loads(rs.get('SampleValuesJson__c') or '[]')
            except json.JSONDecodeError:
                samples = []
            char_ext = rs.get('Characteristic__r.ExternalKey__c') or None
            for smp in samples:
                rows.append({'SOURCE': 'IQC', 'LOT_ID': lot['RecordNo__c'], 'LOT_NO': lot['RecordNo__c'], 'RESULT_ID': rs['ExternalKey__c'],
                             'PLANT_CODE': lot.get('Plant__r.PlantCode__c'), 'ITEM_NO': lot.get('Item__r.ItemNo__c'),
                             'VENDOR_NO': lot.get('Supplier__r.SapVendorNo__c'), 'CHAR_ID': char_ext,
                             'CHAR_NO': char_ext.split('-')[-2] if char_ext else None,
                             'SPECIAL_CLASS': rs.get('SpecialClass__c') or None, 'SAMPLE_NO': smp.get('no'), 'VALUE': smp.get('value'),
                             'IS_OK': smp.get('ok'), 'LSL': rs.get('LSL__c') or None, 'USL': rs.get('USL__c') or None,
                             'GAUGE_NO': rs.get('GaugeNo__c') or None,
                             'INSPECTED_AT': lot.get('DecidedAt__c') or lot.get('GrDate__c') or None})
        ctx.snow('CORE.INSPECTION_RESULT', rows)
        ctx.insp_rows = rows
        done.append('CORE.INSPECTION_RESULT')
        gauge_s12(ctx, rows)
    ncr = read_sf_merged('QMS_NCR__c', 'RecordNo__c')
    if ncr:
        op_type = {(ln['plant'], ln['line'], o['op']): o['type'] for ln in ctx.m['lines'] for o in ln['operations']}
        rows = []
        for n in ncr:
            plant = n.get('Plant__r.PlantCode__c') or None
            item = ctx.items.get(n.get('Item__r.ItemNo__c') or '', {})
            op_key = (n.get('Operation__r.ExternalKey__c') or '').split('-')
            dl = levels(n.get('DefectType__r.ExternalKey__c'))
            cl = levels(n.get('RootCause__r.ExternalKey__c'))
            ch = n.get('Characteristic__r.ExternalKey__c') or None
            rows.append({'NCR_ID': n['RecordNo__c'], 'RECORD_NO': n['RecordNo__c'], 'RECORD_TYPE': n.get('RecordTypeDeveloperName') or None,
                         'PLANT_CODE': plant, 'LINE_CODE': (n.get('Line__r.ExternalKey__c') or '').split('-')[-1] or None,
                         'OPERATION_TYPE': op_type.get(tuple(op_key)) if len(op_key) == 3 else None, 'ITEM_NO': item.get('itemNo'),
                         'PART_CATEGORY': item.get('partCategory'), 'PRODUCT_GROUP': item.get('group'),
                         'RESP_VENDOR_NO': n.get('Supplier__r.SapVendorNo__c') or None, 'SUPPLIER_ITEM_ID': n.get('SupplierItem__r.ExternalKey__c') or None,
                         'CUSTOMER_CODE': n.get('Customer__r.OemCode__c') or None, 'SOURCE_TYPE': n.get('SourceType__c') or None,
                         'SOURCE_RECORD_ID': n.get('SourceRecordNo__c') or None, 'EIGHT_D_ID': n.get('EightD__r.RecordNo__c') or None,
                         'DEFECT_TYPE_L1': dl[0], 'DEFECT_TYPE_L2': dl[1], 'DEFECT_TYPE_L3': dl[2], 'DEFECT_LOCATION': n.get('DefectLocation__c') or None,
                         'CAUSE_L1': cl[0], 'CAUSE_L2': cl[1], 'CAUSE_L3': cl[2],
                         'RESPONSIBILITY': (n.get('Responsibility__r.ExternalKey__c') or '').split('/')[-1] or None,
                         'SEVERITY': n.get('Severity__c') or None,
                         'SPECIAL_CLASS': ctx.chars.get((ch.rsplit('-', 2)[0], ch.rsplit('-', 2)[1]), {}).get('special') if ch else None,
                         'SUSPECT_QTY': n.get('SuspectQty__c') or None, 'DEFECT_QTY': n.get('DefectQty__c') or None,
                         'DEFECT_CONFIRMED_DATE': local_date(ctx, n.get('DefectQtyConfirmedAt__c'), plant),
                         'IS_REPEAT': (n.get('IsRepeat__c') or 'false') == 'true',
                         'UNAUTHORIZED_CHANGE': (n.get('UnauthorizedChange__c') or 'false') == 'true',
                         'CUSTOMER_IMPACT': (n.get('CustomerImpact__c') or 'false') == 'true',
                         'COUNTERMEASURE_TYPE': n.get('CountermeasureType__c') or None, 'VERIFICATION_RESULT': n.get('VerificationResult__c') or None,
                         'STATUS': n.get('Status__c') or None, 'DETECTED_DATE': local_date(ctx, n.get('DetectedAt__c'), plant),
                         'CLOSED_DATE': local_date(ctx, n.get('ClosedAt__c'), plant), 'COUNTERMEASURE_DUE': n.get('CountermeasureDueDate__c') or None,
                         'TOTAL_COST_KRW': None, '_IS_DELETED': False})
        ctx.snow('CORE.NCR_DEFECT', rows)
        ctx.ncr_rows = rows
        done.append('CORE.NCR_DEFECT')
    fm = read_sf_merged('QMS_FourMChange__c', 'RecordNo__c')
    if fm:
        rows = []
        for f in fm:
            plant = f.get('Plant__r.PlantCode__c') or None
            tl = levels(f.get('PrimaryChangeType__r.ExternalKey__c'))
            rows.append({'FOURM_ID': f['RecordNo__c'], 'RECORD_NO': f['RecordNo__c'], 'RECORD_TYPE': f.get('RecordTypeDeveloperName') or None,
                         'PLANT_CODE': plant, 'VENDOR_NO': f.get('Supplier__r.SapVendorNo__c') or None,
                         'CHANGE_TYPE_L1': tl[0], 'CHANGE_TYPE_L2': tl[1], 'CHANGE_TYPE_L3': tl[2], 'RISK_CLASS': f.get('RiskClass__c') or None,
                         'REQUESTED_DATE': (f.get('RequestedDate__c') or '')[:10] or None,
                         'PLANNED_APPLY_DATE': (f.get('PlannedApplyDate__c') or '')[:10] or None,
                         'APPLIED_AT': f.get('AppliedAt__c') or None, 'CLOSED_AT': f.get('ClosedAt__c') or None,
                         'LEAD_COMPLIANT': (f.get('LeadCompliant__c') or 'false') == 'true',
                         'UNAUTHORIZED': (f.get('Unauthorized__c') or 'false') == 'true', 'STATUS': f.get('Status__c') or None,
                         '_IS_DELETED': False})
        ctx.snow('CORE.FOURM_CHANGE', rows)
        ctx.fourm_rows = rows
        done.append('CORE.FOURM_CHANGE')
    ctx.derived = done
    ctx.scenario_keys_present = os.path.exists(keys_f)
    if not lot_rows:
        ctx.notes.append('Salesforce 수입검사 CSV 없음 → CORE.INSPECTION_RESULT, expected/gauge_S12_dwh.json, QMS_GAU_IMPACT_RESULTS 목 미생성')


def gauge_s12(ctx, rows):
    """S12: GA-KR01-0456 마지막 합격 교정(2025-11-20) 이후 ~ 불합격 교정(2026-11-20) 사이 이 측정기로 판정한 수입검사 로트.
    위험: 진값 추정 = 측정값 − As-found 오차(+0.05mm)가 규격 밖인 시료가 있으면 HIGH(expected/gauge_S12.json과 같은 판정식).
    minMargin = 진값 추정에서 규격 한계까지 최소 거리(특성 단위, 음수면 규격 밖)."""
    g0, g1 = ctx.d('2025-11-20').isoformat(), ctx.d('2026-11-20').isoformat()
    as_found = 0.05
    sel = [r for r in rows if r['GAUGE_NO'] == 'GA-KR01-0456' and g0 <= (r['INSPECTED_AT'] or '')[:10] <= g1]
    lots = {}
    for r in sel:
        lots.setdefault((r['LOT_NO'], r['ITEM_NO'], r['CHAR_NO']), []).append(r)
    out = []
    for (lot, item, chno), rs in sorted(lots.items()):
        usl = float(rs[0]['USL']) if rs[0]['USL'] not in (None, '') else None
        lsl = float(rs[0]['LSL']) if rs[0]['LSL'] not in (None, '') else None
        vals = [float(x['VALUE']) for x in rs if x['VALUE'] not in (None, '')]
        true_vals = [v - as_found for v in vals]
        margins = [min(m for m in ((usl - v) if usl is not None else None, (v - lsl) if lsl is not None else None) if m is not None)
                   for v in true_vals if usl is not None or lsl is not None]
        mm = min(margins) if margins else None
        out.append({'source': 'IQC', 'lotId': lot, 'lotNo': lot, 'itemNo': item, 'charNo': chno,
                    'inspectedAt': max(x['INSPECTED_AT'] for x in rs), 'sampleCount': len(vals),
                    'minMargin': round(mm, 6) if mm is not None else None,
                    'riskLevel': 'HIGH' if (mm is not None and mm < 0) else 'LOW'})
    exp = {'gaugeNo': 'GA-KR01-0456', 'from': g0, 'to': g1, 'asFoundError': as_found,
           'method': '진값 추정 = 측정값 − As-found 오차. 진값이 규격 밖(minMargin < 0)인 시료가 있으면 HIGH', 'lots': out,
           'lotCount': len(out), 'highRiskLots': sum(1 for x in out if x['riskLevel'] == 'HIGH')}
    # expected/gauge_S12.json은 Salesforce 데이터 작업 소유 → DWH 측 계산은 별도 파일
    write_json('expected/gauge_S12_dwh.json', exp)
    cols = [('source', 'STRING', None), ('lotId', 'STRING', None), ('lotNo', 'STRING', None), ('itemNo', 'STRING', None), ('charNo', 'STRING', None),
            ('inspectedAt', 'DATETIME', None), ('sampleCount', 'INTEGER', None), ('minMargin', 'NUMBER', 'mm'), ('riskLevel', 'STRING', None)]
    write_mock(ctx, 'QMS_GAU_IMPACT_RESULTS', 'ok', envelope('QMS_GAU_IMPACT_RESULTS', {'gaugeNo': 'GA-KR01-0456', 'fromDate': g0, 'toDate': g1,
                                                                                       'asFoundError': as_found, 'plantCodes': ['KR01']},
                                                             cols, [[x[c[0]] for c in cols] for x in out], as_of=ctx.loaded_at))
    ctx.gauge_expected = exp


def derived_kpis_and_mocks(ctx):
    """Salesforce CSV에서 파생한 CORE 테이블로 IQC·NCR·4M KPI와 조회 목을 만든다."""
    m13 = add_months(ctx.d('2026-11-01'), -12)
    lots = read_sf_merged('QMS_IqcLot__c', 'ExternalKey__c')
    if lots:
        agg = {}
        for l in lots:
            if l.get('Status__c') != 'DECIDED' or not l.get('GrDate__c'):
                continue
            plant = l.get('Plant__r.PlantCode__c')
            m = month_start(dt.date.fromisoformat(local_date(ctx, l['GrDate__c'], plant))).isoformat()
            if m < m13.isoformat():
                continue
            b = agg.setdefault((m, plant, l.get('Supplier__r.SapVendorNo__c')), [0, 0])
            b[0] += 1
            b[1] += 1 if l.get('Decision__c') == 'ACCEPT' else 0
        for (m, plant, v), (n, ok) in sorted(agg.items()):
            dims = {'plant': plant, 'supplier': v}
            kpi_row(ctx, 'QMS_IQC_LOTS', 'MONTH', m, n, 'CNT', dims)
            lar = 100.0 * ok / n
            kpi_row(ctx, 'QMS_IQC_LAR', 'MONTH', m, lar, 'PCT', dims, None, rag_th(lar, 'UP', 98, 95))
        lcols = [('lotNo', 'STRING', None), ('grDate', 'DATE', None), ('decision', 'STRING', None), ('inspectionLevel', 'STRING', None),
                 ('coaStatus', 'STRING', None), ('ngCount', 'INTEGER', None), ('rejectQty', 'NUMBER', None)]
        sel = sorted((l for l in lots if l.get('Supplier__r.SapVendorNo__c') == 'V10002' and l.get('Item__r.ItemNo__c') == 'P-HSG-BE1'
                      and l.get('Plant__r.PlantCode__c') == 'KR01' and (l.get('GrDate__c') or '') >= ctx.d('2026-06-01').isoformat()),
                     key=lambda l: l['GrDate__c'], reverse=True)
        params = {'vendorNo': 'V10002', 'itemNo': 'P-HSG-BE1', 'fromDate': ctx.d('2026-06-01').isoformat(), 'toDate': ctx.d('2026-11-30').isoformat(),
                  'plantCodes': ['KR01']}
        write_mock(ctx, 'QMS_IQC_LOT_DETAIL', 'ok', envelope('QMS_IQC_LOT_DETAIL', params, lcols,
                                                             [[l['RecordNo__c'], local_date(ctx, l['GrDate__c'], 'KR01'), l.get('Decision__c'),
                                                               l.get('InspectionLevel__c'), l.get('CoaStatus__c'), int(l['NgResultCount__c']) if l.get('NgResultCount__c') else None,
                                                               float(l['RejectQty__c']) if l.get('RejectQty__c') else None] for l in sel], as_of=ctx.loaded_at))
        write_mock(ctx, 'QMS_IQC_LOT_DETAIL', 'empty', envelope('QMS_IQC_LOT_DETAIL', dict(params, vendorNo='V10004', itemNo='P-HSG-BE1'), lcols, [],
                                                                as_of=ctx.loaded_at))
    insp = getattr(ctx, 'insp_rows', None)
    if insp:
        use = {}
        for r in insp:
            if r['GAUGE_NO'] and r['CHAR_ID']:
                b = use.setdefault((r['CHAR_ID'], r['CHAR_NO'], r['GAUGE_NO']), [0, ''])
                b[0] += 1
                b[1] = max(b[1], r['INSPECTED_AT'] or '')
        write_mock(ctx, 'QMS_MSA_GAUGE_USAGE', 'ok', envelope('QMS_MSA_GAUGE_USAGE', {'plantCodes': ['KR01'], 'fromDate': ctx.d('2026-06-01').isoformat()},
                                                              [('charId', 'STRING', None), ('charNo', 'STRING', None), ('gaugeNo', 'STRING', None),
                                                               ('measureCount', 'INTEGER', None), ('lastMeasuredAt', 'DATETIME', None)],
                                                              [[k[0], k[1], k[2], v[0], v[1]] for k, v in sorted(use.items(), key=lambda kv: -kv[1][0])],
                                                              as_of=ctx.loaded_at))
    ncr = getattr(ctx, 'ncr_rows', None)
    if ncr:
        opened, dqty, closed = {}, {}, {}
        for r in ncr:
            if r['DETECTED_DATE']:
                k = (month_start(dt.date.fromisoformat(r['DETECTED_DATE'])).isoformat(), r['PLANT_CODE'])
                opened[k] = opened.get(k, 0) + 1
            if r['DEFECT_CONFIRMED_DATE'] and r['DEFECT_QTY']:
                k = (month_start(dt.date.fromisoformat(r['DEFECT_CONFIRMED_DATE'])).isoformat(), r['PLANT_CODE'])
                dqty[k] = dqty.get(k, 0) + float(r['DEFECT_QTY'])
            if r['CLOSED_DATE']:
                k = (month_start(dt.date.fromisoformat(r['CLOSED_DATE'])).isoformat(), r['PLANT_CODE'])
                closed[k] = closed.get(k, 0) + 1
        for (m, plant), v in sorted(opened.items()):
            if m >= m13.isoformat():
                kpi_row(ctx, 'QMS_NCR_OPENED', 'MONTH', m, v, 'CNT', {'plant': plant})
        for (m, plant), v in sorted(dqty.items()):
            if m >= m13.isoformat():
                kpi_row(ctx, 'QMS_NCR_DEFECT_QTY', 'MONTH', m, v, 'CNT', {'plant': plant})
        # 파레토(최근 6개월, 불량 유형 L2)
        p6 = ctx.d('2026-06-01').isoformat()
        par = {}
        for r in ncr:
            if (r['DETECTED_DATE'] or '') >= p6 and r['DEFECT_TYPE_L2']:
                b = par.setdefault(r['DEFECT_TYPE_L2'], [0, 0.0])
                b[0] += 1
                b[1] += float(r['DEFECT_QTY'] or 0)
        names = {f"{l1['code']}/{l2['code']}": l2['name'] for l1 in ctx.m['codes']['DEFECT_TYPE'] for l2 in l1.get('children', [])}
        l1_of = {l2['code']: l1['code'] for l1 in ctx.m['codes']['DEFECT_TYPE'] for l2 in l1.get('children', [])}
        tot = sum(v[0] for v in par.values()) or 1
        prow, cum = [], 0
        for k, (cnt, q) in sorted(par.items(), key=lambda kv: (-kv[1][0], kv[0])):
            cum += cnt
            prow.append([k, names.get(f'{l1_of.get(k)}/{k}', k), cnt, q, round(100 * cum / tot, 2)])
        write_mock(ctx, 'QMS_NCR_PARETO', 'ok', envelope('QMS_NCR_PARETO', {'plantCodes': sorted(ctx.plants), 'fromDate': p6,
                                                                           'toDate': ctx.d('2026-11-30').isoformat()},
                                                         [('defectTypeL2Code', 'STRING', None), ('defectTypeL2', 'STRING', None), ('ncrCount', 'INTEGER', None),
                                                          ('defectQty', 'NUMBER', None), ('cumulativePct', 'NUMBER', '%')], prow, as_of=ctx.loaded_at, scope='ALL'))
        trows, m = [], m13
        while m <= ctx.d('2026-11-01'):
            ms = m.isoformat()
            me = add_months(m, 1).isoformat()
            op = sum(1 for r in ncr if ms <= (r['DETECTED_DATE'] or '') < me)
            cl = sum(1 for r in ncr if ms <= (r['CLOSED_DATE'] or '') < me)
            open_end = sum(1 for r in ncr if (r['DETECTED_DATE'] or '9') < me and not ((r['CLOSED_DATE'] or '9') < me))
            trows.append([ms, op, cl, open_end])
            m = add_months(m, 1)
        write_mock(ctx, 'QMS_NCR_TREND', 'ok', envelope('QMS_NCR_TREND', {'plantCodes': sorted(ctx.plants), 'fromMonth': m13.isoformat()[:7],
                                                                         'toMonth': ctx.d('2026-11-01').isoformat()[:7]},
                                                        [('month', 'DATE', None), ('opened', 'INTEGER', None), ('closed', 'INTEGER', None),
                                                         ('openEnd', 'INTEGER', None)], trows, as_of=ctx.loaded_at, scope='ALL'))
    fm = getattr(ctx, 'fourm_rows', None)
    if fm:
        agg = {}
        for r in fm:
            if not r['REQUESTED_DATE'] or r['REQUESTED_DATE'] < m13.isoformat():
                continue
            k = (month_start(dt.date.fromisoformat(r['REQUESTED_DATE'])).isoformat(), r['PLANT_CODE'], r['VENDOR_NO'])
            b = agg.setdefault(k, [0, 0])
            b[0] += 1
            b[1] += 1 if r['UNAUTHORIZED'] else 0
        for (m, plant, v), (n, un) in sorted(agg.items()):
            dims = {'plant': plant, 'supplier': v}
            kpi_row(ctx, 'QMS_4M_OPENED', 'MONTH', m, n, 'CNT', dims)
            kpi_row(ctx, 'QMS_4M_UNAUTHORIZED', 'MONTH', m, un, 'CNT', dims, None, 'GREEN' if un == 0 else ('AMBER' if un <= 1 else 'RED'))


# ============================================================== KPI

def kpi_row(ctx, key, ptype, pstart, value, unit, dims, target=None, rag=None):
    dk = '|'.join(f'{k}={v}' for k, v in sorted(dims.items()) if v)
    row = {'ExternalKey__c': sha1(key, ptype, pstart, dk), 'KpiKey__c': key, 'PeriodType__c': ptype, 'PeriodStart__c': pstart,
           'Plant__r.PlantCode__c': dims.get('plant'), 'Line__r.ExternalKey__c': dims.get('line'),
           'Item__r.ItemNo__c': dims.get('item'), 'Supplier__r.SapVendorNo__c': dims.get('supplier'),
           'Customer__r.OemCode__c': dims.get('customer'), 'Characteristic__r.ExternalKey__c': dims.get('char'),
           'Vehicle__r.ExternalKey__c': dims.get('vehicle'), 'Value__c': None if value is None else round(value, 6),
           'Target__c': target, 'Unit__c': unit, 'Rag__c': rag}
    ctx.kpis.append(row)


def rag_th(v, direction, g, a):
    if v is None:
        return None
    if direction == 'UP':
        return 'GREEN' if v >= g else ('AMBER' if v >= a else 'RED')
    return 'GREEN' if v <= g else ('AMBER' if v <= a else 'RED')


def gen_kpis(ctx):
    day_from = ctx.d('2026-10-02')
    # SPC
    for plan in SPC_PLANS:
        if not plan.get('_caps'):
            continue
        ch = ctx.chars[(plan['item'], plan['char'])]
        tgt = ch.get('targetCpk') or 1.33
        dims = {'plant': plan['plant'], 'line': f"{plan['plant']}-{plan['line']}", 'item': plan['item'],
                'char': ctx.char_key(plan['item'], plan['char'])}
        for c in plan['_caps']:
            if c['PERIOD_TYPE'] == 'ROLLING_30D' and c['PERIOD_END'] >= day_from.isoformat():
                for k, fld in (('QMS_SPC_CPK', 'CPK'), ('QMS_SPC_PPK', 'PPK')):
                    v = c[fld]
                    kpi_row(ctx, k, 'DAY', c['PERIOD_END'], v, 'RATIO', dims, tgt,
                            None if v is None else ('GREEN' if v >= tgt else 'AMBER' if v >= 1.0 else 'RED'))
            if c['PERIOD_TYPE'] == 'MONTH':
                for k, fld in (('QMS_SPC_CPK', 'CPK'), ('QMS_SPC_PPK', 'PPK')):
                    v = c[fld]
                    kpi_row(ctx, k, 'MONTH', c['PERIOD_START'], v, 'RATIO', dims, tgt,
                            None if v is None else ('GREEN' if v >= tgt else 'AMBER' if v >= 1.0 else 'RED'))
    by_line_day = {}
    for plan in SPC_PLANS:
        for s in plan.get('_sig') or []:
            d = dt.datetime.strptime(s['SUBGROUP_TS'], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=UTC).astimezone(ctx.tz[plan['plant']]).date()
            if d < day_from:
                continue
            k = (plan['plant'], plan['line'], d.isoformat())
            b = by_line_day.setdefault(k, {'OOS': 0, 'OOC': 0})
            b[s['SIGNAL_TYPE']] += 1
    lines = {(p['plant'], p['line']) for p in SPC_PLANS if p.get('_groups')}
    for (pl, ln) in sorted(lines):
        for d in daterange(day_from, ctx.d('2026-11-30')):
            b = by_line_day.get((pl, ln, d.isoformat()), {'OOS': 0, 'OOC': 0})
            dims = {'plant': pl, 'line': f'{pl}-{ln}'}
            kpi_row(ctx, 'QMS_SPC_SIGNALS_OOS', 'DAY', d.isoformat(), b['OOS'], 'CNT', dims, None,
                    'GREEN' if b['OOS'] == 0 else ('AMBER' if b['OOS'] <= 1 else 'RED'))
            kpi_row(ctx, 'QMS_SPC_SIGNALS_OOC', 'DAY', d.isoformat(), b['OOC'], 'CNT', dims, None,
                    'GREEN' if b['OOC'] == 0 else ('AMBER' if b['OOC'] <= 5 else 'RED'))
            below = 0
            for plan in SPC_PLANS:
                if (plan['plant'], plan['line']) != (pl, ln) or not plan.get('_caps'):
                    continue
                c = next((x for x in plan['_caps'] if x['PERIOD_TYPE'] == 'ROLLING_30D' and x['PERIOD_END'] == d.isoformat()), None)
                tgt = ctx.chars[(plan['item'], plan['char'])].get('targetCpk') or 1.33
                if c and c['CPK'] is not None and c['CPK'] < tgt:
                    below += 1
            kpi_row(ctx, 'QMS_SPC_BELOW_TARGET', 'DAY', d.isoformat(), below, 'CNT', dims, None,
                    'GREEN' if below == 0 else ('AMBER' if below <= 2 else 'RED'))
    # OCAP 확인 기한 준수(월, 공장) — 알람 CSV 기준
    alarms = read_csv(os.path.join(ROOT, 'salesforce', '93_QMS_SpcAlarm__c.csv'))
    by_pm = {}
    for a in alarms:
        first = dt.datetime.strptime(a['FirstSignalAt__c'], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=UTC)
        pl = a['Plant__r.PlantCode__c']
        m = month_start(first.astimezone(ctx.tz[pl]).date()).isoformat()
        b = by_pm.setdefault((pl, m), [0, 0])
        b[0] += 1
        b[1] += 1 if a['AckAt__c'] <= a['AckDueAt__c'] else 0
    for (pl, m), (n, ok) in sorted(by_pm.items()):
        v = 100.0 * ok / n
        kpi_row(ctx, 'QMS_SPC_OCAP_ONTIME', 'MONTH', m, v, 'PCT', {'plant': pl}, None, rag_th(v, 'UP', 95, 85))
    # EOL(CN01 KC1L)
    prod_by_day = {}
    for p in ctx.mes_prod_rows:
        if p['PLANT_CODE'] == 'CN01' and p['ITEM_NO'] == '92101-KC1L':
            prod_by_day[p['PROD_DATE']] = prod_by_day.get(p['PROD_DATE'], 0) + p['INPUT_QTY']
    for d, s in sorted(ctx.eol_stats.items()):
        if d < day_from:
            continue
        dims = {'plant': 'CN01', 'line': 'CN01-L01', 'item': '92101-KC1L'}
        fpy = 100.0 * s['fp'] / s['tested']
        failppm = s['finalFail'] / s['tested'] * 1e6
        cov = 100.0 * s['tested'] / max(prod_by_day.get(d.isoformat(), s['tested']), 1)
        kpi_row(ctx, 'QMS_EOL_FPY', 'DAY', d.isoformat(), fpy, 'PCT', dims, None, rag_th(fpy, 'UP', 98, 95))
        kpi_row(ctx, 'QMS_EOL_FAIL_PPM', 'DAY', d.isoformat(), failppm, 'PPM', dims, None, rag_th(failppm, 'DOWN', 100, 300))
        kpi_row(ctx, 'QMS_EOL_COVERAGE', 'DAY', d.isoformat(), min(cov, 100.0), 'PCT', dims, None, rag_th(min(cov, 100.0), 'UP', 100, 99.5))
    # B2B(월, 최근 13개월)
    m13 = add_months(ctx.d('2026-11-01'), -12).isoformat()
    for k, v in ctx.b2b_expected['ppmMonthly'].items():
        oem, item, m = k.split('|')
        if m < m13:
            continue
        tgt = PPM_TARGET[oem]
        dims = {'customer': oem, 'item': item, 'plant': (ctx.items[item]['plants'][0] if len(ctx.items[item]['plants']) == 1 else None)}
        kpi_row(ctx, 'QMS_PPM_CUSTOMER', 'MONTH', m, v['ppm'], 'PPM', dims, tgt, rag_th(v['ppm'], 'DOWN', tgt, tgt * 1.5))
        kpi_row(ctx, 'QMS_CUSTOMER_LINE_DEFECTS', 'MONTH', m, v['qty'], 'CNT', dims)
    sold = {(v['CUSTOMER_CODE'], v['VEHICLE_CODE'], v['MONTH']): v['QTY'] for v in ctx.b2b_vol if v['VOLUME_TYPE'] == 'SOLD'}
    veh_by_code = {(v['customer'], v['code']): k for k, v in ctx.vehicles.items()}
    field = {}
    for e in ctx.b2b_core:
        if e['DATA_TYPE'] == 'FIELD':
            k = (e['CUSTOMER_CODE'], e['VEHICLE_CODE'], e['ITEM_NO'], e['FAILURE_MONTH'])
            field[k] = field.get(k, 0) + e['QTY']
    for (oem, vcode, item, fm), q in sorted(field.items()):
        if fm < m13:
            continue
        park = sum(v for (o, vc, m), v in sold.items() if o == oem and vc == vcode and m <= fm)
        if park:
            kpi_row(ctx, 'QMS_FIELD_R1000', 'MONTH', fm, q / park * 1000, 'R1000',
                    {'customer': oem, 'vehicle': veh_by_code.get((oem, vcode)), 'item': item})
    # MIS 3·12 누적 R/1000(판매 코호트 월 기준, 해당 MIS 시점이 지난 코호트만)
    claims, vmap = {}, {}
    for e in ctx.b2b_core:
        if e['DATA_TYPE'] == 'FIELD':
            claims.setdefault((e['CUSTOMER_CODE'], e['VEHICLE_CODE'], e['SALES_MONTH']), []).append(e)
            vmap[(e['CUSTOMER_CODE'], e['VEHICLE_CODE'])] = e['ITEM_NO']
    for (oem, vcode, cm), s in sorted(sold.items()):
        item = vmap.get((oem, vcode))
        for mis_pt, key in ((3, 'QMS_FIELD_MIS3_R1000'), (12, 'QMS_FIELD_MIS12_R1000')):
            if not s or not item or cm < m13 or add_months(dt.date.fromisoformat(cm), mis_pt) > ctx.d('2026-11-01'):
                continue
            v = sum(e['QTY'] for e in claims.get((oem, vcode, cm), []) if e['MIS'] <= mis_pt) / s * 1000
            kpi_row(ctx, key, 'MONTH', cm, v, 'R1000', {'customer': oem, 'item': item})
    returns = {}
    for e in ctx.b2b_core:
        if e['DATA_TYPE'] == 'RETURN':
            k = (e['CUSTOMER_CODE'], e['ITEM_NO'], e['EVENT_DATE'][:7] + '-01')
            returns[k] = returns.get(k, 0) + 1
    for (oem, item, m), q in sorted(returns.items()):
        if m >= m13:
            kpi_row(ctx, 'QMS_CUSTOMER_RETURNS', 'MONTH', m, q, 'CNT', {'customer': oem, 'item': item})
    # MSA(월, KR01)
    by_m = {}
    for d, verdict in ctx.msa_verdicts:
        by_m.setdefault(month_start(d).isoformat(), []).append(verdict)
    for m, studies in sorted(by_m.items()):
        v = 100.0 * studies.count('ACCEPTABLE') / len(studies)
        kpi_row(ctx, 'QMS_MSA_ACCEPT_RATE', 'MONTH', m, v, 'PCT', {'plant': 'KR01'}, None, rag_th(v, 'UP', 90, 75))
    # 측정기 교정 경과 정지(US01 GA-US01-0101, 기한 2026-11-20)
    for d in daterange(day_from, ctx.d('2026-11-30')):
        for pl in ('KR01', 'CN01', 'US01', 'PL01'):
            v = 1 if (pl == 'US01' and d >= ctx.d('2026-11-21')) else 0
            kpi_row(ctx, 'QMS_GAU_OVERDUE', 'DAY', d.isoformat(), v, 'CNT', {'plant': pl}, None,
                    'GREEN' if v == 0 else ('AMBER' if v <= 3 else 'RED'))
    if ctx.derived:
        derived_kpis_and_mocks(ctx)
    ctx.sf('90_CMN_KpiValue__c', ctx.kpis)
    # 대시보드 정답 요약(S5)
    sel = [k for k in ctx.kpis if (k['PeriodType__c'] == 'MONTH' and k['PeriodStart__c'] == ctx.d('2026-11-01').isoformat())
           or (k['PeriodType__c'] == 'DAY' and k['PeriodStart__c'] == ctx.d('2026-11-30').isoformat())]
    write_csv('expected/kpi_S5.csv', sel)
    ctx.counts['expected/kpi_S5.csv'] = len(sel)


# ============================================================== 신선도·적재 스크립트·문서

def gen_freshness(ctx):
    rows = [{'SOURCE_KEY': k, 'LAST_LOADED_AT': ctx.loaded_at, 'EXPECTED_INTERVAL_MIN': v, 'UPDATED_BY_TASK': 'DEMO_LOAD'}
            for k, v in (('MES_SPC', 5), ('SPC_SUBGROUP', 5), ('SPC_CAPABILITY', 1440), ('MES_PRODUCTION', 60), ('EOL', 60),
                         ('IQC_RESULT', 15), ('CUSTOMER_QUALITY', 1440), ('SF_REPLICA_15MIN', 15), ('SF_REPLICA_DAILY', 1440),
                         ('MSA_RESULT', 1440), ('SAP_STOCK', 60), ('SAP_SHIPMENT', 1440), ('SAP_BOM', 1440))]
    ctx.snow('MART.DATA_FRESHNESS', rows)
    write_mock(ctx, 'QMS_DW_FRESHNESS', 'ok', envelope('QMS_DW_FRESHNESS', {}, [('sourceKey', 'STRING', None), ('lastLoadedAt', 'DATETIME', None),
                                                                              ('expectedIntervalMin', 'INTEGER', None), ('stale', 'BOOLEAN', None)],
                                                       [[r['SOURCE_KEY'], r['LAST_LOADED_AT'], r['EXPECTED_INTERVAL_MIN'], False] for r in rows],
                                                       as_of=ctx.loaded_at, scope=None))


LOAD_ORDER = ['CORE.SPC_CONSTANTS', 'CORE.SPC_RULE_DEF', 'CORE.SPC_MEASUREMENT', 'CORE.SPC_SUBGROUP', 'CORE.SPC_SIGNAL',
              'CORE.SPC_CAPABILITY', 'CORE.MSA_MEASUREMENT', 'ML.MSA_RESULT', 'ML.MSA_CONSTANT', 'CORE.MES_PRODUCTION',
              'CORE.MES_DEFECT', 'CORE.EOL_TEST_RESULT', 'CORE.SAP_SHIPMENT', 'CORE.SAP_FX_RATE', 'CORE.SAP_MATERIAL_PRICE',
              'CORE.SAP_BOM', 'CORE.SAP_BATCH', 'CORE.SAP_STOCK', 'CORE.LOT_TRACE', 'STG.CUSTOMER_QUALITY_STD',
              'CORE.CUSTOMER_QUALITY_EVENT', 'CORE.CUSTOMER_VOLUME', 'CORE.INSPECTION_RESULT', 'CORE.NCR_DEFECT',
              'CORE.FOURM_CHANGE', 'MART.DATA_FRESHNESS']


DB_GUARD = ["-- 대상 DB 확인: SL_QDW_DEMO·SL_QDW_DEV가 아니면 예외로 중단한다(snow sql은 첫 오류에서 멈춘다).",
            "EXECUTE IMMEDIATE $$",
            "DECLARE",
            "  not_demo_db EXCEPTION (-20001, 'ABORT: demo data loads only into SL_QDW_DEMO or SL_QDW_DEV');",
            "BEGIN",
            "  IF (CURRENT_DATABASE() IS NULL OR CURRENT_DATABASE() NOT IN ('SL_QDW_DEMO', 'SL_QDW_DEV')) THEN",
            "    RAISE not_demo_db;",
            "  END IF;",
            "  RETURN 'OK: ' || CURRENT_DATABASE();",
            "END;",
            "$$;",
            "",
            "CREATE FILE FORMAT IF NOT EXISTS RAW.DEMO_CSV TYPE = CSV PARSE_HEADER = TRUE FIELD_OPTIONALLY_ENCLOSED_BY = '\"'",
            "  NULL_IF = ('') EMPTY_FIELD_AS_NULL = TRUE TIMESTAMP_FORMAT = AUTO DATE_FORMAT = AUTO ENCODING = 'UTF8';",
            "CREATE STAGE IF NOT EXISTS RAW.DEMO_STAGE FILE_FORMAT = RAW.DEMO_CSV;",
            ""]


def copy_sql(tables):
    sql = [f"PUT 'file://<% demo_dir %>/{t}.csv' @RAW.DEMO_STAGE/{t}/ OVERWRITE = TRUE AUTO_COMPRESS = TRUE;" for t in tables] + ['']
    for t in tables:
        sql.append(f"TRUNCATE TABLE IF EXISTS {t};")
        sql.append(f"COPY INTO {t} FROM @RAW.DEMO_STAGE/{t}/ FILE_FORMAT = (FORMAT_NAME = RAW.DEMO_CSV) "
                   f"MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE ON_ERROR = ABORT_STATEMENT;")
    return sql


def gen_load_scripts(ctx):
    tables = [t for t in LOAD_ORDER if t in ctx.counts and t != 'CORE.CUSTOMER_QUALITY_EVENT']
    sql = ['-- SL QMS 데모 데이터 적재(gen_snowflake.py 생성). 개발·데모 DB에서만 실행한다.',
           '-- 사용: scripts/demo/load_snowflake.sh <connection> (또는 snow sql -c <connection> -f load_demo.sql -D "demo_dir=<절대 경로>")',
           '-- 대상 테이블은 DWH-001과 각 WI의 schemachange 스크립트로 먼저 만든다. 데모 적재 중 적재 Task는 정지 상태로 둔다.',
           '-- CORE.CUSTOMER_QUALITY_EVENT는 동적 테이블(STG.CUSTOMER_QUALITY_STD에서 갱신)이라 여기서 적재하지 않는다.',
           '-- 동적 테이블이 없는 환경만 load_demo_b2b_core.sql을 추가로 실행한다.',
           ''] + DB_GUARD + copy_sql(tables)
    sql += ['',
            '-- CSV의 JSON 문자열을 VARIANT 객체로 바꾼다(COPY는 문자열 VARIANT로 적재).',
            "UPDATE CORE.EOL_TEST_RESULT SET TEST_ITEMS = PARSE_JSON(TEST_ITEMS::STRING) WHERE TYPEOF(TEST_ITEMS) = 'VARCHAR';",
            "UPDATE ML.MSA_RESULT SET RESULT = PARSE_JSON(RESULT::STRING) WHERE TYPEOF(RESULT) = 'VARCHAR';",
            '',
            '-- PLAN_ID·STUDY_ID의 데모 번호(RecordNo)를 Salesforce Id로 바꾼다. 복제 테이블이 아직 없으면 건너뛴다(Salesforce 적재·복제 후 다시 실행).',
            'EXECUTE IMMEDIATE $$',
            'BEGIN',
            '  UPDATE CORE.SPC_SUBGROUP s SET PLAN_ID = p.ID FROM CORE.SF_QMS_SPCPLAN p WHERE s.PLAN_NO = p.RECORDNO__C AND s.PLAN_ID = s.PLAN_NO;',
            '  UPDATE CORE.SPC_SIGNAL s SET PLAN_ID = p.ID FROM CORE.SF_QMS_SPCPLAN p WHERE s.PLAN_NO = p.RECORDNO__C AND s.PLAN_ID = s.PLAN_NO;',
            '  UPDATE CORE.SPC_CAPABILITY s SET PLAN_ID = p.ID FROM CORE.SF_QMS_SPCPLAN p WHERE s.PLAN_NO = p.RECORDNO__C AND s.PLAN_ID = s.PLAN_NO;',
            '  UPDATE CORE.MSA_MEASUREMENT s SET STUDY_ID = p.ID FROM CORE.SF_QMS_MSASTUDY p WHERE s.STUDY_NO = p.RECORDNO__C AND s.STUDY_ID = s.STUDY_NO;',
            '  UPDATE ML.MSA_RESULT s SET STUDY_ID = p.ID FROM CORE.SF_QMS_MSASTUDY p WHERE s.STUDY_NO = p.RECORDNO__C AND s.STUDY_ID = s.STUDY_NO;',
            "  RETURN 'PLAN_ID/STUDY_ID 치환 완료';",
            'EXCEPTION',
            "  WHEN STATEMENT_ERROR THEN RETURN 'SKIP: CORE.SF_QMS_SPCPLAN/SF_QMS_MSASTUDY 없음 - Salesforce 복제 후 다시 실행';",
            'END;',
            '$$;']
    if 'CORE.CUSTOMER_QUALITY_EVENT' in ctx.counts:
        b2b = ['-- 동적 테이블이 없는 환경 전용: CORE.CUSTOMER_QUALITY_EVENT를 표준화 결과 CSV로 직접 적재한다.', ''] + DB_GUARD + \
              copy_sql(['CORE.CUSTOMER_QUALITY_EVENT'])
        with open(out_path('snowflake', 'load_demo_b2b_core.sql'), 'w', encoding='utf-8') as f:
            f.write('\n'.join(b2b) + '\n')
    with open(out_path('snowflake', 'load_demo.sql'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(sql) + '\n')
    sh = '''#!/usr/bin/env bash
# SL QMS 데모 데이터를 Snowflake 개발·데모 DB에 적재한다(gen_snowflake.py 생성).
# 사용: scripts/demo/load_snowflake.sh <snow-connection-name> [--with-b2b-core]
# 전제: Snowflake CLI(snow) 설치, 연결의 database가 SL_QDW_DEMO 또는 SL_QDW_DEV, 테이블은 schemachange로 생성 완료.
set -euo pipefail
CONN="${1:?연결 이름이 필요합니다(snow connection list)}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DIR="$ROOT/data/demo/snowflake"
DB="$(snow sql -c "$CONN" -q "SELECT CURRENT_DATABASE()" --format json | python3 -c 'import json,sys; print(list(json.load(sys.stdin)[0].values())[0])')"
case "$DB" in
  SL_QDW_DEMO|SL_QDW_DEV) ;;
  *) echo "중단: 데모 데이터는 SL_QDW_DEMO·SL_QDW_DEV에만 적재합니다(현재 $DB)" >&2; exit 2 ;;
esac
snow sql -c "$CONN" -f "$DIR/load_demo.sql" -D "demo_dir=$DIR"
if [ "${2:-}" = "--with-b2b-core" ]; then
  # CORE.CUSTOMER_QUALITY_EVENT 동적 테이블이 없는 환경만
  snow sql -c "$CONN" -f "$DIR/load_demo_b2b_core.sql" -D "demo_dir=$DIR"
fi
echo "적재 완료: $DB"
'''
    p = os.path.abspath(os.path.join(ROOT, '..', '..', 'scripts', 'demo', 'load_snowflake.sh'))
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(sh)
    os.chmod(p, 0o755)
    plan = [{'order': o, 'file': f'{n}.csv', 'object': n.split('_', 1)[1], 'externalId': ext}
            for o, n, ext in ((90, '90_CMN_KpiValue__c', 'ExternalKey__c'), (91, '91_QMS_SpcPlan__c', 'RecordNo__c'),
                              (92, '92_QMS_SpcLimit__c', 'ExternalKey__c'), (92.5, '92u_QMS_SpcPlan__c', 'RecordNo__c'),
                              (93, '93_QMS_SpcAlarm__c', 'RecordNo__c'), (94, '94_QMS_MsaStudy__c', 'RecordNo__c'),
                              (95, '95_QMS_MsaAppraiser__c', 'ExternalKey__c'), (96, '96_QMS_CustomerDefectMap__c', 'ExternalKey__c'),
                              (97, '97_QMS_CustomerPartMap__c', 'ExternalKey__c'))]
    write_json('salesforce/load-plan.snowflake.json', {'note': 'Snowflake 데이터 작업 소유 CSV. load-plan.json에 합쳐 Salesforce 기준정보(사용자·특성·측정기·코드) 다음에 적재한다. 92u는 92 적재 후 계획의 CurrentLimit 갱신.',
                                                       'files': plan})


def write_docs(ctx):
    cr = ['# Snowflake 데모 데이터 작업에서 나온 WI 변경 요청', '',
          '데모 데이터(gen_snowflake.py)를 만들면서 찾은 명세 누락·불일치다. 조정자가 data/demo/wi-change-requests.md에 합친다.', '',
          '| 대상 WI | 내용 | 데모에서 쓴 임시 값 |', '| --- | --- | --- |']
    cr += [f'| {a} | {b} | {c} |' for a, b, c in ctx.change_requests]
    with open(out_path('wi-change-requests-snowflake.md'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(cr) + '\n')
    counts = '\n'.join(f'| {k} | {v} |' for k, v in sorted(ctx.counts.items()) if not isinstance(v, list))
    by_key = {}
    for m in ctx.counts.get('mocks', []):
        k, case = m.split('/')
        by_key.setdefault(k, []).append(case)
    mock_list = '\n'.join(f'- {k}: {", ".join(sorted(v))}' for k, v in sorted(by_key.items()))
    readme = f'''# Snowflake 데모 데이터(gen_snowflake.py)

생성: `python3 data/demo/generator/generate_all.py` (Salesforce → Snowflake 순서). Snowflake 부분만: `python3 -c "import sys; sys.path.insert(0,'data/demo/generator'); import common, gen_snowflake; gen_snowflake.generate(common.load_master(), common.Clock())"`

## 시각 규칙

- 모든 TIMESTAMP는 UTC ISO 8601(`2026-11-30T14:55:00Z`)로 저장한다. Snowflake 열 타입은 TIMESTAMP_TZ.
- 생성은 공장 현지 시각으로 하고(공장 시간대 = CMN_Plant__c.TimeZone__c: KR01·KR02 Asia/Seoul, CN01 Asia/Shanghai, US01 America/Chicago, PL01 Europe/Warsaw) UTC로 바꿔 쓴다.
- 날짜 열(PROD_DATE, PERIOD_START, PGI_DATE 등)은 **공장 현지 날짜**다. 화면은 UTC 시각을 사용자 시간대로, 업무 기준일은 공장 시간대로 표시한다(spec-snowflake-display 4.3).
- PERIOD_TYPE DAY·MONTH 공정능력과 KPI의 기간 경계도 공장 현지 날짜 기준이다.

## 키 규칙

- PLAN_ID·STUDY_ID에는 Salesforce Id 대신 데모 번호(RecordNo)가 들어 있다. PLAN_NO·STUDY_NO 열과 같고, Salesforce 적재 후 load_demo.sql 끝의 UPDATE로 Id로 바꾼다.
- MEAS_ID = `{{MES 포인트}}-{{UTC yyyyMMddHHmmss}}-{{순번}}`, SIGNAL_ID = sha1(planNo, rule, chart, subgroupNo) 앞 32자.
- 고객 품질 EVENT_KEY = SHA-256(SOURCE, CUSTOMER_CODE, DATA_TYPE, CUSTOMER_REF_NO, LINE_NO). VIN은 STG에만, CORE는 VIN_HASH.

## 적재

`scripts/demo/load_snowflake.sh <snow 연결> [--with-b2b-core]` — DB가 SL_QDW_DEMO·SL_QDW_DEV가 아니면 중단한다. 테이블은 schemachange로 먼저 만든다.
CORE.CUSTOMER_QUALITY_EVENT는 동적 테이블이므로 기본 적재에서 빠지고, 동적 테이블이 없는 환경만 `--with-b2b-core`로 직접 적재한다.
Salesforce 90번대 CSV(KPI, SPC 계획·한계·알람, MSA 연구·평가자, 고객 결함·품번 매핑)는 `salesforce/load-plan.snowflake.json` 순서로 Salesforce 적재에 합친다.

## 기대값(골든)

| 파일 | 내용 |
| --- | --- |
| expected/spc_S7.json | 계획별(키 KR01-L02-OP10-C10, KR01-L01-OP20-C40, KR01-L01-OP40-C30, CN01-L01-OP60-C20) 1단계 한계·상수·계산 방법, 규칙별 신호 목록, DAY·MONTH·ROLLING_30D·STUDY 공정능력, 드리프트 후 최초 R2·R1 |
| expected/msa_S8.json | S8-MSA1·2(ANOVA 표, 분산 성분, %GRR, ndc, 교호작용 p·풀링, 판정, X̄-R 대조), S8-MSA3(kappa, 유효성, 미검출·오검출, 설계 오류) |
| expected/b2b_S10.json | 고객·품번·월 0km PPM, BMW BE1L PPM, HMC HE1 코호트 MIS 곡선, 데모 경보 규칙 결과 |
| expected/eol_S13.json | CN01 KC1L EOL 월·일 직행률 |
| expected/kpi_S5.csv | 2026-11 MONTH·2026-11-30 DAY KPI 값(대시보드 정답) |
| expected/gauge_S12_dwh.json | (Salesforce 수입검사 CSV가 있을 때) GA-KR01-0456 영향 로트, INSPECTION_RESULT 기준 |
| expected/scenario_keys_snowflake.json | 논리 키 → 레코드 번호(S7-PLAN, S7-ALARM, S8-MSA1~3 등) |

## DWH 응답 목

`mocks/dwh/{{QueryKey}}/{{case}}.json`(데모 명세 7절 봉투). ok 케이스 rows는 위 CSV에서 계산한 값과 같다.

{mock_list}

## 파생 데이터(Salesforce CSV 필요)

`salesforce/*QMS_IqcLot__c*.csv`·`*QMS_IqcResult__c*.csv`·`*QMS_NCR__c*.csv`·`*QMS_FourMChange__c*.csv`가 있으면 CORE.INSPECTION_RESULT·NCR_DEFECT·FOURM_CHANGE, IQC·NCR·4M KPI, 목 QMS_GAU_IMPACT_RESULTS·QMS_IQC_LOT_DETAIL·QMS_MSA_GAUGE_USAGE·QMS_NCR_PARETO·QMS_NCR_TREND를 만든다. 없으면 협력사 로트를 `{{VendorNo}}-{{yyMMdd}}-A` 패턴으로 합성한다. Salesforce 생성 후 `generate_all.py`를 다시 실행하면 된다.

## 행 수

| 파일 | 행 |
| --- | --- |
{counts}
'''
    with open(out_path('README-snowflake.md'), 'w', encoding='utf-8') as f:
        f.write(readme)


def register_change_requests(ctx):
    c = ctx.cr
    c('QMS-04-SPC-002, QMS-06-MSA-002·003', 'CORE.SPC_SUBGROUP·SPC_SIGNAL·SPC_CAPABILITY에 PLAN_NO, CORE.MSA_MEASUREMENT·ML.MSA_RESULT에 STUDY_NO(RecordNo) 열 추가. 데모·테스트 재현과 조인 키', 'PLAN_ID·STUDY_ID에 RecordNo를 넣고 Salesforce 적재 후 UPDATE로 Id 치환(load_demo.sql)')
    c('QMS-04-SPC-001', 'QMS_SpcLimit__c.ExternalKey__c(Text(80), External ID, Unique) 추가', '`{PlanNo}-V{Version}` 예: SPC-KR01-00001-V1')
    c('QMS-06-MSA-002', 'QMS_MsaAppraiser__c.ExternalKey__c 추가', '`{StudyNo}-{Label}` 예: MSA-KR01-2026-00007-A')
    c('CMN-00-MDM-002', 'CMN_Operation__c.ExternalKey__c 추가', '`{PlantCode}-{LineCode}-{OpCode}` 예: KR01-L02-OP10')
    c('CMN-00-MDM-007', 'CMN_Code__c.ExternalKey__c를 계층 경로 전체로', '`{Group}/{L1}/{L2}/{L3}` 예: DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG, CAUSE_5M1E/MACHINE/DISPENSER_FLOW')
    c('CMN-00-DWH-003', 'CMN_KpiValue__c.Unit__c 예시를 Vol.7 레지스트리 단위 코드로, Vehicle__c 차원 추가(QMS_FIELD_R1000)', 'Unit = RATIO·CNT·PCT·PPM·R1000, Vehicle__r.ExternalKey__c 열 사용(필드 추가 전에는 적재 시 열 제거)')
    c('QMS-06-MSA-002·003', 'CORE.MSA_MEASUREMENT 열 정의(제안)', 'STUDY_ID, STUDY_NO, CALC_SEQ, STUDY_TYPE, PLANT_CODE, GAUGE_NO, ITEM_NO, CHAR_NO, PART, APPRAISER, APPRAISER_EMP_NO, TRIAL, VALUE, RESULT, REFERENCE, MEASURED_AT, _LOADED_AT. 키 (STUDY_ID, CALC_SEQ, PART, APPRAISER, TRIAL)')
    c('QMS-06-MSA-003', 'ML.MSA_RESULT 열 정의(제안), ML.MSA_CONSTANT 초기 값 출처', 'MSA_RESULT: STUDY_ID, STUDY_NO, CALC_SEQ, CALC_AT, ENGINE_VERSION, RESULT(VARIANT). MSA_CONSTANT K1·K2·K3는 정의식 계산값, VERIFIED_BY 공란(검수 전 XBAR_R 계산 실패가 정상)')
    c('QMS-06-MSA-004', '계수형 판정 기준 기본값', '데모 임시: kappa ≥ 0.75, 유효성 ≥ 80%, 미검출 ≤ 5%, 오검출 ≤ 12.5%(QMS_MsaCriteria__mdt). AIAG 권장 표(유효성 90·미검출 2·오검출 5)를 쓰면 S8-MSA3은 CONDITIONAL')
    c('QMS-05-B2B-001, QMS-09-INT-014', 'STG.CUSTOMER_QUALITY_STD 열 정의(제안)', 'EVENT_KEY, SOURCE, UPLOAD_ID, CUSTOMER_CODE, DATA_TYPE, CUSTOMER_REF_NO, LINE_NO, EVENT_DATE, VEHICLE_CODE, VIN, CUSTOMER_PART_NO, CUSTOMER_DEFECT_CODE, CUSTOMER_DEFECT_TEXT, QTY, PRODUCTION_MONTH, SALES_MONTH, FAILURE_MONTH, MILEAGE_KM, COST_AMOUNT, COST_CURRENCY, COUNTRY, CUSTOMER_JUDGMENT, _IS_DELETED, LOADED_AT')
    c('QMS-05-B2B-001', '출하 공장이 2곳 이상인 품번(BE1L: KR01·PL01)은 BR-3으로 PLANT_CODE가 NULL → 공장별 고객 PPM 불가. SAP 출하 이력(납품처·VIN·로트)으로 공장 추정 규칙 필요', '데모는 PLANT_CODE NULL, KPI는 고객·품번 단위')
    c('QMS-05-B2B-006', '등록 쿼리 결과 열(제안)', 'TREND: periodStart, dataType, customerCode, eventCount, qty, denominator, ppm, r1000, target / PARETO: defectTypeCode, defectTypeName, eventCount, qty, pct, cumulativePct / MIS_CURVE: cohortMonth, mis, cumulativeClaims, soldVehicles, cumR1000')
    c('QMS-05-CLM-008', 'QMS_CLM_SUSPECT_STOCK 결과 열(제안)', 'locationType(PLANT_STOCK, SERVICE, IN_TRANSIT), plantCode, storageLocation, oemCode, itemNo, batch, stockType, batchProdDate, qty, pgiDate, snapshotTs')
    c('QMS-04-SPC-003', 'S7 데모에서 최근 10일 Cpk 1.30 < 1.33이지만 BR-5는 ROLLING_30D 기준이라 11-30까지 QMS_SPC_CAPABILITY_LOW가 발생하지 않음(11-30 ROLLING_30D Cpk 1.51, expected/spc_S7.json). 데모 시연에 공정능력 미달 알람이 필요하면 판정 창 설정값(예: QMS_SPC_CAPABILITY_WINDOW_DAYS) 추가', 'STUDY(11-21~11-30) 행을 SPC_CAPABILITY에 넣어 화면 시연, 알람은 R1·R2 신호 알람으로 시연')
    c('QMS-04-SPC-002', 'SPC_CONSTANTS에 SOURCE_REF·VERIFIED_BY·VERIFIED_AT 열(검수 추적), D3_CONST(d3) 열 추가 제안', '데모 값은 정의식 계산값, VERIFIED_BY 공란')
    c('QMS-04-EFC-002, QMS-09-INT-011', 'CORE.MES_DEFECT.DEFECT_TYPE_CODE 형식 명시(CMN_Code ExternalKey 전체 경로)', 'DEFECT_TYPE/SEALING/CONDENSATION/INNER_FOG 형식, MES_DEFECT_CODE는 MF-* 데모 코드')
    c('QMS-03-IQC-007', 'CORE.INSPECTION_RESULT에 GAUGE_NO, LOT_NO 열(데모 조인용)', 'LOT_ID에 RecordNo, LOT_NO 동일 값')
    c('QMS-04-SPC-006', 'QMS_SPC_PLAN_SUMMARY의 cpk·rag 기준 기간이 ROLLING_30D라 S7(최근 10일 Cpk 1.30)이 GREEN으로 보임. 드리프트 초기 경고가 필요하면 rag 기준 기간 설정 또는 최근 STUDY 값 병기', '목은 ROLLING_30D 기준(S7 GREEN, 1.51), STUDY 값은 QMS_SPC_CAPABILITY_STUDY 목')
    c('QMS-04-SPC-005', '지속 이동(드리프트·평균 이동) 중 한 알람에 신호가 수백 건 붙으면 SignalsJson__c(Long Text 131072)를 넘음. 상한(예: 최근 500건 + 총 건수) 규칙 필요', 'S13 CN01 알람 798건 → 120,000자 이내 앞부분만 저장, SignalCount__c는 전체 건수')
    c('QMS-04-EFC-002', 'CORE.MES_DEFECT 키 "MES 불량 기록 Id"의 열 이름 미정', 'MES_DEFECT_ID = {PLANT}-{MES_LOT_NO}-{MES_DEFECT_CODE}')
    c('QMS-04-FQC-004', 'EOL_TEST_RESULT.TEST_ITEMS 배열 원소 키 이름 미정', '[{code, value, result}], code = AIM_V·LEAK·DRL_I(데모)')
    c('QMS-05-B2B-006', 'TOP_ITEMS·DETAIL·LAST_LOADED 결과 열(제안)', 'TOP_ITEMS: itemNo, itemName, currentQty, previousQty, changePct / DETAIL: eventDate, customerRefNo, vehicleCode, itemNo, defectTypeCode, customerDefectText, mis, mileageKm, country, costKrw(includeCost=false면 NULL), customerJudgment, claimNo / LAST_LOADED: customerCode, dataType, lastLoadedAt, lastEventDate, rowCount')
    c('QMS-06-MSA-005', 'QMS_MSA_CHART PROCEDURE result 형식(제안)', '{engineVersion, studyId, calcSeq, chartType, status, mimeType image/png, width, height, imageBase64, series, categories}')
    c('QMS-04-EFC-002', 'QMS_EFC_DEFECT_PARETO 파라미터(공장·기간)와 이름 열 원천', 'plantCodes, fromDate, toDate. defectTypeName = CMN_Code L3 이름(ko)')
    c('QMS-06-GAU-004', 'QMS_GAU_IMPACT_RESULTS 위험 판정식(minMargin 단위·기준) 미정', 'minMargin = (측정값 − As-found 오차)에서 규격 한계까지 최소 거리(특성 단위), 음수면 HIGH(Salesforce 데모 gauge_S12.json과 같은 식)')
    c('데모 명세 3절·5절 S12', 'expected/gauge_S12.json을 Salesforce 생성기와 Snowflake 생성기가 둘 다 산출 대상으로 가짐(소유 중복)', 'Snowflake 쪽 계산은 expected/gauge_S12_dwh.json(같은 로트 목록을 INSPECTION_RESULT 기준으로 계산), gauge_S12.json은 Salesforce 작업 소유로 둠')
    c('데모 명세 7절', '응답 형식 예시의 queryKey QMS_SPC_CHART와 열(xbar)이 등록 쿼리(QMS_SPC_SUBGROUPS, mean)와 다름', '목은 QMS_SPC_SUBGROUPS 사용')
    c('QMS-08-AIQ-011', 'OPERATION 엔터티 키가 PLANT+LINE+OPERATION_TYPE이라 데모 명세 S11의 "KR01 L01 OP20"은 OP10~OP30(ASSEMBLY)을 묶은 KR01-L01-ASSEMBLY로 집계됨. CORE.SPC_SIGNAL에는 공정 열이 없어 SPC 계획(Operation) 조인 필요. CN01 L01(S13)도 최근 7일 OOC 213건으로 상위 후보', '원천: 최근 7일 OOC KR01 L02 343, KR01 L01 OP20 280(OOS 1 포함), CN01 L01 OP60 213')
    c('CMN-00-DWH-003', 'Vol.7 카탈로그 일수 단위는 DAYS(QMS_4M_CYCLE_DAYS 등)인데 데모 명세 4절 예시는 DAY', '데모 KPI에 일수 KPI 없음(해당 없음), 카탈로그 DAYS를 따를 것')


def generate(master, clock):
    global GENERATED_AT
    ctx = Ctx(master, clock)
    GENERATED_AT = iso(dt.datetime.combine(clock.today, dt.time(0, 0, 3), tzinfo=UTC))
    LOADED_AT[0] = ctx.loaded_at
    register_change_requests(ctx)
    gen_spc(ctx)
    gen_msa(ctx)
    gen_mes(ctx)
    gen_sap(ctx)
    gen_b2b(ctx)
    alarms = read_csv(os.path.join(ROOT, 'salesforce', '93_QMS_SpcAlarm__c.csv'))
    spc_summary_mock(ctx, alarms)
    gen_derived(ctx)
    gen_kpis(ctx)
    gen_freshness(ctx)
    gen_load_scripts(ctx)
    write_docs(ctx)
    summary = {
        'S7': ctx.spc_expected['plans']['KR01-L02-OP10-C10']['capability']['STUDY'],
        'S7_rolling_last': ctx.spc_expected['plans']['KR01-L02-OP10-C10']['capability']['ROLLING_30D_LAST'],
        'S7_firsts': ctx.spc_expected['summary'],
        'MSA': {k: (v.get('metrics', {}).get('pctGrrStudyVar'), v.get('metrics', {}).get('ndc'),
                    v.get('metrics', {}).get('kappaVsStandardMin'), v['verdict']['value']) for k, v in ctx.msa_expected['studies'].items()},
        'EOL': {m: v['fpyPct'] for m, v in ctx.eol_expected['monthly'].items()},
        'MES_top': ctx.mes_top[:5], 'BMW_BE1L_ppm_last4': list(ctx.b2b_expected['BMW_BE1L_ppm'].items())[-4:],
        'b2b_alerts': [(a['ruleCode'], a.get('cohort') or a.get('periodStart'), a['value']) for a in ctx.b2b_expected['alerts']],
        'derived': ctx.derived, 'notes': ctx.notes}
    write_json('expected/_snowflake_run_summary.json', summary)
    write_json('expected/scenario_keys_snowflake.json', {'note': '데모 논리 키 → 레코드 번호(Snowflake 데이터 작업분). scenario_keys.json에 합친다.',
                                                         'keys': dict(sorted(ctx.keys.items()))})
    return summary
