import { createElement } from "lwc";
import CmnApprovalHistory from "c/cmnApprovalHistory";
import getHistory from "@salesforce/apex/CMN_ApprovalController.getHistory";

jest.mock(
  "@salesforce/apex/CMN_ApprovalController.getHistory",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function mount() {
  const el = createElement("c-cmn-approval-history", {
    is: CmnApprovalHistory
  });
  el.recordId = "a01000000000001AAA";
  document.body.appendChild(el);
  await flush();
  return el;
}
const qa = (el, s) => [...el.shadowRoot.querySelectorAll(s)];

describe("c-cmn-approval-history", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("버전 1 반려·버전 2 승인을 구분해 순서대로(AC-2)", async () => {
    getHistory.mockResolvedValue([
      {
        requestId: "a0K1",
        version: 1,
        recordNo: "APV-1",
        status: "REJECTED",
        steps: [
          {
            id: "s1",
            stepNo: 1,
            stepType: "APPROVE",
            approverName: "Kim",
            status: "REJECTED",
            actorLabel: "Kim",
            comment: "no"
          }
        ]
      },
      {
        requestId: "a0K2",
        version: 2,
        recordNo: "APV-2",
        status: "APPROVED",
        steps: [
          {
            id: "s2",
            stepNo: 1,
            stepType: "APPROVE",
            approverName: "Kim",
            status: "APPROVED",
            actorLabel: "Lee (on behalf of Kim)"
          }
        ]
      }
    ]);
    const el = await mount();
    const sections = qa(el, "section");
    expect(sections.map((s) => s.dataset.version)).toEqual(["1", "2"]);
    expect(sections[0].textContent).toContain("REJECTED");
    expect(qa(el, "[data-id=actor]")[1].textContent).toContain("on behalf of");
  });

  it("이력 없음·오류", async () => {
    getHistory.mockResolvedValue([]);
    let el = await mount();
    expect(el.shadowRoot.querySelector("[data-id=empty]")).not.toBeNull();
    document.body.removeChild(el);
    getHistory.mockRejectedValue({});
    el = await mount();
    expect(el.shadowRoot.querySelector("p[role=alert]")).not.toBeNull();
  });
});
