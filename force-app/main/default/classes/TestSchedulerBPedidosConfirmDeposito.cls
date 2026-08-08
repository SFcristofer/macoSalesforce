@isTest
private class TestSchedulerBPedidosConfirmDeposito {
	
	@isTest static void testScheduler() {
         test.startTest();
         SchedulerBatchPedidosConfirmadosDeposito sb = new SchedulerBatchPedidosConfirmadosDeposito ();
         String chron = '0 0 23 * * ?';
         System.schedule('TestSB', chron, sb);
         test.stopTest();
	}	
	
}