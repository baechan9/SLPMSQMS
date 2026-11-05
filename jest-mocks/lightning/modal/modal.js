/**
 * Jest 전용 lightning/modal 대체(sfdx-lwc-jest에 스텁이 없다). LightningModal을 상속한 대화상자를 단독으로 렌더링하고,
 * close(결과)는 테스트가 확인할 수 있게 마지막 결과를 남긴다. open은 각 테스트가 jest.fn으로 바꿔 쓴다.
 */
import { LightningElement, api } from "lwc";

export default class LightningModal extends LightningElement {
  @api label;
  @api size;
  @api description;

  static open = jest.fn(() => Promise.resolve(undefined));

  close(result) {
    this.closedWith = result;
    this.dispatchEvent(new CustomEvent("close", { detail: result }));
  }
}
