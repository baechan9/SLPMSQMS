import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import OVERDUE from "@salesforce/label/c.CMN_DueIndicator_Overdue";
import TODAY from "@salesforce/label/c.CMN_DueIndicator_Today";
import DAYS_LEFT from "@salesforce/label/c.CMN_DueIndicator_DaysLeft";
import NO_DUE from "@salesforce/label/c.CMN_DueIndicator_NoDue";

const SOON_DAYS = 3;

/**
 * 업무 레코드 기한 표시(CMN-00-UX-004 BR-4). 하이라이트 패널은 수식 숫자만 보여 주므로,
 * 하위 헤더에서 D-day를 아이콘과 문구(기한 경과 n일 / 오늘 마감 / n일 남음)로 보인다. 색만으로 구분하지 않는다.
 * 단일 레코드 조회이고 서버 업무 규칙이 없어 LDS(getRecord)를 쓴다.
 */
export default class CmnDueIndicator extends LightningElement {
  @api recordId;
  @api objectApiName;
  /** D-day 수식 필드(기한 - 오늘) */
  @api daysField = "DaysToDue__c";

  record;

  get optionalFields() {
    return this.objectApiName && this.daysField
      ? [`${this.objectApiName}.${this.daysField}`]
      : undefined;
  }

  @wire(getRecord, { recordId: "$recordId", optionalFields: "$optionalFields" })
  wiredRecord({ data, error }) {
    this.record = error ? undefined : data;
  }

  get days() {
    const raw = this.record?.fields?.[this.daysField]?.value;
    return raw === null || raw === undefined ? null : Number(raw);
  }

  get state() {
    const d = this.days;
    if (d === null || Number.isNaN(d)) {
      return "none";
    }
    if (d < 0) {
      return "overdue";
    }
    if (d === 0) {
      return "today";
    }
    return d <= SOON_DAYS ? "soon" : "normal";
  }

  get text() {
    switch (this.state) {
      case "overdue":
        return OVERDUE.replace("{0}", Math.abs(this.days));
      case "today":
        return TODAY;
      case "none":
        return NO_DUE;
      default:
        return DAYS_LEFT.replace("{0}", this.days);
    }
  }

  get iconName() {
    switch (this.state) {
      case "overdue":
        return "utility:warning";
      case "today":
      case "soon":
        return "utility:clock";
      default:
        return "utility:event";
    }
  }

  get iconVariant() {
    return this.state === "overdue"
      ? "error"
      : this.state === "normal" || this.state === "none"
        ? null
        : "warning";
  }

  get textClass() {
    return this.state === "overdue"
      ? "slds-text-color_error slds-text-title_bold"
      : "slds-text-body_regular";
  }
}
