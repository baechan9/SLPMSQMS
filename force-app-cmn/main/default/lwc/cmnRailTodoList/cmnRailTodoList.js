import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getOpenTodos from "@salesforce/apex/CMN_RailPanelController.getOpenTodos";
import EMPTY from "@salesforce/label/c.CMN_RailTodo_Empty";
import OVERDUE from "@salesforce/label/c.CMN_RailTodo_Overdue";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

/**
 * 결정 지원 레일 TODO 패널(CMN-00-UX-004 BR-6): 이 레코드에 걸린 열린 To-Do(누가 기다리는가).
 * 패널 계약을 지키고, 열린 건수를 railbadge로 알린다.
 */
export default class CmnRailTodoList extends NavigationMixin(LightningElement) {
  @api recordId;
  @api objectApiName;
  @api config;
  @api variant;

  labels = { empty: EMPTY, overdue: OVERDUE };
  items = [];
  errorMessage;
  loaded = false;

  @wire(getOpenTodos, { recordId: "$recordId" })
  wiredTodos({ data, error }) {
    if (data) {
      this.items = data;
      this.errorMessage = undefined;
      this.loaded = true;
      this.dispatchEvent(
        new CustomEvent("railbadge", {
          detail: {
            count: data.length,
            severity: data.some((t) => t.isOverdue) ? "warning" : "info"
          }
        })
      );
    } else if (error) {
      this.items = [];
      this.errorMessage = error?.body?.message || ERROR;
      this.loaded = true;
    }
  }

  get isEmpty() {
    return this.loaded && !this.errorMessage && this.items.length === 0;
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
