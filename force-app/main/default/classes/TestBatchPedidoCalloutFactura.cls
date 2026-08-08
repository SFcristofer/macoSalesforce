@isTest
private class TestBatchPedidoCalloutFactura {
	
    @isTest static void testBatchPedidoCalloutFactura() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();	  

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('example'));
        Test.startTest();
        BatchPedidoCalloutFactura batch = new BatchPedidoCalloutFactura();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
    }
	
}