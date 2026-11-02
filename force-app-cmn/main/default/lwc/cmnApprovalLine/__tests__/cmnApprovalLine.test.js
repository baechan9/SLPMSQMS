import { createElement } from "lwc";
import CmnApprovalLine from "c/cmnApprovalLine";
import getLine from "@salesforce/apex/CMN_ApprovalController.getLine";
import searchApprovers from "@salesforce/apex/CMN_ApprovalController.searchApprovers";
import submit from "@salesforce/apex/CMN_ApprovalController.submit";
import recall from "@salesforce/apex/CMN_ApprovalController.recall";
import loadPersonal from "@salesforce/apex/CMN_ApprovalController.loadPersonal";
import savePersonal from "@salesforce/apex/CMN_ApprovalController.savePersonal";

jest.mock(
  "@salesforce/apex/CMN_ApprovalController.getLine",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ApprovalController.searchApprovers",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ApprovalController.submit",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ApprovalController.recall",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ApprovalController.loadPersonal",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_ApprovalController.savePersonal",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const VIEW = {
  canSubmit: true,
  allowEdit: true,
  canRecall: false,
  current: null,
  stepTypes: [
    { label: "Approve", value: "APPROVE" },
    { label: "Review", value: "REVIEW" }
  ],
  personalTemplates: [{ label: "Mine", value: "a0T000000000001AAA" }],
  steps: [
    {
      stepNo: 1,
      stepType: "REVIEW",
      approverId: "005000000000001AAA",
      approverName: "Kim",
      isMandatory: true
    },
    {
      stepNo: 2,
      stepType: "APPROVE",
      approverId: "005000000000002AAA",
      approverName: "Lee",
      isMandatory: false
    }
  ]
};

async function mount(view = VIEW) {
  getLine.mockResolvedValue(view);
  const el = createElement("c-cmn-approval-line", { is: CmnApprovalLine });
  el.recordId = "a01000000000001AAA";
  el.typeCode = "QMS_4M_APPROVE";
  document.body.appendChild(el);
  await flush();
  return el;
}
const q = (el, s) => el.shadowRoot.querySelector(s);
const qa = (el, s) => [...el.shadowRoot.querySelectorAll(s)];

describe("c-cmn-approval-line", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("해석된 결재선을 그리고 필수 단계는 삭제 버튼이 없다", async () => {
    const el = await mount();
    expect(qa(el, "li").length).toBe(2);
    expect(qa(el, "lightning-button-icon").length).toBe(1);
  });

  it("결재자를 검색해 추가하고 상신한다", async () => {
    const el = await mount();
    searchApprovers.mockResolvedValue([
      { id: "005000000000003AAA", name: "Park", departmentName: "QA" }
    ]);
    q(el, "[data-id=search]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "Pa" } })
    );
    await flush();
    q(el, "lightning-button[data-id='005000000000003AAA']").click();
    await flush();
    expect(qa(el, "li").length).toBe(3);
    submit.mockResolvedValue("a0K000000000001AAA");
    q(el, "[data-id=submit]").click();
    await flush();
    const arg = submit.mock.calls[0][0];
    expect(arg.typeCode).toBe("QMS_4M_APPROVE");
    expect(JSON.parse(arg.stepsJson).map((s) => s.approverId)).toEqual([
      "005000000000001AAA",
      "005000000000002AAA",
      "005000000000003AAA"
    ]);
    expect(getLine).toHaveBeenCalledTimes(2);
  });

  it("비필수 단계 삭제, 개인 결재선 불러오기·저장(AC-3)", async () => {
    const el = await mount();
    q(el, "lightning-button-icon").click();
    await flush();
    expect(qa(el, "li").length).toBe(1);
    loadPersonal.mockResolvedValue([
      {
        stepNo: 1,
        stepType: "REVIEW",
        approverId: "005000000000001AAA",
        approverName: "Kim",
        isMandatory: true
      },
      {
        stepNo: 2,
        stepType: "APPROVE",
        approverId: "005000000000009AAA",
        approverName: "Choi",
        isMandatory: false
      }
    ]);
    q(el, "[data-id=personal]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "a0T000000000001AAA" } })
    );
    await flush();
    expect(qa(el, "li").length).toBe(2);
    savePersonal.mockResolvedValue("a0T000000000002AAA");
    q(el, "[data-id=personal-name]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "My line" } })
    );
    q(el, "[data-id=save-personal]").click();
    await flush();
    expect(savePersonal.mock.calls[0][0].name).toBe("My line");
  });

  it("진행 중이면 상신 불가·회수 가능, 오류는 안내", async () => {
    const el = await mount({
      ...VIEW,
      canSubmit: false,
      canRecall: true,
      current: { status: "IN_PROGRESS", requestId: "a0K000000000001AAA" }
    });
    expect(q(el, "[data-id=in-progress]")).not.toBeNull();
    expect(q(el, "[data-id=submit]").disabled).toBe(true);
    expect(q(el, "[data-id=editor]")).toBeNull();
    recall.mockResolvedValue();
    q(el, "[data-id=recall]").click();
    await flush();
    expect(recall).toHaveBeenCalledWith({
      requestId: "a0K000000000001AAA",
      comment: ""
    });
    document.body.removeChild(el);
    getLine.mockRejectedValue({ body: { message: "role missing" } });
    const bad = createElement("c-cmn-approval-line", { is: CmnApprovalLine });
    document.body.appendChild(bad);
    await flush();
    expect(q(bad, "p[role=alert]").textContent).toBe("role missing");
  });
});
