/**
 * 엑셀 붙여넣기 해석(CMN-00-UX-006 BR-3). 화면 없는 순수 함수 모듈이라 붙여넣기 대화상자와 Jest가 함께 쓴다.
 * - 클립보드 텍스트(탭 구분, 셀 안 줄바꿈은 큰따옴표로 감싼 형식)를 행·열로 나눈다.
 * - 시작 열부터 그리드 열 순서대로 맞추고, 열 타입별로 값을 바꾼다. 바꿀 수 없으면 값은 비우고 오류 코드를 단다.
 *   날짜: yyyy-mm-dd, yyyy.mm.dd, yyyy/mm/dd, 사용자 로캘 순서 / 숫자: 로캘 천 단위 구분 기호 제거 /
 *   선택 목록: API 값 또는 사용자 언어 라벨 / 참조·코드: 서버 확인 결과(이름·외부 키) / 체크박스: 참·거짓 낱말.
 */
export const ERR_DATE = "DATE";
export const ERR_NUMBER = "NUMBER";
export const ERR_PICKLIST = "PICKLIST";
export const ERR_LOOKUP = "LOOKUP";
export const ERR_CHECKBOX = "CHECKBOX";
export const ERR_LENGTH = "LENGTH";

const TRUE_WORDS = new Set(["true", "y", "yes", "1", "o", "v", "\u2713"]);
const FALSE_WORDS = new Set(["false", "n", "no", "0", "x", "-"]);
const REFERENCE_TYPES = new Set(["LOOKUP", "CODE"]);

/**
 * 클립보드 텍스트 → 행 배열(셀 문자열 배열). 끝의 빈 줄은 버린다.
 * @param {string} text 붙여넣은 텍스트
 * @returns {string[][]} 행
 */
export function parseClipboard(text) {
  const rows = [];
  if (!text) {
    return rows;
  }
  let row = [];
  let cell = "";
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (quoted) {
      if (ch === '"' && text[i + 1] === '"') {
        cell += '"';
        i++;
      } else if (ch === '"') {
        quoted = false;
      } else {
        cell += ch;
      }
    } else if (ch === '"' && cell === "") {
      quoted = true;
    } else if (ch === "\t") {
      row.push(cell);
      cell = "";
    } else if (ch === "\n" || ch === "\r") {
      if (ch === "\r" && text[i + 1] === "\n") {
        i++;
      }
      row.push(cell);
      rows.push(row);
      row = [];
      cell = "";
    } else {
      cell += ch;
    }
  }
  if (cell !== "" || row.length) {
    row.push(cell);
    rows.push(row);
  }
  while (rows.length && rows[rows.length - 1].every((c) => c.trim() === "")) {
    rows.pop();
  }
  return rows;
}

/**
 * 로캘의 천 단위·소수점 기호.
 * @param {string} locale 예: ko-KR
 * @returns {{group: string, decimal: string}} 기호
 */
export function numberSymbols(locale) {
  try {
    const parts = new Intl.NumberFormat(locale).formatToParts(12345.6);
    return {
      group: parts.find((p) => p.type === "group")?.value ?? ",",
      decimal: parts.find((p) => p.type === "decimal")?.value ?? "."
    };
  } catch {
    return { group: ",", decimal: "." };
  }
}

/**
 * 로캘의 날짜 부분 순서(예: en-US → month, day, year).
 * @param {string} locale 로캘
 * @returns {string[]} year·month·day 순서
 */
export function dateOrder(locale) {
  try {
    const order = new Intl.DateTimeFormat(locale, {
      year: "numeric",
      month: "2-digit",
      day: "2-digit"
    })
      .formatToParts(new Date(2026, 10, 26))
      .map((p) => p.type)
      .filter((t) => t === "year" || t === "month" || t === "day");
    return order.length === 3 ? order : ["year", "month", "day"];
  } catch {
    return ["year", "month", "day"];
  }
}

function pad(n) {
  return String(n).padStart(2, "0");
}

function isoDate(y, m, d) {
  const date = new Date(Date.UTC(y, m - 1, d));
  if (
    date.getUTCFullYear() !== y ||
    date.getUTCMonth() !== m - 1 ||
    date.getUTCDate() !== d
  ) {
    return null;
  }
  return `${y}-${pad(m)}-${pad(d)}`;
}

/**
 * 날짜 문자열 → yyyy-mm-dd. 해석할 수 없으면 null.
 * @param {string} raw 값
 * @param {string} locale 로캘
 * @returns {string|null} ISO 날짜
 */
export function parseDate(raw, locale) {
  const s = String(raw ?? "").trim();
  const ymd = s.match(/^(\d{4})\s*[-./]\s*(\d{1,2})\s*[-./]\s*(\d{1,2})\.?$/);
  if (ymd) {
    return isoDate(Number(ymd[1]), Number(ymd[2]), Number(ymd[3]));
  }
  const parts = s.split(/\D+/).filter(Boolean);
  if (parts.length !== 3 || /[^\d\s./-]/.test(s)) {
    return null;
  }
  const order = dateOrder(locale);
  const value = {};
  order.forEach((type, i) => {
    value[type] = Number(parts[i]);
  });
  if (String(parts[order.indexOf("year")]).length === 2) {
    value.year += 2000;
  }
  return isoDate(value.year, value.month, value.day);
}

/**
 * 숫자 문자열 → 숫자. 해석할 수 없으면 null.
 * @param {string} raw 값
 * @param {string} locale 로캘
 * @returns {number|null} 숫자
 */
export function parseNumber(raw, locale) {
  const { group, decimal } = numberSymbols(locale);
  let s = String(raw ?? "")
    .trim()
    .replace(/[\s\u00a0\u202f]/g, "");
  s = s.split(group).join("");
  if (decimal !== ".") {
    s = s.split(decimal).join(".");
  }
  if (!/^[-+]?(\d+\.?\d*|\.\d+)$/.test(s)) {
    return null;
  }
  const n = Number(s);
  return Number.isFinite(n) ? n : null;
}

/**
 * 셀 값 하나를 열 타입으로 바꾼다.
 * @param {string} raw 붙여넣은 값
 * @param {object} column 그리드 열(inputType, options, length, fieldApiName)
 * @param {object} options { locale, lookups: { 필드: { 값: {id, label, ambiguous} } } }
 * @returns {{value: any, label?: string, error?: string}} 결과
 */
export function convertCell(raw, column, options = {}) {
  const s = String(raw ?? "").trim();
  const type = column.inputType;
  if (s === "") {
    return { value: type === "CHECKBOX" ? false : null };
  }
  switch (type) {
    case "DATE": {
      const v = parseDate(s, options.locale);
      return v ? { value: v } : { value: null, error: ERR_DATE };
    }
    case "NUMBER": {
      const v = parseNumber(s, options.locale);
      return v === null ? { value: null, error: ERR_NUMBER } : { value: v };
    }
    case "CHECKBOX": {
      const w = s.toLowerCase();
      if (TRUE_WORDS.has(w)) {
        return { value: true };
      }
      return FALSE_WORDS.has(w)
        ? { value: false }
        : { value: null, error: ERR_CHECKBOX };
    }
    case "PICKLIST": {
      const lower = s.toLowerCase();
      const hit =
        (column.options ?? []).find((o) => o.value === s) ??
        (column.options ?? []).find(
          (o) =>
            o.value?.toLowerCase() === lower || o.label?.toLowerCase() === lower
        );
      return hit
        ? { value: hit.value, label: hit.label }
        : { value: null, error: ERR_PICKLIST };
    }
    case "LOOKUP":
    case "CODE": {
      const hit = options.lookups?.[column.fieldApiName]?.[s];
      return hit?.id
        ? { value: hit.id, label: hit.label }
        : { value: null, error: ERR_LOOKUP };
    }
    default: {
      if (column.length && s.length > column.length) {
        return { value: null, error: ERR_LENGTH };
      }
      return { value: s };
    }
  }
}

/**
 * 붙여넣은 열 → 그리드 열(시작 열부터 순서대로). 넘치는 열은 null.
 * @param {object[]} columns 그리드 데이터 열(화면 순서)
 * @param {number} startIndex 시작 열 순번
 * @param {number} width 붙여넣은 열 수
 * @returns {Array<object|null>} 열 또는 null
 */
export function mapColumns(columns, startIndex, width) {
  const out = [];
  for (let i = 0; i < width; i++) {
    out.push(columns[startIndex + i] ?? null);
  }
  return out;
}

/**
 * 서버 참조 확인 요청: 참조·코드 열별 서로 다른 값.
 * @param {string[][]} rows 데이터 행(머리글 제외)
 * @param {Array<object|null>} mapped mapColumns 결과
 * @returns {object} { 필드: [값] }
 */
export function lookupRequest(rows, mapped) {
  const out = {};
  mapped.forEach((col, i) => {
    if (!col || !col.editable || !REFERENCE_TYPES.has(col.inputType)) {
      return;
    }
    const values = new Set();
    rows.forEach((r) => {
      const v = String(r[i] ?? "").trim();
      if (v) {
        values.add(v);
      }
    });
    if (values.size) {
      out[col.fieldApiName] = [...values];
    }
  });
  return out;
}

/**
 * 미리보기와 적용용 결과를 만든다.
 * @param {object} args { rows(머리글 제외), mapped, locale, lookups }
 * @returns {object} { rows: [{ cells: [{raw, value, label, error, skipped}] }], errorCount, skippedCount }
 */
export function buildPreview({ rows, mapped, locale, lookups }) {
  let errorCount = 0;
  let skippedCount = 0;
  const out = rows.map((r) => ({
    cells: mapped.map((col, i) => {
      const raw = r[i] ?? "";
      if (!col || !col.editable) {
        if (String(raw).trim() !== "") {
          skippedCount++;
        }
        return { raw, skipped: true };
      }
      const c = convertCell(raw, col, { locale, lookups });
      if (c.error) {
        errorCount++;
      }
      return { raw, ...c };
    })
  }));
  return { rows: out, errorCount, skippedCount };
}
