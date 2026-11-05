import {
  roundHalfUp,
  judgeValue,
  judgeItem,
  okNgOf,
  PASS,
  FAIL,
  INCOMPLETE
} from "c/cmnFieldEntryJudge";

const VAR = { type: "VARIABLE", lsl: 1.0, usl: 2.0, decimals: 2, sampleQty: 3 };

describe("c-cmn-field-entry-judge (UX-008 BR-2)", () => {
  it("AC-1: rounds half up before comparing with inclusive specs", () => {
    expect(judgeValue(VAR, { numValue: 2.05 })).toBe(FAIL);
    expect(judgeValue(VAR, { numValue: 2.004 })).toBe(PASS);
    expect(judgeValue(VAR, { numValue: 0.995 })).toBe(PASS);
    expect(judgeValue(VAR, { numValue: 0.994 })).toBe(FAIL);
    expect(roundHalfUp(2.005, 2)).toBe(2.01);
    expect(roundHalfUp(-1.005, 2)).toBe(-1.01);
    expect(roundHalfUp(1.23456)).toBe(1.23456);
  });

  it("checks one-sided specs, attributes and text", () => {
    expect(judgeValue({ type: "VARIABLE", lsl: 10 }, { numValue: 99 })).toBe(
      PASS
    );
    expect(judgeValue({ type: "VARIABLE", usl: 10 }, { numValue: 10.01 })).toBe(
      FAIL
    );
    expect(judgeValue({ type: "VARIABLE" }, { numValue: "" })).toBe(INCOMPLETE);
    expect(judgeValue({ type: "ATTRIBUTE" }, { okNg: "NG" })).toBe(FAIL);
    expect(judgeValue({ type: "VISUAL" }, { okNg: "OK" })).toBe(PASS);
    expect(judgeValue({ type: "REPORT" }, {})).toBe(INCOMPLETE);
    expect(judgeValue({ type: "TEXT" }, { text: " " })).toBe(INCOMPLETE);
    expect(judgeValue({ type: "TEXT" }, { text: "fine" })).toBe(PASS);
    expect(judgeValue(VAR, undefined)).toBe(INCOMPLETE);
  });

  it("judges an item from its samples", () => {
    const values = {
      1: { numValue: 1.5 },
      2: { numValue: 1.6 },
      3: { numValue: 1.7 }
    };
    expect(judgeItem(VAR, (n) => values[n])).toBe(PASS);
    expect(judgeItem(VAR, (n) => (n === 3 ? undefined : values[n]))).toBe(
      INCOMPLETE
    );
    expect(judgeItem(VAR, (n) => (n === 2 ? { numValue: 3 } : undefined))).toBe(
      FAIL
    );
  });

  it("reads OK/NG words", () => {
    expect(okNgOf(" OK ")).toBe("OK");
    expect(okNgOf("x")).toBe("NG");
    expect(okNgOf("maybe")).toBeNull();
  });
});
