import { createElement } from "lwc";
import CmnRailPanel from "c/cmnRailPanel";
import resolveBindings from "@salesforce/apex/CMN_RailPanelController.resolveBindings";
import getOpenTodos from "@salesforce/apex/CMN_RailPanelController.getOpenTodos";

// 배포되지 않았거나 로드 중 실패하는 패널
jest.mock(
  "c/cmnRailBroken",
  () => {
    throw new Error("not deployed");
  },
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_RailPanelController.resolveBindings",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_RailPanelController.getOpenTodos",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const TODO = {
  key: "TODO",
  componentName: "c/cmnRailTodoList",
  title: "To-Do",
  config: null
};

async function mount(panel, open) {
  const el = createElement("c-cmn-rail-panel", { is: CmnRailPanel });
  el.panel = panel;
  el.open = open;
  el.recordId = "a01000000000001AAA";
  el.objectApiName = "CMN_TestRecord__c";
  document.body.appendChild(el);
  await flush();
  await flush();
  return el;
}
const q = (el, s) => el.shadowRoot.querySelector(s);

describe("c-cmn-rail-panel", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("AC-9: 접힌 패널은 컴포넌트를 불러오지 않고 서버도 부르지 않는다", async () => {
    const el = await mount(
      { ...TODO, config: '{"bind":{"plantId":"Plant__c"}}' },
      false
    );
    expect(q(el, "[data-id=body]")).toBeNull();
    expect(q(el, "[data-id=component]")).toBeNull();
    expect(resolveBindings).not.toHaveBeenCalled();
    expect(q(el, "[data-id=toggle]").getAttribute("aria-expanded")).toBe(
      "false"
    );
  });

  it("펼치면 패널을 불러와 계약 속성을 넘기고, 패널 건수를 배지로 보인다", async () => {
    const el = await mount(TODO, true);
    const child = q(el, "[data-id=component]");
    expect(child).not.toBeNull();
    expect(child.recordId).toBe("a01000000000001AAA");
    expect(child.variant).toBe("rail");
    getOpenTodos.emit([
      { id: "1", title: "A", isOverdue: true },
      { id: "2", title: "B", isOverdue: false }
    ]);
    await flush();
    expect(q(el, "[data-id=badge]").textContent).toBe("2");
  });

  it("AC-4: 패널 하나가 실패하면 그 칸에만 오류와 다시 시도", async () => {
    const el = await mount(
      { key: "X", componentName: "c/cmnRailBroken", title: "X" },
      true
    );
    expect(q(el, "[data-id=error]")).not.toBeNull();
    expect(q(el, "[data-id=retry]")).not.toBeNull();
    const bad = await mount(
      { key: "Y", componentName: "lightning/button", title: "Y" },
      true
    );
    expect(q(bad, "[data-id=error]")).not.toBeNull();
  });

  it("AC-6: 문맥 분석 bind는 레코드 값을 읽어 config에 넣는다", async () => {
    resolveBindings.mockResolvedValue({ Plant__c: "a02000000000001AAA" });
    const el = await mount(
      { ...TODO, config: '{"widgetKey":"W","bind":{"plantId":"Plant__c"}}' },
      true
    );
    expect(resolveBindings).toHaveBeenCalledWith({
      recordId: "a01000000000001AAA",
      fieldNames: ["Plant__c"]
    });
    expect(q(el, "[data-id=component]").config).toEqual({
      widgetKey: "W",
      bind: { plantId: "Plant__c" },
      plantId: "a02000000000001AAA"
    });
  });

  it("머리 버튼은 toggle 이벤트로 열림 상태를 알린다", async () => {
    const el = await mount(TODO, false);
    const handler = jest.fn();
    el.addEventListener("toggle", handler);
    q(el, "[data-id=toggle]").click();
    expect(handler.mock.calls[0][0].detail).toEqual({
      key: "TODO",
      open: true
    });
  });
});
