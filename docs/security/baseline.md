# 보안 설정 기준선(Security Baseline)

CMN-00-SEC-004 AC-3 근거 문서다. 항목마다 **값**, **적용 방법**(메타데이터 / 설정 화면 / 외부 시스템), **설정 화면 경로**, **확인 방법**을 남긴다. 값이나 적용 방법이 바뀌면 이 문서와 해당 메타데이터를 같은 커밋에서 바꾼다.

- 적용 범위: Salesforce(SL QMS·PMS Org), Snowflake QDW, MuleSoft Anypoint.
- 기준 문서: 비기능 요구 NFR-4.2(암호화·SSO), TISAX 점검 항목.
- 비밀값(비밀번호·키·토큰)은 이 문서와 저장소 어디에도 두지 않는다(CMN-00-ARC-001 BR-3).

## 1. Salesforce

| # | 항목 | 값 | 적용 방법 | 설정 화면 경로 | 확인 방법 |
| --- | --- | --- | --- | --- | --- |
| S-1 | My Domain | 회사 전용 도메인 | Org 생성 시(Scratch·Sandbox는 기본 포함) | 설정 > 회사 설정 > 내 도메인 | 로그인 URL이 `*.my.salesforce.com` |
| S-2 | login.salesforce.com 로그인 차단 | 사용(My Domain URL로만 로그인) | 메타데이터 `force-app-cmn/main/default/settings/MyDomain.settings-meta.xml`(`canOnlyLoginWithMyDomainUrl = true`) | 설정 > 내 도메인 > 정책 > "https://login.salesforce.com에서 로그인 방지" | 메타데이터 조회(`Settings:MyDomain`), 화면에서 login.salesforce.com 로그인 거부(AC-1) |
| S-3 | SSO 전용 로그인 | 사용자 = SAML SSO(포탈 IdP), 로그인 페이지에서 ID/PW 양식 제거 | TDO-002에서 SAML 설정 후 화면 설정 | 설정 > 내 도메인 > 인증 구성 > 편집 > 인증 서비스(SSO만 선택, "로그인 양식" 해제) | 일반 사용자 ID/PW 로그인 거부(AC-1) |
| S-4 | 비상용 관리자 | 시스템 관리자 2명만 ID/PW + MFA. 이름·보관 위치는 운영 대장(저장소 밖) | 운영 절차 | 설정 > 사용자 > (2명) 프로필·권한 | 분기별 계정 점검(사용 이력 확인) |
| S-5 | MFA | 모든 직접 UI 로그인에 MFA 필수(SSO 사용자는 IdP MFA) | 설정 화면(Org 기본값 확인) | 설정 > ID 확인 > "모든 직접 UI 로그인에 MFA 필요" | 비상용 관리자 로그인 시 MFA 요청 |
| S-6 | 세션 시간 제한 | 2시간 | 메타데이터 `Security.settings-meta.xml`(`sessionTimeout = TwoHours`) | 설정 > 세션 설정 > 시간 초과 값 | 메타데이터 조회(`Settings:Security`) |
| S-7 | 세션 IP 고정 | 해제(해외 이동 사용자) | 메타데이터 `Security.settings-meta.xml`(`lockSessionsToIp = false`) | 설정 > 세션 설정 > "세션을 해당 세션이 시작된 IP 주소로 잠금" | 메타데이터 조회 |
| S-8 | 전송 암호화 | TLS 1.2 이상(플랫폼 기본) | 플랫폼 기본 | 설정 > 중요 업데이트·릴리스 업데이트(TLS 관련 항목) | 외부 연계(Mule) TLS 1.2 이상 협상 확인 |
| S-9 | 저장 암호화 | 플랫폼 기본 저장 암호화. Shield Platform Encryption은 결정 D-6 후 대상 필드 지정 | 결정 대기 | 설정 > 플랫폼 암호화(Shield 구매 시) | 결정 후 대상 필드 목록을 이 문서에 추가 |
| S-10 | 통합 사용자 | Mule 연결용 3개(SAP 연계, MES·DW 연계, 외부 시스템 연계), Salesforce Integration User 라이선스 + `CMN_PS_Integration` + 업무 Vol. 통합 PS(필요한 것만) | INT-001·Vol.9 WI | 설정 > 사용자(라이선스 Salesforce Integration) | 사용자별 PS 목록 점검 |
| S-11 | 통합 인증 | Mule → Salesforce: OAuth 2.0 JWT Bearer(연결된 앱 + 인증서). 비밀번호 로그인 금지 | INT-001 | 설정 > 앱 관리자 > (연결된 앱) > 정책: "관리자가 승인한 사용자는 사전 승인됨" | 통합 사용자 로그인 기록이 OAuth로만 남음 |
| S-12 | 외부 호출 자격 증명 | Named Credential + External Credential만(코드·메타데이터에 비밀값 금지) | ARC-001 BR-3 | 설정 > 이름이 지정된 자격 증명 | 저장소 검사(비밀값 패턴 0건) |
| S-13 | Apex 레코드 잠금 | Apex에서 잠금·해제 허용(결재 엔진) | 메타데이터 `Apex.settings-meta.xml`(`enableApexApprovalLockUnlock`) | 설정 > 프로세스 자동화 설정 | APV-001 테스트 |

### 1.1 적용·확인 기록

| 일자 | Org | 항목 | 결과 |
| --- | --- | --- | --- |
| 2026-11-02 | qms-dev-a(Scratch) | S-2, S-6, S-7 | 배포 후 메타데이터 조회로 `canOnlyLoginWithMyDomainUrl = true`, `sessionTimeout = TwoHours`, `lockSessionsToIp = false` 확인 |
| 2026-11-02 | qms-dev-a(Scratch) | AC-1(API) | SOAP `login()`으로 확인 시도: login.salesforce.com = `INVALID_LOGIN`, test.salesforce.com·My Domain = `INVALID_OPERATION`(신규 Org는 SOAP login()이 비활성이라 API로는 판정 불가). 화면 로그인으로 확인해야 함 |
| (대기) | qms-int | AC-1(화면) | 테스트 IdP 연결(TDO-002) 후 일반 사용자로 login.salesforce.com ID/PW 로그인 → 거부 확인 |

## 2. Snowflake(QDW) — 외부 트랙 적용

Snowflake 객체는 schemachange 버전 스크립트로만 만든다(`snowflake/migrations`, ARC-001 BR-4). 아래 SQL은 CMN-00-DWH-001이 스키마·역할을 만든 뒤 외부 트랙 담당이 다음 버전 스크립트로 옮겨 적용한다. 대상 테이블·컬럼 이름은 DWH-001 스키마 확정 후 맞춘다.

| # | 항목 | 값 | 확인 방법 |
| --- | --- | --- | --- |
| W-1 | 사용자 인증 | SAML SSO(사내 IdP) | `SHOW SECURITY INTEGRATIONS`에 SAML2 통합 |
| W-2 | 서비스 계정 인증 | Key-pair 인증만(비밀번호 금지): Mule(ROLE_INGEST·ROLE_TRANSFORM), Salesforce 조회(ROLE_SF_READER), AI(ROLE_AI_SERVICE) | `DESC USER`에서 `RSA_PUBLIC_KEY` 있음, `PASSWORD` 없음 |
| W-3 | 네트워크 정책 | Mule 송출 IP, Salesforce 송출 IP 범위, 사내망만 허용 | `SHOW NETWORK POLICIES`, 계정·서비스 사용자에 적용 |
| W-4 | 마스킹: 임율·원가 | `ROLE_FINANCE_READ`만 원문 | AC-2: `ROLE_QMS_ANALYST`로 조회 시 마스킹 값 |
| W-5 | 마스킹: NCR 비용 | `ROLE_FINANCE_READ`·`ROLE_QMS_COST`만 원문(검토 반영 Vol.6a NCR-008 BR-4) | `ROLE_QMS_ANALYST`로 조회 시 마스킹 값 |
| W-6 | RAW 개인정보(VIN) | `ROLE_INGEST`는 적재만, VIN 원문 조회는 업무 역할에 주지 않음(검토 반영 Vol.9 INT-014 BR-5) | `ROLE_QMS_ANALYST`로 VIN 컬럼 조회 시 마스킹 값 |
| W-7 | 역할 계층 | `ROLE_DW_ADMIN` ⊃ `ROLE_TRANSFORM` ⊃ `ROLE_INGEST`, 조회 역할(`ROLE_QMS_ANALYST`, `ROLE_SF_READER`, `ROLE_AI_SERVICE`)은 CURATED·MART 읽기만 | `SHOW GRANTS TO ROLE` |

```sql
-- W-3 네트워크 정책(IP는 운영 값으로 바꿔 적용, 저장소에는 예시만)
CREATE NETWORK POLICY IF NOT EXISTS NP_QDW_DEFAULT
  ALLOWED_IP_LIST = ('<mule-egress-ip>', '<salesforce-egress-range>', '<corporate-range>');
ALTER ACCOUNT SET NETWORK_POLICY = NP_QDW_DEFAULT;

-- W-4·W-5 마스킹(숫자 금액 컬럼)
CREATE MASKING POLICY IF NOT EXISTS MP_COST_NUMBER AS (val NUMBER) RETURNS NUMBER ->
  CASE WHEN IS_ROLE_IN_SESSION('ROLE_FINANCE_READ') THEN val ELSE NULL END;
CREATE MASKING POLICY IF NOT EXISTS MP_NCR_COST_NUMBER AS (val NUMBER) RETURNS NUMBER ->
  CASE WHEN IS_ROLE_IN_SESSION('ROLE_FINANCE_READ') OR IS_ROLE_IN_SESSION('ROLE_QMS_COST') THEN val ELSE NULL END;
-- 적용 예(대상 컬럼은 DWH-001 스키마 확정 후)
-- ALTER TABLE MART.<원가 테이블> MODIFY COLUMN <임율 컬럼> SET MASKING POLICY MP_COST_NUMBER;
-- ALTER TABLE CORE.NCR_DEFECT MODIFY COLUMN <비용 컬럼> SET MASKING POLICY MP_NCR_COST_NUMBER;

-- W-6 VIN(문자열)
CREATE MASKING POLICY IF NOT EXISTS MP_VIN AS (val STRING) RETURNS STRING ->
  CASE WHEN IS_ROLE_IN_SESSION('ROLE_DW_ADMIN') THEN val ELSE REGEXP_REPLACE(val, '.', '*', 1, 0) END;
```

## 3. MuleSoft — 외부 트랙 적용

| # | 항목 | 값 | 설정 위치 | 확인 방법 |
| --- | --- | --- | --- | --- |
| M-1 | API 클라이언트 인증 | Client ID Enforcement + OAuth 2.0 Client Credentials | Anypoint API Manager > (API) > Policies | client_id 없이 호출 시 401 |
| M-2 | Mule → Salesforce | OAuth 2.0 JWT Bearer, 통합 사용자 3개(S-10) | Anypoint Secrets Manager(인증서·키) | 연결 테스트 |
| M-3 | Mule → Snowflake | Key-pair(W-2), 역할 ROLE_INGEST·ROLE_TRANSFORM | Secrets Manager | 연결 테스트 |
| M-4 | 전송 | TLS 1.2 이상, 내부 통신도 HTTPS | Runtime Manager > TLS Context | 협상 버전 로그 |
| M-5 | 비밀값 | Secrets Manager·보안 속성만, 저장소·설정 파일에 평문 금지 | — | 저장소 검사 |

## 4. 결정·오픈 이슈

| 항목 | 상태 | 비고 |
| --- | --- | --- |
| D-6 Shield(Platform Encryption, Field Audit Trail) 구매 범위 | 결정 대기 | S-9 대상 필드는 결정 후 |
| 중국 공장 데이터 국외 이전(PIPL·데이터 보안법) | 오픈 | 중국 사용자 개인정보 처리 방식 |
| Salesforce·Snowflake·MuleSoft TISAX 레이블 보유 여부 | 오픈 | 공급사 확인 |
