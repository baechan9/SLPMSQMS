import { LightningElement, api, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";
import FORM_FACTOR from "@salesforce/client/formFactor";
import USER_ID from "@salesforce/user/Id";
import loadSheet from "@salesforce/apex/CMN_ChecklistController.load";
import saveAnswers from "@salesforce/apex/CMN_ChecklistController.saveAnswers";
import previewScore from "@salesforce/apex/CMN_ChecklistController.preview";
import raiseFollowUp from "@salesforce/apex/CMN_ChecklistController.raiseFollowUp";
import { draftKey, saveDraft, loadDraft, clearDraft } from "c/cmnDraftStore";
import CmnChecklistFollowUp from "c/cmnChecklistFollowUp";
import LOADING from "@salesforce/label/c.CMN_Checklist_Loading";
import LOAD_ERROR from "@salesforce/label/c.CMN_Checklist_LoadError";
import NO_RECORD from "@salesforce/label/c.CMN_Checklist_NoRecord";
import PROGRESS from "@salesforce/label/c.CMN_Checklist_Progress";
import MY_ONLY from "@salesforce/label/c.CMN_Checklist_MyOnly";
import SHOW_SCORE from "@salesforce/label/c.CMN_Checklist_ShowScore";
import SECTIONS from "@salesforce/label/c.CMN_Checklist_Sections";
import SECTION_PROGRESS from "@salesforce/label/c.CMN_Checklist_SectionProgress";
import VIEW_CARDS from "@salesforce/label/c.CMN_Checklist_ViewCards";
import VIEW_TABLE from "@salesforce/label/c.CMN_Checklist_ViewTable";
import VIEW_LABEL from "@salesforce/label/c.CMN_Checklist_ViewLabel";
import STAR from "@salesforce/label/c.CMN_Checklist_Star";
import GUIDANCE from "@salesforce/label/c.CMN_Checklist_Guidance";
import ANSWER from "@salesforce/label/c.CMN_Checklist_Answer";
import POINTS from "@salesforce/label/c.CMN_Checklist_Points";
import COMPLIANT from "@salesforce/label/c.CMN_Checklist_Compliant";
import NONCOMPLIANT from "@salesforce/label/c.CMN_Checklist_Noncompliant";
import YES from "@salesforce/label/c.CMN_Checklist_Yes";
import NO from "@salesforce/label/c.CMN_Checklist_No";
import SAMPLE_QTY from "@salesforce/label/c.CMN_Checklist_SampleQty";
import DEFECT_A from "@salesforce/label/c.CMN_Checklist_DefectA";
import DEFECT_B from "@salesforce/label/c.CMN_Checklist_DefectB";
import DEFECT_C from "@salesforce/label/c.CMN_Checklist_DefectC";
import NA from "@salesforce/label/c.CMN_Checklist_Na";
import NA_REASON from "@salesforce/label/c.CMN_Checklist_NaReason";
import NOTES from "@salesforce/label/c.CMN_Checklist_Notes";
import NOTES_HINT from "@salesforce/label/c.CMN_Checklist_NotesRequiredHint";
import NO_FOLLOW_UP_REASON from "@salesforce/label/c.CMN_Checklist_NoFollowUpReason";
import FOLLOW_UP from "@salesforce/label/c.CMN_Checklist_FollowUp";
import FOLLOW_UP_CREATED from "@salesforce/label/c.CMN_Checklist_FollowUpCreated";
import FOLLOW_UP_TITLE from "@salesforce/label/c.CMN_Checklist_FollowUpTitle";
import PREV from "@salesforce/label/c.CMN_Checklist_Prev";
import NEXT from "@salesforce/label/c.CMN_Checklist_Next";
import OPEN from "@salesforce/label/c.CMN_Checklist_Open";
import SUBMIT from "@salesforce/label/c.CMN_Checklist_Submit";
import SAVE_NOW from "@salesforce/label/c.CMN_Checklist_SaveNow";
import DRAFT_SAVED from "@salesforce/label/c.CMN_Checklist_DraftSaved";
import SERVER_SAVED from "@salesforce/label/c.CMN_Checklist_ServerSaved";
import PENDING from "@salesforce/label/c.CMN_Checklist_Pending";
import SAVE_FAILED from "@salesforce/label/c.CMN_Checklist_SaveFailed";
import DRAFT_RESTORE from "@salesforce/label/c.CMN_Checklist_DraftRestore";
import DRAFT_TITLE from "@salesforce/label/c.CMN_Checklist_DraftTitle";
import UNANSWERED_CONFIRM from "@salesforce/label/c.CMN_Checklist_UnansweredConfirm";
import SUBMIT_TITLE from "@salesforce/label/c.CMN_Checklist_SubmitTitle";
import SUBMITTED from "@salesforce/label/c.CMN_Checklist_Submitted";
import FIX_ERRORS from "@salesforce/label/c.CMN_Checklist_FixErrors";
import READ_ONLY from "@salesforce/label/c.CMN_Checklist_ReadOnly";
import SCORE_TITLE from "@salesforce/label/c.CMN_Checklist_ScoreTitle";
import SCORE_PERCENT from "@salesforce/label/c.CMN_Checklist_ScorePercent";
import GRADE from "@salesforce/label/c.CMN_Checklist_Grade";
import GRADE_BEFORE from "@salesforce/label/c.CMN_Checklist_GradeBefore";
import UNANSWERED from "@salesforce/label/c.CMN_Checklist_Unanswered";
import PHOTOS from "@salesforce/label/c.CMN_Checklist_Photos";
import NO_QUESTIONS from "@salesforce/label/c.CMN_Checklist_NoQuestions";
import NA_REASON_REQUIRED from "@salesforce/label/c.CMN_Checklist_NaReasonRequired";
import UNEXPECTED from "@salesforce/label/c.CMN_Common_UnexpectedError";

const DRAFT_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const CHOICES = {
  COMPLIANCE: {
    field: "compliance",
    options: [
      ["COMPLIANT", COMPLIANT],
      ["NONCOMPLIANT", NONCOMPLIANT]
    ]
  },
  YES_NO: {
    field: "yesNo",
    options: [
      ["YES", YES],
      ["NO", NO]
    ]
  }
};

function format(template, ...args) {
  return args.reduce((s, a, i) => s.replace(`{${i}}`, a), template ?? "");
}

function sameUser(a, b) {
  return !!a && !!b && String(a).slice(0, 15) === String(b).slice(0, 15);
}

function blank(v) {
  return v === null || v === undefined || v === "";
}

function same(a, b) {
  return JSON.stringify(a ?? {}) === JSON.stringify(b ?? {});
}

/**
 * 체크리스트 수행 화면(CMN-00-UX-009, 화면 유형 T4). 심사·자체 평가·레슨런 점검·PMS Gate의 질문 답·관찰·증빙·후속 조치를 한 화면으로 한다.
 * 질문지·필수 입력 규칙·점수 계산은 레코드 객체에 등록된 Provider가 갖고, 셸은 입력과 표시만 한다(점수를 계산하지 않는다).
 * - 요소 목록·진행률(태블릿·데스크톱 왼쪽, 휴대폰 위 선택 목록), 질문 카드, 데스크톱 질문 표 보기(BR-1)
 * - 답 유형별 입력(BR-2), NA·사유, 관찰 메모, 사진, 후속 조치(BR-5), 내 분담만(BR-6)
 * - 임시 저장 7일, 요소를 다 답하면 중간 저장, 전송 대기·지금 저장, 제출(BR-7), 다음 질문 이동은 서버 호출 없음(BR-9)
 */
export default class CmnChecklistRunner extends LightningElement {
  _recordId;
  connected = false;
  started = false;
  pageChecked = false;

  @api
  get recordId() {
    return this._recordId;
  }
  set recordId(value) {
    this._recordId = value;
    this.start();
  }

  @wire(CurrentPageReference)
  handlePageRef(ref) {
    this.pageChecked = true;
    const id = ref?.state?.c__recordId;
    if (id && !this._recordId) {
      this._recordId = id;
      this.start();
    }
  }

  labels = {
    loading: LOADING,
    myOnly: MY_ONLY,
    showScore: SHOW_SCORE,
    sections: SECTIONS,
    viewLabel: VIEW_LABEL,
    star: STAR,
    guidance: GUIDANCE,
    answer: ANSWER,
    sampleQty: SAMPLE_QTY,
    defectA: DEFECT_A,
    defectB: DEFECT_B,
    defectC: DEFECT_C,
    na: NA,
    naReason: NA_REASON,
    notes: NOTES,
    notesHint: NOTES_HINT,
    noFollowUpReason: NO_FOLLOW_UP_REASON,
    followUp: FOLLOW_UP,
    followUpCreated: FOLLOW_UP_CREATED,
    prev: PREV,
    next: NEXT,
    open: OPEN,
    submit: SUBMIT,
    saveNow: SAVE_NOW,
    readOnly: READ_ONLY,
    scoreTitle: SCORE_TITLE,
    noQuestions: NO_QUESTIONS,
    noRecord: NO_RECORD
  };
  sheet;
  answers = {};
  pending = {};
  pendingSeq = 0;
  errors = {};
  generalErrors = [];
  currentKey;
  myOnly = false;
  view = "CARDS";
  guidanceOpen = false;
  score;
  scoreOpen = false;
  isLoading = false;
  isSaving = false;
  loadError;
  offline = false;
  failMessage;
  draftSaved = false;
  serverSaved = false;
  submitted = false;

  connectedCallback() {
    this.connected = true;
    this.start();
  }

  start() {
    if (this.connected && this._recordId && !this.started) {
      this.started = true;
      this.load();
    }
  }

  // ---------------------------------------------------------------- 로드·초안
  get storeKey() {
    return draftKey(USER_ID, "CHECKLIST", this._recordId);
  }

  async load() {
    this.isLoading = true;
    this.loadError = undefined;
    try {
      const sheet = await loadSheet({ recordId: this._recordId });
      const answers = {};
      (sheet?.answers ?? []).forEach((a) => {
        answers[a.questionKey] = a;
      });
      this.sheet = sheet;
      this.answers = answers;
      this.currentKey = this.visibleQuestions[0]?.key;
      if (sheet?.editable) {
        await this.offerDraft(answers);
      }
    } catch (e) {
      this.loadError = e?.body?.message || LOAD_ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  async offerDraft(serverAnswers) {
    const draft = loadDraft(this.storeKey);
    const keys = new Set((this.sheet.questions ?? []).map((q) => q.key));
    const changed = Object.entries(draft?.answers ?? {}).filter(
      ([k, a]) => keys.has(k) && !same(a, serverAnswers[k])
    );
    if (!changed.length) {
      if (draft) {
        clearDraft(this.storeKey);
      }
      return;
    }
    const ok = await LightningConfirm.open({
      message: format(DRAFT_RESTORE, changed.length),
      label: DRAFT_TITLE,
      theme: "warning"
    });
    if (!ok) {
      clearDraft(this.storeKey);
      return;
    }
    const answers = { ...serverAnswers };
    const pending = {};
    changed.forEach(([k, a]) => {
      answers[k] = a;
      pending[k] = ++this.pendingSeq;
    });
    this.answers = answers;
    this.pending = pending;
    this.draftSaved = true;
  }

  persist() {
    if (this.sheet?.editable) {
      this.draftSaved = saveDraft(
        this.storeKey,
        { answers: this.answers },
        DRAFT_TTL_MS
      );
    }
  }

  // ---------------------------------------------------------------- 화면 상태
  get noRecord() {
    return this.connected && this.pageChecked && !this._recordId;
  }

  get readOnly() {
    return !this.sheet?.editable;
  }

  get isPhone() {
    return FORM_FACTOR === "Small";
  }

  get showTableToggle() {
    return FORM_FACTOR === "Large";
  }

  get isCards() {
    return this.view === "CARDS" || !this.showTableToggle;
  }

  get viewOptions() {
    return [
      { label: VIEW_CARDS, value: "CARDS" },
      { label: VIEW_TABLE, value: "TABLE" }
    ];
  }

  get visibleQuestions() {
    const qs = this.sheet?.questions ?? [];
    return this.myOnly
      ? qs.filter((q) => !q.assignedToId || sameUser(q.assignedToId, USER_ID))
      : qs;
  }

  isAnswered(q) {
    const a = this.answers[q.key];
    if (!a) {
      return false;
    }
    if (a.isNa) {
      return true;
    }
    switch (q.answerType) {
      case "SCORE_STEPS":
      case "POINTS":
        return !blank(a.points);
      case "COMPLIANCE":
        return !blank(a.compliance);
      case "YES_NO":
        return !blank(a.yesNo);
      case "DEFECT_CLASS":
        return !blank(a.sampleQty);
      default:
        return !blank(a.text?.trim?.());
    }
  }

  get answeredCount() {
    return this.visibleQuestions.filter((q) => this.isAnswered(q)).length;
  }

  get progressText() {
    return format(PROGRESS, this.answeredCount, this.visibleQuestions.length);
  }

  get progressValue() {
    const n = this.visibleQuestions.length;
    return n ? Math.round((this.answeredCount / n) * 100) : 0;
  }

  get sectionItems() {
    const visible = this.visibleQuestions;
    const current = this.current?.question.sectionKey;
    return (this.sheet?.sections ?? []).map((s) => {
      const qs = visible.filter((q) => q.sectionKey === s.key);
      const done = qs.filter((q) => this.isAnswered(q)).length;
      return {
        key: s.key,
        label: s.label,
        progress: format(SECTION_PROGRESS, done, qs.length),
        complete: qs.length > 0 && done === qs.length,
        className: `slds-button slds-button_reset section-link slds-p-around_x-small ${s.key === current ? "is-current" : ""}`,
        ariaCurrent: s.key === current ? "true" : "false",
        disabled: qs.length === 0
      };
    });
  }

  get sectionOptions() {
    return this.sectionItems.map((s) => ({
      label: `${s.label} (${s.progress})`,
      value: s.key
    }));
  }

  get currentSectionKey() {
    return this.current?.question.sectionKey;
  }

  get pendingCount() {
    return Object.keys(this.pending).length;
  }

  get statusText() {
    if (this.pendingCount && (this.offline || !this.serverSaved)) {
      return format(PENDING, this.pendingCount);
    }
    if (this.serverSaved && !this.pendingCount) {
      return SERVER_SAVED;
    }
    return this.draftSaved ? DRAFT_SAVED : "";
  }

  get showSaveNow() {
    return !this.readOnly && this.pendingCount > 0;
  }

  get showScoreButton() {
    return this.sheet?.scoreVisible === true;
  }

  get scoreView() {
    const s = this.score;
    if (!s) {
      return null;
    }
    return {
      percent: blank(s.percent) ? "-" : format(SCORE_PERCENT, s.percent),
      grade: s.grade ? format(GRADE, s.grade) : "",
      before:
        s.gradeBeforeDowngrade && s.gradeBeforeDowngrade !== s.grade
          ? format(GRADE_BEFORE, s.gradeBeforeDowngrade)
          : "",
      reasons: (s.downgradeReasons ?? []).map((r, i) => ({
        key: `r${i}`,
        text: r
      })),
      sections: (s.sectionPercents ?? []).map((x) => ({
        key: x.key,
        text: `${x.label}: ${blank(x.percent) ? "-" : `${x.percent}%`}`
      })),
      unanswered: format(UNANSWERED, s.unansweredCount ?? 0)
    };
  }

  // ---------------------------------------------------------------- 질문 카드
  needsNoteHint(q, a) {
    return (
      (!blank(q.noteRequiredAtOrBelow) &&
        !blank(a.points) &&
        Number(a.points) <= q.noteRequiredAtOrBelow) ||
      a.compliance === "NONCOMPLIANT"
    );
  }

  get current() {
    const visible = this.visibleQuestions;
    const q = visible.find((x) => x.key === this.currentKey) ?? visible[0];
    if (!q) {
      return null;
    }
    const a = this.answers[q.key] ?? {};
    const index = visible.indexOf(q);
    const disabled = this.readOnly || a.isNa === true;
    const choice = CHOICES[q.answerType];
    const hint = !a.isNa && this.needsNoteHint(q, a);
    return {
      key: q.key,
      question: q,
      title: `${q.no ?? ""} ${q.text ?? ""}`.trim(),
      isStar: q.isStar === true,
      hasGuidance: !blank(q.guidance),
      isScoreSteps: q.answerType === "SCORE_STEPS",
      isPoints: q.answerType === "POINTS",
      isChoice: !!choice,
      isDefect: q.answerType === "DEFECT_CLASS",
      isText: q.answerType === "TEXT",
      scoreButtons: (q.allowedScores ?? []).map((s) => ({
        key: `${q.key}-${s}`,
        value: String(s),
        label: String(s),
        className: `slds-button ${Number(a.points) === Number(s) && !blank(a.points) ? "slds-button_brand" : "slds-button_neutral"} score-button`,
        pressed:
          Number(a.points) === Number(s) && !blank(a.points) ? "true" : "false"
      })),
      pointsLabel: format(POINTS, q.maxPoints ?? ""),
      maxPoints: q.maxPoints,
      points: a.points ?? "",
      choiceButtons: (choice?.options ?? []).map(([value, label]) => ({
        key: `${q.key}-${value}`,
        value,
        label,
        field: choice.field,
        className: `slds-button slds-button_stretch ${a[choice.field] === value ? "slds-button_brand" : "slds-button_neutral"} choice-button`,
        pressed: a[choice.field] === value ? "true" : "false"
      })),
      sampleQty: a.sampleQty ?? "",
      defectA: a.defectA ?? "",
      defectB: a.defectB ?? "",
      defectC: a.defectC ?? "",
      text: a.text ?? "",
      allowNa: q.allowNa === true,
      isNa: a.isNa === true,
      naReason: a.naReason ?? "",
      notes: a.notes ?? "",
      noteHint: hint,
      showNoFollowUpReason: hint && !a.followUpId,
      noFollowUpReason: a.noFollowUpReason ?? "",
      hasFollowUp: !!a.followUpId,
      photoText: (a.photoIds ?? []).length
        ? format(PHOTOS, a.photoIds.length)
        : "",
      showPhoto: !!this.sheet?.photoDocClass && !this.readOnly,
      disabled,
      errors: this.errors[q.key] ?? [],
      prevDisabled: index <= 0,
      nextDisabled: index < 0 || index >= visible.length - 1
    };
  }

  answerText(q, a) {
    if (!a) {
      return "";
    }
    if (a.isNa) {
      return NA;
    }
    switch (q.answerType) {
      case "SCORE_STEPS":
      case "POINTS":
        return blank(a.points) ? "" : String(a.points);
      case "COMPLIANCE":
        return a.compliance === "COMPLIANT"
          ? COMPLIANT
          : a.compliance
            ? NONCOMPLIANT
            : "";
      case "YES_NO":
        return a.yesNo === "YES" ? YES : a.yesNo ? NO : "";
      case "DEFECT_CLASS":
        return blank(a.sampleQty)
          ? ""
          : `${a.sampleQty} / ${a.defectA ?? 0}·${a.defectB ?? 0}·${a.defectC ?? 0}`;
      default:
        return a.text ?? "";
    }
  }

  get tableRows() {
    return this.visibleQuestions.map((q) => {
      const a = this.answers[q.key];
      return {
        key: q.key,
        no: q.no,
        isStar: q.isStar === true,
        text: q.text,
        answer: this.answerText(q, a),
        notes: a?.notes ?? "",
        hasFollowUp: !!a?.followUpId,
        hasError: !!this.errors[q.key],
        rowClass: this.errors[q.key] ? "slds-has-error" : ""
      };
    });
  }

  // ---------------------------------------------------------------- 입력
  setAnswer(questionKey, patch) {
    const cur = this.answers[questionKey] ?? { questionKey, photoIds: [] };
    this.answers = { ...this.answers, [questionKey]: { ...cur, ...patch } };
    this.pending = { ...this.pending, [questionKey]: ++this.pendingSeq };
    const errors = { ...this.errors };
    delete errors[questionKey];
    this.errors = errors;
    this.persist();
    const q = this.sheet.questions.find((x) => x.key === questionKey);
    const section = this.visibleQuestions.filter(
      (x) => x.sectionKey === q?.sectionKey
    );
    if (section.length && section.every((x) => this.isAnswered(x))) {
      this.autoSave();
    }
  }

  handleScore(event) {
    this.setAnswer(this.current.key, {
      points: Number(event.currentTarget.dataset.value)
    });
  }

  handleChoice(event) {
    const { field, value } = event.currentTarget.dataset;
    this.setAnswer(this.current.key, { [field]: value });
  }

  handleNumber(event) {
    const field = event.target.dataset.field;
    const raw = event.detail?.value ?? event.target.value;
    this.setAnswer(this.current.key, {
      [field]: blank(raw) ? null : Number(raw)
    });
  }

  handleTextField(event) {
    const field = event.target.dataset.field;
    this.setAnswer(this.current.key, {
      [field]: event.detail?.value ?? event.target.value ?? ""
    });
  }

  handleNa(event) {
    const isNa = event.detail?.checked ?? event.target.checked;
    this.setAnswer(this.current.key, { isNa });
  }

  handlePhotos(event) {
    const ids = event.detail?.documentIds ?? [];
    if (ids.length) {
      const cur = this.answers[this.current.key]?.photoIds ?? [];
      this.setAnswer(this.current.key, { photoIds: [...cur, ...ids] });
    }
  }

  async handleFollowUp() {
    const current = this.current;
    const input = await CmnChecklistFollowUp.open({
      size: "small",
      label: FOLLOW_UP_TITLE,
      questionText: current.title
    });
    if (!input) {
      return;
    }
    try {
      const id = await raiseFollowUp({
        recordId: this._recordId,
        questionKey: current.key,
        inputJson: JSON.stringify(input)
      });
      this.setAnswer(current.key, { followUpId: id });
      this.toast(FOLLOW_UP_CREATED, "success");
    } catch (e) {
      this.toast(e?.body?.message || UNEXPECTED, "error");
    }
  }

  // ---------------------------------------------------------------- 이동·필터
  handleNext() {
    const visible = this.visibleQuestions;
    const i = visible.findIndex((q) => q.key === this.current?.key);
    if (i >= 0 && i < visible.length - 1) {
      this.currentKey = visible[i + 1].key;
      this.guidanceOpen = false;
    }
  }

  handlePrev() {
    const visible = this.visibleQuestions;
    const i = visible.findIndex((q) => q.key === this.current?.key);
    if (i > 0) {
      this.currentKey = visible[i - 1].key;
      this.guidanceOpen = false;
    }
  }

  goToSection(sectionKey) {
    const q = this.visibleQuestions.find((x) => x.sectionKey === sectionKey);
    if (q) {
      this.currentKey = q.key;
      this.view = "CARDS";
    }
  }

  handleSectionClick(event) {
    this.goToSection(event.currentTarget.dataset.key);
  }

  handleSectionSelect(event) {
    this.goToSection(event.detail?.value);
  }

  handleOpenRow(event) {
    this.currentKey = event.currentTarget.dataset.key;
    this.view = "CARDS";
  }

  handleMyOnly(event) {
    this.myOnly = event.detail?.checked ?? !this.myOnly;
  }

  handleView(event) {
    this.view = event.detail?.value ?? "CARDS";
  }

  handleGuidance() {
    this.guidanceOpen = !this.guidanceOpen;
  }

  // ---------------------------------------------------------------- 저장·점수
  answersFor(keys) {
    const set = new Set(keys);
    return Object.values(this.answers).filter((a) => set.has(a.questionKey));
  }

  autoSave() {
    if (this.readOnly || this.offline || this.isSaving) {
      return;
    }
    this.sendPending();
  }

  /** 바뀐 질문만 중간 저장한다. 실패하면 사용자가 "지금 저장"을 누를 때까지 자동으로 다시 보내지 않는다. */
  async sendPending() {
    const sent = { ...this.pending };
    const keys = Object.keys(sent);
    if (!keys.length) {
      return true;
    }
    this.isSaving = true;
    try {
      const result = await saveAnswers({
        recordId: this._recordId,
        answersJson: JSON.stringify(this.answersFor(keys)),
        isFinal: false
      });
      this.applyErrors(result);
      if (result?.success) {
        const pending = { ...this.pending };
        keys.forEach((k) => {
          if (pending[k] === sent[k]) {
            delete pending[k];
          }
        });
        this.pending = pending;
        this.offline = false;
        this.failMessage = undefined;
        this.serverSaved = true;
      }
      return result?.success === true;
    } catch {
      this.offline = true;
      this.failMessage = SAVE_FAILED;
      return false;
    } finally {
      this.isSaving = false;
    }
  }

  handleSaveNow() {
    return this.sendPending();
  }

  applyErrors(result) {
    const errors = {};
    const general = [];
    (result?.errors ?? []).forEach((e) => {
      if (e.questionKey) {
        errors[e.questionKey] = [...(errors[e.questionKey] ?? []), e.message];
      } else {
        general.push(e.message);
      }
    });
    this.errors = errors;
    this.generalErrors = general;
    const first = this.visibleQuestions.find((q) => errors[q.key]);
    if (first) {
      this.currentKey = first.key;
      this.view = "CARDS";
    }
  }

  /** 점수 보기(BR-4): 저장하지 않은 답을 먼저 중간 저장하고 Provider 계산 결과를 보인다. */
  async handleShowScore() {
    if (this.pendingCount && !this.readOnly) {
      const ok = await this.sendPending();
      if (!ok) {
        return;
      }
    }
    try {
      this.score = await previewScore({ recordId: this._recordId });
      this.scoreOpen = true;
    } catch (e) {
      this.toast(e?.body?.message || UNEXPECTED, "error");
    }
  }

  handleCloseScore() {
    this.scoreOpen = false;
  }

  async handleSubmit() {
    // 화면 확인: NA 사유(AC-6)
    const naErrors = {};
    (this.sheet.questions ?? []).forEach((q) => {
      const a = this.answers[q.key];
      if (a?.isNa && blank(a.naReason?.trim?.())) {
        naErrors[q.key] = [NA_REASON_REQUIRED];
      }
    });
    if (Object.keys(naErrors).length) {
      this.applyErrors({
        errors: Object.entries(naErrors).map(([questionKey, m]) => ({
          questionKey,
          message: m[0]
        }))
      });
      this.toast(FIX_ERRORS, "error");
      return;
    }
    const unanswered = (this.sheet.questions ?? []).filter(
      (q) => !this.isAnswered(q)
    ).length;
    if (unanswered) {
      const ok = await LightningConfirm.open({
        message: format(UNANSWERED_CONFIRM, unanswered),
        label: SUBMIT_TITLE,
        theme: "warning"
      });
      if (!ok) {
        return;
      }
    }
    this.isSaving = true;
    try {
      const result = await saveAnswers({
        recordId: this._recordId,
        answersJson: JSON.stringify(Object.values(this.answers)),
        isFinal: true
      });
      this.applyErrors(result);
      if (!result?.success) {
        this.toast(FIX_ERRORS, "error");
        return;
      }
      this.pending = {};
      this.offline = false;
      this.failMessage = undefined;
      this.serverSaved = true;
      this.submitted = true;
      clearDraft(this.storeKey);
      this.draftSaved = false;
      this.toast(SUBMITTED, "success");
    } catch (e) {
      this.offline = true;
      this.failMessage = e?.body?.message || SAVE_FAILED;
    } finally {
      this.isSaving = false;
    }
  }

  toast(message, variant) {
    this.dispatchEvent(new ShowToastEvent({ message, variant }));
  }
}
