import { createElement } from "lwc";
import CmnApprovalAction from "c/cmnApprovalAction";
import getAction from "@salesforce/apex/CMN_ApprovalController.getAction";
import approve from "@salesforce/apex/CMN_ApprovalController.approve";
import reject from "@salesforce/apex/CMN_ApprovalController.reject";

jest.mock(
  "@salesforce/apex/CMN_ApprovalController.getAction",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ApprovalController.approve",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ApprovalController.reject",
  () => ({ default: jest.fn() }),
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
const VIEW = {
  requestId: "a0K000000000001AAA",
  recordNo: "APV-2026-0000001",
  title: "4M change",
  status: "IN_PROGRESS",
  targetId: "a01000000000001AAA",
  myStepId: "a0L000000000001AAA",
  isDelegate: false,
  summary: [{ label: "Status", value: "DRAFT" }]
};

async function mount(view = VIEW) {
  getAction.mockResolvedValue(view);
  const el = createElement("c-cmn-approval-action", { is: CmnApprovalAction });
  el.recordId = "a0K000000000001AAA";
  document.body.appendChild(el);
  await flush();
  return el;
}
const q = (el, s) => el.shadowRoot.querySelector(s);

describe("c-cmn-approval-action", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("반려는 의견이 있어야 켜진다(AC-1)", async () => {
    const el = await mount();
    expect(q(el, "[data-id=reject]").disabled).toBe(true);
    q(el, "[data-id=comment]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "fix spec" } })
    );
    await flush();
    expect(q(el, "[data-id=reject]").disabled).toBe(false);
    reject.mockResolvedValue();
    q(el, "[data-id=reject]").click();
    await flush();
    expect(reject).toHaveBeenCalledWith({
      stepId: "a0L000000000001AAA",
      comment: "fix spec"
    });
  });

  it("승인, 스냅숏, 대상 열기", async () => {
    const el = await mount();
    expect(q(el, "[data-id=summary]")).not.toBeNull();
    approve.mockResolvedValue();
    q(el, "[data-id=approve]").click();
    await flush();
    expect(approve).toHaveBeenCalledWith({
      stepId: "a0L000000000001AAA",
      comment: ""
    });
    q(el, "[data-id=target]").click();
    expect(mockNavigate.mock.calls[0][0].attributes.recordId).toBe(
      "a01000000000001AAA"
    );
  });

  it("대결 표시, 처리 차례 아님, 서버 오류", async () => {
    let el = await mount({ ...VIEW, isDelegate: true, delegatorName: "Kim" });
    // Jest 라벨 목은 키 문자열이라 토큰 치환 대신 대결 안내 영역 표시만 본다
    expect(q(el, "[data-id=delegated]")).not.toBeNull();
    document.body.removeChild(el);
    el = await mount({ ...VIEW, myStepId: null });
    expect(q(el, "[data-id=not-my-turn]")).not.toBeNull();
    document.body.removeChild(el);
    el = await mount();
    const toast = jest.fn();
    el.addEventListener("lightning__showtoast", toast);
    approve.mockRejectedValue({ body: { message: "not pending" } });
    q(el, "[data-id=approve]").click();
    await flush();
    expect(toast.mock.calls[0][0].detail.message).toBe("not pending");
  });
});
