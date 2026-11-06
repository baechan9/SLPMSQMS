import { createElement } from "lwc";
import CmnUnifiedSearch from "c/cmnUnifiedSearch";
import search from "@salesforce/apex/CMN_UnifiedSearchController.search";
import { CurrentPageReference } from "lightning/navigation";

jest.mock(
  "@salesforce/apex/CMN_UnifiedSearchController.search",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
const mockNavigate = jest.fn();
jest.mock("lightning/navigation", () => {
  const { createTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
  const Navigate = Symbol("Navigate");
  const NavigationMixin = (Base) =>
    class extends Base {
      [Navigate](ref) {
        mockNavigate(ref);
      }
    };
  NavigationMixin.Navigate = Navigate;
  return {
    __esModule: true,
    NavigationMixin,
    CurrentPageReference: createTestWireAdapter(jest.fn())
  };
});

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const RESULT = {
  term: "lens fog",
  recordCount: 2,
  records: [
    {
      objectApiName: "CMN_Item__c",
      objectLabel: "Items",
      hits: [
        {
          id: "a01000000000001AAA",
          numberText: "S-LENS-BE1",
          title: "Lens",
          subtitle: "CP-1"
        },
        { id: "a01000000000002AAA", numberText: null, title: "Housing" }
      ]
    }
  ],
  documents: {
    state: "OK",
    isMock: true,
    summary: "Vent spec raised",
    sources: [{ text: "DOC-1 Rev.2" }],
    items: [
      {
        key: "d0",
        title: "8D lens fog",
        docNo: "DOC-1",
        revisionLabel: "Rev.2",
        docClass: "8D",
        snippet: "vent",
        scorePercent: 91,
        superseded: false
      },
      {
        key: "d1",
        title: "8D lens fog",
        docNo: "DOC-1",
        revisionLabel: "Rev.1",
        docClass: "8D",
        snippet: "temp",
        scorePercent: 80,
        superseded: true
      }
    ]
  }
};

function mount() {
  const el = createElement("c-cmn-unified-search", { is: CmnUnifiedSearch });
  document.body.appendChild(el);
  return el;
}
const q = (el, sel) => el.shadowRoot.querySelector(sel);
const all = (el, sel) => el.shadowRoot.querySelectorAll(sel);

function type(el, value) {
  const input = q(el, "lightning-input.term");
  input.value = value;
  input.dispatchEvent(new CustomEvent("change", { detail: { value } }));
}

describe("c-cmn-unified-search (AI-002 BR-3)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("shows the hint, then summary, documents and records for one term", async () => {
    search.mockResolvedValue(JSON.parse(JSON.stringify(RESULT)));
    const el = mount();
    expect(q(el, "[data-id=hint]").textContent.trim()).toBe(
      "c.CMN_Search_Hint"
    );
    type(el, " lens fog ");
    q(el, "lightning-input.term").dispatchEvent(
      new KeyboardEvent("keyup", { key: "Enter" })
    );
    await flush();
    expect(search).toHaveBeenCalledWith({
      term: "lens fog",
      includeSuperseded: false
    });
    expect(q(el, "p.summary-text").textContent).toBe("Vent spec raised");
    expect(q(el, "[data-id=ai-badge]").textContent).toContain(
      "c.CMN_Search_AiGenerated"
    );
    expect(q(el, "c-cmn-prototype-badge").show).toBe(true);
    expect(all(el, "ul.sources li")).toHaveLength(1);
    const docs = all(el, "li.doc");
    expect(docs).toHaveLength(2);
    expect(docs[0].textContent).toContain("DOC-1 · Rev.2 · 8D");
    expect(docs[1].querySelector(".superseded-badge")).not.toBeNull();
    const hits = all(el, "li.hit lightning-button");
    expect(hits).toHaveLength(2);
    expect(hits[0].label).toBe("S-LENS-BE1 Lens");
    expect(hits[1].label).toBe("Housing");
    hits[0].click();
    expect(mockNavigate.mock.calls[0][0].attributes.recordId).toBe(
      "a01000000000001AAA"
    );
  });

  it("re-runs with superseded revisions and opens with c__q", async () => {
    search.mockResolvedValue(JSON.parse(JSON.stringify(RESULT)));
    const el = mount();
    CurrentPageReference.emit({ state: { c__q: "PPAP" } });
    await flush();
    expect(search).toHaveBeenLastCalledWith({
      term: "PPAP",
      includeSuperseded: false
    });
    const box = q(el, "lightning-input.superseded");
    box.checked = true;
    box.dispatchEvent(new CustomEvent("change"));
    await flush();
    expect(search).toHaveBeenLastCalledWith({
      term: "PPAP",
      includeSuperseded: true
    });
  });

  it("validates the term length on the screen", async () => {
    const el = mount();
    type(el, "a");
    q(el, "lightning-button.run").click();
    await flush();
    expect(search).not.toHaveBeenCalled();
    expect(q(el, "[data-id=error]").textContent.trim()).toBe(
      "c.CMN_Search_TermLength"
    );
  });

  it("shows the not-available document state and the no-result message", async () => {
    search.mockResolvedValueOnce({
      term: "zz",
      recordCount: 0,
      records: [],
      documents: { state: "NOT_AVAILABLE", message: "Not yet", items: [] }
    });
    const el = mount();
    type(el, "zz");
    q(el, "lightning-button.run").click();
    await flush();
    expect(q(el, "[data-id=docs-not-available]").textContent.trim()).toBe(
      "Not yet"
    );
    expect(q(el, "section.summary")).toBeNull();
    expect(q(el, "[data-id=empty]")).toBeNull();

    search.mockResolvedValueOnce({
      term: "zz",
      recordCount: 0,
      records: [],
      documents: { state: "EMPTY", items: [], sources: [] }
    });
    q(el, "lightning-button.run").click();
    await flush();
    expect(q(el, "[data-id=empty]").textContent.trim()).toBe(
      "c.CMN_Search_NoResults"
    );
    expect(q(el, "[data-id=docs-empty]")).not.toBeNull();

    search.mockRejectedValueOnce({ body: { message: "Too short" } });
    q(el, "lightning-button.run").click();
    await flush();
    expect(q(el, "[data-id=error]").textContent.trim()).toBe("Too short");
  });
});
