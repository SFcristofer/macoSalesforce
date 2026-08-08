@isTest
private class TestQBBillSchedulerBatch {
    @isTest static void testQBInvoiceSchedulerBatch() {
        test.startTest();
        QBBillSchedulerBatch qbScheduler = new QBBillSchedulerBatch();
        String chron = '0 0 23 * * ?';
        System.schedule('TestQBISB', chron, qbScheduler);
        test.stopTest();
    }

}