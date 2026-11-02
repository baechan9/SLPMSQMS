import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getAction from "@salesforce/apex/CMN_ApprovalController.getAction";
import approve from "@salesforce/apex/CMN_ApprovalController.approve";
import reject from "@salesforce/apex/CMN_ApprovalController.reject";
import TITLE from "@salesforce/label/c.CMN_ApprovalAction_Title";
import APPROVE from "@salesforce/label/c.CMN_ApprovalAction_Approve";
import REJECT from "@salesforce/label/c.CMN_ApprovalAction_Reject";
import COMMENT from "@salesforce/label/c.CMN_ApprovalAction_Comment";
import REJECT_NEEDS from "@salesforce/label/c.CMN_ApprovalAction_RejectNeedsComment";
import DELEGATED from "@salesforce/label/c.CMN_ApprovalAction_Delegated";
import OPEN_TARGET from "@salesforce/label/c.CMN_ApprovalAction_OpenTarget";
import DONE from "@salesforce/label/c.CMN_ApprovalAction_Done";
import NOT_MY_TURN from "@salesforce/label/c.CMN_ApprovalAction_NotMyTurn";
import SUMMARY from "@salesforce/label/c.CMN_ApprovalAction_Summary";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

/**
 * 결재 처리(CMN-00-APV-003). To-Do에서 결재 요청을 열면 이 컴포넌트로 승인·반려한다(데스크톱·모바일 동일, UX-001 AC-2).
 * 반려는 의견이 있어야 버튼이 켜지고 서버도 의견 없는 반려를 막는다(AC-1).
 */
export default class CmnApprovalAction extends NavigationMixin(
  LightningElement
) {
  @api recordId;

  labels = {
    title: TITLE,
    approve: APPROVE,
    reject: REJECT,
    comment: COMMENT,
    rejectNeeds: REJECT_NEEDS,
    openTarget: OPEN_TARGET,
    notMyTurn: NOT_MY_TURN,
    summary: SUMMARY,
    loading: LOADING
  };
  view;
  isLoading = true;
  isSaving = false;
  errorMessage;
  comment = "";

  connectedCallback() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      this.view = await getAction({ requestId: this.recordId });
      this.errorMessage = undefined;
    } catch (e) {
      this.errorMessage = e?.body?.message || ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  get canAct() {
    return !!this.view?.myStepId;
  }

  get delegatedText() {
    return this.view?.isDelegate
      ? DELEGATED.replace("{0}", this.view.delegatorName ?? "")
      : null;
  }

  get rejectDisabled() {
    return this.isSaving || !this.comment.trim();
  }

  get hasSummary() {
    return (this.view?.summary ?? []).length > 0;
  }

  handleComment(event) {
    this.comment = event.detail.value ?? "";
  }

  openTarget() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: { recordId: this.view.targetId, actionName: "view" }
    });
  }

  async handleApprove() {
    await this.act(approve);
  }

  async handleReject() {
    if (!this.comment.trim()) {
      this.toast(REJECT_NEEDS, "error");
      return;
    }
    await this.act(reject);
  }

  async act(call) {
    this.isSaving = true;
    try {
      await call({ stepId: this.view.myStepId, comment: this.comment });
      this.comment = "";
      this.toast(DONE, "success");
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
