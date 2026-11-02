import { LightningElement, api } from "lwc";
import { getBarcodeScanner } from "lightning/mobileCapabilities";
import SCAN from "@salesforce/label/c.CMN_Barcode_Scan";
import MANUAL from "@salesforce/label/c.CMN_Barcode_Manual";
import SCAN_FAILED from "@salesforce/label/c.CMN_Barcode_Failed";

/**
 * 바코드·QR 스캔 공통 컴포넌트(CMN-00-UX-001 BR-5). Salesforce 모바일 앱이면 카메라 스캔 버튼, 아니면(웹) 수동 입력 칸을 보인다.
 * 결과는 `scan` 이벤트(detail: {value, type})로 부모에 알린다. 로트 라벨·측정기 QR·사원증 사번(검토 반영 Vol.6b)에 함께 쓴다.
 */
export default class CmnBarcodeScanner extends LightningElement {
  /** 입력 칸 라벨(부모가 업무에 맞게 지정) */
  @api label = MANUAL;
  /** 허용 바코드 유형(비우면 QR·Code128·Code39·EAN13·DataMatrix) */
  @api barcodeTypes;

  labels = { scan: SCAN };
  canScan = false;
  errorMessage;
  manualValue = "";
  scanner;

  connectedCallback() {
    this.scanner = getBarcodeScanner();
    this.canScan = this.scanner?.isAvailable() === true;
  }

  get types() {
    const t = this.scanner?.barcodeTypes ?? {};
    return this.barcodeTypes?.length
      ? this.barcodeTypes
      : [t.QR, t.CODE_128, t.CODE_39, t.EAN_13, t.DATA_MATRIX].filter(Boolean);
  }

  async handleScan() {
    this.errorMessage = undefined;
    try {
      const result = await this.scanner.beginCapture({
        barcodeTypes: this.types,
        instructionText: this.label
      });
      this.emit(result.value, result.type);
    } catch (e) {
      // 사용자가 취소하면 오류를 보이지 않는다
      if (e?.code !== "USER_DISMISSED") {
        this.errorMessage = SCAN_FAILED;
      }
    } finally {
      this.scanner.endCapture();
    }
  }

  handleManual(event) {
    this.manualValue = event.detail.value ?? "";
  }

  handleManualCommit() {
    const value = this.manualValue.trim();
    if (value) {
      this.emit(value, "MANUAL");
    }
  }

  handleKeyUp(event) {
    if (event.key === "Enter") {
      this.handleManualCommit();
    }
  }

  emit(value, type) {
    this.dispatchEvent(new CustomEvent("scan", { detail: { value, type } }));
  }
}
