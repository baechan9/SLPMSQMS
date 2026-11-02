import { createElement } from "lwc";
import CmnAppMenuHub from "c/cmnAppMenuHub";
import getMenu from "@salesforce/apex/CMN_AppMenuController.getMenu";

jest.mock(
  "@salesforce/apex/CMN_AppMenuController.getMenu",
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
const MENU = {
  menuKey: "QMS_03",
  title: "Parts",
  description: "desc",
  iconName: "standard:partners",
  readyCount: 2,
  items: [
    {
      key: "A",
      featureCode: "IQC",
      title: "Incoming",
      ready: false,
      bundle: "A1"
    },
    {
      key: "B",
      featureCode: "MDM",
      title: "Plants",
      ready: true,
      targetType: "OBJECT",
      target: "CMN_Plant__c"
    },
    {
      key: "C",
      featureCode: "APV",
      title: "Approvals",
      ready: true,
      targetType: "PAGE",
      target: "CMN_ApprovalMonitor"
    }
  ]
};

async function mount() {
  const el = createElement("c-cmn-app-menu-hub", { is: CmnAppMenuHub });
  el.menuKey = "QMS_03";
  document.body.appendChild(el);
  await flush();
  return el;
}
const q = (el, s) => el.shadowRoot.querySelector(s);
const qa = (el, s) => el.shadowRoot.querySelectorAll(s);

describe("c-cmn-app-menu-hub", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("메뉴 머리글과 타일: 준비 중은 묶음 표시, 사용 가능은 열기 버튼", async () => {
    getMenu.mockResolvedValue(MENU);
    const el = await mount();
    expect(getMenu).toHaveBeenCalledWith({ menuKey: "QMS_03" });
    expect(q(el, "[data-id=title]").textContent).toContain("Parts");
    expect(qa(el, "[data-id=tile]").length).toBe(3);
    expect(qa(el, "[data-id=planned]").length).toBe(1);
    expect(qa(el, "[data-id=open]").length).toBe(2);
  });

  it("객체 타일은 목록, 페이지 타일은 앱 페이지를 연다", async () => {
    getMenu.mockResolvedValue(MENU);
    const el = await mount();
    const buttons = qa(el, "[data-id=open]");
    buttons[0].click();
    expect(mockNavigate).toHaveBeenLastCalledWith({
      type: "standard__objectPage",
      attributes: { objectApiName: "CMN_Plant__c", actionName: "home" }
    });
    buttons[1].click();
    expect(mockNavigate).toHaveBeenLastCalledWith({
      type: "standard__navItemPage",
      attributes: { apiName: "CMN_ApprovalMonitor" }
    });
  });

  it("빈 메뉴와 오류(다시 시도)", async () => {
    getMenu.mockResolvedValueOnce({ ...MENU, items: [], readyCount: 0 });
    let el = await mount();
    expect(q(el, "[data-id=empty]")).not.toBeNull();
    document.body.removeChild(el);
    getMenu.mockRejectedValueOnce({ body: { message: "nope" } });
    el = await mount();
    expect(q(el, "[data-id=error]").textContent).toContain("nope");
    getMenu.mockResolvedValueOnce(MENU);
    q(el, "[data-id=retry]").click();
    await flush();
    expect(qa(el, "[data-id=tile]").length).toBe(3);
  });
});
