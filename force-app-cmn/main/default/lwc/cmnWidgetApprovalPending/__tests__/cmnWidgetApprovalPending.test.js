import { createElement } from "lwc";
import CmnWidgetApprovalPending from "c/cmnWidgetApprovalPending";
import approvalSummary from "@salesforce/apex/CMN_CoreWidgetController.approvalSummary";

jest.mock(
  "@salesforce/apex/CMN_CoreWidgetController.approvalSummary",
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

async function mount() {
  const el = createElement("c-cmn-widget-approval-pending", {
    is: CmnWidgetApprovalPending
  });
  el.config = { maxRows: 5 };
  document.body.appendChild(el);
  await flush();
  return el;
}

describe("c-cmn-widget-approval-pending", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("대기 결재 목록과 요청 열기", async () => {
    approvalSummary.mockResolvedValue({
      total: 7,
      rows: [
        {
          requestId: "a0K000000000001AAA",
          recordNo: "APV-1",
          title: "doc",
          pendingDays: 3
        }
      ]
    });
    const el = await mount();
    expect(
      el.shadowRoot.querySelector("[data-id=total]").textContent
    ).toContain("7");
    el.shadowRoot.querySelector("lightning-button").click();
    expect(mockNavigate.mock.calls[0][0].attributes.recordId).toBe(
      "a0K000000000001AAA"
    );
  });

  it("빈 결과·오류", async () => {
    approvalSummary.mockResolvedValue({ total: 0, rows: [] });
    let el = await mount();
    expect(el.shadowRoot.querySelector("[data-id=empty]")).not.toBeNull();
    document.body.removeChild(el);
    approvalSummary.mockRejectedValue({});
    el = await mount();
    expect(el.shadowRoot.querySelector("[role=alert]")).not.toBeNull();
  });
});
