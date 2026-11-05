import { LightningElement, api } from "lwc";
import resolveBindings from "@salesforce/apex/CMN_RailPanelController.resolveBindings";
import PANEL_ERROR from "@salesforce/label/c.CMN_DecisionRail_PanelError";
import RETRY from "@salesforce/label/c.CMN_DecisionRail_Retry";
import BADGE from "@salesforce/label/c.CMN_DecisionRail_Badge";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";

const COMPONENT = /^c\/[a-z][A-Za-z0-9]{1,79}$/;

/**
 * 결정 지원 레일 패널 한 칸(CMN-00-UX-004 BR-5·6·7).
 * - 펼친 패널만 불러온다(접힌 패널은 서버 호출 0건, AC-9). 컴포넌트는 lwc:is 동적 로드.
 * - 패널 하나의 예외는 이 칸에서 끝낸다(errorCallback, AC-4).
 * - 패널 계약: recordId·objectApiName·config·variant="rail"을 넘기고, 패널이 보내는 railbadge 건수를 머리에 표시한다.
 * - 문맥 분석 패널(config.bind)은 레코드 필드 값을 서버에서 읽어 config에 넣는다(위젯 계약, BR-7). 위젯용 size="S"도 넘긴다.
 */
export default class CmnRailPanel extends LightningElement {
  @api panel;
  @api recordId;
  @api objectApiName;

  labels = { error: PANEL_ERROR, retry: RETRY, loading: LOADING };
  ctor;
  config = {};
  hasError = false;
  isLoading = false;
  badge;
  _open = false;
  _connected = false;

  @api
  get open() {
    return this._open;
  }
  set open(value) {
    this._open = !!value;
    if (this._open && this._connected) {
      this.ensureLoaded();
    }
  }

  connectedCallback() {
    this._connected = true;
    if (this._open) {
      this.ensureLoaded();
    }
  }

  errorCallback() {
    // 패널 하나의 렌더링 예외는 이 칸만 오류로 바꾼다(AC-4)
    this.hasError = true;
  }

  ensureLoaded() {
    if (!this.ctor && !this.isLoading && !this.hasError) {
      this.load();
    }
  }

  async load() {
    const name = this.panel?.componentName ?? "";
    if (!COMPONENT.test(name)) {
      this.hasError = true;
      return;
    }
    this.isLoading = true;
    try {
      this.config = await this.buildConfig();
      const mod = await import(`c/${name.slice(2)}`);
      this.ctor = mod.default;
      this.hasError = false;
    } catch {
      this.hasError = true;
    } finally {
      this.isLoading = false;
    }
  }

  async buildConfig() {
    let base = {};
    try {
      base = JSON.parse(this.panel?.config || "{}") ?? {};
    } catch {
      base = {};
    }
    const bind = base.bind;
    if (!bind || !this.recordId) {
      return base;
    }
    const values =
      (await resolveBindings({
        recordId: this.recordId,
        fieldNames: Object.values(bind)
      })) ?? {};
    const bound = {};
    Object.entries(bind).forEach(([key, field]) => {
      bound[key] = values[field] ?? null;
    });
    return { ...base, ...bound };
  }

  get isOpen() {
    return this._open;
  }

  get sectionClass() {
    return this._open ? "slds-section slds-is-open" : "slds-section";
  }

  get chevron() {
    return this._open ? "utility:chevrondown" : "utility:chevronright";
  }

  get ariaExpanded() {
    return this._open ? "true" : "false";
  }

  get hasBadge() {
    return Number.isFinite(this.badge) && this.badge > 0;
  }

  get badgeText() {
    return BADGE.replace("{0}", this.badge);
  }

  get showComponent() {
    return !this.hasError && !!this.ctor;
  }

  toggle() {
    this.dispatchEvent(
      new CustomEvent("toggle", {
        detail: { key: this.panel?.key, open: !this._open }
      })
    );
  }

  handleBadge(event) {
    event.stopPropagation();
    const count = Number(event.detail?.count);
    this.badge = Number.isFinite(count) ? count : undefined;
  }

  handleRetry() {
    this.hasError = false;
    this.ctor = undefined;
    this.load();
  }
}
