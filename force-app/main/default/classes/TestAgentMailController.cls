@isTest
private class TestAgentMailController
{
	
	@isTest static void testController() 
	{
		Account agente;
		Account parent;
		PedidoDeCompra__c objPedidoCompra;
        TestUtil tu = new TestUtil();

        tu.initOpportunityTest();
        Test.startTest();
        tu.initPedidoAgente();
       
	    agente = tu.getAgent();
		parent = tu.getParentAgent();

		System.debug('PC ag[' + agente + ']');
		System.debug('PC paag[' + parent + ']');		

        objPedidoCompra = tu.getPedidoCompra();
		System.debug('PC [' + objPedidoCompra + '] [' + objPedidoCompra.proforma__r.cuenta__c + ']');
        
        ApexPages.StandardController stdPedido = new ApexPages.StandardController(objPedidoCompra);
        AgentMailController agentM = new AgentMailController(stdPedido);
        Test.stopTest();

	}
	

}