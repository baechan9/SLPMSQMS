import { createElement } from "lwc";
import CmnLanguageSwitcher from "c/cmnLanguageSwitcher";
import getState from "@salesforce/apex/CMN_LanguageController.getState";
import setLanguage from "@salesforce/apex/CMN_LanguageController.setLanguage";
import followPortal from "@salesforce/apex/CMN_LanguageController.followPortal";

jest.mock(
  "@salesforce/apex/CMN_LanguageController.getState",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_LanguageController.setLanguage",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_LanguageController.followPortal",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// Apex 목 Promise와 재렌더링을 끝낸다(테스트 전용)
// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const STATE = {
  current: "ko",
  overridden: false,
  languages: ["ko", "en_US", "zh_CN", "pl", "es", "pt_BR"]
};

function mount() {
  const el = createElement("c-cmn-language-switcher", {
    is: CmnLanguageSwitcher
  });
  document.body.appendChild(el);
  return el;
}

function group(el) {
  return el.shadowRoot.querySelector("lightning-radio-group");
}

describe("c-cmn-language-switcher", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("언어 6개와 포털 따르기를 보이고, 직접 지정이 아니면 포털 따르기가 선택된다", async () => {
    getState.mockResolvedValue(STATE);
    const el = mount();
    await flush();
    const g = group(el);
    expect(g.options.map((o) => o.value)).toEqual([
      "ko",
      "en_US",
      "zh_CN",
      "pl",
      "es",
      "pt_BR",
      "__portal__"
    ]);
    expect(g.value).toBe("__portal__");
    expect(el.shadowRoot.querySelector("p").textContent).toBe(
      "c.CMN_LanguageSwitcher_Following"
    );
  });

  it("언어를 고르면 저장하고 직접 지정으로 바꾼 뒤 다시 불러온다", async () => {
    getState.mockResolvedValue(STATE);
    setLanguage.mockResolvedValue();
    const original = window.location;
    delete window.location;
    window.location = { reload: jest.fn() };
    try {
      const el = mount();
      await flush();
      group(el).dispatchEvent(
        new CustomEvent("change", { detail: { value: "zh_CN" } })
      );
      await flush();
      expect(setLanguage).toHaveBeenCalledWith({ localeKey: "zh_CN" });
      expect(window.location.reload).toHaveBeenCalled();
      expect(group(el).value).toBe("zh_CN");
      expect(el.shadowRoot.querySelector('p[role="status"]').textContent).toBe(
        "c.CMN_LanguageSwitcher_Saved"
      );
    } finally {
      window.location = original;
    }
  });

  it("포털 따르기를 고르면 직접 지정을 푼다", async () => {
    getState.mockResolvedValue({
      ...STATE,
      current: "zh_CN",
      overridden: true
    });
    followPortal.mockResolvedValue();
    const el = mount();
    await flush();
    expect(group(el).value).toBe("zh_CN");
    group(el).dispatchEvent(
      new CustomEvent("change", { detail: { value: "__portal__" } })
    );
    await flush();
    expect(followPortal).toHaveBeenCalled();
    expect(group(el).value).toBe("__portal__");
  });

  it("저장 실패는 라벨 문구", async () => {
    getState.mockResolvedValue(STATE);
    setLanguage.mockRejectedValue({ body: { message: "internal" } });
    const el = mount();
    await flush();
    group(el).dispatchEvent(
      new CustomEvent("change", { detail: { value: "en_US" } })
    );
    await flush();
    expect(
      el.shadowRoot.querySelector('p[role="alert"]').textContent.trim()
    ).toBe("c.CMN_LanguageSwitcher_Error");
  });

  it("불러오기 실패도 라벨 문구", async () => {
    getState.mockRejectedValue({});
    const el = mount();
    await flush();
    expect(
      el.shadowRoot.querySelector('p[role="alert"]').textContent.trim()
    ).toBe("c.CMN_LanguageSwitcher_Error");
  });
});
