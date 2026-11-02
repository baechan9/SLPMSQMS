import { LightningElement, api } from "lwc";
import getHistory from "@salesforce/apex/CMN_ApprovalController.getHistory";
import TITLE from "@salesforce/label/c.CMN_ApprovalHistory_Title";
import VERSION from "@salesforce/label/c.CMN_ApprovalHistory_Version";
import EMPTY from "@salesforce/label/c.CMN_ApprovalHistory_Empty";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

/**
 * 결재 이력(CMN-00-APV-003 AC-2). 같은 대상의 모든 버전(재상신 포함)을 버전 순으로 나누어 보이고,
 * 버전 안에서는 단계 순으로 처리자(대결이면 "처리자(대결: 위임자)")·일시·의견을 보인다.
 */
export default class CmnApprovalHistory extends LightningElement {
  @api recordId;

  labels = { title: TITLE, empty: EMPTY, loading: LOADING };
  versions = [];
  isLoading = true;
  errorMessage;

  connectedCallback() {
    this.load();
  }

  @api
  async refresh() {
    await this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      const rows = await getHistory({ targetId: this.recordId });
      this.versions = (rows ?? []).map((v) => ({
        ...v,
        heading: `${VERSION.replace("{0}", v.version)} · ${v.recordNo ?? ""} · ${v.status}`
      }));
      this.errorMessage = undefined;
    } catch (e) {
      this.errorMessage = e?.body?.message || ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  get isEmpty() {
    return !this.isLoading && !this.errorMessage && this.versions.length === 0;
  }
}
