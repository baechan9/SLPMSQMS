import LightningDatatable from "lightning/datatable";
import picklistView from "./picklistView.html";
import picklistEdit from "./picklistEdit.html";
import referenceView from "./referenceView.html";
import lookupEdit from "./lookupEdit.html";
import codeEdit from "./codeEdit.html";
import rowStateView from "./rowStateView.html";

/**
 * 공통 편집 그리드의 표(CMN-00-UX-006 BR-8). lightning-datatable(인라인 편집·draft-values·errors)에
 * 선택 목록·참조·공통 코드 셀과 행 상태 열을 커스텀 타입(보기·편집 템플릿)으로 더한다. 키보드 이동·편집은 표준 그대로다.
 */
export default class CmnGridDatatable extends LightningDatatable {
  static customTypes = {
    cmnPicklist: {
      template: picklistView,
      editTemplate: picklistEdit,
      standardCellLayout: true,
      typeAttributes: ["options", "fieldLabel", "required"]
    },
    cmnLookup: {
      template: referenceView,
      editTemplate: lookupEdit,
      standardCellLayout: true,
      typeAttributes: [
        "display",
        "referenceTo",
        "filter",
        "fieldLabel",
        "required"
      ]
    },
    cmnCode: {
      template: referenceView,
      editTemplate: codeEdit,
      standardCellLayout: true,
      typeAttributes: ["display", "codeGroup", "fieldLabel", "required"]
    },
    cmnRowState: {
      template: rowStateView,
      standardCellLayout: true,
      typeAttributes: ["icon", "warning"]
    }
  };
}
