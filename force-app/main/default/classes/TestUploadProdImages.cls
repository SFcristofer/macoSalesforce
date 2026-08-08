@isTest
private class TestUploadProdImages {
	
	@isTest static void testUploadImage() {
		TestUtil tu = new TestUtil();
		tu.initSoloBase();
		list<Product2> prods = tu.getAllPBUpdated();
		system.assertEquals(prods[0].IdImagen1__c, null);

		Test.startTest();		
        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));		
		UploadProdImages upi = new UploadProdImages(new ApexPages.StandardController(prods[0]));
		PageReference pageRef = Page.UploadProdImages;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('id',prods[0].id);
		upi.ProdImageList[0].fileBody = Blob.valueof('RANDOM-TEXT-TO-BINARY');
		upi.saveChanges();
		//prods = tu.getAllPBUpdated();
		//system.assertNotEquals(prods[0].IdImagen1__c, null);
		Test.stopTest();
	}
	
	@isTest static void testReturn() {
		TestUtil tu = new TestUtil();
		tu.initSoloBase();

        //Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));		
		UploadProdImages upi = new UploadProdImages(new ApexPages.StandardController(tu.getAllPBUpdated()[0]));
		upi.done();
	}
	
}