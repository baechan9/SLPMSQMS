import { api } from "lwc";
import LightningModal from "lightning/modal";
import compare from "@salesforce/apex/CMN_DocumentCompareController.compare";
import applySummary from "@salesforce/apex/CMN_DocumentCompareController.applySummary";
import TITLE from "@salesforce/label/c.CMN_DocCompare_Title";
import FROM_LABEL from "@salesforce/label/c.CMN_DocCompare_From";
import TO_LABEL from "@salesforce/label/c.CMN_DocCompare_To";
import RUN from "@salesforce/label/c.CMN_DocCompare_Run";
import SUMMARY from "@salesforce/label/c.CMN_DocCompare_Summary";
import CHANGES from "@salesforce/label/c.CMN_DocCompare_Changes";
import CELLS from "@salesforce/label/c.CMN_DocCompare_Cells";
import KIND from "@salesforce/label/c.CMN_DocCompare_Kind";
import SECTION from "@salesforce/label/c.CMN_DocCompare_Section";
import BEFORE from "@salesforce/label/c.CMN_DocCompare_Before";
import AFTER from "@salesforce/label/c.CMN_DocCompare_After";
import COLUMN from "@salesforce/label/c.CMN_DocCompare_Column";
import APPLY from "@salesforce/label/c.CMN_DocCompare_Apply";
import CLOSE from "@salesforce/label/c.CMN_DocCompare_Close";
import NO_CHANGES from "@salesforce/label/c.CMN_DocCompare_NoChanges";
import PICK_TWO from "@salesforce/label/c.CMN_DocCompare_PickTwo";
import AI_GENERATED from "@salesforce/label/c.CMN_Search_AiGenerated";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import UNEXPECTED from "@salesforce/label/c.CMN_Common_UnexpectedError";

const STATE_OK = "OK";

/**
 * 문서 버전 비교·변경 요약(CMN-00-AI-003). 문서 패널(cmnDocumentPanel)의 "버전 비교"에서 연다.
 * - 이전·이후 리비전을 고르면(기본: 바로 전 → 최신) 서버가 변경 목록·표 셀 비교·AI 요약을 돌려준다.
 * - 텍스트가 없는 형식은 "비교 불가"(AI 호출 없음), 엔진 미연결(A단계)은 "준비 중" 문구를 보인다.
 * - 요약은 고칠 수 있고 "변경 내용에 반영"으로 이후 리비전의 변경 내용이 된다(BR-2, 상세 기능 단계에서 동작).
 */
export default class CmnDocumentCompare extends LightningModal {
  @api documentName;

  labels = {
    title: TITLE,
    from: FROM_LABEL,
    to: TO_LABEL,
    run: RUN,
    summary: SUMMARY,
    changes: CHANGES,
    cells: CELLS,
    kind: KIND,
    section: SECTION,
    before: BEFORE,
    after: AFTER,
    column: COLUMN,
    apply: APPLY,
    close: CLOSE,
    noChanges: NO_CHANGES,
    aiGenerated: AI_GENERATED,
    loading: LOADING
  };
  fromId;
  toId;
  result;
  summaryText = "";
  isLoading = false;
  errorMessage;
  applyMessage;
  _revisions = [];

  /** [{id, label, revisionNo}] */
  @api
  get revisions() {
    return this._revisions;
  }
  set revisions(value) {
    this._revisions = [...(value ?? [])].sort(
      (a, b) => (b.revisionNo ?? 0) - (a.revisionNo ?? 0)
    );
    this.toId = this._revisions[0]?.id;
    this.fromId = this._revisions[1]?.id;
  }

  get options() {
    return this._revisions.map((r) => ({ label: r.label, value: r.id }));
  }

  get isOk() {
    return this.result?.state === STATE_OK;
  }

  get stateMessage() {
    return this.result && !this.isOk ? this.result.message : null;
  }

  get hasChanges() {
    return (this.result?.changes ?? []).length > 0;
  }

  get hasCells() {
    return (this.result?.cells ?? []).length > 0;
  }

  get showNoChanges() {
    return this.isOk && !this.hasChanges && !this.hasCells;
  }

  get isMock() {
    return this.result?.isMock === true;
  }

  get runDisabled() {
    return this.isLoading || !this.fromId || !this.toId;
  }

  handleFrom(event) {
    this.fromId = event.detail.value;
  }

  handleTo(event) {
    this.toId = event.detail.value;
  }

  handleSummary(event) {
    this.summaryText = event.detail?.value ?? event.target.value ?? "";
  }

  async runCompare() {
    if (!this.fromId || !this.toId || this.fromId === this.toId) {
      this.errorMessage = PICK_TWO;
      return;
    }
    this.isLoading = true;
    this.errorMessage = undefined;
    this.applyMessage = undefined;
    try {
      this.result = await compare({
        fromRevisionId: this.fromId,
        toRevisionId: this.toId
      });
      this.summaryText = this.result?.summary ?? "";
    } catch (error) {
      this.result = undefined;
      this.errorMessage = error?.body?.message || UNEXPECTED;
    } finally {
      this.isLoading = false;
    }
  }

  async handleApply() {
    this.applyMessage = undefined;
    try {
      await applySummary({ revisionId: this.toId, summary: this.summaryText });
      this.close({ applied: true });
    } catch (error) {
      // A단계: 서버가 "상세 기능 개발 단계에서 동작" 문구를 돌려준다
      this.applyMessage = error?.body?.message || UNEXPECTED;
    }
  }

  handleClose() {
    this.close();
  }
}
