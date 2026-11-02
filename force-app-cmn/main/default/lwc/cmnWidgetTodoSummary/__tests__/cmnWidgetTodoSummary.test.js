import { createElement } from "lwc";
import CmnWidgetTodoSummary from "c/cmnWidgetTodoSummary";
import todoSummary from "@salesforce/apex/CMN_CoreWidgetController.todoSummary";

jest.mock(
  "@salesforce/apex/CMN_CoreWidgetController.todoSummary",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function mount() {
  const el = createElement("c-cmn-widget-todo-summary", {
    is: CmnWidgetTodoSummary
  });
  el.config = { system: "QMS", plantId: "a05000000000001AAA" };
  document.body.appendChild(el);
  await flush();
  return el;
}

describe("c-cmn-widget-todo-summary", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("config를 그대로 넘기고 건수·기한 경과 표시", async () => {
    todoSummary.mockResolvedValue({ task: 3, approval: 2, overdue: 1 });
    const el = await mount();
    expect(JSON.parse(todoSummary.mock.calls[0][0].configJson)).toEqual({
      system: "QMS",
      plantId: "a05000000000001AAA"
    });
    expect(el.shadowRoot.querySelector("[data-id=task]").textContent).toContain(
      "3"
    );
    expect(
      el.shadowRoot.querySelector("[data-id=overdue] lightning-icon")
    ).not.toBeNull();
  });

  it("오류는 위젯 안에서 표시하고 다시 시도", async () => {
    todoSummary
      .mockRejectedValueOnce({ body: { message: "x" } })
      .mockResolvedValue({ task: 0, approval: 0, overdue: 0 });
    const el = await mount();
    expect(el.shadowRoot.querySelector("[role=alert]")).not.toBeNull();
    el.shadowRoot.querySelector("[data-id=retry]").click();
    await flush();
    expect(
      el.shadowRoot.querySelector("[data-id=overdue] lightning-icon")
    ).toBeNull();
  });
});
