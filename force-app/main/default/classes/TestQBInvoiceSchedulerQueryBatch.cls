@isTest
private class TestQBInvoiceSchedulerQueryBatch {
    @isTest static void testQBInvoiceSchedulerQueryBatch() {
        test.startTest();
        QBInvoiceSchedulerQueryBatch scheduler = new QBInvoiceSchedulerQueryBatch();
        String chron = '0 0 23 * * ?';
        System.schedule('TestQBISQB', chron, scheduler);
        test.stopTest();
    }

}