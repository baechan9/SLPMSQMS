# 연계 산출물

Mule 애플리케이션 소스(`mule/`)가 아닌 연계 산출물을 둔다. QMS-09 Vol.이 정한 경로를 따른다.

| 경로 | 내용 | 소유 WI |
| --- | --- | --- |
| `integration/contracts/{if-id}.schema.json` | 인터페이스별 원천 페이로드·Salesforce upsert 본문·이벤트 페이로드 JSON Schema | QMS-09-INT-003 |
| `integration/mocks/{system}/` | 목 원천 시스템(`mule/mock-source-systems`)의 고정 응답 JSON | QMS-09-INT-003 |
| `integration/poc/run_scenario.sh` | PoC 시나리오 주입 스크립트 | QMS-09-INT-003 |
| `integration/catalog.md` | 인터페이스 카탈로그(`CMN_Interface__mdt`에서 생성, 손으로 고치지 않음) | QMS-09-INT-001 |

Salesforce 화면·Apex 테스트용 목(`data/demo/mocks/`)과 섞지 않는다. 그쪽은 데모 데이터 생성기 산출물이다.
