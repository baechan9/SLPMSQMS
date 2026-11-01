"""Vol. 워크아이템 md 형식 검사(파일을 고치지 않는다).
검사: WI 헤더 형식, 메타 라인 8항목·값 범위, 공수 2~8, 표 열 수 일치, 중복 WI ID.
사용: python3 scripts/validate_vol.py docs/10-workitems/vol4-....md [...]   (docs/에서 실행)"""
import re, sys, collections

PRIORITY = {'필수', '권장'}
WAVE = {'W0', 'W1', 'W2', 'W3'}
FITGAP = {'OOTB', 'Tailoring', 'Customization'}
PLATFORM = {'SF', 'EXP', 'SNOW', 'MULE', 'DC', 'AF'}
TYPE = {'DM', 'CFG', 'APEX', 'LWC', 'FLOW', 'INT', 'SQL', 'SNOWPARK', 'AGENT', 'DOC'}
HEADER = re.compile(r'^### ((CMN|QMS|PMS)-(\d\d)-([A-Z0-9]+)-(\d{3}[a-z]?)) (.+)$')


def cells(line):
    return re.sub(r'`[^`]*`', '', line).strip().strip('|').split('|')


def check(path):
    lines = open(path, encoding='utf-8').read().split('\n')
    errors, wis = [], []
    i = 0
    while i < len(lines):
        if lines[i].startswith('|'):
            j = i
            while j < len(lines) and lines[j].startswith('|'):
                j += 1
            counts = [len(cells(l)) for l in lines[i:j]]
            if len(set(counts)) > 1:
                errors.append(f'{i + 1}행: 표 열 수 불일치 {counts}')
            i = j
            continue
        if lines[i].startswith('### ') and re.match(r'^### (CMN|QMS|PMS)-', lines[i]):
            m = HEADER.match(lines[i])
            if not m:
                errors.append(f'{i + 1}행: WI 헤더 형식 오류: {lines[i]}')
            else:
                j = i + 1
                while j < len(lines) and not lines[j].strip():
                    j += 1
                p = [x.strip() for x in lines[j].split(' · ')]
                wid = m.group(1)
                if len(p) != 8:
                    errors.append(f'{j + 1}행: {wid} 메타 라인 항목 {len(p)}개(8개 필요)')
                else:
                    if not p[0].startswith('추적 '):
                        errors.append(f'{wid}: 추적 항목은 "추적 "으로 시작')
                    if p[1] not in PRIORITY:
                        errors.append(f'{wid}: 우선순위 값 {p[1]}')
                    if p[2] not in WAVE:
                        errors.append(f'{wid}: Wave 값 {p[2]}')
                    bad = {x.strip() for x in p[3].split(',')} - PLATFORM
                    if bad:
                        errors.append(f'{wid}: 플랫폼 값 {bad}')
                    bad = {x.strip() for x in p[4].split(',')} - TYPE
                    if bad:
                        errors.append(f'{wid}: 유형 값 {bad}')
                    if p[5] not in FITGAP:
                        errors.append(f'{wid}: Fit-Gap 값 {p[5]}')
                    if not p[6].startswith('선행 '):
                        errors.append(f'{wid}: 선행 항목은 "선행 "으로 시작')
                    mm = re.match(r'^(\d+(?:\.\d+)?) M/D$', p[7])
                    if not mm:
                        errors.append(f'{wid}: 공수 형식 {p[7]}')
                    else:
                        md = float(mm.group(1))
                        if not 2 <= md <= 8:
                            errors.append(f'{wid}: 공수 {md}는 2~8 범위 밖')
                        wis.append((wid, p[2], md))
        i += 1
    dup = [k for k, v in collections.Counter(w[0] for w in wis).items() if v > 1]
    if dup:
        errors.append(f'중복 WI ID: {dup}')
    waves = collections.Counter(w[1] for w in wis)
    print(f'{path}: WI {len(wis)}, {sum(w[2] for w in wis):g} M/D, Wave {dict(sorted(waves.items()))}')
    for e in errors:
        print('  ERROR', e)
    return not errors


if __name__ == '__main__':
    ok = all([check(p) for p in sys.argv[1:]])
    sys.exit(0 if ok else 1)
