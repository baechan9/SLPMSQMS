import { createElement } from "lwc";
import CmnDocumentPanel from "c/cmnDocumentPanel";
import getPanel from "@salesforce/apex/CMN_DocumentController.getPanel";
import registerFiles from "@salesforce/apex/CMN_DocumentController.registerFiles";
import registerLink from "@salesforce/apex/CMN_DocumentController.registerLink";
import submitDocument from "@salesforce/apex/CMN_DocumentController.submitDocument";

// 탐색 호출을 기록하는 목(기본 스텁은 아무것도 하지 않는다)
const mockNavigate = jest.fn();
jest.mock("lightning/navigation", () => {
  const Navigate = Symbol("Navigate");
  const NavigationMixin = (Base) =>
    class extends Base {
      [Navigate](pageRef) {
        mockNavigate(pageRef);
      }
    };
  NavigationMixin.Navigate = Navigate;
  return { __esModule: true, NavigationMixin };
});
jest.mock(
  "@salesforce/apex/CMN_DocumentController.getPanel",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_DocumentController.registerFiles",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_DocumentController.registerLink",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CMN_DocumentController.submitDocument",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const REV1 = {
  id: "a0R000000000001AAA",
  revisionNo: 2,
  status: "RELEASED",
  statusLabel: "Released",
  storageType: "SF_FILE",
  fileName: "8d.pdf",
  contentDocumentId: "069000000000001AAA",
  duplicate: true,
  createdByName: "Kim",
  createdDate: "2026-11-02T00:00:00.000Z"
};
const PANEL = {
  canRead: true,
  canEdit: true,
  maxFileMb: 50,
  classes: [
    {
      classId: "a0C000000000001AAA",
      code: "8D_REPORT",
      label: "8D Report",
      required: false,
      missing: false,
      linkOnly: false,
      multiFile: false,
      documents: [
        {
          id: "a0D000000000001AAA",
          name: "8D Report",
          deliverableType: "ATTACHMENT",
          canSubmit: false,
          current: REV1,
          revisions: [
            REV1,
            {
              ...REV1,
              id: "a0R000000000002AAA",
              revisionNo: 1,
              duplicate: false
            }
          ]
        }
      ]
    },
    {
      classId: "a0C000000000002AAA",
      code: "PPAP_PSW",
      label: "PSW",
      required: true,
      missing: true,
      linkOnly: false,
      multiFile: false,
      templateDocumentId: "069000000000009AAA",
      documents: [
        {
          id: "a0D000000000002AAA",
          name: "PSW",
          deliverableType: "APPROVAL",
          canSubmit: true,
          current: null,
          revisions: [
            {
              id: "a0R000000000003AAA",
              revisionNo: 1,
              status: "DRAFT",
              statusLabel: "Draft",
              storageType: "PDM",
              externalRef: "PSW-1"
            }
          ]
        }
      ]
    },
    {
      classId: "a0C000000000003AAA",
      code: "DRAWING",
      label: "Drawing",
      linkOnly: true,
      documents: []
    }
  ]
};

async function mount(panel = PANEL) {
  getPanel.mockResolvedValue(panel);
  const el = createElement("c-cmn-document-panel", { is: CmnDocumentPanel });
  el.recordId = "a01000000000001AAA";
  el.allowedDocClasses = "8D_REPORT,PPAP_PSW,DRAWING";
  el.requiredDocClasses = "PPAP_PSW";
  document.body.appendChild(el);
  await flush();
  return el;
}

const q = (el, sel) => el.shadowRoot.querySelector(sel);
const qa = (el, sel) => [...el.shadowRoot.querySelectorAll(sel)];

describe("c-cmn-document-panel", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("분류별 현재 리비전·중복 경고·필수 누락·양식을 보인다", async () => {
    const el = await mount();
    expect(getPanel).toHaveBeenCalledWith({
      parentId: "a01000000000001AAA",
      allowedDocClasses: "8D_REPORT,PPAP_PSW,DRAWING",
      requiredDocClasses: "PPAP_PSW"
    });
    // 문서 없는 비필수 분류(DRAWING)는 숨긴다
    expect(qa(el, "[data-class]").map((d) => d.dataset.class)).toEqual([
      "8D_REPORT",
      "PPAP_PSW"
    ]);
    expect(q(el, "[data-id=duplicate]")).not.toBeNull();
    expect(q(el, "[data-id=missing]")).not.toBeNull();
    expect(q(el, "a[href*='069000000000009AAA']")).not.toBeNull();
    // 업로드 분류에서 링크 전용은 빠진다
    expect(q(el, "lightning-combobox[data-id=class]").options.length).toBe(2);
  });

  it("업로드가 끝나면 서버에 등록하고 다시 불러온다", async () => {
    const el = await mount();
    const combo = q(el, "lightning-combobox[data-id=class]");
    combo.dispatchEvent(
      new CustomEvent("change", { detail: { value: "a0C000000000001AAA" } })
    );
    await flush();
    expect(q(el, "lightning-file-upload").disabled).toBe(false);
    registerFiles.mockResolvedValue({ results: [] });
    q(el, "lightning-file-upload").dispatchEvent(
      new CustomEvent("uploadfinished", {
        detail: { files: [{ documentId: "069000000000005AAA" }] }
      })
    );
    await flush();
    expect(registerFiles).toHaveBeenCalledWith({
      parentId: "a01000000000001AAA",
      docClassId: "a0C000000000001AAA",
      contentDocumentIds: ["069000000000005AAA"],
      changeNote: "",
      supplierVisible: false
    });
    expect(getPanel).toHaveBeenCalledTimes(2);
  });

  it("크기 초과 응답은 등록 없이 안내한다", async () => {
    const el = await mount();
    const handler = jest.fn();
    el.addEventListener("lightning__showtoast", handler);
    registerFiles.mockResolvedValue({ results: [], error: "over 50MB" });
    q(el, "lightning-file-upload").dispatchEvent(
      new CustomEvent("uploadfinished", {
        detail: { files: [{ documentId: "069000000000005AAA" }] }
      })
    );
    await flush();
    expect(handler.mock.calls[0][0].detail.message).toBe("over 50MB");
    expect(getPanel).toHaveBeenCalledTimes(1);
  });

  it("https가 아닌 링크는 링크로 그리지 않는다", async () => {
    const bad = JSON.parse(JSON.stringify(PANEL));
    bad.classes[1].documents[0].current = {
      id: "a0R000000000009AAA",
      revisionNo: 1,
      status: "RELEASED",
      storageType: "URL",
      // 악성 링크 입력 예시(렌더링되지 않아야 한다)
      // eslint-disable-next-line no-script-url
      url: "javascript:alert(1)",
      fileName: "x"
    };
    bad.classes[1].documents[0].revisions = [
      bad.classes[1].documents[0].current
    ];
    const el = await mount(bad);
    expect(q(el, "a[target=_blank]")).toBeNull();
  });

  it("크기 초과 등 서버 오류는 토스트로 알린다", async () => {
    const el = await mount();
    const handler = jest.fn();
    el.addEventListener("lightning__showtoast", handler);
    registerFiles.mockRejectedValue({ body: { message: "too large" } });
    q(el, "lightning-file-upload").dispatchEvent(
      new CustomEvent("uploadfinished", {
        detail: { files: [{ documentId: "069000000000005AAA" }] }
      })
    );
    await flush();
    expect(handler.mock.calls[0][0].detail.message).toBe("too large");
  });

  it("링크를 등록한다", async () => {
    const el = await mount();
    q(el, "lightning-button[data-id=toggle-link]").click();
    await flush();
    const set = (field, value) =>
      q(el, `[data-field=${field}]`).dispatchEvent(
        new CustomEvent("change", { detail: { value } })
      );
    set("classId", "a0C000000000003AAA");
    set("storageType", "PDM");
    set("externalRef", "DWG-1");
    registerLink.mockResolvedValue({});
    q(el, "lightning-button[data-id=save-link]").click();
    await flush();
    expect(registerLink).toHaveBeenCalledWith({
      parentId: "a01000000000001AAA",
      docClassId: "a0C000000000003AAA",
      storageType: "PDM",
      url: null,
      externalRef: "DWG-1",
      title: null,
      changeNote: null
    });
  });

  it("이력 펼치기, 파일 미리보기, 결재 상신", async () => {
    const el = await mount();
    const historyButtons = qa(el, "lightning-button").filter(
      (b) => b.label === "c.CMN_Doc_History"
    );
    historyButtons[0].click();
    await flush();
    expect(qa(el, "[data-id=history] li").length).toBe(2);

    q(el, "lightning-button[data-file]").click();
    expect(mockNavigate.mock.calls[0][0].state.selectedRecordId).toBe(
      "069000000000001AAA"
    );

    submitDocument.mockResolvedValue("a0K000000000001AAA");
    qa(el, "lightning-button")
      .find((b) => b.label === "c.CMN_Doc_Submit")
      .click();
    await flush();
    expect(submitDocument).toHaveBeenCalledWith({
      documentId: "a0D000000000002AAA",
      comment: null
    });
  });

  it("부모를 볼 수 없으면 안내, 편집 권한이 없으면 업로드 영역이 없다", async () => {
    let el = await mount({ canRead: false, canEdit: false, classes: [] });
    expect(q(el, "[data-id=no-access]")).not.toBeNull();
    document.body.removeChild(el);
    el = await mount({ ...PANEL, canEdit: false });
    expect(q(el, "[data-id=upload]")).toBeNull();
  });

  it("조회 오류", async () => {
    getPanel.mockRejectedValue({});
    const el = createElement("c-cmn-document-panel", { is: CmnDocumentPanel });
    document.body.appendChild(el);
    await flush();
    expect(q(el, "p[role=alert]").textContent).toBe(
      "c.CMN_Common_UnexpectedError"
    );
  });
});
