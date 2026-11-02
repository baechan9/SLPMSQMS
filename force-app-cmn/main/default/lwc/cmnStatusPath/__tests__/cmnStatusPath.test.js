import { createElement } from "lwc";
import CmnStatusPath from "c/cmnStatusPath";
import { getRecord } from "lightning/uiRecordApi";
import getPath from "@salesforce/apex/CMN_StatusPathController.getPath";

jest.mock(
  "@salesforce/apex/CMN_StatusPathController.getPath",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const PATH = {
  objectApiName: "QMS_NCR__c",
  statusField: "Status__c",
  steps: [
    { value: "DRAFT", label: "Draft", isTerminal: false },
    { value: "IN_PROGRESS", label: "In Progress", isTerminal: false },
    { value: "CLOSED", label: "Closed", isTerminal: true },
    { value: "CANCELLED", label: "Cancelled", isTerminal: true }
  ]
};

function mount() {
  const el = createElement("c-cmn-status-path", { is: CmnStatusPath });
  el.recordId = "a01000000000001AAA";
  document.body.appendChild(el);
  return el;
}

function indicator(el) {
  return el.shadowRoot.querySelector("lightning-progress-indicator");
}

function stepValues(el) {
  return [...el.shadowRoot.querySelectorAll("lightning-progress-step")].map(
    (s) => s.value
  );
}

describe("c-cmn-status-path", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("로딩 중에는 스피너를 보인다", () => {
    const el = mount();
    expect(el.shadowRoot.querySelector("lightning-spinner")).not.toBeNull();
  });

  it("진행 중이면 종료 칸은 정상 완료, 현재 단계를 강조한다", async () => {
    const el = mount();
    getPath.emit(PATH);
    await flush();
    getRecord.emit({ fields: { Status__c: { value: "IN_PROGRESS" } } });
    await flush();
    expect(stepValues(el)).toEqual(["DRAFT", "IN_PROGRESS", "CLOSED"]);
    expect(indicator(el).currentStep).toBe("IN_PROGRESS");
    expect(indicator(el).hasError).toBe(false);
  });

  it("정상 완료가 아닌 종료 상태는 그 상태를 오류로 표시한다", async () => {
    const el = mount();
    getPath.emit(PATH);
    await flush();
    getRecord.emit({ fields: { Status__c: { value: "CANCELLED" } } });
    await flush();
    expect(stepValues(el)).toEqual(["DRAFT", "IN_PROGRESS", "CANCELLED"]);
    expect(indicator(el).currentStep).toBe("CANCELLED");
    expect(indicator(el).hasError).toBe(true);
  });

  it("흐름이 없으면 미설정 안내를 보인다", async () => {
    const el = mount();
    getPath.emit(null);
    await flush();
    expect(indicator(el)).toBeNull();
    expect(el.shadowRoot.querySelector("p").textContent).toBe(
      "c.CMN_StatusPath_NotConfigured"
    );
  });

  it("오류면 공통 오류 문구를 보인다", async () => {
    const el = mount();
    getPath.error();
    await flush();
    expect(el.shadowRoot.querySelector("p[role=alert]").textContent).toBe(
      "c.CMN_Common_UnexpectedError"
    );
  });

  it("알 수 없는 상태 값이면 강조 단계가 없다", async () => {
    const el = mount();
    getPath.emit(PATH);
    await flush();
    getRecord.emit({ fields: { Status__c: { value: "LEGACY" } } });
    await flush();
    expect(indicator(el).currentStep).toBeUndefined();
  });
});
