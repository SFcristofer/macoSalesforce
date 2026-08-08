@isTest
private class TestQBBillQuerySTokenBatch {

    @isTest static void testQBBillQuerySTokenBatch() {

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaProveedor('Contabilizada');
        
        System.debug('TEST QUERY ST BATCH QB Bill');
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('billPagado'));
        Test.startTest();
        QBBillQuerySTokenBatch batch = new QBBillQuerySTokenBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
  }

}