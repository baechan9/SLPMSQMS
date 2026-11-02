import { createElement } from "lwc";
import CmnMeetingPanel from "c/cmnMeetingPanel";
import getPanel from "@salesforce/apex/CMN_MeetingController.getPanel";
import confirmMinutes from "@salesforce/apex/CMN_MeetingController.confirmMinutes";
import addAction from "@salesforce/apex/CMN_MeetingController.addAction";
import completeAction from "@salesforce/apex/CMN_MeetingController.completeAction";

jest.mock(
  "@salesforce/apex/CMN_MeetingController.getPanel",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_MeetingController.confirmMinutes",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_MeetingController.addAction",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_MeetingController.completeAction",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const PANEL = {
  canRead: true,
  canEdit: true,
  canConfirm: true,
  status: "HELD",
  actions: [
    {
      id: "a0A000000000001AAA",
      name: "fix jig",
      ownerName: "Kim",
      dueDate: "2026-12-10",
      status: "OPEN",
      statusLabel: "Open",
      canComplete: true
    }
  ]
};

async function mount(panel = PANEL) {
  getPanel.mockResolvedValue(panel);
  const el = createElement("c-cmn-meeting-panel", { is: CmnMeetingPanel });
  el.recordId = "a0M000000000001AAA";
  document.body.appendChild(el);
  await flush();
  return el;
}

const q = (el, sel) => el.shadowRoot.querySelector(sel);

describe("c-cmn-meeting-panel", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("조치 목록과 확정 버튼", async () => {
    const el = await mount();
    expect(q(el, "[data-action=a0A000000000001AAA]")).not.toBeNull();
    expect(q(el, "lightning-button[data-id=confirm]")).not.toBeNull();
  });

  it("회의록 확정 후 다시 불러온다", async () => {
    const el = await mount();
    confirmMinutes.mockResolvedValue(1);
    q(el, "lightning-button[data-id=confirm]").click();
    await flush();
    expect(confirmMinutes).toHaveBeenCalledWith({
      meetingId: "a0M000000000001AAA"
    });
    expect(getPanel).toHaveBeenCalledTimes(2);
  });

  it("조치 추가는 내용·담당자·기한이 있어야 한다", async () => {
    const el = await mount();
    const button = () => q(el, "lightning-button[data-id=add-button]");
    expect(button().disabled).toBe(true);
    q(el, "[data-field=title]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "check" } })
    );
    q(el, "lightning-record-picker").dispatchEvent(
      new CustomEvent("change", { detail: { recordId: "005000000000001AAA" } })
    );
    q(el, "[data-field=due]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "2026-12-20" } })
    );
    await flush();
    expect(button().disabled).toBe(false);
    addAction.mockResolvedValue("a0A000000000002AAA");
    button().click();
    await flush();
    expect(addAction).toHaveBeenCalledWith({
      meetingId: "a0M000000000001AAA",
      title: "check",
      ownerId: "005000000000001AAA",
      dueDate: "2026-12-20"
    });
  });

  it("조치 완료, 실패는 토스트", async () => {
    const el = await mount();
    const handler = jest.fn();
    el.addEventListener("lightning__showtoast", handler);
    completeAction.mockRejectedValue({ body: { message: "no access" } });
    q(el, "li lightning-button").click();
    await flush();
    expect(completeAction).toHaveBeenCalledWith({
      actionId: "a0A000000000001AAA"
    });
    expect(handler.mock.calls[0][0].detail.message).toBe("no access");
  });

  it("조치 없음·편집 불가·오류", async () => {
    let el = await mount({
      ...PANEL,
      canEdit: false,
      canConfirm: false,
      actions: []
    });
    expect(q(el, "[data-id=empty]")).not.toBeNull();
    expect(q(el, "[data-id=add]")).toBeNull();
    document.body.removeChild(el);
    getPanel.mockRejectedValue({});
    el = createElement("c-cmn-meeting-panel", { is: CmnMeetingPanel });
    document.body.appendChild(el);
    await flush();
    expect(q(el, "p[role=alert]").textContent).toBe(
      "c.CMN_Common_UnexpectedError"
    );
  });
});
