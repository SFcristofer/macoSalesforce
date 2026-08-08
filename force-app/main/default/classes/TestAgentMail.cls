@isTest
private class TestAgentMail {
    
    @isTest static void testAgentMail() 
    {
        Account agente;
        PedidoDeCompra__c pedido;
        List<PedidoDeCompra__c> pedidos;
        System.debug('TEST AGENT 1');        
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        System.debug('TEST AGENT 2');
        test.startTest();
        tu.initPedidoAgente();
        System.debug('TEST AGENT 3');
        pedidos = tu.getPedidosAgente();
        pedido = pedidos[0];
        agente = tu.getAgent();
        System.debug('TEST AGENT 4');        
        pedido.Booking_Agente__c = agente.Id;
        pedido.Cuenta_Agente_DO__c = agente.Id;
        AgentMail.getDataOrder(pedidos);
        System.debug('TEST AGENT 5');        
        test.stopTest();
    }
    
}