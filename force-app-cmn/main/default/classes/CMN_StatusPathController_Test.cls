/**
 * @description 상태 진행바 데이터 검증(CMN-00-UX-003 BR-1).
 * @group CMN-00-UX-003
 */
@IsTest
private class CMN_StatusPathController_Test {
  @IsTest
  static void test_BR1_stepsInOrderWithUserLanguageLabels() {
    // Given: 테스트 대상 객체 흐름(라벨 키 지정)
    Id recordId = fakeId(CMN_TestRecord__c.SObjectType);

    // When
    CMN_StatusPathController.Path p = CMN_StatusPathController.getPath(
      recordId
    );

    // Then: 순서대로, 라벨은 사용자 언어 Custom Label, 종료 단계 표시
    Assert.areEqual('Status__c', p.statusField);
    List<String> values = new List<String>();
    for (CMN_StatusPathController.Step s : p.steps) {
      values.add(s.value);
    }
    Assert.areEqual(
      new List<String>{ 'DRAFT', 'IN_PROGRESS', 'DONE', 'CANCELLED' },
      values
    );
    Assert.areEqual(Label.CMN_Status_InProgress, p.steps[1].label);
    Assert.isFalse(p.steps[1].isTerminal);
    Assert.isTrue(p.steps[2].isTerminal);
  }

  @IsTest
  static void test_BR1_picklistLabelWhenNoLabelKey() {
    // Given: 결재 요청 흐름(라벨 키 없음 → 선택 목록 라벨)
    Map<String, String> picklist = new Map<String, String>();
    for (
      Schema.PicklistEntry e : CMN_ApprovalRequest__c.Status__c.getDescribe()
        .getPicklistValues()
    ) {
      picklist.put(e.getValue(), e.getLabel());
    }

    // When
    CMN_StatusPathController.Path p = CMN_StatusPathController.getPath(
      fakeId(CMN_ApprovalRequest__c.SObjectType)
    );

    // Then
    Assert.areEqual(5, p.steps.size());
    Assert.areEqual(picklist.get('APPROVED'), p.steps[2].label);
  }

  @IsTest
  static void test_notConfiguredAndInvalidInput() {
    // 설정 없는 객체는 null, Id 없음은 입력 오류
    Assert.isNull(CMN_StatusPathController.getPath(UserInfo.getUserId()));
    try {
      CMN_StatusPathController.getPath(null);
      Assert.fail('입력 오류');
    } catch (AuraHandledException e) {
      Assert.areEqual(Label.CMN_Common_InvalidInput, e.getMessage());
    }
  }

  private static Id fakeId(Schema.SObjectType t) {
    return Id.valueOf(
      t.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix() +
      '000000000001'
    );
  }
}
