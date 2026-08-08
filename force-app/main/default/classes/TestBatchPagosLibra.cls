@isTest
private class TestBatchPagosLibra {
	
    @isTest static void testBatchPagos() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('pagos'));
        Test.startTest();
        BatchPagosLibra batch = new BatchPagosLibra();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
    }
	
}