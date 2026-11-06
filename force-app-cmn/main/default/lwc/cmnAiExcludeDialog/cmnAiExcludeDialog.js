import { api } from "lwc";
import LightningModal from "lightning/modal";
import TITLE from "@salesforce/label/c.CMN_AiRec_ExcludeTitle";
import REASON from "@salesforce/label/c.CMN_AiRec_ExcludeReason";
import CONFIRM from "@salesforce/label/c.CMN_AiRec_Exclude";
import CANCEL from "@salesforce/label/c.CMN_AiRec_Cancel";
import REQUIRED from "@salesforce/label/c.CMN_AiRec_ReasonRequired";

/** 제외 사유 공통 코드 그룹(AI-004 데이터 모델) */
const REASON_GROUP = "AI_EXCLUDE_REASON";

/**
 * AI 추천 제외 대화상자(CMN-00-AI-004 BR-3·AC-2). 사유(공통 코드 AI_EXCLUDE_REASON)를 골라야 닫힌다.
 * close 결과: { reasonId } 또는 취소면 undefined.
 */
export default class CmnAiExcludeDialog extends LightningModal {
  /** 제외할 추천 제목 */
  @api recommendationTitle;

  labels = {
    title: TITLE,
    reason: REASON,
    confirm: CONFIRM,
    cancel: CANCEL
  };
  reasonGroup = REASON_GROUP;
  reasonId;
  errorMessage;

  handleReason(event) {
    this.reasonId = event.detail?.value ?? undefined;
    this.errorMessage = undefined;
  }

  handleCancel() {
    this.close();
  }

  handleConfirm() {
    if (!this.reasonId) {
      this.errorMessage = REQUIRED;
      return;
    }
    this.close({ reasonId: this.reasonId });
  }
}
