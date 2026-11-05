/**
 * 브라우저 임시 저장(CMN-00-UX-006 BR-2, UX-008·009도 쓴다).
 * 저장하지 않은 화면 입력을 사용자 브라우저(localStorage)에 남겨, 창을 닫았다 다시 열어도 복원할 수 있게 한다.
 * - 키 = draftKey(사용자 Id, 화면 키, 레코드 Id …). 다른 사용자·레코드의 초안과 섞이지 않는다.
 * - 보관 기간(기본 14일, 저장할 때 화면별로 지정 — 현장 입력·체크리스트는 7일)이 지난 초안은 읽을 때와 저장할 때 지운다.
 * - 저장소를 쓸 수 없는 환경(사생활 보호 모드, 용량 초과, 차단)에서는 조용히 실패한다. 초안은 편의 기능이라 업무를 막지 않는다.
 * 서버 데이터가 아니므로 공유·보관용으로 쓰지 않는다.
 */
const PREFIX = "cmnDraft:";
const VERSION = 1;
export const DRAFT_TTL_MS = 14 * 24 * 60 * 60 * 1000;

function storage() {
  try {
    return window.localStorage ?? null;
  } catch {
    return null;
  }
}

/**
 * 초안 키를 만든다.
 * @param {...any} parts 사용자 Id, 화면 키, 레코드 Id 등
 * @returns {string} 키
 */
export function draftKey(...parts) {
  return PREFIX + parts.map((p) => String(p ?? "")).join(":");
}

function expired(d) {
  return !d || Date.now() - d.savedAt > (d.ttl ?? DRAFT_TTL_MS);
}

/**
 * 초안을 저장한다.
 * @param {string} key draftKey 결과
 * @param {object} payload JSON으로 바꿀 수 있는 값
 * @param {number} ttlMs 보관 기간(밀리초, 기본 14일)
 * @returns {boolean} 저장했으면 true
 */
export function saveDraft(key, payload, ttlMs = DRAFT_TTL_MS) {
  const s = storage();
  if (!s || !key) {
    return false;
  }
  try {
    s.setItem(
      key,
      JSON.stringify({ v: VERSION, savedAt: Date.now(), ttl: ttlMs, payload })
    );
    pruneDrafts();
    return true;
  } catch {
    return false;
  }
}

/**
 * 초안을 읽는다. 없거나 만료·형식 오류면 null(만료·형식 오류는 지운다).
 * @param {string} key draftKey 결과
 * @returns {object|null} 저장한 값
 */
export function loadDraft(key) {
  const s = storage();
  if (!s || !key) {
    return null;
  }
  try {
    const raw = s.getItem(key);
    if (!raw) {
      return null;
    }
    const d = JSON.parse(raw);
    if (!d || d.v !== VERSION || expired(d)) {
      s.removeItem(key);
      return null;
    }
    return d.payload ?? null;
  } catch {
    clearDraft(key);
    return null;
  }
}

/**
 * 초안을 지운다(저장 성공·변경 취소·복원 거절).
 * @param {string} key draftKey 결과
 */
export function clearDraft(key) {
  const s = storage();
  if (!s || !key) {
    return;
  }
  try {
    s.removeItem(key);
  } catch {
    // 저장소를 쓸 수 없으면 지울 초안도 없다
  }
}

/**
 * 만료된 초안을 모두 지운다.
 * @returns {number} 지운 개수
 */
export function pruneDrafts() {
  const s = storage();
  if (!s) {
    return 0;
  }
  const stale = [];
  try {
    for (let i = 0; i < s.length; i++) {
      const key = s.key(i);
      if (key?.startsWith(PREFIX)) {
        const d = safeParse(s.getItem(key));
        if (expired(d)) {
          stale.push(key);
        }
      }
    }
    stale.forEach((key) => s.removeItem(key));
  } catch {
    return 0;
  }
  return stale.length;
}

function safeParse(raw) {
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}
