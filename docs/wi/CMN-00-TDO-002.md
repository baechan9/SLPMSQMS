# CMN-00-TDO-002 완료 보고 — 포탈 SSO

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-TDO-002 (vol0-cmn-common.md CMN-00-TDO-002) |
| Wave / 공수(계획 → 실제) | W0 / 3 M/D → 약 0.5 M/D |
| 완료일 | 2026-11-02(Salesforce SP 측) |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 중(SP 측 완료, AC-1~3 SAML 왕복은 포털 IdP 준비 후 SIT) |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의) |

## 1. AC 결과

| AC | 확인 | 결과 |
| --- | --- | --- |
| AC-1 포털 로그인 상태에서 Workplace–QMS → 추가 로그인 없이 홈 | SP 설정(`SamlSsoConfig`, JIT, FederationId 매칭)이 qms-dev-a에 배포됨(IdP = qms-spike 메타데이터로 검증). SAML 왕복은 IdP 쪽 연결된 앱 생성이 스크래치 Org에서 막혀 확인 불가 | 대기(SIT) |
| AC-2 미로그인 NCR 링크 → 포털 인증 후 그 NCR | RelayState 유지는 플랫폼 SP-initiated 동작, 로그인 페이지 인증 서비스 설정 필요(절차 3단계) | 대기(SIT) |
| AC-3 퇴사자(비활성 User) SSO → 안내 페이지 | 서버 측: 매칭 사용자가 없으면 JIT가 사용자를 만들지 않고 실패(`test_AC03_unknownFederationIdIsNotProvisioned`), 비활성 사용자는 플랫폼이 로그인 거부 → 사용자 지정 오류 URL = `CMN_SsoNoAccess`(3개 언어). 페이지 공개(사이트)는 P4·SIT | 서버 측 통과, 화면 대기 |
| BR-1 FederationIdentifier = 사번 | `CMN_SsoService_Test.test_BR1_federationIdFollowsEmployeeNo`(생성·사번 변경 따라감, 사번 없는 사용자 유지). qms-dev-a 데모 사용자 5명 정렬 확인 | 통과 |

## 2. 구현 내역

- Apex: `CMN_SsoService.alignFederationId`(사용자 트리거 before insert·update에서 호출), JIT 핸들러는 I18N-001의 `CMN_SamlJitHandler` 그대로 사용(BR-3과 일치).
- Visualforce `CMN_SsoNoAccess`(공개 안내, `?lang=`으로 언어), 라벨 3개.
- 스크립트 `scripts/org/sso-sp-config.py <alias> <idp-metadata.xml> [--name] [--error-url] [--dry-run]`: IdP 메타데이터에서 SamlSsoConfig를 만들어 mdapi 형식으로 배포(소스 추적 영향 없음), SP 요청 서명 인증서 자동 생성, JIT 핸들러·실행 사용자 Id 지정, ACS URL 출력.
- 문서 `docs/dev/sso-setup.md`(순서·확인 방법·테스트 IdP 제약).
- 확인 기록: qms-spike에 IdP 인증서(`CMN_TestIdp`)·IdP 활성화 배포 → IdP 메타데이터 다운로드 → qms-dev-a에 `CMN_TestIdpSso` 배포 성공(Issuer = qms-spike, JIT 사용, 핸들러 지정).
- 핵심 설계 판단
  1. **SP 설정은 저장소 밖**: IdP 인증서·URL이 환경마다 달라 메타데이터로 커밋하지 않고 스크립트로 만든다. 저장소에는 재현 절차만 둔다.
  2. **매칭 키는 트리거가 보장**: HR 연계(INT-002)·관리자 수동 생성·데모 적재 어디서 사용자를 만들어도 FederationIdentifier = 사번이 되도록 했다(BR-1의 "INT-002가 세팅"을 트리거로 일원화).
  3. **비활성·미등록 사용자 처리**: 비활성 사용자는 플랫폼이 SAML 로그인을 거부하고, 미등록 사번은 JIT가 사용자 생성을 거부한다. 둘 다 SAML 사용자 지정 오류 URL로 가므로 안내 페이지 하나로 AC-3을 처리한다.

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| Apex 테스트 | CMN_SsoService_Test 2건, CMN_LanguageService_Test(JIT) 통과 |
| 커버리지 | CMN_SsoService 100% |
| Code Analyzer(심각도 1~2) | 0건 |

## 4. 보안 점검

- [x] JIT는 사용자를 만들지 않는다(권한 부여는 HR 연계·관리자만)
- [x] 인증서는 Org에서 생성(개인 키 내보내기 불가), 저장소에 인증서·키 없음
- [x] 안내 페이지는 정적 문구만(입력 반영 없음, `lang`은 언어 선택에만 사용)
- [ ] `/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 명세 차이 | FederationIdentifier 설정 주체: INT-002 → 사용자 트리거(모든 생성 경로) | 명세 보완 요청 |
| 플랫폼 제약 | 스크래치 Org에서 연결된 앱(SAML) 생성 불가 → Org끼리 테스트 IdP 구성 불가(개발 플랜 8.x "SSO 테스트 IdP 연결" 확인 결과) | SIT에서 포털 IdP로 AC 확인. 개발 플랜 위험 항목 갱신 |
| 대기 | 안내 페이지 공개 사이트, 로그인 페이지 인증 서비스 선택(로그인 양식 해제) | P4 SPP-001 사이트 또는 SIT 설정 |
| 오픈 이슈 | 포털 IdP 제품·SAML 지원 여부(OIDC만이면 Auth Provider 방식), 어설션 속성 목록 | 포털 담당 확인 |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch), 테스트 IdP 메타데이터: `qms-spike`(Scratch)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-TDO-002] SSO 매칭 키·권한 없음 안내·SP 설정 스크립트`
