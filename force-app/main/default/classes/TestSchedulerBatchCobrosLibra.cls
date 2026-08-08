@isTest
private class TestSchedulerBatchCobrosLibra {
	
    @isTest static void testSchedulerBatchCobrosLibra() {
        test.startTest();
        SchedulerBatchCobrosLibra sbpl = new SchedulerBatchCobrosLibra();
        String chron = '0 0 23 * * ?';
        System.schedule('TestSBPL', chron, sbpl);
        test.stopTest();
    }
	
}