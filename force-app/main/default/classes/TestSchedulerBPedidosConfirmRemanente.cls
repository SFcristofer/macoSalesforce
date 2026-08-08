@isTest
private class TestSchedulerBPedidosConfirmRemanente {
	
	@isTest static void testScheduler() {
         test.startTest();
         SchedulerBtchPedidosConfirmadosRemanente sb = new SchedulerBtchPedidosConfirmadosRemanente ();
         String chron = '0 0 23 * * ?';
         System.schedule('TestSB', chron, sb);
         test.stopTest();
	}	
	
}