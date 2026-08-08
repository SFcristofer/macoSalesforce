@isTest
private class TestQBJournalEntryBatch {

    @isTest static void testQBJournalEntryBatch() {

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaProveedor('Contabilizada');
        
        System.debug('TEST BATCH QB Bill');
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBJoutnal'));
        Test.startTest();
        QBJournalEntryBatch batch = new QBJournalEntryBatch();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
  }

}