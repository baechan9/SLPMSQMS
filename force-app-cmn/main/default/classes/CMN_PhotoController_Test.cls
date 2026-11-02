/**
 * @description 모바일 사진 첨부 서버 검증(CMN-00-UX-001 AC-1). 이미지 축소(장변 1920px)는 화면(cmnImageResize Jest)에서 확인한다.
 * @group CMN-00-UX-001
 */
@IsTest
private class CMN_PhotoController_Test {
  @TestSetup
  static void setup() {
    CMN_Company__c c = new CMN_Company__c(
      Name = 'SL',
      CompanyCode__c = '1000',
      Country__c = 'KR'
    );
    insert c;
    CMN_Plant__c p = new CMN_Plant__c(
      Name = 'KR01',
      PlantCode__c = 'KR01',
      Company__c = c.Id,
      Region__c = 'KR',
      TimeZone__c = 'Asia/Seoul',
      DefaultLanguage__c = 'ko'
    );
    insert p;
    CMN_CodeGroup__c g = new CMN_CodeGroup__c(
      Name = 'DOC_CLASS',
      GroupCode__c = 'DOC_CLASS',
      MaxLevel__c = 2
    );
    insert g;
    insert new CMN_Code__c(
      CodeGroup__c = g.Id,
      Code__c = 'NCR_PHOTO',
      Name = 'NCR photo',
      IsActive__c = true,
      Attribute2__c = 'MULTI_FILE'
    );
    insert new CMN_TestRecord__c(
      Name = 'ncr',
      Plant__c = p.Id,
      Status__c = 'DRAFT'
    );
  }

  @IsTest
  static void test_AC01_threePhotosBecomeThreeFiles() {
    // Given: 촬영·축소된 사진 3장
    Id ncr = [SELECT Id FROM CMN_TestRecord__c].Id;
    List<CMN_PhotoController.Photo> photos = new List<CMN_PhotoController.Photo>();
    for (Integer i = 1; i <= 3; i++) {
      CMN_PhotoController.Photo p = new CMN_PhotoController.Photo();
      p.fileName = 'photo-' + i + '.jpg';
      p.base64 = EncodingUtil.base64Encode(Blob.valueOf('jpeg-' + i));
      photos.add(p);
    }

    // When
    List<CMN_DocumentService.Result> results = CMN_PhotoController.uploadPhotos(
      ncr,
      'NCR_PHOTO',
      photos
    );

    // Then: 문서·파일 3개(사진은 파일명 단위 문서), 모두 공개
    Assert.areEqual(3, results.size());
    Assert.areEqual(
      3,
      [SELECT COUNT() FROM CMN_Document__c WHERE ParentRecordId__c = :ncr]
    );
    Assert.areEqual(
      3,
      [
        SELECT COUNT()
        FROM CMN_DocumentRevision__c
        WHERE Status__c = 'RELEASED' AND StorageType__c = 'SF_FILE'
      ]
    );
  }

  @IsTest
  static void test_negative_inputValidation() {
    Id ncr = [SELECT Id FROM CMN_TestRecord__c].Id;
    CMN_PhotoController.Photo p = new CMN_PhotoController.Photo();
    p.fileName = '../bad.jpg';
    p.base64 = EncodingUtil.base64Encode(Blob.valueOf('x'));
    for (
      Object[] c : new List<Object[]>{
        new List<Object>{
          ncr,
          'NCR_PHOTO',
          new List<CMN_PhotoController.Photo>{ p },
          Label.CMN_Common_InvalidInput
        },
        new List<Object>{
          ncr,
          'NO_SUCH',
          new List<CMN_PhotoController.Photo>{ p },
          Label.CMN_Doc_InvalidClass
        },
        new List<Object>{
          ncr,
          'NCR_PHOTO',
          new List<CMN_PhotoController.Photo>(),
          Label.CMN_Common_InvalidInput
        }
      }
    ) {
      try {
        CMN_PhotoController.uploadPhotos(
          (Id) c[0],
          (String) c[1],
          (List<CMN_PhotoController.Photo>) c[2]
        );
        Assert.fail('오류가 나야 한다');
      } catch (AuraHandledException e) {
        Assert.areEqual((String) c[3], e.getMessage());
      }
    }
  }
}
