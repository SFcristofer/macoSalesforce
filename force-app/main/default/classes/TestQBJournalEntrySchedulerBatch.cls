@isTest
private class TestQBJournalEntrySchedulerBatch {
    @isTest static void testQBJournalEntrySchedulerBatch() {
        test.startTest();
        QBJournalEntrySchedulerBatch qbScheduler = new QBJournalEntrySchedulerBatch();
        String chron = '0 0 23 * * ?';
        System.schedule('TestQBJESB', chron, qbScheduler);
        test.stopTest();
    }

}