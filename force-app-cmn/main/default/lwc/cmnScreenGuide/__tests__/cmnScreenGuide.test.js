import { createElement } from "lwc";
import CmnScreenGuide from "c/cmnScreenGuide";
import getGuide from "@salesforce/apex/CMN_ScreenGuideController.getGuide";
import { CurrentPageReference } from "lightning/navigation";

jest.mock(
  "@salesforce/apex/CMN_ScreenGuideController.getGuide",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const FOUND = {
  pageKey: "QMS_NCR__c.RECORD",
  found: true,
  title: "NCR record",
  content: "<p>Step 1</p>",
  language: "en_US",
  isFallback: true,
  videoUrl: "https://video.example.com/ncr",
  standardDocUrl: "https://std.example.com/ncr",
  updatedAt: "2026-11-06T00:00:00.000Z"
};

function mount() {
  const el = createElement("c-cmn-screen-guide", { is: CmnScreenGuide });
  document.body.appendChild(el);
  return el;
}
const q = (el, sel) => el.shadowRoot.querySelector(sel);

async function navigate(ref) {
  CurrentPageReference.emit(ref);
  await flush();
  await flush();
}

describe("c-cmn-screen-guide (UX-002)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("AC-1·AC-2: record page guide with fallback notice and links", async () => {
    getGuide.mockResolvedValue(FOUND);
    const el = mount();
    await navigate({
      type: "standard__recordPage",
      attributes: {
        recordId: "a01000000000001AAA",
        objectApiName: "QMS_NCR__c",
        actionName: "view"
      }
    });
    expect(getGuide).toHaveBeenLastCalledWith({
      pageKey: "QMS_NCR__c.RECORD",
      recordId: null
    });
    expect(q(el, "h2.guide-title").textContent.trim()).toBe("NCR record");
    expect(q(el, "[data-id=fallback]")).not.toBeNull();
    expect(q(el, "lightning-formatted-rich-text.content").value).toBe(
      "<p>Step 1</p>"
    );
    expect(q(el, "[data-id=video]").href).toBe("https://video.example.com/ncr");
    expect(q(el, "[data-id=standard-doc]")).not.toBeNull();
    expect(q(el, "[data-id=page-key]").textContent).toContain(
      "c.CMN_Guide_PageKey"
    );
  });

  it("derives the page key from each page type", async () => {
    getGuide.mockResolvedValue({ pageKey: "X", found: false });
    mount();
    await navigate({
      type: "standard__recordPage",
      attributes: { recordId: "a01000000000002AAA", actionName: "view" }
    });
    expect(getGuide).toHaveBeenLastCalledWith({
      pageKey: null,
      recordId: "a01000000000002AAA"
    });
    await navigate({
      type: "standard__objectPage",
      attributes: { objectApiName: "CMN_Item__c", actionName: "list" }
    });
    expect(getGuide).toHaveBeenLastCalledWith({
      pageKey: "CMN_Item__c.LIST",
      recordId: null
    });
    await navigate({
      type: "standard__navItemPage",
      attributes: { apiName: "CMN_UnifiedSearch" }
    });
    expect(getGuide).toHaveBeenLastCalledWith({
      pageKey: "CMN_UnifiedSearch",
      recordId: null
    });
    await navigate({
      type: "standard__namedPage",
      attributes: { pageName: "home" }
    });
    expect(getGuide).toHaveBeenLastCalledWith({
      pageKey: "home",
      recordId: null
    });
  });

  it("shows no-guide, unsupported and error states", async () => {
    getGuide.mockResolvedValue({ pageKey: "CMN_Item__c.LIST", found: false });
    const el = mount();
    await navigate({
      type: "standard__objectPage",
      attributes: { objectApiName: "CMN_Item__c" }
    });
    expect(q(el, "[data-id=no-guide]")).not.toBeNull();

    await navigate({ type: "standard__webPage", attributes: {} });
    expect(q(el, "[data-id=unsupported]")).not.toBeNull();
    expect(q(el, "[data-id=page-key]")).toBeNull();

    getGuide.mockRejectedValue({ body: { message: "Bad key" } });
    await navigate({
      type: "standard__navItemPage",
      attributes: { apiName: "bad" }
    });
    expect(q(el, "[data-id=error]").textContent.trim()).toBe("Bad key");
  });
});
