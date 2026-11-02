import { createElement } from "lwc";
import CmnPhotoCapture from "c/cmnPhotoCapture";
import uploadPhotos from "@salesforce/apex/CMN_PhotoController.uploadPhotos";
import { resizeImage } from "c/cmnImageResize";

jest.mock(
  "@salesforce/apex/CMN_PhotoController.uploadPhotos",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("c/cmnImageResize", () => ({
  resizeImage: jest.fn((file) =>
    Promise.resolve({
      fileName: file.name + ".jpg",
      base64: "AAA",
      width: 1920,
      height: 1440
    })
  )
}));

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

function mount() {
  const el = createElement("c-cmn-photo-capture", { is: CmnPhotoCapture });
  el.recordId = "a01000000000001AAA";
  document.body.appendChild(el);
  return el;
}

function choose(el, count) {
  const input = el.shadowRoot.querySelector("[data-id=input]");
  const files = Array.from({ length: count }, (_, i) => ({ name: `p${i}` }));
  Object.defineProperty(input, "files", { value: files, configurable: true });
  input.dispatchEvent(new CustomEvent("change"));
}

describe("c-cmn-photo-capture", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("카메라 입력(capture)과 사진 3장 축소 후 업로드(AC-1)", async () => {
    const el = mount();
    const input = el.shadowRoot.querySelector("[data-id=input]");
    expect(input.getAttribute("capture")).toBe("environment");
    expect(input.getAttribute("accept")).toBe("image/*");
    uploadPhotos.mockResolvedValue([{}, {}, {}]);
    const handler = jest.fn();
    el.addEventListener("uploaded", handler);
    choose(el, 3);
    await flush();
    expect(resizeImage).toHaveBeenCalledTimes(3);
    expect(uploadPhotos).toHaveBeenCalledWith({
      parentId: "a01000000000001AAA",
      docClassCode: "NCR_PHOTO",
      photos: [
        { fileName: "p0.jpg", base64: "AAA" },
        { fileName: "p1.jpg", base64: "AAA" },
        { fileName: "p2.jpg", base64: "AAA" }
      ]
    });
    expect(handler.mock.calls[0][0].detail.count).toBe(3);
  });

  it("11장은 거절, 서버 오류는 토스트", async () => {
    const el = mount();
    const toast = jest.fn();
    el.addEventListener("lightning__showtoast", toast);
    choose(el, 11);
    await flush();
    expect(uploadPhotos).not.toHaveBeenCalled();
    uploadPhotos.mockRejectedValue({ body: { message: "no access" } });
    choose(el, 1);
    await flush();
    expect(toast.mock.calls[1][0].detail.message).toBe("no access");
  });
});
