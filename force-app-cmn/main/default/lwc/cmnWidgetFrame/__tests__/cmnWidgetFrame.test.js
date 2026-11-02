import { createElement } from "lwc";
import CmnWidgetFrame from "c/cmnWidgetFrame";

// 배포되지 않았거나 로드 중 실패하는 위젯
jest.mock(
  "c/cmnWidgetBroken",
  () => {
    throw new Error("not deployed");
  },
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_CoreWidgetController.todoSummary",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const W = {
  widgetKey: "CMN_W_TODO_SUMMARY",
  title: "My",
  size: "S",
  state: "OK",
  configJson: '{"a":1}',
  mobileSupported: true
};

async function mount(widget, filters = {}) {
  const el = createElement("c-cmn-widget-frame", { is: CmnWidgetFrame });
  el.widget = widget;
  el.systemCode = "QMS";
  el.filters = filters;
  document.body.appendChild(el);
  await flush();
  await flush();
  return el;
}
const q = (el, s) => el.shadowRoot.querySelector(s);

describe("c-cmn-widget-frame", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("권한 없음·사용 불가 자리표시(BR-2)", async () => {
    let el = await mount({ ...W, state: "NO_ACCESS", componentName: null });
    expect(q(el, "[data-id=placeholder]").textContent).toBe(
      "c.CMN_WidgetBoard_NoAccess"
    );
    document.body.removeChild(el);
    el = await mount({ ...W, state: "UNAVAILABLE", componentName: null });
    expect(q(el, "[data-id=placeholder]").textContent).toBe(
      "c.CMN_WidgetBoard_Unavailable"
    );
  });

  it("위젯을 동적으로 로드하고 공통 필터를 config보다 우선 전달(BR-6)", async () => {
    const el = await mount(
      { ...W, componentName: "cmnWidgetTodoSummary" },
      { plantId: "a05000000000001AAA", period: "LAST_30_DAYS" }
    );
    const widget = q(el, "[data-id=widget]");
    expect(widget).not.toBeNull();
    expect(widget.config).toEqual({
      a: 1,
      system: "QMS",
      plantId: "a05000000000001AAA",
      period: "LAST_30_DAYS"
    });
  });

  it("위젯 로드 실패는 그 칸만 오류로(AC-3), 잘못된 컴포넌트 이름은 로드하지 않음", async () => {
    const el = await mount({ ...W, componentName: "cmnWidgetBroken" });
    expect(q(el, "[data-id=error]")).not.toBeNull();
    expect(q(el, "[data-id=retry]")).not.toBeNull();
    document.body.removeChild(el);
    const bad = await mount({ ...W, componentName: "../evil" });
    expect(q(bad, "[data-id=widget]")).toBeNull();
  });
});
