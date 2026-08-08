@isTest
private class TestQBInvoiceQueryBatch {

    @isTest static void testQBInvoiceQueryBatch() {

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaCliente('Contabilizada');
        
        System.debug('TEST QUERY BATCH QB Invoice');
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('invoiceCobrada'));
        Test.startTest();
        QBInvoiceQueryBatch batch = new QBInvoiceQueryBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
  }

}