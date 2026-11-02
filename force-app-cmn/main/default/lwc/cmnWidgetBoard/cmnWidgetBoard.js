import { LightningElement, api } from "lwc";
import LightningConfirm from "lightning/confirm";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getBoard from "@salesforce/apex/CMN_DashboardController.getBoard";
import saveBoard from "@salesforce/apex/CMN_DashboardController.saveBoard";
import resetBoard from "@salesforce/apex/CMN_DashboardController.resetBoard";
import getGallery from "@salesforce/apex/CMN_DashboardController.getGallery";
import TITLE from "@salesforce/label/c.CMN_WidgetBoard_Title";
import EDIT from "@salesforce/label/c.CMN_WidgetBoard_Edit";
import SAVE from "@salesforce/label/c.CMN_WidgetBoard_Save";
import CANCEL from "@salesforce/label/c.CMN_WidgetBoard_Cancel";
import RESET from "@salesforce/label/c.CMN_WidgetBoard_Reset";
import RESET_CONFIRM from "@salesforce/label/c.CMN_WidgetBoard_ResetConfirm";
import ADD_WIDGET from "@salesforce/label/c.CMN_WidgetBoard_AddWidget";
import GALLERY_EMPTY from "@salesforce/label/c.CMN_WidgetBoard_GalleryEmpty";
import REMOVE from "@salesforce/label/c.CMN_WidgetBoard_Remove";
import MOVE_UP from "@salesforce/label/c.CMN_WidgetBoard_MoveUp";
import MOVE_DOWN from "@salesforce/label/c.CMN_WidgetBoard_MoveDown";
import SIZE from "@salesforce/label/c.CMN_WidgetBoard_Size";
import SIZE_S from "@salesforce/label/c.CMN_WidgetBoard_SizeS";
import SIZE_M from "@salesforce/label/c.CMN_WidgetBoard_SizeM";
import SIZE_L from "@salesforce/label/c.CMN_WidgetBoard_SizeL";
import SETTINGS from "@salesforce/label/c.CMN_WidgetBoard_Settings";
import CONFIG_JSON from "@salesforce/label/c.CMN_WidgetBoard_ConfigJson";
import APPLY from "@salesforce/label/c.CMN_WidgetBoard_Apply";
import PLANT from "@salesforce/label/c.CMN_WidgetBoard_Plant";
import PERIOD from "@salesforce/label/c.CMN_WidgetBoard_Period";
import PERIOD_ALL from "@salesforce/label/c.CMN_WidgetBoard_PeriodAll";
import PERIOD_30 from "@salesforce/label/c.CMN_WidgetBoard_Period30";
import PERIOD_90 from "@salesforce/label/c.CMN_WidgetBoard_Period90";
import PERIOD_365 from "@salesforce/label/c.CMN_WidgetBoard_Period365";
import EMPTY from "@salesforce/label/c.CMN_WidgetBoard_Empty";
import SAVED from "@salesforce/label/c.CMN_WidgetBoard_Saved";
import INVALID_CONFIG from "@salesforce/label/c.CMN_WidgetBoard_InvalidConfig";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

const COLUMNS = { S: 4, M: 6, L: 12 };
let seq = 0;

/**
 * 위젯 대시보드(CMN-00-DSH-001). 12열 그리드(S 4열·M 6열·L 12열, 모바일은 모두 12열 — BR-1).
 * 처음 열면 서버가 역할 템플릿을 복사해 둔다(BR-3, AC-1). 편집은 사본에서 하고 저장해야 반영된다(AC-2).
 */
export default class CmnWidgetBoard extends LightningElement {
  @api systemCode = "QMS";

  labels = {
    title: TITLE,
    edit: EDIT,
    save: SAVE,
    cancel: CANCEL,
    reset: RESET,
    addWidget: ADD_WIDGET,
    galleryEmpty: GALLERY_EMPTY,
    remove: REMOVE,
    moveUp: MOVE_UP,
    moveDown: MOVE_DOWN,
    size: SIZE,
    settings: SETTINGS,
    configJson: CONFIG_JSON,
    apply: APPLY,
    plant: PLANT,
    period: PERIOD,
    empty: EMPTY,
    loading: LOADING
  };
  sizeOptions = [
    { label: SIZE_S, value: "S" },
    { label: SIZE_M, value: "M" },
    { label: SIZE_L, value: "L" }
  ];
  periodOptions = [
    { label: PERIOD_ALL, value: "" },
    { label: PERIOD_30, value: "LAST_30_DAYS" },
    { label: PERIOD_90, value: "LAST_90_DAYS" },
    { label: PERIOD_365, value: "LAST_365_DAYS" }
  ];
  items = [];
  draft = [];
  gallery = [];
  selectedWidget;
  isEditing = false;
  isLoading = true;
  isSaving = false;
  errorMessage;
  filters = { plantId: null, period: "" };

  connectedCallback() {
    this.run(() => getBoard({ systemCode: this.systemCode }));
  }

  async run(call, message) {
    this.isSaving = true;
    try {
      const view = await call();
      this.items = this.decorate(view?.items ?? []);
      this.errorMessage = undefined;
      this.isEditing = false;
      if (message) {
        this.toast(message, "success");
      }
    } catch (e) {
      const text = e?.body?.message || ERROR;
      if (this.isLoading) {
        this.errorMessage = text;
      } else {
        this.toast(text, "error");
      }
    } finally {
      this.isLoading = false;
      this.isSaving = false;
    }
  }

  decorate(rows) {
    return rows.map((w, index, all) => {
      seq += 1;
      const item = { ...w, key: w.key ?? `${w.widgetKey}-${seq}` };
      return this.withLayout(item, index, all.length);
    });
  }

  withLayout(item, index, count) {
    const cols = COLUMNS[item.size] ?? 6;
    return {
      ...item,
      cls: `slds-col slds-size_1-of-1 slds-medium-size_${cols}-of-12 slds-p-bottom_small`,
      isFirst: index === 0,
      isLast: index === count - 1,
      showConfig: item.showConfig ?? false,
      configDraft: item.configDraft ?? item.configJson
    };
  }

  relayout(list) {
    return list.map((item, index) => this.withLayout(item, index, list.length));
  }

  get shown() {
    return this.isEditing ? this.draft : this.items;
  }

  get isEmpty() {
    return !this.isLoading && !this.errorMessage && this.shown.length === 0;
  }

  get galleryOptions() {
    return this.gallery.map((g) => ({ label: g.title, value: g.widgetKey }));
  }

  get hasGallery() {
    return this.gallery.length > 0;
  }

  get addDisabled() {
    return !this.selectedWidget;
  }

  // ------------------------------------------------------------ 공통 필터(BR-6)
  handlePlant(event) {
    this.filters = { ...this.filters, plantId: event.detail.recordId ?? null };
  }

  handlePeriod(event) {
    this.filters = { ...this.filters, period: event.detail.value ?? "" };
  }

  // ------------------------------------------------------------ 편집
  async handleEdit() {
    this.draft = this.relayout(this.items.map((i) => ({ ...i })));
    this.isEditing = true;
    try {
      this.gallery = (await getGallery({ systemCode: this.systemCode })) ?? [];
    } catch (e) {
      this.gallery = [];
      this.toast(e?.body?.message || ERROR, "error");
    }
  }

  handleCancel() {
    this.isEditing = false;
    this.draft = [];
  }

  handleSelectWidget(event) {
    this.selectedWidget = event.detail.value;
  }

  handleAdd() {
    const g = this.gallery.find((w) => w.widgetKey === this.selectedWidget);
    if (!g) {
      return;
    }
    seq += 1;
    this.draft = this.relayout([
      ...this.draft,
      {
        key: `${g.widgetKey}-${seq}`,
        widgetKey: g.widgetKey,
        componentName: g.componentName,
        title: g.title,
        size: g.defaultSize,
        configJson: g.defaultConfigJson,
        state: "OK",
        hasSchema: g.hasSchema,
        mobileSupported: g.mobileSupported
      }
    ]);
    this.selectedWidget = undefined;
  }

  indexOf(event) {
    return this.draft.findIndex(
      (i) => i.key === event.currentTarget.dataset.key
    );
  }

  handleRemove(event) {
    const index = this.indexOf(event);
    this.draft = this.relayout(this.draft.filter((_, i) => i !== index));
  }

  handleMove(event) {
    const index = this.indexOf(event);
    const target = index + (event.currentTarget.dataset.dir === "up" ? -1 : 1);
    if (index < 0 || target < 0 || target >= this.draft.length) {
      return;
    }
    const list = [...this.draft];
    [list[index], list[target]] = [list[target], list[index]];
    this.draft = this.relayout(list);
  }

  handleSize(event) {
    const index = this.indexOf(event);
    const list = [...this.draft];
    list[index] = { ...list[index], size: event.detail.value };
    this.draft = this.relayout(list);
  }

  handleToggleConfig(event) {
    const index = this.indexOf(event);
    const list = [...this.draft];
    list[index] = { ...list[index], showConfig: !list[index].showConfig };
    this.draft = this.relayout(list);
  }

  handleConfigInput(event) {
    const index = this.indexOf(event);
    const list = [...this.draft];
    list[index] = { ...list[index], configDraft: event.detail.value };
    this.draft = list;
  }

  handleApplyConfig(event) {
    const index = this.indexOf(event);
    const item = this.draft[index];
    try {
      const parsed = JSON.parse(item.configDraft || "{}");
      if (
        parsed === null ||
        typeof parsed !== "object" ||
        Array.isArray(parsed)
      ) {
        throw new Error("not an object");
      }
      const list = [...this.draft];
      list[index] = {
        ...item,
        configJson: JSON.stringify(parsed),
        showConfig: false
      };
      this.draft = this.relayout(list);
    } catch {
      this.toast(INVALID_CONFIG.replace("{0}", item.title ?? ""), "error");
    }
  }

  handleSave() {
    const layout = this.draft.map((i, index) => ({
      widgetKey: i.widgetKey,
      size: i.size,
      order: index + 1,
      config: JSON.parse(i.configJson || "{}")
    }));
    this.run(
      () =>
        saveBoard({
          systemCode: this.systemCode,
          layoutJson: JSON.stringify(layout)
        }),
      SAVED
    );
  }

  async handleReset() {
    const ok = await LightningConfirm.open({
      message: RESET_CONFIRM,
      label: RESET
    });
    if (ok) {
      this.run(() => resetBoard({ systemCode: this.systemCode }));
    }
  }

  toast(message, variant) {
    this.dispatchEvent(new ShowToastEvent({ message, variant }));
  }
}
