import { LightningElement } from "lwc";
import getState from "@salesforce/apex/CMN_LanguageController.getState";
import setLanguage from "@salesforce/apex/CMN_LanguageController.setLanguage";
import followPortal from "@salesforce/apex/CMN_LanguageController.followPortal";
import TITLE from "@salesforce/label/c.CMN_LanguageSwitcher_Title";
import FOLLOW from "@salesforce/label/c.CMN_LanguageSwitcher_FollowPortal";
import OVERRIDDEN from "@salesforce/label/c.CMN_LanguageSwitcher_Overridden";
import FOLLOWING from "@salesforce/label/c.CMN_LanguageSwitcher_Following";
import SAVED from "@salesforce/label/c.CMN_LanguageSwitcher_Saved";
import ERROR from "@salesforce/label/c.CMN_LanguageSwitcher_Error";
import LOADING from "@salesforce/label/c.CMN_CodePicker_Loading";
import KO from "@salesforce/label/c.CMN_Language_ko";
import EN from "@salesforce/label/c.CMN_Language_en_US";
import ZH from "@salesforce/label/c.CMN_Language_zh_CN";
import PL from "@salesforce/label/c.CMN_Language_pl";
import ES from "@salesforce/label/c.CMN_Language_es";
import PT from "@salesforce/label/c.CMN_Language_pt_BR";

const NAMES = { ko: KO, en_US: EN, zh_CN: ZH, pl: PL, es: ES, pt_BR: PT };
const FOLLOW_VALUE = "__portal__";

/**
 * 표시 언어 스위처(CMN-00-I18N-001 BR-4).
 * 언어를 고르면 그 언어로 바꾸고 직접 지정(LanguageOverride)으로 저장한 뒤 화면을 다시 불러온다.
 * "포털 언어 따르기"는 직접 지정을 풀어 다음 SSO 로그인부터 포털 언어를 쓴다.
 */
export default class CmnLanguageSwitcher extends LightningElement {
  labels = { title: TITLE, loading: LOADING };
  isLoading = true;
  isSaving = false;
  errorMessage;
  notice;
  current;
  overridden = false;
  languages = [];

  connectedCallback() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      const s = await getState();
      this.current = s.current;
      this.overridden = s.overridden;
      this.languages = s.languages ?? [];
    } catch {
      this.errorMessage = ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  get options() {
    return [
      ...this.languages.map((code) => ({
        label: NAMES[code] ?? code,
        value: code
      })),
      { label: FOLLOW, value: FOLLOW_VALUE }
    ];
  }

  get value() {
    return this.overridden ? this.current : FOLLOW_VALUE;
  }

  get status() {
    return this.overridden ? OVERRIDDEN : FOLLOWING;
  }

  get isReady() {
    return !this.isLoading;
  }

  async handleChange(event) {
    const value = event.detail.value;
    this.isSaving = true;
    this.errorMessage = undefined;
    try {
      if (value === FOLLOW_VALUE) {
        await followPortal();
        this.overridden = false;
        return;
      }
      await setLanguage({ localeKey: value });
      this.current = value;
      this.overridden = true;
      this.notice = SAVED;
      this.reload();
    } catch {
      this.errorMessage = ERROR;
    } finally {
      this.isSaving = false;
    }
  }

  /** 새 언어 라벨로 다시 그리려면 페이지 전체를 다시 불러와야 한다 */
  reload() {
    window.location.reload();
  }
}
