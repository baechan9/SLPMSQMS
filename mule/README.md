# MuleSoft 애플리케이션

Mule 애플리케이션 소스를 둔다(CMN-00-ARC-001 저장소 구조). 외부 트랙 담당이 운영한다(개발 플랜 3.4절).

- 위치: `mule/{api-name}/` — 이름은 `{계층}-{대상}-api`(계층 = sys / prc / exp, Vol.0 3.2절). 예: `mule/sys-sap-material-api/`, `mule/prc-dw-query-api/`
- 목 애플리케이션 `mock-source-systems`(QMS-09-INT-003)도 여기에 둔다: `mule/mock-source-systems/`
- 비밀값은 Mule Secure Properties로만 다룬다(ARC-001 BR-3). 키·비밀번호를 저장소에 두지 않는다.

애플리케이션이 아닌 연계 산출물(계약 스키마, 목 응답 JSON, PoC 주입 스크립트, 카탈로그)은 `integration/`에 둔다(`integration/README.md`).
