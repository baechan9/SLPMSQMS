/**
 * @description 모바일 사진 첨부(CMN-00-UX-001 BR-4, AC-1). cmnPhotoCapture가 카메라로 찍고 장변 1920px로 줄인 이미지를 받아
 * 사용자 파일로 저장한 뒤 DOC-001 문서(사진 분류 = MULTI_FILE, 파일명 단위 문서)로 등록한다.
 * @group CMN-00-UX-001
 */
public with sharing class CMN_PhotoController {
  private static final Integer MAX_PHOTOS = 10;
  /** 1920px JPEG는 보통 1MB 안팎. base64 4MB(원본 약 3MB) 넘으면 축소가 안 된 것으로 보고 거절한다 */
  private static final Integer MAX_BASE64 = 4 * 1024 * 1024;
  private static final Pattern NAME = Pattern.compile(
    '^[^\\\\/:*?"<>|]{1,200}$'
  );

  /** @description 사진 한 장. */
  public class Photo {
    @AuraEnabled
    public String fileName { get; set; }
    @AuraEnabled
    public String base64 { get; set; }
  }

  /**
   * @description 사진을 부모 레코드의 문서로 등록한다.
   * @param parentId 부모 업무 레코드
   * @param docClassCode DOC_CLASS 코드(예: NCR_PHOTO)
   * @param photos 사진(최대 10장)
   * @return 문서 등록 결과
   * @throws AuraHandledException 입력·권한·분류 오류
   */
  @AuraEnabled
  public static List<CMN_DocumentService.Result> uploadPhotos(
    Id parentId,
    String docClassCode,
    List<Photo> photos
  ) {
    try {
      if (
        parentId == null ||
        String.isBlank(docClassCode) ||
        photos == null ||
        photos.isEmpty() ||
        photos.size() > MAX_PHOTOS
      ) {
        throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
      }
      List<CMN_Code__c> classes = CMN_DocumentSelector.docClasses(
        new Set<String>{ docClassCode }
      );
      if (classes.isEmpty()) {
        throw new CMN_ValidationException(Label.CMN_Doc_InvalidClass);
      }
      List<ContentVersion> versions = new List<ContentVersion>();
      for (Photo p : photos) {
        if (
          p == null ||
          String.isBlank(p.base64) ||
          p.base64.length() > MAX_BASE64 ||
          !NAME.matcher(p.fileName ?? '').matches()
        ) {
          throw new CMN_ValidationException(Label.CMN_Common_InvalidInput);
        }
        versions.add(
          new ContentVersion(
            Title = p.fileName.substringBeforeLast('.'),
            PathOnClient = p.fileName,
            VersionData = EncodingUtil.base64Decode(p.base64)
          )
        );
      }
      Database.insert(versions, AccessLevel.USER_MODE);
      List<Id> documentIds = new List<Id>();
      for (ContentVersion v : [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id IN :versions
        WITH USER_MODE
      ]) {
        documentIds.add(v.ContentDocumentId);
      }
      return CMN_DocumentService.registerFiles(
        parentId,
        classes[0].Id,
        documentIds,
        null,
        false
      );
    } catch (Exception e) {
      String message = e instanceof CMN_ValidationException
        ? e.getMessage()
        : Label.CMN_Common_UnexpectedError;
      if (!(e instanceof CMN_ValidationException)) {
        CMN_Logger.error(
          'CMN_PhotoController.uploadPhotos',
          e.getMessage(),
          parentId,
          e
        );
      }
      AuraHandledException aura = new AuraHandledException(message);
      aura.setMessage(message);
      throw aura;
    }
  }
}
