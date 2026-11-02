import { createElement } from "lwc";
import CmnBarcodeScanner from "c/cmnBarcodeScanner";
import { getBarcodeScanner } from "lightning/mobileCapabilities";

jest.mock(
  "lightning/mobileCapabilities",
  () => ({ getBarcodeScanner: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

function scanner(available, capture) {
  return {
    isAvailable: () => available,
    barcodeTypes: { QR: "qr", CODE_128: "code128" },
    beginCapture: capture,
    endCapture: jest.fn()
  };
}

function mount() {
  const el = createElement("c-cmn-barcode-scanner", { is: CmnBarcodeScanner });
  document.body.appendChild(el);
  return el;
}

describe("c-cmn-barcode-scanner", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("모바일 앱: 스캔 결과를 scan 이벤트로", async () => {
    const s = scanner(
      true,
      jest.fn().mockResolvedValue({ value: "LOT-1", type: "qr" })
    );
    getBarcodeScanner.mockReturnValue(s);
    const el = mount();
    const handler = jest.fn();
    el.addEventListener("scan", handler);
    await flush();
    el.shadowRoot.querySelector("[data-id=scan]").click();
    await flush();
    expect(s.beginCapture.mock.calls[0][0].barcodeTypes).toEqual([
      "qr",
      "code128"
    ]);
    expect(handler.mock.calls[0][0].detail).toEqual({
      value: "LOT-1",
      type: "qr"
    });
    expect(s.endCapture).toHaveBeenCalled();
  });

  it("스캔 실패는 안내, 취소는 조용히", async () => {
    const s = scanner(
      true,
      jest.fn().mockRejectedValue({ code: "USER_DISMISSED" })
    );
    getBarcodeScanner.mockReturnValue(s);
    const el = mount();
    await flush();
    el.shadowRoot.querySelector("[data-id=scan]").click();
    await flush();
    expect(el.shadowRoot.querySelector("p[role=alert]")).toBeNull();
    s.beginCapture.mockRejectedValue({ code: "SERVICE_NOT_ENABLED" });
    el.shadowRoot.querySelector("[data-id=scan]").click();
    await flush();
    expect(el.shadowRoot.querySelector("p[role=alert]")).not.toBeNull();
  });

  it("웹: 수동 입력(사원증 사번 등)을 엔터로 보낸다", async () => {
    getBarcodeScanner.mockReturnValue(scanner(false));
    const el = mount();
    const handler = jest.fn();
    el.addEventListener("scan", handler);
    await flush();
    const input = el.shadowRoot.querySelector("[data-id=manual]");
    input.dispatchEvent(
      new CustomEvent("change", { detail: { value: " E1101 " } })
    );
    input.dispatchEvent(new KeyboardEvent("keyup", { key: "Enter" }));
    expect(handler.mock.calls[0][0].detail).toEqual({
      value: "E1101",
      type: "MANUAL"
    });
  });
});
