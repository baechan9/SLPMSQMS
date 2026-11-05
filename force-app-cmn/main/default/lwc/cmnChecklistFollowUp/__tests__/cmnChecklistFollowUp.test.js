import { createElement } from "lwc";
import CmnChecklistFollowUp from "c/cmnChecklistFollowUp";

describe("c-cmn-checklist-follow-up (UX-009 BR-5)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  function mount() {
    const el = createElement("c-cmn-checklist-follow-up", {
      is: CmnChecklistFollowUp
    });
    el.questionText = "1.1 Work standards posted?";
    document.body.appendChild(el);
    return el;
  }

  function change(el, cls, detail) {
    el.shadowRoot
      .querySelector(cls)
      .dispatchEvent(new CustomEvent("change", { detail }));
  }

  it("requires a title and due date, then returns the input", async () => {
    const el = mount();
    const closed = jest.fn();
    el.addEventListener("close", closed);
    el.shadowRoot.querySelector("lightning-button.fu-create").click();
    await Promise.resolve();
    expect(closed).not.toHaveBeenCalled();
    expect(el.shadowRoot.querySelector("p.fu-error").textContent).toBe(
      "c.CMN_Checklist_FollowUpTitleRequired"
    );
    change(el, "lightning-input.fu-title", { value: "  Post standard " });
    change(el, "lightning-textarea.fu-description", { value: "Line 2" });
    change(el, "lightning-record-picker.fu-owner", {
      recordId: "005000000000001AAA"
    });
    change(el, "lightning-input.fu-due", { value: "2026-11-13" });
    change(el, "lightning-combobox.fu-severity", { value: "HIGH" });
    el.shadowRoot.querySelector("lightning-button.fu-create").click();
    expect(closed.mock.calls[0][0].detail).toEqual({
      title: "Post standard",
      description: "Line 2",
      ownerId: "005000000000001AAA",
      dueDate: "2026-11-13",
      severity: "HIGH"
    });
    expect(el.shadowRoot.querySelector("p.question").textContent).toContain(
      "1.1"
    );
  });

  it("cancels with null", () => {
    const el = mount();
    const closed = jest.fn();
    el.addEventListener("close", closed);
    el.shadowRoot.querySelector("lightning-button.fu-cancel").click();
    expect(closed.mock.calls[0][0].detail).toBeNull();
  });
});
