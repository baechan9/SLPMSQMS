/**
 * @description 대리결재 위임 규칙(CMN-00-APV-004).
 * - 등록(BR-1): 위임자 본인 또는 위임자의 부서장(관리자 권한 CMN_DelegationAdmin 예외). 대리인은 위임자가 아닌 활성 사용자.
 * - 범위: 기간(StartAt ≤ 시각 < EndAt), 결재 유형(TypeCodes 공란 = 전체). 대결은 1단계만(BR-2): 위임자의 위임만 보고 대리인의 위임은 따라가지 않는다.
 * - 단계 도래(BR-3): 결재 이벤트 구독이 위임자 To-Do와 함께 대리인 To-Do(대결 표시)를 만든다. 먼저 처리한 쪽이 확정하고 단계 To-Do 전체가 닫힌다.
 * - 등록 즉시(BR-5): 이미 PENDING인 위임자 단계에도 대리인 To-Do·대상 읽기 공유를 만든다.
 * - 휴직(BR-6): 사용자 HR 상태가 LEAVE가 되고 결재 대기가 있으면 부서장에게 "대리인 지정 필요" 알림.
 * @group CMN-00-APV-004
 */
public with sharing class CMN_DelegationService {
  public static final String ADMIN_PERMISSION = 'CMN_DelegationAdmin';
  public static final String NEEDED_EVENT = 'CMN_DELEGATION_NEEDED';

  @TestVisible
  private static Datetime nowOverride;

  /**
   * @description 저장 전 검증·외부 키(이관 모드에서는 키만 채운다).
   * @param rows 위임
   */
  public static void prepare(List<CMN_Delegation__c> rows) {
    Set<Id> users = new Set<Id>();
    for (CMN_Delegation__c d : rows) {
      if (d.Delegator__c == null) {
        d.Delegator__c = UserInfo.getUserId();
      }
      users.add(d.Delegator__c);
      users.add(d.Delegate__c);
    }
    users.remove(null);
    Map<Id, User> byId = CMN_DelegationSelector.users(users);
    Boolean migration = CMN_TriggerHandler.isMigrationMode();
    Boolean admin = FeatureManagement.checkPermission(ADMIN_PERMISSION);
    Map<Id, CMN_Department__c> depts = migration || admin
      ? new Map<Id, CMN_Department__c>()
      : CMN_UserOrgService.departmentsOf(users);
    for (CMN_Delegation__c d : rows) {
      User delegator = byId.get(d.Delegator__c);
      if (String.isBlank(d.Name)) {
        d.Name = d.Reason__c?.left(80) ?? 'Delegation';
      }
      if (String.isBlank(d.ExternalKey__c) && delegator != null) {
        d.ExternalKey__c = ('DLG-' +
          (delegator.EmployeeNo__c ?? String.valueOf(delegator.Id)) +
          '-' +
          d.StartAt__c?.format('yyyyMMdd', delegator.TimeZoneSidKey))
          .left(80);
      }
      if (migration) {
        continue;
      }
      User delegate = byId.get(d.Delegate__c);
      if (
        delegate == null ||
        !delegate.IsActive ||
        d.Delegate__c == d.Delegator__c
      ) {
        d.addError(Label.CMN_Delegation_InvalidDelegate);
        continue;
      }
      if (d.EndAt__c <= d.StartAt__c) {
        d.addError(Label.CMN_Delegation_InvalidPeriod);
        continue;
      }
      Id me = UserInfo.getUserId();
      if (
        !admin &&
        me != d.Delegator__c &&
        depts.get(d.Delegator__c)?.Manager__c != me
      ) {
        d.addError(Label.CMN_Delegation_NotAllowed);
      }
    }
  }

  /**
   * @description 위임자별 지금 유효한 위임(1단계).
   * @param delegatorIds 위임자(결재자)
   * @return 위임자 Id → 위임 목록
   */
  public static Map<Id, List<CMN_Delegation__c>> activeFor(
    Set<Id> delegatorIds
  ) {
    Map<Id, List<CMN_Delegation__c>> out = new Map<Id, List<CMN_Delegation__c>>();
    if (delegatorIds.isEmpty()) {
      return out;
    }
    for (
      CMN_Delegation__c d : CMN_DelegationSelector.activeAt(delegatorIds, now())
    ) {
      if (!out.containsKey(d.Delegator__c)) {
        out.put(d.Delegator__c, new List<CMN_Delegation__c>());
      }
      out.get(d.Delegator__c).add(d);
    }
    return out;
  }

  /**
   * @description 결재 유형에 맞는 유효한 대리인(없으면 빈 집합).
   * @param delegations 위임자의 유효 위임
   * @param typeCode 결재 유형
   * @return 대리인 Id
   */
  public static Set<Id> delegatesFor(
    List<CMN_Delegation__c> delegations,
    String typeCode
  ) {
    Set<Id> out = new Set<Id>();
    for (CMN_Delegation__c d : delegations ?? new List<CMN_Delegation__c>()) {
      if (covers(d, typeCode)) {
        out.add(d.Delegate__c);
      }
    }
    return out;
  }

  /**
   * @description 지금 actor가 approver의 유효한 대리인인지(결재 처리 권한, BR-4).
   * @param approverId 지정 결재자
   * @param actorId 처리하려는 사용자
   * @param typeCode 결재 유형
   * @return 대리인이면 true
   */
  public static Boolean isDelegate(Id approverId, Id actorId, String typeCode) {
    return delegatesFor(
        activeFor(new Set<Id>{ approverId }).get(approverId),
        typeCode
      )
      .contains(actorId);
  }

  /**
   * @description BR-5: 저장된 위임이 지금 유효하면 위임자의 PENDING 단계에 대리인 To-Do와 읽기 공유를 만든다.
   * @param rows 저장된 위임
   */
  public static void openForPendingSteps(List<CMN_Delegation__c> rows) {
    Datetime at = now();
    Map<Id, List<CMN_Delegation__c>> byDelegator = new Map<Id, List<CMN_Delegation__c>>();
    for (CMN_Delegation__c d : rows) {
      if (d.StartAt__c <= at && d.EndAt__c > at && d.Delegate__c != null) {
        if (!byDelegator.containsKey(d.Delegator__c)) {
          byDelegator.put(d.Delegator__c, new List<CMN_Delegation__c>());
        }
        byDelegator.get(d.Delegator__c).add(d);
      }
    }
    if (byDelegator.isEmpty()) {
      return;
    }
    List<CMN_ApprovalStep__c> steps = CMN_DelegationSelector.pendingStepsOf(
      byDelegator.keySet()
    );
    List<CMN_TodoSpec> specs = new List<CMN_TodoSpec>();
    for (CMN_ApprovalStep__c s : steps) {
      Set<Id> delegates = delegatesFor(
        byDelegator.get(s.Approver__c),
        s.Request__r.TypeCode__c
      );
      if (!delegates.isEmpty()) {
        CMN_ApprovalService.grantRead(
          s.Request__r.TargetRecordId__c,
          s.Request__c,
          delegates
        );
        specs.addAll(delegateSpecs(s, delegates));
      }
    }
    CMN_TodoService.open(specs);
  }

  /**
   * @description 결재 단계의 대리인 To-Do 명세(대결 표시, 원천 = 결재 단계라 단계가 끝나면 함께 닫힌다).
   * @param s 결재 단계(Request__r 포함)
   * @param delegates 대리인
   * @return To-Do 명세
   */
  public static List<CMN_TodoSpec> delegateSpecs(
    CMN_ApprovalStep__c s,
    Set<Id> delegates
  ) {
    List<CMN_TodoSpec> out = new List<CMN_TodoSpec>();
    for (Id d : delegates) {
      CMN_TodoSpec spec = new CMN_TodoSpec(
        d,
        CMN_TodoService.SOURCE_APPROVAL,
        s.Id,
        s.Request__r.TargetRecordId__c,
        'CMN_Todo_' + CMN_TodoService.SOURCE_APPROVAL
      );
      spec.category = 'APPROVAL';
      String target = s.Request__r.TargetObject__c?.substringBefore('_');
      spec.systemCode = target == 'QMS' || target == 'PMS' ? target : 'CMN';
      spec.recordNo = s.Request__r.TargetRecordNo__c ??
        s.Request__r.RecordNo__c;
      spec.titleParams = new List<Object>{ s.Request__r.Title__c };
      spec.plantId = s.Request__r.Plant__c;
      spec.isDelegated = true;
      spec.delegatedFromId = s.Approver__c;
      out.add(spec);
    }
    return out;
  }

  /**
   * @description BR-6: HR 상태가 LEAVE가 된 사용자에게 결재 대기가 있으면 부서장에게 알린다.
   * @param users 저장된 사용자
   * @param oldMap 이전 값
   */
  public static void notifyLeave(List<User> users, Map<Id, SObject> oldMap) {
    Map<Id, User> onLeave = new Map<Id, User>();
    for (User u : users) {
      if (
        u.HrStatus__c == 'LEAVE' &&
        (String) oldMap?.get(u.Id)?.get('HrStatus__c') != 'LEAVE'
      ) {
        onLeave.put(u.Id, u);
      }
    }
    if (onLeave.isEmpty()) {
      return;
    }
    Map<Id, Integer> pending = CMN_EmployeeSelector.pendingApprovalCounts(
      onLeave.keySet()
    );
    Map<Id, CMN_Department__c> depts = CMN_UserOrgService.departmentsOf(
      onLeave.keySet()
    );
    List<CMN_NotificationService.Message> messages = new List<CMN_NotificationService.Message>();
    for (User u : onLeave.values()) {
      Integer n = pending.get(u.Id) ?? 0;
      Id manager = depts.get(u.Id)?.Manager__c;
      if (n == 0 || manager == null || manager == u.Id) {
        continue;
      }
      messages.add(
        new CMN_NotificationService.Message(
          NEEDED_EVENT,
          new Set<Id>{ manager },
          u.Id,
          new Map<String, String>{
            'UserName' => u.FirstName == null
              ? u.LastName
              : u.LastName + ' ' + u.FirstName,
            'PendingApprovals' => String.valueOf(n)
          }
        )
      );
    }
    CMN_NotificationService.send(messages);
  }

  private static Boolean covers(CMN_Delegation__c d, String typeCode) {
    if (String.isBlank(d.TypeCodes__c)) {
      return true;
    }
    for (String t : d.TypeCodes__c.split(',')) {
      if (t.trim() == typeCode) {
        return true;
      }
    }
    return false;
  }

  private static Datetime now() {
    return nowOverride ?? Datetime.now();
  }
}
