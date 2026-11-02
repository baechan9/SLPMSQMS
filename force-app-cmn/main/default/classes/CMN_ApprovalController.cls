/**
 * @description 결재 화면 진입점(CMN-00-APV-003): cmnApprovalLine·cmnApprovalAction·cmnApprovalHistory·cmnApprovalMonitor.
 * 처리 규칙은 모두 서버 서비스(CMN_ApprovalService·CMN_ApprovalLineResolver)가 다시 확인한다(화면 비활성은 편의일 뿐).
 * @group CMN-00-APV-003
 */
public with sharing class CMN_ApprovalController {
  private static final Pattern TYPE_CODE = Pattern.compile(
    '^[A-Za-z0-9_]{1,40}$'
  );
  private static final Set<String> VIEWS = new Set<String>{
    'SUBMITTED',
    'ACTED',
    'IN_PROGRESS'
  };
  private static final Integer SUMMARY_FIELDS = 30;
  private static final Set<String> SYSTEM_FIELDS = new Set<String>{
    'id',
    'ownerid',
    'isdeleted',
    'createddate',
    'createdbyid',
    'lastmodifieddate',
    'lastmodifiedbyid',
    'systemmodstamp',
    'lastactivitydate',
    'lastvieweddate',
    'lastreferenceddate',
    'recordtypeid'
  };

  /** @description 결재선 화면 데이터. */
  public class LineView {
    @AuraEnabled
    public Boolean canSubmit = false;
    @AuraEnabled
    public String refusal;
    @AuraEnabled
    public Boolean allowEdit = true;
    @AuraEnabled
    public CMN_ApprovalStatusDTO current;
    @AuraEnabled
    public Boolean canRecall = false;
    @AuraEnabled
    public List<LineStep> steps = new List<LineStep>();
    @AuraEnabled
    public List<Option> personalTemplates = new List<Option>();
    @AuraEnabled
    public List<Option> stepTypes = new List<Option>();
  }

  /** @description 결재선 한 단계(화면). */
  public class LineStep {
    @AuraEnabled
    public Integer stepNo;
    @AuraEnabled
    public String stepType;
    @AuraEnabled
    public Id approverId;
    @AuraEnabled
    public String approverName;
    @AuraEnabled
    public String roleCode;
    @AuraEnabled
    public Boolean isMandatory = false;
  }

  /** @description 선택지. */
  public class Option {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;
  }

  /** @description 결재자 검색 결과. */
  public class UserHit {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String employeeNo;
    @AuraEnabled
    public String departmentName;
  }

  /** @description 결재 처리 화면 데이터. */
  public class ActionView {
    @AuraEnabled
    public Id requestId;
    @AuraEnabled
    public String recordNo;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Id targetId;
    @AuraEnabled
    public String drafterName;
    @AuraEnabled
    public String submitComment;
    @AuraEnabled
    public Id myStepId;
    @AuraEnabled
    public Boolean isDelegate = false;
    @AuraEnabled
    public String delegatorName;
    @AuraEnabled
    public List<Option> summary = new List<Option>();
  }

  /** @description 이력 한 버전. */
  public class HistoryVersion {
    @AuraEnabled
    public Id requestId;
    @AuraEnabled
    public Integer version;
    @AuraEnabled
    public String recordNo;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String drafterName;
    @AuraEnabled
    public Datetime submittedAt;
    @AuraEnabled
    public String submitComment;
    @AuraEnabled
    public List<HistoryStep> steps = new List<HistoryStep>();
  }

  /** @description 이력 한 단계. */
  public class HistoryStep {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public Integer stepNo;
    @AuraEnabled
    public String stepType;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String approverName;
    @AuraEnabled
    public String actorLabel;
    @AuraEnabled
    public Datetime actedAt;
    @AuraEnabled
    public String comment;
  }

  /** @description 모니터 한 줄. */
  public class MonitorRow {
    @AuraEnabled
    public Id requestId;
    @AuraEnabled
    public String recordNo;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String typeCode;
    @AuraEnabled
    public String plantCode;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String drafterName;
    @AuraEnabled
    public Datetime submittedAt;
    @AuraEnabled
    public String pendingApprovers;
    @AuraEnabled
    public Integer pendingDays;
  }

  // ------------------------------------------------------------------ 결재선(cmnApprovalLine)
  /**
   * @description 대상·유형의 결재선(진행 중이면 현재 상태)과 상신 가능 여부(BR-2).
   * @param targetId 업무 레코드
   * @param typeCode 결재 유형
   * @return 결재선 화면
   * @throws AuraHandledException 잘못된 입력·결재선 해석 오류(Role 미지정 등)
   */
  @AuraEnabled
  public static LineView getLine(Id targetId, String typeCode) {
    try {
      requireTarget(targetId, typeCode);
      LineView v = new LineView();
      v.current = CMN_ApprovalService.getStatus(targetId);
      Boolean inProgress = v.current?.status == CMN_ApprovalService.IN_PROGRESS;
      v.canRecall =
        inProgress &&
        v.current.drafterId == UserInfo.getUserId() &&
        !anyActed(v.current);
      v.refusal = inProgress
        ? Label.CMN_Approval_AlreadyInProgress
        : CMN_ApprovalService.submitRefusal(targetId, typeCode);
      v.canSubmit = String.isBlank(v.refusal);
      CMN_ApprovalTemplate__c t = CMN_ApprovalLineResolver.templateFor(
        targetId,
        typeCode
      );
      v.allowEdit = t == null || t.AllowUserEdit__c;
      v.steps = toLine(CMN_ApprovalLineResolver.resolve(targetId, typeCode));
      for (
        Schema.PicklistEntry e : CMN_ApprovalStep__c.StepType__c.getDescribe()
          .getPicklistValues()
      ) {
        Option o = new Option();
        o.label = e.getLabel();
        o.value = e.getValue();
        v.stepTypes.add(o);
      }
      for (
        CMN_ApprovalTemplate__c p : CMN_ApprovalUiSelector.personalTemplates(
          typeCode
        )
      ) {
        Option o = new Option();
        o.label = p.Name;
        o.value = p.Id;
        v.personalTemplates.add(o);
      }
      return v;
    } catch (Exception e) {
      throw toAura(e, 'CMN_ApprovalController.getLine');
    }
  }

  /**
   * @description 결재자 검색(BR-1: 이름·사번·부서명, 활성 사용자).
   * @param term 검색어(2자 이상 40자 이하)
   * @return 사용자
   * @throws AuraHandledException 잘못된 입력
   */
  @AuraEnabled
  public static List<UserHit> searchApprovers(String term) {
    try {
      String t = term?.trim();
      if (String.isBlank(t) || t.length() < 2 || t.length() > 40) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      List<User> users = CMN_ApprovalUiSelector.searchUsers(t);
      Set<String> codes = new Set<String>();
      for (User u : users) {
        if (u.DepartmentCode__c != null) {
          codes.add(u.DepartmentCode__c);
        }
      }
      Map<String, String> depts = CMN_ApprovalUiSelector.departmentNames(codes);
      List<UserHit> out = new List<UserHit>();
      for (User u : users) {
        UserHit h = new UserHit();
        h.id = u.Id;
        h.name = u.Name;
        h.employeeNo = u.EmployeeNo__c;
        h.departmentName = depts.get(u.DepartmentCode__c);
        out.add(h);
      }
      return out;
    } catch (Exception e) {
      throw toAura(e, 'CMN_ApprovalController.searchApprovers');
    }
  }

  /**
   * @description 상신. 결재선 규칙(필수 단계·편집 불가)과 상신 가능 상태는 서버가 확인한다.
   * @param targetId 업무 레코드
   * @param typeCode 결재 유형
   * @param stepsJson 결재선 JSON([{stepNo, stepType, approverId, roleCode}])
   * @param comment 상신 의견
   * @return 결재 요청 Id
   * @throws AuraHandledException 검증 오류
   */
  @AuraEnabled
  public static Id submit(
    Id targetId,
    String typeCode,
    String stepsJson,
    String comment
  ) {
    try {
      requireTarget(targetId, typeCode);
      return CMN_ApprovalService.submit(
        targetId,
        typeCode,
        parseSteps(stepsJson),
        comment?.left(4000)
      );
    } catch (Exception e) {
      throw toAura(e, 'CMN_ApprovalController.submit');
    }
  }

  /**
   * @description 회수(첫 결재 전, 기안자만 — 서버 확인).
   * @param requestId 결재 요청
   * @param comment 의견
   * @throws AuraHandledException 회수 불가
   */
  @AuraEnabled
  public static void recall(Id requestId, String comment) {
    try {
      requireRequest(requestId);
      CMN_ApprovalService.recall(requestId, comment?.left(4000));
    } catch (Exception e) {
      throw toAura(e, 'CMN_ApprovalController.recall');
    }
  }

  /**
   * @description 결재선을 개인 템플릿으로 저장.
   * @param typeCode 결재 유형
   * @param name 이름(80자)
   * @param stepsJson 결재선 JSON
   * @return 템플릿 Id
   * @throws AuraHandledException 입력 오류
   */
  @AuraEnabled
  public static Id savePersonal(
    String typeCode,
    String name,
    String stepsJson
  ) {
    try {
      if (
        !TYPE_CODE.matcher(typeCode ?? '').matches() || String.isBlank(name)
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      return CMN_ApprovalLineResolver.savePersonal(
        typeCode,
        name.trim(),
        parseSteps(stepsJson)
      );
    } catch (Exception e) {
      throw toAura(e, 'CMN_ApprovalController.savePersonal');
    }
  }

  /**
   * @description 개인 템플릿 불러오기(AC-3): 템플릿의 필수 단계는 그대로 두고 나머지를 개인 결재선으로 채운다.
   * @param targetId 업무 레코드
   * @param typeCode 결재 유형
   * @param templateId 개인 템플릿
   * @return 결재선
   * @throws AuraHandledException 입력 오류
   */
  @AuraEnabled
  public static List<LineStep> loadPersonal(
    Id targetId,
    String typeCode,
    Id templateId
  ) {
    try {
      requireTarget(targetId, typeCode);
      if (
        templateId == null ||
        templateId.getSObjectType() != CMN_ApprovalTemplate__c.SObjectType
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      List<CMN_ApprovalStepSpec> merged = new List<CMN_ApprovalStepSpec>();
      Set<String> seen = new Set<String>();
      for (
        CMN_ApprovalStepSpec s : CMN_ApprovalLineResolver.resolve(
          targetId,
          typeCode
        )
      ) {
        if (s.isMandatory) {
          merged.add(s);
          seen.add(s.stepType + '|' + s.approverId);
        }
      }
      for (
        CMN_ApprovalStepSpec s : CMN_ApprovalLineResolver.loadPersonal(
          templateId
        )
      ) {
        if (!seen.contains(s.stepType + '|' + s.approverId)) {
          merged.add(s);
        }
      }
      return toLine(byStepNo(merged));
    } catch (Exception e) {
      throw toAura(e, 'CMN_ApprovalController.loadPersonal');
    }
  }

  // ------------------------------------------------------------------ 처리(cmnApprovalAction)
  /**
   * @description 결재 처리 화면: 스냅숏, 대상, 내 처리 차례(대결 포함).
   * @param requestId 결재 요청
   * @return 처리 화면(볼 수 없으면 null)
   * @throws AuraHandledException 잘못된 입력
   */
  @AuraEnabled
  public static ActionView getAction(Id requestId) {
    try {
      requireRequest(requestId);
      CMN_ApprovalRequest__c r = CMN_ApprovalUiSelector.request(requestId);
      if (r == null) {
        return null;
      }
      ActionView v = new ActionView();
      v.requestId = r.Id;
      v.recordNo = r.RecordNo__c;
      v.title = r.Title__c;
      v.status = r.Status__c;
      v.targetId = r.TargetRecordId__c;
      v.drafterName = r.CreatedBy?.Name;
      v.submitComment = r.SubmitComment__c;
      Id me = UserInfo.getUserId();
      for (CMN_ApprovalStep__c s : r.Steps__r) {
        if (s.Status__c != CMN_ApprovalService.PENDING) {
          continue;
        }
        if (s.Approver__c == me) {
          v.myStepId = s.Id;
          v.isDelegate = false;
          break;
        }
        if (
          CMN_DelegationService.isDelegate(s.Approver__c, me, r.TypeCode__c)
        ) {
          v.myStepId = s.Id;
          v.isDelegate = true;
          v.delegatorName = s.Approver__r?.Name;
        }
      }
      v.summary = summarize(r.TargetObject__c, r.Summary__c);
      return v;
    } catch (Exception e) {
      throw toAura(e, 'CMN_ApprovalController.getAction');
    }
  }

  /**
   * @description 승인.
   * @param stepId 단계
   * @param comment 의견
   * @throws AuraHandledException 처리 차례·결재자 아님
   */
  @AuraEnabled
  public static void approve(Id stepId, String comment) {
    try {
      requireStep(stepId);
      CMN_ApprovalService.approve(stepId, comment?.left(4000));
    } catch (Exception e) {
      throw toAura(e, 'CMN_ApprovalController.approve');
    }
  }

  /**
   * @description 반려(의견 필수 — 서버가 확인, AC-1).
   * @param stepId 단계
   * @param comment 반려 의견
   * @throws AuraHandledException 의견 없음·처리 차례 아님
   */
  @AuraEnabled
  public static void reject(Id stepId, String comment) {
    try {
      requireStep(stepId);
      CMN_ApprovalService.reject(stepId, comment?.trim()?.left(4000));
    } catch (Exception e) {
      throw toAura(e, 'CMN_ApprovalController.reject');
    }
  }

  // ------------------------------------------------------------------ 이력(cmnApprovalHistory)
  /**
   * @description 대상의 모든 버전 결재 이력(AC-2: 버전별·시간순).
   * @param targetId 업무 레코드
   * @return 버전 목록
   * @throws AuraHandledException 잘못된 입력
   */
  @AuraEnabled
  public static List<HistoryVersion> getHistory(Id targetId) {
    try {
      if (targetId == null) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      // 결재 요청 레코드 페이지에 놓이면 그 요청의 대상 이력을 보인다
      Id key = targetId;
      if (targetId.getSObjectType() == CMN_ApprovalRequest__c.SObjectType) {
        CMN_ApprovalRequest__c request = CMN_ApprovalUiSelector.request(
          targetId
        );
        if (request == null) {
          return new List<HistoryVersion>();
        }
        key = request.TargetRecordId__c;
      }
      List<HistoryVersion> out = new List<HistoryVersion>();
      for (CMN_ApprovalRequest__c r : CMN_ApprovalUiSelector.history(key)) {
        HistoryVersion h = new HistoryVersion();
        h.requestId = r.Id;
        h.version = r.Version__c?.intValue();
        h.recordNo = r.RecordNo__c;
        h.status = r.Status__c;
        h.drafterName = r.CreatedBy?.Name;
        h.submittedAt = r.SubmittedAt__c;
        h.submitComment = r.SubmitComment__c;
        for (CMN_ApprovalStep__c s : r.Steps__r) {
          HistoryStep hs = new HistoryStep();
          hs.id = s.Id;
          hs.stepNo = s.StepNo__c?.intValue();
          hs.stepType = s.StepType__c;
          hs.status = s.Status__c;
          hs.approverName = s.Approver__r?.Name;
          // 대결이면 "처리자(대결: 위임자)"(APV-004 BR-4)
          hs.actorLabel = s.ActedBy__r == null
            ? null
            : (s.IsDelegated__c
                ? String.format(
                    Label.CMN_Approval_DelegatedActor,
                    new List<Object>{ s.ActedBy__r.Name, s.Approver__r?.Name }
                  )
                : s.ActedBy__r.Name);
          hs.actedAt = s.ActedAt__c;
          hs.comment = s.Comment__c;
          h.steps.add(hs);
        }
        out.add(h);
      }
      return out;
    } catch (Exception e) {
      throw toAura(e, 'CMN_ApprovalController.getHistory');
    }
  }

  // ------------------------------------------------------------------ 모니터(cmnApprovalMonitor)
  /**
   * @description 결재 유형 선택지(모니터 유형 필터). 유형 설정은 메타데이터라 전원이 볼 수 있다.
   * @return 유형(라벨 순)
   */
  @AuraEnabled(cacheable=true)
  public static List<Option> getTypes() {
    List<Option> out = new List<Option>();
    for (CMN_ApprovalType__mdt t : CMN_ApprovalType__mdt.getAll().values()) {
      Option o = new Option();
      o.label = t.MasterLabel;
      o.value = t.DeveloperName;
      out.add(o);
    }
    out.sort(new OptionByLabel());
    return out;
  }

  /** @description 선택지 라벨 순 정렬. */
  private class OptionByLabel implements Comparator<Option> {
    public Integer compare(Option a, Option b) {
      return (a.label ?? '').compareTo(b.label ?? '');
    }
  }

  /**
   * @description 결재 모니터(내가 상신 / 내가 처리 / 진행 중), 체류일수(BR-3: 현재 PENDING 시작 이후 달력일).
   * @param view SUBMITTED, ACTED, IN_PROGRESS
   * @param typeCode 결재 유형(선택)
   * @param plantId 공장(선택)
   * @param fromDate 상신일 시작(선택)
   * @param toDate 상신일 끝(선택)
   * @return 목록(최근 200건)
   * @throws AuraHandledException 잘못된 입력
   */
  @AuraEnabled
  public static List<MonitorRow> getMonitor(
    String view,
    String typeCode,
    Id plantId,
    Date fromDate,
    Date toDate
  ) {
    try {
      if (
        !VIEWS.contains(view) ||
        (String.isNotBlank(typeCode) &&
        !TYPE_CODE.matcher(typeCode).matches()) ||
        (plantId != null &&
        plantId.getSObjectType() != CMN_Plant__c.SObjectType)
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      List<MonitorRow> out = new List<MonitorRow>();
      Date today = Date.today();
      for (
        CMN_ApprovalRequest__c r : CMN_ApprovalUiSelector.monitor(
          view,
          typeCode,
          plantId,
          fromDate,
          toDate
        )
      ) {
        MonitorRow m = new MonitorRow();
        m.requestId = r.Id;
        m.recordNo = r.RecordNo__c;
        m.title = r.Title__c;
        m.typeCode = r.TypeCode__c;
        m.plantCode = r.Plant__r?.PlantCode__c;
        m.status = r.Status__c;
        m.drafterName = r.CreatedBy?.Name;
        m.submittedAt = r.SubmittedAt__c;
        List<String> names = new List<String>();
        Datetime since;
        for (CMN_ApprovalStep__c s : r.Steps__r) {
          names.add(s.Approver__r?.Name);
          if (
            s.PendingAt__c != null && (since == null || s.PendingAt__c < since)
          ) {
            since = s.PendingAt__c;
          }
        }
        m.pendingApprovers = String.join(names, ', ');
        m.pendingDays = since == null ? null : since.date().daysBetween(today);
        out.add(m);
      }
      return out;
    } catch (Exception e) {
      throw toAura(e, 'CMN_ApprovalController.getMonitor');
    }
  }

  // ------------------------------------------------------------------ 내부
  private static List<LineStep> toLine(List<CMN_ApprovalStepSpec> specs) {
    Set<Id> users = new Set<Id>();
    for (CMN_ApprovalStepSpec s : specs) {
      users.add(s.approverId);
    }
    users.remove(null);
    Map<Id, User> names = CMN_ApprovalUiSelector.users(users);
    List<LineStep> out = new List<LineStep>();
    for (CMN_ApprovalStepSpec s : specs) {
      LineStep l = new LineStep();
      l.stepNo = s.stepNo;
      l.stepType = s.stepType;
      l.approverId = s.approverId;
      l.approverName = names.get(s.approverId)?.Name;
      l.roleCode = s.roleCode;
      l.isMandatory = s.isMandatory == true;
      out.add(l);
    }
    return out;
  }

  /** 단계 순서로 정렬(같은 순서 안에서는 넣은 순서 유지: 필수 단계가 앞). */
  private static List<CMN_ApprovalStepSpec> byStepNo(
    List<CMN_ApprovalStepSpec> specs
  ) {
    Map<Integer, List<CMN_ApprovalStepSpec>> groups = new Map<Integer, List<CMN_ApprovalStepSpec>>();
    for (CMN_ApprovalStepSpec s : specs) {
      Integer no = s.stepNo ?? 0;
      if (!groups.containsKey(no)) {
        groups.put(no, new List<CMN_ApprovalStepSpec>());
      }
      groups.get(no).add(s);
    }
    List<Integer> nos = new List<Integer>(groups.keySet());
    nos.sort();
    List<CMN_ApprovalStepSpec> out = new List<CMN_ApprovalStepSpec>();
    for (Integer no : nos) {
      out.addAll(groups.get(no));
    }
    return out;
  }

  private static List<CMN_ApprovalStepSpec> parseSteps(String stepsJson) {
    try {
      List<CMN_ApprovalStepSpec> steps = (List<CMN_ApprovalStepSpec>) JSON.deserializeStrict(
        stepsJson,
        List<CMN_ApprovalStepSpec>.class
      );
      if (steps == null || steps.isEmpty() || steps.size() > 30) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      return steps;
    } catch (JSONException e) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
  }

  private static Boolean anyActed(CMN_ApprovalStatusDTO s) {
    for (CMN_ApprovalStatusDTO.Step st : s.steps) {
      if (st.actedById != null) {
        return true;
      }
    }
    return false;
  }

  /** 상신 시점 스냅숏(JSON)을 필드 라벨·값으로(시스템 필드 제외, 30개). */
  private static List<Option> summarize(String objectName, String summaryJson) {
    List<Option> out = new List<Option>();
    if (String.isBlank(summaryJson) || String.isBlank(objectName)) {
      return out;
    }
    Map<String, Schema.SObjectField> fields;
    try {
      fields = Schema.describeSObjects(
          new List<String>{ objectName },
          SObjectDescribeOptions.DEFERRED
        )[0]
        .fields.getMap();
    } catch (Exception e) {
      return out;
    }
    Map<String, Object> values;
    try {
      values = (Map<String, Object>) JSON.deserializeUntyped(summaryJson);
    } catch (Exception e) {
      return out;
    }
    for (String k : values.keySet()) {
      Schema.SObjectField f = fields.get(k.toLowerCase());
      Object v = values.get(k);
      if (
        f == null ||
        v == null ||
        v instanceof Map<String, Object> ||
        SYSTEM_FIELDS.contains(k.toLowerCase())
      ) {
        continue;
      }
      Schema.DescribeFieldResult d = f.getDescribe();
      if (!d.isAccessible()) {
        continue;
      }
      Option o = new Option();
      o.label = d.getLabel();
      o.value = String.valueOf(v).abbreviate(255);
      out.add(o);
      if (out.size() >= SUMMARY_FIELDS) {
        break;
      }
    }
    return out;
  }

  private static void requireTarget(Id targetId, String typeCode) {
    if (targetId == null || !TYPE_CODE.matcher(typeCode ?? '').matches()) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
  }

  private static void requireRequest(Id requestId) {
    if (
      requestId == null ||
      requestId.getSObjectType() != CMN_ApprovalRequest__c.SObjectType
    ) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
  }

  private static void requireStep(Id stepId) {
    if (
      stepId == null ||
      stepId.getSObjectType() != CMN_ApprovalStep__c.SObjectType
    ) {
      throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
    }
  }

  private static AuraHandledException toAura(Exception e, String source) {
    String message;
    if (e instanceof CMN_ValidationException) {
      message = e.getMessage();
    } else {
      CMN_Logger.error(source, e.getMessage(), null, e);
      message = Label.CMN_Common_UnexpectedError;
    }
    AuraHandledException aura = new AuraHandledException(message);
    aura.setMessage(message);
    return aura;
  }
}
