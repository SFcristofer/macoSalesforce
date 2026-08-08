@isTest
private class TestBatchCobrosLibra {
	
    @isTest static void testBatchCobros() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();

        List<PedidoDeCompra__c> pedidos = [SELECT Id, Name, Numero_de_Factura__c FROM PedidoDeCompra__c];
        System.debug('pedidossize[' + pedidos + ']');

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('cobros'));
        Test.startTest();
        BatchCobrosLibra batch = new BatchCobrosLibra();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
    }
	
}