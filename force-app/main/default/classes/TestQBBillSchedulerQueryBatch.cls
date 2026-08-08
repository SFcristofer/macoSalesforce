@isTest
private class TestQBBillSchedulerQueryBatch {
    @isTest static void testQBBillSchedulerQueryBatch() {
        test.startTest();
        QBBillSchedulerQueryBatch scheduler = new QBBillSchedulerQueryBatch();
        String chron = '0 0 23 * * ?';
        System.schedule('TestQBBSQB', chron, scheduler);
        test.stopTest();
    }

}