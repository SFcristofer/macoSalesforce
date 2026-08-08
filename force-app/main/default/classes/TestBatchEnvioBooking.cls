@isTest
private class TestBatchEnvioBooking 
{
	
	@isTest static void testBatch() {
	    // Implement test code
       Account agente;
       PedidoDeCompra__c pedido;
       List<PedidoDeCompra__c> pedidos;
       TestUtil tu = new TestUtil();
       tu.initOpportunityTest();

       Test.startTest();
       tu.initPedidoAgente();
       pedidos = tu.getPedidosAgente();
       pedido = pedidos[0];
       agente = tu.getAgent();
       pedido.Booking_Agente__c = agente.Id;
       pedido.Cuenta_Agente_DO__c = agente.Id;

       BatchEnvioBooking batch = new BatchEnvioBooking(BatchEnvioBooking.TYPE_BATCH_SETENVIO);
       Id batchId = Database.executeBatch(batch);
       Test.stopTest();		
	}


	@isTest static void testBatchTask() {
	    // Implement test code
       Account agente;
       PedidoDeCompra__c pedido;       
       List<PedidoDeCompra__c> pedidos;
       TestUtil tu = new TestUtil();
       tu.initOpportunityTest();

       Test.startTest();       
       tu.initPedidoAgenteTask();
       pedidos = tu.getPedidosAgente();
       pedido = pedidos[0];
       agente = tu.getAgent();
       pedido.Booking_Agente__c = agente.Id;
       pedido.Cuenta_Agente_DO__c = agente.Id;

       BatchEnvioBooking batch = new BatchEnvioBooking(BatchEnvioBooking.TYPE_BATCH_TASK);
       Id batchId = Database.executeBatch(batch);
       Test.stopTest();		
	}

}