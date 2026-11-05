import { createElement } from "lwc";
import CmnFieldEntryShell from "c/cmnFieldEntryShell";
import loadSheet from "@salesforce/apex/CMN_FieldEntryController.load";
import saveEntries from "@salesforce/apex/CMN_FieldEntryController.save";
import validateScan from "@salesforce/apex/CMN_FieldEntryController.validateScan";
import LightningConfirm from "lightning/confirm";
import { CurrentPageReference } from "lightning/navigation";
import { draftKey } from "c/cmnDraftStore";
import USER_ID from "@salesforce/user/Id";
import SHEET from "./data/sheet.json";

jest.mock(
  "@salesforce/apex/CMN_FieldEntryController.load",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_FieldEntryController.save",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_FieldEntryController.validateScan",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_PhotoController.uploadPhotos",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "lightning/mobileCapabilities",
  () => ({ getBarcodeScanner: () => ({ isAvailable: () => false }) }),
  { virtual: true }
);
jest.mock("lightning/confirm", () => ({
  __esModule: true,
  default: { open: jest.fn() }
}));

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const REC = "a0G000000000001AAA";
const sheet = (overrides = {}) => ({
  ...JSON.parse(JSON.stringify(SHEET)),
  ...overrides
});

async function mount(s = sheet(), props = { recordId: REC }) {
  loadSheet.mockResolvedValue(s);
  const el = createElement("c-cmn-field-entry-shell", {
    is: CmnFieldEntryShell
  });
  Object.assign(el, props);
  document.body.appendChild(el);
  await flush();
  await flush();
  return el;
}

const $ = (el, sel) => el.shadowRoot.querySelector(sel);
const $$ = (el, sel) => el.shadowRoot.querySelectorAll(sel);

async function setMode(el, mode) {
  $(el, "lightning-radio-group.mode").dispatchEvent(
    new CustomEvent("change", { detail: { value: mode } })
  );
  await flush();
}

async function typeNumber(el, value) {
  const input = $(el, "input.seq-number");
  input.value = value;
  input.dispatchEvent(new CustomEvent("change"));
  await flush();
}

async function tableValue(el, key, value) {
  const input = $(el, `input.cell-input[data-key="${key}"]`);
  input.value = value;
  input.dispatchEvent(new CustomEvent("change"));
  await flush();
}

describe("c-cmn-field-entry-shell (UX-008)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    localStorage.clear();
    jest.clearAllMocks();
  });

  it("AC-1: previews fail for 2.05 and pass for 2.004 with text and icon", async () => {
    const el = await mount();
    await setMode(el, "SEQUENTIAL");
    expect($(el, "h2.item-label").textContent).toContain("Outer");
    expect($(el, "p.spec").textContent).toContain("1.00 ~ 2.00 mm");
    await typeNumber(el, "2.05");
    expect($(el, "p.preview").textContent).toContain("c.CMN_FieldEntry_Fail");
    expect($(el, "p.preview lightning-icon").iconName).toBe("utility:error");
    await typeNumber(el, "2.004");
    expect($(el, "p.preview").textContent).toContain("c.CMN_FieldEntry_Pass");
  });

  it("AC-2: moves to the next sample without calling the server", async () => {
    const el = await mount();
    await setMode(el, "SEQUENTIAL");
    await typeNumber(el, "1.5");
    $(el, "lightning-button.btn-next").click();
    await flush();
    expect($(el, "p.sample-text").textContent).toBe("c.CMN_FieldEntry_Sample");
    expect($(el, "input.seq-number").dataset.key).toBe("OUTER#2");
    $(el, "lightning-button.btn-prev").click();
    await flush();
    expect($(el, "input.seq-number").dataset.key).toBe("OUTER#1");
    expect(saveEntries).not.toHaveBeenCalled();
    expect(validateScan).not.toHaveBeenCalled();
    expect(loadSheet).toHaveBeenCalledTimes(1);
  });

  it("AC-3: offers to restore entries left on this device", async () => {
    localStorage.setItem(
      draftKey(USER_ID, "FIELD_ENTRY", REC),
      JSON.stringify({
        v: 1,
        savedAt: Date.now(),
        ttl: 7 * 86400000,
        payload: {
          values: {
            "OUTER#1": {
              itemKey: "OUTER",
              sampleNo: 1,
              numValue: 1.7,
              photoIds: []
            }
          },
          gauges: { OUTER: "G-0001" }
        }
      })
    );
    LightningConfirm.open.mockResolvedValue(true);
    const el = await mount();
    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    expect($(el, 'input.cell-input[data-key="OUTER#1"]').value).toBe("1.7");
    expect($(el, "span.status-text").textContent).toBe(
      "c.CMN_FieldEntry_Pending"
    );
  });

  it("AC-4: pastes a column of five values into samples 1 to 5", async () => {
    const el = await mount();
    const first = $(el, 'input.cell-input[data-key="OUTER#1"]');
    const paste = new CustomEvent("paste", { cancelable: true });
    paste.clipboardData = { getData: () => "1.10\n1.20\n1.30\n1.40\n1.50\n" };
    first.dispatchEvent(paste);
    await flush();
    expect(paste.defaultPrevented).toBe(true);
    ["1.1", "1.2", "1.3", "1.4", "1.5"].forEach((v, i) => {
      expect($(el, `input.cell-input[data-key="OUTER#${i + 1}"]`).value).toBe(
        v
      );
    });
    // 모드를 바꿔도 값을 잃지 않는다
    await setMode(el, "SEQUENTIAL");
    expect($(el, "input.seq-number").value).toBe("1.1");
  });

  it("AC-5: blocks finalizing when an NG needs a photo and the gauge is missing", async () => {
    const el = await mount();
    const select = $(el, 'select.cell-select[data-key="BUBBLE#1"]');
    select.value = "NG";
    select.dispatchEvent(new CustomEvent("change"));
    await tableValue(el, "OUTER#1", "1.5");
    $(el, "lightning-button.btn-finalize").click();
    await flush();
    const items = $$(el, "div.photo-missing li");
    expect(items).toHaveLength(2);
    expect(items[0].textContent).toBe("c.CMN_FieldEntry_PhotoRequired");
    expect(items[1].textContent).toBe("c.CMN_FieldEntry_GaugeRequired");
    expect(saveEntries.mock.calls.filter((c) => c[0].isFinal)).toHaveLength(0);
  });

  it("AC-5: attaches uploaded photo ids to the NG sample", async () => {
    const el = await mount();
    await setMode(el, "SEQUENTIAL");
    // 기포 시료 1로 이동
    for (let i = 0; i < 7; i++) {
      $(el, "lightning-button.btn-next").click();
      // eslint-disable-next-line no-await-in-loop
      await flush();
    }
    expect($(el, "h2.item-label").textContent).toContain("Bubble");
    $(el, 'button[data-value="NG"]').click();
    await flush();
    const photo = $(el, "c-cmn-photo-capture");
    expect(photo.docClass).toBe("TEST_PHOTO");
    photo.dispatchEvent(
      new CustomEvent("uploaded", {
        detail: { count: 1, documentIds: ["a0D000000000001AAA"] }
      })
    );
    await flush();
    expect($(el, "p.photo-count").textContent).toBe("c.CMN_FieldEntry_Photos");
  });

  it("AC-6: shows the server result and highlights items that differ", async () => {
    const el = await mount();
    LightningConfirm.open.mockResolvedValue(true);
    saveEntries.mockResolvedValue({
      success: true,
      overall: "FAIL",
      itemResults: {
        OUTER: "FAIL",
        HEIGHT: "INCOMPLETE",
        BUBBLE: "INCOMPLETE",
        NOTE: "INCOMPLETE"
      },
      errors: [],
      nextActionLabel: "Raise NCR"
    });
    await tableValue(el, "NOTE#1", "fine");
    saveEntries.mockClear();
    $(el, "lightning-button.btn-finalize").click();
    await flush();
    await flush();
    const call = saveEntries.mock.calls[0][0];
    expect(call.isFinal).toBe(true);
    expect(JSON.parse(call.valuesJson)).toEqual([
      {
        itemKey: "NOTE",
        sampleNo: 1,
        numValue: null,
        okNg: null,
        text: "fine",
        photoIds: [],
        gaugeNo: null
      }
    ]);
    expect($(el, "div.diff-banner")).not.toBeNull();
    // 외경(서버 불합격 / 화면 입력 중)과 특이사항(서버 입력 중 / 화면 합격)을 강조하고 서버 판정을 함께 보인다
    const diffRows = $$(el, "tr.diff-row");
    expect(diffRows).toHaveLength(2);
    expect(diffRows[0].querySelector(".server-result").textContent).toContain(
      "c.CMN_FieldEntry_ServerResult"
    );
    expect($(el, "p.next-action").textContent).toBe("Raise NCR");
    expect($(el, "div.final-result").textContent).toContain(
      "c.CMN_FieldEntry_Finalized"
    );
  });

  it("AC-7: read-only sheet has no input or save buttons", async () => {
    const el = await mount(sheet({ editable: false }));
    expect($(el, "lightning-button.btn-finalize")).toBeNull();
    expect($(el, "p.read-only")).not.toBeNull();
    expect($(el, 'input.cell-input[data-key="OUTER#1"]').disabled).toBe(true);
    expect($(el, "div.lot-check")).toBeNull();
    expect(LightningConfirm.open).not.toHaveBeenCalled();
  });

  it("AC-8: keeps entering after a failed save, shows pending and never resends by itself", async () => {
    const el = await mount();
    saveEntries.mockRejectedValue(new Error("offline"));
    await tableValue(el, "HEIGHT#1", "10.5");
    await tableValue(el, "HEIGHT#2", "11");
    await flush();
    expect(saveEntries).toHaveBeenCalledTimes(1);
    expect($(el, "p.save-failed")).not.toBeNull();
    // 다른 항목을 다 채워도 자동 재전송 없음
    await tableValue(el, "NOTE#1", "ok");
    await flush();
    expect(saveEntries).toHaveBeenCalledTimes(1);
    expect($(el, "span.status-text").textContent).toBe(
      "c.CMN_FieldEntry_Pending"
    );
    // 사용자가 다시 저장
    saveEntries.mockResolvedValue({
      success: true,
      itemResults: { HEIGHT: "PASS", NOTE: "PASS" },
      errors: []
    });
    $(el, "lightning-button.btn-save-now").click();
    await flush();
    await flush();
    expect(saveEntries).toHaveBeenCalledTimes(2);
    expect(
      JSON.parse(saveEntries.mock.calls[1][0].valuesJson)
        .map((v) => v.itemKey)
        .sort()
    ).toEqual(["HEIGHT", "HEIGHT", "NOTE"]);
    expect($(el, "span.status-text").textContent).toBe(
      "c.CMN_FieldEntry_ServerSaved"
    );
    expect($(el, "p.save-failed")).toBeNull();
  });

  it("BR-6: checks lot and gauge scans with the server", async () => {
    const el = await mount();
    validateScan.mockResolvedValueOnce(null).mockResolvedValueOnce("Bad gauge");
    $(el, "div.lot-check c-cmn-barcode-scanner").dispatchEvent(
      new CustomEvent("scan", {
        detail: { value: "TST-KR01-2026-000001", type: "MANUAL" }
      })
    );
    await flush();
    expect(validateScan).toHaveBeenCalledWith({
      recordId: REC,
      scanType: "LOT",
      value: "TST-KR01-2026-000001"
    });
    expect($(el, "div.lot-check p").className).toContain(
      "slds-text-color_success"
    );
    await setMode(el, "SEQUENTIAL");
    $(el, "div.gauge c-cmn-barcode-scanner").dispatchEvent(
      new CustomEvent("scan", { detail: { value: "12", type: "MANUAL" } })
    );
    await flush();
    expect($(el, "div.gauge p").textContent).toBe("Bad gauge");
  });

  it("shows server errors, number errors and the missing-only filter", async () => {
    const el = await mount();
    await setMode(el, "SEQUENTIAL");
    await typeNumber(el, "abc");
    expect($(el, "p.slot-error").textContent).toBe(
      "c.CMN_FieldEntry_NotNumber"
    );
    $(el, "lightning-input.missing-only").dispatchEvent(
      new CustomEvent("change", { detail: { checked: true } })
    );
    await flush();
    await typeNumber(el, "1.5");
    // 미입력만: 입력한 칸은 빠지고 다음 미입력 칸이 보인다
    expect($(el, "input.seq-number").dataset.key).toBe("OUTER#2");
    // 측정기 번호를 확인한 뒤 확정 → 미입력 확인을 묻고, 취소하면 저장하지 않는다
    validateScan.mockResolvedValue(null);
    $(el, "div.gauge c-cmn-barcode-scanner").dispatchEvent(
      new CustomEvent("scan", { detail: { value: "G-0001", type: "MANUAL" } })
    );
    await flush();
    LightningConfirm.open.mockResolvedValue(false);
    $(el, "lightning-button.btn-finalize").click();
    await flush();
    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    expect(saveEntries.mock.calls.filter((c) => c[0].isFinal)).toHaveLength(0);
  });

  it("reads the record from the page state and reports load errors", async () => {
    loadSheet.mockRejectedValue({ body: { message: "No screen" } });
    const el = createElement("c-cmn-field-entry-shell", {
      is: CmnFieldEntryShell
    });
    document.body.appendChild(el);
    CurrentPageReference.emit({ state: {} });
    await flush();
    expect($(el, "p.no-record")).not.toBeNull();
    CurrentPageReference.emit({ state: { c__recordId: REC } });
    await flush();
    await flush();
    expect(loadSheet).toHaveBeenCalledWith({ recordId: REC });
    expect($(el, "p.load-error").textContent).toBe("No screen");
  });
});
