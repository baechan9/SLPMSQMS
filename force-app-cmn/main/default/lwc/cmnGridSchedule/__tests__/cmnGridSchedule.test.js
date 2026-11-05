import { createElement } from "lwc";
import CmnGridSchedule from "c/cmnGridSchedule";

function mount(props) {
  const el = createElement("c-cmn-grid-schedule", { is: CmnGridSchedule });
  Object.assign(el, props);
  document.body.appendChild(el);
  return el;
}

describe("c-cmn-grid-schedule (UX-006 BR-6)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("draws week ticks, today line and one bar per dated row with warning text", () => {
    const el = mount({
      locale: "ko-KR",
      today: "2026-11-06",
      rows: [
        { key: "a", label: "Plan A", start: "2026-11-02", end: "2026-11-13" },
        {
          key: "b",
          label: "Plan B",
          start: "2026-11-04",
          end: "2026-11-05",
          warning: "Overdue"
        },
        { key: "c", label: "No dates", start: null, end: null },
        {
          key: "d",
          label: "Deleted",
          start: "2026-11-01",
          end: "2026-11-02",
          deleted: true
        }
      ]
    });
    const bars = el.shadowRoot.querySelectorAll("span.bar");
    expect(bars).toHaveLength(2);
    expect(bars[0].className).toContain("slds-theme_info");
    expect(bars[1].className).toContain("slds-theme_warning");
    expect(bars[0].style.left).toBe("0%");
    expect(el.shadowRoot.querySelectorAll("span.tick")).toHaveLength(2);
    expect(el.shadowRoot.querySelector("span.today")).not.toBeNull();
    expect(el.shadowRoot.textContent).toContain("Overdue");
    expect(el.shadowRoot.textContent).toContain("CMN_Grid_ScheduleNoDates");
  });

  it("shows the empty message when no row has dates", () => {
    const el = mount({ rows: [{ key: "a", label: "A" }] });
    expect(el.shadowRoot.querySelector("span.bar")).toBeNull();
    expect(el.shadowRoot.textContent).toContain("CMN_Grid_ScheduleEmpty");
  });
});
