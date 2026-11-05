import { createElement } from "lwc";
import CmnDecisionRail from "c/cmnDecisionRail";
import getPanels from "@salesforce/apex/CMN_RailPanelController.getPanels";

jest.mock(
  "@salesforce/client/formFactor",
  () => ({ __esModule: true, default: "Large" }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_RailPanelController.getPanels",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const PANELS = [
  {
    key: "COMMENT",
    componentName: "c/cmnRailMissing",
    title: "C",
    order: 0,
    phoneOrder: 4,
    defaultOpen: false
  },
  {
    key: "APPROVAL",
    componentName: "c/cmnRailMissing",
    title: "A",
    order: 20,
    phoneOrder: 2,
    defaultOpen: true
  }
];

async function mount() {
  const el = createElement("c-cmn-decision-rail", { is: CmnDecisionRail });
  el.recordId = "a01000000000001AAA";
  el.objectApiName = "CMN_TestRecord__c";
  document.body.appendChild(el);
  await flush();
  return el;
}
const qa = (el, s) => el.shadowRoot.querySelectorAll(s);

describe("c-cmn-decision-rail", () => {
  beforeEach(() => window.localStorage.clear());
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("AC-2: 서버 순서대로 패널을 놓고 기본 펼침을 따른다", async () => {
    const el = await mount();
    getPanels.emit(PANELS);
    await flush();
    const panels = qa(el, "c-cmn-rail-panel");
    expect(panels.length).toBe(2);
    expect(panels[0].panel.key).toBe("COMMENT");
    expect(panels[0].open).toBe(false);
    expect(panels[1].open).toBe(true);
  });

  it("BR-5: 접고 편 상태를 객체별로 기억한다", async () => {
    let el = await mount();
    getPanels.emit(PANELS);
    await flush();
    qa(el, "c-cmn-rail-panel")[0].dispatchEvent(
      new CustomEvent("toggle", { detail: { key: "COMMENT", open: true } })
    );
    await flush();
    expect(qa(el, "c-cmn-rail-panel")[0].open).toBe(true);
    expect(
      JSON.parse(
        window.localStorage.getItem("cmnDecisionRail:CMN_TestRecord__c")
      )
    ).toEqual({ COMMENT: true, APPROVAL: true });
    document.body.removeChild(el);
    el = await mount();
    getPanels.emit(PANELS);
    await flush();
    expect(qa(el, "c-cmn-rail-panel")[0].open).toBe(true);
  });

  it("빈 목록과 오류", async () => {
    const el = await mount();
    getPanels.emit([]);
    await flush();
    expect(el.shadowRoot.querySelector("[data-id=empty]")).not.toBeNull();
    getPanels.error();
    await flush();
    expect(el.shadowRoot.querySelector("[data-id=error]")).not.toBeNull();
  });
});
