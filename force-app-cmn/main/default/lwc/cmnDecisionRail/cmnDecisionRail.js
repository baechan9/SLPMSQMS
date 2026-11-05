import { LightningElement, api, wire } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import getPanels from "@salesforce/apex/CMN_RailPanelController.getPanels";
import TITLE from "@salesforce/label/c.CMN_DecisionRail_Title";
import EMPTY from "@salesforce/label/c.CMN_DecisionRail_Empty";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

const STORE_PREFIX = "cmnDecisionRail:";

/**
 * 결정 지원 레일(CMN-00-UX-004 BR-1·5·8). 업무 레코드 페이지 사이드바의 유일한 컴포넌트다.
 * 패널 목록·순서·기본 펼침은 CMN_RailPanel__mdt(서버)가 정하고, 사용자가 접고 편 상태는 브라우저에 객체별로 남긴다.
 * 휴대폰은 PhoneOrder 순서로 본문 아래에 보인다.
 */
export default class CmnDecisionRail extends LightningElement {
  @api recordId;
  @api objectApiName;

  labels = { title: TITLE, empty: EMPTY };
  panels = [];
  errorMessage;
  loaded = false;

  @wire(getPanels, { objectApiName: "$objectApiName" })
  wiredPanels({ data, error }) {
    if (data) {
      const stored = this.readState();
      const phone = FORM_FACTOR === "Small";
      const list = [...data];
      if (phone) {
        list.sort((a, b) => (a.phoneOrder ?? 999) - (b.phoneOrder ?? 999));
      }
      this.panels = list.map((p) => ({
        ...p,
        open: stored[p.key] ?? p.defaultOpen === true
      }));
      this.errorMessage = undefined;
      this.loaded = true;
    } else if (error) {
      this.panels = [];
      this.errorMessage = ERROR;
      this.loaded = true;
    }
  }

  get isEmpty() {
    return this.loaded && !this.errorMessage && this.panels.length === 0;
  }

  handleToggle(event) {
    const { key, open } = event.detail ?? {};
    this.panels = this.panels.map((p) => (p.key === key ? { ...p, open } : p));
    this.writeState();
  }

  get storeKey() {
    return STORE_PREFIX + (this.objectApiName ?? "");
  }

  readState() {
    try {
      return JSON.parse(window.localStorage.getItem(this.storeKey) || "{}");
    } catch {
      // 브라우저 저장소를 쓸 수 없으면 기본 펼침을 쓴다
      return {};
    }
  }

  writeState() {
    try {
      const state = {};
      this.panels.forEach((p) => {
        state[p.key] = p.open;
      });
      window.localStorage.setItem(this.storeKey, JSON.stringify(state));
    } catch {
      // 저장 실패는 화면 동작에 영향이 없다
    }
  }
}
