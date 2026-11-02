import { createElement } from "lwc";
import CmnWidgetBoard from "c/cmnWidgetBoard";
import getBoard from "@salesforce/apex/CMN_DashboardController.getBoard";

jest.mock(
  "@salesforce/client/formFactor",
  () => ({ __esModule: true, default: "Small" }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_DashboardController.getBoard",
  () => ({ default: jest.fn(() => Promise.resolve({ items: [] })) }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function mount(hideOnPhone) {
  const el = createElement("c-cmn-widget-board", { is: CmnWidgetBoard });
  el.hideOnPhone = hideOnPhone;
  document.body.appendChild(el);
  await flush();
  return el;
}

describe("c-cmn-widget-board 휴대폰", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("홈 배치(hideOnPhone)면 휴대폰에서 그리지 않고 읽지도 않음(TDO-004 BR-3)", async () => {
    const el = await mount(true);
    expect(el.shadowRoot.querySelector("lightning-card")).toBeNull();
    expect(getBoard).not.toHaveBeenCalled();
  });

  it("대시보드 탭 배치면 휴대폰에서도 보드를 그림", async () => {
    const el = await mount(false);
    expect(el.shadowRoot.querySelector("lightning-card")).not.toBeNull();
    expect(getBoard).toHaveBeenCalled();
  });
});
