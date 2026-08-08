@isTest
private class TestQBBillUpdateBatch {

    @isTest static void testQBBillUpdateBatch() {

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaProveedor('Contabilizada', '1');
        
        System.debug('TEST QUERY UPDT BATCH QB Bill');
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator(''));
        Test.startTest();
        QBBillUpdateBatch batch = new QBBillUpdateBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
  }

}