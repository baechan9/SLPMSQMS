import { LightningElement, api } from "lwc";

/**
 * 그리드 셀 표시(CMN-00-UX-006). lightning-datatable 커스텀 타입의 보기 템플릿이 쓴다.
 * - 기본: 선택 목록이면 값의 사용자 언어 라벨, 참조·코드면 표시명(display), 없으면 값
 * - state: 행 상태 문구와 아이콘, 행 경고(아이콘 + 문구). 색만으로 구분하지 않는다
 */
export default class CmnGridCellLabel extends LightningElement {
  @api value;
  @api options;
  @api display;
  @api variant;
  @api icon;
  @api warning;

  get isState() {
    return this.variant === "state";
  }

  get text() {
    if (this.value === null || this.value === undefined || this.value === "") {
      return "";
    }
    const hit = (this.options ?? []).find((o) => o.value === this.value);
    return hit?.label ?? this.display ?? String(this.value);
  }
}
