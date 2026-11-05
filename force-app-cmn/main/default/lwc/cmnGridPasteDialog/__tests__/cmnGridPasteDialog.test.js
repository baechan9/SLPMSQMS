import { createElement } from "lwc";
import CmnGridPasteDialog from "c/cmnGridPasteDialog";

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

const COLUMNS = [
  {
    fieldApiName: "LineNo__c",
    label: "No",
    inputType: "NUMBER",
    editable: false
  },
  {
    fieldApiName: "Name",
    label: "Item",
    inputType: "TEXT",
    editable: true,
    length: 80
  },
  {
    fieldApiName: "StartDate__c",
    label: "Start",
    inputType: "DATE",
    editable: true
  },
  {
    fieldApiName: "Quantity__c",
    label: "Qty",
    inputType: "NUMBER",
    editable: true
  },
  {
    fieldApiName: "Plant__c",
    label: "Plant",
    inputType: "LOOKUP",
    editable: true
  }
];

function mount(props = {}) {
  const el = createElement("c-cmn-grid-paste-dialog", {
    is: CmnGridPasteDialog
  });
  Object.assign(el, {
    columns: COLUMNS,
    maxRows: 200,
    locale: "ko-KR",
    ...props
  });
  document.body.appendChild(el);
  return el;
}

async function paste(el, text) {
  const area = el.shadowRoot.querySelector("lightning-textarea");
  area.dispatchEvent(new CustomEvent("change", { detail: { value: text } }));
  await flush();
  await flush();
}

describe("c-cmn-grid-paste-dialog (UX-006 BR-3)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("AC-2: previews one bad date cell and resolves lookups in one call", async () => {
    const resolver = jest.fn(() =>
      Promise.resolve([
        { fieldApiName: "Plant__c", key: "KR01", id: "a0P1", label: "KR01" },
        { fieldApiName: "Plant__c", key: "KR02", id: null, ambiguous: true }
      ])
    );
    const el = mount({ resolver });
    await paste(
      el,
      [
        "A\t2026-11-01\t1\tKR01",
        "B\t2026-11-02\t2\tKR01",
        "C\t2026-11-31\t3\tKR01",
        "D\t2026-11-04\t4\tKR01",
        "E\t2026-11-05\t5\tKR02"
      ].join("\n")
    );
    expect(resolver).toHaveBeenCalledTimes(1);
    expect(resolver).toHaveBeenCalledWith({ Plant__c: ["KR01", "KR02"] });
    const errorCells = el.shadowRoot.querySelectorAll("span.cell-error");
    // 날짜 1칸 + 여러 건 일치 참조 1칸
    expect(errorCells).toHaveLength(2);
    expect(el.shadowRoot.querySelectorAll("tbody tr")).toHaveLength(5);
    expect(el.shadowRoot.querySelector("p.summary").textContent).toContain(
      "CMN_Grid_PasteSummary"
    );
  });

  it("applies with header row skipped and returns typed cells", async () => {
    const el = mount();
    const header = el.shadowRoot.querySelector("lightning-input.header-check");
    header.dispatchEvent(
      new CustomEvent("change", { detail: { checked: true } })
    );
    await paste(el, "Item\tStart\nPump\t2026.11.06");
    const closed = jest.fn();
    el.addEventListener("close", closed);
    el.shadowRoot.querySelector("lightning-button.apply").click();
    expect(closed).toHaveBeenCalledTimes(1);
    expect(closed.mock.calls[0][0].detail).toEqual({
      mode: "append",
      rows: [
        {
          cells: {
            Name: { value: "Pump", raw: "Pump", error: null, label: null },
            StartDate__c: {
              value: "2026-11-06",
              raw: "2026.11.06",
              error: null,
              label: null
            }
          }
        }
      ]
    });
  });

  it("asks for a selected row before overwriting and cancels with null", async () => {
    const el = mount({ canOverwrite: false });
    await paste(el, "Pump");
    el.shadowRoot
      .querySelector("lightning-radio-group")
      .dispatchEvent(
        new CustomEvent("change", { detail: { value: "overwrite" } })
      );
    el.shadowRoot.querySelector("lightning-button.apply").click();
    await flush();
    expect(
      el.shadowRoot.querySelector("p.error-message").textContent
    ).toContain("CMN_Grid_PasteNoSelection");
    const closed = jest.fn();
    el.addEventListener("close", closed);
    el.shadowRoot.querySelector("lightning-button.cancel").click();
    expect(closed.mock.calls[0][0].detail).toBeNull();
  });

  it("starts at another column and warns when too many rows", async () => {
    const el = mount({ maxRows: 1 });
    el.shadowRoot
      .querySelector("lightning-combobox.start-column")
      .dispatchEvent(new CustomEvent("change", { detail: { value: "3" } }));
    await paste(el, "5\n6");
    expect(el.shadowRoot.querySelectorAll("tbody tr")).toHaveLength(1);
    expect(el.shadowRoot.textContent).toContain("CMN_Grid_PasteTooMany");
    expect(el.shadowRoot.querySelector("thead").textContent).toContain("Qty");
  });
});
