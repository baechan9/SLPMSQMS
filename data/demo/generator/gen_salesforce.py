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

from common import ROOT, out_path, rng, write_csv, write_json  # noqa: E402
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
            o.add(f, {'PlantCode__c': p['code'], 'Name': p['name'], 'Company__r.CompanyCode__c': p['company'],
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
        # DOC_CLASS 검토 반영 값(review-pack Vol.2·3·4·5·6a·6b·6c). 기존 데모 값(8D_REPORT 등)은 다른 데이터가 참조해 유지한다
        DOC_CLASS_CR = ['TEST_PHOTO', 'OCAP_EVIDENCE', 'CUSTOMER_COA', 'HZD_EVIDENCE', 'LELE_EVIDENCE', 'LELE_APPLY_EVIDENCE', 'PPAP_PACKAGE',
                        'PPAP_CUSTOMER_APPROVAL', 'EIGHTD_REPORT', 'EIGHTD_EVIDENCE', 'EIGHTD_TEMPLATE', 'CLAIM_CUSTOMER_DOC', 'CLAIM_COST_EVIDENCE',
                        'B2B_SOURCE_FILE', 'CUSTOMER_SCORECARD', 'WORK_INSTRUCTION', 'COMPANY_STANDARD', 'DESIGN_GUIDE', 'NCR_EVIDENCE',
                        'LIMIT_SAMPLE_CUSTOMER_APPROVAL', 'LIMIT_SAMPLE_CHECK_PHOTO', 'TRAINING_CERT', 'QUALIFICATION_CERT', 'GAUGE_DISPOSAL_CONSENT',
                        'MSA_CHART', 'LAB_RAW_DATA', 'LAB_IMAGE', 'LAB_EXTERNAL_REPORT', 'AUDIT_EVIDENCE_PACKAGE', 'AUDIT_PREP_DOC', 'FINDING_EVIDENCE',
                        'CUSTOMER_AUDIT_REPORT', 'CUSTOMER_AUDIT_RESPONSE', 'CERT_SL', 'CB_REPORT', 'CB_RESPONSE', 'MGMT_REVIEW_INPUT', 'IMP_DELIVERABLE']
        o, m = self.out, self.m
        groups = {
            'DEFECT_TYPE': (3, m['codes']['DEFECT_TYPE']), 'CAUSE_5M1E': (3, m['codes']['CAUSE_5M1E']),  # 3단계 운영(Vol.5 요청)
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
                                                    'FOURM_REQUEST', 'FOURM_EVIDENCE', 'PPAP_APPROVAL_NOTICE', 'MSA_REPORT', 'TRAINING_MATERIAL']
                                                   + DOC_CLASS_CR]
                          + [{'code': 'PPAP', 'children': [{'code': e[1]} for e in C.PPAP_ELEMENTS] + [{'code': 'SUB_COMPONENT'}]}]),
            'DEFECT_LOCATION': (1, [{'code': c} for c in ['LENS_INNER', 'LENS_OUTER', 'HOUSING', 'SEAL_LINE', 'CONNECTOR_AREA', 'BEZEL']]),
            'AI_EXCLUDE_REASON': (1, [{'code': c} for c in ['NOT_RELEVANT', 'ALREADY_REVIEWED', 'WEAK_EVIDENCE', 'NOT_APPLICABLE', 'OTHER']]),
            # 검토 반영(review-pack Vol.5 B2B-005, Vol.6c IAU-001): 그룹만 먼저 두고 QMS_PROCESS 값(책임 부서 속성)은 IAU WI가 채운다
            'ALERT_DISMISS_REASON': (1, [{'code': c} for c in ['FALSE_ALARM', 'ALREADY_HANDLED', 'NOT_APPLICABLE', 'OTHER']]),
            'QMS_PROCESS': (1, []),
            'IQC_COMMON_CHECK': (1, [{'code': c} for c in ['PACKAGING', 'LABEL', 'QUANTITY', 'CONTAMINATION']]),
            # CMN-00-MTG-001 회의 유형(검토 반영 Vol.6c: MANAGEMENT_REVIEW)
            'MEETING_TYPE': (1, [{'code': c} for c in ['QUALITY_MEETING', 'HORIZONTAL_DEPLOYMENT', 'GATE_REVIEW', 'CUSTOMER_RESPONSE',
                                                       'MANAGEMENT_REVIEW']]),
            'GAUGE_TYPE': (1, [{'code': c} for c in ['MICROMETER', 'CALIPER', 'HEIGHT_GAUGE', 'AIMING_TESTER', 'LEAK_TESTER', 'VISION',
                                                     'SPECTROPHOTOMETER', 'PIN_GAUGE', 'CHECKING_FIXTURE', 'CMM', 'XRAY', 'FTIR', 'DSC',
                                                     'DIAL_GAUGE', 'HARDNESS_TESTER', 'MOISTURE_ANALYZER', 'MICROSCOPE']]),
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
        names.update({'QUALITY_MEETING': '품질회의', 'HORIZONTAL_DEPLOYMENT': '수평전개 회의', 'GATE_REVIEW': '게이트 리뷰',
                      'CUSTOMER_RESPONSE': '고객 대응 회의', 'MANAGEMENT_REVIEW': '경영검토'})
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
        # User는 사용자 정의 객체를 Lookup할 수 없어(플랫폼 제약) 부서·기본 공장을 코드로 둔다(CMN-00-MDM-001 명세 차이)
        fu = o.file('User', 'EmployeeNo__c', {},
                    tag='update', note='로더가 만든 사용자만 갱신(없는 사번 행은 건너뜀)')
        for e in m['employees']:
            if e['license']:
                o.add(fu, {'EmployeeNo__c': e['no'], 'DepartmentCode__c': e['dept'], 'PrimaryPlantCode__c': e['plant'],
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
                gauge = None
                if plant == 'KR01' and c.get('unit') == 'mm':
                    gauge = 'GA-KR01-0456' if (item, cn) == ('P-HSG-BE1', 'C10') else ('GA-KR01-0512' if cn == 'C20' and item.startswith('P-HSG') else 'GA-KR01-0511')
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

    # ------------------------------------------------------------ 사례 이력(NCR·8D·클레임)
    def plan_cases(self):
        """명세 S0 분포를 지키는 종결 사례와 미종결 NCR 목록을 만든다."""
        claim_take = {('INNER_FOG', 'DISPENSER_FLOW'): 2, ('INNER_FOG', 'VENT_MEMBRANE'): 1, ('DRL_FLICKER', 'LED_SOLDER'): 2,
                      ('DRL_FLICKER', 'PIN_DEFORM'): 1, ('AIM_OUT', 'ACT_GEAR'): 2, ('LENS_SCRATCH', 'STD_NOT_FOLLOWED'): 1}
        claim_extra = [('LEVELING_FAIL', 'ACT_GEAR', 3), ('HV_LOW', 'MOLD_WEAR', 1), ('LED_OFF', 'SKILL', 2), ('LEAK_RATE', 'OVEN_TEMP', 1), ('INNER_FOREIGN', 'DUST', 2)]
        ncr_extra = [('SOLDER_VOID', 'LED_SOLDER', 1), ('HOLE_POSITION', 'HSG_WARP', 2), ('HOLE_POSITION', 'MOLD_WEAR', 2), ('INNER_FOREIGN', 'DUST', 5),
                     ('LED_OFF', 'ESD_CONTROL', 3), ('LEAK_RATE', 'OVEN_TEMP', 3), ('LEAK_RATE', 'CURING_TIME', 2), ('BEZEL_SCRATCH', 'STD_NOT_FOLLOWED', 5),
                     ('LENS_THICKNESS', 'MOLD_WEAR', 3)]
        claims, ncrs = [], []
        for defect, cause, n in C.CASE_DISTRIBUTION:
            take = claim_take.get((defect, cause), 0)
            claims += [(defect, cause)] * take
            ncrs += [(defect, cause)] * (n - take)
        for defect, cause, n in claim_extra:
            claims += [(defect, cause)] * n
        for defect, cause, n in ncr_extra:
            ncrs += [(defect, cause)] * n
        assert len(claims) == 18 and len(ncrs) == 58, (len(claims), len(ncrs))
        return claims, ncrs

    def pick_context(self, r, defect, cause):
        """불량·원인으로 품번·공장·라인·협력사를 정한다."""
        info = C.DEFECTS[defect]
        cinfo = C.CAUSES[cause]
        supplier_part = {'VENT_MEMBRANE': 'P-VENT-01', 'HSG_WARP': r.choice(['P-HSG-BE1', 'P-HSG-HE1']), 'LED_SOLDER': r.choice(['P-LED-HE1', 'P-LED-BE1']),
                         'PIN_DEFORM': 'P-CON-01'}
        if cinfo['supplier']:
            part = supplier_part[cause]
            cands = [s for s in self.m['supplierItems'] if s['item'] == part and s['plant'] == 'KR01'] or [s for s in self.m['supplierItems'] if s['item'] == part]
            s = cands[0]
            fg = r.choice([i for i in info['items'] if self.items[i]['type'] == 'FG'] or ['92101-HE1L'])
            return {'item': part, 'plant': s['plant'], 'line': None, 'op': None, 'vendor': s['vendor'], 'si': self.si_key(s['vendor'], part, s['plant']), 'fg': fg}
        item = r.choice(info['items'])
        plant = self.items[item]['plants'][0] if item != '63117-BE1L' else r.choice(['KR01', 'KR01', 'PL01'])
        if item.startswith('S-LENS'):
            line = 'L03' if defect in ('COATING_CRACK',) or cause in ('COATING_CURE', 'HUMIDITY') else 'L02'
        elif self.items[item]['type'] == 'FG':
            line = {'KR01': 'L01' if 'BE1' in item else 'L05', 'KR02': 'L01'}.get(plant, 'L01')
        else:
            line = None
            plant = 'KR01'
        op = None
        if line and cinfo.get('op'):
            ops = [o['op'] for ln in self.m['lines'] if ln['plant'] == plant and ln['line'] == line for o in ln['operations']]
            op = cinfo['op'] if cinfo['op'] in ops else None
        return {'item': item, 'plant': plant, 'line': line, 'op': op, 'vendor': None, 'si': None, 'fg': item}

    def text(self, r, defect, ctx, where, qty):
        info = C.DEFECTS[defect]
        it = self.items[ctx['fg']]
        veh = self.m['vehicles']
        vname = next((v['code'] for v in veh if v['key'] in it.get('vehicles', [])), 'HE1')
        return r.choice(info['phen']).format(veh=vname, side='LH' if 'L' in ctx['fg'][-2:] else 'RH', where=where, qty=qty,
                                             val=r.choice(['0.27', '0.31', '0.34', '+0.26', '3.12', '31']), pin=r.randint(2, 11))

    def history(self):
        o = self.out
        self.f_ncr = o.file('QMS_NCR__c', 'RecordNo__c', {
            'Plant__r.PlantCode__c': R_PLANT, 'Line__r.ExternalKey__c': R_LINE, 'Operation__r.ExternalKey__c': R_OP, 'Item__r.ItemNo__c': R_ITEM,
            'Supplier__r.SapVendorNo__c': R_SUPP, 'SupplierItem__r.ExternalKey__c': R_SI, 'SupplierShareTo__r.SapVendorNo__c': R_SUPP,
            'Customer__r.OemCode__c': R_CUST, 'Vehicle__r.ExternalKey__c': R_VEH, 'DetectedBy__r.EmployeeNo__c': R_USER,
            'DefectType__r.ExternalKey__c': R_CODE, 'SuspectedCause__r.ExternalKey__c': R_CODE, 'Responsibility__r.ExternalKey__c': R_CODE,
            'ResponsibleDept__r.DeptCode__c': R_DEPT, 'RootCause__r.ExternalKey__c': R_CODE, 'ClosedBy__r.EmployeeNo__c': R_USER,
            'Characteristic__r.ExternalKey__c': R_CHAR})
        self.f_8d = o.file('QMS_EightD__c', 'RecordNo__c', {
            'Plant__r.PlantCode__c': R_PLANT, 'Item__r.ItemNo__c': R_ITEM, 'Customer__r.OemCode__c': R_CUST, 'Supplier__r.SapVendorNo__c': R_SUPP,
            'ResponsibleDept__r.DeptCode__c': R_DEPT, 'Champion__r.EmployeeNo__c': R_USER, 'Leader__r.EmployeeNo__c': R_USER,
            'DefectType__r.ExternalKey__c': R_CODE, 'OccurrenceCauseCode__r.ExternalKey__c': R_CODE, 'EscapeCauseCode__r.ExternalKey__c': R_CODE,
            'Characteristic__r.ExternalKey__c': R_CHAR})
        self.f_step = o.file('QMS_EightDStep__c', 'ExternalKey__c', {'EightD__r.RecordNo__c': ('QMS_EightD__c', 'RecordNo__c'),
                                                                     'SubmittedBy__r.EmployeeNo__c': R_USER, 'ApprovedBy__r.EmployeeNo__c': R_USER})
        self.f_team = o.file('QMS_EightDTeamMember__c', 'ExternalKey__c', {'EightD__r.RecordNo__c': ('QMS_EightD__c', 'RecordNo__c'),
                                                                           'User__r.EmployeeNo__c': R_USER, 'Department__r.DeptCode__c': R_DEPT})
        self.f_act = o.file('QMS_EightDAction__c', 'ExternalKey__c', {'EightD__r.RecordNo__c': ('QMS_EightD__c', 'RecordNo__c'),
                                                                      'Owner__r.EmployeeNo__c': R_USER, 'ResponsibleDept__r.DeptCode__c': R_DEPT,
                                                                      'VerifiedBy__r.EmployeeNo__c': R_USER})
        self.f_claim = o.file('QMS_Claim__c', 'RecordNo__c', {
            'Customer__r.OemCode__c': R_CUST, 'Vehicle__r.ExternalKey__c': R_VEH, 'Item__r.ItemNo__c': R_ITEM, 'Plant__r.PlantCode__c': R_PLANT,
            'Line__r.ExternalKey__c': R_LINE, 'DefectType__r.ExternalKey__c': R_CODE, 'Responsibility__r.ExternalKey__c': R_CODE,
            'ResponsibleDept__r.DeptCode__c': R_DEPT, 'Supplier__r.SapVendorNo__c': R_SUPP, 'SupplierItem__r.ExternalKey__c': R_SI,
            'Characteristic__r.ExternalKey__c': R_CHAR})
        self.f_ncr2 = o.file('QMS_NCR__c', 'RecordNo__c', {'EightD__r.RecordNo__c': ('QMS_EightD__c', 'RecordNo__c')}, tag='pass2-8d')
        self.f_claim2 = o.file('QMS_Claim__c', 'RecordNo__c', {'EightD__r.RecordNo__c': ('QMS_EightD__c', 'RecordNo__c')}, tag='pass2-8d')
        self.f_cont = o.file('QMS_NcrContainment__c', 'ExternalKey__c', {'Ncr__r.RecordNo__c': ('QMS_NCR__c', 'RecordNo__c'), 'DoneBy__r.EmployeeNo__c': R_USER})
        self.f_disp = o.file('QMS_NcrDisposition__c', 'ExternalKey__c', {'Ncr__r.RecordNo__c': ('QMS_NCR__c', 'RecordNo__c'), 'Disposition__r.ExternalKey__c': R_CODE,
                                                                        'Executor__r.EmployeeNo__c': R_USER})
        self.add_cr('QMS-05-CLM-001', 'QMS_EightDTeamMember__c·QMS_EightDAction__c에 ExternalKey__c 추가(EightDStep은 정의됨)', '{8D 번호}-TM{nn}, {8D 번호}-{ActionNo}')
        self.add_cr('QMS-06-NCR-003', 'QMS_NcrContainment__c에 ExternalKey__c 추가(Disposition은 정의됨)', '{NCR 번호}-C{nn}, {NCR 번호}-D{nn}')

        r = rng('sf-history', self.seed)
        claims, ncrs = self.plan_cases()
        self.closed_8d = []   # (8D 번호, defect, cause)
        start, end = self.D('2024-12-05'), self.D('2026-10-10')
        span = (end - start).days

        # 클레임 사례 18건(종결) — 협력사 원인 4건은 협력사 NCR(LINKED_8D)
        r.shuffle(claims)
        for i, (defect, cause) in enumerate(claims):
            d0 = start + dt.timedelta(days=int(span * (i + 0.5) / len(claims)) + r.randint(-5, 5))
            self.make_claim_case(r, defect, cause, d0, closed=True)
        # NCR 사례 58건(종결)
        r.shuffle(ncrs)
        flat_iqc = [self.D('2026-10-05'), self.D('2026-10-19')]
        full_left = 12   # NCR FULL_8D 18 = 종결 12 + 클레임 연계 4 + S1 + S2
        for i, (defect, cause) in enumerate(ncrs):
            d0 = start + dt.timedelta(days=int(span * (i + 0.5) / len(ncrs)) + r.randint(-4, 4))
            iqc_date = None
            forced = None
            if defect == 'FLATNESS' and flat_iqc and cause == 'HSG_WARP':
                iqc_date = flat_iqc.pop(0)
                d0 = iqc_date
                forced = {'item': 'P-HSG-BE1', 'plant': 'KR01', 'vendor': 'V10002', 'si': self.si_key('V10002', 'P-HSG-BE1', 'KR01'), 'line': None, 'op': None}
            full = defect in ('INNER_FOG', 'DRL_FLICKER', 'AIM_OUT') and full_left > 0
            if full:
                full_left -= 1
            self.make_ncr_case(r, defect, cause, d0, closed=True, full=full, iqc_date=iqc_date, forced=forced)
        assert full_left == 0, full_left
        # 미종결 NCR 6건(협력사 3: 하우징 평면도 수입검사 불합격, 사내 3) + S1·S2 = 미종결 8, 합계 70
        opens = [('FLATNESS', '2026-11-09', 'P-HSG-BE1', False), ('FLATNESS', '2026-11-23', 'P-HSG-HE1', False), ('FLATNESS', '2026-11-25', 'P-HSG-HE1', False),
                 ('LENS_HAZE', '2026-11-18', None, False), ('LEAK_RATE', '2026-11-26', None, False), ('INNER_FOREIGN', '2026-11-29', None, False)]
        self.open_flat = {}
        for defect, d, part, full in opens:
            no = self.make_ncr_case(r, defect, None, self.D(d), closed=False, full=full, part=part, iqc_date=self.D(d) if part else None)
            if part:
                self.open_flat[(part, d)] = no
        # 미종결 클레임 1건 + S2 = 미종결 2, 합계 20
        self.make_claim_case(r, 'LEVELING_FAIL', None, self.D('2026-11-06'), closed=False, item='84001-GE1L')

    def emp_for(self, plant, kind):
        table = {'KR01': {'qe': 'E1102', 'qm': 'E1101', 'sqe': 'E1112', 'insp': 'E1104'}, 'CN01': {'qe': 'E2102', 'qm': 'E2101', 'sqe': 'E2102', 'insp': 'E2102'},
                 'US01': {'qe': 'E3102', 'qm': 'E3101', 'sqe': 'E3102', 'insp': 'E3102'}, 'PL01': {'qe': 'E4102', 'qm': 'E4101', 'sqe': 'E4102', 'insp': 'E4102'},
                 'KR02': {'qe': 'E1102', 'qm': 'E1101', 'sqe': 'E1112', 'insp': 'E1105'}}
        return table.get(plant, table['KR01'])[kind]

    def make_ncr_case(self, r, defect, cause, d0, closed, full, part=None, iqc_date=None, linked_claim=None, linked_8d=None, forced=None):
        o = self.out
        if cause:
            ctx = self.pick_context(r, defect, cause)
        else:
            if part:
                s = next(s for s in self.m['supplierItems'] if s['item'] == part and s['plant'] == 'KR01')
                ctx = {'item': part, 'plant': 'KR01', 'line': None, 'op': None, 'vendor': s['vendor'], 'si': self.si_key(s['vendor'], part, 'KR01'), 'fg': '63117-BE1L'}
            else:
                item = r.choice([i for i in C.DEFECTS[defect]['items']])
                plant = self.items[item]['plants'][0]
                line = ('L01' if 'BE1' in item else 'L05') if self.items[item]['type'] == 'FG' and plant == 'KR01' else ('L02' if item.startswith('S-LENS') else ('L01' if self.items[item]['type'] == 'FG' else None))
                ctx = {'item': item, 'plant': plant, 'line': line, 'op': None, 'vendor': None, 'si': None, 'fg': item}
        if forced:
            ctx.update(forced)
        supplier = ctx['vendor'] is not None
        year = d0.year
        no = self.seq('NCR-{PLANT}-{YYYY}', ctx['plant'], year, 6)
        qty = r.choice([2, 3, 4, 6, 8, 12, 20])
        where = r.choice(C.WHERE_INTERNAL)
        source = 'IQC' if iqc_date else ('CUSTOMER_CLAIM' if linked_claim else ('PROCESS' if not supplier else r.choice(['IQC', 'PROCESS'])))
        desc = self.text(r, defect, ctx, '수입검사' if source == 'IQC' else where, qty)
        close_d = d0 + dt.timedelta(days=r.randint(25, 55)) if closed else None
        if closed and close_d >= self.today:
            close_d = self.today - dt.timedelta(days=r.randint(2, 6))
        mode = 'LINKED_8D' if linked_8d else ('FULL_8D' if full else 'SHORT_CAPA')
        qm = self.emp_for(ctx['plant'], 'qm')
        resp_dept = None if supplier else {'KR01': 'D1120', 'KR02': 'D1120', 'CN01': 'D4100', 'US01': 'D5100', 'PL01': 'D6100'}[ctx['plant']]
        status = 'CLOSED' if closed else r.choice(['DISPOSITION', 'COUNTERMEASURE', 'COUNTERMEASURE', 'VERIFICATION'])
        if part and not closed:
            status = 'COUNTERMEASURE'
        row = {'RecordNo__c': no, 'RecordTypeDeveloperName': 'SUPPLIER' if supplier else 'INTERNAL',
               'Name': f"{self.items[ctx['item']]['name']} {C.DEFECTS[defect]['symptomEn'] if False else self.code_name[self.ck('DEFECT_TYPE', defect)].split(' > ')[-1]}",
               'Status__c': status, 'ResponsibilityStatus__c': 'CONFIRMED' if status not in ('DISPOSITION',) else 'NOTIFIED',
               'CountermeasureType__c': mode, 'SourceType__c': source,
               'SourceRecordId__c': ref('QMS_Claim__c', 'RecordNo__c', linked_claim) if linked_claim else (ref('QMS_IqcLot__c', 'ExternalKey__c', '@IQCLOT') if iqc_date else None),
               'SourceObject__c': 'QMS_Claim__c' if linked_claim else ('QMS_IqcLot__c' if iqc_date else None),
               'SourceRecordNo__c': linked_claim,
               'Plant__r.PlantCode__c': ctx['plant'], 'Line__r.ExternalKey__c': f"{ctx['plant']}-{ctx['line']}" if ctx['line'] else None,
               'Operation__r.ExternalKey__c': f"{ctx['plant']}-{ctx['line']}-{ctx['op']}" if ctx['op'] and ctx['line'] else None,
               'Item__r.ItemNo__c': ctx['item'], 'Supplier__r.SapVendorNo__c': ctx['vendor'], 'SupplierItem__r.ExternalKey__c': ctx['si'],
               'SupplierShareTo__r.SapVendorNo__c': ctx['vendor'],
               'DetectedAt__c': ts(d0, 10, 20), 'DetectedBy__r.EmployeeNo__c': self.emp_for(ctx['plant'], 'insp' if source == 'IQC' else 'qe'),
               'DefectType__r.ExternalKey__c': self.ck('DEFECT_TYPE', defect), 'DefectTypePath__c': self.cpath('DEFECT_TYPE', defect),
               'Description__c': desc, 'SuspectQty__c': qty * 10, 'DefectQty__c': qty if status != 'DISPOSITION' else None,
               'DefectQtyConfirmedAt__c': ts(d0 + dt.timedelta(days=2), 17) if status != 'DISPOSITION' else None, 'Uom__c': 'EA',
               'LotNos__c': f"{ctx['item']}-{d0.strftime('%y%m%d')}-0{r.randint(1, 4)}", 'Severity__c': C.DEFECTS[defect]['severity'],
               'CustomerImpact__c': str(source == 'CUSTOMER_CLAIM').lower(),
               'Responsibility__r.ExternalKey__c': self.ck('RESPONSIBILITY', 'SUPPLIER' if supplier else 'INTERNAL_PROCESS'),
               'ResponsibleDept__r.DeptCode__c': resp_dept, 'ContainmentDueAt__c': ts(d0 + dt.timedelta(days=1), 18),
               'ContainmentDone__c': 'true', 'ContainmentSummary__c': f'사내 재고 {qty * 10}EA 선별, 불량 {qty}EA 격리', 'CountermeasureDueDate__c': iso(d0 + dt.timedelta(days=30)),
               'VerificationResult__c': 'EFFECTIVE' if closed else 'PENDING',
               'RootCause__r.ExternalKey__c': self.ck('CAUSE_5M1E', cause) if closed and cause else None,
               'RootCausePath__c': self.cpath('CAUSE_5M1E', cause) if closed and cause else None,
               'ImplementedDate__c': iso(close_d - dt.timedelta(days=14)) if closed else None,
               'ClosedAt__c': ts(close_d, 16) if closed else None, 'ClosedBy__r.EmployeeNo__c': qm if closed else None,
               'NoticeIssuedAt__c': ts(d0 + dt.timedelta(days=1), 11), 'EightDClosed__c': str(closed).lower()}
        if iqc_date:
            row['_iqc'] = (ctx['item'], ctx['plant'], iqc_date)
        o.add(self.f_ncr, row)
        # 8D
        ed_no = linked_8d
        if not linked_8d:
            ed_no = self.make_8d(r, 'NCR_SUPPLIER' if supplier else 'NCR_INTERNAL', 'FULL_8D' if full else 'SHORT_CAPA', no, 'QMS_NCR__c', ctx,
                                 defect, cause if closed else None, d0, close_d, desc, qty, closed)
        o.add(self.f_ncr2, {'RecordNo__c': no, 'EightD__r.RecordNo__c': ed_no})
        # 봉쇄·처분
        o.add(self.f_cont, {'ExternalKey__c': f'{no}-C01', 'Ncr__r.RecordNo__c': no, 'Location__c': 'RECEIVING' if source == 'IQC' else 'FG_WAREHOUSE',
                            'Method__c': 'SORT_100', 'QtyChecked__c': qty * 10, 'QtyNg__c': qty, 'Status__c': 'DONE',
                            'DoneBy__r.EmployeeNo__c': self.emp_for(ctx['plant'], 'qe'), 'DoneAt__c': ts(d0 + dt.timedelta(days=1), 15)})
        if status != 'DISPOSITION':
            disp = 'RETURN' if supplier else r.choice(['SCRAP', 'REWORK'])
            o.add(self.f_disp, {'ExternalKey__c': f'{no}-D01', 'Ncr__r.RecordNo__c': no, 'Sequence__c': 1, 'Disposition__r.ExternalKey__c': self.ck('DISPOSITION', disp),
                                'Qty__c': qty, 'Uom__c': 'EA', 'Executor__r.EmployeeNo__c': self.emp_for(ctx['plant'], 'qe'),
                                'PlannedDate__c': iso(d0 + dt.timedelta(days=3)), 'DoneDate__c': iso(d0 + dt.timedelta(days=4)), 'Status__c': 'DONE',
                                'ResultGoodQty__c': 0 if disp != 'REWORK' else qty, 'ResultNgQty__c': qty if disp != 'REWORK' else 0,
                                'CustomerApprovalRequired__c': 'false', 'SapMovementRequired__c': str(ctx['plant'] == 'KR01').lower(),
                                'SapMovementStatus__c': 'CONFIRMED' if ctx['plant'] == 'KR01' else 'NOT_REQUIRED'})
        return no

    def make_8d(self, r, rtype, mode, src_no, src_obj, ctx, defect, cause, d0, close_d, desc, qty, closed, customer=None, form=None,
                current=None, steps_state=None, leader=None, champion=None):
        o = self.out
        no = self.seq('8D-{PLANT}-{YYYY}', ctx['plant'], d0.year, 5)
        cinfo = C.CAUSES.get(cause) if cause else None
        steps = ['D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8'] if mode == 'FULL_8D' else ['D2', 'D3', 'D4', 'D5', 'D6', 'D8']
        cur = current or ('D8' if closed else r.choice(['D4', 'D5', 'D6']))
        leader = leader or self.emp_for(ctx['plant'], 'sqe' if rtype == 'NCR_SUPPLIER' else 'qe')
        champion = champion or self.emp_for(ctx['plant'], 'qm')
        form = form or ('STD_8D' if rtype != 'CUSTOMER_CLAIM' else 'STD_8D')
        status = 'CLOSED' if closed else 'IN_PROGRESS'
        row = {'RecordNo__c': no, 'RecordTypeDeveloperName': rtype, 'Name': f"{self.items[ctx['item']]['name']} {self.cpath('DEFECT_TYPE', defect).split(' > ')[-1]}",
               'Status__c': status, 'CurrentStep__c': 'D8' if closed else cur, 'Mode__c': mode,
               'SourceRecordId__c': ref(src_obj, 'RecordNo__c', src_no), 'SourceObject__c': src_obj, 'SourceRecordNo__c': src_no,
               'Plant__r.PlantCode__c': ctx['plant'], 'Item__r.ItemNo__c': ctx['item'], 'Customer__r.OemCode__c': customer,
               'Supplier__r.SapVendorNo__c': ctx['vendor'] if rtype == 'NCR_SUPPLIER' else None,
               'ResponsibleDept__r.DeptCode__c': None if rtype == 'NCR_SUPPLIER' else {'KR01': 'D1120', 'KR02': 'D1120', 'CN01': 'D4100', 'US01': 'D5100', 'PL01': 'D6100'}[ctx['plant']],
               'Severity__c': {'A': 'CRITICAL', 'B': 'MAJOR', 'C': 'MINOR'}[C.DEFECTS[defect]['severity']], 'Form__c': form,
               'Champion__r.EmployeeNo__c': champion, 'Leader__r.EmployeeNo__c': leader,
               'SupplierLeaderName__c': '협력사 품질팀장(가상)' if rtype == 'NCR_SUPPLIER' else None,
               'DueDate__c': iso(d0 + dt.timedelta(days=30)), 'ProblemStatement__c': desc,
               'D2What__c': self.cpath('DEFECT_TYPE', defect).split(' > ')[-1], 'D2Where__c': f"{ctx['plant']} {ctx['line'] or '수입검사'}",
               'D2When__c': d0.isoformat(), 'D2Who__c': '품질팀 검사원', 'D2Why__c': '고객·후공정 품질 영향', 'D2How__c': '외관·기능 검사에서 발견',
               'D2HowMany__c': qty, 'DefectType__r.ExternalKey__c': self.ck('DEFECT_TYPE', defect), 'DefectTypePath__c': self.cpath('DEFECT_TYPE', defect),
               'D3Effective__c': 'true',
               'OccurrenceCause__c': cinfo['occ'] if cinfo else None, 'EscapeCause__c': cinfo['esc'] if cinfo and mode == 'FULL_8D' else None,
               'OccurrenceCauseCode__r.ExternalKey__c': self.ck('CAUSE_5M1E', cause) if cause else None,
               'WhyWhyJson__c': j([{'chain': 'OCCURRENCE', 'whys': cinfo['why']}]) if cinfo else None,
               'RootCauseVerified__c': str(bool(cinfo)).lower(), 'RootCauseVerification__c': '재현 시험으로 원인 확인(데모)' if cinfo else None,
               'PermanentActionSummary__c': ' / '.join(cinfo['actions']) if cinfo and cur not in ('D4',) else None,
               'EffectivenessMethod__c': 'RECURRENCE' if closed else None, 'EffectivenessCriteria__c': '대책 적용 후 4주간 동일 불량 재발 0건' if closed else None,
               'EffectivenessFrom__c': iso(close_d - dt.timedelta(days=28)) if closed else None, 'EffectivenessTo__c': iso(close_d - dt.timedelta(days=1)) if closed else None,
               'EffectivenessResult__c': 'EFFECTIVE' if closed else 'PENDING',
               'D7Pfmea__c': 'YES' if closed and mode == 'FULL_8D' else ('NO_NEED' if closed else 'PENDING'),
               'D7ControlPlan__c': 'YES' if closed and mode == 'FULL_8D' else ('NO_NEED' if closed else 'PENDING'),
               'D7WorkInstruction__c': 'YES' if closed else 'PENDING', 'D7Standard__c': 'NO_NEED' if closed else 'PENDING',
               'D7DesignRule__c': 'NO_NEED' if closed else 'PENDING', 'D7NoNeedReason__c': '설계 기준 영향 없음' if closed else None,
               'HorizontalDeployDecision__c': 'NOT_NEEDED' if closed else 'PENDING', 'LessonLearnedDecision__c': 'NOT_NEEDED' if closed else 'PENDING',
               'ClosureComment__c': cinfo['verify'] if closed and cinfo else None, 'ClosedAt__c': ts(close_d, 15) if closed else None, 'ReopenCount__c': 0}
        o.add(self.f_8d, row)
        stepset = steps_state or {}
        cur_idx = steps.index(cur) if cur in steps else len(steps) - 1
        for i, s in enumerate(steps):
            st = stepset.get(s) or ('APPROVED' if closed or i < cur_idx else ('IN_PROGRESS' if i == cur_idx else 'NOT_STARTED'))
            sd = d0 + dt.timedelta(days=2 + i * 4)
            o.add(self.f_step, {'ExternalKey__c': f'{no}-{s}', 'EightD__r.RecordNo__c': no, 'StepNo__c': s, 'Sequence__c': int(s[1]), 'Status__c': st,
                                'DueDate__c': iso(sd + dt.timedelta(days=3)), 'StartedAt__c': ts(sd, 9) if st != 'NOT_STARTED' else None,
                                'SubmittedAt__c': ts(sd + dt.timedelta(days=2), 17) if st == 'APPROVED' else None,
                                'ApprovedAt__c': ts(sd + dt.timedelta(days=3), 10) if st == 'APPROVED' else None,
                                'SubmittedBy__r.EmployeeNo__c': leader if st == 'APPROVED' else None, 'ApprovedBy__r.EmployeeNo__c': champion if st == 'APPROVED' else None})
        if mode == 'FULL_8D':
            for k, (emp, role) in enumerate([(champion, 'CHAMPION'), (leader, 'LEADER'), (self.emp_for(ctx['plant'], 'qe') if leader != self.emp_for(ctx['plant'], 'qe') else 'E1103', 'MEMBER')], 1):
                o.add(self.f_team, {'ExternalKey__c': f'{no}-TM{k:02d}', 'EightD__r.RecordNo__c': no, 'User__r.EmployeeNo__c': emp, 'Role__c': role})
        n = 1
        o.add(self.f_act, {'ExternalKey__c': f'{no}-A{n:02d}', 'EightD__r.RecordNo__c': no, 'ActionNo__c': f'A{n:02d}', 'ActionType__c': 'CONTAINMENT',
                           'Description__c': f'사내 재고·운송 중 재고 선별({qty * 10}EA)', 'Owner__r.EmployeeNo__c': self.emp_for(ctx['plant'], 'qe'),
                           'DueDate__c': iso(d0 + dt.timedelta(days=1)), 'CompletedDate__c': iso(d0 + dt.timedelta(days=1)), 'Status__c': 'VERIFIED' if closed else 'DONE',
                           'LocationType__c': 'SL_WAREHOUSE', 'SuspectQty__c': qty * 10, 'CheckedQty__c': qty * 10, 'NgQty__c': qty, 'Sequence__c': 10})
        if cinfo and cur not in ('D4',):
            for a in cinfo['actions'][:2 if mode == 'SHORT_CAPA' else 3]:
                n += 1
                o.add(self.f_act, {'ExternalKey__c': f'{no}-A{n:02d}', 'EightD__r.RecordNo__c': no, 'ActionNo__c': f'A{n:02d}', 'ActionType__c': 'CORRECTIVE',
                                   'CauseChain__c': 'OCCURRENCE', 'Description__c': a,
                                   'Owner__r.EmployeeNo__c': leader if rtype != 'NCR_SUPPLIER' else None,
                                   'SupplierOwnerName__c': '협력사 담당(가상)' if rtype == 'NCR_SUPPLIER' else None,
                                   'DueDate__c': iso(d0 + dt.timedelta(days=21)), 'CompletedDate__c': iso(close_d - dt.timedelta(days=20)) if closed else None,
                                   'ImplementedDate__c': iso(close_d - dt.timedelta(days=20)) if closed else None,
                                   'Selected__c': 'true', 'ValidationMethod__c': '재현 시험·공정 데이터 확인',
                                   'Status__c': 'VERIFIED' if closed else 'IN_PROGRESS', 'VerificationResult__c': 'EFFECTIVE' if closed else None,
                                   'VerifiedBy__r.EmployeeNo__c': champion if closed else None, 'VerifiedAt__c': ts(close_d - dt.timedelta(days=2), 14) if closed else None,
                                   'Sequence__c': n * 10})
            if mode == 'FULL_8D':
                n += 1
                o.add(self.f_act, {'ExternalKey__c': f'{no}-A{n:02d}', 'EightD__r.RecordNo__c': no, 'ActionNo__c': f'A{n:02d}', 'ActionType__c': 'PREVENTIVE',
                                   'Description__c': cinfo['prev'], 'Owner__r.EmployeeNo__c': champion, 'DueDate__c': iso(d0 + dt.timedelta(days=35)),
                                   'CompletedDate__c': iso(close_d - dt.timedelta(days=5)) if closed else None, 'Status__c': 'DONE' if closed else 'PLANNED',
                                   'Sequence__c': n * 10})
        if closed and cause:
            self.closed_8d.append((no, defect, cause, rtype, mode, ctx['item'], ctx['plant'], close_d.isoformat()))
        return no

    def make_claim_case(self, r, defect, cause, d0, closed, item=None):
        o = self.out
        fgs = [i for i in C.DEFECTS[defect]['items'] if self.items[i]['type'] == 'FG']
        item = item or r.choice(fgs or ['92101-HE1L'])
        it = self.items[item]
        cust = it['customer']
        plant = it['plants'][0]
        line = 'L01' if 'BE1' in item else ('L05' if plant == 'KR01' else 'L01')
        veh = it['vehicles'][0]
        c = next(x for x in self.m['customers'] if x['oemCode'] == cust)
        no = self.seq('CLM-{PLANT}-{YYYY}', plant, d0.year, 5)
        qty = r.choice([2, 3, 5, 8, 12])
        ctype = r.choice(['LINE_0KM', 'FIELD', 'WARRANTY'])
        cinfo = C.CAUSES.get(cause) if cause else None
        supplier = bool(cinfo and cinfo['supplier'])
        close_d = d0 + dt.timedelta(days=r.randint(30, 50)) if closed else None
        ctx = {'item': item, 'plant': plant, 'line': line, 'op': None, 'vendor': None, 'si': None, 'fg': item}
        desc = self.text(r, defect, ctx, r.choice(C.WHERE_CUSTOMER), qty)
        status = 'CLOSED' if closed else ('CORRECTIVE' if defect == 'LEVELING_FAIL' else 'ANALYSIS')
        sctx = None
        if supplier:
            sctx = self.pick_context(r, defect, cause)
        row = {'RecordNo__c': no, 'Name': f"{c['oemCode']} {veh.split('-')[1]} {self.cpath('DEFECT_TYPE', defect).split(' > ')[-1]}",
               'ExternalKey__c': f"{c['oemCode']}-{d0.strftime('%Y%m%d')}-{qty:03d}", 'Status__c': status,
               'Result__c': ('SUPPLIER_FAULT' if supplier else 'SL_FAULT') if closed else None,
               'Customer__r.OemCode__c': cust, 'Vehicle__r.ExternalKey__c': veh, 'Item__r.ItemNo__c': item, 'CustomerPartNo__c': it.get('customerPartNo'),
               'Plant__r.PlantCode__c': plant, 'Line__r.ExternalKey__c': f'{plant}-{line}', 'ClaimType__c': ctype,
               'Severity__c': {'A': 'CRITICAL', 'B': 'MAJOR', 'C': 'MINOR'}[C.DEFECTS[defect]['severity']], 'SourceChannel__c': 'MANUAL',
               'CustomerClaimNo__c': f"{c['oemCode']}-QC-{d0.strftime('%y%m')}-{r.randint(1000, 9999)}", 'ReceivedAt__c': ts(d0, 9),
               'OccurredDate__c': iso(d0 - dt.timedelta(days=3)), 'OccurrenceLocation__c': '고객 조립 라인(데모)' if ctype == 'LINE_0KM' else '딜러 정비(데모)',
               'Country__c': {'KR01': 'KR', 'CN01': 'CN', 'US01': 'US', 'PL01': 'PL'}.get(plant, 'KR'), 'DefectDescription__c': desc,
               'DefectType__r.ExternalKey__c': self.ck('DEFECT_TYPE', defect), 'DefectTypePath__c': self.cpath('DEFECT_TYPE', defect),
               'ClaimQty__c': qty, 'SuspectQty__c': qty * 30, 'ProductionDateFrom__c': iso(d0 - dt.timedelta(days=60)), 'ProductionDateTo__c': iso(d0 - dt.timedelta(days=20)),
               'ContainmentDueAt__c': ts(d0 + dt.timedelta(days=c['containmentDays']), 18), 'RootCauseDueDate__c': iso(d0 + dt.timedelta(days=c['rootCauseDays'])),
               'FinalDueDate__c': iso(d0 + dt.timedelta(days=c['eightDDays'])), 'CustomerResponseForm__c': c['claimForm'], 'EscalationLevel__c': 0,
               'Responsibility__r.ExternalKey__c': self.ck('RESPONSIBILITY', 'SUPPLIER' if supplier else 'INTERNAL_PROCESS') if closed else None,
               'ResponsibleDept__r.DeptCode__c': None if supplier else ('D1120' if plant == 'KR01' else None),
               'Supplier__r.SapVendorNo__c': sctx['vendor'] if supplier else None, 'SupplierItem__r.ExternalKey__c': sctx['si'] if supplier else None,
               'SpecialCharEscape__c': 'false', 'ReturnQty__c': qty, 'ReturnReceivedDate__c': iso(d0 + dt.timedelta(days=3)),
               'ResponsibilityApproved__c': str(closed).lower(), 'CustomerAccepted__c': str(closed).lower(),
               'CustomerAcceptedDate__c': iso(close_d) if closed else None, 'ClosedAt__c': ts(close_d, 17) if closed else None,
               'CloseComment__c': '고객 회신 수용, 효과 확인 완료' if closed else None}
        o.add(self.f_claim, row)
        ed = self.make_8d(r, 'CUSTOMER_CLAIM', 'FULL_8D', no, 'QMS_Claim__c', ctx, defect, cause, d0, close_d, desc, qty, closed,
                          customer=cust, form=c['claimForm'], current=None if closed else ('D5' if status == 'CORRECTIVE' else 'D4'))
        o.add(self.f_claim2, {'RecordNo__c': no, 'EightD__r.RecordNo__c': ed})
        if supplier:
            sn = self.make_ncr_case(r, defect, cause, d0 + dt.timedelta(days=4), closed=closed, full=False, linked_claim=no, linked_8d=ed,
                                    forced={k: sctx[k] for k in ('item', 'plant', 'vendor', 'si', 'line', 'op')})
            row['SupplierNcrRecordId__c'] = ref('QMS_NCR__c', 'RecordNo__c', sn)
            row['SupplierNcrRecordNo__c'] = sn
        return no, ed

    # ------------------------------------------------------------ S9 수입검사
    def gen_value(self, r, c, bad=False):
        lsl, usl, nom = c.get('lsl'), c.get('usl'), c.get('nominal')
        if lsl is not None and usl is not None:
            mid, tol = (nom if nom is not None else (lsl + usl) / 2), (usl - lsl)
            v = r.gauss(mid, tol / 8.5)
            if bad:
                v = usl + tol * r.uniform(0.05, 0.25)
        elif usl is not None:
            v = abs(r.gauss(usl * 0.5, usl * 0.12))
            if bad:
                v = usl * r.uniform(1.06, 1.18)
        elif lsl is not None:
            v = r.gauss(lsl * 1.028, lsl * 0.005)
            if bad:
                v = lsl * r.uniform(0.95, 0.985)
        else:
            v = r.gauss(nom or 0, 0.01)
        return round(v, 4)

    def in_spec(self, c, v):
        return (c.get('lsl') is None or v >= c['lsl']) and (c.get('usl') is None or v <= c['usl'])

    def iqc(self):
        o, r = self.out, rng('sf-iqc', self.seed)
        lot_refs = {'Plant__r.PlantCode__c': R_PLANT, 'Item__r.ItemNo__c': R_ITEM, 'Supplier__r.SapVendorNo__c': R_SUPP, 'SupplierItem__r.ExternalKey__c': R_SI,
                    'Standard__r.ExternalKey__c': ('QMS_IqcStandard__c', 'ExternalKey__c'), 'Inspector__r.EmployeeNo__c': R_USER, 'DecidedBy__r.EmployeeNo__c': R_USER}
        f_lot = o.file('QMS_IqcLot__c', 'ExternalKey__c', lot_refs)
        f_res = o.file('QMS_IqcResult__c', 'ExternalKey__c', {'Lot__r.ExternalKey__c': ('QMS_IqcLot__c', 'ExternalKey__c'),
                                                              'StandardLine__r.ExternalKey__c': ('QMS_IqcStandardLine__c', 'ExternalKey__c'),
                                                              'Characteristic__r.ExternalKey__c': R_CHAR})
        f_coa = o.file('QMS_SupplierCoa__c', 'RecordNo__c', {'SupplierItem__r.ExternalKey__c': R_SI, 'Supplier__r.SapVendorNo__c': R_SUPP, 'Item__r.ItemNo__c': R_ITEM,
                                                             'Plant__r.PlantCode__c': R_PLANT, 'Standard__r.ExternalKey__c': ('QMS_IqcStandard__c', 'ExternalKey__c'),
                                                             'MatchedLot__r.ExternalKey__c': ('QMS_IqcLot__c', 'ExternalKey__c')})
        f_lc = o.file('QMS_IqcLevelChange__c', 'ExternalKey__c', {'SupplierItem__r.ExternalKey__c': R_SI})
        f_hold = o.file('QMS_IqcLevelHold__c', 'ExternalKey__c', {'SupplierItem__r.ExternalKey__c': R_SI})
        self.add_cr('QMS-03-IQC-002', 'QMS_IqcResult__c에 ExternalKey__c 추가(로트 키 + 라인 번호), QMS_IqcLot__c에 Coa__c 필드 정의 누락(IQC-006 BR-3이 사용) — 데모는 COA.MatchedLot만 채움', '{로트 ExternalKey}-R{nn}')
        self.add_cr('QMS-03-IQC-005', 'QMS_IqcLevelChange__c·QMS_IqcLevelHold__c에 ExternalKey__c 추가', 'LC-{SupplierItem}-{yyyymmdd}, HOLD-{원천 번호}')
        # 요일(0=월) 입고 주기 — 6개월 약 1,400로트. P-HSG-BE1 KR01은 월요일만(10-19 '최근 5로트 중 2로트' 재현)
        freq = {('V10001', 'P-LENS-HE1', 'KR01'): (0, 2, 4), ('V10002', 'P-HSG-HE1', 'KR01'): (0, 2, 4), ('V10002', 'P-HSG-BE1', 'KR01'): (0,),
                ('V10002', 'P-BZL-HE1', 'KR01'): (1, 3), ('V10003', 'P-LED-HE1', 'KR01'): (0, 1, 2, 3, 4), ('V10003', 'P-LED-BE1', 'KR01'): (1, 3),
                ('V10004', 'P-REF-BE1', 'KR01'): (1, 3), ('V10005', 'P-CON-01', 'KR01'): (0, 1, 2, 3, 4), ('V10006', 'P-PCB-HE1', 'KR01'): (0, 1, 2, 3, 4),
                ('V10007', 'P-ACT-01', 'KR01'): (0, 2, 4), ('V10008', 'P-VENT-01', 'KR01'): (1, 4), ('V10008', 'R-PC-A01', 'KR01'): (0, 2, 4),
                ('V10001', 'P-LENS-HE1', 'CN01'): (1, 3), ('V10005', 'P-CON-01', 'CN01'): (1, 3), ('V10005', 'P-CON-01', 'US01'): (1, 3),
                ('V10007', 'P-ACT-01', 'US01'): (1, 3), ('V10002', 'P-HSG-BE1', 'PL01'): (1, 3), ('V10003', 'P-LED-BE1', 'PL01'): (1, 3),
                ('V10005', 'P-CON-01', 'PL01'): (1, 3), ('V10007', 'P-ACT-01', 'PL01'): (1, 3)}
        no_gr = {(('V10003', 'P-LED-HE1', 'KR01'), self.D('2026-11-05'))}   # 성적서 OOS_HOLD로 출하 보류된 날
        qty_by_cat = {'LENS': 500, 'HOUSING': 300, 'BEZEL': 300, 'LED_MODULE': 1000, 'REFLECTOR': 400, 'CONNECTOR': 2000, 'PCB': 1000,
                      'ACTUATOR': 500, 'ETC': 5000}
        rejects = {('P-HSG-BE1', 'KR01'): ['2026-10-05', '2026-10-19', '2026-11-09'], ('P-HSG-HE1', 'KR01'): ['2026-11-23', '2026-11-25']}
        rejects = {k: {self.D(x) for x in v} for k, v in rejects.items()}
        coa_same = {self.D('2026-11-03'), self.D('2026-11-17')}
        base = {('V10002', 'P-HSG-BE1', 'KR01'): [('2026-10-19', 'NORMAL', 'TIGHTENED', 'SWITCH_RULE', '최근 연속 5로트 중 2로트 불합격')],
                ('V10002', 'P-HSG-HE1', 'KR01'): [('2026-11-25', 'NORMAL', 'TIGHTENED', 'SWITCH_RULE', '최근 연속 5로트 중 2로트 불합격')],
                ('V10005', 'P-CON-01', 'KR01'): [('2026-05-15', 'NORMAL', 'REDUCED', 'SWITCH_RULE', '연속 10로트 합격, SQE 확인')],
                ('V10007', 'P-ACT-01', 'KR01'): [('2026-03-02', 'REDUCED', 'SKIP', 'SKIP_APPROVAL', '완화 6개월·연속 20로트 합격, 무검사 결재 승인')],
                ('V10008', 'R-PC-A01', 'KR01'): [('2026-04-10', 'NORMAL', 'REDUCED', 'SWITCH_RULE', '연속 10로트 합격, SQE 확인')]}
        self.level_changes = []
        for (v, it, p), chg in base.items():
            for d, fr_, to, why, detail in chg:
                k = f'LC-{v}-{it}-{p}-{self.D(d).strftime("%Y%m%d")}'
                o.add(f_lc, {'ExternalKey__c': k, 'SupplierItem__r.ExternalKey__c': self.si_key(v, it, p), 'FromLevel__c': fr_, 'ToLevel__c': to,
                             'Reason__c': why, 'RuleDetail__c': detail})
                self.level_changes.append({'supplierItem': self.si_key(v, it, p), 'date': self.D(d).isoformat(), 'from': fr_, 'to': to, 'reason': why})

        def base_level(key, d):
            lv = self.si[key]['inspectionLevel']
            for ds, fr_, to, _, _ in base.get(key, []):
                if d < self.D(ds):
                    lv = fr_
            return lv
        # Hold: NCR(하우징 불합격), STABILIZATION(S3)
        self.holds = []
        stb_from = self.D('2026-11-25')   # 초기안정화 시작(첫 적용 로트)
        start, end = self.D('2026-06-01'), self.D('2026-11-30')
        coa_cache = {}
        lot_seq = 0
        d = start
        while d <= end:
            for key, days in freq.items():
                v, it, p = key
                if d.weekday() not in days or (key, d) in no_gr:
                    continue
                si = self.si[key]
                std = self.iqs[(it, p)]
                cat = self.items[it].get('partCategory', 'ETC')
                qty = 2000 if it.startswith('R-') else qty_by_cat.get(cat, 500)
                lot_seq += 1
                self.make_lot(o, r, f_lot, f_res, f_coa, key, si, std, d, qty, lot_seq, rejects.get((it, p), set()), coa_same, coa_cache,
                              base_level(key, d), stb_from)
            d += dt.timedelta(days=1)
        # 감마LED 성적서 규격 이탈(출하 보류, 로트 없음)
        k = ('V10003', 'P-LED-HE1', 'KR01')
        d = self.D('2026-11-05')
        coa_no = self.seq('COA-{PLANT}-{YYYY}', 'KR01', d.year, 6)
        vals = []
        for ln in self.iqs[('P-LED-HE1', 'KR01')]['lines']:
            c = ln['_char']
            if not c or c['type'] != 'VARIABLE':
                continue
            xs = [self.gen_value(r, c) for _ in range(5)]
            if c['charNo'] == 'C40':
                xs[2] = 27.0
            vals.append({'lineId': ln['ExternalKey__c'], 'charNo': c['charNo'], 'checkType': 'VARIABLE', 'lsl': c.get('lsl'), 'usl': c.get('usl'),
                         'values': xs, 'ok': [self.in_spec(c, x) for x in xs]})
        o.add(f_coa, {'RecordNo__c': coa_no, 'SupplierItem__r.ExternalKey__c': self.si_key(*k), 'Supplier__r.SapVendorNo__c': 'V10003', 'Item__r.ItemNo__c': 'P-LED-HE1',
                      'Plant__r.PlantCode__c': 'KR01', 'DeliveryNoteNo__c': 'DN-V10003-261105-01', 'SupplierLotNo__c': 'V10003-261105-A', 'ShipDate__c': iso(d),
                      'ShipQty__c': 1000, 'Standard__r.ExternalKey__c': self.iqs[('P-LED-HE1', 'KR01')]['key'], 'StandardVersion__c': 1, 'ValuesJson__c': j(vals),
                      'OosCount__c': 1, 'Is4mChange__c': 'false', 'Status__c': 'OOS_HOLD'})
        self.keys['S9-COA-OOS'] = coa_no
        # Hold 레코드
        for (part, d), ncr_no in [(('P-HSG-BE1', '2026-10-05'), self.ncr_by_iqc[('P-HSG-BE1', 'KR01', self.D('2026-10-05'))]),
                                  (('P-HSG-BE1', '2026-10-19'), self.ncr_by_iqc[('P-HSG-BE1', 'KR01', self.D('2026-10-19'))]),
                                  (('P-HSG-BE1', '2026-11-09'), self.ncr_by_iqc[('P-HSG-BE1', 'KR01', self.D('2026-11-09'))]),
                                  (('P-HSG-HE1', '2026-11-23'), self.ncr_by_iqc[('P-HSG-HE1', 'KR01', self.D('2026-11-23'))]),
                                  (('P-HSG-HE1', '2026-11-25'), self.ncr_by_iqc[('P-HSG-HE1', 'KR01', self.D('2026-11-25'))])]:
            closed_at = self.ncr_closed.get(ncr_no)
            o.add(f_hold, {'ExternalKey__c': f'HOLD-{ncr_no}', 'SupplierItem__r.ExternalKey__c': self.si_key('V10002', part, 'KR01'), 'HoldType__c': 'NCR',
                           'MinLevel__c': 'TIGHTENED', 'FullInspection__c': 'false', 'SourceRecordId__c': ref('QMS_NCR__c', 'RecordNo__c', ncr_no),
                           'SourceRecordNo__c': ncr_no, 'IsActive__c': str(closed_at is None).lower(), 'ReleasedAt__c': closed_at})
            self.holds.append({'supplierItem': self.si_key('V10002', part, 'KR01'), 'type': 'NCR', 'source': ncr_no, 'active': closed_at is None})
        self.f_hold = f_hold

    def make_lot(self, o, r, f_lot, f_res, f_coa, key, si, std, d, qty, n, reject_dates, coa_same, coa_cache, base_lv, stb_from):
        v, it, p = key
        bad = d in reject_dates
        hold_full = (it == 'P-LENS-HE1' and p == 'KR01' and d >= stb_from)
        hold_tight = hold_full or (it == 'P-HSG-BE1' and p == 'KR01' and d > self.D('2026-10-05')) or (it == 'P-HSG-HE1' and p == 'KR01' and d > self.D('2026-11-23'))
        level = 'TIGHTENED' if hold_tight and base_lv in ('NORMAL', 'REDUCED') else base_lv
        is4m_first = (it == 'P-LENS-HE1' and p == 'KR01' and d == self.D('2026-11-25'))
        full = hold_full or is4m_first
        ext = f"{p}-{d.year}-50{d.strftime('%m%d')}{n:04d}-0001"
        rec_no = self.seq('IQC-{PLANT}-{YYYY}', p, d.year, 6)
        pending = d >= self.D('2026-11-30')
        skip = level == 'SKIP'
        decision = None if pending else ('REJECT' if bad else 'ACCEPT')
        inspector = self.emp_for(p, 'insp')
        lines_out = []
        ng_count = 0
        if not skip:
            for idx, ln in enumerate(std['lines'], 1):
                c = ln['_char']
                ss = int(qty) if full else self.sample_size(level, qty)
                if ln['CheckType__c'] == 'VARIABLE' and c:
                    ss_v = min(ss, 500)
                    xs = [self.gen_value(r, c) for _ in range(ss_v)]
                    if bad and c['charNo'] == 'C20':
                        for b in range(min(3, ss_v)):
                            xs[b] = self.gen_value(r, c, bad=True)
                    samples = [{'no': i + 1, 'value': x, 'ok': self.in_spec(c, x)} for i, x in enumerate(xs)]
                    ng = sum(1 for s in samples if not s['ok'])
                    judg = 'PENDING' if pending else ('NG' if ng > 0 else 'OK')
                    mn, mx, mean = min(xs), max(xs), round(sum(xs) / len(xs), 4)
                else:
                    ss_v = min(ss, 200)
                    samples = [{'no': i + 1, 'ok': True} for i in range(ss_v)]
                    ng, judg, mn, mx, mean = 0, ('PENDING' if pending else 'OK'), None, None, None
                if pending and idx > 1:
                    samples, judg = [], 'PENDING'
                ng_count += 1 if judg == 'NG' else 0
                res = {'ExternalKey__c': f'{ext}-R{idx:02d}', 'Lot__r.ExternalKey__c': ext, 'StandardLine__r.ExternalKey__c': ln['ExternalKey__c'],
                       'Characteristic__r.ExternalKey__c': c['ext'] if c else None, 'Sequence__c': idx * 10,
                       'CheckName__c': c['name'] if c else ln['CheckItemName__c'], 'CheckType__c': ln['CheckType__c'],
                       'SpecialClass__c': c['special'] if c else 'NONE', 'Nominal__c': c.get('nominal') if c else None,
                       'LSL__c': c.get('lsl') if c else None, 'USL__c': c.get('usl') if c else None, 'Unit__c': c.get('unit') if c else None,
                       'Method__c': ln['Method__c'], 'SampleSize__c': ss_v, 'AcceptNo__c': 0, 'RejectNo__c': 1, 'SampleValuesJson__c': j(samples),
                       'MeasuredCount__c': len(samples), 'NgCount__c': ng, 'Min__c': mn, 'Max__c': mx, 'Mean__c': mean, 'Judgment__c': judg,
                       'GaugeNo__c': ln['_gauge'] if c else None}
                lines_out.append(res)
                o.add(f_res, res)
        coa_status, coa_no = 'NOT_REQUIRED', None
        if std['coaRequired'] and not skip:
            coa_status = 'MATCHED'
            coa_no = self.seq('COA-{PLANT}-{YYYY}', p, d.year, 6)
            vals = []
            for ln in std['lines']:
                c = ln['_char']
                if not c or c['type'] != 'VARIABLE':
                    continue
                ck = (key, c['charNo'])
                if d in coa_same and it == 'P-CON-01' and p == 'KR01' and ck in coa_cache:
                    xs = coa_cache[ck]
                else:
                    xs = [self.gen_value(r, c) for _ in range(5)]
                    if d in coa_same and it == 'P-CON-01' and p == 'KR01':
                        coa_cache[ck] = xs
                vals.append({'lineId': ln['ExternalKey__c'], 'charNo': c['charNo'], 'checkType': 'VARIABLE', 'lsl': c.get('lsl'), 'usl': c.get('usl'),
                             'values': xs, 'ok': [self.in_spec(c, x) for x in xs]})
            o.add(f_coa, {'RecordNo__c': coa_no, 'SupplierItem__r.ExternalKey__c': si['key'], 'Supplier__r.SapVendorNo__c': v, 'Item__r.ItemNo__c': it,
                          'Plant__r.PlantCode__c': p, 'DeliveryNoteNo__c': f"DN-{v}-{d.strftime('%y%m%d')}-01", 'SupplierLotNo__c': f"{v}-{d.strftime('%y%m%d')}-A",
                          'ShipDate__c': iso(d - dt.timedelta(days=2)), 'ShipQty__c': qty, 'Standard__r.ExternalKey__c': std['key'], 'StandardVersion__c': 1,
                          'ValuesJson__c': j(vals), 'OosCount__c': 0, 'Is4mChange__c': str(is4m_first).lower(),
                          'Supplier4mRecordNo__c': '@S3-4M' if is4m_first else None, 'MatchedLot__r.ExternalKey__c': ext, 'Status__c': 'MATCHED'})
        ncr_ref = None
        if bad:
            ncr_ref = self.ncr_by_iqc.get((it, p, d))
        lot = {'ExternalKey__c': ext, 'RecordNo__c': rec_no, 'Name': f"{it} {self.m['suppliers'][int(v[-1]) - 1]['name'][:4]} {d.isoformat()}",
               'SapInspLotNo__c': f'0100{d.strftime("%m%d")}{n:04d}' if p == 'KR01' else None, 'Plant__r.PlantCode__c': p, 'Item__r.ItemNo__c': it,
               'Supplier__r.SapVendorNo__c': v, 'SupplierItem__r.ExternalKey__c': si['key'], 'GrDate__c': iso(d), 'GrQty__c': qty,
               'Uom__c': 'KG' if it.startswith('R-') else 'EA', 'SupplierLotNo__c': f"{v}-{d.strftime('%y%m%d')}-A",
               'DeliveryNoteNo__c': f"DN-{v}-{d.strftime('%y%m%d')}-01", 'PoNo__c': f'45000{n:05d}', 'CancelFlag__c': 'false',
               'InspectionLevel__c': level, 'FullInspection__c': str(full).lower(),
               'LevelReason__c': ('4M 초품' if is4m_first else ('STABILIZATION Hold(전수)' if hold_full else ('NCR Hold' if hold_tight else None))),
               'Standard__r.ExternalKey__c': None if skip else std['key'], 'StandardVersion__c': None if skip else 1, 'CoaStatus__c': coa_status,
               'Is4mFirstLot__c': str(is4m_first).lower(), 'Supplier4mRecordNo__c': '@S3-4M' if is4m_first else None,
               'PpapStatusAtGr__c': si['ppap'], 'LongInactive__c': 'false', 'AutoAccepted__c': str(skip).lower(),
               'Status__c': 'IN_INSPECTION' if pending else 'DECIDED', 'Decision__c': 'ACCEPT' if skip else decision,
               'Inspector__r.EmployeeNo__c': None if skip else inspector, 'DecidedBy__r.EmployeeNo__c': None if (skip or pending) else inspector,
               'DecidedAt__c': ts(d, 15) if not pending else None, 'DueAt__c': ts(d + dt.timedelta(days=1), 9),
               'RejectQty__c': qty if bad and not pending else None, 'NgResultCount__c': None if pending else ng_count,
               'MeasuredResultCount__c': None if pending else len(lines_out),
               'NcrRecordId__c': ref('QMS_NCR__c', 'RecordNo__c', ncr_ref) if ncr_ref else None,
               'SapSyncStatus__c': 'CONFIRMED' if p == 'KR01' and not pending else ('PENDING' if p == 'KR01' else 'NOT_REQUIRED')}
        o.add(f_lot, lot)
        self.lots.append({'ext': ext, 'recordNo': rec_no, 'supplierItem': si['key'], 'vendor': v, 'item': it, 'plant': p, 'date': d.isoformat(),
                          'level': level, 'full': full, 'decision': lot['Decision__c'], 'auto': skip, 'pending': pending, 'qty': qty,
                          'coa': coa_no, 'coaStatus': coa_status, 'is4mFirst': is4m_first, 'ncr': ncr_ref,
                          'gaugeResults': [x['ExternalKey__c'] for x in lines_out if x.get('GaugeNo__c') == 'GA-KR01-0456'],
                          'gaugeValues': [(x['ExternalKey__c'], x['CheckName__c'], x['LSL__c'], x['USL__c'], json.loads(x['SampleValuesJson__c']))
                                          for x in lines_out if x.get('GaugeNo__c') == 'GA-KR01-0456']})
        if is4m_first:
            self.keys['S3-IQC-FIRST'] = rec_no
            self.keys['S3-IQC-FIRST-EXT'] = ext

    def index_ncr(self):
        self.ncr_by_iqc, self.ncr_closed = {}, {}
        for row in self.f_ncr['rows']:
            if '_iqc' in row:
                self.ncr_by_iqc[row['_iqc']] = row['RecordNo__c']
            if row.get('ClosedAt__c'):
                self.ncr_closed[row['RecordNo__c']] = row['ClosedAt__c']

    def link_iqc_ncr(self):
        by = {(l['item'], l['plant'], self.D(l['date']) if isinstance(l['date'], str) else l['date']): l['ext'] for l in self.lots}
        for row in self.f_ncr['rows']:
            if '_iqc' in row:
                ext = by.get(row['_iqc'])
                row['SourceRecordId__c'] = ref('QMS_IqcLot__c', 'ExternalKey__c', ext) if ext else None
                row['SourceRecordNo__c'] = next((l['recordNo'] for l in self.lots if l['ext'] == ext), None)
                del row['_iqc']

    # ------------------------------------------------------------ 레슨런(S0·S6)
    def lele(self):
        o, r = self.out, rng('sf-lele', self.seed)
        f = o.file('QMS_LessonLearned__c', 'RecordNo__c', {'Plant__r.PlantCode__c': R_PLANT, 'Customer__r.OemCode__c': R_CUST, 'ProductGroup__r.GroupCode__c': R_PG,
                                                           'DefectType__r.ExternalKey__c': R_CODE, 'CauseCode__r.ExternalKey__c': R_CODE,
                                                           'PublishedBy__r.EmployeeNo__c': R_USER})
        fc = o.file('QMS_LeleCheckpoint__c', 'ExternalKey__c', {'LessonLearned__r.RecordNo__c': ('QMS_LessonLearned__c', 'RecordNo__c')})
        self.lele_keys = {}
        vm = {'MECH_DESIGN': 'DESIGN_REVIEW', 'OPT_DESIGN': 'SIMULATION', 'ELEC_DESIGN': 'SIMULATION', 'MOLD_DESIGN': 'DESIGN_REVIEW',
              'DV_TEST': 'TEST', 'PV_TEST': 'TEST', 'PFMEA': 'DOCUMENT_REVIEW', 'CONTROL_PLAN': 'DOCUMENT_REVIEW', 'SUPPLIER_PPAP': 'DOCUMENT_REVIEW',
              'PAST_ISSUE_REVIEW': 'CHECKLIST'}
        for i, l in enumerate(C.LELE):
            src = next((c for c in self.closed_8d if c[1] == l['defect'] and c[2] == l['cause']), None) if l['defect'] else None
            pub = self.D(src[7]) + dt.timedelta(days=10) if src else self.D('2025-02-10') + dt.timedelta(days=i * 17)
            if pub >= self.today:
                pub = self.today - dt.timedelta(days=5)
            no = self.seq('LL-{YYYY}', None, pub.year, 5).replace('LL--', 'LL-')
            self.lele_keys[l['key']] = no
            cust = 'BMW' if 'BMW' in l['groups'] else ('HMC' if 'HKMC' in l['groups'] else None)
            o.add(f, {'RecordNo__c': no, 'Name': l['title'], 'TitleEn__c': l['titleEn'], 'Status__c': 'PUBLISHED', 'Origin__c': l['origin'],
                      'SourceType__c': 'EIGHT_D' if src else 'MANUAL', 'SourceRecordId__c': ref('QMS_EightD__c', 'RecordNo__c', src[0]) if src else None,
                      'SourceObject__c': 'QMS_EightD__c' if src else None, 'SourceRecordNo__c': src[0] if src else None,
                      'Plant__r.PlantCode__c': 'KR01', 'Customer__r.OemCode__c': cust, 'CustomerGroups__c': ';'.join(l['groups']) or None,
                      'ProductGroup__r.GroupCode__c': 'LAMP_HL', 'PartCategories__c': ';'.join(l['parts']) or None,
                      'DefectType__r.ExternalKey__c': self.ck('DEFECT_TYPE', l['defect']) if l['defect'] else None,
                      'DefectTypePath__c': self.cpath('DEFECT_TYPE', l['defect']) if l['defect'] else None,
                      'CauseCode__r.ExternalKey__c': self.ck('CAUSE_5M1E', l['cause']) if l['cause'] else None,
                      'CausePath__c': self.cpath('CAUSE_5M1E', l['cause']) if l['cause'] else None,
                      'Phenomenon__c': l['phen'], 'RootCause__c': l['cause_txt'], 'Countermeasure__c': l['cm'], 'LearningPoint__c': l['lp'],
                      'SummaryEn__c': f"{l['titleEn']}. Learned from {C.DEFECTS[l['defect']]['symptomEn'].lower() if l['defect'] else 'project reviews'}.",
                      'Severity__c': l['sev'], 'StandardReflection__c': 'DONE', 'StandardDocRefs__c': f"SL-QS-{l['key'][-3:]}(데모 회사표준)",
                      'KeywordText__c': f"{l['title']} {' '.join(l['parts'])}", 'Version__c': 1, 'LatestVersion__c': 'true',
                      'PublishedAt__c': ts(pub, 14), 'PublishedBy__r.EmployeeNo__c': 'E1002', 'IsVerified__c': str(bool(src)).lower()})
            o.add(fc, {'ExternalKey__c': f'{no}-CP01', 'LessonLearned__r.RecordNo__c': no, 'Sequence__c': 10, 'CheckText__c': l['check'],
                       'CheckTextEn__c': l['checkEn'], 'DevPhaseCode__c': l['phase'], 'ActivityTypeCode__c': l['act'][1],
                       'VerificationMethod__c': vm.get(l['act'][1], 'CHECKLIST'), 'RequiredEvidence__c': '검토 기록 또는 시험 성적서',
                       'IsMandatory__c': str(l['sev'] in ('A', 'B')).lower()})
        # S6 PMS 맥락(PMS 객체는 미설계라 텍스트 Id)
        acts = [('OPT_DESIGN', 'P1', '광학 설계(배광 해석)'), ('MECH_DESIGN', 'P1', '기구 설계(하우징·브래킷·벤트)'), ('ELEC_DESIGN', 'P1', '전장 설계(매트릭스 LED)'),
                ('MOLD_DESIGN', 'P2', '렌즈·하우징 금형 설계'), ('DV_TEST', 'P3', 'DV 시험'), ('SUPPLIER_PPAP', 'P4', '협력사 PPAP'),
                ('PAST_ISSUE_REVIEW', 'P1', '과거차 문제 반영 검토')]
        self.s6 = {'projectRecordId': 'a0PDEMO00000BE3', 'projectNo': 'PJT-2026-0142', 'projectName': 'BE3 헤드램프 신규 개발(데모)',
                   'customer': 'BMW', 'vehicle': 'BMW-BE3', 'productGroup': 'LAMP_HL',
                   'activities': [{'activityRecordId': f'a0QDEMO0000BE3{n:02d}', 'name': nm, 'devPhaseCode': ph, 'activityTypeCode': at}
                                  for n, (at, ph, nm) in enumerate(acts, 1)]}

    # ------------------------------------------------------------ 문서(성적서·보고서 링크)
    def doc(self, parent_obj, parent_field, parent_key, doc_class, name, plant, d, supplier=None):
        o = self.out
        if not hasattr(self, 'f_doc'):
            self.f_doc = o.file('CMN_Document__c', 'ExternalKey__c', {'DocClass__r.ExternalKey__c': R_CODE, 'Plant__r.PlantCode__c': R_PLANT,
                                                                      'Supplier__r.SapVendorNo__c': R_SUPP})
            self.f_rev = o.file('CMN_DocumentRevision__c', 'ExternalKey__c', {'Document__r.ExternalKey__c': ('CMN_Document__c', 'ExternalKey__c')},
                                note='ExternalKey__c 의미 충돌(DOC-001은 외부 저장소 키로 정의) — 변경 요청 참고')
            self.f_doc2 = o.file('CMN_Document__c', 'ExternalKey__c', {'CurrentRevision__r.ExternalKey__c': ('CMN_DocumentRevision__c', 'ExternalKey__c')},
                                 tag='pass2-current')
            self.add_cr('CMN-00-DOC-001', 'CMN_Document__c에 ExternalKey__c(업서트 키) 추가. CMN_DocumentRevision__c.ExternalKey__c는 "외부 저장소 키"로 정의돼 있어 업서트 키와 이름이 충돌 → 외부 저장소 키를 ExternalRef__c로 바꾸고 ExternalKey__c를 External ID로', 'DOC-{부모 키}-{DocClass}, 리비전 = {문서 키}-R1(데모는 ExternalKey__c를 업서트 키로 사용)')
            self.add_cr('CMN-00-DOC-001', 'CMN_Document__c.Supplier__c·SupplierVisible__c(Vol.3 요청)를 본문에 추가', '협력사 공개 문서만 채움')
        dk = f'DOC-{parent_key}-{doc_class.split("/")[-1]}'
        o.add(self.f_doc, {'ExternalKey__c': dk, 'Name': name, 'ParentRecordId__c': ref(parent_obj, parent_field, parent_key), 'ParentObject__c': parent_obj,
                           'DocClass__r.ExternalKey__c': doc_class, 'DeliverableType__c': 'ATTACHMENT', 'Plant__r.PlantCode__c': plant,
                           'Supplier__r.SapVendorNo__c': supplier, 'SupplierVisible__c': str(bool(supplier)).lower()})
        rk = f'{dk}-R1'
        o.add(self.f_rev, {'ExternalKey__c': rk, 'Document__r.ExternalKey__c': dk, 'RevisionNo__c': 1, 'Status__c': 'RELEASED', 'StorageType__c': 'URL',
                           'ExternalUrl__c': f'https://docs.example.com/slqms-demo/{dk}.pdf', 'FileName__c': f'{dk}.pdf', 'IndexStatus__c': 'PENDING',
                           'ChangeNote__c': f'최초 등록({d.isoformat()})'})
        o.add(self.f_doc2, {'ExternalKey__c': dk, 'CurrentRevision__r.ExternalKey__c': rk})
        return dk

    # ------------------------------------------------------------ 인정시험·PPAP·4M·초기안정화(S3 포함)
    def qual_ppap_4m(self):
        o, r = self.out, rng('sf-s3', self.seed)
        self.f_qp = o.file('QMS_QualPlan__c', 'RecordNo__c', {'Item__r.ItemNo__c': R_ITEM, 'Supplier__r.SapVendorNo__c': R_SUPP, 'Customer__r.OemCode__c': R_CUST,
                                                              'Vehicle__r.ExternalKey__c': R_VEH, 'Plant__r.PlantCode__c': R_PLANT,
                                                              'Standard__r.ExternalKey__c': ('QMS_TestStandard__c', 'ExternalKey__c'), 'ResponsibleDept__r.DeptCode__c': R_DEPT})
        self.f_qpl = o.file('QMS_QualPlanLine__c', 'ExternalKey__c', {'Plan__r.RecordNo__c': ('QMS_QualPlan__c', 'RecordNo__c'),
                                                                      'TestItem__r.TestCode__c': ('QMS_TestItem__c', 'TestCode__c'), 'ExecutorDept__r.DeptCode__c': R_DEPT})
        self.f_qpl2 = o.file('QMS_QualPlanLine__c', 'ExternalKey__c', {'ReportDocument__r.ExternalKey__c': ('CMN_Document__c', 'ExternalKey__c')}, tag='pass2-report')
        self.add_cr('QMS-02-DVQ-003', 'QMS_QualPlanLine__c에 ExternalKey__c 추가(라인 Id를 문서 부모·NCR 원천으로 참조)', '{계획 번호}-L{nn}')
        tests = {t[0]: t for t in C.TEST_ITEMS}

        def qual(item, plant, trig, phase, std, d0, target, status, result, supplier=None, customer=None, vehicle=None, src=None, rt='PART'):
            no = self.seq('QTP-{PLANT}-{YYYY}', plant, d0.year, 5)
            o.add(self.f_qp, {'RecordNo__c': no, 'RecordTypeDeveloperName': rt, 'Name': f"{self.items[item]['name']} {'4M 변경 검증' if trig == 'CHANGE_4M' else '인정시험'}",
                              'Item__r.ItemNo__c': item, 'Supplier__r.SapVendorNo__c': supplier, 'Customer__r.OemCode__c': customer, 'Vehicle__r.ExternalKey__c': vehicle,
                              'Plant__r.PlantCode__c': plant, 'TriggerType__c': trig, 'Phase__c': phase,
                              'ChangeTypes__c': self.ck('CHANGE_TYPE', 'RESIN_GRADE') if trig == 'CHANGE_4M' else None,
                              'Standard__r.ExternalKey__c': std, 'StandardVersion__c': 1,
                              'SourceRecordId__c': ref(src[0], 'RecordNo__c', src[1]) if src else None, 'SourceObject__c': src[0] if src else None,
                              'SourceRecordNo__c': src[1] if src else None, 'TargetDate__c': iso(target), 'ResponsibleDept__r.DeptCode__c': 'D1110' if rt == 'PART' else 'D2010',
                              'Status__c': status, 'FinalResult__c': result})
            for n, code in enumerate(self.test_standards[std], 1):
                t = tests[code]
                ext_lab = t[13] is None
                lk = f'{no}-L{n:02d}'
                ps = d0 + dt.timedelta(days=5 + n)
                pe = ps + dt.timedelta(days=min(t[12], 30))
                done = status == 'CLOSED'
                o.add(self.f_qpl, {'ExternalKey__c': lk, 'Plan__r.RecordNo__c': no, 'TestItem__r.TestCode__c': code, 'TestCode__c': code, 'TestName__c': t[1],
                                   'TestItemRevision__c': 1, 'MethodStandard__c': t[4], 'Condition__c': t[5], 'JudgmentType__c': t[6], 'Unit__c': t[7],
                                   'LSL__c': t[8], 'USL__c': t[9], 'Criteria__c': t[10], 'IsMandatory__c': 'true', 'SampleQty__c': t[11],
                                   'Executor__c': 'EXTERNAL_LAB' if ext_lab else 'INTERNAL_LAB', 'ExecutorDept__r.DeptCode__c': t[13],
                                   'ExternalLabName__c': '외부 공인 시험기관(데모)' if ext_lab else None, 'ExecutionSystem__c': 'QMS',
                                   'PlannedStart__c': iso(ps), 'PlannedEnd__c': iso(pe), 'ActualStart__c': iso(ps) if done else None, 'ActualEnd__c': iso(pe) if done else None,
                                   'LineStatus__c': 'DONE' if done else 'PLANNED', 'Result__c': 'PASS' if done else None, 'Sequence__c': n * 10})
                if done:
                    dk = self.doc('QMS_QualPlanLine__c', 'ExternalKey__c', lk, self.ck('DOC_CLASS', 'TEST_REPORT'), f'{t[1]} 시험 성적서', plant, pe)
                    o.add(self.f_qpl2, {'ExternalKey__c': lk, 'ReportDocument__r.ExternalKey__c': dk})
            return no

        self.f_ppap = o.file('QMS_Ppap__c', 'RecordNo__c', {'SupplierItem__r.ExternalKey__c': R_SI, 'Supplier__r.SapVendorNo__c': R_SUPP, 'Item__r.ItemNo__c': R_ITEM,
                                                            'Plant__r.PlantCode__c': R_PLANT, 'Sqe__r.EmployeeNo__c': R_USER})
        self.f_pel = o.file('QMS_PpapElementLine__c', 'ExternalKey__c', {'Ppap__r.RecordNo__c': ('QMS_Ppap__c', 'RecordNo__c'),
                                                                         'Element__r.ElementCode__c': ('QMS_PpapElement__c', 'ElementCode__c'),
                                                                         'ReviewedBy__r.EmployeeNo__c': R_USER})
        self.f_psub = o.file('QMS_PpapSubmission__c', 'ExternalKey__c', {'Ppap__r.RecordNo__c': ('QMS_Ppap__c', 'RecordNo__c'), 'Supplier__r.SapVendorNo__c': R_SUPP,
                                                                         'Plant__r.PlantCode__c': R_PLANT})
        self.add_cr('QMS-03-PPA-002', 'QMS_PpapElementLine__c·QMS_PpapSubmission__c에 ExternalKey__c 추가', '{PPAP 번호}-{요소 코드}, {PPAP 번호}-R{n}')

        def ppap(v, item, plant, trig, d0, status, result, src=None, interim=None):
            no = self.seq('PPA-{PLANT}-{YYYY}', plant, d0.year, 5)
            o.add(self.f_ppap, {'RecordNo__c': no, 'RecordTypeDeveloperName': 'SUPPLIER', 'Name': f"{self.items[item]['name']} {'Re-PPAP' if trig != 'NEW_PART' else 'PPAP'}",
                                'SupplierItem__r.ExternalKey__c': self.si_key(v, item, plant), 'Supplier__r.SapVendorNo__c': v, 'Item__r.ItemNo__c': item,
                                'Plant__r.PlantCode__c': plant, 'Trigger__c': trig, 'ChangeTypes__c': self.ck('CHANGE_TYPE', 'RESIN_GRADE') if trig == 'CHANGE_4M' else None,
                                'ElementSet__c': 'AIAG_PPAP4', 'Level__c': '3', 'SourceRecordId__c': ref(src[0], 'RecordNo__c', src[1]) if src else None,
                                'SourceObject__c': src[0] if src else None, 'SourceRecordNo__c': src[1] if src else None,
                                'DueDate__c': iso(d0 + dt.timedelta(days=35)), 'Status__c': status, 'Result__c': result, 'CurrentRound__c': 1,
                                'InterimExpiry__c': iso(interim[0]) if interim else None, 'InterimConditions__c': interim[1] if interim else None,
                                'Sqe__r.EmployeeNo__c': self.emp_for(plant, 'sqe'), 'CustomerApprovalRequired__c': 'false'})
            done = status in ('APPROVED', 'INTERIM', 'APPROVAL')
            for no_, code, name, en, itype in C.PPAP_ELEMENTS:
                req = 'R' if no_ in C.PPAP_LEVEL3_RETAINED else 'S'
                o.add(self.f_pel, {'ExternalKey__c': f'{no}-{code}', 'Ppap__r.RecordNo__c': no, 'Element__r.ElementCode__c': f'AIAG_PPAP4-{no_}', 'ElementCode__c': f'AIAG_PPAP4-{no_}',
                                   'ElementName__c': name, 'DocClassCode__c': self.ck('DOC_CLASS', code), 'InputType__c': itype, 'Sequence__c': int(no_),
                                   'Requirement__c': req, 'Status__c': ('ACCEPTED' if done else 'SUBMITTED') if req == 'S' else 'RETAINED',
                                   'ReviewedBy__r.EmployeeNo__c': self.emp_for(plant, 'sqe') if req == 'S' and done else None,
                                   'ReviewedAt__c': ts(d0 + dt.timedelta(days=30), 11) if req == 'S' and done else None})
            o.add(self.f_psub, {'ExternalKey__c': f'{no}-R1', 'Ppap__r.RecordNo__c': no, 'Supplier__r.SapVendorNo__c': v, 'Plant__r.PlantCode__c': plant, 'Round__c': 1,
                                'Status__c': 'REVIEWED' if done else 'SUBMITTED', 'EditableElementCodes__c': ','.join(f'AIAG_PPAP4-{e[0]}' for e in C.PPAP_ELEMENTS if e[0] not in C.PPAP_LEVEL3_RETAINED),
                                'PswJson__c': j({'reason': trig, 'level': 3, 'weightKg': 0.42, 'declaration': True, 'signer': '협력사 품질 책임(가상)', 'signedDate': (d0 + dt.timedelta(days=25)).isoformat()}),
                                'SubmittedAt__c': ts(d0 + dt.timedelta(days=25), 16)})
            return no

        self.f_4m = o.file('QMS_FourMChange__c', 'RecordNo__c', {'Plant__r.PlantCode__c': R_PLANT, 'Supplier__r.SapVendorNo__c': R_SUPP, 'PrimaryChangeType__r.ExternalKey__c': R_CODE})
        self.f_4mi = o.file('QMS_FourMItem__c', 'ExternalKey__c', {'FourM__r.RecordNo__c': ('QMS_FourMChange__c', 'RecordNo__c'), 'Item__r.ItemNo__c': R_ITEM,
                                                                   'SupplierItem__r.ExternalKey__c': R_SI, 'Line__r.ExternalKey__c': R_LINE, 'Customer__r.OemCode__c': R_CUST})
        self.f_4mv = o.file('QMS_FourMVerification__c', 'ExternalKey__c', {'FourM__r.RecordNo__c': ('QMS_FourMChange__c', 'RecordNo__c'), 'Item__r.ItemNo__c': R_ITEM,
                                                                           'Customer__r.OemCode__c': R_CUST, 'Owner__r.EmployeeNo__c': R_USER})
        self.add_cr('QMS-06-4MC-002', 'QMS_FourMItem__c·QMS_FourMVerification__c에 ExternalKey__c 추가', '{4M 번호}-I{nn}, {4M 번호}-V{nn}')
        # --- S3
        d0 = self.D('2026-09-10')
        s4m_req = self.seq('S4M-{PLANT}-{YYYY}', 'KR01', 2026, 5)
        fm_no = self.seq('4M-{PLANT}-{YYYY}', 'KR01', 2026, 5)
        self.keys.update({'S3-4M-REQ': s4m_req, 'S3-4M': fm_no})
        qual_no = qual('P-LENS-HE1', 'KR01', 'CHANGE_4M', 'CHANGE', 'TS-LENS-4M-RESIN', self.D('2026-09-19'), self.D('2026-11-05'), 'CLOSED', 'PASS',
                       supplier='V10001', src=('QMS_FourMChange__c', fm_no))
        ppap_no = ppap('V10001', 'P-LENS-HE1', 'KR01', 'CHANGE_4M', self.D('2026-10-01'), 'APPROVED', 'APPROVED', src=('QMS_FourMChange__c', fm_no))
        self.keys.update({'S3-QUAL': qual_no, 'S3-PPAP': ppap_no})
        f_req = o.file('QMS_SupplierFourMRequest__c', 'RecordNo__c', {'Supplier__r.SapVendorNo__c': R_SUPP, 'Plant__r.PlantCode__c': R_PLANT, 'ChangeType__r.ExternalKey__c': R_CODE})
        o.add(f_req, {'RecordNo__c': s4m_req, 'Supplier__r.SapVendorNo__c': 'V10001', 'Plant__r.PlantCode__c': 'KR01', 'ChangeType__r.ExternalKey__c': self.ck('CHANGE_TYPE', 'RESIN_GRADE'),
                      'Title__c': 'HE1 아우터 렌즈 PC 레진 등급 변경(A→B)', 'BeforeDescription__c': '광학용 PC 레진 A등급(R-PC-A01)',
                      'AfterDescription__c': '광학용 PC 레진 B등급(R-PC-B01, 내후 강화 첨가제 포함, 세타소재 공급)', 'Reason__c': 'QUALITY',
                      'PlannedApplyDate__c': iso(self.D('2026-11-20')), 'SupplierValidation__c': '협력사 사전 평가: 사출 조건 동일, 헤이즈·투과율 동등, 내광성 개선(가상)',
                      'OldStockQtyAtSupplier__c': 1500, 'Status__c': 'ACCEPTED', 'FourMChangeId__c': ref('QMS_FourMChange__c', 'RecordNo__c', fm_no),
                      'FourMRecordNo__c': fm_no, 'SubmittedAt__c': ts(d0, 10)})
        stb_no = self.seq('STB-{PLANT}-{YYYY}', 'KR01', 2026, 5)
        self.keys['S3-STB'] = stb_no
        o.add(self.f_4m, {'RecordNo__c': fm_no, 'RecordTypeDeveloperName': 'SUPPLIER', 'Name': 'HE1 렌즈 레진 등급 변경(알파광학)', 'Status__c': 'STABILIZING',
                          'Plant__r.PlantCode__c': 'KR01', 'Supplier__r.SapVendorNo__c': 'V10001', 'PrimaryChangeType__r.ExternalKey__c': self.ck('CHANGE_TYPE', 'RESIN_GRADE'),
                          'ChangeTypeCodes__c': self.ck('CHANGE_TYPE', 'RESIN_GRADE'), 'Category5M1E__c': 'MATERIAL',
                          'BeforeDescription__c': '광학용 PC 레진 A등급(R-PC-A01)', 'AfterDescription__c': '광학용 PC 레진 B등급(R-PC-B01)',
                          'Reason__c': 'QUALITY', 'ReasonDetail__c': '필드 황변 개선(가상)', 'PlannedApplyDate__c': iso(self.D('2026-11-20')),
                          'RequestedDate__c': iso(d0), 'LeadCompliant__c': 'true', 'RiskClass__c': 'A',
                          'RiskRationale__c': '광학 특성(SC)과 하드코팅 밀착(SC)에 영향 가능, HMC 통보 대상',
                          'RiskChecklistJson__c': j([{'q': '특별특성 영향', 'a': 'YES'}, {'q': '고객 통보 필요', 'a': 'YES'}, {'q': '금형 변경', 'a': 'NO'}]),
                          'SpecialCharImpact__c': 'true', 'AffectedCharacteristicIds__c': ','.join([self.char_key('P-LENS-HE1', 'C10'), self.char_key('P-LENS-HE1', 'C50')]),
                          'PfmeaImpact__c': 'UPDATE_REQUIRED', 'CustomerNotice__c': 'NOTICE', 'CustomerGroups__c': 'HKMC',
                          'RuleSnapshotJson__c': j({'rule': 'CTR-RESIN-GRADE', 'riskClass': 'A', 'customerNotice': 'NOTICE', 'minLeadDays': 30}),
                          'PlanApprovedAt__c': ts(self.D('2026-09-18'), 15), 'ApplyApprovedAt__c': ts(self.D('2026-11-20'), 14),
                          'OldStockDisposition__c': 'USE_UP', 'OldStockQty__c': 1500, 'OldStockCheckedAt__c': ts(self.D('2026-11-20'), 16),
                          'CutoverCondition__c': '협력사 구 레진 재고 소진 후 B등급 첫 출하', 'IdentificationMethod__c': '첫 3로트 라벨 녹색 4M 표식',
                          'FirstLotNo__c': 'V10001-261125-A', 'FirstLotRecordId__c': '@S3-IQC-FIRST-REF', 'FirstLotSource__c': 'IQC',
                          'AppliedAt__c': ts(self.D('2026-11-25'), 15), 'StabilizationPlanId__c': ref('QMS_StabilizationPlan__c', 'RecordNo__c', stb_no),
                          'StabilizationStatus__c': 'ACTIVE', 'SupplierRequestId__c': ref('QMS_SupplierFourMRequest__c', 'RecordNo__c', s4m_req), 'Unauthorized__c': 'false'})
        o.add(self.f_4mi, {'ExternalKey__c': f'{fm_no}-I01', 'FourM__r.RecordNo__c': fm_no, 'ItemRole__c': 'CHANGED', 'Item__r.ItemNo__c': 'P-LENS-HE1',
                           'SupplierItem__r.ExternalKey__c': self.si_key('V10001', 'P-LENS-HE1', 'KR01'), 'AddedBy__c': 'MANUAL', 'IsExcluded__c': 'false'})
        o.add(self.f_4mi, {'ExternalKey__c': f'{fm_no}-I02', 'FourM__r.RecordNo__c': fm_no, 'ItemRole__c': 'AFFECTED_FG', 'Item__r.ItemNo__c': '92101-HE1L',
                           'Customer__r.OemCode__c': 'HMC', 'CustomerGroup__c': 'HKMC', 'AddedBy__c': 'AUTO_BOM', 'IsExcluded__c': 'false'})
        vs = [('QUAL_TEST', '인정시험(내광성·열충격·헤이즈)', 'QMS_QualPlan__c', qual_no, '2026-11-02', 'E1112'),
              ('PPAP_SUPPLIER', '협력사 Re-PPAP(레벨 3)', 'QMS_Ppap__c', ppap_no, '2026-11-15', 'E1112'),
              ('CUSTOMER_NOTICE', 'HMC 변경 통보', None, None, '2026-09-25', 'E1202'),
              ('PFMEA_UPDATE', '협력사 PFMEA 개정 확인', None, None, '2026-10-20', 'E1112'),
              ('CONTROL_PLAN_UPDATE', '협력사 관리계획서 개정 확인', None, None, '2026-10-20', 'E1112'),
              ('FIRST_LOT_INSPECTION', '첫 적용 로트 전수 검사', 'QMS_IqcLot__c', None, '2026-11-25', 'E1104')]
        for n, (vt, title, lobj, lno, dd, own) in enumerate(vs, 1):
            row = {'ExternalKey__c': f'{fm_no}-V{n:02d}', 'FourM__r.RecordNo__c': fm_no, 'Sequence__c': n * 10, 'VerificationType__c': vt,
                   'GateStage__c': 'AFTER_APPLY' if vt == 'FIRST_LOT_INSPECTION' else 'BEFORE_APPLY', 'IsMandatory__c': 'true',
                   'Item__r.ItemNo__c': 'P-LENS-HE1', 'Customer__r.OemCode__c': 'HMC' if vt == 'CUSTOMER_NOTICE' else None, 'Title__c': title,
                   'Owner__r.EmployeeNo__c': own, 'DueDate__c': iso(self.D(dd)), 'Status__c': 'DONE', 'ResultSummary__c': '완료(데모)',
                   'LinkedRecordId__c': ref(lobj, 'RecordNo__c', lno) if lno else ('@S3-IQC-FIRST-REF' if vt == 'FIRST_LOT_INSPECTION' else None),
                   'LinkedRecordNo__c': lno, 'LinkedObject__c': lobj, 'AutoCreated__c': str(vt in ('QUAL_TEST', 'PPAP_SUPPLIER', 'FIRST_LOT_INSPECTION')).lower(),
                   'NoticeSentDate__c': iso(self.D('2026-09-25')) if vt == 'CUSTOMER_NOTICE' else None,
                   'CustomerDecision__c': 'APPROVED' if vt == 'CUSTOMER_NOTICE' else None, 'CustomerDecisionDate__c': iso(self.D('2026-10-02')) if vt == 'CUSTOMER_NOTICE' else None,
                   'CustomerRefNo__c': 'HMC-CN-2026-0931(가상)' if vt == 'CUSTOMER_NOTICE' else None, 'CompletedAt__c': ts(self.D(dd), 17)}
            o.add(self.f_4mv, row)
        # 초기안정화
        f_stb = o.file('QMS_StabilizationPlan__c', 'RecordNo__c', {'SupplierItem__r.ExternalKey__c': R_SI, 'Supplier__r.SapVendorNo__c': R_SUPP, 'Item__r.ItemNo__c': R_ITEM,
                                                                    'Plant__r.PlantCode__c': R_PLANT})
        o.add(f_stb, {'RecordNo__c': stb_no, 'RecordTypeDeveloperName': 'PART', 'Status__c': 'ACTIVE', 'SupplierItem__r.ExternalKey__c': self.si_key('V10001', 'P-LENS-HE1', 'KR01'),
                      'Supplier__r.SapVendorNo__c': 'V10001', 'Item__r.ItemNo__c': 'P-LENS-HE1', 'Plant__r.PlantCode__c': 'KR01', 'Trigger__c': 'CHANGE_4M',
                      'SourceRecordId__c': ref('QMS_FourMChange__c', 'RecordNo__c', fm_no), 'SourceObject__c': 'QMS_FourMChange__c', 'SourceRecordNo__c': fm_no,
                      'StartDate__c': iso(self.D('2026-11-25')), 'MinDays__c': 90, 'MinLots__c': 10, 'TargetPpm__c': 100, 'ZeroSpecialDefect__c': 'true',
                      'HoldMinLevel__c': 'TIGHTENED', 'HoldFullInspection__c': 'true', 'SupplierContainment__c': 'true', 'SupplierReportFrequency__c': 'WEEKLY',
                      'ExtensionCount__c': 0, 'ActualLots__c': 2, 'ActualRejectLots__c': 0, 'ActualReceivedQty__c': 1000, 'ActualDefectQty__c': 0,
                      'ActualPpm__c': 0, 'ActualSpecialDefects__c': 0})
        rel = self.seq('STB-{PLANT}-{YYYY}', 'KR01', 2025, 5)
        o.add(f_stb, {'RecordNo__c': rel, 'RecordTypeDeveloperName': 'PART', 'Status__c': 'RELEASED', 'SupplierItem__r.ExternalKey__c': self.si_key('V10003', 'P-LED-BE1', 'KR01'),
                      'Supplier__r.SapVendorNo__c': 'V10003', 'Item__r.ItemNo__c': 'P-LED-BE1', 'Plant__r.PlantCode__c': 'KR01', 'Trigger__c': 'NEW_PART',
                      'StartDate__c': iso(self.D('2025-06-02')), 'MinDays__c': 90, 'MinLots__c': 10, 'TargetPpm__c': 100, 'ZeroSpecialDefect__c': 'true',
                      'HoldMinLevel__c': 'TIGHTENED', 'HoldFullInspection__c': 'false', 'SupplierContainment__c': 'true', 'SupplierReportFrequency__c': 'WEEKLY',
                      'ExtensionCount__c': 0, 'ActualLots__c': 14, 'ActualRejectLots__c': 0, 'ActualReceivedQty__c': 14000, 'ActualDefectQty__c': 0,
                      'ActualPpm__c': 0, 'ActualSpecialDefects__c': 0, 'ReleasedAt__c': ts(self.D('2025-09-15'), 14), 'ReleaseComment__c': '해제 조건 충족(데모)'})
        o.add(self.f_hold, {'ExternalKey__c': f'HOLD-{stb_no}', 'SupplierItem__r.ExternalKey__c': self.si_key('V10001', 'P-LENS-HE1', 'KR01'), 'HoldType__c': 'STABILIZATION',
                            'MinLevel__c': 'TIGHTENED', 'FullInspection__c': 'true', 'SourceRecordId__c': ref('QMS_StabilizationPlan__c', 'RecordNo__c', stb_no),
                            'SourceRecordNo__c': stb_no, 'IsActive__c': 'true'})
        self.holds.append({'supplierItem': self.si_key('V10001', 'P-LENS-HE1', 'KR01'), 'type': 'STABILIZATION', 'source': stb_no, 'active': True})
        self.placeholders = {'@S3-4M': fm_no}
        # --- 이력(S3 포함 합계 = 명세 건수): 인정시험 14 + S3 = 15, PPAP 16 + 델타 + S3 = 18, 4M 11 + S3 = 12(종결 10)
        hist_items = [('P-LED-HE1', 'V10003'), ('P-HSG-BE1', 'V10002'), ('P-CON-01', 'V10005'), ('P-PCB-HE1', 'V10006'), ('P-ACT-01', 'V10007'), ('P-REF-BE1', 'V10004'),
                      ('P-BZL-HE1', 'V10002'), ('P-LED-BE1', 'V10003'), ('P-VENT-01', 'V10008')]
        for k in range(14):
            d = self.D('2025-01-15') + dt.timedelta(days=k * 40)
            if k < 6:
                item, v = hist_items[k % len(hist_items)]
                qual(item, 'KR01', 'NEW_DEV', 'DV', 'TS-LED-NEWPART-DV' if 'LED' in item else 'TS-LENS-4M-RESIN', d, d + dt.timedelta(days=45), 'CLOSED', 'PASS', supplier=v)
            else:
                fg = r.choice(['63117-BE1L', '92101-HE1L', '92101-KE1L', '84001-GE1L'])
                cust = self.items[fg]['customer']
                std = 'TS-HL-BMW-NEWDEV-DV' if cust == 'BMW' else ('TS-HL-4M-PROCESS' if k % 3 == 0 else 'TS-HL-NEWDEV-DV')
                qual(fg, self.items[fg]['plants'][0], 'CHANGE_4M' if std == 'TS-HL-4M-PROCESS' else 'NEW_DEV', 'CHANGE' if std == 'TS-HL-4M-PROCESS' else 'DV', std,
                     d, d + dt.timedelta(days=60), 'CLOSED', 'PASS' if k != 9 else 'CONDITIONAL', customer=cust, vehicle=self.items[fg]['vehicles'][0], rt='PRODUCT')
        for k in range(16):
            item, v = hist_items[k % len(hist_items)]
            plant = 'KR01' if k % 4 else 'PL01' if (v, item, 'PL01') in self.si else 'KR01'
            ppap(v, item, plant, ['NEW_PART', 'CHANGE_4M', 'TOOL_TRANSFER', 'ECO'][k % 4], self.D('2025-01-20') + dt.timedelta(days=k * 33), 'APPROVED', 'APPROVED')
        delta = ppap('V10004', 'P-REF-BE1', 'KR01', 'NEW_PART', self.D('2026-08-10'), 'APPROVAL', 'INTERIM',
                     interim=(self.D('2026-12-20'), '증착 두께 공정능력 Ppk 1.41(목표 1.67) — 30로트 데이터로 재제출'))
        self.keys['S0-PPAP-INTERIM'] = delta
        types = ['MOLD_REPAIR', 'PROCESS_PARAM', 'EQUIP_REPLACE', 'SITE_TRANSFER', 'RESIN_SUPPLIER', 'SUB_PART_SUPPLIER', 'MOLD_TRANSFER', 'GAUGE_METHOD',
                 'SC_OPERATOR_CHANGE', 'ENV_CONDITION', 'PROCESS_PARAM']
        for k, ct in enumerate(types):
            sup = ct in ('RESIN_SUPPLIER', 'SUB_PART_SUPPLIER', 'MOLD_TRANSFER')
            d = self.D('2025-01-10') + dt.timedelta(days=k * 50)
            no = self.seq('4M-{PLANT}-{YYYY}', 'KR01', d.year, 5)
            l1 = next(x for x in self.m['codes']['CHANGE_TYPE'] for y in x['children'] if ct in y['children'])['code']
            closed = k < 10
            unauthorized = ct == 'PROCESS_PARAM' and k == 1
            v = {'RESIN_SUPPLIER': 'V10008', 'SUB_PART_SUPPLIER': 'V10003', 'MOLD_TRANSFER': 'V10002'}.get(ct)
            o.add(self.f_4m, {'RecordNo__c': no, 'RecordTypeDeveloperName': 'SUPPLIER' if sup else 'INTERNAL', 'Name': f'{C.CHANGE_TYPE_NAMES.get(ct, ct)}(데모 이력)',
                              'Status__c': 'CLOSED' if closed else ('VERIFYING' if k == 10 else 'APPLY_APPROVAL'), 'Plant__r.PlantCode__c': 'KR01',
                              'Supplier__r.SapVendorNo__c': v, 'PrimaryChangeType__r.ExternalKey__c': self.ck('CHANGE_TYPE', ct), 'ChangeTypeCodes__c': self.ck('CHANGE_TYPE', ct),
                              'Category5M1E__c': l1, 'BeforeDescription__c': '변경 전 조건(데모)', 'AfterDescription__c': '변경 후 조건(데모)',
                              'Reason__c': ['COST', 'QUALITY', 'CAPACITY', 'EQUIPMENT'][k % 4], 'PlannedApplyDate__c': iso(d + dt.timedelta(days=45)),
                              'RequestedDate__c': iso(d), 'LeadCompliant__c': str(not unauthorized).lower(), 'LateReason__c': '사후 등록(무단 변경 확인)' if unauthorized else None,
                              'RiskClass__c': ['B', 'C', 'B', 'A'][k % 4], 'SpecialCharImpact__c': 'false', 'PfmeaImpact__c': 'NONE', 'CustomerNotice__c': 'NOT_REQUIRED',
                              'AppliedAt__c': ts(d + dt.timedelta(days=50), 10) if closed else None, 'Unauthorized__c': str(unauthorized).lower(),
                              'FollowUpEndDate__c': iso(d + dt.timedelta(days=90)) if closed else None})
            o.add(self.f_4mi, {'ExternalKey__c': f'{no}-I01', 'FourM__r.RecordNo__c': no, 'ItemRole__c': 'CHANGED',
                               'Item__r.ItemNo__c': {'RESIN_SUPPLIER': 'R-PC-A01', 'SUB_PART_SUPPLIER': 'P-LED-HE1', 'MOLD_TRANSFER': 'P-HSG-BE1'}.get(ct, '63117-BE1L'),
                               'SupplierItem__r.ExternalKey__c': {'RESIN_SUPPLIER': self.si_key('V10008', 'R-PC-A01', 'KR01'), 'SUB_PART_SUPPLIER': self.si_key('V10003', 'P-LED-HE1', 'KR01'),
                                                                  'MOLD_TRANSFER': self.si_key('V10002', 'P-HSG-BE1', 'KR01')}.get(ct),
                               'Line__r.ExternalKey__c': None if sup else 'KR01-L01', 'AddedBy__c': 'MANUAL', 'IsExcluded__c': 'false'})
            o.add(self.f_4mv, {'ExternalKey__c': f'{no}-V01', 'FourM__r.RecordNo__c': no, 'Sequence__c': 10, 'VerificationType__c': 'PFMEA_UPDATE',
                               'GateStage__c': 'BEFORE_APPLY', 'IsMandatory__c': 'true', 'Title__c': 'PFMEA 영향 검토', 'Owner__r.EmployeeNo__c': 'E1103',
                               'DueDate__c': iso(d + dt.timedelta(days=20)), 'Status__c': 'DONE' if closed or k == 11 else 'IN_PROGRESS', 'AutoCreated__c': 'true'})
            if unauthorized:
                self.keys['S0-4M-UNAUTHORIZED'] = no

    # ------------------------------------------------------------ S1 부적합 Full Cycle
    def s1(self):
        o, r = self.out, rng('sf-s1', self.seed)
        d0 = self.D('2026-11-24')
        ctx = {'item': '63117-BE1L', 'plant': 'KR01', 'line': 'L01', 'op': None, 'vendor': None, 'si': None, 'fg': '63117-BE1L'}
        no = self.seq('NCR-{PLANT}-{YYYY}', 'KR01', 2026, 6)
        desc = ('BMW 조립 라인 세차 시험 후 BE1 헤드램프 LH 렌즈 내부 상단에 김서림이 보여 3EA가 반품됐다. '
                '반품품 3EA 모두 실링 비드 끊김 없이 폭이 얇은 구간(하단 좌측)이 있고, 같은 주간 생산품이다.')
        self.keys['S1-NCR'] = no
        o.add(self.f_ncr, {
            'RecordNo__c': no, 'RecordTypeDeveloperName': 'INTERNAL', 'Name': 'BE1 헤드램프 LH 내부 김서림(BMW 반품)', 'Status__c': 'COUNTERMEASURE',
            'ResponsibilityStatus__c': 'CONFIRMED', 'CountermeasureType__c': 'FULL_8D', 'SourceType__c': 'CUSTOMER_RETURN',
            'SourceRecordId__c': None, 'SourceObject__c': None, 'SourceRecordNo__c': 'BMW-RT-2611-0042(가상)',
            'Plant__r.PlantCode__c': 'KR01', 'Line__r.ExternalKey__c': 'KR01-L01', 'Operation__r.ExternalKey__c': None, 'Item__r.ItemNo__c': '63117-BE1L',
            'Customer__r.OemCode__c': 'BMW', 'Vehicle__r.ExternalKey__c': 'BMW-BE1', 'DetectedAt__c': ts(d0, 9, 40), 'DetectedBy__r.EmployeeNo__c': 'E1103',
            'DefectType__r.ExternalKey__c': self.ck('DEFECT_TYPE', 'INNER_FOG'), 'DefectTypePath__c': self.cpath('DEFECT_TYPE', 'INNER_FOG'),
            'Characteristic__r.ExternalKey__c': self.char_key('63117-BE1L', 'C50'), 'Description__c': desc,
            'SuspectQty__c': 160, 'DefectQty__c': 3, 'DefectQtyConfirmedAt__c': ts(d0, 17), 'Uom__c': 'EA', 'LotNos__c': '63117-BE1L-261116-02,63117-BE1L-261117-01',
            'Severity__c': 'B', 'CustomerImpact__c': 'true', 'Responsibility__r.ExternalKey__c': self.ck('RESPONSIBILITY', 'INTERNAL_PROCESS'),
            'ResponsibleDept__r.DeptCode__c': 'D1120', 'ContainmentDueAt__c': ts(d0 + dt.timedelta(days=1), 18), 'ContainmentDone__c': 'true',
            'ContainmentSummary__c': '사내 완제품 재고 120EA 기밀 재검사(불량 0), 운송 중 40EA 회수 선별(불량 0)', 'CountermeasureDueDate__c': iso(d0 + dt.timedelta(days=20)),
            'VerificationResult__c': 'PENDING', 'NoticeIssuedAt__c': ts(d0, 13), 'EightDClosed__c': 'false'})
        ed = self.make_8d(r, 'NCR_INTERNAL', 'FULL_8D', no, 'QMS_NCR__c', ctx, 'INNER_FOG', None, d0, None, desc, 3, False,
                          customer='BMW', form='BMW_8D', current='D4', leader='E1103', champion='E1101')
        self.keys['S1-8D'] = ed
        row = self.f_8d['rows'][-1]
        row.update({'Name': 'BE1 LH 내부 김서림 8D(BMW 반품)', 'D2What__c': 'BE1 헤드램프 LH 렌즈 내부 김서림', 'D2Where__c': 'BMW 조립 라인 세차 시험(KR01 L01 생산품)',
                    'D2When__c': '2026-11-24 반품 접수(생산 2026-11-16~17)', 'D2Who__c': 'BMW 라인 검사원 발견, SL 품질 접수',
                    'D2Why__c': '고객 라인 정지 위험, 필드 유출 시 시인성 저하', 'D2How__c': '세차 시험 후 육안', 'D2HowMany__c': 3,
                    'D3Effective__c': 'true', 'DueDate__c': iso(d0 + dt.timedelta(days=20))})
        o.add(self.f_ncr2, {'RecordNo__c': no, 'EightD__r.RecordNo__c': ed})
        for k, (loc, qc, ng, by) in enumerate([('FG_WAREHOUSE', 120, 0, 'E1105'), ('IN_TRANSIT', 40, 0, 'E1102')], 1):
            o.add(self.f_cont, {'ExternalKey__c': f'{no}-C{k:02d}', 'Ncr__r.RecordNo__c': no, 'Location__c': loc, 'Method__c': 'SORT_100',
                                'QtyChecked__c': qc, 'QtyNg__c': ng, 'Status__c': 'DONE', 'DoneBy__r.EmployeeNo__c': by,
                                'DoneAt__c': ts(d0 + dt.timedelta(days=1), 16)})
        o.add(self.f_disp, {'ExternalKey__c': f'{no}-D01', 'Ncr__r.RecordNo__c': no, 'Sequence__c': 1, 'Disposition__r.ExternalKey__c': self.ck('DISPOSITION', 'SCRAP'),
                            'Qty__c': 3, 'Uom__c': 'EA', 'Executor__r.EmployeeNo__c': 'E1102', 'PlannedDate__c': iso(d0 + dt.timedelta(days=5)),
                            'DoneDate__c': None, 'Status__c': 'PLANNED', 'CustomerApprovalRequired__c': 'false', 'SapMovementRequired__c': 'true',
                            'SapMovementStatus__c': 'PENDING'})
        self.s1_ctx = {'ncr': no, '8d': ed, 'line': 'KR01-L01', 'operation': 'KR01-L01-OP20', 'characteristic': self.char_key('63117-BE1L', 'C40'),
                       'gauge': 'GA-KR01-0610'}

    # ------------------------------------------------------------ S2 고객 클레임 8D
    def s2(self):
        o, r = self.out, rng('sf-s2', self.seed)
        d0 = self.D('2026-11-12')
        c = next(x for x in self.m['customers'] if x['oemCode'] == 'HMC')
        no = self.seq('CLM-{PLANT}-{YYYY}', 'KR01', 2026, 5)
        lab_no = self.seq('LAB-{PLANT}-{YYYY}', 'KR01', 2026, 5)
        ncr_no = self.seq('NCR-{PLANT}-{YYYY}', 'KR01', 2026, 6)
        self.keys.update({'S2-CLAIM': no, 'S2-LAB': lab_no, 'S2-NCR': ncr_no})
        desc = ('HMC HE1 필드에서 주간주행등(DRL) 점멸 12건 접수. MIS 1~3개월 차량 집중(MIS 3 이내 12건), 고유 VIN 해시 12건. '
                '저온 시동 직후 점멸이 시작되고 수 분 뒤 사라진다는 정비 기록이 다수다.')
        row = {'RecordNo__c': no, 'Name': 'HMC HE1 DRL 점멸(필드)', 'ExternalKey__c': 'HMC-20261112-012', 'Status__c': 'CORRECTIVE', 'Result__c': None,
               'Customer__r.OemCode__c': 'HMC', 'Vehicle__r.ExternalKey__c': 'HMC-HE1', 'Item__r.ItemNo__c': '92101-HE1L',
               'CustomerPartNo__c': self.items['92101-HE1L'].get('customerPartNo'), 'Plant__r.PlantCode__c': 'KR01', 'Line__r.ExternalKey__c': 'KR01-L05',
               'ClaimType__c': 'FIELD', 'Severity__c': 'MAJOR', 'SourceChannel__c': 'MANUAL', 'CustomerClaimNo__c': 'HMC-QC-2611-4471',
               'ReceivedAt__c': ts(d0, 9), 'OccurredDate__c': iso(d0 - dt.timedelta(days=6)), 'OccurrenceLocation__c': '국내 딜러 정비 입고(데모)', 'Country__c': 'KR',
               'DefectDescription__c': desc, 'CustomerDefectCode__c': 'E-DRL-FLK', 'DefectType__r.ExternalKey__c': self.ck('DEFECT_TYPE', 'DRL_FLICKER'),
               'DefectTypePath__c': self.cpath('DEFECT_TYPE', 'DRL_FLICKER'), 'ClaimQty__c': 12, 'SuspectQty__c': 3600,
               'ProductionDateFrom__c': '2026-08-03', 'ProductionDateTo__c': '2026-09-25', 'LotInfo__c': 'MIS 1~3, VIN 해시 12건(Snowflake B2B 원천), LED 모듈 로트 V10003-2608xx',
               'ContainmentDueAt__c': ts(d0 + dt.timedelta(days=c['containmentDays']), 18), 'RootCauseDueDate__c': iso(d0 + dt.timedelta(days=c['rootCauseDays'])),
               'FinalDueDate__c': iso(d0 + dt.timedelta(days=c['eightDDays'])), 'CustomerResponseForm__c': 'HKMC_6PI', 'IsRecurrence__c': 'false', 'EscalationLevel__c': 1,
               'Responsibility__r.ExternalKey__c': self.ck('RESPONSIBILITY', 'SUPPLIER'), 'Supplier__r.SapVendorNo__c': 'V10003',
               'SupplierItem__r.ExternalKey__c': self.si_key('V10003', 'P-LED-HE1', 'KR01'), 'Characteristic__r.ExternalKey__c': self.char_key('P-LED-HE1', 'C40'),
               'SpecialCharEscape__c': 'true', 'AnalysisResult__c': '반품 6EA X-ray: LED 솔더 보이드 최대 31%(기준 25% 이하), 저온 열충격 후 접촉 불량 재현',
               'ReturnQty__c': 6, 'ReturnReceivedDate__c': iso(d0 + dt.timedelta(days=2)),
               'LabRequestRecordId__c': ref('QMS_LabRequest__c', 'RecordNo__c', lab_no), 'LabRequestRecordNo__c': lab_no,
               'LabResultSummary__c': 'X-ray 솔더 보이드 31%(NG), 단면 관찰 솔더 크랙 확인',
               'SupplierNcrRecordId__c': ref('QMS_NCR__c', 'RecordNo__c', ncr_no), 'SupplierNcrRecordNo__c': ncr_no,
               'ResponsibilityApproved__c': 'true', 'CustomerAccepted__c': 'false'}
        o.add(self.f_claim, row)
        ctx = {'item': '92101-HE1L', 'plant': 'KR01', 'line': 'L05', 'op': None, 'vendor': None, 'si': None, 'fg': '92101-HE1L'}
        ced = self.make_8d(r, 'CUSTOMER_CLAIM', 'FULL_8D', no, 'QMS_Claim__c', ctx, 'DRL_FLICKER', None, d0, None, desc, 12, False,
                           customer='HMC', form='HKMC_6PI', current='D4', leader='E1202', champion='E1201')
        self.f_8d['rows'][-1].update({'Name': 'HMC HE1 DRL 점멸 고객 8D(6PI)', 'D2What__c': 'HE1 헤드램프 DRL 점멸', 'D2Where__c': '국내 필드(딜러 정비 입고)',
                                      'D2When__c': 'MIS 1~3, 2026-11 접수', 'D2HowMany__c': 12, 'D2Who__c': 'HMC 품질(필드)',
                                      'D2How__c': '정비 입고 시 고객 불만, 저온 시동 직후 재현', 'DueDate__c': iso(d0 + dt.timedelta(days=14))})
        self.keys['S2-CLAIM-8D'] = ced
        o.add(self.f_claim2, {'RecordNo__c': no, 'EightD__r.RecordNo__c': ced})
        # 분석 의뢰(X-ray)
        self.lab_request(lab_no, 'CLAIM', ('QMS_Claim__c', no), 'KR01', 'E1202', 'D1020', 'PRODUCT', '92101-HE1L', 'V10003', 6,
                         'HE1 헤드램프 반품품 6EA(DRL 점멸 발생품), LED 모듈 분리 전 상태', d0 + dt.timedelta(days=2), d0 + dt.timedelta(days=6),
                         [('LAB-XRAY-001', 31.0, 'NG'), ('LAB-XSEC-001', None, 'NG')], 'NONCONFORM',
                         'LED 모듈 솔더 보이드 최대 31%(기준 25% 이하) — 리플로 프로파일 이상 의심, 단면 관찰에서 솔더 크랙', urgent=True)
        # 협력사 NCR·8D
        ctx2 = {'item': 'P-LED-HE1', 'plant': 'KR01', 'line': None, 'op': None, 'vendor': 'V10003', 'si': self.si_key('V10003', 'P-LED-HE1', 'KR01'), 'fg': '92101-HE1L'}
        nd = d0 + dt.timedelta(days=7)
        ndesc = 'HMC HE1 DRL 점멸 클레임 반품 분석 결과 LED 모듈 솔더 보이드 31%(기준 25% 이하). 감마LED 리플로 공정 원인 조사와 대책을 요구한다.'
        o.add(self.f_ncr, {
            'RecordNo__c': ncr_no, 'RecordTypeDeveloperName': 'SUPPLIER', 'Name': 'HE1 LED 모듈 솔더 보이드 초과(클레임 귀책)', 'Status__c': 'COUNTERMEASURE',
            'ResponsibilityStatus__c': 'CONFIRMED', 'CountermeasureType__c': 'FULL_8D', 'SourceType__c': 'CUSTOMER_CLAIM',
            'SourceRecordId__c': ref('QMS_Claim__c', 'RecordNo__c', no), 'SourceObject__c': 'QMS_Claim__c', 'SourceRecordNo__c': no,
            'Plant__r.PlantCode__c': 'KR01', 'Item__r.ItemNo__c': 'P-LED-HE1', 'Supplier__r.SapVendorNo__c': 'V10003',
            'SupplierItem__r.ExternalKey__c': ctx2['si'], 'SupplierShareTo__r.SapVendorNo__c': 'V10003', 'Customer__r.OemCode__c': 'HMC',
            'Vehicle__r.ExternalKey__c': 'HMC-HE1', 'DetectedAt__c': ts(nd, 10), 'DetectedBy__r.EmployeeNo__c': 'E1112',
            'DefectType__r.ExternalKey__c': self.ck('DEFECT_TYPE', 'DRL_FLICKER'), 'DefectTypePath__c': self.cpath('DEFECT_TYPE', 'DRL_FLICKER'),
            'Characteristic__r.ExternalKey__c': self.char_key('P-LED-HE1', 'C40'), 'Description__c': ndesc, 'SuspectQty__c': 3600, 'DefectQty__c': 12,
            'DefectQtyConfirmedAt__c': ts(nd, 17), 'Uom__c': 'EA', 'LotNos__c': 'V10003-260803-A~V10003-260925-A', 'Severity__c': 'B', 'CustomerImpact__c': 'true',
            'Responsibility__r.ExternalKey__c': self.ck('RESPONSIBILITY', 'SUPPLIER'), 'ContainmentDueAt__c': ts(nd + dt.timedelta(days=1), 18),
            'ContainmentDone__c': 'true', 'ContainmentSummary__c': '협력사 재고 2,400EA X-ray 전수, SL 입고 재고 1,000EA 격리 후 선별',
            'CountermeasureDueDate__c': iso(nd + dt.timedelta(days=21)), 'VerificationResult__c': 'PENDING', 'NoticeIssuedAt__c': ts(nd, 14), 'EightDClosed__c': 'false'})
        sed = self.make_8d(r, 'NCR_SUPPLIER', 'FULL_8D', ncr_no, 'QMS_NCR__c', ctx2, 'DRL_FLICKER', None, nd, None, ndesc, 12, False,
                           current='D5', leader='E1112', champion='E1111')
        cinfo = C.CAUSES['LED_SOLDER']
        self.f_8d['rows'][-1].update({'Name': '감마LED HE1 LED 모듈 솔더 보이드 8D(협력사)', 'OccurrenceCause__c': cinfo['occ'], 'EscapeCause__c': cinfo['esc'],
                                      'OccurrenceCauseCode__r.ExternalKey__c': self.ck('CAUSE_5M1E', 'LED_SOLDER'),
                                      'WhyWhyJson__c': j([{'chain': 'OCCURRENCE', 'whys': cinfo['why']}]), 'RootCauseVerified__c': 'true',
                                      'RootCauseVerification__c': '협력사 리플로 프로파일 재현 시험(피크 온도 -8℃에서 보이드 28~33%)',
                                      'SupplierLeaderName__c': '감마LED 품질팀장(가상)'})
        self.keys['S2-8D'] = sed
        o.add(self.f_ncr2, {'RecordNo__c': ncr_no, 'EightD__r.RecordNo__c': sed})
        o.add(self.f_cont, {'ExternalKey__c': f'{ncr_no}-C01', 'Ncr__r.RecordNo__c': ncr_no, 'Location__c': 'RECEIVING', 'Method__c': 'SORT_100',
                            'QtyChecked__c': 1000, 'QtyNg__c': 0, 'Status__c': 'DONE', 'DoneBy__r.EmployeeNo__c': 'E1104', 'DoneAt__c': ts(nd + dt.timedelta(days=1), 15)})
        o.add(self.f_cont, {'ExternalKey__c': f'{ncr_no}-C02', 'Ncr__r.RecordNo__c': ncr_no, 'Location__c': 'SUPPLIER', 'Method__c': 'SORT_100',
                            'QtyChecked__c': 2400, 'QtyNg__c': 37, 'Status__c': 'DONE', 'DoneBy__r.EmployeeNo__c': 'E1112', 'DoneAt__c': ts(nd + dt.timedelta(days=2), 18)})
        # 협력사 포털 제출(단계별)
        f_sub = o.file('QMS_EightDSubmission__c', 'ExternalKey__c', {'EightD__r.RecordNo__c': ('QMS_EightD__c', 'RecordNo__c'), 'Supplier__r.SapVendorNo__c': R_SUPP,
                                                                     'Plant__r.PlantCode__c': R_PLANT, 'ReviewedBy__r.EmployeeNo__c': R_USER})
        self.add_cr('QMS-05-CLM-005', 'QMS_EightDSubmission__c에 ExternalKey__c 추가, SubmittedBy__c(포털 사용자 Lookup)는 데모에서 비움', '{8D 번호}-{Stage}-R{Round}')
        subs = [('CONTAINMENT', 'REVIEWED', 'ACCEPTED', 1, 2, j({'d1Team': ['감마LED 품질팀장(가상)', '감마LED 생산기술(가상)'],
                                                                  'd2': 'HE1 DRL LED 모듈 솔더 보이드 초과', 'd3': '재고 2,400EA X-ray 전수, NG 37EA 격리'})),
                ('ROOT_CAUSE', 'REVIEWED', 'ACCEPTED', 1, 7, j({'occurrence': cinfo['occ'], 'escape': cinfo['esc'], 'whys': cinfo['why']})),
                ('ACTION_PLAN', 'DRAFT', None, 1, 14, None)]
        for stage, st, dec, rnd, dd, content in subs:
            sub_d = nd + dt.timedelta(days=dd)
            o.add(f_sub, {'ExternalKey__c': f'{sed}-{stage}-R{rnd}', 'EightD__r.RecordNo__c': sed, 'Supplier__r.SapVendorNo__c': 'V10003',
                          'Plant__r.PlantCode__c': 'KR01', 'Stage__c': stage, 'Round__c': rnd, 'Status__c': st, 'Decision__c': dec,
                          'DueDate__c': iso(sub_d), 'ContentJson__c': content,
                          'ActionsJson__c': j([{'type': 'CORRECTIVE', 'text': a} for a in cinfo['actions'][:2]]) if stage == 'ACTION_PLAN' else None,
                          'TeamJson__c': j(['감마LED 품질팀장(가상)', '감마LED 생산기술(가상)', 'SL SQE 임재현']) if stage == 'CONTAINMENT' else None,
                          'SubmittedAt__c': ts(sub_d - dt.timedelta(days=1), 16) if st != 'DRAFT' else None,
                          'ReviewedBy__r.EmployeeNo__c': 'E1112' if st == 'REVIEWED' else None, 'ReviewedAt__c': ts(sub_d, 11) if st == 'REVIEWED' else None})
        self.s2_ctx = {'claim': no, 'claim8d': ced, 'lab': lab_no, 'ncr': ncr_no, '8d': sed}

    def lab_request(self, no, purpose, src, plant, requester, dept, stype, item, vendor, qty, sample_desc, d_req, d_done, items, conclusion, summary,
                    urgent=False, status='COMPLETED'):
        o = self.out
        if not hasattr(self, 'f_lab'):
            self.f_lab = o.file('QMS_LabRequest__c', 'RecordNo__c', {'Plant__r.PlantCode__c': R_PLANT, 'RequesterPlant__r.PlantCode__c': R_PLANT,
                                                                     'RequesterDept__r.DeptCode__c': R_DEPT, 'Requester__r.EmployeeNo__c': R_USER,
                                                                     'Item__r.ItemNo__c': R_ITEM, 'Supplier__r.SapVendorNo__c': R_SUPP,
                                                                     'AcceptedBy__r.EmployeeNo__c': R_USER})
            self.f_labi = o.file('QMS_LabRequestItem__c', 'ExternalKey__c', {'Request__r.RecordNo__c': ('QMS_LabRequest__c', 'RecordNo__c'),
                                                                            'AnalysisItem__r.ItemCode__c': ('QMS_LabAnalysisItem__c', 'ItemCode__c'),
                                                                            'Equipment__r.GaugeNo__c': ('QMS_Gauge__c', 'GaugeNo__c'), 'Analyst__r.EmployeeNo__c': R_USER})
            self.add_cr('QMS-06-LAB-001', 'QMS_LabRequestItem__c에 ExternalKey__c 추가', '{의뢰 번호}-I{nn}')
        labs = {x[0]: x for x in C.LAB_ITEMS}
        eq = {'LAB-XRAY-001': 'GA-KR01-0720', 'LAB-XSEC-001': 'GA-KR01-0721', 'LAB-FTIR-001': 'GA-KR01-0722', 'LAB-DSC-001': 'GA-KR01-0723',
              'LAB-HARD-001': 'GA-KR01-0724', 'LAB-MOIST-001': 'GA-KR01-0725', 'LAB-HAZE-001': 'GA-KR01-0705', 'LAB-SEM-001': 'GA-KR01-0726'}
        done = status == 'COMPLETED'
        o.add(self.f_lab, {'RecordNo__c': no, 'Name': sample_desc[:60], 'RequestType__c': 'ADHOC', 'Purpose__c': purpose,
                           'SourceRecordId__c': ref(src[0], 'RecordNo__c', src[1]) if src else None, 'SourceObject__c': src[0] if src else None,
                           'SourceRecordNo__c': src[1] if src else None, 'Plant__r.PlantCode__c': 'KR01', 'RequesterPlant__r.PlantCode__c': plant,
                           'RequesterDept__r.DeptCode__c': dept, 'Requester__r.EmployeeNo__c': requester, 'SampleType__c': stype, 'Item__r.ItemNo__c': item,
                           'Supplier__r.SapVendorNo__c': vendor, 'LotNo__c': None, 'SampleQty__c': qty, 'SampleDescription__c': sample_desc,
                           'Priority__c': 'URGENT' if urgent else 'NORMAL', 'UrgentReason__c': '고객 클레임 원인 회신 기한' if urgent else None,
                           'RequiredDate__c': iso(d_done), 'AcceptedBy__r.EmployeeNo__c': 'E1171', 'AcceptedAt__c': ts(d_req, 14),
                           'SampleReceivedAt__c': ts(d_req, 16), 'DueDate__c': iso(d_done), 'Conclusion__c': conclusion if done else None,
                           'Summary__c': summary if done else None, 'Status__c': status})
        for k, (code, val, judg) in enumerate(items, 1):
            li = labs[code]
            o.add(self.f_labi, {'ExternalKey__c': f'{no}-I{k:02d}', 'Request__r.RecordNo__c': no, 'AnalysisItem__r.ItemCode__c': code, 'ItemCode__c': code,
                                'ItemName__c': li[1], 'MethodStandard__c': li[4], 'ResultType__c': li[6], 'Unit__c': li[7], 'IsExternal__c': 'false',
                                'StandardTatDays__c': li[8], 'Equipment__r.GaugeNo__c': eq.get(code), 'Analyst__r.EmployeeNo__c': 'E1162',
                                'Status__c': 'DONE' if done else 'IN_PROGRESS', 'ResultValue__c': val if done and li[6] == 'VALUE' else None,
                                'ResultText__c': (summary if val is None else None) if done and li[6] != 'VALUE' else None,
                                'Judgment__c': judg if done else None, 'StartedAt__c': ts(d_req + dt.timedelta(days=1), 9),
                                'CompletedAt__c': ts(d_done, 15) if done else None})

    # ------------------------------------------------------------ 심사(S4 포함 8건)
    def audits(self):
        o, r = self.out, rng('sf-audit', self.seed)
        f_a = o.file('QMS_Audit__c', 'RecordNo__c', {'Plant__r.PlantCode__c': R_PLANT, 'Supplier__r.SapVendorNo__c': R_SUPP, 'Customer__r.OemCode__c': R_CUST,
                                                      'Checklist__r.ChecklistCode__c': ('QMS_AuditChecklist__c', 'ChecklistCode__c'),
                                                      'AuditeeDept__r.DeptCode__c': R_DEPT, 'LeadAuditor__r.EmployeeNo__c': R_USER, 'ProductGroup__r.GroupCode__c': R_PG})
        f_a2 = o.file('QMS_Audit__c', 'RecordNo__c', {'ParentAudit__r.RecordNo__c': ('QMS_Audit__c', 'RecordNo__c')}, tag='pass2-parent')
        f_ri = o.file('QMS_AuditResultItem__c', 'ExternalKey__c', {'Audit__r.RecordNo__c': ('QMS_Audit__c', 'RecordNo__c'),
                                                                   'Question__r.ExternalKey__c': ('QMS_AuditQuestion__c', 'ExternalKey__c'),
                                                                   'AnsweredBy__r.EmployeeNo__c': R_USER})
        f_fd = o.file('QMS_AuditFinding__c', 'RecordNo__c', {'Audit__r.RecordNo__c': ('QMS_Audit__c', 'RecordNo__c'), 'Plant__r.PlantCode__c': R_PLANT,
                                                             'Supplier__r.SapVendorNo__c': R_SUPP, 'Customer__r.OemCode__c': R_CUST,
                                                             'ResponsibleDept__r.DeptCode__c': R_DEPT, 'ResponsibleUser__r.EmployeeNo__c': R_USER,
                                                             'RootCauseCode__r.ExternalKey__c': R_CODE, 'VerifiedBy__r.EmployeeNo__c': R_USER})
        f_pt = o.file('QMS_CustomerAuditPrepTask__c', 'ExternalKey__c', {'Audit__r.RecordNo__c': ('QMS_Audit__c', 'RecordNo__c'), 'Owner__r.EmployeeNo__c': R_USER})
        self.add_cr('QMS-06-IAU-002', 'QMS_AuditResultItem__c·QMS_CustomerAuditPrepTask__c에 ExternalKey__c 추가', '{심사 번호}-{질문 번호}, {심사 번호}-T{nn}')

        def audit(rt, atype, plant, start, status, name, lead, supplier=None, customer=None, kind=None, checklist='VDA63-SL-DEMO-V1', score=None,
                  grade=None, ext_auditors=None, parent=None, reason=None, end=None, reg_year=None, **extra):
            no = self.seq('AUD-{PLANT}-{YYYY}', plant, reg_year or start.year, 5)
            done = status in ('REPORTING', 'REPORT_APPROVAL', 'FOLLOW_UP', 'CLOSED')
            row = {'RecordNo__c': no, 'RecordTypeDeveloperName': rt, 'Name': name, 'AuditType__c': atype, 'Plant__r.PlantCode__c': plant,
                   'Supplier__r.SapVendorNo__c': supplier, 'Customer__r.OemCode__c': customer,
                   'Checklist__r.ChecklistCode__c': checklist if rt in ('INTERNAL', 'SUPPLIER') or checklist else None, 'ChecklistCode__c': checklist,
                   'ScopeProcessCodes__c': 'P2;P3;P4;P5;P6;P7' if atype == 'PROCESS' else ('QMS' if atype == 'SYSTEM' else None),
                   'ScopeLineIds__c': 'KR01-L01' if atype == 'PROCESS' and rt == 'INTERNAL' else None, 'Shift__c': 'ALL' if atype == 'PROCESS' and rt == 'INTERNAL' else None,
                   'AuditeeDept__r.DeptCode__c': 'D1120' if rt == 'INTERNAL' else None, 'PlannedStart__c': iso(start),
                   'PlannedEnd__c': iso(end or start + dt.timedelta(days=1)), 'ActualStart__c': iso(start) if done else None,
                   'ActualEnd__c': iso(end or start + dt.timedelta(days=1)) if done else None, 'LeadAuditor__r.EmployeeNo__c': lead,
                   'ExternalAuditors__c': ext_auditors, 'IsRemote__c': 'false', 'ScorePercent__c': score, 'Grade__c': grade,
                   'ScoreSource__c': ('ENTERED' if rt in ('CUSTOMER', 'CERTIFICATION') else 'CALCULATED') if score is not None else None,
                   'Conclusion__c': '중대한 시스템 결함 없음. 지적 사항 시정 후 유효성 확인 예정(데모).' if done else None,
                   'Strengths__c': '변경 관리 이력과 교육 기록이 시스템으로 추적된다(데모).' if done else None,
                   'SupplierSite__c': '본사 공장(가상)' if rt == 'SUPPLIER' else None, 'AuditRequestReason__c': reason if rt == 'SUPPLIER' else None,
                   'CustomerAuditKind__c': kind if rt == 'CUSTOMER' else None, 'Status__c': status}
            row.update(extra)
            o.add(f_a, row)
            if parent:
                o.add(f_a2, {'RecordNo__c': no, 'ParentAudit__r.RecordNo__c': parent})
            return no

        def results(no, scores, d, by):
            for k, qno, el, sub, text, star in self.vda_q:
                sc = scores.get(qno)
                o.add(f_ri, {'ExternalKey__c': f'{no}-{qno}', 'Audit__r.RecordNo__c': no, 'Question__r.ExternalKey__c': k, 'QuestionNo__c': qno,
                             'Element__c': el, 'SubElement__c': sub or None, 'Sequence__c': int(float(qno[1:].split('.')[0]) * 100 + len(qno)),
                             'QuestionText__c': text, 'IsStarQuestion__c': str(star).lower(), 'AnswerType__c': 'SCORE_STEPS', 'MaxPoints__c': 10, 'Weight__c': 1,
                             'AllowNA__c': 'true', 'Points__c': sc, 'Status__c': 'ANSWERED' if sc is not None else 'OPEN',
                             'Notes__c': '4M 적용 시점(첫 로트·식별) 증빙이 시스템 밖 엑셀에 흩어져 있음' if qno == 'P6.1.4' else None,
                             'AnsweredBy__r.EmployeeNo__c': by if sc is not None else None, 'AnsweredAt__c': ts(d, 16) if sc is not None else None})

        # 직전 BMW 공정 심사(2025-05) — FOLLOW_UP, 지적 3건(종결 2, 진행 1)
        prev = audit('CUSTOMER', 'PROCESS', 'KR01', self.D('2025-05-13'), 'FOLLOW_UP', 'BMW 공정 심사 2025(BE1 라인)', 'E1101', customer='BMW',
                     kind='VDA63_PROCESS', score=86.0, grade='B', ext_auditors='BMW 공급자 품질 심사원 2명(가상)', end=self.D('2025-05-14'),
                     CustomerAuditRef__c='BMW-PA-2025-KR-0118(가상)', CustomerReportReceivedAt__c=iso(self.D('2025-05-28')), ScopeVehicles__c='BMW-BE1')
        self.keys['S4-AUDIT-PREV'] = prev
        fins = [('MINOR', 'P6.4.1', '측정기 교정 라벨과 시스템 교정 일자 불일치 2건', 'CLOSED', 'MEASUREMENT', 'GAUGE_DRIFT'),
                ('MINOR', 'P6.3.1', 'OP20 실링 작업자 자격 갱신 기록 누락', 'CLOSED', 'MAN', 'SKILL'),
                ('MAJOR', 'P6.1.4', '공정 변경(디스펜서 노즐 교체) 후 첫 생산품 확인 기록이 없음', 'IMPLEMENTED', 'METHOD', 'STD_NOT_FOLLOWED')]
        for fk, (cls, qno, text, st, _, cause) in enumerate(fins, 1):
            fno = self.seq('AF-{PLANT}-{YYYY}', 'KR01', 2025, 6)
            closed = st == 'CLOSED'
            o.add(f_fd, {'RecordNo__c': fno, 'Audit__r.RecordNo__c': prev, 'QuestionNo__c': qno, 'Classification__c': cls,
                         'RequirementRef__c': f'VDA 6.3 형식 {qno}(SL 문구)', 'Description__c': text, 'ObjectiveEvidence__c': '현장 확인·기록 대조(데모)',
                         'Plant__r.PlantCode__c': 'KR01', 'Customer__r.OemCode__c': 'BMW', 'ResponsibleDept__r.DeptCode__c': 'D1120',
                         'ResponsibleUser__r.EmployeeNo__c': 'E1103', 'IsReleased__c': 'true', 'ReleasedAt__c': ts(self.D('2025-05-28'), 10),
                         'ResponseDue__c': iso(self.D('2025-06-11')), 'ClosureDue__c': iso(self.D('2025-08-29') if cls == 'MINOR' else self.D('2026-12-31')),
                         'Correction__c': '즉시 수정(데모)', 'RootCause__c': C.CAUSES[cause]['occ'], 'RootCauseCode__r.ExternalKey__c': self.ck('CAUSE_5M1E', cause),
                         'RootCausePath__c': self.cpath('CAUSE_5M1E', cause), 'ImplementedDate__c': iso(self.D('2025-07-20') if closed else self.D('2026-10-30')),
                         'VerificationMethod__c': 'ON_SITE' if closed else None, 'VerificationRound__c': 1,
                         'VerifiedBy__r.EmployeeNo__c': 'E1101' if closed else None, 'VerifiedAt__c': ts(self.D('2025-08-20'), 15) if closed else None,
                         'ClosedAt__c': ts(self.D('2025-08-22'), 10) if closed else None, 'ExternalFindingRef__c': f'BMW-F{fk:02d}',
                         'ExternalClassification__c': 'Major' if cls == 'MAJOR' else 'Minor', 'ExternalAcceptance__c': 'ACCEPTED' if closed else 'PENDING',
                         'ExternalSubmittedAt__c': iso(self.D('2025-06-10')), 'Requires8D__c': 'false', 'Status__c': st})
            if not closed:
                self.keys['S4-PREV-FINDING-OPEN'] = fno
        # S4 — BMW 공정 심사 2027-01-20 준비, 자체 평가 2026-11-25(84%, B)
        scores = {q[1]: 10 for q in self.vda_q}
        tens = 6
        for i, q in enumerate(self.vda_q):
            if q[1] == 'P6.1.4':
                scores[q[1]] = 4
            elif i >= tens:
                scores[q[1]] = 8
        n8 = sum(1 for v in scores.values() if v == 8)
        assert n8 == 13 and sum(scores.values()) == 168, (n8, sum(scores.values()))
        s4 = audit('CUSTOMER', 'PROCESS', 'KR01', self.D('2027-01-20'), 'PREPARING', 'BMW 공정 심사 2027(BE1 라인) 대비', 'E1101', customer='BMW',
                   kind='VDA63_PROCESS', ext_auditors='BMW 공급자 품질 심사원(가상)', end=self.D('2027-01-21'), parent=prev, reg_year=2026,
                   CustomerAuditRef__c='BMW-PA-2027-KR-0007(가상)', ScopeVehicles__c='BMW-BE1', ReadinessScore__c=84.0, ReadinessGrade__c='B',
                   EvidenceFrom__c=iso(self.D('2025-12-01')), EvidenceTo__c=iso(self.D('2026-11-30')))
        self.keys['S4-AUDIT'] = s4
        results(s4, scores, self.D('2026-11-25'), 'E1102')
        tasks = [('SELF_ASSESSMENT', 'VDA 6.3 형식 자체 평가(P2~P7)', 'E1102', '2026-11-25', 'DONE', None),
                 ('PREVIOUS_FINDINGS', '직전 심사 MAJOR 지적(P6.1.4) 종결 증빙', 'E1103', '2026-12-15', 'OPEN', None),
                 ('EVIDENCE', '4M 적용 시점 증빙(첫 로트·식별·초기안정화) 시스템 조회 화면 준비', 'E1102', '2026-12-20', 'OPEN', None),
                 ('EVIDENCE', '렌즈 두께 공정능력(Cpk) 최근 6개월 자료', 'E1103', '2026-12-20', 'OPEN', None),
                 ('EVIDENCE', '측정기 교정 이력·S12 영향 분석 결과 정리', 'E1151', '2026-12-18', 'OPEN', None),
                 ('EXPECTED_FINDING', '변경 관리(P6.1.4) 예상 지적 대비 — 적용 시점 기록 표준화', 'E1101', '2026-12-31', 'OPEN', 'P6.1.4'),
                 ('TRAINING', 'BE1 라인 대응자 사전 교육(인터뷰 예상 질문)', 'E1101', '2027-01-10', 'OPEN', None),
                 ('LOGISTICS', '심사 일정·회의실·통역 확정', 'E1101', '2027-01-06', 'OPEN', None)]
        self.s4_tasks = []
        for k, (cat, title, own, due, st, qno) in enumerate(tasks, 1):
            tk = f'{s4}-T{k:02d}'
            self.s4_tasks.append((tk, title, own, due, st))
            o.add(f_pt, {'ExternalKey__c': tk, 'Audit__r.RecordNo__c': s4, 'Sequence__c': k * 10, 'Category__c': cat, 'Title__c': title,
                         'Description__c': None, 'Owner__r.EmployeeNo__c': own, 'DueDate__c': iso(self.D(due)), 'Status__c': st,
                         'CompletedDate__c': iso(self.D(due)) if st == 'DONE' else None, 'QuestionNo__c': qno,
                         'LinkedRecordId__c': ref('QMS_FourMChange__c', 'RecordNo__c', self.keys['S3-4M']) if k == 3 else None,
                         'LinkedRecordNo__c': self.keys['S3-4M'] if k == 3 else None})
        # 이력 심사 6건
        a1 = audit('INTERNAL', 'PROCESS', 'KR01', self.D('2026-03-17'), 'CLOSED', '내부 공정 심사 2026 상반기(L01)', 'E1002', score=88.5, grade='B')
        results(a1, {q[1]: (10 if i % 3 else 8) for i, q in enumerate(self.vda_q)}, self.D('2026-03-18'), 'E1002')
        audit('INTERNAL', 'SYSTEM', 'KR01', self.D('2025-09-09'), 'CLOSED', '내부 시스템 심사 2025(IATF 16949 기준)', 'E1003', checklist=None,
              Checklist__r_ChecklistCode__c=None)
        audit('SUPPLIER', 'PROCESS', 'KR01', self.D('2025-06-24'), 'CLOSED', '알파광학 정기 공정 심사 2025', 'E1112', supplier='V10001', score=91.0, grade='A',
              reason='PERIODIC', PublishedToSupplier__c='true')
        sup = audit('SUPPLIER', 'PROCESS', 'KR01', self.D('2026-12-10'), 'PREPARING', '베타폴리텍 품질 신호 공정 심사(하우징 평면도)', 'E1112', supplier='V10002',
                    reason='QUALITY_SIGNAL', PrepRequest__c='하우징 사출 금형 냉각·취출 조건 기록, 평면도 측정 데이터 최근 3개월 준비 요청',
                    SupplierNoticeSentAt__c=ts(self.D('2026-11-26'), 10))
        self.keys['S11-SUPPLIER-AUDIT'] = sup
        audit('CERTIFICATION', 'SYSTEM', 'KR01', self.D('2026-06-16'), 'CLOSED', 'IATF 16949 사후 심사 2026(KR01)', 'E1002', checklist=None,
              ext_auditors='인증기관 심사원 2명(가상)', CertDecision__c='RECOMMENDED', CustomerReportReceivedAt__c=iso(self.D('2026-06-30')))
        audit('CUSTOMER', 'PROCESS', 'KR01', self.D('2025-10-21'), 'CLOSED', 'HMC 공정 점검 2025(HE1 라인)', 'E1201', customer='HMC', kind='VDA63_PROCESS',
              score=92.0, grade='A', ext_auditors='HMC 협력사 품질 심사원(가상)', checklist=None, CustomerReportReceivedAt__c=iso(self.D('2025-11-05')))
        for row in f_a['rows']:
            row.pop('Checklist__r_ChecklistCode__c', None)
            if row['ChecklistCode__c'] is None:
                row['Checklist__r.ChecklistCode__c'] = None

    # ------------------------------------------------------------ 측정기·교정(S12 포함)
    def gauges(self):
        o, r = self.out, rng('sf-gauge', self.seed)
        f_g = o.file('QMS_Gauge__c', 'GaugeNo__c', {'GaugeType__r.ExternalKey__c': R_CODE, 'Plant__r.PlantCode__c': R_PLANT, 'Department__r.DeptCode__c': R_DEPT,
                                                     'Line__r.ExternalKey__c': R_LINE, 'Custodian__r.EmployeeNo__c': R_EMP, 'Item__r.ItemNo__c': R_ITEM})
        f_c = o.file('QMS_Calibration__c', 'RecordNo__c', {'Gauge__r.GaugeNo__c': ('QMS_Gauge__c', 'GaugeNo__c'), 'PerformedBy__r.EmployeeNo__c': R_EMP})
        f_i = o.file('QMS_GaugeImpactAnalysis__c', 'RecordNo__c', {'Gauge__r.GaugeNo__c': ('QMS_Gauge__c', 'GaugeNo__c'),
                                                                    'Calibration__r.RecordNo__c': ('QMS_Calibration__c', 'RecordNo__c'), 'Plant__r.PlantCode__c': R_PLANT})
        self.add_cr('QMS-06-GAU-001', "측정기 RecordNo 패턴 GA-{PLANT}-{SEQ:6}과 GaugeNo(GA-KR01-0123)가 같은 접두라 혼동 — RecordNo 접두를 'GAU-'로 바꾸는 안", '데모는 WI 패턴 그대로 GA-KR01-000001 형식')
        self.add_cr('CMN-00-MDM-007', 'GAUGE_TYPE에 DIAL_GAUGE·HARDNESS_TESTER·MOISTURE_ANALYZER·MICROSCOPE 추가(분석실 장비)', '데모 코드로 추가')
        dept = {'KR01': 'D1150', 'KR02': 'D1150', 'CN01': 'D4100', 'US01': 'D5100', 'PL01': 'D6100'}
        cust = {'KR01': 'E1151', 'KR02': 'E1151', 'CN01': 'E2102', 'US01': 'E3102', 'PL01': 'E4102'}
        cat_of = {'MICROMETER': 'GENERAL', 'CALIPER': 'GENERAL', 'HEIGHT_GAUGE': 'GENERAL', 'DIAL_GAUGE': 'GENERAL', 'PIN_GAUGE': 'GENERAL',
                  'AIMING_TESTER': 'TEST_EQUIPMENT', 'LEAK_TESTER': 'TEST_EQUIPMENT', 'VISION': 'TEST_EQUIPMENT', 'CHECKING_FIXTURE': 'FIXTURE',
                  'CMM': 'CMM', 'SPECTROPHOTOMETER': 'LAB_INSTRUMENT', 'XRAY': 'LAB_INSTRUMENT', 'FTIR': 'LAB_INSTRUMENT', 'DSC': 'LAB_INSTRUMENT',
                  'HARDNESS_TESTER': 'LAB_INSTRUMENT', 'MOISTURE_ANALYZER': 'LAB_INSTRUMENT', 'MICROSCOPE': 'LAB_INSTRUMENT'}
        rng_of = {'MICROMETER': (0, 25, 0.001), 'CALIPER': (0, 150, 0.01), 'HEIGHT_GAUGE': (0, 300, 0.01), 'DIAL_GAUGE': (0, 10, 0.001),
                  'PIN_GAUGE': (0.5, 10, 0.001), 'CMM': (0, 1000, 0.0005)}
        gl = [dict(g, line=None) for g in self.m['gauges']]
        extra = [('GA-KR01-0511', '디지털 마이크로미터 0-25mm(수입검사)', 'MICROMETER', 'KR01', 'KR01 수입검사실', 12, '2026-04-08'),
                 ('GA-KR01-0512', '평면도 측정 정반·다이얼 게이지', 'DIAL_GAUGE', 'KR01', 'KR01 수입검사실', 12, '2026-02-17'),
                 ('GA-KR01-0720', 'X-ray 검사기(솔더 보이드)', 'XRAY', 'KR01', '분석실', 12, '2026-03-24'),
                 ('GA-KR01-0721', '단면 연마·광학 현미경', 'MICROSCOPE', 'KR01', '분석실', 12, '2026-01-20'),
                 ('GA-KR01-0722', 'FT-IR 분광기', 'FTIR', 'KR01', '분석실', 12, '2026-05-12'),
                 ('GA-KR01-0723', 'DSC 열분석기', 'DSC', 'KR01', '분석실', 12, '2026-06-09'),
                 ('GA-KR01-0724', '연필 경도 시험기', 'HARDNESS_TESTER', 'KR01', '분석실', 12, '2026-07-14'),
                 ('GA-KR01-0725', '레진 수분 측정기', 'MOISTURE_ANALYZER', 'KR01', '분석실', 6, '2026-09-08'),
                 ('GA-KR01-0726', 'SEM(주사전자현미경)', 'MICROSCOPE', 'KR01', '분석실', 12, '2026-04-21')]
        for no, name, typ, plant, loc, months, last in extra:
            gl.append({'no': no, 'name': name, 'type': typ, 'plant': plant, 'location': loc, 'resolution': rng_of.get(typ, (0, 0, None))[2],
                       'calMonths': months, 'lastCal': last, 'status': 'ACTIVE', 'line': None})
        fillers = [('KR01', 'CALIPER', '캘리퍼스 0-150mm', 'L01'), ('KR01', 'PIN_GAUGE', '핀 게이지 세트', 'L01'), ('KR01', 'CHECKING_FIXTURE', 'BE1 LH 검사구', 'L01'),
                   ('KR01', 'CHECKING_FIXTURE', 'BE1 RH 검사구', 'L01'), ('KR01', 'LEAK_TESTER', '기밀 시험기 #2', 'L05'), ('KR01', 'AIMING_TESTER', '광축 측정기(HE1)', 'L05'),
                   ('KR01', 'VISION', '렌즈 외관 비전', 'L02'), ('KR01', 'MICROMETER', '디지털 마이크로미터 0-25mm(L02)', 'L02'), ('KR01', 'CMM', '3차원 측정기', None),
                   ('KR01', 'SPECTROPHOTOMETER', '코팅 두께 분광 측정기', 'L03'), ('KR01', 'CHECKING_FIXTURE', 'HE1 LH 검사구', 'L05'), ('KR01', 'CALIPER', '캘리퍼스 0-200mm', 'L05'),
                   ('KR01', 'HEIGHT_GAUGE', '하이트 게이지 0-600mm', None), ('KR01', 'DIAL_GAUGE', '다이얼 게이지(금형)', 'L02'), ('KR02', 'CALIPER', '캘리퍼스 0-150mm', 'L01'),
                   ('KR02', 'AIMING_TESTER', '광축 측정기', 'L01'), ('KR02', 'LEAK_TESTER', '기밀 시험기', 'L01'), ('KR02', 'CHECKING_FIXTURE', 'KE1 LH 검사구', 'L01')]
        for pl in ('CN01', 'US01', 'PL01'):
            fillers += [(pl, 'CALIPER', '캘리퍼스 0-150mm', 'L01'), (pl, 'MICROMETER', '디지털 마이크로미터 0-25mm', None), (pl, 'LEAK_TESTER', '기밀 시험기', 'L01'),
                        (pl, 'CHECKING_FIXTURE', '헤드램프 검사구', 'L01'), (pl, 'PIN_GAUGE', '핀 게이지 세트', None), (pl, 'HEIGHT_GAUGE', '하이트 게이지 0-300mm', None),
                        (pl, 'VISION', 'EOL 외관 비전', 'L01'), (pl, 'CMM', '3차원 측정기', None)]
        lines = {(ln['plant'], ln['line']) for ln in self.m['lines']}
        seqs = {}
        for plant, typ, name, line in fillers:
            if len(gl) >= 60:
                break
            seqs[plant] = seqs.get(plant, 800) + 1
            months = 6 if typ in ('AIMING_TESTER', 'LEAK_TESTER', 'VISION') else 12
            last = self.today - dt.timedelta(days=r.randint(20, months * 30 - 20))
            gl.append({'no': f'GA-{plant}-{seqs[plant]:04d}', 'name': name, 'type': typ, 'plant': plant, 'location': f'{plant} {line or "품질 측정실"}',
                       'resolution': rng_of.get(typ, (0, 0, None))[2], 'calMonths': months, 'lastCal': last.isoformat(), 'status': 'ACTIVE',
                       'line': line if (plant, line) in lines else None})
        assert len(gl) == 60, len(gl)
        fixtures_item = {'BE1 LH 검사구': '63117-BE1L', 'BE1 RH 검사구': '63117-BE1R', 'HE1 LH 검사구': '92101-HE1L', 'KE1 LH 검사구': '92101-KE1L',
                         '헤드램프 검사구': '63117-BE1L'}
        cals = []
        self.gauge_list = gl
        for g in sorted(gl, key=lambda x: (x['plant'], x['no'])):
            plant, typ = g['plant'], g['type']
            cat = cat_of[typ]
            rmin, rmax, res = rng_of.get(typ, (None, None, None))
            ext_cal = cat in ('LAB_INSTRUMENT', 'CMM', 'TEST_EQUIPMENT') and typ != 'VISION'
            last = self.D(g['lastCal'])
            s12 = g['no'] == 'GA-KR01-0456'
            if s12:
                last_ok, fail_d = self.D('2025-11-20'), self.D('2026-11-20')
            months = g['calMonths']
            nxt = last_ok if s12 else last
            next_due = (nxt + dt.timedelta(days=round(months * 30.44)))
            status = g['status']
            susp = g.get('suspendReason')
            if s12:
                status, susp = 'SUSPENDED', 'CAL_FAILED'
            item = fixtures_item.get(g['name']) if cat == 'FIXTURE' else None
            if cat == 'FIXTURE' and item not in self.items:
                item = '63117-BE1L'
            o.add(f_g, {'RecordNo__c': self.seq('GA-{PLANT}', plant, None, 6).replace(f'GA-{plant}--', f'GA-{plant}-'), 'GaugeNo__c': g['no'], 'Name': g['name'],
                        'GaugeType__r.ExternalKey__c': self.ck('GAUGE_TYPE', typ), 'Category__c': cat, 'Manufacturer__c': '데모계측(가상)',
                        'Model__c': f'DM-{typ[:3]}-{r.randint(100, 999)}', 'SerialNo__c': f'SN{r.randint(100000, 999999)}',
                        'RangeMin__c': rmin, 'RangeMax__c': rmax, 'Unit__c': 'mm' if rmin is not None else None, 'Resolution__c': g.get('resolution') if cat == 'GENERAL' else None,
                        'AccuracySpec__c': f"±{(res or 0.01) * 2:g}mm" if rmin is not None else '제조사 사양(데모)', 'Plant__r.PlantCode__c': plant,
                        'Department__r.DeptCode__c': 'D1030' if g['location'] == '분석실' else dept[plant], 'Line__r.ExternalKey__c': f"{plant}-{g['line']}" if g.get('line') else None,
                        'Location__c': g['location'], 'Custodian__r.EmployeeNo__c': 'E1161' if g['location'] == '분석실' else cust[plant], 'Ownership__c': 'SL',
                        'Item__r.ItemNo__c': item, 'CalibrationType__c': 'EXTERNAL' if ext_cal else 'INTERNAL', 'CalIntervalMonths__c': months,
                        'LastCalDate__c': iso(last_ok if s12 else last), 'NextCalDueDate__c': iso(next_due), 'SuspendReason__c': susp,
                        'MsaRequired__c': str(cat in ('GENERAL', 'TEST_EQUIPMENT', 'FIXTURE')).lower(), 'MasterSource__c': 'QMS', 'Status__c': status})
            # 교정 이력(2024-12 이후)
            d = last_ok if s12 else last
            hist = []
            while d >= self.D('2024-12-01'):
                hist.append(d)
                d = d - dt.timedelta(days=round(months * 30.44))
            for hd in hist:
                cals.append((hd, g, 'PASS', ext_cal, rmin))
            if s12:
                cals.append((fail_d, g, 'FAIL', ext_cal, rmin))
            elif next_due <= self.D('2026-12-31') and status == 'ACTIVE':
                cals.append((next_due, g, 'PLANNED', ext_cal, rmin))
        self.s12 = {}
        for hd, g, res_, ext_cal, rmin in sorted(cals, key=lambda x: (x[0], x[1]['no'])):
            plant = g['plant']
            no = self.seq('CAL-{PLANT}-{YYYY}', plant, hd.year, 6)
            done = res_ != 'PLANNED'
            err = 0.05 if res_ == 'FAIL' else (round(r.uniform(0.0, 0.004), 4) if rmin is not None else None)
            tol = 0.30 if g['no'] == 'GA-KR01-0456' else 0.02
            internal = not ext_cal
            o.add(f_c, {'RecordNo__c': no, 'Gauge__r.GaugeNo__c': g['no'], 'CalType__c': 'EXTERNAL' if ext_cal else 'INTERNAL', 'Reason__c': 'PERIODIC',
                        'DueDate__c': iso(hd), 'Vendor__c': '공인 교정기관(가상)' if ext_cal else None, 'VendorAccredited__c': str(ext_cal).lower() if ext_cal else None,
                        'AccreditationNo__c': 'KOLAS-DEMO-0001(가상)' if ext_cal else None,
                        'SentDate__c': iso(hd - dt.timedelta(days=5)) if ext_cal and done else None, 'ReturnedDate__c': iso(hd) if ext_cal and done else None,
                        'PerformedDate__c': iso(hd) if done else None, 'PerformedBy__r.EmployeeNo__c': 'E1151' if internal and done and plant in ('KR01', 'KR02') else (
                            {'CN01': 'E2102', 'US01': 'E3102', 'PL01': 'E4102'}.get(plant) if internal and done else None),
                        'Procedure__c': 'SL-CAL-PR-01 측정기 교정 절차(데모)' if internal else None, 'ReferenceStandard__c': '게이지 블록 세트(교정 성적서 KOLAS, 가상)' if internal else None,
                        'Environment__c': '20±1℃, 50±10%RH' if done else None,
                        'PointsJson__c': j([{'nominal': p, 'asFound': round(p + (err if res_ == 'FAIL' else r.uniform(-0.003, 0.003)), 4), 'asLeft': None if res_ == 'FAIL' else round(p + r.uniform(-0.002, 0.002), 4),
                                             'tolerance': 0.02} for p in ((50, 150, 250) if g['type'] == 'HEIGHT_GAUGE' else (5, 10, 20))]) if internal and done else None,
                        'AsFoundResult__c': ('OUT_OF_TOL' if res_ == 'FAIL' else 'IN_TOL') if done else None,
                        'AsLeftResult__c': ('NOT_ADJUSTED' if res_ == 'FAIL' else 'IN_TOL') if done else None,
                        'MaxErrorAsFound__c': err if done else None, 'MaxErrorPctOfTol__c': round(err / tol * 100, 1) if done and err is not None else None,
                        'CertificateNo__c': f'CERT-{no}' if done else None, 'NextDueDate__c': iso(hd + dt.timedelta(days=round(g['calMonths'] * 30.44))) if res_ == 'PASS' else None,
                        'Status__c': 'DONE' if done else 'PLANNED', 'Result__c': res_ if done else None})
            if g['no'] == 'GA-KR01-0456':
                self.s12['cal_fail' if res_ == 'FAIL' else 'cal_last_pass'] = no
        gia = self.seq('GIA-{PLANT}-{YYYY}', 'KR01', 2026, 4)
        self.s12['impact'] = gia
        o.add(f_i, {'RecordNo__c': gia, 'Gauge__r.GaugeNo__c': 'GA-KR01-0456', 'Calibration__r.RecordNo__c': self.s12['cal_fail'], 'Plant__r.PlantCode__c': 'KR01',
                    'PeriodFrom__c': '2025-11-20', 'PeriodTo__c': '2026-11-20', 'MaxErrorAsFound__c': 0.05, 'MaxErrorPctOfTol__c': 16.7,
                    'UncoveredSources__c': '2025-11-20~2026-05-31 수입검사 로트는 데모 데이터 기간 밖', 'Status__c': 'OPEN'})
        self.keys.update({'S12-GAUGE': 'GA-KR01-0456', 'S12-CAL-FAIL': self.s12['cal_fail'], 'S12-CAL-LAST-PASS': self.s12['cal_last_pass'], 'S12-IMPACT': gia})

    # ------------------------------------------------------------ 교육·자격·인증·한도견본·분석 의뢰 이력
    def people_history(self):
        o, r = self.out, rng('sf-people', self.seed)
        f_s = o.file('QMS_TrainingSession__c', 'RecordNo__c', {'Course__r.CourseCode__c': ('QMS_TrainingCourse__c', 'CourseCode__c'), 'Plant__r.PlantCode__c': R_PLANT,
                                                               'Instructor__r.EmployeeNo__c': R_EMP})
        f_a = o.file('QMS_TrainingAttendance__c', 'ExternalKey__c', {'Course__r.CourseCode__c': ('QMS_TrainingCourse__c', 'CourseCode__c'),
                                                                     'Session__r.RecordNo__c': ('QMS_TrainingSession__c', 'RecordNo__c'),
                                                                     'Employee__r.EmployeeNo__c': R_EMP, 'Plant__r.PlantCode__c': R_PLANT})
        courses = {c[0]: c for c in C.COURSES}
        kr = [e['no'] for e in self.m['employees'] if e['plant'] == 'KR01']
        aud = {'TRN-IQC-01': ['E1104', 'E1105', 'E1114', 'E1303'], 'TRN-EOL-01': ['E1105', 'E1301', 'E1302'], 'TRN-VIS-01': ['E1104', 'E1105', 'E1301', 'E1302', 'E1303'],
               'TRN-SPC-01': ['E1102', 'E1103', 'E1141', 'E1121'], 'TRN-MSA-01': ['E1102', 'E1103', 'E1105', 'E1151'], 'TRN-8D-01': ['E1102', 'E1103', 'E1112', 'E1113', 'E1202'],
               'TRN-FMEA-01': ['E1103', 'E1141', 'E1181', 'E1182'], 'TRN-IATF-01': ['E1002', 'E1003', 'E1112'], 'TRN-VDA-01': ['E1002', 'E1101', 'E1112', 'E1102'],
               'TRN-SUP-01': ['E1111', 'E1112', 'E1113'], 'TRN-CAL-01': ['E1151', 'E1105'], 'TRN-ESD-01': ['E1121', 'E1301', 'E1302', 'E1103']}
        self.attend = {}
        order = list(courses)
        for k in range(24):
            code = order[k % len(order)]
            d = self.D('2024-12-10') + dt.timedelta(days=k * 30 + r.randint(0, 6))
            if d >= self.today:
                break
            no = self.seq('TS-{PLANT}-{YYYY}', 'KR01', d.year, 4)
            hours = courses[code][4]
            ext = courses[code][3] in ('EXTERNAL_COURSE', 'ELEARNING_EXTERNAL')
            o.add(f_s, {'RecordNo__c': no, 'Course__r.CourseCode__c': code, 'CourseVersion__c': 1, 'Plant__r.PlantCode__c': 'KR01', 'PlannedDate__c': iso(d),
                        'StartAt__c': ts(d, 9), 'EndAt__c': ts(d, 9 + min(int(hours), 8)), 'Location__c': 'KR01 교육장' if not ext else '외부 교육기관(가상)',
                        'Language__c': 'ko', 'Instructor__r.EmployeeNo__c': None if ext else {'TRN-CAL-01': 'E1151', 'TRN-VDA-01': 'E1002'}.get(code, 'E1101'),
                        'ExternalInstructor__c': '외부 강사(가상)' if ext else None, 'Capacity__c': 20, 'Status__c': 'COMPLETED'})
            for emp in aud[code]:
                score = r.choice([72, 78, 84, 88, 92, 96, 64]) if courses[code][3] != 'ELEARNING_EXTERNAL' else None
                passed = score is None or score >= 70
                key = f'{emp}-{code}-{no}'
                o.add(f_a, {'ExternalKey__c': key, 'Course__r.CourseCode__c': code, 'CourseVersion__c': 1, 'Session__r.RecordNo__c': no,
                            'Employee__r.EmployeeNo__c': emp, 'Plant__r.PlantCode__c': 'KR01', 'Source__c': 'SESSION', 'AttendedHours__c': hours,
                            'CheckInAt__c': ts(d, 8, 55), 'Score__c': score, 'CompletedDate__c': iso(d) if passed else None,
                            'RefreshDueDate__c': iso(d + dt.timedelta(days=730)) if passed else None, 'Status__c': 'PASSED' if passed else 'FAILED'})
                if passed:
                    self.attend.setdefault(emp, []).append((code, d))
        # 자격 60
        f_q = o.file('QMS_Qualification__c', 'RecordNo__c', {'Employee__r.EmployeeNo__c': R_EMP, 'QualificationType__r.TypeCode__c': ('QMS_QualificationType__c', 'TypeCode__c'),
                                                             'Plant__r.PlantCode__c': R_PLANT})
        plan = [('INSPECTOR_IQC', ['E1104', 'E1105', 'E1114', 'E1303', 'E2102', 'E3102', 'E4102']), ('INSPECTOR_EOL', ['E1105', 'E1301', 'E1302', 'E2102', 'E3102', 'E4102', 'E1104', 'E1114']),
                ('INSPECTOR_VISUAL', ['E1104', 'E1105', 'E1301', 'E1302', 'E1303', 'E1114', 'E2102', 'E4102']),
                ('AUDITOR_SYSTEM', ['E1002', 'E1003', 'E1101', 'E2101', 'E3101', 'E4101']), ('AUDITOR_PROCESS', ['E1002', 'E1101', 'E1102', 'E1112', 'E2101', 'E4101']),
                ('AUDITOR_PRODUCT', ['E1102', 'E1103', 'E1105', 'E2102', 'E1114', 'E3102', 'E4102']), ('AUDITOR_VDA63', ['E1002', 'E1112', 'E1101']),
                ('AUDITOR_SUPPLIER', ['E1111', 'E1112', 'E1113', 'E2102', 'E3102', 'E4102']), ('CALIBRATION_TECH', ['E1151', 'E1105', 'E2102', 'E3102', 'E4102']),
                ('LAB_ANALYST', ['E1161', 'E1162', 'E1171', 'E1172', 'E1162'])]
        qtypes = {q[0]: q for q in C.QUAL_TYPES}
        n = 0
        seen = set()
        self.quals = []
        for tcode, emps in plan:
            for emp in emps:
                if (tcode, emp) in seen or n >= 60:
                    continue
                seen.add((tcode, emp))
                n += 1
                e = self.emps[emp]
                plant = e['plant'] or 'KR01'
                months = qtypes[tcode][4]
                vf = self.D('2024-03-01') + dt.timedelta(days=(n * 23) % 900)
                vt = vf + dt.timedelta(days=round(months * 30.44)) if months else None
                status = 'QUALIFIED'
                if vt and vt < self.today:
                    status = 'EXPIRED' if n % 2 else 'QUALIFIED'
                    if status == 'QUALIFIED':
                        vf = vt - dt.timedelta(days=30)
                        vt = vf + dt.timedelta(days=round(months * 30.44))
                no = self.seq('QF-{PLANT}-{YYYY}', plant, vf.year, 5)
                cat = qtypes[tcode][3]
                o.add(f_q, {'RecordNo__c': no, 'Employee__r.EmployeeNo__c': emp, 'QualificationType__r.TypeCode__c': tcode, 'Plant__r.PlantCode__c': plant,
                            'ScopePartCategories__c': 'LENS;HOUSING;LED_MODULE;CONNECTOR' if tcode == 'INSPECTOR_IQC' else None,
                            'ScopeAuditStandards__c': {'AUDITOR_VDA63': 'VDA63', 'AUDITOR_SYSTEM': 'IATF16949'}.get(tcode) if cat == 'AUDITOR' else None,
                            'ScopeAnalysisCategories__c': 'STRUCTURE;COMPOSITION;THERMAL;SURFACE;HARDNESS' if tcode == 'LAB_ANALYST' else None,
                            'ValidFrom__c': iso(vf), 'ValidTo__c': iso(vt), 'ExperienceStartDate__c': iso(vf - dt.timedelta(days=400)), 'OjtHours__c': 16 if cat == 'INSPECTOR' else None,
                            'ActivityCount__c': r.randint(2, 12) if cat == 'AUDITOR' else None, 'LastActivityDate__c': iso(self.today - dt.timedelta(days=r.randint(15, 200))) if cat == 'AUDITOR' else None,
                            'VisionTestDate__c': iso(vf - dt.timedelta(days=10)) if cat == 'INSPECTOR' else None, 'VisionTestResult__c': 'PASS' if cat == 'INSPECTOR' else None,
                            'ExternalCertNo__c': f'VDA-DEMO-{n:04d}(가상)' if tcode == 'AUDITOR_VDA63' else None, 'ExternalValidTo__c': iso(vt) if tcode == 'AUDITOR_VDA63' else None,
                            'RequirementsMet__c': 'true', 'Source__c': 'NORMAL', 'Status__c': status})
                self.quals.append({'recordNo': no, 'employee': emp, 'type': tcode, 'plant': plant, 'validTo': iso(vt), 'status': status})
        # 인증 6
        f_ct = o.file('QMS_Certification__c', 'RecordNo__c', {'Plant__r.PlantCode__c': R_PLANT})
        for plant, std_, issue in [('KR01', 'IATF16949', '2024-07-01'), ('KR02', 'IATF16949', '2025-03-15'), ('CN01', 'IATF16949', '2024-10-20'),
                                   ('US01', 'IATF16949', '2025-06-10'), ('PL01', 'IATF16949', '2024-11-05'), ('KR01', 'ISO14001', '2025-01-20')]:
            d = self.D(issue)
            no = self.seq('CRT-{PLANT}', plant, None, 4).replace(f'CRT-{plant}--', f'CRT-{plant}-')
            o.add(f_ct, {'RecordNo__c': no, 'Plant__r.PlantCode__c': plant, 'Standard__c': std_, 'CertBody__c': '가상 인증기관(데모)',
                         'CertNo__c': f'{std_}-{plant}-DEMO-{r.randint(1000, 9999)}', 'IatfCertId__c': f'0{r.randint(100000, 999999)}' if std_ == 'IATF16949' else None,
                         'Scope__c': '자동차용 램프(헤드램프·리어램프) 설계 및 제조(데모)', 'InitialCertDate__c': iso(d - dt.timedelta(days=365 * 3)), 'IssueDate__c': iso(d),
                         'ValidFrom__c': iso(d), 'ValidTo__c': iso(d + dt.timedelta(days=365 * 3 - 1)), 'SurveillanceIntervalMonths__c': 12,
                         'Status__c': 'ACTIVE'})
        # 협력사 인증서 8
        f_sc = o.file('QMS_SupplierCertificate__c', 'ExternalKey__c', {'Supplier__r.SapVendorNo__c': R_SUPP})
        self.add_cr('QMS-03-SPP-003', 'QMS_SupplierCertificate__c에 ExternalKey__c 추가', 'SC-{VendorNo}-{CertType}')
        for s in self.m['suppliers']:
            ctype = 'IATF16949' if s['iatf'] else 'ISO9001'
            vt = self.D(s['iatfExpiry']) if s.get('iatfExpiry') else self.D('2027-06-30')
            o.add(f_sc, {'ExternalKey__c': f"SC-{s['vendorNo']}-{ctype}", 'Supplier__r.SapVendorNo__c': s['vendorNo'], 'CertType__c': ctype,
                         'CertNo__c': f"{ctype}-{s['vendorNo']}-DEMO", 'CertBody__c': '가상 인증기관(데모)', 'ValidFrom__c': iso(vt - dt.timedelta(days=365 * 3 - 1)),
                         'ValidTo__c': iso(vt), 'SiteScope__c': '본사 공장(가상)', 'Status__c': 'VERIFIED' if vt >= self.today else 'EXPIRED'})
        # 한도견본 15
        f_ls = o.file('QMS_LimitSample__c', 'RecordNo__c', {'Item__r.ItemNo__c': R_ITEM, 'Characteristic__r.ExternalKey__c': R_CHAR, 'Plant__r.PlantCode__c': R_PLANT,
                                                           'DefectCode__r.ExternalKey__c': R_CODE, 'Customer__r.OemCode__c': R_CUST, 'Supplier__r.SapVendorNo__c': R_SUPP})
        vis = [(c['item'], c['charNo']) for c in self.m['characteristics'] if c['type'] == 'VISUAL']
        defs = ['LENS_SCRATCH', 'INNER_FOREIGN', 'BEZEL_SCRATCH', 'LENS_HAZE', 'COATING_CRACK']
        zones = ['A', 'B', 'C']
        self.limit_samples = []
        for k in range(15):
            item, cn = vis[k % len(vis)]
            defect = defs[k % len(defs)]
            zone = zones[(k // len(vis)) % 3]
            d = self.D('2025-01-15') + dt.timedelta(days=k * 41)
            no = self.seq('LS-{PLANT}-{YYYY}', 'KR01', d.year, 5)
            cust_ = self.items[item].get('customer')
            o.add(f_ls, {'RecordNo__c': no, 'Name': f"{self.items[item]['name']} {self.cpath('DEFECT_TYPE', defect).split(' > ')[-1]} {zone}영역",
                         'Item__r.ItemNo__c': item, 'Characteristic__r.ExternalKey__c': self.char_key(item, cn), 'Plant__r.PlantCode__c': 'KR01',
                         'DefectCode__r.ExternalKey__c': self.ck('DEFECT_TYPE', defect), 'DefectPath__c': self.cpath('DEFECT_TYPE', defect),
                         'Customer__r.OemCode__c': cust_ if zone == 'A' else None, 'Version__c': 1, 'InspectionZone__c': zone,
                         'AcceptCriteria__c': {'A': '길이 0.3mm 이하·1개 이하 허용', 'B': '길이 0.5mm 이하·2개 이하 허용', 'C': '기능 영향 없으면 허용'}[zone],
                         'MaxSizeMm__c': {'A': 0.3, 'B': 0.5, 'C': 1.0}[zone], 'MaxCount__c': {'A': 1, 'B': 2, 'C': 5}[zone], 'LightingLux__c': '1000±200',
                         'LightSource__c': 'D65 표준광', 'ViewDistanceMm__c': 500, 'ViewTimeSec__c': 10, 'ViewAngle__c': '정면 ±30°',
                         'CustomerApprovalRequired__c': str(zone == 'A' and bool(cust_)).lower(), 'CustomerApprovalDate__c': iso(d + dt.timedelta(days=10)) if zone == 'A' and cust_ else None,
                         'CustomerApproverName__c': '고객 품질 담당(가상)' if zone == 'A' and cust_ else None, 'ValidMonths__c': 24, 'CheckIntervalDays__c': 90,
                         'EffectiveFrom__c': iso(d + dt.timedelta(days=12)), 'NeedsReview__c': 'false', 'Status__c': 'ACTIVE'})
            self.limit_samples.append(no)
        # 분석 의뢰 이력 24(S2-LAB 포함 25)
        purposes = [('NCR', 'QMS_NCR__c'), ('CLAIM', 'QMS_Claim__c'), ('DEVELOPMENT', None), ('CHANGE_4M', 'QMS_FourMChange__c')]
        ncrs = [x for x in self.f_ncr['rows'] if x.get('ClosedAt__c')]
        claims = [x for x in self.f_claim['rows'] if x.get('ClosedAt__c')]
        fm = [x for x in self.f_4m['rows'] if x['Status__c'] == 'CLOSED']
        item_for = {'LENS_HAZE': ('LAB-HAZE-001', 'LAB-MOIST-001'), 'COATING_CRACK': ('LAB-HARD-001', 'LAB-SEM-001'), 'DRL_FLICKER': ('LAB-XRAY-001', 'LAB-XSEC-001'),
                    'LED_OFF': ('LAB-XRAY-001',), 'INNER_FOREIGN': ('LAB-FTIR-001',), 'INNER_FOG': ('LAB-FTIR-001',), 'SOLDER_VOID': ('LAB-XRAY-001',)}
        for k in range(24):
            purpose, sobj = purposes[k % 4]
            if purpose == 'NCR':
                src = ncrs[(k * 7) % len(ncrs)]
            elif purpose == 'CLAIM':
                src = claims[(k * 5) % len(claims)]
            elif purpose == 'CHANGE_4M':
                src = fm[k % len(fm)]
            else:
                src = None
            dpath = src.get('DefectTypePath__c', '') if src else ''
            leaf = next((dk for dk in item_for if self.cpath('DEFECT_TYPE', dk) == dpath), None) if src else None
            codes = item_for.get(leaf) or (('LAB-DSC-001',) if purpose == 'CHANGE_4M' else ('LAB-FTIR-001',))
            d = self.D(src['DetectedAt__c'][:10] if src and 'DetectedAt__c' in src else (src['ReceivedAt__c'][:10] if src and 'ReceivedAt__c' in src else '2025-01-01')) \
                if src and purpose != 'CHANGE_4M' else self.D('2025-02-10') + dt.timedelta(days=k * 27)
            d = d + dt.timedelta(days=3)
            if d >= self.today - dt.timedelta(days=10):
                d = self.today - dt.timedelta(days=20 + k)
            no = self.seq('LAB-{PLANT}-{YYYY}', 'KR01', d.year, 5)
            ok = purpose in ('DEVELOPMENT', 'CHANGE_4M')
            item = src['Item__r.ItemNo__c'] if src and 'Item__r.ItemNo__c' in src else '63117-BE1L'
            self.lab_request(no, purpose, (sobj, src['RecordNo__c']) if src else None, src.get('Plant__r.PlantCode__c', 'KR01') if src else 'KR01',
                             'E1102' if purpose != 'DEVELOPMENT' else 'E1182', 'D1100' if purpose != 'DEVELOPMENT' else 'D2010',
                             'PART' if item.startswith('P-') else ('SFG' if item.startswith('S-') else ('RAW' if item.startswith('R-') else 'PRODUCT')),
                             item, None, 3, f"{self.items[item]['name']} 분석 시료 3EA", d, d + dt.timedelta(days=5),
                             [(c, None if C.LAB_ITEMS[[x[0] for x in C.LAB_ITEMS].index(c)][6] != 'VALUE' else round(r.uniform(5, 20), 2), 'OK' if ok else 'NG') for c in codes],
                             'CONFORM' if ok else 'NONCONFORM', '분석 결과 요약(데모): ' + ('기준 충족' if ok else '불량 원인과 일치하는 이상 확인'))

    # ------------------------------------------------------------ 결재·To-Do
    def workflow(self):
        o = self.out
        f_ar = o.file('CMN_ApprovalRequest__c', 'RecordNo__c', {'Plant__r.PlantCode__c': R_PLANT})
        f_as = o.file('CMN_ApprovalStep__c', 'ExternalKey__c', {'Request__r.RecordNo__c': ('CMN_ApprovalRequest__c', 'RecordNo__c'),
                                                                'Approver__r.EmployeeNo__c': R_USER, 'ActedBy__r.EmployeeNo__c': R_USER})
        f_td = o.file('CMN_Todo__c', 'ExternalKey__c', {'Assignee__r.EmployeeNo__c': R_USER, 'DelegatedFrom__r.EmployeeNo__c': R_USER, 'Plant__r.PlantCode__c': R_PLANT})
        self.add_cr('CMN-00-APV-001', 'CMN_ApprovalStep__c에 ExternalKey__c 추가(결재 요청 RecordNo + 단계 번호)', '{APV 번호}-S{StepNo}')
        self.todos = []

        def todo(stype, sobj, skey_field, skey, tobj, tkey_field, tkey, rec_no, assignee, cat, title, due, plant='KR01', delegated_from=None):
            src_tok = ref(sobj, skey_field, skey)
            row = {'ExternalKey__c': f'{stype}/{src_tok}/{user(assignee)}', 'Assignee__r.EmployeeNo__c': assignee, 'Category__c': cat, 'System__c': 'QMS',
                   'SourceType__c': stype, 'SourceRecordId__c': src_tok, 'SourceObject__c': sobj, 'TargetRecordId__c': ref(tobj, tkey_field, tkey),
                   'RecordNo__c': rec_no, 'TitleLabel__c': f"{stype.split('_')[0]}_Todo_{stype}", 'TitleParams__c': j([rec_no]), 'TitleFallback__c': title,
                   'DueDate__c': iso(due) if due else None, 'Status__c': 'OPEN', 'IsDelegated__c': str(bool(delegated_from)).lower(),
                   'DelegatedFrom__r.EmployeeNo__c': delegated_from, 'Plant__r.PlantCode__c': plant}
            o.add(f_td, row)
            self.todos.append({'assignee': assignee, 'category': cat, 'sourceType': stype, 'recordNo': rec_no, 'title': title, 'due': iso(due) if due else None,
                               'delegatedFrom': delegated_from})

        def approval(type_code, tobj, tno, title, plant, status, steps, submitted, completed=None, summary=None):
            d = submitted
            no = self.seq('APV-{YYYY}', None, d.year, 7).replace('APV--', 'APV-')
            cur = next((s[0] for s in steps if s[3] == 'PENDING'), None)
            o.add(f_ar, {'RecordNo__c': no, 'TypeCode__c': type_code, 'TargetRecordId__c': ref(tobj, 'RecordNo__c', tno), 'TargetObject__c': tobj,
                         'TargetRecordNo__c': tno, 'Title__c': title, 'Status__c': status, 'CurrentStepNo__c': cur, 'Plant__r.PlantCode__c': plant,
                         'Version__c': 1, 'Summary__c': summary, 'SubmittedAt__c': ts(d, 10), 'CompletedAt__c': ts(completed, 16) if completed else None})
            for sno, stype, emp, st, acted, role in steps:
                sk = f'{no}-S{sno}'
                o.add(f_as, {'ExternalKey__c': sk, 'Request__r.RecordNo__c': no, 'StepNo__c': sno, 'StepType__c': stype, 'Approver__r.EmployeeNo__c': emp,
                             'RoleCode__c': role, 'Status__c': st, 'ActedBy__r.EmployeeNo__c': emp if st == 'APPROVED' else None, 'IsDelegated__c': 'false',
                             'Comment__c': '승인(데모)' if st == 'APPROVED' else None, 'ActedAt__c': ts(acted, 15) if acted else None})
                if st == 'PENDING':
                    todo('CMN_APPROVAL', 'CMN_ApprovalStep__c', 'ExternalKey__c', sk, tobj, 'RecordNo__c', tno, tno, emp, 'APPROVAL',
                         f'[결재] {title}', None, plant)
                    if emp == 'E1101':
                        todo('CMN_APPROVAL', 'CMN_ApprovalStep__c', 'ExternalKey__c', sk, tobj, 'RecordNo__c', tno, tno, 'E1102', 'APPROVAL',
                             f'[결재·위임] {title}', None, plant, delegated_from='E1101')
            return no

        D = self.D
        fm, q, pp = self.keys['S3-4M'], self.keys['S3-QUAL'], self.keys['S3-PPAP']
        self.keys['S3-4M-PLAN-APV'] = approval('QMS_4M_APPROVE', 'QMS_FourMChange__c', fm, 'HE1 렌즈 레진 등급 변경 4M 계획 결재', 'KR01', 'APPROVED',
                                               [(1, 'REVIEW', 'E1101', 'APPROVED', D('2026-09-16'), 'QUALITY_MANAGER'), (2, 'AGREE', 'E1121', 'APPROVED', D('2026-09-17'), 'PRODUCTION_MANAGER'),
                                                (3, 'APPROVE', 'E1131', 'APPROVED', D('2026-09-18'), 'PLANT_MANAGER')], D('2026-09-15'), D('2026-09-18'))
        self.keys['S3-4M-APPLY-APV'] = approval('QMS_4M_APPROVE', 'QMS_FourMChange__c', fm, 'HE1 렌즈 레진 등급 변경 4M 적용 결재', 'KR01', 'APPROVED',
                                                [(1, 'REVIEW', 'E1101', 'APPROVED', D('2026-11-18'), 'QUALITY_MANAGER'), (2, 'AGREE', 'E1121', 'APPROVED', D('2026-11-19'), 'PRODUCTION_MANAGER'),
                                                 (3, 'APPROVE', 'E1131', 'APPROVED', D('2026-11-20'), 'PLANT_MANAGER')], D('2026-11-17'), D('2026-11-20'))
        approval('QMS_QUAL_JUDGMENT', 'QMS_QualPlan__c', q, 'HE1 렌즈 레진 변경 인정시험 판정', 'KR01', 'APPROVED',
                 [(1, 'APPROVE', 'E1101', 'APPROVED', D('2026-10-30'), 'QUALITY_MANAGER')], D('2026-10-29'), D('2026-10-30'))
        approval('QMS_PPAP_APPROVE', 'QMS_Ppap__c', pp, 'HE1 렌즈 Re-PPAP 판정(레벨 3)', 'KR01', 'APPROVED',
                 [(1, 'APPROVE', 'E1111', 'APPROVED', D('2026-11-15'), 'SQ_MANAGER')], D('2026-11-13'), D('2026-11-15'))
        self.keys['S0-PPAP-INTERIM-APV'] = approval('QMS_PPAP_APPROVE', 'QMS_Ppap__c', self.keys['S0-PPAP-INTERIM'], '델타코팅 리플렉터 PPAP 잠정 승인 판정', 'KR01',
                                                    'IN_PROGRESS', [(1, 'APPROVE', 'E1111', 'PENDING', None, 'SQ_MANAGER')], D('2026-11-27'),
                                                    summary='증착 두께 Ppk 1.41(목표 1.67) — 잠정 승인 조건: 30로트 데이터 재제출, 유효 2026-12-20')
        con_ncr = self.open_flat[('P-HSG-HE1', '2026-11-23')]
        self.keys['S0-CONCESSION-APV'] = approval('QMS_NCR_CONCESSION', 'QMS_NCR__c', con_ncr, 'HE1 하우징 평면도 초과 로트 특채(선별 사용)', 'KR01', 'IN_PROGRESS',
                                                  [(1, 'AGREE', 'E1121', 'APPROVED', D('2026-11-28'), 'PRODUCTION_MANAGER'), (2, 'APPROVE', 'E1101', 'PENDING', None, 'QUALITY_MANAGER'),
                                                   (3, 'APPROVE', 'E1131', 'WAITING', None, 'PLANT_MANAGER')], D('2026-11-27'),
                                                  summary='평면도 0.31~0.33mm 로트 300EA 중 선별 합격품 사용, 실링 비드 폭 +0.2mm 보정 조건')
        approval('QMS_IQC_SKIP_APPROVE', 'QMS_IqcLevelChange__c', None, '오메가액추에이터 P-ACT-01 무검사 전환', 'KR01', 'APPROVED',
                 [(1, 'APPROVE', 'E1111', 'APPROVED', D('2026-02-26'), 'SQ_MANAGER'), (2, 'APPROVE', 'E1101', 'APPROVED', D('2026-02-27'), 'QUALITY_MANAGER')],
                 D('2026-02-25'), D('2026-02-27'))
        # 무검사 결재 대상은 수준 변경 기록(ExternalKey) — TargetRecordId를 바로잡는다
        lc_key = f"LC-V10007-P-ACT-01-KR01-{D('2026-03-02').strftime('%Y%m%d')}"
        f_ar['rows'][-1].update({'TargetRecordId__c': ref('QMS_IqcLevelChange__c', 'ExternalKey__c', lc_key), 'TargetRecordNo__c': lc_key})
        # 진행 중 8D → 리더 To-Do
        for row in self.f_8d['rows']:
            if row['Status__c'] != 'IN_PROGRESS':
                continue
            no, cur = row['RecordNo__c'], row['CurrentStep__c']
            waiting_supplier = row['RecordTypeDeveloperName'] == 'NCR_SUPPLIER' and cur in ('D5', 'D6')
            todo('QMS_8D_STEP', 'QMS_EightDStep__c', 'ExternalKey__c', f'{no}-{cur}', 'QMS_EightD__c', 'RecordNo__c', no, no, row['Leader__r.EmployeeNo__c'], 'TASK',
                 f"{no} {cur} {'협력사 제출 확인' if waiting_supplier else '작성'}", self.D(row['DueDate__c']), row['Plant__r.PlantCode__c'])
        stb = self.keys['S3-STB']
        todo('QMS_STAB_REPORT', 'QMS_StabilizationPlan__c', 'RecordNo__c', stb, 'QMS_StabilizationPlan__c', 'RecordNo__c', stb, stb, 'E1112', 'TASK',
             f'{stb} 초기안정화 주간 보고 검토(알파광학 HE1 렌즈)', D('2026-12-04'))
        gia = self.keys['S12-IMPACT']
        todo('QMS_GAUGE_IMPACT', 'QMS_GaugeImpactAnalysis__c', 'RecordNo__c', gia, 'QMS_GaugeImpactAnalysis__c', 'RecordNo__c', gia, gia, 'E1151', 'TASK',
             f'{gia} GA-KR01-0456 교정 불합격 영향 분석', D('2026-12-04'))
        coa = self.keys['S9-COA-OOS']
        todo('QMS_COA_REVIEW', 'QMS_SupplierCoa__c', 'RecordNo__c', coa, 'QMS_SupplierCoa__c', 'RecordNo__c', coa, coa, 'E1112', 'TASK',
             f'{coa} 감마LED 성적서 규격 이탈(솔더 보이드 27%) 검토', D('2026-12-02'))
        for tk, title, own, due, st in self.s4_tasks:
            if st == 'OPEN':
                todo('QMS_AUDIT_PREP', 'QMS_CustomerAuditPrepTask__c', 'ExternalKey__c', tk, 'QMS_Audit__c', 'RecordNo__c', self.keys['S4-AUDIT'],
                     self.keys['S4-AUDIT'], own, 'TASK', f'[BMW 심사 준비] {title}', D(due))
        for lot in self.lots:
            if lot['pending'] and lot['plant'] == 'KR01':
                todo('QMS_IQC_LOT', 'QMS_IqcLot__c', 'ExternalKey__c', lot['ext'], 'QMS_IqcLot__c', 'ExternalKey__c', lot['ext'], lot['recordNo'], 'E1104', 'TASK',
                     f"{lot['recordNo']} 수입검사({lot['item']})", D('2026-12-01'))

    # ------------------------------------------------------------ 마무리: 자리표시 치환·정렬·쓰기·점검
    def resolve_placeholders(self):
        first_ext, first_no, fm = self.keys['S3-IQC-FIRST-EXT'], self.keys['S3-IQC-FIRST'], self.keys['S3-4M']
        lot_tok = ref('QMS_IqcLot__c', 'ExternalKey__c', first_ext)
        for f in self.out.files:
            for row in f['rows']:
                for k, v in list(row.items()):
                    if v == '@S3-IQC-FIRST-REF':
                        row[k] = lot_tok
                        if k == 'LinkedRecordId__c':
                            row['LinkedRecordNo__c'] = first_no
                    elif v == '@S3-4M':
                        row[k] = fm
                    elif isinstance(v, str) and v.startswith('@'):
                        raise ValueError(f"치환 안 된 자리표시 {f['obj']}.{k}={v}")

    def order_files(self):
        """값 기준 의존(관계 열·재적재 패스)으로 위상 정렬한다. 생성 순서를 최대한 유지한다."""
        import heapq
        files = self.out.files
        first = {}
        for i, f in enumerate(files):
            if not f['ext']:
                continue
            m = first.setdefault((f['obj'], f['ext']), {})
            for row in f['rows']:
                v = row.get(f['ext'])
                if v not in (None, ''):
                    m.setdefault(str(v), i)
        deps = {i: set() for i in range(len(files))}
        for i, f in enumerate(files):
            for col, (tobj, tfield) in f['refs'].items():
                if tobj == 'User':
                    continue
                m = first.get((tobj, tfield), {})
                for row in f['rows']:
                    v = row.get(col)
                    if v not in (None, ''):
                        j = m.get(str(v))
                        if j is not None and j != i:
                            deps[i].add(j)
            if f['ext']:
                m = first.get((f['obj'], f['ext']), {})
                for row in f['rows']:
                    j = m.get(str(row.get(f['ext'])))
                    if j is not None and j != i:
                        deps[i].add(j)
        indeg = {i: len(d) for i, d in deps.items()}
        rev = {i: [] for i in deps}
        for i, d in deps.items():
            for j in d:
                rev[j].append(i)
        heap = [i for i, n in indeg.items() if n == 0]
        heapq.heapify(heap)
        order = []
        while heap:
            i = heapq.heappop(heap)
            order.append(i)
            for k in rev[i]:
                indeg[k] -= 1
                if indeg[k] == 0:
                    heapq.heappush(heap, k)
        if len(order) != len(files):
            left = [(files[i]['obj'], files[i]['tag']) for i in deps if i not in order]
            raise ValueError(f'관계 순환: {left}')
        return [files[i] for i in order]

    def validate(self):
        errs = []
        keys = self.out.keys
        users = set(self.license_users)
        for f in self.out.files:
            for row in f['rows']:
                for col, v in row.items():
                    if col.startswith('_'):
                        errs.append(f"{f['obj']}: 내부 열 {col} 남음")
                        continue
                    if v in (None, ''):
                        continue
                    if ('__r.' in col or col.startswith('Account.')) and col not in f['refs']:
                        errs.append(f"{f['obj']}: 관계 열 {col} 대상 미등록")
                    if col in f['refs']:
                        tobj, tfield = f['refs'][col]
                        if tobj == 'User':
                            if v not in users:
                                errs.append(f"{f['obj']}.{col}: 사용자 {v} 없음")
                        elif str(v) not in keys.get((tobj, tfield), set()):
                            errs.append(f"{f['obj']}.{col}: {tobj}.{tfield}={v} 없음")
                    if isinstance(v, str) and '{{' in v:
                        for m in REF_RE.finditer(v):
                            if m.group(3) not in keys.get((m.group(1), m.group(2)), set()):
                                errs.append(f"{f['obj']}.{col}: 토큰 {m.group(0)} 대상 없음")
                        for m in USER_RE.finditer(v):
                            if m.group(1) not in users:
                                errs.append(f"{f['obj']}.{col}: 사용자 토큰 {m.group(1)} 없음")
        return errs

    # ------------------------------------------------------------ CSV·적재 계획 쓰기
    PASS_TAGS = ('pass2', 'update', 'L2', 'L3')      # 파일 번호에 a·b 접미를 붙이는 태그
    UPDATE_TAGS = ('pass2', 'update')               # 원본 행이 아닌 갱신 패스
    SKIP_IF_USER_MISSING = {'User', 'CMN_UserPlantAccess__c', 'CMN_Delegation__c'}   # 결재 Role 배정은 관리자로 대체(결재선 해석 유지)

    def write_salesforce(self):
        sf_dir = out_path('salesforce', 'x')
        sf_dir = os.path.dirname(sf_dir)
        for name in os.listdir(sf_dir):
            if re.match(r'^[0-8]\d[a-z]?_.+\.csv$', name):
                os.remove(os.path.join(sf_dir, name))
        order = self.order_files()
        plan, nn, sub = [], 0, 0
        for f in order:
            is_pass = f['tag'].startswith(self.PASS_TAGS)
            if is_pass and nn > 0:
                sub += 1
                prefix, ordv = f'{nn:02d}{chr(96 + sub)}', round(nn + sub / 10, 1)
            else:
                nn, sub = nn + 1, 0
                prefix, ordv = f'{nn:02d}', nn
            assert nn <= 89, '90번대는 Snowflake 데이터 작업 몫'
            rows = [{k: v for k, v in r.items() if not k.startswith('_')} for r in f['rows']]
            cols = []
            for r in rows:
                for k in r:
                    if k not in cols:
                        cols.append(k)
            name = f"{prefix}_{f['obj']}.csv"
            write_csv(f'salesforce/{name}', rows, cols)
            f['file'] = name
            user_cols = [c for c, t in f['refs'].items() if t[0] == 'User' and c in cols]
            token_cols = [c for c in cols if any(isinstance(r.get(c), str) and '{{' in r.get(c) for r in rows)]
            missing = 'skip' if (f['obj'] in self.SKIP_IF_USER_MISSING or f['tag'] == 'pass2-user') else 'admin'
            plan.append({'order': ordv, 'file': name, 'object': f['obj'], 'externalId': f['ext'], 'operation': f['mode'], 'pass': f['tag'] or None,
                         'rows': len(rows), 'recordTypeColumn': 'RecordTypeDeveloperName' in cols,
                         'relations': {c: f'{t[0]}.{t[1]}' for c, t in f['refs'].items() if c in cols},
                         'userLookups': user_cols, 'tokenColumns': token_cols, 'onMissingUser': missing, 'note': f['note'] or None})
        write_json('salesforce/load-plan.json', {
            'note': ('Salesforce 데모 적재 순서. scripts/demo/load_salesforce.sh가 이 파일과 load-plan.snowflake.json(90번대)을 order 순으로 합쳐 '
                     '`sf data upsert bulk`로 적재한다. RecordTypeDeveloperName 열은 RecordTypeId로, {{ref:객체.외부키=값}}·{{user:사번}} 토큰은 Id로 바꾼다. '
                     '토큰 대상이 아직 없으면 비워 적재하고 마지막 보정 패스에서 다시 채운다. onMissingUser = skip이면 사용자가 없는 행을 건너뛰고, '
                     'admin이면 실행 사용자(E1901)로 바꾼다.'),
            'asOf': self.today.isoformat(), 'users': 'salesforce/users/*.json', 'files': plan})
        self.plan = plan
        return plan

    # ------------------------------------------------------------ 기대값·키
    def write_expected(self):
        keys = dict(sorted(self.keys.items()))
        objects = {}
        for k, v in keys.items():
            for f in self.out.files:
                if f['ext'] and self.out.key_exists(f['obj'], f['ext'], v):
                    objects[k] = f"{f['obj']}.{f['ext']}"
                    break
        snow = os.path.join(ROOT, 'expected', 'scenario_keys_snowflake.json')
        snow_keys = {}
        if os.path.exists(snow):
            with open(snow, encoding='utf-8') as fh:
                snow_keys = json.load(fh).get('keys', {})
        merged = dict(keys)
        for k, v in snow_keys.items():
            merged.setdefault(k, v)
        write_json('expected/scenario_keys.json', {
            'note': '시나리오 논리 키 → 실제 번호. Salesforce 키는 gen_salesforce.py, Snowflake 키(SPC·MSA 등)는 scenario_keys_snowflake.json에서 합친다(있을 때).',
            'asOf': self.today.isoformat(), 'keys': dict(sorted(merged.items())), 'objects': objects,
            'sources': {'salesforce': sorted(keys), 'snowflake': sorted(k for k in snow_keys if k not in keys)},
            'lele': self.lele_keys, 's1Context': self.s1_ctx, 's2Context': self.s2_ctx, 's6Project': self.s6,
            'causeDistributionBasis': '종결 8D(클레임 8D 포함)의 OccurrenceCauseCode. LINKED_8D NCR은 클레임 8D를 공유하므로 8D 기준으로 한 번만 센다.',
            'closedEightD': [{'eightD': c[0], 'defect': c[1], 'cause': c[2], 'recordType': c[3], 'mode': c[4], 'item': c[5], 'plant': c[6], 'closedDate': c[7]}
                             for c in self.closed_8d]})
        # S9 수입검사
        months = {}
        for lot in self.lots:
            if lot['pending'] or lot['auto']:
                continue
            k = (lot['date'][:7], lot['vendor'], lot['plant'])
            m = months.setdefault(k, {'month': k[0], 'vendor': k[1], 'plant': k[2], 'decidedLots': 0, 'acceptLots': 0, 'rejectLots': 0})
            m['decidedLots'] += 1
            m['acceptLots' if lot['decision'] == 'ACCEPT' else 'rejectLots'] += 1
        for m in months.values():
            m['lar'] = round(m['acceptLots'] / m['decidedLots'] * 100, 6)
        coa_pairs = [l for l in self.lots if l['item'] == 'P-CON-01' and l['plant'] == 'KR01' and l['date'] in ('2026-11-03', '2026-11-17')]
        write_json('expected/iqc_S9.json', {
            'asOf': self.today.isoformat(), 'period': {'from': '2026-06-01', 'to': '2026-11-30'},
            'larDefinition': 'QMS_IQC_LAR = ACCEPT 로트 / 판정 로트 × 100(자동 합격 SKIP·검사 중 로트 제외), 월 = 입고일(GrDate) 기준',
            'counts': {'lots': len(self.lots), 'decided': sum(1 for l in self.lots if not l['pending'] and not l['auto']),
                       'autoAccepted': sum(1 for l in self.lots if l['auto']), 'pending': sum(1 for l in self.lots if l['pending']),
                       'rejected': sum(1 for l in self.lots if l['decision'] == 'REJECT')},
            'levelChanges': self.level_changes, 'holds': self.holds,
            'rejects': [{'lot': l['recordNo'], 'lotKey': l['ext'], 'date': l['date'], 'item': l['item'], 'vendor': l['vendor'], 'plant': l['plant'], 'ncr': l['ncr']}
                        for l in self.lots if l['decision'] == 'REJECT'],
            'coaAnomalies': [{'rule': 'R1_IDENTICAL_VALUES', 'supplierItem': self.si_key('V10005', 'P-CON-01', 'KR01'), 'coa': [l['coa'] for l in coa_pairs],
                              'dates': [l['date'] for l in coa_pairs]},
                             {'rule': 'OOS_HOLD', 'coa': self.keys['S9-COA-OOS'], 'supplierItem': self.si_key('V10003', 'P-LED-HE1', 'KR01'),
                              'characteristic': self.char_key('P-LED-HE1', 'C40'), 'value': 27.0, 'usl': 25.0}],
            's3FirstLot': {'lot': self.keys['S3-IQC-FIRST'], 'lotKey': self.keys['S3-IQC-FIRST-EXT'], 'level': 'TIGHTENED', 'fullInspection': True,
                           'stabilizationLotsDecided': sum(1 for l in self.lots if l['item'] == 'P-LENS-HE1' and l['plant'] == 'KR01'
                                                           and l['date'] >= '2026-11-25' and not l['pending'])},
            'larMonthly': sorted(months.values(), key=lambda x: (x['month'], x['vendor'], x['plant']))})
        # S12 측정기 영향
        tol, err = 0.30, 0.05
        lots = []
        for l in self.lots:
            if not l['gaugeValues'] or not ('2025-11-20' <= l['date'] <= '2026-11-20') or l['pending']:
                continue
            for rk, name, lsl, usl, samples in l['gaugeValues']:
                vals = [s_['value'] for s_ in samples]
                risk = [v for v in vals if (lsl is not None and v - err < lsl) or (usl is not None and v - err > usl)]
                lots.append({'lot': l['recordNo'], 'lotKey': l['ext'], 'grDate': l['date'], 'item': l['item'], 'vendor': l['vendor'], 'result': rk,
                             'check': name, 'lsl': lsl, 'usl': usl, 'n': len(vals), 'min': min(vals), 'max': max(vals), 'decision': l['decision'],
                             'highRisk': bool(risk), 'riskSampleCount': len(risk)})
        write_json('expected/gauge_S12.json', {
            'gauge': 'GA-KR01-0456', 'calibrationFail': self.keys['S12-CAL-FAIL'], 'lastPassCalibration': self.keys['S12-CAL-LAST-PASS'],
            'impactAnalysis': self.keys['S12-IMPACT'], 'asFoundError': err, 'tolerance': tol, 'maxErrorPctOfTol': 16.7,
            'period': {'from': '2025-11-20', 'to': '2026-11-20'}, 'dataCoverage': {'from': '2026-06-01', 'note': '데모 수입검사 로트는 2026-06-01부터 있다(이전 기간은 UncoveredSources).'},
            'method': '이 측정기로 판정한 결과(GaugeNo__c = GA-KR01-0456)만 대상. 진값 추정 = 측정값 − As-found 오차(+0.05mm). 진값이 규격 밖인 시료가 있으면 고위험 로트.',
            'summary': {'affectedLotCount': len({x['lot'] for x in lots}), 'affectedResultCount': len(lots), 'highRiskLotCount': len({x['lot'] for x in lots if x['highRisk']})},
            'lots': lots})

    # ------------------------------------------------------------ 사용자 정의
    PRIORITY = ['E1101', 'E1102', 'E1103', 'E1104', 'E1111', 'E1112', 'E1202', 'E1151']
    TWO_CHAR_FAMILY = ('남궁', '황보', '선우', '제갈')

    def write_users(self):
        users_dir = os.path.dirname(out_path('salesforce', 'users', 'x'))
        for name in os.listdir(users_dir):
            if name.endswith('.json'):
                os.remove(os.path.join(users_dir, name))
        plants = {p['code']: p for p in self.m['plants']}
        tz = {'KR01': 'Asia/Seoul', 'KR02': 'Asia/Seoul', 'CN01': 'Asia/Shanghai', 'US01': 'America/Chicago', 'PL01': 'Europe/Warsaw'}
        loc = {'ko': ('ko_KR', 'ko'), 'zh_CN': ('zh_CN', 'zh_CN'), 'en_US': ('en_US', 'en_US'), 'pl': ('pl_PL', 'en_US')}
        rest = [e['no'] for e in self.m['employees'] if e['license'] and e['no'] not in self.PRIORITY]
        ranked = self.PRIORITY + rest
        for e in self.m['employees']:
            if not e['license']:
                continue
            nm = e['name']
            if ' ' in nm:
                first, last = nm.split(' ', 1)
            elif nm[:2] in self.TWO_CHAR_FAMILY:
                last, first = nm[:2], nm[2:]
            else:
                last, first = nm[:1], nm[1:]
            plant = e['plant'] or 'KR01'
            lang = plants[plant].get('lang', 'ko')
            lsk, llk = loc.get(lang, ('ko_KR', 'ko'))
            write_json(f"salesforce/users/{e['no']}.json", {
                'Username': f"{e['no'].lower()}.{{orgAlias}}@slqms.demo", 'LastName': last, 'FirstName': first or None,
                'Email': f"{e['no'].lower()}@slqms.example.com", 'Alias': e['no'].lower(), 'CommunityNickname': f"{e['no'].lower()}.demo",
                'TimeZoneSidKey': tz[plant], 'LocaleSidKey': lsk, 'LanguageLocaleKey': llk, 'EmailEncodingKey': 'UTF-8',
                'profileName': 'Standard User', 'FederationIdentifier': e['no'], 'EmployeeNo__c': e['no'],
                '_demo': {'priority': ranked.index(e['no']) + 1, 'create': e['no'] in self.PRIORITY, 'mapToAdmin': e['no'] == 'E1901',
                          'permissionSetGroups': e['psg'], 'approvalRoles': [r['role'] + ('@' + r['plant'] if r['plant'] else '') for r in e['roles']],
                          'nameKo': nm, 'nameEn': e['nameEn'], 'dept': e['dept'], 'plant': e['plant']}})

    # ------------------------------------------------------------ 화면 Apex 목(LWC Jest)
    @staticmethod
    def fake_id(prefix, key):
        import hashlib
        h = hashlib.md5(f'{prefix}:{key}'.encode()).hexdigest().upper()
        return (prefix + h)[:15] + 'AAA'

    def row_of(self, obj, field, value):
        for f in self.out.files:
            if f['obj'] == obj and f['ext'] == field and not f['tag'].startswith(self.UPDATE_TAGS):
                for r in f['rows']:
                    if r.get(field) == value:
                        return r
        return None

    def rows_where(self, obj, col, value):
        return [r for f in self.out.files if f['obj'] == obj and not f['tag'].startswith(self.UPDATE_TAGS) for r in f['rows'] if r.get(col) == value]

    def write_mocks(self):
        base = os.path.dirname(out_path('mocks', 'apex', 'x'))
        for root, _, names in os.walk(base):
            for n in names:
                if n.endswith('.json'):
                    os.remove(os.path.join(root, n))

        def meta(dto, status, scenario, note=None):
            return {'dto': dto, 'definition': status, 'scenario': scenario, 'asOf': self.today.isoformat(), 'generator': 'gen_salesforce.py', 'note': note}

        def status_dto(no, scenario):
            e = self.row_of('QMS_EightD__c', 'RecordNo__c', no)
            steps = self.rows_where('QMS_EightDStep__c', 'EightD__r.RecordNo__c', no)
            return {'_meta': meta('QMS_EightDStatusDTO', 'WI 정의(QMS-05-CLM-001 getStatusBySource)', scenario),
                    'eightDId': self.fake_id('a0E', no), 'recordNo': no, 'status': e['Status__c'], 'currentStep': e['CurrentStep__c'],
                    'stepStatus': {s['StepNo__c']: s['Status__c'] for s in steps}, 'dueDate': e['DueDate__c'], 'isOverdue': e['DueDate__c'] < self.today.isoformat(),
                    'occurrenceCauseCode': e.get('OccurrenceCauseCode__r.ExternalKey__c'), 'escapeCauseCode': e.get('EscapeCauseCode__r.ExternalKey__c'),
                    'effectivenessResult': e['EffectivenessResult__c'], 'closedAt': e['ClosedAt__c']}
        write_json('mocks/apex/QMS_EightDStatusDTO/S1-8D.json', status_dto(self.keys['S1-8D'], 'S1'))
        write_json('mocks/apex/QMS_EightDStatusDTO/S2-8D.json', status_dto(self.keys['S2-8D'], 'S2'))
        # 8D 화면(제안 DTO)
        no = self.keys['S1-8D']
        e = self.row_of('QMS_EightD__c', 'RecordNo__c', no)
        ncr = self.row_of('QMS_NCR__c', 'RecordNo__c', self.keys['S1-NCR'])
        write_json('mocks/apex/qmsEightDScreen/S1-8D.json', {
            '_meta': meta('QMS_EightDScreenDTO', '제안 DTO(WI 미정의 — 변경 요청)', 'S1', '8D 작성 화면 초기 로드 응답. 필드명은 객체 API명에서 __c를 뗀 camelCase'),
            'header': {'id': self.fake_id('a0E', no), 'recordNo': no, 'name': e['Name'], 'recordType': 'NCR_INTERNAL', 'mode': e['Mode__c'], 'form': e['Form__c'],
                       'status': e['Status__c'], 'currentStep': e['CurrentStep__c'], 'dueDate': e['DueDate__c'], 'severity': e['Severity__c'],
                       'plantCode': 'KR01', 'itemNo': e['Item__r.ItemNo__c'], 'customerCode': 'BMW', 'leader': {'employeeNo': 'E1103', 'name': self.emps['E1103']['name']},
                       'champion': {'employeeNo': 'E1101', 'name': self.emps['E1101']['name']}},
            'source': {'object': 'QMS_NCR__c', 'recordNo': self.keys['S1-NCR'], 'sourceType': ncr['SourceType__c'], 'defectTypePath': ncr['DefectTypePath__c'],
                       'defectQty': ncr['DefectQty__c'], 'suspectQty': ncr['SuspectQty__c']},
            'steps': [{'stepNo': s['StepNo__c'], 'status': s['Status__c'], 'dueDate': s['DueDate__c'], 'approvedAt': s['ApprovedAt__c']}
                      for s in self.rows_where('QMS_EightDStep__c', 'EightD__r.RecordNo__c', no)],
            'd2': {k: e[k] for k in ('ProblemStatement__c', 'D2What__c', 'D2Where__c', 'D2When__c', 'D2Who__c', 'D2Why__c', 'D2How__c', 'D2HowMany__c')},
            'team': [{'employeeNo': t['User__r.EmployeeNo__c'], 'role': t['Role__c']} for t in self.rows_where('QMS_EightDTeamMember__c', 'EightD__r.RecordNo__c', no)],
            'actions': [{'actionNo': a['ActionNo__c'], 'type': a['ActionType__c'], 'description': a['Description__c'], 'status': a['Status__c'],
                         'suspectQty': a.get('SuspectQty__c'), 'ngQty': a.get('NgQty__c')} for a in self.rows_where('QMS_EightDAction__c', 'EightD__r.RecordNo__c', no)],
            'containment': [{'location': c['Location__c'], 'checked': c['QtyChecked__c'], 'ng': c['QtyNg__c'], 'status': c['Status__c']}
                            for c in self.rows_where('QMS_NcrContainment__c', 'Ncr__r.RecordNo__c', self.keys['S1-NCR'])],
            'aiAssist': {'available': True, 'stepNo': 'D4', 'lastRecommendationId': None, 'expectedFile': 'data/demo/expected/ai_rca_S1.json'},
            'permissions': {'canEdit': True, 'canSubmit': True, 'canApprove': False}})
        # 4M 상태(제안)·검증 그리드(제안)
        fm = self.keys['S3-4M']
        frow = self.row_of('QMS_FourMChange__c', 'RecordNo__c', fm)
        vers = self.rows_where('QMS_FourMVerification__c', 'FourM__r.RecordNo__c', fm)
        write_json('mocks/apex/QMS_FourMStatusDTO/S3-4M.json', {
            '_meta': meta('QMS_FourMStatusDTO', '제안 DTO(4MC-002 getStatusBySource 반환형, 필드 미정의 — 변경 요청)', 'S3'),
            'fourMId': self.fake_id('a0F', fm), 'recordNo': fm, 'status': frow['Status__c'], 'riskClass': frow['RiskClass__c'],
            'plannedApplyDate': frow['PlannedApplyDate__c'], 'appliedAt': frow['AppliedAt__c'], 'firstLotRecordNo': self.keys['S3-IQC-FIRST'],
            'stabilization': {'recordNo': self.keys['S3-STB'], 'status': 'ACTIVE', 'startDate': '2026-11-25', 'minDays': 90, 'minLots': 10, 'actualLots': 2},
            'verificationTotal': len(vers), 'verificationDone': sum(1 for v in vers if v['Status__c'] == 'DONE'), 'unauthorized': False})
        write_json('mocks/apex/qmsFourMVerificationGrid/S3-4M.json', {
            '_meta': meta('QMS_FourMVerificationRowDTO[]', '제안 DTO(WI 미정의 — 변경 요청)', 'S3'),
            'fourMRecordNo': fm, 'rows': [{'id': self.fake_id('a0G', v['ExternalKey__c']), 'sequence': v['Sequence__c'], 'type': v['VerificationType__c'],
                                           'gateStage': v['GateStage__c'], 'title': v['Title__c'], 'owner': v['Owner__r.EmployeeNo__c'], 'dueDate': v['DueDate__c'],
                                           'status': v['Status__c'], 'linkedObject': v['LinkedObject__c'], 'linkedRecordNo': v['LinkedRecordNo__c'],
                                           'customerDecision': v['CustomerDecision__c'], 'mandatory': True} for v in vers]})
        # 수입검사 대기열(제안)
        queue = [l for l in self.lots if l['pending'] and l['plant'] == 'KR01']
        sup_name = {s['vendorNo']: s['name'] for s in self.m['suppliers']}
        write_json('mocks/apex/qmsIqcQueue/KR01.json', {
            '_meta': meta('QMS_IqcQueueDTO', '제안 DTO(WI 미정의 — 변경 요청)', 'S9'),
            'plantCode': 'KR01', 'asOf': ts(self.today, 8), 'counts': {'pending': len(queue), 'overdue': 0, 'fullInspection': sum(1 for l in queue if l['full'])},
            'rows': [{'lotId': self.fake_id('a0H', l['ext']), 'recordNo': l['recordNo'], 'externalKey': l['ext'], 'itemNo': l['item'],
                      'itemName': self.items[l['item']]['name'], 'vendorNo': l['vendor'], 'vendorName': sup_name[l['vendor']], 'grDate': l['date'],
                      'grQty': l['qty'], 'inspectionLevel': l['level'], 'fullInspection': l['full'], 'coaStatus': l['coaStatus'],
                      'holds': [h['type'] for h in self.holds if h['supplierItem'] == l['supplierItem'] and h['active']], 'is4mFirstLot': l['is4mFirst'],
                      'dueAt': ts(self.D(l['date']) + dt.timedelta(days=1), 9)} for l in queue]})
        # 협력사 포털 홈(제안) — 감마LED
        write_json('mocks/apex/qmsPortalHome/V10003.json', {
            '_meta': meta('QMS_PortalHomeDTO', '제안 DTO(WI 미정의 — 변경 요청)', 'S2·S9', '협력사 포털 홈 카드 묶음'),
            'supplier': {'vendorNo': 'V10003', 'name': sup_name['V10003']},
            'eightD': [{'recordNo': self.keys['S2-8D'], 'title': '감마LED HE1 LED 모듈 솔더 보이드 8D(협력사)', 'currentStep': 'D5',
                        'nextSubmission': {'stage': 'ACTION_PLAN', 'round': 1, 'status': 'DRAFT'}, 'dueDate': self.row_of('QMS_EightD__c', 'RecordNo__c', self.keys['S2-8D'])['DueDate__c']}],
            'ncr': [{'recordNo': self.keys['S2-NCR'], 'status': 'COUNTERMEASURE', 'defect': 'DRL 점멸(솔더 보이드)'}],
            'coa': [{'recordNo': self.keys['S9-COA-OOS'], 'status': 'OOS_HOLD', 'itemNo': 'P-LED-HE1', 'message': '솔더 보이드율 27%(규격 25% 이하) — 출하 보류'}],
            'notices': [], 'lar3Months': [m for m in json.load(open(os.path.join(ROOT, 'expected', 'iqc_S9.json'), encoding='utf-8'))['larMonthly']
                                          if m['vendor'] == 'V10003' and m['month'] >= '2026-09']})

    # ------------------------------------------------------------ Apex 테스트 픽스처
    def write_fixtures(self):
        files = self.order_files()
        idx = {id(f): i for i, f in enumerate(files)}
        creator = {}
        for f in files:
            if f['ext'] and not f['tag'].startswith(self.UPDATE_TAGS):
                for r in f['rows']:
                    creator.setdefault((f['obj'], f['ext'], str(r.get(f['ext']))), (f, r))
        k = self.keys
        focus = {k[x] for x in ('S1-NCR', 'S1-8D', 'S2-CLAIM', 'S2-CLAIM-8D', 'S2-NCR', 'S2-8D', 'S2-LAB', 'S3-4M', 'S3-4M-REQ', 'S3-QUAL', 'S3-PPAP',
                                'S3-STB', 'S3-IQC-FIRST-EXT', 'S4-AUDIT', 'S4-AUDIT-PREV', 'S12-GAUGE', 'S12-CAL-FAIL', 'S12-IMPACT', 'S9-COA-OOS',
                                'S0-PPAP-INTERIM')}
        for l in self.lots:
            if l['item'] == 'P-HSG-BE1' and l['plant'] == 'KR01' and '2026-09-21' <= l['date'] <= '2026-11-09':
                focus.add(l['ext'])
            if l['item'] == 'P-CON-01' and l['plant'] == 'KR01' and l['date'] in ('2026-11-03', '2026-11-17'):
                focus.update({l['ext'], l['coa']})
        whole = {'CMN_CodeGroup__c', 'CMN_Code__c', 'CMN_ApprovalTemplate__c', 'CMN_ApprovalTemplateStep__c', 'CMN_Delegation__c', 'QMS_SamplingPlan__c',
                 'QMS_SamplingPlanRow__c', 'QMS_PpapElement__c', 'QMS_PpapLevelRule__c', 'QMS_ChangeTypeRule__c', 'QMS_IqcLevelChange__c', 'QMS_IqcLevelHold__c',
                 'QMS_AuditChecklist__c', 'QMS_AuditQuestion__c', 'QMS_AuditGradeRule__c', 'QMS_TestItem__c', 'QMS_TestStandard__c', 'QMS_TestStandardLine__c'}
        chosen = {i: [] for i in range(len(files))}
        keyset = set()

        def take(f, r):
            key = (f['obj'], f['ext'], str(r.get(f['ext'])))
            if key in keyset:
                return False
            keyset.add(key)
            chosen[idx[id(f)]].append(r)
            return True
        for f in files:
            if f['tag'].startswith(self.UPDATE_TAGS):
                continue
            for r in f['rows']:
                if f['obj'] in whole or str(r.get(f['ext'])) in focus or any(str(r.get(c)) in focus for c in f['refs']):
                    take(f, r)
        changed = True
        while changed:
            changed = False
            for i, f in enumerate(files):
                if f['tag'].startswith(self.UPDATE_TAGS):
                    continue
                for r in list(chosen[i]):
                    for c, (tobj, tfield) in f['refs'].items():
                        v = r.get(c)
                        if v in (None, '') or tobj == 'User':
                            continue
                        hit = creator.get((tobj, tfield, str(v)))
                        if hit and take(*hit):
                            changed = True
            for i, f in enumerate(files):
                if not f['tag'].startswith(self.UPDATE_TAGS):
                    continue
                for r in f['rows']:
                    if (f['obj'], f['ext'], str(r.get(f['ext']))) in keyset and r not in chosen[i]:
                        chosen[i].append(r)
                        for c, (tobj, tfield) in f['refs'].items():
                            v = r.get(c)
                            if v not in (None, '') and tobj != 'User':
                                hit = creator.get((tobj, tfield, str(v)))
                                if hit and take(*hit):
                                    changed = True
        users = set()
        steps = []
        for i, f in enumerate(files):
            rows = []
            for r in chosen[i]:
                row = {}
                for c, v in r.items():
                    if c.startswith('_'):
                        continue
                    if c in f['refs'] and v not in (None, ''):
                        tobj, tfield = f['refs'][c]
                        if tobj == 'User':
                            users.add(v)
                        elif (tobj, tfield, str(v)) not in keyset:
                            v = None
                    if isinstance(v, str) and '{{' in v:
                        ok = all((m.group(1), m.group(2), m.group(3)) in keyset for m in REF_RE.finditer(v))
                        users.update(USER_RE.findall(v))
                        v = v if ok else None
                    row[c] = v
                rows.append(row)
            if rows:
                steps.append({'order': len(steps) + 1, 'object': f['obj'], 'externalId': f['ext'], 'pass': f['tag'] or None, 'rows': rows})
        emps = [self.emps[u] for u in sorted(users) if u in self.emps]
        data = {'version': 1, 'asOf': self.today.isoformat(),
                'note': ('CMN_TestDataFactory용 소형 고정 데이터(정적 리소스 QMS_DemoFixtures). 데모 CSV와 같은 키·값의 부분 집합이다. '
                         'steps 순서대로 externalId로 upsert하고, 관계 열 Field__r.ExternalField는 앞 단계에서 만든 레코드 Id로, '
                         '{{ref:객체.외부키=값}}·{{user:사번}} 토큰과 RecordTypeDeveloperName은 팩토리가 바꾼다. 사용자는 users 목록대로 테스트 안에서 만든다.'),
                'scenarioKeys': {x: self.keys[x] for x in sorted(self.keys)},
                'users': [{'employeeNo': e['no'], 'name': e['name'], 'plant': e['plant'], 'dept': e['dept'], 'permissionSetGroups': e['psg'],
                           'approvalRoles': [r['role'] + ('@' + r['plant'] if r['plant'] else '') for r in e['roles']]} for e in emps],
                'steps': steps}
        path = write_json('fixtures/demo_fixtures.json', data)
        self.fixture_size = os.path.getsize(path)
        self.fixture_rows = sum(len(s['rows']) for s in steps)

    # ------------------------------------------------------------ WI 변경 요청
    def write_change_requests(self):
        extra = [
            ('데모 명세 8절', '변경 요청 파일을 데이터 작업별로 나눔(Salesforce: wi-change-requests-salesforce.md, Snowflake: wi-change-requests-snowflake.md). 명세의 wi-change-requests.md 단일 파일 표기와 다름', '두 파일로 운영'),
            ('데모 명세 5절 S0', 'NCR 70건·클레임 20건·4M 12건·인정시험 15건·PPAP 18건에 시나리오(S1·S2·S3) 레코드 포함 여부가 명시되지 않음 — 데모는 포함해 합계를 맞춤', 'NCR 70(INTERNAL 45·SUPPLIER 25·종결 62, S1·S2 포함), 클레임 20(S2 포함), 4M 12·인정시험 15·PPAP 18(S3 포함)'),
            ('QMS-05-CLM-001', 'QMS_Claim__c에 MIS(판매 후 개월)·VIN 해시 수 필드 없음 — S2 D2 초안 요소(MIS·VIN 해시 수)를 둘 곳이 없음. 필드 추가 또는 Snowflake B2B 조회로 표시 규칙 명시', 'LotInfo__c·DefectDescription__c 텍스트에 기록'),
            ('QMS-05-CLM-001', 'QMS_EightDStatusDTO 외 8D 작성 화면 초기 로드 DTO가 없음', 'mocks/apex/qmsEightDScreen/S1-8D.json(제안 DTO)'),
            ('QMS-06-4MC-002', 'QMS_FourMStatusDTO 필드 정의 없음(getStatusBySource 반환형만 있음), 검증 그리드 DTO 없음', 'mocks/apex/QMS_FourMStatusDTO/S3-4M.json, qmsFourMVerificationGrid/S3-4M.json(제안 DTO)'),
            ('QMS-03-IQC-003', '수입검사 대기열 화면 Apex DTO 정의 없음', 'mocks/apex/qmsIqcQueue/KR01.json(제안 DTO)'),
            ('QMS-03-SPP-002', '협력사 포털 홈 Apex DTO 정의 없음', 'mocks/apex/qmsPortalHome/V10003.json(제안 DTO)'),
            ('CMN-00-TDO-001', 'CMN_Todo__c.ExternalKey__c = {SourceType}/{SourceRecordId}/{AssigneeId}가 Salesforce Id를 포함해 이관·데모 CSV에서 미리 만들 수 없음 — 적재 시 Id 치환 필요(데모 로더가 토큰으로 처리)', '{SourceType}/{{ref:…}}/{{user:사번}}'),
            ('CMN-00-ARC-003', '데모·이관 적재 시 RecordNo가 이미 있으면 채번하지 않고 카운터를 그 값 이상으로 맞추는 동작 필요(데모 명세 4절과 같음)', 'CSV RecordNo 그대로 적재'),
            ('CMN-00-MDM-001', 'User.EmployeeNo__c External ID는 정의돼 있으나 데모 사용자 수가 Scratch Org 라이선스에 묶임 — 미생성 사용자 Lookup의 대체 규칙(실행 관리자) 필요', '로더 onMissingUser: skip/admin'),
        ]
        rows = []
        seen = set()
        for t, c, v in self.cr + extra:
            if (t, c) in seen:
                continue
            seen.add((t, c))
            rows.append((t, c, v))
        rows.sort(key=lambda x: x[0])
        lines = ['# WI 변경 요청 — Salesforce 데모 데이터 작업', '',
                 '데모 CSV를 만들며 확인한 WI 정의 누락·불일치다. 2단계 WI 보강 작업이 반영한다. 생성기(`gen_salesforce.py`)가 다시 만들므로 손으로 고치지 않는다.', '',
                 '| 대상 WI | 내용 | 데모에서 쓴 임시 값 |', '| --- | --- | --- |']
        for t, c, v in rows:
            lines.append(f"| {t} | {c.replace('|', '/')} | {v.replace('|', '/')} |")
        path = out_path('wi-change-requests-salesforce.md')
        with open(path, 'w', encoding='utf-8') as fh:
            fh.write('\n'.join(lines) + '\n')
        self.cr_rows = rows


def generate(master, clock):
    import time
    t0 = time.time()
    g = Gen(master, clock)
    g.masters()
    g.config()
    g.history()
    g.index_ncr()
    g.iqc()
    g.link_iqc_ncr()
    g.lele()
    g.qual_ppap_4m()
    g.s1()
    g.s2()
    g.audits()
    g.gauges()
    g.people_history()
    g.workflow()
    g.resolve_placeholders()
    _renumber(g)
    errs = g.validate()
    if errs:
        raise ValueError('참조 점검 실패:\n' + '\n'.join(errs[:50]))
    plan = g.write_salesforce()
    g.write_expected()
    g.write_users()
    g.write_mocks()
    g.write_fixtures()
    g.write_change_requests()
    counts = {}
    for p in plan:
        if not (p['pass'] or '').startswith(Gen.UPDATE_TAGS):
            counts[p['object']] = counts.get(p['object'], 0) + p['rows']
    print(f'[salesforce] CSV {len(plan)}개 파일, 참조 점검 통과(관계 열·토큰)')
    for obj, n in counts.items():
        print(f'  {obj:40s} {n:6d}')
    print(f'  시나리오 키 {len(g.keys)}, To-Do {len(g.todos)}, 픽스처 {g.fixture_rows}행 {g.fixture_size // 1024}KB, 변경 요청 {len(g.cr_rows)}건')
    print(f'[salesforce] {time.time() - t0:.1f}s')
    return {'files': len(plan), 'counts': counts, 'keys': g.keys}


def _renumber(g):
    """업무 번호를 발생일 순으로 다시 매긴다(생성 순서와 무관하게 번호 = 시간 순). 모든 행·키·기대값 구조에 일괄 치환."""
    specs = [('QMS_NCR__c', 'DetectedAt__c'), ('QMS_Claim__c', 'ReceivedAt__c'), ('QMS_EightD__c', None), ('QMS_LessonLearned__c', 'PublishedAt__c'),
             ('QMS_Qualification__c', 'ValidFrom__c'), ('QMS_LabRequest__c', 'SampleReceivedAt__c'), ('QMS_Audit__c', 'PlannedStart__c'),
             ('CMN_ApprovalRequest__c', 'SubmittedAt__c'), ('QMS_Ppap__c', 'DueDate__c'), ('QMS_QualPlan__c', 'TargetDate__c'),
             ('QMS_FourMChange__c', 'RequestedDate__c'), ('QMS_StabilizationPlan__c', 'StartDate__c'), ('QMS_SupplierCoa__c', 'ShipDate__c')]
    creators = {}
    for f in g.out.files:
        if f['ext'] == 'RecordNo__c' and not f['tag'].startswith(Gen.UPDATE_TAGS):
            creators.setdefault(f['obj'], []).extend(f['rows'])
    src_date = {}
    for r in creators.get('QMS_NCR__c', []):
        src_date[r['RecordNo__c']] = r['DetectedAt__c']
    for r in creators.get('QMS_Claim__c', []):
        src_date[r['RecordNo__c']] = r['ReceivedAt__c']
    mapping = {}
    for obj, field in specs:
        groups = {}
        for r in creators.get(obj, []):
            no = r['RecordNo__c']
            when = src_date.get(r.get('SourceRecordNo__c'), '') + '~' if field is None else str(r.get(field) or '')
            groups.setdefault(no.rsplit('-', 1)[0], []).append((when, no))
        for prefix, items in groups.items():
            width = len(items[0][1].rsplit('-', 1)[1])
            for n, (_, old) in enumerate(sorted(items), 1):
                new = f'{prefix}-{n:0{width}d}'
                if new != old:
                    mapping[old] = new
    if not mapping:
        return
    rx = re.compile(r'(?<![A-Za-z0-9])(?:' + '|'.join(re.escape(k) for k in sorted(mapping, key=len, reverse=True)) + r')(?![0-9])')

    def sub(v):
        if isinstance(v, str):
            return rx.sub(lambda m: mapping[m.group(0)], v)
        if isinstance(v, list):
            return [sub(x) for x in v]
        if isinstance(v, tuple):
            return tuple(sub(x) for x in v)
        if isinstance(v, dict):
            return {sub(k): sub(x) for k, x in v.items()}
        return v
    for f in g.out.files:
        f['rows'][:] = [{k: sub(v) for k, v in r.items()} for r in f['rows']]
    g.out.keys = {}
    for f in g.out.files:
        for r in f['rows']:
            if f['ext'] and r.get(f['ext']) not in (None, ''):
                g.out.keys.setdefault((f['obj'], f['ext']), set()).add(str(r[f['ext']]))
    for e in g.license_users:
        g.out.keys.setdefault(R_USER, set()).add(e)
    for attr in ('keys', 'closed_8d', 'lots', 'holds', 'todos', 's1_ctx', 's2_ctx', 'lele_keys', 'level_changes', 'quals', 'limit_samples', 'open_flat', 's4_tasks', 's12'):
        if hasattr(g, attr):
            setattr(g, attr, sub(getattr(g, attr)))
    g.renumbered = len(mapping)
