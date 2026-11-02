import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import getPath from "@salesforce/apex/CMN_StatusPathController.getPath";
import TITLE from "@salesforce/label/c.CMN_StatusPath_Title";
import NOT_CONFIGURED from "@salesforce/label/c.CMN_StatusPath_NotConfigured";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

/**
 * 상태 진행바(CMN-00-UX-003 BR-1).
 * 흐름 정의(단계·라벨)는 Apex(설정, 캐시), 현재 상태 값은 LDS getRecord로 읽어 업무 버튼·결재로 상태가 바뀌면 바로 반영한다.
 * 표시: 종료가 아닌 단계 전부 + 종료 칸 하나. 현재가 종료 상태면 그 상태, 아니면 순서가 가장 앞선 종료 단계(정상 완료).
 * 정상 완료가 아닌 종료(반려·취소 등)는 오류 표시. 단계를 눌러도 상태는 바뀌지 않는다.
 */
export default class CmnStatusPath extends LightningElement {
  @api recordId;
  @api objectApiName;

  labels = { title: TITLE, notConfigured: NOT_CONFIGURED, loading: LOADING };
  path;
  pathLoaded = false;
  current;
  errorMessage;

  @wire(getPath, { recordId: "$recordId" })
  wiredPath({ data, error }) {
    if (data !== undefined) {
      this.path = data;
      this.pathLoaded = true;
      this.errorMessage = undefined;
    } else if (error) {
      this.pathLoaded = true;
      this.errorMessage = ERROR;
    }
  }

  get fields() {
    return this.path
      ? [`${this.path.objectApiName}.${this.path.statusField}`]
      : undefined;
  }

  @wire(getRecord, { recordId: "$recordId", fields: "$fields" })
  wiredRecord({ data, error }) {
    if (data) {
      this.current = data.fields?.[this.path.statusField]?.value ?? undefined;
    } else if (error) {
      this.errorMessage = ERROR;
    }
  }

  get isLoading() {
    return !this.pathLoaded;
  }

  get isNotConfigured() {
    return this.pathLoaded && !this.errorMessage && !this.path;
  }

  get hasPath() {
    return !this.errorMessage && this.path && this.visibleSteps.length > 0;
  }

  get terminals() {
    return (this.path?.steps ?? []).filter((s) => s.isTerminal);
  }

  get visibleSteps() {
    const steps = this.path?.steps ?? [];
    const open = steps.filter((s) => !s.isTerminal);
    const terminals = this.terminals;
    const currentTerminal = terminals.find((s) => s.value === this.current);
    const end = currentTerminal ?? terminals[0];
    return end ? [...open, end] : open;
  }

  get currentStep() {
    return this.visibleSteps.some((s) => s.value === this.current)
      ? this.current
      : undefined;
  }

  get hasError() {
    const terminals = this.terminals;
    return (
      terminals.length > 0 &&
      this.current !== terminals[0].value &&
      terminals.some((s) => s.value === this.current)
    );
  }
}
