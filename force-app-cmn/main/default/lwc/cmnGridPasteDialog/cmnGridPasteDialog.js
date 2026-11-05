import { api } from "lwc";
import LightningModal from "lightning/modal";
import {
  parseClipboard,
  mapColumns,
  lookupRequest,
  buildPreview,
  ERR_DATE,
  ERR_NUMBER,
  ERR_PICKLIST,
  ERR_LOOKUP,
  ERR_CHECKBOX,
  ERR_LENGTH
} from "c/cmnGridPasteParser";
import TITLE from "@salesforce/label/c.CMN_Grid_PasteTitle";
import HELP from "@salesforce/label/c.CMN_Grid_PasteHelp";
import AREA from "@salesforce/label/c.CMN_Grid_PasteArea";
import HEADER from "@salesforce/label/c.CMN_Grid_PasteHeader";
import START_COLUMN from "@salesforce/label/c.CMN_Grid_PasteStartColumn";
import PREVIEW from "@salesforce/label/c.CMN_Grid_PastePreview";
import MODE from "@salesforce/label/c.CMN_Grid_PasteMode";
import APPEND from "@salesforce/label/c.CMN_Grid_PasteAppend";
import OVERWRITE from "@salesforce/label/c.CMN_Grid_PasteOverwrite";
import APPLY from "@salesforce/label/c.CMN_Grid_PasteApply";
import CANCEL from "@salesforce/label/c.CMN_Grid_PasteCancel";
import SUMMARY from "@salesforce/label/c.CMN_Grid_PasteSummary";
import CHECKING from "@salesforce/label/c.CMN_Grid_PasteChecking";
import ERR_DATE_TEXT from "@salesforce/label/c.CMN_Grid_PasteErrDate";
import ERR_NUMBER_TEXT from "@salesforce/label/c.CMN_Grid_PasteErrNumber";
import ERR_PICKLIST_TEXT from "@salesforce/label/c.CMN_Grid_PasteErrPicklist";
import ERR_LOOKUP_TEXT from "@salesforce/label/c.CMN_Grid_PasteErrLookup";
import ERR_CHECKBOX_TEXT from "@salesforce/label/c.CMN_Grid_PasteErrCheckbox";
import ERR_LENGTH_TEXT from "@salesforce/label/c.CMN_Grid_PasteErrLength";
import READ_ONLY_COL from "@salesforce/label/c.CMN_Grid_PasteReadOnlyCol";
import TOO_MANY from "@salesforce/label/c.CMN_Grid_PasteTooMany";
import NO_SELECTION from "@salesforce/label/c.CMN_Grid_PasteNoSelection";
import LOAD_ERROR from "@salesforce/label/c.CMN_Grid_LoadError";

const PREVIEW_ROWS = 200;
const ERROR_TEXT = {
  [ERR_DATE]: ERR_DATE_TEXT,
  [ERR_NUMBER]: ERR_NUMBER_TEXT,
  [ERR_PICKLIST]: ERR_PICKLIST_TEXT,
  [ERR_LOOKUP]: ERR_LOOKUP_TEXT,
  [ERR_CHECKBOX]: ERR_CHECKBOX_TEXT,
  [ERR_LENGTH]: ERR_LENGTH_TEXT
};

function format(template, ...args) {
  return args.reduce((s, a, i) => s.replace(`{${i}}`, a), template);
}

/**
 * 엑셀 붙여넣기 대화상자(CMN-00-UX-006 BR-3).
 * 1) 탭 구분 범위를 붙여넣고 2) 첫 행 머리글·시작 열을 고르고 3) 열 매핑·변환 오류 셀을 미리 보고
 * 4) 아래에 추가 / 선택한 행부터 덮어쓰기를 골라 적용한다. 참조·코드 값은 서버 확인 1회(resolver)로 바꾼다.
 * 닫을 때 { mode, rows: [{ cells: { 필드: { value, raw, error, label } } }] }를 돌려준다(취소면 null).
 */
export default class CmnGridPasteDialog extends LightningModal {
  /** 그리드 데이터 열(화면 순서, editable 포함) */
  @api columns = [];
  @api maxRows = 200;
  @api canOverwrite = false;
  @api locale;
  /** (keysByField) => Promise<LookupMatch[]> */
  @api resolver;

  labels = {
    title: TITLE,
    help: HELP,
    area: AREA,
    header: HEADER,
    startColumn: START_COLUMN,
    preview: PREVIEW,
    mode: MODE,
    apply: APPLY,
    cancel: CANCEL,
    checking: CHECKING
  };
  text = "";
  hasHeader = false;
  startIndex = 0;
  mode = "append";
  mapped = [];
  result;
  tooMany = false;
  isChecking = false;
  errorMessage;
  lookupCache = {};
  seq = 0;

  connectedCallback() {
    const first = (this.columns ?? []).findIndex((c) => c.editable);
    this.startIndex = first < 0 ? 0 : first;
  }

  get startOptions() {
    return (this.columns ?? []).map((c, i) => ({
      label: c.label,
      value: String(i)
    }));
  }

  get startValue() {
    return String(this.startIndex);
  }

  get modeOptions() {
    return [
      { label: APPEND, value: "append" },
      { label: OVERWRITE, value: "overwrite" }
    ];
  }

  get hasPreview() {
    return !!this.result?.rows?.length;
  }

  get applyDisabled() {
    return !this.hasPreview || this.isChecking;
  }

  get previewHeader() {
    return this.mapped.map((c, i) => ({
      key: `h${i}`,
      text: !c ? "" : c.editable ? c.label : `${c.label} (${READ_ONLY_COL})`
    }));
  }

  get previewRows() {
    return (this.result?.rows ?? []).slice(0, PREVIEW_ROWS).map((r, ri) => ({
      key: `r${ri}`,
      cells: r.cells.map((c, ci) => ({
        key: `c${ri}-${ci}`,
        text: c.error || c.skipped ? c.raw : this.display(c),
        error: c.error ? ERROR_TEXT[c.error] : null,
        className: c.skipped
          ? "slds-text-color_weak"
          : c.error
            ? "slds-text-color_error"
            : ""
      }))
    }));
  }

  get summary() {
    if (!this.result) {
      return "";
    }
    return format(
      SUMMARY,
      this.result.rows.length,
      this.mapped.filter((c) => c?.editable).length,
      this.result.errorCount
    );
  }

  get tooManyText() {
    return this.tooMany ? format(TOO_MANY, this.maxRows) : "";
  }

  display(c) {
    if (c.label) {
      return c.label;
    }
    if (c.value === true) {
      return "✓";
    }
    if (c.value === false || c.value === null || c.value === undefined) {
      return "";
    }
    return String(c.value);
  }

  handleText(event) {
    this.text = event.detail?.value ?? event.target?.value ?? "";
    return this.refresh();
  }

  handleHeader(event) {
    this.hasHeader = event.detail?.checked ?? event.target?.checked ?? false;
    return this.refresh();
  }

  handleStart(event) {
    this.startIndex = Number(event.detail?.value ?? 0);
    return this.refresh();
  }

  handleMode(event) {
    this.mode = event.detail?.value ?? "append";
    this.errorMessage = undefined;
  }

  async refresh() {
    const token = ++this.seq;
    this.errorMessage = undefined;
    const all = parseClipboard(this.text);
    const rows = this.hasHeader ? all.slice(1) : all;
    this.tooMany = rows.length > this.maxRows;
    const used = rows.slice(0, this.maxRows);
    const width = used.reduce((w, r) => Math.max(w, r.length), 0);
    const mapped = mapColumns(this.columns ?? [], this.startIndex, width);
    const request = lookupRequest(used, mapped);
    const missing = {};
    Object.entries(request).forEach(([field, keys]) => {
      const todo = keys.filter(
        (k) => !(this.lookupCache[field] && k in this.lookupCache[field])
      );
      if (todo.length) {
        missing[field] = todo;
      }
    });
    if (Object.keys(missing).length && this.resolver) {
      this.isChecking = true;
      try {
        const matches = (await this.resolver(missing)) ?? [];
        const cache = { ...this.lookupCache };
        matches.forEach((m) => {
          cache[m.fieldApiName] = {
            ...(cache[m.fieldApiName] ?? {}),
            [m.key]: m
          };
        });
        this.lookupCache = cache;
      } catch (e) {
        this.errorMessage = e?.body?.message || LOAD_ERROR;
      } finally {
        this.isChecking = false;
      }
    }
    if (token !== this.seq) {
      return;
    }
    this.mapped = mapped;
    this.result = buildPreview({
      rows: used,
      mapped,
      locale: this.locale,
      lookups: this.lookupCache
    });
  }

  handleApply() {
    if (!this.hasPreview) {
      return;
    }
    if (this.mode === "overwrite" && !this.canOverwrite) {
      this.errorMessage = NO_SELECTION;
      return;
    }
    const rows = this.result.rows.map((r) => {
      const cells = {};
      r.cells.forEach((c, i) => {
        const col = this.mapped[i];
        if (col?.editable && !c.skipped) {
          cells[col.fieldApiName] = {
            value: c.value ?? null,
            raw: c.raw,
            error: c.error ?? null,
            label: c.label ?? null
          };
        }
      });
      return { cells };
    });
    this.close({ mode: this.mode, rows });
  }

  handleCancel() {
    this.close(null);
  }
}
