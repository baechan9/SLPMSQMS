const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
  ...jestConfig,
  // 데모 목 응답을 경로 별칭으로 읽는다: import mock from "@demo/mocks/apex/qmsIqcQueue/KR01.json"
  moduleNameMapper: {
    ...jestConfig.moduleNameMapper,
    "^@demo/(.*)$": "<rootDir>/data/demo/$1",
    // sfdx-lwc-jest에 없는 기본 모듈 대체(UX-006 붙여넣기 대화상자 등 LightningModal)
    "^lightning/modal$": "<rootDir>/jest-mocks/lightning/modal/modal"
  },
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver"]
};
