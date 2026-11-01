import { createElement } from "lwc";
import CmnCodePicker from "c/cmnCodePicker";
import getCodes from "@salesforce/apex/CMN_CodePickerController.getCodes";

jest.mock(
  "@salesforce/apex/CMN_CodePickerController.getCodes",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// 서버가 비활성 코드를 이미 뺐고 사용자 언어 이름을 골라 준 응답
const DATA = {
  groupCode: "DEFECT_TYPE",
  maxLevel: 3,
  codes: [
    {
      id: "a1",
      parentId: null,
      level: 1,
      label: "Appearance",
      path: "Appearance",
      externalKey: "DEFECT_TYPE/APPEARANCE"
    },
    {
      id: "a2",
      parentId: null,
      level: 1,
      label: "Dimension",
      path: "Dimension",
      externalKey: "DEFECT_TYPE/DIMENSION"
    },
    {
      id: "b1",
      parentId: "a1",
      level: 2,
      label: "Foreign",
      path: "Appearance > Foreign",
      externalKey: "DEFECT_TYPE/APPEARANCE/FOREIGN"
    },
    {
      id: "c1",
      parentId: "b1",
      level: 3,
      label: "Inner",
      path: "Appearance > Foreign > Inner",
      externalKey: "DEFECT_TYPE/APPEARANCE/FOREIGN/INNER"
    }
  ]
};

// Apex 목의 Promise와 재렌더링을 모두 끝낸다(테스트 전용)
// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

function mount(props = {}) {
  const el = createElement("c-cmn-code-picker", { is: CmnCodePicker });
  Object.assign(el, { groupCode: "DEFECT_TYPE", label: "Defect type" }, props);
  document.body.appendChild(el);
  return el;
}

function combos(el) {
  return el.shadowRoot.querySelectorAll("lightning-combobox");
}

function choose(combo, value) {
  combo.dispatchEvent(new CustomEvent("change", { detail: { value } }));
}

describe("c-cmn-code-picker", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("처음에는 1단계만 보이고 서버가 준 표시명을 쓴다", async () => {
    getCodes.mockResolvedValue(DATA);
    const el = mount();
    await flush();
    const c = combos(el);
    expect(getCodes).toHaveBeenCalledWith({ groupCode: "DEFECT_TYPE" });
    expect(c.length).toBe(1);
    expect(c[0].label).toBe("Defect type");
    expect(c[0].options.map((o) => o.label)).toEqual([
      "Appearance",
      "Dimension"
    ]);
  });

  it("상위를 고르면 다음 단계가 열리고 리프에서만 값이 정해진다", async () => {
    getCodes.mockResolvedValue(DATA);
    const el = mount();
    const handler = jest.fn();
    el.addEventListener("change", handler);
    await flush();

    choose(combos(el)[0], "a1");
    await flush();
    expect(combos(el).length).toBe(2);
    expect(handler.mock.calls[0][0].detail.value).toBeNull();

    choose(combos(el)[1], "b1");
    await flush();
    choose(combos(el)[2], "c1");
    await flush();
    const last = handler.mock.calls[2][0].detail;
    expect(last.value).toBe("c1");
    expect(last.path).toBe("Appearance > Foreign > Inner");
    expect(last.externalKey).toBe("DEFECT_TYPE/APPEARANCE/FOREIGN/INNER");
  });

  it("하위가 없는 1단계 코드는 바로 값이 된다", async () => {
    getCodes.mockResolvedValue(DATA);
    const el = mount();
    const handler = jest.fn();
    el.addEventListener("change", handler);
    await flush();
    choose(combos(el)[0], "a2");
    await flush();
    expect(handler.mock.calls[0][0].detail.value).toBe("a2");
    expect(combos(el).length).toBe(1);
  });

  it("maxLevel로 단계를 줄이면 그 단계에서 값이 정해진다", async () => {
    getCodes.mockResolvedValue(DATA);
    const el = mount({ maxLevel: 2 });
    const handler = jest.fn();
    el.addEventListener("change", handler);
    await flush();
    choose(combos(el)[0], "a1");
    await flush();
    choose(combos(el)[1], "b1");
    await flush();
    expect(handler.mock.calls[1][0].detail.value).toBe("b1");
    expect(combos(el).length).toBe(2);
  });

  it("초기 값이 있으면 상위 단계까지 채워 보여 준다", async () => {
    getCodes.mockResolvedValue(DATA);
    const el = mount({ value: "c1" });
    await flush();
    const c = combos(el);
    expect(c.length).toBe(3);
    expect([c[0].value, c[1].value, c[2].value]).toEqual(["a1", "b1", "c1"]);
  });

  it("코드가 없으면 빈 상태 문구", async () => {
    getCodes.mockResolvedValue({ groupCode: "X", maxLevel: 1, codes: [] });
    const el = mount({ groupCode: "X" });
    await flush();
    expect(combos(el).length).toBe(0);
    expect(el.shadowRoot.querySelector("p").textContent).toBe(
      "c.CMN_CodePicker_Empty"
    );
  });

  it("불러오기 실패는 서버 원문 대신 라벨 문구", async () => {
    getCodes.mockRejectedValue({ body: { message: "internal detail" } });
    const el = mount();
    await flush();
    const p = el.shadowRoot.querySelector("p");
    expect(p.textContent).toBe("c.CMN_CodePicker_LoadError");
    expect(p.getAttribute("role")).toBe("alert");
  });

  it("불러오는 동안 스피너", async () => {
    getCodes.mockReturnValue(new Promise(() => {}));
    const el = mount();
    await Promise.resolve();
    expect(el.shadowRoot.querySelector("lightning-spinner")).not.toBeNull();
  });
});
