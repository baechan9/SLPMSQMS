import {
  draftKey,
  saveDraft,
  loadDraft,
  clearDraft,
  pruneDrafts,
  DRAFT_TTL_MS
} from "c/cmnDraftStore";

describe("c-cmn-draft-store (UX-006 BR-2)", () => {
  afterEach(() => {
    localStorage.clear();
    jest.restoreAllMocks();
  });

  it("saves, loads and clears a draft per user, screen and record", () => {
    const mine = draftKey("005A", "GRID", "a01");
    const other = draftKey("005B", "GRID", "a01");
    expect(saveDraft(mine, { rows: [1, 2] })).toBe(true);
    expect(loadDraft(mine)).toEqual({ rows: [1, 2] });
    expect(loadDraft(other)).toBeNull();
    clearDraft(mine);
    expect(loadDraft(mine)).toBeNull();
  });

  it("drops expired and broken drafts", () => {
    const key = draftKey("u", "g", "r");
    const now = Date.now();
    saveDraft(key, { a: 1 });
    jest.spyOn(Date, "now").mockReturnValue(now + DRAFT_TTL_MS + 1000);
    expect(loadDraft(key)).toBeNull();
    expect(localStorage.getItem(key)).toBeNull();

    localStorage.setItem(draftKey("u", "g", "broken"), "{not json");
    expect(loadDraft(draftKey("u", "g", "broken"))).toBeNull();
  });

  it("prunes only expired drafts", () => {
    const now = Date.now();
    localStorage.setItem(
      draftKey("u", "old"),
      JSON.stringify({ v: 1, savedAt: now - DRAFT_TTL_MS - 1, payload: {} })
    );
    saveDraft(draftKey("u", "new"), { b: 2 });
    localStorage.setItem("unrelated", "x");
    expect(pruneDrafts()).toBe(0);
    expect(localStorage.getItem(draftKey("u", "old"))).toBeNull();
    expect(loadDraft(draftKey("u", "new"))).toEqual({ b: 2 });
    expect(localStorage.getItem("unrelated")).toBe("x");
  });

  it("fails quietly when storage is full", () => {
    jest.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw new Error("QuotaExceededError");
    });
    expect(saveDraft(draftKey("u", "g"), { big: true })).toBe(false);
  });
});
