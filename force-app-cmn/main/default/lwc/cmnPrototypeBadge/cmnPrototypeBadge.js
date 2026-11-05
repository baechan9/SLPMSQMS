import { LightningElement, api } from "lwc";
import MOCK_BADGE from "@salesforce/label/c.CMN_Prototype_MockBadge";

/**
 * "예시 데이터" 표시(A0 프로토 공용 장치). 목 응답(isMock = true)을 그리는 화면 구석에 둔다.
 * 실제 데이터로 바뀌면(B단계) show가 false가 되어 사라진다.
 */
export default class CmnPrototypeBadge extends LightningElement {
  @api show = false;
  label = MOCK_BADGE;
}
