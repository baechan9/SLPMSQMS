import { LightningElement, api } from "lwc";
import getCodes from "@salesforce/apex/CMN_CodePickerController.getCodes";
import LEVEL from "@salesforce/label/c.CMN_CodePicker_Level";
import PLACEHOLDER from "@salesforce/label/c.CMN_CodePicker_Placeholder";
import EMPTY from "@salesforce/label/c.CMN_CodePicker_Empty";
import LOAD_ERROR from "@salesforce/label/c.CMN_CodePicker_LoadError";
import LOADING from "@salesforce/label/c.CMN_CodePicker_Loading";

/**
 * 계층형 공통 코드 연쇄 선택(CMN-00-MDM-007).
 * 대→중→소 순서로 고르고, 리프(하위가 없거나 maxLevel에 닿은 코드)를 고르면 value가 정해진다.
 * 비활성 코드와 그 하위, 사용자 언어 표시명은 서버(CMN_CodePickerController)가 정한다.
 * change 이벤트 detail: { value: 리프 코드 Id 또는 null, path: 표시 경로, externalKey: 코드 경로 }
 */
export default class CmnCodePicker extends LightningElement {
  /** 코드 그룹(예: DEFECT_TYPE) */
  @api groupCode;
  /** 첫 단계 콤보박스 라벨(필드 이름) */
  @api label;
  @api required = false;
  @api disabled = false;

  labels = { placeholder: PLACEHOLDER, empty: EMPTY, loading: LOADING };
  isLoading = true;
  errorMessage;
  codes = [];
  groupMaxLevel;
  selectedIds = [];
  _value;
  _maxLevel;

  /** 이 화면에서 쓸 최대 단계(그룹 최대 단계보다 작게만 줄일 수 있다) */
  @api
  get maxLevel() {
    return this._maxLevel;
  }
  set maxLevel(v) {
    this._maxLevel = v ? Number(v) : undefined;
  }

  /** 선택된 리프 코드 Id */
  @api
  get value() {
    return this._value;
  }
  set value(v) {
    this._value = v;
    this.selectedIds = this.chainOf(v);
  }

  connectedCallback() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    this.errorMessage = undefined;
    try {
      const data = await getCodes({ groupCode: this.groupCode });
      this.codes = data?.codes ?? [];
      this.groupMaxLevel = data?.maxLevel;
      this.selectedIds = this.chainOf(this._value);
    } catch {
      // 서버 원문은 보이지 않고 라벨 문구만(서버가 원인을 로그로 남긴다)
      this.codes = [];
      this.errorMessage = LOAD_ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  get isEmpty() {
    return !this.isLoading && !this.errorMessage && this.codes.length === 0;
  }

  get hasCodes() {
    return !this.isLoading && !this.errorMessage && this.codes.length > 0;
  }

  get effectiveMaxLevel() {
    const group = this.groupMaxLevel ?? 4;
    return this._maxLevel ? Math.min(this._maxLevel, group) : group;
  }

  /** 화면에 보일 단계: 1단계와, 선택한 코드에 하위가 있으면 다음 단계 */
  get levels() {
    const out = [];
    let parentId = null;
    for (let level = 1; level <= this.effectiveMaxLevel; level++) {
      const options = this.childrenOf(parentId).map((c) => ({
        label: c.label,
        value: c.id
      }));
      if (options.length === 0) {
        break;
      }
      const value = this.selectedIds[level - 1] ?? null;
      out.push({
        key: `level-${level}`,
        level,
        label:
          level === 1
            ? this.label || LEVEL.replace("{0}", level)
            : LEVEL.replace("{0}", level),
        options,
        value,
        required: this.required && level === 1
      });
      if (!value) {
        break;
      }
      parentId = value;
    }
    return out;
  }

  handleChange(event) {
    const level = Number(event.target.dataset.level);
    const id = event.detail.value;
    this.selectedIds = [...this.selectedIds.slice(0, level - 1), id];
    const isLeaf =
      level >= this.effectiveMaxLevel || this.childrenOf(id).length === 0;
    this._value = isLeaf ? id : null;
    const code = isLeaf ? this.codes.find((c) => c.id === id) : null;
    this.dispatchEvent(
      new CustomEvent("change", {
        detail: {
          value: this._value,
          path: code?.path ?? null,
          externalKey: code?.externalKey ?? null
        }
      })
    );
  }

  childrenOf(parentId) {
    return this.codes.filter((c) => (c.parentId ?? null) === parentId);
  }

  /** 리프 Id → 뿌리부터의 Id 목록(초기 값 표시) */
  chainOf(leafId) {
    const chain = [];
    let cur = this.codes.find((c) => c.id === leafId);
    while (cur) {
      chain.unshift(cur.id);
      const parentId = cur.parentId;
      cur = parentId ? this.codes.find((c) => c.id === parentId) : null;
    }
    return chain;
  }
}
