@isTest
private class TestFileAWSS3Uploader {

	@isTest static void testAWSFileUploader() {
		TestUtil tu = new TestUtil();

        Document document;

        document = new Document();
        document.Body = Blob.valueOf('Some Text');
        document.ContentType = 'image/jpg';
        document.DeveloperName = 'test';
        document.IsPublic = true;
        document.Name = 'TestImg';
        document.FolderId = [SELECT Id FROM Folder WHERE Name = 'Imagenes de Productos'].Id;
        //insert document;

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));        
        FileAWSS3Uploader.uploadImage('key', 'secret', 'bucketName', 'host', 'fname', 'awsdir', document.Body);

	}


}