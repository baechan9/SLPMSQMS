import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getTodos from "@salesforce/apex/CMN_TodoListController.getTodos";
import TITLE from "@salesforce/label/c.CMN_TodoList_Title";
import TAB_TASK from "@salesforce/label/c.CMN_TodoList_TabTask";
import TAB_APPROVAL from "@salesforce/label/c.CMN_TodoList_TabApproval";
import SYSTEM from "@salesforce/label/c.CMN_TodoList_System";
import SYSTEM_ALL from "@salesforce/label/c.CMN_TodoList_SystemAll";
import DUE from "@salesforce/label/c.CMN_TodoList_Due";
import NO_DUE from "@salesforce/label/c.CMN_TodoList_NoDue";
import OVERDUE from "@salesforce/label/c.CMN_TodoList_Overdue";
import DELEGATED from "@salesforce/label/c.CMN_TodoList_Delegated";
import EMPTY from "@salesforce/label/c.CMN_TodoList_Empty";
import LOAD_MORE from "@salesforce/label/c.CMN_TodoList_LoadMore";
import REFRESH from "@salesforce/label/c.CMN_TodoList_Refresh";
import RETRY from "@salesforce/label/c.CMN_TodoList_Retry";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

const TASK = "TASK";
const APPROVAL = "APPROVAL";

/**
 * 메인 홈 To-Do 목록(CMN-00-TDO-004 BR-1·BR-2). 업무·결재 탭(건수 배지), 시스템 필터(앱 기본값),
 * 기한 경과는 빨간 글씨와 문구로 함께 표시, 한 번에 20건 + 더 보기. 항목을 누르면 서버가 정한 레코드(결재는 결재 요청)를 연다.
 */
export default class CmnTodoList extends NavigationMixin(LightningElement) {
  @api systemCode = "QMS";

  labels = {
    title: TITLE,
    system: SYSTEM,
    empty: EMPTY,
    loadMore: LOAD_MORE,
    refresh: REFRESH,
    retry: RETRY,
    loading: LOADING,
    overdue: OVERDUE,
    delegated: DELEGATED
  };
  systemOptions = [
    { label: "QMS", value: "QMS" },
    { label: "PMS", value: "PMS" },
    { label: SYSTEM_ALL, value: "ALL" }
  ];
  category = TASK;
  systemFilter;
  items = [];
  taskCount = 0;
  approvalCount = 0;
  hasMore = false;
  isLoading = true;
  isLoadingMore = false;
  errorMessage;

  connectedCallback() {
    this.systemFilter = this.systemCode || "QMS";
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      const page = await this.fetch(0);
      this.items = this.decorate(page?.items ?? []);
      this.errorMessage = undefined;
    } catch (e) {
      this.errorMessage = e?.body?.message || ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  async handleLoadMore() {
    this.isLoadingMore = true;
    try {
      const page = await this.fetch(this.items.length);
      this.items = [...this.items, ...this.decorate(page?.items ?? [])];
    } catch (e) {
      this.errorMessage = e?.body?.message || ERROR;
    } finally {
      this.isLoadingMore = false;
    }
  }

  async fetch(offsetRows) {
    const page = await getTodos({
      category: this.category,
      systemFilter: this.systemFilter,
      offsetRows
    });
    this.taskCount = page?.taskCount ?? 0;
    this.approvalCount = page?.approvalCount ?? 0;
    this.hasMore = page?.hasMore === true;
    return page;
  }

  decorate(rows) {
    return rows.map((t) => ({
      ...t,
      dueText: t.dueDate ? DUE.replace("{0}", t.dueDate) : NO_DUE,
      dueClass: t.isOverdue ? "slds-text-color_error" : "slds-text-color_weak",
      meta: [t.recordNo, t.plantName].filter((v) => v).join(" · ")
    }));
  }

  get taskTabLabel() {
    return `${TAB_TASK} (${this.taskCount})`;
  }

  get approvalTabLabel() {
    return `${TAB_APPROVAL} (${this.approvalCount})`;
  }

  get isEmpty() {
    return this.items.length === 0;
  }

  handleTab(event) {
    const next = event.target.value;
    if (next !== this.category) {
      this.category = next === APPROVAL ? APPROVAL : TASK;
      this.load();
    }
  }

  handleSystem(event) {
    this.systemFilter = event.detail.value;
    this.load();
  }

  open(event) {
    const id = event.currentTarget.dataset.id;
    if (id) {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: { recordId: id, actionName: "view" }
      });
    }
  }
}
