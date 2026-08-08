@isTest
private class TestUploadAWSS3Controller {

	@isTest static void testAWSUploadCtrlr() {
        Product2 product;
		TestUtil tu = new TestUtil();
        tu.initSoloBase();
        tu.createProductoBaseImage();

        Test.startTest();
        product = tu.getProductImage();
        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));
        ApexPages.StandardController stdController = new ApexPages.StandardController(product);
        UploadAWSS3Controller controller = new UploadAWSS3Controller(stdController);
        controller.uploadImage();
        Test.stopTest();
	}

}