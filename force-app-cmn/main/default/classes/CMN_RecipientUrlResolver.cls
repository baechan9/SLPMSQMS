/**
 * @description 알림 링크 변환(CMN-00-NTF-001 BR-5, 검토 반영 Vol.3). 포털 수신자에게 보낼 링크를 만든다.
 * CMN이 QMS 클래스를 직접 참조하지 않도록 구현 클래스 이름을 CMN 설정 `CMN_NTF_PORTAL_URL_RESOLVER`에 등록한다
 * (QMS-03-SPP-001 `QMS_PortalUrlResolver`). 알림 묶음(최대 CMN_NTF_CHUNK_SIZE명) 전체를 한 번에 넘기므로 구현은 SOQL을 한 번만 쓴다.
 * @group CMN-00-NTF-001
 */
public interface CMN_RecipientUrlResolver {
  /**
   * @description 레코드별 포털 수신자 링크.
   * @param portalUsersByRecord 알림 레코드 Id → 포털 수신자
   * @return 알림 레코드 Id → (수신자 Id → URL). 없는 수신자는 사내 링크를 쓴다
   */
  Map<Id, Map<Id, String>> urlsFor(Map<Id, Set<Id>> portalUsersByRecord);
}
