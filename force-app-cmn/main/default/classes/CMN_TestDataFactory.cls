/**
 * @description 테스트 데이터 공장(개발 플랜 CR-4). 정적 리소스 QMS_DemoFixtures(data/demo/fixtures/demo_fixtures.json)의
 *              steps를 순서대로 레코드로 만든다. 데모 CSV와 같은 키·값이라 테스트와 데모가 같은 데이터를 본다.
 *              Org에 아직 없는 객체·필드의 단계·열은 건너뛰므로 페이즈가 진행돼 객체가 늘어도 그대로 쓴다.
 *              - 관계 열 `Field__r.ExtField`(표준 관계는 `Account.ExtField`)는 앞 단계에서 만든 레코드 Id로 바꾼다.
 *              - `{{ref:객체.외부키필드=값}}`, `{{user:사번}}` 토큰, RecordTypeDeveloperName 열을 바꾼다.
 *              - 이관 모드로 적재해 업무 핸들러가 기존 번호·상태를 유지한다(CMN_TriggerHandler.isMigrationMode).
 *              프로필은 이름이 아니라 라이선스로 찾는다(ko Org는 표준 프로필 이름이 한국어).
 * @group CMN-00-ARC-002
 */
@IsTest
public class CMN_TestDataFactory {
  public static final String RESOURCE = 'QMS_DemoFixtures';
  private static final Pattern REF = Pattern.compile(
    '\\{\\{ref:([A-Za-z0-9_]+)\\.([A-Za-z0-9_]+)=([^}]*)\\}\\}'
  );
  private static final Pattern USR = Pattern.compile(
    '\\{\\{user:([A-Z0-9]+)\\}\\}'
  );

  private static Map<String, Object> fixture;
  private static final Map<String, Id> REFS = new Map<String, Id>(); // 객체|외부키필드|값 → Id
  private static final Map<String, Id> USERS = new Map<String, Id>(); // 사번 → User Id
  private static final Map<String, Schema.SObjectType> GLOBAL_TYPES = Schema.getGlobalDescribe();

  /**
   * @description 배포된 객체의 모든 단계를 적재한다.
   */
  public static void loadFixtures() {
    loadFixtures(null);
  }

  /**
   * @description 지정 객체의 단계만 적재한다(null이면 배포된 전체).
   * @param objectApiNames 적재할 객체 API 이름
   */
  public static void loadFixtures(Set<String> objectApiNames) {
    Boolean before = CMN_TriggerHandler.permissionsOverride == null;
    if (before) {
      CMN_TriggerHandler.permissionsOverride = new Set<String>{
        CMN_TriggerHandler.MIGRATION_PERMISSION
      };
    }
    try {
      for (Object o : (List<Object>) data().get('steps')) {
        Map<String, Object> step = (Map<String, Object>) o;
        String obj = (String) step.get('object');
        if (objectApiNames != null && !objectApiNames.contains(obj)) {
          continue;
        }
        Schema.SObjectType t = GLOBAL_TYPES.get(obj.toLowerCase());
        if (t == null || obj == 'User') {
          continue;
        }
        loadStep(
          t,
          obj,
          (String) step.get('externalId'),
          (List<Object>) step.get('rows')
        );
      }
    } finally {
      if (before) {
        CMN_TriggerHandler.permissionsOverride = null;
      }
    }
  }

  /**
   * @description 픽스처로 만든 레코드 Id.
   * @param objectApiName 객체 API 이름
   * @param externalValue 그 단계 외부 키 값
   * @return Id(없으면 null)
   */
  public static Id idOf(String objectApiName, String externalValue) {
    for (String k : REFS.keySet()) {
      if (
        k.startsWith(objectApiName + '|') && k.endsWith('|' + externalValue)
      ) {
        return REFS.get(k);
      }
    }
    return null;
  }

  /**
   * @description 픽스처 사용자를 만든다(Profile은 라이선스로 선택, PSG가 배포돼 있으면 할당). Mixed DML을 피하려고 runAs 안에서 만든다.
   * @param employeeNos 사번(null이면 픽스처 전체)
   * @return 사번 → User
   */
  public static Map<String, User> createUsers(Set<String> employeeNos) {
    Map<String, User> created = new Map<String, User>();
    List<Map<String, Object>> defs = new List<Map<String, Object>>();
    for (Object o : (List<Object>) data().get('users')) {
      Map<String, Object> u = (Map<String, Object>) o;
      if (
        employeeNos == null ||
        employeeNos.contains((String) u.get('employeeNo'))
      ) {
        defs.add(u);
      }
    }
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Map<String, Schema.SObjectField> userFields = User.SObjectType.getDescribe(
          SObjectDescribeOptions.DEFERRED
        )
        .fields.getMap();
      Id profileId = profileIdForLicense('Salesforce Platform');
      for (Map<String, Object> d : defs) {
        String emp = (String) d.get('employeeNo');
        User u = newUser(emp, (String) d.get('name'), profileId);
        if (userFields.containsKey('employeeno__c')) {
          u.put('EmployeeNo__c', emp);
        }
        created.put(emp, u);
      }
      insert created.values();
      Set<String> psgNames = new Set<String>();
      for (Map<String, Object> d : defs) {
        for (Object p : (List<Object>) d.get('permissionSetGroups')) {
          psgNames.add((String) p);
        }
      }
      Map<String, Id> psgIds = new Map<String, Id>();
      for (PermissionSetGroup g : [
        SELECT Id, DeveloperName
        FROM PermissionSetGroup
        WHERE DeveloperName IN :psgNames
      ]) {
        psgIds.put(g.DeveloperName, g.Id);
      }
      if (!psgIds.isEmpty()) {
        Test.calculatePermissionSetGroup(new List<Id>(psgIds.values()));
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
        for (Map<String, Object> d : defs) {
          for (Object p : (List<Object>) d.get('permissionSetGroups')) {
            if (psgIds.containsKey((String) p)) {
              psas.add(
                new PermissionSetAssignment(
                  AssigneeId = created.get((String) d.get('employeeNo')).Id,
                  PermissionSetGroupId = psgIds.get((String) p)
                )
              );
            }
          }
        }
        insert psas;
      }
    }
    for (String emp : created.keySet()) {
      USERS.put(emp, created.get(emp).Id);
    }
    return created;
  }

  /**
   * @description 테스트 사용자(저장하지 않음).
   * @param alias 별칭(사번 등, 8자 이하로 자름)
   * @param lastName 성명
   * @param profileId 프로필
   * @return User
   */
  public static User newUser(String alias, String lastName, Id profileId) {
    String unique =
      alias +
      '.' +
      Crypto.getRandomInteger() +
      '@test.slqms.example.com';
    return new User(
      LastName = lastName ?? alias,
      Alias = alias.left(8),
      Email = alias + '@slqms.example.com',
      Username = unique.toLowerCase(),
      ProfileId = profileId,
      TimeZoneSidKey = 'Asia/Seoul',
      LocaleSidKey = 'ko_KR',
      LanguageLocaleKey = 'ko',
      EmailEncodingKey = 'UTF-8'
    );
  }

  /**
   * @description 라이선스의 기본 프로필. SL 프로필(CMN-00-SEC-001)이 있으면 그것, 없으면 그 라이선스의 최소 권한 프로필.
   * @param licenseName UserLicense.Name(예: Salesforce, Salesforce Platform)
   * @return Profile Id
   */
  public static Id profileIdForLicense(String licenseName) {
    Id fallback;
    for (Profile p : [
      SELECT Id, Name
      FROM Profile
      WHERE UserLicense.Name = :licenseName
      ORDER BY Name
    ]) {
      if (p.Name.startsWith('SL Internal')) {
        return p.Id;
      }
      if (fallback == null || p.Name.startsWith('Minimum Access')) {
        fallback = p.Id;
      }
    }
    return fallback;
  }

  // ------------------------------------------------------------------ 내부
  private static Map<String, Object> data() {
    if (fixture == null) {
      StaticResource sr = [
        SELECT Body
        FROM StaticResource
        WHERE Name = :RESOURCE
        LIMIT 1
      ];
      fixture = (Map<String, Object>) JSON.deserializeUntyped(
        sr.Body.toString()
      );
    }
    return fixture;
  }

  private static void loadStep(
    Schema.SObjectType t,
    String obj,
    String extField,
    List<Object> rows
  ) {
    Schema.DescribeSObjectResult d = t.getDescribe(
      SObjectDescribeOptions.DEFERRED
    );
    Map<String, Schema.SObjectField> fields = d.fields.getMap();
    Map<String, Schema.RecordTypeInfo> rts = d.getRecordTypeInfosByDeveloperName();
    if (!fields.containsKey(extField.toLowerCase())) {
      return;
    }
    rememberExisting(obj, extField, rows);
    List<SObject> inserts = new List<SObject>();
    List<SObject> updates = new List<SObject>();
    List<String> insertKeys = new List<String>();
    for (Object o : rows) {
      Map<String, Object> row = (Map<String, Object>) o;
      String ext = String.valueOf(row.get(extField));
      String key = obj + '|' + extField + '|' + ext;
      SObject rec = t.newSObject();
      Boolean isUpdate = REFS.containsKey(key);
      if (isUpdate) {
        rec.Id = REFS.get(key);
      }
      for (String col : row.keySet()) {
        Object raw = row.get(col);
        if (col == 'RecordTypeDeveloperName') {
          if (raw != null && rts.containsKey((String) raw)) {
            rec.put('RecordTypeId', rts.get((String) raw).getRecordTypeId());
          }
          continue;
        }
        if (col.contains('.')) {
          putRelation(rec, fields, col, raw, isUpdate);
          continue;
        }
        Schema.SObjectField f = fields.get(col.toLowerCase());
        if (f == null) {
          continue;
        }
        Schema.DescribeFieldResult fd = f.getDescribe();
        if (isUpdate ? !fd.isUpdateable() : !fd.isCreateable()) {
          continue;
        }
        rec.put(f, convert(fd.getType(), substitute(raw)));
      }
      if (isUpdate) {
        updates.add(rec);
      } else {
        inserts.add(rec);
        insertKeys.add(key);
      }
    }
    insert inserts;
    update updates;
    for (Integer i = 0; i < inserts.size(); i++) {
      REFS.put(insertKeys[i], inserts[i].Id);
    }
  }

  /** 이미 있는 레코드(@TestSetup 등)는 외부 키로 찾아 갱신 대상으로 둔다. 같은 키를 다시 넣어 중복 오류가 나지 않게 한다. */
  private static void rememberExisting(
    String obj,
    String extField,
    List<Object> rows
  ) {
    Set<String> exts = new Set<String>();
    for (Object o : rows) {
      Object v = ((Map<String, Object>) o).get(extField);
      if (v != null) {
        exts.add(String.valueOf(v));
      }
    }
    String soql =
      'SELECT Id, ' +
      String.escapeSingleQuotes(extField) +
      ' FROM ' +
      String.escapeSingleQuotes(obj) +
      ' WHERE ' +
      String.escapeSingleQuotes(extField) +
      ' IN :exts';
    for (
      SObject e : Database.queryWithBinds(
        soql,
        new Map<String, Object>{ 'exts' => exts },
        AccessLevel.SYSTEM_MODE
      )
    ) {
      REFS.put(
        obj + '|' + extField + '|' + String.valueOf(e.get(extField)),
        e.Id
      );
    }
  }

  private static void putRelation(
    SObject rec,
    Map<String, Schema.SObjectField> fields,
    String col,
    Object raw,
    Boolean isUpdate
  ) {
    String rel = col.substringBefore('.');
    String extField = col.substringAfter('.');
    String fieldName = rel.endsWith('__r')
      ? rel.removeEnd('__r') + '__c'
      : rel + 'Id';
    Schema.SObjectField f = fields.get(fieldName.toLowerCase());
    if (f == null || raw == null || String.isBlank(String.valueOf(raw))) {
      return;
    }
    Schema.DescribeFieldResult fd = f.getDescribe();
    if (isUpdate && !fd.isUpdateable()) {
      return; // 주종 관계 필드는 갱신할 수 없다(재지정 불가)
    }
    List<Schema.SObjectType> targets = fd.getReferenceTo();
    String target = targets.isEmpty() ? null : String.valueOf(targets[0]);
    Id refId = target == 'User'
      ? USERS.get(String.valueOf(raw))
      : REFS.get(target + '|' + extField + '|' + raw);
    if (refId != null) {
      rec.put(f, refId);
    }
  }

  private static Object substitute(Object raw) {
    if (!(raw instanceof String) || !((String) raw).contains('{{')) {
      return raw;
    }
    String s = (String) raw;
    Matcher m = REF.matcher(s);
    while (m.find()) {
      Id refId = REFS.get(m.group(1) + '|' + m.group(2) + '|' + m.group(3));
      s = s.replace(m.group(0), refId == null ? '' : String.valueOf(refId));
      m = REF.matcher(s);
    }
    Matcher u = USR.matcher(s);
    while (u.find()) {
      Id uid = USERS.get(u.group(1)) ?? UserInfo.getUserId();
      s = s.replace(u.group(0), String.valueOf(uid));
      u = USR.matcher(s);
    }
    return s;
  }

  private static Object convert(Schema.DisplayType t, Object raw) {
    if (
      raw == null || (raw instanceof String && String.isBlank((String) raw))
    ) {
      return null;
    }
    String v = String.valueOf(raw);
    switch on t {
      when BOOLEAN {
        return v.equalsIgnoreCase('true');
      }
      when DATE {
        return Date.valueOf(v.left(10));
      }
      when DATETIME {
        return (Datetime) JSON.deserialize('"' + v + '"', Datetime.class);
      }
      when DOUBLE, PERCENT, CURRENCY {
        return Decimal.valueOf(v);
      }
      when INTEGER {
        return Integer.valueOf(v);
      }
      when LONG {
        return Long.valueOf(v);
      }
      when else {
        return v;
      }
    }
  }
}
