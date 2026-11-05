import {
  parseClipboard,
  parseDate,
  parseNumber,
  convertCell,
  mapColumns,
  lookupRequest,
  buildPreview,
  ERR_DATE,
  ERR_PICKLIST,
  ERR_LOOKUP,
  ERR_CHECKBOX,
  ERR_LENGTH,
  ERR_NUMBER
} from "c/cmnGridPasteParser";

const COLUMNS = [
  { fieldApiName: "Name", inputType: "TEXT", editable: true, length: 10 },
  { fieldApiName: "StartDate__c", inputType: "DATE", editable: true },
  { fieldApiName: "Quantity__c", inputType: "NUMBER", editable: true },
  {
    fieldApiName: "Category__c",
    inputType: "PICKLIST",
    editable: true,
    options: [
      { value: "PLAN", label: "Plan" },
      { value: "CHECK", label: "Check" }
    ]
  },
  { fieldApiName: "Plant__c", inputType: "LOOKUP", editable: true },
  { fieldApiName: "LineNo__c", inputType: "NUMBER", editable: false }
];

describe("c-cmn-grid-paste-parser (UX-006 BR-3)", () => {
  it("parses tab separated cells with quoted line breaks", () => {
    const text = 'a\tb\r\n"multi\nline"\t"say ""hi"""\n\n';
    expect(parseClipboard(text)).toEqual([
      ["a", "b"],
      ["multi\nline", 'say "hi"']
    ]);
    expect(parseClipboard("")).toEqual([]);
  });

  it("reads ISO, dotted and locale dates and rejects impossible dates", () => {
    expect(parseDate("2026-11-06", "ko-KR")).toBe("2026-11-06");
    expect(parseDate("2026.11.6", "ko-KR")).toBe("2026-11-06");
    expect(parseDate("2026. 11. 6.", "ko-KR")).toBe("2026-11-06");
    expect(parseDate("11/6/2026", "en-US")).toBe("2026-11-06");
    expect(parseDate("06/11/2026", "en-GB")).toBe("2026-11-06");
    expect(parseDate("2026-02-30", "ko-KR")).toBeNull();
    expect(parseDate("next week", "ko-KR")).toBeNull();
  });

  it("removes locale thousand separators", () => {
    expect(parseNumber("1,234.5", "en-US")).toBe(1234.5);
    expect(parseNumber("1.234,5", "de-DE")).toBe(1234.5);
    expect(parseNumber(" -12 ", "ko-KR")).toBe(-12);
    expect(parseNumber("12a", "ko-KR")).toBeNull();
  });

  it("converts cells by column type", () => {
    const opts = {
      locale: "ko-KR",
      lookups: { Plant__c: { KR01: { id: "a0P1", label: "KR01" } } }
    };
    expect(convertCell("check", COLUMNS[3], opts)).toEqual({
      value: "CHECK",
      label: "Check"
    });
    expect(convertCell("ZZ", COLUMNS[3], opts).error).toBe(ERR_PICKLIST);
    expect(convertCell("KR01", COLUMNS[4], opts)).toEqual({
      value: "a0P1",
      label: "KR01"
    });
    expect(convertCell("KR99", COLUMNS[4], opts).error).toBe(ERR_LOOKUP);
    expect(convertCell("Y", { inputType: "CHECKBOX" }, opts).value).toBe(true);
    expect(convertCell("x", { inputType: "CHECKBOX" }, opts).value).toBe(false);
    expect(convertCell("maybe", { inputType: "CHECKBOX" }, opts).error).toBe(
      ERR_CHECKBOX
    );
    expect(convertCell("", { inputType: "CHECKBOX" }, opts).value).toBe(false);
    expect(convertCell("abcdefghijk", COLUMNS[0], opts).error).toBe(ERR_LENGTH);
    expect(convertCell("1e", COLUMNS[2], opts).error).toBe(ERR_NUMBER);
    expect(convertCell("  ", COLUMNS[1], opts)).toEqual({ value: null });
  });

  it("AC-2: 5 x 4 paste with one bad date shows one error cell", () => {
    const rows = parseClipboard(
      [
        "Row 1\t2026-11-01\t1,000\tPlan",
        "Row 2\t2026.11.02\t2\tCheck",
        "Row 3\t2026-13-45\t3\tPLAN",
        "Row 4\t2026-11-04\t4\tCHECK",
        "Row 5\t2026-11-05\t5\tPlan"
      ].join("\n")
    );
    const mapped = mapColumns(COLUMNS, 0, 4);
    const preview = buildPreview({
      rows,
      mapped,
      locale: "ko-KR",
      lookups: {}
    });
    expect(preview.rows).toHaveLength(5);
    expect(preview.errorCount).toBe(1);
    const bad = preview.rows[2].cells[1];
    expect(bad).toMatchObject({
      value: null,
      error: ERR_DATE,
      raw: "2026-13-45"
    });
    expect(preview.rows[0].cells[2].value).toBe(1000);
  });

  it("maps from the start column, skips read-only columns and collects lookup keys", () => {
    const rows = [
      ["KR01", "7", "x"],
      ["KR02", "8", ""],
      ["KR01", "9", ""]
    ];
    const mapped = mapColumns(COLUMNS, 4, 3);
    expect(mapped.map((c) => c?.fieldApiName ?? null)).toEqual([
      "Plant__c",
      "LineNo__c",
      null
    ]);
    expect(lookupRequest(rows, mapped)).toEqual({ Plant__c: ["KR01", "KR02"] });
    const preview = buildPreview({
      rows,
      mapped,
      locale: "ko-KR",
      lookups: {}
    });
    expect(preview.skippedCount).toBe(4);
    expect(preview.rows[0].cells[1].skipped).toBe(true);
  });
});
