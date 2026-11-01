# 테스트 참조 (AC 매핑·데모 픽스처·목)

## 1. AC → 테스트 매핑 표(계획 단계에서 먼저 작성)

| AC | 테스트 클래스.메서드 | 종류 | 데이터 |
| --- | --- | --- | --- |
| AC-1 | QMS_IqcLotService_Test.test_AC01_sameExternalKeyUpsertsOnce | 단위 | 픽스처 S9 |
| AC-5 | QMS_IqcLotService_Test.test_AC05_bulk200WithinLimits | 벌크 | 생성 200건 |
| (권한) | QMS_IqcInspectionController_Test.test_permission_inspectorOnly | 권한 | runAs PSG |
| (음수) | QMS_IqcInspectionController_Test.test_negative_invalidDecision | 음수 | — |

계획에 이 표가 없으면 구현을 시작하지 않는다. 완료 보고서에 같은 표를 결과와 함께 다시 적는다.

## 2. 테스트 클래스 기본형

```apex
@IsTest
private class QMS_IqcLotService_Test {
    @TestSetup
    static void setup() {
        // 데모와 같은 키·값의 기준정보(정적 리소스 QMS_DemoFixtures)
        CMN_TestDataFactory.loadFixture('MASTER_CORE');
        CMN_TestDataFactory.loadFixture('S9_IQC_MIN');
    }

    @IsTest
    static void test_AC02_skipLevelAutoAccepts() {
        // Given: 무검사 수준 협력사 품번(데모 V10007 / P-ACT-01 / KR01)
        CMN_SupplierItem__c si = CMN_TestDataFactory.supplierItem('V10007-P-ACT-01-KR01');
        // When
        Test.startTest();
        QMS_IqcLot__c lot = CMN_TestDataFactory.newLot(si, 100);
        insert lot;
        Test.stopTest();
        // Then
        QMS_IqcLot__c saved = [SELECT Status__c, Decision__c, AutoAccepted__c FROM QMS_IqcLot__c WHERE Id = :lot.Id];
        Assert.areEqual('DECIDED', saved.Status__c, 'SKIP 로트는 즉시 판정');
        Assert.isTrue(saved.AutoAccepted__c, '자동 합격 표시');
    }

    @IsTest
    static void test_AC05_bulk200WithinLimits() {
        List<QMS_IqcLot__c> lots = CMN_TestDataFactory.newLots(200);
        Test.startTest();
        insert lots;
        Integer queries = Limits.getQueries();
        Test.stopTest();
        Assert.isTrue(queries < 20, '200건 처리 SOQL 수: ' + queries);
    }
}
```

## 3. 권한 테스트

```apex
@IsTest
static void test_permission_viewerCannotDecide() {
    User viewer = CMN_TestDataFactory.userWithPsg('QMS_PSG_Viewer', 'KR01');
    QMS_IqcLot__c lot = CMN_TestDataFactory.openLot();
    System.runAs(viewer) {
        try {
            QMS_IqcInspectionController.decide(lot.Id, 'ACCEPT', null, null);
            Assert.fail('조회 권한자는 판정할 수 없어야 한다');
        } catch (AuraHandledException e) {
            Assert.areEqual(System.Label.CMN_Common_NoPermission, e.getMessage());
        }
    }
}
```

## 4. 콜아웃 목(DWH 응답)

```apex
@IsTest
public class CMN_DwMock implements HttpCalloutMock {
    private final String resourceName; // 예: 'QMS_Mock_QMS_SPC_CHART_ok' (data/demo/mocks/dwh/QMS_SPC_CHART/ok.json을 배포한 정적 리소스)
    public CMN_DwMock(String resourceName) { this.resourceName = resourceName; }
    public HttpResponse respond(HttpRequest req) {
        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = :resourceName LIMIT 1];
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        res.setBody(sr.Body.toString());
        return res;
    }
}
// 사용: Test.setMock(HttpCalloutMock.class, new CMN_DwMock('QMS_Mock_QMS_SPC_CHART_ok'));
```

테스트용 목 정적 리소스는 테스트 전용 디렉터리(ARC-001 구성)에 두고, 운영 패키지에 포함할지는 ARC-001 결정을 따른다.

## 5. 골든 비교

- 통계(Cpk, %GRR 등): `Assert.isTrue(Math.abs(actual - expected) <= Math.abs(expected) * 1e-6)`. 기대값은 `data/demo/expected/*.json`의 키를 픽스처로 읽는다.
- 건수·코드: 정확히 일치.
- Snowflake 계산(SQL·Snowpark)은 Snowflake 쪽 테스트에서 같은 기대값 파일과 비교한다(Salesforce 테스트는 목 응답을 쓴다).

## 6. 실행 명령

```bash
# LWC
npm run test:unit -- --coverage
# Apex (Scratch Org)
sf apex run test -o <alias> -n QMS_IqcLotService_Test,QMS_IqcInspectionController_Test -c -r human -w 10
# 정적 분석
sf code-analyzer run --target force-app --rule-selector Recommended --severity-threshold 2
```
