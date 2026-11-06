import { LightningElement, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import search from "@salesforce/apex/CMN_UnifiedSearchController.search";
import TITLE from "@salesforce/label/c.CMN_Search_Title";
import INPUT_LABEL from "@salesforce/label/c.CMN_Search_InputLabel";
import PLACEHOLDER from "@salesforce/label/c.CMN_Search_Placeholder";
import RUN from "@salesforce/label/c.CMN_Search_Run";
import INCLUDE_SUPERSEDED from "@salesforce/label/c.CMN_Search_IncludeSuperseded";
import HINT from "@salesforce/label/c.CMN_Search_Hint";
import AI_SUMMARY from "@salesforce/label/c.CMN_Search_AiSummary";
import AI_GENERATED from "@salesforce/label/c.CMN_Search_AiGenerated";
import SUMMARY_NOTICE from "@salesforce/label/c.CMN_Search_SummaryNotice";
import SOURCES from "@salesforce/label/c.CMN_Search_Sources";
import DOCUMENTS from "@salesforce/label/c.CMN_Search_Documents";
import RECORDS from "@salesforce/label/c.CMN_Search_Records";
import NO_RESULTS from "@salesforce/label/c.CMN_Search_NoResults";
import NO_DOCUMENTS from "@salesforce/label/c.CMN_Search_NoDocuments";
import SUPERSEDED from "@salesforce/label/c.CMN_Search_Superseded";
import SCORE from "@salesforce/label/c.CMN_Search_Score";
import COUNT from "@salesforce/label/c.CMN_Search_Count";
import TERM_LENGTH from "@salesforce/label/c.CMN_Search_TermLength";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";
import UNEXPECTED from "@salesforce/label/c.CMN_Common_UnexpectedError";

const TERM_MIN = 2;
const STATE_OK = "OK";
const STATE_NOT_AVAILABLE = "NOT_AVAILABLE";

/**
 * 통합 검색·요약(CMN-00-AI-002 BR-3). 입력 하나로 레코드(번호·제목·품번)와 문서 내용을 함께 찾는다.
 * - 위: AI 요약(근거 문서, "AI 생성"·참고용 안내), 아래: 문서 결과와 레코드 결과(객체별).
 * - 상태 매개변수 c__q로 검색어를 받아 바로 찾는다(메뉴 허브·다른 화면에서 열기).
 * - 문서 의미 검색 엔진이 아직 없으면(A단계) 서버가 준 "준비 중" 문구를 보이고 레코드 결과만 쓴다.
 */
export default class CmnUnifiedSearch extends NavigationMixin(
  LightningElement
) {
  labels = {
    title: TITLE,
    inputLabel: INPUT_LABEL,
    placeholder: PLACEHOLDER,
    run: RUN,
    includeSuperseded: INCLUDE_SUPERSEDED,
    hint: HINT,
    aiSummary: AI_SUMMARY,
    aiGenerated: AI_GENERATED,
    summaryNotice: SUMMARY_NOTICE,
    sources: SOURCES,
    documents: DOCUMENTS,
    records: RECORDS,
    noResults: NO_RESULTS,
    noDocuments: NO_DOCUMENTS,
    superseded: SUPERSEDED,
    loading: LOADING
  };
  term = "";
  includeSuperseded = false;
  result;
  isLoading = false;
  errorMessage;
  _pageTerm;

  @wire(CurrentPageReference)
  setPageReference(ref) {
    const q = ref?.state?.c__q;
    if (q && q !== this._pageTerm) {
      this._pageTerm = q;
      this.term = q;
      this.runSearch();
    }
  }

  handleTerm(event) {
    this.term = event.detail?.value ?? event.target.value ?? "";
  }

  handleKeyUp(event) {
    if (event.key === "Enter") {
      this.runSearch();
    }
  }

  handleSuperseded(event) {
    this.includeSuperseded = event.target.checked;
    if (this.result) {
      this.runSearch();
    }
  }

  async runSearch() {
    const t = (this.term || "").trim();
    if (t.length < TERM_MIN) {
      this.errorMessage = TERM_LENGTH;
      return;
    }
    this.isLoading = true;
    this.errorMessage = undefined;
    try {
      this.result = await search({
        term: t,
        includeSuperseded: this.includeSuperseded
      });
    } catch (error) {
      this.result = undefined;
      this.errorMessage = error?.body?.message || UNEXPECTED;
    } finally {
      this.isLoading = false;
    }
  }

  get showHint() {
    return !this.result && !this.errorMessage && !this.isLoading;
  }

  get hasResult() {
    return !!this.result && !this.isLoading;
  }

  get docs() {
    return this.result?.documents ?? {};
  }

  get docsReady() {
    return this.docs.state !== STATE_NOT_AVAILABLE;
  }

  get docsNotAvailable() {
    return this.docs.state === STATE_NOT_AVAILABLE;
  }

  get hasSummary() {
    return this.docsReady && !!this.docs.summary;
  }

  get hasDocItems() {
    return (this.docs.items ?? []).length > 0;
  }

  get showNoDocuments() {
    return this.docsReady && !this.hasDocItems;
  }

  get docItems() {
    return (this.docs.items ?? []).map((d) => ({
      ...d,
      meta: [d.docNo, d.revisionLabel, d.docClass].filter(Boolean).join(" · "),
      scoreLabel:
        d.scorePercent === null || d.scorePercent === undefined
          ? null
          : SCORE.replace("{0}", d.scorePercent)
    }));
  }

  get sourceItems() {
    return (this.docs.sources ?? []).map((s, i) => ({ ...s, key: `s${i}` }));
  }

  get recordGroups() {
    return (this.result?.records ?? []).map((g) => ({
      ...g,
      countLabel: COUNT.replace("{0}", g.hits.length),
      hits: g.hits.map((h) => ({
        ...h,
        display: h.numberText ? `${h.numberText} ${h.title ?? ""}` : h.title
      }))
    }));
  }

  get hasRecords() {
    return (this.result?.recordCount ?? 0) > 0;
  }

  get noResults() {
    return (
      this.hasResult &&
      !this.hasRecords &&
      !this.hasDocItems &&
      !this.docsNotAvailable
    );
  }

  get docsTitle() {
    return this.labels.documents;
  }

  get isMock() {
    return this.docs.isMock === true;
  }

  get docsOk() {
    return this.docs.state === STATE_OK;
  }

  openRecord(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.currentTarget.dataset.id,
        actionName: "view"
      }
    });
  }
}
