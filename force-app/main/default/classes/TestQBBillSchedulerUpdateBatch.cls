@isTest
private class TestQBBillSchedulerUpdateBatch {
    @isTest static void testQBBillSchedulerUpdateBatch() {
        test.startTest();
        QBBillSchedulerUpdateBatch scheduler = new QBBillSchedulerUpdateBatch();
        String chron = '0 0 23 * * ?';
        System.schedule('TestQBBSQUB', chron, scheduler);
        test.stopTest();
    }

}