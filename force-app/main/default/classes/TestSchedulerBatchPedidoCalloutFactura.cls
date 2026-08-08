@isTest
private class TestSchedulerBatchPedidoCalloutFactura 
{
	
	@isTest static void testScheduler() 
	{
         test.startTest();
         SchedulerBatchPedidoCalloutFactura sb = new SchedulerBatchPedidoCalloutFactura();
         String chron = '0 0 23 * * ?';
         System.schedule('TestSB', chron, sb);
         test.stopTest();
	}	
	
}