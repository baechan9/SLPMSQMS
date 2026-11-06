import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { publish, MessageContext } from "lightning/messageService";
import {
  registerRefreshHandler,
  unregisterRefreshHandler
} from "lightning/refresh";
import AI_CHANNEL from "@salesforce/messageChannel/CMN_AiRecommendation__c";
import getRecommendations from "@salesforce/apex/CMN_AiRecommendationController.getRecommendations";
import decide from "@salesforce/apex/CMN_AiRecommendationController.decide";
import CmnAiExcludeDialog from "c/cmnAiExcludeDialog";
import EMPTY from "@salesforce/label/c.CMN_AiRec_Empty";
import NOTICE from "@salesforce/label/c.CMN_AiRec_Notice";
import ADOPT from "@salesforce/label/c.CMN_AiRec_Adopt";
import MODIFY from "@salesforce/label/c.CMN_AiRec_Modify";
import EXCLUDE from "@salesforce/label/c.CMN_AiRec_Exclude";
import RANK from "@salesforce/label/c.CMN_AiRec_Rank";
import SCORE from "@salesforce/label/c.CMN_AiRec_Score";
import RATIONALE from "@salesforce/label/c.CMN_AiRec_Rationale";
import SOURCES from "@salesforce/label/c.CMN_AiRec_Sources";
import DECIDED from "@salesforce/label/c.CMN_AiRec_DecidedBy";
import HIT from "@salesforce/label/c.CMN_AiRec_Hit";
import MISS from "@salesforce/label/c.CMN_AiRec_Miss";
import MORE from "@salesforce/label/c.CMN_AiRec_ShowMore";
import LESS from "@salesforce/label/c.CMN_AiRec_ShowLess";
import EXCLUDE_TITLE from "@salesforce/label/c.CMN_AiRec_ExcludeTitle";
import DONE_ADOPTED from "@salesforce/label/c.CMN_AiRec_DoneAdopted";
import DONE_MODIFIED from "@salesforce/label/c.CMN_AiRec_DoneModified";
import DONE_EXCLUDED from "@salesforce/label/c.CMN_AiRec_DoneExcluded";
import LOAD_ERROR from "@salesforce/label/c.CMN_AiRec_LoadError";
import UNEXPECTED from "@salesforce/label/c.CMN_Common_UnexpectedError";
import LOADING from "@salesforce/label/c.CMN_Common_Loading";

const RENDERER = /^c\/[a-z][A-Za-z0-9]{1,79}$/;
const RAIL_DEFAULT = 3;
const PROPOSED = "PROPOSED";
const ADOPTED = "ADOPTED";
const MODIFIED = "MODIFIED";
const EXCLUDED = "EXCLUDED";
const DONE = {
  [ADOPTED]: DONE_ADOPTED,
  [MODIFIED]: DONE_MODIFIED,
  [EXCLUDED]: DONE_EXCLUDED
};

function parseConfig(value) {
  if (!value) {
    return {};
  }
  if (typeof value === "string") {
    try {
      return JSON.parse(value) ?? {};
    } catch {
      return {};
    }
  }
  return value;
}

function badgeClass(status) {
  if (status === ADOPTED || status === MODIFIED) {
    return "slds-badge slds-theme_success";
  }
  if (status === EXCLUDED) {
    return "slds-badge slds-badge_lightest";
  }
  return "slds-badge";
}

/**
 * AI 추천 목록(CMN-00-AI-004 BR-3). 업무 레코드의 결정 지원 레일 AI 패널이자 업무 화면 안 추천 영역이다.
 * - 패널 계약(UX-004 BR-6): recordId·objectApiName·config·variant. variant="rail"이면 카드 maxRail(기본 3)개 + "더 보기".
 *   아직 결정하지 않은 제안 수를 railbadge로 알린다.
 * - config: useCase(비우면 전체), renderer(UseCase 전용 카드 내용 컴포넌트 c/이름, content·recommendation 속성), maxRail.
 * - 채택·수정 채택·제외(사유 필수)는 서버가 기록한다. 추천을 본문 필드에 쓰지 않고, 결정 사실을
 *   recommendationdecided 이벤트(버블·composed)와 메시지 채널 CMN_AiRecommendation으로 알린다(업무 화면이 입력란에 복사).
 * - 같은 페이지의 RefreshEvent(예: AI 추천 실행 컴포넌트)를 받으면 다시 읽는다.
 */
export default class CmnAiRecommendationList extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api objectApiName;
  @api variant;
  /** App Builder 속성(config.useCase가 있으면 그것이 우선) */
  @api useCase;

  labels = {
    empty: EMPTY,
    notice: NOTICE,
    adopt: ADOPT,
    modify: MODIFY,
    exclude: EXCLUDE,
    rationale: RATIONALE,
    sources: SOURCES,
    less: LESS,
    loading: LOADING
  };
  rows = [];
  isLoading = false;
  loaded = false;
  errorMessage;
  expanded = false;
  busyId;
  rendererCtor;
  openRationale = new Set();
  _config = {};
  _connected = false;
  _refreshId;

  @wire(MessageContext) messageContext;

  @api
  get config() {
    return this._config;
  }
  set config(value) {
    this._config = parseConfig(value);
    if (this._connected) {
      this.loadRenderer();
      this.load();
    }
  }

  connectedCallback() {
    this._connected = true;
    this._refreshId = registerRefreshHandler(this, this.refreshView.bind(this));
    this.loadRenderer();
    this.load();
  }

  disconnectedCallback() {
    this._connected = false;
    if (this._refreshId !== undefined) {
      unregisterRefreshHandler(this._refreshId);
    }
  }

  refreshView() {
    return this.load().then(() => true);
  }

  get effectiveUseCase() {
    return this._config?.useCase || this.useCase || null;
  }

  get isRail() {
    return this.variant === "rail";
  }

  get maxRail() {
    const n = Number(this._config?.maxRail);
    return Number.isInteger(n) && n > 0 ? n : RAIL_DEFAULT;
  }

  async loadRenderer() {
    const name = this._config?.renderer;
    if (!name || !RENDERER.test(name)) {
      this.rendererCtor = undefined;
      return;
    }
    try {
      const mod = await import(`c/${name.slice(2)}`);
      this.rendererCtor = mod.default;
    } catch {
      // 렌더러를 못 불러오면 기본 카드 내용으로 보인다(목록은 계속 쓸 수 있다)
      this.rendererCtor = undefined;
    }
  }

  async load() {
    if (!this.recordId) {
      return;
    }
    this.isLoading = true;
    try {
      const view = await getRecommendations({
        recordId: this.recordId,
        useCase: this.effectiveUseCase
      });
      this.rows = view?.items ?? [];
      this.errorMessage = undefined;
      this.notifyBadge();
    } catch (error) {
      this.rows = [];
      this.errorMessage = error?.body?.message || LOAD_ERROR;
    } finally {
      this.isLoading = false;
      this.loaded = true;
    }
  }

  notifyBadge() {
    const count = this.rows.filter((r) => r.status === PROPOSED).length;
    this.dispatchEvent(
      new CustomEvent("railbadge", { detail: { count, severity: "info" } })
    );
  }

  get showSpinner() {
    return this.isLoading && !this.loaded;
  }

  get isEmpty() {
    return this.loaded && !this.errorMessage && this.rows.length === 0;
  }

  get hasRows() {
    return !this.errorMessage && this.rows.length > 0;
  }

  get cards() {
    const visible =
      this.isRail && !this.expanded
        ? this.rows.slice(0, this.maxRail)
        : this.rows;
    return visible.map((r) => {
      const decided = r.decidedBy ? DECIDED.replace("{0}", r.decidedBy) : null;
      return {
        ...r,
        rankLabel: RANK.replace("{0}", r.rank),
        scoreLabel:
          r.scorePercent === null || r.scorePercent === undefined
            ? null
            : SCORE.replace("{0}", r.scorePercent),
        badgeClass: badgeClass(r.status),
        decidedText: decided,
        hitText: r.isFinalized ? (r.isHit ? HIT : MISS) : null,
        details: (r.details ?? []).map((d, i) => ({
          ...d,
          labelKey: `l${i}`,
          valueKey: `v${i}`
        })),
        hasDetails: (r.details ?? []).length > 0,
        hasRefs: (r.refs ?? []).length > 0,
        showRationale: this.openRationale.has(r.id),
        rationaleExpanded: this.openRationale.has(r.id) ? "true" : "false",
        rationaleIcon: this.openRationale.has(r.id)
          ? "utility:chevrondown"
          : "utility:chevronright",
        isBusy: this.busyId === r.id,
        adoptDisabled: this.busyId === r.id || r.status === ADOPTED,
        modifyDisabled: this.busyId === r.id || r.status === MODIFIED,
        excludeDisabled: this.busyId === r.id || r.status === EXCLUDED,
        adoptVariant: r.status === ADOPTED ? "brand" : "neutral",
        modifyVariant: r.status === MODIFIED ? "brand" : "neutral",
        excludeVariant: r.status === EXCLUDED ? "brand" : "neutral"
      };
    });
  }

  get hasMore() {
    return this.isRail && this.rows.length > this.maxRail;
  }

  get moreLabel() {
    return this.expanded
      ? LESS
      : MORE.replace("{0}", this.rows.length - this.maxRail);
  }

  get hasRenderer() {
    return !!this.rendererCtor;
  }

  toggleMore() {
    this.expanded = !this.expanded;
  }

  toggleRationale(event) {
    const id = event.currentTarget.dataset.id;
    const next = new Set(this.openRationale);
    if (next.has(id)) {
      next.delete(id);
    } else {
      next.add(id);
    }
    this.openRationale = next;
  }

  openRef(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.currentTarget.dataset.id,
        actionName: "view"
      }
    });
  }

  handleAdopt(event) {
    this.applyDecision(event.currentTarget.dataset.id, ADOPTED);
  }

  handleModify(event) {
    this.applyDecision(event.currentTarget.dataset.id, MODIFIED);
  }

  async handleExclude(event) {
    const id = event.currentTarget.dataset.id;
    const row = this.rows.find((r) => r.id === id);
    const result = await CmnAiExcludeDialog.open({
      size: "small",
      label: EXCLUDE_TITLE,
      recommendationTitle: row?.title
    });
    if (result?.reasonId) {
      await this.applyDecision(id, EXCLUDED, result.reasonId);
    }
  }

  async applyDecision(id, status, reasonCode) {
    if (!id || this.busyId) {
      return;
    }
    this.busyId = id;
    try {
      const updated = await decide({
        recommendationId: id,
        status,
        reasonCode: reasonCode ?? null
      });
      this.rows = this.rows.map((r) => (r.id === id ? updated : r));
      this.notifyBadge();
      this.announce(updated);
      this.dispatchEvent(
        new ShowToastEvent({ message: DONE[status], variant: "success" })
      );
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          message: error?.body?.message || UNEXPECTED,
          variant: "error"
        })
      );
    } finally {
      this.busyId = undefined;
    }
  }

  announce(rec) {
    const detail = {
      recordId: this.recordId,
      recommendationId: rec.id,
      useCase: rec.useCase,
      status: rec.status,
      rank: rec.rank,
      contentJson: rec.contentJson
    };
    this.dispatchEvent(
      new CustomEvent("recommendationdecided", {
        detail,
        bubbles: true,
        composed: true
      })
    );
    publish(this.messageContext, AI_CHANNEL, detail);
  }
}
