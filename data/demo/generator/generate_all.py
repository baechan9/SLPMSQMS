"""데모 데이터 전체 생성: Salesforce → Snowflake 순서로 실행한다.
사용: python3 data/demo/generator/generate_all.py [--today YYYY-MM-DD]"""
import argparse
import datetime as dt
import importlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from common import Clock, load_master  # noqa: E402


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--today', help='기준일 이동(기본 2026-12-01)')
    args = p.parse_args()
    clock = Clock(dt.date.fromisoformat(args.today) if args.today else None)
    master = load_master()
    # Salesforce를 마지막에 한 번 더 돌린다: 그때 Snowflake 시나리오 키가 scenario_keys.json에 합쳐진다
    for name in ('gen_salesforce', 'gen_snowflake', 'gen_salesforce'):
        mod = importlib.import_module(name)
        mod.generate(master, clock)
        print(f'{name} 완료')


if __name__ == '__main__':
    main()
