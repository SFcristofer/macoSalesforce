@isTest
private class TestMassiveImageUploadAWSS3 {

    @isTest static void testMassiveUploadImgsAWSS3() {
        Product2 product;
        TestUtil tu = new TestUtil();
        tu.initSoloBase();
        tu.createProductoBaseImage();

        Test.startTest();
        product = tu.getProductImage();
        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));
        MassiveImageUploadAWSS3 upldr = new MassiveImageUploadAWSS3(3);
        upldr.executeLoad();

        Test.stopTest();
    }


    @isTest static void testResetFlagsUploadImgsAWSS3() {
        Product2 product;
        TestUtil tu = new TestUtil();
        tu.initSoloBase();        
        tu.createProductoBaseImage();

        Test.startTest();
        product = tu.getProductImage();

        MassiveImageUploadAWSS3 upldr = new MassiveImageUploadAWSS3(3);
        upldr.resetUploadFlags();

        Test.stopTest();
    }    

}