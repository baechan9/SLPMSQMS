# Snowflake 마이그레이션(QDW)

Snowflake DDL은 [schemachange](https://github.com/Snowflake-Labs/schemachange) 버전 스크립트로만 바꾼다. 수동 DDL은 금지한다(CMN-00-ARC-001 BR-4). 외부 트랙 담당이 운영한다(개발 플랜 3.4절).

| 경로 | 내용 |
| --- | --- |
| `schemachange-config.yml` | 공통 설정. 접속 정보는 환경 변수로만 받는다 |
| `migrations/V{nnn}__{설명}.sql` | 버전 스크립트. 번호는 건너뛰지 않고 늘린다. V001은 시작점, 스키마·역할·웨어하우스는 CMN-00-DWH-001이 V002부터 만든다 |

## 실행

```bash
pip install schemachange
export SNOWFLAKE_ACCOUNT=...  SNOWFLAKE_USER=...  SNOWFLAKE_ROLE=ROLE_DW_ADMIN  SNOWFLAKE_WAREHOUSE=WH_TRANSFORM
export SNOWFLAKE_PRIVATE_KEY_PATH=~/.snowflake/rsa_key.p8   # Key-pair 인증(비밀번호 금지, CMN-00-SEC-004)
export QDW_DATABASE=SL_QDW_DEV                              # TEST: SL_QDW_TEST, 운영: SL_QDW
schemachange deploy --config-folder snowflake
```

- 이력은 `{QDW_DATABASE}.PUBLIC.SCHEMACHANGE_HISTORY`에 남는다(ARC-001 AC-3).
- 키·비밀번호·계정 정보를 이 폴더나 저장소 어디에도 두지 않는다(ARC-001 BR-3). CI에서는 파이프라인 시크릿으로 넣는다.
- 같은 스크립트를 DEV에 적용한 뒤 TEST에 적용해 재현한다(CMN-00-DWH-001 AC-1).
