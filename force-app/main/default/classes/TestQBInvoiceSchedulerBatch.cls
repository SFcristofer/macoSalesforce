@isTest
private class TestQBInvoiceSchedulerBatch {
    @isTest static void testQBInvoiceSchedulerBatch() {
        test.startTest();
        QBInvoiceSchedulerBatch qbScheduler = new QBInvoiceSchedulerBatch();
        String chron = '0 0 23 * * ?';
        System.schedule('TestQBISB', chron, qbScheduler);
        test.stopTest();
    }

}