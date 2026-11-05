/**
 * 현장 입력 즉시 합불 미리보기(CMN-00-UX-008 BR-2). 서버 공용 규격 비교(CMN_FieldEntry.judgeValue·judgeItem)와 같은 규칙이다.
 * 규격 비교만 한다. 업무 판정·확정은 서버 Provider가 한다(셸에 판정 규칙을 두지 않는다).
 */
export const PASS = "PASS";
export const FAIL = "FAIL";
export const INCOMPLETE = "INCOMPLETE";
const OK_WORDS = new Set(["ok", "o", "pass", "y", "1", "✓"]);
const NG_WORDS = new Set(["ng", "x", "fail", "n", "0"]);

/**
 * 반올림(HALF_UP, 0에서 먼 쪽). 부동소수 오차를 피하려고 아주 작은 값을 더한다.
 * @param {number} value 값
 * @param {number} decimals 소수 자리(비우면 그대로)
 * @returns {number} 반올림 값
 */
export function roundHalfUp(value, decimals) {
  if (decimals === null || decimals === undefined) {
    return value;
  }
  const f = 10 ** decimals;
  return (Math.sign(value) * Math.round(Math.abs(value) * f + 1e-9)) / f;
}

/**
 * 시료 값 하나.
 * @param {object} item 항목(type, lsl, usl, decimals)
 * @param {object} value 값(numValue, okNg, text)
 * @returns {string} PASS, FAIL, INCOMPLETE
 */
export function judgeValue(item, value) {
  if (!value) {
    return INCOMPLETE;
  }
  if (item.type === "VARIABLE") {
    const n = value.numValue;
    if (n === null || n === undefined || n === "" || Number.isNaN(Number(n))) {
      return INCOMPLETE;
    }
    const x = roundHalfUp(Number(n), item.decimals);
    const low = item.lsl !== null && item.lsl !== undefined && x < item.lsl;
    const high = item.usl !== null && item.usl !== undefined && x > item.usl;
    return low || high ? FAIL : PASS;
  }
  if (item.type === "TEXT") {
    return value.text && String(value.text).trim() ? PASS : INCOMPLETE;
  }
  if (value.okNg !== "OK" && value.okNg !== "NG") {
    return INCOMPLETE;
  }
  return value.okNg === "NG" ? FAIL : PASS;
}

/**
 * 항목 판정: 하나라도 불합격이면 불합격, 빈 시료가 있으면 입력 중, 모두 합격이면 합격.
 * @param {object} item 항목(sampleQty)
 * @param {function} valueOf (sampleNo) => 값
 * @returns {string} PASS, FAIL, INCOMPLETE
 */
export function judgeItem(item, valueOf) {
  let missing = false;
  for (let n = 1; n <= (item.sampleQty || 1); n++) {
    const r = judgeValue(item, valueOf(n));
    if (r === FAIL) {
      return FAIL;
    }
    missing = missing || r === INCOMPLETE;
  }
  return missing ? INCOMPLETE : PASS;
}

/**
 * 붙여넣은 낱말 → OK/NG. 모르는 값은 null.
 * @param {string} text 값
 * @returns {string|null} OK, NG, null
 */
export function okNgOf(text) {
  const w = String(text ?? "")
    .trim()
    .toLowerCase();
  if (OK_WORDS.has(w)) {
    return "OK";
  }
  return NG_WORDS.has(w) ? "NG" : null;
}
