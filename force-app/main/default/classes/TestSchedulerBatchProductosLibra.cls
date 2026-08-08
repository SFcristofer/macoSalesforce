@isTest
private class TestSchedulerBatchProductosLibra 
{
	
	@isTest static void testScheduler() 
	{
         test.startTest();
         SchedulerBatchProductosLibra sb = new SchedulerBatchProductosLibra ();
         String chron = '0 0 23 * * ?';
         System.schedule('TestSB', chron, sb);
         test.stopTest();
	}	
	
}