import { createElement } from "lwc";
import CmnAiExcludeDialog from "c/cmnAiExcludeDialog";
import getCodes from "@salesforce/apex/CMN_CodePickerController.getCodes";

jest.mock(
  "@salesforce/apex/CMN_CodePickerController.getCodes",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("c-cmn-ai-exclude-dialog (AI-004 AC-2)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  async function mount() {
    getCodes.mockResolvedValue({
      maxLevel: 1,
      codes: [
        {
          id: "a0C000000000001AAA",
          label: "Not relevant",
          level: 1,
          parentId: null,
          path: "Not relevant",
          externalKey: "AI_EXCLUDE_REASON/NOT_RELEVANT"
        }
      ]
    });
    const el = createElement("c-cmn-ai-exclude-dialog", {
      is: CmnAiExcludeDialog
    });
    el.recommendationTitle = "Cause 1";
    document.body.appendChild(el);
    await flush();
    return el;
  }

  it("requires a reason before closing with it", async () => {
    const el = await mount();
    expect(getCodes).toHaveBeenCalledWith({ groupCode: "AI_EXCLUDE_REASON" });
    expect(el.shadowRoot.querySelector("p.target").textContent).toContain(
      "Cause 1"
    );
    const closed = jest.fn();
    el.addEventListener("close", closed);
    el.shadowRoot.querySelector("lightning-button.confirm").click();
    await flush();
    expect(closed).not.toHaveBeenCalled();
    expect(
      el.shadowRoot.querySelector("p[role=alert]").textContent.trim()
    ).toBe("c.CMN_AiRec_ReasonRequired");

    el.shadowRoot.querySelector("c-cmn-code-picker.reason").dispatchEvent(
      new CustomEvent("change", {
        detail: { value: "a0C000000000001AAA", path: "Not relevant" }
      })
    );
    await flush();
    expect(el.shadowRoot.querySelector("p[role=alert]")).toBeNull();
    el.shadowRoot.querySelector("lightning-button.confirm").click();
    expect(closed.mock.calls[0][0].detail).toEqual({
      reasonId: "a0C000000000001AAA"
    });
  });

  it("cancel closes without a result", async () => {
    const el = await mount();
    const closed = jest.fn();
    el.addEventListener("close", closed);
    el.shadowRoot.querySelector("lightning-button.cancel").click();
    expect(closed.mock.calls[0][0].detail).toBeFalsy();
  });
});
