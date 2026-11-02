import { fitWithin, jpegName, MAX_EDGE } from "c/cmnImageResize";

describe("c-cmn-image-resize", () => {
  it("장변을 1920px로 줄이고 비율을 지킨다(AC-1)", () => {
    expect(MAX_EDGE).toBe(1920);
    expect(fitWithin(4032, 3024)).toEqual({ width: 1920, height: 1440 });
    expect(fitWithin(3024, 4032)).toEqual({ width: 1440, height: 1920 });
  });

  it("이미 작으면 그대로", () => {
    expect(fitWithin(800, 600)).toEqual({ width: 800, height: 600 });
    expect(fitWithin(1920, 1080)).toEqual({ width: 1920, height: 1080 });
  });

  it("파일명은 .jpg", () => {
    expect(jpegName("IMG_0001.HEIC")).toBe("IMG_0001.jpg");
    expect(jpegName("")).toBe("photo.jpg");
  });
});
