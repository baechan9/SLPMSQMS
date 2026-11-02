import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getPanel from "@salesforce/apex/CMN_MeetingController.getPanel";
import confirmMinutes from "@salesforce/apex/CMN_MeetingController.confirmMinutes";
import addAction from "@salesforce/apex/CMN_MeetingController.addAction";
import completeAction from "@salesforce/apex/CMN_MeetingController.completeAction";
import TITLE from "@salesforce/label/c.CMN_Meeting_Title";
import CONFIRM from "@salesforce/label/c.CMN_Meeting_Confirm";
import CONFIRMED from "@salesforce/label/c.CMN_Meeting_Confirmed";
import ACTIONS from "@salesforce/label/c.CMN_Meeting_Actions";
import ADD_ACTION from "@salesforce/label/c.CMN_Meeting_AddAction";
import ACTION_DONE from "@salesforce/label/c.CMN_Meeting_ActionDone";
import ACTION_TITLE from "@salesforce/label/c.CMN_Meeting_ActionTitle";
import ACTION_OWNER from "@salesforce/label/c.CMN_Meeting_ActionOwner";
import ACTION_DUE from "@salesforce/label/c.CMN_Meeting_ActionDue";
import NO_ACTIONS from "@salesforce/label/c.CMN_Meeting_NoActions";
import SAVED from "@salesforce/label/c.CMN_Meeting_Saved";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

/**
 * 회의 진행 패널(CMN-00-MTG-001).
 * - 회의록 확정(BR-2): 개최·작성 중 회의만, 확정하면 조치 담당자 To-Do와 참석자 알림을 서버가 만든다.
 * - 조치 항목(BR-3): 추가(담당자·기한), 완료. 확정 뒤 추가한 조치는 저장 즉시 담당자 To-Do.
 */
export default class CmnMeetingPanel extends LightningElement {
  @api recordId;

  labels = {
    title: TITLE,
    confirm: CONFIRM,
    actions: ACTIONS,
    addAction: ADD_ACTION,
    done: ACTION_DONE,
    actionTitle: ACTION_TITLE,
    owner: ACTION_OWNER,
    due: ACTION_DUE,
    empty: NO_ACTIONS,
    loading: LOADING
  };
  panel;
  isLoading = true;
  isSaving = false;
  errorMessage;
  draft = {};

  connectedCallback() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      this.panel = await getPanel({ meetingId: this.recordId });
      this.errorMessage = undefined;
    } catch (e) {
      this.errorMessage = e?.body?.message || ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  get canEdit() {
    return this.panel?.canEdit === true;
  }

  get actions() {
    return this.panel?.actions ?? [];
  }

  get hasActions() {
    return this.actions.length > 0;
  }

  get addDisabled() {
    return (
      this.isSaving ||
      !this.draft.title?.trim() ||
      !this.draft.ownerId ||
      !this.draft.dueDate
    );
  }

  handleTitle(event) {
    this.draft = { ...this.draft, title: event.detail.value };
  }

  handleOwner(event) {
    this.draft = { ...this.draft, ownerId: event.detail.recordId ?? null };
  }

  handleDue(event) {
    this.draft = { ...this.draft, dueDate: event.detail.value };
  }

  async handleConfirm() {
    await this.run(
      () => confirmMinutes({ meetingId: this.recordId }),
      CONFIRMED
    );
  }

  async handleAdd() {
    const ok = await this.run(
      () =>
        addAction({
          meetingId: this.recordId,
          title: this.draft.title,
          ownerId: this.draft.ownerId,
          dueDate: this.draft.dueDate
        }),
      SAVED
    );
    if (ok) {
      this.draft = {};
    }
  }

  async handleDone(event) {
    const actionId = event.target.dataset.id;
    await this.run(() => completeAction({ actionId }), SAVED);
  }

  async run(call, message) {
    this.isSaving = true;
    try {
      await call();
      this.toast(message, "success");
      await this.load();
      return true;
    } catch (e) {
      this.toast(e?.body?.message || ERROR, "error");
      return false;
    } finally {
      this.isSaving = false;
    }
  }

  toast(message, variant) {
    this.dispatchEvent(new ShowToastEvent({ message, variant }));
  }
}
