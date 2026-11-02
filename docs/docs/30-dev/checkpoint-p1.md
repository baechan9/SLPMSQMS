# 개발 중단점 p1 — 2026-11-02

이 문서는 개발을 멈춘 지점과 다시 시작하는 방법을 기록한다. **"중단점 p1"은 페이즈 P1(공통 프레임워크·기준정보)과 다른 것이다.** 이 중단점 이후의 개발 순서는 [화면 우선 개발 플랜](screen-first-plan.md)을 따른다.

## 1. 요약

| 항목 | 값 |
| --- | --- |
| 중단 일시 | 2026-11-02 |
| 중단 사유 | 개발 전략 변경 요청: 프로토타입·화면 개발을 먼저 하고, 1차 화면 검토·승인 후 상세 기능을 개발한다 |
| Git 브랜치 | `p3/cmn-extension` |
| 마지막 커밋 | `a28cd30` `[CMN-00-APV-003] 결재선 편집·상신, 처리, 이력, 결재 현황 화면` |
| 작업 트리 | CMN-00-DSH-001 작업 중 파일이 **커밋되지 않은 채** 남아 있다(3절) |
| 원격 push | 하지 않음. `main`, `p0/setup`, `p1/cmn-foundation`, `p2/cmn-security-services`, `p3/cmn-extension` 모두 로컬에만 있다 |
| 개발 Org | `qms-dev-a`(Scratch, Dev Hub LSPMSQMS, **2026-11-22 만료**). APV-003까지 배포됨 |

## 2. 완료 범위

| 페이즈 | 상태 | 내용 |
| --- | --- | --- |
| P0 착수 준비 | 거의 완료 | ARC-001 개발 중: GitHub CI 실제 실행(AC-2)과 Snowflake 부분(AC-3)만 남음 |
| P1 공통 프레임워크·기준정보 | 완료(게이트 통과) | 12건 개발 완료 |
| P2 보안·공통 서비스·연계 기반 | 완료(조건부 게이트 통과) | 결재·To-Do·알림·문서·코멘트·공유 등. SEC-004·INT-001·TDO-002·INT-002·INT-003은 외부 트랙·SIT 잔여로 "개발 중" |
| P3 공통 확장 | 진행 중(16건 중 5건 완료) | 완료: APV-004 대리결재, APV-005 결재 독촉, MTG-001 회의, UX-001 모바일, APV-003 결재 UI. 작업 중: DSH-001 위젯 보드. 대기: TDO-004, TDO-003, DWH-003, DWH-004, AI-001, AI-004, DWH-002(외부), QMS-09-INT-001·002·003 |

WI별 상태와 보고서 링크는 `docs/docs/20-status/DEV-STATUS.md`, 완료 보고는 `docs/wi/{WI-ID}.md`에 있다.

## 3. 작업 중이던 WI: CMN-00-DSH-001 위젯 대시보드 프레임워크

### 3.1 만든 것(커밋 안 됨)

| 구분 | 파일 | 상태 |
| --- | --- | --- |
| 메타데이터 정의 | `meta-src/cmn/CMN_Widget__mdt.json`(ConfigSchema·AvailableSystems·MobileSupported·IsActive 포함, 샘플 위젯 2건), `CMN_DashboardTemplate__mdt.json`(Persona 10종, PermissionSetGroups·Priority·IsDefault, 템플릿 3건), `CMN_DashboardTemplateItem__mdt.json`(항목 6건), `CMN_DashboardResolver__mdt.json`(TEMPLATE_RESOLVER·CONFIG_VALIDATOR 등록), `CMN_UserDashboard__c.json`(UniqueKey = 사용자Id:시스템) | 작성·생성기 실행 완료, 배포 전 |
| 권한 | `meta-src/cmn/permissionsets/CMN_PS_Dashboard_User.json`, 사내 PSG 14개에 추가(협력사 포털 PSG 제외) | 생성 완료, 배포 전 |
| 라벨 | `meta-src/cmn/labels/CMN-00-DSH-001.json` 47개(ko·en_US·zh_CN) | 생성 완료, 배포 전 |
| Apex | `CMN_DashboardTemplateResolver`, `CMN_WidgetConfigValidator`(인터페이스), `CMN_DashboardSelector`, `CMN_DashboardService`, `CMN_DashboardController`, `CMN_CoreWidgetController` | 작성만 함. **컴파일·배포·테스트 전**, `.cls-meta.xml` 없음 |
| 생성 산출물 | `force-app-cmn/.../objects/CMN_Widget__mdt` 등 5개 객체, customMetadata 11건, 레이아웃·번역, PSG 수정 | 생성기 출력 |

### 3.2 다시 시작할 때 먼저 고칠 것

- `CMN_CoreWidgetController.todoSummary`의 집계 SOQL: 공장 조건이 자리표시(`Plant__c = :plantId OR Plant__c != NULL OR Plant__c = NULL`)로 남아 있어 필터가 동작하지 않고 `WITH USER_MODE`도 빠져 있다. `approvalSummary`처럼 `Database.queryWithBinds(..., AccessLevel.USER_MODE)`로 바꾸고 plantId가 있을 때만 조건을 붙인다.
- 같은 클래스 `Filter`의 `(String) String.valueOf(...)` 중복 변환 정리.
- `.cls-meta.xml` 6개 추가(`CMN_ApprovalWriter.cls-meta.xml` 복사).

### 3.3 남은 일

1. LWC: `cmnWidgetBoard`(12열 그리드 S4·M6·L12, 모바일 12열, 편집 모드 — 추가·제거·순서·크기·설정 JSON, 공통 필터 공장·기간 BR-6, 템플릿 초기화), `cmnWidgetFrame`(`lwc:is` 동적 로드, Intersection Observer 지연 로드, `errorCallback`으로 위젯 단위 오류 격리 AC-3, 권한 없음·사용 불가 자리표시 BR-2), 샘플 위젯 `cmnWidgetTodoSummary`, `cmnWidgetApprovalPending` + Jest.
2. Apex 테스트: `CMN_DashboardService_Test`(AC-1 PSG별 템플릿 복사, AC-2 저장 후 재조회 동일, BR-2 권한 잃은 위젯 유지·새 추가 거부, 확장 해석기·검증기 — `widgetsOverride`·`templatesOverride`·`templateItemsOverride`·`extensionsOverride` 사용, mdt 테스트 값은 `JSON.deserialize`로 만든다), `CMN_CoreWidgetController_Test`.
3. `scripts/dev/wi-check.sh CMN_DashboardService_Test,CMN_CoreWidgetController_Test` → 보고서 `docs/wi/CMN-00-DSH-001.md` → DEV-STATUS → 커밋.
4. 화면 우선 플랜에서 DSH-001은 A0 묶음의 첫 항목이다(위젯 화면 전체의 틀). 위 1~3을 그대로 마친다.

## 4. Org 상태

| Org | 만료 | 상태 |
| --- | --- | --- |
| `qms-dev-a` | 2026-11-22 | APV-003까지 배포. DeploymentSettings `doesSkipAsyncApexValidation` 적용(예약 잡이 걸린 클래스 재배포 허용). 예약 잡 `CMN_ApprovalReminderJob`(매시), `CMN_ActionItemReminderJob`(매일 9시). P3 데모 데이터 적재(코드 그룹 16, 코드 157, 위임 1). 디버그 TraceFlag `CMN_Probe`(30분 만료, 남아 있어도 무해) |
| `qms-int` | 2026-12-01 | P2 게이트 Org. APV-003 이후 변경은 배포 안 됨 |
| `qms-ci` | 2026-12-01 | CI 검증용(시크릿 `SF_AUTH_URL_CI`는 사용자 등록 대기) |
| `qms-spike` | 2026-11-04 | 스파이크용(IdP 인증서). 곧 만료 |
| `scratchOrg` | 2026-12-01 | 초기 Org, 사용 안 함 |

## 5. 다시 시작하는 방법

```bash
git checkout p3/cmn-extension
git status                      # 3.1의 미커밋 파일 확인
python3 scripts/dev/metagen.py  # 생성 산출물 최신 확인
# 3.2 수정 → 3.3 순서로 DSH-001 완료
scripts/dev/wi-check.sh CMN_DashboardService_Test,CMN_CoreWidgetController_Test
```

- `qms-dev-a`가 만료됐으면 `scripts/org/build-scratch.sh qms-dev-a --phase 3`으로 새로 만든다(DeploymentSettings는 Scratch 정의에 들어 있다).
- 그 다음은 [화면 우선 개발 플랜](screen-first-plan.md) 5절 A0 묶음 순서로 진행한다. 기존 페이즈 문서(`p03`~`p13`)는 B단계(상세 기능)의 순서·게이트로 계속 쓴다.

## 6. 사용자 확인·조치 대기

- 브랜치 push, `main` 보호 규칙, GitHub 시크릿 `SF_AUTH_URL_CI` 등록.
- 화면 확인 항목: 앱 런처·언어 전환·코드 선택·코멘트·상태 진행바·문서·회의 패널 배치, 60MB 업로드, 모바일 실기기(사진·바코드·결재 처리), 결재 현황 탭·결재 요청 레코드 페이지, login.salesforce.com 차단.
- SSO SAML 왕복은 SIT(포털 IdP)에서.
- 화면 우선 플랜의 결정 항목 SF-1~SF-7(플랜 9절).
