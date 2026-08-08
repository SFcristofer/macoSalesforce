@isTest
private class TestQBInvoiceBatch {

    @isTest static void testQBInvoiceBatch() {

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaCliente('Enviada');
        
        System.debug('TEST BATCH ALTA CLIENTES');
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBInvoice'));
        Test.startTest();
        QBInvoiceBatch batch = new QBInvoiceBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
  }

}