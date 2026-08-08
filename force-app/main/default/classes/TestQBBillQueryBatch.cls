@isTest
private class TestQBBillQueryBatch {

    @isTest static void testQBBillQueryBatch() {

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaProveedor('Contabilizada');
        
        System.debug('TEST QUERY BATCH QB Bill');
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('billPagado'));
        Test.startTest();
        QBBillQueryBatch batch = new QBBillQueryBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
  }

}