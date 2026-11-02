/**
 * @description 공통 결재 엔진(CMN-00-APV-001). 어떤 업무 객체든 "상신 → 단계별 처리 → 완료 콜백"을 같은 방식으로 한다.
 * - 같은 StepNo는 병렬(모두 승인해야 다음 순서), CC는 그 순서에 닿으면 NOTIFIED로 표시하고 기다리지 않는다(BR-2).
 * - 반려 시 요청 REJECTED, 남은 단계 SKIPPED, 잠금 해제(BR-3). 회수는 기안자만, 어떤 단계도 처리되기 전에만(BR-4).
 * - 상신 때 결재자·참조자에게 대상과 요청 읽기 공유(사유 CMN_Approval, BR-6). 업무 상태는 콜백이 바꾼다(BR-8).
 * - 모든 상태 변화는 CMN_ApprovalEvent__e로 알린다(BR-9). To-Do·알림은 이 이벤트를 구독한다.
 * 표준 Approval Process(ProcessInstance)는 쓰지 않는다(결정 D-2 권고).
 * @group CMN-00-APV-001
 */
public with sharing class CMN_ApprovalService {
  public static final String IN_PROGRESS = 'IN_PROGRESS';
  public static final String APPROVED = 'APPROVED';
  public static final String REJECTED = 'REJECTED';
  public static final String RECALLED = 'RECALLED';
  public static final String WAITING = 'WAITING';
  public static final String PENDING = 'PENDING';
  public static final String SKIPPED = 'SKIPPED';
  public static final String NOTIFIED = 'NOTIFIED';
  public static final String TYPE_APPROVE = 'APPROVE';
  public static final String TYPE_CC = 'CC';
  private static final Set<String> STEP_TYPES = new Set<String>{
    'REVIEW',
    'AGREE',
    TYPE_APPROVE,
    TYPE_CC
  };
  private static final String CAUSE_APPROVAL = 'CMN_Approval__c';

  @TestVisible
  private static Map<String, CMN_ApprovalType__mdt> typesOverride;
  @TestVisible
  private static CMN_ApprovalCallback callbackOverride;
  @TestVisible
  private static List<CMN_ApprovalEvent__e> published = new List<CMN_ApprovalEvent__e>();

  // ------------------------------------------------------------------ 상신
  /**
   * @description 결재를 상신한다.
   * @param targetId 대상 레코드
   * @param typeCode 결재 유형(CMN_ApprovalType__mdt DeveloperName)
   * @param steps 결재선
   * @param comment 상신 의견
   * @return 결재 요청 Id
   * @throws CMN_ValidationException 결재선·대상·진행 중 결재 검증 실패(라벨 문구)
   */
  public static Id submit(
    Id targetId,
    String typeCode,
    List<CMN_ApprovalStepSpec> steps,
    String comment
  ) {
    CMN_ApprovalType__mdt approvalType = typeOf(typeCode);
    String targetObject = String.valueOf(targetId.getSObjectType());
    if (approvalType.TargetObject__c != targetObject) {
      throw new CMN_ValidationException(Label.CMN_Approval_TargetMismatch);
    }
    Id drafter = UserInfo.getUserId();
    validateSteps(steps, approvalType, drafter);
    CMN_ApprovalCallback callback = callbackFor(approvalType);
    String refusal = callback?.canSubmit(targetId);
    if (String.isNotBlank(refusal)) {
      throw new CMN_ValidationException(
        String.format(
          Label.CMN_Approval_CannotSubmit,
          new List<Object>{ refusal }
        )
      );
    }
    Integer version = 1;
    for (
      CMN_ApprovalRequest__c existing : CMN_ApprovalSelector.requestsOf(
        targetId
      )
    ) {
      if (existing.Status__c == IN_PROGRESS) {
        throw new CMN_ValidationException(Label.CMN_Approval_AlreadyInProgress);
      }
      version = Math.max(version, existing.Version__c.intValue() + 1);
    }

    SObject target = snapshot(targetId);
    Map<String, Object> fields = target.getPopulatedFieldsAsMap();
    String targetNo = (String) fields.get('RecordNo__c');
    String title = String.join(
        new List<String>{ targetNo ?? '', (String) fields.get('Name') ?? '' },
        ' '
      )
      .trim();
    CMN_ApprovalRequest__c request = new CMN_ApprovalRequest__c(
      Name = (String.isBlank(title) ? typeCode : title).left(80),
      Title__c = (String.isBlank(title) ? typeCode : title).left(255),
      TypeCode__c = typeCode,
      TargetRecordId__c = targetId,
      TargetObject__c = targetObject,
      TargetRecordNo__c = targetNo,
      Plant__c = plantOf(fields),
      Version__c = version,
      Summary__c = JSON.serialize(fields).left(32768),
      SubmitComment__c = comment?.left(4000),
      Status__c = IN_PROGRESS,
      SubmittedAt__c = Datetime.now()
    );
    // 상태·일시는 사용자 FLS가 읽기라 엔진이 시스템 모드로 쓴다(채번은 요청 트리거)
    CMN_ApprovalWriter.save(new List<SObject>{ request });
    String recordNo = [
      SELECT RecordNo__c
      FROM CMN_ApprovalRequest__c
      WHERE Id = :request.Id
      WITH SYSTEM_MODE
    ]
    .RecordNo__c;

    List<CMN_ApprovalStep__c> rows = new List<CMN_ApprovalStep__c>();
    Map<Integer, Integer> seen = new Map<Integer, Integer>();
    for (CMN_ApprovalStepSpec s : sorted(steps)) {
      Integer n = (seen.get(s.stepNo) ?? 0) + 1;
      seen.put(s.stepNo, n);
      rows.add(
        new CMN_ApprovalStep__c(
          Request__c = request.Id,
          StepNo__c = s.stepNo,
          StepType__c = s.stepType,
          Approver__c = s.approverId,
          RoleCode__c = s.roleCode,
          Status__c = WAITING,
          ExternalKey__c = recordNo + '-S' + s.stepNo + (n > 1 ? '-' + n : '')
        )
      );
    }
    List<CMN_ApprovalEvent__e> events = new List<CMN_ApprovalEvent__e>{
      event(request, null, 'SUBMITTED', drafter)
    };
    request.CurrentStepNo__c = openNextGroup(rows, null, events, request);
    CMN_ApprovalWriter.save(rows);
    for (CMN_ApprovalEvent__e e : events) {
      if (e.EventType__c == 'STEP_PENDING' && e.StepId__c == null) {
        e.StepId__c = stepIdFor(rows, (Id) e.UserId__c);
      }
    }
    CMN_ApprovalWriter.save(
      new List<SObject>{
        new CMN_ApprovalRequest__c(
          Id = request.Id,
          CurrentStepNo__c = request.CurrentStepNo__c
        )
      }
    );

    if (approvalType.LockOnSubmit__c) {
      CMN_ApprovalWriter.lock(targetId);
    }
    shareWithApprovers(targetId, request.Id, rows);
    request.RecordNo__c = recordNo;
    callback?.onSubmitted(request);
    publish(events);
    return request.Id;
  }

  // ------------------------------------------------------------------ 처리
  /**
   * @description 단계를 승인한다(마지막 순서가 모두 승인되면 요청 승인).
   * @param stepId 처리할 단계
   * @param comment 의견
   * @throws CMN_ValidationException 처리 차례가 아니거나 결재자가 아님
   */
  public static void approve(Id stepId, String comment) {
    act(stepId, comment, true);
  }

  /**
   * @description 단계를 반려한다(요청 반려, 남은 단계 건너뜀).
   * @param stepId 처리할 단계
   * @param comment 반려 사유(필수)
   * @throws CMN_ValidationException 사유 없음, 처리 차례가 아니거나 결재자가 아님
   */
  public static void reject(Id stepId, String comment) {
    if (String.isBlank(comment)) {
      throw new CMN_ValidationException(Label.CMN_Approval_CommentRequired);
    }
    act(stepId, comment, false);
  }

  /**
   * @description 기안자가 회수한다(어떤 단계도 처리되기 전에만, BR-4).
   * @param requestId 결재 요청
   * @param comment 회수 사유
   * @throws CMN_ValidationException 기안자가 아니거나 이미 처리된 단계가 있음
   */
  public static void recall(Id requestId, String comment) {
    CMN_ApprovalRequest__c request = CMN_ApprovalSelector.requestForUpdate(
      requestId
    );
    if (
      request == null ||
      request.Status__c != IN_PROGRESS ||
      request.CreatedById != UserInfo.getUserId()
    ) {
      throw new CMN_ValidationException(Label.CMN_Approval_RecallNotAllowed);
    }
    List<CMN_ApprovalStep__c> steps = CMN_ApprovalSelector.steps(requestId);
    for (CMN_ApprovalStep__c s : steps) {
      if (s.Status__c == APPROVED || s.Status__c == REJECTED) {
        throw new CMN_ValidationException(Label.CMN_Approval_RecallNotAllowed);
      }
    }
    request.Status__c = RECALLED;
    request.CompletedAt__c = Datetime.now();
    request.CurrentStepNo__c = null;
    request.SubmitComment__c = comment?.left(4000) ?? request.SubmitComment__c;
    close(request, steps);
    unlock(request, false);
    callbackFor(typeOf(request.TypeCode__c))?.onRecalled(request);
    publish(
      new List<CMN_ApprovalEvent__e>{
        event(request, null, 'RECALLED', UserInfo.getUserId())
      }
    );
  }

  /**
   * @description 대상의 최신 차수 결재 상태.
   * @param targetId 대상 레코드
   * @return 상태(결재가 없으면 null)
   */
  public static CMN_ApprovalStatusDTO getStatus(Id targetId) {
    List<CMN_ApprovalRequest__c> requests = CMN_ApprovalSelector.requestsOf(
      targetId
    );
    if (requests.isEmpty()) {
      return null;
    }
    CMN_ApprovalRequest__c r = requests[0];
    CMN_ApprovalStatusDTO dto = new CMN_ApprovalStatusDTO();
    dto.requestId = r.Id;
    dto.recordNo = r.RecordNo__c;
    dto.status = r.Status__c;
    dto.version = r.Version__c?.intValue();
    dto.currentStepNo = r.CurrentStepNo__c?.intValue();
    dto.drafterId = r.CreatedById;
    for (CMN_ApprovalStep__c s : CMN_ApprovalSelector.steps(r.Id)) {
      CMN_ApprovalStatusDTO.Step d = new CMN_ApprovalStatusDTO.Step();
      d.stepId = s.Id;
      d.stepNo = s.StepNo__c?.intValue();
      d.stepType = s.StepType__c;
      d.approverId = s.Approver__c;
      d.approverName = s.Approver__r?.Name;
      d.status = s.Status__c;
      d.actedById = s.ActedBy__c;
      d.actedAt = s.ActedAt__c;
      d.comment = s.Comment__c;
      dto.steps.add(d);
    }
    return dto;
  }

  // ------------------------------------------------------------------ 내부
  private static void act(Id stepId, String comment, Boolean approve) {
    CMN_ApprovalStep__c found = CMN_ApprovalSelector.step(stepId);
    if (found == null) {
      throw new CMN_ValidationException(Label.CMN_Approval_NotPending);
    }
    CMN_ApprovalRequest__c request = CMN_ApprovalSelector.requestForUpdate(
      found.Request__c
    );
    List<CMN_ApprovalStep__c> steps = CMN_ApprovalSelector.steps(request.Id);
    CMN_ApprovalStep__c step;
    for (CMN_ApprovalStep__c s : steps) {
      if (s.Id == stepId) {
        step = s;
      }
    }
    if (request.Status__c != IN_PROGRESS || step.Status__c != PENDING) {
      throw new CMN_ValidationException(Label.CMN_Approval_NotPending);
    }
    if (step.Approver__c != UserInfo.getUserId()) {
      throw new CMN_ValidationException(Label.CMN_Approval_NotApprover);
    }
    step.Status__c = approve ? APPROVED : REJECTED;
    step.ActedBy__c = UserInfo.getUserId();
    step.ActedAt__c = Datetime.now();
    step.Comment__c = comment?.left(4000);
    List<CMN_ApprovalEvent__e> events = new List<CMN_ApprovalEvent__e>{
      event(request, step.Id, 'STEP_DONE', UserInfo.getUserId())
    };
    CMN_ApprovalType__mdt approvalType = typeOf(request.TypeCode__c);

    if (!approve) {
      request.Status__c = REJECTED;
      request.CompletedAt__c = Datetime.now();
      request.CurrentStepNo__c = null;
      close(request, steps);
      unlock(request, false);
      callbackFor(approvalType)?.onRejected(request);
      events.add(event(request, null, REJECTED, UserInfo.getUserId()));
      publish(events);
      return;
    }
    Boolean groupDone = true;
    for (CMN_ApprovalStep__c s : steps) {
      if (
        s.StepNo__c == step.StepNo__c &&
        s.Status__c != APPROVED &&
        s.Status__c != NOTIFIED
      ) {
        groupDone = false;
      }
    }
    if (groupDone) {
      request.CurrentStepNo__c = openNextGroup(
        steps,
        step.StepNo__c,
        events,
        request
      );
    }
    CMN_ApprovalWriter.save(steps);
    if (request.CurrentStepNo__c == null) {
      request.Status__c = APPROVED;
      request.CompletedAt__c = Datetime.now();
      CMN_ApprovalWriter.save(new List<SObject>{ request });
      unlock(request, approvalType.KeepLockedAfterApproval__c);
      callbackFor(approvalType)?.onApproved(request);
      events.add(event(request, null, APPROVED, UserInfo.getUserId()));
    } else {
      CMN_ApprovalWriter.save(new List<SObject>{ request });
    }
    publish(events);
  }

  /**
   * 다음 순서를 연다: after 다음의 가장 작은 StepNo 묶음을 PENDING(CC는 NOTIFIED)으로. CC만 있는 묶음은 건너뛴다.
   * @return 열린 순서(없으면 null — 결재 끝)
   */
  private static Decimal openNextGroup(
    List<CMN_ApprovalStep__c> steps,
    Decimal after,
    List<CMN_ApprovalEvent__e> events,
    CMN_ApprovalRequest__c request
  ) {
    Decimal current = after;
    while (true) {
      Decimal next;
      for (CMN_ApprovalStep__c s : steps) {
        if (
          (current == null || s.StepNo__c > current) &&
          (next == null ||
          s.StepNo__c < next)
        ) {
          next = s.StepNo__c;
        }
      }
      if (next == null) {
        return null;
      }
      Boolean actionable = false;
      for (CMN_ApprovalStep__c s : steps) {
        if (s.StepNo__c != next) {
          continue;
        }
        if (s.StepType__c == TYPE_CC) {
          s.Status__c = NOTIFIED;
        } else {
          s.Status__c = PENDING;
          actionable = true;
          events.add(event(request, s.Id, 'STEP_PENDING', s.Approver__c));
        }
      }
      if (actionable) {
        return next;
      }
      current = next;
    }
    return null;
  }

  /** 끝난 요청: 남은 대기·처리 차례 단계를 건너뜀으로. */
  private static void close(
    CMN_ApprovalRequest__c request,
    List<CMN_ApprovalStep__c> steps
  ) {
    for (CMN_ApprovalStep__c s : steps) {
      if (s.Status__c == WAITING || s.Status__c == PENDING) {
        s.Status__c = SKIPPED;
      }
    }
    CMN_ApprovalWriter.save(steps);
    CMN_ApprovalWriter.save(new List<SObject>{ request });
  }

  private static void unlock(CMN_ApprovalRequest__c request, Boolean keep) {
    Id target = (Id) request.TargetRecordId__c;
    if (!keep) {
      CMN_ApprovalWriter.unlock(target);
    }
  }

  private static void validateSteps(
    List<CMN_ApprovalStepSpec> steps,
    CMN_ApprovalType__mdt approvalType,
    Id drafter
  ) {
    if (steps == null || steps.isEmpty()) {
      throw new CMN_ValidationException(Label.CMN_Approval_NoSteps);
    }
    Integer last;
    Set<Id> approvers = new Set<Id>();
    Set<Id> actors = new Set<Id>();
    for (CMN_ApprovalStepSpec s : steps) {
      if (s.stepNo == null || !STEP_TYPES.contains(s.stepType)) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      if (s.approverId == null) {
        throw new CMN_ValidationException(Label.CMN_Approval_ApproverInactive);
      }
      approvers.add(s.approverId);
      if (s.stepType != TYPE_CC) {
        actors.add(s.approverId);
      }
      last = last == null ? s.stepNo : Math.max(last, s.stepNo);
    }
    for (CMN_ApprovalStepSpec s : steps) {
      if (s.stepNo == last && s.stepType != TYPE_APPROVE) {
        throw new CMN_ValidationException(Label.CMN_Approval_LastMustApprove);
      }
    }
    if (!CMN_ApprovalSelector.activeUsers(approvers).containsAll(approvers)) {
      throw new CMN_ValidationException(Label.CMN_Approval_ApproverInactive);
    }
    if (actors.contains(drafter)) {
      throw new CMN_ValidationException(Label.CMN_Approval_SelfApproval);
    }
    if (approvalType.RequireDrafterManager__c) {
      Id manager = CMN_UserOrgService.departmentsOf(new Set<Id>{ drafter })
        .get(drafter)
        ?.Manager__c;
      if (manager == null || !actors.contains(manager)) {
        throw new CMN_ValidationException(Label.CMN_Approval_ManagerRequired);
      }
    }
  }

  private static List<CMN_ApprovalStepSpec> sorted(
    List<CMN_ApprovalStepSpec> steps
  ) {
    Map<Integer, List<CMN_ApprovalStepSpec>> byNo = new Map<Integer, List<CMN_ApprovalStepSpec>>();
    for (CMN_ApprovalStepSpec s : steps) {
      if (!byNo.containsKey(s.stepNo)) {
        byNo.put(s.stepNo, new List<CMN_ApprovalStepSpec>());
      }
      byNo.get(s.stepNo).add(s);
    }
    List<Integer> nos = new List<Integer>(byNo.keySet());
    nos.sort();
    List<CMN_ApprovalStepSpec> out = new List<CMN_ApprovalStepSpec>();
    for (Integer n : nos) {
      out.addAll(byNo.get(n));
    }
    return out;
  }

  /** 상신 시점 대상 필드 전체(감사 근거). 결재자 공장과 무관하게 엔진이 읽는다. */
  private static SObject snapshot(Id targetId) {
    Schema.SObjectType t = targetId.getSObjectType();
    List<String> names = new List<String>();
    for (
      Schema.SObjectField f : t.getDescribe(SObjectDescribeOptions.DEFERRED)
        .fields.getMap()
        .values()
    ) {
      Schema.DescribeFieldResult d = f.getDescribe();
      if (
        d.getType() != Schema.DisplayType.ADDRESS &&
        d.getType() != Schema.DisplayType.LOCATION
      ) {
        names.add(d.getName());
      }
    }
    return Database.queryWithBinds(
      'SELECT ' +
        String.join(names, ', ') +
        ' FROM ' +
        String.escapeSingleQuotes(String.valueOf(t)) +
        ' WHERE Id = :id',
      new Map<String, Object>{ 'id' => targetId },
      AccessLevel.SYSTEM_MODE
    )[0];
  }

  private static Id plantOf(Map<String, Object> fields) {
    Object v = fields.get('Plant__c');
    return v instanceof Id &&
      ((Id) v).getSObjectType() == CMN_Plant__c.SObjectType
      ? (Id) v
      : null;
  }

  /** BR-6: 결재자·참조자에게 대상과 요청 읽기 공유. 대상 객체에 CMN_Approval 사유가 없으면 수동 공유. */
  private static void shareWithApprovers(
    Id targetId,
    Id requestId,
    List<CMN_ApprovalStep__c> steps
  ) {
    Set<Id> users = new Set<Id>();
    for (CMN_ApprovalStep__c s : steps) {
      users.add(s.Approver__c);
    }
    List<SObject> rows = new List<SObject>();
    String targetObject = String.valueOf(targetId.getSObjectType());
    if (targetObject.endsWith('__c')) {
      Schema.SObjectType shareType = shareTypeOf(targetObject);
      String cause = hasCause(shareType, CAUSE_APPROVAL)
        ? CAUSE_APPROVAL
        : 'Manual';
      for (Id u : users) {
        rows.add(shareRow(shareType, targetId, u, cause));
      }
    } else {
      CMN_Logger.warn(
        'CMN_ApprovalService.shareWithApprovers',
        'Standard object target not shared: ' + targetObject,
        targetId
      );
    }
    Schema.SObjectType requestShare = CMN_ApprovalRequest__Share.SObjectType;
    for (Id u : users) {
      rows.add(shareRow(requestShare, requestId, u, CAUSE_APPROVAL));
    }
    CMN_ShareWriter.write(new List<SObject>(), rows);
  }

  private static Schema.SObjectType shareTypeOf(String objectName) {
    return ((SObject) Type.forName(
          'Schema.' + objectName.removeEnd('__c') + '__Share'
        )
        .newInstance())
      .getSObjectType();
  }

  private static Boolean hasCause(Schema.SObjectType shareType, String cause) {
    for (
      Schema.PicklistEntry e : shareType.getDescribe(
          SObjectDescribeOptions.DEFERRED
        )
        .fields.getMap()
        .get('rowcause')
        .getDescribe()
        .getPicklistValues()
    ) {
      if (e.getValue() == cause) {
        return true;
      }
    }
    return false;
  }

  private static SObject shareRow(
    Schema.SObjectType shareType,
    Id parentId,
    Id userId,
    String cause
  ) {
    SObject row = shareType.newSObject();
    row.put('ParentId', parentId);
    row.put('UserOrGroupId', userId);
    row.put('AccessLevel', 'Read');
    row.put('RowCause', cause);
    return row;
  }

  private static Id stepIdFor(List<CMN_ApprovalStep__c> rows, Id approver) {
    for (CMN_ApprovalStep__c r : rows) {
      if (r.Approver__c == approver && r.Status__c == PENDING) {
        return r.Id;
      }
    }
    return null;
  }

  private static CMN_ApprovalType__mdt typeOf(String typeCode) {
    CMN_ApprovalType__mdt t = typesOverride?.get(typeCode) ??
      CMN_ApprovalType__mdt.getInstance(typeCode);
    if (t == null) {
      throw new CMN_ValidationException(
        String.format(Label.CMN_Approval_NoType, new List<Object>{ typeCode })
      );
    }
    return t;
  }

  private static CMN_ApprovalCallback callbackFor(
    CMN_ApprovalType__mdt approvalType
  ) {
    if (callbackOverride != null) {
      return callbackOverride;
    }
    if (String.isBlank(approvalType.CallbackClass__c)) {
      return null;
    }
    return (CMN_ApprovalCallback) Type.forName(approvalType.CallbackClass__c)
      .newInstance();
  }

  private static CMN_ApprovalEvent__e event(
    CMN_ApprovalRequest__c request,
    Id stepId,
    String eventType,
    Id userId
  ) {
    return new CMN_ApprovalEvent__e(
      RequestId__c = request.Id,
      StepId__c = stepId,
      EventType__c = eventType,
      UserId__c = userId,
      TargetRecordId__c = request.TargetRecordId__c,
      TypeCode__c = request.TypeCode__c
    );
  }

  private static void publish(List<CMN_ApprovalEvent__e> events) {
    published.addAll(events);
    EventBus.publish(events);
  }
}
