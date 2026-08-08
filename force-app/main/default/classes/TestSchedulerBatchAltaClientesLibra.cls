@isTest
private class TestSchedulerBatchAltaClientesLibra {
    @isTest static void testSchedulerBatchAltaProveedoresLibra() {
        test.startTest();
        SchedulerBatchAltaClientesLibra sbpl = new SchedulerBatchAltaClientesLibra();
        String chron = '0 0 23 * * ?';
        System.schedule('TestSBPL', chron, sbpl);
        test.stopTest();
    }

}