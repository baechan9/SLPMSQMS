import { createElement } from "lwc";
import CmnRailTodoList from "c/cmnRailTodoList";
import getOpenTodos from "@salesforce/apex/CMN_RailPanelController.getOpenTodos";

jest.mock(
  "@salesforce/apex/CMN_RailPanelController.getOpenTodos",
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

async function mount() {
  const el = createElement("c-cmn-rail-todo-list", { is: CmnRailTodoList });
  el.recordId = "a01000000000001AAA";
  document.body.appendChild(el);
  await flush();
  return el;
}
const q = (el, s) => el.shadowRoot.querySelector(s);
const qa = (el, s) => el.shadowRoot.querySelectorAll(s);

describe("c-cmn-rail-todo-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("BR-6: 열린 To-Do를 보이고 건수를 railbadge로 알린다", async () => {
    const el = await mount();
    const badge = jest.fn();
    el.addEventListener("railbadge", badge);
    getOpenTodos.emit([
      { id: "t1", title: "Fix", assigneeName: "Kim", isOverdue: true },
      { id: "t2", title: "Check", assigneeName: "Lee", isOverdue: false }
    ]);
    await flush();
    expect(qa(el, "[data-id=todo]").length).toBe(2);
    expect(qa(el, "[data-id=overdue]").length).toBe(1);
    expect(badge.mock.calls[0][0].detail).toEqual({
      count: 2,
      severity: "warning"
    });
    q(el, "lightning-button").click();
    expect(mockNavigate).toHaveBeenCalledWith({
      type: "standard__recordPage",
      attributes: { recordId: "t1", actionName: "view" }
    });
  });

  it("빈 목록과 오류", async () => {
    const el = await mount();
    getOpenTodos.emit([]);
    await flush();
    expect(q(el, "[data-id=empty]")).not.toBeNull();
    getOpenTodos.error({ message: "nope" });
    await flush();
    expect(q(el, "[data-id=error]").textContent).toContain("nope");
  });
});
