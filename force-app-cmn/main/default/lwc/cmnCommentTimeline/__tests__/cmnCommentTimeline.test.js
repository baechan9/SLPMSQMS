import { createElement } from "lwc";
import CmnCommentTimeline from "c/cmnCommentTimeline";
import { getRecord } from "lightning/uiRecordApi";
import LightningConfirm from "lightning/confirm";
import getComments from "@salesforce/apex/CMN_CommentController.getComments";
import postComment from "@salesforce/apex/CMN_CommentController.postComment";
import editComment from "@salesforce/apex/CMN_CommentController.editComment";
import deleteComment from "@salesforce/apex/CMN_CommentController.deleteComment";

jest.mock(
  "@salesforce/apex/CMN_CommentController.getComments",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_CommentController.postComment",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_CommentController.editComment",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_CommentController.deleteComment",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "lightning/confirm",
  () => ({ __esModule: true, default: { open: jest.fn() } }),
  {
    virtual: true
  }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const ROWS = [
  {
    id: "a0Q000000000001AAA",
    body: "mine",
    authorId: "005000000000001AAA",
    authorName: "Kim",
    createdDate: "2026-11-02T01:00:00.000Z",
    isEdited: true,
    canEdit: true,
    mentions: [{ id: "005000000000002AAA", name: "Lee" }]
  },
  {
    id: "a0Q000000000002AAA",
    body: "other",
    authorId: "005000000000003AAA",
    authorName: "Park",
    createdDate: "2026-11-01T01:00:00.000Z",
    isEdited: false,
    canEdit: false,
    mentions: []
  }
];

async function mount(rows = ROWS) {
  getComments.mockResolvedValue(rows);
  const el = createElement("c-cmn-comment-timeline", {
    is: CmnCommentTimeline
  });
  el.recordId = "a01000000000001AAA";
  document.body.appendChild(el);
  await flush();
  return el;
}

const q = (el, sel) => el.shadowRoot.querySelector(sel);
const qa = (el, sel) => [...el.shadowRoot.querySelectorAll(sel)];

describe("c-cmn-comment-timeline", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("최신순 목록을 그리고 본인 코멘트만 수정·삭제 버튼이 있다", async () => {
    const el = await mount();
    expect(qa(el, "li").length).toBe(2);
    expect(qa(el, "lightning-button[data-action=edit]").length).toBe(1);
    expect(qa(el, "lightning-badge").length).toBe(1);
    expect(q(el, "li").textContent).toContain("@Lee");
    expect(getComments).toHaveBeenCalledWith({
      parentId: "a01000000000001AAA"
    });
  });

  it("코멘트가 없으면 빈 안내", async () => {
    const el = await mount([]);
    expect(q(el, "[data-id=empty]")).not.toBeNull();
  });

  it("조회 오류는 서버 라벨 문구 또는 공통 문구", async () => {
    getComments.mockRejectedValue({ body: { message: "no access" } });
    const el = createElement("c-cmn-comment-timeline", {
      is: CmnCommentTimeline
    });
    document.body.appendChild(el);
    await flush();
    expect(q(el, "p[role=alert]").textContent).toBe("no access");
  });

  it("멘션을 골라 코멘트를 등록하면 다시 불러온다", async () => {
    const el = await mount();
    const button = q(el, "lightning-button[data-id=post]");
    expect(button.disabled).toBe(true);

    const area = q(el, "lightning-textarea[data-id=draft]");
    area.dispatchEvent(
      new CustomEvent("change", { detail: { value: "@Lee check" } })
    );
    const picker = q(el, "lightning-record-picker");
    picker.dispatchEvent(
      new CustomEvent("change", { detail: { recordId: "005000000000002AAA" } })
    );
    await flush();
    getRecord.emit({
      id: "005000000000002AAA",
      fields: { Name: { value: "Lee" } }
    });
    await flush();
    expect(q(el, "lightning-pill-container").items).toEqual([
      { name: "005000000000002AAA", label: "@Lee" }
    ]);

    postComment.mockResolvedValue("a0Q000000000009AAA");
    q(el, "lightning-button[data-id=post]").click();
    await flush();
    expect(postComment).toHaveBeenCalledWith({
      parentId: "a01000000000001AAA",
      body: "@Lee check",
      mentionedUserIds: ["005000000000002AAA"]
    });
    expect(getComments).toHaveBeenCalledTimes(2);
  });

  it("본인 코멘트를 고친다", async () => {
    const el = await mount();
    q(el, "lightning-button[data-action=edit]").click();
    await flush();
    q(el, "lightning-textarea[data-id=editDraft]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "mine v2" } })
    );
    editComment.mockResolvedValue();
    q(el, "lightning-button[data-id=save]").click();
    await flush();
    expect(editComment).toHaveBeenCalledWith({
      commentId: "a0Q000000000001AAA",
      body: "mine v2",
      mentionedUserIds: ["005000000000002AAA"]
    });
  });

  it("삭제는 확인 후에만", async () => {
    const el = await mount();
    LightningConfirm.open.mockResolvedValue(false);
    q(el, "lightning-button[data-action=delete]").click();
    await flush();
    expect(deleteComment).not.toHaveBeenCalled();

    LightningConfirm.open.mockResolvedValue(true);
    deleteComment.mockResolvedValue();
    q(el, "lightning-button[data-action=delete]").click();
    await flush();
    expect(deleteComment).toHaveBeenCalledWith({
      commentId: "a0Q000000000001AAA"
    });
  });

  it("저장 실패는 토스트로 알린다", async () => {
    const el = await mount();
    const handler = jest.fn();
    el.addEventListener("lightning__showtoast", handler);
    q(el, "lightning-textarea[data-id=draft]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "x" } })
    );
    postComment.mockRejectedValue({ body: { message: "expired" } });
    q(el, "lightning-button[data-id=post]").click();
    await flush();
    expect(handler).toHaveBeenCalled();
    expect(handler.mock.calls[0][0].detail.message).toBe("expired");
  });
});
