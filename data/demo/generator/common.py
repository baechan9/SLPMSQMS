"""데모 데이터 생성 공통 함수(표준 라이브러리만 사용).
마스터 로드, seed 고정 난수, 기준일 이동, CSV·JSON 쓰기를 제공한다. gen_salesforce.py와 gen_snowflake.py가 같이 쓴다."""
import csv
import datetime as dt
import json
import os
import random

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
MASTER_PATH = os.path.join(ROOT, 'master', 'demo_master.json')
BASE_TODAY = dt.date(2026, 12, 1)


def load_master():
    with open(MASTER_PATH, encoding='utf-8') as f:
        return json.load(f)


class Clock:
    """명세의 날짜(BASE_TODAY 기준)를 --today 기준으로 같은 간격만큼 옮긴다."""

    def __init__(self, today=None):
        self.today = today or BASE_TODAY
        self.shift = self.today - BASE_TODAY

    def d(self, iso):
        """명세에 적힌 날짜 문자열을 이동된 date로 바꾼다."""
        return dt.date.fromisoformat(iso) + self.shift

    def dt(self, iso):
        return dt.datetime.fromisoformat(iso) + self.shift


def rng(name, seed):
    """생성기·테이블별로 독립된 난수열. 같은 seed와 이름이면 항상 같은 값이 나온다."""
    return random.Random(f'{seed}:{name}')


def out_path(*parts):
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


def write_csv(rel_path, rows, fieldnames=None):
    """rows: dict 목록. 값이 None이면 빈 칸으로 쓴다. UTF-8(BOM 없음, Bulk API 호환)."""
    path = out_path(*rel_path.split('/'))
    if not rows and not fieldnames:
        raise ValueError(f'{rel_path}: 행과 열이 모두 없습니다')
    fields = fieldnames or list(rows[0].keys())
    with open(path, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fields, lineterminator='\n')
        w.writeheader()
        for r in rows:
            w.writerow({k: ('' if r.get(k) is None else r.get(k)) for k in fields})
    return path


def write_json(rel_path, data):
    path = out_path(*rel_path.split('/'))
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2, default=str)
        f.write('\n')
    return path


def code_leaves(tree, prefix):
    """demo_master.json 코드 트리를 리프 경로 목록(['GROUP/L1/L2/L3', ...])으로 펼친다."""
    out = []
    for node in tree:
        if isinstance(node, str):
            out.append(f'{prefix}/{node}')
            continue
        path = f"{prefix}/{node['code']}"
        kids = node.get('children')
        if kids:
            out.extend(code_leaves(kids, path))
        else:
            out.append(path)
    return out
