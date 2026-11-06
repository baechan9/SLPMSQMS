/**
 * @description KPI 값 규칙(CMN-00-DWH-003 BR-1). Mule이 Snowflake `MART.V_SF_KPI_*` 뷰를 외부 키(KPI·기간·차원 해시)로
 * upsert한다. 값·신호 판정은 Snowflake가 하고 Salesforce는 화면에 보일 값만 보관한다.
 * - Name: 사람이 읽는 제목 `{KPI 키} {기간 단위} {기간 시작}`(목록·검색용, 저장할 때마다 다시 만든다)
 * - 13개월 초과 값 삭제 배치는 상세 기능 단계(B)에서 더한다(결정 O-2).
 * @group CMN-00-DWH-003
 */
public with sharing class CMN_KpiValueService {
  private static final Integer NAME_MAX = 80;

  /**
   * @description 저장 전 정리: 이름을 KPI 키·기간으로 채운다(SOQL 없음, 일괄 적재 200건 기준).
   * @param kpiValues 저장할 KPI 값
   */
  public static void prepare(List<CMN_KpiValue__c> kpiValues) {
    for (CMN_KpiValue__c v : kpiValues) {
      v.Name = titleOf(v);
    }
  }

  /**
   * @description 목록에 보일 제목. 기간 시작은 언어와 무관하게 yyyy-MM-dd로 쓴다.
   * @param v KPI 값
   * @return 제목(최대 80자)
   */
  @TestVisible
  private static String titleOf(CMN_KpiValue__c v) {
    List<String> parts = new List<String>();
    for (String p : new List<String>{ v.KpiKey__c, v.PeriodType__c }) {
      if (String.isNotBlank(p)) {
        parts.add(p.trim());
      }
    }
    Date d = v.PeriodStart__c;
    if (d != null) {
      parts.add(
        d.year() +
          '-' +
          String.valueOf(d.month()).leftPad(2, '0') +
          '-' +
          String.valueOf(d.day()).leftPad(2, '0')
      );
    }
    return String.join(parts, ' ').left(NAME_MAX);
  }
}
