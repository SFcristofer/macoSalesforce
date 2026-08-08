@isTest
private class TestBatchAltaProveedoresLibra {

   @isTest static void testBatchAltaProveedores() {

        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        
        System.debug('TEST BATCH');
        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));
        Test.startTest();        
        BatchAltaProveedoresLibra batch = new BatchAltaProveedoresLibra();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
	}

}