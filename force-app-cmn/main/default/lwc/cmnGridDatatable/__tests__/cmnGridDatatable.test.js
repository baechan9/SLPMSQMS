import { createElement } from "lwc";
import CmnGridDatatable from "c/cmnGridDatatable";
import CmnGridCellLabel from "c/cmnGridCellLabel";
import CmnGridLookupInput from "c/cmnGridLookupInput";
import CmnGridCodeInput from "c/cmnGridCodeInput";

jest.mock(
  "@salesforce/apex/CMN_CodePickerController.getCodes",
  () => ({
    default: jest.fn(() => Promise.resolve({ codes: [], maxLevel: 2 }))
  }),
  { virtual: true }
);

function mount(tag, Ctor, props = {}) {
  const el = createElement(tag, { is: Ctor });
  Object.assign(el, props);
  document.body.appendChild(el);
  return el;
}

describe("grid cells (UX-006 BR-8)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("registers picklist, lookup, code and row-state custom types with edit templates", () => {
    const types = CmnGridDatatable.customTypes;
    expect(Object.keys(types)).toEqual([
      "cmnPicklist",
      "cmnLookup",
      "cmnCode",
      "cmnRowState"
    ]);
    ["cmnPicklist", "cmnLookup", "cmnCode"].forEach((t) => {
      expect(types[t].editTemplate).toBeDefined();
      expect(types[t].standardCellLayout).toBe(true);
    });
    expect(types.cmnRowState.editTemplate).toBeUndefined();
  });

  it("shows picklist labels, reference names and row state with warning text", () => {
    const pick = mount("c-cmn-grid-cell-label", CmnGridCellLabel, {
      value: "PLAN",
      options: [{ value: "PLAN", label: "Plan" }]
    });
    expect(pick.shadowRoot.textContent).toBe("Plan");
    const ref = mount("c-cmn-grid-cell-label", CmnGridCellLabel, {
      value: "a0P1",
      display: "KR01"
    });
    expect(ref.shadowRoot.textContent).toBe("KR01");
    const state = mount("c-cmn-grid-cell-label", CmnGridCellLabel, {
      variant: "state",
      value: "Error",
      icon: "utility:error",
      warning: "Overdue"
    });
    expect(state.shadowRoot.textContent).toContain("Error");
    expect(state.shadowRoot.textContent).toContain("Overdue");
    expect(state.shadowRoot.querySelectorAll("lightning-icon")).toHaveLength(2);
  });

  it("lookup input exposes value, validity and the record picker filter", () => {
    const el = mount("c-cmn-grid-lookup-input", CmnGridLookupInput, {
      objectApiName: "CMN_Plant__c",
      required: true,
      filter: [
        { fieldPath: "IsActive__c", value: "true" },
        { fieldPath: "Region__c", value: "KR" }
      ]
    });
    expect(el.validity.valid).toBe(false);
    const picker = el.shadowRoot.querySelector("lightning-record-picker");
    expect(picker.filter).toEqual({
      criteria: [
        { fieldPath: "IsActive__c", operator: "eq", value: true },
        { fieldPath: "Region__c", operator: "eq", value: "KR" }
      ]
    });
    picker.dispatchEvent(
      new CustomEvent("change", { detail: { recordId: "a0P2" } })
    );
    expect(el.value).toBe("a0P2");
    expect(el.validity.valid).toBe(true);
    el.focus();
    el.showHelpMessageIfInvalid();
  });

  it("code input takes the leaf code from the code picker", () => {
    const el = mount("c-cmn-grid-code-input", CmnGridCodeInput, {
      groupCode: "DEFECT_TYPE",
      required: true,
      value: "a0C1"
    });
    expect(el.value).toBe("a0C1");
    const picker = el.shadowRoot.querySelector("c-cmn-code-picker");
    picker.dispatchEvent(
      new CustomEvent("change", { detail: { value: null } })
    );
    expect(el.validity.valid).toBe(false);
    picker.dispatchEvent(
      new CustomEvent("change", { detail: { value: "a0C2" } })
    );
    expect(el.value).toBe("a0C2");
    el.focus();
    el.showHelpMessageIfInvalid();
  });
});
