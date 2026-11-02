/**
 * 이미지 축소 공통 모듈(CMN-00-UX-001 BR-4). 업로드 전에 장변을 1920px 이하 JPEG로 줄여 통신·저장 비용을 줄인다.
 * 화면 없는 서비스 모듈이라 다른 LWC가 import해서 쓴다.
 */
export const MAX_EDGE = 1920;

/**
 * 비율을 지키며 장변이 maxEdge 이하가 되는 크기. 이미 작으면 그대로.
 * @param {number} width 원본 너비
 * @param {number} height 원본 높이
 * @param {number} maxEdge 장변 한도
 * @returns {{width: number, height: number}} 새 크기
 */
export function fitWithin(width, height, maxEdge = MAX_EDGE) {
  const longEdge = Math.max(width, height);
  if (!longEdge || longEdge <= maxEdge) {
    return { width, height };
  }
  const scale = maxEdge / longEdge;
  return {
    width: Math.round(width * scale),
    height: Math.round(height * scale)
  };
}

/**
 * 확장자를 .jpg로 바꾼 파일명.
 * @param {string} name 원본 이름
 * @returns {string} JPEG 파일명
 */
export function jpegName(name) {
  const base = (name || "photo").replace(/\.[^.]+$/, "");
  return `${base}.jpg`;
}

function loadImage(file) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      resolve(img);
    };
    img.onerror = (e) => {
      URL.revokeObjectURL(url);
      reject(e);
    };
    img.src = url;
  });
}

/**
 * 이미지 파일을 장변 maxEdge 이하 JPEG(base64)로 줄인다.
 * @param {File} file 카메라·갤러리 파일
 * @param {number} maxEdge 장변 한도
 * @param {number} quality JPEG 품질(0~1)
 * @returns {Promise<{fileName: string, base64: string, width: number, height: number}>} 축소 결과
 */
export async function resizeImage(file, maxEdge = MAX_EDGE, quality = 0.85) {
  const img = await loadImage(file);
  const { width, height } = fitWithin(
    img.naturalWidth || img.width,
    img.naturalHeight || img.height,
    maxEdge
  );
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  canvas.getContext("2d").drawImage(img, 0, 0, width, height);
  const dataUrl = canvas.toDataURL("image/jpeg", quality);
  return {
    fileName: jpegName(file.name),
    base64: dataUrl.substring(dataUrl.indexOf(",") + 1),
    width,
    height
  };
}
