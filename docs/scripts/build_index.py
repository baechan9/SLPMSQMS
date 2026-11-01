"""docs/10-workitems/*.md 의 WI 헤더(### ID 제목)와 메타 라인을 읽어 master/workitem-index.csv 를 만든다.
사용: python scripts/build_index.py   (상태 열은 기존 CSV 값을 유지)"""
import re, csv, glob, os
L2 = {'00':'공통','02':'개발 품질','03':'부품/협력사 품질','04':'제품/공정 품질','05':'고객 품질',
      '06':'품질 운영 지원','07':'Dashboard','08':'AI','09':'연계'}
L3 = {'ARC':'개발 기반','MDM':'기준정보','SEC':'권한·보안','I18N':'다국어','UX':'화면 공통','APV':'결재',
      'TDO':'To-Do·포탈','NTF':'알림','DOC':'문서','DSH':'대시보드','MTG':'회의','INT':'연계',
      'DWH':'Snowflake DW','AI':'AI','DVQ':'인정시험','SPP':'협력사 포털','IQC':'수입검사','PWT':'부품 보증시험',
      'PPA':'부품 Re-PPAP','PIS':'부품 초기안정화','EFC':'초기유동','SPC':'SPC','FQC':'제품/출하 검사',
      'HZD':'수평전개','LEL':'레슨런(LELE)','RPP':'제품 Re-PPAP','B2B':'고객 B2B 데이터','CLM':'고객 Claim·8D',
      'SQM':'협력사 품질목표/실적','4MC':'4M 변경','NCR':'부적합','LMS':'한도견본','TRN':'교육·자격',
      'GAU':'측정기','MSA':'MSA','LAB':'분석실','IMP':'개선과제','IAU':'내부심사','SAU':'협력사 Audit',
      'CAU':'고객 Audit(VDA 6.3)','CER':'인증 관리','AIQ':'품질 AI'}
OUT = 'master/workitem-index.csv'
prev = {}
if os.path.exists(OUT):
    for r in csv.DictReader(open(OUT, encoding='utf-8-sig')): prev[r['WI_ID']] = r.get('상태', '검토 대기')
rows = []
for path in sorted(glob.glob('docs/10-workitems/vol*.md')):
    src = os.path.basename(path).split('-')[0]
    lines = open(path, encoding='utf-8').read().split('\n')
    for i, l in enumerate(lines):
        m = re.match(r'^### ((CMN|QMS|PMS)-(\d\d)-([A-Z0-9]+)-(\d{3}[a-z]?)) (.+)$', l)
        if not m: continue
        j = i + 1
        while not lines[j].strip(): j += 1
        p = [x.strip() for x in lines[j].split(' · ')]
        if len(p) != 8:
            print('WARN 메타 라인 형식 오류:', m.group(1), p); continue
        rows.append({'WI_ID': m.group(1), 'L1_시스템': m.group(2),
            'L2_메뉴': f"{m.group(3)} {L2.get(m.group(3), '')}", 'L3_기능': f"{m.group(4)} {L3.get(m.group(4), '')}",
            'L4_워크아이템': m.group(6), 'RFP_추적': p[0].removeprefix('추적 '), '우선순위': p[1], 'Wave': p[2],
            '플랫폼': p[3], '유형': p[4], 'FitGap': p[5], '선행WI': p[6].removeprefix('선행 '),
            '공수MD': p[7].replace(' M/D', ''), '출처': src, '상태': prev.get(m.group(1), '검토 대기')})
with open(OUT, 'w', newline='', encoding='utf-8-sig') as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print(f'{len(rows)} WI, {sum(float(r["공수MD"]) for r in rows):g} M/D → {OUT}')
