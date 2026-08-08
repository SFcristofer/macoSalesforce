@isTest
private class TestBatchProductosLibra {

    @isTest static void testBatchProductos() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));
        Test.startTest();
        BatchProductosLibra batch = new BatchProductosLibra();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
    }
}