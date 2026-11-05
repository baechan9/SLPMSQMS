import { LightningElement, api } from "lwc";
import TODAY from "@salesforce/label/c.CMN_Grid_ScheduleToday";
import NO_DATES from "@salesforce/label/c.CMN_Grid_ScheduleNoDates";
import EMPTY from "@salesforce/label/c.CMN_Grid_ScheduleEmpty";
import PERIOD from "@salesforce/label/c.CMN_Grid_SchedulePeriod";

const DAY_MS = 24 * 60 * 60 * 1000;
const MAX_TICK_LABELS = 26;

function toDay(iso) {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso ?? "");
  return m
    ? Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3])) / DAY_MS
    : null;
}

function format(template, ...args) {
  return args.reduce((s, a, i) => s.replace(`{${i}}`, a), template);
}

/**
 * 일정 막대 보기(CMN-00-UX-006 BR-6). 주 단위 눈금, 오늘 선, 행별 막대(시작~종료)를 CSS로 그린다(외부 라이브러리 없음).
 * 위치·폭은 기간 대비 %라 화면 폭에 맞춰 늘고 준다. 막대를 끌어 날짜를 바꾸지 않는다(날짜는 표 보기 셀로 편집).
 * 경고(종료일 경과 등, Provider 행 메타)는 아이콘과 문구로 함께 보인다.
 * rows: [{ key, label, start(yyyy-mm-dd), end, warning, deleted }]
 */
export default class CmnGridSchedule extends LightningElement {
  @api rows = [];
  @api locale;
  @api today;

  get todayDay() {
    if (this.today) {
      return toDay(this.today);
    }
    const now = new Date();
    return Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()) / DAY_MS;
  }

  get model() {
    const live = (this.rows ?? []).filter((r) => !r.deleted);
    const dated = live
      .map((r) => ({ ...r, s: toDay(r.start), e: toDay(r.end) }))
      .filter((r) => r.s !== null && r.e !== null);
    const undated = live.length - dated.length;
    if (!dated.length) {
      return { empty: true, undated, bars: [], ticks: [] };
    }
    const min = Math.min(...dated.map((r) => Math.min(r.s, r.e)));
    const max = Math.max(...dated.map((r) => Math.max(r.s, r.e)));
    // 월요일 시작 주(1970-01-01은 목요일)
    const start = min - ((min + 3) % 7);
    const end = max + (6 - ((max + 3) % 7));
    const total = end - start + 1;
    const pct = (d) => ((d - start) / total) * 100;
    const weeks = Math.ceil(total / 7);
    const every = Math.max(1, Math.ceil(weeks / MAX_TICK_LABELS));
    const fmt = new Intl.DateTimeFormat(this.locale || undefined, {
      month: "2-digit",
      day: "2-digit",
      timeZone: "UTC"
    });
    const ticks = [];
    for (let i = 0; i < weeks; i++) {
      const day = start + i * 7;
      ticks.push({
        key: `w${i}`,
        label: i % every === 0 ? fmt.format(new Date(day * DAY_MS)) : "",
        style: `left: ${pct(day)}%;`
      });
    }
    const today = this.todayDay;
    const bars = dated.map((r) => {
      const from = Math.min(r.s, r.e);
      const to = Math.max(r.s, r.e);
      const width = Math.max(((to - from + 1) / total) * 100, 0.5);
      const period = format(PERIOD, r.start, r.end);
      return {
        key: r.key,
        label: r.label ?? "",
        warning: r.warning,
        period,
        title: [r.label, period, r.warning].filter(Boolean).join(" / "),
        barClass: `bar ${r.warning ? "slds-theme_warning" : "slds-theme_info"}`,
        style: `left: ${pct(from)}%; width: ${width}%;`
      };
    });
    return {
      empty: false,
      undated,
      ticks,
      bars,
      showToday: today >= start && today <= end,
      todayStyle: `left: ${pct(today)}%;`
    };
  }

  get labels() {
    return { today: TODAY, empty: EMPTY };
  }

  get undatedText() {
    const n = this.model.undated;
    return n ? format(NO_DATES, n) : "";
  }
}
