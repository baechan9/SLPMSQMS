import { createElement } from "lwc";
import CmnEditableGrid from "c/cmnEditableGrid";
import loadGrid from "@salesforce/apex/CMN_GridController.load";
import GRID_VIEW from "./data/gridView.json";

const view = (overrides = {}) => ({
  ...JSON.parse(JSON.stringify(GRID_VIEW)),
  ...overrides
});

jest.mock(
  "@salesforce/client/formFactor",
  () => ({ __esModule: true, default: "Small" }),
  {
    virtual: true
  }
);
jest.mock(
  "@salesforce/apex/CMN_GridController.load",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_GridController.save",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_GridController.resolveLookups",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("c-cmn-editable-grid on phone (UX-006 BR-7)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("AC-7: shows read-only cards with up to four phone fields and no edit buttons", async () => {
    loadGrid.mockResolvedValue(view());
    const el = createElement("c-cmn-editable-grid", { is: CmnEditableGrid });
    el.recordId = "a0G000000000001AAA";
    el.gridKey = "CMN_TestRecordLines";
    document.body.appendChild(el);
    await flush();
    await flush();
    expect(el.shadowRoot.querySelector("c-cmn-grid-datatable")).toBeNull();
    expect(el.shadowRoot.querySelector("lightning-button.btn-save")).toBeNull();
    const cards = el.shadowRoot.querySelectorAll("li.card");
    expect(cards).toHaveLength(2);
    const open = cards[0].querySelector("lightning-button.card-open");
    expect(open.label).toBe("Line 1");
    // 제목 1 + 필드 3(구분·시작·종료) = 휴대폰 열 4개
    expect(cards[0].querySelectorAll("dt")).toHaveLength(3);
    expect(cards[0].textContent).toContain("Plan");
    open.click();
  });
});
