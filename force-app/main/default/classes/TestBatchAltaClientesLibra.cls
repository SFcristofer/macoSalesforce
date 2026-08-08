@isTest
private class TestBatchAltaClientesLibra {

    @isTest static void testBatchAltaClientes() {

        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        
        System.debug('TEST BATCH ALTA CLIENTES');
        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));
        Test.startTest();        
        BatchAltaClientesLibra batch = new BatchAltaClientesLibra();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
	}

}