import { createElement } from "lwc";
import CmnPrototypeBadge from "c/cmnPrototypeBadge";

describe("c-cmn-prototype-badge (A0 prototype kit)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("shows the sample-data badge only for mock responses", async () => {
    const el = createElement("c-cmn-prototype-badge", {
      is: CmnPrototypeBadge
    });
    document.body.appendChild(el);
    expect(el.shadowRoot.querySelector(".slds-badge")).toBeNull();
    el.show = true;
    await Promise.resolve();
    expect(el.shadowRoot.querySelector(".slds-badge").textContent).toContain(
      "c.CMN_Prototype_MockBadge"
    );
  });
});
