import { createElement } from "lwc";
import CmnEditableGrid from "c/cmnEditableGrid";
import loadGrid from "@salesforce/apex/CMN_GridController.load";
import saveGrid from "@salesforce/apex/CMN_GridController.save";
import resolveLookups from "@salesforce/apex/CMN_GridController.resolveLookups";
import LightningConfirm from "lightning/confirm";
import CmnGridPasteDialog from "c/cmnGridPasteDialog";
import { subscribe } from "lightning/messageService";
import { draftKey } from "c/cmnDraftStore";
import USER_ID from "@salesforce/user/Id";
import GRID_VIEW from "./data/gridView.json";

const view = (overrides = {}) => ({
  ...JSON.parse(JSON.stringify(GRID_VIEW)),
  ...overrides
});

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
  () => ({ default: jest.fn(() => Promise.resolve([])) }),
  { virtual: true }
);
jest.mock("lightning/confirm", () => ({
  __esModule: true,
  default: { open: jest.fn() }
}));
jest.mock("c/cmnGridPasteDialog", () => ({
  __esModule: true,
  default: { open: jest.fn() }
}));

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const PARENT = "a0G000000000001AAA";
const ROW1 = "a0L000000000001AAA";
const ROW2 = "a0L000000000002AAA";
const STORE = () => draftKey(USER_ID, "CMN_TestRecordLines", PARENT);

async function mount(v = view()) {
  loadGrid.mockResolvedValue(v);
  const el = createElement("c-cmn-editable-grid", { is: CmnEditableGrid });
  el.recordId = PARENT;
  el.gridKey = "CMN_TestRecordLines";
  document.body.appendChild(el);
  await flush();
  await flush();
  return el;
}

const table = (el) => el.shadowRoot.querySelector("c-cmn-grid-datatable");
const button = (el, cls) =>
  el.shadowRoot.querySelector(`lightning-button.${cls}`);

async function edit(el, draftValues) {
  table(el).dispatchEvent(
    new CustomEvent("cellchange", { detail: { draftValues } })
  );
  await flush();
}

describe("c-cmn-editable-grid (UX-006)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    localStorage.clear();
    jest.clearAllMocks();
  });

  it("AC-1: loads columns (state + frozen first) and rows with per-cell editability", async () => {
    const el = await mount();
    expect(loadGrid).toHaveBeenCalledWith({
      gridKey: "CMN_TestRecordLines",
      parentId: PARENT
    });
    const dt = table(el);
    const cols = dt.columns;
    expect(cols[0].type).toBe("cmnRowState");
    expect(cols[1].fieldName).toBe("Name");
    expect(cols[1].label).toBe("Item *");
    expect(cols.find((c) => c.fieldName === "Category__c").type).toBe(
      "cmnPicklist"
    );
    expect(cols.find((c) => c.fieldName === "Plant__c").type).toBe("cmnLookup");
    expect(cols.find((c) => c.fieldName === "Code__c").type).toBe("cmnCode");
    expect(cols.find((c) => c.fieldName === "StartDate__c").type).toBe(
      "date-local"
    );
    expect(cols.find((c) => c.fieldName === "LineNo__c").editable).toBe(false);
    expect(dt.keyField).toBe("__key");
    expect(dt.data).toHaveLength(2);
    // 완료 행(BR-11): 잠긴 셀은 편집 불가, 상태 '삭제 불가'
    const done = dt.data[1];
    expect(done.__ed_StartDate__c).toBe(false);
    expect(done.__ed_Name).toBe(true);
    expect(done.__stateText).toBe("c.CMN_Grid_StateLocked");
    expect(dt.data[0].__d_Plant__c).toBe("KR01");
    expect(button(el, "btn-save").disabled).toBe(true);
  });

  it("AC-3: saves changed, new and deleted rows in one call and clears the draft", async () => {
    const el = await mount();
    await edit(el, [{ __key: ROW1, Quantity__c: "7" }]);
    button(el, "btn-add").click();
    await flush();
    const added = table(el).data[2];
    expect(added.__stateText).toBe("c.CMN_Grid_StateNew");
    await edit(el, [{ __key: added.__key, Name: "Added" }]);
    // 첫 행 선택 → 삭제 표시
    table(el).dispatchEvent(
      new CustomEvent("rowselection", {
        detail: { selectedRows: [{ __key: ROW1 }] }
      })
    );
    button(el, "btn-delete").click();
    await flush();
    expect(table(el).data[0].__stateText).toBe("c.CMN_Grid_StateDeleted");
    expect(localStorage.getItem(STORE())).not.toBeNull();

    saveGrid.mockResolvedValue({
      success: true,
      savedCount: 1,
      deletedCount: 1,
      view: view({ clientVersion: "2:2000:def" })
    });
    button(el, "btn-save").click();
    await flush();
    await flush();
    const args = saveGrid.mock.calls[0][0];
    expect(args.deletedIds).toEqual([ROW1]);
    expect(args.clientVersion).toBe("2:1000:abc");
    const rows = JSON.parse(args.rowsJson);
    // 삭제할 행의 수정은 보내지 않는다. 새 행은 기본값 + 입력값
    expect(rows).toEqual([
      {
        key: added.__key,
        values: {
          Name: "Added",
          Category__c: "PLAN",
          Quantity__c: 1,
          StartDate__c: "2026-11-06"
        }
      }
    ]);
    expect(localStorage.getItem(STORE())).toBeNull();
    expect(table(el).draftValues).toEqual([]);
  });

  it("validates required cells on screen before calling the server", async () => {
    const el = await mount();
    await edit(el, [{ __key: ROW1, Name: "" }]);
    button(el, "btn-save").click();
    await flush();
    expect(saveGrid).not.toHaveBeenCalled();
    const errors = table(el).errors;
    expect(errors.rows[ROW1].fieldNames).toEqual(["Name"]);
    expect(el.shadowRoot.querySelector(".error-count").textContent).toContain(
      "c.CMN_Grid_ErrorCount"
    );
  });

  it("AC-4: shows provider row errors and filters to error rows", async () => {
    const el = await mount();
    await edit(el, [{ __key: ROW1, EndDate__c: "2026-10-01" }]);
    saveGrid.mockResolvedValue({
      success: false,
      conflict: false,
      rowErrors: [
        {
          key: ROW1,
          messages: ["End before start"],
          fieldNames: ["EndDate__c"]
        }
      ],
      gridErrors: []
    });
    button(el, "btn-save").click();
    await flush();
    await flush();
    const dt = table(el);
    expect(dt.errors.rows[ROW1].messages).toEqual(["End before start"]);
    expect(dt.data[0].__stateText).toBe("c.CMN_Grid_StateError");
    // 오류 행만 보기
    el.shadowRoot
      .querySelector("lightning-input.errors-only")
      .dispatchEvent(new CustomEvent("change", { detail: { checked: true } }));
    await flush();
    expect(table(el).data).toHaveLength(1);
    // 변경은 그대로 남는다
    expect(table(el).draftValues).toHaveLength(1);
  });

  it("AC-5: blocks on version conflict and refreshes keeping the draft", async () => {
    const el = await mount();
    await edit(el, [{ __key: ROW1, Name: "Mine" }]);
    saveGrid.mockResolvedValue({
      success: false,
      conflict: true,
      rowErrors: [],
      gridErrors: ["c.CMN_Grid_Conflict"]
    });
    button(el, "btn-save").click();
    await flush();
    await flush();
    expect(el.shadowRoot.querySelector(".conflict")).not.toBeNull();
    LightningConfirm.open.mockResolvedValue(true);
    button(el, "btn-conflict-refresh").click();
    await flush();
    await flush();
    expect(loadGrid).toHaveBeenCalledTimes(2);
    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    expect(table(el).draftValues).toEqual([{ __key: ROW1, Name: "Mine" }]);
  });

  it("AC-8: offers to restore a saved draft when reopened", async () => {
    localStorage.setItem(
      STORE(),
      JSON.stringify({
        v: 1,
        savedAt: Date.now(),
        payload: {
          draftValues: [
            { __key: ROW1, Name: "Draft" },
            { __key: "a0L00000000009XAAA", Name: "Gone" }
          ],
          newRows: [],
          deleted: [],
          pasteErrors: {},
          labelCache: {}
        }
      })
    );
    LightningConfirm.open.mockResolvedValue(true);
    const el = await mount();
    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    // 없어진 행의 초안은 버린다
    expect(table(el).draftValues).toEqual([{ __key: ROW1, Name: "Draft" }]);

    // 거절하면 초안을 지운다
    document.body.removeChild(el);
    LightningConfirm.open.mockResolvedValue(false);
    await mount();
    expect(localStorage.getItem(STORE())).toBeNull();
  });

  it("AC-9: read-only grid has no editing buttons", async () => {
    const el = await mount(
      view({
        editable: false,
        allowAdd: false,
        allowDelete: false,
        allowPaste: false,
        columns: view().columns.map((c) => ({ ...c, editable: false }))
      })
    );
    expect(button(el, "btn-save")).toBeNull();
    expect(button(el, "btn-add")).toBeNull();
    expect(el.shadowRoot.querySelector(".read-only")).not.toBeNull();
    expect(table(el).hideCheckboxColumn).toBe(true);
    expect(LightningConfirm.open).not.toHaveBeenCalled();
  });

  it("BR-11: blocks deleting a locked row with the provider message", async () => {
    const el = await mount();
    const toast = jest.fn();
    el.addEventListener("lightning__showtoast", toast);
    table(el).dispatchEvent(
      new CustomEvent("rowselection", {
        detail: { selectedRows: [{ __key: ROW2 }] }
      })
    );
    button(el, "btn-delete").click();
    await flush();
    expect(toast.mock.calls[0][0].detail.message).toBe(
      "Done rows can't be deleted"
    );
    expect(table(el).data[1].__stateText).toBe("c.CMN_Grid_StateLocked");
  });

  it("AC-2: applies a paste with a conversion error as a blank cell with an error", async () => {
    const el = await mount();
    CmnGridPasteDialog.open.mockResolvedValue({
      mode: "append",
      rows: [
        {
          cells: {
            Name: { value: "Pasted", raw: "Pasted", error: null, label: null },
            StartDate__c: {
              value: null,
              raw: "2026-13-45",
              error: "DATE",
              label: null
            },
            Plant__c: {
              value: "a0P000000000002AAA",
              raw: "KR02",
              error: null,
              label: "KR02"
            }
          }
        }
      ]
    });
    button(el, "btn-paste").click();
    await flush();
    await flush();
    expect(CmnGridPasteDialog.open.mock.calls[0][0].canOverwrite).toBe(false);
    const dt = table(el);
    const pasted = dt.data[2];
    expect(pasted.Name).toBe("Pasted");
    expect(pasted.StartDate__c).toBeNull();
    expect(pasted.__d_Plant__c).toBe("KR02");
    expect(dt.errors.rows[pasted.__key].fieldNames).toEqual(["StartDate__c"]);
    // 오류 칸을 고치면 오류가 사라진다
    await edit(el, [{ __key: pasted.__key, StartDate__c: "2026-11-10" }]);
    expect(table(el).errors.rows[pasted.__key]).toBeUndefined();
  });

  it("overwrites from the selected row and resolves edited lookup labels", async () => {
    const el = await mount();
    table(el).dispatchEvent(
      new CustomEvent("rowselection", {
        detail: { selectedRows: [{ __key: ROW1 }] }
      })
    );
    CmnGridPasteDialog.open.mockResolvedValue({
      mode: "overwrite",
      rows: [
        {
          cells: {
            Quantity__c: { value: 9, raw: "9", error: null, label: null }
          }
        }
      ]
    });
    button(el, "btn-paste").click();
    await flush();
    expect(CmnGridPasteDialog.open.mock.calls[0][0].canOverwrite).toBe(true);
    expect(table(el).draftValues).toEqual([{ __key: ROW1, Quantity__c: 9 }]);

    resolveLookups.mockResolvedValue([
      {
        fieldApiName: "Plant__c",
        key: "a0P000000000003AAA",
        id: "a0P000000000003AAA",
        label: "CN01"
      }
    ]);
    await edit(el, [{ __key: ROW1, Plant__c: "a0P000000000003AAA" }]);
    await flush();
    expect(JSON.parse(resolveLookups.mock.calls[0][0].keysJson)).toEqual({
      Plant__c: ["a0P000000000003AAA"]
    });
    expect(table(el).data[0].__d_Plant__c).toBe("CN01");
  });

  it("BR-6: switches to the schedule view with merged draft dates", async () => {
    const el = await mount();
    await edit(el, [{ __key: ROW1, EndDate__c: "2026-11-20" }]);
    button(el, "btn-schedule").click();
    await flush();
    const schedule = el.shadowRoot.querySelector("c-cmn-grid-schedule");
    expect(schedule.rows[0]).toMatchObject({
      label: "Line 1",
      end: "2026-11-20"
    });
    expect(table(el)).toBeNull();
  });

  it("BR-10: reloads on a matching refresh message and asks first when dirty", async () => {
    const el = await mount();
    const handler = subscribe.mock.calls[0][2];
    await handler({ gridKey: "OTHER", parentId: PARENT });
    expect(loadGrid).toHaveBeenCalledTimes(1);
    await edit(el, [{ __key: ROW1, Name: "Dirty" }]);
    LightningConfirm.open.mockResolvedValue(false);
    await handler({
      gridKey: "CMN_TestRecordLines",
      parentId: PARENT.slice(0, 15)
    });
    expect(loadGrid).toHaveBeenCalledTimes(1);
    LightningConfirm.open.mockResolvedValue(true);
    await el.refresh();
    await flush();
    expect(loadGrid).toHaveBeenCalledTimes(2);
    expect(table(el).draftValues).toEqual([]);
  });

  it("cancels all changes and shows load errors and truncation", async () => {
    const el = await mount(view({ truncated: true }));
    expect(el.shadowRoot.querySelector(".truncated")).not.toBeNull();
    await edit(el, [{ __key: ROW1, Name: "X" }]);
    button(el, "btn-cancel").click();
    await flush();
    expect(table(el).draftValues).toEqual([]);
    expect(localStorage.getItem(STORE())).toBeNull();

    document.body.removeChild(el);
    loadGrid.mockRejectedValue({ body: { message: "No access" } });
    const failed = createElement("c-cmn-editable-grid", {
      is: CmnEditableGrid
    });
    failed.recordId = PARENT;
    failed.gridKey = "CMN_TestRecordLines";
    document.body.appendChild(failed);
    await flush();
    await flush();
    expect(
      failed.shadowRoot.querySelector(".load-error").textContent
    ).toContain("No access");
  });

  it("shows the empty message for a grid without rows", async () => {
    const el = await mount(view({ rows: [] }));
    expect(el.shadowRoot.querySelector(".empty").textContent).toBe(
      "c.CMN_Grid_Empty"
    );
  });
});
