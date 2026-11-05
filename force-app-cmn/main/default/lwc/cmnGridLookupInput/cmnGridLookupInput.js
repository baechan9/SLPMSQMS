import { LightningElement, api } from "lwc";
import SEARCH from "@salesforce/label/c.CMN_Grid_LookupSearch";

/**
 * 그리드 참조(Lookup) 셀 편집(CMN-00-UX-006 BR-8). lightning-datatable 편집 템플릿의 data-inputable 요소라
 * value·focus·validity·showHelpMessageIfInvalid를 표준 입력처럼 내보낸다.
 * filter: [{fieldPath, value}] → lightning-record-picker 조건(같음). 'true'·'false'는 불리언으로 바꾼다.
 */
export default class CmnGridLookupInput extends LightningElement {
  @api objectApiName;
  @api label;
  @api required = false;
  @api filter;
  placeholder = SEARCH;
  _value;

  @api
  get value() {
    return this._value;
  }
  set value(v) {
    this._value = v || null;
  }

  @api
  get validity() {
    return { valid: !this.required || !!this._value };
  }

  @api
  focus() {
    this.refs.picker?.focus?.();
  }

  @api
  showHelpMessageIfInvalid() {
    this.refs.picker?.reportValidity?.();
  }

  get pickerFilter() {
    const terms = (this.filter ?? []).filter((t) => t?.fieldPath);
    if (!terms.length) {
      return undefined;
    }
    return {
      criteria: terms.map((t) => ({
        fieldPath: t.fieldPath,
        operator: "eq",
        value: t.value === "true" ? true : t.value === "false" ? false : t.value
      }))
    };
  }

  handleChange(event) {
    this._value = event.detail?.recordId ?? null;
  }
}
