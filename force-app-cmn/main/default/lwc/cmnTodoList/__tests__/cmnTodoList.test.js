import { createElement } from "lwc";
import CmnTodoList from "c/cmnTodoList";
import getTodos from "@salesforce/apex/CMN_TodoListController.getTodos";

jest.mock(
  "@salesforce/apex/CMN_TodoListController.getTodos",
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
const row = (n, extra = {}) => ({
  id: `a0T00000000000${n}AAA`,
  title: `todo ${n}`,
  recordNo: `NCR-${n}`,
  plantName: "KR01",
  dueDate: "2026-11-01",
  isOverdue: false,
  navigationId: `a0X00000000000${n}AAA`,
  ...extra
});

async function mount(systemCode) {
  const el = createElement("c-cmn-todo-list", { is: CmnTodoList });
  if (systemCode) {
    el.systemCode = systemCode;
  }
  document.body.appendChild(el);
  await flush();
  return el;
}
const q = (el, s) => el.shadowRoot.querySelector(s);
const qa = (el, s) => el.shadowRoot.querySelectorAll(s);

describe("c-cmn-todo-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("앱 기본 시스템으로 업무 탭을 읽고 탭에 건수 표시(AC-1·BR-1)", async () => {
    getTodos.mockResolvedValue({
      items: [row(1), row(2, { isOverdue: true })],
      taskCount: 2,
      approvalCount: 4,
      hasMore: false
    });
    const el = await mount("PMS");
    expect(getTodos).toHaveBeenCalledWith({
      category: "TASK",
      systemFilter: "PMS",
      offsetRows: 0
    });
    expect(qa(el, "[data-id=item]").length).toBe(2);
    expect(q(el, "[data-id=tab-task]").label).toBe(
      "c.CMN_TodoList_TabTask (2)"
    );
    expect(q(el, "[data-id=tab-approval]").label).toBe(
      "c.CMN_TodoList_TabApproval (4)"
    );
    // 기한 경과는 색과 문구를 함께
    expect(qa(el, "[data-id=overdue]").length).toBe(1);
  });

  it("시스템 필터 전체로 바꾸면 다시 읽음(AC-1)", async () => {
    getTodos.mockResolvedValue({ items: [row(1)], taskCount: 1 });
    const el = await mount();
    q(el, "[data-id=system]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "ALL" } })
    );
    await flush();
    expect(getTodos).toHaveBeenLastCalledWith({
      category: "TASK",
      systemFilter: "ALL",
      offsetRows: 0
    });
  });

  it("결재 탭 전환, 항목을 누르면 서버가 정한 레코드를 연다(BR-2)", async () => {
    getTodos.mockResolvedValue({
      items: [row(7)],
      taskCount: 0,
      approvalCount: 1
    });
    const el = await mount();
    const tab = q(el, "[data-id=tab-approval]");
    tab.value = "APPROVAL";
    tab.dispatchEvent(new CustomEvent("active"));
    await flush();
    expect(getTodos).toHaveBeenLastCalledWith({
      category: "APPROVAL",
      systemFilter: "QMS",
      offsetRows: 0
    });
    q(el, "[data-id=item] lightning-button").click();
    expect(mockNavigate).toHaveBeenCalledWith({
      type: "standard__recordPage",
      attributes: { recordId: "a0X000000000007AAA", actionName: "view" }
    });
  });

  it("20건 다음은 더 보기로 이어서 읽음(BR-2)", async () => {
    const first = Array.from({ length: 20 }, (_, i) => row(i + 10));
    getTodos
      .mockResolvedValueOnce({ items: first, taskCount: 21, hasMore: true })
      .mockResolvedValueOnce({ items: [row(99)], taskCount: 21 });
    const el = await mount();
    q(el, "[data-id=more]").click();
    await flush();
    expect(getTodos).toHaveBeenLastCalledWith({
      category: "TASK",
      systemFilter: "QMS",
      offsetRows: 20
    });
    expect(qa(el, "[data-id=item]").length).toBe(21);
    expect(q(el, "[data-id=more]")).toBeNull();
  });

  it("빈 결과와 오류 상태", async () => {
    getTodos.mockResolvedValueOnce({ items: [] });
    let el = await mount();
    expect(q(el, "[data-id=empty]")).not.toBeNull();
    document.body.removeChild(el);
    getTodos.mockRejectedValueOnce({ body: { message: "fail" } });
    el = await mount();
    expect(q(el, "[data-id=error]").textContent).toContain("fail");
    getTodos.mockResolvedValueOnce({ items: [row(1)] });
    q(el, "[data-id=retry]").click();
    await flush();
    expect(qa(el, "[data-id=item]").length).toBe(1);
  });
});
