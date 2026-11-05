import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";
import {
  subscribe,
  unsubscribe,
  MessageContext
} from "lightning/messageService";
import GRID_REFRESH from "@salesforce/messageChannel/CMN_GridRefresh__c";
import FORM_FACTOR from "@salesforce/client/formFactor";
import LOCALE from "@salesforce/i18n/locale";
import USER_ID from "@salesforce/user/Id";
import loadGrid from "@salesforce/apex/CMN_GridController.load";
import saveGrid from "@salesforce/apex/CMN_GridController.save";
import resolveLookups from "@salesforce/apex/CMN_GridController.resolveLookups";
import { draftKey, saveDraft, loadDraft, clearDraft } from "c/cmnDraftStore";
import CmnGridPasteDialog from "c/cmnGridPasteDialog";
import BTN_ADD from "@salesforce/label/c.CMN_Grid_BtnAddRow";
import BTN_DELETE from "@salesforce/label/c.CMN_Grid_BtnDelete";
import BTN_PASTE from "@salesforce/label/c.CMN_Grid_BtnPaste";
import BTN_SCHEDULE from "@salesforce/label/c.CMN_Grid_BtnSchedule";
import BTN_TABLE from "@salesforce/label/c.CMN_Grid_BtnTable";
import BTN_CANCEL from "@salesforce/label/c.CMN_Grid_BtnCancel";
import BTN_SAVE from "@salesforce/label/c.CMN_Grid_BtnSave";
import BTN_REFRESH from "@salesforce/label/c.CMN_Grid_BtnRefresh";
import ERROR_COUNT from "@salesforce/label/c.CMN_Grid_ErrorCount";
import ERRORS_ONLY from "@salesforce/label/c.CMN_Grid_ErrorsOnly";
import CHANGE_COUNT from "@salesforce/label/c.CMN_Grid_ChangeCount";
import LOADING from "@salesforce/label/c.CMN_Grid_Loading";
import SAVING from "@salesforce/label/c.CMN_Grid_Saving";
import EMPTY from "@salesforce/label/c.CMN_Grid_Empty";
import EMPTY_READ_ONLY from "@salesforce/label/c.CMN_Grid_EmptyReadOnly";
import LOAD_ERROR from "@salesforce/label/c.CMN_Grid_LoadError";
import TRUNCATED from "@salesforce/label/c.CMN_Grid_Truncated";
import READ_ONLY from "@salesforce/label/c.CMN_Grid_ReadOnly";
import COL_STATE from "@salesforce/label/c.CMN_Grid_ColState";
import STATE_NEW from "@salesforce/label/c.CMN_Grid_StateNew";
import STATE_DELETED from "@salesforce/label/c.CMN_Grid_StateDeleted";
import STATE_CHANGED from "@salesforce/label/c.CMN_Grid_StateChanged";
import STATE_ERROR from "@salesforce/label/c.CMN_Grid_StateError";
import STATE_LOCKED from "@salesforce/label/c.CMN_Grid_StateLocked";
import ROW_ERROR_TITLE from "@salesforce/label/c.CMN_Grid_RowErrorTitle";
import TABLE_ERROR_TITLE from "@salesforce/label/c.CMN_Grid_TableErrorTitle";
import DRAFT_RESTORE from "@salesforce/label/c.CMN_Grid_DraftRestore";
import DRAFT_TITLE from "@salesforce/label/c.CMN_Grid_DraftTitle";
import UNSAVED_REFRESH from "@salesforce/label/c.CMN_Grid_UnsavedRefresh";
import SAVED from "@salesforce/label/c.CMN_Grid_Saved";
import NOTHING_TO_SAVE from "@salesforce/label/c.CMN_Grid_NothingToSave";
import FIX_ERRORS from "@salesforce/label/c.CMN_Grid_FixErrors";
import SELECT_ROWS from "@salesforce/label/c.CMN_Grid_SelectRows";
import PASTE_TITLE from "@salesforce/label/c.CMN_Grid_PasteTitle";
import PASTE_CELL_ERROR from "@salesforce/label/c.CMN_Grid_PasteCellError";
import REQUIRED_MISSING from "@salesforce/label/c.CMN_Grid_RequiredMissing";
import INVALID_VALUE from "@salesforce/label/c.CMN_Grid_InvalidValue";
import CELL_LOCKED from "@salesforce/label/c.CMN_Grid_CellLocked";
import DELETE_BLOCKED from "@salesforce/label/c.CMN_Grid_DeleteBlocked";
import SAVE_FAILED from "@salesforce/label/c.CMN_Grid_SaveFailed";
import CONFLICT from "@salesforce/label/c.CMN_Grid_Conflict";
import PHONE_OPEN from "@salesforce/label/c.CMN_Grid_PhoneOpen";

const KEY = "__key";
const NEW_PREFIX = "new-";
const REFERENCE = new Set(["LOOKUP", "CODE"]);
const SCROLL_ROWS = 15;
const STATE_ICON = {
  ERROR: "utility:error",
  DELETED: "utility:delete",
  NEW: "utility:new",
  CHANGED: "utility:edit",
  LOCKED: "utility:lock"
};
const STATE_TEXT = {
  ERROR: STATE_ERROR,
  DELETED: STATE_DELETED,
  NEW: STATE_NEW,
  CHANGED: STATE_CHANGED,
  LOCKED: STATE_LOCKED
};

function format(template, ...args) {
  return args.reduce((s, a, i) => s.replace(`{${i}}`, a), template ?? "");
}

function isBlank(v) {
  return v === null || v === undefined || v === "";
}

function isNewKey(key) {
  return String(key).startsWith(NEW_PREFIX);
}

function sameId(a, b) {
  return !!a && !!b && String(a).slice(0, 15) === String(b).slice(0, 15);
}

/**
 * 공통 편집 그리드(CMN-00-UX-006, 화면 유형 T2). 행이 많고 셀 단위로 입력하는 화면을 그리드 정의(gridKey)와
 * 업무 Provider만으로 만든다. 레코드 페이지에 두면 recordId(부모)가 자동으로 들어온다.
 * - 셀 편집은 브라우저 초안으로만 쌓고(바뀐 셀 표시) 저장할 때 한 번에 보낸다. 초안은 cmnDraftStore에 자동 저장(BR-2).
 * - 붙여넣기 대화상자(BR-3), 클라이언트 검증 → 서버 Provider 검증(BR-4), 버전 충돌 안내(BR-5),
 *   일정 막대 보기(BR-6), 휴대폰 읽기 전용 카드(BR-7), 외부 새로 고침 LMS·refresh()(BR-10), 행 메타(BR-11).
 * 업무 검증은 이 컴포넌트에 넣지 않는다(각 그리드의 Provider).
 */
export default class CmnEditableGrid extends NavigationMixin(LightningElement) {
  @api recordId;
  @api gridKey;

  @wire(MessageContext) messageContext;

  labels = {
    add: BTN_ADD,
    remove: BTN_DELETE,
    paste: BTN_PASTE,
    cancel: BTN_CANCEL,
    save: BTN_SAVE,
    refresh: BTN_REFRESH,
    errorsOnly: ERRORS_ONLY,
    loading: LOADING,
    saving: SAVING,
    readOnly: READ_ONLY,
    conflict: CONFLICT,
    open: PHONE_OPEN
  };
  view;
  baseRows = [];
  newRows = [];
  draftValues = [];
  deleted = [];
  pasteErrors = {};
  clientErrors = {};
  serverErrors = {};
  gridErrors = [];
  selectedKeys = [];
  labelCache = {};
  showSchedule = false;
  errorsOnly = false;
  isLoading = true;
  isSaving = false;
  loadError;
  conflict = false;
  hostWidth = 0;
  newSeq = 0;
  subscription;

  connectedCallback() {
    this.subscription = subscribe(this.messageContext, GRID_REFRESH, (m) =>
      this.handleRefreshMessage(m)
    );
    this.load(true);
  }

  disconnectedCallback() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  renderedCallback() {
    // 열 상대 폭(WidthWeight)을 실제 폭으로 바꾸려고 표 영역 폭을 잰다. 크게 바뀔 때만 다시 계산한다
    const width = this.refs?.host?.clientWidth ?? 0;
    if (width && Math.abs(width - this.hostWidth) > 40) {
      this.hostWidth = width;
    }
  }

  // ---------------------------------------------------------------- 공개
  /** 서버에서 다시 읽는다. 저장하지 않은 변경이 있으면 먼저 묻는다(BR-10). */
  @api
  async refresh() {
    if (this.isDirty) {
      const ok = await LightningConfirm.open({
        message: UNSAVED_REFRESH,
        label: DRAFT_TITLE,
        theme: "warning"
      });
      if (!ok) {
        return;
      }
    }
    clearDraft(this.storeKey);
    await this.load(false);
  }

  // ---------------------------------------------------------------- 로드·초안
  get storeKey() {
    return draftKey(USER_ID, this.gridKey, this.recordId);
  }

  async load(offerDraft) {
    this.isLoading = true;
    this.loadError = undefined;
    try {
      const view = await loadGrid({
        gridKey: this.gridKey,
        parentId: this.recordId
      });
      this.applyView(view);
      if (offerDraft && view.editable && !this.isPhone) {
        await this.offerDraft();
      }
    } catch (e) {
      this.view = undefined;
      this.loadError = e?.body?.message || LOAD_ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  applyView(view) {
    this.view = view;
    this.baseRows = (view?.rows ?? []).map((r) => ({ ...r, [KEY]: r.Id }));
    this.newRows = [];
    this.draftValues = [];
    this.deleted = [];
    this.pasteErrors = {};
    this.clientErrors = {};
    this.serverErrors = {};
    this.gridErrors = [];
    this.selectedKeys = [];
    this.conflict = false;
    this.errorsOnly = false;
    if (!view?.scheduleStartField) {
      this.showSchedule = false;
    }
  }

  /** 저장하지 않은 초안이 있으면 복원 여부를 묻는다(BR-2, AC-8). 없어진 행의 초안은 버린다. */
  async offerDraft() {
    const draft = loadDraft(this.storeKey);
    const count = draft ? this.changedKeysOf(draft).size : 0;
    if (!count) {
      if (draft) {
        clearDraft(this.storeKey);
      }
      return;
    }
    const ok = await LightningConfirm.open({
      message: format(DRAFT_RESTORE, count),
      label: DRAFT_TITLE,
      theme: "warning"
    });
    if (!ok) {
      clearDraft(this.storeKey);
      return;
    }
    const newRows = this.view.allowAdd ? (draft.newRows ?? []) : [];
    const keys = new Set([
      ...this.baseRows.map((r) => r[KEY]),
      ...newRows.map((r) => r[KEY])
    ]);
    this.newRows = newRows;
    this.draftValues = (draft.draftValues ?? []).filter((d) =>
      keys.has(d[KEY])
    );
    this.deleted = (draft.deleted ?? []).filter((k) => keys.has(k));
    this.pasteErrors = draft.pasteErrors ?? {};
    this.labelCache = draft.labelCache ?? {};
    this.newSeq = newRows.reduce(
      (n, r) =>
        Math.max(n, Number(String(r[KEY]).slice(NEW_PREFIX.length)) || 0),
      0
    );
  }

  changedKeysOf(state) {
    const keys = new Set();
    (state.draftValues ?? []).forEach((d) => keys.add(d[KEY]));
    (state.newRows ?? []).forEach((r) => keys.add(r[KEY]));
    (state.deleted ?? []).forEach((k) => keys.add(k));
    return keys;
  }

  persist() {
    if (!this.view?.editable) {
      return;
    }
    if (this.isDirty) {
      saveDraft(this.storeKey, {
        draftValues: this.draftValues,
        newRows: this.newRows,
        deleted: this.deleted,
        pasteErrors: this.pasteErrors,
        labelCache: this.labelCache
      });
    } else {
      clearDraft(this.storeKey);
    }
  }

  // ---------------------------------------------------------------- 화면 상태
  get isPhone() {
    return FORM_FACTOR === "Small";
  }

  get hasView() {
    return !!this.view && !this.isLoading;
  }

  get showDesktop() {
    return this.hasView && !this.isPhone;
  }

  get showPhone() {
    return this.hasView && this.isPhone;
  }

  get isEditable() {
    return !!this.view?.editable;
  }

  get isReadOnly() {
    return !!this.view && !this.view.editable;
  }

  get changedKeys() {
    return this.changedKeysOf(this);
  }

  get isDirty() {
    return this.changedKeys.size > 0;
  }

  get changeText() {
    const n = this.changedKeys.size;
    return n ? format(CHANGE_COUNT, n) : "";
  }

  get saveDisabled() {
    return !this.isDirty || this.isSaving;
  }

  get cancelDisabled() {
    return !this.isDirty || this.isSaving;
  }

  get hasSchedule() {
    return !!(this.view?.scheduleStartField && this.view?.scheduleEndField);
  }

  get scheduleLabel() {
    return this.showSchedule ? BTN_TABLE : BTN_SCHEDULE;
  }

  get hideCheckbox() {
    return !(this.view?.allowDelete || this.view?.allowPaste);
  }

  get truncatedText() {
    return this.view?.truncated ? format(TRUNCATED, this.view.maxRows) : "";
  }

  get emptyText() {
    if (!this.view || this.baseRows.length || this.newRows.length) {
      return "";
    }
    return this.view.editable ? EMPTY : EMPTY_READ_ONLY;
  }

  get rowErrors() {
    const out = {};
    const add = (key, e) => {
      const cur = out[key] ?? { messages: [], fieldNames: [] };
      e.messages.forEach(
        (m) => !cur.messages.includes(m) && cur.messages.push(m)
      );
      e.fieldNames.forEach(
        (f) => !cur.fieldNames.includes(f) && cur.fieldNames.push(f)
      );
      out[key] = cur;
    };
    Object.entries(this.pasteErrorMap).forEach(([k, e]) => add(k, e));
    Object.entries(this.clientErrors).forEach(([k, e]) => add(k, e));
    Object.entries(this.serverErrors).forEach(([k, e]) => add(k, e));
    return out;
  }

  get pasteErrorMap() {
    const out = {};
    Object.entries(this.pasteErrors).forEach(([key, fields]) => {
      const names = Object.keys(fields ?? {});
      if (names.length) {
        out[key] = {
          fieldNames: names,
          messages: names.map((f) => format(PASTE_CELL_ERROR, fields[f]))
        };
      }
    });
    return out;
  }

  get errorCount() {
    return Object.keys(this.rowErrors).length + this.gridErrors.length;
  }

  get errorText() {
    return this.errorCount ? format(ERROR_COUNT, this.errorCount) : "";
  }

  get tableErrors() {
    const rows = {};
    Object.entries(this.rowErrors).forEach(([key, e]) => {
      rows[key] = {
        title: ROW_ERROR_TITLE,
        messages: e.messages,
        fieldNames: e.fieldNames
      };
    });
    const out = { rows };
    if (this.gridErrors.length) {
      out.table = { title: TABLE_ERROR_TITLE, messages: this.gridErrors };
    }
    return out;
  }

  get locale() {
    return LOCALE;
  }

  get scrollClass() {
    return this.baseRows.length + this.newRows.length > SCROLL_ROWS
      ? "grid-scroll"
      : "";
  }

  // ---------------------------------------------------------------- 열·행
  get dataColumns() {
    const cols = this.view?.columns ?? [];
    // 가로 스크롤 고정 열(Frozen)은 앞에 둔다(표준 표는 열 고정이 없어 앞쪽 배치로 대신한다)
    return [...cols.filter((c) => c.frozen), ...cols.filter((c) => !c.frozen)];
  }

  get editableColumns() {
    return this.dataColumns.filter((c) => c.editable);
  }

  get tableColumns() {
    const cols = this.dataColumns;
    const weights = cols.reduce((s, c) => s + (c.widthWeight || 2), 2);
    const unit = this.hostWidth ? this.hostWidth / weights : 0;
    const width = (w) => {
      return unit ? Math.max(80, Math.round(unit * w)) : undefined;
    };
    const out = [
      {
        label: COL_STATE,
        fieldName: "__stateText",
        type: "cmnRowState",
        typeAttributes: {
          icon: { fieldName: "__stateIcon" },
          warning: { fieldName: "__warning" }
        },
        hideDefaultActions: true,
        initialWidth: width(2)
      }
    ];
    cols.forEach((c) => out.push(this.columnDef(c, width(c.widthWeight || 2))));
    return out;
  }

  columnDef(c, initialWidth) {
    const f = c.fieldApiName;
    const def = {
      label: c.required && c.editable ? `${c.label} *` : c.label,
      fieldName: f,
      editable: c.editable ? { fieldName: `__ed_${f}` } : false,
      hideDefaultActions: true
    };
    if (initialWidth) {
      def.initialWidth = initialWidth;
    }
    switch (c.inputType) {
      case "NUMBER":
        def.type = "number";
        def.typeAttributes = {
          minimumFractionDigits: 0,
          maximumFractionDigits: c.scale ?? 2
        };
        break;
      case "DATE":
        def.type = "date-local";
        def.typeAttributes = {
          year: "numeric",
          month: "2-digit",
          day: "2-digit"
        };
        break;
      case "CHECKBOX":
        def.type = "boolean";
        break;
      case "PICKLIST":
        def.type = "cmnPicklist";
        def.typeAttributes = {
          options: c.options ?? [],
          fieldLabel: c.label,
          required: c.required
        };
        break;
      case "LOOKUP":
        def.type = "cmnLookup";
        def.typeAttributes = {
          display: { fieldName: `__d_${f}` },
          referenceTo: c.referenceTo,
          filter: c.lookupFilter ?? [],
          fieldLabel: c.label,
          required: c.required
        };
        break;
      case "CODE":
        def.type = "cmnCode";
        def.typeAttributes = {
          display: { fieldName: `__d_${f}` },
          codeGroup: c.codeGroup,
          fieldLabel: c.label,
          required: c.required
        };
        break;
      default:
        def.type = "text";
    }
    return def;
  }

  get draftsByKey() {
    const out = new Map();
    this.draftValues.forEach((d) => out.set(d[KEY], d));
    return out;
  }

  get allRows() {
    return [...this.baseRows, ...this.newRows];
  }

  get tableData() {
    const drafts = this.draftsByKey;
    const errors = this.rowErrors;
    let rows = this.allRows.map((r) =>
      this.displayRow(r, drafts.get(r[KEY]), errors)
    );
    if (this.errorsOnly) {
      rows = rows.filter((r) => errors[r[KEY]]);
    }
    return rows;
  }

  stateOf(r, draft, errors) {
    const key = r[KEY];
    if (errors[key]) {
      return "ERROR";
    }
    if (this.deleted.includes(key)) {
      return "DELETED";
    }
    if (r.__isNew) {
      return "NEW";
    }
    if (draft) {
      return "CHANGED";
    }
    return r.__deletable === false ? "LOCKED" : "";
  }

  displayRow(r, draft, errors) {
    const key = r[KEY];
    const out = { ...r };
    const deleted = this.deleted.includes(key);
    const locked = new Set(r.__locked ?? []);
    this.dataColumns.forEach((c) => {
      const f = c.fieldApiName;
      out[`__ed_${f}`] = c.editable && !deleted && !locked.has(f);
      if (REFERENCE.has(c.inputType)) {
        const value = draft && f in draft ? draft[f] : r[f];
        const cached = value ? this.labelCache[f]?.[value] : undefined;
        out[`__d_${f}`] =
          cached ?? (value === r[f] ? r[`__d_${f}`] : undefined) ?? value ?? "";
      }
    });
    const state = this.stateOf(r, draft, errors);
    out.__stateText = STATE_TEXT[state] ?? "";
    out.__stateIcon = STATE_ICON[state];
    return out;
  }

  // ---------------------------------------------------------------- 편집
  handleCellChange(event) {
    const changes = event.detail?.draftValues ?? [];
    const drafts = new Map(this.draftsByKey);
    const pasteErrors = { ...this.pasteErrors };
    const clientErrors = { ...this.clientErrors };
    const serverErrors = { ...this.serverErrors };
    const lookups = {};
    changes.forEach((change) => {
      const key = change[KEY];
      drafts.set(key, { ...(drafts.get(key) ?? { [KEY]: key }), ...change });
      Object.keys(change)
        .filter((f) => f !== KEY)
        .forEach((f) => {
          if (pasteErrors[key]) {
            const rest = { ...pasteErrors[key] };
            delete rest[f];
            pasteErrors[key] = rest;
          }
          const col = this.dataColumns.find((c) => c.fieldApiName === f);
          const v = change[f];
          if (
            col &&
            REFERENCE.has(col.inputType) &&
            v &&
            !this.labelCache[f]?.[v]
          ) {
            lookups[f] = [...new Set([...(lookups[f] ?? []), v])];
          }
        });
      delete clientErrors[key];
      delete serverErrors[key];
    });
    this.draftValues = [...drafts.values()];
    this.pasteErrors = pasteErrors;
    this.clientErrors = clientErrors;
    this.serverErrors = serverErrors;
    this.persist();
    if (Object.keys(lookups).length) {
      this.resolveLabels(lookups);
    }
  }

  /** 셀 편집으로 고른 참조 레코드의 표시명(서버 1회). 실패하면 Id를 그대로 보인다. */
  async resolveLabels(byField) {
    try {
      const matches = await resolveLookups({
        gridKey: this.gridKey,
        parentId: this.recordId,
        keysJson: JSON.stringify(byField)
      });
      const cache = { ...this.labelCache };
      (matches ?? []).forEach((m) => {
        if (m.id) {
          cache[m.fieldApiName] = {
            ...(cache[m.fieldApiName] ?? {}),
            [m.key]: m.label
          };
        }
      });
      this.labelCache = cache;
      this.persist();
    } catch {
      // 표시명만 못 가져온 것이라 값(Id)은 그대로 저장할 수 있다
    }
  }

  handleRowSelection(event) {
    this.selectedKeys = (event.detail?.selectedRows ?? []).map((r) => r[KEY]);
  }

  newRow() {
    this.newSeq += 1;
    return {
      [KEY]: `${NEW_PREFIX}${this.newSeq}`,
      __isNew: true,
      __deletable: true,
      __locked: [],
      ...(this.view?.defaults ?? {})
    };
  }

  handleAddRow() {
    this.newRows = [...this.newRows, this.newRow()];
    this.persist();
  }

  /** 선택 행 삭제 표시(저장할 때 반영). 이미 삭제 표시된 행을 다시 누르면 되돌린다. 새 행은 바로 뺀다. */
  handleDelete() {
    if (!this.selectedKeys.length) {
      this.toast(SELECT_ROWS, "warning");
      return;
    }
    const selected = new Set(this.selectedKeys);
    const blocked = [];
    let deleted = [...this.deleted];
    this.baseRows
      .filter((r) => selected.has(r[KEY]))
      .forEach((r) => {
        const key = r[KEY];
        if (deleted.includes(key)) {
          deleted = deleted.filter((k) => k !== key);
        } else if (r.__deletable === false) {
          blocked.push(r.__deleteBlocked || DELETE_BLOCKED);
        } else {
          deleted.push(key);
        }
      });
    this.newRows = this.newRows.filter((r) => !selected.has(r[KEY]));
    this.draftValues = this.draftValues.filter(
      (d) => !(isNewKey(d[KEY]) && selected.has(d[KEY]))
    );
    this.deleted = deleted;
    this.selectedKeys = [];
    if (blocked.length) {
      this.toast(blocked[0], "warning");
    }
    this.persist();
  }

  handleCancel() {
    this.newRows = [];
    this.draftValues = [];
    this.deleted = [];
    this.pasteErrors = {};
    this.clientErrors = {};
    this.serverErrors = {};
    this.gridErrors = [];
    this.selectedKeys = [];
    this.errorsOnly = false;
    clearDraft(this.storeKey);
  }

  handleToggleSchedule() {
    this.showSchedule = !this.showSchedule;
  }

  handleErrorsOnly(event) {
    this.errorsOnly = event.detail?.checked ?? !this.errorsOnly;
  }

  handleRefreshClick() {
    return this.refresh();
  }

  /** 버전 충돌: 내 변경을 초안으로 남긴 채 최신 행을 읽고 복원 여부를 묻는다(덮어쓰지 않는다). */
  handleConflictRefresh() {
    this.persist();
    return this.load(true);
  }

  handleRefreshMessage(message) {
    if (
      message?.gridKey === this.gridKey &&
      sameId(message?.parentId, this.recordId)
    ) {
      return this.refresh();
    }
    return undefined;
  }

  // ---------------------------------------------------------------- 붙여넣기
  async handlePaste() {
    const keys = this.allRows.map((r) => r[KEY]);
    const startIndex = this.selectedKeys.length
      ? Math.min(
          ...this.selectedKeys.map((k) => keys.indexOf(k)).filter((i) => i >= 0)
        )
      : -1;
    const result = await CmnGridPasteDialog.open({
      size: "large",
      label: PASTE_TITLE,
      columns: this.dataColumns,
      maxRows: this.view.maxRows,
      canOverwrite: Number.isFinite(startIndex) && startIndex >= 0,
      locale: LOCALE,
      resolver: (keysByField) =>
        resolveLookups({
          gridKey: this.gridKey,
          parentId: this.recordId,
          keysJson: JSON.stringify(keysByField)
        })
    });
    if (result?.rows?.length) {
      this.applyPaste(result, startIndex);
    }
  }

  /** 붙여넣기 결과 반영: 새 행은 행 값으로, 기존 행은 초안으로. 변환 실패 셀은 빈 값 + 오류(BR-3). */
  applyPaste(result, startIndex) {
    const all = this.allRows;
    const drafts = new Map(this.draftsByKey);
    const newRows = [...this.newRows];
    const pasteErrors = { ...this.pasteErrors };
    const cache = { ...this.labelCache };
    result.rows.forEach((p, i) => {
      let target = result.mode === "overwrite" ? all[startIndex + i] : null;
      if (!target) {
        if (!this.view.allowAdd) {
          return;
        }
        target = this.newRow();
        newRows.push(target);
      }
      const key = target[KEY];
      if (this.deleted.includes(key)) {
        return;
      }
      const isNew = !!target.__isNew;
      if (isNew) {
        // 새 행은 행 값을 바로 바꾼다(반응형 갱신을 위해 복사본으로 바꿔 끼운다)
        const index = newRows.findIndex((r) => r[KEY] === key);
        target = { ...target };
        newRows[index] = target;
      }
      const locked = new Set(target.__locked ?? []);
      const draft = { ...(drafts.get(key) ?? { [KEY]: key }) };
      const rowErrors = { ...(pasteErrors[key] ?? {}) };
      Object.entries(p.cells ?? {}).forEach(([f, cell]) => {
        if (locked.has(f)) {
          return;
        }
        const value = cell.error ? null : cell.value;
        if (isNew) {
          target[f] = value;
        } else {
          draft[f] = value ?? "";
        }
        if (cell.error) {
          rowErrors[f] = cell.raw;
        } else {
          delete rowErrors[f];
        }
        if (cell.label && !isBlank(value)) {
          cache[f] = { ...(cache[f] ?? {}), [value]: cell.label };
        }
      });
      if (!isNew && Object.keys(draft).length > 1) {
        drafts.set(key, draft);
      }
      pasteErrors[key] = rowErrors;
    });
    this.newRows = newRows;
    this.draftValues = [...drafts.values()];
    this.pasteErrors = pasteErrors;
    this.labelCache = cache;
    this.persist();
  }

  // ---------------------------------------------------------------- 저장
  /** 화면 검증(필수·숫자 형식·잠긴 셀·붙여넣기 변환 오류). 업무 검증은 서버 Provider가 한다(BR-4). */
  validateClient() {
    const errors = {};
    const add = (key, f, message) => {
      const e = errors[key] ?? { messages: [], fieldNames: [] };
      if (!e.messages.includes(message)) {
        e.messages.push(message);
      }
      if (!e.fieldNames.includes(f)) {
        e.fieldNames.push(f);
      }
      errors[key] = e;
    };
    const drafts = this.draftsByKey;
    this.allRows
      .filter(
        (r) =>
          !this.deleted.includes(r[KEY]) && (r.__isNew || drafts.has(r[KEY]))
      )
      .forEach((r) => {
        const key = r[KEY];
        const draft = drafts.get(key) ?? {};
        const locked = new Set(r.__locked ?? []);
        this.editableColumns.forEach((c) => {
          const f = c.fieldApiName;
          const v = f in draft ? draft[f] : r[f];
          if (c.required && isBlank(v)) {
            add(key, f, format(REQUIRED_MISSING, c.label));
          } else if (
            c.inputType === "NUMBER" &&
            !isBlank(v) &&
            !Number.isFinite(Number(v))
          ) {
            add(key, f, format(INVALID_VALUE, c.label));
          }
          if (f in draft && locked.has(f)) {
            add(key, f, format(CELL_LOCKED, c.label));
          }
        });
      });
    return errors;
  }

  payloadRows() {
    const drafts = this.draftsByKey;
    const editable = new Set(this.editableColumns.map((c) => c.fieldApiName));
    const out = [];
    this.newRows
      .filter((r) => !this.deleted.includes(r[KEY]))
      .forEach((r) => {
        const draft = drafts.get(r[KEY]) ?? {};
        const values = {};
        editable.forEach((f) => {
          const v = f in draft ? draft[f] : r[f];
          if (!isBlank(v)) {
            values[f] = v;
          }
        });
        out.push({ key: r[KEY], values });
      });
    this.baseRows
      .filter((r) => !this.deleted.includes(r[KEY]) && drafts.has(r[KEY]))
      .forEach((r) => {
        const draft = drafts.get(r[KEY]);
        const values = {};
        Object.keys(draft)
          .filter((f) => editable.has(f))
          .forEach((f) => {
            values[f] = draft[f];
          });
        if (Object.keys(values).length) {
          out.push({ key: r[KEY], id: r.Id, values });
        }
      });
    return out;
  }

  async handleSave() {
    if (!this.isDirty) {
      this.toast(NOTHING_TO_SAVE, "info");
      return;
    }
    const errors = this.validateClient();
    this.clientErrors = errors;
    this.serverErrors = {};
    this.gridErrors = [];
    if (Object.keys(errors).length || Object.keys(this.pasteErrorMap).length) {
      this.toast(FIX_ERRORS, "error");
      return;
    }
    this.isSaving = true;
    try {
      const result = await saveGrid({
        gridKey: this.gridKey,
        parentId: this.recordId,
        rowsJson: JSON.stringify(this.payloadRows()),
        deletedIds: this.deleted.filter((k) => !isNewKey(k)),
        clientVersion: this.view.clientVersion
      });
      if (result?.success) {
        clearDraft(this.storeKey);
        this.applyView(result.view);
        this.toast(
          format(SAVED, result.savedCount ?? 0, result.deletedCount ?? 0),
          "success"
        );
        return;
      }
      this.conflict = result?.conflict === true;
      const server = {};
      (result?.rowErrors ?? []).forEach((e) => {
        server[e.key] = {
          messages: e.messages ?? [],
          fieldNames: e.fieldNames ?? []
        };
      });
      this.serverErrors = server;
      this.gridErrors = result?.gridErrors ?? [];
      if (!this.conflict) {
        this.toast(this.gridErrors[0] || FIX_ERRORS, "error");
      }
    } catch (e) {
      this.gridErrors = [e?.body?.message || SAVE_FAILED];
      this.toast(this.gridErrors[0], "error");
    } finally {
      this.isSaving = false;
    }
  }

  // ---------------------------------------------------------------- 일정·휴대폰
  get scheduleRows() {
    const view = this.view;
    if (!view?.scheduleStartField) {
      return [];
    }
    const nameCol =
      this.dataColumns.find((c) => c.isNameField) ??
      this.dataColumns.find((c) => c.inputType === "TEXT");
    const drafts = this.draftsByKey;
    return this.allRows.map((r) => {
      const draft = drafts.get(r[KEY]) ?? {};
      const pick = (f) => (f in draft ? draft[f] : r[f]);
      return {
        key: r[KEY],
        label: nameCol ? pick(nameCol.fieldApiName) : "",
        start: pick(view.scheduleStartField),
        end: pick(view.scheduleEndField),
        warning: r.__warning,
        deleted: this.deleted.includes(r[KEY])
      };
    });
  }

  get phoneCards() {
    const cols = this.dataColumns.filter((c) => c.showOnPhone).slice(0, 4);
    return this.baseRows.map((r) => {
      const fields = cols.map((c) => ({
        labelKey: `${r[KEY]}-${c.fieldApiName}-l`,
        valueKey: `${r[KEY]}-${c.fieldApiName}-v`,
        label: c.label,
        text: this.formatValue(c, r)
      }));
      return {
        key: r[KEY],
        id: r.Id,
        title: fields[0]?.text || PHONE_OPEN,
        fields: fields.slice(1),
        warning: r.__warning
      };
    });
  }

  formatValue(c, r) {
    const v = r[c.fieldApiName];
    if (isBlank(v)) {
      return "";
    }
    switch (c.inputType) {
      case "LOOKUP":
      case "CODE":
        return r[`__d_${c.fieldApiName}`] ?? String(v);
      case "PICKLIST":
        return (c.options ?? []).find((o) => o.value === v)?.label ?? String(v);
      case "CHECKBOX":
        return v ? "✓" : "";
      case "DATE": {
        const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(v);
        return m
          ? new Intl.DateTimeFormat(LOCALE).format(
              new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]))
            )
          : String(v);
      }
      case "NUMBER":
        return new Intl.NumberFormat(LOCALE).format(Number(v));
      default:
        return String(v);
    }
  }

  handleOpenCard(event) {
    const id = event.currentTarget?.dataset?.id;
    if (!id) {
      return;
    }
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: id,
        objectApiName: this.view?.objectApiName,
        actionName: "view"
      }
    });
  }

  toast(message, variant) {
    this.dispatchEvent(new ShowToastEvent({ message, variant }));
  }
}
