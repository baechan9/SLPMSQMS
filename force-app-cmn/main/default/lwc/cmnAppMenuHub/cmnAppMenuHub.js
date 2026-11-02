import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getMenu from "@salesforce/apex/CMN_AppMenuController.getMenu";
import READY from "@salesforce/label/c.CMN_AppMenu_Ready";
import PLANNED from "@salesforce/label/c.CMN_AppMenu_Planned";
import PLANNED_IN from "@salesforce/label/c.CMN_AppMenu_PlannedIn";
import OPEN from "@salesforce/label/c.CMN_AppMenu_Open";
import SUMMARY from "@salesforce/label/c.CMN_AppMenu_Summary";
import EMPTY from "@salesforce/label/c.CMN_AppMenu_Empty";
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

/**
 * 앱 메뉴 허브(화면 우선 플랜 A0 앱 내비게이션 골격). 메뉴 하나의 기능을 타일로 보여준다.
 * 화면이 있는 기능은 목록·앱 페이지를 열고, 아직 없는 기능은 '준비 중'과 1차 화면 묶음을 표시한다.
 * 타일 구성은 CMN_AppMenuItem__mdt가 정한다(각 묶음이 화면을 만들면 Target을 채운다).
 */
export default class CmnAppMenuHub extends NavigationMixin(LightningElement) {
  @api menuKey;

  labels = { open: OPEN, empty: EMPTY, retry: RETRY, loading: LOADING };
  menu;
  items = [];
  isLoading = true;
  errorMessage;

  connectedCallback() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      const view = await getMenu({ menuKey: this.menuKey });
      this.menu = view;
      this.items = (view?.items ?? []).map((i) => ({
        ...i,
        statusLabel: i.ready ? READY : PLANNED,
        statusClass: i.ready
          ? "slds-badge slds-theme_success"
          : "slds-badge slds-badge_lightest",
        plannedText:
          !i.ready && i.bundle ? PLANNED_IN.replace("{0}", i.bundle) : null
      }));
      this.errorMessage = undefined;
    } catch (e) {
      this.errorMessage = e?.body?.message || ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  get isEmpty() {
    return this.items.length === 0;
  }

  get summary() {
    return SUMMARY.replace("{0}", this.items.length).replace(
      "{1}",
      this.menu?.readyCount ?? 0
    );
  }

  get iconName() {
    return this.menu?.iconName || "standard:custom";
  }

  open(event) {
    const item = this.items.find(
      (i) => i.key === event.currentTarget.dataset.key
    );
    const toRef = PAGE_REFS[item?.targetType];
    if (toRef) {
      this[NavigationMixin.Navigate](toRef(item.target));
    }
  }
}
