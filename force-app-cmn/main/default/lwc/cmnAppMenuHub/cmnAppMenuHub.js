import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import FORM_FACTOR from "@salesforce/client/formFactor";
import getMenu from "@salesforce/apex/CMN_AppMenuController.getMenu";
import getHub from "@salesforce/apex/CMN_AppMenuController.getHub";
import findRecord from "@salesforce/apex/CMN_AppMenuController.findRecord";
import READY from "@salesforce/label/c.CMN_AppMenu_Ready";
import PLANNED from "@salesforce/label/c.CMN_AppMenu_Planned";
import PLANNED_IN from "@salesforce/label/c.CMN_AppMenu_PlannedIn";
import OPEN from "@salesforce/label/c.CMN_AppMenu_Open";
import SUMMARY from "@salesforce/label/c.CMN_AppMenu_Summary";
import EMPTY from "@salesforce/label/c.CMN_AppMenu_Empty";
import SEARCH_LABEL from "@salesforce/label/c.CMN_AppMenu_SearchLabel";
import SEARCH_PLACEHOLDER from "@salesforce/label/c.CMN_AppMenu_SearchPlaceholder";
import SEARCH_HINT from "@salesforce/label/c.CMN_AppMenu_SearchHint";
import NOT_FOUND from "@salesforce/label/c.CMN_AppMenu_RecordNotFound";
import NO_MATCH from "@salesforce/label/c.CMN_AppMenu_NoMatch";
import OPEN_MENU from "@salesforce/label/c.CMN_AppMenu_OpenMenu";
import PENDING from "@salesforce/label/c.CMN_AppMenu_Pending";
import OVERDUE from "@salesforce/label/c.CMN_AppMenu_Overdue";
import REFRESH from "@salesforce/label/c.CMN_AppMenu_Refresh";
import JUMP_TO from "@salesforce/label/c.CMN_AppMenu_JumpTo";
import RETRY from "@salesforce/label/c.CMN_TodoList_Retry";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

const PAGE_REFS = {
  OBJECT: (target) => ({
    type: "standard__objectPage",
    attributes: { objectApiName: target, actionName: "home" }
  }),
  PAGE: (target) => ({
    type: "standard__navItemPage",
    attributes: { apiName: target }
  })
};

const fill = (label, value) => label.replace("{0}", value);

/**
 * 앱 메뉴 허브(CMN-00-UX-007, A0 골격에서 시작).
 * - menuKey가 있으면 메뉴별 모드: 메뉴 하나의 기능 타일.
 * - menuKey가 없으면 전체 메뉴 모드: 현재 앱의 메뉴 그룹 전부, 화면 검색, 업무 번호 바로가기, 그룹 바로가기, 미결 배지.
 * 화면이 있는 기능은 목록·앱 페이지를 열고, 아직 없는 기능은 '준비 중'과 1차 화면 묶음을 표시한다.
 */
export default class CmnAppMenuHub extends NavigationMixin(LightningElement) {
  /** 메뉴 키(CMN_AppMenu__mdt). 비우면 전체 메뉴 모드 */
  @api menuKey;
  /** 전체 메뉴 모드에서 앱을 고정할 때(비우면 사용자의 현재 앱) */
  @api appName;

  labels = {
    open: OPEN,
    empty: EMPTY,
    retry: RETRY,
    loading: LOADING,
    searchLabel: SEARCH_LABEL,
    searchPlaceholder: SEARCH_PLACEHOLDER,
    searchHint: SEARCH_HINT,
    noMatch: NO_MATCH,
    openMenu: OPEN_MENU,
    refresh: REFRESH,
    jumpTo: JUMP_TO
  };
  menu;
  hub;
  groups = [];
  searchTerm = "";
  findMessage;
  isLoading = true;
  errorMessage;

  connectedCallback() {
    this.load();
  }

  get isHub() {
    return !this.menuKey;
  }

  async load() {
    this.isLoading = true;
    try {
      if (this.isHub) {
        const hub = await getHub({
          appName: this.appName || null,
          formFactor: FORM_FACTOR
        });
        this.hub = hub;
        this.menu = undefined;
        this.groups = (hub?.groups ?? []).map((g) => this.toGroup(g));
      } else {
        const view = await getMenu({ menuKey: this.menuKey });
        this.menu = view;
        this.groups = view ? [this.toGroup(view)] : [];
      }
      this.errorMessage = undefined;
    } catch (e) {
      this.errorMessage = e?.body?.message || ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  toGroup(view) {
    return {
      ...view,
      sectionKey: `section-${view.menuKey}`,
      hasPageTab: !!view.pageTab,
      items: (view.items ?? []).map((i) => ({
        ...i,
        statusLabel: i.ready ? READY : PLANNED,
        statusClass: i.ready
          ? "slds-badge slds-theme_success"
          : "slds-badge slds-badge_lightest",
        plannedText: !i.ready && i.bundle ? fill(PLANNED_IN, i.bundle) : null,
        pendingText: i.pendingCount > 0 ? fill(PENDING, i.pendingCount) : null,
        overdueText: i.overdueCount > 0 ? fill(OVERDUE, i.overdueCount) : null,
        searchText: [i.title, i.description, i.featureCode, i.keywords]
          .filter(Boolean)
          .join(" ")
          .toLowerCase()
      }))
    };
  }

  /** 검색어로 거른 그룹(그룹 안 타일이 하나도 안 맞으면 그룹도 숨김). */
  get visibleGroups() {
    const term = this.searchTerm.trim().toLowerCase();
    if (!term) {
      return this.groups;
    }
    return this.groups
      .map((g) => ({
        ...g,
        items: g.items.filter((i) => i.searchText.includes(term))
      }))
      .filter((g) => g.items.length > 0);
  }

  get hasVisibleGroups() {
    return this.visibleGroups.length > 0;
  }

  get isEmpty() {
    return this.groups.every((g) => g.items.length === 0);
  }

  get showNoMatch() {
    return !this.isEmpty && !!this.searchTerm.trim() && !this.hasVisibleGroups;
  }

  get looksLikeNumber() {
    const term = this.searchTerm.trim().toUpperCase();
    return (
      !!term && (this.hub?.numberPrefixes ?? []).some((p) => term.startsWith(p))
    );
  }

  get title() {
    return this.isHub ? this.hub?.title : this.menu?.title;
  }

  get description() {
    return this.isHub ? this.hub?.description : this.menu?.description;
  }

  get iconName() {
    return this.isHub
      ? "standard:apps"
      : this.menu?.iconName || "standard:custom";
  }

  get summary() {
    const tiles = this.groups.reduce((n, g) => n + g.items.length, 0);
    const ready = this.groups.reduce((n, g) => n + (g.readyCount ?? 0), 0);
    return SUMMARY.replace("{0}", tiles).replace("{1}", ready);
  }

  get showGroupHeaders() {
    return this.isHub;
  }

  handleSearch(event) {
    this.searchTerm = event.target.value ?? "";
    this.findMessage = undefined;
  }

  async handleSearchKey(event) {
    if (event.key !== "Enter" || !this.looksLikeNumber) {
      return;
    }
    try {
      const result = await findRecord({ recordNo: this.searchTerm.trim() });
      if (result?.found) {
        this.findMessage = undefined;
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: result.recordId,
            objectApiName: result.objectApiName,
            actionName: "view"
          }
        });
      } else {
        this.findMessage = result?.message || NOT_FOUND;
      }
    } catch (e) {
      this.findMessage = e?.body?.message || ERROR;
    }
  }

  jump(event) {
    const key = event.currentTarget.dataset.key;
    const section = this.template.querySelector(`[data-section="${key}"]`);
    section?.scrollIntoView?.({ behavior: "smooth", block: "start" });
  }

  openMenu(event) {
    const tab = event.currentTarget.dataset.tab;
    if (tab) {
      this[NavigationMixin.Navigate](PAGE_REFS.PAGE(tab));
    }
  }

  open(event) {
    const key = event.currentTarget.dataset.key;
    const item = this.groups.flatMap((g) => g.items).find((i) => i.key === key);
    const toRef = PAGE_REFS[item?.targetType];
    if (toRef) {
      this[NavigationMixin.Navigate](toRef(item.target));
    }
  }
}
