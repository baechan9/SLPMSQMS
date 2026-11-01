const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
  ...jestConfig,
  // 데모 목 응답을 경로 별칭으로 읽는다: import mock from "@demo/mocks/apex/qmsIqcQueue/KR01.json"
  moduleNameMapper: {
    ...jestConfig.moduleNameMapper,
    "^@demo/(.*)$": "<rootDir>/data/demo/$1"
  },
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver"]
};
