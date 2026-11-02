import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import approvalSummary from "@salesforce/apex/CMN_CoreWidgetController.approvalSummary";
import TOTAL from "@salesforce/label/c.CMN_Widget_ApprovalPending_Total";
import DAYS from "@salesforce/label/c.CMN_Widget_ApprovalPending_Days";
import EMPTY from "@salesforce/label/c.CMN_Widget_ApprovalPending_Empty";
import RETRY from "@salesforce/label/c.CMN_WidgetBoard_Retry";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

/**
 * 내 결재 대기 위젯(CMN-00-DSH-001 기본 위젯). 오래 기다린 순, 결재 번호를 누르면 결재 요청(처리 화면)을 연다.
 */
export default class CmnWidgetApprovalPending extends NavigationMixin(
  LightningElement
) {
  @api size;
  _config;

  labels = { total: TOTAL, empty: EMPTY, retry: RETRY, loading: LOADING };
  total = 0;
  rows = [];
  isLoading = true;
  errorMessage;

  @api
  get config() {
    return this._config;
  }
  set config(value) {
    this._config = value;
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      const data = await approvalSummary({
        configJson: JSON.stringify(this._config ?? {})
      });
      this.total = data?.total ?? 0;
      this.rows = (data?.rows ?? []).map((r) => ({
        ...r,
        daysText:
          r.pendingDays == null ? "" : DAYS.replace("{0}", r.pendingDays)
      }));
      this.errorMessage = undefined;
    } catch (e) {
      this.errorMessage = e?.body?.message || ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  get isEmpty() {
    return this.rows.length === 0;
  }

  open(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.currentTarget.dataset.id,
        actionName: "view"
      }
    });
  }
}
