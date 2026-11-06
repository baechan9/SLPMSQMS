import { createElement } from "lwc";
import CmnDocumentCompare from "c/cmnDocumentCompare";
import compare from "@salesforce/apex/CMN_DocumentCompareController.compare";
import applySummary from "@salesforce/apex/CMN_DocumentCompareController.applySummary";

jest.mock(
  "@salesforce/apex/CMN_DocumentCompareController.compare",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_DocumentCompareController.applySummary",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const REVS = [
  { id: "r1", label: "Rev 1", revisionNo: 1 },
  { id: "r3", label: "Rev 3", revisionNo: 3 },
  { id: "r2", label: "Rev 2", revisionNo: 2 }
];
const OK = {
  state: "OK",
  isMock: true,
  fromLabel: "Rev.2",
  toLabel: "Rev.3",
  summary: "3 specs changed",
  changes: [
    {
      key: "c0",
      changeType: "CHANGED",
      typeLabel: "Changed",
      section: "3",
      beforeText: "2.10",
      afterText: "2.05"
    }
  ],
  rowKeyLabel: "Char No",
  cells: [
    {
      key: "t0",
      rowKey: "C10",
      columnName: "USL",
      beforeText: "2.10",
      afterText: "2.05"
    },
    {
      key: "t1",
      rowKey: "C14",
      columnName: "LSL",
      beforeText: "3.0",
      afterText: "3.2"
    },
    {
      key: "t2",
      rowKey: "C22",
      columnName: "Points",
      beforeText: "5",
      afterText: "9"
    }
  ]
};

function mount() {
  const el = createElement("c-cmn-document-compare", {
    is: CmnDocumentCompare
  });
  el.documentName = "Control plan";
  el.revisions = REVS;
  document.body.appendChild(el);
  return el;
}
const q = (el, sel) => el.shadowRoot.querySelector(sel);

describe("c-cmn-document-compare (AI-003)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("AC-1: compares the previous and latest revision and shows the table and summary", async () => {
    compare.mockResolvedValue(OK);
    const el = mount();
    expect(q(el, "lightning-combobox.from").value).toBe("r2");
    expect(q(el, "lightning-combobox.to").value).toBe("r3");
    q(el, "lightning-button.run").click();
    await flush();
    expect(compare).toHaveBeenCalledWith({
      fromRevisionId: "r2",
      toRevisionId: "r3"
    });
    expect(q(el, "lightning-textarea.summary").value).toBe("3 specs changed");
    expect(el.shadowRoot.querySelectorAll("tr.change")).toHaveLength(1);
    expect(el.shadowRoot.querySelectorAll("tr.cell")).toHaveLength(3);
    expect(q(el, "table.cells th").textContent).toBe("Char No");
    expect(q(el, "c-cmn-prototype-badge").show).toBe(true);
  });

  it("AC-2: a not-comparable result shows the message without tables or apply", async () => {
    compare.mockResolvedValue({
      state: "NOT_COMPARABLE",
      message: "No text",
      changes: [],
      cells: []
    });
    const el = mount();
    q(el, "lightning-button.run").click();
    await flush();
    expect(q(el, "[data-id=state]").textContent.trim()).toBe("No text");
    expect(q(el, "table.changes")).toBeNull();
    expect(q(el, "lightning-button.apply")).toBeNull();
  });

  it("blocks the same revision and shows the apply stub message", async () => {
    const el = mount();
    q(el, "lightning-combobox.from").dispatchEvent(
      new CustomEvent("change", { detail: { value: "r3" } })
    );
    q(el, "lightning-button.run").click();
    await flush();
    expect(compare).not.toHaveBeenCalled();
    expect(q(el, "[data-id=error]").textContent.trim()).toBe(
      "c.CMN_DocCompare_PickTwo"
    );

    compare.mockResolvedValue(OK);
    applySummary.mockRejectedValue({ body: { message: "Later stage" } });
    q(el, "lightning-combobox.from").dispatchEvent(
      new CustomEvent("change", { detail: { value: "r1" } })
    );
    q(el, "lightning-button.run").click();
    await flush();
    const area = q(el, "lightning-textarea.summary");
    area.value = "edited";
    area.dispatchEvent(
      new CustomEvent("change", { detail: { value: "edited" } })
    );
    q(el, "lightning-button.apply").click();
    await flush();
    expect(applySummary).toHaveBeenCalledWith({
      revisionId: "r3",
      summary: "edited"
    });
    expect(q(el, "[data-id=apply-message]").textContent.trim()).toBe(
      "Later stage"
    );
  });
});
