#!/usr/bin/env python3
"""Apex 클래스별 커버리지가 기준(기본 85%) 미만이면 클래스 이름을 출력하고 실패한다(CMN-00-ARC-001 BR-1, AC-2).

사용:
  sf project deploy start --dry-run -o <alias> --test-level RunLocalTests --json > build/deploy.json
  python3 scripts/ci/check-coverage.py build/deploy.json [--threshold 85]

읽는 형식
- 배포 결과(`sf project deploy start --json`): result.details.runTestResult.codeCoverage[]
- 테스트 실행 결과(`sf apex run test --code-coverage --json`): result.coverage.coverage[]
판정 대상: sfdx-project.json 패키지 디렉터리에 있는 클래스·트리거만. RunLocalTests는 Org 기본 클래스
(Experience Cloud가 만드는 CommunitiesSelfRegController 등, 커버리지 85% 미만)도 돌리므로 그것은 참고로만 표시한다.
종료 코드: 0 = 통과(Apex 없음 포함), 1 = 기준 미달 또는 배포·테스트 실패, 2 = 입력 오류.
"""
import argparse
import glob
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def project_apex_names():
    """저장소 패키지 디렉터리의 Apex 클래스·트리거 이름."""
    with open(os.path.join(ROOT, 'sfdx-project.json'), encoding='utf-8') as f:
        dirs = [d['path'] for d in json.load(f)['packageDirectories']]
    names = set()
    for d in dirs:
        for ext in ('cls', 'trigger'):
            for p in glob.glob(os.path.join(ROOT, d, '**', f'*.{ext}'), recursive=True):
                names.add(os.path.splitext(os.path.basename(p))[0])
    return names


def as_list(v):
    if v is None:
        return []
    return v if isinstance(v, list) else [v]


def from_deploy(result):
    rtr = ((result.get('details') or {}).get('runTestResult')) or {}
    rows = []
    for c in as_list(rtr.get('codeCoverage')):
        total = int(c.get('numLocations') or 0)
        if total == 0:
            continue
        covered = total - int(c.get('numLocationsNotCovered') or 0)
        rows.append((c.get('name'), covered, total))
    failures = [f"{f.get('name')}.{f.get('methodName')}: {(f.get('message') or '')[:200]}" for f in as_list(rtr.get('failures'))]
    return rows, failures


def from_test_run(result):
    rows = []
    for c in as_list((result.get('coverage') or {}).get('coverage')):
        total = int(c.get('totalLines') or 0)
        if total == 0:
            continue
        rows.append((c.get('name'), int(c.get('totalCovered') or 0), total))
    failures = [f"{t.get('FullName') or t.get('MethodName')}: {(t.get('Message') or '')[:200]}"
                for t in as_list(result.get('tests')) if t.get('Outcome') not in (None, 'Pass')]
    return rows, failures


def main():
    ap = argparse.ArgumentParser(description='Apex 클래스별 커버리지 기준 검사')
    ap.add_argument('file', help='sf 명령의 --json 출력 파일')
    ap.add_argument('--threshold', type=float, default=85.0, help='클래스별 최소 커버리지(%%, 기본 85)')
    ap.add_argument('--all', action='store_true', help='저장소 밖 Org 클래스도 판정한다')
    a = ap.parse_args()
    try:
        with open(a.file, encoding='utf-8') as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        print(f'입력을 읽을 수 없음: {e}')
        return 2
    result = data.get('result') or {}
    if 'coverage' in result or 'tests' in result:
        rows, failures = from_test_run(result)
    else:
        rows, failures = from_deploy(result)
    ok = True
    if data.get('status', 0) != 0 or result.get('success') is False:
        print(f"배포·테스트 실패: {data.get('message') or result.get('errorMessage') or result.get('status')}")
        ok = False
    for f in failures:
        print(f'테스트 실패: {f}')
        ok = False
    mine = None if a.all else project_apex_names()
    judged = [r for r in rows if mine is None or r[0] in mine]
    if not judged:
        print('판정할 Apex 커버리지 없음(저장소에 Apex 코드가 없거나 테스트를 실행하지 않음)')
        return 0 if ok else 1
    low = []
    for name, covered, total in sorted(rows):
        pct = covered * 100.0 / total
        if mine is not None and name not in mine:
            print(f'참고  {pct:6.2f}%  {covered}/{total}  {name}(저장소 밖 Org 클래스, 판정 제외)')
            continue
        mark = '미달' if pct < a.threshold else '통과'
        print(f'{mark}  {pct:6.2f}%  {covered}/{total}  {name}')
        if pct < a.threshold:
            low.append(name)
    if low:
        print(f"커버리지 {a.threshold:g}% 미만 클래스 {len(low)}개: {', '.join(low)}")
        ok = False
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
