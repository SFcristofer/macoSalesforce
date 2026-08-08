@isTest
private class TestOrderCloneController {

    @isTest static void testOrderCloneController() {
        List<PedidoDeCompra__c> pedidos;
        PedidoDeCompra__c pedido;
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        test.startTest();
        tu.initPedidoAgente();
        pedidos = tu.getPedidosAgente();

        System.debug('pedidos.size[' + pedidos.size() + ']');

        pedido = pedidos.get(0);

        System.debug('pedido[' + pedido + ']');

        ApexPages.StandardController stdOrder = new ApexPages.StandardController(pedido);
        OrderCloneController orderController = new OrderCloneController(stdOrder);
        orderController.cloneOrder();
        orderController.getIdOrder();
        orderController.getIdOrderCloned();
        test.stopTest();
    }
}