/**
 * @description CMN_ApprovalEvent__e 구독: 결재 단계 To-Do를 열고 닫는다(CMN-00-TDO-001 BR-2).
 * - STEP_PENDING: 결재자 APPROVAL To-Do open(원천 = 결재 단계). 구독 시점에 이미 처리된 단계는 열지 않는다.
 * - STEP_DONE: 그 단계 To-Do close. APPROVED: 요청의 남은 To-Do close. REJECTED·RECALLED: 남은 To-Do cancel.
 * 이벤트는 요청 안에서 순서대로 쌓이므로(단계는 다시 열리지 않고 재상신은 새 요청) open → close → cancel 순으로 처리한다.
 * 대리인 To-Do(BR-2 "+유효 대리인")는 CMN-00-APV-004가 위임 정보로 추가한다. 닫기는 처리자 구분 없이 단계 전체라 대리인 To-Do도 함께 닫힌다.
 * @group CMN-00-TDO-001
 */
public with sharing class CMN_ApprovalEventTriggerHandler extends CMN_TriggerHandler {
  protected override void afterInsert() {
    Set<Id> pending = new Set<Id>();
    Set<Id> done = new Set<Id>();
    Set<Id> approved = new Set<Id>();
    Set<Id> stopped = new Set<Id>();
    for (CMN_ApprovalEvent__e e : (List<CMN_ApprovalEvent__e>) newRecords) {
      switch on e.EventType__c {
        when 'STEP_PENDING' {
          pending.add(e.StepId__c);
        }
        when 'STEP_DONE' {
          done.add(e.StepId__c);
        }
        when 'APPROVED' {
          approved.add(e.RequestId__c);
        }
        when 'REJECTED', 'RECALLED' {
          stopped.add(e.RequestId__c);
        }
      }
    }
    pending.remove(null);
    if (
      pending.isEmpty() &&
      done.isEmpty() &&
      approved.isEmpty() &&
      stopped.isEmpty()
    ) {
      return;
    }
    try {
      sync(pending, done, approved, stopped);
    } catch (Exception ex) {
      // 구독 실패가 결재 처리 자체를 되돌리지 않는다. 원문은 로그로 남기고 재처리는 운영자가 한다.
      CMN_Logger.error(
        'CMN_ApprovalEventTriggerHandler',
        ex.getMessage(),
        null,
        ex
      );
    }
  }

  private static void sync(
    Set<Id> pending,
    Set<Id> done,
    Set<Id> approved,
    Set<Id> stopped
  ) {
    Set<Id> requests = new Set<Id>(approved);
    requests.addAll(stopped);
    List<CMN_TodoSpec> specs = new List<CMN_TodoSpec>();
    Set<Id> closeSteps = new Set<Id>(done);
    Set<Id> cancelSteps = new Set<Id>();
    for (
      CMN_ApprovalStep__c s : CMN_TodoSelector.approvalSteps(pending, requests)
    ) {
      if (
        pending.contains(s.Id) && s.Status__c == CMN_ApprovalService.PENDING
      ) {
        specs.add(specOf(s));
      }
      if (approved.contains(s.Request__c)) {
        closeSteps.add(s.Id);
      }
      if (stopped.contains(s.Request__c)) {
        cancelSteps.add(s.Id);
      }
    }
    CMN_TodoService.open(specs);
    CMN_TodoService.close(CMN_TodoService.SOURCE_APPROVAL, closeSteps, null);
    CMN_TodoService.cancel(CMN_TodoService.SOURCE_APPROVAL, cancelSteps);
  }

  private static CMN_TodoSpec specOf(CMN_ApprovalStep__c s) {
    CMN_ApprovalRequest__c r = s.Request__r;
    CMN_TodoSpec spec = new CMN_TodoSpec(
      s.Approver__c,
      CMN_TodoService.SOURCE_APPROVAL,
      s.Id,
      r.TargetRecordId__c,
      'CMN_Todo_' + CMN_TodoService.SOURCE_APPROVAL
    );
    spec.category = 'APPROVAL';
    spec.systemCode = systemOf(r.TargetObject__c);
    spec.recordNo = r.TargetRecordNo__c ?? r.RecordNo__c;
    spec.titleParams = new List<Object>{ r.Title__c };
    spec.plantId = r.Plant__c;
    return spec;
  }

  /** 대상 객체 접두어로 포털 표시 시스템을 정한다(QMS_·PMS_ 외는 CMN). */
  private static String systemOf(String targetObject) {
    String prefix = targetObject?.substringBefore('_');
    return prefix == 'QMS' || prefix == 'PMS' ? prefix : 'CMN';
  }
}
