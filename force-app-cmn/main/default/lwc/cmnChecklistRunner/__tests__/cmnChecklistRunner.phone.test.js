import { createElement } from "lwc";
import CmnChecklistRunner from "c/cmnChecklistRunner";
import loadSheet from "@salesforce/apex/CMN_ChecklistController.load";
import SHEET from "./data/sheet.json";

jest.mock(
  "@salesforce/client/formFactor",
  () => ({ __esModule: true, default: "Small" }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ChecklistController.load",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ChecklistController.saveAnswers",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ChecklistController.preview",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ChecklistController.raiseFollowUp",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_PhotoController.uploadPhotos",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("c-cmn-checklist-runner on phone (UX-009 BR-1)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("uses a section picklist on top and no table view", async () => {
    loadSheet.mockResolvedValue(JSON.parse(JSON.stringify(SHEET)));
    const el = createElement("c-cmn-checklist-runner", {
      is: CmnChecklistRunner
    });
    el.recordId = "a0G000000000001AAA";
    document.body.appendChild(el);
    await flush();
    await flush();
    expect(el.shadowRoot.querySelector("nav.sections")).toBeNull();
    expect(
      el.shadowRoot.querySelector("lightning-radio-group.view")
    ).toBeNull();
    const select = el.shadowRoot.querySelector(
      "lightning-combobox.section-select"
    );
    expect(select.options).toHaveLength(2);
    expect(select.value).toBe("S1");
    select.dispatchEvent(
      new CustomEvent("change", { detail: { value: "S2" } })
    );
    await flush();
    expect(
      el.shadowRoot.querySelector("h2.question-title").textContent
    ).toContain("2.1");
  });
});
