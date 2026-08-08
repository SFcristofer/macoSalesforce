@isTest
private class TestQBBillSchedulerQuerySTokenBatch {
    @isTest static void testQBBillSchedulerQuerySTokenBatch() {
        test.startTest();
        QBBillSchedulerQuerySTokenBatch scheduler = new QBBillSchedulerQuerySTokenBatch();
        String chron = '0 0 23 * * ?';
        System.schedule('TestQBBSQSTB', chron, scheduler);
        test.stopTest();
    }

}