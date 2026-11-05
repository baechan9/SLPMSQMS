import { createElement } from "lwc";
import CmnAppMenuHub from "c/cmnAppMenuHub";
import getMenu from "@salesforce/apex/CMN_AppMenuController.getMenu";
import getHub from "@salesforce/apex/CMN_AppMenuController.getHub";
import findRecord from "@salesforce/apex/CMN_AppMenuController.findRecord";

jest.mock(
  "@salesforce/client/formFactor",
  () => ({ __esModule: true, default: "Large" }),
  { virtual: true }
);
jest.mock(
  "@salesforce/label/c.CMN_AppMenu_Pending",
  () => ({ default: "{0} open" }),
  { virtual: true }
);
jest.mock(
  "@salesforce/label/c.CMN_AppMenu_Overdue",
  () => ({ default: "{0} overdue" }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_AppMenuController.getMenu",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_AppMenuController.getHub",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_AppMenuController.findRecord",
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
      target: "CMN_ApprovalMonitor",
      keywords: "sign-off,approve",
      pendingCount: 3,
      overdueCount: 1
    }
  ]
};
const HUB = {
  appName: "SL_QMS_Quality",
  title: "Menu Hub",
  description: "hub",
  numberPrefixes: ["NCR-", "TST-"],
  groups: [
    { ...MENU, pageTab: "QMS_Menu03" },
    {
      menuKey: "CMN_WORK",
      title: "Common Work",
      readyCount: 1,
      pageTab: "CMN_MenuWork",
      items: [
        {
          key: "D",
          featureCode: "TDO",
          title: "To-Do",
          ready: true,
          targetType: "OBJECT",
          target: "CMN_Todo__c"
        }
      ]
    }
  ]
};

async function mount(menuKey) {
  const el = createElement("c-cmn-app-menu-hub", { is: CmnAppMenuHub });
  if (menuKey) {
    el.menuKey = menuKey;
  }
  document.body.appendChild(el);
  await flush();
  return el;
}
const q = (el, s) => el.shadowRoot.querySelector(s);
const qa = (el, s) => el.shadowRoot.querySelectorAll(s);

async function typeSearch(el, value, key) {
  const input = q(el, "[data-id=search-input]");
  input.value = value;
  input.dispatchEvent(new CustomEvent("change"));
  if (key) {
    input.dispatchEvent(new KeyboardEvent("keyup", { key }));
  }
  await flush();
}

describe("c-cmn-app-menu-hub", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  describe("메뉴별 모드(menuKey 지정, AC-7 회귀)", () => {
    it("메뉴 머리글과 타일: 준비 중은 묶음 표시, 사용 가능은 열기 버튼", async () => {
      getMenu.mockResolvedValue(MENU);
      const el = await mount("QMS_03");
      expect(getMenu).toHaveBeenCalledWith({ menuKey: "QMS_03" });
      expect(getHub).not.toHaveBeenCalled();
      expect(q(el, "[data-id=title]").textContent).toContain("Parts");
      expect(qa(el, "[data-id=tile]").length).toBe(3);
      expect(qa(el, "[data-id=planned]").length).toBe(1);
      expect(qa(el, "[data-id=open]").length).toBe(2);
      expect(q(el, "[data-id=search]")).toBeNull();
      expect(q(el, "[data-id=group-title]")).toBeNull();
    });

    it("객체 타일은 목록, 페이지 타일은 앱 페이지를 연다", async () => {
      getMenu.mockResolvedValue(MENU);
      const el = await mount("QMS_03");
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
      let el = await mount("QMS_03");
      expect(q(el, "[data-id=empty]")).not.toBeNull();
      document.body.removeChild(el);
      getMenu.mockRejectedValueOnce({ body: { message: "nope" } });
      el = await mount("QMS_03");
      expect(q(el, "[data-id=error]").textContent).toContain("nope");
      getMenu.mockResolvedValueOnce(MENU);
      q(el, "[data-id=retry]").click();
      await flush();
      expect(qa(el, "[data-id=tile]").length).toBe(3);
    });
  });

  describe("전체 메뉴 모드(menuKey 없음)", () => {
    it("BR-3: 현재 앱의 그룹을 머리글·바로가기·메뉴 열기와 함께 보인다", async () => {
      getHub.mockResolvedValue(HUB);
      const el = await mount();
      expect(getHub).toHaveBeenCalledWith({
        appName: null,
        formFactor: "Large"
      });
      expect(qa(el, "[data-id=group]").length).toBe(2);
      expect(qa(el, "[data-id=group-title]")[1].textContent).toContain(
        "Common Work"
      );
      expect(qa(el, "[data-id=tile]").length).toBe(4);
      expect(qa(el, "[data-id=jump] lightning-button").length).toBe(2);
      qa(el, "[data-id=open-menu]")[1].click();
      expect(mockNavigate).toHaveBeenLastCalledWith({
        type: "standard__navItemPage",
        attributes: { apiName: "CMN_MenuWork" }
      });
    });

    it("AC-3: 미결 배지와 기한 경과 표시(텍스트 포함)", async () => {
      getHub.mockResolvedValue(HUB);
      const el = await mount();
      const pending = qa(el, "[data-id=pending]");
      expect(pending.length).toBe(1);
      expect(pending[0].textContent).toContain("3");
      expect(q(el, "[data-id=overdue]").textContent).toContain("1");
    });

    it("BR-6: 화면 검색은 제목·검색 동의어로 거르고, 맞는 것이 없으면 안내", async () => {
      getHub.mockResolvedValue(HUB);
      const el = await mount();
      await typeSearch(el, "approve");
      expect(qa(el, "[data-id=tile]").length).toBe(1);
      expect(qa(el, "[data-id=group]").length).toBe(1);
      await typeSearch(el, "zzz-nothing");
      expect(q(el, "[data-id=no-match]")).not.toBeNull();
      expect(findRecord).not.toHaveBeenCalled();
    });

    it("AC-4: 업무 번호 + Enter는 레코드를 연다", async () => {
      getHub.mockResolvedValue(HUB);
      findRecord.mockResolvedValue({
        found: true,
        recordId: "a01000000000001AAA",
        objectApiName: "CMN_TestRecord__c"
      });
      const el = await mount();
      await typeSearch(el, "tst-kr01-2026-000001", "Enter");
      expect(findRecord).toHaveBeenCalledWith({
        recordNo: "tst-kr01-2026-000001"
      });
      expect(mockNavigate).toHaveBeenLastCalledWith({
        type: "standard__recordPage",
        attributes: {
          recordId: "a01000000000001AAA",
          objectApiName: "CMN_TestRecord__c",
          actionName: "view"
        }
      });
    });

    it("AC-4: 찾을 수 없으면 같은 안내, 접두어가 아니면 서버를 부르지 않는다", async () => {
      getHub.mockResolvedValue(HUB);
      findRecord.mockResolvedValue({ found: false, message: "not found" });
      const el = await mount();
      await typeSearch(el, "NCR-KR01-2027-999999", "Enter");
      expect(q(el, "[data-id=find-message]").textContent).toContain(
        "not found"
      );
      expect(mockNavigate).not.toHaveBeenCalled();
      findRecord.mockClear();
      await typeSearch(el, "Plants", "Enter");
      expect(findRecord).not.toHaveBeenCalled();
      expect(q(el, "[data-id=find-message]")).toBeNull();
    });

    it("새로 고침은 허브를 다시 읽고, 오류는 다시 시도로 회복", async () => {
      getHub.mockRejectedValueOnce({ body: { message: "down" } });
      const el = await mount();
      expect(q(el, "[data-id=error]").textContent).toContain("down");
      getHub.mockResolvedValueOnce(HUB);
      q(el, "[data-id=retry]").click();
      await flush();
      expect(qa(el, "[data-id=group]").length).toBe(2);
      getHub.mockResolvedValueOnce({ ...HUB, groups: [] });
      q(el, "[data-id=refresh]").click();
      await flush();
      expect(q(el, "[data-id=empty]")).not.toBeNull();
    });
  });
});
