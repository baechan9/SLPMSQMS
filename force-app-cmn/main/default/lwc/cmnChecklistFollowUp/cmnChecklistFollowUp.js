import { api } from "lwc";
import LightningModal from "lightning/modal";
import TITLE from "@salesforce/label/c.CMN_Checklist_FollowUpTitle";
import FU_TITLE from "@salesforce/label/c.CMN_Checklist_FuTitle";
import FU_DESCRIPTION from "@salesforce/label/c.CMN_Checklist_FuDescription";
import FU_OWNER from "@salesforce/label/c.CMN_Checklist_FuOwner";
import FU_DUE from "@salesforce/label/c.CMN_Checklist_FuDue";
import FU_SEVERITY from "@salesforce/label/c.CMN_Checklist_FuSeverity";
import SEV_HIGH from "@salesforce/label/c.CMN_Checklist_SevHigh";
import SEV_MEDIUM from "@salesforce/label/c.CMN_Checklist_SevMedium";
import SEV_LOW from "@salesforce/label/c.CMN_Checklist_SevLow";
import CREATE from "@salesforce/label/c.CMN_Checklist_FuCreate";
import CANCEL from "@salesforce/label/c.CMN_Checklist_FuCancel";
import REQUIRED from "@salesforce/label/c.CMN_Checklist_FollowUpTitleRequired";

/**
 * 체크리스트 후속 조치 입력(CMN-00-UX-009 BR-5): 제목·내용·담당·기한·심각도.
 * 닫을 때 { title, description, ownerId, dueDate, severity }를 돌려준다(취소면 null). 생성은 화면이 Provider에 맡긴다.
 */
export default class CmnChecklistFollowUp extends LightningModal {
  /** 질문 번호·문구(머리글 아래 표시) */
  @api questionText;

  labels = {
    header: TITLE,
    title: FU_TITLE,
    description: FU_DESCRIPTION,
    owner: FU_OWNER,
    due: FU_DUE,
    severity: FU_SEVERITY,
    create: CREATE,
    cancel: CANCEL
  };
  title = "";
  description = "";
  ownerId;
  dueDate;
  severity = "MEDIUM";
  errorMessage;

  get severityOptions() {
    return [
      { label: SEV_HIGH, value: "HIGH" },
      { label: SEV_MEDIUM, value: "MEDIUM" },
      { label: SEV_LOW, value: "LOW" }
    ];
  }

  handleField(event) {
    const field = event.target.dataset.field;
    this[field] = event.detail?.value ?? event.detail?.recordId ?? null;
  }

  handleOwner(event) {
    this.ownerId = event.detail?.recordId ?? null;
  }

  handleCreate() {
    if (!this.title?.trim() || !this.dueDate) {
      this.errorMessage = REQUIRED;
      return;
    }
    this.close({
      title: this.title.trim(),
      description: this.description,
      ownerId: this.ownerId ?? null,
      dueDate: this.dueDate,
      severity: this.severity
    });
  }

  handleCancel() {
    this.close(null);
  }
}
