import { LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getMonitor from "@salesforce/apex/CMN_ApprovalController.getMonitor";
import getTypes from "@salesforce/apex/CMN_ApprovalController.getTypes";
import TITLE from "@salesforce/label/c.CMN_ApprovalMonitor_Title";
import SUBMITTED from "@salesforce/label/c.CMN_ApprovalMonitor_Submitted";
import ACTED from "@salesforce/label/c.CMN_ApprovalMonitor_Acted";
import IN_PROGRESS from "@salesforce/label/c.CMN_ApprovalMonitor_InProgress";
import TYPE_FILTER from "@salesforce/label/c.CMN_ApprovalMonitor_TypeFilter";
import FROM_DATE from "@salesforce/label/c.CMN_ApprovalMonitor_From";
import TO_DATE from "@salesforce/label/c.CMN_ApprovalMonitor_To";
import SEARCH from "@salesforce/label/c.CMN_ApprovalMonitor_Search";
import EMPTY from "@salesforce/label/c.CMN_ApprovalMonitor_Empty";
import RECORD_NO from "@salesforce/label/c.CMN_ApprovalMonitor_RecordNo";
import TITLE_COL from "@salesforce/label/c.CMN_ApprovalMonitor_TitleCol";
import PLANT from "@salesforce/label/c.CMN_ApprovalMonitor_Plant";
import STATUS from "@salesforce/label/c.CMN_ApprovalMonitor_Status";
import DRAFTER from "@salesforce/label/c.CMN_ApprovalMonitor_Drafter";
import SUBMITTED_AT from "@salesforce/label/c.CMN_ApprovalMonitor_SubmittedAt";
import APPROVERS from "@salesforce/label/c.CMN_ApprovalMonitor_Approvers";
import PENDING_DAYS from "@salesforce/label/c.CMN_ApprovalMonitor_PendingDays";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

const COLUMNS = [
  {
    label: RECORD_NO,
    type: "button",
    typeAttributes: {
      label: { fieldName: "recordNo" },
      name: "open",
      variant: "base"
    }
  },
  { label: TITLE_COL, fieldName: "title", wrapText: true },
  { label: PLANT, fieldName: "plantCode" },
  { label: STATUS, fieldName: "status" },
  { label: DRAFTER, fieldName: "drafterName" },
  {
    label: SUBMITTED_AT,
    fieldName: "submittedAt",
    type: "date",
    typeAttributes: { year: "numeric", month: "2-digit", day: "2-digit" }
  },
  { label: APPROVERS, fieldName: "pendingApprovers", wrapText: true },
  { label: PENDING_DAYS, fieldName: "pendingDays", type: "number" }
];

/**
 * 결재 현황(CMN-00-APV-003 BR-3). 내가 상신 / 내가 처리 / 진행 중(볼 수 있는 것) 세 보기와
 * 유형·공장·상신 기간 필터, 현재 대기 단계의 체류일수를 보인다. 행의 결재 번호를 누르면 결재 요청을 연다.
 */
export default class CmnApprovalMonitor extends NavigationMixin(
  LightningElement
) {
  labels = {
    title: TITLE,
    submitted: SUBMITTED,
    acted: ACTED,
    inProgress: IN_PROGRESS,
    typeFilter: TYPE_FILTER,
    from: FROM_DATE,
    to: TO_DATE,
    search: SEARCH,
    empty: EMPTY,
    plant: PLANT,
    loading: LOADING
  };
  columns = COLUMNS;
  view = "SUBMITTED";
  typeCode = "";
  plantId;
  fromDate;
  toDate;
  rows = [];
  typeOptions = [{ label: "-", value: "" }];
  isLoading = false;
  errorMessage;

  @wire(getTypes)
  wiredTypes({ data }) {
    if (data) {
      this.typeOptions = [{ label: "-", value: "" }, ...data];
    }
  }

  connectedCallback() {
    this.load();
  }

  get isEmpty() {
    return !this.isLoading && !this.errorMessage && this.rows.length === 0;
  }

  get hasRows() {
    return !this.errorMessage && this.rows.length > 0;
  }

  handleView(event) {
    const next = event.target.value;
    if (next && next !== this.view) {
      this.view = next;
      this.load();
    }
  }

  handleType(event) {
    this.typeCode = event.detail.value ?? "";
  }

  handlePlant(event) {
    this.plantId = event.detail.recordId ?? undefined;
  }

  handleFrom(event) {
    this.fromDate = event.detail.value || undefined;
  }

  handleTo(event) {
    this.toDate = event.detail.value || undefined;
  }

  handleSearch() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      const rows = await getMonitor({
        view: this.view,
        typeCode: this.typeCode,
        plantId: this.plantId,
        fromDate: this.fromDate,
        toDate: this.toDate
      });
      this.rows = (rows ?? []).map((r) => ({ ...r, id: r.requestId }));
      this.errorMessage = undefined;
    } catch (e) {
      this.rows = [];
      this.errorMessage = e?.body?.message || ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  handleRowAction(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: { recordId: event.detail.row.requestId, actionName: "view" }
    });
  }
}
