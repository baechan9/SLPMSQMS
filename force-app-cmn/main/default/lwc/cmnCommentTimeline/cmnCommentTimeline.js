import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";
import USER_NAME from "@salesforce/schema/User.Name";
import getComments from "@salesforce/apex/CMN_CommentController.getComments";
import postComment from "@salesforce/apex/CMN_CommentController.postComment";
import editComment from "@salesforce/apex/CMN_CommentController.editComment";
import deleteComment from "@salesforce/apex/CMN_CommentController.deleteComment";
import TITLE from "@salesforce/label/c.CMN_Comment_Title";
import PLACEHOLDER from "@salesforce/label/c.CMN_Comment_Placeholder";
import POST from "@salesforce/label/c.CMN_Comment_Post";
import SAVE from "@salesforce/label/c.CMN_Comment_Save";
import CANCEL from "@salesforce/label/c.CMN_Comment_Cancel";
import EDIT from "@salesforce/label/c.CMN_Comment_Edit";
import DELETE from "@salesforce/label/c.CMN_Comment_Delete";
import EDITED from "@salesforce/label/c.CMN_Comment_Edited";
import EMPTY from "@salesforce/label/c.CMN_Comment_Empty";
import MENTION from "@salesforce/label/c.CMN_Comment_Mention";
import MENTIONED from "@salesforce/label/c.CMN_Comment_Mentioned";
import BODY_REQUIRED from "@salesforce/label/c.CMN_Comment_BodyRequired";
import POSTED from "@salesforce/label/c.CMN_Comment_Posted";
import SAVED from "@salesforce/label/c.CMN_Comment_Saved";
import DELETED from "@salesforce/label/c.CMN_Comment_Deleted";
import DELETE_CONFIRM from "@salesforce/label/c.CMN_Comment_DeleteConfirm";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

const USER_FILTER = {
  criteria: [{ fieldPath: "IsActive", operator: "eq", value: true }]
};

/**
 * 코멘트 타임라인(CMN-00-UX-003). 표준 Chatter 대신 쓴다.
 * - 최신순 목록. 부모 레코드를 볼 수 없는 사용자에게는 서버가 빈 목록을 준다(BR-3).
 * - 작성자 본인만 기한(기본 24시간) 안에서 수정·삭제 버튼이 보인다. 서버·트리거가 같은 규칙을 다시 확인한다(BR-2).
 * - @멘션: 사용자 선택기로 고른 사용자를 멘션 목록에 담고, 저장하면 서버가 새 멘션에게만 알림을 보낸다.
 */
export default class CmnCommentTimeline extends LightningElement {
  @api recordId;
  /** 결정 지원 레일 패널 계약(UX-004 BR-6, UX-003 BR-4) */
  @api objectApiName;
  @api config;
  @api variant;

  labels = {
    title: TITLE,
    placeholder: PLACEHOLDER,
    post: POST,
    save: SAVE,
    cancel: CANCEL,
    edit: EDIT,
    delete: DELETE,
    edited: EDITED,
    empty: EMPTY,
    mention: MENTION,
    mentioned: MENTIONED,
    loading: LOADING
  };
  userFilter = USER_FILTER;
  comments = [];
  isLoading = true;
  isSaving = false;
  errorMessage;
  draft = "";
  mentions = [];
  editingId;
  editDraft = "";
  editMentions = [];
  pickedUserId;
  pickTarget = "draft";

  connectedCallback() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      const rows = await getComments({ parentId: this.recordId });
      this.comments = (rows ?? []).map((c) => ({
        ...c,
        mentionNames: (c.mentions ?? []).map((m) => `@${m.name}`).join(" ")
      }));
      this.errorMessage = undefined;
      // 결정 지원 레일 머리의 건수 배지(UX-004 BR-6). 레일 밖에서는 듣는 곳이 없다
      this.dispatchEvent(
        new CustomEvent("railbadge", {
          detail: { count: this.comments.length, severity: "info" }
        })
      );
    } catch (e) {
      this.errorMessage = this.messageOf(e);
    } finally {
      this.isLoading = false;
    }
  }

  // 멘션 사용자 이름(단건 LDS)
  @wire(getRecord, { recordId: "$pickedUserId", fields: [USER_NAME] })
  wiredPicked({ data }) {
    if (!data) {
      return;
    }
    const mention = { id: data.id, name: getFieldValue(data, USER_NAME) };
    const list = this.pickTarget === "edit" ? "editMentions" : "mentions";
    if (!this[list].some((m) => m.id === mention.id)) {
      this[list] = [...this[list], mention];
    }
    this.pickedUserId = undefined;
    this.template
      .querySelectorAll("lightning-record-picker")
      .forEach((p) => p.clearSelection());
  }

  get isEmpty() {
    return !this.isLoading && !this.errorMessage && this.comments.length === 0;
  }

  get items() {
    return this.comments.map((c) => ({
      ...c,
      isEditing: c.id === this.editingId
    }));
  }

  get mentionPills() {
    return this.mentions.map((m) => ({ name: m.id, label: `@${m.name}` }));
  }

  get editMentionPills() {
    return this.editMentions.map((m) => ({ name: m.id, label: `@${m.name}` }));
  }

  get postDisabled() {
    return this.isSaving || !this.draft.trim();
  }

  handleDraft(event) {
    this.draft = event.detail.value ?? "";
  }

  handleEditDraft(event) {
    this.editDraft = event.detail.value ?? "";
  }

  handlePick(event) {
    this.pickTarget = event.target.dataset.target ?? "draft";
    this.pickedUserId = event.detail.recordId ?? undefined;
  }

  handleRemoveMention(event) {
    const id = event.detail.item.name;
    this.mentions = this.mentions.filter((m) => m.id !== id);
  }

  handleRemoveEditMention(event) {
    const id = event.detail.item.name;
    this.editMentions = this.editMentions.filter((m) => m.id !== id);
  }

  async handlePost() {
    if (!this.draft.trim()) {
      this.toast(BODY_REQUIRED, "error");
      return;
    }
    this.isSaving = true;
    try {
      await postComment({
        parentId: this.recordId,
        body: this.draft,
        mentionedUserIds: this.mentions.map((m) => m.id)
      });
      this.draft = "";
      this.mentions = [];
      this.toast(POSTED, "success");
      await this.load();
    } catch (e) {
      this.toast(this.messageOf(e), "error");
    } finally {
      this.isSaving = false;
    }
  }

  handleEdit(event) {
    const c = this.comments.find((x) => x.id === event.target.dataset.id);
    this.editingId = c.id;
    this.editDraft = c.body;
    this.editMentions = (c.mentions ?? []).map((m) => ({ ...m }));
  }

  handleCancelEdit() {
    this.editingId = undefined;
    this.editDraft = "";
    this.editMentions = [];
  }

  async handleSave() {
    if (!this.editDraft.trim()) {
      this.toast(BODY_REQUIRED, "error");
      return;
    }
    this.isSaving = true;
    try {
      await editComment({
        commentId: this.editingId,
        body: this.editDraft,
        mentionedUserIds: this.editMentions.map((m) => m.id)
      });
      this.handleCancelEdit();
      this.toast(SAVED, "success");
      await this.load();
    } catch (e) {
      this.toast(this.messageOf(e), "error");
    } finally {
      this.isSaving = false;
    }
  }

  async handleDelete(event) {
    const id = event.target.dataset.id;
    const ok = await LightningConfirm.open({
      message: DELETE_CONFIRM,
      variant: "headerless"
    });
    if (!ok) {
      return;
    }
    this.isSaving = true;
    try {
      await deleteComment({ commentId: id });
      this.toast(DELETED, "success");
      await this.load();
    } catch (e) {
      this.toast(this.messageOf(e), "error");
    } finally {
      this.isSaving = false;
    }
  }

  /** 서버가 라벨 문구로 만든 AuraHandledException만 보이고, 그 밖은 공통 문구. */
  messageOf(e) {
    return e?.body?.message || ERROR;
  }

  toast(message, variant) {
    this.dispatchEvent(new ShowToastEvent({ message, variant }));
  }
}
