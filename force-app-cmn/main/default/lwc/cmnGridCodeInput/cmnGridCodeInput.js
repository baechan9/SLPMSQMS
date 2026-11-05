import { LightningElement, api } from "lwc";

/**
 * 그리드 공통 코드(CODE) 셀 편집(CMN-00-UX-006 BR-8, MDM-007 cmnCodePicker).
 * lightning-datatable 편집 템플릿의 data-inputable 요소라 value·focus·validity·showHelpMessageIfInvalid를 내보낸다.
 * 리프 코드를 골라야 value가 정해진다(대→중→소). 표시명은 그리드가 서버 참조 확인으로 가져온다.
 */
export default class CmnGridCodeInput extends LightningElement {
  @api groupCode;
  @api label;
  @api required = false;
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
    this.template.querySelector("c-cmn-code-picker")?.focus?.();
  }

  @api
  showHelpMessageIfInvalid() {
    // 코드 선택기는 각 단계 콤보박스가 필수 표시를 한다
  }

  handleChange(event) {
    this._value = event.detail?.value ?? null;
  }
}
