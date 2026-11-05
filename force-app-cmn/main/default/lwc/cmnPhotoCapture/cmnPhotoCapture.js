import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { resizeImage } from "c/cmnImageResize";
import uploadPhotos from "@salesforce/apex/CMN_PhotoController.uploadPhotos";
import LABEL from "@salesforce/label/c.CMN_Photo_Label";
import UPLOADED from "@salesforce/label/c.CMN_Photo_Uploaded";
import TOO_MANY from "@salesforce/label/c.CMN_Photo_TooMany";
import PROCESSING from "@salesforce/label/c.CMN_Photo_Processing";
import ERROR from "@salesforce/label/c.CMN_Common_UnexpectedError";

const MAX_PHOTOS = 10;

/**
 * 모바일 사진 촬영·첨부(CMN-00-UX-001 BR-4, AC-1). 모바일 앱·모바일 웹에서는 카메라가 열리고(capture),
 * 데스크톱에서는 파일 선택이 열린다. 업로드 전에 장변 1920px JPEG로 줄인 뒤 서버가 문서(사진 분류)로 등록한다.
 */
export default class CmnPhotoCapture extends LightningElement {
  @api recordId;
  @api docClass = "NCR_PHOTO";

  labels = { label: LABEL, processing: PROCESSING };
  isBusy = false;

  async handleFiles(event) {
    const files = [...(event.target.files ?? [])];
    event.target.value = null;
    if (!files.length) {
      return;
    }
    if (files.length > MAX_PHOTOS) {
      this.toast(TOO_MANY.replace("{0}", MAX_PHOTOS), "error");
      return;
    }
    this.isBusy = true;
    try {
      const photos = [];
      for (const file of files) {
        // eslint-disable-next-line no-await-in-loop
        const resized = await resizeImage(file);
        photos.push({ fileName: resized.fileName, base64: resized.base64 });
      }
      const results = await uploadPhotos({
        parentId: this.recordId,
        docClassCode: this.docClass,
        photos
      });
      this.toast(UPLOADED.replace("{0}", results.length), "success");
      // documentIds: 현장 입력·체크리스트가 값에 사진을 묶는다(UX-008·009)
      this.dispatchEvent(
        new CustomEvent("uploaded", {
          detail: {
            count: results.length,
            documentIds: results.map((r) => r.documentId)
          }
        })
      );
    } catch (e) {
      this.toast(e?.body?.message || ERROR, "error");
    } finally {
      this.isBusy = false;
    }
  }

  toast(message, variant) {
    this.dispatchEvent(new ShowToastEvent({ message, variant }));
  }
}
