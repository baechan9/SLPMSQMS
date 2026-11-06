import { createElement } from "lwc";
import CmnAiRecommendationList from "c/cmnAiRecommendationList";
import getRecommendations from "@salesforce/apex/CMN_AiRecommendationController.getRecommendations";
import decide from "@salesforce/apex/CMN_AiRecommendationController.decide";
import CmnAiExcludeDialog from "c/cmnAiExcludeDialog";
import { publish } from "lightning/messageService";
import { registerRefreshHandler } from "lightning/refresh";
import VIEW from "./data/view.json";

jest.mock(
  "@salesforce/apex/CMN_AiRecommendationController.getRecommendations",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_AiRecommendationController.decide",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("c/cmnAiExcludeDialog", () => ({
  __esModule: true,
  default: { open: jest.fn() }
}));
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
// 배포되지 않은 UseCase 렌더러(불러오기 실패 → 기본 카드 내용)
jest.mock(
  "c/qmsBrokenRenderer",
  () => {
    throw new Error("not deployed");
  },
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const RECORD_ID = "a01000000000009AAA";

function view() {
  return JSON.parse(JSON.stringify(VIEW));
}

async function mount(props = {}) {
  const el = createElement("c-cmn-ai-recommendation-list", {
    is: CmnAiRecommendationList
  });
  el.recordId = RECORD_ID;
  Object.assign(el, props);
  const badges = [];
  el.addEventListener("railbadge", (e) => badges.push(e.detail));
  el.badges = badges;
  document.body.appendChild(el);
  await flush();
  await flush();
  return el;
}

const all = (el, sel) => el.shadowRoot.querySelectorAll(sel);
const one = (el, sel) => el.shadowRoot.querySelector(sel);

describe("c-cmn-ai-recommendation-list (AI-004 BR-3)", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("rail variant shows 3 cards, more on demand, and reports open proposals", async () => {
    getRecommendations.mockResolvedValue(view());
    const el = await mount({ variant: "rail" });
    expect(getRecommendations).toHaveBeenCalledWith({
      recordId: RECORD_ID,
      useCase: null
    });
    expect(all(el, "li.card")).toHaveLength(3);
    expect(el.badges[el.badges.length - 1]).toEqual({
      count: 3,
      severity: "info"
    });
    one(el, "lightning-button.more").click();
    await flush();
    expect(all(el, "li.card")).toHaveLength(5);
    expect(one(el, "lightning-button.more").label).toBe("c.CMN_AiRec_ShowLess");
  });

  it("default variant shows everything with status, hit and decision info", async () => {
    getRecommendations.mockResolvedValue(view());
    const el = await mount({ config: '{"useCase":"QMS_RCA"}' });
    expect(getRecommendations).toHaveBeenLastCalledWith({
      recordId: RECORD_ID,
      useCase: "QMS_RCA"
    });
    const cards = all(el, "li.card");
    expect(cards).toHaveLength(5);
    expect(one(el, "lightning-button.more")).toBeNull();
    const last = cards[4];
    expect(last.querySelector("[data-id=status]").textContent).toBe("Excluded");
    expect(last.querySelector(".hit").textContent).toBe("c.CMN_AiRec_Miss");
    expect(last.querySelector(".exclude-reason").textContent).toBe(
      "Not relevant"
    );
    // 결정할 수 없는 추천에는 버튼이 없다
    expect(last.querySelector("lightning-button-group.actions")).toBeNull();
    // 이미 채택한 추천은 채택 버튼이 눌린 상태(비활성)
    const adoptedBtn = cards[3].querySelector("lightning-button.adopt");
    expect(adoptedBtn.disabled).toBe(true);
    expect(adoptedBtn.variant).toBe("brand");
    // 기본 카드 내용: 문장·이름-값
    expect(cards[0].querySelector("p.text").textContent).toBe("Seal issue 1");
    expect(cards[0].querySelector("dd").textContent.trim()).toBe("C1");
    expect(one(el, "p.notice").textContent).toContain("c.CMN_AiRec_Notice");
  });

  it("adopting records the decision and announces it without writing fields", async () => {
    getRecommendations.mockResolvedValue(view());
    const updated = {
      ...view().items[1],
      status: "ADOPTED",
      statusLabel: "Adopted",
      decidedBy: "Me"
    };
    decide.mockResolvedValue(updated);
    const el = await mount();
    const decided = jest.fn();
    const toast = jest.fn();
    el.addEventListener("recommendationdecided", decided);
    el.addEventListener("lightning__showtoast", toast);
    all(el, "li.card")[1].querySelector("lightning-button.adopt").click();
    await flush();
    expect(decide).toHaveBeenCalledWith({
      recommendationId: updated.id,
      status: "ADOPTED",
      reasonCode: null
    });
    expect(decided.mock.calls[0][0].detail).toEqual({
      recordId: RECORD_ID,
      recommendationId: updated.id,
      useCase: "QMS_RCA",
      status: "ADOPTED",
      rank: 2,
      contentJson: updated.contentJson
    });
    expect(publish).toHaveBeenCalledTimes(1);
    expect(publish.mock.calls[0][2].status).toBe("ADOPTED");
    expect(toast.mock.calls[0][0].detail.variant).toBe("success");
    expect(
      all(el, "li.card")[1].querySelector("[data-id=status]").textContent
    ).toBe("Adopted");
    expect(el.badges[el.badges.length - 1].count).toBe(2);
  });

  it("modify marks the card as adopted with changes", async () => {
    getRecommendations.mockResolvedValue(view());
    decide.mockResolvedValue({
      ...view().items[0],
      status: "MODIFIED",
      statusLabel: "Modified"
    });
    const el = await mount();
    all(el, "li.card")[0].querySelector("lightning-button.modify").click();
    await flush();
    expect(decide.mock.calls[0][0].status).toBe("MODIFIED");
    const btn = all(el, "li.card")[0].querySelector("lightning-button.modify");
    expect(btn.disabled).toBe(true);
  });

  it("AC-2: excluding needs a reason from the dialog; cancel changes nothing", async () => {
    getRecommendations.mockResolvedValue(view());
    const el = await mount();
    CmnAiExcludeDialog.open.mockResolvedValueOnce(undefined);
    all(el, "li.card")[0].querySelector("lightning-button.exclude").click();
    await flush();
    expect(CmnAiExcludeDialog.open.mock.calls[0][0].recommendationTitle).toBe(
      "Cause 1"
    );
    expect(decide).not.toHaveBeenCalled();

    CmnAiExcludeDialog.open.mockResolvedValueOnce({
      reasonId: "a0C000000000001AAA"
    });
    decide.mockResolvedValue({
      ...view().items[0],
      status: "EXCLUDED",
      statusLabel: "Excluded",
      excludeReason: "Not relevant",
      decidedBy: "Me"
    });
    all(el, "li.card")[0].querySelector("lightning-button.exclude").click();
    await flush();
    await flush();
    expect(decide).toHaveBeenCalledWith({
      recommendationId: view().items[0].id,
      status: "EXCLUDED",
      reasonCode: "a0C000000000001AAA"
    });
    expect(
      all(el, "li.card")[0].querySelector(".exclude-reason").textContent
    ).toBe("Not relevant");
  });

  it("shows the server message when a decision is refused", async () => {
    getRecommendations.mockResolvedValue(view());
    decide.mockRejectedValue({ body: { message: "No access" } });
    const el = await mount();
    const toast = jest.fn();
    el.addEventListener("lightning__showtoast", toast);
    all(el, "li.card")[0].querySelector("lightning-button.adopt").click();
    await flush();
    expect(toast.mock.calls[0][0].detail).toMatchObject({
      message: "No access",
      variant: "error"
    });
    expect(publish).not.toHaveBeenCalled();
    expect(
      all(el, "li.card")[0].querySelector("lightning-button.adopt").disabled
    ).toBe(false);
  });

  it("rationale toggles and source links open the record", async () => {
    getRecommendations.mockResolvedValue(view());
    const el = await mount();
    const card = () => all(el, "li.card")[0];
    expect(card().querySelector("p.rationale")).toBeNull();
    card().querySelector("button[aria-expanded]").click();
    await flush();
    expect(card().querySelector("p.rationale").textContent).toContain(
      "Because 1"
    );
    expect(
      card()
        .querySelector("button[aria-expanded]")
        .getAttribute("aria-expanded")
    ).toBe("true");
    card().querySelector("lightning-button.ref").click();
    expect(mockNavigate.mock.calls[0][0].attributes.recordId).toBe(
      "a01000000000001AAA"
    );
  });

  it("shows empty and error states", async () => {
    getRecommendations.mockResolvedValue({ items: [], proposedCount: 0 });
    const empty = await mount({ variant: "rail" });
    expect(one(empty, "[data-id=empty]").textContent).toBe("c.CMN_AiRec_Empty");
    expect(empty.badges[0].count).toBe(0);

    getRecommendations.mockRejectedValue({ body: { message: "Bad input" } });
    const failed = await mount();
    expect(one(failed, "[data-id=error]").textContent.trim()).toBe("Bad input");
  });

  it("reloads on a page refresh and falls back when the renderer is missing", async () => {
    getRecommendations.mockResolvedValue(view());
    const el = await mount({
      useCase: "QMS_CAPA",
      config: { renderer: "c/qmsBrokenRenderer" }
    });
    expect(getRecommendations).toHaveBeenLastCalledWith({
      recordId: RECORD_ID,
      useCase: "QMS_CAPA"
    });
    expect(one(el, "[data-id=renderer]")).toBeNull();
    expect(all(el, "p.text")).toHaveLength(5);
    const handler = registerRefreshHandler.mock.calls.at(-1)[1];
    const callsBefore = getRecommendations.mock.calls.length;
    const ok = await handler.call(el);
    expect(ok).toBe(true);
    expect(getRecommendations.mock.calls.length).toBe(callsBefore + 1);
  });
});
