import { createElement } from "lwc";
import CmnChecklistRunner from "c/cmnChecklistRunner";
import loadSheet from "@salesforce/apex/CMN_ChecklistController.load";
import saveAnswers from "@salesforce/apex/CMN_ChecklistController.saveAnswers";
import previewScore from "@salesforce/apex/CMN_ChecklistController.preview";
import raiseFollowUp from "@salesforce/apex/CMN_ChecklistController.raiseFollowUp";
import LightningConfirm from "lightning/confirm";
import CmnChecklistFollowUp from "c/cmnChecklistFollowUp";
import { CurrentPageReference } from "lightning/navigation";
import { draftKey } from "c/cmnDraftStore";
import USER_ID from "@salesforce/user/Id";
import SHEET from "./data/sheet.json";

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
jest.mock("lightning/confirm", () => ({
  __esModule: true,
  default: { open: jest.fn() }
}));
jest.mock("c/cmnChecklistFollowUp", () => ({
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

async function mount(s = sheet()) {
  loadSheet.mockResolvedValue(s);
  const el = createElement("c-cmn-checklist-runner", {
    is: CmnChecklistRunner
  });
  el.recordId = REC;
  document.body.appendChild(el);
  await flush();
  await flush();
  return el;
}

const one = (el, sel) => el.shadowRoot.querySelector(sel);
const all = (el, sel) => el.shadowRoot.querySelectorAll(sel);
const title = (el) => one(el, "h2.question-title").textContent.trim();

async function next(el, times = 1) {
  for (let i = 0; i < times; i++) {
    one(el, "lightning-button.btn-next").click();
    // eslint-disable-next-line no-await-in-loop
    await flush();
  }
}

async function choose(el, value) {
  one(el, `button[data-value="${value}"]`).click();
  await flush();
}

async function textField(el, field, value) {
  one(el, `lightning-textarea[data-field="${field}"]`).dispatchEvent(
    new CustomEvent("change", { detail: { value } })
  );
  await flush();
}

describe("c-cmn-checklist-runner (UX-009)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    localStorage.clear();
    jest.clearAllMocks();
  });

  it("AC-1: shows only the allowed score buttons", async () => {
    const el = await mount();
    expect(title(el)).toContain("1.1");
    expect(one(el, "lightning-icon.star")).not.toBeNull();
    const buttons = all(el, "button.score-button");
    expect([...buttons].map((b) => b.textContent.trim())).toEqual([
      "0",
      "4",
      "6",
      "8",
      "10"
    ]);
    expect(one(el, "lightning-input.points-input")).toBeNull();
    await choose(el, "6");
    expect(one(el, 'button[data-value="6"]').getAttribute("aria-pressed")).toBe(
      "true"
    );
    // 4점 이하면 관찰 메모 필수 안내와 후속 조치 미생성 사유 칸
    await choose(el, "4");
    expect(one(el, "p.note-hint")).not.toBeNull();
    expect(one(el, "lightning-textarea.no-follow-up")).not.toBeNull();
  });

  it("AC-2: shows provider errors on the question card and keeps the answer", async () => {
    const el = await mount();
    await choose(el, "4");
    await next(el, 2);
    LightningConfirm.open.mockResolvedValue(true);
    saveAnswers.mockResolvedValue({
      success: false,
      errors: [{ questionKey: "Q1", message: "Add a note" }]
    });
    saveAnswers.mockClear();
    one(el, "lightning-button.btn-submit").click();
    await flush();
    await flush();
    expect(saveAnswers.mock.calls[0][0].isFinal).toBe(true);
    // 오류 질문으로 돌아가 카드에 보인다
    expect(title(el)).toContain("1.1");
    expect(one(el, "p.card-error").textContent).toBe("Add a note");
  });

  it("AC-3: creates a follow-up through the provider and marks the card", async () => {
    const el = await mount();
    CmnChecklistFollowUp.open.mockResolvedValue({
      title: "Post standard",
      description: "",
      ownerId: null,
      dueDate: "2026-11-13",
      severity: "HIGH"
    });
    raiseFollowUp.mockResolvedValue("a0A000000000001AAA");
    one(el, "lightning-button.btn-follow-up").click();
    await flush();
    await flush();
    expect(CmnChecklistFollowUp.open.mock.calls[0][0].questionText).toContain(
      "1.1"
    );
    expect(raiseFollowUp).toHaveBeenCalledWith({
      recordId: REC,
      questionKey: "Q1",
      inputJson: JSON.stringify({
        title: "Post standard",
        description: "",
        ownerId: null,
        dueDate: "2026-11-13",
        severity: "HIGH"
      })
    });
    expect(one(el, "span.follow-up-done")).not.toBeNull();
    expect(one(el, "lightning-button.btn-follow-up")).toBeNull();
  });

  it("AC-4: saves pending answers first, then shows the provider score", async () => {
    const el = await mount();
    saveAnswers.mockResolvedValue({ success: true, errors: [] });
    await choose(el, "8");
    previewScore.mockResolvedValue({
      percent: 71.7,
      grade: "C",
      gradeBeforeDowngrade: "B",
      downgradeReasons: ["Starred question low"],
      sectionPercents: [{ key: "S1", label: "Process control", percent: 70 }],
      unansweredCount: 3
    });
    one(el, "lightning-button.btn-score").click();
    await flush();
    await flush();
    expect(saveAnswers).toHaveBeenCalledTimes(1);
    expect(saveAnswers.mock.calls[0][0].isFinal).toBe(false);
    expect(previewScore).toHaveBeenCalledWith({ recordId: REC });
    expect(one(el, "p.score-unanswered").textContent).toBe(
      "c.CMN_Checklist_Unanswered"
    );
    expect(one(el, "li.score-reason").textContent).toBe("Starred question low");
    expect(one(el, "p.score-before")).not.toBeNull();
    expect(one(el, "li.score-section").textContent).toBe(
      "Process control: 70%"
    );
  });

  it("AC-5: moves between questions without calling the server", async () => {
    const el = await mount();
    await next(el, 3);
    expect(title(el)).toContain("2.1");
    one(el, "lightning-button.btn-prev").click();
    await flush();
    expect(title(el)).toContain("1.3");
    expect(saveAnswers).not.toHaveBeenCalled();
    expect(previewScore).not.toHaveBeenCalled();
    expect(loadSheet).toHaveBeenCalledTimes(1);
  });

  it("AC-6: hides NA when not allowed and blocks NA without a reason", async () => {
    const el = await mount();
    expect(one(el, "lightning-input.na")).toBeNull();
    await next(el, 1);
    expect(title(el)).toContain("1.2");
    const na = one(el, "lightning-input.na");
    na.dispatchEvent(new CustomEvent("change", { detail: { checked: true } }));
    await flush();
    expect(one(el, "lightning-textarea.na-reason")).not.toBeNull();
    expect(one(el, "lightning-input.points-input").disabled).toBe(true);
    one(el, "lightning-button.btn-submit").click();
    await flush();
    expect(saveAnswers).not.toHaveBeenCalled();
    expect(one(el, "p.card-error").textContent).toBe(
      "c.CMN_Checklist_NaReasonRequired"
    );
  });

  it("AC-7: my questions only hides questions assigned to someone else", async () => {
    const el = await mount();
    one(el, "lightning-input.my-only").dispatchEvent(
      new CustomEvent("change", { detail: { checked: true } })
    );
    await flush();
    one(el, "lightning-radio-group.view").dispatchEvent(
      new CustomEvent("change", { detail: { value: "TABLE" } })
    );
    await flush();
    const keys = [...all(el, "lightning-button.btn-open")].map(
      (b) => b.dataset.key
    );
    // Q5는 다른 사용자 분담, Q4는 내 분담, 분담 없는 질문은 모두 보인다
    expect(keys).toEqual(["Q1", "Q2", "Q3", "Q4", "Q6"]);
    // 표에서 열기 → 카드
    all(el, "lightning-button.btn-open")[3].click();
    await flush();
    expect(title(el)).toContain("2.1");
  });

  it("BR-7: completing a section saves once; after a failure nothing is resent until Save Now", async () => {
    const el = await mount();
    saveAnswers.mockRejectedValue(new Error("offline"));
    await choose(el, "8");
    await next(el, 1);
    one(el, "lightning-input.points-input").dispatchEvent(
      new CustomEvent("change", { detail: { value: "5" } })
    );
    await flush();
    expect(saveAnswers).not.toHaveBeenCalled();
    await next(el, 1);
    await choose(el, "COMPLIANT");
    await flush();
    expect(saveAnswers).toHaveBeenCalledTimes(1);
    expect(one(el, "p.save-failed")).not.toBeNull();
    // 요소 2를 다 답해도 다시 보내지 않는다
    await next(el, 1);
    await choose(el, "YES");
    expect(saveAnswers).toHaveBeenCalledTimes(1);
    expect(one(el, "span.status-text").textContent).toBe(
      "c.CMN_Checklist_Pending"
    );
    saveAnswers.mockResolvedValue({ success: true, errors: [] });
    one(el, "lightning-button.btn-save-now").click();
    await flush();
    await flush();
    expect(saveAnswers).toHaveBeenCalledTimes(2);
    expect(
      JSON.parse(saveAnswers.mock.calls[1][0].answersJson)
        .map((a) => a.questionKey)
        .sort()
    ).toEqual(["Q1", "Q2", "Q3", "Q4"]);
    expect(one(el, "span.status-text").textContent).toBe(
      "c.CMN_Checklist_ServerSaved"
    );
  });

  it("restores a device draft, navigates sections and submits", async () => {
    localStorage.setItem(
      draftKey(USER_ID, "CHECKLIST", REC),
      JSON.stringify({
        v: 1,
        savedAt: Date.now(),
        ttl: 7 * 86400000,
        payload: {
          answers: {
            Q6: { questionKey: "Q6", text: "Draft idea", photoIds: [] }
          }
        }
      })
    );
    LightningConfirm.open.mockResolvedValue(true);
    const el = await mount();
    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    // 요소 2로 이동
    all(el, "button.section-link")[1].click();
    await flush();
    expect(title(el)).toContain("2.1");
    await next(el, 2);
    expect(one(el, "lightning-textarea.answer-text").value).toBe("Draft idea");
    await textField(el, "notes", "Seen on line 2");
    saveAnswers.mockResolvedValue({ success: true, errors: [] });
    one(el, "lightning-button.btn-submit").click();
    await flush();
    await flush();
    const final = saveAnswers.mock.calls.find((c) => c[0].isFinal)[0];
    expect(JSON.parse(final.answersJson)).toEqual([
      {
        questionKey: "Q6",
        text: "Draft idea",
        photoIds: [],
        notes: "Seen on line 2"
      }
    ]);
    expect(
      localStorage.getItem(draftKey(USER_ID, "CHECKLIST", REC))
    ).toBeNull();
  });

  it("is read-only when the sheet is not editable and hides the score when not visible", async () => {
    const el = await mount(sheet({ editable: false, scoreVisible: false }));
    expect(one(el, "lightning-button.btn-submit")).toBeNull();
    expect(one(el, "lightning-button.btn-score")).toBeNull();
    expect(one(el, "lightning-button.btn-follow-up")).toBeNull();
    expect(one(el, "p.read-only")).not.toBeNull();
    expect(one(el, 'button[data-value="6"]').disabled).toBe(true);
    expect(LightningConfirm.open).not.toHaveBeenCalled();
  });

  it("reads the record from the page state and reports load errors", async () => {
    loadSheet.mockRejectedValue({ body: { message: "No checklist" } });
    const el = createElement("c-cmn-checklist-runner", {
      is: CmnChecklistRunner
    });
    document.body.appendChild(el);
    CurrentPageReference.emit({ state: {} });
    await flush();
    expect(one(el, "p.no-record")).not.toBeNull();
    CurrentPageReference.emit({ state: { c__recordId: REC } });
    await flush();
    await flush();
    expect(one(el, "p.load-error").textContent).toBe("No checklist");
  });
});
