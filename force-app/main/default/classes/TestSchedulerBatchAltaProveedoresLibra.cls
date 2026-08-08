@isTest
private class TestSchedulerBatchAltaProveedoresLibra {

    @isTest static void testSchedulerBatchAltaProveedoresLibra() {
        test.startTest();
        SchedulerBatchAltaProveedoresLibra sbpl = new SchedulerBatchAltaProveedoresLibra();
        String chron = '0 0 23 * * ?';
        System.schedule('TestSBPL', chron, sbpl);
        test.stopTest();
    }
}