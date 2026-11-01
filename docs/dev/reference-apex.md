# Apex 참조 (예시·한도)

`.claude/rules/sf-dev.md` 3~5절의 규칙을 코드로 보여준다. 이름은 예시이며 실제 이름은 WI 명세를 따른다.

## 1. 트리거와 핸들러

```apex
// 트리거: 객체당 1개, 본문 한 줄 (ARC-002 BR-1)
trigger QMS_IqcLotTrigger on QMS_IqcLot__c (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    new QMS_IqcLotTriggerHandler().run();
}
```

```apex
/**
 * @description 검사 로트 트리거 핸들러. 채번·초기화만 위임하고 규칙은 서비스에 둔다.
 * @group QMS-03-IQC-002
 */
public with sharing class QMS_IqcLotTriggerHandler extends CMN_TriggerHandler {
    public override void beforeInsert() {
        CMN_NumberingService.assign(Trigger.new);
    }
    public override void afterInsert() {
        QMS_IqcLotService.initialize((List<QMS_IqcLot__c>) Trigger.new);
    }
}
```

## 2. 서비스·셀렉터와 사용자 모드

```apex
public with sharing class QMS_IqcLotSelector {
    // 조회는 셀렉터 한곳에. 정적 SOQL은 USER_MODE.
    public static List<QMS_IqcLot__c> byIds(Set<Id> ids) {
        return [
            SELECT Id, RecordNo__c, Status__c, Plant__c, SupplierItem__c
            FROM QMS_IqcLot__c
            WHERE Id IN :ids
            WITH USER_MODE
        ];
    }

    // 동적 조건이 필요하면 바인드 맵 + AccessLevel. 정렬 필드는 허용 목록으로 검증.
    private static final Set<String> SORTABLE = new Set<String>{ 'DueAt__c', 'GrDate__c' };

    public static List<QMS_IqcLot__c> queue(Id plantId, String sortField, Integer limitRows) {
        String orderBy = SORTABLE.contains(sortField) ? sortField : 'DueAt__c';
        String soql =
            'SELECT Id, RecordNo__c, DueAt__c FROM QMS_IqcLot__c ' +
            'WHERE Plant__c = :plantId AND Status__c IN :openStatuses ' +
            'ORDER BY ' + orderBy + ' LIMIT :limitRows';
        return Database.queryWithBinds(
            soql,
            new Map<String, Object>{
                'plantId' => plantId,
                'openStatuses' => new List<String>{ 'WAITING', 'IN_INSPECTION' },
                'limitRows' => limitRows
            },
            AccessLevel.USER_MODE
        );
    }
}
```

```apex
// 사용자 입력에서 비롯된 저장은 사용자 모드 DML
update as user lotsToUpdate;
// 또는
Database.SaveResult[] results = Database.update(lotsToUpdate, false, AccessLevel.USER_MODE);
```

시스템 모드가 필요한 곳(트리거 후처리, 이벤트 구독, 배치)은 의도를 드러낸다.

```apex
List<CMN_SupplierItem__c> items = [
    SELECT Id, InspectionLevel__c FROM CMN_SupplierItem__c WHERE Id IN :ids WITH SYSTEM_MODE
];
```

## 3. 화면 컨트롤러와 오류 처리

```apex
public with sharing class QMS_IqcInspectionController {
    /**
     * @description 로트 판정. 입력을 서버에서 다시 검증하고, 사용자에게는 라벨 문구만 보낸다.
     * @param lotId 검사 로트 Id
     * @param decision ACCEPT 또는 REJECT
     * @return 판정 후 로트 요약 DTO
     * @throws AuraHandledException 검증 실패·권한 없음·예상하지 못한 오류
     */
    @AuraEnabled
    public static QMS_IqcLotDto decide(Id lotId, String decision, Id defectTypeId, String reason) {
        try {
            if (lotId == null || !new Set<String>{ 'ACCEPT', 'REJECT' }.contains(decision)) {
                throw new QMS_ValidationException(System.Label.QMS_Common_InvalidInput);
            }
            return QMS_IqcLotService.decide(lotId, decision, defectTypeId, reason);
        } catch (QMS_ValidationException e) {
            throw newAuraException(e.getMessage()); // 이미 라벨 문구
        } catch (Exception e) {
            CMN_Logger.error('QMS_IqcInspectionController.decide', e.getMessage(), lotId, e);
            throw newAuraException(System.Label.CMN_Common_UnexpectedError);
        }
    }

    private static AuraHandledException newAuraException(String msg) {
        AuraHandledException ex = new AuraHandledException(msg);
        ex.setMessage(msg); // 테스트에서 getMessage()로 확인 가능하게
        return ex;
    }
}
```

## 4. 비동기

```apex
// 콜아웃·체인 작업: Queueable + Finalizer로 실패 후처리
public with sharing class QMS_MsaCalcJob implements Queueable, Database.AllowsCallouts {
    private final Id studyId;
    public QMS_MsaCalcJob(Id studyId) { this.studyId = studyId; }

    public void execute(QueueableContext ctx) {
        System.attachFinalizer(new QMS_MsaCalcFinalizer(studyId));
        QMS_MsaService.calculate(studyId); // DWH-004 PROCEDURE 호출
    }
}

public with sharing class QMS_MsaCalcFinalizer implements Finalizer {
    private final Id studyId;
    public QMS_MsaCalcFinalizer(Id studyId) { this.studyId = studyId; }
    public void execute(FinalizerContext ctx) {
        if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
            QMS_MsaService.markCalcFailed(studyId, ctx.getException()?.getMessage());
        }
    }
}
```

```apex
// 화면에서 5초 넘게 걸릴 수 있는 조회: Continuation
@AuraEnabled(continuation=true cacheable=true)
public static Object startQuery(String queryKey, String paramsJson) {
    Continuation con = new Continuation(60);
    con.continuationMethod = 'finishQuery';
    con.addHttpRequest(CMN_DwQueryService.buildRequest(queryKey, paramsJson));
    return con;
}
```

## 5. 거버너 한도 전체(요약표에 없는 것)

| 항목 | 동기 | 비동기 |
| --- | --- | --- |
| SOQL 쿼리 수 | 100 | 200 |
| SOQL 조회 행 | 50,000 | 50,000 |
| SOSL 쿼리 수 | 20 | 20 |
| DML 문 / 처리 행 | 150 / 10,000 | 150 / 10,000 |
| CPU 시간 | 10,000ms | 60,000ms |
| 힙 | 6MB | 12MB |
| 콜아웃 수 / 누적 대기 시간 | 100 / 120초 | 100 / 120초 |
| 트랜잭션당 Queueable 추가 | 50 | 1 |
| 이벤트 발행(즉시) | 150 문(DML 문 한도 공유) | 150 |
| 이메일 단건 발송 호출 | 10 | 10 |
| 5초 넘는 동기 요청 동시 실행(조직) | 10 | — |

대량 처리 기준: 5만 건 이상은 Batch Apex, 그 이하 반복 작업은 Queueable 체인.
