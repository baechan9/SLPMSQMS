import { createElement } from "lwc";
import CmnWidgetBoard from "c/cmnWidgetBoard";
import getBoard from "@salesforce/apex/CMN_DashboardController.getBoard";
import saveBoard from "@salesforce/apex/CMN_DashboardController.saveBoard";
import resetBoard from "@salesforce/apex/CMN_DashboardController.resetBoard";
import getGallery from "@salesforce/apex/CMN_DashboardController.getGallery";
import LightningConfirm from "lightning/confirm";

jest.mock(
  "@salesforce/apex/CMN_DashboardController.getBoard",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_DashboardController.saveBoard",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_DashboardController.resetBoard",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_DashboardController.getGallery",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_CoreWidgetController.todoSummary",
  () => ({ default: jest.fn(() => Promise.resolve({})) }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_CoreWidgetController.approvalSummary",
  () => ({ default: jest.fn(() => Promise.resolve({})) }),
  { virtual: true }
);
jest.mock("lightning/confirm", () => ({
  __esModule: true,
  default: { open: jest.fn() }
}));

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const ITEMS = [
  {
    widgetKey: "CMN_W_APPROVAL_PENDING",
    componentName: "cmnWidgetApprovalPending",
    title: "Approval",
    size: "M",
    position: 1,
    configJson: '{"maxRows":5}',
    state: "OK",
    hasSchema: true,
    mobileSupported: true
  },
  {
    widgetKey: "CMN_W_TODO_SUMMARY",
    componentName: "cmnWidgetTodoSummary",
    title: "Todo",
    size: "S",
    position: 2,
    configJson: "{}",
    state: "OK",
    hasSchema: false,
    mobileSupported: true
  }
];

async function mount() {
  getBoard.mockResolvedValue({
    systemCode: "QMS",
    sourceTemplate: "QMS_DEFAULT",
    items: ITEMS
  });
  const el = createElement("c-cmn-widget-board", { is: CmnWidgetBoard });
  document.body.appendChild(el);
  await flush();
  return el;
}
const q = (el, s) => el.shadowRoot.querySelector(s);
const qa = (el, s) => [...el.shadowRoot.querySelectorAll(s)];

describe("c-cmn-widget-board", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("템플릿 배치를 12열 그리드로 표시(AC-1, BR-1)", async () => {
    const el = await mount();
    expect(getBoard).toHaveBeenCalledWith({ systemCode: "QMS" });
    const cells = qa(el, "[data-widget]");
    expect(cells.map((c) => c.dataset.widget)).toEqual([
      "CMN_W_APPROVAL_PENDING",
      "CMN_W_TODO_SUMMARY"
    ]);
    expect(cells[0].className).toContain("slds-medium-size_6-of-12");
    expect(cells[1].className).toContain("slds-medium-size_4-of-12");
    expect(cells[0].className).toContain("slds-size_1-of-1");
  });

  it("편집: 추가·순서·크기 변경 후 저장(AC-2)", async () => {
    getGallery.mockResolvedValue([
      {
        widgetKey: "CMN_W_NEW",
        componentName: "cmnWidgetTodoSummary",
        title: "New",
        defaultSize: "L",
        defaultConfigJson: "{}",
        hasSchema: false,
        mobileSupported: true
      }
    ]);
    saveBoard.mockResolvedValue({ items: ITEMS });
    const el = await mount();
    q(el, "[data-id=edit]").click();
    await flush();
    q(el, "[data-id=gallery]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "CMN_W_NEW" } })
    );
    await flush();
    q(el, "[data-id=add]").click();
    await flush();
    qa(el, "[data-id=down]")[0].click();
    await flush();
    qa(el, "[data-id=size]")[0].dispatchEvent(
      new CustomEvent("change", { detail: { value: "L" } })
    );
    await flush();
    q(el, "[data-id=save]").click();
    await flush();
    const layout = JSON.parse(saveBoard.mock.calls[0][0].layoutJson);
    expect(layout.map((i) => i.widgetKey)).toEqual([
      "CMN_W_TODO_SUMMARY",
      "CMN_W_APPROVAL_PENDING",
      "CMN_W_NEW"
    ]);
    expect(layout[0].size).toBe("L");
    expect(layout.map((i) => i.order)).toEqual([1, 2, 3]);
    expect(layout[1].config).toEqual({ maxRows: 5 });
  });

  it("설정 JSON 적용·잘못된 JSON 거부, 제거, 취소", async () => {
    getGallery.mockResolvedValue([]);
    const el = await mount();
    q(el, "[data-id=edit]").click();
    await flush();
    expect(q(el, "[data-id=gallery-empty]")).not.toBeNull();
    q(el, "[data-id=settings]").click();
    await flush();
    const toast = jest.fn();
    el.addEventListener("lightning__showtoast", toast);
    q(el, "[data-id=config]").dispatchEvent(
      new CustomEvent("change", { detail: { value: "[1]" } })
    );
    q(el, "[data-id=apply]").click();
    await flush();
    expect(toast).toHaveBeenCalled();
    q(el, "[data-id=config]").dispatchEvent(
      new CustomEvent("change", { detail: { value: '{"maxRows":9}' } })
    );
    q(el, "[data-id=apply]").click();
    await flush();
    expect(q(el, "[data-id=config]")).toBeNull();
    qa(el, "[data-id=remove]")[0].click();
    await flush();
    expect(qa(el, "[data-widget]")).toHaveLength(1);
    q(el, "[data-id=cancel]").click();
    await flush();
    expect(qa(el, "[data-widget]")).toHaveLength(2);
  });

  it("템플릿으로 초기화는 확인 후(BR-3), 오류 표시", async () => {
    resetBoard.mockResolvedValue({ items: [] });
    LightningConfirm.open.mockResolvedValue(true);
    const el = await mount();
    q(el, "[data-id=reset]").click();
    await flush();
    await flush();
    expect(resetBoard).toHaveBeenCalledWith({ systemCode: "QMS" });
    expect(q(el, "[data-id=empty]")).not.toBeNull();
    document.body.removeChild(el);
    getBoard.mockRejectedValue({ body: { message: "denied" } });
    const err = createElement("c-cmn-widget-board", { is: CmnWidgetBoard });
    document.body.appendChild(err);
    await flush();
    expect(q(err, "p[role=alert]").textContent).toBe("denied");
  });
});
