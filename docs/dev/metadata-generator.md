# 메타데이터 생성기(metagen)

객체·필드·번역·권한 셋 메타데이터는 손으로 쓰지 않고 `meta-src/`의 JSON 정의로 만든다. WI 완료 조건(Vol.0 3.3)이 모든 객체·필드·선택 목록 값의 ko·en_US·zh_CN 번역과 Permission Set 반영을 요구하는데, 수백 개 필드를 XML로 직접 쓰면 누락과 형식 오류가 생기기 때문이다.

```bash
python3 scripts/dev/metagen.py           # meta-src 전체 → force-app-*/ 생성
python3 scripts/dev/metagen.py --check   # 생성 결과가 저장소와 같은지(CI)
scripts/dev/wi-check.sh <테스트 클래스>   # 생성·포맷·린트·분석·배포·테스트·커버리지 한 번에
```

## 규칙

- 생성기가 쓰는 폴더(`objects/`, `objectTranslations/`, `labels/`, `permissionsets/`, `permissionsetgroups/`, `applications/`, `layouts/`, `translations/`, `customMetadata/`, `tabs/`)는 손으로 고치지 않는다. 프로필(`profiles/`)은 `scripts/dev/profile-lockdown.py`가 만든다(`docs/dev/persona-psg.md`). 정의 JSON을 고치고 다시 실행한다. Prettier도 이 폴더는 건드리지 않는다(`.prettierignore`).
- Org 기본 언어가 ko라서 정의의 `"ko"` 값이 기본 라벨이 되고, `en_US`·`zh_CN`은 번역 파일로 간다.
- 조직 전체 번역 파일(`translations/{lang}.translation-meta.xml`)은 언어마다 하나라 `force-app-cmn`에 모은다(패키지마다 두면 배포가 충돌한다).
- 권한 셋의 필드 권한은 정의에서 자동으로 만든다. 필수·주종 필드는 넣지 않고(넣으면 배포 오류), 수식·롤업은 읽기 전용, `"serviceOnly": true` 필드(상태처럼 서비스로만 바꾸는 필드)는 읽기 전용이다.
- Apex 클래스·트리거 메타 파일은 `scripts/dev/ensure-meta.sh`가 만든다.
- 페이지 레이아웃(`layouts/`)은 객체마다 Org가 자동으로 만드는 `{라벨} 레이아웃`과 같은 이름으로 만들어 덮어쓴다(프로필별 레이아웃 할당이 필요 없게). 정의의 `layout.columns`·`layout.relatedLists`로 바꿀 수 있고 `"layout": false`면 만들지 않는다. 필수·주종 필드는 Required, 서비스 전용·수식은 Readonly.
- `trackHistory`는 객체 정의에 `enableHistory: true`가 있을 때만 켠다.

## 정의 파일

| 위치 | 종류 | 핵심 키 |
| --- | --- | --- |
| `meta-src/{cmn,qms,pms}/<객체>.json` | 객체 | `object`, `package`, `kind`(object·mdt·event·setting), `label`, `plural`, `nameField`, `sharingModel`, `fields`, `recordTypes`, `validationRules`, `tab`, `records`(mdt) |
| `meta-src/**/permissionsets/<이름>.json` | 권한 셋 | `permissionSet.objects`(read·edit·edit-delete·viewall·admin, 표준 객체 필드만 줄 때 fields-read·fields-edit), `tabs`, `classes`, `customPermissions`, `apps`, `readOnlyFields`, `editableFields`(서비스 전용 필드 중 이 권한 셋에만 쓰기를 여는 필드, 예: 통합 사용자 외부 키), `allObjectFields`(true면 정의된 모든 객체·필드 편집 — `CMN_PS_DataMigration` 전용) |
| `meta-src/**/labels/<WI>.json` | Custom Label | `labels[].name`, `value{ko,en_US,zh_CN}`, `category` |
| `meta-src/**/permissionsetgroups/<이름>.json` | 권한 셋 그룹 | `permissionSetGroup.permissionSets`(기능 WI가 자기 PS 이름을 더한다) |
| `meta-src/cmn/applications/<이름>.json` | Lightning 앱 | `application.label`(문자열 또는 언어별), `tabs`, `headerColor`. 앱 라벨 번역은 조직 번역 파일로 간다 |
| 표준 객체(Account·User 등) | 필드만 | `"standard": true` — 객체 파일은 만들지 않고 필드·레코드타입·번역만 |

필드 `type`: Text, LongTextArea, Html, Number, Currency, Percent, Checkbox, Date, DateTime, Email, Phone, Url, Picklist, MultiselectPicklist, Lookup, MasterDetail, Formula(`returnType`), Summary, MetadataRelationship(Custom Metadata 간 관계: `referenceTo`·`relationshipName`, 레코드 값은 상대 DeveloperName). 객체 `listViews: [{name, label, columns, filters: [{field, operation, value}], filterScope}]`는 리스트뷰를 만든다(라벨은 ko 값, 번역 없음). 선택 목록 값은 `values: [{"api": "...", "label": {"ko": ..., "en_US": ..., "zh_CN": ...}}]`.
