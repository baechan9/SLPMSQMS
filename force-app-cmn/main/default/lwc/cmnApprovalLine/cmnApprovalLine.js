import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getLine from "@salesforce/apex/CMN_ApprovalController.getLine";
import searchApprovers from "@salesforce/apex/CMN_ApprovalController.searchApprovers";
import submit from "@salesforce/apex/CMN_ApprovalController.submit";
import recall from "@salesforce/apex/CMN_ApprovalController.recall";
import savePersonal from "@salesforce/apex/CMN_ApprovalController.savePersonal";
import loadPersonal from "@salesforce/apex/CMN_ApprovalController.loadPersonal";
import TITLE from "@salesforce/label/c.CMN_ApprovalLine_Title";
import STEP from "@salesforce/label/c.CMN_ApprovalLine_Step";
import TYPE from "@salesforce/label/c.CMN_ApprovalLine_Type";
import APPROVER from "@salesforce/label/c.CMN_ApprovalLine_Approver";
import MANDATORY from "@salesforce/label/c.CMN_ApprovalLine_Mandatory";
import ADD from "@salesforce/label/c.CMN_ApprovalLine_Add";
import SEARCH from "@salesforce/label/c.CMN_ApprovalLine_Search";
import REMOVE from "@salesforce/label/c.CMN_ApprovalLine_Remove";
import COMMENT from "@salesforce/label/c.CMN_ApprovalLine_Comment";
import SUBMIT from "@salesforce/label/c.CMN_ApprovalLine_Submit";
import RECALL from "@salesforce/label/c.CMN_ApprovalLine_Recall";
import SUBMITTED from "@salesforce/label/c.CMN_ApprovalLine_Submitted";
import RECALLED from "@salesforce/label/c.CMN_ApprovalLine_Recalled";
import LOAD_PERSONAL from "@salesforce/label/c.CMN_ApprovalLine_LoadPersonal";
import SAVE_PERSONAL from "@salesforce/label/c.CMN_ApprovalLine_SavePersonal";
import PERSONAL_NAME from "@salesforce/label/c.CMN_ApprovalLine_PersonalName";
import SAVED from "@salesforce/label/c.CMN_ApprovalLine_Saved";
import EMPTY from "@salesforce/label/c.CMN_ApprovalLine_Empty";
import IN_PROGRESS from "@salesforce/label/c.CMN_ApprovalLine_InProgress";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

/**
 * 결재선 표시·편집·상신(CMN-00-APV-003). 서버가 템플릿(APV-002)으로 해석한 결재선을 보여 주고,
 * 편집 허용 템플릿이면 결재자 추가(이름·사번·부서명 검색, BR-1)·삭제(필수 단계 제외)를 할 수 있다.
 * 상신 가능 여부(BR-2)와 필수 단계·편집 규칙은 서버가 다시 확인한다.
 */
export default class CmnApprovalLine extends LightningElement {
  @api recordId;
  @api typeCode;
  /** 결정 지원 레일 패널 계약(UX-004 BR-6, APV-003 BR-4): 결재 유형은 config.typeCode로도 받는다 */
  @api objectApiName;
  @api config;
  @api variant;

  labels = {
    title: TITLE,
    step: STEP,
    type: TYPE,
    approver: APPROVER,
    mandatory: MANDATORY,
    add: ADD,
    search: SEARCH,
    remove: REMOVE,
    comment: COMMENT,
    submit: SUBMIT,
    recall: RECALL,
    loadPersonal: LOAD_PERSONAL,
    savePersonal: SAVE_PERSONAL,
    personalName: PERSONAL_NAME,
    empty: EMPTY,
    inProgress: IN_PROGRESS,
    loading: LOADING
  };
  view;
  steps = [];
  isLoading = true;
  isSaving = false;
  errorMessage;
  comment = "";
  searchTerm = "";
  hits = [];
  newType = "APPROVE";
  personalName = "";

  connectedCallback() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      this.view = await getLine({
        targetId: this.recordId,
        typeCode: this.effectiveTypeCode
      });
      this.steps = (this.view.steps ?? []).map((s) => ({ ...s }));
      this.errorMessage = undefined;
    } catch (e) {
      this.errorMessage = e?.body?.message || ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  get effectiveTypeCode() {
    return this.typeCode || this.config?.typeCode;
  }

  get inProgress() {
    return this.view?.current?.status === "IN_PROGRESS";
  }

  get editable() {
    return this.view?.canSubmit === true && this.view?.allowEdit === true;
  }

  get rows() {
    return this.steps.map((s, i) => ({
      ...s,
      key: `${i}-${s.approverId}`,
      index: i,
      canRemove: this.editable && !s.isMandatory
    }));
  }

  get hasSteps() {
    return this.steps.length > 0;
  }

  get submitDisabled() {
    return this.isSaving || !this.view?.canSubmit || !this.hasSteps;
  }

  get typeOptions() {
    return this.view?.stepTypes ?? [];
  }

  get personalOptions() {
    return this.view?.personalTemplates ?? [];
  }

  get hasPersonal() {
    return this.personalOptions.length > 0;
  }

  handleComment(event) {
    this.comment = event.detail.value ?? "";
  }

  handleType(event) {
    this.newType = event.detail.value;
  }

  async handleSearch(event) {
    this.searchTerm = event.detail.value ?? "";
    if (this.searchTerm.trim().length < 2) {
      this.hits = [];
      return;
    }
    try {
      this.hits = await searchApprovers({ term: this.searchTerm });
    } catch (e) {
      this.hits = [];
      this.toast(e?.body?.message || ERROR, "error");
    }
  }

  handleAdd(event) {
    const hit = this.hits.find((h) => h.id === event.currentTarget.dataset.id);
    const last = this.steps.reduce((m, s) => Math.max(m, s.stepNo ?? 0), 0);
    this.steps = [
      ...this.steps,
      {
        stepNo: last + 1,
        stepType: this.newType,
        approverId: hit.id,
        approverName: hit.name,
        isMandatory: false
      }
    ];
    this.hits = [];
    this.searchTerm = "";
  }

  handleRemove(event) {
    const index = Number(event.currentTarget.dataset.index);
    this.steps = this.steps.filter((_, i) => i !== index);
  }

  stepsJson() {
    return JSON.stringify(
      this.steps.map((s) => ({
        stepNo: s.stepNo,
        stepType: s.stepType,
        approverId: s.approverId,
        roleCode: s.roleCode ?? null
      }))
    );
  }

  async handleSubmit() {
    await this.run(
      () =>
        submit({
          targetId: this.recordId,
          typeCode: this.effectiveTypeCode,
          stepsJson: this.stepsJson(),
          comment: this.comment
        }),
      SUBMITTED
    );
  }

  async handleRecall() {
    await this.run(
      () =>
        recall({
          requestId: this.view.current.requestId,
          comment: this.comment
        }),
      RECALLED
    );
  }

  async handleLoadPersonal(event) {
    try {
      const line = await loadPersonal({
        targetId: this.recordId,
        typeCode: this.effectiveTypeCode,
        templateId: event.detail.value
      });
      this.steps = line.map((s) => ({ ...s }));
    } catch (e) {
      this.toast(e?.body?.message || ERROR, "error");
    }
  }

  handlePersonalName(event) {
    this.personalName = event.detail.value ?? "";
  }

  async handleSavePersonal() {
    if (!this.personalName.trim()) {
      return;
    }
    await this.run(
      () =>
        savePersonal({
          typeCode: this.effectiveTypeCode,
          name: this.personalName,
          stepsJson: this.stepsJson()
        }),
      SAVED
    );
    this.personalName = "";
  }

  async run(call, message) {
    this.isSaving = true;
    try {
      await call();
      this.toast(message, "success");
      this.comment = "";
      await this.load();
    } catch (e) {
      this.toast(e?.body?.message || ERROR, "error");
    } finally {
      this.isSaving = false;
    }
  }

  toast(message, variant) {
    this.dispatchEvent(new ShowToastEvent({ message, variant }));
  }
}
