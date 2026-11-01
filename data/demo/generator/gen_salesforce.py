"""Salesforce 데모 데이터 생성기(표준 라이브러리만 사용).

사용: python3 data/demo/generator/generate_all.py  (또는 generate(master, clock) 직접 호출)
출력: data/demo/salesforce/NN_{객체}.csv, load-plan.json, users/*.json,
      data/demo/expected/{scenario_keys, iqc_S9, gauge_S12}.json, data/demo/mocks/apex/*.json,
      data/demo/fixtures/demo_fixtures.json, data/demo/wi-change-requests-salesforce.md

CSV 규칙
- 관계 열: `Field__r.ExternalField` (Bulk API 외부 키 참조). Account는 `Account.SapVendorNo__c` 형식.
- RecordType: `RecordTypeDeveloperName` 열 → 로더가 RecordTypeId로 바꾼다.
- 다형 Id 텍스트(SourceRecordId__c 등): 셀 안에 `{{ref:SObject.ExternalField=값}}` 토큰 → 로더가 Id로 바꾼다.
  사용자 Id가 필요한 텍스트(To-Do ExternalKey 등)는 `{{user:사번}}` 토큰.
- 90번대 파일 번호는 Snowflake 데이터 작업이 쓴다(여기서는 01~89만 사용)."""
import datetime as dt
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from common import BASE_TODAY, rng, write_csv, write_json  # noqa: E402
import sf_corpus as C  # noqa: E402

UTC = dt.timezone.utc
REF_RE = re.compile(r'\{\{ref:([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)=([^}]*)\}\}')
USER_RE = re.compile(r'\{\{user:([A-Z0-9]+)\}\}')

# 관계 열 → (대상 객체, 대상 외부 키) 기본 매핑
R_PLANT = ('CMN_Plant__c', 'PlantCode__c')
R_LINE = ('CMN_Line__c', 'ExternalKey__c')
R_OP = ('CMN_Operation__c', 'ExternalKey__c')
R_ITEM = ('CMN_Item__c', 'ItemNo__c')
R_CUST = ('Account', 'OemCode__c')
R_SUPP = ('Account', 'SapVendorNo__c')
R_VEH = ('CMN_Vehicle__c', 'ExternalKey__c')
R_SI = ('CMN_SupplierItem__c', 'ExternalKey__c')
R_CHAR = ('CMN_Characteristic__c', 'ExternalKey__c')
R_CODE = ('CMN_Code__c', 'ExternalKey__c')
R_DEPT = ('CMN_Department__c', 'DeptCode__c')
R_USER = ('User', 'EmployeeNo__c')
R_EMP = ('CMN_Employee__c', 'EmployeeNo__c')
R_PG = ('CMN_ProductGroup__c', 'GroupCode__c')


class Out:
    """CSV 파일 레지스트리. 행·관계·키를 모아 끝에 번호를 붙여 쓰고 참조를 점검한다."""

    def __init__(self):
        self.files = []
        self.keys = {}

    def file(self, obj, ext, refs=None, tag='', note='', mode='upsert'):
        f = {'obj': obj, 'ext': ext, 'refs': dict(refs or {}), 'tag': tag, 'note': note, 'mode': mode, 'rows': []}
        self.files.append(f)
        return f

    def add(self, f, row):
        f['rows'].append(row)
        if f['ext'] and row.get(f['ext']) not in (None, ''):
            self.keys.setdefault((f['obj'], f['ext']), set()).add(str(row[f['ext']]))
        return row

    def key_exists(self, obj, field, value):
        return str(value) in self.keys.get((obj, field), set())


def iso(d):
    return d.isoformat() if d else None


def ts(d, hh=0, mm=0):
    """date + KST 시각 → UTC ISO 문자열."""
    if d is None:
        return None
    t = dt.datetime(d.year, d.month, d.day, hh, mm) - dt.timedelta(hours=9)
    return t.strftime('%Y-%m-%dT%H:%M:%SZ')


def ref(obj, field, value):
    return f'{{{{ref:{obj}.{field}={value}}}}}'


def user(emp):
    return f'{{{{user:{emp}}}}}'


def j(data):
    return json.dumps(data, ensure_ascii=False, separators=(',', ':'))


class Gen:
    def __init__(self, master, clock):
        self.m = master
        self.clock = clock
        self.seed = master['meta']['seed']
        self.out = Out()
        self.today = clock.d('2026-12-01')
        self.counters = {}
        self.keys = {}            # 시나리오 논리 키 → 실제 번호
        self.cr = []              # 변경 요청(대상 WI, 내용, 데모 임시 값)
        self.items = {i['itemNo']: i for i in master['items']}
        self.emps = {e['no']: e for e in master['employees']}
        self.chars = {}           # (item, charNo) → dict + ext key
        self.si = {}              # (vendor, item, plant) → dict
        self.code_key = {}        # (group, leaf) → ExternalKey
        self.code_name = {}       # ExternalKey → 표시 경로
        self.license_users = [e['no'] for e in master['employees'] if e['license']]
        self.lots = []            # 수입검사 로트(기대값용)
        self.mocks = {}
        self.fixture_keys = set()

    # ------------------------------------------------------------ 공통
    def D(self, iso_str):
        return self.clock.d(iso_str)

    def seq(self, pattern, plant=None, year=None, width=6):
        """WI 채번 패턴 값 생성. 예: seq('NCR-{PLANT}-{YYYY}', 'KR01', 2026, 6)."""
        key = (pattern, plant, year)
        self.counters[key] = self.counters.get(key, 0) + 1
        return pattern.replace('{PLANT}', plant or '').replace('{YYYY}', str(year or '')) + '-' + str(self.counters[key]).zfill(width)

    def ck(self, group, leaf):
        k = self.code_key.get((group, leaf))
        if not k:
            raise KeyError(f'코드 없음: {group}/{leaf}')
        return k

    def cpath(self, group, leaf):
        return self.code_name[self.ck(group, leaf)]

    def si_key(self, vendor, item, plant):
        return f'{vendor}-{item}-{plant}'

    def char_key(self, item, char_no):
        return self.chars[(item, char_no)]['ext']

    def add_cr(self, target, content, temp):
        self.cr.append((target, content, temp))

    # ------------------------------------------------------------ 기준정보
    def masters(self):
        o, m = self.out, self.m
        f = o.file('CMN_Company__c', 'CompanyCode__c')
        for c in m['companies']:
            o.add(f, {'CompanyCode__c': c['code'], 'Name': c['name'], 'Country__c': c['country']})

        f = o.file('CMN_ProductGroup__c', 'GroupCode__c', tag='pass1')
        f2 = o.file('CMN_ProductGroup__c', 'GroupCode__c', {'Parent__r.GroupCode__c': R_PG}, tag='pass2-parent')
        for g in m['productGroups']:
            o.add(f, {'GroupCode__c': g['code'], 'Name': g['name']})
            if g['parent']:
                o.add(f2, {'GroupCode__c': g['code'], 'Parent__r.GroupCode__c': g['parent']})

        f = o.file('CMN_Plant__c', 'PlantCode__c', {'Company__r.CompanyCode__c': ('CMN_Company__c', 'CompanyCode__c')})
        for p in m['plants']:
            o.add(f, {'PlantCode__c': p['code'], 'Name': p['name'], 'NameEn__c': p['nameEn'], 'Company__r.CompanyCode__c': p['company'],
                      'Region__c': p['region'], 'TimeZone__c': p['timeZone'], 'DefaultLanguage__c': p['lang'], 'MesSiteCode__c': p['mesSite']})

        fl = o.file('CMN_Line__c', 'ExternalKey__c', {'Plant__r.PlantCode__c': R_PLANT, 'ProductGroup__r.GroupCode__c': R_PG})
        fo = o.file('CMN_Operation__c', 'ExternalKey__c', {'Line__r.ExternalKey__c': R_LINE})
        for ln in m['lines']:
            lk = f"{ln['plant']}-{ln['line']}"
            o.add(fl, {'ExternalKey__c': lk, 'LineCode__c': ln['line'], 'Name': ln['name'], 'Plant__r.PlantCode__c': ln['plant'],
                       'ProductGroup__r.GroupCode__c': ln['productGroup'], 'MesLineCode__c': ln['mesLine']})
            for op in ln['operations']:
                o.add(fo, {'ExternalKey__c': f"{lk}-{op['op']}", 'OpCode__c': op['op'], 'Name': op['name'], 'Line__r.ExternalKey__c': lk,
                           'Sequence__c': op['seq'], 'OperationType__c': op['type']})
        self.add_cr('CMN-00-MDM-002', 'CMN_Operation__c에 ExternalKey__c(Text(80), External ID, Unique) 추가. 이관·데모 upsert 키', '{PlantCode}-{LineCode}-{OpCode}')

        self.codes()

        fc = o.file('Account', 'OemCode__c', tag='customer', note='RecordTypeDeveloperName → RecordTypeId')
        for c in m['customers']:
            o.add(fc, {'OemCode__c': c['oemCode'], 'RecordTypeDeveloperName': 'CMN_Customer', 'Name': c['name'], 'CustomerGroup__c': c['group'],
                       'SapCustomerNo__c': c['sapNo'], 'ContainmentDueDays__c': c['containmentDays'], 'EightDDueDays__c': c['eightDDays'],
                       'RootCauseDueDays__c': c['rootCauseDays'], 'PpapDefaultLevel__c': str(c['ppapLevel']),
                       'AuditStandard__c': ';'.join(c['audit']), 'ClaimFormTemplate__c': c['claimForm']})
        self.add_cr('CMN-00-MDM-003', 'Account.RootCauseDueDays__c(Vol.5 요청)를 MDM-003 본문에 추가', '고객별 7~10일')
        fs = o.file('Account', 'SapVendorNo__c', tag='supplier', note='RecordTypeDeveloperName → RecordTypeId')
        for s in m['suppliers']:
            o.add(fs, {'SapVendorNo__c': s['vendorNo'], 'RecordTypeDeveloperName': 'CMN_Supplier', 'Name': s['name'],
                       'SupplierGrade__c': s['grade'], 'IatfCertified__c': str(s['iatf']).lower(), 'IatfExpiry__c': s['iatfExpiry'],
                       'PortalEnabled__c': str(s['portal']).lower(), 'BillingCountry': s['country']})

        f = o.file('CMN_Vehicle__c', 'ExternalKey__c', {'Customer__r.OemCode__c': R_CUST})
        for v in m['vehicles']:
            o.add(f, {'ExternalKey__c': v['key'], 'VehicleCode__c': v['code'], 'Name': v['name'], 'Customer__r.OemCode__c': v['customer'],
                      'SopDate__c': v['sop'], 'EopDate__c': v['eop']})

        fi = o.file('CMN_Item__c', 'ItemNo__c', {'ProductGroup__r.GroupCode__c': R_PG, 'Customer__r.OemCode__c': R_CUST})
        fip = o.file('CMN_ItemPlant__c', 'ExternalKey__c', {'Item__r.ItemNo__c': R_ITEM, 'Plant__r.PlantCode__c': R_PLANT})
        fiv = o.file('CMN_ItemVehicle__c', 'ExternalKey__c', {'Item__r.ItemNo__c': R_ITEM, 'Vehicle__r.ExternalKey__c': R_VEH})
        for it in m['items']:
            o.add(fi, {'ItemNo__c': it['itemNo'], 'Name': it['name'], 'ItemType__c': it['type'], 'ProductGroup__r.GroupCode__c': it['group'],
                       'Customer__r.OemCode__c': it.get('customer'), 'CustomerPartNo__c': it.get('customerPartNo'),
                       'DrawingNo__c': 'DWG-' + it['itemNo'], 'DrawingRev__c': 'C', 'PartCategory__c': it.get('partCategory')})
            for p in it['plants']:
                o.add(fip, {'ExternalKey__c': f"{it['itemNo']}-{p}", 'Item__r.ItemNo__c': it['itemNo'], 'Plant__r.PlantCode__c': p, 'Status__c': 'ACTIVE'})
            for v in it['vehicles']:
                o.add(fiv, {'ExternalKey__c': f"{it['itemNo']}-{v}", 'Item__r.ItemNo__c': it['itemNo'], 'Vehicle__r.ExternalKey__c': v, 'UsagePerVehicle__c': 1})
        self.add_cr('CMN-00-MDM-004', 'CMN_ItemVehicle__c에 ExternalKey__c 추가(UsagePerVehicle__c는 Vol.5 요청)', '{ItemNo}-{VehicleKey}')

        f = o.file('CMN_SupplierItem__c', 'ExternalKey__c', {'Supplier__r.SapVendorNo__c': R_SUPP, 'Item__r.ItemNo__c': R_ITEM, 'Plant__r.PlantCode__c': R_PLANT})
        for s in m['supplierItems']:
            k = self.si_key(s['vendor'], s['item'], s['plant'])
            self.si[(s['vendor'], s['item'], s['plant'])] = dict(s, key=k)
            o.add(f, {'ExternalKey__c': k, 'Supplier__r.SapVendorNo__c': s['vendor'], 'Item__r.ItemNo__c': s['item'], 'Plant__r.PlantCode__c': s['plant'],
                      'PpapStatus__c': s['ppap'], 'InspectionLevel__c': s['inspectionLevel']})

        f = o.file('CMN_Characteristic__c', 'ExternalKey__c', {'Item__r.ItemNo__c': R_ITEM})
        for c in m['characteristics']:
            ext = f"{c['item']}-{c['charNo']}-{c['from'].replace('-', '')}"
            self.chars[(c['item'], c['charNo'])] = dict(c, ext=ext)
            o.add(f, {'ExternalKey__c': ext, 'Item__r.ItemNo__c': c['item'], 'CharNo__c': c['charNo'], 'Name': c['name'], 'CharType__c': c['type'],
                      'Nominal__c': c.get('nominal'), 'LSL__c': c.get('lsl'), 'USL__c': c.get('usl'),
                      'Unit__c': c.get('unit') if c['type'] == 'VARIABLE' else None, 'SpecialClass__c': c['special'],
                      'SpcRequired__c': str(c.get('spc', False)).lower(), 'TargetCpk__c': c.get('targetCpk'),
                      'Status__c': 'ACTIVE', 'EffectiveFrom__c': c['from']})
        self.add_cr('CMN-00-MDM-006', 'Unit__c 값에 lm, cc/min, mA 추가', '해당 특성 Unit = ETC, 이름에 단위 표기는 마스터 unitNotes 기준')

        self.org_people()

    def codes(self):
        o, m = self.out, self.m
        groups = {
            'DEFECT_TYPE': (3, m['codes']['DEFECT_TYPE']), 'CAUSE_5M1E': (2, m['codes']['CAUSE_5M1E']),
            'RESPONSIBILITY': (1, [{'code': c} for c in m['codes']['RESPONSIBILITY']]),
            'DISPOSITION': (1, [{'code': c} for c in m['codes']['DISPOSITION']]),
            'CHANGE_TYPE': (3, self._change_tree(m['codes']['CHANGE_TYPE'])),
            'DEV_PHASE': (1, m['codes']['DEV_PHASE']),
            'DEV_ACTIVITY_TYPE': (2, [{'code': n['code'], 'children': [{'code': c} for c in n['children']]} for n in m['codes']['DEV_ACTIVITY_TYPE']]),
            'APPROVAL_ROLE': (1, [{'code': c} for c in ['QUALITY_MANAGER', 'PRODUCTION_MANAGER', 'PLANT_MANAGER', 'PURCHASING_MANAGER', 'DEV_MANAGER',
                                                        'QM_HEAD', 'LAB_RECEIVER', 'SUPPLIER_QUALITY', 'SQ_MANAGER', 'IQC_LEAD', 'PE_MANAGER',
                                                        'METROLOGY_LEAD', 'LAB_MANAGER', 'TRAINING_COORDINATOR', 'CQ_MANAGER', 'QMS_MANAGER', 'LELE_OWNER']]),
            'DOC_CLASS': (2, [{'code': c} for c in ['TEST_REPORT', 'DVPR', '8D_REPORT', 'SUPPLIER_COA', 'IQC_PHOTO', 'NCR_PHOTO', 'NCR_NOTICE',
                                                    'LAB_REPORT', 'CALIBRATION_CERT', 'CERT_SUPPLIER', 'LIMIT_SAMPLE_PHOTO', 'AUDIT_REPORT', 'AUDIT_EVIDENCE',
                                                    'FOURM_REQUEST', 'FOURM_EVIDENCE', 'PPAP_APPROVAL_NOTICE', 'MSA_REPORT', 'TRAINING_MATERIAL']]
                          + [{'code': 'PPAP', 'children': [{'code': e[1]} for e in C.PPAP_ELEMENTS]}]),
            'DEFECT_LOCATION': (1, [{'code': c} for c in ['LENS_INNER', 'LENS_OUTER', 'HOUSING', 'SEAL_LINE', 'CONNECTOR_AREA', 'BEZEL']]),
            'AI_EXCLUDE_REASON': (1, [{'code': c} for c in ['NOT_RELEVANT', 'ALREADY_REVIEWED', 'WEAK_EVIDENCE', 'OTHER']]),
            'IQC_COMMON_CHECK': (1, [{'code': c} for c in ['PACKAGING', 'LABEL', 'QUANTITY', 'CONTAMINATION']]),
            'GAUGE_TYPE': (1, [{'code': c} for c in ['MICROMETER', 'CALIPER', 'HEIGHT_GAUGE', 'AIMING_TESTER', 'LEAK_TESTER', 'VISION',
                                                     'SPECTROPHOTOMETER', 'PIN_GAUGE', 'CHECKING_FIXTURE', 'CMM', 'XRAY', 'FTIR', 'DSC']]),
        }
        names = {}
        for grp in ('DEFECT_TYPE', 'CAUSE_5M1E'):
            def walk(nodes):
                for n in nodes:
                    names[n['code']] = n.get('name', n['code'])
                    walk(n.get('children', []))
            walk(m['codes'][grp])
        for n in m['codes']['DEV_PHASE']:
            names[n['code']] = n['name']
        names.update(C.CHANGE_TYPE_NAMES)
        names.update(C.DEV_NAMES)
        fg = o.file('CMN_CodeGroup__c', 'GroupCode__c')
        files = [o.file('CMN_Code__c', 'ExternalKey__c', {'CodeGroup__r.GroupCode__c': ('CMN_CodeGroup__c', 'GroupCode__c'),
                                                          'Parent__r.ExternalKey__c': R_CODE}, tag=f'L{lv}') for lv in (1, 2, 3)]
        for grp, (maxlv, tree) in groups.items():
            o.add(fg, {'GroupCode__c': grp, 'Name': grp, 'MaxLevel__c': maxlv})

            def emit(nodes, level, parent_key, parent_path):
                for i, n in enumerate(nodes, 1):
                    code = n['code']
                    key = f'{(parent_key or grp)}/{code}'
                    label = names.get(code, code)
                    path = f'{parent_path} > {label}' if parent_path else label
                    o.add(files[level - 1], {'ExternalKey__c': key, 'CodeGroup__r.GroupCode__c': grp, 'Code__c': code,
                                             'Parent__r.ExternalKey__c': parent_key, 'Level__c': level, 'Name': label,
                                             'NameEn__c': code.replace('_', ' ').title(), 'SortOrder__c': i * 10, 'IsActive__c': 'true'})
                    self.code_key.setdefault((grp, code), key)
                    self.code_name[key] = path
                    emit(n.get('children', []), level + 1, key, path)
            emit(tree, 1, None, None)
        self.add_cr('CMN-00-MDM-007', 'CMN_Code__c.ExternalKey__c를 계층 경로 전체 {Group}/{L1}/{L2}/{L3}로 정의(같은 그룹 안 하위 코드 이름 중복 허용)', '예: CHANGE_TYPE/METHOD/CONDITION/PROCESS_PARAM')
        self.add_cr('CMN-00-MDM-007', '코드 그룹 GAUGE_TYPE·IQC_COMMON_CHECK·DEFECT_LOCATION 초기값, DOC_CLASS 값(PPAP 하위 18요소 포함) 확정', 'demo_master.json·gen_salesforce.codes() 값')

    def _change_tree(self, tree):
        out = []
        for n in tree:
            kids = []
            for k in n['children']:
                code = k['code']
                kids.append({'code': code, 'children': [{'code': c} for c in k['children']]})
            out.append({'code': n['code'], 'children': kids})
        return out

    def org_people(self):
        o, m = self.out, self.m
        fd = o.file('CMN_Department__c', 'DeptCode__c', {'Plant__r.PlantCode__c': R_PLANT}, tag='pass1')
        for d in m['departments']:
            o.add(fd, {'DeptCode__c': d['code'], 'Name': d['name'], 'Plant__r.PlantCode__c': d['plant'], 'IsActive__c': 'true'})
        fe = o.file('CMN_Employee__c', 'EmployeeNo__c', {'Department__r.DeptCode__c': R_DEPT}, tag='pass1')
        for e in m['employees']:
            o.add(fe, {'EmployeeNo__c': e['no'], 'Name': e['name'], 'NameEn__c': e['nameEn'],
                       'Email__c': f"{e['no'].lower()}@slqms.example.com", 'Department__r.DeptCode__c': e['dept'],
                       'JobGradeCode__c': 'G3' if e['psg'] else 'G5', 'HrStatus__c': 'ACTIVE'})
        # 사용자는 로더가 users/*.json으로 만든다. 여기 User CSV는 생성 후 필드 갱신용.
        for e in m['employees']:
            if e['license']:
                self.out.keys.setdefault(R_USER, set()).add(e['no'])
        fu = o.file('User', 'EmployeeNo__c', {'Department__r.DeptCode__c': R_DEPT, 'PrimaryPlant__r.PlantCode__c': R_PLANT},
                    tag='update', note='로더가 만든 사용자만 갱신(없는 사번 행은 건너뜀)')
        for e in m['employees']:
            if e['license']:
                o.add(fu, {'EmployeeNo__c': e['no'], 'Department__r.DeptCode__c': e['dept'], 'PrimaryPlant__r.PlantCode__c': e['plant'],
                           'JobGradeCode__c': 'G3', 'HrStatus__c': 'ACTIVE', 'LanguageOverride__c': 'false'})
        fd2 = o.file('CMN_Department__c', 'DeptCode__c', {'Parent__r.DeptCode__c': R_DEPT, 'Manager__r.EmployeeNo__c': R_USER}, tag='pass2')
        for d in m['departments']:
            o.add(fd2, {'DeptCode__c': d['code'], 'Parent__r.DeptCode__c': d['parent'], 'Manager__r.EmployeeNo__c': d['manager']})
        fe2 = o.file('CMN_Employee__c', 'EmployeeNo__c', {'User__r.EmployeeNo__c': R_USER}, tag='pass2-user')
        for e in m['employees']:
            if e['license']:
                o.add(fe2, {'EmployeeNo__c': e['no'], 'User__r.EmployeeNo__c': e['no']})

        fc = o.file('Contact', 'ExternalKey__c', {'Account.SapVendorNo__c': R_SUPP})
        kr = ['김', '이', '박', '최', '정', '강', '조', '윤']
        given = ['민호', '지현', '수빈', '태준', '하린', '준서', '예린', '도윤']
        for i, s in enumerate(m['suppliers']):
            for n, roles in ((1, 'QUALITY;PPAP'), (2, 'SHIPPING;MANAGEMENT')):
                o.add(fc, {'ExternalKey__c': f"CT-{s['vendorNo']}-{n:02d}", 'Account.SapVendorNo__c': s['vendorNo'],
                           'LastName': kr[(i + n) % 8], 'FirstName': given[(i * 2 + n) % 8],
                           'Email': f"{s['vendorNo'].lower()}.contact{n}@example.com", 'Title': '품질 담당' if n == 1 else '영업·관리 책임',
                           'SupplierRoles__c': roles, 'PortalPlants__c': None, 'PortalUserStatus__c': 'NONE'})
        self.add_cr('QMS-03-SPP-001', 'Contact에 ExternalKey__c 추가(협력사 담당자 이관·데모 upsert)', 'CT-{VendorNo}-{nn}')

        fa = o.file('CMN_UserPlantAccess__c', 'ExternalKey__c', {'User__r.EmployeeNo__c': R_USER, 'Plant__r.PlantCode__c': R_PLANT})
        for e in m['employees']:
            if e['license'] and e['plant']:
                o.add(fa, {'ExternalKey__c': f"{e['no']}-{e['plant']}", 'User__r.EmployeeNo__c': e['no'], 'Plant__r.PlantCode__c': e['plant'], 'AccessLevel__c': 'Edit'})

        fr = o.file('CMN_RoleAssignment__c', 'ExternalKey__c', {'Role__r.ExternalKey__c': R_CODE, 'Plant__r.PlantCode__c': R_PLANT, 'User__r.EmployeeNo__c': R_USER})
        for e in m['employees']:
            for r in e['roles']:
                o.add(fr, {'ExternalKey__c': f"RA-{r['role']}-{r['plant'] or 'ALL'}-{e['no']}", 'Role__r.ExternalKey__c': self.ck('APPROVAL_ROLE', r['role']),
                           'Plant__r.PlantCode__c': r['plant'], 'User__r.EmployeeNo__c': e['no'], 'ValidFrom__c': iso(self.D('2024-12-01'))})
        self.add_cr('CMN-00-APV-002', 'CMN_RoleAssignment__c·CMN_ApprovalTemplate__c·CMN_ApprovalTemplateStep__c에 ExternalKey__c 추가', 'RA-{Role}-{Plant 또는 ALL}-{사번}, TPL-{TypeCode}, TPL-{TypeCode}-{StepNo}')
        ft = o.file('CMN_ApprovalTemplate__c', 'ExternalKey__c')
        fts = o.file('CMN_ApprovalTemplateStep__c', 'ExternalKey__c', {'Template__r.ExternalKey__c': ('CMN_ApprovalTemplate__c', 'ExternalKey__c')})
        for type_code, desc, steps in C.APPROVAL_TEMPLATES:
            tk = f'TPL-{type_code}'
            o.add(ft, {'ExternalKey__c': tk, 'Name': desc, 'TypeCode__c': type_code, 'Scope__c': 'SYSTEM', 'AllowUserEdit__c': 'true',
                       'IsDefault__c': 'true', 'IsActive__c': 'true'})
            for no, st, rt, role, mand in steps:
                o.add(fts, {'ExternalKey__c': f'{tk}-{no}', 'Template__r.ExternalKey__c': tk, 'StepNo__c': no, 'StepType__c': st,
                            'ResolverType__c': rt, 'RoleCode__c': role, 'IsMandatory__c': str(mand).lower()})
        fdl = o.file('CMN_Delegation__c', 'ExternalKey__c', {'Delegator__r.EmployeeNo__c': R_USER, 'Delegate__r.EmployeeNo__c': R_USER})
        o.add(fdl, {'ExternalKey__c': 'DLG-E1101-20261201', 'Delegator__r.EmployeeNo__c': 'E1101', 'Delegate__r.EmployeeNo__c': 'E1102',
                    'StartAt__c': ts(self.D('2026-12-01'), 0), 'EndAt__c': ts(self.D('2026-12-05'), 23, 59), 'TypeCodes__c': None,
                    'Reason__c': '해외 고객 출장(데모)'})
        self.add_cr('CMN-00-APV-004', 'CMN_Delegation__c에 ExternalKey__c 추가', 'DLG-{위임자 사번}-{시작일 yyyymmdd}')

    # ------------------------------------------------------------ 설정 데이터
    def config(self):
        o = self.out
        f = o.file('QMS_TestItem__c', 'TestCode__c', {'ResponsibleDept__r.DeptCode__c': R_DEPT})
        for (code, name, en, cat, std, cond, jt, unit, lsl, usl, crit, qty, days, dept) in C.TEST_ITEMS:
            o.add(f, {'TestCode__c': code, 'Name': name, 'NameEn__c': en, 'Category__c': cat, 'MethodStandard__c': std, 'Condition__c': cond,
                      'JudgmentType__c': jt, 'Unit__c': unit, 'LSL__c': lsl, 'USL__c': usl, 'Criteria__c': crit, 'DefaultSampleQty__c': qty,
                      'DefaultDurationDays__c': days, 'DefaultExecutor__c': 'EXTERNAL_LAB' if dept is None else 'INTERNAL_LAB',
                      'ResponsibleDept__r.DeptCode__c': dept, 'Revision__c': 1, 'Status__c': 'ACTIVE'})
        fs = o.file('QMS_TestStandard__c', 'ExternalKey__c', {'Customer__r.OemCode__c': R_CUST, 'ProductGroup__r.GroupCode__c': R_PG})
        fl = o.file('QMS_TestStandardLine__c', 'ExternalKey__c', {'Standard__r.ExternalKey__c': ('QMS_TestStandard__c', 'ExternalKey__c'),
                                                                  'TestItem__r.TestCode__c': ('QMS_TestItem__c', 'TestCode__c')})
        stds = [
            ('TS-LENS-4M-RESIN', 'PART', None, None, 'LENS', 'CHANGE_4M', self.ck('CHANGE_TYPE', 'RESIN_GRADE'), 'CHANGE', ['MAT-UV-001', 'ENV-THS-001', 'MAT-HAZE-001']),
            ('TS-HL-NEWDEV-DV', 'PRODUCT', None, 'LAMP_HL', None, 'NEW_DEV', None, 'DV', ['ENV-THS-001', 'ENV-HH-001', 'ENV-CON-001', 'SEA-IPX9K-001', 'SEA-LEAK-001', 'MEC-VIB-001', 'OPT-BEAM-001', 'ELE-EMC-001', 'ELE-VOLT-001', 'DUR-ACT-001']),
            ('TS-HL-BMW-NEWDEV-DV', 'PRODUCT', 'BMW', 'LAMP_HL', None, 'NEW_DEV', None, 'DV', ['ENV-THS-001', 'ENV-HH-001', 'ENV-CON-001', 'SEA-IPX9K-001', 'SEA-LEAK-001', 'MEC-VIB-001', 'OPT-BEAM-001', 'MAT-UV-001', 'ELE-EMC-001', 'ELE-VOLT-001', 'DUR-ACT-001']),
            ('TS-HL-4M-PROCESS', 'PRODUCT', None, 'LAMP_HL', None, 'CHANGE_4M', self.ck('CHANGE_TYPE', 'PROCESS_PARAM'), 'CHANGE', ['ENV-CON-001', 'SEA-LEAK-001', 'ENV-HH-001']),
            ('TS-LED-NEWPART-DV', 'PART', None, None, 'LED_MODULE', 'NEW_DEV', None, 'DV', ['ENV-THS-001', 'ELE-VOLT-001', 'ELE-EMC-001']),
        ]
        self.test_standards = {}
        for key, scope, cust, pg, pc, trig, ctype, phase, tests in stds:
            self.test_standards[key] = tests
            o.add(fs, {'ExternalKey__c': key, 'Name': key, 'Scope__c': scope, 'Customer__r.OemCode__c': cust, 'ProductGroup__r.GroupCode__c': pg,
                       'PartCategory__c': pc, 'TriggerType__c': trig, 'ChangeTypes__c': ctype, 'Phase__c': phase, 'Status__c': 'ACTIVE', 'Version__c': 1})
            for i, t in enumerate(tests, 1):
                o.add(fl, {'ExternalKey__c': f'{key}-{i:02d}', 'Standard__r.ExternalKey__c': key, 'TestItem__r.TestCode__c': t,
                           'IsMandatory__c': 'true', 'Sequence__c': i * 10})
        self.add_cr('QMS-02-DVQ-002', 'QMS_TestStandard__c·QMS_TestStandardLine__c에 ExternalKey__c 추가, ChangeTypes__c 값 형식을 CHANGE_TYPE 경로 키(쉼표 구분)로 명시', 'TS-{요지}, TS-{요지}-{nn}')

        # 샘플링(데모 가정 표 — ISO 2859-1·c=0 공식 표가 아님)
        fp = o.file('QMS_SamplingPlan__c', 'PlanCode__c')
        fr = o.file('QMS_SamplingPlanRow__c', 'ExternalKey__c', {'Plan__r.PlanCode__c': ('QMS_SamplingPlan__c', 'PlanCode__c')})
        o.add(fp, {'PlanCode__c': 'C0-DEMO', 'Name': 'c=0 데모 표(가정 값, 공식 표 아님)', 'Method__c': 'C0', 'Status__c': 'ACTIVE'})
        self.sampling = []
        bands = [(1, 50), (51, 150), (151, 500), (501, 1200), (1201, 3200), (3201, None)]
        sizes = {'NORMAL': [5, 8, 13, 20, 32, 50], 'TIGHTENED': [8, 13, 20, 32, 50, 80], 'REDUCED': [3, 5, 8, 13, 20, 32]}
        for lvl, ss in sizes.items():
            for (a, b), n in zip(bands, ss):
                self.sampling.append((lvl, a, b, n))
                o.add(fr, {'ExternalKey__c': f'C0-DEMO-{lvl}-{a}', 'Plan__r.PlanCode__c': 'C0-DEMO', 'LotSizeFrom__c': a, 'LotSizeTo__c': b,
                           'Level__c': lvl, 'SampleSize__c': n, 'AcceptNo__c': 0, 'RejectNo__c': 1})
        o.add(fp, {'PlanCode__c': 'FULL-100', 'Name': '전수', 'Method__c': 'FULL', 'Status__c': 'ACTIVE'})
        self.add_cr('QMS-03-IQC-001', 'QMS_SamplingPlanRow__c·QMS_IqcStandard__c·QMS_IqcStandardLine__c에 ExternalKey__c 추가', 'C0-DEMO-{Level}-{From}, IQS-{ItemNo}-{Plant}-V{n}, IQS-...-L{nn}')
        self.add_cr('QMS-03-IQC-001', '데모 샘플링 표는 가정 값(c=0, 6구간). SL 현행 표로 교체', 'C0-DEMO')
        self.iqc_standards()
        self.ppap_config()
        self.other_config()

    def sample_size(self, level, qty):
        lvl = 'NORMAL' if level in ('NORMAL', 'SKIP') else level
        for lv, a, b, n in self.sampling:
            if lv == lvl and qty >= a and (b is None or qty <= b):
                return min(n, int(qty))
        return int(qty)

    def iqc_standards(self):
        o = self.out
        fs = o.file('QMS_IqcStandard__c', 'ExternalKey__c', {'Item__r.ItemNo__c': R_ITEM, 'Plant__r.PlantCode__c': R_PLANT,
                                                             'DefaultSamplingPlan__r.PlanCode__c': ('QMS_SamplingPlan__c', 'PlanCode__c')})
        fl = o.file('QMS_IqcStandardLine__c', 'ExternalKey__c', {'Standard__r.ExternalKey__c': ('QMS_IqcStandard__c', 'ExternalKey__c'),
                                                                 'Characteristic__r.ExternalKey__c': R_CHAR})
        self.iqs = {}
        coa_req = {'LENS', 'LED_MODULE', 'CONNECTOR', 'HOUSING'}
        seen = set()
        for s in self.m['supplierItems']:
            item, plant = s['item'], s['plant']
            if (item, plant) in seen:
                continue
            seen.add((item, plant))
            it = self.items[item]
            key = f'IQS-{item}-{plant}-V1'
            lines = []
            n = 0
            for (ci, cn), c in self.chars.items():
                if ci != item:
                    continue
                n += 1
                gauge = 'GA-KR01-0456' if item.startswith('P-HSG') else ('GA-KR01-0511' if c.get('unit') == 'mm' else None)
                lines.append({'ExternalKey__c': f'{key}-L{n:02d}', 'Standard__r.ExternalKey__c': key, 'Sequence__c': n * 10,
                              'Characteristic__r.ExternalKey__c': c['ext'], 'CheckItemName__c': None, 'CheckType__c': c['type'],
                              'Method__c': {'mm': '측정기 측정(마이크로미터·하이트 게이지)', '%': '분광 측정·X-ray', 'V': '전기 특성 측정',
                                            'N': '삽입력 시험기', 'ETC': '광속 적분구 측정'}.get(c.get('unit'), '육안·한도견본 비교'),
                              'Frequency__c': 'EVERY_LOT', 'CoaCheck__c': str(c['type'] == 'VARIABLE').lower(),
                              'CoaSampleQty__c': 5 if c['type'] == 'VARIABLE' else None, '_char': c, '_gauge': gauge})
            if not lines:
                n += 1
                lines.append({'ExternalKey__c': f'{key}-L{n:02d}', 'Standard__r.ExternalKey__c': key, 'Sequence__c': n * 10,
                              'Characteristic__r.ExternalKey__c': None, 'CheckItemName__c': '도면 주요 치수 합부(검사구)', 'CheckType__c': 'ATTRIBUTE',
                              'Method__c': '검사구 체결 확인', 'Frequency__c': 'EVERY_LOT', 'CoaCheck__c': 'false', 'CoaSampleQty__c': None,
                              '_char': None, '_gauge': None})
            for chk, typ in (('포장 상태', 'VISUAL'), ('라벨·식별 표시', 'ATTRIBUTE')):
                n += 1
                lines.append({'ExternalKey__c': f'{key}-L{n:02d}', 'Standard__r.ExternalKey__c': key, 'Sequence__c': n * 10,
                              'Characteristic__r.ExternalKey__c': None, 'CheckItemName__c': chk, 'CheckType__c': typ,
                              'Method__c': '육안 확인', 'Frequency__c': 'EVERY_LOT', 'CoaCheck__c': 'false', 'CoaSampleQty__c': None,
                              '_char': None, '_gauge': None})
            self.iqs[(item, plant)] = {'key': key, 'lines': lines, 'coaRequired': it.get('partCategory') in coa_req}
            o.add(fs, {'ExternalKey__c': key, 'Item__r.ItemNo__c': item, 'Plant__r.PlantCode__c': plant, 'Version__c': 1, 'Status__c': 'ACTIVE',
                       'DefaultSamplingPlan__r.PlanCode__c': 'C0-DEMO', 'CoaRequired__c': str(it.get('partCategory') in coa_req).lower(),
                       'InspectionLeadHours__c': 24, 'Name': f"{it['name']} 수입검사 기준서({plant})"})
            for ln in lines:
                o.add(fl, {k: v for k, v in ln.items() if not k.startswith('_')})

    def ppap_config(self):
        o = self.out
        fe = o.file('QMS_PpapElement__c', 'ElementCode__c', {'DocClass__r.ExternalKey__c': R_CODE})
        for no, code, name, en, itype in C.PPAP_ELEMENTS:
            lv3 = 'R' if no in C.PPAP_LEVEL3_RETAINED else 'S'
            lv1 = 'S' if code in ('PSW', 'AAR') else 'R'
            lv2 = 'S' if code in ('PSW', 'AAR', 'DESIGN_RECORD', 'ENG_CHANGE', 'DIM_RESULT', 'MAT_PERF_TEST', 'INITIAL_PROCESS_STUDY') else 'R'
            o.add(fe, {'ElementCode__c': f'AIAG_PPAP4-{no}', 'ElementSet__c': 'AIAG_PPAP4', 'Sequence__c': int(no), 'Name': name, 'NameEn__c': en,
                       'DocClass__r.ExternalKey__c': self.ck('DOC_CLASS', code), 'InputType__c': itype,
                       'Level1__c': lv1, 'Level2__c': lv2, 'Level3__c': lv3, 'Level4__c': 'C' if code == 'CSR_RECORD' else lv3, 'Level5__c': 'R',
                       'Guidance__c': '[데모 가정] 레벨별 S/R 값은 매뉴얼 원문 검수 전 임시 값이다. ' + name + ' 제출본이 최신 리비전인지 확인한다.',
                       'IsActive__c': 'true'})
        self.add_cr('QMS-03-PPA-001', 'PPAP 요소 레벨별 S/R 값 확정(품질경영팀 매뉴얼 검수)', '데모 가정: 레벨3 = 샘플·마스터 샘플·검사 보조구 R, 나머지 S. Guidance에 [데모 가정] 표시')
        fr = o.file('QMS_PpapLevelRule__c', 'ExternalKey__c')
        rules = [('PLR-SUP-4M', 'SUPPLIER', 'CHANGE_4M', None, None, None, 'ANY', 3), ('PLR-SUP-4M-BMW-LENS', 'SUPPLIER', 'CHANGE_4M', None, 'LENS', 'BMW', 'ANY', 3),
                 ('PLR-SUP-TOOL', 'SUPPLIER', 'TOOL_TRANSFER', None, None, None, 'ANY', 3), ('PLR-SUP-INACTIVE', 'SUPPLIER', 'LONG_INACTIVE', None, None, None, 'NO', 2),
                 ('PLR-SUP-NEW', 'SUPPLIER', 'NEW_PART', None, None, None, 'ANY', 3)]
        for k, sc, trig, ct, pc, cg, hsc, lv in rules:
            o.add(fr, {'ExternalKey__c': k, 'Scope__c': sc, 'Trigger__c': trig, 'ChangeTypes__c': ct, 'PartCategory__c': pc, 'CustomerGroup__c': cg,
                       'HasSpecialChar__c': hsc, 'ElementSet__c': 'AIAG_PPAP4', 'Level__c': str(lv), 'IsActive__c': 'true'})
        self.add_cr('QMS-03-PPA-001', 'QMS_PpapLevelRule__c에 ExternalKey__c 추가', 'PLR-{요지}')
        fc = o.file('QMS_ChangeTypeRule__c', 'ExternalKey__c', {'ChangeType__r.ExternalKey__c': R_CODE})
        rules = [('CTR-RESIN-GRADE', 'RESIN_GRADE', 'BOTH', 'A', 'NOTICE', 30, True, True, False, True, 30),
                 ('CTR-MOLD-REPAIR', 'MOLD_REPAIR', 'BOTH', 'B', 'NOT_REQUIRED', None, False, True, False, True, 14),
                 ('CTR-PROCESS-PARAM', 'PROCESS_PARAM', 'INTERNAL', 'B', 'NOT_REQUIRED', None, True, False, False, True, 14),
                 ('CTR-GAUGE-METHOD', 'GAUGE_METHOD', 'BOTH', 'C', 'NOT_REQUIRED', None, False, False, False, False, 7),
                 ('CTR-SITE-TRANSFER', 'SITE_TRANSFER', 'BOTH', 'A', 'APPROVAL', 90, True, True, True, True, 90)]
        for k, ct, sc, risk, notice, lead, qual, sppap, cppap, stab, minlead in rules:
            o.add(fc, {'ExternalKey__c': k, 'ChangeType__r.ExternalKey__c': self.ck('CHANGE_TYPE', ct), 'Scope__c': sc, 'RiskClass__c': risk,
                       'CustomerNotice__c': notice, 'CustomerLeadDays__c': lead, 'QualTestRequired__c': str(qual).lower(),
                       'SupplierPpapRequired__c': str(sppap).lower(), 'CustomerPpapRequired__c': str(cppap).lower(),
                       'StabilizationRequired__c': str(stab).lower(), 'PfmeaReview__c': 'true', 'ControlPlanUpdate__c': 'true',
                       'WorkInstructionUpdate__c': 'false', 'TrialRun__c': 'true', 'MsaRequired__c': str(ct == 'GAUGE_METHOD').lower(),
                       'TrainingRequired__c': 'false', 'LimitSampleReview__c': 'false', 'MinLeadDays__c': minlead, 'Status__c': 'ACTIVE', 'Version__c': 1})
        self.add_cr('QMS-06-4MC-001', 'QMS_ChangeTypeRule__c에 ExternalKey__c 추가(SL 기준표 이관 키)', 'CTR-{요지}')

    def other_config(self):
        o = self.out
        f = o.file('QMS_LabAnalysisItem__c', 'ItemCode__c', {'Plant__r.PlantCode__c': R_PLANT})
        for code, name, en, cat, std, eq, rt, unit, tat in C.LAB_ITEMS:
            o.add(f, {'ItemCode__c': code, 'Name': name, 'NameEn__c': en, 'Category__c': cat, 'MethodStandard__c': std, 'EquipmentTypeCodes__c': eq,
                      'ResultType__c': rt, 'Unit__c': unit, 'StandardTatDays__c': tat, 'Plant__r.PlantCode__c': 'KR01', 'IsExternal__c': 'false',
                      'RequiredQualTypeCode__c': 'LAB_ANALYST', 'Status__c': 'ACTIVE'})
        f = o.file('QMS_QualificationType__c', 'TypeCode__c')
        for code, name, en, cat, months in C.QUAL_TYPES:
            o.add(f, {'TypeCode__c': code, 'Name': name, 'NameEn__c': en, 'Category__c': cat,
                      'ScopeDimensions__c': 'PLANT;PART_CATEGORY' if cat == 'INSPECTOR' else ('PLANT;AUDIT_STANDARD' if cat == 'AUDITOR' else 'PLANT'),
                      'ValidMonths__c': months, 'RequiresVisionTest__c': str(cat == 'INSPECTOR').lower(), 'MinExperienceMonths__c': 6,
                      'RenewalRule__c': 'RETRAIN_AND_ACTIVITY' if cat == 'AUDITOR' else 'REEXAM', 'IsExternalCert__c': str(code == 'AUDITOR_VDA63').lower(),
                      'Status__c': 'ACTIVE'})
        f = o.file('QMS_TrainingCourse__c', 'CourseCode__c', {'OwnerDept__r.DeptCode__c': R_DEPT})
        for code, name, cat, deliv, hours in C.COURSES:
            o.add(f, {'CourseCode__c': code, 'Name': name, 'Category__c': cat, 'DeliveryType__c': deliv, 'DurationHours__c': hours,
                      'HasExam__c': str(deliv != 'ELEARNING_EXTERNAL').lower(), 'PassScore__c': 70, 'MinAttendancePct__c': 90,
                      'Objectives__c': f'{name} 업무 수행에 필요한 기준과 판정 방법을 익힌다.', 'RefreshMonths__c': 24,
                      'Languages__c': 'ko;en_US', 'OwnerDept__r.DeptCode__c': 'D3100', 'Version__c': 1, 'Status__c': 'ACTIVE'})
        # 심사 체크리스트(VDA 6.3 형식, SL 자체 문구) + IATF 공정 심사(적합·부적합)
        fc = o.file('QMS_AuditChecklist__c', 'ChecklistCode__c')
        fq = o.file('QMS_AuditQuestion__c', 'ExternalKey__c', {'Checklist__r.ChecklistCode__c': ('QMS_AuditChecklist__c', 'ChecklistCode__c')})
        fg = o.file('QMS_AuditGradeRule__c', 'ExternalKey__c', {'Checklist__r.ChecklistCode__c': ('QMS_AuditChecklist__c', 'ChecklistCode__c')})
        o.add(fc, {'ChecklistCode__c': 'VDA63-SL-DEMO-V1', 'Family__c': 'VDA63', 'Version__c': 1, 'Name': 'VDA 6.3 형식 공정 심사(SL 문구, 데모)',
                   'Scheme__c': 'VDA63', 'RecordTypes__c': 'INTERNAL;SUPPLIER;CUSTOMER', 'AuditTypes__c': 'PROCESS;PRE_ASSESSMENT;CUSTOMER_AUDIT',
                   'StandardRef__c': 'VDA 6.3 형식(질문 번호만, 문구는 SL 자체)', 'AllowedScores__c': '0,4,6,8,10', 'TextSource__c': 'SL_WORDING',
                   'LicenseConfirmed__c': 'false', 'EffectiveFrom__c': iso(self.D('2025-01-01')), 'TotalMethod__c': 'QUESTION_SUM', 'Status__c': 'ACTIVE'})
        self.vda_q = []
        for i, (qno, el, sub, text, star) in enumerate(C.VDA_QUESTIONS, 1):
            k = f'VDA63-SL-DEMO-V1-{qno}'
            self.vda_q.append((k, qno, el, sub, text, star))
            o.add(fq, {'ExternalKey__c': k, 'Checklist__r.ChecklistCode__c': 'VDA63-SL-DEMO-V1', 'QuestionNo__c': qno, 'Element__c': el,
                       'SubElement__c': sub or None, 'Sequence__c': i * 10, 'QuestionText__c': text, 'IsStarQuestion__c': str(star).lower(),
                       'AnswerType__c': 'SCORE_STEPS', 'MaxPoints__c': 10, 'Weight__c': 1, 'AllowNA__c': 'true',
                       'EvidenceKeys__c': {'P6.1.4': 'EV-4M-HISTORY', 'P6.2.3': 'EV-SPC-CAPABILITY', 'P6.3.1': 'EV-TRAINING', 'P6.4.1': 'EV-GAUGE-CAL',
                                           'P4.5': 'EV-PPAP'}.get(qno)})
        for k, rt, grade, mn, mx, cond, thr, applies, res, seq, desc in [
                ('VDA63-SL-DEMO-V1-A', 'GRADE_BAND', 'A', 90, 100, None, None, None, None, 1, '[데모 가정] 90% 이상 A'),
                ('VDA63-SL-DEMO-V1-B', 'GRADE_BAND', 'B', 80, 89.99, None, None, None, None, 2, '[데모 가정] 80% 이상 90% 미만 B'),
                ('VDA63-SL-DEMO-V1-C', 'GRADE_BAND', 'C', 0, 79.99, None, None, None, None, 3, '[데모 가정] 80% 미만 C'),
                ('VDA63-SL-DEMO-V1-DG1', 'DOWNGRADE', None, None, None, 'STAR_QUESTION_SCORE_LE', 0, 'A,B', 'C', 4, '[데모 가정] 별표 질문 0점이면 C')]:
            o.add(fg, {'ExternalKey__c': k, 'Checklist__r.ChecklistCode__c': 'VDA63-SL-DEMO-V1', 'RuleType__c': rt, 'Grade__c': grade,
                       'MinPercent__c': mn, 'MaxPercent__c': mx, 'Condition__c': cond, 'Threshold__c': thr, 'AppliesToGrades__c': applies,
                       'ResultGrade__c': res, 'Sequence__c': seq, 'Description__c': desc})
        self.add_cr('QMS-06-IAU-001', 'QMS_AuditGradeRule__c에 ExternalKey__c 추가, 등급·강등 규칙 실제 값 확정(원문 검수)', '[데모 가정] A≥90, B≥80, C<80, 별표 0점 → C')
