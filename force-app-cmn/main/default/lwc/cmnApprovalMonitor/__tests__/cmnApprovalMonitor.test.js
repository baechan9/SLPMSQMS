import { createElement } from "lwc";
import CmnApprovalMonitor from "c/cmnApprovalMonitor";
import getMonitor from "@salesforce/apex/CMN_ApprovalController.getMonitor";

jest.mock(
  "@salesforce/apex/CMN_ApprovalController.getMonitor",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ApprovalController.getTypes",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);
const mockNavigate = jest.fn();
jest.mock("lightning/navigation", () => {
  const Navigate = Symbol("Navigate");
  const NavigationMixin = (Base) =>
    class extends Base {
      [Navigate](ref) {
        mockNavigate(ref);
      }
    };
  NavigationMixin.Navigate = Navigate;
  return { __esModule: true, NavigationMixin };
});

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const ROW = {
  requestId: "a0K000000000001AAA",
  recordNo: "APV-1",
  title: "doc",
  status: "IN_PROGRESS",
  pendingDays: 3
};

async function mount() {
  const el = createElement("c-cmn-approval-monitor", {
    is: CmnApprovalMonitor
  });
  document.body.appendChild(el);
  await flush();
  return el;
}
const q = (el, s) => el.shadowRoot.querySelector(s);

describe("c-cmn-approval-monitor", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("내가 상신으로 시작하고 보기·필터를 바꿔 조회한다", async () => {
    getMonitor.mockResolvedValue([ROW]);
    const el = await mount();
    expect(getMonitor.mock.calls[0][0].view).toBe("SUBMITTED");
    expect(q(el, "[data-id=table]").data[0].pendingDays).toBe(3);

    q(el, "[data-id=tab-progress]").dispatchEvent(new CustomEvent("active"));
    await flush();
    expect(getMonitor.mock.calls[1][0].view).toBe("IN_PROGRESS");

    q(el, "[data-id=type]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "CMN_DOC_RELEASE" } })
    );
    q(el, "[data-id=from]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "2026-11-01" } })
    );
    q(el, "[data-id=search]").click();
    await flush();
    expect(getMonitor.mock.calls[2][0]).toMatchObject({
      view: "IN_PROGRESS",
      typeCode: "CMN_DOC_RELEASE",
      fromDate: "2026-11-01"
    });
  });

  it("행의 결재 번호로 결재 요청을 연다", async () => {
    getMonitor.mockResolvedValue([ROW]);
    const el = await mount();
    q(el, "[data-id=table]").dispatchEvent(
      new CustomEvent("rowaction", {
        detail: { action: { name: "open" }, row: ROW }
      })
    );
    expect(mockNavigate.mock.calls[0][0].attributes.recordId).toBe(
      "a0K000000000001AAA"
    );
  });

  it("빈 결과·오류", async () => {
    getMonitor.mockResolvedValue([]);
    let el = await mount();
    expect(q(el, "[data-id=empty]")).not.toBeNull();
    document.body.removeChild(el);
    getMonitor.mockRejectedValue({ body: { message: "bad" } });
    el = await mount();
    expect(q(el, "p[role=alert]").textContent).toBe("bad");
  });
});
