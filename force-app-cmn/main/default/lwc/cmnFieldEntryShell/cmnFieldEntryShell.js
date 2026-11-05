import { LightningElement, api, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";
import FORM_FACTOR from "@salesforce/client/formFactor";
import LOCALE from "@salesforce/i18n/locale";
import USER_ID from "@salesforce/user/Id";
import loadSheet from "@salesforce/apex/CMN_FieldEntryController.load";
import saveEntries from "@salesforce/apex/CMN_FieldEntryController.save";
import validateScan from "@salesforce/apex/CMN_FieldEntryController.validateScan";
import { draftKey, saveDraft, loadDraft, clearDraft } from "c/cmnDraftStore";
import { parseNumber } from "c/cmnGridPasteParser";
import {
  judgeValue,
  judgeItem,
  okNgOf,
  PASS,
  FAIL
} from "c/cmnFieldEntryJudge";
import LOADING from "@salesforce/label/c.CMN_FieldEntry_Loading";
import LOAD_ERROR from "@salesforce/label/c.CMN_FieldEntry_LoadError";
import NO_RECORD from "@salesforce/label/c.CMN_FieldEntry_NoRecord";
import PROGRESS from "@salesforce/label/c.CMN_FieldEntry_Progress";
import MODE_SEQUENTIAL from "@salesforce/label/c.CMN_FieldEntry_ModeSequential";
import MODE_TABLE from "@salesforce/label/c.CMN_FieldEntry_ModeTable";
import MODE_LABEL from "@salesforce/label/c.CMN_FieldEntry_ModeLabel";
import MISSING_ONLY from "@salesforce/label/c.CMN_FieldEntry_MissingOnly";
import SAMPLE from "@salesforce/label/c.CMN_FieldEntry_Sample";
import SAMPLE_COL from "@salesforce/label/c.CMN_FieldEntry_SampleCol";
import ITEM_COL from "@salesforce/label/c.CMN_FieldEntry_ItemCol";
import SPEC_COL from "@salesforce/label/c.CMN_FieldEntry_SpecCol";
import RESULT_COL from "@salesforce/label/c.CMN_FieldEntry_ResultCol";
import VALUE_LABEL from "@salesforce/label/c.CMN_FieldEntry_Value";
import TEXT_LABEL from "@salesforce/label/c.CMN_FieldEntry_Text";
import OK_LABEL from "@salesforce/label/c.CMN_FieldEntry_Ok";
import NG_LABEL from "@salesforce/label/c.CMN_FieldEntry_Ng";
import PASS_LABEL from "@salesforce/label/c.CMN_FieldEntry_Pass";
import FAIL_LABEL from "@salesforce/label/c.CMN_FieldEntry_Fail";
import INCOMPLETE_LABEL from "@salesforce/label/c.CMN_FieldEntry_Incomplete";
import PREV from "@salesforce/label/c.CMN_FieldEntry_Prev";
import NEXT from "@salesforce/label/c.CMN_FieldEntry_Next";
import FINALIZE from "@salesforce/label/c.CMN_FieldEntry_Finalize";
import SAVE_NOW from "@salesforce/label/c.CMN_FieldEntry_SaveNow";
import DRAFT_SAVED from "@salesforce/label/c.CMN_FieldEntry_DraftSaved";
import SERVER_SAVED from "@salesforce/label/c.CMN_FieldEntry_ServerSaved";
import PENDING from "@salesforce/label/c.CMN_FieldEntry_Pending";
import SAVE_FAILED from "@salesforce/label/c.CMN_FieldEntry_SaveFailed";
import DRAFT_RESTORE from "@salesforce/label/c.CMN_FieldEntry_DraftRestore";
import DRAFT_TITLE from "@salesforce/label/c.CMN_FieldEntry_DraftTitle";
import MISSING_CONFIRM from "@salesforce/label/c.CMN_FieldEntry_MissingConfirm";
import FINALIZE_TITLE from "@salesforce/label/c.CMN_FieldEntry_FinalizeTitle";
import PHOTO_MISSING_TITLE from "@salesforce/label/c.CMN_FieldEntry_PhotoMissingTitle";
import PHOTO_REQUIRED from "@salesforce/label/c.CMN_FieldEntry_PhotoRequired";
import GAUGE_REQUIRED from "@salesforce/label/c.CMN_FieldEntry_GaugeRequired";
import FINALIZED from "@salesforce/label/c.CMN_FieldEntry_Finalized";
import SERVER_DIFF from "@salesforce/label/c.CMN_FieldEntry_ServerDiff";
import SERVER_RESULT from "@salesforce/label/c.CMN_FieldEntry_ServerResult";
import READ_ONLY from "@salesforce/label/c.CMN_FieldEntry_ReadOnly";
import LOT from "@salesforce/label/c.CMN_FieldEntry_Lot";
import GAUGE from "@salesforce/label/c.CMN_FieldEntry_Gauge";
import SCAN_OK from "@salesforce/label/c.CMN_FieldEntry_ScanOk";
import REFERENCE from "@salesforce/label/c.CMN_FieldEntry_Reference";
import PHOTOS from "@salesforce/label/c.CMN_FieldEntry_Photos";
import METHOD from "@salesforce/label/c.CMN_FieldEntry_Method";
import NOMINAL from "@salesforce/label/c.CMN_FieldEntry_Nominal";
import ALL_DONE from "@salesforce/label/c.CMN_FieldEntry_AllDone";
import PASTE_HINT from "@salesforce/label/c.CMN_FieldEntry_PasteHint";
import NOT_NUMBER from "@salesforce/label/c.CMN_FieldEntry_NotNumber";
import UNEXPECTED from "@salesforce/label/c.CMN_Common_UnexpectedError";

const DRAFT_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const OK_NG_TYPES = new Set(["ATTRIBUTE", "VISUAL", "REPORT"]);
const MAX_LISTED = 10;
const RESULT_TEXT = {
  PASS: PASS_LABEL,
  FAIL: FAIL_LABEL,
  INCOMPLETE: INCOMPLETE_LABEL
};
const RESULT_ICON = {
  PASS: "utility:success",
  FAIL: "utility:error",
  INCOMPLETE: "utility:clock"
};
const RESULT_VARIANT = { PASS: "success", FAIL: "error", INCOMPLETE: "" };

function format(template, ...args) {
  return args.reduce((s, a, i) => s.replace(`{${i}}`, a), template ?? "");
}

function slotKey(itemKey, sampleNo) {
  return `${itemKey}#${sampleNo}`;
}

function same(a, b) {
  const norm = (v) =>
    JSON.stringify({
      n: v?.numValue ?? null,
      o: v?.okNg ?? null,
      t: v?.text ?? null,
      p: v?.photoIds ?? [],
      g: v?.gaugeNo ?? null
    });
  return norm(a) === norm(b);
}

/**
 * 현장 입력 셸(CMN-00-UX-008, 화면 유형 T3). 수입·출하 검사, 시험 결과, 교정, 초기유동 점검의 시료 값 입력을 한 셸로 한다.
 * 시트(헤더·항목·값·편집 가능)는 레코드 객체에 등록된 Provider가 준다. 셸은 규격 비교 미리보기만 하고 판정은 서버가 확정한다.
 * - 순차 모드(휴대폰·태블릿 기본): 항목 1개 × 시료 1개, 다음·이전은 서버 호출 없음(BR-2)
 * - 표 모드(데스크톱 기본): 행 = 항목, 열 = 시료, 세로 붙여넣기(BR-3)
 * - 입력마다 브라우저 임시 저장, 항목을 다 채우면 서버 중간 저장, "판정 확정"은 최종 저장(BR-4)
 * - 저장 실패 시 입력 계속 + "전송 대기 n건", 자동 재전송 없음(BR-5)
 * 진입: 레코드 페이지·화면 액션(recordId) 또는 현장 입력 탭(상태 매개변수 c__recordId).
 */
export default class CmnFieldEntryShell extends NavigationMixin(
  LightningElement
) {
  _recordId;
  connected = false;
  started = false;
  pageChecked = false;

  @api
  get recordId() {
    return this._recordId;
  }
  set recordId(value) {
    this._recordId = value;
    this.start();
  }

  @wire(CurrentPageReference)
  handlePageRef(ref) {
    this.pageChecked = true;
    const id = ref?.state?.c__recordId;
    if (id && !this._recordId) {
      this._recordId = id;
      this.start();
    }
  }

  labels = {
    loading: LOADING,
    modeLabel: MODE_LABEL,
    missingOnly: MISSING_ONLY,
    itemCol: ITEM_COL,
    specCol: SPEC_COL,
    resultCol: RESULT_COL,
    text: TEXT_LABEL,
    ok: OK_LABEL,
    ng: NG_LABEL,
    prev: PREV,
    next: NEXT,
    finalize: FINALIZE,
    saveNow: SAVE_NOW,
    readOnly: READ_ONLY,
    lot: LOT,
    gauge: GAUGE,
    reference: REFERENCE,
    photoMissingTitle: PHOTO_MISSING_TITLE,
    serverDiff: SERVER_DIFF,
    allDone: ALL_DONE,
    pasteHint: PASTE_HINT
  };
  sheet;
  values = {};
  pending = {};
  pendingSeq = 0;
  gauges = {};
  scanStatus = {};
  errors = {};
  generalErrors = [];
  photoMissing = [];
  serverResults = {};
  diffItems = [];
  overall;
  nextAction;
  mode = "SEQUENTIAL";
  missingOnly = false;
  currentKey;
  isLoading = false;
  isSaving = false;
  loadError;
  offline = false;
  failMessage;
  draftSaved = false;
  serverSaved = false;

  connectedCallback() {
    this.connected = true;
    this.start();
  }

  start() {
    if (this.connected && this._recordId && !this.started) {
      this.started = true;
      this.load();
    }
  }

  // ---------------------------------------------------------------- 로드·초안
  get storeKey() {
    return draftKey(USER_ID, "FIELD_ENTRY", this._recordId);
  }

  async load() {
    this.isLoading = true;
    this.loadError = undefined;
    try {
      const sheet = await loadSheet({ recordId: this._recordId });
      const values = {};
      (sheet?.values ?? []).forEach((v) => {
        values[slotKey(v.itemKey, v.sampleNo)] = {
          ...v,
          photoIds: v.photoIds ?? []
        };
      });
      (sheet?.values ?? []).forEach((v) => {
        if (v.gaugeNo) {
          this.gauges = { ...this.gauges, [v.itemKey]: v.gaugeNo };
        }
      });
      this.sheet = sheet;
      this.values = values;
      this.mode =
        FORM_FACTOR === "Large" ? sheet?.defaultMode || "TABLE" : "SEQUENTIAL";
      this.currentKey = this.slots[0]?.key;
      if (sheet?.editable) {
        await this.offerDraft(values);
      }
    } catch (e) {
      this.loadError = e?.body?.message || LOAD_ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  /** 이 기기에 남은 입력값이 서버 값과 다르면 복원 여부를 묻는다(AC-3). */
  async offerDraft(serverValues) {
    const draft = loadDraft(this.storeKey);
    const keys = new Set(this.slots.map((s) => s.key));
    const changed = Object.entries(draft?.values ?? {}).filter(
      ([k, v]) => keys.has(k) && !same(v, serverValues[k])
    );
    if (!changed.length) {
      if (draft) {
        clearDraft(this.storeKey);
      }
      return;
    }
    const ok = await LightningConfirm.open({
      message: format(DRAFT_RESTORE, changed.length),
      label: DRAFT_TITLE,
      theme: "warning"
    });
    if (!ok) {
      clearDraft(this.storeKey);
      return;
    }
    const values = { ...serverValues };
    const pending = {};
    changed.forEach(([k, v]) => {
      values[k] = v;
      pending[v.itemKey] = ++this.pendingSeq;
    });
    this.values = values;
    this.pending = pending;
    this.gauges = { ...this.gauges, ...(draft.gauges ?? {}) };
    this.draftSaved = true;
  }

  persist() {
    if (!this.sheet?.editable) {
      return;
    }
    this.draftSaved = saveDraft(
      this.storeKey,
      { values: this.values, gauges: this.gauges },
      DRAFT_TTL_MS
    );
  }

  // ---------------------------------------------------------------- 화면 상태
  get noRecord() {
    return this.connected && this.pageChecked && !this._recordId;
  }

  get noRecordText() {
    return NO_RECORD;
  }

  get readOnly() {
    return !this.sheet?.editable;
  }

  get items() {
    return [...(this.sheet?.items ?? [])].sort(
      (a, b) => (a.sequence ?? 0) - (b.sequence ?? 0)
    );
  }

  get itemsByKey() {
    const out = {};
    this.items.forEach((i) => {
      out[i.key] = i;
    });
    return out;
  }

  get slots() {
    const out = [];
    this.items.forEach((item) => {
      for (let n = 1; n <= (item.sampleQty || 1); n++) {
        out.push({ key: slotKey(item.key, n), item, sampleNo: n });
      }
    });
    return out;
  }

  isEntered(slot) {
    return judgeValue(slot.item, this.values[slot.key]) !== "INCOMPLETE";
  }

  get visibleSlots() {
    return this.missingOnly
      ? this.slots.filter((s) => !this.isEntered(s))
      : this.slots;
  }

  get enteredCount() {
    return this.slots.filter((s) => this.isEntered(s)).length;
  }

  get progressText() {
    return format(PROGRESS, this.enteredCount, this.slots.length);
  }

  get progressValue() {
    return this.slots.length
      ? Math.round((this.enteredCount / this.slots.length) * 100)
      : 0;
  }

  get headerLine() {
    const h = this.sheet?.header ?? {};
    return [h.recordNo, h.itemNo, h.plant].filter(Boolean).join(" · ");
  }

  get showLotCheck() {
    return !!this.sheet?.lotCheck && !this.readOnly;
  }

  get lotStatus() {
    return this.statusView(this.scanStatus.LOT);
  }

  statusView(status) {
    if (!status) {
      return null;
    }
    return {
      text: status.ok ? `${SCAN_OK}: ${status.value}` : status.message,
      className: status.ok ? "slds-text-color_success" : "slds-text-color_error"
    };
  }

  get modeOptions() {
    return [
      { label: MODE_SEQUENTIAL, value: "SEQUENTIAL" },
      { label: MODE_TABLE, value: "TABLE" }
    ];
  }

  get isSequential() {
    return this.mode === "SEQUENTIAL";
  }

  get pendingCount() {
    return Object.keys(this.pending).length;
  }

  get statusText() {
    if (this.pendingCount && (this.offline || !this.serverSaved)) {
      return format(PENDING, this.pendingCount);
    }
    if (this.serverSaved && !this.pendingCount) {
      return SERVER_SAVED;
    }
    return this.draftSaved ? DRAFT_SAVED : "";
  }

  get showSaveNow() {
    return !this.readOnly && this.pendingCount > 0;
  }

  get finalizeDisabled() {
    return this.isSaving;
  }

  get hasDiff() {
    return this.diffItems.length > 0;
  }

  get finalText() {
    return this.overall
      ? format(FINALIZED, RESULT_TEXT[this.overall] ?? this.overall)
      : "";
  }

  // ---------------------------------------------------------------- 항목 표시
  specText(item) {
    if (item.type !== "VARIABLE") {
      return "";
    }
    const f = (v) => {
      return item.decimals === null || item.decimals === undefined
        ? String(v)
        : Number(v).toFixed(item.decimals);
    };
    const has = (v) => v !== null && v !== undefined;
    let range = "";
    if (has(item.lsl) && has(item.usl)) {
      range = `${f(item.lsl)} ~ ${f(item.usl)}`;
    } else if (has(item.lsl)) {
      range = `≥ ${f(item.lsl)}`;
    } else if (has(item.usl)) {
      range = `≤ ${f(item.usl)}`;
    }
    const nominal = has(item.nominal)
      ? ` (${format(NOMINAL, f(item.nominal))})`
      : "";
    return `${range} ${item.unit ?? ""}${nominal}`.trim();
  }

  resultView(result, server) {
    return {
      text: RESULT_TEXT[result],
      icon: RESULT_ICON[result],
      variant: RESULT_VARIANT[result],
      server:
        server && server !== result
          ? `${SERVER_RESULT}: ${RESULT_TEXT[server] ?? server}`
          : ""
    };
  }

  itemPreview(item) {
    return judgeItem(item, (n) => this.values[slotKey(item.key, n)]);
  }

  needsPhoto(item) {
    return item.type === "VISUAL" || item.photoRequiredOnNg === true;
  }

  get current() {
    const visible = this.visibleSlots;
    const slot = visible.find((s) => s.key === this.currentKey) ?? visible[0];
    if (!slot) {
      return null;
    }
    const item = slot.item;
    const v = this.values[slot.key] ?? {};
    const result = judgeValue(item, v);
    const index = visible.indexOf(slot);
    return {
      key: slot.key,
      item,
      itemKey: item.key,
      sampleText: format(SAMPLE, slot.sampleNo, item.sampleQty || 1),
      specText: this.specText(item),
      methodText: item.method ? format(METHOD, item.method) : "",
      valueLabel: format(VALUE_LABEL, item.unit ?? "").trim(),
      isNumber: item.type === "VARIABLE",
      isOkNg: OK_NG_TYPES.has(item.type),
      isText: item.type === "TEXT",
      numText: v.numValue ?? "",
      text: v.text ?? "",
      okClass: `slds-button slds-button_stretch big-button ${v.okNg === "OK" ? "slds-button_success" : "slds-button_neutral"}`,
      ngClass: `slds-button slds-button_stretch big-button ${v.okNg === "NG" ? "slds-button_destructive" : "slds-button_neutral"}`,
      okPressed: v.okNg === "OK" ? "true" : "false",
      ngPressed: v.okNg === "NG" ? "true" : "false",
      showPhoto: this.needsPhoto(item) && v.okNg === "NG" && !this.readOnly,
      photoText: (v.photoIds ?? []).length
        ? format(PHOTOS, v.photoIds.length)
        : "",
      showGauge: item.gaugeRequired === true && !this.readOnly,
      gaugeStatus: this.statusView(this.scanStatus[`GAUGE:${item.key}`]),
      gaugeValue: this.gauges[item.key],
      result: this.resultView(result),
      errors: this.errors[slot.key] ?? this.errors[item.key] ?? [],
      hasPrev: index > 0,
      hasNext: index >= 0 && index < visible.length - 1,
      prevDisabled: index <= 0,
      nextDisabled: index < 0 || index >= visible.length - 1
    };
  }

  get sampleHeaders() {
    const max = this.items.reduce((m, i) => Math.max(m, i.sampleQty || 1), 0);
    return Array.from({ length: max }, (_, i) => ({
      key: `s${i + 1}`,
      text: format(SAMPLE_COL, i + 1)
    }));
  }

  get tableRows() {
    const max = this.sampleHeaders.length;
    return this.items.map((item) => {
      const cells = [];
      for (let n = 1; n <= max; n++) {
        const key = slotKey(item.key, n);
        const v = this.values[key] ?? {};
        const inRange = n <= (item.sampleQty || 1);
        const errs = this.errors[key] ?? [];
        const result = inRange ? judgeValue(item, v) : null;
        cells.push({
          key,
          isNumber: inRange && item.type === "VARIABLE",
          isOkNg: inRange && OK_NG_TYPES.has(item.type),
          isText: inRange && item.type === "TEXT",
          text: item.type === "TEXT" ? (v.text ?? "") : (v.numValue ?? ""),
          isOk: v.okNg === "OK",
          isNg: v.okNg === "NG",
          aria: `${item.label} ${format(SAMPLE_COL, n)}`,
          cellClass: [
            errs.length ? "slds-has-error" : "",
            result === FAIL ? "cell-fail" : ""
          ].join(" "),
          title: errs.join(" "),
          failText: result === FAIL ? FAIL_LABEL : ""
        });
      }
      const preview = this.itemPreview(item);
      const diff = this.diffItems.includes(item.key);
      return {
        key: item.key,
        label: item.label,
        specialClass: item.specialClass,
        specText: this.specText(item),
        cells,
        result: this.resultView(preview, this.serverResults[item.key]),
        rowClass: diff ? "diff-row" : "",
        diff,
        errors: this.errors[item.key] ?? []
      };
    });
  }

  // ---------------------------------------------------------------- 입력
  setValues(patches) {
    const values = { ...this.values };
    const touched = new Set();
    const errors = { ...this.errors };
    patches.forEach(({ key, patch }) => {
      const [itemKey, n] = key.split("#");
      const cur = values[key] ?? { itemKey, sampleNo: Number(n), photoIds: [] };
      values[key] = { ...cur, ...patch };
      touched.add(itemKey);
      delete errors[key];
    });
    const pending = { ...this.pending };
    touched.forEach((itemKey) => {
      pending[itemKey] = ++this.pendingSeq;
      delete errors[itemKey];
    });
    this.values = values;
    this.errors = errors;
    this.pending = pending;
    this.persist();
    const complete = [...touched].some(
      (k) => this.itemPreview(this.itemsByKey[k]) !== "INCOMPLETE"
    );
    if (complete) {
      this.autoSave();
    }
  }

  handleNumber(event) {
    const key = event.target.dataset.key;
    const raw = String(event.target.value ?? "").trim();
    if (!raw) {
      this.setValues([{ key, patch: { numValue: null } }]);
      return;
    }
    const n = parseNumber(raw, LOCALE);
    if (n === null) {
      this.errors = { ...this.errors, [key]: [NOT_NUMBER] };
      return;
    }
    this.setValues([{ key, patch: { numValue: n } }]);
  }

  handleNumberKey(event) {
    if (event.key === "Enter") {
      this.handleNumber(event);
      this.handleNext();
    }
  }

  handleOkNg(event) {
    const { key, value } = event.currentTarget.dataset;
    this.setValues([{ key, patch: { okNg: value } }]);
  }

  handleOkNgSelect(event) {
    this.setValues([
      {
        key: event.target.dataset.key,
        patch: { okNg: event.target.value || null }
      }
    ]);
  }

  handleText(event) {
    const key = event.target.dataset.key;
    this.setValues([
      { key, patch: { text: event.detail?.value ?? event.target.value ?? "" } }
    ]);
  }

  /** 표 모드 세로 붙여넣기(BR-3, AC-4): 엑셀 값 목록을 그 시료부터 차례로 넣는다. */
  handlePaste(event) {
    const text = event.clipboardData?.getData("text") ?? "";
    const lines = text.split(/\r?\n/).map((l) => l.trim());
    while (lines.length && !lines[lines.length - 1]) {
      lines.pop();
    }
    if (lines.length < 2) {
      return;
    }
    event.preventDefault();
    const [itemKey, start] = event.target.dataset.key.split("#");
    const item = this.itemsByKey[itemKey];
    const patches = [];
    const errors = {};
    lines.forEach((line, i) => {
      const n = Number(start) + i;
      if (n > (item.sampleQty || 1)) {
        return;
      }
      const key = slotKey(itemKey, n);
      if (item.type === "VARIABLE") {
        const num = line ? parseNumber(line, LOCALE) : null;
        if (line && num === null) {
          errors[key] = [NOT_NUMBER];
          return;
        }
        patches.push({ key, patch: { numValue: num } });
      } else if (OK_NG_TYPES.has(item.type)) {
        patches.push({ key, patch: { okNg: okNgOf(line) } });
      } else {
        patches.push({ key, patch: { text: line } });
      }
    });
    this.setValues(patches);
    this.errors = { ...this.errors, ...errors };
  }

  handlePhotos(event) {
    const key = event.currentTarget.dataset.key;
    const ids = event.detail?.documentIds ?? [];
    if (!ids.length) {
      return;
    }
    const cur = this.values[key]?.photoIds ?? [];
    this.setValues([{ key, patch: { photoIds: [...cur, ...ids] } }]);
  }

  async handleLotScan(event) {
    await this.checkScan("LOT", "LOT", event.detail?.value);
  }

  async handleGaugeScan(event) {
    const itemKey = event.currentTarget.dataset.item;
    const ok = await this.checkScan(
      "GAUGE",
      `GAUGE:${itemKey}`,
      event.detail?.value
    );
    if (ok) {
      this.gauges = { ...this.gauges, [itemKey]: event.detail.value };
      this.pending = { ...this.pending, [itemKey]: ++this.pendingSeq };
      this.persist();
    }
  }

  async checkScan(scanType, statusKey, value) {
    if (!value) {
      return false;
    }
    try {
      const message = await validateScan({
        recordId: this._recordId,
        scanType,
        value
      });
      this.scanStatus = {
        ...this.scanStatus,
        [statusKey]: { value, ok: !message, message }
      };
      return !message;
    } catch (e) {
      this.scanStatus = {
        ...this.scanStatus,
        [statusKey]: {
          value,
          ok: false,
          message: e?.body?.message || UNEXPECTED
        }
      };
      return false;
    }
  }

  handleReference(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.currentTarget.dataset.id,
        actionName: "view"
      }
    });
  }

  // ---------------------------------------------------------------- 이동·모드
  handleNext() {
    const visible = this.visibleSlots;
    const i = visible.findIndex((s) => s.key === this.current?.key);
    if (i >= 0 && i < visible.length - 1) {
      this.currentKey = visible[i + 1].key;
    }
  }

  handlePrev() {
    const visible = this.visibleSlots;
    const i = visible.findIndex((s) => s.key === this.current?.key);
    if (i > 0) {
      this.currentKey = visible[i - 1].key;
    }
  }

  handleMode(event) {
    this.mode = event.detail?.value ?? "SEQUENTIAL";
  }

  handleMissingOnly(event) {
    this.missingOnly = event.detail?.checked ?? !this.missingOnly;
  }

  // ---------------------------------------------------------------- 저장
  valuesFor(itemKeys) {
    const keys = new Set(itemKeys);
    return Object.values(this.values)
      .filter((v) => keys.has(v.itemKey))
      .map((v) => ({
        itemKey: v.itemKey,
        sampleNo: v.sampleNo,
        numValue: v.numValue ?? null,
        okNg: v.okNg ?? null,
        text: v.text ?? null,
        photoIds: v.photoIds ?? [],
        gaugeNo: this.gauges[v.itemKey] ?? v.gaugeNo ?? null
      }));
  }

  /** 항목을 다 채웠을 때 서버 중간 저장. 한 번 실패하면 사용자가 "지금 저장"을 누를 때까지 다시 보내지 않는다(BR-5). */
  autoSave() {
    if (this.readOnly || this.offline || this.isSaving) {
      return;
    }
    this.sendPending();
  }

  async sendPending() {
    const sent = { ...this.pending };
    const itemKeys = Object.keys(sent);
    if (!itemKeys.length) {
      return true;
    }
    this.isSaving = true;
    try {
      const result = await saveEntries({
        recordId: this._recordId,
        valuesJson: JSON.stringify(this.valuesFor(itemKeys)),
        isFinal: false
      });
      if (result?.success) {
        const pending = { ...this.pending };
        // 보내는 동안 또 바뀐 항목은 남긴다
        itemKeys.forEach((k) => {
          if (pending[k] === sent[k]) {
            delete pending[k];
          }
        });
        this.pending = pending;
        this.offline = false;
        this.failMessage = undefined;
        this.serverSaved = true;
        this.serverResults = {
          ...this.serverResults,
          ...(result.itemResults ?? {})
        };
      }
      this.applyErrors(result);
      return result?.success === true;
    } catch {
      this.offline = true;
      this.failMessage = SAVE_FAILED;
      return false;
    } finally {
      this.isSaving = false;
    }
  }

  handleSaveNow() {
    return this.sendPending();
  }

  applyErrors(result) {
    const errors = {};
    const general = [];
    (result?.errors ?? []).forEach((e) => {
      if (!e.itemKey) {
        general.push(e.message);
        return;
      }
      const key = e.sampleNo ? slotKey(e.itemKey, e.sampleNo) : e.itemKey;
      errors[key] = [...(errors[key] ?? []), e.message];
    });
    this.errors = { ...this.errors, ...errors };
    this.generalErrors = general;
  }

  /** 최종 저장 전 셸 확인: NG 사진(BR-7, AC-5)과 측정기 번호(BR-6). */
  shellIssues() {
    const out = [];
    this.slots.forEach((s) => {
      const v = this.values[s.key];
      if (
        this.needsPhoto(s.item) &&
        v?.okNg === "NG" &&
        !(v.photoIds ?? []).length
      ) {
        out.push({
          key: s.key,
          text: format(PHOTO_REQUIRED, s.item.label, s.sampleNo)
        });
      }
    });
    this.items
      .filter(
        (i) =>
          i.gaugeRequired &&
          !this.gauges[i.key] &&
          this.slots.some((s) => s.item.key === i.key && this.isEntered(s))
      )
      .forEach((i) =>
        out.push({ key: i.key, text: format(GAUGE_REQUIRED, i.label) })
      );
    return out;
  }

  async handleFinalize() {
    const issues = this.shellIssues();
    this.photoMissing = issues;
    if (issues.length) {
      return;
    }
    const missing = this.slots.filter((s) => !this.isEntered(s));
    if (missing.length) {
      const list = missing
        .slice(0, MAX_LISTED)
        .map((s) => `${s.item.label} ${s.sampleNo}`)
        .join(", ");
      const ok = await LightningConfirm.open({
        message: format(MISSING_CONFIRM, missing.length, list),
        label: FINALIZE_TITLE,
        theme: "warning"
      });
      if (!ok) {
        return;
      }
    }
    this.isSaving = true;
    try {
      const result = await saveEntries({
        recordId: this._recordId,
        valuesJson: JSON.stringify(
          this.valuesFor(this.items.map((i) => i.key))
        ),
        isFinal: true
      });
      this.applyErrors(result);
      if (!result?.success) {
        return;
      }
      this.pending = {};
      this.offline = false;
      this.failMessage = undefined;
      this.serverSaved = true;
      clearDraft(this.storeKey);
      this.draftSaved = false;
      this.serverResults = { ...(result.itemResults ?? {}) };
      // 서버 판정이 화면 미리보기와 다른 항목(AC-6)
      this.diffItems = this.items
        .filter(
          (i) =>
            this.serverResults[i.key] &&
            this.serverResults[i.key] !== this.itemPreview(i)
        )
        .map((i) => i.key);
      this.overall = result.overall;
      this.nextAction = result.nextActionLabel;
      this.dispatchEvent(
        new ShowToastEvent({
          message: this.finalText,
          variant: result.overall === PASS ? "success" : "warning"
        })
      );
    } catch (e) {
      this.offline = true;
      this.failMessage = e?.body?.message || SAVE_FAILED;
    } finally {
      this.isSaving = false;
    }
  }
}
