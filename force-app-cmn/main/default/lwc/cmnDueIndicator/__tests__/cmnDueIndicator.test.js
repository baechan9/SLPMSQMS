import { createElement } from "lwc";
import CmnDueIndicator from "c/cmnDueIndicator";
import { getRecord } from "lightning/uiRecordApi";

jest.mock(
  "@salesforce/label/c.CMN_DueIndicator_Overdue",
  () => ({ default: "Overdue {0}" }),
  { virtual: true }
);
jest.mock(
  "@salesforce/label/c.CMN_DueIndicator_DaysLeft",
  () => ({ default: "{0} left" }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function mount(days) {
  const el = createElement("c-cmn-due-indicator", { is: CmnDueIndicator });
  el.recordId = "a01000000000001AAA";
  el.objectApiName = "CMN_TestRecord__c";
  document.body.appendChild(el);
  getRecord.emit({ fields: { DaysToDue__c: { value: days } } });
  await flush();
  return el;
}
const q = (el, s) => el.shadowRoot.querySelector(s);

describe("c-cmn-due-indicator", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("AC-5: 기한이 어제면 '기한 경과 1일' 문구와 경고 아이콘", async () => {
    const el = await mount(-1);
    expect(q(el, "[data-id=due]").dataset.state).toBe("overdue");
    expect(q(el, "[data-id=due-text]").textContent).toBe("Overdue 1");
    const icon = q(el, "lightning-icon");
    expect(icon.iconName).toBe("utility:warning");
    expect(icon.alternativeText).toBe("Overdue 1");
  });

  it("BR-4: 오늘·3일 이내·그 뒤·기한 없음", async () => {
    let el = await mount(0);
    expect(q(el, "[data-id=due]").dataset.state).toBe("today");
    document.body.removeChild(el);
    el = await mount(2);
    expect(q(el, "[data-id=due]").dataset.state).toBe("soon");
    expect(q(el, "[data-id=due-text]").textContent).toBe("2 left");
    document.body.removeChild(el);
    el = await mount(10);
    expect(q(el, "[data-id=due]").dataset.state).toBe("normal");
    document.body.removeChild(el);
    el = await mount(null);
    expect(q(el, "[data-id=due]").dataset.state).toBe("none");
  });
});
