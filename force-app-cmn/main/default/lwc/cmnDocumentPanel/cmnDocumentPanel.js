import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getPanel from "@salesforce/apex/CMN_DocumentController.getPanel";
import registerFiles from "@salesforce/apex/CMN_DocumentController.registerFiles";
import registerLink from "@salesforce/apex/CMN_DocumentController.registerLink";
import submitDocument from "@salesforce/apex/CMN_DocumentController.submitDocument";
import TITLE from "@salesforce/label/c.CMN_Doc_Title";
import UPLOAD from "@salesforce/label/c.CMN_Doc_Upload";
import CLASS_LABEL from "@salesforce/label/c.CMN_Doc_Class";
import CHANGE_NOTE from "@salesforce/label/c.CMN_Doc_ChangeNote";
import SUPPLIER_VISIBLE from "@salesforce/label/c.CMN_Doc_SupplierVisible";
import ADD_LINK from "@salesforce/label/c.CMN_Doc_AddLink";
import STORAGE from "@salesforce/label/c.CMN_Doc_Storage";
import URL_LABEL from "@salesforce/label/c.CMN_Doc_Url";
import EXTERNAL_REF from "@salesforce/label/c.CMN_Doc_ExternalRef";
import LINK_TITLE from "@salesforce/label/c.CMN_Doc_LinkTitle";
import SAVE from "@salesforce/label/c.CMN_Doc_Save";
import CANCEL from "@salesforce/label/c.CMN_Doc_Cancel";
import TEMPLATE from "@salesforce/label/c.CMN_Doc_Template";
import HISTORY from "@salesforce/label/c.CMN_Doc_History";
import REQUIRED from "@salesforce/label/c.CMN_Doc_Required";
import MISSING from "@salesforce/label/c.CMN_Doc_Missing";
import DUPLICATE from "@salesforce/label/c.CMN_Doc_Duplicate";
import EMPTY from "@salesforce/label/c.CMN_Doc_Empty";
import REGISTERED from "@salesforce/label/c.CMN_Doc_Registered";
import SUBMIT from "@salesforce/label/c.CMN_Doc_Submit";
import SUBMITTED from "@salesforce/label/c.CMN_Doc_Submitted";
import REVISION from "@salesforce/label/c.CMN_Doc_Revision";
import NO_READ from "@salesforce/label/c.CMN_Doc_NoReadAccess";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

const STORAGE_TYPES = ["SHAREPOINT", "PDM", "DMS", "URL", "SF_RECORD"];

/**
 * 문서·리비전 패널(CMN-00-DOC-001).
 * - 분류별(허용 목록 순서) 현재 리비전·상태·중복 경고, 이력 펼치기, 필수 분류 누락 표시, 양식 내려받기.
 * - 업로드: 파일은 먼저 사용자 개인 파일로 올리고(record-id 없음), 서버가 크기·분류 규칙을 확인한 뒤 문서에 연결한다.
 *   크기를 넘으면 서버가 올린 파일을 지우고 링크 등록을 안내한다.
 * - 링크: 외부 저장소(SharePoint·PDM·DMS·URL) 링크 또는 외부 문서 번호.
 * - 결재형 문서의 작성 중 리비전은 결재선 템플릿으로 상신한다(결재선 편집은 결재 화면).
 */
export default class CmnDocumentPanel extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api allowedDocClasses;
  @api requiredDocClasses;

  labels = {
    title: TITLE,
    upload: UPLOAD,
    docClass: CLASS_LABEL,
    changeNote: CHANGE_NOTE,
    supplierVisible: SUPPLIER_VISIBLE,
    addLink: ADD_LINK,
    storage: STORAGE,
    url: URL_LABEL,
    externalRef: EXTERNAL_REF,
    linkTitle: LINK_TITLE,
    save: SAVE,
    cancel: CANCEL,
    template: TEMPLATE,
    history: HISTORY,
    required: REQUIRED,
    missing: MISSING,
    duplicate: DUPLICATE,
    empty: EMPTY,
    submit: SUBMIT,
    noRead: NO_READ,
    loading: LOADING
  };
  panel;
  isLoading = true;
  isSaving = false;
  errorMessage;
  selectedClassId;
  changeNote = "";
  supplierVisible = false;
  showLink = false;
  link = {};
  expanded = {};

  connectedCallback() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      this.panel = await getPanel({
        parentId: this.recordId,
        allowedDocClasses: this.allowedDocClasses ?? null,
        requiredDocClasses: this.requiredDocClasses ?? null
      });
      this.errorMessage = undefined;
    } catch (e) {
      this.errorMessage = this.messageOf(e);
    } finally {
      this.isLoading = false;
    }
  }

  get canRead() {
    return this.panel?.canRead === true;
  }

  get canEdit() {
    return this.panel?.canEdit === true;
  }

  get noAccess() {
    return !this.isLoading && !this.errorMessage && this.panel && !this.canRead;
  }

  get groups() {
    return (this.panel?.classes ?? [])
      .filter((g) => g.documents.length > 0 || g.required)
      .map((g) => ({
        ...g,
        templateUrl: g.templateDocumentId
          ? `/sfc/servlet.shepherd/document/download/${g.templateDocumentId}`
          : null,
        documents: g.documents.map((d) => this.decorate(d))
      }));
  }

  get isEmpty() {
    return this.canRead && this.groups.length === 0;
  }

  decorate(d) {
    const revisions = d.revisions.map((r) => ({
      ...r,
      label: REVISION.replace("{0}", r.revisionNo),
      isFile: r.storageType === "SF_FILE",
      isLink: r.storageType !== "SF_FILE" && !!r.url,
      displayName: r.fileName || r.externalRef || r.url
    }));
    const current =
      revisions.find((r) => r.id === d.current?.id) ?? revisions[0] ?? null;
    return {
      ...d,
      currentView: current,
      revisions,
      isExpanded: this.expanded[d.id] === true
    };
  }

  get uploadClassOptions() {
    return (this.panel?.classes ?? [])
      .filter((g) => !g.linkOnly)
      .map((g) => ({ label: g.label, value: g.classId }));
  }

  get linkClassOptions() {
    return (this.panel?.classes ?? []).map((g) => ({
      label: g.label,
      value: g.classId
    }));
  }

  get storageOptions() {
    return STORAGE_TYPES.map((s) => ({ label: s, value: s }));
  }

  get selectedClass() {
    return (this.panel?.classes ?? []).find(
      (g) => g.classId === this.selectedClassId
    );
  }

  get multipleUpload() {
    return this.selectedClass?.multiFile === true;
  }

  get uploadDisabled() {
    return !this.selectedClassId || this.isSaving;
  }

  handleClass(event) {
    this.selectedClassId = event.detail.value;
  }

  handleNote(event) {
    this.changeNote = event.detail.value ?? "";
  }

  handleVisible(event) {
    this.supplierVisible = event.detail.checked === true;
  }

  async handleUploadFinished(event) {
    const ids = (event.detail.files ?? []).map((f) => f.documentId);
    if (!ids.length) {
      return;
    }
    this.isSaving = true;
    try {
      await registerFiles({
        parentId: this.recordId,
        docClassId: this.selectedClassId,
        contentDocumentIds: ids,
        changeNote: this.changeNote,
        supplierVisible: this.supplierVisible
      });
      this.changeNote = "";
      this.toast(REGISTERED, "success");
      await this.load();
    } catch (e) {
      this.toast(this.messageOf(e), "error");
    } finally {
      this.isSaving = false;
    }
  }

  toggleLink() {
    this.showLink = !this.showLink;
    this.link = {};
  }

  handleLinkField(event) {
    this.link = {
      ...this.link,
      [event.target.dataset.field]: event.detail.value
    };
  }

  async handleSaveLink() {
    this.isSaving = true;
    try {
      await registerLink({
        parentId: this.recordId,
        docClassId: this.link.classId,
        storageType: this.link.storageType,
        url: this.link.url ?? null,
        externalRef: this.link.externalRef ?? null,
        title: this.link.title ?? null,
        changeNote: this.link.note ?? null
      });
      this.showLink = false;
      this.link = {};
      this.toast(REGISTERED, "success");
      await this.load();
    } catch (e) {
      this.toast(this.messageOf(e), "error");
    } finally {
      this.isSaving = false;
    }
  }

  toggleHistory(event) {
    const id = event.target.dataset.id;
    this.expanded = { ...this.expanded, [id]: !this.expanded[id] };
  }

  openFile(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__namedPage",
      attributes: { pageName: "filePreview" },
      state: { selectedRecordId: event.target.dataset.file }
    });
  }

  async handleSubmit(event) {
    this.isSaving = true;
    try {
      await submitDocument({
        documentId: event.target.dataset.id,
        comment: null
      });
      this.toast(SUBMITTED, "success");
      await this.load();
    } catch (e) {
      this.toast(this.messageOf(e), "error");
    } finally {
      this.isSaving = false;
    }
  }

  /** 서버가 라벨 문구로 만든 오류만 보이고, 그 밖은 공통 문구. */
  messageOf(e) {
    return e?.body?.message || ERROR;
  }

  toast(message, variant) {
    this.dispatchEvent(new ShowToastEvent({ message, variant }));
  }
}
