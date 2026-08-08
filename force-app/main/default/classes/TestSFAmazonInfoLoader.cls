@isTest
private class TestSFAmazonInfoLoader {

    @isTest static void testAmazonInfoLoader() {
		TestUtil tu = new TestUtil();
        tu.initSoloBase();
        tu.createProductoBaseImage();

        SFAmazonInfoLoader ldr = new SFAmazonInfoLoader();
        ldr.getInformationProductImage();

	}
}