import { LightningElement, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import getGuide from "@salesforce/apex/CMN_ScreenGuideController.getGuide";
import TITLE from "@salesforce/label/c.CMN_Guide_Title";
import NO_GUIDE from "@salesforce/label/c.CMN_Guide_NoGuide";
import UNSUPPORTED from "@salesforce/label/c.CMN_Guide_Unsupported";
import FALLBACK from "@salesforce/label/c.CMN_Guide_Fallback";
import PAGE_KEY from "@salesforce/label/c.CMN_Guide_PageKey";
import VIDEO from "@salesforce/label/c.CMN_Guide_Video";
import STANDARD_DOC from "@salesforce/label/c.CMN_Guide_StandardDoc";
import UPDATED from "@salesforce/label/c.CMN_Guide_Updated";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import UNEXPECTED from "@salesforce/label/c.CMN_Common_UnexpectedError";

const RECORD = ".RECORD";
const LIST = ".LIST";

/**
 * 화면별 사용 가이드(CMN-00-UX-002). 유틸리티 바에 두고 지금 보는 화면의 가이드를 보인다(BR-1).
 * 화면 키: 레코드 페이지 = {객체API}.RECORD, 목록 = {객체API}.LIST, 앱 페이지 = 페이지(탭) API명, 홈 = home.
 * 레코드 페이지 주소에 객체 이름이 없으면 레코드 Id로 서버가 정한다. 언어 대체는 서버가 한다(BR-2).
 */
export default class CmnScreenGuide extends LightningElement {
  labels = {
    title: TITLE,
    noGuide: NO_GUIDE,
    unsupported: UNSUPPORTED,
    fallback: FALLBACK,
    video: VIDEO,
    standardDoc: STANDARD_DOC,
    updated: UPDATED,
    loading: LOADING
  };
  pageKey;
  recordId;
  guide;
  errorMessage;
  isLoading = false;
  _requestKey;

  @wire(CurrentPageReference)
  setPageReference(ref) {
    const { pageKey, recordId } = this.keyOf(ref);
    this.pageKey = pageKey;
    this.recordId = recordId;
    this.load();
  }

  keyOf(ref) {
    const type = ref?.type;
    const attrs = ref?.attributes ?? {};
    if (type === "standard__recordPage") {
      return attrs.objectApiName
        ? { pageKey: attrs.objectApiName + RECORD, recordId: null }
        : { pageKey: null, recordId: attrs.recordId ?? null };
    }
    if (type === "standard__objectPage" && attrs.objectApiName) {
      return { pageKey: attrs.objectApiName + LIST, recordId: null };
    }
    if (type === "standard__navItemPage" && attrs.apiName) {
      return { pageKey: attrs.apiName, recordId: null };
    }
    if (type === "standard__namedPage" && attrs.pageName) {
      return { pageKey: attrs.pageName, recordId: null };
    }
    return { pageKey: null, recordId: null };
  }

  async load() {
    const requestKey = `${this.pageKey}|${this.recordId}`;
    this._requestKey = requestKey;
    this.guide = undefined;
    this.errorMessage = undefined;
    if (!this.pageKey && !this.recordId) {
      return;
    }
    this.isLoading = true;
    try {
      const result = await getGuide({
        pageKey: this.pageKey,
        recordId: this.recordId
      });
      if (this._requestKey === requestKey) {
        this.guide = result;
      }
    } catch (error) {
      if (this._requestKey === requestKey) {
        this.errorMessage = error?.body?.message || UNEXPECTED;
      }
    } finally {
      if (this._requestKey === requestKey) {
        this.isLoading = false;
      }
    }
  }

  get isUnsupported() {
    return !this.pageKey && !this.recordId && !this.isLoading;
  }

  get hasGuide() {
    return this.guide?.found === true;
  }

  get showNoGuide() {
    return !!this.guide && !this.guide.found;
  }

  get pageKeyText() {
    const key = this.guide?.pageKey ?? this.pageKey;
    return key ? PAGE_KEY.replace("{0}", key) : null;
  }
}
