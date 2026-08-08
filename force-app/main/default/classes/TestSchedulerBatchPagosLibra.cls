@isTest
private class TestSchedulerBatchPagosLibra 
{
	
	@isTest static void testSchedulerBatchPagosLibra()
	{
        test.startTest();
         SchedulerBatchPagosLibra sbpl = new SchedulerBatchPagosLibra ();
         String chron = '0 0 23 * * ?';
         System.schedule('TestSBPL', chron, sbpl);
         test.stopTest();
	}

}