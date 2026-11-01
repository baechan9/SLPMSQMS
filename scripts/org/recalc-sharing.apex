// 데모·이관 적재 뒤 공장 그룹·구성원과 공유 설정 객체 전체의 공유를 다시 계산한다(CMN-00-SEC-002 BR-6).
// 공장 그룹은 공장 생성 후 비동기로 만들어져 직후에 적재된 레코드는 공유가 빠질 수 있다.
for (CMN_SharingConfig__mdt c : CMN_SharingConfig__mdt.getAll().values()) {
  if (c.IsActive__c) {
    System.debug('recalc ' + c.ObjectApiName__c + ' ' + CMN_SharingRecalcBatch.run(c.ObjectApiName__c));
  }
}
