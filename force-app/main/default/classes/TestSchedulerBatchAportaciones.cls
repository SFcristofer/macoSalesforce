@isTest
private class TestSchedulerBatchAportaciones 
{
	
	@isTest static void testScheduler() 
	{
         test.startTest();
         SchedulerBatchAportaciones sba = new SchedulerBatchAportaciones ();
         String chron = '0 0 23 * * ?';
         System.schedule('TestSBA', chron, sba);
         test.stopTest();
	}	
	
}