-- QDW 버전 관리 시작점(CMN-00-ARC-001). 스키마(RAW·STG·CORE·MART·ML·SHARE), 웨어하우스, 역할,
-- Resource Monitor는 CMN-00-DWH-001이 V002부터 만든다. 이 스크립트는 이력 테이블 생성과 접속 확인만 한다.
SELECT CURRENT_ACCOUNT(), CURRENT_ROLE(), CURRENT_DATABASE();
