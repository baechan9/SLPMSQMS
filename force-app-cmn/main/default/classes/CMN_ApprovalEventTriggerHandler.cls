/**
 * @description CMN_ApprovalEvent__e 구독: 결재 단계 To-Do를 열고 닫고(CMN-00-TDO-001 BR-2), 결재 알림을 보낸다(CMN-00-NTF-001).
 * To-Do
 * - STEP_PENDING: 결재자 APPROVAL To-Do open(원천 = 결재 단계). 구독 시점에 이미 처리된 단계는 열지 않는다.
 * - STEP_DONE: 그 단계 To-Do close. APPROVED: 요청의 남은 To-Do close. REJECTED·RECALLED: 남은 To-Do cancel.
 * 이벤트는 요청 안에서 순서대로 쌓이므로(단계는 다시 열리지 않고 재상신은 새 요청) open → close → cancel 순으로 처리한다.
 * 대리인 To-Do(BR-2 "+유효 대리인")는 CMN-00-APV-004가 위임 정보로 추가한다. 닫기는 처리자 구분 없이 단계 전체라 대리인 To-Do도 함께 닫힌다.
 * 알림(규칙 코드)
 * - STEP_PENDING → 결재자 APV_STEP_PENDING(보낸 사람 = 기안자), APPROVED → 기안자 APV_APPROVED, REJECTED → 기안자 APV_REJECTED(보낸 사람 = 반려자).
 * 링크는 결재 대상 업무 레코드다. To-Do와 알림은 서로의 실패에 영향받지 않는다.
 * @group CMN-00-TDO-001
 */
public with sharing class CMN_ApprovalEventTriggerHandler extends CMN_TriggerHandler {
  private Set<Id> pending = new Set<Id>();
  private Set<Id> done = new Set<Id>();
  private Set<Id> approved = new Set<Id>();
  private Set<Id> rejected = new Set<Id>();
  private Set<Id> recalled = new Set<Id>();
  /** 승인·반려한 사용자(알림 보낸 사람) */
  private Map<Id, Id> actorByRequest = new Map<Id, Id>();

  protected override void afterInsert() {
    for (CMN_ApprovalEvent__e e : (List<CMN_ApprovalEvent__e>) newRecords) {
      Id requestId = e.RequestId__c;
      switch on e.EventType__c {
        when 'STEP_PENDING' {
          pending.add(e.StepId__c);
        }
        when 'STEP_DONE' {
          done.add(e.StepId__c);
        }
        when 'APPROVED' {
          approved.add(requestId);
          actorByRequest.put(requestId, e.UserId__c);
        }
        when 'REJECTED' {
          rejected.add(requestId);
          actorByRequest.put(requestId, e.UserId__c);
        }
        when 'RECALLED' {
          recalled.add(requestId);
        }
      }
    }
    pending.remove(null);
    done.remove(null);
    Set<Id> requests = new Set<Id>(approved);
    requests.addAll(rejected);
    requests.addAll(recalled);
    if (pending.isEmpty() && done.isEmpty() && requests.isEmpty()) {
      return;
    }
    List<CMN_ApprovalStep__c> steps = CMN_TodoSelector.approvalSteps(
      pending,
      requests
    );
    // 구독 실패가 결재 처리 자체를 되돌리지 않는다. 원문은 로그로 남기고 재처리는 운영자가 한다
    syncTodos(steps);
    try {
      notify(steps);
    } catch (Exception ex) {
      logFailure('notify', ex);
    }
  }

  private void syncTodos(List<CMN_ApprovalStep__c> steps) {
    List<CMN_TodoSpec> specs = new List<CMN_TodoSpec>();
    Set<Id> closeSteps = new Set<Id>(done);
    Set<Id> cancelSteps = new Set<Id>();
    for (CMN_ApprovalStep__c s : steps) {
      // 단계 사이에 비활성화된 결재자(퇴직 등)는 To-Do를 만들지 않는다(한 명 때문에 묶음 전체가 실패하지 않게)
      if (isPending(s) && s.Approver__r?.IsActive == true) {
        specs.add(specOf(s));
      }
      if (approved.contains(s.Request__c)) {
        closeSteps.add(s.Id);
      }
      if (rejected.contains(s.Request__c) || recalled.contains(s.Request__c)) {
        cancelSteps.add(s.Id);
      }
    }
    // 열기·닫기·취소는 서로의 실패에 영향받지 않는다
    try {
      CMN_TodoService.open(specs);
    } catch (Exception ex) {
      logFailure('open', ex);
    }
    try {
      CMN_TodoService.close(CMN_TodoService.SOURCE_APPROVAL, closeSteps, null);
    } catch (Exception ex) {
      logFailure('close', ex);
    }
    try {
      CMN_TodoService.cancel(CMN_TodoService.SOURCE_APPROVAL, cancelSteps);
    } catch (Exception ex) {
      logFailure('cancel', ex);
    }
  }

  private void notify(List<CMN_ApprovalStep__c> steps) {
    List<CMN_NotificationService.Message> messages = new List<CMN_NotificationService.Message>();
    Map<Id, CMN_ApprovalRequest__c> requests = new Map<Id, CMN_ApprovalRequest__c>();
    for (CMN_ApprovalStep__c s : steps) {
      requests.put(s.Request__c, s.Request__r);
      if (isPending(s)) {
        messages.add(
          message(
            'APV_STEP_PENDING',
            s.Approver__c,
            s.Request__r,
            s.Request__r.CreatedById
          )
        );
      }
    }
    for (Id requestId : requests.keySet()) {
      CMN_ApprovalRequest__c r = requests.get(requestId);
      if (approved.contains(requestId)) {
        messages.add(
          message(
            'APV_APPROVED',
            r.CreatedById,
            r,
            actorByRequest.get(requestId)
          )
        );
      }
      if (rejected.contains(requestId)) {
        messages.add(
          message(
            'APV_REJECTED',
            r.CreatedById,
            r,
            actorByRequest.get(requestId)
          )
        );
      }
    }
    CMN_NotificationService.send(messages);
  }

  /** 구독 단계별 실패 기록(결재 처리 자체는 되돌리지 않는다, 재처리는 운영자). */
  private static void logFailure(String step, Exception ex) {
    CMN_Logger.error(
      'CMN_ApprovalEventTriggerHandler.' + step,
      ex.getMessage(),
      null,
      ex
    );
  }

  private Boolean isPending(CMN_ApprovalStep__c s) {
    return pending.contains(s.Id) && s.Status__c == CMN_ApprovalService.PENDING;
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

  private static CMN_NotificationService.Message message(
    String eventCode,
    Id recipientId,
    CMN_ApprovalRequest__c r,
    Id actorId
  ) {
    CMN_NotificationService.Message m = new CMN_NotificationService.Message(
      eventCode,
      new Set<Id>{ recipientId },
      r.TargetRecordId__c,
      new Map<String, String>{
        'Title' => r.Title__c ?? '',
        'RecordNo' => r.TargetRecordNo__c ?? r.RecordNo__c ?? ''
      }
    );
    m.actorId = actorId ?? m.actorId;
    return m;
  }

  /** 대상 객체 접두어로 포털 표시 시스템을 정한다(QMS_·PMS_ 외는 CMN). */
  private static String systemOf(String targetObject) {
    String prefix = targetObject?.substringBefore('_');
    return prefix == 'QMS' || prefix == 'PMS' ? prefix : 'CMN';
  }
}
