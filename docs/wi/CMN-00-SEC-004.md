# CMN-00-SEC-004 완료 보고 — 인증·암호화·플랫폼 보안 설정

| 항목 | 값 |
| --- | --- |
| WI | CMN-00-SEC-004 (vol0-cmn-common.md CMN-00-SEC-004) |
| Wave / 공수(계획 → 실제) | W0 / 3 M/D → 약 0.3 M/D |
| 완료일 | 2026-11-02(Salesforce 설정·근거 문서). AC-1 화면 확인·AC-2는 대기 |
| 구현 | Claude Code(에이전트) |
| 상태 | 개발 중(Salesforce 부분 완료, AC-1 화면 확인은 TDO-002 테스트 IdP 연결 후, AC-2는 외부 트랙) |
| 명세 상태 | 검토 전 명세(2026-11-02 착수 동의), review-pack 변경 요청 2건 반영(Vol.6a ROLE_QMS_COST·NCR 비용 마스킹, Vol.9 Mule 통합 사용자 3개·ROLE_INGEST VIN 제한) — 근거 문서에 기록 |

## 1. AC 결과

| AC | 확인 | 결과 |
| --- | --- | --- |
| AC-1 일반 사용자 login.salesforce.com ID/PW 로그인 → 거부 | `MyDomain.settings-meta.xml`(`canOnlyLoginWithMyDomainUrl`) 배포·조회 확인. API(SOAP login)로는 판정 불가: login.salesforce.com `INVALID_LOGIN`(스크래치 사용자는 sandbox 로그인 서버), test.salesforce.com·My Domain `INVALID_OPERATION`(신규 Org SOAP login() 비활성) | 설정 완료, 화면 확인 대기(qms-int, TDO-002 이후) |
| AC-2 마스킹 대상 컬럼을 ROLE_QMS_ANALYST로 조회 → 마스킹 값 | 마스킹 정책 SQL을 근거 문서 2절에 작성(MP_COST_NUMBER·MP_NCR_COST_NUMBER·MP_VIN). 적용은 DWH-001 스키마 확정 후 외부 트랙 | 대기(외부 트랙) |
| AC-3 `docs/security/baseline.md`에 항목별 설정 화면 경로 | 작성: Salesforce 13항목(값·적용 방법·화면 경로·확인 방법), 적용·확인 기록, Snowflake 7항목 + SQL, MuleSoft 5항목, 결정·오픈 이슈 | 통과 |

## 2. 구현 내역

- 메타데이터
  - `force-app-cmn/main/default/settings/Security.settings-meta.xml`: 세션 시간 제한 2시간, 세션 IP 고정 해제.
  - `force-app-cmn/main/default/settings/MyDomain.settings-meta.xml`: login.salesforce.com 로그인 차단(My Domain URL로만).
- 문서: `docs/security/baseline.md`(AC-3).
- 확인: qms-dev-a 배포 후 `Settings:Security`·`Settings:MyDomain` 조회로 값 확인. CLI(새로 고침 토큰)와 dry-run은 설정 후에도 정상.
- 핵심 설계 판단
  1. **설정은 메타데이터로**: 메타데이터 API로 배포할 수 있는 항목(세션·My Domain 정책)은 저장소에 두어 모든 Org(Scratch·Sandbox·운영)에 같은 값이 가도록 했다. 설정 메타데이터는 넣은 항목만 바뀐다.
  2. **SSO 전용 로그인 페이지는 SSO 연결 뒤에**: My Domain 인증 구성에서 로그인 양식을 빼는 것은 SAML IdP 설정(TDO-002) 없이 하면 Scratch Org에 들어갈 수 없게 되므로 TDO-002에서 화면 설정으로 하고 근거 문서(S-3)에 경로를 남겼다.
  3. **API 로그인 차단(`doesApiLoginRequireOrgDomain`)은 넣지 않음**: CLI·CI 인증 흐름에 미치는 영향을 확인하지 못해 보류(운영 반영 전 SIT에서 확인).

## 3. 테스트·품질

| 항목 | 결과 |
| --- | --- |
| dry-run → 배포 | 성공(qms-dev-a) |
| 메타데이터 조회 확인 | `canOnlyLoginWithMyDomainUrl = true`, `sessionTimeout = TwoHours`, `lockSessionsToIp = false` |
| Apex·LWC | 해당 없음(설정 WI) |

## 4. 보안 점검

- [x] 비밀번호·키·IP 실값을 저장소에 두지 않음(Snowflake 네트워크 정책 IP는 자리 표시자)
- [x] AC-1 확인용으로 qms-dev-a 관리자 비밀번호를 생성했으나 화면·로그·파일에 남기지 않음
- [ ] `/security-review`: 페이즈 게이트에서 일괄 실행

## 5. 명세 차이·이슈·후속

| 구분 | 내용 | 조치 |
| --- | --- | --- |
| 미확인 | AC-1 화면 확인 | TDO-002(테스트 IdP) 후 qms-int에서 일반 사용자로 확인, 근거 문서 1.1절에 기록 |
| 외부 트랙 | AC-2 Snowflake 마스킹·네트워크 정책·Key-pair, MuleSoft 정책 | DWH-001·외부 트랙. SQL은 근거 문서 2절 |
| CR 반영(문서) | ROLE_QMS_COST·NCR 비용 마스킹(Vol.6a), Mule 통합 사용자 3개·ROLE_INGEST VIN 제한(Vol.9) | 근거 문서 W-5·W-6·S-10 |
| 보류 | API 로그인도 My Domain만 허용(`doesApiLoginRequireOrgDomain`) | SIT에서 CLI·Mule 영향 확인 후 결정 |
| 결정 대기 | D-6 Shield 범위, 중국 PIPL, TISAX 레이블 | review-pack |

## 6. 배포 정보

- 대상 Org: `qms-dev-a`(Scratch, LSPMSQMS)
- dry-run → 배포: 성공
- 커밋: `[CMN-00-SEC-004] 세션·My Domain 로그인 정책과 보안 기준선 문서`
