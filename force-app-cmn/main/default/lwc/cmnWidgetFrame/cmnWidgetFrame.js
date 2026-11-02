import { LightningElement, api } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import NO_ACCESS from "@salesforce/label/c.CMN_WidgetBoard_NoAccess";
import UNAVAILABLE from "@salesforce/label/c.CMN_WidgetBoard_Unavailable";
import WIDGET_ERROR from "@salesforce/label/c.CMN_WidgetBoard_WidgetError";
import RETRY from "@salesforce/label/c.CMN_WidgetBoard_Retry";
import NOT_ON_MOBILE from "@salesforce/label/c.CMN_WidgetBoard_NotOnMobile";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";

const COMPONENT_NAME = /^[a-z][A-Za-z0-9]{1,79}$/;

/**
 * 위젯 한 칸(CMN-00-DSH-001 BR-1·BR-2·BR-4·AC-3).
 * - 컴포넌트는 lwc:is 동적 로드, 화면에 보일 때(Intersection Observer) 처음 로드한다.
 * - 위젯이 렌더링 중 예외를 내면 errorCallback이 이 칸만 오류로 바꾼다(보드 전체는 계속 동작).
 * - 보드 공통 필터(공장·기간)는 위젯 config보다 우선해 병합한다(BR-6).
 */
export default class CmnWidgetFrame extends LightningElement {
  @api widget;
  @api systemCode;
  @api filters;

  labels = { retry: RETRY, loading: LOADING };
  ctor;
  isVisible = false;
  hasError = false;
  isLoading = false;
  observer;

  connectedCallback() {
    if (typeof IntersectionObserver === "undefined") {
      this.isVisible = true;
      this.load();
    }
  }

  renderedCallback() {
    if (
      this.isVisible ||
      this.observer ||
      typeof IntersectionObserver === "undefined"
    ) {
      return;
    }
    this.observer = new IntersectionObserver((entries) => {
      if (entries.some((e) => e.isIntersecting)) {
        this.isVisible = true;
        this.observer.disconnect();
        this.load();
      }
    });
    this.observer.observe(this.template.host);
  }

  disconnectedCallback() {
    this.observer?.disconnect();
  }

  errorCallback() {
    // 위젯 하나의 예외는 이 칸에서 끝낸다(AC-3)
    this.hasError = true;
  }

  async load() {
    const name = this.widget?.componentName;
    if (!this.isRenderable || !COMPONENT_NAME.test(name ?? "")) {
      return;
    }
    this.isLoading = true;
    try {
      const mod = await import(`c/${name}`);
      this.ctor = mod.default;
      this.hasError = false;
    } catch {
      this.hasError = true;
    } finally {
      this.isLoading = false;
    }
  }

  handleRetry() {
    this.hasError = false;
    this.ctor = undefined;
    this.load();
  }

  get isRenderable() {
    return this.widget?.state === "OK" && !this.notOnMobile;
  }

  get notOnMobile() {
    return FORM_FACTOR === "Small" && this.widget?.mobileSupported === false;
  }

  get placeholder() {
    if (this.widget?.state === "NO_ACCESS") {
      return NO_ACCESS;
    }
    if (this.widget?.state !== "OK") {
      return UNAVAILABLE;
    }
    return this.notOnMobile ? NOT_ON_MOBILE : null;
  }

  get errorText() {
    return WIDGET_ERROR;
  }

  get showWidget() {
    return !this.placeholder && !this.hasError && !!this.ctor;
  }

  get config() {
    let base = {};
    try {
      base = JSON.parse(this.widget?.configJson || "{}");
    } catch {
      base = {};
    }
    const merged = { ...base, system: this.systemCode };
    if (this.filters?.plantId) {
      merged.plantId = this.filters.plantId;
    }
    if (this.filters?.period) {
      merged.period = this.filters.period;
    }
    return merged;
  }
}
