#!/usr/bin/env python3
"""객체 카탈로그: WI 명세(Vol.0~9 데이터 모델 표)의 전체 객체를 배포 현황·화면 묶음과 함께 목록으로 만들고,
메뉴별 ER 다이어그램(Mermaid)을 그린다. 앞으로 만들 객체까지 포함한다.

    python3 scripts/dev/object-catalog.py                 # docs/docs/30-dev/object-catalog.md
    python3 scripts/dev/object-catalog.py --json out.json # 같은 내용을 JSON으로도

- 객체·필드·관계: 명세 데이터 모델 표(`| 객체 / 필드 | 타입 | ...`). 관계 대상이 타입에 없으면 필드 이름으로 추정한다.
- 이름: 배포된 객체는 meta-src 라벨, 아직 없는 객체는 docs/docs/30-dev/object-names.csv.
- 상태: force-app에 있으면 배포, 없으면 screen-map.csv의 소유 WI 화면 묶음(A단계) 또는 B단계 페이즈.
"""
import argparse
import collections
import csv
import glob
import json
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SPECS = os.path.join(ROOT, 'docs/docs/10-workitems')
OUT = os.path.join(ROOT, 'docs/docs/30-dev/object-catalog.md')
NAMES = os.path.join(ROOT, 'docs/docs/30-dev/object-names.csv')
SCREEN_MAP = os.path.join(ROOT, 'docs/docs/30-dev/screen-map.csv')
OBJ = r'(?:CMN|QMS|PMS)_[A-Za-z0-9]+__(?:c|mdt|e)'
STANDARD = {'Account', 'User', 'Contact'}
# 필드 이름만으로 대상을 알 수 있는 공통 관계
COMMON_TARGETS = {
    'Plant': 'CMN_Plant__c', 'Item': 'CMN_Item__c', 'Supplier': 'Account', 'Customer': 'Account',
    'Line': 'CMN_Line__c', 'Operation': 'CMN_Operation__c', 'Characteristic': 'CMN_Characteristic__c',
    'Vehicle': 'CMN_Vehicle__c', 'SupplierItem': 'CMN_SupplierItem__c', 'Department': 'CMN_Department__c',
    'Employee': 'CMN_Employee__c', 'ProductGroup': 'CMN_ProductGroup__c', 'Company': 'CMN_Company__c',
    'DefectType': 'CMN_Code__c', 'Cause': 'CMN_Code__c', 'FourM': 'QMS_FourMChange__c',
}
# ER 다이어그램에서 뺄 관계 대상(거의 모든 객체가 참조해 그림을 덮는다)
NOISY = {'User', 'CMN_Code__c'}
MENUS = [
    ('CMN-MDM', '공통 — 기준정보', None),
    ('CMN-ENG', '공통 — 업무 엔진·운영', None),
    ('QMS-02', 'QMS-02 개발 품질', None),
    ('QMS-03', 'QMS-03 부품/협력사 품질', None),
    ('QMS-04', 'QMS-04 제품/공정 품질', None),
    ('QMS-05', 'QMS-05 고객 품질', None),
    ('QMS-06a', 'QMS-06 품질 운영 지원 — 4M 변경·부적합', None),
    ('QMS-06b', 'QMS-06 품질 운영 지원 — 한도견본·교육·측정기·MSA·분석실', None),
    ('QMS-06c', 'QMS-06 품질 운영 지원 — 심사·인증·협력사 실적·개선 과제', None),
    ('QMS-07', 'QMS-07 대시보드', None),
    ('QMS-08', 'QMS-08 AI', None),
    ('QMS-09', 'QMS-09 연계', None),
]
MENU_TITLE = {k: t for k, t, _ in MENUS}
MDM_FEATURES = {'MDM', 'SEC', 'I18N'}
# 그림 1: 층 구조와 메뉴 간 업무 연결(Lookup이 아닌 원천 Id·이벤트·게이트웨이는 점선)
OVERVIEW = '''```mermaid
flowchart TB
    subgraph MDM["① 공통 기준정보 (배포됨)"]
        direction LR
        Company["법인"] --> Plant["공장"] --> Line["라인"] --> Op["공정"]
        Account["고객·협력사<br/>(Account)"] --> Vehicle["차종"]
        PG["제품군"] --> Item["품번"] --> Char["품질 특성<br/>(특별특성 CC/SC)"]
        Account --> SI["협력사 품번<br/>(검사 수준·PPAP 상태)"]
        Item --> SI
        Code["공통 코드<br/>(불량 유형·원인·문서 분류)"]
    end
    subgraph ENG["② 공통 업무 엔진 (배포됨)"]
        direction LR
        APV["결재"] --- TODO["To-Do"] --- NTF["알림"]
        DOC["문서·리비전"] --- MTG["회의·조치 항목"] --- CMT["코멘트"]
        KPI["KPI 값·AI 추천 기록<br/>(A0 예정)"]
    end
    subgraph QMS["③ QMS 메뉴 업무 객체 (A1~A7 예정)"]
        direction LR
        QP["02 인정시험 계획"]
        IQC["03 수입검사 로트"]
        PPAP["03·04 PPAP"]
        PIS["03·04 초기안정화"]
        SPC["04 SPC 알람"]
        FQC["04 출하검사 로트"]
        B2B["05 고객 품질 경보"]
        CLM["05 고객 클레임"]
        E8D["05 8D 엔진"]
        NCR["06 부적합(NCR)"]
        FOURM["06 4M 변경"]
        HZD["04 수평전개"]
        LEL["04 레슨런"]
        AUD["06 심사·지적"]
        GAU["06 측정기·MSA·교육·한도견본·분석실"]
    end
    IQC -. 판정 이벤트 .-> NCR
    FQC -. 판정 이벤트 .-> NCR
    SPC -. 게이트웨이 .-> NCR
    QP -. 불합격 .-> NCR
    B2B -. 경보 .-> CLM
    NCR -- Lookup --> E8D
    CLM -- Lookup --> E8D
    AUD -. 지적 대책 .-> E8D
    E8D -. 재발 방지 .-> FOURM
    E8D -. 수평전개 .-> HZD
    E8D -. 교훈 .-> LEL
    FOURM -. 재PPAP .-> PPAP
    MDM ==> QMS
    ENG ==> QMS
```'''

REVIEW_NOTES = {
    'QMS_AuditFindingAction__c': '오브젝트 리뷰 O-5: 공통 조치 항목(CMN_ActionItem__c)으로 대체 권고',
    'QMS_CustomerAuditPrepTask__c': '오브젝트 리뷰 O-5: 공통 조치 항목(CMN_ActionItem__c)으로 대체 권고',
    'QMS_HorizontalDeployTarget__c': '오브젝트 리뷰 O-7: 수평전개와 Master-Detail로 변경 권고',
    'CMN_KpiValue__c': '오브젝트 리뷰 O-2: 집계 단위·보존 기간 조정 권고',
}


def cells(line):
    return [c.strip() for c in line.strip().strip('|').split('|')]


def extract():
    """명세 데이터 모델 표 → 객체별 필드·소유 WI."""
    out = collections.OrderedDict()
    for f in sorted(glob.glob(os.path.join(SPECS, 'vol*.md'))):
        lines = open(f, encoding='utf-8').read().split('\n')
        wi = ''
        i = 0
        while i < len(lines):
            line = lines[i]
            m = re.match(r'^(#{2,4})\s+(.*)', line)
            if m:
                mw = re.match(r'((?:CMN|QMS)-\d\d-[A-Z0-9]+-\d{3}[a-z]?)', m.group(2).strip())
                if mw:
                    wi = mw.group(1)
                elif m.group(1) == '##':
                    wi = ''
            if line.startswith('|') and i + 1 < len(lines) and re.match(r'^\|\s*-', lines[i + 1]):
                hdr = cells(line)
                if hdr and hdr[0] in ('객체 / 필드', '필드') and len(hdr) >= 3 and '타입' in hdr[1]:
                    has_req = len(hdr) >= 4 and '필수' in hdr[2]
                    j = i + 2
                    cur = None
                    while j < len(lines) and lines[j].startswith('|'):
                        c = cells(lines[j])
                        name = re.sub(r'[`*]', '', c[0]).strip()
                        typ = c[1] if len(c) > 1 else ''
                        desc = (c[3] if has_req and len(c) > 3 else (c[2] if len(c) > 2 else ''))
                        mo = re.match(rf'^({OBJ})(?:\.(.+))?$', name)
                        if mo:
                            obj, fld = mo.group(1), mo.group(2)
                            cur = obj
                        elif re.match(r'^(Account|User|Contact)\.', name):
                            obj, fld = name.split('.', 1)
                            cur = obj
                        else:
                            obj, fld = cur, name
                        if obj:
                            o = out.setdefault(obj, {'wis': [], 'fields': []})
                            if wi and wi not in o['wis']:
                                o['wis'].append(wi)
                            if fld:
                                names = [fn.strip() for fn in re.split(r'\s*/\s*', fld)]
                                types = [t.strip() for t in typ.split(' / ')]
                                for n, fn in enumerate(names):
                                    if re.match(r'^[A-Za-z][A-Za-z0-9_]*(__c)?$', fn):
                                        t = types[n] if len(types) == len(names) else typ
                                        o['fields'].append({'name': fn, 'type': t, 'desc': desc})
                        j += 1
                    i = j
                    continue
            i += 1
    return out


def short(obj):
    return re.sub(r'^(CMN|QMS|PMS)_|__(c|mdt|e)$', '', obj)


def resolve(field, typ, child, model, owner):
    """관계 필드 → (종류, 대상 객체). 타입 괄호의 대상이 우선, 없으면 필드 이름으로 추정."""
    kind = 'MD' if re.search(r'Master[- ]?Detail', typ) else ('L' if 'Lookup' in typ else None)
    if not kind:
        return None
    # 'Picklist / Lookup(X) / Text' 처럼 필드 여러 개를 한 행에 쓴 경우는 타입을 나누지 않고 첫 대상만 본다
    m = re.search(rf'(?:Lookup|Master[- ]?Detail)\s*\(\s*({OBJ}|Account|User|Contact|self)', typ)
    if m:
        target = child if m.group(1) == 'self' else m.group(1)
        return kind, target
    base = re.sub(r'__c$', '', field)
    base = re.sub(r'^(Target|Source|Related|Responsible|Original)(?=[A-Z])', '', base)
    if re.search(r'(By|Owner|Approver|Assignee|Manager|Leader|Auditor|Inspector)$', base) or base in ('User',):
        return kind, 'User'
    prefix = child.split('_')[0]
    same_menu = [o for o in model if o.startswith(prefix + '_') and o.endswith('__c') and o != child]

    def pick(cands):
        # 상세 객체 이름이 헤더 이름으로 시작하면 그 헤더(SamplingPlanRow → SamplingPlan), 다음은 같은 WI
        cands.sort(key=lambda o: (not short(child).startswith(short(o)), owner.get(o) != owner.get(child), len(o)))
        return cands[0] if cands else None

    # Master-Detail은 같은 WI의 헤더가 우선(QualSampleResult.Line__c = 인정시험 계획 라인)
    if kind == 'MD':
        hit = pick([o for o in same_menu if owner.get(o) == owner.get(child) and short(o).lower().endswith(base.lower())])
        if hit:
            return kind, hit
    if base in COMMON_TARGETS:
        return kind, COMMON_TARGETS[base]
    hit = pick([o for o in same_menu if short(o).lower().endswith(base.lower())]) or \
        pick([o for o in same_menu if short(o).lower().startswith(base.lower())])
    return (kind, hit) if hit else None


def load_names():
    names = {}
    with open(NAMES, encoding='utf-8') as f:
        for r in csv.DictReader(f):
            names[r['객체']] = r['이름']
    for p in glob.glob(os.path.join(ROOT, 'meta-src/*/*.json')):
        with open(p, encoding='utf-8') as f:
            d = json.load(f)
        if 'object' in d and isinstance(d.get('label'), dict) and d['label'].get('ko'):
            names[d['object']] = d['label']['ko']
    names.update({'Account': '거래처(고객·협력사)', 'User': '사용자'})
    return names


def deployed():
    out = {os.path.basename(os.path.dirname(p))
           for p in glob.glob(os.path.join(ROOT, 'force-app-*/main/default/objects/*/*.object-meta.xml'))}
    for std in STANDARD:
        if glob.glob(os.path.join(ROOT, f'force-app-*/main/default/objects/{std}/fields/*.xml')):
            out.add(std)
    return out


def deployed_rels():
    """배포 소스의 Lookup·Master-Detail(명세 표보다 정확하다)."""
    out = collections.defaultdict(list)
    for p in glob.glob(os.path.join(ROOT, 'force-app-*/main/default/objects/*/fields/*.field-meta.xml')):
        obj = p.split('/objects/')[1].split('/')[0]
        x = open(p, encoding='utf-8').read()
        t = re.search(r'<type>(Lookup|MasterDetail)</type>', x)
        r = re.search(r'<referenceTo>([^<]+)</referenceTo>', x)
        if t and r:
            out[obj].append({'child': obj, 'parent': r.group(1), 'kind': 'MD' if t.group(1) == 'MasterDetail' else 'L',
                             'field': os.path.basename(p).split('.')[0]})
    return out


def screen_map():
    with open(SCREEN_MAP, encoding='utf-8-sig') as f:
        return {r['WI_ID']: r for r in csv.DictReader(f)}


def menu_of(obj, owner_wi):
    if not owner_wi.startswith(('CMN-', 'QMS-')):
        return 'CMN-ENG'
    parts = owner_wi.split('-')
    if parts[0] == 'CMN':
        return 'CMN-MDM' if parts[2] in MDM_FEATURES or obj in STANDARD else 'CMN-ENG'
    if parts[1] == '06':
        return 'QMS-06a' if parts[2] in ('4MC', 'NCR') else ('QMS-06b' if parts[2] in ('LMS', 'TRN', 'GAU', 'MSA', 'LAB') else 'QMS-06c')
    return f'QMS-{parts[1]}'


def kind_label(obj):
    if obj.endswith('__mdt'):
        return '메타데이터'
    if obj.endswith('__e'):
        return '이벤트'
    return '표준 확장' if obj in STANDARD else '객체'


def build():
    model = extract()
    names = load_names()
    dep = deployed()
    dep_rels = deployed_rels()
    smap = screen_map()
    # 명세 밖에서 구현 중 추가된 배포 객체(설정 mdt·이벤트·테스트 객체)도 목록에 넣는다
    extra_owner = {'CMN_AppMenu__mdt': 'A0 공용 장치', 'CMN_AppMenuItem__mdt': 'A0 공용 장치',
                   'CMN_DashboardResolver__mdt': 'CMN-00-DSH-001', 'CMN_Setting__mdt': 'CMN-00-MDM-003',
                   'CMN_TestRecord__c': 'CMN-00-ARC-003', 'CMN_TodoChanged__e': 'CMN-00-TDO-001'}
    for o, w in extra_owner.items():
        if o in dep and o not in model:
            model[o] = {'wis': [w], 'fields': [], 'extra': True}
    owner = {o: (v['wis'][0] if v['wis'] else '') for o, v in model.items()}
    rows = []
    rels = []
    for o, v in model.items():
        w = owner[o]
        if o in dep:
            status = '배포됨'
        else:
            s = smap.get(w, {})
            if s.get('진행', '').startswith('A단계'):
                status = f"예정 {s.get('화면묶음', '')}"
            elif s:
                status = f"예정 B단계({s.get('상세페이즈', '')})"
            else:
                status = '예정'
        seen = set()
        if o in dep:
            rels.extend(e for e in dep_rels.get(o, []) if e['parent'] in model or e['parent'] in STANDARD)
            v = {**v, 'fields_rel': []}
        for f in ([] if o in dep else v['fields']):
            r = resolve(f['name'], f['type'], o, model, owner)
            if r and (r[1] in model or r[1] in STANDARD) and (o, r[1], f['name']) not in seen:
                seen.add((o, r[1], f['name']))
                rels.append({'child': o, 'parent': r[1], 'kind': r[0], 'field': f['name']})
        note = REVIEW_NOTES.get(o, '')
        if v.get('extra'):
            note = (note + ' ' if note else '') + '구현 중 추가(명세 표 밖)'
        rows.append({'object': o, 'name': names.get(o, ''), 'kind': kind_label(o), 'menu': menu_of(o, w),
                     'owner': w, 'fields': len({f['name'] for f in v['fields']}), 'status': status, 'note': note})
    return rows, rels


def mermaid(menu, rows, rels, names):
    objs = {r['object'] for r in rows if r['menu'] == menu and r['kind'] in ('객체', '표준 확장')}
    if not objs:
        return None
    edges = [e for e in rels if (e['child'] in objs or (e['parent'] in objs and e['child'] in objs))
             and e['parent'] not in NOISY and e['child'] != e['parent']]
    # 다른 메뉴로 가는 Lookup은 공통 기준정보·같은 엔진만 그린다(메뉴 간 업무 연결은 개요 그림)
    ents = set(objs)
    for e in edges:
        ents.add(e['parent'])
    lines = ['```mermaid', 'erDiagram']
    for o in sorted(ents):
        label = names.get(o, '') or o
        mark = '' if o in objs else ' (다른 메뉴)'
        lines.append(f'    {ident(o)} {{')
        lines.append(f'        string api "{o}"')
        lines.append(f'        string name "{label}{mark}"')
        lines.append('    }')
    done = set()
    for e in edges:
        key = (e['parent'], e['child'], e['kind'])
        fields = [x['field'] for x in edges if (x['parent'], x['child'], x['kind']) == key]
        if key in done:
            continue
        done.add(key)
        card = '||--o{' if e['kind'] == 'MD' else '|o--o{'
        lab = ', '.join(sorted(set(fields)))[:40]
        lines.append(f'    {ident(e["parent"])} {card} {ident(e["child"])} : "{lab}"')
    lines.append('```')
    return '\n'.join(lines)


def ident(obj):
    return re.sub(r'[^A-Za-z0-9_]', '', obj.replace('__', '_'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--json')
    a = ap.parse_args()
    rows, rels = build()
    names = {r['object']: r['name'] for r in rows}
    names.update({'Account': '거래처(고객·협력사)', 'User': '사용자'})
    order = {k: i for i, (k, _, _) in enumerate(MENUS)}
    kind_order = {'표준 확장': 0, '객체': 1, '메타데이터': 2, '이벤트': 3}
    rows.sort(key=lambda r: (order.get(r['menu'], 99), kind_order[r['kind']], r['owner'], r['object']))
    total = collections.Counter()
    by_menu = collections.defaultdict(collections.Counter)
    for r in rows:
        k = '배포됨' if r['status'] == '배포됨' else '예정'
        by_menu[r['menu']][r['kind']] += 1
        by_menu[r['menu']][k] += 1
        total[r['kind']] += 1
        total[k] += 1
    md = ['# 객체 카탈로그 — 배포된 객체와 앞으로 만들 객체, 메뉴별 ER 다이어그램', '',
          '`python3 scripts/dev/object-catalog.py`가 WI 명세의 데이터 모델 표, 배포 소스, `screen-map.csv`로 만든다. 손으로 고치지 않는다. '
          '아직 없는 객체의 이름은 `object-names.csv`에서 고친다.', '',
          '- 상태: **배포됨** = 개발 Org에 있음, **예정 A{n}** = 화면 우선 플랜 1차 화면 묶음에서 데이터 모델과 함께 만듦, **예정 B단계** = 화면 없이 상세 기능 단계에서 만듦.',
          '- 필드 수는 명세 표 기준(배포 객체는 구현 때 더한 필드가 있어 데이터 사전 수가 더 많다).',
          '- ER 다이어그램: `||--o{` Master-Detail(상위 삭제·공유를 따름), `|o--o{` Lookup. 사용자(User)·공통 코드(CMN_Code__c) 참조는 거의 모든 객체에 있어 그림에서 뺐다. '
          '메뉴 간 업무 연결(원천 텍스트 Id·이벤트·게이트웨이)은 Lookup이 아니라 그림 1(개요)에 점선으로 그렸다.', '',
          '## 요약', '',
          '| 메뉴 | 객체 | 표준 확장 | 메타데이터 | 이벤트 | 배포됨 | 예정 |', '| --- | --- | --- | --- | --- | --- | --- |']
    for k, title, _ in MENUS:
        c = by_menu[k]
        md.append(f"| {title} | {c['객체']} | {c['표준 확장']} | {c['메타데이터']} | {c['이벤트']} | {c['배포됨']} | {c['예정']} |")
    md.append(f"| 합계 | {total['객체']} | {total['표준 확장']} | {total['메타데이터']} | {total['이벤트']} | {total['배포됨']} | {total['예정']} |")
    md += ['', '## 그림 1. 전체 구조와 메뉴 간 연결', '',
           '굵은 화살표: 모든 메뉴가 기준정보를 Lookup하고 결재·To-Do·문서 등 공통 엔진을 쓴다. 실선: Lookup. '
           '점선: 원천 텍스트 Id + Platform Event·게이트웨이로 잇는 느슨한 연결(상대 메뉴 배포 순서와 무관).', '', OVERVIEW, '',
           '## 전체 목록', '']
    for k, title, _ in MENUS:
        part = [r for r in rows if r['menu'] == k]
        if not part:
            continue
        md += [f'### {title}', '', '| 객체 API | 이름 | 종류 | 소유 WI | 필드 | 상태 | 상위(Master-Detail) | 비고 |',
               '| --- | --- | --- | --- | --- | --- | --- | --- |']
        for r in part:
            parents = sorted({e['parent'] for e in rels if e['child'] == r['object'] and e['kind'] == 'MD'})
            md.append(f"| {r['object']} | {r['name']} | {r['kind']} | {r['owner']} | {r['fields']} | {r['status']} | "
                      f"{', '.join(parents)} | {r['note']} |")
        md.append('')
    md += ['## 메뉴별 ER 다이어그램', '']
    for k, title, _ in MENUS:
        d = mermaid(k, rows, rels, names)
        if d:
            md += [f'### {title}', '', d, '']
    with open(OUT, 'w', encoding='utf-8') as f:
        f.write('\n'.join(md) + '\n')
    if a.json:
        with open(a.json, 'w', encoding='utf-8') as f:
            json.dump({'rows': rows, 'rels': rels, 'menus': [[k, t] for k, t, _ in MENUS]}, f, ensure_ascii=False, indent=1)
    print(f"객체 {len(rows)}개(배포 {total['배포됨']}, 예정 {total['예정']}), 관계 {len(rels)}개 → {os.path.relpath(OUT, ROOT)}")


if __name__ == '__main__':
    main()
