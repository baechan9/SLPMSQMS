### {SYS}-{MENU}-{FUNC}-{nnn} {제목}

추적 {Q-## / P-## / NFR-x.x} · {필수|권장} · {W0|W1|W2|W3} · {SF, EXP, SNOW, MULE, DC, AF} · {DM, CFG, APEX, LWC, FLOW, INT, SQL, SNOWPARK, AGENT, DOC} · {OOTB|Tailoring|Customization} · 선행 {WI 목록 또는 없음} · {n} M/D

**목적**: 왜 필요한가. 자동차 품질/PM 도메인 맥락 1~3문장.

**범위** In: 이 WI가 만드는 것. Out: 다른 WI로 넘기는 것(WI ID 명시).

**데이터 모델**

| 객체 / 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| QMS_Xxx__c.FieldName__c | Text(80) | Y | |

**비즈니스 규칙**

- BR-1: 검증·상태 전이·계산식. 숫자·기한·권한을 구체적으로.

**화면/UX**: LWC 이름, 배치 위치, 모바일 여부.

**권한**: 어떤 Permission Set이 무엇을 할 수 있는가.

**수용 기준**

- AC-1: Given …, When …, Then ….

**에이전트 주의**: 흔한 오해, 하지 말아야 할 구현.

**오픈 이슈**: SL 확인 필요 항목.

<!-- 규칙: 메타 라인은 정확히 8개 항목을 " · "로 구분(scripts/build_index.py가 파싱). 표 셀 안에 | 금지. -->
