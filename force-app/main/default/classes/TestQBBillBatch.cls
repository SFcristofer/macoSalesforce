@isTest
private class TestQBBillBatch {

    @isTest static void testQBBillBatch() {

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaProveedor('Creada');
        
        System.debug('TEST BATCH QB Bill');
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBBill'));
        Test.startTest();
        QBBillBatch batch = new QBBillBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
  }

}