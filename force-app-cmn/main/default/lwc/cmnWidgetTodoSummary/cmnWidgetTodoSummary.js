import { LightningElement, api } from "lwc";
import todoSummary from "@salesforce/apex/CMN_CoreWidgetController.todoSummary";
import TASK from "@salesforce/label/c.CMN_Widget_TodoSummary_Task";
import APPROVAL from "@salesforce/label/c.CMN_Widget_TodoSummary_Approval";
import OVERDUE from "@salesforce/label/c.CMN_Widget_TodoSummary_Overdue";
import RETRY from "@salesforce/label/c.CMN_WidgetBoard_Retry";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

/**
 * 내 To-Do 요약 위젯(CMN-00-DSH-001 기본 위젯, BR-4 계약: @api config·size, 실패는 위젯 안에서만 표시).
 */
export default class CmnWidgetTodoSummary extends LightningElement {
  @api size;
  _config;

  labels = {
    task: TASK,
    approval: APPROVAL,
    overdue: OVERDUE,
    retry: RETRY,
    loading: LOADING
  };
  data;
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
      this.data = await todoSummary({
        configJson: JSON.stringify(this._config ?? {})
      });
      this.errorMessage = undefined;
    } catch (e) {
      this.errorMessage = e?.body?.message || ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  get task() {
    return this.data?.task ?? 0;
  }

  get approval() {
    return this.data?.approval ?? 0;
  }

  get overdue() {
    return this.data?.overdue ?? 0;
  }

  get hasOverdue() {
    return this.overdue > 0;
  }
}
