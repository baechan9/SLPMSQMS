/**
 * @description 품질 특성 규칙과 버전 관리(CMN-00-MDM-006).
 * - BR-2: 목표 Cpk가 비면 CC 1.67, 그 외 1.33.
 * - BR-3: ACTIVE 규격은 고칠 수 없다(검증 규칙). 새 버전(DRAFT)을 만들어 활성화하면 같은 품번·특성 번호의 이전 ACTIVE가
 *   새 시작일 전날로 닫히고 OBSOLETE가 된다 — "언제 어떤 규격으로 판정했는가"를 재현한다.
 * 상태(Status__c)는 사용자 FLS 읽기 전용이라 이 서비스가 시스템 모드로 바꾼다.
 * @group CMN-00-MDM-006
 */
public with sharing class CMN_CharacteristicService {
  public static final String DRAFT = 'DRAFT';
  public static final String ACTIVE = 'ACTIVE';
  public static final String OBSOLETE = 'OBSOLETE';
  @TestVisible
  private static final Decimal CPK_CC = 1.67;
  @TestVisible
  private static final Decimal CPK_DEFAULT = 1.33;

  /**
   * @description 저장 전: 목표 Cpk 기본값과 외부 키 {ItemNo}-{CharNo}-{yyyymmdd}(시작일이 없으면 -DRAFT), 중복 차단.
   * @param records 저장할 특성(before insert·update)
   */
  public static void prepare(List<CMN_Characteristic__c> records) {
    Set<Id> itemIds = new Set<Id>();
    for (CMN_Characteristic__c c : records) {
      if (c.TargetCpk__c == null) {
        c.TargetCpk__c = c.SpecialClass__c == 'CC' ? CPK_CC : CPK_DEFAULT;
      }
      itemIds.add(c.Item__c);
    }
    Map<Id, CMN_Item__c> items = CMN_ItemSelector.itemsById(itemIds);
    for (CMN_Characteristic__c c : records) {
      CMN_Item__c i = items.get(c.Item__c);
      if (i == null || String.isBlank(c.CharNo__c)) {
        continue;
      }
      c.CharNo__c = c.CharNo__c.trim();
      c.ExternalKey__c =
        i.ItemNo__c +
        '-' +
        c.CharNo__c +
        '-' +
        (c.EffectiveFrom__c == null
          ? DRAFT
          : Datetime.newInstance(
                c.EffectiveFrom__c,
                Time.newInstance(0, 0, 0, 0)
              )
              .format('yyyyMMdd'));
    }
    CMN_KeyGuard.rejectDuplicates(
      records,
      CMN_Characteristic__c.ExternalKey__c,
      CMN_Characteristic__c.CharNo__c,
      CMN_Characteristic__c.ExternalKey__c,
      Label.CMN_Char_DuplicateVersion
    );
  }

  /**
   * @description 초안만 삭제할 수 있다(활성·폐기 특성은 판정 이력의 규격 근거).
   * @param records Trigger.old
   */
  public static void preventDeleteUnlessDraft(
    List<CMN_Characteristic__c> records
  ) {
    for (CMN_Characteristic__c c : records) {
      if (c.Status__c != DRAFT) {
        c.addError(Label.CMN_Char_DeleteOnlyDraft);
      }
    }
  }

  /**
   * @description ACTIVE 특성의 새 버전(DRAFT)을 만든다. 규격은 복사하고 사용자가 초안에서 고친 뒤 활성화한다.
   * @param sourceId ACTIVE 특성
   * @param effectiveFrom 새 버전 적용 시작일(현재 버전 시작일 이후)
   * @return 새 초안 Id
   * @throws CMN_ValidationException ACTIVE가 아니거나 시작일이 없거나 이르면
   */
  public static Id newVersion(Id sourceId, Date effectiveFrom) {
    List<CMN_Characteristic__c> found = CMN_CharacteristicSelector.byIds(
      new Set<Id>{ sourceId }
    );
    if (found.isEmpty() || found[0].Status__c != ACTIVE) {
      throw new CMN_ValidationException(Label.CMN_Char_NotActive);
    }
    CMN_Characteristic__c src = found[0];
    if (effectiveFrom == null) {
      throw new CMN_ValidationException(Label.CMN_Char_FromRequired);
    }
    if (src.EffectiveFrom__c != null && effectiveFrom <= src.EffectiveFrom__c) {
      throw new CMN_ValidationException(Label.CMN_Char_NewVersionMustBeLater);
    }
    CMN_Characteristic__c draft = new CMN_Characteristic__c(
      Name = src.Name,
      Item__c = src.Item__c,
      CharNo__c = src.CharNo__c,
      CharType__c = src.CharType__c,
      Nominal__c = src.Nominal__c,
      USL__c = src.USL__c,
      LSL__c = src.LSL__c,
      Unit__c = src.Unit__c,
      SpecialClass__c = src.SpecialClass__c,
      CustomerSymbol__c = src.CustomerSymbol__c,
      SpcRequired__c = src.SpcRequired__c,
      TargetCpk__c = src.TargetCpk__c,
      EffectiveFrom__c = effectiveFrom
    );
    // 상태는 기본값 DRAFT, 외부 키는 트리거. 사용자가 만들 수 있는 필드만 넣어 사용자 모드로 저장한다
    Database.insert(draft, AccessLevel.USER_MODE);
    return draft.Id;
  }

  /**
   * @description 초안을 활성화하고 같은 품번·특성 번호의 이전 ACTIVE 버전을 새 시작일 전날로 닫는다.
   * @param draftIds 활성화할 초안
   * @throws CMN_ValidationException 초안이 아니거나 시작일이 없거나 이전 버전보다 이르면
   */
  public static void activate(Set<Id> draftIds) {
    List<CMN_Characteristic__c> drafts = CMN_CharacteristicSelector.byIds(
      draftIds
    );
    Set<Id> itemIds = new Set<Id>();
    Set<String> charNos = new Set<String>();
    for (CMN_Characteristic__c d : drafts) {
      if (d.Status__c != DRAFT) {
        throw new CMN_ValidationException(Label.CMN_Char_NotDraft);
      }
      if (d.EffectiveFrom__c == null) {
        throw new CMN_ValidationException(Label.CMN_Char_FromRequired);
      }
      itemIds.add(d.Item__c);
      charNos.add(d.CharNo__c);
    }
    Map<String, CMN_Characteristic__c> draftByKey = new Map<String, CMN_Characteristic__c>();
    List<CMN_Characteristic__c> changes = new List<CMN_Characteristic__c>();
    for (CMN_Characteristic__c d : drafts) {
      draftByKey.put(d.Item__c + '|' + d.CharNo__c, d);
      changes.add(new CMN_Characteristic__c(Id = d.Id, Status__c = ACTIVE));
    }
    for (
      CMN_Characteristic__c old : CMN_CharacteristicSelector.activeVersions(
        itemIds,
        charNos
      )
    ) {
      CMN_Characteristic__c d = draftByKey.get(
        old.Item__c + '|' + old.CharNo__c
      );
      if (d == null) {
        continue;
      }
      if (
        old.EffectiveFrom__c != null &&
        d.EffectiveFrom__c <= old.EffectiveFrom__c
      ) {
        throw new CMN_ValidationException(Label.CMN_Char_NewVersionMustBeLater);
      }
      changes.add(
        new CMN_Characteristic__c(
          Id = old.Id,
          Status__c = OBSOLETE,
          EffectiveTo__c = d.EffectiveFrom__c.addDays(-1)
        )
      );
    }
    Database.update(changes, AccessLevel.SYSTEM_MODE);
  }
}
