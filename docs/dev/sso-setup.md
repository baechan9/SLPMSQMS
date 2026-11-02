# 포털 SSO 설정 절차(CMN-00-TDO-002)

Salesforce = SAML 2.0 Service Provider(SP), 사내 포털 = Identity Provider(IdP). 사용자 매칭은 어설션 NameID = `User.FederationIdentifier` = 사번이다. 이 문서는 SIT·운영 Org에 SSO를 붙이는 순서와 확인 방법을 정리한다. 보안 기준선은 [docs/security/baseline.md](../security/baseline.md) S-2·S-3을 따른다.

## 1. 저장소에 있는 것과 없는 것

| 구분 | 위치 | 비고 |
| --- | --- | --- |
| JIT 핸들러 | `CMN_SamlJitHandler` | 사용자를 만들지 않고(BR-3) 어설션 속성 `lang`으로 표시 언어만 갱신(I18N-001 BR-2) |
| 매칭 키 맞춤 | `CMN_SsoService.alignFederationId`(사용자 트리거) | 사번이 있는 사용자는 FederationIdentifier = 사번. 사번 없는 비상용 관리자·통합 사용자는 그대로 |
| 권한 없음 안내 | Visualforce `CMN_SsoNoAccess`(`?lang=ko`/`en_US`/`zh_CN`) | SAML 사용자 지정 오류 URL. 공개 사이트로 노출해야 한다(3절) |
| SP SAML 설정 | 저장소에 두지 않음 | IdP 인증서·엔드포인트가 환경마다 다르다. `scripts/org/sso-sp-config.py`가 IdP 메타데이터로 만들어 배포 |
| My Domain 정책 | `settings/MyDomain.settings-meta.xml` | login.salesforce.com 로그인 차단(SEC-004) |

## 2. 순서

1. **IdP 메타데이터 받기**: 포털 담당에게 SAML 2.0 IdP 메타데이터 XML(entityID, SingleSignOnService, 서명 인증서)을 받는다. 어설션 NameID = 사번, 속성 `lang`(포털 언어 코드)을 요청한다.
2. **SP 설정 배포**:
   ```bash
   python3 scripts/org/sso-sp-config.py <alias> <idp-metadata.xml> --name CMN_PortalSso --error-url https://<공개 사이트>/CMN_SsoNoAccess
   ```
   - SP 요청 서명 인증서(`CMN_PortalSsoSp`, 자체 서명)가 없으면 만든다.
   - JIT 사용(`userProvisioning`), 핸들러 `CMN_SamlJitHandler`, 실행 사용자 = 배포한 관리자.
   - 출력되는 **ACS URL**(`https://<my-domain>?so=<OrgId15>`)과 **Entity ID**(My Domain URL)를 포털 담당에게 전달한다. IdP-initiated 바로가기("Workplace – QMS")는 이 ACS로 보내고 RelayState에 `/lightning/page/home`을 준다.
3. **로그인 페이지**: 설정 > 내 도메인 > 인증 구성 > 편집에서 인증 서비스로 이 SSO를 고르고 "로그인 양식"을 해제한다(BR-4, 모바일 앱도 같은 화면을 쓴다). 비상용 관리자 2명은 `https://<my-domain>/?login`으로 ID/PW + MFA 로그인한다.
4. **안내 페이지 공개**: `CMN_SsoNoAccess`를 공개 사이트(사이트 게스트 프로필에 페이지 접근 허용)로 노출하고 그 주소를 2단계 `--error-url`로 다시 배포한다. 포털(P4 SPP-001) 사이트가 생기면 그 사이트를 쓴다.
5. **매칭 키 확인**: `SELECT EmployeeNo__c, FederationIdentifier FROM User WHERE EmployeeNo__c != null`에서 두 값이 같다(HR 연계 INT-002가 사용자를 만들 때 트리거가 맞춘다).

## 3. 확인(수용 기준)

| AC | 방법 | 기대 |
| --- | --- | --- |
| AC-1 | 포털 로그인 상태에서 "Workplace – QMS" | 추가 로그인 없이 SL QMS 홈 |
| AC-2 | 로그아웃 상태에서 NCR 레코드 링크(메일) 클릭 → 포털 인증 | 그 NCR 레코드로 이동(RelayState 유지) |
| AC-3 | 비활성 사용자 또는 Salesforce에 없는 사번으로 SSO | 안내 페이지(`CMN_SsoNoAccess`) |

SAML 흐름 오류는 설정 > SAML Single Sign-On 설정 > "SAML 어설션 검증기"에서 마지막 실패 원인을 본다.

## 4. 테스트 IdP를 Salesforce Org로 만들 수 없는 이유(2026-11-02 확인)

- 스크래치 Org에서 IdP 인증서(`Certificate` 메타데이터, 자체 서명 생성)와 IdP 활성화(`IdentityProviderSettings`), IdP 메타데이터(`/.well-known/samlidp.xml`)는 만들 수 있다.
- 그러나 IdP 쪽에 SP를 등록할 **연결된 앱(SAML) 생성이 막혀 있다**("연결된 앱을 생성할 수 없습니다 … 고객 지원에 문의"). 신규 Org 기본 정책이다.
- 그래서 Scratch Org끼리 SAML 왕복은 할 수 없다. SP 설정이 배포되는 것까지(qms-dev-a, IdP = qms-spike 메타데이터)만 확인했고, AC-1~3은 포털 IdP(또는 연결된 앱을 만들 수 있는 Org)가 준비되면 SIT에서 확인한다.
